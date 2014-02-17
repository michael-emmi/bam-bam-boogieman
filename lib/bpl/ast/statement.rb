require_relative 'traversable'

module Bpl
  module AST
    class Statement
      include Traversable
      children :attributes
      
      Return = Statement.new
      def Return.to_s; "return;" end
    end
    
    class AssertStatement < Statement
      children :expression
      def initialize(e); @expression = e end
      def to_s; "assert #{@expression};" end
    end
    
    class AssumeStatement < Statement
      children :expression
      def initialize(attrs,e); @attributes = attrs; @expression = e end
      def to_s
        "assume #{@attributes.empty? ? "" : @attributes * " " + " "}#{@expression};" 
      end
    end
    
    class HavocStatement < Statement
      children :identifiers
      def initialize(ids); @identifiers = ids end
      def to_s; "havoc #{@identifiers * ", "};" end
    end
    
    class AssignStatement < Statement
      children :lhs, :rhs
      def initialize(l,r); @lhs = l; @rhs = r end
      def to_s; "#{@lhs * ", "} := #{@rhs * ", "};" end
    end
    
    class CallStatement < Statement
      children :procedure, :arguments, :assignments
      def initialize(attrs,rets,p,args)
        @attributes = attrs
        @procedure = p
        @arguments = args
        @assignments = rets
      end
      def forall?; @assignments.nil? end
      def to_s
        lhs = ""
        lhs << (@attributes * " ") + " " unless @attributes.empty?
        if @assignments then
          lhs << @assignments * ", " + " := " unless @assignments.empty?
        else
          lhs << "forall " if forall?
        end
        "call #{lhs}#{@procedure}(#{@arguments * ", "});"
      end
    end
    
    class IfStatement < Statement
      children :condition, :block, :else
      def initialize(cond,blk,els); @condition = cond; @block = blk; @else = els end
      def to_s
        "if (#{@condition}) #{@block}#{@else.nil? ? "" : " else #{@else}" }"
      end
    end
    
    class WhileStatement < Statement
      children :condition, :invariants, :block
      def initialize(cond,invs,blk)
        @condition = cond
        @invariants = invs
        @block = blk
      end
      def to_s
        invs = @invariants.empty? ? " " : "\n" + @invariants * "\n" + "\n"
        "while (#{@condition})#{invs}#{@block}"
      end
    end
    
    class BreakStatement < Statement
      children :identifiers
      def initialize(ids); @identifiers = ids end
      def to_s
        tgts = @identifiers.empty? ? "" : " " + @identifiers * ", "
        "break#{tgts};"
      end
    end
    
    class GotoStatement < Statement
      children :identifiers
      def initialize(ids); @identifiers = ids end
      def to_s; "goto #{@identifiers * ", "};" end
    end
    
    class Block
      include Traversable
      children :declarations, :statements
      def initialize(decls,stmts)
        @declarations = decls
        @statements = stmts
      end
      def to_s
        str = ""
        unless @declarations.empty?
          str << "\n"
          @declarations.each do |d|
            str << "#{d}\n"
          end
        end
        unless @statements.empty?
          str << "\n"
          @statements.each do |s|
            case s
            when Statement
              str << "#{s}\n"
            else
              str << "#{s}:\n"
            end
          end
        end
        "{#{str.gsub(/^(.*[^:\n])$/,"#{"  "}\\1")}}"
      end
    end

  end
end