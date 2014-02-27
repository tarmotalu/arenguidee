describe Point do
  describe "#name" do
    it "must not be required" do
      Point.new(:name => nil).tap(&:valid?).errors[:name].must_be_empty
      Point.new(:name => "").tap(&:valid?).errors[:name].must_be_empty
    end
  end

  describe "#content" do
    it "must default to blank" do
      Point.new.content.must_equal ""
    end

    it "must require presence" do
      Point.new(:content => nil).tap(&:valid?).errors[:content].wont_be_empty
      Point.new(:content => "").tap(&:valid?).errors[:content].wont_be_empty
    end

    it "must require length between 1 and 2500 characters" do
      point = Point.new(:content => "x")
      point.tap(&:valid?).errors[:content].must_be_empty
      point = Point.new(:content => "x" * 2500)
      point.tap(&:valid?).errors[:content].must_be_empty
      point = Point.new(:content => "x" * 2501)
      point.tap(&:valid?).errors[:content].wont_be_empty
    end
  end
end
