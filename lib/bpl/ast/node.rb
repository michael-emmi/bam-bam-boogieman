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
        opts.each do |k,v|
          send("#{k}=",v) if respond_to?("#{k}=")
        end
      end

      def print_attrs
        return "" unless @attributes
        @attributes.map do |k,vs|
          vals = vs.map{|e| case e when String; "\"#{e}\"" else yield e end} * ", "
          "{:#{k}#{vals.empty? ? "" : " #{vals}"}}"
        end * " "
      end
  
      def inspect; print &:inspect end
      def to_s; print {|a| a} end
  
      def traverse(&block)
        return self unless block_given?
        block.call self, :pre
        self.class.children.each do |sym|
          var = "@#{sym}"
          child = instance_variable_get(var)
          case child
          when Node
            c = child.traverse(&block)
            instance_variable_set(var,c) if c && c.is_a?(Node)
          when Array
            cs = child.reduce([]) do |cs,c|
              cc = c.is_a?(Node) ? c.traverse(&block) : c
              cs + case cc
              when nil; []
              when Array; cc
              when Node; [cc]
              when c.class; [cc]
              else
                puts "FOUND SOMEHTING CRAZY -- #{cc} -- FROM -- #{c}"
                []
              end
            end
            instance_variable_set(var,cs)
          end
        end
        block.call self, :post
      end  
  
      def each(&block)
        traverse {|x,p| block.call x if p == :pre; x}
      end
      
      def replace(&block)
        traverse {|x,p| if p == :post then block.call x else x end}
      end
    end
  end
end