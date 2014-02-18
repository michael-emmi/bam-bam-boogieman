require_relative 'traversable'

module Bpl
  module AST
    class Declaration
      include Traversable
      attr_accessor :program
      children :attributes
      def inspect; to_s end
    end
    
    class TypeDeclaration < Declaration
      children :name, :arguments
      children :finite, :type
      def signature; "type #{@name}" end
      def inspect
        spec = @attributes.map(&:inspect) + (@finite ? ['finite'] : []) + 
          [@name] + @arguments.map(&:inspect) + (@type ? ["= #{@type.inspect}"] : [])
        "type #{spec * " "};"
      end
      def to_s
        spec = @attributes + (@finite ? ['finite'] : []) + [@name] + @arguments + (@type ? ["= #{@type}"] : [])
        "type #{spec * " "};"
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
      def inspect
        str = "function ".bold
        str << @attributes.map(&:inspect) * " " + " " unless @attributes.empty?
        str << "#{@name}(#{@arguments.map(&:inspect) * ", "}) #{'returns'.bold} (#{@return.inspect})"
        str << (@body ? " { #{@body.inspect} }" : ";")
      end
      def to_s
        str = "function "
        str << @attributes * " " + " " unless @attributes.empty?
        str << "#{@name}(#{@arguments * ", "}) returns (#{@return})"
        str << (@body ? " { #{@body} }" : ";")
      end
    end
    
    class AxiomDeclaration < Declaration
      children :expression
      def inspect
        (['axiom'.bold] + @attributes.map(&:inspect) + [@expression.inspect]) * " " + ';'
      end
      def to_s; (['axiom'] + @attributes + [@expression]) * " " + ';' end
    end
    
    class NameDeclaration < Declaration
      children :names, :type, :where
      def signature; "#{@names * ", "}: #{@type}" end
      def inspect
        str = ""
        str << @attributes.map(&:inspect) * " " + " " unless @attributes.empty?
        str << @names * ", "
        str << ": " unless @names.empty?
        str << @type.inspect
        str << " where #{@where.inspect}" if @where
        str
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
      def signature; "var #{@names * ", "}: #{@type}" end
      def inspect; "#{'var'.bold} #{eval(super.inspect)};" end
      def to_s; "var #{super.to_s};" end
    end
    
    class ConstantDeclaration < NameDeclaration
      children :unique, :order_spec
      def signature; "const #{@names * ", "}: #{@type}" end
      def inspect
        lhs = @attributes.map(&:inspect) + (@unique ? ['unique'.bold] : []) + [@names * ", "]
        rhs = [@type.inspect]
        if @order_spec && @order_spec[0]
          rhs << ['<:'] 
          unless @order_spec[0].empty?
            rhs << @order_spec[0].map{|c,p| (c ? 'unique '.bold : '') + p.to_s } * ", " 
          end
        end
        rhs << ['complete'.bold] if @order_spec && @order_spec[1]
        "#{'const'.bold} #{lhs * " "}: #{rhs * " "};"
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
      children :name, :type_arguments, :parameters, :returns
      children :specifications, :body
      def inspect_sig
        str = "#{(@attributes.map(&:inspect) + [@name]) * " "}"
        str << "(#{@parameters.map(&:inspect) * ", "}) "
        str << "#{'returns'.bold} (#{@returns.map(&:inspect) * ", "})" unless @returns.empty?
        str
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
      def inspect
        str = "#{'procedure'.bold} #{inspect_sig}"
        str << ";" unless @body
        str << "\n" + @specifications.map(&:inspect) * "\n" unless @specifications.empty?
        str << "\n" + @body.inspect if @body
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
      def inspect
        str = "implementation".bold + " #{inspect_sig}"
        str << "\n" + (@body.inspect * "\n")
        str
      end
      def to_s
        str = "implementation #{sig_string}"
        str << "\n" + (@body * "\n")
        str
      end
    end
  end
end