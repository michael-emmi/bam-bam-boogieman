module Bpl
  module AST
    class Resolution < Bpl::Transformation
      def self.description
        "Resolve program identifiers and types."
      end

      def run! program
        program.resolve!
      end
    end

    class Node
      def resolve! scope=nil
        scope ||= [self] if self.respond_to?(:resolve)
        scope ||= []
        scope = [scope] unless scope.is_a?(Array)
        scope.select!{|s| s.respond_to?(:resolve)}

        traverse do |elem,turn|
          case elem
          when ProcedureDeclaration, FunctionDeclaration, Body, QuantifiedExpression
            case turn
            when :pre then scope.unshift elem
            else scope.shift
            end
            if elem.is_a?(ImplementationDeclaration)
              elem.declaration = self.resolve(ProcedureIdentifier.new(name: elem.name))
              warn "could not resolve implementation #{elem.name}" unless elem.declaration
            end

          when Block
            case turn
            when :pre
              scope.unshift elem
            else
              scope.shift
            end

          when Identifier
            case turn
            when :pre
              if s = scope.find {|s| s.resolve elem} then
                elem.declaration = s.resolve elem

                if elem.is_a?(LabelIdentifier) && src = scope.find{|b| b.is_a? Block}
                  src.successors << elem.declaration.id
                  elem.declaration.predecessors << src.id
                end

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
            if elem.is_a?(IfStatement) || elem.is_a?(WhileStatement)
              case turn
              when :pre then scope.unshift elem
              else scope.shift
              end
            end
            case turn
            when :post
              proc_decl = scope.find {|s| s.is_a?(ProcedureDeclaration)}
              elem.parent = proc_decl

              if elem.is_a?(CallStatement) && elem.target
                elem.target.callers << proc_decl
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
          @declarations.find{|d| d.is_a?(StorageDeclaration) && d.names.include?(id.name)}

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

    class Body
      def resolve(id)
        case id
        when StorageIdentifier
          @declarations.find{|decl| decl.names.include? id.name}

        when LabelIdentifier
          ls = @blocks.find{|b| b.labels.find{|l| l.name == id.name}}
          def ls.signature; "label" end if ls
          ls

        else
          nil
        end
      end
    end

    class Block; def resolve(id) return end end

    class IfStatement
      def resolve(id)
        return unless id.is_a?(LabelIdentifier)
        @blocks.find{|b| b.labels.find{|l| l.name == id.name}} ||
        @else && @else.is_a?(Enumerable) &&
        @else.find{|b| b.labels.find{|l| l.name == id.name}}
      end
    end

    class WhileStatement
      def resolve(id)
        return unless id.is_a?(LabelIdentifier)
        @blocks.find{|b| b.labels.find{|l| l.name == id.name}}
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
