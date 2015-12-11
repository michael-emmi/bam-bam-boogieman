module Bpl
  class Preemption < Pass

    depends :resolution
    depends :atomicity
    flag "--preemption", "Add preemptions."

    def run! program
      program.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration)
        next unless proc.body
        next if proc.has_attribute?(atomicity.attribute)
        proc.each do |stmt|
          next unless stmt.is_a?(AssignStatement) | stmt.is_a?(HavocStatement)
          next unless stmt.any? do |g|
            g.is_a?(StorageIdentifier) && g.is_global? && g.is_variable?
          end
          stmt.insert_before bpl("assume {:yield} true;")
        end
      end

    end
  end
end
