# -*- ruby encoding: utf-8 -*-

require 'spec_helper'

describe PrivateMethodHandler do
  subject do
    klass = Class.new
    klass.class_eval {
      def foo; end
      private :foo
    }
    klass
  end

  it "should remove private methods properly" do
    subject.private_instance_methods(false).should == [ "foo" ]
    PrivateMethodHandler.remove(subject)
    subject.private_instance_methods(false).should == [ ]
  end

  it "should restore private methods when finished" do
    subject.private_instance_methods(false).should == [ "foo" ]
    PrivateMethodHandler.remove(subject)
    subject.private_instance_methods(false).should == [ ]
    PrivateMethodHandler.restore(subject)
    subject.private_instance_methods(false).should == [ "foo" ]
  end
end

# vim: ft=ruby

