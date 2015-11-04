module Bpl
  module Analysis
    class LoopIdentification < Bpl::Pass
      def self.description
        "Determine the loops of each procedure."
      end

      depends :domination

      def run! program
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration) && proc.body
          proc.body.loops.clear
          proc.body.blocks.each do |blk|
            (blk.dominators & blk.successors).each do |head|
              proc.body.loops[head] ||= Set.new
              proc.body.loops[head].merge([head,blk])
              work_list = [blk]
              until work_list.empty?
                work_list.shift.predecessors.each do |pred|
                  next if proc.body.loops[head].include?(pred)
                  proc.body.loops[head].add(pred)
                  work_list |= [pred]
                end
              end
            end
          end
        end
      end

    end
  end
end
