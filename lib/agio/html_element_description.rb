# -*- ruby encoding: utf-8 -*-

require 'nokogiri'

##
# Agio::HTMLElementDescription is a wrapper around
# Nokogiri::HTML::ElementDescription to work around a bug with LibXML2 prior
# to 2.7.7. In HTMLParser.c, the #define of INLINE didn't have commas,
# meaning that strings were concatenated instead of forming an
# array (e.g., what should have been <tt>[ "small", "em" ]</tt> ended up
# being <tt>[ "smallem" ]</tt>). This was fixed in libxml2 commit
# 4b41f15d... on 20 January 2010 by Eugene Pimenov.
#
# Nokogiri includes a DefaultDescription hash that contains the same basic
# information, so we will use that (with appropriate wrappers) if the
# version of LibXML2 is not sufficient to have this bug fixed.
class Agio::HTMLElementDescription
  ver = Nokogiri::VERSION_INFO["libxml"]["loaded"]
  ver = ver.split(%r{\.}).map { |e| e.to_i }

  ok = ver[0] > 2
  ok = ok || (ver[0] == 2 and ver[1] > 7)
  ok = ok || (ver[0] == 2 and ver[1] == 7 and ver[2] >= 7)

  if ok
    def self.[](name)
      Nokogiri::HTML::ElementDescription[name]
    end
  else
    def self.[](name)
      @cache ||= {}

      name = name.downcase
      desc = @cache[name]

      if desc.nil?
        desc = Nokogiri::HTML::ElementDescription::DefaultDescriptions[name]
        desc = if desc.nil?
                 false
               else
                 self.new(desc)
               end

        @cache[name] = desc
      end

      if desc
        desc
      else
        nil
      end
    end
  end

  def initialize(desc)
    @d = desc
    @name = name.downcase
    @d = Nokogiri::HTML::ElementDescription::DefaultDescriptions[@name]
  end

  def name
    @d ? @d.name : @name
  end

  def block?
    !inline?
  end

  def to_s
    "#{name}: #{description}"
  end

  def inspect
    "#<#{self.class.name}: #{name} #{description}>"
  end

  def sub_elements
    @d ? @d.subelts : []
  end

  def inline?
    @d ? @d.isinline : nil
  end

  def empty?
    @d ? @d.empty : nil
  end

  def implied_start_tag?
    @d ? @d.startTag : nil
  end

  def implied_end_tag?
    @d ? @d.endTag : nil
  end

  def save_end_tag?
    @d ? @d.saveEndTag : nil
  end

  def deprecated?
    @d ? @d.depr : nil
  end

  def description
    @d ? @d.desc : nil
  end

  def default_sub_element
    @d ? @d.defaultsubelt : nil
  end

  def optional_attributes
    @d ? @d.attrs_opt : []
  end

  def deprecated_attributes
    @d ? @d.attrs_depr : []
  end

  def required_attributes
    @d ? @d.attrs_req : []
  end
end

# vim: ft=ruby
