module Bpl
  module AST
    class Trace
      attr_accessor :src_file
      attr_accessor :steps
      
      def initialize(trace_file)
        @steps = []

        lines = File.read(trace_file).lines
        lines.shift until lines.first =~ /Execution trace:/

        num_blocks = 0

        while lines.first !~ /Boogie program verifier finished/
          line = lines.shift
          next if line.empty?  
  
          line.match /([^\s]+)\((\d+),(\d+)\): ([^\s]+)/ do |m|
            src_file, line, col, label = m[1], m[2].to_i, m[3].to_i, m[4]
            src_file = File.join(File.dirname(trace_file), src_file)
    
            case label
            when /Entry/, /Return/
            else
              block = get_block(src_file,line-1)
              vals = get_vals(src_file.chomp('.bpl') + '.model', @steps.count)              
              @steps << {file: src_file, line: line, col: col, label: label, block: block, vals: vals}
            end
          end
        end        
      end
      
      def print
        puts "*" * 80
        puts "A TRACE FOLLOWS"
        @steps.each_with_index do |step,i|
          puts "*" * 80
          puts "#{i+1}. FILE #{step[:file]} LINE #{step[:line]} COL #{step[:col]} LABEL #{step[:label]}"
          if step[:block]
            puts "*" * 80
            puts (step[:block].count > 10 ? step[:block].take(5) + [" ... (truncated) ..."] + step[:block][-4..-1] : step[:block])
          end
          puts "VALS : #{step[:vals] * "\n"}"
        end
      end
      
      def svg_craziness
      end
    end
  end
end

def get_block(file, line)
  File.read(file).lines.drop(line).take_while{|l| l !~ /\b(goto|return)\b/}
end

def get_vals(file, step)
  File.read(file).lines.grep(/@#{step}/)
end

