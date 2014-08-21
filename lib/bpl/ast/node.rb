class String
  def fmt
    self.split.join(' ').gsub(/\s*;/, ';')
  end
end

module Bpl
  module AST
    class Node
      include Enumerable
  
      class << self
        def children(*args)
          @children ||= []
          @children += args
          args.each do |arg|
            class_eval "attr_accessor :#{arg}"
          end
          @children
        end
        def inherited(subclass)
          subclass.instance_variable_set("@children",@children)
        end
      end
  
      children :attributes
      attr_accessor :parent
  
      def initialize(opts = {})
        @attributes = {}
        opts.each do |k,v|
          send("#{k}=",v) if respond_to?("#{k}=")
        end
      end

      def show_attrs
        @attributes.map do |k,vs|
          vals = vs.map{|e| case e when String; "\"#{e}\"" else yield e end} * ", "
          "{:#{k}#{vals.empty? ? "" : " #{vals}"}}"
        end * " "
      end

      def inspect; show &:inspect end
      def to_s; show {|a| a} end

      def +(n) [self] + case n when Array; n else [n] end end

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
            instance_variable_set("@#{sym}",c) if c && c.is_a?(Node)

          when Array
            instance_variable_set("@#{sym}", child.reduce([]) do |cs,c|
              cs + case cc = c.is_a?(Node) ? c.replace!(&block) : c
              when Array; cc
              when Node, c.class; [cc]
              else []
              end
            end)
          end
        end
        block.call self
      end

      def each(&block)
        traverse {|x,p| block.call x if p == :pre; x}
      end

    end

    module RelationalContainer
      module ClassMethods
        attr_accessor :container_array, :parent_field
        attr_accessor :add_methods, :remove_methods

        def container_relation(arr, parent)
          @container_array = arr
          @parent_field = parent
        end

        def add_methods(*args)
          @add_methods ||= []
          @add_methods += args
        end

        def remove_methods(*args)
          @remove_methods ||= []
          @remove_methods += args
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def method_missing(method, *elems, &block)
        arr = instance_variable_get(self.class.container_array) if self.class.container_array
        par = self.class.parent_field
        if arr && par && self.class.add_methods.include?(method) then
          elems.each do |elem|

            next unless elem.is_a?(Node)

            # Set the @parent_field
            elem.instance_variable_set(par, self)

            ## Have the element deleted from the @container_array whenever the
            ## @parent_field is reassigned.
            # (class << elem; self end).send(:define_method, "#{par}=".to_sym) do |p|
            #   instance_variable_set(par,p)
            #   arr.delete(self)
            # end
          end
          arr.send(method,*elems,&block)

        elsif arr && par && self.class.remove_methods.include?(method) then
          elem = arr.send(method,*elems,&block)

          # Unlink the element's @parent_field
          if elem && elem.instance_variable_get(par) == self
            elem.instance_variable_set(par, nil)
          end

          elem

        else super
        end
      end

      def respond_to?(method)
        return true if self.class.add_methods.include?(method)
        return true if self.class.remove_methods.include?(method)
        super
      end
    end

  end
end
