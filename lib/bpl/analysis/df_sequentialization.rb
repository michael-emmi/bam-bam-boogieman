module Bpl
  module AST
    
    class Identifier
      def start; "#{@name}.start".parse end
      def next; "#{@name}.next".parse end
      def guess; "#{@name}.guess".parse end
      def save; "#{@name}.save".parse end
    end
    
    class VariableDeclaration
      def start; "var #{@names.map{|g| "#{g}.start"} * ", "}: #{@type};".parse end
      def next; "var #{@names.map{|g| "#{g}.next"} * ", "}: #{@type};".parse end
      def guess; "var #{@names.map{|g| "#{g}.guess"} * ", "}: #{@type};".parse end
      def save; "var #{@names.map{|g| "#{g}.save"} * ", "}: #{@type};".parse end
    end

    class Program
      def df_sequentialize!

        gs = global_variables.map{|d| d.idents}.flatten
        
        return if gs.empty?

        @declarations << seq_idx = "var #s: int;".parse
        @declarations += global_variables.map(&:next)
        
        replace do |elem|
          case elem
          when AssumeStatement
            if elem.attributes.has_key?(:startpoint)

              ["#s := 0;".parse] +
              ["#s.self := 0;".parse] +
              gs.map{|g| "#{g.next} := #{g.start};".parse} +
              [elem]

            elsif elem.attributes.has_key?(:endpoint)

              [elem] +
              gs.map{|g| "assume #{g} == #{g.start};".parse} +
              gs.map{|g| "#{g} := #{g.next};".parse}

            else
              elem
            end

          when ProcedureDeclaration, ImplementationDeclaration
            if elem.has_body?

              if elem.is_entrypoint?
                elem.body.declarations << "var #s.self: int;".parse 
              else
                elem.parameters << "#s.self: int".parse
              end

              if elem.is_a?(ProcedureDeclaration)
                elem.specifications << "modifies #{gs.map(&:next) * ", "};".parse
                elem.specifications << "modifies #{seq_idx.idents * ", "};".parse
              end
              
              if elem.is_entrypoint?
                elem.body.declarations += global_variables.map(&:start)
              end

              if elem.body.any?{|id| id.is_a?(Identifier) && id.name =~ /.save/}
                elem.body.declarations += global_variables.map(&:save)
                elem.body.declarations += global_variables.map(&:guess)
              end
              
              elem.body.statements.unshift( "call boogie_si_record_int(#s.self);".parse )
            end
            elem

          when CallStatement
            if elem.attributes.include? :async then
              elem.attributes.delete 'async'
              elem.arguments << "#s".parse \
                unless elem.procedure.declaration.nil? || !elem.procedure.declaration.has_body?
              
              # replace the return assignments with dummy assignments
              elem.assignments.map! do |x|
                elem.parent.fresh_var(x.declaration.type).idents.first
              end
              
              # make sure to pass the 'save'd version of any globals
              elem.arguments.map! do |e|
                e.replace do |e|
                  e.is_a?(Identifier) && global_variables.include?(e.declaration) ? e.save : e
                end                
              end
              
              # some async-simulating guessing magic
              gs.map{|g| "#{g.save} := #{g};".parse} +
              gs.map{|g| "#{g} := #{g.next};".parse} +
              gs.map{|g| "havoc #{g.guess};".parse} +
              gs.map{|g| "#{g.next} := #{g.guess};".parse} +
              [ "#s := #s + 1;".parse, elem ] +
              gs.map{|g| "assume #{g} == #{g.guess};".parse} +
              gs.map{|g| "#{g} := #{g.save};".parse}
              
            else # a synchronous procedure call
              elem.arguments << "#s.self".parse \
                unless elem.procedure.declaration.nil? || !elem.procedure.declaration.has_body?
              elem
            end            
          else
            elem
          end
        end

      end
    end

  end
end
