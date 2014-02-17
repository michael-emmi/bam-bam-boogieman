require_relative 'traversable'

module Bpl
  module AST
    class Declaration
      include Traversable
      attr_accessor :program
      attr_accessor :attributes
    end
    
    class TypeDeclaration < Declaration
      attr_accessor :name, :arguments
      attr_accessor :finite, :type
      def initialize(attrs,fin,n,args,t)
        @attributes = attrs
        @finite = fin
        @name = n
        @arguments = args
        @type = t
      end
      def signature
        "type #{@name}"
      end
      def to_s
        spec = @attributes + (@finite ? ['finite'] : []) + [@name] + @arguments + (@type ? ["= #{@type}"] : [])
        "type #{spec * " "};"
      end
    end
    
    class FunctionDeclaration < Declaration
      attr_accessor :name, :type_arguments, :arguments, :return, :body
      def initialize(attrs,n,targs,args,ret,bd)
        @attributes = attrs
        @name = n
        @type_argument = targs
        @arguments = args
        @return = ret
        @body = bd
      end
      def resolve(id)
        id.is_storage? && @arguments.find{|decl| decl.names.include? id.name}
      end
      def signature
        "function #{@name}(#{@arguments.map{|x|x.type} * ","}) returns (#{@return})"
      end
      def to_s
        str = "function "
        str << @attributes * " " + " " unless @attributes.empty?
        str << "#{@name}(#{@arguments * ", "}) returns (#{@return})"
        str << (@body ? " { #{@body} }" : ";")
      end
    end
    
    class AxiomDeclaration < Declaration
      attr_accessor :expression
      def initialize(attrs,expr)
        @attributes = attrs
        @expression = expr
      end
      def to_s
        (['axiom'] + @attributes + [@expression]) * " " + ';'
      end
    end
    
    class NameDeclaration < Declaration
      attr_accessor :names, :type, :where
      def initialize(attrs,names,type,where)
        @attributes = attrs
        @names = names
        @type = type
        @where = where
      end
      def signature
        "#{@names * ", "}: #{@type}"
      end
      def to_s
        str = ""
        str << @attributes * " " + " " unless @attributes.empty?
        str << @names * ", "
        str << ": " unless @names.empty?
        str << @type.to_s
        str << " where #{@where}" if @where
        str
      end
    end
    
    class VariableDeclaration < NameDeclaration
      def initialize(attrs,names,type,where)
        super(attrs,names,type,where)
      end
      def signature
        "var #{@names * ", "}: #{@type}"
      end
      def to_s; "var #{super.to_s};" end
    end
    
    class ConstantDeclaration < NameDeclaration
      attr_accessor :unique, :order_spec
      def initialize(attrs,uniq,names,type,ord)
        super(attrs,names,type,nil)
        @unique = uniq
        @order_spec = ord
      end
      def signature
        "const #{@names * ", "}: #{@type}"
      end
      def to_s
        lhs = @attributes + (@unique ? ['unique'] : []) + [@names * ", "]
        rhs = [@type]
        if @order_spec && @order_spec[0]
          rhs << ['<:'] 
          unless @order_spec[0].empty?
            rhs << @order_spec[0].map{|c,p| (c ? 'unique ' : '') + p.to_s } * ", " 
          end
        end
        rhs << ['complete'] if @order_spec && @order_spec[1]
        "const #{lhs * " "}: #{rhs * " "};"
      end
    end
    
    class ProcedureDeclaration < Declaration
      attr_accessor :name, :type_arguments, :parameters, :returns
      attr_accessor :specifications
      attr_accessor :variables, :statements
      def initialize(attrs,name,targs,params,rets,specs,body)
        @attributes = attrs
        @name = name
        @type_arguments = targs
        @parameters = params
        @returns = rets
        @specifications = specs
        @body = body
      end
      def resolve(id)
        if id.is_storage? then
          @parameters.find{|decl| decl.names.include? id.name} ||
          @returns.find{|decl| decl.names.include? id.name} ||
          @body && @body.declarations.find{|decl| decl.names.include? id.name}
        elsif id.is_label? && @body then
          ls = @body.statements.find{|label| label == id.name}
          def ls.signature; "label" end if ls
          ls
        else
          nil
        end
      end
      def sig_string
        str = "#{(@attributes + [@name]) * " "}"
        str << "(#{@parameters * ", "})"
        str << " returns (#{@returns * ", "})" unless @returns.empty?
        str
      end
      def signature
        "procedure #{@name}(#{@parameters.map{:type} * ","})" +
        (@returns.empty? ? "" : " returns (#{@returns.map{:type} * ","})")
      end
      def to_s
        str = "procedure #{sig_string}"
        str << ";" unless @body
        str << "\n" + @specifications * "\n" unless @specifications.empty?
        str << "\n" + @body.to_s if @body
        str
      end
    end
    
    class ImplementationDeclaration < ProcedureDeclaration
      def initialize(attrs,name,targs,params,rets,bodies)
        super(attrs,name,targs,params,rets,[],bodies)
      end
      def to_s
        str = "implementation #{sig_string}"
        str << "\n" + (@body * "\n")
        str
      end
    end
  end
end