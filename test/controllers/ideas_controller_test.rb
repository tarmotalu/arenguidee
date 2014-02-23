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
  end
end
