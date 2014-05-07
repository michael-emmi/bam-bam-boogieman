require_relative 'node'

module Bpl
  module AST
    class Declaration < Node
    end
    
    class TypeDeclaration < Declaration
      children :name, :arguments
      children :finite, :type
      def signature; "type #{@name}" end
      def show(&blk)
        args = @arguments.map{|a| yield a} * " "
        type = @type ? " = #{yield @type}" : ""
        "type #{show_attrs(&blk)} #{'finite' if @finite} #{@name} #{args} #{type};".fmt
      end
    end
    
    class FunctionDeclaration < Declaration
      children :name, :type_arguments, :arguments, :return, :body
      def signature
        args = @arguments.map(&:flatten).flatten.map{|x|x.type} * ","
        "#{@name}(#{args}): #{@return.type}".gsub(/\s/,'')
      end
      def show(&blk)
        args = @arguments.map{|a| yield a} * ", "
        ret = yield @return
        body = @body ? " { #{yield @body} }" : ";"
        "function #{show_attrs(&blk)} #{@name}(#{args}) returns (#{ret})#{body}".fmt
      end
    end
    
    class AxiomDeclaration < Declaration
      children :expression
      def show(&blk) "axiom #{show_attrs(&blk)} #{yield @expression};".fmt end
    end
    
    class NameDeclaration < Declaration
      children :names, :type, :where
      def signature; "#{@names * ", "}: #{@type}" end      
      def show(&blk)
        names = @names.empty? ? "" : (@names * ", " + ":")
        where = @where ? "where #{@where}" : ""
        "#{show_attrs(&blk)} #{names} #{yield @type} #{where}".fmt
      end
      def flatten
        if @names.empty?
          self
        else
          @names.map do |name|
            self.class.new(names: [name], type: @type, where: @where)
          end
        end
      end
      def idents
        @names.map do |name|
          StorageIdentifier.new(name: name, declaration: self)
        end
      end
    end
    
    class VariableDeclaration < NameDeclaration
      def signature; "var #{@names * ", "}: #{@type}" end
      def show; "var #{super};" end
    end
    
    class ConstantDeclaration < NameDeclaration
      children :unique, :order_spec
      def signature; "const #{@names * ", "}: #{@type}" end
      def show(&blk)
        names = @names.empty? ? "" : (@names * ", " + ":")
        ord = ""
        if @order_spec && @order_spec[0]
          ord << ' <: '
          unless @order_spec[0].empty?
            ord << @order_spec[0].map{|c,p| (c ? 'unique ' : '') + p.to_s } * ", " 
          end
        end
        ord << ' complete' if @order_spec && @order_spec[1]
        "const #{show_attrs(&blk)} #{'unique' if @unique} #{names} #{yield @type}#{ord};".fmt
      end
    end
    
    class ProcedureDeclaration < Declaration
      children :name, :type_arguments, :parameters, :returns
      children :specifications, :body
      attr_accessor :callers
      def initialize(opts = {})
        super(opts)
        @callers = Set.new
      end
      def modifies
        specifications.map{|s| s.is_a?(ModifiesClause) ? s.identifiers : []}.flatten
      end
      def sig(&blk)
        params = @parameters.map{|a| yield a} * ", "
        rets = @returns.empty? ? "" : "returns (#{@returns.map{|a| yield a} * ", "})"
        "#{show_attrs(&blk)} #{@name}(#{params}) #{rets}".fmt
      end
      def signature
        "#{@name}(#{@parameters.map(&:type) * ","})" +
        (@returns.empty? ? "" : ":#{@returns.map(&:type) * ","}")
      end
      def show(&block)
        specs = @specifications.empty? ? "" : "\n"
        specs << "// accesses #{accesses.map{|a| yield a} * ", "};\n" \
          if respond_to?(:accesses) && accesses && !accesses.empty?
        specs << @specifications.map{|a| yield a} * "\n"
        if @body
          "procedure #{sig(&block)}#{specs}\n#{yield @body}"
        else
          "procedure #{sig(&block)};#{specs}"
        end
      end
    end
    
    class ImplementationDeclaration < ProcedureDeclaration
      def show; "implementation #{sig(&block)}\n#{yield @body}" end
    end
  end
end