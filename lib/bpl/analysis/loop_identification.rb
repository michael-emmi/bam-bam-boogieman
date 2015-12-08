module Bpl
  module Analysis
    class LoopIdentification < Bpl::Pass

      depends :unstructuring
      depends :cfg_construction, :domination
      flag "--loop-identification", "Compute loops."
      result :loops, {}

      def run! program
        dominators = domination.dominators
        cfg = cfg_construction

        loops.clear
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration) && proc.body
          proc.body.blocks.each do |blk|
            (dominators[blk] & cfg.successors[blk]).each do |head|
              loops[head] ||= Set.new
              loops[head].merge([head,blk])
              work_list = [blk]
              until work_list.empty?
                cfg.predecessors[work_list.shift].each do |pred|
                  next if loops[head].include?(pred)
                  loops[head].add(pred)
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
