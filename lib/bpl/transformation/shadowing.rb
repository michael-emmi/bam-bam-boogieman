module Bpl
  module Transformation
    class Shadowing < Bpl::Pass

      def self.description
        "Create a shadow program."
      end

      depends :resolution, :ct_annotation

      def shadow(x) "#{x}.shadow" end
      def shadow_eq(x) "#{x} == #{shadow(x)}" end
      def decl(v)
        v.class.new(names: v.names.map(&method(:shadow)), type: v.type)
      end

      def shadow_copy(node)
        shadow = node.copy
        shadow.each do |expr|
          next unless expr.is_a?(StorageIdentifier)
          next if expr.declaration &&
                  expr.declaration.is_a?(ConstantDeclaration)
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

      ACCESS_SIZE = 32

      def word_length(parameter, attribute)
        parameter.attributes[attribute].first.value * 8 / ACCESS_SIZE
      end

      def memory_equality(addr)
        # FIXME this should depend on the type and region, obviously! FIXME
        "$load.i#{ACCESS_SIZE}($M.0,#{addr}) == $load.i#{ACCESS_SIZE}($M.0.shadow,#{addr})"
      end

      EXEMPTION_LIST = [
        '\$alloc',
        '\$free',
        'boogie_si_',
        '__VERIFIER_'
      ]
      EXEMPTIONS = /#{EXEMPTION_LIST * "|"}/

      def exempt? decl
        EXEMPTIONS.match(decl) && true
      end


      ANNOTATIONS = [
        :public_in, :public_in_reg,
        :public_out, :public_out_reg,
        :declassified_out, :declassified_out_reg,
        :public_return, :public_return_reg,
        :declassified_return, :declassified_return_reg
      ]

      def annotated_parameters(proc_decl)
        hash = ANNOTATIONS.map{|ax| [ax,[]]}.to_h
        (proc_decl.parameters + proc_decl.returns).each do |p|
          hash.keys.each {|ax| hash[ax] << p if p.attributes[ax]}
        end
        hash
      end

      def shadow_assert(expr)
        bpl("$shadow_ok := $shadow_ok && #{expr};")
      end

      def run! program

        # duplicate global variables
        program.global_variables.each {|v| v.insert_after(decl(v))}
        program.global_variables.last.insert_after(bpl("var $shadow_ok: bool;"))

        # duplicate parameters, returns, and local variables
        program.each_child do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          next if exempt?(decl.name)

          params = annotated_parameters(decl)

          return_variables = decl.returns.map{|v| v.names}.flatten

          # Shadow the parameters and returns
          (decl.parameters + decl.returns).each {|d| d.insert_after(decl(d))}

          next unless decl.body

          last_lhs = nil

          decl.body.locals.each {|d| d.insert_after(decl(d))}

          decl.body.each do |stmt|
            case stmt
            when AssumeStatement

              # TODO should we be shadowing assume statements?
              stmt.insert_after(shadow_copy(stmt))

            when AssignStatement

              fail "Unexpected assignment statement: #{stmt}" unless stmt.lhs.length == 1

              # ensure the indicies to loads and stores are equal
              accesses(stmt).each do |idx|
                stmt.insert_before(shadow_assert(shadow_eq(idx)))
              end

              # shadow the assignment
              stmt.insert_after(shadow_copy(stmt))

              last_lhs = stmt.lhs.first

            when CallStatement
              if exempt?(stmt.procedure.name)
                stmt.assignments.each do |x|
                  stmt.insert_after("#{x} := #{shadow(x)}")
                end
              else
                (stmt.arguments + stmt.assignments).each do |arg|
                  arg.insert_after(shadow_copy(arg))
                end
              end

            when GotoStatement
              next if stmt.identifiers.length < 2
              unless stmt.identifiers.length == 2
                fail "Unexpected goto statement: #{stmt}"
              end
              stmt.insert_before(shadow_assert(shadow_eq(last_lhs)))

            when ReturnStatement
              return_variables.each do |v|
                stmt.insert_before(shadow_assert(shadow_eq(v)))
              end

            end
          end

          # Restrict to equality on public inputs
          params[:public_in].each do |p|
            p.names.each do |x|
              decl.append_children(:specifications,
                bpl("requires #{shadow_eq x};"))
            end
          end

          params[:public_in_reg].each do |p|
            p.names.each do |x|
              word_length(p, :public_in_reg).times.each do |offset|
                addr = "#{x} + #{offset}"
                # NOTE we must know how to access this memory too...
                decl.append_children(:specifications,
                  bpl("requires #{memory_equality(addr)};"))
              end
            end
          end

          # Restrict to equality on public / declassified outputs
          decl.body.each do |ret|
            next unless ret.is_a?(ReturnStatement)

            [:public_out, :public_return].each do |ax|
              params[ax].each do |p|
                p.names.each do |x|
                  ret.insert_before(shadow_assert(shadow_eq(x)))
                end
              end
            end

            [:public_out_reg, :public_return_reg].each do |ax|
              params[ax].each do |p|
                p.names.each do |x|
                  word_length(p, ax).times.each do |offset|
                    addr = "#{x} + #{offset}"
                    # NOTE we must know how to access this memory too...
                    ret.insert_before(shadow_assert(memory_equality(addr)))
                  end
                end
              end
            end

            [:declassified_out, :declassified_return].each do |ax|
              params[ax].each do |p|
                p.names.each do |x|
                  ret.insert_before(bpl("assume #{shadow_eq x};"))
                end
              end
            end

            [:declassified_out_reg, :declassified_return_reg].each do |ax|
              params[ax].each do |p|
                p.names.each do |x|
                  word_length(p, ax).times.each do |offset|
                    addr = "#{x} + #{offset}"
                    # NOTE we must know how to access this memory too...
                    ret.insert_before(bpl("assume #{memory_equality(addr)};"))
                  end
                end
              end
            end

          end

          if decl.attributes[:entrypoint]
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
