# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "c2s/version"

Gem::Specification.new do |s|
  s.name        = "c2s"
  s.version     = C2S::VERSION.sub(/-.*-/,'-').sub('++','')
  s.licenses    = ['MIT']
  s.authors     = ['Michael Emmi']
  s.email       = 'michael.emmi@gmail.com'
  s.homepage    = 'https://github.com/michael-emmi/c2s'
  s.summary     = File.read('README.md').lines.first.split('--')[1].strip
  s.description = File.read('README.md').lines.drop(1).take_while{|line| line !~ /##/}.join.strip
  s.files       = `git ls-files`.split("\n")
  s.executables = ['c2s']
  s.require_path = 'lib'
end