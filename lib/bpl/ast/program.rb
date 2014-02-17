require_relative 'traversable'

module Bpl
  module AST
    class Program
      include Traversable
            
      attr_accessor :declarations

      def initialize(decls = [])
        @declarations = decls
        @declarations.each do |d|
          d.program = self
        end
      end
      def add(decl)
        @declarations << decl
        decl.program = self
      end
      def resolve_identifiers        
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
          end
          elem
        end

        replace do |p|
          case p
          when ProcedureDeclaration
            p unless p.name =~ /printf/
          when CallStatement
            p.attributes << Attribute.new("found", [1])
            p
          else
            p
          end
        end
      end

      def to_s
        @declarations * "\n"
      end      
      
      def resolve(id)
        @declarations.find do |decl|
          id.is_storage? && decl.is_a?(NameDeclaration) && decl.names.include?(id.name) ||
          id.is_function? && decl.is_a?(FunctionDeclaration) && decl.name == id.name ||
          id.is_procedure? && decl.is_a?(ProcedureDeclaration) && decl.name == id.name
        end
      end
      def name
        "THE PROGRAM W/ NO NAME"
      end
    end
  end
end