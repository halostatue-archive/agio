# -*- ruby encoding: utf-8 -*-

##
# A simple wrapper around string data in an HTML document.
class Agio::Data
  def initialize(value)
    @value = value
  end

  attr_reader :value

  def to_s
    value
  end

  def to_str
    value
  end

  def inspect
    %Q(#<#{self.class} #{value.inspect}>)
  end

  ##
  # Used mostly for testing.
  def ==(other)
    if other.kind_of? Agio::Data
      self.class == other.class && value == other.value
    else
      value == other
    end
  end
end

##
# A simple wrapper around CData in an HTML document.
class Agio::CData < Agio::Data; end

##
# A simple wrapper around the string contents of an HTML comment.
class Agio::Comment < Agio::Data; end

##
# A simple wrapper around the contents of an XML declaration in an
# XHTML document.
class Agio::XMLDecl
  def initialize(options = {})
    @version = options[:version]
    @encoding = options[:encoding]
    @standalone = options[:standalone]
  end

  attr_reader :version, :encoding, :standalone

  def to_a
    [ version, encoding, standalone ]
  end

  def to_s
    s = %Q(<?xml )
    s += %Q(version="#{version}" ) unless version.nil?
    s += %Q(encoding="#{encoding}" ) unless encoding.nil?
    s += %Q(standalone="#{!!standalone}" ) unless standalone.nil?
    s += "?>"
    s
  end

  def inspect
    %Q(#<#{self.class} '#{to_s}'>)
  end

  def to_str
    to_s
  end

  def ==(other)
    case other
    when String
      to_s == other
    when Array
      to_a == other
    when Agio::XMLDecl
      to_s == other.to_s
    else
      false
    end
  end
end

# vim: ft=ruby
