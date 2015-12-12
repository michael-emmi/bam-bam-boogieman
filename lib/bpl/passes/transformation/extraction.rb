module Bpl
  class Extraction < Pass

    depends :loop_identification
    switch "--extraction", "Extract annotated loops."

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

      exits = blocks.collect do |b|
        b.select do |x|
          x.is_a?(LabelIdentifier) &&
          blocks.none? {|bb| bb.names.include?(x.name)}
        end
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
      decl.append_children(:body, Body.new(locals: [], blocks: []))
      decl.body.append_children(:blocks,
        bpl("$entry: goto #{blocks.first.name};")) if blocks.first.name
      decl.body.append_children(:blocks,
        *blocks.map(&:copy))
      decl.body.blocks.first.prepend_children(:statements,
        *locals.map{|x| bpl("#{x.name} := #{x.name}.0;")})
      decl.body.append_children(:blocks,
        *exits.map {|l| bpl("#{l}: assume !#{condition}; return;")})

      stmt = bpl %{
        call #{locals.map(&:name) * ", "} #{":=" unless locals.empty?}
        $loop.#{id}(#{locals.map(&:name) * ", "});
      }

      return decl, stmt
    end

    def run! program
      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration)
        next unless proc.body
        proc.each do |stmt|
          next unless stmt.is_a?(WhileStatement)
          next if stmt.invariants.empty?

          block = Block.new(names: [], statements: [stmt.copy])
          decl, call = extract(stmt.condition, stmt.invariants, [block])
          program.append_children(:declarations, decl)
          stmt.replace_with(call)
          invalidates :all
        end
      end
      loop_identification.loops.each do |head,body|
        condition = bpl("true")

        ls = head.select {|l| l.is_a?(LabelIdentifier)}.map(&:name)
        exits = ls.select {|l| body.none? {|b| b.names.include?(l)}}
        entry = body.
          collect {|b| b.statements.first if !(b.names & (ls-exits)).empty?}.
          compact
        fail "Unexpected loop condition." unless
          entry.count == 1 && entry.first.is_a?(AssumeStatement)

        condition = entry.first.expression
        invariants = []
        head.statements.each do |stmt|
          case stmt
          when AssertStatement
            invariants << stmt
          when AssumeStatement

          else
            break
          end
        end
        next if invariants.empty?

        decl, call = extract(condition, invariants, body.map(&:copy))
        program.append_children(:declarations, decl)

        head.replace_children(:statements,
          call,
          bpl("goto #{exits * ", "};"))
        body.each {|b| b.remove if b != head}
        invalidates :all
      end
    end
  end
end
