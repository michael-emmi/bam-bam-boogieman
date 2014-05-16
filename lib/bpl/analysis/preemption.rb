module Bpl
  module Analysis
    def self.add_preemptions! program
      program.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration) && proc.body
        next if proc.name =~ /^\$/ # includes $static_init, $malloc, $free, ...
        next if proc.name =~ /__SMACK/
        next if proc.attributes.include? :atomic
        proc.replace do |stmt|
          next stmt unless stmt.is_a?(AssignStatement)
          next stmt unless stmt.any? do |g|
            g.is_a?(StorageIdentifier) && g.is_global? && g.is_variable?
          end
          next [bpl("assume {:yield} true;"), stmt]
        end
      end
    end
  end
end
