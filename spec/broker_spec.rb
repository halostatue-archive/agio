# -*- ruby encoding: utf-8 -*-

require 'spec_helper'

describe Agio::Broker do
  # We need to be able to inspect the status of the Agio::Broker during
  # testing (#stack), and we need to test some otherwise private methods
  # (#push, #pop).
  before { PrivateMethodHandler.remove(Agio::Broker) }
  after { PrivateMethodHandler.restore(Agio::Broker) }
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

  context "#push with Agio::Data objects" do
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
      subject.stack.first.should == comment_result
      subject.stack.first.contents.first.class.should == Agio::Comment
    end

    it "should accept an Agio::XMLDecl object" do
      subject.push(Agio::XMLDecl.new('test'))
      subject.blocks.should_not be_empty
      subject.blocks.size.should == 1
      subject.blocks.first.should == Agio::XMLDecl.new('test')
      subject.stack.should be_empty
    end
  end

  def B(tag, options = {})
    Agio::Block.new(tag, options)
  end

  context "push with Agio::Block objects" do
    it "should ignore <html> blocks" do
      result = subject.push(B('html'))
      result.should be_nil
      subject.blocks.should be_empty
      subject.stack.should be_empty
    end

    context "with <head> and <body> blocks" do
      before(:each) { subject.push(B('head')) }

      it "should accept a <head> block" do
        subject.blocks.should be_empty
        subject.stack.should == [ B('head') ]
      end

      it "should pop a <head> block but otherwise ignore a <body> block." do
        result = subject.push(B('body'))
        result.should be_nil
        subject.blocks.should == [ B('head') ]
        subject.stack.should be_empty
      end
    end

    context "when the stack is empty" do
      it "should push an implied <ul> when receiving a <li>" do
        result = subject.push(B('li'))
        result.should == B('li')
        subject.blocks.should be_empty
        subject.stack.should == [ B('ul'), B('li') ]
      end

      it "should push an implied <dl> when receiving a <dt>" do
        result = subject.push(B('dt'))
        result.should == B('dt')
        subject.blocks.should be_empty
        subject.stack.should == [ B('dl'), B('dt') ]
      end

      it "should push an implied <dl> when receiving a <dd>" do
        result = subject.push(B('dd'))
        result.should == B('dd')
        subject.blocks.should be_empty
        subject.stack.should == [ B('dl'), B('dd') ]
      end

      it "should push an implied <p> when receiving an inline block" do
        result = subject.push(B('em'))
        result.should == B('em')
        subject.blocks.should be_empty
        subject.stack.should == [ B('p'), B('em') ]

        subject.stack.clear
        subject.stack.should be_empty
        result = subject.push(B('span'))
        result.should == B('span')
        subject.blocks.should be_empty
        subject.stack.should == [ B('p'), B('span') ]
      end

      it "should push a <div> directly" do
        result = subject.push(B('div'))
        result.should == B('div')
        subject.blocks.should be_empty
        subject.stack.should == [ B('div') ]
      end

      it "should push a <blockquote> directly" do
        result = subject.push(B('blockquote'))
        result.should == B('blockquote')
        subject.blocks.should be_empty
        subject.stack.should == [ B('blockquote') ]
      end
    end

    context "when the stack has a <dl> block" do
      before(:each) { subject.push(B('dl')) }

      it "should append a <dt>" do
        subject.push(B('dt'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('dl'), B('dt') ]
      end

      it "should append a <dd>" do
        subject.push(B('dd'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('dl'), B('dd') ]
      end

      it "should shift and reset the stack when receiving a <p>" do
        subject.push(B('p'))
        subject.blocks.should == [ B('dl') ]
        subject.stack.should == [ B('p') ]
      end
    end

    context "when the stack has a <ol> block" do
      before(:each) { subject.push(B('ol')) }

      it "should append a <li>" do
        subject.push(B('li'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('ol'), B('li') ]
      end

      it "should shift and reset the stack when receiving a <p>" do
        subject.push(B('p'))
        subject.blocks.should == [ B('ol') ]
        subject.stack.should == [ B('p') ]
      end
    end

    context "when the stack has a <ul> block" do
      before(:each) { subject.push(B('ul')) }

      it "should append a <li>" do
        subject.push(B('li'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('ul'), B('li') ]
      end

      it "should shift and reset the stack when receiving a <p>" do
        subject.push(B('p'))
        subject.blocks.should == [ B('ul') ]
        subject.stack.should == [ B('p') ]
      end
    end

    context "when the stack has a <p> block" do
      before(:each) { subject.push(B('p')) }

      it "should append an inline element like <em>" do
        subject.push(B('em'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('p'), B('em') ]
      end

      it "should shift and reset the stack with another <p>" do
        subject.push(B('p'))
        subject.blocks.should == [ B('p') ]
        subject.stack.should == [ B('p') ]
      end

      it "should shift and reset the stack with a <div>" do
        subject.push(B('div'))
        subject.blocks.should == [ B('p') ]
        subject.stack.should == [ B('div') ]
      end

      it "should shift and reset the stack with a <blockquote>" do
        subject.push(B('blockquote'))
        subject.blocks.should == [ B('p') ]
        subject.stack.should == [ B('blockquote') ]
      end

      it "should shift and reset the stack with a <ol>" do
        subject.push(B('ol'))
        subject.blocks.should == [ B('p') ]
        subject.stack.should == [ B('ol') ]
      end

      it "should shift and reset the stack with a <li>, imploying a <ul>" do
        subject.push(B('li'))
        subject.blocks.should == [ B('p') ]
        subject.stack.should == [ B('ul'), B('li') ]
      end
    end

    context "when the stack has a <div> block" do
      before(:each) { subject.push(B('div')) }

      it "should append an inline element like <em>" do
        subject.push(B('em'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('div'), B('em') ]
      end

      it "should append a <p>" do
        subject.push(B('p'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('div'), B('p') ]
      end

      it "should append a <div>" do
        subject.push(B('div'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('div'), B('div') ]
      end

      it "should append a <blockquote>" do
        subject.push(B('blockquote'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('div'), B('blockquote') ]
      end

      it "should append a <ol>" do
        subject.push(B('ol'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('div'), B('ol') ]
      end

      it "should append a <li>, imploying a <ul>" do
        subject.push(B('li'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('div'), B('ul'), B('li') ]
      end
    end

    context "when the stack has a <blockquote> block" do
      before(:each) { subject.push(B('blockquote')) }

      it "should append an inline element like <em>" do
        subject.push(B('em'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('blockquote'), B('em') ]
      end

      it "should append a <p>" do
        subject.push(B('p'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('blockquote'), B('p') ]
      end

      it "should append a <div>" do
        subject.push(B('div'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('blockquote'), B('div') ]
      end

      it "should append another <blockquote>" do
        subject.push(B('blockquote'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('blockquote'), B('blockquote') ]
      end

      it "should append an <ol>" do
        subject.push(B('ol'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('blockquote'), B('ol') ]
      end

      it "should append a <li>, imploying a <ul>" do
        subject.push(B('li'))
        subject.blocks.should be_empty
        subject.stack.should == [ B('blockquote'), B('ul'), B('li') ]
      end
    end
  end

  context "pop the Agio::Block stack" do
    let(:em) {
      r = B('em')
      r.append(Agio::Data.new('text'))
      r
    }
    let(:div) {
      r = B('div')
      r.append(em)
      r
    }

    it "should return nil if the stack is empty." do
      subject.stack.should be_empty
      subject.pop.should == nil
    end

    it "should move a Block to the blocks when there's one item on the stack" do
      subject.push(B('p'))
      subject.pop.should == B('p')
      subject.stack.should be_empty
      subject.blocks.should == [ B('p') ]
    end

    it "should append a Block to the top of the stack when there's more than one item on the stack" do
      subject.push(B('div'))
      subject.push(B('em'))
      subject.push('text')
      subject.stack.should == [ B('div'), em ]
      subject.pop.should == em

      subject.blocks.should be_empty
      subject.stack.should == [ div ]
      subject.stack[-1].contents.should == [ em ]
    end

    it "should pop to the named block when a name is given" do
      subject.push(B('div'))
      subject.push(B('em'))
      subject.push('text')
      subject.stack.should == [ B('div'), em ]
      subject.pop('div').should == div

      subject.blocks.should == [ div ]
      subject.stack.should be_empty
    end

    it "should pop the whole stack if a name can't be found" do
      subject.push(B('div'))
      subject.push(B('em'))
      subject.push('text')
      subject.stack.should == [ B('div'), em ]
      subject.pop('p').should == div

      subject.blocks.should == [ div ]
      subject.stack.should be_empty
    end
  end

  context "methods inherited from Nokogiri::XML::SAX::Document" do
    let(:cdata) { Agio::CData.new('cdata') }
    let(:comment) { Agio::CData.new('comment') }
    let(:data) { Agio::Data.new('data') }
    let(:div) { B('div') }
    let(:em) { B('em') }
    let(:nem) { B('em', :prefix => 'n', :uri => 'x:y') }
    let(:xml) {
      Agio::XMLDecl.new(:version => "1.0", :encoding => "UTF-8",
                        :standalone => false)
    }

    before(:each) { subject.push(div) }

    it "should push an Agio::CData block when #cdata_block is called" do
      div.append(cdata)
      subject.cdata_block("cdata")
      subject.blocks.should be_empty
      subject.stack.should == [ div ]
    end

    it "should push an Agio::Data block when #characters is called" do
      div.append(data)
      subject.characters("data")
      subject.blocks.should be_empty
      subject.stack.should == [ div ]
    end

    it "should push an Agio::Comment block when #comment is called" do
      div.append(comment)
      subject.comment("data")
      subject.blocks.should be_empty
      subject.stack.should == [ div ]
    end

    it "should clear the stack when #end_document is called" do
      div.append(data)
      subject.characters('data')

      subject.blocks.should be_empty
      subject.stack.should == [ div ]

      subject.end_document
      subject.blocks.should == [ div ]
      subject.stack.should be_empty
    end

    it "should pop the named element when #end_element is called" do
      em.append(data)

      subject.push(B('em'))
      subject.characters('data')

      subject.blocks.should be_empty
      subject.stack.should == [ div, em ]

      div.append(em)
      subject.end_element('em')
      subject.blocks.should be_empty
      subject.stack.should == [ div ]

      subject.end_element('div')
      subject.blocks.should == [ div ]
      subject.stack.should be_empty
    end

    it "should pop the named element with namespace when #end_element_namespace is called" do
      em.append(data.dup)
      nem.append(data.dup)

      subject.push(B('em', :prefix => 'n', :uri => 'x:y'))
      subject.characters('data')
      subject.push(B('em'))
      subject.characters('data')

      subject.blocks.should be_empty
      subject.stack.should == [ div, nem, em ]

      div.append(nem)
      div.append(em)

      subject.end_element_namespace('em', 'n', 'x:y')
      subject.blocks.should be_empty
      subject.stack.should == [ div ]

      subject.end_element('div')
      subject.blocks.should == [ div ]
      subject.stack.should be_empty
    end

    it "should add to the #errors array when #error is called" do
      subject.error("foo")
      subject.errors.should == [ "foo" ]
    end

    it "should clear the stack when #end_document is called" do
      div.append(data)
      subject.characters('data')

      subject.blocks.should be_empty
      subject.stack.should == [ div ]

      subject.start_document
      subject.blocks.should == [ div ]
      subject.stack.should be_empty
    end

    it "should push a new Agio::Block when #start_element is called" do
      subject.start_element('div')
      subject.blocks.should be_empty
      subject.stack.should == [ div, div ]
    end

    it "should push a new Agio::Block when #start_element_namespace is called" do
      div.options[:attrs] = []
      div.options[:prefix] = 'n'
      div.options[:uri] = 'x:y'
      div.options[:ns] = []

      subject.start_element_namespace('div', [], 'n', 'x:y')
      subject.blocks.should be_empty
      subject.stack.should == [ div, div ]
    end

    it "should add to the #warnings array when #warning is called" do
      subject.warning("foo")
      subject.warnings.should == [ "foo" ]
    end

    it "should push an XML declaration" do
      subject.xmldecl("1.0", "UTF-8", false)
      subject.blocks.should == [ xml ]
      subject.stack.should == [ div ]
    end
  end
end

# vim: ft=ruby
