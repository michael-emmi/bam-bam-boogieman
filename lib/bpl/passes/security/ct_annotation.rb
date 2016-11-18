module Bpl
  class CtAnnotation < Pass

    depends :resolution
    depends :cfg_construction, :conditional_identification
    switch "--ct-annotation", "Extract constant-time annotations."

    ANNOTATIONS = [
      :public_in,
      :public_out,
      :declassified_out,
    ]

    BLOCK_ANNOTATIONS = [
      :benign,
    ]

    def run! program
      cfg = cfg_construction

      program.declarations.each do |decl|
        next unless decl.is_a?(ProcedureDeclaration)
        next unless decl.body

        values = {}

        decl.body.each do |stmt|
          next unless stmt.is_a?(CallStatement)

          if stmt.procedure.name =~ /__SMACK_value/
            name = stmt.attributes.find{|a| a.key =~ /name/}
            kind = stmt.attributes.find{|a| a.key =~ /array|field/}

            values[stmt.assignments.first.name] = {
              id: name.values.first,
              kind: kind && kind.key,
              access: kind && kind.values
            }

          elsif stmt.procedure.name =~ /#{ANNOTATIONS * "|"}/
            var = stmt.arguments.first.name
            v = values[var]
            fail "Unknown value: #{var}" unless v
            access = v[:access] || [v[:id]]
            decl.append_children(:specifications,
              bpl("requires {:#{stmt.procedure.name} #{access * ", "}} true;")
            )
            invalidates :resolution

          elsif stmt.procedure.name =~ /#{BLOCK_ANNOTATIONS * "|"}/
            head = cfg.predecessors[stmt.parent].first
            cond = conditional_identification.conditionals[head]
            next unless cond
            cond[:blocks].each do |blk|
              blk.prepend_children(:statements, bpl("assume {:selfcomp \"#{head.name}\", \"#{cond[:sortie].name}\"} true;"))
            end
            stmt.remove
          end

        end
      end

    end

  end
end
