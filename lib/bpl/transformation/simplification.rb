module Bpl
  module Transformation
    class Simplification < Bpl::Pass

      def self.description
        <<-eos
          Various code simplifications.
          * remove trivial assume (true) statements
        eos
      end

      def run! program
        program.each do |elem|
          case elem
          when ProcedureDeclaration
            if elem.modifies.empty? && elem.returns.empty? && elem.body
              elem.replace_children(:body,nil)
            end

          when AssumeStatement, AssertStatement
            expr = elem.expression
            elem.remove if expr.is_a?(BooleanLiteral) && expr.value == true
          end
        end
      end
    end
  end
end
