#!/usr/bin/env ruby

$version = 0.7

require 'set'
require 'optparse'

begin
  require 'colorize'
rescue LoadError
  class String
    def yellow; self end
    def red; self end
    def green; self end
    def blue; self end
    def bold; self end
  end
end

module Kernel
  @@warnings = Set.new
  @@show_warnings = true
  alias :old_abort :abort
  
  def abort(str)
    old_abort("Error: #{str}".red)
  end

  def warn(*args)
    return unless @@show_warnings
    args.each do |str|
      unless @@warnings.include? str
        $stderr.puts "Warning: #{str}".yellow
        @@warnings << str
      end
    end
  end
  
  def bpl(str) BoogieLanguage.new.parse_str(str) end
end

$use_assertions = false
$add_inline_attributes = false

class String
  def parse; BoogieLanguage.new.parse_str(self) end
  def bpl; BoogieLanguage.new.parse_str(self) end
end

def rex
  # TODO cross platform...
  abort "cannot find 'rex' in executable path." if `which rex`.empty?
  'rex'
end

def racc
  # TODO cross platform...
  abort "cannot find 'racc' in executable path." if `which racc`.empty?
  'racc'
end

def generate_parser
  # TODO don't have to redo each time...
  origin = Dir.pwd
  Dir.chdir File.join(File.dirname(__FILE__),'bpl')
  system("#{rex} lexer.rex")
  system("#{racc} parser.racc")
  Dir.chdir origin
end

def timed(desc = nil)
  time = Time.now
  res = yield if block_given?
  time = (Time.now - time).round(2)
  puts "#{desc} took #{time}s." if @verbose && desc
  res
end

if __FILE__ == $0 then

  OptionParser.new do |opts|    
    @verbose = false
    @quiet = false
    @warnings = true
    @keep = false
    @output_file = nil
    
    @resolution = true
    @type_checking = true
    @sequentialization = true
    @inspection = false
    @verification = false

    @rounds = nil
    @delays = 0

    @verifier = :boogie_si
    @boogie_opts = []
    @timeout = Float::INFINITY
    @unroll = Float::INFINITY
    @graph = false

    opts.banner = "Usage: #{File.basename $0} [options] FILE(s)"
    
    opts.separator ""
    opts.separator "Basic options:"
    
    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  
    opts.on("--version", "Show version") do
      puts "#{File.basename $0} version #{$version || "??"}"
      exit
    end
  
    opts.on("-v", "--[no-]verbose", "Run verbosely? (default #{@verbose})") do |v|
      @verbose = v
      @quiet = !v
    end

    opts.on("-q", "--[no-]quiet", "Run quietly? (default #{@quiet})") do |q|
      @quiet = q
      @verbose = !q
    end

    opts.on("-w", "--[no-]warnings", "Show warnings? (default #{@warnings})") do |w|
      self.class.class_variable_set(:@@show_warnings,w)
    end

    opts.on("-k", "--[no-]keep-files", "Keep intermediate files? (default #{@keep})") do |v|
      @keep = v
    end
    
    opts.on("-o", "--output-file FILENAME") do |f|
      @output_file = f
    end

    opts.separator ""
    opts.separator "Staging options:"
    
    opts.on("--[no-]resolution", "Do identifier resolution? (default #{@resolution})") do |r|
      @resolution = r
    end
    
    opts.on("--[no-]type-checking", "Do type checking? (default #{@type_checking})") do |r|
      @type_checking = r
    end
    
    opts.on("--[no-]sequentialize", "Do sequentialization? (default #{@sequentialization})") do |s|
      @sequentialization = s
    end
    
    opts.on("--[no-]verify", "Do verification? (default #{@verification})") do |v|
      @verification = v
    end    
    
    opts.on("--[no-]inspect", "Inspect program? (default #{@inspect})") do |i|
      @inspection = i
    end    

    opts.separator ""
    opts.separator "Sequentialization options:"

    opts.on("-r", "--rounds MAX", Integer, "The rounds bound (default #{@delays+1})") do |r|
      @rounds = r 
    end

    opts.on("-d", "--delays MAX", Integer, "The delay bound (default #{@delays})") do |d|
      @delays = d 
    end
    
    opts.separator ""
    opts.separator "Verifier options:"
  
    opts.on("--verifier NAME", [:boogie_si, :boogie_fi], 
            "Select verifier (default #{@verifier})") do |v|
      @verifier = v
    end
  
    opts.on("-t", "--timeout TIME", Integer, "Verifier timeout (default #{@timeout})") do |t|
      @boogie_opts << "/timeLimit:#{t}"
    end

    opts.on("-u", "--unroll MAX", Integer, "Loop/recursion bound (default #{@unroll})") do |u|
      @unroll = u
    end
    
    # opts.on("-g", "--graph-of-trace", "generate a trace graph") do |g|
    #   @graph = g
    # end
  end.parse!

  abort "Must specify a single Boogie source file." unless ARGV.size == 1
  src = ARGV[0]
  abort "Source file '#{src}' does not exist." unless File.exists?(src)
  
  timed 'Parser-generation' do generate_parser end

  require_relative 'bpl/parser.tab'
  require_relative 'bpl/analysis/resolution'
  require_relative 'bpl/analysis/type_checking'
  require_relative 'bpl/analysis/normalization'
  require_relative 'bpl/analysis/vectorization'
  require_relative 'bpl/analysis/df_sequentialization'
  require_relative 'bpl/analysis/backend'

  program = timed 'Parsing' do
    BoogieLanguage.new.parse(File.read(ARGV.first))
  end

  timed 'Resolution' do
    program.resolve!
  end if @resolution
  
  timed 'Type-checking' do
    program.type_check
  end if @resolution && @type_checking

  if @sequentialization
    timed('Normalization') {program.normalize!}
    # timed('Vectorization') {program.vectorize!(@rounds,@delays)}
    timed('Sequentialization') {program.df_sequentialize!}
  end

  program.prepare_for_backend!

  if @inspection
    timed 'Inspection' do
      program.resolve!
      puts program.inspect
      program.type_check
    end
  end
  
  if @output_file
    timed('Writing to file') {File.write(@output_file,program)}
  elsif @verify
    warn "verification not yet implemented."
  else
    warn "without verification or output, my efforts are wasted."
  end
  
end
