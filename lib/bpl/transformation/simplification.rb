module Bpl
  module Transformation
    class Simplification < Bpl::Pass

      def self.description
        <<-eos
          Various code simplifications.
          * remove trivial assume (true) statements
        eos
      end

      depends :resolution, :modifies_correction

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
