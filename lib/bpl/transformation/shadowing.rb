module Bpl
  module Transformation
    class Shadowing < Bpl::Pass

      def self.description
        "Create a shadow program."
      end

      depends :resolution, :ct_annotation

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

      def loads(obj, attr)
        load_expr, map_expr, inc_expr, len_expr = attr
        Enumerator.new do |y|
          (len_expr.value / inc_expr.value).times do |i|
            y.yield(
              bpl("#{load_expr}(#{map_expr}, #{obj} + #{i * inc_expr.value})"),
              bpl("#{load_expr}(#{shadow map_expr}, #{obj} + #{i * inc_expr.value})")
            )
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
        :public_in_value, :public_in_object,
        :public_out_value, :public_out_object,
        :declassified_out_value, :declassified_out_object
      ]

      def annotated_parameters(proc_decl)
        hash = ANNOTATIONS.map{|ax| [ax,[]]}.to_h
        (proc_decl.parameters + proc_decl.returns).each do |p|
          hash.keys.each {|ax| hash[ax] << p if p.attributes[ax]}
        end
        hash
      end

      def shadow_assert(expr,delay)
        if delay
          bpl("$shadow_ok := $shadow_ok && #{expr};")
        else
          bpl("assert (#{expr});");
        end
      end

      def has_declassification(prog)
        res = false
        prog.each_child do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          next unless decl.attributes[:entrypoint]
          (decl.parameters + decl.returns).each do |p|
            if p.attributes[:declassified_out_object] or
               p.attributes[:declassified_out_value]
              res = true
            end
            next unless res
          end
          next unless res
        end
        res
      end

      def run! program

        delay_assertions = has_declassification(program)
        unless $quiet
          if delay_assertions
            info "Program has declassification -- Delaying shadow assertions."
          else
            info "Program has no declassification -- Inserting shadow assertions in place."
          end
        end

        # duplicate global variables
        program.global_variables.each {|v| v.insert_after(decl(v))}
        program.global_variables.last.insert_after(bpl("var $shadow_ok: bool;")) if delay_assertions

        # duplicate parameters, returns, and local variables
        program.each_child do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          next if exempt?(decl.name)

          params = annotated_parameters(decl)

          return_variables = decl.returns.map{|v| v.names}.flatten

          # Shadow the parameters and returns
          (decl.parameters + decl.returns).each {|d| d.insert_after(decl(d))}

          next unless decl.body

          decl.body.locals.each {|d| d.insert_after(decl(d))}

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
                stmt.insert_before(shadow_assert(shadow_eq(idx),delay_assertions))
              end

              # shadow the assignment
              stmt.insert_after(shadow_copy(stmt))

            when CallStatement
              if magic?(stmt.procedure.name)
                stmt.arguments.each do |x|
                  unless x.type.is_a?(MapType)
                    stmt.insert_before(shadow_assert(shadow_eq(x),delay_assertions))
                  end
                end
              end

              if exempt?(stmt.procedure.name)
                stmt.assignments.each do |x|
                  stmt.insert_after(bpl("#{shadow(x)} := #{x};"))
                end
              else
                (stmt.arguments + stmt.assignments).each do |arg|
                  arg.insert_after(shadow_copy(arg))
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
                if expr = annotation.attributes[:branchcond].first
                  stmt.insert_before(shadow_assert(shadow_eq(expr),delay_assertions))
                end
              end

            end
          end

          # Restrict to equality on public inputs
          params[:public_in_value].each do |p|
            p.names.each do |x|
              decl.append_children(:specifications,
                bpl("requires #{shadow_eq bpl x};"))
            end
          end

          params[:public_in_object].each do |p|
            p.names.each do |x|
              loads(x, p.attributes[:public_in_object]).each do |e,f|
                decl.append_children(:specifications,
                  bpl("requires #{e} == #{f};"))
              end
            end
          end

          # Restrict to equality on public / declassified outputs
          decl.body.each do |ret|
            next unless ret.is_a?(ReturnStatement)

            params[:public_out_value].each do |p|
              p.names.each do |x|
                ret.insert_before(shadow_assert(shadow_eq(bpl(x)),delay_assertions))
              end
            end

            params[:public_out_object].each do |p|
              p.names.each do |x|
                loads(x, p.attributes[:public_out_object]).each do |e,f|
                  ret.insert_before(shadow_assert("#{e} == #{f}",delay_assertions))
                end
              end
            end

            params[:declassified_out_value].each do |p|
              p.names.each do |x|
                ret.insert_before(bpl("assume #{shadow_eq x};"))
              end
            end

            params[:declassified_out_object].each do |p|
              p.names.each do |x|
                loads(x, p.attributes[:declassified_out_object]).each do |e,f|
                  ret.insert_before(bpl("assume #{e} == #{f};"))
                end
              end
            end

          end

          if decl.attributes[:entrypoint] and
             delay_assertions
            decl.body.blocks.first.statements.first.insert_before(
              bpl("$shadow_ok := true;"))
            decl.body.select{|r| r.is_a?(ReturnStatement)}.
              each{|r| r.insert_before(bpl("assert $shadow_ok;"))}
          end

        end
      end
    end
  end
end
