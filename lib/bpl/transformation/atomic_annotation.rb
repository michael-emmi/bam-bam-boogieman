module Bpl

  module Transformation
    class AtomicAnnotation < Bpl::Pass

      depends :atomicity
      flag "--atomic-annotation", "Annotate atomic procedures."

      def run! program
        changed = false
        program.declarations.each do |decl|
          if atomicity.atomic[decl]
            unless decl.has_attribute?(atomicity.attribute)
              decl.add_attribute(atomicity.attribute)
              changed = true
            end
          end
        end
        changed
      end
    end
  end

end
