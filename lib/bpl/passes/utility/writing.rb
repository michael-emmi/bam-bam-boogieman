# typed: true
module Bpl
  class Writing < Pass

    option :file
    switch "-o", "--output [FILENAME]" do |y, f|
      y.yield :file, f
    end

    def first?
      res = @first.nil?
      @first = false
      res
    end

    def run! program
      first = first?
      if file
        File.open(file, first ? 'w' : 'a') do |f|
          f.puts "---".comment unless first
          f.puts program
        end
      elsif $stdout.tty?
        puts "---"
        puts program.hilite
      else
        puts "---".comment
        puts program
      end
    end

  end
end
