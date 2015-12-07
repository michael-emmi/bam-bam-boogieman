module Bpl
  module Transformation
    class Preemption < Bpl::Pass

      flag "--preemption", "Add preemptions."

      def run! program
        changed = false
        program.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration) && proc.body
          next if proc.name =~ /^\$/ # includes $static_init, $malloc, $free, ...
          next if proc.name =~ /__SMACK/
          next if proc.has_attribute? :atomic
          proc.each do |stmt|
            next unless stmt.is_a?(AssignStatement)
            next unless stmt.any? do |g|
              g.is_a?(StorageIdentifier) && g.is_global? && g.is_variable?
            end
            stmt.insert_before bpl("assume {:yield} true;")
            changed = true
          end
        end
        changed
      end
    end
  end
end
