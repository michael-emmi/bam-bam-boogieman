require_relative 'node'

module Bpl
  module AST
    class Specification < Node
      attr_accessor :free
    end
    
    class LoopInvariant < Specification
      children :expression
      def print; "#{"free" if @free} invariant #{yield @expression};".fmt end
    end
    
    class RequiresClause < Specification
      children :expression
      def print; "#{"free" if @free} requires #{yield @expression};".fmt end
    end
    
    class ModifiesClause < Specification
      children :identifiers
      def print; "#{"free" if @free} modifies #{@identifiers.map{|a| yield a} * ", "};".fmt end
    end
    
    class EnsuresClause < Specification
      children :expression
      def print; "#{"free" if @free} ensures #{yield @expression};".fmt end
    end
  end
end