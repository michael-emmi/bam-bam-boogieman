#!/usr/bin/env ruby

`rex lexer.rex`
`racc parser.racc`

require_relative 'parser.tab'

abort "give me a string" unless ARGV.size > 0

BoogieLanguage.new.parse (ARGV * " ")
