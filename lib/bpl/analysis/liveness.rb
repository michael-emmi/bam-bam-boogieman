module Bpl
  module Analysis
    class Liveness < Bpl::Pass
      def self.description
        "Determine the live variables at each block."
      end

      depends :cfg_construction, :resolution, :modifies_correction


      def defined(stmt)
        Set.new(
          if stmt.is_a?(AssignStatement)
            stmt.lhs.map(&:ident)
          elsif stmt.is_a?(HavocStatement)
            stmt.identifiers
          elsif stmt.is_a?(CallStatement)
            stmt.assignments.map(&:ident) | stmt.procedure.declaration.modifies
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

          # NOTE do not include identifier *instances* which are definitions
          next if defs.include?(id)
          vars |= [id]
        end
        vars
      end

      def run! program
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration) && proc.body
          proc.body.live.clear
          used = {}
          defined = {}
          work_list = []
          proc.body.blocks.each do |blk|
            used[blk] = Set.new
            defined[blk] = Set.new
            blk.statements.each do |stmt|
              used[blk].merge(Set.new(self.used(stmt).map(&:name)) - defined[blk])
              defined[blk].merge(self.defined(stmt).map(&:name))
            end
            proc.body.live[blk] = used[blk]
            work_list << blk
          end
          until work_list.empty?
            blk = work_list.shift
            updates = blk.successors.
              inject(Set.new){|acc,succ| acc | proc.body.live[succ]} - defined[blk]
            unless updates.subset?(proc.body.live[blk])
              proc.body.live[blk].merge(updates)
              blk.predecessors.each do |pred|
                work_list |= [pred]
              end
            end
          end
        end
      end

    end
  end
end
