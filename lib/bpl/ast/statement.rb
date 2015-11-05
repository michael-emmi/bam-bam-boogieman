require_relative 'node'

module Bpl
  module AST
    class Statement < Node
    end

    module Printing
      def self.indent(str)
        str.gsub(/^(.*)$/,"  \\1").
        gsub(/^\s+(#{Bpl::IDENTIFIER}:[^=].*)$/,"\\1")
      end
      def self.braces(str) "{\n" + indent(str) + "\n}" end
    end

    class AssertStatement < Statement
      children :expression
      def show(&blk)
        "#{yield :assert} #{show_attrs(&blk)} #{yield @expression};".fmt
      end
    end

    class AssumeStatement < Statement
      children :expression
      def show(&blk)
        "#{yield :assume} #{show_attrs(&blk)} #{yield @expression};".fmt
      end
    end

    class HavocStatement < Statement
      children :identifiers
      def show
        "#{yield :havoc} #{@identifiers.map{|a| yield a} * ", "};"
      end
    end

    class AssignStatement < Statement
      children :lhs, :rhs
      def show
        "#{@lhs.map{|a| yield a} * ", "} := #{@rhs.map{|a| yield a} * ", "};"
      end
    end

    class GotoStatement < Statement
      children :identifiers
      def show
        "#{yield :goto} #{@identifiers.map{|a| yield a} * ", "};"
      end
    end

    class ReturnStatement < Statement
      children :expression
      def show
        "#{yield :return} #{@expression ? (yield @expression) : "" };".fmt
      end
    end

    class CallStatement < Statement
      children :procedure, :arguments, :assignments
      def forall?; @assignments.nil? end
      def target; @procedure.declaration end
      def show(&blk)
        if @assignments
          rets = @assignments.map{|a| yield a} * ", " + (@assignments.empty? ? '' : ' := ')
        else
          rets = "forall"
        end
        proc = yield @procedure
        args = @arguments.map{|a| yield a} * ", "
        "#{yield :call} #{show_attrs(&blk)} #{rets} #{proc}(#{args});".fmt
      end
    end

    class IfStatement < Statement
      include Scope
      def declarations
        @blocks +
        case @else
        when IfStatement then @else.declarations
        when Enumerable then @else
        else []
        end
      end

      children :condition, :blocks, :else
      def show
        body = Printing.braces(@blocks.map{|b| yield b} * "\n")
        rest = case @else
        when IfStatement
          " else " + yield(@else)
        when Enumerable
          " else " + Printing.braces(@else.map{|b| yield b} * "\n")
        else
          ""
        end
        "#{yield :if} (#{yield @condition}) #{body}#{rest}"
      end
    end

    class WhileStatement < Statement
      include Scope
      def declarations; @blocks end

      children :condition, :invariants, :blocks
      def show
        body = Printing.braces(@blocks.map{|b| yield b} * "\n")
        invs = @invariants.map{|a| yield a} * "\n"
        invs = "\n" + invs + "\n" unless invs.empty?
        "#{yield :while} (#{yield @condition})#{invs} #{body}"
      end
    end

    class BreakStatement < Statement
      children :identifiers
      def show; "#{yield :break} #{@identifiers.map{|a| yield a} * ", "};" end
    end

    class Block < Declaration
      children :names, :statements

      def predecessors; @predecessors ||= Set.new end
      def successors; @successors ||= Set.new end
      def dominators; @dominators ||= Set.new end

      def name; names.first || "" end
      def id; LabelIdentifier.new(name: name, declaration: self) end

      def copy
        Block.new(names: names.dup, statements: statements.map(&:copy))
      end

      def show
        (names.empty? ? "" : "#{name}:\n") +
        (names.drop(1) + statements).map{|s| yield s} * "\n"
      end
    end

    class Body < Node
      children :locals, :blocks

      def definitions; @definitions ||= {} end
      def loops; @loops ||= {} end
      def live; @live ||= {} end

      include Scope
      def declarations; locals + blocks end

      def show
        Printing.braces((locals + blocks).map{|b| yield b} * "\n")
      end

      def fresh_var(prefix,type,taken=[])
        taken += @locals.map{|d| d.names}.flatten
        name = fresh_from(prefix || "$var", taken)
        append_children(:locals, bpl("var #{name}: #{type};"))
        bpl(name)
      end

      def fresh_label(prefix)
        name = fresh_from (prefix || "$bb"), @blocks.map{|b| b.names.map(&:name)}.flatten
        decl = Label.new(name: name)
        return LabelIdentifier.new(name: name, declaration: decl)
      end

      def fresh_from(prefix,taken)
        return prefix unless taken.include?(prefix) || prefix.empty?
        (0..Float::INFINITY).each do |i|
           break "#{prefix}_#{i}" unless taken.include?("#{prefix}_#{i}")
        end
      end

    end
  end
end
