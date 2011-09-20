# -*- ruby encoding: utf-8 -*-

require 'text/format'
require 'digest/md5'

##
# The Bourse is where the incoming HTML document, after parsing through the
# Broker, will be transformed into Markdown.
class Agio::Bourse
  extend Agio::Flags

  ##
  # :attr_accessor: link_count
  # The counter for non-inline links and images.

  ##
  # :method: link_count?
  # Returns +true+ if the link_count is non-zero.

  ##
  # :method: incr_link_count
  # Increments the link count by the provided value.

  ##
  # :method: decr_link_count
  # Decrements the link count by the provided value.
  integer_flag  :link_count

  ##
  # :attr_accessor: list_stack
  # A stack for lists being managed.

  ##
  # :method: list_stack?
  # Returns +true+ if the list_stack is not empty.
  array_flag    :list_stack

  ##
  # The Bourse is initialized with both the Broker instance and the Agio
  # instance; the latter is used because it controls how some of the
  # conversions should be performed.
  def initialize(broker, agio)
    @broker, @agio = broker, agio

    @formatter = Text::Format.new
    @formatter.first_indent = 0

    self.link_placement = nil
    @output = StringIO.new("")

    @abbr = { }
    @links = { }

    reset_flags(true)
  end

  attr_reader :abbr
  private :abbr

  attr_reader :links
  private :links

  ##
  # An instance of Text::Format that is used to cleanly format the text
  # output by the Bourse.
  attr_reader :formatter

  ##
  # The output StringIO.
  attr_reader :output

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

  attr_reader :broker
  private :broker

  attr_reader :agio
  private :agio

  def transform
    blocks = broker.blocks.map { |block|
      body = transform_block(block)

      if :paragraph == link_placement
        [ body, link_references ]
      else
        body
      end

    }.flatten.compact

    if :endnote == link_placement
      blocks << link_references
    end

    output.write(blocks.join("\n\n"))
  end

  def link_references(clear = nil)
    items = links.values.sort_by { |link| link[:id] }
    text = items.map { |link|
      unless link[:written]
        link[:written] = true
        s = %Q(   [#{link[:id]}]: #{link[:href]})
        s << %Q( "#{link[:title]}") if link[:title]
        s
      end
    }.join("\n")
  end
  private :link_references

  def escape(string, parents)
    unless parents.include? "pre"
      string = string.
        gsub(/\*/) { "\\*" }.
        gsub(/`/) { "\\`" }.
        gsub(/_/) { "\\_" }.
        gsub(/^(\d+\. )/) { "\\$1" }
    end
    string
  end

  def transform_block(block, parents = [])
    contents = block.contents.map { |object|
      case object
      when String
        escape(object, parents)
      when Agio::Data
        escape(object.value, parents)
      when Agio::Block
        transform_block(object, parents + [ block.name ])
      end
    }

    case block.name
    when /^h([1-6])$/
      "#{"#" * $1.to_i} #{contents.join}"
    when "p", "div"
      formatter.format_one_paragraph(contents.join).chomp
    when "br"
      "  "
    when "hr"
      "* * *"
    when "head", "style", "script"
      nil
    when "em", "i", "u"
      "_#{contents.join}_"
    when "strong", "b"
      "**#{contents.join}**"
    when "blockquote"
      contents.map { |line|
        line.split($/).map { |part| "> #{part}" }.join("\n")
      }.join("\n")
    when "code"
      if parents.include? "pre"
        contents.join
      else
        "`#{contents.join}`"
      end
    when "abbr"
      abbr[block.options[:attrs]["title"]] = contents.join
    when "a"
      attrs = block.options[:attrs]
      text = contents.join

      if attrs and attrs["href"]
        href, title = attrs["href"], attrs["title"]

        if :inline == link_placement
          if title
            %Q([#{text}](#{href} "#{title}"))
          else
            %Q([#{text}](#{href}))
          end
        else
          key = Digest::MD5.hexdigest(href + title.to_s)
          link = links[key]

          unless link
            incr_link_count 1
            link = {
              :title  => title,
              :href   => href,
              :id     => link_count
            }

            links[key] = link
          end

          %Q([#{text}][#{link[:id]}])
        end
      else
        text
      end
    when "img"
      attrs = block.options[:attrs]
      attrs["href"] = attrs["src"]
      text = attrs["alt"] || contents.join

      if attrs and attrs["href"]
        href, title = attrs["href"], attrs["title"]

        if :inline == link_placement
          if title
            %Q(![#{text}](#{href} "#{title}"))
          else
            %Q(![#{text}](#{href}))
          end
        else
          key = Digest::MD5.hexdigest(href + title.to_s)
          link = links[key]

          unless link
            incr_link_count 1
            link = {
              :title  => title,
              :href   => href,
              :id     => link_count
            }

            links[key] = link
          end

          %Q(![#{text}][#{link[:id]}])
        end
      else
        text
      end
    when "dl"
      contents.join
    when "dt"
      contents.join("\n")
    when "dd"
      ":   #{contents.join}"
    when "ol"
      count = 0
      contents.map { |line|
        next if line.strip.empty?
        first, *rest = line.split($/)

        fpref = "#{count += 1}.  "
        first = "#{fpref}#{first}"

        if rest.empty?
          first
        else
          rpref = " " * fpref.size
          rest = rest.map { |part| "#{rpref}#{part}" }
          [ first, rest ].flatten.join("\n")
        end
      }.compact.join("\n")
    when "ul"
      contents.map { |line|
        next if line.strip.empty?
        first, *rest = line.split($/)

        fpref = "  * "
        first = "#{fpref}#{first}"

        if rest.empty?
          first
        else
          rpref = " " * fpref.size
          rest = rest.map { |part| "#{rpref}#{part}" }
          [ first, rest ].flatten.join("\n")
        end
      }.compact.join("\n")
    when "li"
      contents.join
    when "pre"
      contents.map { |line|
        line.split($/).map { |part| "    #{part}" }.join("\n")
      }.join("\n")
    end
  end
  private :transform_block
end

# vim: ft=ruby
