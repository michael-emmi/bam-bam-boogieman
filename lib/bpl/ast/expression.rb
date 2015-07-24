require_relative 'node'
require_relative 'type'

module Bpl
  module AST
    class Expression < Node
      Wildcard = Expression.new
      def Wildcard.show; "*" end
    end

    class Literal < Expression
      attr_accessor :value
    end

    class BooleanLiteral < Literal
      def eql?(bool) bool.is_a?(BooleanLiteral) && bool.value == @value end
      def show; "#{yield (@value ? :true : :false)}" end
      def type; Type::Boolean end
    end

    class IntegerLiteral < Literal
      def eql?(int) int.is_a?(IntegerLiteral) && int.value == @value end
      def show; "#{@value}" end
      def type; Type::Integer end
    end

    class BitvectorLiteral < Literal
      attr_accessor :base
      def eql?(bv) bv.is_a?(BitvectorLiteral) && bv.base == @base && bv.value == value end
      def show; "#{@value}bv#{@base}" end
      def type; BitvectorType.new @base end
    end

    class Identifier < Expression
      include Binding
      attr_accessor :name

      # XXX identifiers should be unique so that we can distinguish between
      # bindings, for example
      # def hash; name.hash end
      # def <=>(id)  @name <=> id.name end
      # def eql?(id) id.is_a?(self.class) && id.name == @name end

      def type
        declaration.type if declaration.respond_to? :type
      end
      def is_variable?
        declaration && declaration.is_a?(VariableDeclaration) || false
      end
      def is_global?
        declaration && declaration.parent && declaration.parent.is_a?(Program) || false
      end
      def show; @name end
      def hilite
        (declaration ? (is_global? ? @name.blue : @name.green) : @name.red) +
        (type ? ":#{type.hilite}" : "")
      end
    end

    class StorageIdentifier < Identifier; end
    class ProcedureIdentifier < Identifier; end
    class FunctionIdentifier < Identifier; end
    class LabelIdentifier < Identifier; end

    class FunctionApplication < Expression
      children :function, :arguments
      def eql?(fa)
        fa.is_a?(FunctionApplication) &&
        fa.function.eql?(@function) &&
        fa.arguments.eql?(@arguments)
      end
      def show; "#{yield @function}(#{@arguments.map{|a| yield a} * ","})" end
      def hilite
        "#{@function.hilite}(#{@arguments.map(&:hilite) * ", "})" +
        (type ? ":#{type.hilite}" : "")
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
      def show; "old(#{yield @expression})" end
      def type; @expression.type end
    end

    class LogicalNegation < UnaryExpression
      def show; "!#{yield @expression}" end
      def type; Type::Boolean end
    end

    class ArithmeticNegation < UnaryExpression
      def show; "-#{yield @expression}" end
      def type; Type::Integer end
    end

    class BinaryExpression < Expression
      children :lhs, :op, :rhs
      def eql?(be)
        be.is_a?(BinaryExpression) &&
        be.lhs.eql?(@lhs) && be.op == @op && be.rhs.eql?(@rhs)
      end
      def show; "(#{yield @lhs} #{@op} #{yield @rhs})" end
      def type
        case @op
        when '<==>', '==>', '||', '&&', '==', '!=', '<', '>', '<=', '>=', '<:'
          Type::Boolean
        when '++'
          l = @lhs.type && l.is_a?(BitvectorType) &&
          r = @rhs.type && r.is_a?(BitvectorType) &&
          BitvectorType.new(width: l.width + r.width)
        when '+', '-', '*', '/', '%'
          Type::Integer
        end
      end
    end

    class IfExpression < Expression
      children :condition, :then, :else
      def eql?(ie)
        ie.is_a?(IfExpression) &&
        ie.condition.eql?(@condition) &&
        ie.then.eql?(@then) &&
        ie.else.eql?(@else)
      end
      def show
        "(#{yield :if} #{yield @condition} #{yield :then} #{yield @then} #{yield :else} #{yield @else})"
      end
      def type; @then.type end
    end

    class CodeExpression < Expression
      children :block
      def eql?(ce) ce.is_a?(CodeExpression) && ce.block.eql?(@block) end
      def show; "|#{yield @block}|" end
      def type; Type::Boolean end
    end

    class MapSelect < Expression
      children :map, :indexes
      def eql?(ms)
        ms.is_a?(MapSelect) &&
        ms.map.eql?(@map) && ms.indexes.eql?(@indexes)
      end
      def show; "#{yield @map}[#{@indexes.map{|a| yield a} * ","}]" end
      def type; @map.type.is_a?(MapType) && @map.type.range end
    end

    class MapUpdate < Expression
      children :map, :indexes, :value
      def eql?(ms)
        ms.is_a?(MapSelect) &&
        ms.map.eql?(@map) && ms.indexes.eql?(@indexes) && ms.value.eql?(@value)
      end
      def show; "#{yield @map}[#{@indexes.map{|a| yield a} * ","} := #{yield @value}]" end
      def type; @map.type end
    end

    class BitvectorExtract < Expression
      children :bitvector, :msb, :lsb
      def eql?(bve)
        bve.is_a?(BitvectorExtract) &&
        bve.bitvector.eql?(@bitvector) && bve.msb == @msb && bve.lsb == @lsb
      end
      def show; "#{yield @bitvector}[#{@msb}:#{@lsb}]" end
      def type; BitvectorType.new width: (@msb - @lsb) end
    end

    class QuantifiedExpression < Expression
      include Scope
      def declarations; @variables end

      children :quantifier, :type_arguments, :variables, :expression, :triggers
      def eql?(qe)
        qe.is_a?(QuantifiedExpression) &&
        qe.quantifier == @quantifier &&
        qe.type_arguments.eql?(@type_arguments) &&
        qe.variables.eql?(@variables) &&
        qe.expression.eql?(@expression) &&
        qe.triggers.eql?(@triggers)
      end
      def show(&block)
        if @type_arguments.empty?
          tvs = ""
        else
          tvs = "<#{@type_arguments.map{|a| yield a} * ", "}>"
        end
        vs = @variables.map{|a| yield a} * ", "
        as = show_attrs(&block)
        ts = @triggers.map{|t| yield t} * " "
        "(#{@quantifier} #{tvs} #{vs} :: #{as} #{ts} #{yield @expression})".fmt
      end
      def type; Type::Boolean end
    end

    class Trigger < Expression
      children :expressions
      def eql?(t) t.is_a?(Trigger) && t.expressions.eql(@expressions) end
      def show(&block) "{#{@expressions.map{|e| yield e} * ", "}}" end
    end
  end
end
