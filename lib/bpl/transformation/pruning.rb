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
        work_list = program.declarations.select{|d| d.has_attribute? :entrypoint}
        until work_list.empty?
          decl = work_list.shift
          decl.add_attribute :reachable
          decl.each do |elem|
            case elem
            when Identifier, CustomType
              d = elem.declaration
              work_list |= [d] unless d.nil? || d.has_attribute?(:reachable)
            end
          end
          decl.bindings.each do |elem|
            ax = elem.each_ancestor.find{|d| d.is_a?(AxiomDeclaration)}
            work_list |= [ax] unless ax.nil? || ax.has_attribute?(:reachable)
          end
        end

        program.declarations.each do |d|
          unless d.has_attribute(:reachable)
            info "PRUNING UNUSED DECLARATION"
            info
            info d.to_s.indent
            info
            d.remove
          end
        end

        program.each{|elem| elem.remove_attribute :reachable}
      end

      def silly_expression?(expr)
        case expr
        when QuantifiedExpression
          silly_expression?(expr.expression)
        when BinaryExpression
          silly_expression?(expr.lhs) && silly_expression?(expr.rhs)
        when FunctionApplication
          silly_expression?(expr.function)
        when Identifier
          !expr.declaration.has_attribute?(:reachable)
        else
          false
        end
      end
    end
  end
end
