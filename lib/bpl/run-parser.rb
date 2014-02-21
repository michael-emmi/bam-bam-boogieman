#!/usr/bin/env ruby

`rex lexer.rex`
`racc parser.racc`

require 'set'

begin
  require 'colorize'
rescue LoadError
  class String
    def yellow; self end
    def red; self end
    def green; self end
  end
end

module Kernel
  @@warnings = Set.new

  def warn(*args)
    args.each do |str|
      unless @@warnings.include? str
        $stderr.puts "Warning: #{str}".yellow
        @@warnings << str
      end
    end
  end
end

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

