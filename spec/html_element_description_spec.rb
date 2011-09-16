# -*- ruby encoding: utf-8 -*-

require 'spec_helper'

describe Agio::HTMLElementDescription do
  context "HTML block elements like 'p'" do
    subject { Agio::HTMLElementDescription['p'] }

    its(:name) { should == 'p' }
    its(:to_s) { should =~ /p:\s+paragraph/ }
    its(:inspect) { should =~ %r{#<.*ElementDescription:\s+p\s+paragraph\s*>} }
    its(:block?) { should == true }
    its(:inline?) { should == false }
    its(:sub_elements) { should include('em', 'small') }
    its(:sub_elements) { should_not include('p') }
    its(:empty?) { should == false }
    its(:implied_start_tag?) { should == false }
    its(:implied_end_tag?) { should == true }
    its(:save_end_tag?) { should == false }
    its(:deprecated?) { should == false }
    its(:description) { should =~ /paragraph/ }
    its(:default_sub_element) { should be_nil }
    its(:optional_attributes) { should include("id", "class", "style") }
    its(:deprecated_attributes) { should include("align") }
    its(:required_attributes) { should be_empty }
  end

  context "HTML inline elements like 'em'" do
    subject { Agio::HTMLElementDescription['em'] }

    its(:name) { should == 'em' }
    its(:to_s) { should =~ /em:\s+emphasis/ }
    its(:inspect) { should =~ %r{#<.*ElementDescription:\s+em\s+emphasis\s*>} }
    its(:block?) { should == false }
    its(:inline?) { should == true }
    its(:sub_elements) { should include('em', 'small') }
    its(:sub_elements) { should_not include('p') }
    its(:empty?) { should == false }
    its(:implied_start_tag?) { should == false }
    its(:implied_end_tag?) { should == true }
    its(:save_end_tag?) { should == false }
    its(:deprecated?) { should == false }
    its(:description) { should =~ /emphasis/ }
    its(:default_sub_element) { should be_nil }
    its(:optional_attributes) { should include("id", "class", "style") }
    its(:deprecated_attributes) { should be_empty }
    its(:required_attributes) { should be_empty }
  end
end

# vim: ft=ruby

