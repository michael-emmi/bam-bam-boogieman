require_relative 'node'

module Bpl
  module AST
    class Program < Node
      children :declarations
      def print; @declarations.map{|d| yield d} * "\n" end      
      def global_variables; @declarations.select{|d| d.is_a?(VariableDeclaration)} end      
      def name
        "THE PROGRAM W/ NO NAME"
      end
    end
  end
end