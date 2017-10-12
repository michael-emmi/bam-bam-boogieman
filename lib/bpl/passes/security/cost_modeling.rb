module Bpl
  class CostModeling < Pass

    # TODO: This has to refactored -- it is copied from shadowing.rb
    EXEMPTION_LIST = [
      '\$alloc',
      '\$free',
      'boogie_si_',
      '__VERIFIER_',
      '__SIDEWINDER_',
      '__SMACK_(?!static_init)',
      '__memcpy_chk',
      'llvm.dbg',
      'llvm.lifetime',
      'llvm.objectsize',
      'llvm.stacksave',
      'llvm.stackrestore'
    ]

    EXEMPTIONS = /#{EXEMPTION_LIST * "|"}/

    STUB_ANNOTATION = :__VERIFIER_TIMING_CONTRACT

    def stub? decl
      decl.specifications.each.any? { |s| s.has_attribute? STUB_ANNOTATION }
    end

    LEAKAGE_ANNOTATION_NAME =  "__VERIFIER_ASSUME_LEAKAGE"
    CURRENT_LEAKAGE_NAME = "__VERIFIER_CURRENT_LEAKAGE"

    def exempt? decl
      EXEMPTIONS.match(decl) && true
    end

    depends :normalization
    depends :ct_annotation, :cfg_construction
    depends :resolution, :loop_identification
    depends :definition_localization, :liveness
    invalidates :all
    switch "--cost-modeling", "Add cost-tracking variables."

    def is_annotation_stmt? (stmt, annot_name)
      return false unless stmt.is_a?(CallStatement)
      return stmt.procedure.to_s == annot_name
    end

    def has_annotation?(decl, annot_name)
      return false unless decl.body
      return (not (decl.body.select{|r| is_annotation_stmt?(r,annot_name)}.empty?))
    end

    #the annotation should have one argument, and we just want whatever it is
    def get_annotation_value annotationStmt
      raise "annotation should have one argument" unless annotationStmt.arguments.length == 1
      return annotationStmt.arguments.first.to_s
    end
    
    def annotate_function_body! decl
      if (has_annotation?(decl, LEAKAGE_ANNOTATION_NAME)) then
        decl.body.select{ |s| is_annotation_stmt?(s, LEAKAGE_ANNOTATION_NAME)}.each do |s| 
          value = get_annotation_value s
          s.insert_after(bpl("$l := $add.i32($l, #{value});"))
        end
      else
        decl.body.select{ |s| s.is_a?(AssumeStatement)}.each do |stmt|
          next unless values = stmt.get_attribute(:'smack.InstTimingCost.Int64')
          stmt.insert_after(bpl("$l := $add.i32($l, #{values.first});"))
        end
      end
    end



    def cost_of block
      assumes = block.select{ |s| s.is_a?(AssumeStatement)}
      assumes.inject(0) do |acc, stmt|
        if values = stmt.get_attribute(:'smack.InstTimingCost.Int64')
          acc += values.first.show.to_i
        end
        acc
      end
    end

    def extract_control_blocks(head, blocks, cfg)

      control_blocks = []
      blocks.each do |b|
        cfg.successors[b].each do |succ|
          next if blocks.include?(succ)
          control_blocks.push(b)
        end
      end

      raise StandardError unless control_blocks.size.equal? 1

      exit_block = cfg.successors[control_blocks[0]].detect{|b| !blocks.include?(b)}

      return control_blocks, exit_block if control_blocks[0] == head

      work_list = control_blocks.clone
      until work_list.empty?
        cfg.predecessors[work_list.shift].each do |pred|
          next if control_blocks.include?(pred)
          next if pred == head && (control_blocks.push(pred) || true)
          control_blocks.push(pred)
          work_list |= [pred]
        end
      end

      return control_blocks, exit_block
    end


    def summarize_loops! decl

      cfg = cfg_construction

      loop_identification.loops.each do |head, blocks|

        block = decl.body.blocks.find do |b|
          b.name == head.name && decl.name == head.parent.parent.name
        end

        next unless block

        # identify entry block and insert current leakage variable
        entry = cfg.predecessors[head].detect{ |b| !blocks.include?(b) }
        entry_lkg = entry.detect{|s| is_annotation_stmt?(s, CURRENT_LEAKAGE_NAME) }

        next unless entry_lkg

        entry_lkg.remove
        curr_lkg_var = entry_lkg.assignments.first
        curr_lkg_asn = AssignStatement.new lhs:curr_lkg_var, rhs: bpl("$l")

        entry.statements.last.insert_before(curr_lkg_asn)


        # idenify loop segments and compute costs
        cntr, ex = extract_control_blocks(head, blocks, cfg)
        body = blocks - cntr

        cntr_cost = cntr.inject(0) { |acc, blk| (acc + (cost_of blk)) }
        body_cost = body.inject(0) { |acc, blk| (acc + (cost_of blk)) }

        # identify loop counter
        cnt_update_block = cfg.predecessors[head].detect{ |b| blocks.include?(b) }
        args = decl.declarations.inject([]) { |acc, d| acc << d.idents[0].name }
        counter = (liveness.live[head] & liveness.live[cnt_update_block]) - args

        # compute and insert cost invariant
        head.prepend_children(:statements,
          bpl("assert ($l == #{curr_lkg_var}+#{counter.first}*(#{body_cost}+#{cntr_cost}));"))

      end

    end

    def redirect_to_stub! decl
      args, asmt = [], []
      decl.parameters.each {|d| args.push(d.names.flatten).flatten}
      decl.returns.each {|d| asmt.push(d.names.flatten).flatten}
      args, asmt = args.flatten, asmt.flatten
      stub_name = decl.specifications.first.get_attribute(STUB_ANNOTATION)&.first&.first
      stub_call = bpl("call #{asmt.join(",")} := #{stub_name}(#{args.join(",")});")
      myblock = Block.new(names: [], statements: [stub_call])
      decl.body.replace_children(:locals, [])
      decl.body.replace_children(:blocks, myblock)
    end

    def run! program
      # add cost global variable
      program.prepend_children(:declarations, bpl("var $l: int;"))
      program.prepend_children(:declarations, bpl("var $__delta: int;"))

      # update cost global variable
      program.each_child do |decl|
        next unless decl.is_a?(ProcedureDeclaration)
        next if exempt?(decl.name)
        next unless decl.body

        decl.add_attribute(:cost_modeling)

        redirect_to_stub!(decl) if stub?(decl)
        if decl.has_attribute?(:entrypoint)
          decl.body.blocks.first.statements.first.insert_before(bpl("$l := 0;"))
        end

        summarize_loops! decl

        annotate_function_body! decl

      end

    end
  end
end
