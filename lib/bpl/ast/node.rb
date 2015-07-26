class String
  def fmt
    self.split.join(' ').gsub(/\s*;/, ';')
  end
  def hilite
    underline
  end
end

class Symbol
  def hilite
    to_s.bold
  end
end

module Bpl
  module AST
    module Scope; end
    module Binding; end

    class Node
      include Enumerable

      class << self
        def children(*args)
          @children ||= []
          @children += args
          args.each do |arg|
            define_method(arg) do
              x = instance_variable_get("@#{arg}")
              case x when Array then x.dup.freeze else x end
            end
          end
          @children
        end
        def inherited(subclass)
          subclass.instance_variable_set("@children",@children)
        end
      end

      children :attributes
      attr_reader :parent
      attr_reader :token

      def initialize(opts = {})
        @attributes = {}
        @parent = nil
        @token = nil
        opts.each do |k,v|
          instance_variable_set("@#{k}",v) if respond_to?(k)
        end
        opts.each do |k,v|
          case v
          when Node
            v.link(self)
          when Array
            v.each {|x| x.link(self) if x.is_a?(Node)}
          end
        end
      end

      def link(parent)
        @parent = parent
        each do |elem|
          if elem.respond_to?(:bind) && elem.declaration.nil?
            resolver = each_ancestor.find do |scope|
              scope.respond_to?(:resolve) && scope.resolve(elem)
            end
            elem.bind(resolver.resolve(elem)) if resolver
          end
        end
      end

      def unlink
        @parent = nil
        each do |elem|
          elem.unbind if elem.respond_to?(:unbind)
        end
      end

      def show_attrs
        @attributes.map do |k,vs|
          vals = vs.map{|e| case e when String; "\"#{e}\"" else yield e end} * ", "
          "{:#{k}#{vals.empty? ? "" : " #{vals}"}}"
        end * " "
      end

      REFERENCES = [:@parent, :@declaration]
      def inspect
        if REFERENCES.any?{|v| instance_variable_get(v).is_a?(Node)}
          node = clone
          REFERENCES.each do |v|
            n = node.instance_variable_get(v)
            node.instance_variable_set(v,n.class) if n
          end
          node.inspect
        else
          return super
        end
      end

      def hilite; show(&:hilite) end
      def to_s; show {|a| a} end

      def each(&block)
        enumerator = Enumerator.new {|y| enumerate(y)}
        if block_given?
          enumerator.each(&block)
        else
          enumerator
        end
      end

      def each_child(&block)
        enumerator = Enumerator.new {|y| enumerate_children(y)}
        if block_given?
          enumerator.each(&block)
        else
          enumerator
        end
      end

      def each_ancestor(&block)
        enumerator = Enumerator.new {|y| enumerate_ancestors(y)}
        if block_given?
          enumerator.each(&block)
        else
          enumerator
        end
      end

      def prepend_child(name,elem) insert_children(name,:first,elem) end
      def append_child(name,elem) insert_children(name,:last,elem) end

      def insert_before(*elems) insert_siblings(:before,*elems) end
      def insert_after(*elems) insert_siblings(:after,*elems) end
      def replace_with(*elems) insert_siblings(:inplace,*elems) end
      def remove; insert_siblings(:inplace) end

      # the following could be private

      def enumerate(yielder)
        yielder.yield(self)
        self.class.children.each do |sym|
          case node = instance_variable_get("@#{sym}")
          when Node
            node.enumerate(yielder)
          when Array
            node.dup.each {|n| n.enumerate(yielder) if n.is_a?(Node)}
          end
        end
      end

      def enumerate_children(yielder)
        self.class.children.each do |sym|
          case node = instance_variable_get("@#{sym}")
          when Node
            yielder.yield(node)
          when Array
            node.dup.each {|n| yielder.yield(n) if n.is_a?(Node)}
          end
        end
      end

      def enumerate_ancestors(yielder)
        yielder.yield(self)
        parent.enumerate_ancestors(yielder) if parent
      end

      def insert_children(name,where,*elems)
        var = instance_variable_get("@#{name}")
        if var && var.is_a?(Array)
          case where
          when :first
            var.unshift(*elems)
          else
            var.push(*elems)
          end
          elems.each {|elem| elem.link(self) if elem.respond_to?(:link)}
        end
      end

      def insert_siblings(where,*elems)
        parent.class.children.each do |sym|
          ary = parent.instance_variable_get("@#{sym}")
          next unless ary.is_a?(Array)
          next unless idx = ary.index(self)
          case where
          when :before
            ary.insert(idx,*elems)
          when :after
            ary.insert(idx+1,*elems)
          when :inplace
            ary.delete_at(idx)
            ary.insert(idx,*elems)
          end
          elems.each {|elem| elem.link(parent)}
          self.unlink if where == :inplace
        end if parent
        self
      end

    end

  end
end
