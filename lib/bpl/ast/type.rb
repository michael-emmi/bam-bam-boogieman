require_relative 'traversable'

module Bpl
  module AST
    class Type
      include Traversable
      
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
      def print; "#{@name} #{@arguments.map{|a| yield a} * " "}".split.join(' ') end
    end
    
    class MapType < Type
      children :arguments, :domain, :range
      def print
        args = @arguments.empty? ? "" : "<#{@arguments.map{|a| yield a} * ","}>"
        "#{args} [#{@domain.map{|a| yield a} * ","}] #{yield @range}".split.join(' ')
      end
    end
  end
end