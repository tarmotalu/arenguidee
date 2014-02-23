describe User do
  describe "#email" do
    it "must be allowed nil" do
      User.new(:email => nil).tap(&:valid?).errors[:email].must_be_empty
    end

    it "must be allowed blank" do
      User.new(:email => "").tap(&:valid?).errors[:email].must_be_empty
    end

    it "must require length between 3 and 128 characters" do
      User.new(:email => "a@").tap(&:valid?).errors[:email].wont_be_empty
      User.new(:email => "a@b").tap(&:valid?).errors[:email].must_be_empty

      user = User.new(:email => "a@" + "b" * 126)
      user.tap(&:valid?).errors[:email].must_be_empty
      user = User.new(:email => "a@" + "b" * 127)
      user.tap(&:valid?).errors[:email].wont_be_empty
    end

    it "must require @ sign" do
      User.new(:email => "a@b").tap(&:valid?).errors[:email].must_be_empty
      User.new(:email => "axb").tap(&:valid?).errors[:email].wont_be_empty
    end

    it "must require uniqueness" do
      User.create!(:email => "user@example.org")
      user = User.new(:email => "user@example.org")
      user.tap(&:valid?).errors[:email].wont_be_empty
    end

    it "must require uniqueness case-insensitively" do
      User.create!(:email => "user@example.org")
      user = User.new(:email => "uSeR@eXample.ORG")
      user.tap(&:valid?).errors[:email].wont_be_empty
    end

    it "must not require uniqueness if blank" do
      User.create!(:email => "")
      User.new(:email => "").tap(&:valid?).errors[:email].must_be_empty
    end
  end
end
