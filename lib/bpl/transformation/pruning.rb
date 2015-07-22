module Bpl
  module Transformation
    class Pruning < Bpl::Pass
      def self.description
        "Delete unreachable declarations."
      end

      def run! program
        work_list = program.declarations.select(&:is_entrypoint?)
        until work_list.empty?
          decl = work_list.shift
          decl.attributes[:reachable] = []
          decl.each do |elem|
            case elem
            when Identifier, CustomType
              d = elem.declaration
              work_list |= [d] unless d.nil? || d.attributes[:reachable]
            end
          end
        end

        # Axiom declarations which reference reachable functions are reachable.
        program.declarations.each do |decl|
          next unless decl.is_a?(AxiomDeclaration)
          decl.attributes[:reachable] = [] if decl.any? do |elem|
            case elem
            when Identifier
              elem.declaration && elem.declaration.attributes[:reachable]
            end
          end
        end

        program.declarations.select!{|d| d.attributes[:reachable]}
        program.each{|elem| elem.attributes.delete(:reachable)}
      end
    end
  end
end
