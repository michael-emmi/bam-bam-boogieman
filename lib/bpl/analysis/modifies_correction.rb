module Bpl
  module AST

    class Program
      def correct_modifies!
        globals = global_variables.map(&:names).flatten
        work_list = []
        @declarations.each do |proc|
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

  end
end
