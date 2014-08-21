require_relative 'node'
require 'Forwardable'

module Bpl
  module AST
    class Statement < Node
      attr_reader :block
      def insert_before(*stmts)
        return unless @block
        idx = @block.index(self)
        @block.insert(idx,*stmts) if idx
      end
      def insert_after(*stmts)
        return unless @block
        idx = @block.index(self)
        @block.insert(idx+1,*stmts) if idx
      end
      def replace_with(*stmts)
        return unless @block
        idx = @block.index(self)
        @block.insert(idx+1,*stmts) if idx
        @block.delete_at(idx) if idx
      end
      def remove; @block.delete(self) if @block end
    end

    module Printing
      def self.indent(str) str.gsub(/^(.*)$/,"  \\1").gsub(/^\s+(#{Bpl::IDENTIFIER}:[^=].*)$/,"\\1") end
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
      include RelationalContainer
      extend Forwardable

      children :labels, :statements

      attr_reader :body, :predecessors, :successors

      container_relation :@statements, :@block
      add_methods :push, :<<, :unshift, :insert, :[]=
      remove_methods :pop, :shift, :delete_at, :delete
      def_delegators :@statements, :[], :at, :first, :last, :index
      def_delegators :@statements, :length, :count, :size, :empty?, :include?

      def initialize(opts = {})
        super(opts)
        @labels ||= []
        @statements ||= []
        @predecessors ||= []
        @successors ||= []
        @statements.each{|s| s.instance_variable_set(:@block,self)}
      end

      def name; @labels.first && @labels.first.name || "?" end
      def id; LabelIdentifier.new(name: name, declaration: self) end

      def show
        preds = @predecessors && " // preds " + @predecessors.map{|p| yield p} * ", "
        (@labels.empty? ? "" : "#{name}:#{preds}\n") +
        (@labels.drop(1) + @statements).map{|s| yield s} * "\n"
      end

      def insert_before(*blks)
        return unless @body
        idx = @body.index(self)
        @body.insert(idx,*blks) if idx
      end
      def insert_after(*blks)
        return unless @body
        idx = @body.index(self)
        @body.insert(idx+1,*blks) if idx
      end
      def replace_with(*blks)
        return unless @body
        idx = @body.index(self)
        @body.delete_at(idx) if idx
        @body.insert(idx,*blks) if idx
      end
      def remove; @body.delete(self) if @body end
    end

    class Body < Node
      include RelationalContainer
      extend Forwardable

      children :declarations, :blocks

      container_relation :@blocks, :@body
      add_methods :push, :<<, :unshift, :insert
      remove_methods :pop, :shift, :delete_at, :delete
      def_delegators :@blocks, :[], :at, :first, :last, :index
      def_delegators :@blocks, :length, :count, :size, :empty?, :include?

      def initialize(opts = {})
        super(opts)
        @declarations ||= []
        @blocks ||= []
        @blocks.each{|b| b.instance_variable_set(:@body,self)}
      end

      def show
        Printing.braces((@declarations + @blocks).map{|b| yield b} * "\n")
      end

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
    end
  end
end
