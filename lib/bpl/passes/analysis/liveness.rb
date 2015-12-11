module Bpl
  class Liveness < Pass

    depends :cfg_construction, :resolution, :modification
    flag "--liveness", "Compute live variables."
    result :live, {}

    def defined(stmt)
      Set.new(
        if stmt.is_a?(AssignStatement)
          stmt.lhs.map(&:ident).map(&:name)
        elsif stmt.is_a?(HavocStatement)
          stmt.identifiers.map(&:name)
        elsif stmt.is_a?(CallStatement)
          stmt.assignments.map(&:ident).map(&:name) |
            modification.modifies[stmt.procedure.declaration].to_a
        else
          []
        end
      )
    end

    def used(stmt)
      vars = []
      defs = defined(stmt)
      stmt.each do |id|
        next unless id.is_a?(StorageIdentifier)
        next if defs.include?(id.name)
        vars |= [id.name]
      end
      vars
    end

    def run! program
      cfg = cfg_construction
      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration) && proc.body
        used = {}
        defined = {}
        work_list = []
        proc.body.blocks.each do |blk|
          used[blk] = Set.new
          defined[blk] = Set.new
          blk.statements.each do |stmt|
            used[blk].merge(Set.new(self.used(stmt)) - defined[blk])
            defined[blk].merge(self.defined(stmt))
          end
          live[blk] = used[blk]
          work_list << blk
        end
        until work_list.empty?
          blk = work_list.shift
          updates = cfg.successors[blk].
            inject(Set.new){|acc,succ| acc | live[succ]} - defined[blk]
          unless updates.subset?(live[blk])
            live[blk].merge(updates)
            cfg.predecessors[blk].each do |pred|
              work_list |= [pred]
            end
          end
        end
      end
    end

  end
end
