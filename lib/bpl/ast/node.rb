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
    module Binding; end
    module Scope; end

    class Token
      def initialize(line_number)
        @line = line_number
      end
    end

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
          case v
          when Node
            v.link(self)
          when Array
            v.each {|x| x.link(self) if x.is_a?(Node)}
          end
        end
      end

      def link(parent) @parent = parent end
      def unlink; @parent = nil end

      def show_attrs
        @attributes.map do |k,vs|
          vals = vs.map{|e| case e when String; "\"#{e}\"" else yield e end} * ", "
          "{:#{k}#{vals.empty? ? "" : " #{vals}"}}"
        end * " "
      end

      def hilite; show(&:hilite) end
      def to_s; show {|a| a} end

      def traverse(&block)
        return self unless block_given?
        block.call self, :pre
        self.class.children.each do |sym|
          case child = instance_variable_get("@#{sym}")
          when Node; child.traverse(&block)
          when Array
            ## NOTE duplication avoids visiting newly-added children
            child.dup.each {|n| n.traverse(&block) if n.is_a?(Node)}
          end
        end
        block.call self, :post
        self
      end

      def replace!(&block)
        return self unless block_given?
        self.class.children.each do |sym|
          case child = instance_variable_get("@#{sym}")
          when Node
            c = child.replace!(&block)
            if c && c.is_a?(Node)
              child.unlink
              c.link(self)
              instance_variable_set("@#{sym}",c)
            end

          when Array
            ary = []
            child.each do |elem|
              ary << case elem
              when Node
                new_elem = elem.replace!(&block)
                elem.unlink
                new_elem.link(self)
                new_elem
              else
                elem
              end
            end
            instance_variable_set("@#{sym}",ary)

          end
        end
        block.call self
      end

      def each(&block)
        traverse {|x,p| block.call x if p == :pre; x}
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

      def prepend_child(name,elem) insert_children(name,:first,elem) end
      def append_child(name,elem) insert_children(name,:last,elem) end

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
            self.unlink
            ary.insert(idx,*elems)
          end
          elems.each {|elem| elem.link(parent)}
        end if parent
        self
      end

      def insert_before(*elems) insert_siblings(:before,*elems) end
      def insert_after(*elems) insert_siblings(:after,*elems) end
      def replace_with(*elems) insert_siblings(:inplace,*elems) end
      def remove; insert_siblings(:inplace) end

    end

  end
end
