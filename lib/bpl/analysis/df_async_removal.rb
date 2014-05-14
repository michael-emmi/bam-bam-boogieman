module Bpl
  module Analysis
    module DFAsyncRemoval

      def async_to_call! program        
        return unless program.any? {|elem| elem.attributes.include?(:async)}
        globals = program.global_variables
        gs = globals.map(&:idents).flatten
        
        if globals.empty?
          program.each {|elem| elem.attributes.delete(:async)}
          return
        end

        globals.each do |decl|
          program << bpl(
            "var #{decl.names.map{|g| "#{g}.next"} * ", "}: #{decl.type};"
          )
        end

        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          next unless proc.body
          accs = (proc.accesses & gs).sort
          mods = accs - proc.modifies

          proc.specifications <<
            bpl("modifies #{mods * ", "};").resolve!(program) \
            unless mods.empty?
          proc.specifications <<
            bpl("modifies #{accs.map{|g| "#{g}.next"} * ", "};").resolve!(program) \
            unless accs.empty?

          globals.each do |decl|
            proc.body.declarations <<
              bpl("var #{decl.names.map{|g| "#{g}.start"} * ", "}: #{decl.type};")
          end if proc.is_entrypoint?

          globals.each do |decl|
            proc.body.declarations <<
              bpl("var #{decl.names.map{|g| ["#{g}.save", "#{g}.guess"]}.flatten * ", "}: #{decl.type};")
          end if proc.body.any? {|elem| elem.attributes.include?(:async)}
          
          scope = [proc.body, proc, program]

          proc.body.replace do |elem|
            case elem
            when AssumeStatement
              if elem.attributes.include? :startpoint
                next accs.map{|g| bpl("#{g}.next := #{g}.start;").resolve!(scope)} + [elem]

              elsif elem.attributes.include? :endpoint
                next [elem] +
                  accs.map{|g| bpl("assume #{g} == #{g}.start;").resolve!(scope)} +
                  accs.map{|g| bpl("#{g} := #{g}.next;").resolve!(scope)}
                elem

              # elsif elem.attributes.include? :pause
              #   next gs.map{|g| bpl("#{g}.save := #{g};")} +
              #     gs.map{|g| bpl("#{g} := #{g}.next;")} +
              #     gs.map{|g| bpl("havoc #{g}.guess;")} +
              #     gs.map{|g| bpl("#{g}.next := #{g}.guess;")}
              # 
              # elsif elem.attributes.include? :resume
              #   next gs.map{|g| bpl("assume #{g} == #{g}.guess;")} +
              #     gs.map{|g| bpl("#{g} := #{g}.save;")}

              end

            when CallStatement
              called = elem.procedure.declaration

              if elem.attributes.include? :async then
                # var = elem.attributes[:async].first
                elem.attributes.delete :async

                # replace the return assignments with dummy assignments
                elem.assignments.map! do |x|
                  proc.fresh_var(x.declaration.type)
                end

                # make sure to pass the 'save'd version of any globals
                elem.arguments.map! do |e|
                  e.replace do |e|
                    e.is_a?(Identifier) && globals.include?(e.declaration) ? e.save : e
                  end
                end

                call_mods = (called ? called.modifies & gs : gs).sort
                call_accs = (called ? called.accesses & gs : gs).sort
                # call_accs = call_mods

                # some async-simulating guessing magic
                next call_accs.map{|g| bpl("#{g}.save := #{g};").resolve!(scope)} +
                  call_accs.map{|g| bpl("#{g} := #{g}.next;").resolve!(scope)} +
                  call_mods.map{|g| bpl("havoc #{g}.guess;").resolve!(scope)} +
                  call_mods.map{|g| bpl("#{g}.next := #{g}.guess;").resolve!(scope)} +
                  # [ bpl("#tasks := #tasks + 1;") ] +
                  # (var ? [bpl("#{var} := #tasks;")] : []) +
                  [ elem ] +
                  call_mods.map{|g| bpl("assume #{g} == #{g}.guess;").resolve!(scope)} +
                  call_accs.map{|g| bpl("#{g} := #{g}.save;").resolve!(scope)}

              else # a synchronous procedure call
                # elem.arguments << bpl("#t") if called && called.body

              end
            end

            elem
          end
        end
      end

    end
  end
end
