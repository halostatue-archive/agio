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

  def inspect
    %Q(#<#{self.class} #{value.inspect}>)
  end
end

##
# A simple wrapper around CData in an HTML document.
class Agio::CData < Agio::Data; end

##
# A simple wrapper around the string contents of an HTML comment.
class Agio::Comment < Agio::Data; end

##
# A simple wrapper around the string contents of an XML declaration in an
# XHTML document.
class Agio::XMLDecl < Agio::Data; end

# vim: ft=ruby
