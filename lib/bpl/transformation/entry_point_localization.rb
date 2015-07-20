module Bpl

  module AST
    class Declaration
      def is_entrypoint?
        is_a?(ProcedureDeclaration) && attributes.has_key?(:entrypoint)
      end
    end
  end

  module Transformation
    class EntryPointLocalization < Bpl::Pass
      def self.description
        "Locate & annotate program entry points."
      end

      def run! program
        locate_entrypoints! program
        sanity_check program
      end

      def is_default_entrypoint? name
        name =~ /\bmain\b/i
      end

      def locate_entrypoints! program
        eps = program.declarations.select(&:is_entrypoint?)

        if eps.empty?
          info "no entry points found; looking for the defaults..."
          eps = program.declarations.select do |d|
            d.is_a?(ProcedureDeclaration) && is_default_entrypoint?(d.name)
          end
          eps.each{|d| d.attributes[:entrypoint] = []}
          info "using entry point#{'s' if eps.count > 1}: #{eps.map(&:name) * ", "}" \
            unless eps.empty?
        end

        abort "no entry points found." if eps.empty?
      end

      def sanity_check program
        program.each do |elem|
          case elem
          when CallStatement
            abort "found call to entry point procedure #{elem.procedure}." \
              if elem.target && elem.target.is_entrypoint?
          end
        end
      end

    end
  end
end
