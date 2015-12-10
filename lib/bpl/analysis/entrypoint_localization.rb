module Bpl

  module Analysis
    class EntrypointLocalization < Bpl::Pass

      DEFAULT_ENTRYPOINT_ANNOTATION = :entrypoint

      flag "--entrypoint-localization", "Locate & annotate entry points."
      option :attribute, DEFAULT_ENTRYPOINT_ANNOTATION
      result :entrypoints, Set.new

      flag "--entrypoint-attribute NAME", "Attribute NAME for entrypoints." do |name|
        option :attribute, name
      end

      def default_entrypoint? name
        name =~ /\bmain\b/i
      end

      def run! program
        program.declarations.each do |d|
          entrypoints << d if d.has_attribute?(attribute)
        end

        program.declarations.each do |d|
          next unless d.is_a?(ProcedureDeclaration)
          entrypoints << d if default_entrypoint?(d.name)
        end if entrypoints.empty?

        warn "No entrypoints found." if entrypoints.empty?
        warn "Found call to entrypoint." if program.any? do |elem|
          elem.is_a?(CallStatement) && entrypoints.include?(elem.target)
        end
      end

    end
  end
end
