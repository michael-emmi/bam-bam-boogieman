require_relative 'node'

module Bpl
  module AST
    class Program < Node
      children :declarations
      attr_accessor :source_file
      def print; @declarations.map{|d| yield d} * "\n" end      
      def global_variables; @declarations.select{|d| d.is_a?(VariableDeclaration)} end      
      def name
        "THE PROGRAM W/ NO NAME"
      end

      def fresh_var(prefix,type)
        taken = global_variables.map{|d| d.names}.flatten
        var = prefix unless taken.include?(prefix)
        var ||= (0..Float::INFINITY).each do |i|
          unless taken.include?(v = "#{prefix}_#{i}"); break v end
        end
        @declarations << decl = bpl("var #{var}: #{type};")
        decl
      end

    end
  end
end