module Bpl
  class ConditionalIdentification < Pass

    depends :cfg_construction, :domination
    switch "--conditional-identification", "Compute conditional blocks."
    result :conditionals, {}

    def successors blk; cfg_construction.successors[blk] end
    def dominators blk; domination.dominators[blk] end

    def exit?(blk) successors(blk).empty? end
    def loop?(blk) (dominators(blk) & successors(blk)).any? end
    def external?(blk, branches) (dominators(blk) & branches).empty? end

    def save_result(head, blocks, exits)
      conditionals[head] = { blocks: blocks, exits: exits }
    end

    def run! program
      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration) && proc.body

        proc.body.blocks.each do |head|
          branches = successors(head)
          next unless branches.count > 1

          blocks = Set.new([head])
          exits = Set.new
          work_list = branches.to_a

          until work_list.empty?
            blk = work_list.shift

            if loop?(blk)
              blocks = nil
              break

            elsif external?(blk, branches)
              exits << blk

            else
              blocks << blk
              successors(blk).each {|b| work_list |= [b]} unless exit?(blk)
            end
          end

          save_result(head, blocks, exits) if blocks
        end
      end
    end

  end
end
