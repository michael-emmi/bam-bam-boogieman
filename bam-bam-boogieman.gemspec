# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bam-bam-boogieman/version'

Gem::Specification.new do |spec|
  spec.name        = "bam-bam-boogieman"
  spec.version     = BAM::VERSION
  spec.authors     = ['Michael Emmi']
  spec.email       = 'michael.emmi@gmail.com'

  spec.summary     = %q{Boogie AST Manipulator}
  spec.description = File.read('README.md').lines.drop(1).take_while{|line| line !~ /##/}.join.strip
  spec.homepage    = 'https://github.com/michael-emmi/bam-bam-boogieman'
  spec.licenses    = ['MIT']

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "colorize", "~> 0.8"
  spec.add_development_dependency "figlet", "~> 1.1"
end
