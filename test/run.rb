#!/usr/bin/env ruby
# typed: false

require 'optparse'
require 'colorize'
require 'tempfile'
require 'open3'

def bam_exe
  File.join(__dir__, "..", "exe", "bam")
end

def get_arguments
  args = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{File.basename $0} [options]"
    opts.separator ""
    opts.separator "Basic options:"

    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end

    opts.on("-v", "--[no-]verbose", "Run verbosely?") do |v|
      args[:verbose] = v
      args[:quiet] = !v
    end

    opts.on("-q", "--[no-]quiet", "Run quietly?") do |q|
      args[:quiet] = q
      args[:verbose] = !q
    end
  end.parse!

  return args
end

begin
  args = get_arguments
  counts = { :success => 0, :failure => 0 }

  puts "bam REGRESSION TESTS".bold unless args[:quiet]

  root = File.dirname(__FILE__)

  Dir.mktmpdir do |temp|
    Dir.glob(File.join(root, "**/*.bpl")).each do |source|
      command_flags = source + ".flags"
      expected_result = source + ".result"
      actual_result = File.join(temp, File.basename(expected_result))
      next unless File.exist?(expected_result)

      flags = File.read(command_flags).split if File.exist?(command_flags)

      print "#{source} "
      stdin, out, err, thd = Open3.popen3(bam_exe, source, *flags, "-o", actual_result)
      stdin.close

      if thd.value != 0
        puts "PROBLEM:", out.read, err.read
      end
      diff = `diff -w -B #{actual_result} #{expected_result}`

      if $? == 0 && diff.empty?
        puts "OK".green
        counts[:success] += 1
      else
        puts "FAIL".red
        puts diff unless args[:quiet]
        counts[:failure] += 1
      end
      out.close
      err.close
    end
  end

  puts "#{counts[:success]} tests succeeded, #{counts[:failure]} tests failed."
  exit(counts[:failure] == 0)

rescue Interrupt
  puts "tests interrupted"
  exit(false)

ensure

end
