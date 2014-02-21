require_relative 'node'

module Bpl
  module AST
    class Statement < Node
    end
    
    class AssertStatement < Statement
      children :expression
      def print(&blk) "assert #{print_attrs(&blk)} #{yield @expression};".squeeze("\s") end
    end
    
    class AssumeStatement < Statement
      children :expression
      def print(&blk) "assume #{print_attrs(&blk)} #{yield @expression};".squeeze("\s") end
    end
    
    class HavocStatement < Statement
      children :identifiers
      def print; "havoc #{@identifiers.map{|a| yield a} * ", "};" end
    end
    
    class AssignStatement < Statement
      children :lhs, :rhs
      def print; "#{@lhs.map{|a| yield a} * ", "} := #{@rhs.map{|a| yield a} * ", "};" end
    end
    
    class CallStatement < Statement
      children :procedure, :arguments, :assignments
      def forall?; @assignments.nil? end
      def print(&blk)
        if @assignments
          rets = @assignments.map{|a| yield a} * ", " + (@assignments.empty? ? '' : ' := ')
        else
          rets = "forall"
        end
        proc = yield @procedure
        args = @arguments.map{|a| yield a} * ", "
        "call #{print_attrs(&blk)} #{rets} #{proc}(#{args});".squeeze("\s")
      end
    end
    
    class IfStatement < Statement
      children :condition, :block, :else
      def print
        cond = yield @condition
        block = yield @block
        els_ = @else ? " else #{yield @else}" : ""
        "if (#{cond}) #{block}#{els_}"
      end
    end
    
    class WhileStatement < Statement
      children :condition, :invariants, :block
      def print
        invs = @invariants.empty? ? " " : "\n" + @invariants.map{|a| yield a} * "\n" + "\n"
        "while (#{yield @condition})#{invs}#{yield @block}"
      end
    end
    
    class BreakStatement < Statement
      children :identifiers
      def print; "break #{@identifiers.map{|a| yield a} * ", "};" end
    end
    
    class GotoStatement < Statement
      children :identifiers
      def print; "goto #{@identifiers.map{|a| yield a} * ", "};" end
    end
    
    class ReturnStatement < Statement
      def print; "return;" end
    end
    
    class Block < Statement
      children :declarations, :statements
      def print
        str = "\n"
        str << @declarations.map{|d| yield d} * "\n" + "\n\n" unless @declarations.empty?
        str << @statements.map{|s| s.is_a?(String) ? "#{s}:" : yield(s)} * "\n"
        str << "\n"
        "{#{str.gsub(/^(.*[^:\n])$/,"#{"  "}\\1")}}"
      end
    end

  end
end