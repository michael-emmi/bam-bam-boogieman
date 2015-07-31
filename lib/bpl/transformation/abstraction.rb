module Bpl
  module AST
    class Node
      def abstractions; Enumerator.new {} end
    end

    class VariableDeclaration
      def abstractions
        Enumerator.new do |y|
          # TODO remove the declaration, and all bindings (?)
        end
      end
    end

    class FunctionDeclaration
      def abstractions
        Enumerator.new do |y|
          unless body.nil?
            y.yield({
              elems: [copy.replace_children(:body,nil)],
              weight: count
            })
          end
        end
      end
    end

    class AxiomDeclaration
      def abstractions
        Enumerator.new do |y|
          unless expression.is_a?(BooleanLiteral)
            y.yield({
              elems: [copy.replace_children(:expression,bpl("true"))],
              weight: count
            })
          end
        end
      end
    end

    class ProcedureDeclaration
      def abstractions
        Enumerator.new do |y|
          unless attributes[:entrypoint] ||
                 attributes[:has_assertion] ||
                 body.nil?

            y.yield({
              elems: [copy.replace_children(:body,nil)],
              weight: body.count * 10
            })
          end
        end
      end
    end

    class Block
      def abstractions
        Enumerator.new do |y|
          abstracted = false
          abs_block = copy
          abs_block.statements.each do |stmt|
            if stmt.is_a?(CallStatement)
            end
            if abs_stmt = stmt.abstractions.first
              abstracted = true
              stmt.replace_with(*abs_stmt[:elems])
            end
          end
          y.yield({
            elems: [abs_block],
            weight: count * 10
          }) if abstracted
        end
      end
    end

    class AssertStatement
      def abstractions
        Enumerator.new do |y|
          unless expression.is_a?(BooleanLiteral)
            y.yield({
              elems: [copy.replace_children(:expression,bpl("false"))],
              weight: 100
            })
          end
        end
      end
    end

    class AssumeStatement
      def abstractions
        Enumerator.new do |y|
          unless expression.is_a?(BooleanLiteral)
            y.yield({
              elems: [copy.replace_children(:expression,bpl("true"))],
              weight: count
            })
          end
        end
      end
    end

    class AssignStatement
      def abstractions
        Enumerator.new do |y|
          ids = lhs.map do |expr|
            loop do
              break if expr.is_a?(Identifier)
              expr = expr.map
            end
            expr
          end
          y.yield({
            elems: ids.map{|id| bpl("havoc #{id};")},
            weight: count
          })
        end
      end
    end

    class CallStatement
      def abstractions
        Enumerator.new do |y|
          if procedure.declaration &&
             procedure.declaration.attributes[:has_assertion].nil?

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
            y.yield({
              elems: ids.map{|id| bpl("havoc #{id};")},
              weight: procedure.declaration.count
            })
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
      depends :resolution, :call_graph_construction, :modifies_correction
      depends :assertion_localization

      def each_abstraction(program)
        Enumerator.new do |y|
          program.each do |elem|
            elem.abstractions.each do |abs|
              y.yield abs.merge({original: elem})
            end
          end
        end
      end

      def run! program

        # Just return the number of abstractable elements (?)
        if count
          n = each_abstraction(program).count
          program.each_child {|c| c.remove }
          program.append_children(:declarations, bpl("assume {:count #{n}} true;"))
        end

        break_at_index = index ? [index.to_i,0].max : rand(1000)

        each_abstraction(program).sort{|a,b| a[:weight] <=> b[:weight]}.reverse.
        cycle.each_with_index do |abs,idx|
          if idx == break_at_index
            elem = abs[:original]
            repl = abs[:elems]
            info "ABSTRACTING (idx = #{idx}, weight = #{abs[:weight]})"
            info elem.to_s.indent
            info "#{"ON LINE #{elem.token}, " if elem.token}WITH"
            info repl.map(&:to_s).join("\n").indent
            info
            elem.replace_with(*repl)
            break
          end
        end
      end
    end
  end
end
