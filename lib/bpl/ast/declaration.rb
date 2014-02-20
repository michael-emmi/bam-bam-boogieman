require_relative 'traversable'

module Bpl
  module AST
    class Declaration
      include Traversable
      attr_accessor :program
      children :attributes
    end
    
    class TypeDeclaration < Declaration
      children :name, :arguments
      children :finite, :type
      def signature; "type #{@name}" end
      def print
        attrs = @attributes.map{|a| yield a} * " "
        args = @arguments.map{|a| yield a} * " "
        type = @type ? " = #{yield @type}" : ""
        "type #{attrs} #{'finite' if @finite} #{@name} #{args} #{type};".squeeze("\s")
      end
    end
    
    class FunctionDeclaration < Declaration
      children :name, :type_arguments, :arguments, :return, :body
      def resolve(id)
        id.is_storage? && @arguments.find{|decl| decl.names.include? id.name}
      end
      def signature
        "function #{@name}(#{@arguments.map{|x|x.type} * ","}) returns (#{@return})"
      end
      def print
        attrs = @attributes.map{|a| yield a} * " "
        args = @arguments.map{|a| yield a} * ", "
        ret = yield @return
        body = @body ? " { #{yield @body} }" : ";"
        "function #{attrs} #{@name}(#{args}) returns (#{ret})#{body}".squeeze("\s")
      end
    end
    
    class AxiomDeclaration < Declaration
      children :expression
      def print; "axiom #{@attributes.map{|a| yield a} * " "} #{yield @expression};".squeeze("\s") end
    end
    
    class NameDeclaration < Declaration
      children :names, :type, :where
      def signature; "#{@names * ", "}: #{@type}" end      
      def print
        attrs = @attributes.map{|a| yield a} * " "
        names = @names.empty? ? "" : (@names * ", " + ":")
        where = @where ? "where #{@where}" : ""
        "#{attrs} #{names} #{yield @type} #{where}".split.join(' ')
      end
    end
    
    class VariableDeclaration < NameDeclaration
      def signature; "var #{@names * ", "}: #{@type}" end
      def print; "var #{super};" end
    end
    
    class ConstantDeclaration < NameDeclaration
      children :unique, :order_spec
      def signature; "const #{@names * ", "}: #{@type}" end
      def print
        attrs = @attributes.map{|a| yield a} * " "
        names = @names.empty? ? "" : (@names * ", " + ":")
        ord = ""
        if @order_spec && @order_spec[0]
          ord << ' <: '
          unless @order_spec[0].empty?
            ord << @order_spec[0].map{|c,p| (c ? 'unique ' : '') + p.to_s } * ", " 
          end
        end
        ord << ' complete' if @order_spec && @order_spec[1]
        "const #{attrs} #{'unique' if @unique} #{names} #{yield @type}#{ord};".squeeze("\s")
      end
    end
    
    class ProcedureDeclaration < Declaration
      children :name, :type_arguments, :parameters, :returns
      children :specifications, :body
      def sig
        attrs = @attributes.map{|a| yield a} * " "
        params = @parameters.map{|a| yield a} * ", "
        rets = @returns.empty? ? "" : "returns (#{@returns.map{|a| yield a} * ", "})"
        "#{attrs} #{@name}(#{params}) #{rets}".split.join(' ')
      end
      def signature
        "procedure #{@name}(#{@parameters.map{:type} * ","})" +
        (@returns.empty? ? "" : " returns (#{@returns.map{:type} * ","})")
      end
      def print(&block)
        specs = @specifications.empty? ? "" : "\n"
        specs << @specifications.map{|a| yield a} * "\n"
        if @body
          "procedure #{sig(&block)}#{specs}\n#{yield @body}"
        else
          "procedure #{sig(&block)};#{specs}"
        end
      end
    end
    
    class ImplementationDeclaration < ProcedureDeclaration
      def print; "implementation #{sig(&block)}\n#{yield @body}" end
    end
  end
end