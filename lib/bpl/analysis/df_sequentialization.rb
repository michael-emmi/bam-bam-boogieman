module Bpl
  module AST
    
    class Identifier
      def start; bpl "#{@name}.start" end
      def next; bpl "#{@name}.next" end
      def guess; bpl "#{@name}.guess" end
      def save; bpl "#{@name}.save" end
    end
    
    class VariableDeclaration
      def start; bpl "var #{@names.map{|g| "#{g}.start"} * ", "}: #{@type};" end
      def next; bpl "var #{@names.map{|g| "#{g}.next"} * ", "}: #{@type};" end
      def guess; bpl "var #{@names.map{|g| "#{g}.guess"} * ", "}: #{@type};" end
      def save; bpl "var #{@names.map{|g| "#{g}.save"} * ", "}: #{@type};" end
    end

    class Program
      def df_sequentialize!

        gs = global_variables.map{|d| d.idents}.flatten
        
        return if gs.empty?

        @declarations << seq_idx = bpl("var #s: int;")
        @declarations += global_variables.map(&:next)
        
        replace do |elem|
          case elem
          when AssumeStatement
            if elem.attributes.has_key?(:startpoint)

              [bpl("#s := 0;")] +
              [bpl("#s.self := 0;")] +
              gs.map{|g| bpl("#{g.next} := #{g.start};")} +
              [elem]

            elsif elem.attributes.has_key?(:endpoint)

              [elem] +
              gs.map{|g| bpl("assume #{g} == #{g.start};")} +
              gs.map{|g| bpl("#{g} := #{g.next};")}

            else
              elem
            end

          when ProcedureDeclaration
            if elem.has_body?

              if elem.is_entrypoint?
                elem.body.declarations << bpl("var #s.self: int;")
              else
                elem.parameters << bpl("#s.self: int")
                elem.body.statements.unshift( bpl "call boogie_si_record_int(#s.self);" )
              end

              if elem.is_a?(ProcedureDeclaration)
                elem.specifications << bpl("modifies #{gs.map(&:next) * ", "};")
                elem.specifications << bpl("modifies #{seq_idx.idents * ", "};")
              end
              
              if elem.is_entrypoint?
                elem.body.declarations += global_variables.map(&:start)
              end

              if elem.body.any?{|id| id.is_a?(Identifier) && id.name =~ /.save/}
                elem.body.declarations += global_variables.map(&:save)
                elem.body.declarations += global_variables.map(&:guess)
              end
              
            end
            elem

          when CallStatement
            if elem.attributes.include? :async then
              elem.attributes.delete :async
              elem.arguments << bpl("#s") \
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
              gs.map{|g| bpl("#{g.save} := #{g};")} +
              gs.map{|g| bpl("#{g} := #{g.next};")} +
              gs.map{|g| bpl("havoc #{g.guess};")} +
              gs.map{|g| bpl("#{g.next} := #{g.guess};")} +
              [ bpl("#s := #s + 1;") ] +
              [ elem ] +
              gs.map{|g| bpl("assume #{g} == #{g.guess};")} +
              gs.map{|g| bpl("#{g} := #{g.save};")}
              
            else # a synchronous procedure call
              elem.arguments << bpl("#s.self") \
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
