require_relative 'traversable'

module Bpl
  module AST
    class Program
      include Traversable
      children :declarations
      
      def add(decl)
        @declarations << decl
        decl.program = self
      end

      def to_s; @declarations * "\n" end
      def inspect; @declarations.map(&:inspect) * "\n" end
      
      def name
        "THE PROGRAM W/ NO NAME"
      end
    end
  end
end