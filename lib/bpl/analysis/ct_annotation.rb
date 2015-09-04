module Bpl
  module Analysis
    class CtAnnotation < Bpl::Pass
      def self.description
        "Add constant-time annotations."
      end

      depends :resolution

      ANNOTATIONS = [
        :public_in, :public_in_reg,
        :public_out, :public_out_reg,
        :declassified_out, :declassified_out_reg
      ]

      def reference(expression)
        if expression.is_a?(StorageIdentifier)
          expression
        elsif expression.is_a?(FunctionApplication) &&
              expression.function.name =~ /\$bitcast/ &&
              expression.arguments.count == 1 &&
              expression.arguments.first.is_a?(StorageIdentifier)
        then
          expression.arguments.first
        else
          nil
        end
      end

      def aliasing(assignment)
        if assignment.is_a?(AssignStatement) &&
           assignment.lhs.count == 1 &&
           assignment.rhs.count == 1 &&
           assignment.lhs.first.is_a?(StorageIdentifier) &&
           ref = reference(assignment.rhs.first)
        then
          { assignment.lhs.first.name => ref }
        else
          {}
        end
      end

      def run! program
        program.declarations.each do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          next unless decl.body

          parameters = decl.parameters
          returns = decl.returns
          aliases = {}
          regions = {}

          decl.body.each do |stmt|
            aliases.merge!(aliasing(stmt))

            next unless stmt.is_a?(CallStatement)

            if stmt.procedure.name =~ /(mem|ret)_region/
              if stmt.procedure.name =~ /ret/
                address = decl.returns.first.idents.first
                length = stmt.arguments.first
              else
                address, length = stmt.arguments
              end
              address = aliases[address.name] until address.nil? ||
                parameters.include?(address.declaration) ||
                returns.include?(address.declaration)
              regions[stmt.assignments.first.name] = [address, length]
              # stmt.remove

            elsif stmt.procedure.name =~ /of_(var|ret)/
              if stmt.procedure.name =~ /ret/
                address = decl.returns.first.idents.first
              else
                address = stmt.arguments.first
              end
              address = aliases[address.name] until address.nil? ||
                parameters.include?(address.declaration) ||
                returns.include?(address.declaration)
              regions[stmt.assignments.first.name] = [address]
              # stmt.remove

            elsif stmt.procedure.name =~ /#{ANNOTATIONS * "|"}/
              region = stmt.arguments.first
              address, length = regions[region.name]
              attr = "#{stmt.procedure.name}#{"_reg" if length}".to_sym
              val = if length then [length] else [] end
              address.declaration.attributes[attr] = val
              # stmt.remove

            end
          end

        end
      end

    end
  end
end