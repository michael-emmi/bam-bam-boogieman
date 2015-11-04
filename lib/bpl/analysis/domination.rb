module Bpl
  module Analysis
    class Domination < Bpl::Pass
      def self.description
        "Determine dominators of each basic block."
      end

      depends :cfg_construction

      def run! program
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration) && proc.body
          entry = proc.body.blocks.first

          proc.body.blocks.each do |blk|
            blk.dominators.replace(blk == entry ? [entry] : proc.body.blocks)
          end

          work_list = entry.successors.to_a
          until work_list.empty? do
            blk = work_list.shift
            doms = blk.predecessors.each.inject(blk.dominators) do |acc,b|
              acc & b.dominators
            end.add(blk)
            unless blk.dominators.count == doms.count
              blk.dominators.replace(doms)
              work_list |= blk.successors.to_a
            end
          end
        end
      end

    end
  end
end
