module Bpl

  module Transformation
    class EntrypointAnnotation < Bpl::Pass

      depends :entrypoint_localization
      flag "--entrypoint-annotation", "Annotate entrypoints."

      def run! program
        changed = false
        program.declarations.each do |decl|
          if entrypoint_localization.entrypoints.include?(decl)
            unless decl.has_attribute?(entrypoint_localization.attribute)
              decl.add_attribute(entrypoint_localization.attribute)
              changed = true
            end
          end
        end
        changed
      end
    end
  end

end
