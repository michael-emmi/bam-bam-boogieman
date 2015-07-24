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

    class Node
      def resolve!
        each do |elem|
          elem.resolve_self! if elem.respond_to?(:resolve_self!)
        end
        self
      end
      def find_binding(elem,scope=self)
        scope.respond_to?(:resolve) && scope.resolve(elem) ||
        scope.parent && find_binding(elem,scope.parent)
      end
    end

    class Identifier
      def resolve_self!
        bind(find_binding(self)) ||
        warn("Could not resolve identifier #{self}")
      end
    end

    class CustomType
      def resolve_self!
        bind(find_binding(self)) ||
        warn("could not resolve type #{self}")
      end
    end
  end

  class ImplementationDeclaration
    def resolve_self!
      bind(find_binding(self)) ||
      warn("could not resolve implementation #{name}")
    end
  end

  # class CallStatement
  #   def resolve!
  #     ss = scope.find {|s| s.is_a?(ProcedureDeclaration)}
  #     if ss && procedure.declaration
  #       procedure.declaration.callers << ss
  #     end
  #   end
  # end

  # class GotoStatement
  #   def resolve!(scope)
  #     if ss = scope.find {|s| s.is_a?(Block)}
  #       identifiers.each do |id|
  #         if id.declaration
  #           id.declaration.predecessors << ss
  #         end
  #       end
  #     end
  #   end
  # end

  module Analysis
    class Resolution < Bpl::Pass
      def self.description
        "Resolve program identifiers and types."
      end

      def run! program
        program.resolve!
      end
    end
  end
end
