# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "gswax/version"

Gem::Specification.new do |s|
  s.name        = "gswax"
  s.version     = Gswax::VERSION
  s.authors     = ["j. kaiden"]
  s.email       = ["jakekaiden@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{an audio player for folks who miss their vinyl}
  s.description = %q{an audio player for folks who miss thier vinyl}


  require 'find'
  req_files = []
  Find.find("lib"){|path| req_files << path unless File.directory?(path)}
  #s.files         = `git ls-files`.split("\n")
  s.files = req_files

  #s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  #s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.executables << 'gswax'
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_dependency "green_shoes"
  s.add_dependency "gstreamer"
end
