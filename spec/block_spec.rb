# -*- ruby encoding: utf-8 -*-

require 'spec_helper'

describe Agio::Block do
  context "Block construction" do
    it "should throw an exception if a name is not provided" do
      expect { Agio::Block.new }.to raise_error(ArgumentError)
    end

    it "should work with standard HTML elements like 'li'" do
      block = nil
      expect { block = Agio::Block.new('li') }.to_not raise_error
      block.name.should == 'li'
      block.options.should be_empty
      block.contents.should be_empty
      block.description.should_not be_nil
    end

    it "should work with non-standard elements like 'block'" do
      block = nil
      expect { block = Agio::Block.new('block') }.to_not raise_error
      block.name.should == 'block'
      block.options.should be_empty
      block.contents.should be_empty
      block.description.should be_nil
    end

    it "should accept an options hash" do
      block = nil
      expect { block = Agio::Block.new('li', :x => :y) }.to_not raise_error
      block.name.should == 'li'
      block.options.should == { :x => :y }
      block.contents.should be_empty
      block.description.should_not be_nil
    end
  end

  context "calling #append" do
    subject { Agio::Block.new('li') }

    it "should append one object given as a parameter" do
      expect { subject.append(1) }.to_not raise_error
      subject.contents.should == [ 1 ]
    end

    it "should append multiple objects given as parameters" do
      expect { subject.append(1, 2) }.to_not raise_error
      subject.contents.should == [ 1, 2 ]
    end
  end

  describe "should understand the elements represented by the Block" do
    describe "HTML standard block element <p>" do
      subject { Agio::Block.new('p') }

      its(:name) { should == 'p' }
      its(:description) { subject.to_s.should =~ /p:\s+paragraph/ }

      its(:standard?) { should == true }
      its(:inline?) { should == false }
      its(:block?) { should == true }
      its(:li?) { should == false }
      its(:pre?) { should == false }
      its(:ul_ol?) { should == false }
      its(:definition?) { should == false }
      its(:dl?) { should == false }

      it "should not be able to contain a <p>" do
        subject.can_contain?(Agio::Block.new('p')).should == false
      end

      it "should be able to contain an <em>" do
        subject.can_contain?(Agio::Block.new('em')).should == true
      end

      it "should not be able to contain a <li>" do
        subject.can_contain?(Agio::Block.new('li')).should == false
      end

      it "is a sibling of a <p>" do
        subject.sibling_of?(Agio::Block.new('p')).should == true
      end

      it "is not a sibling of a <blockquote>" do
        subject.sibling_of?(Agio::Block.new('blockquote')).should == false
      end
    end

    describe "HTML standard block element <ol>" do
      subject { Agio::Block.new('ol') }

      its(:name) { should == 'ol' }
      its(:description) { subject.to_s.should =~ /ol:\s+ordered list/ }

      its(:standard?) { should == true }
      its(:inline?) { should == false }
      its(:block?) { should == true }
      its(:li?) { should == false }
      its(:pre?) { should == false }
      its(:ul_ol?) { should == true }
      its(:definition?) { should == false }
      its(:dl?) { should == false }

      it "should not be able to contain a <p>" do
        subject.can_contain?(Agio::Block.new('p')).should == false
      end

      it "should not be able to contain an <em>" do
        subject.can_contain?(Agio::Block.new('em')).should == false
      end

      it "should be able to contain a <li>" do
        subject.can_contain?(Agio::Block.new('li')).should == true
      end

      it "is a sibling of an <ol>" do
        subject.sibling_of?(Agio::Block.new('ol')).should == true
      end

      it "is not a sibling of a <blockquote>" do
        subject.sibling_of?(Agio::Block.new('blockquote')).should == false
      end
    end

    describe "HTML standard inline element <em>" do
      subject { Agio::Block.new('em') }

      its(:name) { should == 'em' }
      its(:description) { subject.to_s.should =~ /em:\s+emphasis/ }

      its(:standard?) { should == true }
      its(:inline?) { should == true }
      its(:block?) { should == false }
      its(:li?) { should == false }
      its(:pre?) { should == false }
      its(:ul_ol?) { should == false }
      its(:definition?) { should == false }
      its(:dl?) { should == false }

      it "should not be able to contain a <p>" do
        subject.can_contain?(Agio::Block.new('p')).should == false
      end

      it "should be able to contain an <em>" do
        subject.can_contain?(Agio::Block.new('em')).should == true
      end

      it "should not be able to contain a <li>" do
        subject.can_contain?(Agio::Block.new('li')).should == false
      end

      it "is not a sibling of an <em>" do
        subject.sibling_of?(Agio::Block.new('em')).should == false
      end

      it "is not a sibling of a <blockquote>" do
        subject.sibling_of?(Agio::Block.new('blockquote')).should == false
      end
    end
  end
end

# vim: ft=ruby
