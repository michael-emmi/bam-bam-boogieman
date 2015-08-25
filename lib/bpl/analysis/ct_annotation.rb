module Bpl
  module Analysis
    class CtAnnotation < Bpl::Pass
      def self.description
        "Add constant-time annotations."
      end

      depends :resolution

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
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          next unless proc.body

          parameters = proc.parameters
          aliases = {}
          regions = {}

          proc.body.each do |stmt|
            aliases.merge!(aliasing(stmt))

            next unless stmt.is_a?(CallStatement)
            if stmt.procedure.name =~ /mem_region/
              address, length = stmt.arguments
              address = aliases[address.name] until address.nil? ||
                parameters.include?(address.declaration)
              regions[stmt.assignments.first.name] = [address, length]

            elsif stmt.procedure.name =~ /of_var/
              address = stmt.arguments.first
              address = aliases[address.name] until address.nil? ||
                parameters.include?(address.declaration)
              regions[stmt.assignments.first.name] = [address]

            elsif stmt.procedure.name =~ /public_in|declassified_out/
              region = stmt.arguments.first
              address, length = regions[region.name]
              attr = stmt.procedure.name.to_sym
              val = if length then [length] else [] end
              address.declaration.attributes[attr] = val
            end
          end

        end
      end

    end
  end
end
