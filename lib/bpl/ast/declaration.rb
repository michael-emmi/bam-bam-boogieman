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
    
    class ConstantDeclaration < Declaration
      attr_accessor :names, :type
      attr_accessor :unique, :order_spec
      def initialize(n,t,attrs,uniq,ord)
        @names = n
        @type = t
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
    
    class VariableDeclaration < Declaration
      attr_accessor :names, :type, :where
      def initialize(ns,t,w,attrs); @names = ns; @type = t; @where = w; @attributes = attrs end
      def to_s
        lhs = (@attributes + [@names * ", "]) * " "
        rhs = ([@type] + (@where ? ['where',@where] : [])) * " "
        "var #{lhs}: #{rhs};"
      end
    end
    
    class ProcedureDeclaration < Declaration
      attr_accessor :name, :type_arguments, :parameters, :returns
      attr_accessor :specification
      attr_accessor :variables, :statements
      def initialize(ax,n,ts,ps,rs,sp,bd)
        @attributes = ax
        @name = n
        @type_arguments = ts
        @parameters = ps
        @returns = rs
        @specification = sp
        @variables = bd ? bd[0] : nil
        @statements = bd ? bd[1] : nil
      end
      def body?; !@statements.nil? end
      def to_s
        front = (@attributes + [@name]) * " "
        params = @parameters.map{|x,t| "#{x}:#{t}"} * ", "
        ret = (@returns.empty? ? "" : " returns (" + @returns.map{|x,t| "#{x}:#{t}"} * ", " + ")")
        sig = "(#{params})#{ret}"
        specs = @specification.empty? ? "" : ("\n" + @specification * "\n")
        vars = (@variables && !@variables.empty?) ? ("\n  " + @variables * "\n  ") : ""
        stmts = @statements ? ("\n" + @statements.map{|ls,s| (ls * ":\n") + (ls.empty? ? "" : ":\n") + "  #{s}"} * "\n") : ""
        body = body? ? "\n{#{vars}#{stmts}\n}" : ""
        "procedure #{front}#{sig}#{";" unless body?} #{specs}#{body}"
      end
    end
    
    class ImplementationDeclaration < Declaration
    end
  end
end