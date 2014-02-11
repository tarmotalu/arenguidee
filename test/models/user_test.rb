class UserTest < ActiveRecord::TestCase
  describe "#apply_omniauth" do
    it "humanizes first name" do
      user = User.new
      user.apply_omniauth("user_info" => {"first_name" => "JOHN"})
      user.first_name.must_equal "John"
    end

    it "humanizes last name" do
      user = User.new
      user.apply_omniauth("user_info" => {"last_name" => "SMITH"})
      user.last_name.must_equal "Smith"
    end

    it "sets login" do
      user = User.new
      user.apply_omniauth("user_info" => {"personal_code" => "1337"})
      user.login.must_equal "1337"
    end

    it "sets email" do
      user = User.new
      user.apply_omniauth("user_info" => {"email" => "old@example.org"})
      user.email.must_equal "old@example.org"
    end

    it "sets status" do
      user = User.new
      user.apply_omniauth("user_info" => {"personal_code" => "1337"})
      user.status.must_equal "active"
    end

    it "humanizes first name given multibyte string" do
      user = User.new
      user.apply_omniauth("user_info" => {"first_name" => "ÜLLE"})
      user.first_name.must_equal "Ülle"
    end
  end
end
