module Bpl
  module Transformation
    class Shadowing < Bpl::Pass

      depends :normalization
      depends :ct_annotation
      depends :resolution, :loop_identification
      depends :definition_localization, :liveness
      invalidates :all
      flag "--shadowing", "Construct the shadow product program."

      def shadow(x) "#{x}.shadow" end
      def shadow_eq(x) "#{x} == #{shadow_copy(x)}" end
      def decl(v)
        v.class.new(names: v.names.map(&method(:shadow)), type: v.type)
      end

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

      def dependent_variables(proc, expr)
        work_list = [expr]
        deps = Set.new
        covered = Set.new(work_list)
        until work_list.empty?
          stmt = work_list.shift
          stmt.each do |id|
            next unless id.is_a?(StorageIdentifier)
            next if id.declaration && id.declaration.parent.is_a?(Program)
            defs = definition_localization.definitions[id.name]
            next unless defs
            deps.add(id.name)
            defs.each do |s|
              next if covered.include?(s)
              covered.add(s)
              work_list |= [s]
            end
          end
        end
        deps
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
        '__VERIFIER_'
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

      ANNOTATIONS = [
        :public_in,
        :public_out,
        :declassified_out
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

      def run! program

        # duplicate global variables
        program.global_variables.each {|v| v.insert_after(decl(v))}
        program.prepend_children(:declarations, bpl("var $shadow_ok: bool;"))

        # duplicate parameters, returns, and local variables
        program.each_child do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          next if exempt?(decl.name)

          annotations = annotated_specifications(decl)

          # Shadow the parameters and returns
          (decl.parameters + decl.returns).each {|d| d.insert_after(decl(d))}

          next unless decl.body

          decl.body.locals.each {|d| d.insert_after(decl(d))}

          equalities = Set.new
          arguments = Set.new

          decl.body.each do |stmt|
            case stmt
            when AssumeStatement

              # TODO should we be shadowing assume statements?
              # NOTE apparently not; because when they appear as branch
              # conditions, they make the preceding shadow assertion
              # trivially true.
              # stmt.insert_after(shadow_copy(stmt))

              # XXX this is an ugly hack to deal with memory intrinsic
              # XXX functions which are implemented with assume statemnts
              if magic?(decl.name)
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
                  equalities.add(expr)
                end
              end

            end
          end

          # Restrict to equality on public inputs
          annotations[:public_in].each do |annot|
            loads(annot).each do |e,f|
              decl.append_children(:specifications,
                bpl("requires #{e} == #{f};"))
            end
          end

          # Restrict to equality on public / declassified outputs
          decl.body.each do |ret|
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

          if decl.has_attribute? :entrypoint
            decl.body.blocks.first.statements.first.insert_before(
              bpl("$shadow_ok := true;"))
            decl.body.select{|r| r.is_a?(ReturnStatement)}.
              each{|r| r.insert_before(bpl("assert $shadow_ok;"))}
          end

          equality_dependencies =
            equalities.
            reduce(Set.new){|acc, expr| acc | dependent_variables(decl, expr)}

          pointer_argument_dependencies =
            arguments.select{|x|
              x.is_a?(StorageIdentifier) &&
              x.declaration &&
              x.declaration.type.is_a?(CustomType) &&
              x.declaration.type.name == "ref"}.
            reduce(Set.new){|acc, expr| acc | dependent_variables(decl, expr)} -
            equality_dependencies

          value_argument_dependencies =
            arguments.select{|x|
              x.is_a?(StorageIdentifier) &&
              x.declaration &&
              x.declaration.type.is_a?(CustomType) &&
              x.declaration.type.name != "ref"}.
            reduce(Set.new){|acc, expr| acc | dependent_variables(decl, expr)} -
            equality_dependencies -
            pointer_argument_dependencies

          loop_identification.loops.each do |head,body|
            next unless head.parent == decl.body
            value_argument_dependencies.each do |x|
              next unless liveness.live[head].include?(x)
              head.prepend_children(:statements,
                bpl("assert {:unlikely_shadow_invariant #{x} == #{shadow x}} true;"))
            end
            pointer_argument_dependencies.each do |x|
              next unless liveness.live[head].include?(x)
              head.prepend_children(:statements,
                bpl("assert {:likely_shadow_invariant} #{x} == #{shadow x};"))
            end
            equality_dependencies.each do |x|
              next unless liveness.live[head].include?(x)
              head.prepend_children(:statements,
                bpl("assert {:shadow_invariant} #{x} == #{shadow x};"))
            end
            head.prepend_children(:statements,
              bpl("assert {:shadow_invariant} $shadow_ok;"))
          end
        end

      end
    end
  end
end
