require_relative 'node'

module Bpl
  module AST
    class Specification < Node
      attr_accessor :free
    end

    class LoopInvariant < Specification
      children :expression
      def show; "#{"free" if @free} invariant #{yield @expression};".fmt end
    end

    class RequiresClause < Specification
      children :expression
      def show; "#{"free" if @free} requires #{yield @expression};".fmt end
    end

    class ModifiesClause < Specification
      children :identifiers
      def show; "#{"free" if @free} modifies #{@identifiers.map{|a| yield a} * ", "};".fmt end
    end

    class AccessesClause < Specification
      children :identifiers
      def show; "#{"free" if @free} accesses #{@identifiers.map{|a| yield a} * ", "};".fmt end
    end

    class EnsuresClause < Specification
      children :expression
      def show; "#{"free" if @free} ensures #{yield @expression};".fmt end
    end
  end
end