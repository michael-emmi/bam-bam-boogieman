module Bpl
  module Analysis
    class CtAnnotation < Bpl::Pass
      def self.description
        "Add constant-time annotations."
      end

      depends :resolution

      ANNOTATIONS = [
        :public_in_,
        :public_out_,
        :declassified_out_,
      ]

      def run! program
        program.declarations.each do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          next unless decl.body

          values = {}
          objects = {}

          decl.body.each do |stmt|
            next unless stmt.is_a?(CallStatement)

            if stmt.procedure.name =~ /__SMACK_value/
              values[stmt.assignments.first.name] = {
                id: stmt.arguments.first
              }

            elsif stmt.procedure.name =~ /__SMACK_object/
              k, vals = stmt.attributes.find{|key,_| key =~ /\$load/}
              objects[stmt.assignments.first.name] = {
                id: stmt.arguments.first,
                attr: [k.to_s] + vals
              }

            elsif stmt.procedure.name =~ /#{ANNOTATIONS * "|"}/
              var = stmt.arguments.first.name
              if stmt.procedure.name =~ /_value/
                v = values[var]
                fail "Unknown value: #{var}" unless v
                decl = v[:id].declaration
                val = []
              else
                o = objects[var]
                fail "Unknown object: #{var}" unless o
                decl = o[:id].declaration
                val = o[:attr]
              end
              decl.attributes[stmt.procedure.name.to_sym] = val
            end

          end

        end
      end

    end
  end
end
