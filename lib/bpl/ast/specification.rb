module Bpl
  module AST
    class Specification; attr_accessor :free end
    
    class LoopInvariant < Specification
      attr_accessor :expression
      def initialize(free,expr); @free = free; @expression = expr end
      def to_s; "#{@free ? "free " : ""}invariant #{@expression};" end
    end
    
    class RequiresClause < Specification
      attr_accessor :expression
      def initialize(free,expr); @free = free; @expression = expr end
      def to_s; "#{@free ? "free " : ""}requires #{@expression};" end
    end
    
    class ModifiesClause < Specification
      attr_accessor :identifiers
      def initialize(free,ids); @free = free; @identifiers = ids end
      def to_s; "#{@free ? "free " : ""}modifies #{@identifiers * ", "};" end
    end
    
    class EnsuresClause < Specification
      attr_accessor :expression
      def initialize(free,expr); @free = free; @expression = expr end
      def to_s; "#{@free ? "free " : ""}ensures #{@expression};" end
    end
  end
end