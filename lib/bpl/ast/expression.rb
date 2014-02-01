require_relative 'type'

module Bpl
  module AST
    class Expression
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
      def initialize(n); @name = n end
      alias to_s name
    end
    
    class FunctionApplication < Expression
      attr_accessor :name, :arguments
      def initialize(f,args); @name = f; @arguments = args end
      def to_s; "#{name}(#{arguments * ","})" end
    end
    
    class UnaryExpression < Expression
      attr_accessor :expression
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
      attr_accessor :lhs, :op, :rhs
      def initialize(vs); @lhs, @op, @rhs = vs end
      def to_s; "(#{lhs} #{op} #{rhs})" end
    end
    
    class MapSelect < Expression
      attr_accessor :map, :indexes
      def initialize(m,idx); @map = m; @indexes = idx end
      def to_s; "#{map}[#{indexes * ","}]" end
    end
    
    class MapUpdate < Expression
      attr_accessor :map, :indexes, :value
      def initialize(m,idx,v); @map = m; @indexes = idx; @value = v end
      def to_s; "#{map}[#{indexes * ","} := #{value}]" end
    end
    
    class BitvectorExtract < Expression
      attr_accessor :bitvector, :msb, :lsb
      def initialize(v,m,l); @bitvector = v; @msb = m; @lsb = l end
      def to_s; "#{@bitvector}[#{@msb}:#{@lsb}]" end
    end
    
    class QuantifiedExpression < Expression
      attr_accessor :quantifier, :type_arguments, :variables, :expression
      attr_accessor :attributes, :triggers
      def initialize(q,tvs,vs,ants,e)
        @quantifier = q
        @type_arguments = tvs
        @variables = vs
        @attributes = ants.select{|a| a.is_a? Attribute}
        @triggers = ants.select{|t| t.is_a? Trigger}
        @expression = e
      end
      def to_s
        tvs = @type_arguments.empty? ? " " : " <#{@type_arguments * ", "}> "
        vs = @variables.map{|v,t| "#{v}: #{t}"} * ", "
        lhs = @quantifier + tvs + vs
        rhs = (@attributes + @triggers + [@expression]) * " "
        "(#{lhs} :: #{rhs})"
      end
    end
    
    class Attribute
      attr_accessor :name, :values
      def initialize(n,vs); @name = n; @values = vs end
      def to_s
        vs = @values.map{|s| (s.is_a? String) ? "\"#{s}\"" : s } * ", "
        "{:#{@name}#{vs.empty? ? "" : " " + vs}}"
      end
    end
    
    class Trigger
      attr_accessor :expressions
      def initialize(es); @expressions = es end
      def to_s; "{#{@expressions * ", "}}" end
    end
  end
end