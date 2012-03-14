# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "pivotal_git_scripts/version"

Gem::Specification.new do |s|
  s.name        = "pivotal_git_scripts"
  s.version     = PivotalGitScripts::VERSION
  s.authors     = ["Pivotal Labs"]
  s.email       = ["gems@pivotallabs.com"]
  s.homepage    = "http://github.com/pivotal/git_scripts"
  s.summary     = %q{Developer git workflow convenience scripts}
  s.description = %q{These scripts are helpers for managing developer workflow when using git repos hosted on GitHub.}

  s.rubyforge_project = "pivotal_git_scripts"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.license       = "MIT"

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
