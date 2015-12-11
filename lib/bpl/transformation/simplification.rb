module Bpl

  module AST
    class Node
      def simplify(cfg, mods, asserts)
      end
    end

    class AxiomDeclaration
      def simplify(cfg, mods, asserts)
        if expression.is_a?(BooleanLiteral) && expression.value == true
          yield({
            description: "removing trivial axiom",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

    class VariableDeclaration
      def simplify(cfg, mods, asserts)
        if bindings.all? do |b|
          b.parent.is_a?(HavocStatement) || b.parent.is_a?(ModifiesClause)
        end then
          yield({
            description: "removing unused variable(s) #{names * ", "}",
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
      def simplify(cfg, mods, asserts)
        if body &&
          !asserts.has_assert[self] &&
          mods.modifies[self].empty? &&
          returns.all? {|r| r.bindings.all? {|b| b.parent.is_a?(HavocStatement)}}
        then
          yield({
            description: "removing body of procedure #{name}",
            action: Proc.new do
              replace_children(:body,nil)
            end
          })
        end
      end
    end

    class Body
      def simplify(cfg, mods, asserts)
        blocks.each do |bb|
          # if bb.successors.count == 1 &&
          #   bb.statements.last.is_a?(GotoStatement) &&
          #   bb.statements.last.identifiers.count == 1
          # then
          #   b = bb.successors.first
          #   if b.predecessors.count == 1 &&
          #      b.statements.count == 1 &&
          #      b.statements.last.is_a?(GotoStatement)
          #   then
          #     yield({
          #       description: "merging trivial block",
          #       elems: [bb,b],
          #       action: Proc.new do
          #         bb.statements.last.replace_with(b.statements.last.copy)
          #         b.remove
          #       end
          #     })
          #   end

          if cfg.successors[bb].count == 2 &&
             bb.statements.last.is_a?(GotoStatement) &&
             bb.statements.last.identifiers.count == 2
          then
            b1, b2 = cfg.successors[bb].to_a
            if b1 != b2 &&
               cfg.successors[b1].count == 1 &&
               cfg.successors[b1] == cfg.successors[b2] &&
               b1.statements.count == 1 &&
               b1.statements.last.is_a?(GotoStatement) &&
               b2.statements.count == 1 &&
               b2.statements.last.is_a?(GotoStatement)
            then
              yield({
                description: "merging trivial branch",
                elems: [bb,b1,b2],
                action: Proc.new do
                  bb.statements.last.replace_with(b1.statements.last.copy)
                  b1.remove
                  b2.remove
                end
              })
            end
          end
        end
      end
    end

    class Block
      def simplify(cfg, mods, asserts)
        if statements.count == 1 &&
           statements.first.is_a?(GotoStatement) &&
           statements.first.identifiers.count == 1 &&
           cfg.predecessors[self].count == 1 &&
           cfg.predecessors[self].first.statements.last.is_a?(GotoStatement) &&
           cfg.predecessors[self].first.statements.last.identifiers.count == 1
          yield({
            description: "removing trivial block",
            action: Proc.new do
              cfg.predecessors[self].first.statements.last.replace_with(statements.last)
              remove
            end
          })
        end
      end
    end

    class AssertStatement
      def simplify(cfg, mods, asserts)
        if expression.is_a?(BooleanLiteral) && expression.value == true
          yield({
            description: "removing trivial assert",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

    class AssumeStatement
      def simplify(cfg, mods, asserts)
        if expression.is_a?(BooleanLiteral) && expression.value == true
          yield({
            description: "removing trivial assume",
            action: Proc.new do
              remove
            end
          })
        end
      end
    end

    class CallStatement
      def simplify(cfg, mods, asserts)
        decl = procedure.declaration
        if decl.modifies.empty? &&
           decl.returns.empty? &&
           !asserts.has_assert[decl]
#
          yield({
            description: "removing trivial call",
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

      depends :resolution
      depends :modification, :cfg_construction, :assertion_localization
      flag "--simplification", "Various code simplifications."

      def run! program
        program.each do |elem|
          elem.simplify(cfg_construction, modification, assertion_localization) do |x|
            info "SIMPLIFICATION * #{x[:description]}"
            (x[:elems]||[elem]).each {|e| info; info Printing.indent(e.to_s).indent}
            info
            x[:action].call()
            invalidates :all
            redo!
          end
        end
      end

    end
  end
end
