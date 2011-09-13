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
class Agio#< Nokogiri::XML::SAX::Document
  VERSION = "1.0.0"
end

require 'agio/flags'
require 'agio/broker'
require 'agio/bourse'

class Agio#< Nokogiri::XML::SAX::Document
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
    bourse.formatter.columns
  end
  ##
  # :attr_writer:
  # The width of the body text for the generated Markdown text outside of
  # +pre+ bodies and other items which do not wrap well in most Markdown
  # parsers.
  #
  # If +nil+ is provided, the default value of 78 is set.
  def columns=(value)
    bourse.formatter.columns = value || 78
    bourse.formatter.columns
  end

  ##
  # :attr_reader:
  # Controls how links are placed in the Markdown document.
  def link_placement
    bourse.link_placement
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
    bourse.link_placement = value
  end

  ##
  # :attr_reader: base_url
  # The base URL for implicit (or local) link references. If not provided,
  # links will remain implicit. This is a String value.
  def base_url
    bourse.base_url
  end
  ##
  # :attr_writer: base_url
  # The base URL for implicit (or local) link references. If not provided,
  # links will remain implicit. This is a String value.
  def base_url=(value)
    bourse.base_url = value
  end

  ##
  # :attr_reader: skip_local_fragments
  # Controls whether local link references containing fragments will be
  # output in the final document.
  #
  # A local link reference is either an implicit link reference (one missing
  # the protocol and host, such as '&lt;a href="about.html"&gt;' or '&lt;a
  # href="/about.html"&gt;') or one that points to the #base_url.
  #
  # If this value is +true+, links that refer to fragments on local URIs
  # will be ignored (such as '&lt;a href="about.html#address"&gt;').
  def skip_local_fragments
    bourse.skip_local_fragments
  end

  ##
  # :attr_writer: skip_local_fragments
  # Controls whether local link references containing fragments will be
  # output in the final document.
  #
  # A local link reference is either an implicit link reference (one missing
  # the protocol and host, such as '&lt;a href="about.html"&gt;' or '&lt;a
  # href="/about.html"&gt;') or one that points to the #base_url.
  #
  # If this value is +true+, links that refer to fragments on local URIs
  # will be ignored (such as '&lt;a href="about.html#address"&gt;').
  def skip_local_fragments=(value)
    bourse.skip_local_fragments = value
  end

  def initialize(options = {})
    @broker = Agio::Broker.new
    @bourse = Agio::Bourse.new(broker, self)

    self.html           = options[:html]
    self.columns        = options[:columns]
    self.link_placement = options[:link_placement]

    yield self if block_given?

    @parser = Nokogiri::HTML::SAX::Parser.new(broker)
  end

  def parse(html)
    @parser.parse(html)
    self
  end
  private :parse

  def transform(html)
    parse(html)
    bourse.transform
  end
  private :transform

  def to_s(html = nil)
    transform(html || self.html)
    bourse.output.string
  end
  alias to_markdown to_s

  def self.to_markdown(html)
    self.new.to_markdown(html)
  end

  attr_reader :broker
  private :broker

  attr_reader :bourse
  private :bourse
end

# vim: ft=ruby
