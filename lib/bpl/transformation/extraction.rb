module Bpl

  module Transformation
    class Extraction < Bpl::Pass

      depends :resolution
      depends :loop_identification
      flag "--extraction", "Extract annotated loops."

      def fresh_id
        @id ||= 0
        @id += 1
      end

      def extract(condition, invariants, blocks)
        id = fresh_id

        globals = blocks.collect do |b|
          b.select {|x| x.is_a?(StorageIdentifier) && x.is_global?}
        end.flatten.uniq(&:name)

        locals = blocks.collect do |b|
          b.select {|x| x.is_a?(StorageIdentifier) && !x.is_global?}
        end.flatten.uniq(&:name)

        decl = bpl("procedure $loop.#{id}();")
        locals.each do |x|
          decl.append_children(:parameters,
            StorageDeclaration.new(names: [x.name + ".0"], type: x.type))
          decl.append_children(:returns,
            StorageDeclaration.new(names: [x.name], type: x.type))
        end
        unless globals.empty?
          decl.append_children(:specifications,
            bpl("modifies #{globals.map(&:name) * ", "};"))
        end
        invariants.each do |i|
          decl.append_children(:specifications,
            bpl("requires #{i.expression};"),
            bpl("ensures #{i.expression};")
          )
        end
        decl.append_children(:specifications, bpl("ensures !#{condition};"))
        decl.append_children(:body, Body.new(locals: [], blocks: blocks))
        decl.body.blocks.first.prepend_children(:statements,
          *locals.map{|x| bpl("#{x.name} := #{x.name}.0;")})

        stmt = bpl %{
          call #{locals.map(&:name) * ", "} #{":=" unless locals.empty?}
          $loop.#{id}(#{locals.map(&:name) * ", "});
        }

        return decl, stmt
      end

      def run! program
        changed = false
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          next unless proc.body
          proc.each do |stmt|
            next unless stmt.is_a?(WhileStatement)
            next if stmt.invariants.empty?

            blocks = [Block.new(names: [], statements: [stmt.copy])]
            decl, call = extract(stmt.condition, stmt.invariants, blocks)
            program.append_children(:declarations, decl)
            stmt.replace_with(call)
          end
        end
        changed
      end
    end
  end

end
