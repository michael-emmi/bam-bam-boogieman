module Bpl
  class Transformation

    class << self
      def options(*args)
        @options ||= []
        @options += args
        args.each do |arg|
          class_eval "attr_accessor :#{arg}"
        end
        @options
      end
      def inherited(subclass)
        subclass.instance_variable_set("@options",@options)
      end
    end

    def self.description
      fail "#{self.class} must implement :description class method."
    end

    def initialize(opts = {})
      opts.each do |k,v|
        send("#{k}=",v) if respond_to?("#{k}=")
      end
    end

    def run! program
      fail "#{self.class} must implement :run instance method."
    end
  end
end
