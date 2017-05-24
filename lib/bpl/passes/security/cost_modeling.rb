module Bpl
  class CostModeling < Pass
    EXEMPTION_LIST = [
      '\$alloc',
      '\$free',
      'boogie_si_',
      '__VERIFIER_',
      '__SMACK_(?!static_init)',
      'llvm.dbg'
    ]

    EXEMPTIONS = /#{EXEMPTION_LIST * "|"}/

    def exempt? decl
      EXEMPTIONS.match(decl) && true
    end

    depends :normalization
    depends :ct_annotation, :cfg_construction
    depends :resolution, :loop_identification
    depends :definition_localization, :liveness
    invalidates :all
    switch "--cost-modeling", "Add cost-tracking variables."


    def run! program
      # add cost global variable
      program.prepend_children(:declarations, bpl("var $l: int;"))

      # update cost global variable
      program.each_child do |decl|
        next unless decl.is_a?(ProcedureDeclaration)
        next if exempt?(decl.name)
        next unless decl.body
        decl.body.blocks.each do |block|
          block.each do |stmt|
            next unless stmt.is_a?(AssumeStatement)
            next unless values = stmt.get_attribute(:'smack.InstTimingCost.Int64')
            stmt.insert_after(bpl("$l := $add.i32($l, #{values.first});"))
          end
        end
      end

    end
  end
end
