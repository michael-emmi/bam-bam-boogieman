module Bpl
  module Analysis
    class CfgConstruction < Bpl::Pass
      def self.description
        "Construct control-flow graphs for each procedure."
      end

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
      end
    end
  end
end
