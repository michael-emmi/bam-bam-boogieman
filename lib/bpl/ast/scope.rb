module Bpl
  module AST
    module Scope

      MATCH = {
        CustomType => TypeDeclaration,
        LabelIdentifier => Block,
        StorageIdentifier => StorageDeclaration,
        FunctionIdentifier => FunctionDeclaration,
        ProcedureIdentifier => ProcedureDeclaration,
        ImplementationDeclaration => ProcedureDeclaration
      }

      def self.notify(msg, *args)
        case msg
        when :link
          parent, child = args
          if parent.respond_to?(:resolve) && child.is_a?(Declaration)
            child.names.each do |name|
              parent.lookup_table[name] = child
            end
          end

        when :unlink
          parent, child = args
          if parent.respond_to?(:resolve) && child.is_a?(Declaration)
            child.names.each do |name|
              parent.lookup_table[name] = nil
            end
          end
        end
      end
      Node.observers << self

      def lookup_table
        @lookup_table ||= {}
      end

      def match?(id,decl)
        decl.is_a?(MATCH[id.class]) &&
        (decl.respond_to?(:names) && decl.names.include?(id.name)) ||
        (decl.respond_to?(:name) && decl.name == id.name)
      end

      def resolve(id)
        decl = lookup_table[id.name]
        decl if decl && match?(id,decl)
      end

    end
  end
end
