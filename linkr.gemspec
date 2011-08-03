# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "linkr/version"

Gem::Specification.new do |s|
  s.name        = "linkr"
  s.version     = Linkr::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Duncan Robertson"]
  s.email       = ["duncan.robertson@bbc.co.uk"]
  s.homepage    = ""
  s.summary     = %q{Resolves urls to the canonical version}
  s.description = %q{Resolves urls to the canonical version. It does this by following redirects in the headers or body of the destination url.}
  
  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')

  s.add_dependency "addressable"

  s.add_development_dependency "rake"
  s.add_development_dependency "fakeweb"
  s.add_development_dependency("bundler", ">= 1.0.0")

  s.has_rdoc      = false
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
