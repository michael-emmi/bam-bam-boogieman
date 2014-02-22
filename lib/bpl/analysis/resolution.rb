module Bpl
  module AST
    
    class Program
      def resolve!
        @declarations.each do |d| d.parent = self end
        scope = [self]
        traverse do |elem,turn|
          case elem
          when ProcedureDeclaration, FunctionDeclaration, QuantifiedExpression
            case turn
            when :pre then scope.unshift elem
            else scope.shift
            end
          when Identifier
            case turn
            when :pre
              if s = scope.find {|s| s.resolve elem} then
                elem.declaration = s.resolve elem
              else
                warn "could not resolve identifier #{elem}"
              end
            end
          when CustomType
            case turn
            when :pre
              elem.declaration = scope.last.resolve(elem)
              warn "could not resolve type #{elem}"  unless elem.declaration

            end
          when Statement
            elem.parent = scope.first
          end
          elem
        end
      end      
    end
    
    class Program
      def resolve(id)
        case id
        when Identifier
          @declarations.find do |decl|
            id.is_storage? && decl.is_a?(NameDeclaration) && decl.names.include?(id.name) ||
            id.is_function? && decl.is_a?(FunctionDeclaration) && decl.name == id.name ||
            id.is_procedure? && decl.is_a?(ProcedureDeclaration) && decl.name == id.name
          end
        when Type
          @declarations.find do |decl|
            decl.is_a?(TypeDeclaration) && decl.name == id.name
          end
        else
          nil
        end
      end
    end
    
    class ProcedureDeclaration
      def resolve(id)
        if id.is_storage? then
          @parameters.find{|decl| decl.names.include? id.name} ||
          @returns.find{|decl| decl.names.include? id.name} ||
          @body && @body.declarations.find{|decl| decl.names.include? id.name}
        elsif id.is_label? && @body then
          ls = @body.statements.find{|label| label == id.name}
          def ls.signature; "label" end if ls
          ls
        else
          nil
        end
      end
    end
    
    class FunctionDeclaration
      def resolve(id)
        id.is_storage? && @arguments.find{|decl| decl.names.include? id.name}
      end
    end
    
    class QuantifiedExpression
      def resolve(id)
        id.is_storage? && @variables.find{|decl| decl.names.include? id.name}
      end
    end
    
  end
end