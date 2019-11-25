# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bam-bam-boogieman/version'

Gem::Specification.new do |spec|
  spec.name        = "bam-bam-boogieman"
  spec.version     = BAM::VERSION
  spec.authors     = ["Michael Emmi"]
  spec.email       = ["michael.emmi@gmail.com"]

  spec.summary     = %q{Boogie AST Manipulator}
  spec.description = File.read('README.md').lines.drop(1).take_while{|line| line !~ /##/}.join.strip
  spec.homepage    = "https://github.com/michael-emmi/bam-bam-boogieman"
  spec.licenses    = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.0.0"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "colorize"
end
