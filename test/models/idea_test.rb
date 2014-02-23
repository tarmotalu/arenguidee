describe Idea do
  describe "#name" do
    it "must default to blank" do
      Idea.new.name.must_equal ""
    end

    it "must require presence" do
      Idea.new(:name => nil).tap(&:valid?).errors[:name].wont_be_empty
      Idea.new(:name => "").tap(&:valid?).errors[:name].wont_be_empty
      Idea.new(:name => " ").tap(&:valid?).errors[:name].wont_be_empty
    end

    it "must require length between 1 and 140 characters" do
      Idea.new(:name => "x").tap(&:valid?).errors[:name].must_be_empty
      Idea.new(:name => "x" * 140).tap(&:valid?).errors[:name].must_be_empty
      Idea.new(:name => "x" * 141).tap(&:valid?).errors[:name].wont_be_empty
    end
  end

  describe "#name=" do
    it "must strip whitespace" do
      Idea.new(:name => "\tWorld peace ").name.must_equal "World peace"
    end

    it "must not strip nil" do
      Idea.new(:name => nil).name.must_equal nil
    end
  end

  describe "#description" do
    it "must default to blank" do
      Idea.new.description.must_equal ""
    end

    it "must require existence" do
      idea = Idea.new(:description => nil)
      idea.tap(&:valid?).errors[:description].wont_be_empty
    end

    it "must be allowed blank" do
      idea = Idea.new(:description => "")
      idea.tap(&:valid?).errors[:description].must_be_empty
      idea = Idea.new(:description => " ")
      idea.tap(&:valid?).errors[:description].must_be_empty
    end

    it "must require length between 1 and 500 characters" do
      idea = Idea.new(:description => "x")
      idea.tap(&:valid?).errors[:description].must_be_empty
      idea = Idea.new(:description => "x" * 500)
      idea.tap(&:valid?).errors[:description].must_be_empty
      idea = Idea.new(:description => "x" * 501)
      idea.tap(&:valid?).errors[:description].wont_be_empty
    end
  end

  describe "#text" do
    it "must default to blank" do
      Idea.new.text.must_equal ""
    end

    it "must require existence" do
      Idea.new(:text => nil).tap(&:valid?).errors[:text].wont_be_empty
    end

    it "must be allowed blank" do
      Idea.new(:text => "").tap(&:valid?).errors[:text].must_be_empty
      Idea.new(:text => " ").tap(&:valid?).errors[:text].must_be_empty
    end

    it "must require length between 1 and 2500 characters" do
      Idea.new(:text => "x").tap(&:valid?).errors[:text].must_be_empty
      Idea.new(:text => "x" * 2500).tap(&:valid?).errors[:text].must_be_empty
      Idea.new(:text => "x" * 2501).tap(&:valid?).errors[:text].wont_be_empty
    end
  end

  describe "#status" do
    it "must not allow blank" do
      Idea.new(:status => nil).tap(&:valid?).errors[:status].wont_be_empty
      Idea.new(:status => "").tap(&:valid?).errors[:status].wont_be_empty
      Idea.new(:status => " ").tap(&:valid?).errors[:status].wont_be_empty
    end

    it "must be published by default" do
      Idea.new.status.must_equal "published"
    end

    %w[published pending removed].each do |status|
      it "must allow #{status} status" do
        idea = Idea.new(:status => status)
        idea.tap(&:valid?).errors[:status].must_be_empty
        idea.status.must_equal status
      end
    end

    it "must not allow foo status" do
      Idea.new(:status => "foo").tap(&:valid?).errors[:status].wont_be_empty
    end
  end
end