require "bam-bam-boogieman/version"

require 'set'
require 'optparse'
require_relative 'bam/prelude'
require_relative 'bam/frontend'
require_relative 'bpl/parser.tab'
require_relative 'bpl/ast/scope'
require_relative 'bpl/ast/binding'
require_relative 'bpl/ast/trace'
require_relative 'bpl/pass'
require_relative 'z3/model'

def source_file_options(files)
  # parse @bam-options comments in the source file(s) for additional options
  opts = []
  files.each do |f|
    next unless File.exist?(f)
    File.readlines(f).grep(/@bam-options (.*)/) do |line|
      line.gsub(/.* @bam-options (.*)/,'\1').split.reverse.each do |arg|
        opts << arg
      end
    end
  end
  opts
end

def command_line_options

  # Add the read switch before any solitary Boogie files
  require_relative 'bpl/passes/utility/reading.rb'
  require_relative 'bpl/passes/utility/writing.rb'

  def file_switch?(x)
    (Bpl::Reading.switch[:args] + Bpl::Writing.switch[:args]).
    any? {|a| /#{a}/ =~ x}
  end

  ARGV.each_index do |idx|
    next if idx > 0 && file_switch?(ARGV[idx-1])
    next unless File.extname(ARGV[idx]) == '.bpl'
    ARGV.insert(idx, Bpl::Reading.switch[:args].first)
  end

  OptionParser.new do |opts|

    opts.banner = "Usage: #{File.basename $0} [options] FILE(s)"

    opts.separator ""
    opts.separator "Basic options:"

    opts.on("-h", "--help", "Show this message") do |v|
      puts opts
      exit
    end

    opts.on("--version", "Show version") do
      puts "#{File.basename $0} version #{BAM::VERSION || "??"}"
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

    categories = {}
    root = File.expand_path(File.dirname(__FILE__))
    Dir.glob(File.join(root,'bpl','passes','**','*/')).each do |dir|
      Dir.glob(File.join(dir, "*.rb")).each do |lib|
        require_relative lib
        name = File.basename(lib,'.rb')
        klass = "Bpl::#{name.classify}"
        @passes[name.to_sym] = Object.const_get(klass)
        categories[File.basename(dir)] ||= Set.new
        categories[File.basename(dir)] << name.to_sym
      end
    end

    categories.each do |cat, passes|
      opts.separator ""
      opts.separator "#{cat} passes:"
      passes.each do |name|
        sw = @passes[name].switch
        opts.on(*sw[:args]) do |*args|
          opts = {}
          sw[:blk].call(
            Enumerator::Yielder.new {|k,v| opts[k] = v},
            *args
          ) if sw[:blk]
          @stages.push([name, opts])
        end
        @passes[name].flags.each do |f|
          opts.on(*f[:args]) do |*args|
            f[:blk].call(
              Enumerator::Yielder.new{|k,v| @passes[name].option k, v},
              *args
            )
          end
        end
      end
    end

    opts.separator ""
  end
end

begin

  @passes = {}
  @stages = []

  command_line_options.parse!

  unless $quiet
    info "BAM! BAM! Boogieman version #{BAM::VERSION}".bold,
      "#{" " * 20}copyright (c) 2015, Michael Emmi".bold
    info
  end

  cache = Hash.new
  programs = []

  if !STDIN.tty? && code = STDIN.read
    programs.push(BoogieLanguage.new.parse(code))
  end

  until @stages.empty? do
    name, args = @stages.shift
    klass = @passes[name]
    next if cache.include?(name) && args.empty?
    deps = klass.depends - cache.keys
    if deps.empty?
      pass = klass.new(args.merge(cache.select{|a| klass.depends.include?(a)}))
      timed name do
        if pass.method(:run!).arity > 0
          programs.each {|program| pass.run!(program)}
        else
          pass.run!
        end
      end
      pass.invalidates.each do |inv|
        case inv when :all then cache.clear else cache.delete inv end
      end
      @stages.unshift([name, args]) if pass.redo?
      cache[name] = pass unless pass.redo?
      programs = programs - pass.removed + pass.added
    else
      @stages.unshift([name, args])
      @stages.unshift(*deps.map{|d| [d,{}]})
    end
  end

rescue Interrupt

rescue ParseError => e
  unless e.message.match(/parse error on value \#<.* @line=(?<line>\d+)> \("(?<token>.*)"\)/) do |m|
    line_no = m[:line].to_i
    abort("parse error at token #{m[:token]} on line #{m[:line]}")

    # TODO track down the source of the parse error
    # File.open(_src_) do |f|
    #   line_no.times { f.gets }
    #   abort("parse error at token \"#{m[:token]}\" on line #{line_no}:\n\n  #{$_}")
    # end

  end
    abort("unidentified parse error: #{e.message.strip}")
  end

ensure
  $temp.each{|f| File.unlink(f) if File.exists?(f)} unless $keep
end
