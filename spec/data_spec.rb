# -*- ruby encoding: utf-8 -*-

require 'spec_helper'

describe Agio::Data do
  subject { Agio::Data.new("test") }

  it "should compare leftwise against a String (data == string)" do
    subject.should == "test"
    subject.should_not == "test1"
  end

  it "should compare rightwise against a String (string == data)" do
    "test".should == subject
    "test1".should_not == subject
  end

  it "should compare against another Agio::Data object" do
    Agio::Data.new("test").should == subject
    subject.should == Agio::Data.new("test")

    Agio::Data.new("test1").should_not == subject
    subject.should_not == Agio::Data.new("test1")
  end

  it "should not compare against an Agio::CData" do
    Agio::CData.new("test").should_not == subject
    subject.should_not == Agio::CData.new("test")
  end

  it "should not compare against an Agio::Comment" do
    Agio::Comment.new("test").should_not == subject
    subject.should_not == Agio::Comment.new("test")
  end

  it "should not compare against an Agio::XMLDecl" do
    Agio::XMLDecl.new.should_not == subject
    subject.should_not == Agio::XMLDecl.new
  end
end

describe Agio::CData do
  subject { Agio::CData.new("test") }

  it "should compare leftwise against a String (data == string)" do
    subject.should == "test"
    subject.should_not == "test1"
  end

  it "should compare rightwise against a String (string == data)" do
    "test".should == subject
    "test1".should_not == subject
  end

  it "should compare against another Agio::Data object" do
    Agio::CData.new("test").should == subject
    subject.should == Agio::CData.new("test")

    Agio::CData.new("test1").should_not == subject
    subject.should_not == Agio::CData.new("test1")
  end

  it "should not compare against an Agio::Data" do
    Agio::Data.new("test").should_not == subject
    subject.should_not == Agio::Data.new("test")
  end

  it "should not compare against an Agio::Comment" do
    Agio::Comment.new("test").should_not == subject
    subject.should_not == Agio::Comment.new("test")
  end

  it "should not compare against an Agio::XMLDecl" do
    Agio::XMLDecl.new.should_not == subject
    subject.should_not == Agio::XMLDecl.new
  end
end

describe Agio::Comment do
  subject { Agio::Comment.new("test") }

  it "should compare leftwise against a String (data == string)" do
    subject.should == "test"
    subject.should_not == "test1"
  end

  it "should compare rightwise against a String (string == data)" do
    "test".should == subject
    "test1".should_not == subject
  end

  it "should compare against another Agio::Data object" do
    Agio::Comment.new("test").should == subject
    subject.should == Agio::Comment.new("test")

    Agio::Comment.new("test1").should_not == subject
    subject.should_not == Agio::Comment.new("test1")
  end

  it "should not compare against an Agio::Data" do
    Agio::Data.new("test").should_not == subject
    subject.should_not == Agio::Data.new("test")
  end

  it "should not compare against an Agio::CData" do
    Agio::CData.new("test").should_not == subject
    subject.should_not == Agio::CData.new("test")
  end

  it "should not compare against an Agio::XMLDecl" do
    Agio::XMLDecl.new.should_not == subject
    subject.should_not == Agio::XMLDecl.new
  end
end

describe Agio::XMLDecl do
  context "constructed with only version" do
    let(:decl_string) { %Q(<?xml version="1.0" ?>) }
    let(:decl_array) { [ "1.0", nil, nil ] }

    subject { Agio::XMLDecl.new(:version => "1.0") }

    its(:version) { should == "1.0" }
    its(:encoding) { should be_nil }
    its(:standalone) { should be_nil }
    its(:to_s) { should == decl_string }
    its(:to_str) { should == decl_string }
    its(:to_a) { should == decl_array }
    its(:inspect) { should == %Q(#<Agio::XMLDecl '#{decl_string}'>) }

    it "should equality-compare with a String transitively" do
      decl_string.should == subject
      decl_string.upcase.should_not == subject

      subject.should == decl_string
      subject.should_not == decl_string.upcase
    end

    it "should compare with an Array" do
      subject.should == decl_array
    end

    it "should compare with another Agio::XMLDecl" do
      subject.should == Agio::XMLDecl.new(:version => "1.0")
    end
  end

  context "constructed with only encoding" do
    let(:decl_string) { %Q(<?xml encoding="UTF-8" ?>) }
    let(:decl_array) { [ nil, "UTF-8", nil ] }

    subject { Agio::XMLDecl.new(:encoding => "UTF-8") }

    its(:version) { should be_nil }
    its(:encoding) { should == "UTF-8" }
    its(:standalone) { should be_nil }
    its(:to_s) { should == decl_string }
    its(:to_str) { should == decl_string }
    its(:to_a) { should == decl_array }
    its(:inspect) { should == %Q(#<Agio::XMLDecl '#{decl_string}'>) }

    it "should equality-compare with a String transitively" do
      decl_string.should == subject
      decl_string.upcase.should_not == subject

      subject.should == decl_string
      subject.should_not == decl_string.upcase
    end

    it "should compare with an Array" do
      subject.should == decl_array
    end

    it "should compare with another Agio::XMLDecl" do
      subject.should == Agio::XMLDecl.new(:encoding => "UTF-8")
    end
  end

  context "constructed with only standalone" do
    let(:decl_string) { %Q(<?xml standalone="true" ?>) }
    let(:decl_array) { [ nil, nil, true ] }

    subject { Agio::XMLDecl.new(:standalone => true) }

    its(:version) { should be_nil }
    its(:encoding) { should be_nil }
    its(:standalone) { should == true }
    its(:to_s) { should == decl_string }
    its(:to_str) { should == decl_string }
    its(:to_a) { should == decl_array }
    its(:inspect) { should == %Q(#<Agio::XMLDecl '#{decl_string}'>) }

    it "should equality-compare with a String transitively" do
      decl_string.should == subject
      decl_string.upcase.should_not == subject

      subject.should == decl_string
      subject.should_not == decl_string.upcase
    end

    it "should compare with an Array" do
      subject.should == decl_array
    end

    it "should compare with another Agio::XMLDecl" do
      subject.should == Agio::XMLDecl.new(:standalone => true)
    end
  end

  context "constructed with version and encoding" do
    let(:decl_string) { %Q(<?xml version="1.0" encoding="UTF-8" ?>) }
    let(:decl_array) { [ "1.0", "UTF-8", nil ] }

    subject { Agio::XMLDecl.new(:version => "1.0", :encoding => "UTF-8") }

    its(:version) { should == "1.0" }
    its(:encoding) { should == "UTF-8" }
    its(:standalone) { should be_nil }
    its(:to_s) { should == decl_string }
    its(:to_str) { should == decl_string }
    its(:to_a) { should == decl_array }
    its(:inspect) { should == %Q(#<Agio::XMLDecl '#{decl_string}'>) }

    it "should equality-compare with a String transitively" do
      decl_string.should == subject
      decl_string.upcase.should_not == subject

      subject.should == decl_string
      subject.should_not == decl_string.upcase
    end

    it "should compare with an Array" do
      subject.should == decl_array
    end

    it "should compare with another Agio::XMLDecl" do
      subject.should ==
        Agio::XMLDecl.new(:version => "1.0", :encoding => "UTF-8")
    end
  end

  context "constructed with version and standalone" do
    let(:decl_string) { %Q(<?xml version="1.0" standalone="false" ?>) }
    let(:decl_array) { [ "1.0", nil, false ] }

    subject { Agio::XMLDecl.new(:version => "1.0", :standalone => false) }

    its(:version) { should == "1.0" }
    its(:encoding) { should be_nil }
    its(:standalone) { should == false }
    its(:to_s) { should == decl_string }
    its(:to_str) { should == decl_string }
    its(:to_a) { should == decl_array }
    its(:inspect) { should == %Q(#<Agio::XMLDecl '#{decl_string}'>) }

    it "should equality-compare with a String transitively" do
      decl_string.should == subject
      decl_string.upcase.should_not == subject

      subject.should == decl_string
      subject.should_not == decl_string.upcase
    end

    it "should compare with an Array" do
      subject.should == decl_array
    end

    it "should compare with another Agio::XMLDecl" do
      subject.should ==
        Agio::XMLDecl.new(:version => "1.0", :standalone => false)
    end
  end

  context "constructed with encoding and standalone" do
    let(:decl_string) { %Q(<?xml encoding="UTF-8" standalone="false" ?>) }
    let(:decl_array) { [ nil, "UTF-8", false ] }

    subject { Agio::XMLDecl.new(:encoding => "UTF-8", :standalone => false) }

    its(:version) { should be_nil }
    its(:encoding) { should == "UTF-8" }
    its(:standalone) { should == false }
    its(:to_s) { should == decl_string }
    its(:to_str) { should == decl_string }
    its(:to_a) { should == decl_array }
    its(:inspect) { should == %Q(#<Agio::XMLDecl '#{decl_string}'>) }

    it "should equality-compare with a String transitively" do
      decl_string.should == subject
      decl_string.upcase.should_not == subject

      subject.should == decl_string
      subject.should_not == decl_string.upcase
    end

    it "should compare with an Array" do
      subject.should == decl_array
    end

    it "should compare with another Agio::XMLDecl" do
      subject.should ==
        Agio::XMLDecl.new(:encoding => "UTF-8", :standalone => false)
    end
  end

  context "constructed with all values" do
    let(:decl_string) { %Q(<?xml version="1.0" encoding="UTF-8" standalone="false" ?>) }
    let(:decl_array) { [ "1.0", "UTF-8", false ] }

    subject { Agio::XMLDecl.new(:version => "1.0", :encoding => "UTF-8",
                                :standalone => false) }

    its(:version) { should == "1.0" }
    its(:encoding) { should == "UTF-8" }
    its(:standalone) { should == false }
    its(:to_s) { should == decl_string }
    its(:to_str) { should == decl_string }
    its(:to_a) { should == decl_array }
    its(:inspect) { should == %Q(#<Agio::XMLDecl '#{decl_string}'>) }

    it "should equality-compare with a String transitively" do
      decl_string.should == subject
      decl_string.upcase.should_not == subject

      subject.should == decl_string
      subject.should_not == decl_string.upcase
    end

    it "should compare with an Array" do
      subject.should == decl_array
    end

    it "should compare with another Agio::XMLDecl" do
      subject.should ==
        Agio::XMLDecl.new(:version => "1.0", :encoding => "UTF-8",
                          :standalone => false)
    end
  end
end

# vim: ft=ruby
