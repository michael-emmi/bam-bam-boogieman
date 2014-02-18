module Traversable
  
  def self.included(base)
    base.extend(ClassMethods)
  end
  
  module ClassMethods
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
  
  def initialize(opts = {})
    opts.each do |k,v|
      send("#{k}=",v) if respond_to?("#{k}=")
    end
  end
  
  def traverse(&block)
    return self unless block_given?
    block.call self, :pre
    self.class.children.each do |sym|
      var = "@#{sym}"
      child = instance_variable_get(var)
      case child
      when Traversable
        c = child.traverse(&block)
        instance_variable_set(var,c) if c && c.is_a?(child.class)        
      when Array
        cs = child.reduce([]) do |cs,c|
          cc = c.is_a?(Traversable) ? c.traverse(&block) : c
          cs + case cc
          when c.class; [cc]
          when Array; cc
          else []
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