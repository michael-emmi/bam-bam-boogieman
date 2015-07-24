require_relative 'node'

module Bpl
  module AST
    class Program < Node
      include Scope

      children :declarations

      def initialize(opts = {})
        super(opts)
        @declarations.each {|d| d.link(self)}
      end

      def add(decl)
        decl.link(self)
        @declarations << decl
      end

      alias_method :<<, :add

      def remove(decl)
        decl.unlink
        @declarations.delete(decl)
      end

      attr_accessor :source_file
      def show; @declarations.map{|d| yield d} * "\n" end
      def global_variables; @declarations.select{|d| d.is_a?(VariableDeclaration)} end
      def name
        "THE PROGRAM W/ NO NAME"
      end

      def fresh_var(prefix,type)
        taken = global_variables.map{|d| d.names}.flatten
        name = prefix unless taken.include?(prefix)
        name ||= (0..Float::INFINITY).each do |i|
          break "#{prefix}_#{i}" unless taken.include?("#{prefix}_#{i}")
        end
        self << decl = bpl("var #{name}: #{type};")
        return StorageIdentifier.new(name: name, declaration: decl)
      end

    end
  end
end
