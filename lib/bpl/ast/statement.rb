require_relative 'traversable'

module Bpl
  module AST
    class Statement
      include Traversable
      children :attributes
      def inspect; to_s end
      
      Return = Statement.new
      def Return.inspect; 'return'.bold + ';' end
      def Return.to_s; "return;" end
    end
    
    class AssertStatement < Statement
      children :expression
      def inspect
        "#{'assert'.bold} #{@attributes.empty? ? "" : @attributes.map(&:inspect) * " " + " "}#{@expression.inspect};"
      end
      def to_s
        "assert #{@attributes.empty? ? "" : @attributes * " " + " "}#{@expression};"
      end
    end
    
    class AssumeStatement < Statement
      children :expression
      def inspect
        "#{'assume'.bold} #{@attributes.empty? ? "" : @attributes.map(&:inspect) * " " + " "}#{@expression.inspect};" 
      end
      def to_s
        "assume #{@attributes.empty? ? "" : @attributes * " " + " "}#{@expression};" 
      end
    end
    
    class HavocStatement < Statement
      children :identifiers
      def inspect; "havoc #{@identifiers.map(&:inspect) * ", "};" end
      def to_s; "havoc #{@identifiers * ", "};" end
    end
    
    class AssignStatement < Statement
      children :lhs, :rhs
      def inspect; "#{@lhs.map(&:inspect) * ", "} := #{@rhs.map(&:inspect) * ", "};" end
      def to_s; "#{@lhs * ", "} := #{@rhs * ", "};" end
    end
    
    class CallStatement < Statement
      children :procedure, :arguments, :assignments
      def forall?; @assignments.nil? end
      def inspect
        lhs = ""
        lhs << (@attributes.map(&:inspect) * " ") + " " unless @attributes.empty?
        if @assignments then
          lhs << @assignments.map(&:inspect) * ", " + " := " unless @assignments.empty?
        else
          lhs << "forall " if forall?
        end
        "call".bold + " #{lhs}#{@procedure.inspect}(#{@arguments.map(&:inspect) * ", "});"
      end
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
      def inspect
        "#{'if'.bold} (#{@condition.inspect}) #{@block.inspect}#{@else.nil? ? "" : " else #{@else.inspect}" }"
      end
      def to_s
        "if (#{@condition}) #{@block}#{@else.nil? ? "" : " else #{@else}" }"
      end
    end
    
    class WhileStatement < Statement
      children :condition, :invariants, :block
      def inspect
        invs = @invariants.empty? ? " " : "\n" + @invariants.map(&:inspect) * "\n" + "\n"
        "#{'while'.bold} (#{@condition.inspect})#{invs}#{@block.inspect}"
      end
      def to_s
        invs = @invariants.empty? ? " " : "\n" + @invariants * "\n" + "\n"
        "while (#{@condition})#{invs}#{@block}"
      end
    end
    
    class BreakStatement < Statement
      children :identifiers
      def inspect
        tgts = @identifiers.empty? ? "" : " " + @identifiers.map(&:inspect) * ", "
        "#{'break'.bold}#{tgts};"
      end
      def to_s
        tgts = @identifiers.empty? ? "" : " " + @identifiers * ", "
        "break#{tgts};"
      end
    end
    
    class GotoStatement < Statement
      children :identifiers
      def inspect; "#{'goto'.bold} #{@identifiers.map(&:inspect) * ", "};" end
      def to_s; "goto #{@identifiers * ", "};" end
    end
    
    class Block
      include Traversable
      children :declarations, :statements
      def inspect
        str = "\n"
        str << @declarations.map(&:inspect) * "\n"
        str << "\n\n" if @declarations
        str << @statements.map{|s| s.is_a?(String) ? "#{s}:" : s.inspect} * "\n"
        str << "\n"
        "{#{str.gsub(/^(.*[^:\n])$/,"#{"  "}\\1")}}"
      end
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