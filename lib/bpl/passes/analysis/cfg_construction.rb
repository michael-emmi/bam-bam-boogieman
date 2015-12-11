module Bpl
  class CfgConstruction < Pass

    depends :resolution
    option :print

    flag "--control-graphs [PRINT]", "Construct control-flow graphs." do |p|
      option :print, p
    end
    result :successors, {}
    result :predecessors, {}

    def run! program
      program.each do |b|
        next unless b.is_a?(Block)
        successors[b] = Set.new
        predecessors[b] = Set.new
      end

      program.each do |elem|
        next unless elem.is_a?(GotoStatement)
        if block = elem.each_ancestor.find {|b| b.is_a?(Block)}
          elem.identifiers.each do |id|
            if id.declaration
              predecessors[id.declaration] << block
              successors[block] << id.declaration
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
            cfg.add_edges("entry", b.name) if predecessors[b].empty?
            if b.statements.last.is_a?(ReturnStatement) ||
              !b.statements.last.is_a?(GotoStatement) && successors[b].empty?
            then
              cfg.add_edges(b.name, "return")
            end
            successors[b].each do |c|
              cfg.add_edges(b.name,c.name)
            end
          end
          cfg.output(pdf: "#{decl.name}.cfg.pdf")
        end
      end

    end
  end
end
