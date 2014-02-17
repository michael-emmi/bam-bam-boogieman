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
      def to_s
        "assert #{@attributes.empty? ? "" : @attributes * " " + " "}#{@expression};"
      end
    end
    
    class AssumeStatement < Statement
      children :expression
      def to_s
        "assume #{@attributes.empty? ? "" : @attributes * " " + " "}#{@expression};" 
      end
    end
    
    class HavocStatement < Statement
      children :identifiers
      def to_s; "havoc #{@identifiers * ", "};" end
    end
    
    class AssignStatement < Statement
      children :lhs, :rhs
      def to_s; "#{@lhs * ", "} := #{@rhs * ", "};" end
    end
    
    class CallStatement < Statement
      children :procedure, :arguments, :assignments
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
      def to_s
        "if (#{@condition}) #{@block}#{@else.nil? ? "" : " else #{@else}" }"
      end
    end
    
    class WhileStatement < Statement
      children :condition, :invariants, :block
      def to_s
        invs = @invariants.empty? ? " " : "\n" + @invariants * "\n" + "\n"
        "while (#{@condition})#{invs}#{@block}"
      end
    end
    
    class BreakStatement < Statement
      children :identifiers
      def to_s
        tgts = @identifiers.empty? ? "" : " " + @identifiers * ", "
        "break#{tgts};"
      end
    end
    
    class GotoStatement < Statement
      children :identifiers
      def to_s; "goto #{@identifiers * ", "};" end
    end
    
    class Block
      include Traversable
      children :declarations, :statements
      def to_s
        str = "\n"
        str << @declarations * "\n"
        str << "\n\n" if @declarations
        str << @statements.map{|s| s.is_a?(String) ? "#{s}:" : s} * "\n"
        str << "\n"
        "{#{str.gsub(/^(.*[^:\n])$/,"#{"  "}\\1")}}"
      end
    end

  end
end