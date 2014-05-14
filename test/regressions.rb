#!/usr/bin/env ruby

require 'optparse'
require_relative '../lib/c2s/version'

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

def c2s; "../lib/c2s.rb" end
$verbose = false
$quiet = false
$keep = false
$temp = []

OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename $0} [options]"
  opts.separator ""
  opts.separator "Basic options:"
  
  opts.on("-h", "--help", "Show this message") do
    puts opts
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

  opts.on("-k", "--[no-]keep-files", "Keep intermediate files? (default #{$keep})") do |v|
    $keep = v
  end

end.parse!

begin
  puts "c2s #{C2S::VERSION} REGRESSION TESTS".bold \
    unless $quiet

  Dir.glob("./regressions/**/*.bpl").each do |source_file|

    # parse @c2s-expected comments in the source file
    expected = File.readlines(source_file).grep(/@c2s-expected (.*)/) do |line|
      line.gsub(/.* @c2s-expected (.*)/,'\1').chomp
    end.flatten.map{|ex| /#{ex}/}

    $temp << output_file = "regression.#{Time.now.to_f}.output"
    cmd = "#{c2s} #{source_file} 1> #{output_file} 2>&1"
    print "#{File.basename(source_file)} : "
    t = Time.now
    system cmd
    @time = (Time.now - t).round
    output = File.readlines(output_file)
    @result = !expected.any? {|pattern| output.grep(pattern).empty?}
    puts "#{@result ? "√".green : "X".red}, #{@time}s"
    # puts output if $verbose
    # puts if $verbose
  end
ensure
  $temp.each{|f| File.unlink(f) if File.exists?(f)} unless $keep
end
