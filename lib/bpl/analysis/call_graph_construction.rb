module Bpl
  module Analysis
    class CallGraphConstruction < Bpl::Pass

      depends :resolution
      option :print

      flag "--call-graphs [PRINT]", "Construct call graphs." do |p|
        option :print, p
      end

      result :callers, {}

      def run! program
        callers.clear
        program.declarations.each do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          callers[decl] = Set.new
        end
        program.each do |elem|
          next unless elem.is_a?(CallStatement)
          callee = elem.procedure.declaration
          caller = elem.each_ancestor.find do |decl|
            decl.is_a?(ProcedureDeclaration)
          end
          callers[callee] << caller if caller
        end


        if print
          require 'graphviz'

          cfg = ::GraphViz.new("call graph", type: :digraph)
          program.each_child do |decl|
            next unless decl.is_a?(ProcedureDeclaration)
            cfg.add_nodes(decl.name)
            callers[decl].each {|c| cfg.add_edges(c.name,decl.name)}
          end
          cfg.output(pdf: "call-graph.pdf")
        end

      end
    end
  end
end
