# macro_plugin.rb

# Sorbet calls this plugin with command line arguments similar to the following:
# ruby --class Metaprogramming --method macro --source macro(:bed)
# we only care about the source here, so we use ARGV[5]
source = ARGV[5]
/children (:\w+(,\s*:\w+)*)/.match(source) do |match_data|
  match_data[1].split(",").each do |elem|
    name = elem.sub(/:/, '').strip
    decl = "def #{name}; end"
    puts decl
  end
end

# Note that Sorbet treats plugin output as rbi files
