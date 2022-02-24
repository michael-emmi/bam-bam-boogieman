# typed: false
module Bpl
  class Shadowing < Pass
    DEFAULT_ASSERT = :assert_shadow_ok
    DEFAULT_MODE = :selective
    DEFAULT_ASSERT_POINTS = [:branchcond_assertion, :memory_assertion, :public_out_assertion]
    DEFAULT_ARGS = "self_comp_mode=#{DEFAULT_MODE},#{DEFAULT_ASSERT_POINTS.map{|p| "#{p}=#{DEFAULT_ASSERT}"} * ","}"

    depends :normalization
    depends :ct_annotation, :cfg_construction
    depends :resolution, :loop_identification
    depends :definition_localization, :liveness
    invalidates :all

    option :argslist

    def parse_args(args)
      rval = Hash.new
      args.split(",").each do |a|
        left,right = a.split("=")
        #symbols are clearer than strings in code
        rval[left.to_sym] = right.to_sym
      end
      return rval
    end

    switch "--shadowing [arg1=val1,...,argk=valk]", "Construct the shadow product program." do |y, f, s|
      y.yield :argslist, f || DEFAULT_ARGS
    end

    def shadow(x) "#{x}.shadow" end
    def unshadow(x) "#{x}".sub(/[.]shadow\z/,'') end
    def shadow_eq(x) "#{x} == #{shadow_copy(x)}" end

    def shadow_var_decl(v)
      v.class.new(names: v.names.map(&method(:shadow)), type: v.type)
    end

    # Shadows the procedure identifier of a CallStatement.
    # Using a String instead of a ProcedureIntefier object (i.e. by simply shadowing the name)
    # breaks compatibility with any postprocessing of the ast.
    def shadow_proc_call!(expr, suffix="shadow")
      #TODO: is there a better way to right this?
      return if("#{expr.procedure}" == "nondet")
      procedure_id = ProcedureIdentifier.new(:name => "#{expr.procedure}.#{suffix}")
      expr.procedure.replace_with(procedure_id)
    end

    def bpl_assert(x) bpl("assert #{x};") end
    def shadow_copy(node)
      shadow = node.copy
      shadow.each do |expr|
        case expr
        when StorageIdentifier
          next if expr.declaration &&
                  ( expr.declaration.is_a?(ConstantDeclaration) ||
                    expr.declaration.parent.is_a?(QuantifiedExpression) )
          expr.name = shadow(expr)

        when CallStatement
          next if exempt?(expr.procedure.name)
          next if magic?(expr.procedure.name)
          shadow_proc_call!(expr)
        end
      end
      return shadow
    end

    def accesses(stmt)
      Enumerator.new do |y|
        stmt.each do |expr|
          next unless expr.is_a?(FunctionApplication)
          next unless expr.function.is_a?(Identifier)
          next unless expr.function.name =~ /\$(load|store)/
          y.yield expr.arguments[1]
        end
      end
    end

    def dependent_variables(proc, exprs)
      dependencies = Set.new

      work_list = exprs.to_a.dup
      covered = Set.new(work_list)

      until work_list.empty?

        node = work_list.shift
        node.each do |id|
          next unless id.is_a?(StorageIdentifier)
          next if id.declaration && id.declaration.parent.is_a?(Program)
          next unless definitions = definition_localization.definitions[proc.name][id.name]

          dependencies.add(id.name)

          definitions.each do |stmt|
            next if covered.include?(stmt)
            covered.add(stmt)
            work_list << stmt
          end
        end
      end
      return dependencies
    end

    def loads(annotation)
      load_expr, map_expr, addr_expr, inc_expr, len_expr = annotation
      Enumerator.new do |y|
        if map_expr.nil?
          y.yield(
            bpl("#{load_expr}"),
            bpl("#{shadow load_expr}"))

        elsif len_expr.nil?
          y.yield(
            bpl("#{load_expr}(#{map_expr}, #{addr_expr})"),
            bpl("#{load_expr}(#{shadow map_expr}, #{shadow_copy addr_expr})"))

        else
          (len_expr.value / inc_expr.value).times do |i|
            y.yield(
              bpl("#{load_expr}(#{map_expr}, #{addr_expr} + #{i * inc_expr.value})"),
              bpl("#{load_expr}(#{shadow map_expr}, #{shadow_copy addr_expr} + #{i * inc_expr.value})")
            )
          end
        end
      end
    end

    EXEMPTION_LIST = [
      '\$alloc',
      '\$free',
      'boogie_si_',
      'corral_atomic_',
      '__VERIFIER_',
      '__SMACK_(?!static_init)',
      '__memcpy_chk',
      'llvm.dbg',
      'llvm.lifetime',
      'llvm.objectsize',
      'llvm.stacksave',
      'llvm.stackrestore'
    ]

    MAGIC_LIST = [
      '\$alloc',
      '\$free',
      '\$memset.i8',
      '\$memcpy.i8',
      '\$memcmp.i8'
    ]

    EXEMPTIONS = /#{EXEMPTION_LIST * "|"}/
    MAGICS = /#{MAGIC_LIST * "|"}/

    def exempt? decl
      EXEMPTIONS.match(decl) && true
    end

    def magic? decl
      MAGICS.match(decl) && true
    end

    def insertvalue? stmt
      expr = stmt.expression
      return expr.is_a?(BinaryExpression) &&
              expr.lhs.is_a?(FunctionApplication) &&
                /\$extractvalue/.match(expr.lhs.function.declaration.name)
    end


    #combines both VARIABLE_ANNOTATIONS and BLOCK_ANNOTATIONS from ct_annotation.rb
    ANNOTATIONS = [
      :public_in,
      :public_out,
      :declassified_out,
      :__VERIFIER_ASSERT_MAX_LEAKAGE
    ]

    TIMING_ANNOTATIONS = [
    ]



    def annotated_specifications(proc_decl)
      hash = ANNOTATIONS.map{|ax| [ax,[]]}.to_h
      proc_decl.specifications.each do |s|
       hash.keys.each {|ax| hash[ax] << s.get_attribute(ax) if s.has_attribute?(ax)}
      end
      hash
    end

    def add_assertion!(node, position, expr, type)
      assertion =
        case @args_hash[type]
        when nil, :assert_never
          nil
        when :assert_now
          assertion = bpl_assert(expr)
        when :assert_shadow_ok
          assertion = shadow_assert(expr)
        else
          raise "unexpected assertion time"
        end
      return unless assertion
      if position == :before
        node.insert_before(assertion)
      elsif position == :after
        node.insert_after(assertion)
      else
        raise "bad direction"
      end
    end

    def shadow_assert(expr)
      bpl("$shadow_ok := $shadow_ok && #{expr};")
    end

    def cross_product(proc)

    end

    def add_shadow_variables!(proc_decl)
      (proc_decl.parameters + proc_decl.returns).each {
        |d| d.insert_after(shadow_var_decl(d))}
      proc_decl.body.locals.each {
        |d| d.insert_after(shadow_var_decl(d))} if proc_decl.body
    end

    def self_composition_block!(block)
      return nil unless block.statements.first.has_attribute?(:selfcomp)
      head, tail = block.statements.first.get_attribute(:selfcomp)
      shadow_block = shadow_copy(block)

      equalities = Set.new

      # replace returns and exits in the original block
      block.each do |stmt|
        case stmt
        when ReturnStatement
        when GotoStatement
          if stmt.identifiers.map(&:name).include?(tail)
            fail "Unexpected branching exit" unless stmt.identifiers.count == 1
          else
            next
          end
        else
          next
        end
        stmt.replace_with(bpl("goto #{shadow(head)};"))
      end

      shadow_block.replace_children(:names, *shadow_block.names.map(&method(:shadow)))
      shadow_block.each do |label|
        next unless label.is_a?(LabelIdentifier) && label.name != tail
        label.replace_with(LabelIdentifier.new(name: shadow(label.name)))
      end

      shadow_block.each do |stmt|
        next unless stmt.is_a?(AssumeStatement)
        next unless values = stmt.get_attribute(:branchcond)
        expr = bpl(unshadow values.first)
        add_assertion!(stmt, :after, shadow_eq(expr), :self_comp_branch_assertion)
        equalities.add(expr)
      end

      return { block: shadow_block, before: tail, eqs: equalities }
    end

    def cross_product_block!(block)
      equalities = Set.new
      arguments = Set.new
      proc_decl = block.parent.parent

      block.each do |stmt|
        case stmt
        when AssumeStatement

          # TODO should we be shadowing assume statements?
          # NOTE apparently not; because when they appear as branch
          # conditions, they make the preceding shadow assertion
          # trivially true.
          # stmt.insert_after(shadow_copy(stmt))

          # XXX this is an ugly hack to deal with memory intrinsic
          # XXX functions which are implemented with assume statemnts
          if magic?(proc_decl.name)
            stmt.insert_after(shadow_copy(stmt))
          end

          if insertvalue?(stmt)
            stmt.insert_after(shadow_copy(stmt))
          end

        when AssignStatement

          # ensure the indicies to loads and stores are equal
          accesses(stmt).each do |idx|
            add_assertion!(stmt, :before, shadow_eq(idx), :memory_assertion)
            equalities.add(idx)
          end

          # shadow the assignment
          stmt.insert_after(shadow_copy(stmt))

        when CallStatement
          if magic?(stmt.procedure.name)
            stmt.arguments.each do |x|
              unless x.type.is_a?(MapType)
                if x.any?{|id| id.is_a?(StorageIdentifier)}
                  #DSN: This appears to be to ensure that malloc and free are called with the same args?
                  add_assertion!(stmt, :before, shadow_eq(x), :magic_param_args_assertion)
                  equalities.add(x)
                end
              end
            end
          end

          if exempt?(stmt.procedure.name)
            stmt.assignments.each do |x|
              stmt.insert_after(bpl("#{shadow(x)} := #{x};"))
            end
          else
            shadow_proc_call!(stmt, "cross_product")
            stmt.arguments.each do |x|
              arguments.add(x)
              x.insert_after(shadow_copy(x))
            end
            stmt.assignments.each do |x|
              x.insert_after(shadow_copy(x))
            end
          end

        when HavocStatement
          nxt = stmt.next_sibling
          if nxt and
             nxt.is_a?(AssumeStatement)
            nxt.insert_after(shadow_copy(nxt))
          end
          stmt.insert_after(shadow_copy(stmt))

        when GotoStatement
          next if stmt.identifiers.length < 2
          unless stmt.identifiers.length == 2
            fail "Unexpected goto statement: #{stmt}"
          end

          if annotation = stmt.previous_sibling
            fail "Expected :branchcond annotation" unless
              annotation.has_attribute?(:branchcond)

            if expr = annotation.get_attribute(:branchcond).first
              add_assertion!(stmt, :before, shadow_eq(expr), :branchcond_assertion)
              equalities.add(expr)
            end
          end

        end
      end

      return equalities, arguments
    end

    def add_assertions!(proc_decl)
      equalities = Set.new

      annotations = annotated_specifications(proc_decl)

      # Restrict to equality on public inputs
      annotations[:public_in].each do |annot|
        loads(annot).each do |e,f|
          proc_decl.append_children(:specifications,
            bpl("requires #{e} == #{f};"))
        end
      end

      # Restrict to equality on public / declassified outputs
      proc_decl.body.each do |ret|
        next unless ret.is_a?(ReturnStatement)
        annotations[:public_out].each do |annot|
          loads(annot).each do |e,f|
            add_assertion(ret, :before, "#{e} == #{f}", :public_out_assertion)
            equalities.add(e)
          end
        end

        annotations[:declassified_out].each do |annot|
          loads(annot).each do |e,f|
            ret.insert_before(bpl("assume #{e} == #{f};"))
          end
        end
      end

      if proc_decl.has_attribute?(:entrypoint)

        if proc_decl.has_attribute?(:cost_modeling)
          #this is ugly, but seems to be how to destructure the annotation here
          if max_leakage = annotations[:__VERIFIER_ASSERT_MAX_LEAKAGE]&.first&.first

            proc_decl.body.select{|r| r.is_a?(ReturnStatement)}.each do |r|
              r.insert_before(bpl("assume $l >= $l.shadow;"))
              r.insert_before(bpl("$__delta := $l - $l.shadow;"));
              r.insert_before(bpl("assert $l <= ($l.shadow + #{max_leakage});"))
            end
          else

            proc_decl.body.select{|r| r.is_a?(ReturnStatement)}.each do |r|
              r.insert_before(bpl("$__delta := $l - $l.shadow;"))
              r.insert_before(bpl("assert $l == $l.shadow;"))
            end
          end
        else

        proc_decl.body.blocks.first.statements.first.insert_before(
          bpl("$shadow_ok := true;"))
        proc_decl.body.select{|r| r.is_a?(ReturnStatement)}.
          each{|r| r.insert_before(bpl("assert $shadow_ok;"))}
        end
      end
      return equalities
    end

    def add_loop_invariants!(proc_decl, arguments, equalities)
      #DSN TODO this might need to be changed for the timing example
      equality_dependencies = dependent_variables(proc_decl, equalities)


      pointer_argument_dependencies =
        dependent_variables(proc_decl,
          arguments.select{|x|
            x.is_a?(StorageIdentifier) &&
            x.declaration &&
            x.declaration.type.is_a?(CustomType) &&
            x.declaration.type.name == "ref"}) -
        equality_dependencies

      value_argument_dependencies =
        dependent_variables(proc_decl,
          arguments.select{|x|
            x.is_a?(StorageIdentifier) &&
            x.declaration &&
            x.declaration.type.is_a?(CustomType) &&
            x.declaration.type.name != "ref"}) -
        equality_dependencies -
        pointer_argument_dependencies

      loop_identification.loops.each do |head,_|

        block = proc_decl.body.blocks.find do |b|
          b.name == head.name && proc_decl.name == head.parent.parent.name
        end

        next unless block

        if proc_decl.has_attribute?(:cost_modeling)
          block.prepend_children(:statements,
             bpl("assert {:cost_invariant} ($l == $l.shadow);"))

        else

          value_argument_dependencies.each do |x|
            next unless liveness.live[head].include?(x)
            block.prepend_children(:statements,
              bpl("assert {:unlikely_shadow_invariant #{x} == #{shadow x}} true;"))
          end
          pointer_argument_dependencies.each do |x|
            next unless liveness.live[head].include?(x)
            block.prepend_children(:statements,
              bpl("assert {:likely_shadow_invariant} #{x} == #{shadow x};"))
          end
          equality_dependencies.each do |x|
            next unless liveness.live[head].include?(x)
            block.prepend_children(:statements,
              bpl("assert {:shadow_invariant} #{x} == #{shadow x};"))
          end

          block.prepend_children(:statements,
            bpl("assert {:shadow_invariant} $shadow_ok;"))

        end
      end
    end

    def shadow_decl(decl)
      s_decl = decl.copy
      s_decl.replace_children(:name, shadow(decl.name))

      # shadow global variables
      s_decl.body.blocks.each do |block|
        block.each do |expr|
          if expr.is_a?(Identifier) && expr.is_variable? && expr.is_global?
            expr.name = shadow(expr)
          end
          if expr.is_a?(CallStatement)
            next if exempt?(expr.procedure.name)
            shadow_proc_call!(expr)
          end
        end
      end
      s_decl
    end

    def create_wrapper_block(original, shadow)
      args = []
      asmt = []
      original.parameters.each {|d| args.push(d.names.flatten).flatten}
      original.returns.each {|d| asmt.push(d.names.flatten).flatten}
      args=args.flatten
      asmt=asmt.flatten
      shadow_args = args.map(&method(:shadow))
      shadow_assgts =  asmt.map(&method(:shadow))
      original_id = ProcedureIdentifier.new({:name =>original.name})
      shadow_id = ProcedureIdentifier.new({:name => shadow.name})


      c1 = CallStatement.new(procedure: original_id,
                             arguments: args,
                             assignments: asmt)
      c2 = CallStatement.new(procedure: shadow_id,
                             arguments: shadow_args,
                             assignments: shadow_assgts)
      r = ReturnStatement.new()
      Block.new(names: [], statements: [c1,c2,r])
    end



    def remove_call!(decl, proc_name)
      decl.body.each do |stmt|
        next unless stmt.is_a?(CallStatement)
        stmt.remove if stmt.procedure.name.eql? proc_name
      end
    end

    def full_self_composition(original)
      if original.body

        shadow = shadow_decl(original)
        original.insert_after(shadow)



        if original.has_attribute?(:entrypoint)
          wrapper = original.copy
          wrapper.replace_children(:name, "#{original.name}.wrapper")

          original.remove_attribute(:entrypoint)
          original.add_attribute(:inline, 1)
          shadow.remove_attribute(:entrypoint)
          shadow.add_attribute(:inline, 1)

          #wrapper already has :entrypoint attribute from cloning

          # transform entry function to wrapper function that
          # calls original and shadow entry functions
          wrapper_block = create_wrapper_block(original, shadow)
          add_shadow_variables!(wrapper)
          wrapper.body.replace_children(:locals, [])
          wrapper.body.replace_children(:blocks, wrapper_block)

          add_assertions!(wrapper)
          if @args_hash.has_key?(:verify_stub)
            remove_call!(original, @args_hash[:verify_stub].to_s.concat("_stub"))
            remove_call!(shadow, @args_hash[:verify_stub].to_s.concat(".shadow"))
          end

          original.insert_after(wrapper)
        end

      end
    end

    def selective_self_composition(decl)
      # We need to create three copies of each function, to be called depending on
      # the conext:
      # 1. the cross_product copy, called from the cross-product context,
      # 2. the original copy, called from the selective-self-composition context
      # 3. the shadow copy, called from the selective-self-composition context.



      # decl is the original - should not be touched by this function
      product_decl = decl.copy
      add_shadow_variables!(product_decl)

      if product_decl.body
        equalities = Set.new
        arguments = Set.new

        product_decl.body.blocks.each do |block|

          if ins = self_composition_block!(block)
            # It is crutial that this be inserted after, because otherwise the entry block might become
            # accidentally set to the shadow, which would be bad.
            block.insert_after(ins[:block])
            equalities.merge(ins[:eqs])

          else
            eqs, args = cross_product_block!(block)
            equalities.merge(eqs)
            arguments.merge(args)
          end
        end

        equalities.merge( add_assertions!(product_decl) )
        add_loop_invariants!(product_decl, arguments, equalities)
      end

      product_decl.replace_children(:name, "#{decl.name}.cross_product")

      if decl.has_attribute?(:entrypoint)
        decl.replace_with(product_decl)
      else
        decl.insert_after(product_decl)
        #shadow is for the shadow calls
        decl.insert_after(shadow_decl(decl)) if decl.body
      end

    end


    def run! program
      @args_hash = parse_args(argslist)
      # duplicate global variables
      program.global_variables.each {|v| v.insert_after(shadow_var_decl(v))}
      program.prepend_children(:declarations, bpl("var $shadow_ok: bool;"))

      # duplicate parameters, returns, and local variables
      program.each_child do |decl|
        next unless decl.is_a?(ProcedureDeclaration)
        next if exempt?(decl.name)

        if @args_hash[:self_comp_mode] == :full
          full_self_composition(decl)
        elsif @args_hash[:self_comp_mode] == :selective
          selective_self_composition(decl)
        else
          raise "unknown self comp mode #{@args_hash[:self_comp_mode]}"
        end
      end
    end
  end
end
