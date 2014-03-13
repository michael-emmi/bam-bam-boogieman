require_relative 'node'

module Bpl
  module AST
    class Type < Node
      Boolean = Type.new
      Integer = Type.new
      def Boolean.show; "bool" end
      def Integer.show; "int" end
      alias :old_eql? :eql?
      def eql?(ty) old_eql?(ty.is_a?(CustomType) ? ty.base : ty) end

      # def base; nil end
      # (is_a?(CustomType) ? base : self).oldeql?( ty.is_a?(CustomType) ? ty.base : ty )
    end
    
    class BitvectorType < Type
      attr_accessor :width
      def show; "bv#{@width}" end
    end
    
    class CustomType < Type
      children :name, :arguments
      attr_accessor :declaration
      def base
        case @declaration && @declaration.type
        when CustomType; base(@declaration.type)
        when Type; @declaration.type
        else self
        end
      end
      def eql?(ty)
        ty = ty.is_a?(CustomType) ? ty.base : ty
        case ty
        when CustomType; base.is_a?(CustomType) && base.name == ty.name
        else !base.is_a?(CustomType) && base.eql?(ty)
        end
      end
      def show; "#{@name} #{@arguments.map{|a| yield a} * " "}".fmt end
    end
    
    class MapType < Type
      children :arguments, :domain, :range
      def eql?(ty)
        ty.is_a?(MapType) && 
        ty.domain.count == @domain.count &&
        ty.domain.zip(@domain).all?{|t1,t2| t1.eql?(t2)} &&
        ty.range.eql?(@range)
      end
      def show
        args = @arguments.empty? ? "" : "<#{@arguments.map{|a| yield a} * ","}>"
        "#{args} [#{@domain.map{|a| yield a} * ","}] #{yield @range}".fmt
      end
    end
  end
end