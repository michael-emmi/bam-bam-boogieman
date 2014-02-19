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

  class Model
    
    @@type = 'type'
    @@u2b = 'U_2_bool'
    @@u2i = 'U_2_int'
    @@map2 = 'Map/2'
    @@map3 = 'Map/3'
    @@maptype = 'MapType0Type'
    
    @@blacklist = [
      'type', 'U_2_bool', 'U_2_int', 'bool_2_U', 'int_2_U', 'tickleBool',
      'Ctor',
      /Map\/\d/,
      /MapType\d+Type/, /MapType\d+TypeInv\d+/,
      /inline\$/,
      /call\d+formal/,
      /%lbl%/
    ]

    attr_accessor :entries
    attr_accessor :map_table

    def initialize; @entries = {} end
    def <<(entry) @entries[entry.name] = entry if entry end    
    def []=(i,j) @entries[i] = j end
    def [](i) @entries[i] end

    def lookup_value(value, use_map_table = true)
      return value if value.nil?
      return @entries[@@u2b][value] unless @entries[@@u2b][value].nil?
      return @entries[@@u2i][value] unless @entries[@@u2i][value].nil?
      return @map_table[value] unless !use_map_table || @map_table[value].nil?
      return value
    end
    
    def blacklisted(name)
      @@blacklist.any? do |pattern|
        pattern === name
      end
    end

    # def lookup_type(v) @mappings[@@type] && @mappings[@@type][v] end
    
    def resolve_value(value)
      new_value = lookup_value value
      case new_value
      when MapValue
        new_value.values = new_value.values.map{|k,v| [resolve_value(k), resolve_value(v)]}.to_h
        new_value
      else
        new_value
      end
    end
    
    def resolve_values!
      @entries.reject{|name| blacklisted(name) || name =~ /Map\/\d/}.each do |_,entry|
        case entry
        when Function
          entry.values = entry.values.map do |keys,val|
            keys = case keys
            when Array; keys.map{|key| resolve_value(key)}
            else resolve_value(keys)
            end
            [keys, resolve_value(val)]
          end.to_h
        else
          entry.value = resolve_value(entry.value)
        end
      end
    end    
    
    def collect_map_values!
      @map_table = {}
      @entries[@@map2].values.each do |keys,val|
        next unless keys
        keys = keys.map{|key| lookup_value key, false}
        val = lookup_value val, false
        @map_table[keys[0]] ||= MapValue.new
        @map_table[keys[0]][keys[1]] = val
      end
    end

    def resolve!
      collect_map_values!
      resolve_values!
    end
    def to_s; @entries.reject{|k,_| blacklisted k}.map{|_,v| v}.sort * "\n" end
  end
end
