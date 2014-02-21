describe User do
  describe "#email" do
    it "must not be required" do
      User.new(:email => nil).tap(&:valid?).errors[:email].must_be_empty
      User.new(:email => "").tap(&:valid?).errors[:email].must_be_empty
    end

    it "must have length between 3 and 128" do
      User.new(:email => "a@").tap(&:valid?).errors[:email].wont_be_empty
      User.new(:email => "a@b").tap(&:valid?).errors[:email].must_be_empty

      user = User.new(:email => "a@" + "b" * 126)
      user.tap(&:valid?).errors[:email].must_be_empty
      user = User.new(:email => "a@" + "b" * 127)
      user.tap(&:valid?).errors[:email].wont_be_empty
    end

    it "must have @ sign" do
      User.new(:email => "a@b").tap(&:valid?).errors[:email].must_be_empty
      User.new(:email => "axb").tap(&:valid?).errors[:email].wont_be_empty
    end

    it "must be unique" do
      User.create!(:email => "user@example.org", :login => "1")
      user = User.new(:email => "user@example.org")
      user.tap(&:valid?).errors[:email].wont_be_empty
    end

    it "must be unique case-insensitively" do
      User.create!(:email => "user@example.org", :login => "1")
      user = User.new(:email => "uSeR@eXample.ORG")
      user.tap(&:valid?).errors[:email].wont_be_empty
    end

    it "must not be unique amongst blank" do
      User.create!(:login => "1", :email => "")
      User.new(:email => "").tap(&:valid?).errors[:email].must_be_empty
    end
  end
end
