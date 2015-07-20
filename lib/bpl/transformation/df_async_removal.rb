module Bpl
  module Transformation
    class DfAsyncRemoval < Bpl::Pass
      def self.description
        "The async-to-call part of the EQR sequentialization."
      end

      def run! program
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
            bpl("modifies #{mods * ", "};", scope: program) \
            unless mods.empty?
          proc.specifications <<
            bpl("modifies #{accs.map{|g| "#{g}.next"} * ", "};", scope: program) \
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

          proc.body.each do |stmt|
            case stmt
            when AssumeStatement
              if stmt.attributes.include? :startpoint
                stmt.insert_before \
                  *(accs.map{|g| bpl("#{g}.next := #{g}.start;", scope: scope)})

              elsif stmt.attributes.include? :endpoint
                stmt.insert_after *(
                  accs.map{|g| bpl("assume #{g} == #{g}.start;", scope: scope)} +
                  accs.map{|g| bpl("#{g} := #{g}.next;", scope: scope)})

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
              called = stmt.target

              if stmt.attributes.include? :async then
                # var = elem.attributes[:async].first
                stmt.attributes.delete :async

                # replace the return assignments with dummy assignments
                stmt.assignments.map! do |x|
                  proc.fresh_var(x.declaration.type)
                end

                # make sure to pass the 'save'd version of any globals
                stmt.arguments.map! do |e|
                  e.replace! do |e|
                    e.is_a?(Identifier) && globals.include?(e.declaration) ? e.save : e
                  end
                end

                call_mods = (called ? called.modifies & gs : gs).sort
                call_accs = (called ? called.accesses & gs : gs).sort
                # call_accs = call_mods

                # some async-simulating guessing magic
                stmt.insert_before *(
                  call_accs.map{|g| bpl("#{g}.save := #{g};", scope: scope)} +
                  call_accs.map{|g| bpl("#{g} := #{g}.next;", scope: scope)} +
                  call_mods.map{|g| bpl("havoc #{g}.guess;", scope: scope)} +
                  call_mods.map{|g| bpl("#{g}.next := #{g}.guess;", scope: scope)})
                  # [ bpl("#tasks := #tasks + 1;") ] +
                  # (var ? [bpl("#{var} := #tasks;")] : []) +
                stmt.insert_after *(
                  call_mods.map{|g| bpl("assume #{g} == #{g}.guess;", scope: scope)} +
                  call_accs.map{|g| bpl("#{g} := #{g}.save;", scope: scope)})

              else # a synchronous procedure call
                # elem.arguments << bpl("#t") if called && called.body

              end
            end

          end
        end
        Bpl::Analysis::correct_modifies! program
      end

    end
  end
end
