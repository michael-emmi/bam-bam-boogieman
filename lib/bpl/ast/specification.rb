require_relative 'node'

module Bpl
  module AST
    class Specification < Node
      attr_accessor :free
    end

    class LoopInvariant < Specification
      children :expression
      def show(&blk)
        "#{yield :free if @free} #{yield :invariant} #{show_attrs(&blk)} #{yield @expression};".fmt
      end
    end

    class RequiresClause < Specification
      children :expression
      def show(&blk)
        "#{yield :free if @free} #{yield :requires} #{show_attrs(&blk)} #{yield @expression};".fmt
      end
    end

    class ModifiesClause < Specification
      children :identifiers
      def show(&blk)
        "#{yield :free if @free} #{yield :modifies} #{show_attrs(&blk)} #{@identifiers.map{|a| yield a} * ", "};".fmt
      end
    end

    class EnsuresClause < Specification
      children :expression
      def show(&blk)
        "#{yield :free if @free} #{yield :ensures} #{show_attrs(&blk)} #{yield @expression};".fmt
      end
    end
  end
end
