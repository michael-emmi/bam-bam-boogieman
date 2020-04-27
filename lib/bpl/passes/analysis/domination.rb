# typed: false
module Bpl
  class Domination < Pass

    depends :cfg_construction
    switch "--domination", "Compute dominators."
    result :dominators, {}

    def run! program
      cfg = cfg_construction

      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration) && proc.body
        entry = proc.body.blocks.first

        proc.body.blocks.each do |blk|
          dominators[blk] ||= Set.new
          dominators[blk].replace(blk == entry ? [entry] : proc.body.blocks)
        end

        work_list = cfg.successors[entry].to_a
        until work_list.empty? do
          blk = work_list.shift
          doms = cfg.predecessors[blk].each.inject(dominators[blk]) do |acc,b|
            acc & dominators[b]
          end.add(blk)
          unless dominators[blk].count == doms.count
            dominators[blk].replace(doms)
            work_list |= cfg.successors[blk].to_a
          end
        end
      end
    end

  end
end
