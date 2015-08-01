module Bpl

  module AST
    class Node
      def simplify
      end
    end

    class AxiomDeclaration
      def simplify
        if expression.is_a?(BooleanLiteral) && expression.value == true
          yield({
            message: "removing trivial axiom",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

    class VariableDeclaration
      def simplify
        if bindings.all? do |b|
          b.parent.is_a?(HavocStatement) || b.parent.is_a?(ModifiesClause)
        end then
          yield({
            message: "removing unused variable",
            action: Proc.new do
              bindings.each do |b|
                if b.parent.identifiers.count == 1
                  b.parent.remove
                else
                  b.remove
                end
              end
              remove
            end
          })
        end
      end
    end

    class ProcedureDeclaration
      def simplify
        if modifies.empty? && returns.empty? && body
          yield({
            message: "simplifying trivial procedure",
            action: Proc.new do
              replace_children(:body,nil)
            end
          })
        end
      end
    end

    class Block
      def simplify
        if statements.count == 1 &&
           statements.first.is_a?(GotoStatement) &&
           statements.first.identifiers.count == 1 &&
           predecessors.count == 1 &&
           predecessors.first.statements.last.is_a?(GotoStatement) &&
           predecessors.first.statements.last.identifiers.count == 1
          yield({
            message: "removing trivial block",
            action: Proc.new do
              predecessors.first.statements.last.replace_with(statements.last)
              remove
            end
          })
        end
      end
    end

    class AssertStatement
      def simplify
        if expression.is_a?(BooleanLiteral) && expression.value == true
          yield({
            message: "removing trivial assert",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

    class AssumeStatement
      def simplify
        if expression.is_a?(BooleanLiteral) && expression.value == true
          yield({
            message: "removing trivial assume",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

    class CallStatement
      def simplify
        decl = procedure.declaration
        if decl.modifies.empty? && decl.returns.empty?
          yield({
            message: "removing trivial call",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

  end

  module Transformation
    class Simplification < Bpl::Pass

      def self.description
        <<-eos
          Various code simplifications.
          * remove trivial assume (true) statements
        eos
      end

      depends :resolution, :modifies_correction, :cfg_construction

      def run! program
        loop do
          updated = false
          program.each do |elem|
            elem.simplify do |x|
              info "SIMPLIFICATION * #{x[:message]}"
              info elem.to_s.indent
              info
              x[:action].call()
              updated = true
            end
          end
          break unless updated
        end
      end

    end
  end
end
