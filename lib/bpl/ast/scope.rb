module Bpl
  module AST
    module Scope

      KIND = {
        CustomType => :type,
        TypeDeclaration => :type,
        LabelIdentifier => :label,
        Block => :label,
        StorageIdentifier => :storage,
        StorageDeclaration => :storage,
        ConstantDeclaration => :storage,
        VariableDeclaration => :storage,
        FunctionIdentifier => :function,
        FunctionDeclaration => :function,
        ProcedureIdentifier => :procedure,
        ProcedureDeclaration => :procedure,
        ImplementationDeclaration => :procedure
      }

      def self.notify(msg, *args)
        case msg
        when :link
          parent, child = args
          if child.is_a?(Declaration)
            child.names.each do |name|
              parent.lookup_table(KIND[child.class])[name] = child
            end
          end

        when :unlink
          parent, child = args
          if child.is_a?(Declaration)
            child.names.each do |name|
              parent.lookup_table(KIND[child.class]).delete(name)
            end
          end
        end
      end

      Node.observers << self

      def lookup_table(kind)
        @lookup_table ||= {}
        @lookup_table[kind] ||= {}
      end

      def resolve(id)
        lookup_table(KIND[id.class])[id.name]
      end

    end
  end
end
