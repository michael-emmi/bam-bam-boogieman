# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bam/version"

Gem::Specification.new do |s|
  s.name        = "bam-bam-boogieman"
  s.version     = BAM::VERSION.sub(/-.*-/,'-').sub('++','')
  s.licenses    = ['MIT']
  s.authors     = ['Michael Emmi']
  s.email       = 'michael.emmi@gmail.com'
  s.homepage    = 'https://github.com/michael-emmi/bam-bam-boogieman'
  s.summary     = "Boogie AST Manipulator"
  s.description = File.read('README.md').lines.drop(1).take_while{|line| line !~ /##/}.join.strip
  s.files       = `git ls-files`.split("\n")
  s.executables = ['bam']
  s.require_path = 'lib'
end
