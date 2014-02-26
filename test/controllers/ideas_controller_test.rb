describe IdeasController do
  include Devise::TestHelpers

  describe "#create" do
    before do
      @category = Category.create!(:name => "World Peace")
      @user = User.create!
      sign_in @user
    end

    it "must save idea" do
      post :create, :idea => {
        :name => "Love all",
        :description => "You know, this and that.",
        :text => "Now, lemme tell you a story.",
        :category_id => @category.id
      }

      Idea.count.must_equal 1
      idea = Idea.first
      idea.name.must_equal "Love all"
      idea.description.must_equal "You know, this and that."
      idea.text.must_equal "Now, lemme tell you a story."
      idea.category_id.must_equal @category.id
    end

    it "must save idea to signed in user" do
      post :create, :idea => {:name => "Love all", :category_id => @category.id}
      Idea.first.user_id.must_equal @user.id
    end

    it "must redirect to idea" do
      post :create, :idea => {:name => "Love all", :category_id => @category.id}
      assert_redirected_to Idea.first
    end

    it "must respond with 422 Unprocessable Entity if failed" do
      post :create, :idea => {}
      assert_template "new"
      assert_response :unprocessable_entity
    end

    it "must set idea pending" do
      post :create, :idea => {:name => "Love all", :category_id => @category.id}
      Idea.first.status.must_equal "pending"
    end

    it "must not allow setting idea published" do
      post :create, :idea => {
        :name => "Love all", :category_id => @category.id,
        :status => "published"
      }
      Idea.first.status.must_equal "pending"
    end

    it "must allow setting idea published if admin" do
      @user.update_attributes(:is_admin => true)
      post :create, :idea => {
        :name => "Love all", :category_id => @category.id,
        :status => "published"
      }
      Idea.first.status.must_equal "published"
    end

    it "must allow leaving idea pending if admin" do
      @user.update_attributes(:is_admin => true)
      post :create, :idea => {
        :name => "Love all", :category_id => @category.id,
        :status => "pending"
      }
      Idea.first.status.must_equal "pending"
    end

    it "must not allow setting idea author name" do
      post :create, :idea => {
        :name => "Love all", :category_id => @category.id, :author_name => "Mia"
      }
      Idea.first.author_name.must_be_empty
    end

    it "must allow setting idea author name if admin" do
      @user.update_attributes(:is_admin => true)
      post :create, :idea => {
        :name => "Love all", :category_id => @category.id, :author_name => "Mia"
      }
      Idea.first.author_name.must_equal "Mia"
    end
  end

  describe "#edit" do
    before do
      @user = User.create!
      sign_in @user
    end

    it "must redirect to root page if not admin" do
      get :edit, :id => 1
      assert_redirected_to root_path
    end

    it "must render edit form if admin" do
      category = Category.create(:name => "World Peace")
      idea = Idea.create!(:user => @user, :category => category, :name => "X!")
      @user.update_attributes(:is_admin => true)
      get :edit, :id => idea.id
      assert_template "edit"
    end
  end

  describe "#update" do
    before do
      @category = Category.create!(:name => "World Peace")
      @user = User.create!
      sign_in @user
    end

    it "must update if admin" do
      idea = Idea.create!(
        :user => @user, :category => @category, :name => "Peace!"
      )
      @user.update_attributes(:is_admin => true)
      put :update, :id => idea.id, :idea => {:name => "War!"}

      assert_redirected_to Idea.first
      Idea.first.name.must_equal "War!"
    end

    it "must redirect to root page if not admin" do
      idea = Idea.create!(
        :user => @user, :category => @category, :name => "Peace!"
      )
      put :update, :id => idea.id, :idea => {:name => "War!"}

      assert_redirected_to root_path
      Idea.first.name.must_equal "Peace!"
    end

    it "must render edit page when validation failed" do
      idea = Idea.create!(
        :user => @user, :category => @category, :name => "Peace!"
      )
      @user.update_attributes(:is_admin => true)
      put :update, :id => idea.id, :idea => {:name => ""}
      assert_template "edit"
      assert_response :unprocessable_entity
    end

    it "must update status if admin" do
      idea = Idea.create!(
        :user => @user, :category => @category,
        :name => "I", :status => "pending"
      )
      @user.update_attributes(:is_admin => true)
      put :update, :id => idea.id, :idea => {:status => "published"}
      Idea.first.status.must_equal "published"
    end

    it "must not update status if not admin" do
      idea = Idea.create!(
        :user => @user, :category => @category,
        :name => "I", :status => "pending"
      )
      put :update, :id => idea.id, :idea => {:status => "published"}
      Idea.first.status.must_equal "pending"
    end
  end
end
