module Bpl
  module AST
    class Program
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
          if elem.is_a?(ProcedureDeclaration) ||
              elem.is_a?(FunctionDeclaration) || 
              elem.is_a?(QuantifiedExpression)
            if turn == :pre then scope.unshift elem else scope.shift end
          elsif turn == :pre && elem.is_a?(Identifier) then
            if s = scope.find {|s| s.resolve elem} then
              elem.declaration = s.resolve elem
            else
              warn "could not resolve identifier #{elem}"
            end
          end
        end
      end
      def to_s
        @declarations * "\n"
      end
      def traverse(&block)
        return unless block_given?
        block.call self, :pre
        @declarations.each{|d| d.traverse(&block)}
        block.call self, :post
      end
      def each(&block)
        traverse {|x,i| block.call x if i == :pre}
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