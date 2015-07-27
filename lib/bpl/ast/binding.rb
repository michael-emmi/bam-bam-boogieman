module Bpl
  module AST
    module Binding
      def declaration
        @declaration ||= nil
      end
      def bind(decl)
        @declaration = decl
        decl.bindings << self unless decl.nil?
        decl
      end
      def unbind
        return unless @declaration
        @declaration.bindings.delete(self)
        @declaration = nil
      end
    end
  end
end
