module Bpl
  module Transformation
    class Selection < Bpl::Pass
      def self.description
        "Select declarations."
      end

      option :expression, "the selection pattern"
      depends :resolution

      def run! program
        program.declarations.each do |d|
          d.remove unless d.respond_to?(:name) && /#{@expression}/.match(d.name)
        end
      end

    end
  end
end
