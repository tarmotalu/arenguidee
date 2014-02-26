describe UsersController do
  include Devise::TestHelpers

  describe "#edit" do
    before do
      @user = User.create!
      sign_in @user
    end

    it "must redirect to signin page if not signed in" do
      sign_out @user
      get :edit, :id => @user.id
      assert_redirected_to new_user_session_path
    end

    it "must redirect to user's page if not same user" do
      user = User.create!
      get :edit, :id => user.id
      assert_redirected_to user_path(user)
    end

    it "must render edit form" do
      get :edit, :id => @user.id
      assert_template "edit"
    end
  end

  describe "#update" do
    it "must redirect to signin page if not signed in" do
      user = User.create!
      put :update, :id => user.id, :user => {:email => "other@example.org"}
      assert_redirected_to user_path(user)
    end

    it "must redirect to user's page if not same user" do
      sign_in User.create!
      user = User.create!
      put :update, :id => user.id, :user => {:email => "other@example.org"}
      assert_redirected_to user_path(user)
    end

    it "must not update if not same user" do
      sign_in User.create!
      user = User.create!(:email => "me@example.org")
      put :update, :id => user.id, :user => {:email => "other@example.org"}
      user.reload.email.must_equal "me@example.org"
    end

    it "must update" do
      user = User.create!(:email => "me@example.org")
      sign_in user

      put :update, :id => user.id, :user => {
        :first_name => "Michael",
        :last_name => "Knight",
        :bio => "When I was young...",
        :email => "other@example.org"
      }

      user.reload
      user.first_name.must_equal "Michael"
      user.last_name.must_equal "Knight"
      user.bio.must_equal "When I was young..."
      user.email.must_equal "other@example.org"
    end

    it "must not update admin status" do
      user = User.create!
      sign_in user
      put :update, :id => user.id, :user => {:is_admin => true}
      user.reload.admin?.must_equal false
    end

    it "must not update login" do
      user = User.create!(:login => "13")
      sign_in user
      put :update, :id => user.id, :user => {:login => "42"}
      user.reload.login.must_equal "13"
    end

    it "must not update facebook uid" do
      user = User.create!(:facebook_uid => 13)
      sign_in user
      put :update, :id => user.id, :user => {:facebook_uid => 42}
      user.reload.facebook_uid.must_equal 13
    end

    it "must render edit page if validation failed" do
      user = User.create!
      sign_in user
      put :update, :id => user.id, :user => {:email => "foo"}
      assert_template "edit"
      assert_response :unprocessable_entity
    end
  end
end
