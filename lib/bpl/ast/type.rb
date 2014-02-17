require_relative 'traversable'

module Bpl
  module AST
    class Type
      include Traversable
      Boolean = Type.new
      Integer = Type.new
      def Boolean.to_s; "bool" end
      def Integer.to_s; "int" end
    end
    
    class BitvectorType < Type
      attr_accessor :width
      def to_s; "bv#{@width}" end
    end
    
    class CustomType < Type
      attr_accessor :name, :arguments
      def to_s; ([@name] + @arguments) * " " end
    end
    
    class MapType < Type
      attr_accessor :arguments, :range, :domain
      def to_s
        args = (@arguments.empty? ? "" : "<#{@arguments * ","}> ")
        "#{args}[#{@range * ","}] #{@domain}"
      end
    end
  end
end