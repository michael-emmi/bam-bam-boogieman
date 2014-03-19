require_relative 'node'

module Bpl
  module AST
    class Statement < Node
    end
    
    class AssertStatement < Statement
      children :expression
      def show(&blk) "assert #{show_attrs(&blk)} #{yield @expression};".fmt end
    end
    
    class AssumeStatement < Statement
      children :expression
      def show(&blk) "assume #{show_attrs(&blk)} #{yield @expression};".fmt end
    end
    
    class HavocStatement < Statement
      children :identifiers
      def show; "havoc #{@identifiers.map{|a| yield a} * ", "};" end
    end
    
    class AssignStatement < Statement
      children :lhs, :rhs
      def show; "#{@lhs.map{|a| yield a} * ", "} := #{@rhs.map{|a| yield a} * ", "};" end
    end
    
    class CallStatement < Statement
      children :procedure, :arguments, :assignments
      def forall?; @assignments.nil? end
      def declaration; @procedure.declaration end
      def show(&blk)
        if @assignments
          rets = @assignments.map{|a| yield a} * ", " + (@assignments.empty? ? '' : ' := ')
        else
          rets = "forall"
        end
        proc = yield @procedure
        args = @arguments.map{|a| yield a} * ", "
        "call #{show_attrs(&blk)} #{rets} #{proc}(#{args});".fmt
      end
    end
    
    class IfStatement < Statement
      children :condition, :block, :else
      def show
        cond = yield @condition
        block = yield @block
        els_ = @else ? " else #{yield @else}" : ""
        "if (#{cond}) #{block}#{els_}"
      end
    end
    
    class WhileStatement < Statement
      children :condition, :invariants, :block
      def show
        invs = @invariants.empty? ? " " : "\n" + @invariants.map{|a| yield a} * "\n" + "\n"
        "while (#{yield @condition})#{invs}#{yield @block}"
      end
    end
    
    class BreakStatement < Statement
      children :identifiers
      def show; "break #{@identifiers.map{|a| yield a} * ", "};" end
    end
    
    class GotoStatement < Statement
      children :identifiers
      def show; "goto #{@identifiers.map{|a| yield a} * ", "};" end
    end
    
    class ReturnStatement < Statement
      def show; "return;" end
    end
    
    class Block < Statement
      children :declarations, :statements
      def show
        str = "\n"
        str << @declarations.map{|d| yield d} * "\n" + "\n\n" unless @declarations.empty?
        str << @statements.map{|s| s.is_a?(String) ? "#{s}:" : yield(s)} * "\n"
        str << "\n"
        "{#{str.gsub(/^(.*[^:\n])$/,"#{"  "}\\1")}}"
      end
    end

  end
end