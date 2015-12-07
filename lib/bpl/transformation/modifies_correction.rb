module Bpl

  module Transformation
    class ModifiesCorrection < Bpl::Pass

      depends :modification
      flag "--modifies-correction", "Correct modifies annotations."

      def run! program
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          proc.specifications.dup.each do |sp|
            sp.remove if sp.is_a?(ModifiesClause)
          end if proc.body
          mods = modification.modifies[proc]
          proc.append_children(:specifications,
            bpl("modifies #{mods.to_a.sort * ", "};")) unless mods.empty?
        end

        true
      end
    end
  end

end
