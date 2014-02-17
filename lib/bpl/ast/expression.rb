require_relative 'traversable'
require_relative 'type'
require 'colorize'

module Bpl
  module AST
    class Expression
      include Traversable
      attr_accessor :scope

      Wildcard = Expression.new
      def Wildcard.to_s; "*" end
    end
    
    class Literal < Expression
      attr_accessor :value
      def initialize(v); @value = v end
    end

    class BooleanLiteral < Literal
      def to_s; @value ? "true" : "false" end
      def type; Type::Boolean end
    end

    class IntegerLiteral < Literal
      def to_s; "#{@value}" end
      def type; Type::Integer end
    end

    class BitvectorLiteral < Literal
      attr_accessor :base
      def initialize(v); @value = v[0]; @base = v[1] end
      def to_s; "#{value}bv#{base}" end
      def type; BitvectorType.new @base end
    end
    
    class Identifier < Expression
      attr_accessor :name
      attr_accessor :kind # :label, :procedure, :storage, :function, 
      attr_accessor :declaration
      def initialize(n); @name = n end
      def is_storage?; @kind && @kind == :storage end
      def is_procedure?; @kind && @kind == :procedure end
      def is_function?; @kind && @kind == :function end
      def is_label?; @kind && @kind == :label end
      def to_s
        @declaration ? @name.green : @name.red
        # @name + (@declaration ? "<#{@declaration.signature}>".green : "<?>".red)
      end
    end
    
    class FunctionApplication < Expression
      children :function, :arguments
      def initialize(f,args); @function = f; @arguments = args end
      def to_s; "#{@function}(#{@arguments * ","})" end
    end
    
    class UnaryExpression < Expression
      children :expression
      def initialize(e); @expression = e end
    end
    
    class OldExpression < UnaryExpression
      def to_s; "old(#{expression})" end
    end    
    
    class LogicalNegation < UnaryExpression
      def to_s; "!#{expression}" end
    end
    
    class ArithmeticNegation < UnaryExpression
      def to_s; "-#{expression}" end
    end
    
    class BinaryExpression < Expression
      children :lhs, :op, :rhs
      def initialize(vs); @lhs, @op, @rhs = vs end
      def to_s; "(#{lhs} #{op} #{rhs})" end
    end
    
    class MapSelect < Expression
      children :map, :indexes
      def initialize(m,idx); @map = m; @indexes = idx end
      def to_s; "#{map}[#{indexes * ","}]" end
    end
    
    class MapUpdate < Expression
      children :map, :indexes, :value
      def initialize(m,idx,v); @map = m; @indexes = idx; @value = v end
      def to_s; "#{map}[#{indexes * ","} := #{value}]" end
    end
    
    class BitvectorExtract < Expression
      children :bitvector, :msb, :lsb
      def initialize(v,m,l); @bitvector = v; @msb = m; @lsb = l end
      def to_s; "#{@bitvector}[#{@msb}:#{@lsb}]" end
    end
    
    class QuantifiedExpression < Expression
      children :quantifier, :type_arguments, :variables, :expression
      children :attributes, :triggers
      def initialize(q,tvs,vs,ants,e)
        @quantifier = q
        @type_arguments = tvs
        @variables = vs
        @attributes = ants.select{|a| a.is_a? Attribute}
        @triggers = ants.select{|t| t.is_a? Trigger}
        @expression = e
      end
      def resolve(id)
        id.is_storage? && @variables.find{|decl| decl.names.include? id.name}
      end
      def to_s
        tvs = @type_arguments.empty? ? [] : ["<#{@type_arguments * ", "}>"]
        lhs = ([@quantifier] + tvs + [@variables * ", "]) * " "
        rhs = (@attributes + @triggers + [@expression]) * " "
        "(#{lhs} :: #{rhs})"
      end
    end
    
    class Attribute
      include Traversable
      children :name, :values
      def initialize(n,vs); @name = n; @values = vs end
      def to_s
        vs = @values.map{|s| (s.is_a? String) ? "\"#{s}\"" : s } * ", "
        "{:#{@name}#{vs.empty? ? "" : " " + vs}}"
      end
    end
    
    class Trigger
      include Traversable
      children :expressions
      def initialize(es); @expressions = es end
      def to_s; "{#{@expressions * ", "}}" end
    end
  end
end