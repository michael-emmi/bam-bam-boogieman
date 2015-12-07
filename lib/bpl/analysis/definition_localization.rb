module Bpl
  module Analysis
    class DefinitionLocalization < Bpl::Pass

      depends :resolution, :modification
      flag "--definition-localization", "Compute definition sites."
      result :definitions, {}

      def add_def(proc, id, stmt)
        definitions[id.name] ||= Set.new
        definitions[id.name].add(stmt)
      end

      def run! program
        definitions.clear
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration) && proc.body

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
              mods = modification.modifies[stmt.procedure.declaration]
              (stmt.assignments + mods.to_a).each do |id|
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
