module Bpl
    
  module Analysis
    def self.resolve! program
      program.declarations.each do |d| d.parent = program end
      scope = [program]
      program.traverse do |elem,turn|
        case elem
        when ProcedureDeclaration, FunctionDeclaration, Block, QuantifiedExpression
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

  module AST
    class Program
      def resolve(id)
        case id
        when StorageIdentifier
          @declarations.find{|d| d.is_a?(NameDeclaration) && d.names.include?(id.name)}

        when FunctionIdentifier
          @declarations.find{|d| d.is_a?(FunctionDeclaration) && d.name == id.name}

        when ProcedureIdentifier
          @declarations.find{|d| d.is_a?(ProcedureDeclaration) && d.name == id.name}

        when Type
          @declarations.find{|d| d.is_a?(TypeDeclaration) && d.name == id.name}

        else
          nil
        end
      end
    end
    
    class ProcedureDeclaration
      def resolve(id)
        return unless id.is_a?(StorageIdentifier)
        @parameters.find{|decl| decl.names.include? id.name} ||
        @returns.find{|decl| decl.names.include? id.name}
      end
    end

    class Block
      def resolve(id)
        case id
        when StorageIdentifier
          @declarations.find{|decl| decl.names.include? id.name}

        when LabelIdentifier
          ls = @statements.find{|label| label == id.name}
          def ls.signature; "label" end if ls
          ls

        else
          nil
        end
      end
    end
    
    class FunctionDeclaration
      def resolve(id)
        id.is_a?(StorageIdentifier) && @arguments.find{|d| d.names.include? id.name}
      end
    end
    
    class QuantifiedExpression
      def resolve(id)
        id.is_a?(StorageIdentifier) && @variables.find{|d| d.names.include? id.name}
      end
    end
    
  end
end