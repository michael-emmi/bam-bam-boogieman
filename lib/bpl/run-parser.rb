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
  alias :old_abort :abort
  def abort(str)
    old_abort("Error: #{str}".red)
  end

  def warn(*args)
    args.each do |str|
      unless @@warnings.include? str
        $stderr.puts "Warning: #{str}".yellow
        @@warnings << str
      end
    end
  end
  
  def bpl(str) BoogieLanguage.new.parse_str(str) end
  # def s(str) BoogieLanguage.new.parse_stmt(str) end
  # def d(str) BoogieLanguage.new.parse_decl(str) end
  # def sp(str) BoogieLanguage.new.parse_spec(str) end
  # def e(str) BoogieLanguage.new.parse_expr(str) end
  # def n(str) BoogieLanguage.new.parse_param(str) end

end

$use_assertions = false
$add_inline_attributes = false

class String
  def parse; BoogieLanguage.new.parse_str(self) end
  def bpl; BoogieLanguage.new.parse_str(self) end
end

require_relative 'parser.tab'
require_relative 'analysis/resolution'
require_relative 'analysis/type_checking'
require_relative 'analysis/normalization'
require_relative 'analysis/vectorization'
require_relative 'analysis/df_sequentialization'
require_relative 'analysis/backend'

abort "give me a string" unless ARGV.size > 0

input = File.exists?(ARGV.first) ? File.read(ARGV.first) : (ARGV * " ")
program = BoogieLanguage.new.parse (input)
program.resolve!
program.type_check
program.normalize!
# program.vectorize!
program.df_sequentialize!
program.prepare_for_backend!
program.resolve!

# NOTE the right order is: vectorize ; seq ; error-flag ; inlines

# puts "INSPECT", program.inspect
# puts "PARSED", program

