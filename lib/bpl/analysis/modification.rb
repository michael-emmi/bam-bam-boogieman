module Bpl

  module AST
    class Identifier < Expression
      def ident; self end
    end
    class MapSelect < Expression
      def ident; @map.ident end
    end
  end

  module Analysis
    class Modification < Bpl::Pass

      depends :call_graph_construction
      flag "--modification", "Compute modified variables."
      result :modifies, {}

      def run! program
        work_list = []
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          work_list << proc
          modifies[proc] = Set.new
          proc.each do |elem|
            case elem
            when HavocStatement
              modifies[proc] +=
                elem.identifiers.select(&:is_global?).map(&:name)
            when AssignStatement
              modifies[proc] +=
                elem.lhs.map(&:ident).select(&:is_global?).map(&:name)
            when CallStatement
              modifies[proc] +=
                elem.assignments.map(&:ident).select(&:is_global?).map(&:name)
            end
          end
        end

        until work_list.empty?
          proc = work_list.shift
          targets = call_graph_construction.callers[proc]
          targets << proc.declaration if proc.respond_to?(:declaration) && proc.declaration
          targets.each do |caller|
            mods = modifies[proc] - modifies[caller]
            unless mods.empty?
              modifies[caller] += mods
              work_list |= [caller]
            end
          end
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
