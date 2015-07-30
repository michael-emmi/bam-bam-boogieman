module Bpl
  module Analysis
    class CallGraphConstruction < Bpl::Pass
      def self.description
        "Construct the call graph."
      end

      depends :resolution

      def run! program
        program.each do |elem|
          next unless elem.is_a?(CallStatement)
          callee = elem.procedure.declaration
          caller = elem.each_ancestor.find do |decl|
            decl.is_a?(ProcedureDeclaration)
          end
          callee.callers << caller if caller
        end
      end
    end
  end
end
