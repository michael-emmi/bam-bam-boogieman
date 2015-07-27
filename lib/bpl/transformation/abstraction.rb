module Bpl
  module AST
    class Node
      def abstractions; Enumerator.new {} end
    end

    class FunctionDeclaration
      def abstractions
        Enumerator.new do |y|
          unless body.nil?
            y.yield FunctionDeclaration.new(
              attributes: attributes, name: name,
              type_arguments: type_arguments, arguments: arguments,
              return: self.return
            )
          end
        end
      end
    end

    class AxiomDeclaration
      def abstractions
        Enumerator.new do |y|
          unless expression.is_a?(BooleanLiteral)
            y.yield AxiomDeclaration.new(
              attributes: attributes,
              expression: BooleanLiteral.new(value: true)
            )
          end
        end
      end
    end

    class ProcedureDeclaration
      def abstractions
        Enumerator.new do |y|
          unless attributes[:entrypoint] || body.nil?
            y.yield ProcedureDeclaration.new(
              attributes: attributes,
              name: name, type_arguments: type_arguments,
              parameters: parameters, returns: returns,
              specifications: specifications
            )
          end
        end
      end
    end

    class AssertStatement
      def abstractions
        Enumerator.new do |y|
          unless expression.is_a?(BooleanLiteral)
            y.yield AssertStatement.new(
              attributes: attributes,
              expression: BooleanLiteral.new(value: false)
            )
          end
        end
      end
    end

    class AssumeStatement
      def abstractions
        Enumerator.new do |y|
          unless expression.is_a?(BooleanLiteral)
            y.yield AssumeStatement.new(
              attributes: attributes,
              expression: BooleanLiteral.new(value: true)
            )
          end
        end
      end
    end

    class AssignStatement
      def abstractions
        Enumerator.new do |y|
          lvalues = lhs.map do |expr|
            loop do
              break if expr.is_a?(Identifier)
              expr = expr.map
            end
            expr
          end
          y.yield HavocStatement.new(
            attributes: attributes,
            identifiers: lvalues
          )
        end
      end
    end

    class CallStatement
      def abstractions
        Enumerator.new do |y|
          return unless procedure.declaration
          ids = procedure.declaration.modifies
          assignments.each do |expr|
            loop do
              if expr.is_a?(Identifier)
                ids << expr
                break
              else
                expr = expr.map
              end
            end
          end
          if ids.empty?
            y.yield AssumeStatement.new(
              attributes: attributes,
              expression: BooleanLiteral.new(value: true)
            )
          else
            y.yield HavocStatement.new(
              attributes: attributes,
              identifiers: ids
            )
          end
        end
      end
    end

  end

  module Transformation
    class Abstraction < Bpl::Pass
      def self.description
        "Abstract the program, one element at a time."
      end

      option :index, "The index of abstractable program elements to abstract."
      option :count, "Just return the number of abstractable program elements."

      def each_abstraction(program)
        Enumerator.new do |y|
          program.each do |elem|
            elem.abstractions.each do |*abs|
              y.yield elem, *abs
            end
          end
        end
      end

      def run! program

        # Just return the number of abstractable elements (?)
        if count
          n = each_abstraction(program).count
          program.each_child {|c| c.remove }
          program.append_child(:declarations, bpl("assume {:count #{n}} true;"))
        end

        break_at_index = index ? [index.to_i,0].max : rand(1000)
        each_abstraction(program).cycle.each_with_index do |elem_n_abs,idx|
          if idx == break_at_index
            elem, *abs = elem_n_abs
            info "ABSTRACTING (idx = #{idx})"
            info elem.to_s.indent
            info "#{"ON LINE #{elem.token}, " if elem.token}WITH"
            info abs.map(&:to_s).join("\n").indent
            elem.replace_with(*abs)
            break
          end
        end
      end
    end
  end
end
