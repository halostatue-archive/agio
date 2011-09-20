# -*- ruby encoding: utf-8 -*-

require 'spec_helper'

describe Agio::Flags do
  subject {
    klass = Class.new
    klass.class_eval { extend Agio::Flags }
    klass
  }

  let(:meta) {
    class << subject
      self
    end
  }

  describe "basic 'extend'" do
    it "should inherit from Agio::Flags" do
      subject.ancestors.should include(Agio::Flags)
      subject.private_instance_methods.should include("reset_flags")
    end

    it "should be extended by Agio::Flags::ClassMethods" do
      meta.ancestors.should include(Agio::Flags::ClassMethods)

      methods = subject.public_methods

      methods.should include("flag_builder")
      methods.should include("string_flag")
      methods.should include("boolean_flag")
      methods.should include("integer_flag")
      methods.should include("hash_flag")
      methods.should include("flag_inits")
      methods.should include("public_flag_inits")
      methods.should include("flags")
    end
  end

  describe "duplicate prevention" do
    before(:each) do
      subject.class_eval do
        string_flag :my_string, :default => 'xyz', :private => true
      end
    end

    it "should raise a SyntaxError if defined again" do
      expect do
        subject.class_eval do
          string_flag :my_string, :default => 'xyz', :private => false
        end
      end.to raise_error(SyntaxError, /already defined/)
    end
  end

  describe "string_flag :my_string, :default => 'xyz', :public => false" do
    $xyz = 'xyz'

    before(:each) do
      subject.class_eval do
        string_flag :my_string, :default => $xyz, :public => false
      end
    end

    it "should have new string_flag methods" do
      pim = subject.private_instance_methods
      pim.should include("init_my_string")
      pim.should include("my_string")
      pim.should include("set_my_string")
      pim.should include("my_string?")

      subject.flag_inits.should include(:init_my_string)

      subject.flags[:my_string].should == {
        :ivar     => "@flag_my_string",
        :init     => :init_my_string,
        :getter   => :my_string,
        :setter   => :set_my_string,
        :tester   => :my_string?,
        :public   => false,
        :type     => :string,
        :default  => subject.flags[:my_string][:default],
      }
    end

    context "object instance" do
      let(:obj) { subject.new }

      def call(method, *args)
        obj.__send__(method, *args)
      end

      it "should create and set the instance variable when #reset_flags is called" do
        obj.instance_variables.should_not include("@flag_my_string")
        call(:reset_flags)
        obj.instance_variables.should include("@flag_my_string")
        obj.instance_variable_get("@flag_my_string").should == $xyz
        obj.instance_variable_get("@flag_my_string").should_not equal($xyz)
      end

      it "#set_my_string should set the value as a string" do
        call(:set_my_string, 'foo')
        call(:my_string).should == 'foo'

        call(:set_my_string, 3)
        call(:my_string).should == "3"
      end

      it "#set_my_string should clear the value if provided nil" do
        call(:set_my_string, 'foo')
        call(:my_string).should == 'foo'

        call(:set_my_string, nil)
        call(:my_string).should be_nil
      end

      it "#my_string? should return false if the value is nil" do
        call(:set_my_string, nil)
        call(:my_string?).should == false
      end

      it "#my_string? should return false if the value is empty" do
        call(:set_my_string, "")
        call(:my_string?).should == false
      end

      it "#my_string? should return true if the value is not nil or empty" do
        call(:set_my_string, "foo")
        call(:my_string?).should == true
      end
    end
  end

  describe "boolean_flag :my_boolean, :public => true" do
    before(:each) do
      subject.class_eval do
        boolean_flag :my_bool, :public => true
      end
    end

    it "should have new boolean_flag methods" do
      subject.private_instance_methods.should include("init_my_bool")

      pim = subject.public_instance_methods
      pim.should include("my_bool")
      pim.should include("my_bool=")
      pim.should include("my_bool?")

      subject.public_flag_inits.should include(:init_my_bool)

      subject.flags[:my_bool].should == {
        :ivar     => "@flag_my_bool",
        :init     => :init_my_bool,
        :getter   => :my_bool,
        :setter   => :my_bool=,
        :tester   => :my_bool?,
        :public   => true,
        :type     => :boolean,
        :default  => false,
      }
    end

    context "object instance" do
      let(:obj) { subject.new }

      def call(method, *args)
        obj.__send__(method, *args)
      end

      it "should do nothing when #reset_flags is called" do
        obj.instance_variables.should_not include("@flag_my_bool")
        call(:reset_flags)
        obj.instance_variables.should_not include("@flag_my_bool")
      end

      it "should create and set the instance variable when #reset_flags(true) is called" do
        obj.instance_variables.should_not include("@flag_my_bool")
        call(:reset_flags, true)
        obj.instance_variables.should include("@flag_my_bool")
        obj.instance_variable_get("@flag_my_bool").should == false
      end

      it "#my_bool= should set the value as a Boolean value" do
        obj.my_bool = 'foo'
        obj.my_bool.should == true

        obj.my_bool = 3
        obj.my_bool.should == true

        obj.my_bool = nil
        obj.my_bool.should == false

        obj.my_bool = false
        obj.my_bool.should == false
      end

      it "#my_bool? and #my_bool should return the same value" do
        obj.my_bool = 'foo'
        obj.my_bool.should == obj.my_bool?

        obj.my_bool = false
        obj.my_bool.should == obj.my_bool?
      end
    end
  end

  describe "integer_flag :my_integer, :default => 42, :public => false" do
    before(:each) do
      subject.class_eval do
        integer_flag :my_integer, :default => 42, :public => false
      end
    end

    it "should have new integer_flag methods" do
      pim = subject.private_instance_methods
      pim.should include("init_my_integer")
      pim.should include("my_integer")
      pim.should include("set_my_integer")
      pim.should include("my_integer?")
      pim.should include("incr_my_integer")
      pim.should include("decr_my_integer")

      subject.flag_inits.should include(:init_my_integer)

      subject.flags[:my_integer].should == {
        :ivar     => "@flag_my_integer",
        :init     => :init_my_integer,
        :getter   => :my_integer,
        :setter   => :set_my_integer,
        :tester   => :my_integer?,
        :public   => false,
        :type     => :integer,
        :default  => 42,
      }
    end

    context "object instance" do
      let(:obj) { subject.new }

      def call(method, *args)
        obj.__send__(method, *args)
      end

      it "should create and set the instance variable when #reset_flags is called" do
        obj.instance_variables.should_not include("@flag_my_integer")
        call(:reset_flags)
        obj.instance_variables.should include("@flag_my_integer")
        obj.instance_variable_get("@flag_my_integer").should == 42
      end

      it "#set_my_integer should set the value as a integer" do
        call(:set_my_integer, 'foo')
        call(:my_integer).should == 0

        call(:set_my_integer, 3)
        call(:my_integer).should == 3

        call(:set_my_integer, 3.5)
        call(:my_integer).should == 3

        call(:set_my_integer, nil)
        call(:my_integer).should == 0
      end

      it "#my_integer? should return nil if the value is zero" do
        call(:set_my_integer, nil)
        call(:my_integer?).should == nil
      end

      it "#my_integer? should return the value if the value is non-zero" do
        call(:reset_flags)
        call(:my_integer?).should == call(:my_integer)
      end

      it "#incr_my_integer should increment the integer by the provided value" do
        call(:reset_flags)
        call(:my_integer).should == 42

        call(:incr_my_integer, 3)
        call(:my_integer).should == 45
      end

      it "#decr_my_integer should decrement the integer by the provided value" do
        call(:reset_flags)
        call(:my_integer).should == 42

        call(:decr_my_integer, 3)
        call(:my_integer).should == 39
      end
    end
  end

  describe "array_flag :my_array" do
    before(:each) do
      subject.class_eval do
        array_flag :my_array
      end
    end

    it "should have new array_flag methods" do
      pim = subject.private_instance_methods
      pim.should include("init_my_array")
      pim.should include("my_array")
      pim.should include("set_my_array")
      pim.should include("my_array?")

      subject.flag_inits.should include(:init_my_array)

      subject.flags[:my_array].should == {
        :ivar     => "@flag_my_array",
        :init     => :init_my_array,
        :getter   => :my_array,
        :setter   => :set_my_array,
        :tester   => :my_array?,
        :public   => nil,
        :type     => :array,
        :default  => subject.flags[:my_array][:default],
      }
    end

    context "object instance" do
      let(:obj) { subject.new }

      def call(method, *args)
        obj.__send__(method, *args)
      end

      it "should create and set the instance variable when #reset_flags is called" do
        obj.instance_variables.should_not include("@flag_my_array")
        call(:reset_flags)
        obj.instance_variables.should include("@flag_my_array")
        obj.instance_variable_get("@flag_my_array").should == []
      end

      it "should not make the same default array over two #reset_flags calls" do
        call(:reset_flags)
        x = obj.instance_variable_get("@flag_my_array")

        call(:reset_flags)
        obj.instance_variable_get("@flag_my_array").should == x
        obj.instance_variable_get("@flag_my_array").should_not equal(x)
      end

      it "#set_my_array should set the value as a array" do
        call(:set_my_array, nil)
        call(:my_array).should be_nil

        call(:set_my_array, 3)
        call(:my_array).should == [ 3 ]

        call(:set_my_array, 3.5)
        call(:my_array).should == [ 3.5 ]

        call(:set_my_array, %W(a b c))
        call(:my_array).should == %W(a b c)
      end

      it "#set_my_array should clear the value if provided nil" do
        call(:set_my_array, 'foo')
        call(:my_array).should == [ 'foo' ]

        call(:set_my_array, nil)
        call(:my_array).should be_nil
      end

      it "#my_array? should return false if the value is empty or nil" do
        call(:set_my_array, nil)
        call(:my_array?).should == false

        call(:set_my_array, [])
        call(:my_array?).should == false
      end

      it "#my_array? should return true if the value is not empty" do
        call(:set_my_array, %W(a b c))
        call(:my_array?).should == true
      end
    end
  end

  describe "hash_flag :my_hash" do
    before(:each) do
      subject.class_eval do
        hash_flag :my_hash
      end
    end

    it "should have new hash_flag methods" do
      pim = subject.private_instance_methods
      pim.should include("init_my_hash")
      pim.should include("my_hash")
      pim.should include("set_my_hash")
      pim.should include("my_hash?")

      subject.flag_inits.should include(:init_my_hash)

      subject.flags[:my_hash].should == {
        :ivar     => "@flag_my_hash",
        :init     => :init_my_hash,
        :getter   => :my_hash,
        :setter   => :set_my_hash,
        :tester   => :my_hash?,
        :public   => nil,
        :type     => :hash,
        :default  => subject.flags[:my_hash][:default],
      }
    end

    context "object instance" do
      let(:obj) { subject.new }
      let(:hash) do
        { :a => 1, :b => 2 }
      end

      def call(method, *args)
        obj.__send__(method, *args)
      end

      it "should create and set the instance variable when #reset_flags is called" do
        obj.instance_variables.should_not include("@flag_my_hash")
        call(:reset_flags)
        obj.instance_variables.should include("@flag_my_hash")
        obj.instance_variable_get("@flag_my_hash").should == {}
      end

      it "should not make the same default hash over two #reset_flags calls" do
        call(:reset_flags)
        x = obj.instance_variable_get("@flag_my_hash")

        call(:reset_flags)
        obj.instance_variable_get("@flag_my_hash").should == x
        obj.instance_variable_get("@flag_my_hash").should_not equal(x)
      end

      it "#set_my_hash should set the value as a hash" do
        call(:set_my_hash, nil)
        call(:my_hash).should be_nil

        call(:set_my_hash, { :a => 1, :b => 2 })
        call(:my_hash).should == { :a => 1, :b => 2 }
      end

      it "#set_my_hash will raise an ArgumentError if not provided nil or a Hash" do
        expect {
          call(:set_my_hash, 3)
        }.to raise_error(ArgumentError)
      end

      it "#set_my_hash should clear the value if provided nil" do
        call(:set_my_hash, hash)
        call(:my_hash).should == hash

        call(:set_my_hash, nil)
        call(:my_hash).should be_nil
      end

      it "#my_hash? should return false if the value is empty or nil" do
        call(:set_my_hash, nil)
        call(:my_hash?).should == false

        call(:set_my_hash, {})
        call(:my_hash?).should == false
      end

      it "#my_hash? should return true if the value is not empty" do
        call(:set_my_hash, hash)
        call(:my_hash?).should == true
      end
    end
  end
end

# vim: ft=ruby
