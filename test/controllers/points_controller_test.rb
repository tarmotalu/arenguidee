describe PointsController do
  include Devise::TestHelpers

  describe "#create" do
    before do
      @user = User.create!
      sign_in @user

      @category = Category.create!(:name => "World Peace")
      @idea = Idea.create!(:user => @user, :category => @category, :name => "X")
    end

    it "must redirect to signin page  if not signed in" do
      sign_out @user
      post :create, :point => {:content => "+1", :idea_id => @idea.id}
      assert_redirected_to new_user_session_path
    end

    it "must save point" do
      post :create, :point => {
        :content => "+1",
        :idea_id => @idea.id,
        :value => 1
      }

      Point.count.must_equal 1
      point = Point.first
      point.value.must_equal 1
      point.content.must_equal "+1"
      point.idea.must_equal @idea
    end

    it "must save point to signed in user" do
      post :create, :point => {:content => "+1", :idea_id => @idea.id}
      Point.first.user.must_equal @user
    end

    it "must not save website" do
      post :create, :point => {
        :content => "+1", :idea_id => @idea.id, :website => "http://foo.com"
      }
      Point.first.website.must_equal nil
    end
  end
end
