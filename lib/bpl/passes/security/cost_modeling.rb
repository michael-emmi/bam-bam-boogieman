# typed: false
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

    LEAKAGE_ANNOTATION_NAME = "__VERIFIER_ASSUME_LEAKAGE"
    ADD_LEAK_ANNOTATION_NAME = "__VERIFIER_ADD_LEAKAGE"
    INV_VAR_ANNOTATION_NAME = "__VERIFIER_LOOP_VAR"

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

    # Iterates over timing annotations of a block and sums them up.
    def cost_of block
      assumes = block.select{ |s| s.is_a?(AssumeStatement)}
      cost = assumes.inject(0) do |acc, stmt|
        if values = stmt.get_attribute(:'smack.InstTimingCost.Int64')
          acc += values.first.show.to_i
        end
        acc
      end

      return cost
    end


    # Given a loop, this function returns a tuple containing the loop's control blocks
    # and its (unique) exit block.
    def extract_control_blocks(head, blocks, cfg)

      # Find the last control block, i.e. the block that has a successor that is not in the loop.
      last_control_block = nil
      blocks.each do |b|
        cfg.successors[b].each do |succ|
          next if blocks.include?(succ)
          # The last control block has to be unique.
          raise StandardError if last_control_block
          last_control_block = b
        end
      end

      # The control block's succesor that is not in the loop is the unique exit block.
      exit_block = cfg.successors[last_control_block].select{|b| !blocks.include?(b)}
      raise StandardError unless exit_block.size == 1

      # In the case of a simple control statement, the last control block is the head block
      # and there are no other control blocks.
      return [last_control_block], exit_block if last_control_block == head

      # If the loop has a complicated control statement, there will be multiple control
      # blocks. Identify them all the way up to the head block.
      work_list = [last_control_block]
      control_blocks = [last_control_block]
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


    # Given a set of blocks, returns 'GotoStatement's of branches
    def extract_branches blocks

      branches = []
      blocks.each do |block|
        block.each do |stmt|
          case stmt
          when GotoStatement
            next if stmt.identifiers.length < 2
            unless stmt.identifiers.length == 2
              fail "Unexpected goto statement: #{stmt}"
            end

            if annotation = stmt.previous_sibling
              fail "Expected :branchcond annotation" unless
                annotation.has_attribute?(:branchcond)
            end

            branches.push(stmt)
          end
        end
      end
      return branches
    end

    # This function automatically computes and inserts leakage-related loop invariants.
    # The invariants are of the form:
    # leakage = leakage_before_entering + loop_counter * (loop_body_cost + control_block_cost)
    def summarize_loops! decl

      cfg = cfg_construction


      # Identify loop-cost related annotations
      loop_vars = []
      if (has_annotation?(decl, INV_VAR_ANNOTATION_NAME)) then
        decl.body.select{ |s| is_annotation_stmt?(s, INV_VAR_ANNOTATION_NAME)}.each do |s|
          value = get_annotation_value s
          loop_vars.push(value)
        end
      end

      loop_identification.loops.each do |head, blocks|

        # Only deal with loops that are in the procedure we are processing.
        loop_is_in_decl = decl.body.blocks.find do |b|
          b.name == head.name && decl.name == head.parent.parent.name
        end

        next unless loop_is_in_decl

        # Create leakage_before_entering variable and insert right before the loop head.
        lkg_before_var = decl.body.fresh_var("i32", prefix: "$loop_l")
        lkg_before_asn = AssignStatement.new lhs: lkg_before_var, rhs: bpl("$l")

        entry = cfg.predecessors[head].detect{ |b| !blocks.include?(b) }
        entry.statements.last.insert_before(lkg_before_asn)


        # Identify control blocks, body blocks and compute their costs.
        control_blocks, exit_block = extract_control_blocks(head, blocks, cfg)
        body_blocks = blocks - control_blocks

        # Identify non-nested branches, their consequent blocks and their alternative blocks.
        # TODO: raise error/warning when we encounetr a non-nested branch.

        gotos = extract_branches body_blocks

        branches = {}
        gotos.each do |goto|
          consequent = goto.identifiers.first.declaration
          alternative = goto.identifiers.last.declaration
          branches[goto] = consequent, alternative
        end

        straight_line_blocks = body_blocks
        branches.each_value do |cons, alt|
          straight_line_blocks -= [cons, alt]
        end

        control_cost = control_blocks.inject(0) { |acc, blk| (acc + (cost_of blk)) }
        straight_line_cost = straight_line_blocks.inject(0) { |acc, blk| (acc + (cost_of blk)) }

        # Identify the loop_counter variable as the intersection of live variables of the head
        # block and its predecessor.
        counter_update_block = cfg.predecessors[head].detect{ |b| blocks.include?(b) }
        args = decl.declarations.inject([]) { |acc, d| acc << d.idents[0].name }
        counter = ((liveness.live[head] & liveness.live[counter_update_block]) - args).first

        cons_inv = ""
        branches.values.each_with_index do |(cons, alt), idx|
          cons_cost = cost_of cons
          #alt_cost = cost_of alt
          cons_inv += "$sdiv.i32(#{loop_vars[idx]}+ #{counter} - 1,64)*#{cons_cost}"
          #puts "(#{continuation} - (old+ #{counter} - 1)/64)*#{alt_cost}"
        end

        straight_line_inv = "(#{counter}#{' - 1' unless cons_inv.empty?})*(#{straight_line_cost}+#{control_cost})";

        #puts "assert ($l == #{lkg_before_var}+#{straight_line_inv}#{' + ' unless cons_inv.empty?}#{cons_inv});"
        # Compute and insert leakage invariant at the beginning of the head block.
        head.prepend_children(:statements,
          bpl("assert ($l == #{lkg_before_var}+#{straight_line_inv}#{' + ' unless cons_inv.empty?}#{cons_inv});"))

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


    def insert_user_leakage! decl
      if (has_annotation?(decl, ADD_LEAK_ANNOTATION_NAME)) then
        decl.body.select{ |s| is_annotation_stmt?(s, ADD_LEAK_ANNOTATION_NAME)}.each do |s|
          value = get_annotation_value s
          s.insert_after(bpl("assume {:smack.InstTimingCost.Int64 #{value}} true;"))
          s.remove
        end
      end
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

        insert_user_leakage! decl

        summarize_loops! decl

        annotate_function_body! decl

      end

    end
  end
end
