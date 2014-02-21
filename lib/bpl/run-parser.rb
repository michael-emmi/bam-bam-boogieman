#!/usr/bin/env ruby

`rex lexer.rex`
`racc parser.racc`

require_relative 'parser.tab'

abort "give me a string" unless ARGV.size > 0

input = File.exists?(ARGV.first) ? File.read(ARGV.first) : (ARGV * " ")
program = BoogieLanguage.new.parse (input)
program.resolve!
program.type_check
program.df_sequentialize!
program.resolve!
puts "INSPECT", program.inspect
# puts "PARSED", program

