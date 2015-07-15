module Bpl
  module Analysis
    class Selection < Bpl::Transformation
      def self.description
        "Select declarations."
      end

      options :expression

      def run! program
        program.declarations.select! do |d|
          d.respond_to?(:name) && /#{@expression}/.match(d.name)
        end
      end

    end
  end
end
