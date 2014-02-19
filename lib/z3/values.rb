module Z3
  class Node
    def initialize(opts = {})
      opts.each do |k,v|
        send("#{k}=",v) if respond_to?("#{k}=")
      end
    end
  end

  class Constant < Node
    attr_accessor :name
    def to_s; @name end
  end
  
  class Variable < Node
    attr_accessor :name, :sequence_number
    def to_s
      "#{@name}@#{@sequence_number}"
    end
  end
  
  class Function < Node
    attr_accessor :mappings
    def []=(i,j) @mappings[i] = j end
    def to_s
      "{\n  #{@mappings.map do |ks,v|
        (ks ? "(#{ks * ","})" : "else") + " -> #{v}"
      end * "\n  "}\n}"
    end
  end

  class Value < Node
    attr_accessor :id
    attr_accessor :name
    def to_s; @name || "T@U!val!#{@id}" end
  end
  
  class Type < Value
    attr_accessor :id
    attr_accessor :name
    def to_s; @name || "T@T!val!#{@id}" end
  end

  class Label < Node
    attr_accessor :id
    def to_s; "%lbl%+#{@id}" end
  end
  
  class Formal < Node
    attr_accessor :call_id, :parameter_name, :sequence_number
    def to_s; "call#{@call_id}formal@#{@parameter_name}@#{@sequence_number}" end
  end
end