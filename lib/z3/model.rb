require_relative 'model_parser.tab'

module Z3
  class Model

    @@u2b = 'U_2_bool'.to_sym
    @@u2i = 'U_2_int'.to_sym
    @@map_maps = ['[2]','Select_[$int]$bool', 'Select_[$int]$int'].map(&:to_sym)
    
    @@blacklist = Regexp.union *[
      'type',
      /(int|bool)Type/,
      /MapType\d+Type/, /MapType\d+TypeInv\d+/,
      /(U|int|bool)_2_(U|int|bool)/,
      'tickleBool',
      'Ctor',
      '[2]', '[3:=]',
      'Select_[$int]$int',
      'Select_[$int]$bool',
      'Store_[$int]$int',
      'Store_[$int]$bool',
      /inline\$/,
      /call\d+formal/,
      /%lbl%/,
      /unique-value!\d+/,
      /distinct-aux-/,
      /si_control_var/,
      /k!\d+/
    ]

    attr_accessor :entries
    attr_accessor :map_table
    
    def initialize(file)
      lines = File.read(file).lines
      start = lines.rindex{|l| l =~ /\*\*\* MODEL/}
      @entries = ModelParser.new.parse(lines.drop(start || 0).join)
      collect_map_values!
      resolve!
    end

    def to_s
      @entries.select{|sym,_| visible(sym)}.map do |sym,val|
        "#{sym} = #{val}"
      end.sort * "\n"
    end

    def visible(sym) sym !~ @@blacklist end
    def ident_pattern; /[a-zA-Z_.$\#'`~^\\?][\w.$\#'`~^\\?]*/ end
    def variable_pattern(idx = nil); /^(#{ident_pattern})@#{idx || /[0-9]+/}$/ end

    def variables(idx = nil)
      @entries.select do |sym,_|
        visible(sym) && sym =~ variable_pattern(idx)
      end.map do |sym,val|
        idx ? [variable_pattern.match(sym){|m| m[1]}, val] : [sym,val]
      end.to_h
    end
    def constants
      @entries.select do |sym,val|
        visible(sym) && sym !~ variable_pattern &&
        (!val.is_a?(Hash) || val.include?(:map))
      end
    end
    def functions
      @entries.select do |sym,val|
        visible(sym) && sym !~ variable_pattern &&
        val.is_a?(Hash) && !val.include?(:map)
      end
    end

    def collect_map_values!
      @map_table = {}

      @@map_maps.each do |mm|
        @entries[mm].each do |keys,val|
          next unless keys
          keys = keys.map{|key| lookup key, false}
          @map_table[keys[0]] ||= {map: true}
          @map_table[keys[0]][keys[1]] = lookup(val, false)
        end if @entries.include? mm
      end

      @entries.select{|k,_| k =~ /^k!\d+$/}.each do |k,vs|
        next unless vs.is_a?(Hash)
        k = lookup(k,false)
        @map_table[k] = {map: true}
        vs.each do |v,vv|
          @map_table[k][v] = lookup(vv,false)
        end
      end
    end

    def resolve!
      @entries.each do |symbol,value|
        @entries[symbol] = resolve(value)
      end
    end

    def resolve value
      case value
      when Array; value.map{|v| resolve(v)}
      when Hash; value.map{|k,v| [resolve(k), resolve(v)]}.to_h
      else
        new_value = lookup(value)
        new_value.is_a?(Hash) ? resolve(new_value) : new_value
      end
    end

    def lookup(value, use_map_table = true)
      result = @entries[@@u2b] && @entries[@@u2b][value]
      return result unless result.nil? # result could be false!

      return @entries[@@u2i] && @entries[@@u2i][value] ||
      use_map_table && @map_table[value] ||
      use_map_table && value.to_s =~ /as-array/ &&
      @map_table[value.to_s.match(/as-array\[(k!\d+)\]/){|m| m[1].to_sym}] ||
      value unless value.nil?
    end

  end
end
