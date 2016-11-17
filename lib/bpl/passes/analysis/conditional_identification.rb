module Bpl
  class ConditionalIdentification < Pass

    depends :cfg_construction, :domination
    switch "--conditional-identification", "Compute conditional blocks."
    result :conditionals, {}

    def run! program
      dominators = domination.dominators
      cfg = cfg_construction

      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration) && proc.body
        proc.body.blocks.each do |head|
          branches = cfg.successors[head]

          next unless branches.count > 1
          next unless (dominators[head] & branches).empty?

          conditionals[head] = Set.new
          conditionals[head].add(head)
          work_list = [head]
          until work_list.empty?
            cfg.successors[work_list.shift].each do |blk|
              next if (dominators[blk] & branches).empty?
              conditionals[head].add(blk)
              work_list |= [blk]
            end
          end
        end
      end
    end

  end
end
