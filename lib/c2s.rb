#!/usr/bin/env ruby

require 'set'
require 'optparse'
require_relative 'c2s/version'

begin
  require 'colorize'
rescue LoadError
  class String
    def yellow; self end
    def red; self end
    def green; self end
    def blue; self end
    def light_black; self end
    def bold; self end
  end
end

$warnings = Set.new
$show_warnings = true
$verbose = false
$quiet = false
$keep = false
$temp = Set.new

module Kernel

  alias :old_abort :abort

  def abort(str)
    old_abort("Error: #{str}".red)
  end

  def info(*args)
    args.each do |str|
      puts "Info: #{str}".light_black unless $quiet
    end
  end

  def warn(*args)
    return unless $show_warnings
    args.each do |str|
      unless $warnings.include? str
        $stderr.puts "Warning: #{str}".yellow
        $warnings << str
      end
    end
  end

  def smack
    abort "'smackgen.py' missing from executable path.\n" \
      "The C/LLVM front end requires SMACK; please install it." \
    if `which smackgen.py`.empty?
    'smackgen.py --verifier=boogie-plain'
  end

  def boogie
    ['Boogie','boogie','Boogie.exe','boogie.exe'].each do |b|
      return "#{b}" if not `which #{b}`.empty?
    end
    abort "'Boogie' missing from executable path.\n" \
      "Verification requires Boogie; please install it."
  end

  def bpl(str, scope: nil)
    elem = BoogieLanguage.new.parse_str(str)
    case elem
    when Node; elem.resolve!(scope)
    when Array; elem.each {|e| e.resolve!(scope)}
    end if scope
    elem
  end
  def bpl_expr(str, scope: nil)
    elem = BoogieLanguage.new.parse_expr(str)
    case elem
    when Node; elem.resolve!(scope)
    when Array; elem.each {|e| e.resolve!(scope)}
    end if scope
    elem
  end
  def bpl_type(str, scope: nil)
    elem = BoogieLanguage.new.parse_type(str)
    case elem
    when Node; elem.resolve!(scope)
    when Array; elem.each {|e| e.resolve!(scope)}
    end if scope
    elem
  end
end

class String
  def to_range
    case self
    when /\d+\.\.\d+/
      split(/\.\./).inject{|i,j| i.to_i..j.to_i}
    else
      to_i..to_i
    end
  end
end

def timed(desc = nil)
  time = Time.now
  res = yield if block_given?
  time = (Time.now - time).round(2)
  puts "#{desc} took #{time}s." if $verbose && desc
  res
end

# parse @c2s-options comments in the source file(s) for additional options
ARGV.select{|f| File.extname(f) == '.bpl' && File.exists?(f)}.map do |f|
  File.readlines(f).grep(/@c2s-options (.*)/) do |line|
    line.gsub(/.* @c2s-options (.*)/,'\1').split.reverse.each do |arg|
      ARGV.unshift arg
    end
  end
end.flatten

@modules = {}
@stages = []
@output_file = nil

require_relative 'bpl/parser.tab'
require_relative 'bpl/transformation'

root = File.expand_path(File.dirname(__FILE__))
Dir.glob(File.join(root,'bpl','analysis','*.rb')).each do |lib|
  require_relative lib
  name = File.basename(lib,'.rb')
  klass = "Bpl::Analysis::#{name.split('_').collect(&:capitalize).join}"
  @modules[name.to_sym] = Object.const_get(klass)
end

OptionParser.new do |opts|

  opts.banner = "Usage: #{File.basename $0} [options] FILE(s)"

  opts.separator ""
  opts.separator "Basic options:"

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.on("--version", "Show version") do
    puts "#{File.basename $0} version #{C2S::VERSION || "??"}"
    exit
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely? (default #{$verbose})") do |v|
    $verbose = v
    $quiet = !v
  end

  opts.on("-q", "--[no-]quiet", "Run quietly? (default #{$quiet})") do |q|
    $quiet = q
    $verbose = !q
  end

  opts.on("-w", "--[no-]warnings", "Show warnings? (default #{$show_warnings})") do |w|
    $show_warnings = w
  end

  opts.on("-k", "--[no-]keep-files", "Keep intermediate files? (default #{$keep})") do |v|
    $keep = v
  end

  opts.on("-o", "--output-file FILENAME") do |f|
    @output_file = f
  end

  opts.separator ""
  opts.separator "Staging options:"

  @modules.each do |name,klass|
    str = "--#{name}"
    str << " [#{klass.options.map{|o| "#{o}:_"} * ","}]" \
      unless klass.options.empty?
    opts.on(str, klass.description) do |args|
      if klass.options.empty?
        args = {}
      else
        args = args.split(',').map{|s| k,v = s.split(':'); [k.to_sym,v]}.to_h
      end
      @stages << klass.new(args)
    end
  end

end.parse!

begin
  puts "c2s version #{C2S::VERSION}, copyright (c) 2014, Michael Emmi".bold \
    unless $quiet

  abort "Must specify a single source file." unless ARGV.size == 1
  src = ARGV[0]
  abort "Source file '#{src}' does not exist." unless File.exists?(src)

  require_relative 'bpl/ast/trace'
  require_relative 'z3/model'
  require_relative 'c2s/frontend'

  include Bpl::Analysis

  # begin
  #   require 'eventmachine'
  # rescue LoadError
  #   warn "Parallel verification requires the eventmachine gem; disabling." if @parallel
  #   @parallel = false
  # end

  # @type_checking = false unless @resolution
  # @sequentialization = false unless @resolution
  # @atomicity = @sequentialization
  # @normalization = @sequentialization || @verification
  # @modifies_correction = @sequentialization
  # @rounds ||= @delays + 1

  src = timed 'Front-end' do
    C2S::process_source_file(src)
  end

  program = timed 'Parsing' do
    BoogieLanguage.new.parse(File.read(src))
  end

  program.source_file = src

  @stages.each do |analysis|
    timed analysis.class.name.split('::').last do
      analysis.run! program
    end
  end

  if @output_file
    timed('Writing transformed program') do
      $temp.delete @output_file
      File.write(@output_file, program)
    end
  else
    puts program
  end

ensure
  $temp.each{|f| File.unlink(f) if File.exists?(f)} unless $keep
end
