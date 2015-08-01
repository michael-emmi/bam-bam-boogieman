module Bpl
  class Pass

    class << self
      def options
        @options || {}
      end
      def option(name, description)
        @options ||= {}
        @options[name] = description
        class_eval "attr_accessor :#{name}"
      end

      def depends(*passes)
        @depends ||= []
        @depends += passes
        @depends
      end

      def inherited(subclass)
        subclass.instance_variable_set("@options",@options)
        subclass.instance_variable_set("@depends",@depends)
      end
    end

    def self.description
      fail "#{self.class} must implement :description class method."
    end

    CUTOFF = 40

    def self.brief
      d = self.description.lines.first.strip
      d.length > CUTOFF ? d.slice(0,CUTOFF-3) + "..." : d
    end

    def self.help
      name = self.name.split('::').last.unclassify
      <<-eos

#{name.nounify}

#{description.indent}

Usage:
  --#{name.gsub('_','-')} #{options.empty? ? "" : "#{options.first.first}:_,..."}

#{options.empty? ? "This pass has no options." : "Options:"}
  #{options.map do |k,v| "\n  #{k}: #{v}\n" end * ""}
      eos
    end

    def initialize(opts = {})
      opts.each do |k,v|
        send("#{k}=",v) if respond_to?("#{k}=")
      end
    end

    def self.destructive?; name =~ /::Transformation::/ end
    def destructive?; self.class.destructive? end    

    def run! program
      fail "#{self.class} must implement :run instance method."
    end
  end
end
