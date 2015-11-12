module Bpl

  module AST
    class Declaration
      def entrypoint?
        is_a?(ProcedureDeclaration) && has_attribute?(:entrypoint)
      end
    end
  end

  module Analysis
    class EntryPointLocalization < Bpl::Pass
      def self.description
        "Locate & annotate program entry points."
      end

      def default_entrypoint? name
        name =~ /\bmain\b/i
      end

      def run! program
        eps = program.declarations.select(&:entrypoint?)

        if eps.empty?
          info "no entry points found; looking for the defaults..."
          eps = program.declarations.select do |d|
            d.is_a?(ProcedureDeclaration) && default_entrypoint?(d.name)
          end
          eps.each{|d| d.add_attribute :entrypoint}
          info "using entry point#{'s' if eps.count > 1}: #{eps.map(&:name) * ", "}" \
            unless eps.empty?
        end

        abort "no entry points found." if eps.empty?

        program.each do |elem|
          case elem
          when CallStatement
            abort "found call to entry point procedure #{elem.procedure}." \
              if elem.target && elem.target.entrypoint?
          end
        end
      end

    end
  end
end
