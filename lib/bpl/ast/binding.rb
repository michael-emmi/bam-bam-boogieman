module Bpl
  module AST

    class Node
      def unbound
        @unbound ||= (s = Set.new; s.add(self) if respond_to?(:bind); s)
      end
    end

    module Binding

      def self.notify(msg, *args)
        case msg
        when :link
          parent, child = *args

          # check the new declaration against the unbound descendants
          if child.is_a?(Declaration)
            fail "Expected parent scope" unless parent.respond_to?(:resolve)
            parent.unbound.dup.each do |ub|
              if res = parent.resolve(ub)
                ub.bind(res)
                ub.each_ancestor{|a| a.unbound.delete(ub)}
              end
            end
          end

          # propagate unbounds upwards, resolving when possible
          parent.each_ancestor do |anc|
            if anc.respond_to?(:resolve)
              child.unbound.dup.each do |ub|
                if res = anc.resolve(ub)
                  ub.bind(res)
                  ub.each_ancestor{|a| a.unbound.delete(ub)}
                end
              end
            end
            anc.unbound.merge(child.unbound)
          end unless child.unbound.empty?

        when :unlink
          parent, child = *args

          # TODO handle unlinking better
          child.each {|elem| elem.unbind if elem.respond_to?(:unbind)}
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
