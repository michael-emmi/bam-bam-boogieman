module Bpl
  module Analysis
    class CallGraphConstruction < Bpl::Pass
      def self.description
        "Construct the call graph."
      end

      option :print, "Print out the call graph?"
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


        if print
          require 'graphviz'

          cfg = ::GraphViz.new("call graph", type: :digraph)
          program.each_child do |decl|
            next unless decl.is_a?(ProcedureDeclaration)
            cfg.add_nodes(decl.name)
            decl.callers.each {|c| cfg.add_edges(c.name,decl.name)}
          end
          cfg.output(pdf: "call-graph.pdf")
        end

      end
    end
  end
end
