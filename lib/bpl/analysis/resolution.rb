module Bpl
  module Analysis
    class Resolution < Bpl::Pass
      def self.description
        "Resolve program identifiers and types."
      end

      def run! program
        program.each do |elem|
          next unless elem.respond_to?(:declaration) && elem.declaration.nil?
          kind = case elem
            when Identifier then "identifier"
            when CustomType then "type"
            when ImplementationDeclaration then "implementation"
          end
          warn ("could not resolve #{kind} #{elem.name}")
        end
      end
    end
  end
end
