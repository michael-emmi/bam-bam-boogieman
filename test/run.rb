#!/usr/bin/env ruby

require 'optparse'
require 'colorize'
require 'tempfile'

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

  puts "bam REGRESSION TESTS".bold unless args[:quiet]

  root = File.dirname(__FILE__)

  Dir.mktmpdir do |temp|
    Dir.glob(File.join(root, "**/*.bpl")).each do |source|
      command_flags = source + ".flags"
      expected_result = source + ".result"
      actual_result = File.join(temp, File.basename(expected_result))
      next unless File.exist?(expected_result)

      cmd = "bam #{source} -o #{actual_result}"
      cmd += " " + File.read(command_flags) if File.exist?(command_flags)

      puts "#{cmd}" if args[:verbose]

      print "#{source} "
      `#{cmd}`
      diff = `diff -w -B #{expected_result} #{actual_result}`
      if diff.empty?
        puts "OK".green
      else
        puts "FAIL".red
        puts diff unless args[:quiet]
      end
    end
  end

rescue Interrupt
  puts "tests interrupted"

ensure

end
