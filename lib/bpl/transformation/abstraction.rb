module Bpl
  module AST
    class Node
      def abstract
      end

      def abstractions
        Enumerator.new do |y|
          abstract{|abs| y.yield abs}
        end
      end
    end

    class VariableDeclaration
      def abstract
        yield({
          description: "abstracting variable",
          weight: 1000000,
          action: Proc.new do
            bindings.each do |b|

              next if b.parent.is_a?(ModifiesClause)
              next if b.parent.is_a?(HavocStatement)

              ok = b.each_ancestor.any? do |a|
                case a
                when AssignStatement, AssumeStatement, AssertStatement
                  if abs = a.abstractions.first
                    abs[:action].call
                    true
                  end
                else
                  false
                end
              end

              next if ok

              fail "unxpected binding: #{b.parent}"
            end
          end
        })
      end
    end

    class FunctionDeclaration
      def abstract
        unless body.nil?
          yield({
            description: "removing function body",
            weight: count,
            action: Proc.new do
              replace_children(:body,nil)
            end
          })
        end
      end
    end

    class AxiomDeclaration
      def abstract
        unless expression.is_a?(BooleanLiteral)
          yield({
            description: "weakening axiom",
            weight: count,
            action: Proc.new do
              replace_children(:expression, bpl("true"))
            end
          })
        end
      end
    end

    class ProcedureDeclaration
      def abstract
        unless attributes[:entrypoint] ||
               attributes[:has_assertion] ||
               body.nil?
          yield({
            description: "removing procedure body",
            weight: body.count * 10,
            action: Proc.new do
              replace_children(:body,nil)
            end
          })
        end
      end
    end

    class Block
      def abstract
        abss = statements.map {|s| s.abstractions.first}.compact
        yield({
          description: "abstracting block’s statements",
          weight: count * 10,
          action: Proc.new do
            abss.each {|abs| abs[:action].call}
          end
        }) unless abss.empty?

        # TODO chop up big blocks too
      end
    end

    class AssertStatement
      def abstract
        unless expression.is_a?(BooleanLiteral)
          yield({
            description: "strengthening assertion",
            weight: 100,
            action: Proc.new do
              replace_children(:expression, bpl("false"))
            end
          })
        end
      end
    end

    class AssumeStatement
      def abstract
        unless expression.is_a?(BooleanLiteral)
          yield({
            description: "weakening assumption",
            weight: count,
            action: Proc.new do
              replace_children(:expression, bpl("true"))
            end
          })
        end
      end
    end

    class AssignStatement
      def abstract
        ids = lhs.map do |expr|
          loop do
            break if expr.is_a?(Identifier)
            expr = expr.map
          end
          expr
        end
        yield({
          description: "havocing assigned variables",
          weight: count,
          action: Proc.new do
            replace_with(*ids.map{|id| bpl("havoc #{id};")})
          end
        })
      end
    end

    class CallStatement
      def abstract
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
          yield({
            description: "havocing assignments and modifies",
            weight: procedure.declaration.count,
            action: Proc.new do
              replace_with(*ids.map{|id| bpl("havoc #{id};")})
            end
          })
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

      depends :call_graph_construction, :modifies_correction
      depends :assertion_localization
      depends :resolution

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
          program.each_child(&:remove)
          program.append_children(:declarations, bpl("assume {:count #{n}} true;"))
        end

        break_at_index = index ? [index.to_i,0].max : rand(1000)

        each_abstraction(program).sort{|a,b| a[:weight] <=> b[:weight]}.reverse.
        cycle.each_with_index do |abs,idx|
          if idx == break_at_index
            info "ABSTRACTION * #{abs[:description]}"
            info abs[:original].to_s.indent
            info
            abs[:action].call
            break
          end
        end
      end
    end
  end
end
