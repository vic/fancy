require File.dirname(__FILE__) + "/spec_helper.rb"

describe FancyParser do

  context "identifier" do

    it "should parse simple hello identifier" do
      hello = parse("hello", :root => :identifier)
      ast = hello.ast
      ast.should_not be_nil
      ast.should be_kind_of(Fancy::AST::Identifier)
      ast.name.should == :hello
    end

    it "should take any character until space" do
      foo = parse("hello ", :root => :identifier)
      foo.ast.name.should == :hello
    end

    it "should take any character until tab" do
      foo = parse("hello\t", :root => :identifier)
      foo.ast.name.should == :hello
    end

    it "should take any character until newline" do
      foo = parse("hello\n", :root => :identifier)
      foo.ast.name.should == :hello
    end


    it "should take any character even operators" do
      foo = parse("foo+bar", :root => :identifier)
      foo.ast.name.should == :"foo+bar"
    end


    it "should take @ as part of identifier" do
      node = parse("@foo", :root => :identifier)
      ast = node.ast
      ast.should be_instance_variable
      ast.name.should == :foo
    end


    it "should take @@ as part of identifier" do
      node = parse("@@foo", :root => :identifier)
      ast = node.ast
      ast.should be_class_variable
      ast.name.should == :foo
    end

    it "should take : ast last character on identifier" do
      foo = parse("foo:bar", :root => :identifier)
      foo.ast.name.should == :"foo:"
    end

  end

end
