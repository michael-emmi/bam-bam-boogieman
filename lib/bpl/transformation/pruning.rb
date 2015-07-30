module Bpl
  module Transformation
    class Pruning < Bpl::Pass
      def self.description
        "Delete unreachable declarations."
      end

      depends :resolution, :entry_point_localization

      # TODO remove variables that are never read
      # TODO remove reads that are never used

      def run! program
        work_list = program.declarations.select{|d| d.attributes[:entrypoint]}
        until work_list.empty?
          decl = work_list.shift
          decl.attributes[:reachable] = []
          decl.each do |elem|
            case elem
            when Identifier, CustomType
              d = elem.declaration
              work_list |= [d] unless d.nil? || d.attributes[:reachable]
            end
          end
        end

        # Axiom declarations which reference reachable functions are reachable.
        program.declarations.each do |axiom|
          next unless axiom.is_a?(AxiomDeclaration)
          next if silly_expression?(axiom.expression)
          axiom.attributes[:reachable] = []
        end

        program.declarations.each do |d|
          unless d.attributes[:reachable]
            info "PRUNING UNUSED DECLARATION"
            info d.to_s.indent
            info
            d.remove
          end
        end

        program.each{|elem| elem.attributes.delete(:reachable)}
      end

      def silly_expression?(expr)
        case expr
        when QuantifiedExpression
          silly_expression?(expr.expression)
        when BinaryExpression
          silly_expression?(expr.lhs) || silly_expression?(expr.rhs)
        when FunctionApplication
          silly_expression?(expr.function)
        when Identifier
          expr.declaration.nil? || expr.declaration.attributes[:reachable].nil?
        else
          false
        end
      end
    end
  end
end
