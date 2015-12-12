module Bpl
  class Selection < Pass

    option :pattern

    switch "--selection PATTERN", "Select decls matching PATTERN." do |y, p|
      y.yield :pattern, p
    end

    invalidates :all

    def run! program
      program.declarations.each do |d|
        names = d.names
        if names.empty?
          names = d.map {|id| id.name if id.is_a?(Identifier)}.compact
        end
        if names.any? {|n| n.match(/#{pattern}/)}
          if d.instance_variable_defined? "@names"
            d.instance_variable_set "@names",
              d.names.select{|n| n.match(/#{pattern}/)}
          end
        else
          d.remove
        end
      end

    end

  end
end
