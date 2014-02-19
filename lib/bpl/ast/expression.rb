require_relative 'traversable'
require_relative 'type'
require 'colorize'

module Bpl
  module AST
    class Expression
      include Traversable
      attr_accessor :scope
      def inspect; to_s end

      Wildcard = Expression.new
      def Wildcard.to_s; "*" end
    end
    
    class Literal < Expression
      attr_accessor :value
    end

    class BooleanLiteral < Literal
      def inspect; (@value ? "true" : "false").bold end
      def to_s; @value ? "true" : "false" end
      def type; Type::Boolean end
    end

    class IntegerLiteral < Literal
      def inspect; "#{@value}" end
      def to_s; "#{@value}" end
      def type; Type::Integer end
    end

    class BitvectorLiteral < Literal
      attr_accessor :base
      def inspect; "#{@value}bv#{@base}".bold end
      def to_s; "#{@value}bv#{@base}" end
      def type; BitvectorType.new @base end
    end
    
    class Identifier < Expression
      attr_accessor :name
      attr_accessor :kind # :label, :procedure, :storage, :function, 
      attr_accessor :declaration
      def is_storage?; @kind && @kind == :storage end
      def is_procedure?; @kind && @kind == :procedure end
      def is_function?; @kind && @kind == :function end
      def is_label?; @kind && @kind == :label end
      def type
        if (d = @declaration) && d.methods.include?(:type) then
          d.type
        else
          nil
        end
      end
      def inspect
        (@declaration ? @name.green : @name.red) + (type ? ":#{type.inspect.yellow}" : "")
      end
      def to_s; @name end
    end
    
    class FunctionApplication < Expression
      children :function, :arguments
      def inspect
        "#{@function.inspect}(#{@arguments.map(&:inspect) * ","})" +
        (type ? ":#{type.inspect.yellow}" : "")
      end
      def to_s; "#{@function}(#{@arguments * ","})" end
      def type
        @function.declaration && @function.declaration.return.type
      end
    end
    
    class UnaryExpression < Expression
      children :expression
    end
    
    class OldExpression < UnaryExpression
      def inspect; "#{'old'.bold}(#{@expression.inspect})" end
      def to_s; "old(#{@expression})" end
      def type; @expression.type end
    end    
    
    class LogicalNegation < UnaryExpression
      def inspect; "!#{@expression.inspect}" end
      def to_s; "!#{@expression}" end
      def type; Type::Boolean end
    end
    
    class ArithmeticNegation < UnaryExpression
      def inspect; "-#{@expression.inspect}" end
      def to_s; "-#{@expression}" end
      def type; Type::Integer end
    end
    
    class BinaryExpression < Expression
      children :lhs, :op, :rhs
      def inspect; "(#{@lhs.inspect} #{@op} #{@rhs.inspect})" end
      def to_s; "(#{@lhs} #{@op} #{@rhs})" end
      def type
        case @op
        when '<==>', '==>', '||', '&&', '==', '!=', '<', '>', '<=', '>=', '<:'
          Type::Boolean
        when '++'
          @lhs.type
        when '+', '-', '*', '/', '%'
          Type::Integer
        end
      end
    end
    
    class MapSelect < Expression
      children :map, :indexes
      def inspect; "#{@map.inspect}[#{@indexes.map(&:inspect) * ","}]" end
      def to_s; "#{@map}[#{@indexes * ","}]" end
      def type; @map.type.is_a?(MapType) && @map.type.range end
    end
    
    class MapUpdate < Expression
      children :map, :indexes, :value
      def inspect; "#{@map.inspect}[#{@indexes.map(&:inspect) * ","} := #{@value.inspect}]" end
      def to_s; "#{@map}[#{@indexes * ","} := #{@value}]" end
      def type; @map.type end
    end
    
    class BitvectorExtract < Expression
      children :bitvector, :msb, :lsb
      def inspect; "#{@bitvector.inspect}[#{@msb}:#{@lsb}]" end
      def to_s; "#{@bitvector}[#{@msb}:#{@lsb}]" end
      def type; BitvectorType.new width: (@msb - @lsb) end
    end
    
    class QuantifiedExpression < Expression
      children :quantifier, :type_arguments, :variables, :expression
      children :attributes, :triggers
      def inspect
        tvs = @type_arguments.empty? ? [] : ["<#{@type_arguments.map(&:inspect) * ", "}>"]
        lhs = ([@quantifier.bold] + tvs + [@variables.map(&:inspect) * ", "]) * " "
        rhs = (@attributes.map(&:inspect) + @triggers.map(&:inspect) + [@expression.inspect]) * " "
        "(#{lhs} :: #{rhs})"
      end
      def to_s
        tvs = @type_arguments.empty? ? [] : ["<#{@type_arguments * ", "}>"]
        lhs = ([@quantifier] + tvs + [@variables * ", "]) * " "
        rhs = (@attributes + @triggers + [@expression]) * " "
        "(#{lhs} :: #{rhs})"
      end
      def type; Type::Boolean end
    end
    
    class Attribute
      include Traversable
      children :name, :values
      def inspect
        vs = @values.map{|s| (s.is_a? String) ? "\"#{s}\"" : s.inspect } * ", "
        "{:#{@name}#{vs.empty? ? "" : " " + vs}}"
      end
      def to_s
        vs = @values.map{|s| (s.is_a? String) ? "\"#{s}\"" : s } * ", "
        "{:#{@name}#{vs.empty? ? "" : " " + vs}}"
      end
    end
    
    class Trigger
      include Traversable
      children :expressions
      def inspect; "{#{@expressions.map(&:inspect) * ", "}}" end
      def to_s; "{#{@expressions * ", "}}" end
    end
  end
end