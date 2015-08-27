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

      def memory_equality(addr)
        # FIXME this should depend on the type and region, obviously! FIXME
        "$load.i32($M.0,#{addr}) == $load.i32($M.0.shadow,#{addr})"
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

      def run! program

        # duplicate global variables
        program.global_variables.each {|v| v.insert_after(decl(v))}

        # duplicate parameters, returns, and local variables
        program.each_child do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          next if exempt?(decl.name)

          public_inputs =
            decl.parameters.select{|p| p.attributes[:public_in]}

          public_outputs =
            decl.parameters.select{|p| p.attributes[:public_out]}

          declassified_outputs =
            decl.parameters.select{|p| p.attributes[:declassified_out]}

          public_returns =
            decl.returns.select{|p| p.attributes[:public_return]}

          declassified_returns =
            decl.returns.select{|p| p.attributes[:declassified_return]}

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
              stmt.select{|e| e.is_a?(MapSelect)}.each do |ms|
                ms.indexes.each do |idx|
                  stmt.insert_before(bpl("assert #{shadow_eq idx};"))
                end
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
              stmt.insert_before(bpl("assert #{shadow_eq last_lhs};"))

            when ReturnStatement
              return_variables.each do |v|
                stmt.insert_before(bpl("assert #{shadow_eq v};"))
              end

            end
          end

          # Restrict to equality on public inputs
          public_inputs.each do |p|
            length = p.attributes[:public_in].first
            p.names.each do |x|
              if length && length.is_a?(IntegerLiteral)
                length.value.times.each do |offset|
                  # NOTE we must know how to access this memory too...
                  decl.append_children(:specifications,
                    bpl("requires #{memory_equality("#{x}+#{offset}")};"))
                end
              else
                decl.append_children(:specifications,
                  bpl("requires #{shadow_eq x};"))
              end
            end
          end

          # Restrict to equality on public / declassified outputs
          decl.body.each do |ret|
            next unless ret.is_a?(ReturnStatement)
            (public_outputs | declassified_outputs).each do |p|
              length = p.attributes[:declassified_out].first ||
                p.attributes[:public_out].first
              p.names.each do |x|
                if length && length.is_a?(IntegerLiteral)
                  length.value.times.each do |offset|
                    ret.insert_before(bpl("assume #{memory_equality("#{x}+#{offset}")};"))
                  end
                else
                  ret.insert_before(bpl("assume #{shadow_eq x};"))
                end
              end
            end
          end

          # Ensure public outputs are equal, contingent on declassified outputs
          unless public_outputs.empty?
            lhs = declassified_outputs.map(&method(:shadow_eq)) * " && "
            lhs = if declassified_outputs.empty? then "" else "#{lhs} ==>" end
            rhs = public_outputs.map(&method(:shadow_eq)) * " && "
            decl.specifications << bpl("ensures #{lhs} #{rhs};")
          end
        end
      end
    end
  end
end
