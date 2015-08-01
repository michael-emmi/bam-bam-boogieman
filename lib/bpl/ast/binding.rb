module Bpl
  module AST
    module Binding

      def declaration
        @declaration ||= nil
      end

      def bind(decl)
        unbind if @declaration != decl
        @declaration = decl
        decl.bindings << self unless decl.nil?
        decl
      end

      def unbind
        return unless @declaration
        @declaration.bindings.delete(self)
        @declaration = nil
      end

      def self.notify(msg,*args)
        case msg
        when :unlink
          _, child = args
          child.each do |node|
            node.unbind if node.respond_to?(:unbind)
          end
        end
      end

      Node.observers << self

    end
  end
end
