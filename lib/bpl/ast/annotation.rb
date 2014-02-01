module Bpl
  module AST
    class Annotation; attr_accessor :free end
    
    class LoopInvariant < Annotation
      attr_accessor :expression
      def initialize(free,expr); @free = free; @expression = expr end
      def to_s; "#{@free ? "free " : ""}invariant #{@expression};" end
    end
    
    class RequiresClause < Annotation
      attr_accessor :expression
      def initialize(free,expr); @free = free; @expression = expr end
      def to_s; "#{@free ? "free " : ""}requires #{@expression};" end
    end
    
    class ModifiesClause < Annotation
      attr_accessor :identifiers
      def initialize(free,ids); @free = free; @identifiers = ids end
      def to_s; "#{@free ? "free " : ""}modifies #{@identifiers * ", "};" end
    end
    
    class EnsuresClause < Annotation
      attr_accessor :expression
      def initialize(free,expr); @free = free; @expression = expr end
      def to_s; "#{@free ? "free " : ""}ensures #{@expression};" end
    end
  end
end