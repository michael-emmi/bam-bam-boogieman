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
      children :expression
      def show; "return #{@expression ? (yield @expression) : "" };".fmt end
    end
    
    class Label < Node
      attr_accessor :name
      def show; name.to_s end
    end

    class Block < Statement
      children :declarations, :labels, :statements
      def initialize(opts = {})
        super(opts)
        @labels = @statements.select{|l| l.is_a?(Label)}
      end
      def fresh_var(prefix,type,taken=[])
        taken += @declarations.map{|d| d.names}.flatten
        name = fresh_from(prefix || "$var", taken)
        @declarations << decl = VariableDeclaration.new(names: [name], type: type)
        return StorageIdentifier.new(name: name, declaration: decl)
      end
      def fresh_label(prefix)
        name = fresh_from (prefix || "$bb"), @labels.map(&:name)
        @labels << decl = Label.new(name: name)
        return LabelIdentifier.new(name: name, declaration: decl)
      end
      def fresh_from(prefix,taken)
        return prefix unless taken.include?(prefix) || prefix.empty?
        (0..Float::INFINITY).each do |i|
           break "#{prefix}_#{i}" unless taken.include?("#{prefix}_#{i}")
        end
      end
      def show
        str = "\n"
        str << @declarations.map{|d| yield d} * "\n" + "\n\n" unless @declarations.empty?
        str << @statements.map{|s| s.is_a?(Label) ? "#{s}:" : yield(s)} * "\n"
        str << "\n"
        "{#{str.gsub(/^(.*[^:\n])$/,"#{"  "}\\1")}}"
      end
    end

  end
end