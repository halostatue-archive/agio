# -*- ruby encoding: utf-8 -*-

require 'spec_helper'

describe Agio::Bourse do
  before { PrivateMethodHandler.remove(Agio::Bourse) }
  after { PrivateMethodHandler.restore(Agio::Bourse) }
end

# vim: ft=ruby
