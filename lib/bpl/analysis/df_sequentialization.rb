module Bpl
  module AST
    
    class Program
      def df_sequentialize!

        gs = (globals = global_variables).map{|d| d.idents}.flatten        
        return if gs.empty?

        @declarations << bpl("var #s: int;")
        @declarations += globals.map do |decl|
          bpl "var #{decl.names.map{|g| "#{g}.next"} * ", "}: #{decl.type};"
        end
        
        @declarations.each do |decl|
          case decl
          when ProcedureDeclaration
            next unless decl.body

            decl.specifications << 
              bpl("modifies #{decl.modified_vars.map{|g| "#{g}.next"} * ", "};")
            decl.specifications << bpl("modifies #s;")

            if decl.is_entrypoint?
              decl.body.declarations << bpl("var #s.self: int;")
              decl.body.declarations += globals.map do |decl|
                bpl "var #{decl.names.map{|g| "#{g}.start"} * ", "}: #{decl.type};"
              end
            else
              decl.parameters << bpl("#s.self: int")
              decl.body.statements.unshift( bpl "call boogie_si_record_int(#s.self);" )
            end
            
            if decl.body.any?{|elem| elem.attributes.include?(:async)}
              decl.body.declarations += globals.map do |decl|
                bpl "var #{decl.names.map{|g| ["#{g}.save", "#{g}.guess"]}.flatten * ", "}: #{decl.type};"
              end
            end
            
            decl.body.replace do |elem|
              case elem
              when AssumeStatement
                if elem.attributes.has_key?(:startpoint)
                  next [bpl("#s := 0;")] +
                    [bpl("#s.self := 0;")] +
                    gs.map{|g| bpl("#{g}.next := #{g}.start;")} +
                    [elem]

                elsif elem.attributes.has_key?(:endpoint)
                  next [elem] +
                    gs.map{|g| bpl("assume #{g} == #{g}.start;")} +
                    gs.map{|g| bpl("#{g} := #{g}.next;")}
                  elem
                end

              when CallStatement
                proc = elem.procedure.declaration

                if elem.attributes.include? :async then
                  elem.attributes.delete :async
                  elem.arguments << bpl("#s") if proc && proc.body
              
                  # replace the return assignments with dummy assignments
                  elem.assignments.map! do |x|
                    elem.parent.fresh_var(x.declaration.type).idents.first
                  end
              
                  # make sure to pass the 'save'd version of any globals
                  elem.arguments.map! do |e|
                    e.replace do |e|
                      e.is_a?(Identifier) && globals.include?(e.declaration) ? e.save : e
                    end                
                  end
              
                  # some async-simulating guessing magic
                  next gs.map{|g| bpl("#{g}.save := #{g};")} +
                    gs.map{|g| bpl("#{g} := #{g}.next;")} +
                    gs.map{|g| bpl("havoc #{g}.guess;")} +
                    gs.map{|g| bpl("#{g}.next := #{g}.guess;")} +
                    [ bpl("#s := #s + 1;") ] +
                    [ elem ] +
                    gs.map{|g| bpl("assume #{g} == #{g}.guess;")} +
                    gs.map{|g| bpl("#{g} := #{g}.save;")}
              
                else # a synchronous procedure call
                  elem.arguments << bpl("#s.self") if proc && proc.body

                end
              end
              
              elem
            end
          end
        end
      end
    end

  end
end
