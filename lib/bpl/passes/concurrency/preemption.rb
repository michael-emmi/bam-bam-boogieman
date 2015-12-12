module Bpl
  class Preemption < Pass
    DEFAULT_PREEMPTION_ANNOTATION = :yield

    depends :resolution
    depends :atomicity

    option :attribute, DEFAULT_PREEMPTION_ANNOTATION

    switch "--preemption", "Add preemptions."

    flag "--preemption-attribute NAME", "Attribute NAME for yield." do |y, name|
      y.yield :attribute, name
    end

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
          stmt.insert_before bpl("assume {:#{attribute}} true;")
        end
      end

    end
  end
end
