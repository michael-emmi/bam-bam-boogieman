module Bpl
  module Analysis
    class CtAnnotation < Bpl::Pass
      def self.description
        "Add constant-time annotations."
      end

      depends :resolution

      ANNOTATIONS = [
        :public_in,
        :public_out,
        :declassified_out,
      ]

      def run! program
        program.declarations.each do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          next unless decl.body

          values = {}

          decl.body.each do |stmt|
            next unless stmt.is_a?(CallStatement)


            if stmt.procedure.name =~ /__SMACK_value/
              _, id = stmt.attributes.find{|key,_| key =~ /name/}
              kind, access = stmt.attributes.find{|key,_| key =~ /array|field/}

              values[stmt.assignments.first.name] = {
                id: id.first,
                kind: kind,
                access: access
              }

            elsif stmt.procedure.name =~ /#{ANNOTATIONS * "|"}/
              var = stmt.arguments.first.name
              v = values[var]
              fail "Unknown value: #{var}" unless v
              access = v[:access] || [v[:id]]
              decl.append_children(:specifications,
                bpl("requires {:#{stmt.procedure.name} #{access * ", "}} true;")
              )
            end

          end

        end
      end

    end
  end
end
