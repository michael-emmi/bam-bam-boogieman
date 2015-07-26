#!/usr/bin/env ruby

require 'optparse'
require_relative '../lib/bam/version'

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

def bam; "../lib/bam.rb" end
$verbose = false
$quiet = false
$keep = false
$run = true
$log = true
$graph = false
$temp = []

def gnuplot(commands)
  IO.popen("gnuplot 2> /dev/null", "w") {|io| io.puts commands}
end

def plot(title, data_file)
  gnuplot <<-eos
  set terminal svg size 600,400 dynamic enhanced fname 'arial' fsize 8 mousing name "histograms_1" butt solid
  set output '#{File.basename(data_file,".*")}.svg'
  set key inside right top vertical Right noreverse noenhanced autotitle nobox
  set datafile missing '-'
  set style data linespoints
  set logscale y
  set xtics border in scale 1,0.5 nomirror rotate by -60  autojustify
  set xtics  norangelimit
  set xtics   ()
  set title "#{title}"
  x = 0.0
  i = 22
  plot '#{data_file}' using 2:xtic(1) title columnheader(2), for [i=3:22] '' using i title columnheader(i)
  eos
end

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

  opts.on("-r", "--[no-]run", "Actually run the regressions? (default #{$run})") do |r|
    $run = r
  end

  opts.on("--[no-]log", "Log regression results for future reference? (default #{$log})") do |l|
    $log = l
  end

  opts.on("-g", "--[no-]graph", "Plot regression history? (default #{$graph})") do |g|
    $graph = g
  end

end.parse!

begin
  puts "bam #{BAM::VERSION} REGRESSION TESTS".bold \
    unless $quiet

  if $run
    if $log
      lines = File.readlines('regressions.dat')
      lines.map! {|l| l.chomp + " -"}
      lines[0].chop!
      lines[0] += "#{BAM::VERSION}"
      File.write('regressions.dat', lines.join("\n"))
    end

    Dir.glob("./regressions/**/*.bpl").each do |source_file|

      # parse @bam-expected comments in the source file
      expected = File.readlines(source_file).grep(/@bam-expected (.*)/) do |line|
        line.gsub(/.* @bam-expected (.*)/,'\1').chomp
      end.flatten.map{|ex| /#{ex}/}

      $temp << output_file = "regression.#{Time.now.to_f}.output"
      cmd = "#{bam} #{source_file} 1> #{output_file} 2>&1"
      print "#{File.basename(source_file)} : "
      t = Time.now
      system cmd
      @time = (Time.now - t).round
      output = File.readlines(output_file)
      @result = !expected.any? {|pattern| output.grep(pattern).empty?}
      puts "#{@result ? "√".green : "X".red}, #{@time}s"

      if $log
        idx = lines.index {|l| l =~ /#{File.basename(source_file)}/}
        lines[idx].chop!
        lines[idx] += "#{@time}"
        File.write('regressions.dat', lines.join("\n"))
        plot('Regression Test Data', 'regressions.dat') if $graph
      end

      # puts output if $verbose
      # puts if $verbose
    end
  end

  if $log && $graph
    plot('Regression Test Data', 'regressions.dat')
    system("open regressions.svg")
  end

ensure
  $temp.each{|f| File.unlink(f) if File.exists?(f)} unless $keep
end
