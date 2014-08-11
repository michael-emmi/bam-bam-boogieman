require_relative 'node'

module Bpl
  module AST
    class Statement < Node
    end

    module Printing
      def self.indent(str) str.gsub(/^(.*[^:\n])$/,"  \\1") end
      def self.braces(str) "{\n" + indent(str) + "\n}" end
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

    class GotoStatement < Statement
      children :identifiers
      def show; "goto #{@identifiers.map{|a| yield a} * ", "};" end
    end

    class ReturnStatement < Statement
      children :expression
      def show; "return #{@expression ? (yield @expression) : "" };".fmt end
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
        "call #{show_attrs(&blk)} #{rets} #{proc}(#{args});".fmt
      end
    end

    class IfStatement < Statement
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
        "if (#{yield @condition}) #{body}#{rest}"
      end
    end

    class WhileStatement < Statement
      children :condition, :invariants, :blocks
      def show
        body = Printing.braces(@blocks.map{|b| yield b} * "\n")
        invs = @invariants.map{|a| yield a} * "\n"
        invs = "\n" + invs + "\n" unless invs.empty?
        "while (#{yield @condition})#{invs} #{body}"
      end
    end

    class BreakStatement < Statement
      children :identifiers
      def show; "break #{@identifiers.map{|a| yield a} * ", "};" end
    end

    class Label < Node
      attr_accessor :name
      def show; "#{name}:" end
    end

    class Block < Node
      children :labels, :statements
      def show; (@labels + @statements).map{|s| yield s} * "\n" end
    end

    class Body < Node
      children :declarations, :blocks

      def fresh_var(prefix,type,taken=[])
        taken += @declarations.map{|d| d.names}.flatten
        name = fresh_from(prefix || "$var", taken)
        @declarations << decl = VariableDeclaration.new(names: [name], type: type)
        return StorageIdentifier.new(name: name, declaration: decl)
      end
      def fresh_label(prefix)
        name = fresh_from (prefix || "$bb"), @blocks.map{|b| b.labels.map(&:name)}.flatten
        decl = Label.new(name: name)
        return LabelIdentifier.new(name: name, declaration: decl)
      end
      def fresh_from(prefix,taken)
        return prefix unless taken.include?(prefix) || prefix.empty?
        (0..Float::INFINITY).each do |i|
           break "#{prefix}_#{i}" unless taken.include?("#{prefix}_#{i}")
        end
      end
      def show
        Printing.braces((@declarations + @blocks).map{|b| yield b} * "\n")
      end
    end
  end
end