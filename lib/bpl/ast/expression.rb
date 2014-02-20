require_relative 'traversable'
require_relative 'type'
require 'colorize'

module Bpl
  module AST
    class Expression
      include Traversable
      attr_accessor :scope

      Wildcard = Expression.new
      def Wildcard.print; "*" end
    end
    
    class Literal < Expression
      attr_accessor :value
    end

    class BooleanLiteral < Literal
      def print; @value ? "true" : "false" end
      def type; Type::Boolean end
    end

    class IntegerLiteral < Literal
      def print; "#{@value}" end
      def type; Type::Integer end
    end

    class BitvectorLiteral < Literal
      attr_accessor :base
      def print; "#{@value}bv#{@base}" end
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
      def print; @name end
      def inspect
        (@declaration ? @name.green : @name.red) + (type ? ":#{type.inspect.yellow}" : "")
      end
    end
    
    class FunctionApplication < Expression
      children :function, :arguments
      def print; "#{yield @function}(#{@arguments.map{|a| yield a} * ","})" end
      def inspect
        "#{@function.inspect}(#{@arguments.map(&:inspect) * ", "})" +
        (type ? ":#{type.inspect.yellow}" : "")
      end
      def type
        @function.declaration && @function.declaration.return.type
      end
    end
    
    class UnaryExpression < Expression
      children :expression
    end
    
    class OldExpression < UnaryExpression
      def print; "old(#{yield @expression})" end
      def type; @expression.type end
    end    
    
    class LogicalNegation < UnaryExpression
      def print; "!#{yield @expression}" end
      def type; Type::Boolean end
    end
    
    class ArithmeticNegation < UnaryExpression
      def print; "-#{yield @expression}" end
      def type; Type::Integer end
    end
    
    class BinaryExpression < Expression
      children :lhs, :op, :rhs
      def print; "(#{yield @lhs} #{@op} #{yield @rhs})" end
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
      def print; "#{yield @map}[#{@indexes.map{|a| yield a} * ","}]" end
      def type; @map.type.is_a?(MapType) && @map.type.range end
    end
    
    class MapUpdate < Expression
      children :map, :indexes, :value
      def print; "#{yield @map}[#{@indexes.map{|a| yield a} * ","} := #{yield @value}]" end
      def type; @map.type end
    end
    
    class BitvectorExtract < Expression
      children :bitvector, :msb, :lsb
      def print; "#{yield @bitvector}[#{@msb}:#{@lsb}]" end
      def type; BitvectorType.new width: (@msb - @lsb) end
    end
    
    class QuantifiedExpression < Expression
      children :quantifier, :type_arguments, :variables, :expression
      children :attributes, :triggers
      def print
        if @type_arguments.empty?
          tvs = ""
        else
          tvs = "<#{@type_arguments.map{|a| yield a} * ", "}>"
        end
        vs = @variables.map{|a| yield a} * ", "
        as = @attributes.map{|a| yield a} * " "
        ts = @triggers.map{|a| yield a} * " "
        "(#{@quantifier} #{tvs} #{vs} :: #{as} #{ts} #{yield @expression})".squeeze("\s")
      end
      def type; Type::Boolean end
    end
    
    class Attribute < Expression
      children :name, :values
      def print
        vs = @values.map{|s| (s.is_a? String) ? "\"#{s}\"" : yield(s) } * ", "
        "{:#{@name}#{vs.empty? ? "" : " #{vs}"}}"
      end
    end
    
    class Trigger < Expression
      children :expressions
      def print; "{#{@expressions.map{|a| yield a} * ", "}}" end
    end
  end
end