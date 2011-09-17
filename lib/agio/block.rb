# -*- ruby encoding: utf-8 -*-

require 'agio/html_element_description'

##
# A Block is the fundamental collection for the Broker that is used to
# then generate the Markdown.
class Agio::Block
  def inspect
    if options.empty?
      %Q(#<#{self.class} #{name} #{contents.inspect}>)
    else
      %Q(#<#{self.class} #{name}(#{options.inspect}) #{contents.inspect}>)
    end
  end

  # The name of the element the Block is for.
  attr_reader :name

  # The options, if provided, for the element.
  attr_reader :options

  # The contents of the Block.
  attr_reader :contents

  # The description of the HTML element the Block represents (this will
  # always be a Nokogiri::HTML::ElementDescription or +nil+).
  attr_reader :description

  # Create the Block from a tag start.
  def initialize(name, options = {})
    @name, @options = name, options
    @description = Agio::HTMLElementDescription[name]
    @contents = []
  end

  # Append the contents provided to the Block.
  def append(*contents)
    @contents.push(*contents)
  end

  # Returns +true+ if the Block is a standard HTML element (as understood
  # by Nokogiri).
  def standard?
    !!description
  end

  ##
  # Returns +true+ if this Block is an HTML inline element.
  def inline?
    description && description.inline?
  end

  ##
  # Returns +true+ if this Block is an HTML block element.
  def block?
    description && description.block?
  end

  ##
  # Returns +true+ if this Block can contain the other Block provided.
  def can_contain?(other)
    description && description.sub_elements.include?(other.name)
  end

  ##
  # Returns +true+ if the Block is a 'li' (list item) element.
  def li?
    name == "li"
  end

  ##
  # Returns +true+ if the Block is a 'pre' element.
  def pre?
    name == "pre"
  end

  ##
  # Returns +true+ if the Block is a 'ul' or 'ol' element.
  def ul_ol?
    name == "ul" or name == "ol"
  end

  ##
  # Returns +true+ if the Block is a definition item ('dt' or 'dd').
  def definition?
    name == "dt" or name == "dd"
  end

  ##
  # Returns +true+ if the block is a definition list ('dl') element.
  def dl?
    definition? or name == "dl"
  end

  ##
  # Determine whether the +other+ Block is a sibling of this Block.
  # Blocks are siblings if:
  #
  # 1. This Block cannot contain the other Block.
  # 2. This Block is a definition ('dt' or 'dd') and so is the other
  #    Block.
  # 3. This Block's name and the other Block's name are the same.
  def sibling_of?(other)
    if can_contain? other
      false
    elsif definition? and other.definition?
      true
    elsif name == other.name
      true
    else
      false
    end
  end

  ##
  # Used mostly for testing.
  def ==(other)
    name == other.name &&
      options == other.options &&
      contents == other.contents
  end
end

# vim: ft=ruby
