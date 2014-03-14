require_relative 'model_parser.tab'

module Z3
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
    
    def initialize(file)
      @entries = {}
      ModelParser.new.parse(File.read(file)).each do |entry|
        @entries[entry.name] = entry if entry
      end
      resolve!
    end
    
    def []=(i,j) @entries[i] = j end
    def [](i) @entries[i] end
      
    def visible_entries
      @entries.select do |name,_|
        !blacklisted(name) && name !~ /\b[A-Za-z]+Type\b/
      end
    end
      
    def constants
      visible_entries.map{|_,v| v}.select{|v| v.is_a?(Constant)}
    end
    def functions
      visible_entries.map{|_,v| v}.select{|v| v.is_a?(Function)}
    end
    def variables(step = nil)
      visible_entries.map{|_,v| v}.select do |v|
        v.is_a?(Variable) && (step.nil? || v.sequence_number == step)
      end
    end

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
      end if @entries.include? @@map2
    end

    def resolve!
      collect_map_values!
      resolve_values!
    end
    def to_s; @entries.reject{|k,_| blacklisted k}.map{|_,v| v}.sort * "\n" end
  end
end