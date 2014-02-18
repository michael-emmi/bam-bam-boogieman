require_relative 'traversable'

module Bpl
  module AST
    class Specification
      include Traversable
      attr_accessor :free
    end
    
    class LoopInvariant < Specification
      children :expression
      def inspect; "#{@free ? "free " : ""}#{'invariant'.bold} #{@expression.inspect};" end
      def to_s; "#{@free ? "free " : ""}invariant #{@expression};" end
    end
    
    class RequiresClause < Specification
      children :expression
      def inspect; "#{@free ? "free " : ""}#{'requires'.bold} #{@expression.inspect};" end
      def to_s; "#{@free ? "free " : ""}requires #{@expression};" end
    end
    
    class ModifiesClause < Specification
      children :identifiers
      def inspect
        (@free ? "free ".bold : "") + "modifies".bold +
        " #{@identifiers.map(&:inspect) * ", "};"
      end
      def to_s; "#{@free ? "free " : ""}modifies #{@identifiers * ", "};" end
    end
    
    class EnsuresClause < Specification
      children :expression
      def inspect; "#{@free ? "free ".bold : ""}#{'ensures'.bold} #{@expression.inspect};" end
      def to_s; "#{@free ? "free " : ""}ensures #{@expression};" end
    end
  end
end