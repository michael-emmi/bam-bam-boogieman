# typed: false
module Bpl
  class ModifiesCorrection < Pass

    depends :modification
    switch "--modifies-correction", "Correct modifies annotations."

    def run! program
      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration)
        proc.specifications.dup.each do |sp|
          sp.remove if sp.is_a?(ModifiesClause)
        end if proc.body
        mods = modification.modifies[proc]
        proc.append_children(:specifications,
          bpl("modifies #{mods.to_a.sort * ", "};")) unless mods.empty?
        invalidates :resolution
      end
    end
  end
end
