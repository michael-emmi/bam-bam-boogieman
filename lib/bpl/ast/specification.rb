require_relative 'node'

module Bpl
  module AST
    class Specification < Node
      attr_accessor :free
    end
    
    class LoopInvariant < Specification
      children :expression
      def print; "#{"free" if @free} invariant #{yield @expression};".split.join(' ') end
    end
    
    class RequiresClause < Specification
      children :expression
      def print; "#{"free" if @free} requires #{yield @expression};".split.join(' ') end
    end
    
    class ModifiesClause < Specification
      children :identifiers
      def print; "#{"free" if @free} modifies #{@identifiers.map{|a| yield a} * ", "};".split.join(' ') end
    end
    
    class EnsuresClause < Specification
      children :expression
      def print; "#{"free" if @free} ensures #{yield @expression};".split.join(' ') end
    end
  end
end