module Bpl
  module AST
    class Program
      attr_accessor :declarations
      def initialize(decls); @declarations = decls end
      def to_s
        @declarations * "\n\n"
      end
    end
  end
end