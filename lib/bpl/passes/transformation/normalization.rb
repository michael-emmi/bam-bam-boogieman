# typed: false
module Bpl
  class Normalization < Pass

    depends :resolution
    switch "--normalization", "Normalize program ..."

    def run! program

      # TODO specify what normalization should be doing

      program.each do |elem|
        case elem
        when AssignStatement
          if elem.lhs.count > 1
            info "NORMALIZING MULTI-ASSIGNMENT"
            info
            info elem.to_s.indent
            info
            writes = elem.lhs.map(&:ident).map(&:name)
            unless elem.rhs.any? do |e|
              e.any? do |x|
                x.is_a?(StorageIdentifier) && writes.include?(x.name)
              end
            end then
              # the simple case, no conflicts
              elem.replace_with(
                *elem.lhs.count.times.map do |i|
                  bpl("#{elem.lhs[i]} := #{elem.rhs[i]};")
                end
              )
            else
              # the complicated case, read all before writing any
              p = elem.each_ancestor.find{|d| d.is_a?(ProcedureDeclaration)}
              vars = elem.lhs.count.times.map do |i|
                p.fresh_var(elem.lhs[i].type)
              end
              elem.replace_with(
                *vars.map.with_index {|x,i| bpl("#{x} := #{elem.rhs[i]};")},
                *vars.map.with_index {|x,i| bpl("#{elem.lhs[i]} := #{x};")}
              )
            end
            invalidates :all
          end
        end
      end

      # TODO what to do with this stuff?
      # sanity_check program
      # uniq_starts_and_ends! program
    end

    # TODO OBSOLETE CODE
    def self.sanity_check program
      program.each do |elem|
        case elem
        when CallStatement
          abort "found call to entry point procedure #{elem.procedure}." \
            if elem.target && elem.target.is_entrypoint?
        when AssumeStatement
          abort "found :startpoint annotation." \
            if elem.attributes.include? :startpoint

          abort "found :endpoint annotation." \
            if elem.attributes.include? :endpoint
        end
      end
    end

    # TODO OBSOLETE CODE
    def self.uniq_starts_and_ends! program
      program << bpl("var $e: bool;")
      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration) && proc.body
        proc.specifications << bpl("modifies $e;", scope: program)

        if proc.is_entrypoint?
          proc.body.first.unshift bpl("$e := false;", scope: program)
          proc.body.first.unshift bpl("assume {:startpoint} true;")
        else
          ## this branch costs extra, on the order of 10s in my tests
          # proc.body.statements.unshift bpl("if ($e) { goto $exit; }")
        end

        case proc.body.last.last
        when GotoStatement, ReturnStatement
        else proc.body.last << bpl("return;")
        end

        exit_block = if proc.is_entrypoint? then
          bpl(<<-END, scope: program)
          $exit:
            assume {:endpoint} true;
            assume $e;
            assert false;
            return;
            END
        else
          bpl("$exit: return;")
        end

        # an artificial scope containing the exit block
        scope = [Body.new(blocks: [exit_block]), proc.body, proc, program]

        proc.body.each do |stmt|
          case stmt
          when AssertStatement
            stmt.replace_with \
              bpl("if (!#{stmt.expression}) { $e := true; goto $exit; }", scope: scope)

          when CallStatement
            # TODO why do these "optimizations" make things slower??
            # next s unless s.target && s.target.body
            # next s if s.target.attributes.include?(:atomic)
            # next s unless s.target.modifies.include?(bpl("$e").resolve!(program))
            # next s if s.target.attributes.include?(:async)
            # next [s, bpl("if ($e) { goto $exit; }", scope: scope)]
            stmt.insert_after bpl("if ($e) { goto $exit; }", scope: scope)

          when AssumeStatement
            if stmt.attributes.include? :yield
              stmt.insert_after bpl("if ($e) { goto $exit; }", scope: scope)
            end

          when ReturnStatement
            stmt.replace_with bpl("goto $exit;", scope: scope)

          end
        end
        proc.body << exit_block
      end
    end
  end
end
