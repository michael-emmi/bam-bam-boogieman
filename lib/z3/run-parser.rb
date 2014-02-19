#!/usr/bin/env ruby

`rex lexer.rex`
`racc parser.racc`

require_relative 'parser.tab'

abort "give me a string" unless ARGV.size > 0

input = File.exists?(ARGV.first) ? File.read(ARGV.first) : (ARGV * " ")
model = Z3Model.new.parse input
# puts "INSPECT", program.inspect
# puts "PARSED", model

model.each do |k,v|
  puts "#{k} -> #{v}"
end
