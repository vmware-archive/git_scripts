# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = "pivotal_git_scripts"
  s.version     = "1.1.0"
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Pivotal Labs"]
  s.email       = ["gems@pivotallabs.com"]
  s.homepage    = "http://github.com/pivotal/git_scripts"
  s.summary     = %q{Developer git workflow convenience scripts}
  s.description = %q{These scripts are helpers for managing developer workflow when using git repos hosted on GitHub.}
  s.has_rdoc      = false

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
end
