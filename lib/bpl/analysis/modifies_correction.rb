module Bpl

  module Analysis
    def self.correct_modifies! program
      globals = program.global_variables.map(&:names).flatten
      work_list = []
      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration)
        work_list << proc
        next unless proc.body
        proc.specifications.reject!{|sp| sp.is_a?(ModifiesClause)}
        mods = Set.new
        proc.body.each do |stmt|
          case stmt
          when HavocStatement
            mods += stmt.identifiers.map(&:name) & globals
          when AssignStatement
            mods += stmt.lhs.map(&:name) & globals
          when CallStatement
            mods += stmt.assignments.map(&:name) & globals
            stmt.declaration.callers << proc
          end
        end
        proc.specifications << bpl("modifies #{mods.to_a * ", "};") \
          unless mods.empty?
      end

      until work_list.empty?
        proc = work_list.shift
        proc.callers.each do |caller|
          mods = proc.modifies - caller.modifies
          unless mods.empty?
            caller.specifications << bpl("modifies #{mods.to_a * ", "};")
            work_list << caller unless work_list.include?(caller)
          end
        end
      end
    end
  end

  module AST
    class ProcedureDeclaration
      def add_modifies!(mods)
        work_list = [self]
        until work_list.empty?
          proc = work_list.shift
          new_mods = mods - proc.modifies
          unless new_mods.empty?
            proc.specifications << bpl("modifies #{new_mods.to_a * ", "};")
            work_list += proc.callers.to_a - work_list
          end
        end
      end
    end
  end

end
