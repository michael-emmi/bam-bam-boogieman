require_relative 'node'

module Bpl
  module AST
    class Type < Node
      Boolean = Type.new
      Integer = Type.new
      def Boolean.print; "bool" end
      def Integer.print; "int" end
    end
    
    class BitvectorType < Type
      attr_accessor :width
      def print; "bv#{@width}" end
    end
    
    class CustomType < Type
      children :name, :arguments
      def eql?(other)
        other.is_a?(CustomType) && other.name == @name
      end
      def print; "#{@name} #{@arguments.map{|a| yield a} * " "}".split.join(' ') end
    end
    
    class MapType < Type
      children :arguments, :domain, :range
      def eql?(other)
        other.is_a?(MapType) && 
        other.domain.count == @domain.count &&
        other.domain.zip(@domain).all?{|t1,t2| t1.eql?(t2)} &&
        other.range.eql?(@range)
      end
      def print
        args = @arguments.empty? ? "" : "<#{@arguments.map{|a| yield a} * ","}>"
        "#{args} [#{@domain.map{|a| yield a} * ","}] #{yield @range}".split.join(' ')
      end
    end
  end
end