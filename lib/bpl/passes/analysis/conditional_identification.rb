module Bpl
  class ConditionalIdentification < Pass

    depends :cfg_construction, :domination
    switch "--conditional-identification", "Compute conditional blocks."
    result :conditionals, {}

    def successors blk; cfg_construction.successors[blk] end
    def dominators blk; domination.dominators[blk] end

    def exit_block?(blk, branches)
      successors(blk).empty? || (dominators(blk) & branches).empty?
    end

    def back_edge?(blk)
      (dominators(blk) & successors(blk)).any?
    end

    def save_result(head, blocks, exits)
      conditionals[head] = { blocks: blocks, exits: exits }
    end

    def run! program
      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration) && proc.body

        proc.body.blocks.each do |head|
          branches = successors(head)
          next unless branches.count > 1

          blocks = Set.new
          exits = Set.new
          work_list = [head]

          until work_list.empty?
            blk = work_list.shift
            blocks << blk

            if back_edge?(blk)
              blocks = nil
              break

            elsif exit_block?(blk, branches)
              exits << blk

            else
              successors(blk).each {|b| work_list |= blk}
            end
          end

          save_result(head, blocks, exits) if blocks
        end
      end
    end

  end
end
