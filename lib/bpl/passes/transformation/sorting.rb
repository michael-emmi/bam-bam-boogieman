module Bpl
  class Sorting < Pass

    KINDS = [:globals, :locals, :specs, :all]

    option :kind

    flag "--sorting [KIND]", KINDS, "either #{KINDS * ", "}" do |kind|
      option :kind, kind || :all
    end

    def type_order(d,e)
      return 0 if d.class == e.class
      res = [ TypeDeclaration,
        ConstantDeclaration,
        FunctionDeclaration,
        AxiomDeclaration,
        VariableDeclaration,
        ProcedureDeclaration,
        ImplementationDeclaration,
        RequiresClause,
        EnsuresClause,
        ModifiesClause
      ].each do |c|
        break -1 if d.is_a?(c)
        break 1 if e.is_a?(c)
      end
      return 0 if res.is_a?(Array)
      return res
    end

    def order(d,e)
      res = type_order(d, e)
      return res unless res == 0
      return d.names.first <=> e.names.first unless d.names.empty? if d.is_a?(Declaration)
      return d.to_s <=> e.to_s
    end

    def run! program

      if kind.match(/locals|all/)
        info "SORTING LOCAL DECLARATIONS"
        info
        program.declarations.each do |d|
          next unless d.is_a?(ProcedureDeclaration)
          next unless d.body
          d.body.locals.each do |v|
            v.instance_variable_set "@names", v.names.sort
          end
          d.body.replace_children :locals,
            *d.body.locals.sort {|d1,d2| order(d1,d2)}
        end
      end

      if kind.match(/globals|all/)
        info "SORTING GLOBAL DECLARATIONS"
        info
        program.declarations.each do |d|
          next unless d.instance_variable_defined?("@names")
          d.instance_variable_set "@names", d.names.sort
        end
        program.replace_children :declarations,
          *program.declarations.sort {|d,e| order(d,e)}
      end

      if kind.match(/specs|all/)
        info "SORTING SPECIFICATIONS"
        info
        program.declarations.each do |d|
          next unless d.is_a?(ProcedureDeclaration)
          d.specifications.each do |s|
            next unless s.is_a?(ModifiesClause)
            s.instance_variable_set "@identifiers",
              s.identifiers.sort {|i,j| i.name <=> j.name}
          end
          d.replace_children :specifications,
            *d.specifications.sort {|s,t| order(s,t)}
        end
      end

    end
  end
end
