module Z3
  class Node
    def initialize(opts = {})
      opts.each do |k,v|
        send("#{k}=",v) if respond_to?("#{k}=")
      end
    end
  end

  class Constant < Node
    attr_accessor :name, :value
    def <=>(node)
      case node
      when Constant; @name <=> node.name
      when Function; 1
      else -1
      end
    end
    def to_s; "const #{@name} = #{@value}" end
    def eql?(c) c.is_a?(Constant) && c.name == @name end
    def hash; @name.hash end
  end
  
  class Variable < Node
    attr_accessor :name, :sequence_number, :value
    def <=>(node)
      case node
      when Variable; @name <=> node.name
      else 1
      end
    end
    def to_s
      "var #{@name}/#{@sequence_number} = #{@value}"
    end
  end
  
  class Function < Node
    attr_accessor :name, :values
    def []=(i,j) @values[i] = j end
    def [](i) @values[i] end
    def <=>(node)
      case node
      when Function; @name <=> node.name
      else -1
      end
    end
    def to_s
      "function #{@name} = {\n  #{@values.map do |ks,v|
        case ks
        when Array; "(#{ks * ","})"
        when nil; "else"
        else ks.to_s
        end + " -> #{v}"
      end * "\n  "}\n}"
    end
  end
  
  class MapValue < Node
    attr_accessor :values
    def initialize; @values = {} end
    def []=(i,j) @values[i] = j end
    def [](i) @values[i] end
    def to_s; "[#{@values.map{|k,v| "#{k}:#{v}"}.sort * ", "}]" end
  end

  class Value < Node
    attr_accessor :id
    def eql?(v) v.is_a?(Value) && v.id == @id end
    def hash; @id.hash end
    def name; "VAL?#{@id}" end
    def to_s; "#{name}" end
  end
  
  class Type < Value
    attr_accessor :id
    attr_accessor :name
    def eql?(t) t.is_a?(Type) && t.id == @id end
    def hash; @id.hash end
    def z3_name; "T@T!val!#{@id}" end
    def to_s; @name || z3_name end
  end

  class Label < Node
    attr_accessor :id, :value
    def name; "%lbl%+#{@id}" end
    def to_s; "#{name} = #{@value}" end
  end
  
  class Formal < Node
    attr_accessor :call_id, :parameter_name, :sequence_number, :value
    def name; "call#{@call_id}formal@#{@parameter_name}@#{@sequence_number}" end
    def to_s; "#{name} = #{@value}" end
  end

end
