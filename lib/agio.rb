# -*- ruby encoding: utf-8 -*-

require 'nokogiri'
require 'stringio'
require 'text/format'

##
# = Agio
# Agio converts HTML to Markdown.
#
# == About the Name
# The name was chosen because agio is "a premium on money in exchange",
# sort of the opposite of a markdown. It comes from the Italian aggio
# (premium), not from the Italian agio (ease), although the hope is that
# there is an ease in use of this library.
#
# It is structurally based on Aaron Swarz's html2txt Python script inasmuch
# as the SAX parsing he does is also done here and with pretty much the same
# behaviour.
#
# == License
# This code is licensed under MIT License
class Agio < Nokogiri::XML::SAX::Document
  VERSION = "1.0.0"
end

require 'agio/flags'
require 'agio/broker'

class Agio < Nokogiri::XML::SAX::Document
  extend Agio::Flags

  ##
  # :attr_accessor:
  # The default HTML document to be processed. Because the #parse method can
  # be called with an HTML document, this does not *need* to be set.
  attr_accessor :html

  ##
  # :attr_reader:
  # The width of the body text for the generated Markdown text outside of
  # +pre+ bodies and other items which do not wrap well in most Markdown
  # parsers.
  def columns
    @formatter.columns
  end
  ##
  # :attr_writer:
  # The width of the body text for the generated Markdown text outside of
  # +pre+ bodies and other items which do not wrap well in most Markdown
  # parsers.
  def columns=(value)
    @formatter.columns = value unless value.nil?
    @formatter.columns
  end

  ##
  # :attr_reader:
  # Controls how links are placed in the Markdown document.
  def link_placement
    @link_placement
  end
  # :attr_writer: link_placement
  # Controls how links are placed in the Markdown document.
  #
  # In-Line::   Links appear next to their wrapped text, like "[See the
  #             example](http://example.org/)". The default for
  #             link_placement, set if the value is +nil+, <tt>:inline</tt>,
  #             or any other unrecognized value.
  # Paragraph:: Links appear in the body as linked references, like "[See
  #             the example][1]", and the reference "[1]:
  #             http://example.org" is placed immediately after the
  #             paragraph in which the link first appears. Used if the value
  #             of link_placement is <tt>:paragraph</tt>.
  # Endnote::   Links appear in the body as linked references, like "[See
  #             the example][1]", and the reference "[1]:
  #             http://example.org" is placed at the end of the document.
  #             Used if the value of link_placement is <tt>:endnote</tt>.
  def link_placement=(value)
    value = case value
            when :inline, :paragraph, :endnote
              value
            when nil
              :inline
            else
              warn "Invalid value for link placement: #{value}; using inline."
              :inline
            end
    @link_placement = value
  end

  ##
  # :attr_accessor: base_url
  # The base URL for implicit (or local) link references. If not provided,
  # links will remain implicit. This is a String value.

  ##
  # :method: base_url?
  # Returns +true+ if the base URL has been set.
  string_flag :base_url, :public => true

  ##
  # :attr_accessor: skip_local_fragments
  # Controls whether local link references containing fragments will be
  # output in the final document.
  #
  # A local link reference is either an implicit link reference (one missing
  # the protocol and host, such as '&lt;a href="about.html"&gt;' or '&lt;a
  # href="/about.html"&gt;') or one that points to the #base_url.
  #
  # If this value is +true+, links that refer to fragments on local URIs
  # will be ignored (such as '&lt;a href="about.html#address"&gt;').

  ##
  # :method: skip_local_fragments?
  # Returns +true+ if local fragments are supposed to be skipped. See
  # #skip_local_fragments.
  boolean_flag :skip_local_fragments, :public => true

  def initialize(options = {})
    @formatter = Text::Format.new
    @formatter.first_indent = 0

    self.html           = options[:html]
    self.columns        = options[:columns]
    self.link_placement = options[:link_placement]

    yield self if block_given?

    @output = StringIO.new("")
    @tokens = Agio::Tokens.new
    @parser = Nokogiri::HTML::SAX::Parser.new(self)
  end

  def parse(html = nil)
    @parser.parse(html || self.html)
    self
  end

  def to_s
    output.string
  end
  alias to_markdown to_s

  def self.to_markdown(html)
    self.new.parse(html).to_markdown
  end

  # Document Methods
  attr_reader :output
  private :output

  attr_reader :tokens
  private :tokens

  def write(data, options = {})
    pure  = options[:pure]
    force = options[:force]
    data  = data.dup

    abbr_data << data if abbr_data?

    unless suppress?
      if pure and not pre?
        data.sub!(/\s+/, ' ')

        if data =~ /\A (.*)\Z/
          set_space true
          data = $1
        end
      end

      if data.empty? and not force
        return
      end

      set_start_pre false if start_pre?

      bq = ">" * blockquote
      bq += " " if blockquote? and not (force and data[0, 1] == ">")

      if pre?
        bq += "    "
        data.gsub!(/\n/) { "\n#{bq}" }
      end

      if start?
        set_paragraph_mode 0
        set_space false
        set_start false
      end

      if force == :end
        set_paragraph_mode 0
        set_space false
        output.write "\n"
      end

      if paragraph_mode?
        set_space false
        output.write "\n#{bq}" * paragraph_mode
      end

      if space?
        output.write " " unless last_was_nl?
        set_space false
      end

      if links?
        if force == :end or (paragraph_mode == 2 and :paragraph == link_placement)
          output.write "\n" if force == :end

          wrote_links = false
          new_links = []
          links.each { |link|
            if out_count > link['out_count']
              wrote_links = true
              # urlparse.urljoin(self.base_url, link['href']))
              output.write "   [#{link['count']}]: #{link['href']}"
              output.write " (#{link['title']})" if link['title']
              output.write "\n"
            else
              new_links << link
            end
          }

          output.write "\n" if wrote_links
          set_links new_links
        end
      end

      if abbr_list? and force == :end
        abbr_list.each_pair { |abbr, definition|
          output.write "  *[#{abbr}]: #{definition}\n"
        }
      end

      set_paragraph_mode 0
      output.write data
      set_last_was_nl data[-1, 1] == "\n"
      incr_out_count 1
    end
  end

  def new_paragraph
    set_paragraph_mode 2
  end

  def paragraph_break
    set_paragraph_mode 1 if paragraph_mode.zero?
  end

  def tag(name, options = {})
    attrs = Hash[(options[:attrs] || [])]
    tag_start = options[:start]

    case name
    when /^h([1-6])$/
      new_paragraph
      write "#{"#" * $1.to_i} " if tag_start
    when "p", "div"
      new_paragraph
    when "br"
      write "  \n"
    when "hr"
      new_paragraph
      write "* * *"
      new_paragraph
    when "head", "style", "script"
      if tag_start
        incr_suppress 1
      else
        decr_suppress 1
      end
    when "body"
      set_suppress 0
    when "blockquote"
      if tag_start
        new_paragraph
        write "> ", :force => true
        set_start true
        incr_blockquote 1
      else
        decr_blockquote 1
        new_paragraph
      end
    when "em", "i", "u"
      write "_"
    when "strong", "b"
      write "**"
    when "code"
      write '`' unless pre?
    when "abbr"
      if tag_start
        set_abbr_title attrs['title']
        set_abbr_data ""
      else
        if abbr_title?
          abbr_list[abbr_data] = abbr_title
          set_abbr_title nil
        end
        set_abbr_data nil
      end
    when "a"
      if tag_start
        href = attrs['href']
        if href and not (skip_local_fragments? and href =~ /^#/)
          link_stack.push attrs
          write "["
        else
          link_stack.push nil
        end
      else
        if link_stack?
          link = link_stack.pop
          if link
            index = previous_index(link)
            if index
              link = links[index]
            else
              incr_link_count 1
              link['count'] = link_count
              link['out_count'] = out_count
              links.push link
            end

            write "][#{link['count']}]"
          end
        end
      end
    when "img"
      if tag_start and attrs['src']
        attrs['href'] = attrs['src']
        alt = attrs['alt'] || ''
        index = previous_index(attrs)
        if index
          attrs = links[index]
        else
          incr_link_count 1
          attrs['count'] = link_count
          attrs['out_count'] = out_count
          links.push attrs
        end

        write "!["
        write alt
        write "][#{attrs['count']}]"
      end
    when "dl"
      new_paragraph if tag_start
    when "dt"
      paragraph_break unless tag_start
    when "dd"
      if tag_start
        write '    '
      else
        paragraph_break
      end
    when "ol", "ul"
      if tag_start
        list_stack.push({ :name => name, :num => 0 })
      else
        list_stack.pop if list_stack?
      end

    new_paragraph
    when "li"
      if tag_start
        paragraph_break
        if list_stack?
          li = list_stack[-1]
        else
          li = { :name => 'ul', 'num' => 0 }
        end

        write "  " * list_stack.size

        case li[:name]
        when "ul"
          write "* "
        when "ol"
          li['num'] += 1
          write "#{li['num']}. "
        end

        set_start true
      else
        paragraph_break
      end
    when "table", "tr"
      new_paragraph if tag_start
    when "td"
      paragraph_break
    when "pre"
      if tag_start
        set_start_pre true
        set_pre true
      else
        set_pre false
      end
    new_paragraph
    else
      # puts "start_element #{name} #{attrs.inspect}"
    end
  end

  # Dispatch Items

  def cdata_block(string)
    decr_suppress 1 if string =~ %r{/script>}
    write string, :pure => true
  end

  def characters(string)
    decr_suppress 1 if string =~ %r{/script>}
    write string, :pure => true
  end

  def comment(string)
    # new_paragraph
    # write "<!-- #{string} -->\n"
  end

  def end_document
    paragraph_break
    write '', :force => :end
  end

  def end_element(name)
    tag(name)
  end

  def end_element_namespace(name, prefix = nil, uri = nil)
    tag(name, :prefix => nil, :uri => nil)
  end

  def error(string)
    raise "Parsing error: #{string}"
  end

  # Called when document starts parsing
  def start_document
    reset_flags
  end

  # Called at the beginning of an element
  # name is the name of the tag
  # attrs are an assoc list of namespaces and attributes, e.g.:
  # [ ["xmlns:foo", "http://sample.net"], ["size", "large"] ]
  def start_element(name, attrs = [])
    tag(name, :attrs => attrs, :start => true)
  end

  def start_element_namespace(name, attrs = [], prefix = nil, uri = nil, ns = [])
    tag(name, :attrs => attrs, :start => true, :prefix => prefix,
        :uri => uri, :ns => ns)
  end

  def warning(string)
    warn "Parsing warning: #{string}"
  end

  def xmldecl(version, encoding, standalone)
    nil
  end

  def reset_flags
    self.class.flag_inits.each { |init| __send__ init }
  end
  private :reset_flags

  def previous_index(attrs)
    if attrs.has_key?('href')
      index = -1
      links.each { |link|
        index += 1
        match = false

        if link.has_key?('href') and link['href'] == attrs['href']
          if link.has_key?('title') or attrs.has_key?('title')
            if link.has_key?('title') and attrs.has_key?('title')
              match = link['title'] == attrs['title']
            end
          else
            match = true
          end
        end

        return index if match
      }
    end

    nil
  end
  private :previous_index

  string_flag   :abbr_title
  string_flag   :abbr_data
  hash_flag     :abbr_list

  boolean_flag  :start, :default => true
  integer_flag  :suppress
  boolean_flag  :space
  boolean_flag  :last_was_nl
  integer_flag  :paragraph_mode
  integer_flag  :out_count

  boolean_flag  :pre
  boolean_flag  :start_pre

  integer_flag  :blockquote

  array_flag    :links
  array_flag    :link_stack
  integer_flag  :link_count

  array_flag    :list_stack
end

# vim: ft=ruby
