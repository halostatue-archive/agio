# -*- ruby encoding: utf-8 -*-

##
# Meta-programming methods to help create and manage the flags used to help
# keep track of processing state for Agio.
module Agio::Flags
  ##
  # When <tt>extend Agio::Flags</tt> is specified in a class, this will
  # +extend+ the class methods with Agio::Flags::ClassMethods and +include+
  # Agio::Flags.
  def self.extend_object(object)
    object.extend ClassMethods
    object.__send__(:include, self)
  end

  ##
  # Resets the flags to their default state. If +with_public+ is +false+,
  # the default, only the internal flags will be reset to their initial
  # state. If +with_public+ is a +true+ value, flags that were initialized
  # with <tt>:public => true</tt> will also be reset.
  #
  # Calls the initializer methods created by the flag methods in
  # ClassMethods.
  def reset_flags(with_public = false)
    self.class.flag_inits { |init| __send__ init }
    self.class.public_flag_inits { |init| __send__ init } if with_public
  end
  private :reset_flags
end

##
# Meta-programming methods to help create flags and accessor and test
# methods for those flags.
module Agio::Flags::ClassMethods
  ##
  # Creates a flag. This method is the core method for building flags. Flags
  # must have a name and may specify one of two options, <tt>:default</tt>
  # or <tt>:public</tt>.
  #
  # flag_builder returns a Hash describing the flag.
  #
  # === Options
  # :default::  The default value for the flag. If not specified, or
  #             not overridden by one of the type helper methods, the
  #             default will be +nil+. If the default is not an immediate
  #             value, the default should be specified in a Proc, as is done
  #             for Array flags: <tt>lambda { [] }</tt>.
  # :public::   If +true+, indicates that the flag is internal and should
  #             not be exposed to the user. The default is that flags are
  #             private (e.g., <tt>:public => false</tt>).
  #
  # === Methods Defined
  # Four methods are always defined by +flag_builder+ or a type helper
  # method. The type helper methods mentioned below may override the default
  # behaviours described below.
  #
  # [Init]      "init_<em>name</em>". This is always private, and should
  #             only be called through Flags#reset_flags. Sets the value of
  #             the flag to the default value. If the default value returns
  #             to #call, it will be called to provide the default value.
  #             Uses the flag's Setter.
  # [Getter]    "name". Returns the value of the flag.
  # [Setter]    "set_<em>name</em>" if private or "<em>name</em>=" if
  #             public. Sets the flag to the provided value.
  # [Tester]    "<em>name</em>?" Returns +true+ or +false+ for the value
  #             with double negation (e.g., <tt>!!value</tt>).
  #
  # When calling flag_builder from a helper method, you can provide a block
  # that will allow the customization of the Setter or the Tester. The other
  # methods cannot be overridden.
  #
  # === Type Helper Methods
  #
  # There are five type helpers defined:
  #
  # [string_flag]   Creates a flag that works with String values. The
  #                 default value is +nil+, unless otherwise specified. If a
  #                 non-nil value is provided, the default value will be
  #                 wrapped in a Proc that will create a new String object
  #                 for every reset. The Setter converts all values (except
  #                 +nil+) to a String using #to_s. The Tester will return
  #                 +false+ if the value is +nil+ or the String is empty.
  # [boolean_flag]  Creates a flag that works with Boolean values (+true+ or
  #                 +false+). The default value for a boolean_flag is
  #                 +false+, unless otherwise specified. The Setter converts
  #                 all values to +true+ or +false+ through double negation
  #                 (e.g., <tt>!!value</tt>). The Tester forces the instance
  #                 variable to +true+ or +false+ through double negation.
  # [integer_flag]  Creates a flag that works with integer values. The
  #                 default value for an integer_flag is zero, unless
  #                 otherwise specified. The Setter converts all values to
  #                 integer with #to_i. The Tester returns +true+ if the
  #                 value is non-zero. Private integer flags also define two
  #                 additional methods, incr_<em>name</em> and
  #                 decr_<em>name</em>, that will increment or decrement the
  #                 integer value by the value provided.
  # [hash_flag]     Creates a flag that works with Hash values. The default
  #                 value is a lambda that creates an empty Hash. The Tester
  #                 returns +false+ if the value is +nil+ or the Hash is
  #                 empty.
  # [array_flag]    Creates a flag that works with Array values. The default
  #                 value is a lambda that creates an empty Array. The
  #                 Tester returns +false+ if the value is +nil+ or the
  #                 Array is empty.
  def flag_builder(name, options = {})
    raise "Flag #{name} already defined" if flags.has_key? name.to_sym

    default     = options[:default]
    type        = options[:type]
    is_public   = options[:public]

    flag = {
      :ivar     => "@flag_#{name}",
      :init     => "init_#{name}".to_sym,
      :getter   => name.to_sym,
      :setter   => (is_public ? "#{name}=" : "set_#{name}").to_sym,
      :tester   => "#{name}?".to_sym,
      :public   => is_public,
      :type     => type,
      :default  => default,
    }

    # Define the flag initializer
    define_method(flag[:init]) do
      value = if default.respond_to? :call
                default.call
              else
                default
              end
      __send__(flag[:setter], value)
    end
    private flag[:init]

    if is_public
      public_flag_inits << flag[:init]
    else
      flag_inits << flag[:init]
    end

    # Define the flag getter
    define_method(flag[:getter]) do
      instance_variable_get(flag[:ivar])
    end
    private flag[:getter] unless is_public

    # Define the flag setter
    defined = yield :setter, flag[:setter], flag[:ivar] if block_given?

    unless defined
      define_method(flag[:setter]) do |value|
        instance_variable_set(flag[:ivar], value)
      end
    end
    private flag[:setter] unless is_public

    # Define the flag tester
    defined = yield :tester, flag[:tester], flag[:ivar] if block_given?

    unless defined
      define_method(flag[:tester]) do
        !!instance_variable_get(ivar)
      end
    end
    private flag[:tester] unless is_public

    flags[name.to_sym] = flag
  end

  ##
  # Defines a flag optimized for working with strings.
  def string_flag(name, options = {})
    options = { :default => nil }.merge(options).merge(:type => :string)

    options[:default] = case options[:default]
                        when String
                          lambda { options[:default].dup }
                        when nil
                          nil
                        else
                          lambda { options[:default].to_s }
                        end

    flag_builder(name, options) do |type, meth, ivar|
      case type
      when :setter
        define_method(meth) do |value|
          value = value.to_s unless value.nil?
          instance_variable_set(ivar, value)
        end
      when :tester
        define_method(meth) do
          value = instance_variable_get(ivar)
          !(value.nil? or value.empty?)
        end
      end
    end
  end

  ##
  # Defines a flag optimized for working with Boolean (+true+ or +false+)
  # values.
  def boolean_flag(name, options = {})
    options = { :default => false }.merge(options).merge(:type => :boolean)
    flag_builder(name, options) do |type, meth, ivar|
      case type
      when :setter
        define_method(meth) do |value|
          instance_variable_set(ivar, !!value)
        end
      when :tester
        define_method(meth) do
          !!instance_variable_get(ivar)
        end
      end
    end
  end

  ##
  # Defines a flag optimized for working with integer values.
  def integer_flag(name, options = {})
    options = { :default => 0 }.merge(options).merge(:type => :integer)

    flag = flag_builder(name, options) do |type, meth, ivar|
      case type
      when :setter
        define_method(meth) do |value|
          instance_variable_set(ivar, value.to_i)
        end
      when :tester
        define_method(meth) do
          instance_variable_get(ivar).nonzero?
        end
      end
    end

    unless flag[:public]
      incr = "incr_#{name}".to_sym
      define_method(incr) do |value|
        value = instance_variable_get(flag[:ivar]) + value.to_i
        instance_variable_set(flag[:ivar], value)
      end
      private incr

      decr = "decr_#{name}".to_sym
      define_method(decr) do |value|
        value = instance_variable_get(flag[:ivar]) - value.to_i
        instance_variable_set(flag[:ivar], value)
      end
      private decr
    end
  end

  ##
  # Defines a flag optimized for working with arrays.
  def array_flag(name, options = {})
    options = { :default => lambda { [] } }.merge(options)
    options = options.merge(:type => :array)
    flag_builder(name, options) do |type, meth, ivar|
      if :tester == type
        define_method(meth) do
          value = instance_variable_get(ivar)
          !(value.nil? or value.empty?)
        end
      end
    end
  end

  ##
  # Defines a flag optimized for working with hashes.
  def hash_flag(name, options = {})
    options = { :default => lambda { {} } }.merge(options)
    options = options.merge(:type => :hash)
    flag_builder(name, options) do |type, meth, ivar|
      if :tester == type
        define_method(meth) do
          value = instance_variable_get(ivar)
          !(value.nil? or value.empty?)
        end
      end
    end
  end

  ##
  # An array of initializer method symbols created so that Flags#reset_flags
  # can reset flags to their default values.
  def flag_inits
    @flag_inits ||= []
  end

  ##
  # An array of initializer method symbols created so that Flags#reset_flags
  # does its work appropriately for public flags.
  def public_flag_inits
    @public_flag_inits ||= []
  end

  ##
  # The flags that have been defined.
  def flags
    @flags ||= {}
  end
end

# vim: ft=ruby
