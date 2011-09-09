# -*- ruby encoding: utf-8 -*-

##
# The Bourse is where the incoming HTML document, after parsing through the
# Broker, will be converted into Markdown.
class Agio::Bourse
  ##
  # The Bourse is initialized with both the blocks from the Broker instance
  # and the Agio instance; the latter is used because it controls how some
  # of the conversions should be performed.
  def initialize(blocks, agio)
    @blocks, @agio = blocks, agio
  end

  attr_reader :blocks
  private :blocks

  attr_reader :agio
  private :agio

  def convert
    nil
  end
end

# vim: ft=ruby
