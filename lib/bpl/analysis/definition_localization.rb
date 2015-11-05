module Bpl
  module Analysis
    class DefinitionLocalization < Bpl::Pass
      def self.description
        "Determine the definitions sites of each variable."
      end

      depends :resolution, :modifies_correction

      def add_def(proc, id, stmt)
        proc.body.definitions[id.name] ||= Set.new
        proc.body.definitions[id.name].add(stmt)
      end

      def run! program
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration) && proc.body
          proc.body.definitions.clear
          proc.body.each do |stmt|
            if stmt.is_a?(AssignStatement)
              stmt.lhs.each do |id|
                if id.is_a?(StorageIdentifier)
                  add_def(proc, id, stmt)
                end
              end
            elsif stmt.is_a?(HavocStatement)
              stmt.identifiers.each do |id|
                add_def(proc, id, stmt)
              end
            elsif stmt.is_a?(CallStatement)
              (stmt.assignments + stmt.procedure.declaration.modifies).each do |id|
                if id.is_a?(StorageIdentifier)
                  add_def(proc, id, stmt)
                end
              end
            end
          end
        end
      end

    end
  end
end
