# -*- ruby encoding: utf-8 -*-

require 'spec_helper'

describe Agio::Broker do
  # We need to be able to inspect the status of the Agio::Broker during
  # testing (#stack), and we need to test some otherwise private methods
  # (#push, #pop).
  before do
    PrivateMethodHandler.remove(Agio::Broker)
  end

  after do
    PrivateMethodHandler.restore(Agio::Broker)
  end

  subject { Agio::Broker.new }

  context "when first created" do
    its(:blocks) { should be_empty }
    its(:stack) { should be_empty }
    its(:errors) { should be_empty }
    its(:warnings) { should be_empty }
  end

  specify "#push should fail on non Agio::Data or Agio::Block objects" do
    expect { subject.push(nil) }.to raise_error(ArgumentError)
    expect { subject.push(1) }.to raise_error(ArgumentError)
  end

  context "#push with Data objects" do
    let(:p_block) { Agio::Block.new('p') }
    let(:data_result) {
      p_block.append(Agio::Data.new('test'))
      p_block
    }
    let(:cdata_result) {
      p_block.append(Agio::CData.new('test'))
      p_block
    }
    let(:comment_result) {
      p_block.append(Agio::Comment.new('test'))
      p_block
    }
    let(:xmldecl_result) {
      p_block.append(Agio::XMLDecl.new('test'))
      p_block
    }

    it "should push an Agio::Block('p') on the stack if one does not exist" do
      subject.push(Agio::Data.new('test'))
      subject.blocks.should be_empty
      subject.stack.should_not be_empty
      subject.stack.size.should == 1
      subject.stack.first.should == data_result
      subject.stack.first.contents.first.class.should == Agio::Data
    end

    it "should create an Agio::Data object with a String argument" do
      subject.push('test')
      subject.blocks.should be_empty
      subject.stack.should_not be_empty
      subject.stack.size.should == 1
      subject.stack.first.should == data_result
      subject.stack.first.contents.first.class.should == Agio::Data
    end

    it "should accept an Agio::CData object" do
      subject.push(Agio::CData.new('test'))
      subject.blocks.should be_empty
      subject.stack.should_not be_empty
      subject.stack.size.should == 1
      subject.stack.first.should == cdata_result
      subject.stack.first.contents.first.class.should == Agio::CData
    end

    it "should accept an Agio::Comment object" do
      subject.push(Agio::Comment.new('test'))
      subject.blocks.should be_empty
      subject.stack.should_not be_empty
      subject.stack.size.should == 1
      subject.stack.first.should == cdata_result
      subject.stack.first.contents.first.class.should == Agio::Comment
    end

    it "should accept an Agio::XMLDecl object" do
      subject.push(Agio::XMLDecl.new('test'))
      subject.blocks.should be_empty
      subject.stack.should_not be_empty
      subject.stack.size.should == 1
      subject.stack.first.should == cdata_result
      subject.stack.first.contents.first.class.should == Agio::XMLDecl
    end
  end
end

# vim: ft=ruby
