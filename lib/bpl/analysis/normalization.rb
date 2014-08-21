module Bpl

  module AST
    class Declaration
      def is_entrypoint?
        is_a?(ProcedureDeclaration) && attributes.has_key?(:entrypoint)
      end
    end
  end

  module Analysis
    def self.normalize! program
      locate_entrypoints! program
      sanity_check program
      uniq_starts_and_ends! program
      # resolve! program
    end

    def self.is_default_entrypoint? name
      name =~ /\bmain\b/i
    end

    def self.locate_entrypoints! program
      eps = program.declarations.select(&:is_entrypoint?)
      
      if eps.empty?
        info "no entry points found; looking for the defaults..."
        eps = program.declarations.select do |d|
          d.is_a?(ProcedureDeclaration) && is_default_entrypoint?(d.name)
        end
        eps.each{|d| d.attributes[:entrypoint] = []}
        info "using entry point#{'s' if eps.count > 1}: #{eps.map(&:name) * ", "}" \
          unless eps.empty?
      end

      abort "no entry points found." if eps.empty?
    end

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
