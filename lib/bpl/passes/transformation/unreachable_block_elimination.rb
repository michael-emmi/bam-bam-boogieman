module Bpl

  class UnreachableBlockElimination < Pass

    depends :cfg_construction
    switch "--unreachable-block-elimination", "Remove unreachable blocks."


    def exists_path?(entry, target, cfg)
      visited = Set.new
      work_list = [entry]

      until work_list.empty?
        block = work_list.shift
        next if visited.include? block
        visited.add block
        work_list |= cfg.successors[block].to_a
      end

      visited.include? target
    end
    
    def run! program

      cfg = cfg_construction
      
      program.declarations.each do |proc|

        next unless proc.is_a?(ProcedureDeclaration) && proc.body

        entry = proc.body.blocks.first

        more = true
        while more
          more = false
          proc.body.blocks.each do |blk|
            if !exists_path?(entry, blk, cfg)
              more = true
              blk.remove
              cfg.predecessors[blk].each {|p| cfg.successors[p].delete(blk)}
              cfg.successors[blk].each {|s| cfg.predecessors[s].delete(blk)}
              cfg.predecessors.delete blk
              cfg.successors.delete blk
            end
          end
        end
      end
    end

  end
end
