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

      def invalidates(*passes)
        @invalidates ||= Set.new
        @invalidates.merge(passes)
      end

      def no_cache; @no_cache ||= true end
      def no_cache?; @no_cache ||= false end

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

    def invalidates(*passes)
      @invalidates ||= Set.new
      self.class.invalidates + @invalidates.merge(passes)
    end

    def redo!; @redo ||= true end
    def redo?; @redo ||= false end

    def no_cache?; self.class.no_cache? end

    def removed(*programs)
      @removed ||= []
      @removed += programs
    end

    def added(*programs)
      @added ||= []
      @added += programs
    end

    def run! program
      fail "#{self.class} must implement :run instance method."
    end
  end
end
