module Bpl
  module AST
    class ProcedureDeclaration
      children :accesses
    end
  end

  module Analysis

    def self.correct_modifies! program
      globals = program.global_variables.map(&:names).flatten
      work_list = []
      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration)
        work_list << proc
        proc.specifications.reject!{|sp| sp.is_a?(ModifiesClause)} if proc.body
        mods = Set.new
        accs = Set.new
        proc.each do |elem|
          case elem
          when StorageIdentifier
            accs << elem if elem.is_variable? && elem.is_global?
          when HavocStatement
            mods += elem.identifiers.map(&:name) & globals
          when AssignStatement
            mods += elem.lhs.map(&:name) & globals
          when CallStatement
            mods += elem.assignments.map(&:name) & globals
            puts "UNRESOLVED: #{elem.inspect}" unless elem.declaration
            elem.declaration.callers << proc
          end
        end
        proc.specifications << bpl("modifies #{mods.to_a * ", "};") \
          unless mods.empty?
        proc.accesses = accs.to_a
      end

      until work_list.empty?
        proc = work_list.shift
        targets = proc.callers
        targets << proc.declaration if proc.respond_to?(:declaration) && proc.declaration
        targets.each do |caller|
          mods = proc.modifies - caller.modifies
          accs = proc.accesses - caller.accesses
          caller.specifications << bpl("modifies #{mods.to_a * ", "};") unless mods.empty?
          caller.accesses |= accs
          work_list |= [caller] unless mods.empty? && accs.empty?
        end
      end
    end
  end

  # module AST
  #   class ProcedureDeclaration
  #     def add_modifies!(mods)
  #       work_list = [self]
  #       until work_list.empty?
  #         proc = work_list.shift
  #         new_mods = mods - proc.modifies
  #         unless new_mods.empty?
  #           proc.specifications << bpl("modifies #{new_mods.to_a * ", "};")
  #           work_list += proc.callers.to_a - work_list
  #         end
  #       end
  #     end
  #   end
  # end

end
