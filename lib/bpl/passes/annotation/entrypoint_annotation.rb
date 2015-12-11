module Bpl
  class EntrypointAnnotation < Pass

    depends :entrypoint_localization
    flag "--entrypoint-annotation", "Annotate entrypoints."

    def run! program
      program.declarations.each do |decl|
        if entrypoint_localization.entrypoints.include?(decl)
          unless decl.has_attribute?(entrypoint_localization.attribute)
            decl.add_attribute(entrypoint_localization.attribute)
            invalidates :all
          end
        end
      end

    end
  end
end
