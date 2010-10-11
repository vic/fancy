require File.dirname(__FILE__) + "/spec_helper.rb"

describe FancyParser do

  context "block" do

    it "should parse a block without arguments" do
      node = parse("{}")
    end

  end

end
