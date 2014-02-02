module Bpl
  module AST
    class Declaration
      attr_accessor :attributes
    end
    
    class TypeDeclaration < Declaration
      attr_accessor :name, :arguments
      attr_accessor :finite, :type
      def initialize(n,args,attrs,fin,t)
        @name = n
        @arguments = args
        @attributes = attrs
        @finite = fin
        @type = t
      end
      def to_s
        spec = @attributes + (@finite ? ['finite'] : []) + [@name] + @arguments + (@type ? ["= #{@type}"] : [])
        "type #{spec * " "};"
      end
    end
    
    class FunctionDeclaration < Declaration
      attr_accessor :name, :type_arguments, :arguments, :return, :body
      def initialize(n,targs,args,ret,bd,attrs)
        @name = n
        @type_argument = targs
        @arguments = args
        @return = ret
        @body = bd
        @attributes = attrs
      end
      def to_s
        front = (@attributes + [@name]) * " "
        params = @arguments.map{|x,t| x ? "#{x}:#{t}" : "#{t}" } * ", "
        ret = (@return.first ? "#{@return[0]}:" : "") + "#{@return[1]}"
        sig = "(#{params}) returns (#{ret})"
        "function #{front}#{sig}#{@body ? " { #{@body} }" : ";"}"
      end
    end
    
    class AxiomDeclaration < Declaration
      attr_accessor :expression
      def initialize(expr,attrs); @expression = expr; @attributes = attrs end
      def to_s; (['axiom'] + @attributes + [@expression]) * " " + ';' end
    end
    
    class NameDeclaration < Declaration
      attr_accessor :names, :type, :where
      def initialize(names,type,where)
        @attributes = []
        @names = names
        @type = type
        @where = where
      end
      def to_s
        lhs = (@attributes + [@names * ", "]) * " "
        rhs = ([@type] + (@where ? ['where',@where] : [])) * " "
        "#{lhs}: #{rhs}"
      end
    end
    
    class VariableDeclaration < NameDeclaration
      def initialize(attrs,names,type,where)
        super(names,type,where)
        @attributes = attrs
      end
      def to_s; "var #{super.to_s};" end
    end
    
    class ConstantDeclaration < NameDeclaration
      attr_accessor :unique, :order_spec
      def initialize(attrs,names,type,uniq,ord)
        super(names,type,nil)
        @attributes = attrs
        @unique = uniq
        @order_spec = ord
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
      def sig_string
        str = "#{(@attributes + [@name]) * " "}"
        str << "(#{@parameters * ", "})"
        str << " returns (#{@returns * ", "})" unless @returns.empty?
        str
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