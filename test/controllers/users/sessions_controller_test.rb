describe Users::SessionsController do
  include Devise::TestHelpers

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "#facebook" do
    describe "when new" do
      omniauth_info = {
        :uid => "100000000001337", :info => {:email => "user@example.org"}
      }

      it "must create user with uid" do
        auth :facebook, omniauth_info
        User.count.must_equal 1
        User.first.facebook_uid.must_equal 100000000001337
      end

      it "must set name and email" do
        auth :facebook, {
          :uid => "100000000001337",

          :info => {
            :first_name => "James III",
            :last_name => "Cornwell",
            :email => "user@example.org"
          }
        }

        user = User.first
        user.email.must_equal "user@example.org"
        user.first_name.must_equal "James III"
        user.last_name.must_equal "Cornwell"
      end

      it "must set name blank if not given" do
        auth :facebook, {
          :uid => "100000000001337",
          :info => {:email => "user@example.org"}
        }


        user = User.first
        user.first_name.must_equal ""
        user.last_name.must_equal ""
      end

      it "must sign user in" do
        auth :facebook, omniauth_info
        assert warden.authenticated?(:user)
      end

      it "must redirect to root" do
        auth :facebook, omniauth_info
        assert_redirected_to root_path
      end
    end

    describe "when email exists" do
      user_attrs = {
        :facebook_uid => "100000000001337",
        :email => "user@example.org"
      }

      omniauth_info = {
        :uid => "200000000000069", :info => {:email => "user@example.org"}
      }

      it "must not change existing account" do
        User.create!(user_attrs)
        auth :facebook, omniauth_info
        User.count.must_equal 1
        User.first.facebook_uid.must_equal 100000000001337
      end

      it "must redirect to signin page with error" do
        User.create!(user_attrs)
        auth :facebook, omniauth_info
        assert_redirected_to new_user_session_path
        request.flash.alert.must_include User.human_attribute_name("email")
      end

      it "must not sign in" do
        User.create!(user_attrs)
        auth :facebook, omniauth_info
        assert !warden.authenticated?(:user)
      end
    end

    describe "when uid exists" do
      user_attrs = {
        :facebook_uid => "100000000001337",
        :email => "user@example.org"
      }

      omniauth_info = {
        :uid => "100000000001337", :info => {:email => "user@example.org"}
      }

      it "must not create new user" do
        User.create!(user_attrs)
        auth :facebook, omniauth_info
        User.count.must_equal 1
      end

      it "must sign user in" do
        User.create!(user_attrs)
        auth :facebook, omniauth_info
        assert warden.authenticated?(:user)
      end

      it "must redirect to root" do
        User.create!(user_attrs)
        auth :facebook, omniauth_info
        assert_redirected_to root_path
      end
    end
  end

  describe "#idcard" do
    describe "when new" do
      omniauth_info = {
        :uid => "38002240211",
        :user_info => {:personal_code => "38002240211"}
      }

      it "must create user with uid" do
        auth :idcard, omniauth_info
        User.count.must_equal 1
        User.first.login.must_equal "38002240211"
      end

      it "must set name" do
        auth :idcard, {
          :uid => "38002240211",
          :user_info => {
            :personal_code => "38002240211",
            :first_name => "James III",
            :last_name => "Cornwell",
          }
        }

        user = User.first
        user.first_name.must_equal "James III"
        user.last_name.must_equal "Cornwell"
      end

      it "must set name blank if not given" do
        auth :idcard, {
          :uid => "38002240211",
          :user_info => {:personal_code => "38002240211"}
        }

        user = User.first
        user.first_name.must_equal ""
        user.last_name.must_equal ""
      end

      it "must sign user in" do
        auth :idcard, omniauth_info
        assert warden.authenticated?(:user)
      end

      it "must redirect to root" do
        auth :idcard, omniauth_info
        assert_redirected_to root_path
      end
    end

    describe "when uid exists" do
      user_attrs = {:login => "38002240211"}
      omniauth_info = {
        :uid => "38002240211",
        :user_info => {:personal_code => "38002240211"}
      }

      it "must not create new user" do
        User.create!(user_attrs)
        auth :idcard, omniauth_info
        User.count.must_equal 1
      end

      it "must sign user in" do
        User.create!(user_attrs)
        auth :idcard, omniauth_info
        assert warden.authenticated?(:user)
      end

      it "must redirect to root" do
        User.create!(user_attrs)
        auth :idcard, omniauth_info
        assert_redirected_to root_path
      end
    end
  end

  describe "#mobileid" do
    after { Timecop.return }

    omniauth_info = {
      :uid => "38002240211",
      :user_info => {:personal_code => "38002240211"},
      :read_pin => {:challenge_id => "1234", :session_code => "31337"}
    }

    def auth_mobileid(info)
      request.env["omniauth.phase"] = "read_pin"
      auth :mobileid, info
      request.env["omniauth.phase"] = "authenticated"
      xhr :post, :mobileid, :session_code => "31337", :info => assigns(:info)
    end

    it "must render confirmation view" do
      request.env["omniauth.phase"] = "read_pin"
      auth :mobileid, omniauth_info
      assert_template "mobileid"
    end

    it "must not create user if not authenticated" do
      request.env["omniauth.phase"] = "read_pin"
      auth :mobileid, omniauth_info
      User.count.must_equal 0
    end

    describe "when info signature mismatches" do
      it "must raise and not create user" do
        request.env["omniauth.phase"] = "read_pin"
        auth :mobileid, omniauth_info
        request.env["omniauth.phase"] = "authenticated"

        invalid = ActiveSupport::MessageVerifier::InvalidSignature
        params = {:session_code => "31337", :info => assigns(:info) + "x"}
        proc { xhr :post, :mobileid, params }.must_raise invalid
        User.count.must_equal 0
      end
    end

    describe "when session code mismatches" do
      it "must raise and not create user" do
        request.env["omniauth.phase"] = "read_pin"
        auth :mobileid, omniauth_info
        request.env["omniauth.phase"] = "authenticated"

        invalid = Users::SessionsController::InvalidInfo
        params = {:session_code => "31338", :info => assigns(:info)}
        proc { xhr :post, :mobileid, params }.must_raise invalid
        User.count.must_equal 0
      end
    end

    describe "when more than 5 minutes have passed since signin" do
      it "must not create user" do
        request.env["omniauth.phase"] = "read_pin"
        auth :mobileid, omniauth_info
        request.env["omniauth.phase"] = "authenticated"
        Timecop.travel Time.now + 5.minutes

        invalid = Users::SessionsController::InvalidInfo
        params = {:session_code => "31337", :info => assigns(:info)}
        proc { xhr :post, :mobileid, params }.must_raise invalid
        User.count.must_equal 0
      end
    end

    describe "when new" do
      it "must create user with uid" do
        auth_mobileid omniauth_info
        User.count.must_equal 1
        User.first.login.must_equal "38002240211"
      end

      it "must set name" do
        auth_mobileid({
          :uid => "38002240211",
          :user_info => {
            :personal_code => "38002240211",
            :first_name => "James III",
            :last_name => "Cornwell",
          },
          :read_pin => {:challenge_id => "1234", :session_code => "31337"}
        })

        user = User.first
        user.first_name.must_equal "James III"
        user.last_name.must_equal "Cornwell"
      end

      it "must set name blank if not given" do
        auth_mobileid({
          :uid => "38002240211",
          :user_info => {:personal_code => "38002240211"},
          :read_pin => {:challenge_id => "1234", :session_code => "31337"}
        })

        user = User.first
        user.first_name.must_equal ""
        user.last_name.must_equal ""
      end

      it "must sign user in" do
        auth_mobileid omniauth_info
        assert warden.authenticated?(:user)
      end

      it "must redirect to root" do
        auth_mobileid omniauth_info
        response.body.must_equal %(window.location = "#{root_path}")
      end
    end

    describe "when uid exists" do
      user_attrs = {:login => "38002240211"}
      omniauth_info = {
        :uid => "38002240211",
        :user_info => {:personal_code => "38002240211"},
        :read_pin => {:challenge_id => "1234", :session_code => "31337"}
      }

      it "must not create new user" do
        User.create!(user_attrs)
        auth_mobileid omniauth_info
        User.count.must_equal 1
      end

      it "must sign user in" do
        User.create!(user_attrs)
        auth_mobileid omniauth_info
        assert warden.authenticated?(:user)
      end

      it "must redirect to root" do
        User.create!(user_attrs)
        auth_mobileid omniauth_info
        response.body.must_equal %(window.location = "#{root_path}")
      end
    end
  end

  describe "#failure" do
    before do
      strategy = OmniAuth::Strategies::Facebook.new(:name => "facebook")
      request.env["omniauth.strategy"] = strategy
    end

    it "must redirect to signin page" do
      get :failure
      assert_redirected_to new_user_session_path
    end

    it "must redirect to signin page with phone number if given" do
      request.env["omniauth.error.type"] = :error_301
      get :failure, :phone => "+37200007"
      assert_redirected_to new_user_session_path(:phone => "+37200007")
    end

    it "must set alert given user_denied error" do
      request.env["omniauth.error.type"] = "user_denied"
      get :failure
      assert_redirected_to new_user_session_path
      request.flash.alert.must_equal I18n.t("users.sessions.user_denied")
    end

    %w[
      error_101
      error_102
      error_301
      error_302
      error_303
      error_internal_error
      error_sim_error
      error_phone_absent
      error_user_cancel
      error_mid_not_ready
    ].each do |code|
      it "must set alert given #{code} error" do
        strategy = OmniAuth::Strategies::Mobileid.new(:name => "mobileid")
        request.env["omniauth.strategy"] = strategy
        request.env["omniauth.error.type"] = code.to_sym

        get :failure
        assert_redirected_to new_user_session_path
        request.flash.alert.must_equal I18n.t("users.sessions.mobileid.#{code}")
      end
    end
  end

  def auth(provider, info)
    OmniAuth.config.add_mock(provider, info.deep_dup)
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[provider]
    get provider
  end
end
