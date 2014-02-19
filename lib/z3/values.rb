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
    def to_s; "const #{@name} = #{@value}" end
    def eql?(c) c.is_a?(Constant) && c.name == @name end
    def hash; @name.hash end
  end
  
  class Variable < Node
    attr_accessor :name, :sequence_number, :value
    def to_s
      "var #{@name}/#{@sequence_number} = #{@value}"
    end
  end
  
  class Function < Node
    attr_accessor :name, :values
    def []=(i,j) @values[i] = j end
    def [](i) @values[i] end
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
    attr_accessor :name, :type
    def eql?(v) v.is_a?(Value) && v.id == @id end
    def hash; @id.hash end
    def z3_name; "T@U!val!#{@id}" end
    def to_s; "#{@name || z3_name}" end
    # def to_s; "#{@name || z3_name}#{@type ? " : #{@type}" : ""}" end
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

    def lookup_primitive_value(value)
      return if value.nil?
      if !@entries[@@u2b][value].nil?
        @entries[@@u2b][value]
      elsif !@entries[@@u2i][value].nil?
        @entries[@@u2i][value]
      else
        value
      end
    end
    
    def lookup_map_value(value)
      return if value.nil?
      @map_table[value] || value
    end
    
    def blacklisted(name)
      @@blacklist.any? do |pattern|
        pattern === name
      end
    end

    # def lookup_type(v) @mappings[@@type] && @mappings[@@type][v] end
    
    def resolve_primitive_values!
      @entries.reject{|name| blacklisted name}.each do |f,entry|
        case entry
        when Function
          entry.values = entry.values.map do |keys,val|
            keys = case keys
              when Array; keys.map do |key| lookup_primitive_value(key) end
              else lookup_primitive_value(keys)
            end
            val = lookup_primitive_value(val)
            [keys,val]
          end.to_h
        else
          entry.value = lookup_primitive_value(entry.value)
        end
      end
    end
    
    def resolve_map_values!
      puts "RESOLVING..."
      @something_resolved = false

      @entries.reject{|name| blacklisted(name) || name =~ /Map\/\d/}.each do |f,entry|
        case entry
        when Function
          entry.values = entry.values.map do |keys,val|
            keys = case keys
            when Array; keys.map do |key| 
              v = lookup_map_value(key)
              @something_resolved = true unless v.eql?(key)
              v
            end
            else
              v = lookup_map_value(keys)
              @something_resolved = true unless v.eql?(keys)
              v
            end
            v = lookup_map_value(val)
            @something_resolved = true unless v.eql?(val)
            [keys,v]
          end.to_h
        else
          v = lookup_map_value(entry.value)
          @something_resolved = true unless v.eql?(entry.value)
          entry.value = v
        end
      end
      puts "SOMETHIGN RESOLVED" if @something_resolved
      @something_resolved
    end
    
    def collect_map_values!
      @map_table = {}
      @entries[@@map2].values.each do |keys,val|
        next unless keys
        @map_table[keys[0]] ||= MapValue.new
        @map_table[keys[0]][keys[1]] = val
      end
    end

    def resolve!      
      resolve_primitive_values!
      collect_map_values!
      begin
        fresh = resolve_map_values!
      end while fresh
    end
    def to_s; @entries.reject{|name| blacklisted name}.map{|_,v| v} * "\n" end
  end
end
