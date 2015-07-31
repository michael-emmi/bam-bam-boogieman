module Bpl
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
        program.each do |elem|
          case elem
          when AxiomDeclaration
            expr = elem.expression
            if expr.is_a?(BooleanLiteral) && expr.value == true
              info "REMOVING TRIVIAL AXIOM"
              info elem.to_s.indent
              info
              elem.remove
            end

          when ProcedureDeclaration
            if elem.modifies.empty? && elem.returns.empty? && elem.body
              info "SIMPLIFYING TRIVIAL PROCEDURE"
              info elem.to_s.indent
              info
              elem.replace_children(:body,nil)
            end

          when VariableDeclaration, ConstantDeclaration
            if elem.bindings.all? do |b|
              b.parent.is_a?(HavocStatement) &&
              b.parent.identifiers.count == 1
            end then
              info "REMOVING UNUSED VARIABLE"
              info elem.to_s.indent
              info
              elem.bindings.each{|b| b.parent.remove}
              elem.remove
            end

          when AssumeStatement, AssertStatement
            expr = elem.expression
            if expr.is_a?(BooleanLiteral) && expr.value == true
              info "REMOVING TRIVIAL STATEMENT"
              info elem.to_s.indent
              info
              elem.remove
            end

          when Block
            if elem.statements.count == 1 &&
               elem.statements.first.is_a?(GotoStatement) &&
               elem.statements.first.identifiers.count == 1 &&
               elem.predecessors.count == 1 &&
               elem.predecessors.first.statements.last.is_a?(GotoStatement) &&
               elem.predecessors.first.statements.last.identifiers.count == 1

              info "REMOVING TRIVIAL BLOCK"
              info elem.to_s.indent
              info
              elem.predecessors.first.statements.last.replace_with(elem.statements.last)
              elem.remove
            end

          when CallStatement
            decl = elem.procedure.declaration
            if decl.modifies.empty? && decl.returns.empty?
              info "REMOVING TRIVIAL CALL"
              info elem.to_s.indent
              info
              elem.remove
            end

          end
        end
      end
    end
  end
end
