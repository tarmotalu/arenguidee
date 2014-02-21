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
        :login => "100000000001337",
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
        request.flash.alert.must_include "Email"
      end

      it "must not sign in" do
        User.create!(user_attrs)
        auth :facebook, omniauth_info
        assert !warden.authenticated?(:user)
      end
    end

    describe "when uid exists" do
      user_attrs = {
        :login => "100000000001337",
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
        user = User.first
        user.login.must_equal "38002240211"
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

  describe "#failure" do
    it "must redirect to signin page with error" do
      request.env["omniauth.error.type"] = "user_denied"
      get :failure
      assert_redirected_to new_user_session_path
      request.flash.notice.must_equal I18n.t("users.sessions.user_denied")
    end
  end

  def auth(provider, info)
    OmniAuth.config.add_mock(provider, info.deep_dup)
    request.env["omniauth.auth"] = OmniAuth.config.mock_auth[provider]
    get provider
  end
end
