# -*- ruby encoding: utf-8 -*-

require 'agio/block'
require 'agio/data'

##
# The Broker class is the object that transforms HTML into an intermediate
# format for Agio so that the intermediate format can be converted into
# Markdown text.
#
# The Broker has two primary data structures it keeps: the block list
# (#blocks) and the block stack (#stack).
#
# The block list is an array of completed blocks for the document that, when
# processed correctly, will allow the meaningful creation of the Markdown
# text.
#
# The block stack is where the blocks reside during creation.
#
# Agio::Broker is a Nokogiri::XML::SAX::Document and can be used by the
# Nokogiri SAX parser to fill the block list.
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
#   Stack [ block(h1) ]
#
# The text will be appended to the block:
#
#   Blocks[ ]
#   Stack [ block(h1, Title) ]
#
# When the closing tag for the element is observed, the block will be popped
# from the stack and pushed to the end of the blocks list.
#
#   Blocks[ block(h1, Title) ]
#   Stack [ ]
#
# The same happens for the second element ("p") and its text:
#
#   Blocks[ block(h1, Title) ]
#   Stack [ block(p, Lorem ipsum dolor it amet) ]
#
# When the "strong" element is received, though, it and its text are pushed
# onto the stack:
#
#   Blocks[ block(h1, Title) ]
#   Stack [ block(p, Lorem ipsum dolor it amet),
#           block(strong, consectetur)
#         ]
#
# When the closing tag for the "strong" element is received, the "strong"
# block is popped off the stack and appended to the block at the top of the
# stack.
#
#   Blocks[ block(h1, Title) ]
#   Stack [ block(p, Lorem ipsum dolor it amet,
#                 block(strong, consectetur)
#         ]
#
# Finally, the text is appended, the closing tag for the "p" element shows
# up, and that block is popped off the stack and appended to the blocks
# list:
#
#   Blocks[ block(h1, Title),
#           block(p, Lorem ipsum dolor it amet,
#                 block(strong, consectetur), adipiscing)
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
#   Stack [ block(p, Lorem ipsum dolor sit amet,) ]
#
# If a span element is encountered, an implicit "p" block element will still
# be assumed.
#
#   &lt;em&gt;Lorem ipsum dolor sit amet,&lt;/em&gt;
#
# Will produce:
#
#   Stack [ block(p),
#           block(em, Lorem ipsum dolor sit amet,)
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
#   Stack [ block(p, Lorem ipsum dolor it amet),
#           block(strong, consectetur adipiscing)
#         ]
#
# When the "p" tag is observed, the Broker sees that the topmost block was
# not opened with a "p" tag, so it *implicitly* closes the topmost block as
# defined above, resulting in:
#
#   Blocks[ block(p, Lorem ipsum dolor it amet,
#                 block(strong, consectetur adipiscing)
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
#   Stack [ block(p, Lorem ipsum dolor it amet,) ]
#
# When the second "p" opening tag is seen, Agio::Broker treats this as
# having an implicit closing "p" tag:
#
#   Blocsk[ block(p, Lorem ipsum dolor it amet,) ]
#   Stack [ block(p) ]
#
# This behaviour does not apply to a nestable element.
#
# === Nestable HTML Elements
# Some HTML elements are considered nestable by Agio::Broker. These
# currently include "blockquote", "ol", and "ul". When opening tags for
# these types are observed, these tags do not cause a current block of the
# same type to be shifted as outlined above. Nestable elements can contain
# other HTML block elements; "li" elements are special in that they cannot
# directly contain another "li", but they can contain other HTML block
# elements.
class Agio::Broker < Nokogiri::XML::SAX::Document
  ##
  # The array of completed document subsections. Each entry is a root object
  # for contained contents. When HTML parsing is complete, this attribute
  # should be read for the structures that must be translated into Markdown.
  attr_reader :blocks

  ##
  # The operating stack.
  attr_reader :stack
  private :stack

  def initialize
    @blocks   = []
    @stack    = []
  end

  ##
  # Push the object onto the stack. Some objects may cause the stack to be
  # modified in other ways. 'html' objects will be ignored. 'body' objects
  # will cause 'head' objects to be popped from the stack and then be
  # ignored.
  def push(object)
    object = Agio::Data.new(object) if object.kind_of? String

    case object
    when Agio::Data
      # The stack will only ever contain Agio::Block objects; so if we get a
      # Agio::Data object, we need push a Agio::Block onto the stack and
      # then append the Agio::Data to the Agio::Block.
      push Agio::Block.new('p') if stack.empty?
      stack[-1].append object
    when Agio::Block
      # We don't care about the outer 'html' element; this would be
      # discarded if we did, so let's explicitly skip it.
      return nil if object.name == 'html'

      # Similarly to the 'html element, we don't care about the 'body'
      # element. We will discard it, but since we collect the 'head' tag, we
      # need to make sure that any existing 'head' Agio::Block is popped off
      # the stack as we ignore the 'body' element.
      if object.name == 'body'
        pop 'head'
        return nil
      end

      # When the stack already has something on it, we need to see if we
      # need to correct the stack; this may empty or otherwise modify the
      # stack, so we need to do this before making any decisions about how
      # to add to the stack.
      unless stack.empty?
        loop do
          top = stack[-1]

          break if top.nil?

          if top.sibling_of? object
            # If the top item is a sibling, pop the stack over.
            pop
          elsif top.can_contain? object
            # If the top item in the stack can contain the current object,
            # keep pushing down.
            break
          elsif top.inline? and not object.inline?
            # If the top item is a span object and the current item is not a
            # span object, pop the stack over.
            pop
          elsif top.dl? and not object.definition?
            # If the top item is a definition list, but the current object
            # isn't a definition item, pop.
            pop
          elsif top.ul_ol? and not object.li?
            # If the top item is a list, but the current object isn't a list
            # item, pop.
            pop
          elsif top.block? and object.block?
            # If the top item is a block and the object is a block, pop.
            pop
          elsif object.inline?
            # If the object is a span object, keep pushing down.
            break
          end

          break if stack.empty? or top.object_id == stack[-1].object_id
        end
      end

      if stack.empty?
        if object.li?
          push Agio::Block.new("ul")
        elsif object.definition?
          push Agio::Block.new("dl")
        elsif object.inline?
          push Agio::Block.new("p")
        end
      else
        top = stack[-1]

        if object.li? and not top.ul_ol?
          # If the top item isn't a "ul" or "ol" element, push that on
          # first.
          push Agio::Block.new("ul")
        elsif object.definition? and not top.dl?
          # If the top item is a definition item ("dt" or "dd") and the top
          # item isn't one of those or a definition list ("dl"), push that
          # on first.
          push Agio::Block.new("dl")
        end
      end

      stack.push object
    end
  end
  private :push

  ##
  # Pop one or more blocks from the stack and process the popped blocks.
  # Returns the last block popped.
  #
  # === Pop Control
  # If +until_element+ is +nil+, only the top item on the stack will be
  # popped and processed.
  #
  # If +until_element+ is *not* +nil+, the stack will be popped and
  # processed until either the stack is empty or the popped item's block
  # name matches the value of +until_element+.
  #
  # === Agio::Block Processing
  # For each block popped off the stack:
  #
  # 1. If the stack is empty, append the block to the #blocks array.
  # 2. If the stack is not empty, append the block to the top item in the
  #    stack.
  def pop(until_element = nil)
    return nil if stack.empty?

    top = nil

    if until_element.nil?
      top = stack.pop

      if stack.empty?
        blocks.push top
      else
        stack[-1].append top
      end
    else
      loop do
        return top if stack.empty?

        top = stack.pop

        if stack.empty?
          blocks.push top
          break
        end

        stack[-1].append top

        break if top.name == until_element
      end
    end

    top
  end
  private :pop

  def cdata_block(string)
    push Agio::CData.new(string)
  end

  def characters(string)
    return if (stack.empty? or stack[-1].pre?) and string =~ /\A\s+\Z/
    push Agio::Data.new(string)
  end

  def comment(string)
    push Agio::Comment.new(string)
  end

  def end_document
    pop while not stack.empty?
  end

  def end_element(name)
    pop(name)
  end

  def end_element_namespace(name, prefix = nil, uri = nil)
    pop(name)
  end

  def error(string)
    raise "Parsing error: #{string}"
  end

  # When we
  def start_document
    pop while not stack.empty?
  end

  def start_element(name, attrs = [])
    options = if attrs.empty?
                { }
              else
                { :attrs => Hash[attrs] }
              end

    push Agio::Block.new(name, options)
  end

  def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = [])
    push Agio::Block.new(name, :attrs => attrs, :prefix => prefix,
                         :uri => uri, :ns => ns)
  end

  def warning(string)
    warn "Parsing warning: #{string}"
  end

  def xmldecl(version, encoding, standalone)
    push Agio::XMLDecl.new([version, encoding, standalone])
  end
end

# vim: ft=ruby
