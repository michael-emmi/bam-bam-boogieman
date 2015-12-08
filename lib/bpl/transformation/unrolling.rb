module Bpl
  module Transformation
    class Unrolling < Bpl::Pass

      flag "--unrolling BOUND", Integer, "Unroll loops." do |n|
        option :bound, n
      end
      depends :loop_identification

      def run! program
        changed = false
        loop_identification.loops.each do |head,body|
          puts "LOOP #{head.name}"
        end
        changed
      end
    end
  end
end
