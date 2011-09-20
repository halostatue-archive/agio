# -*- ruby encoding: utf-8 -*-

require 'rubygems'
require 'rspec'
require 'hoe'

Hoe.plugin :doofus
Hoe.plugin :gemspec
Hoe.plugin :git

Hoe.plugins.delete :rcov

spec = Hoe.spec 'agio' do
  developer('Austin Ziegler', 'austin@rubyforge.org')

  self.history_file = 'History.rdoc'
  self.readme_file = 'README.rdoc'
  self.extra_rdoc_files = FileList["*.rdoc"].to_a

  self.extra_deps << ['nokogiri', '~> 1.5.0']
  self.extra_deps << ['main', '~> 4.7.3']
  self.extra_dev_deps << ['rspec', '~> 2.0']
  self.extra_dev_deps << ['hoe-doofus', '~> 1.0']
  self.extra_dev_deps << ['hoe-gemspec', '~> 1.0']
  self.extra_dev_deps << ['hoe-git', '~> 1.0']
  self.extra_dev_deps << ['hoe-seattlerb', '~> 1.0']
end

RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rcov = true
  t.rcov_opts =  %q[--exclude "osx/objc,gems/,spec/,features/"]
  t.verbose = true
end
  
# vim: syntax=ruby
