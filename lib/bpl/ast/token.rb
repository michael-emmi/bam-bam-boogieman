module Bpl
  module AST
    class Token
      attr_reader :line
      def initialize(line_number)
        @line = line_number
      end
      def to_s
        @line.to_s
      end
    end
  end
end
