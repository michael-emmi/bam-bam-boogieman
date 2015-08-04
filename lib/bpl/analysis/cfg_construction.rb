

module Bpl
  module Analysis
    class CfgConstruction < Bpl::Pass
      def self.description
        "Construct control-flow graphs for each procedure."
      end

      option :print, "Print out the CFGs?"
      depends :resolution

      def run! program
        program.each do |blk|
          if blk.is_a?(Block)
            blk.successors.clear
            blk.predecessors.clear
          end
        end

        program.each do |elem|
          next unless elem.is_a?(GotoStatement)
          if block = elem.each_ancestor.find {|b| b.is_a?(Block)}
            elem.identifiers.each do |id|
              if id.declaration
                id.declaration.predecessors << block
                block.successors << id.declaration
              end
            end
          end
        end

        if print
          require 'graphviz'

          program.each_child do |decl|
            next unless decl.is_a?(ProcedureDeclaration)
            next unless decl.body
            cfg = ::GraphViz.new(decl.name, type: :digraph)
            cfg.add_nodes(decl.body.blocks.map(&:name), shape: :rect)
            decl.body.blocks.each do |b|
              cfg.add_edges("entry", b.name) if b.predecessors.empty?
              if b.statements.last.is_a?(ReturnStatement) ||
                !b.statements.last.is_a?(GotoStatement) && b.successors.empty?
              then
                cfg.add_edges(b.name, "return")
              end
              b.successors.each do |c|
                cfg.add_edges(b.name,c.name)
              end
            end
            cfg.output(pdf: "#{decl.name}.cfg.pdf")
          end
        end

      end
    end
  end
end
