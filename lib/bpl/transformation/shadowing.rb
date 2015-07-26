module Bpl
  module Transformation
    class Shadowing < Bpl::Pass

      def self.description
        "Create a shadow program."
      end

      def shadow(x) "#{x}.shadow" end
      def shadow_eq(x) "#{x} == #{shadow(x)}" end
      def decl(v)
        v.class.new(names: v.names.map(&method(:shadow)), type: v.type)
      end

      def shadow_copy(node)
        copy = bpl(node.to_s)
        copy.each do |expr|
          next unless expr.is_a?(StorageIdentifier)
          next if expr.declaration &&
                  expr.declaration.is_a?(ConstantDeclaration)
          expr.replace_with(StorageIdentifier.new(name: shadow(expr)))
        end
        copy
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
          next unless decl.is_a?(ProcedureDeclaration) && !exempt?(decl.name)

          return_variables = decl.returns.map{|v| v.names}.flatten

          decl.parameters.dup.each {|d| d.insert_after(decl(d))}
          decl.returns.dup.each {|d| d.insert_after(decl(d))}

          next unless decl.body

          public_inputs = Set.new
          public_outputs = Set.new
          declassified_outputs = Set.new

          decl.body.each do |s|
            (s.attributes[:public_input] || []).each(&public_inputs.method(:add))
            (s.attributes[:declassified_output] || []).each(&declassified_outputs.method(:add))
            (s.attributes[:public_output] || []).each(&public_outputs.method(:add))
          end

          public_inputs.each do |x|
            decl.append_child(:specifications, bpl("requires #{shadow_eq x};"))
          end

          unless public_outputs.empty?
            lhs = declassified_outputs.map(&method(:shadow_eq)) * " && "
            lhs = if declassified_outputs.empty? then "" else "#{lhs} ==>" end
            rhs = public_outputs.map(&method(:shadow_eq)) * " && "
            decl.specifications << bpl("ensures #{lhs} #{rhs};")
          end

          last_lhs = nil

          decl.body.locals.dup.each {|d| d.insert_after(decl(d))}

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
                xs = stmt.assignments
                unless xs.empty?
                  stmt.insert_after
                    bpl("#{xs.map{|v| shadow(v.name)} * ", "} := #{xs* ", "};")
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
        end
      end
    end
  end
end
