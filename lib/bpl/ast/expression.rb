require_relative 'node'
require_relative 'type'

module Bpl
  module AST
    class Expression < Node
      Wildcard = Expression.new
      def Wildcard.print; "*" end
    end
    
    class Literal < Expression
      attr_accessor :value
    end

    class BooleanLiteral < Literal
      def eql?(bool) bool.is_a?(BooleanLiteral) && bool.value == @value end
      def print; @value ? "true" : "false" end
      def type; Type::Boolean end
    end

    class IntegerLiteral < Literal
      def eql?(int) int.is_a?(IntegerLiteral) && int.value == @value end
      def print; "#{@value}" end
      def type; Type::Integer end
    end

    class BitvectorLiteral < Literal
      attr_accessor :base
      def eql?(bv) bv.is_a?(BitvectorLiteral) && bv.base == @base && bv.value == value end
      def print; "#{@value}bv#{@base}" end
      def type; BitvectorType.new @base end
    end
    
    class Identifier < Expression
      attr_accessor :name
      attr_accessor :kind # :label, :procedure, :storage, :function, 
      attr_accessor :declaration
      def hash; name.hash end
      def eql?(id) id.is_a?(Identifier) && id.name == @name && id.kind == @kind end
      def is_storage?; @kind && @kind == :storage end
      def is_procedure?; @kind && @kind == :procedure end
      def is_function?; @kind && @kind == :function end
      def is_label?; @kind && @kind == :label end
      
      def is_variable?
        @declaration && @declaration.is_a?(VariableDeclaration)
      end
      def is_constant?
        @declaration && @declaration.is_a?(ConstantDeclaration)
      end
      def is_local?
        @declaration && @declaration.parent && 
        @declaration.parent.is_a?(ProcedureDeclaration)
      end
      def is_global?
        @declaration && @declaration.parent && 
        @declaration.parent.is_a?(Program)
      end

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
      def eql?(fa)
        fa.is_a?(FunctionApplication) &&
        fa.function.eql?(@function) &&
        fa.arguments.eql?(@arguments)
      end
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
      def eql?(ue) ue.is_a?(self.class) && ue.expression.eql?(@expression) end
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
      def eql?(be)
        be.is_a?(BinaryExpression) &&
        be.lhs.eql?(@lhs) && be.op == @op && be.rhs.eql?(@rhs)
      end
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
      def eql?(ms)
        ms.is_a?(MapSelect) &&
        ms.map.eql?(@map) && ms.indexes.eql?(@indexes)
      end
      def print; "#{yield @map}[#{@indexes.map{|a| yield a} * ","}]" end
      def type; @map.type.is_a?(MapType) && @map.type.range end
    end
    
    class MapUpdate < Expression
      children :map, :indexes, :value
      def eql?(ms)
        ms.is_a?(MapSelect) &&
        ms.map.eql?(@map) && ms.indexes.eql?(@indexes) && ms.value.eql?(@value)
      end
      def print; "#{yield @map}[#{@indexes.map{|a| yield a} * ","} := #{yield @value}]" end
      def type; @map.type end
    end
    
    class BitvectorExtract < Expression
      children :bitvector, :msb, :lsb
      def eql?(bve)
        bve.is_a?(BitvectorExtract) &&
        bve.bitvector.eql?(@bitvector) && bve.msb == @msb && bve.lsb == @lsb
      end
      def print; "#{yield @bitvector}[#{@msb}:#{@lsb}]" end
      def type; BitvectorType.new width: (@msb - @lsb) end
    end
    
    class QuantifiedExpression < Expression
      children :quantifier, :type_arguments, :variables, :expression, :triggers
      def eql?(qe)
        qe.is_a?(QuantifiedExpression) &&
        qe.quantifier == @quantifier &&
        qe.type_arguments.eql?(@type_arguments) &&
        qe.variables.eql?(@variables) &&
        qe.expression.eql?(@expression) &&
        qe.triggers.eql?(@triggers)
      end
      def print(&block)
        if @type_arguments.empty?
          tvs = ""
        else
          tvs = "<#{@type_arguments.map{|a| yield a} * ", "}>"
        end
        vs = @variables.map{|a| yield a} * ", "
        as = print_attrs(&block)
        ts = @triggers.map{|t| yield t} * " "
        "(#{@quantifier} #{tvs} #{vs} :: #{as} #{ts} #{yield @expression})".fmt
      end
      def type; Type::Boolean end
    end
    
    class Trigger < Expression
      children :expressions
      def eql?(t) t.is_a?(Trigger) && t.expressions.eql(@expressions) end
      def print(&block) "{#{@expressions.map{|e| yield e} * ", "}}" end
    end
  end
end