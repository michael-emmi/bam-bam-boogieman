module Bpl
  class AtomicAnnotation < Pass

    depends :atomicity
    switch "--atomic-annotation", "Annotate atomic procedures."

    def run! program
      program.declarations.each do |decl|
        if atomicity.atomic[decl]
          unless decl.has_attribute?(atomicity.attribute)
            decl.add_attribute(atomicity.attribute)
            invalidates :atomicity
          end
        end
      end
    end

  end
end
