require_relative 'traversable'

module Bpl
  module AST
    class Type
      include Traversable
      def inspect; to_s end
      
      Boolean = Type.new
      Integer = Type.new
      def Boolean.inspect; "bool" end
      def Boolean.to_s; "bool" end
      def Integer.inspect; "int" end
      def Integer.to_s; "int" end
    end
    
    class BitvectorType < Type
      attr_accessor :width
      def inspect; "bv#{@width}" end
      def to_s; "bv#{@width}" end
    end
    
    class CustomType < Type
      children :name, :arguments
      def inspect; ([@name] + @arguments.map(&:inspect)) * " " end
      def to_s; ([@name] + @arguments) * " " end
    end
    
    class MapType < Type
      children :arguments, :domain, :range
      def inspect
        args = (@arguments.empty? ? "" : "<#{@arguments.map(&:inspect) * ","}> ")
        "#{args}[#{@domain.map(&:inspect) * ","}] #{@range.inspect}"
      end
      def to_s
        args = (@arguments.empty? ? "" : "<#{@arguments * ","}> ")
        "#{args}[#{@domain * ","}] #{@range}"
      end
    end
  end
end