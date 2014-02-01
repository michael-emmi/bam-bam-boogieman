module Bpl
  module AST
    class Type
      Boolean = Type.new
      Integer = Type.new
      def Boolean.to_s; "bool" end
      def Integer.to_s; "int" end
    end
    
    class BitvectorType < Type
      attr_accessor :width
      def initialize(w); @width = w end
      def to_s; "bv#{@width}" end
    end
    
    class CustomType < Type
      attr_accessor :name
      def initialize(n); @name = n end
      def to_s; @name.to_s end
    end
  end
end