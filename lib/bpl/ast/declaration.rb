require_relative 'node'

module Bpl
  module AST

    class Declaration < Node
      def names; respond_to?(:name) && [name] || [] end
      def bindings; @bindings ||= Set.new end
      def unlink; super; bindings.each(&:unbind) end
    end

    class TypeDeclaration < Declaration
      children :name, :arguments
      children :finite, :type
      def signature; "type #{yield @name}" end
      def show(&blk)
        args = @arguments.map{|a| yield a} * " "
        "#{yield :type} #{show_attrs(&blk)} #{yield :finite if @finite} #{yield @name} #{args} #{@type ? " = #{yield @type}" : ""};".fmt
      end
    end

    class FunctionDeclaration < Declaration
      include Scope
      def declarations; @arguments end

      children :name, :type_arguments, :arguments, :return, :body
      def signature
        args = @arguments.map(&:flatten).flatten.map{|x|x.type} * ","
        "#{@name}(#{args}): #{@return.type}".gsub(/\s/,'')
      end
      def show(&blk)
        args = @arguments.map{|a| yield a} * ", "
        ret = yield @return
        body = @body ? " { #{yield @body} }" : ";"
        "#{yield :function} #{show_attrs(&blk)} #{yield @name}(#{args}) #{yield :returns} (#{ret})#{body}".fmt
      end
    end

    class AxiomDeclaration < Declaration
      children :expression
      def show(&blk)
        "#{yield :axiom} #{show_attrs(&blk)} #{yield @expression};".fmt
      end
    end

    class StorageDeclaration < Declaration
      children :names, :type, :where
      def signature; "#{@names * ", "}: #{@type}" end
      def show(&blk)
        names = @names.empty? ? "" : (@names.map(&blk) * ", " + ":")
        where = @where ? "#{yield :where} #{@where}" : ""
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

    class VariableDeclaration < StorageDeclaration
      def signature; "var #{@names * ", "}: #{@type}" end
      def show; "#{yield :var} #{super};" end
    end

    class ConstantDeclaration < StorageDeclaration
      children :unique, :order_spec
      def signature; "const #{@names * ", "}: #{@type}" end
      def show(&blk)
        names = @names.empty? ? "" : (@names.map(&blk) * ", " + ":")
        ord = ""
        if @order_spec && @order_spec[0]
          ord << ' <: '
          unless @order_spec[0].empty?
            ord << @order_spec[0].map{|c,p| (c ? 'unique ' : '') + p.to_s } * ", "
          end
        end
        ord << ' complete' if @order_spec && @order_spec[1]
        "#{yield :const} #{show_attrs(&blk)} #{'unique' if @unique} #{names} #{yield @type}#{ord};".fmt
      end
    end

    class ProcedureDeclaration < Declaration
      include Scope
      def declarations; parameters + returns end
      def callers; @callers ||= Set.new end

      children :name, :type_arguments, :parameters, :returns
      children :specifications, :body

      def is_entrypoint?
        has_attribute? :entrypoint
      end

      def modifies
        specifications.map{|s| s.is_a?(ModifiesClause) ? s.identifiers : []}.flatten
      end
      def fresh_var(prefix="",type)
        taken = @parameters.map{|x| x.names}.flatten + @returns.map{|x| x.names}.flatten
        @body && @body.fresh_var(prefix,type,taken)
      end
      def fresh_label(prefix="$label") @body && @body.fresh_label(prefix) end
      def sig(&blk)
        params = @parameters.map{|a| yield a} * ", "
        rets = @returns.empty? ? "" : "#{yield :returns} (#{@returns.map{|a| yield a} * ", "})"
        "#{show_attrs(&blk)} #{yield @name}(#{params}) #{rets}".fmt
      end
      def signature
        "#{@name}(#{@parameters.map(&:type) * ","})" +
        (@returns.empty? ? "" : ":#{@returns.map(&:type) * ","}")
      end
      def show(&block)
        specs = @specifications.map{|s| yield s} * "\n"
        specs = "\n" + specs unless specs.empty?
        if @body
          "#{yield :procedure} #{sig(&block)}#{specs}\n#{yield @body}"
        else
          "#{yield :procedure} #{sig(&block)};#{specs}"
        end
      end
    end

    class ImplementationDeclaration < ProcedureDeclaration
      include Binding
      def show(&block)
        "#{yield :implementation} #{sig(&block)}\n#{yield @body}"
      end
    end
  end
end
