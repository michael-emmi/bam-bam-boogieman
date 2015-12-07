module Bpl
  module Transformation
    class Selection < Bpl::Pass

      depends :resolution
      option :pattern

      flag "--selection PATTERN", "Select decls matching PATTERN." do |p|
        option :pattern, p
      end

      def run! program
        program.declarations.each do |d|
          d.remove unless d.respond_to?(:name) && /#{pattern}/.match(d.name)
        end
        true
      end

    end
  end
end
