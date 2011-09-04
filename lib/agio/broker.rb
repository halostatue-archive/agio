# -*- ruby encoding: utf-8 -*-

##
# The Broker class is the object that contains the intermediate format for
# Agio that will then be converted into Markdown text.
#
# The broker has two primary data structures it keeps: the block list and
# the block stack.
#
# The block list is an array of completed blocks for the document that, when
# processed in order, will allow the meaningful creation of the Markdown
# text.
#
# The block stack is where the blocks reside during creation.
#
# == Algorithm
# Assume a fairly simple HTML document:
#
#   &lt;h1&gt;Title&lt;/h1&gt;
#   &lt;p&gt;Lorem ipsum dolor sit amet,
#   &lt;strong&gt;consectetur&lt;/strong&gt; adipiscing.&lt;/p&gt;
#
# When the first element ("h1") is observed, a new block will be created on
# the stack:
#
#   Blocks[ ]
#   Stack [ Block(h1) ] 
#
# The text will be appended to the block:
#
#   Blocks[ ]
#   Stack [ Block(h1, Title) ] 
#
# When the close tag for the element is observed, the block will be popped
# from the stack and pushed to the end of the Blocks.
#
#   Blocks[ Block(h1, Title) ]
#   Stack [ ]
#
# The same happens for the second element ("p") and its text:
#
#   Blocks[ Block(h1, Title) ]
#   Stack [ Block(p, Lorem ipsum dolor it amet) ]
#
# When the "strong" element is received, though, it and its text are pushed
# onto the stack:
#
#   Blocks[ Block(h1, Title) ]
#   Stack [ Block(p, Lorem ipsum dolor it amet),
#           Block(strong, consectetur)
#         ]
#
# When the closing tag for the "strong" element is received, the "strong"
# block is popped off the stack and appended to the block at the top of the
# stack.
#
#   Blocks[ Block(h1, Title) ]
#   Stack [ Block(p, Lorem ipsum dolor it amet,
#                 Block(strong, consectetur)
#         ]
#
# Finally, the text is appended, the closing tag for the "p" element shows
# up, and that block is popped off the stack and appended to the Blocks
# list:
#
#   Blocks[ Block(h1, Title),
#           Block(p, Lorem ipsum dolor it amet,
#                 Block(strong, consectetur), adipiscing)
#         ]
#   Stack [ ]
#
# === Handling Broken HTML
# Agio tries to be sane when dealing with broken HTML.
#
# ==== Missing Block Elements
# It is possible to have missing block elements. In this case, an implicit
# "p" block element will be assumed.
#
#   Lorem ipsum dolor sit amet,
#
# When encountered, this will be treated as:
#
#   Stack [ Block(p, Lorem ipsum dolor sit amet,) ]
#
# If a span element is encountered, an implicit "p" block element will still
# be assumed.
#
#   &lt;em&gt;Lorem ipsum dolor sit amet,&lt;/em&gt;
#
# Will produce:
#
#   Stack [ Block(p),
#           Block(em, Lorem ipsum dolor sit amet,)
#         ]
#
# A special case exists for the "li", "dt", and "dd" tags; if they are
# encountered outside of lists ("ul", "ol", or "dl"), implicit list tags
# will be inserted ("ul" for "li"; "dl" for "dt" or "dd").
#
# ==== Unclosed Elements Inside a Block
# Things are a little more complex when dealing with broken HTML.
# Agio::Broker tries to deal with them sanely. Assume the following HTML:
#
#   &lt;p&gt;Lorem ipsum dolor sit amet,
#   &lt;strong&gt;consectetur adipiscing.&lt;/p&gt;
#
# Before the closing "p" tag is observed, the stack looks like this:
#
#   Stack [ Block(p, Lorem ipsum dolor it amet),
#           Block(strong, consectetur adipiscing)
#         ]
#
# When the "p" tag is observed, the Broker sees that the topmost block was
# not opened with a "p" tag, so it *implicitly* closes the topmost block as
# defined above, resulting in:
#
#   Blocks[ Block(p, Lorem ipsum dolor it amet,
#                 Block(strong, consectetur adipiscing)
#         ]
#
# ==== Unclosed Elements Between Blocks
# If an HTML element is not nestable (see below), then observing another
# element start of that type will cause the existing block to be closed and
# a new one to be opened. For example:
#
#   &lt;p&gt;Lorem ipsum dolor sit amet,
#   &lt;p&gt;consectetur adipiscing.&lt;/p&gt;
#
# If the Broker has processed the the first "p" element:
#
#   Blocks[ ]
#   Stack [ Block(p, Lorem ipsum dolor it amet,) ]
#
# When the second "p" opening tag is seen, Agio::Broker treats this as
# having an implicit closing "p" tag:
#
#   Blocsk[ Block(p, Lorem ipsum dolor it amet,) ]
#   Stack [ Block(p) ]
#
# This behaviour does not apply to a nestable element.
#
# === Nestable HTML Elements
# Some HTML elements are considered nestable by Agio::Broker. These
# currently include "blockquote", "ol", and "ul". When opening blocks of
# these types are observed, these blocks do not cause a current block of the
# same type to be shifted as outlined above. Nestable elements can contain
# other block elements; "li" elements are special in that they cannot
# directly contain another "li", but they can contain other block elements.
class Agio::Broker < Nokogiri::XML::SAX::Document
  def self.reload
    load __FILE__
  end

  def self.setup
    h = IO.readlines("test/html/rspec.html").join
    b = self.new
    p = Nokogiri::HTML::SAX::Parser.new(b)
    [ h, b, p ]
  end

  ##
  # A block is the fundamental collection for the Broker.
  class Block
    def inspect
      %Q(#<#{self.class}:0x#{object_id.to_s(16)} @tag=#{tag.inspect} @content=#{content.inspect}>)
    end

    # The tag the block is for.
    attr_reader :tag

    # The contents of the tag.
    attr_reader :content

    def initialize(tag, options = {})
      @tag, @options = tag, options
      @content = []
    end

    def append(*content)
      @content.push(*content)
    end

    # A nestable_block is one that can contain other blocks.
    def nestable_block?
      NESTABLE.include? tag or tag == "li"
    end

    def block?
      BLOCK.include? tag or tag == "li"
    end

    def span?
      not block? and not nestable_block?
    end

    def li?
      tag == "li"
    end

    def pre?
      tag == "pre"
    end

    def ul_ol?
      tag == "ul" or tag == "ol"
    end

    def definition?
      tag == "dt" or tag == "dd"
    end

    def dl?
      definition? or tag == "dl"
    end

    # Sibling tags are:
    # * li
    # * dd, dt
    # * any non-nestable_block tag if the tag is the same.
    def sibling_of?(other)
      if li? and other.li?
        true
      elsif definition? and other.definition?
        true
      elsif not nestable_block? and tag == other.tag
        true
      else
        false
      end
    end

    NESTABLE  = %W(ul ol blockquote)
    BLOCK     = %W(h1 h2 h3 h4 h5 h6 p div table tr td pre dl)
  end

  class Data
    def initialize(value)
      @value = value
    end

    attr_reader :value

    def to_s
      value
    end
  end
  class CData < Data; end
  class Comment < Data; end
  class XMLDecl < Data; end

  ##
  # Blocks are an array of completed document subsections. 
  attr_reader :blocks
# private :blocks

  attr_reader :stack
# private :stack

  def initialize
    @blocks   = []
    @stack    = []
  end

  # Push the object onto the stack. Some objects may cause the stack to be
  # modified in other ways. "html" objects will be ignored. "body" objects
  # will cause "head" objects to be popped from the stack and then be
  # ignored.
  def stack_push(object)
    object = Data.new(object) if object.kind_of? String

    case object
    when Data
      if stack.empty?
        # Push a new p block if the stack is empty.
        stack_push Block.new("p")
      else
        stack[-1].append object
      end
    when Block
      return nil if object.tag == "html"
      if object.tag == "body"
        stack_pop("head")
        return nil
      end

      # When the stack is empty:
      if not stack.empty?
        # Do things that might empty the stack.
        loop do
          top = stack[-1]

          break if top.nil?

          if top.sibling_of? object
            # If the top item is a sibling, pop the stack over.
            stack_pop
          elsif top.nestable_block?
            # If the top item in the stack is a nestable block, we just keep
            # pushing down.
            break
          elsif top.span? and not object.span?
            # If the top item is a span object and the current item is not a
            # span object, pop the stack over.
            stack_pop
          elsif top.dl? and not object.definition?
            # If the top item is a definition list, but the current object
            # isn't a definition item, pop.
            stack_pop
          elsif top.ul_ol? and not object.li?
            # If the top item is a list, but the current object isn't a list
            # item, pop.
            stack_pop
          elsif top.block? and object.block?
            # If the top item is a block and the object is a block, pop.
            stack_pop
          elsif object.span?
            # If the object is a span object, keep pushing down.
            break
          end

          break if stack.empty? or top.object_id == stack[-1].object_id
        end
      end

      if stack.empty?
        if object.li?
          stack_push Block.new("ul")
        elsif object.definition?
          stack_push Block.new("dl")
        elsif object.span?
          stack_push Block.new("p")
        end
      else
        top = stack[-1]

        if object.li? and not top.ul_ol?
          # If the top item isn't a "ul" or "ol" element, push that on
          # first.
          stack_push Block.new("ul")
        elsif object.definition? and not top.dl?
          # If the top item is a definition item ("dt" or "dd") and the top
          # item isn't one of those or a definition list ("dl"), push that
          # on first.
          stack_push Block.new("dl")
        end
      end

      stack.push object
    end
  end
  private :stack_push

  # Pop the top item from the stack, or until an item with the specified tag
  # appears.
  #
  # While popping, if the stack is empty, append the popped item to the
  # block list. If the stack isn't empty, append the popped item to the new
  # top of the stack.
  def stack_pop(until_tag = nil)
    top = nil
    loop do
      return top if stack.empty?

      top = stack.pop

      if stack.empty?
        blocks.push top
        return top
      end

      stack[-1].append top

      return top if top.tag == until_tag
    end

    if stack.empty?
      nil
    else
      top = stack.pop

      if stack.empty?
        blocks.push top
      else
        stack[-1].append top
      end

      top
    end
  end
  private :stack_pop

  def cdata_block(string)
    puts "#{"|" * stack.size} #{string}"
    stack_push CData.new(string)
  end

  def characters(string)
    return if (stack.empty? or stack[-1].pre?) and string =~ /\A\s+\Z/
    puts "#{"|" * stack.size} #{string}"
    stack_push Data.new(string)
  end

  def comment(string)
    puts "#{"|" * stack.size} <!-- #{string} -->"
    stack_push Comment.new(string)
  end

  def end_document
    stack_pop while not stack.empty?
  end

  def end_element(name)
    stack_pop(name)
  end

  def end_element_namespace(name, prefix = nil, uri = nil)
    stack_pop(name)
  end

  def error(string)
    raise "Parsing error: #{string}"
  end

  def start_document
    stack_pop while not stack.empty?
  end

  def start_element(name, attrs = [])
    stack_push Block.new(name, :attrs => attrs)
    puts "#{">" * (stack.size)} #{name}"
  end

  def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = [])
    stack_push Block.new(name, :attrs => attrs, :prefix => prefix,
                         :uri => uri, :ns => ns)
  end

  def warning(string)
    warn "Parsing warning: #{string}"
  end

  def xmldecl(version, encoding, standalone)
    stack_push XMLDecl.new([version, encoding, standalone])
  end
end

# vim: ft=ruby
