module Bpl
  module Analysis
    module DFAsyncRemoval

      def is_global?(g) g.is_a?(StorageIdentifier) && g.is_variable? && g.is_global? end

      def async_to_call! program
        globals = program.global_variables.select{|d| (d.names & ['#d']).empty?}
        gs = globals.map{|d| d.idents}.flatten
        return if gs.empty?

        # program.declarations << bpl("var #tasks: int;")
        program.declarations += globals.map do |decl|
          bpl "var #{decl.names.map{|g| "#{g}.next"} * ", "}: #{decl.type};"
        end

        program.declarations.each do |decl|
          case decl
          when ProcedureDeclaration
            next unless decl.body

            accs = (decl.accesses & gs).sort
            mods = accs - decl.modifies

            decl.specifications << bpl("modifies #{mods * ", "};") \
              unless mods.empty?
            decl.specifications << bpl("modifies #{accs.map{|g| "#{g}.next"} * ", "};") \
              unless accs.empty?

            # TODO why did I write this?!
            # decl.add_modifies! (gs-mods) \
            #   if decl.body.any?{|s| s.attributes.include? :async}

            # decl.specifications << bpl("modifies #tasks;")

            if decl.is_entrypoint?
              # decl.body.declarations << bpl("var #t: int;")
              decl.body.declarations += globals.map do |decl|
                bpl "var #{decl.names.map{|g| "#{g}.start"} * ", "}: #{decl.type};"
              end
            else
              # decl.parameters << bpl("#t: int")
            end

            if decl.body.any? do |elem|
              elem.attributes.include?(:async) ||
              elem.attributes.include?(:pause) ||
              elem.attributes.include?(:resume)
            end then
              decl.body.declarations += globals.map do |decl|
                bpl "var #{decl.names.map{|g| ["#{g}.save", "#{g}.guess"]}.flatten * ", "}: #{decl.type};"
              end
            end

            decl.body.replace do |elem|
              case elem
              when AssumeStatement
                if elem.attributes.include? :startpoint
                  # next [ bpl("#tasks := 0;")] +
                  #   [bpl("#t := 0;")] +
                  next accs.map{|g| bpl("#{g}.next := #{g}.start;")} + [elem]

                elsif elem.attributes.include? :endpoint
                  next [elem] +
                    accs.map{|g| bpl("assume #{g} == #{g}.start;")} +
                    accs.map{|g| bpl("#{g} := #{g}.next;")}
                  elem
                  
                elsif elem.attributes.include? :pause
                  next gs.map{|g| bpl("#{g}.save := #{g};")} +
                    gs.map{|g| bpl("#{g} := #{g}.next;")} +
                    gs.map{|g| bpl("havoc #{g}.guess;")} +
                    gs.map{|g| bpl("#{g}.next := #{g}.guess;")}

                elsif elem.attributes.include? :resume
                  next gs.map{|g| bpl("assume #{g} == #{g}.guess;")} +
                    gs.map{|g| bpl("#{g} := #{g}.save;")}
                end

              when CallStatement
                proc = elem.procedure.declaration

                if elem.attributes.include? :async then

                  var = elem.attributes[:async].first

                  elem.attributes.delete :async
                  # elem.arguments << bpl("#tasks") if proc && proc.body

                  # replace the return assignments with dummy assignments
                  elem.assignments.map! do |x|
                    decl.fresh_var(x.declaration.type)
                  end

                  # make sure to pass the 'save'd version of any globals
                  elem.arguments.map! do |e|
                    e.replace do |e|
                      e.is_a?(Identifier) && globals.include?(e.declaration) ? e.save : e
                    end
                  end

                  call_mods = (proc ? proc.modifies & gs : gs).sort
                  call_accs = (proc ? proc.accesses & gs : gs).sort
                  # call_accs = call_mods

                  # some async-simulating guessing magic
                  next call_accs.map{|g| bpl("#{g}.save := #{g};")} +
                    call_accs.map{|g| bpl("#{g} := #{g}.next;")} +
                    call_mods.map{|g| bpl("havoc #{g}.guess;")} +
                    call_mods.map{|g| bpl("#{g}.next := #{g}.guess;")} +
                    # [ bpl("#tasks := #tasks + 1;") ] +
                    # (var ? [bpl("#{var} := #tasks;")] : []) +
                    [ elem ] +
                    call_mods.map{|g| bpl("assume #{g} == #{g}.guess;")} +
                    call_accs.map{|g| bpl("#{g} := #{g}.save;")}

                else # a synchronous procedure call
                  # elem.arguments << bpl("#t") if proc && proc.body

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
