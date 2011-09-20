# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "agio"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Austin Ziegler"]
  s.date = "2011-09-20"
  s.description = "Agio is a library and a tool for converting HTML to\n{Markdown}[http://daringfireball.net/projects/markdown/]."
  s.email = ["austin@rubyforge.org"]
  s.executables = ["agio"]
  s.extra_rdoc_files = ["Manifest.txt", "History.rdoc", "License.rdoc", "README.rdoc"]
  s.files = [".rspec", "History.rdoc", "License.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "agio.gemspec", "bin/agio", "lib/agio.rb", "lib/agio/block.rb", "lib/agio/bourse.rb", "lib/agio/broker.rb", "lib/agio/data.rb", "lib/agio/flags.rb", "lib/agio/html_element_description.rb", "spec/block_spec.rb", "spec/bourse_spec.rb", "spec/broker_spec.rb", "spec/data_spec.rb", "spec/flags_spec.rb", "spec/html_element_description_spec.rb", "spec/pmh_spec.rb", "spec/spec_helper.rb", ".gemtest"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "agio"
  s.rubygems_version = "1.8.10"
  s.summary = "Agio is a library and a tool for converting HTML to {Markdown}[http://daringfireball.net/projects/markdown/]."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nokogiri>, ["~> 1.5.0"])
      s.add_runtime_dependency(%q<main>, ["~> 4.7.3"])
      s.add_development_dependency(%q<rspec>, ["~> 2.0"])
      s.add_development_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-gemspec>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-seattlerb>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe>, ["~> 2.12"])
    else
      s.add_dependency(%q<nokogiri>, ["~> 1.5.0"])
      s.add_dependency(%q<main>, ["~> 4.7.3"])
      s.add_dependency(%q<rspec>, ["~> 2.0"])
      s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_dependency(%q<hoe-gemspec>, ["~> 1.0"])
      s.add_dependency(%q<hoe-git>, ["~> 1.0"])
      s.add_dependency(%q<hoe-seattlerb>, ["~> 1.0"])
      s.add_dependency(%q<hoe>, ["~> 2.12"])
    end
  else
    s.add_dependency(%q<nokogiri>, ["~> 1.5.0"])
    s.add_dependency(%q<main>, ["~> 4.7.3"])
    s.add_dependency(%q<rspec>, ["~> 2.0"])
    s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec>, ["~> 1.0"])
    s.add_dependency(%q<hoe-git>, ["~> 1.0"])
    s.add_dependency(%q<hoe-seattlerb>, ["~> 1.0"])
    s.add_dependency(%q<hoe>, ["~> 2.12"])
  end
end
