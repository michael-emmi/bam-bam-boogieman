module Bpl
  module AST
    module Binding

      def self.notify(msg, *args)
        case msg
        when :link
          parent, child = *args
          child.each do |elem|
            if elem.respond_to?(:bind) && elem.declaration.nil?
              resolver = elem.each_ancestor.find do |scope|
                scope.respond_to?(:resolve) && scope.resolve(elem)
              end
              elem.bind(resolver.resolve(elem)) if resolver
            end
          end

        when :unlink
          parent, child = *args
          child.each do |elem|
            elem.unbind if elem.respond_to?(:unbind)
          end
        end
      end
      Node.observers << self

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
