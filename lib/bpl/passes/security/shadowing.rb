module Bpl
  class Shadowing < Pass

    depends :normalization
    depends :ct_annotation, :cfg_construction
    depends :resolution, :loop_identification
    depends :definition_localization, :liveness
    invalidates :all

    option :full
    
    switch "--shadowing [FULL]", "Construct the shadow product program." do |y, f, s|
      y.yield :full, f
    end

    def shadow(x) "#{x}.shadow" end
    def unshadow(x) "#{x}".sub(/[.]shadow\z/,'') end
    def shadow_eq(x) "#{x} == #{shadow_copy(x)}" end
    def decl(v)
      v.class.new(names: v.names.map(&method(:shadow)), type: v.type)
    end
    def bpl_assert(x) bpl("assert #{x};") end
    def shadow_copy(node)
      shadow = node.copy
      shadow.each do |expr|
        next unless expr.is_a?(StorageIdentifier)
        next if expr.declaration &&
                ( expr.declaration.is_a?(ConstantDeclaration) ||
                  expr.declaration.parent.is_a?(QuantifiedExpression) )
        # expr.replace_with(StorageIdentifier.new(name: shadow(expr)))
        expr.name = shadow(expr)
      end
      shadow
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

    def shadow_assert(expr)
      bpl("$shadow_ok := $shadow_ok && #{expr};")
    end

    def cross_product(proc)

    end

    def add_shadow_variables!(proc_decl)
      (proc_decl.parameters + proc_decl.returns).each {|d| d.insert_after(decl(d))}
      proc_decl.body.locals.each {|d| d.insert_after(decl(d))} if proc_decl.body
    end

    def self_composition_block(block)
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
        stmt.insert_after(shadow_assert(shadow_eq(expr)))
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

        when AssignStatement

          # ensure the indicies to loads and stores are equal
          accesses(stmt).each do |idx|
            stmt.insert_before(shadow_assert(shadow_eq(idx)))
            equalities.add(idx)
          end

          # shadow the assignment
          stmt.insert_after(shadow_copy(stmt))

        when CallStatement
          if magic?(stmt.procedure.name)
            stmt.arguments.each do |x|
              unless x.type.is_a?(MapType)
                if x.any?{|id| id.is_a?(StorageIdentifier)}
                  stmt.insert_before(shadow_assert(shadow_eq(x)))
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
            stmt.procedure.replace_with(bpl("#{stmt.procedure}.cross_product"))
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
              stmt.insert_before(shadow_assert(shadow_eq(expr)))
              stmt.insert_before(bpl_assert(shadow_eq(expr)))
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
            ret.insert_before(shadow_assert("#{e} == #{f}"))
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
      s_decl.replace_children(:name, "#{decl.name}.shadow")

      # shadow global variables

      s_decl.body.blocks.each do |block|
        block.each do |expr|
          if expr.is_a?(Identifier) && expr.is_variable? && expr.is_global?
            expr.name = shadow(expr)
          end
          if expr.is_a?(CallStatement)
            next if exempt?(expr.procedure.name)
            expr.procedure.replace_with(bpl("#{expr.procedure}.shadow"))
          end
        end
      end
      s_decl
    end

    def create_wrapper_block(decl)
      args = []
      asmt = []
      decl.parameters.each {|d| args.push(d.names.flatten).flatten}
      decl.returns.each {|d| asmt.push(d.names.flatten).flatten}
      args=args.flatten
      asmt=asmt.flatten
      c1 = CallStatement.new(procedure: decl.name,
                             arguments: args,
                             assignments: asmt)
      c2 = CallStatement.new(procedure: "#{decl.name}.shadow",
                             arguments: args.map(&method(:shadow)),
                             assignments: asmt.map(&method(:shadow)))
      r = ReturnStatement.new()
      Block.new(names: [], statements: [c1,c2,r])
    end

    def full_self_composition(decl)
      if decl.body

        shadow = shadow_decl(decl)
        if decl.has_attribute?(:entrypoint)
          
          original = decl.copy
          
          # transform entry function to wrapper function that 
          # calls original and shadowed entry functions
          wrapper_block = create_wrapper_block(decl)
          add_shadow_variables!(decl)
          decl.replace_children(:name, "#{decl.name}.wrapper")
          decl.body.replace_children(:locals, [])
          decl.body.replace_children(:blocks, wrapper_block)
          
          add_assertions!(decl)
          
          decl.insert_after(original)
          
          # update attributes of original and shadowed entry functions
          original.remove_attribute(:entrypoint)
          original.add_attribute(:inline, 1)
          shadow.remove_attribute(:entrypoint)
          shadow.add_attribute(:inline, 1)
          
        end
        decl.insert_after(shadow)
      end
    end

    def selective_self_composition(decl)
      product_decl = decl.copy
      add_shadow_variables!(product_decl)
      
      if product_decl.body
        equalities = Set.new
        arguments = Set.new
        block_insertions = {}
        
        product_decl.body.blocks.each do |block|
          
          block.insert_before *(block_insertions[block.name] || [])
          
          if ins = self_composition_block(block)
            block_insertions[ins[:before]] ||= []
            block_insertions[ins[:before]] << ins[:block]
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
      end
    end
    
    def run! program


      # duplicate global variables
      program.global_variables.each {|v| v.insert_after(decl(v))}
      program.prepend_children(:declarations, bpl("var $shadow_ok: bool;"))

      # duplicate parameters, returns, and local variables
      program.each_child do |decl|
        next unless decl.is_a?(ProcedureDeclaration)
        next if exempt?(decl.name)

        if full
          full_self_composition(decl)
        else
          selective_self_composition(decl)
        end
      end
    end
  end
end
