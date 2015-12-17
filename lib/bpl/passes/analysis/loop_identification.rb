module Bpl
  class LoopIdentification < Pass

    depends :cfg_construction, :domination
    switch "--loop-identification", "Compute loops."
    result :loops, {}

    def run! program
      dominators = domination.dominators
      cfg = cfg_construction

      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration) && proc.body
        proc.body.blocks.each do |blk|
          (dominators[blk] & cfg.successors[blk]).each do |head|
            loops[head] = Set.new
            loops[head].merge([head,blk])
            work_list = [blk]
            until work_list.empty?
              cfg.predecessors[work_list.shift].each do |pred|
                next if loops[head].include?(pred)
                loops[head].add(pred)
                work_list |= [pred]
              end
            end
            loops[head] = proc.body.blocks.select{|b| loops[head].include?(b)}
          end
        end
      end
    end

  end
end
