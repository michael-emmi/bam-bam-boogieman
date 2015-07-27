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
      def match?(id,decl)
        decl.is_a?(MATCH[id.class]) &&
        (decl.respond_to?(:names) && decl.names.include?(id.name)) ||
        (decl.respond_to?(:name) && decl.name == id.name)
      end
      def resolve(id)
        declarations.find{|d| match?(id,d)}
      end
    end
  end
end
