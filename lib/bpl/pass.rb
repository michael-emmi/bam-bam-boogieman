module Bpl
  class Pass

    class << self
      def flag(*args, &blk)
        flags << {args: args, blk: blk}
      end

      def flags
        @flags ||= []
        @flags
      end

      def option(k,v=nil)
        define_method(k) do
          instance_variable_get("@#{k}")
        end
        options[k] = v
      end

      def options
        @options ||= {}
      end

      def depends(*passes)
        @depends ||= []
        @depends += passes
        passes.each do |p|
          define_method(p) { instance_variable_get("@#{p}") }
        end
        @depends
      end

      def result(key, init)
        define_method(key) do
          v = instance_variable_get("@#{key}")
          instance_variable_set("@#{key}", init) unless v
          instance_variable_get("@#{key}")
        end
      end

      def inherited(subclass)
        subclass.instance_variable_set("@flags",@flags)
        subclass.instance_variable_set("@depends",@depends)
      end
    end

    def initialize(opts = {})
      opts.merge(self.class.options).each do |k,v|
        instance_variable_set("@#{k}",v) if respond_to?(k)
      end
    end

    def self.destructive?; name =~ /::Transformation::/ end
    def destructive?; self.class.destructive? end

    def run! program
      fail "#{self.class} must implement :run instance method."
    end
  end
end
