module Bpl
  module AST
    class Node
      def resolve! scope=nil
        scope ||= [self] if self.respond_to?(:resolve)
        scope ||= []
        scope = [scope] unless scope.is_a?(Array)
        declarations.each {|d| d.parent = self} if self.is_a?(Program)
        traverse do |elem,turn|
          case elem
          when ProcedureDeclaration, FunctionDeclaration, Block, QuantifiedExpression
            case turn
            when :pre then scope.unshift elem
            else scope.shift
            end
            if elem.is_a?(ImplementationDeclaration)
              elem.declaration = self.resolve(ProcedureIdentifier.new(name: elem.name))
              warn "could not resolve implementation #{elem.name}" unless elem.declaration
            end

          when Identifier
            case turn
            when :pre
              if s = scope.find {|s| s.resolve elem} then
                elem.declaration = s.resolve elem
              else
                elem.declaration = nil
                warn "could not resolve identifier #{elem}"
              end
            end

          when CustomType
            case turn
            when :pre
              elem.declaration = scope.last.resolve(elem)
              warn "could not resolve type #{elem}" unless elem.declaration
            end

          when Statement
            case turn
            when :post
              proc_decl = scope.find {|s| s.is_a?(ProcedureDeclaration)}
              elem.parent = proc_decl

              if elem.is_a?(CallStatement) && elem.declaration
                elem.declaration.callers << proc_decl
              end

            end
          end
          elem
        end
      end
    end

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
          ls = @statements.find{|label| label.is_a?(Label) && label.name == id.name}
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