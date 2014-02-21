
class String
  def parse; BoogieLanguage.new.parse_str(self) end
end

module Bpl
  module AST
    
    class Identifier
      def next; "#{@name}.next".parse end
      def guess; "#{@name}.guess".parse end
      def save; "#{@name}.save".parse end
      # def next; Identifier.new(name: "#{@name}.next", kind: @kind) end
      # def guess; Identifier.new(name: "#{@name}.guess", kind: @kind) end
      # def save; Identifier.new(name: "#{@name}.save", kind: @kind) end
    end
    
    class VariableDeclaration
      def next; "var #{@names.map{|g| "#{g}.next"} * ", "}: #{@type};".parse end
      def guess; "var #{@names.map{|g| "#{g}.guess"} * ", "}: #{@type};".parse end
      def save; "var #{@names.map{|g| "#{g}.save"} * ", "}: #{@type};".parse end
      # def next; VariableDeclaration.new(names: @names.map{|g| "#{g}.next"}, type: @type, where: @where) end
      # def guess; VariableDeclaration.new(names: @names.map{|g| "#{g}.guess"}, type: @type, where: @where) end
      # def save; VariableDeclaration.new(names: @names.map{|g| "#{g}.save"}, type: @type, where: @where) end
    end

    class Program
      def df_sequentialize!

        gs = global_variables.map{|d| d.idents}.flatten
        
        return if gs.empty?
        
        # TODO wrap this code around the entry point
        begin_code = 
          ["havoc #{gs.map(&:guess) * ", "};".parse] +
          ["#s := 0;".parse] +
          gs.map{|g| "#{g.next} := #{g.guess};".parse}
        end_code =
          gs.map{|g| "assume #{g} == #{g.guess};".parse} +
          gs.map{|g| "#{g} := #{g.next};".parse}

        # @declarations << seq_idx = 
        @declarations << seq_idx = NameDeclaration.new(names: ['#s'], type: Type::Integer)
        @declarations += global_variables.map(&:next)
        
        replace do |elem|
          case elem
          when ProcedureDeclaration, ImplementationDeclaration
            if elem.has_body?
              # elem.parameters << "#s.me: int".parse
              elem.parameters << NameDeclaration.new(names: ['#s.me'], type: Type::Integer)

              if elem.is_a?(ProcedureDeclaration)
                elem.specifications << "modifies #{gs.map(&:next) * ", "};".parse
                elem.specifications << "modifies #{seq_idx.idents * ", "};".parse
              end

              if elem.body.any?{|id| id.is_a?(Identifier) && id.name =~ /.save/}
                elem.body.declarations += global_variables.map(&:save)
                elem.body.declarations += global_variables.map(&:guess)
              end
              
              elem.body.statements.unshift( "call boogie_si_record_int(#s.me);".parse )
            end
            elem

          when CallStatement
            if elem.attributes.include? "async"
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
              elem.arguments << "#s.me".parse \
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