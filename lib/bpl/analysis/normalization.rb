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
            if (d = elem.procedure.declaration) && d.is_entrypoint?
        when AssumeStatement
          abort "found :startpoint annotation." \
            if elem.attributes.include? :startpoint

          abort "found :endpoint annotation." \
            if elem.attributes.include? :endpoint
        end
      end
    end

    def self.uniq_starts_and_ends! program
      program.declarations << bpl("var $e: bool;")
      program.declarations.each do |proc|
        next unless proc.is_a?(ProcedureDeclaration) && proc.body
        proc.specifications << bpl("modifies $e;").resolve!(program)

        if proc.is_entrypoint?
          proc.body.statements.unshift bpl("$e := false;").resolve!(program)
          proc.body.statements.unshift bpl("assume {:startpoint} true;")
        else
          # this branch costs extra, on the order of 10s in my tests
          # proc.body.statements.unshift bpl("if ($e) { goto $exit; }")
        end

        case proc.body.statements.last
        when GotoStatement, ReturnStatement
        else
          proc.body.statements << bpl("return;")
        end
        
        exit_label = proc.fresh_label("$exit")

        exit_block = Block.new(declarations: [], statements: [
          exit_label.declaration,
          if proc.is_entrypoint? then [
            bpl("assume {:endpoint} true;"),
            bpl("assume $e;").resolve!(program),
            bpl("assert false;")
          ] end,
          bpl("return;")
        ].compact.flatten)

        scope = [exit_block, proc.body, proc, program]

        proc.body.replace do |s|
          case s
          when AssertStatement
            next bpl("if (!#{s.expression}) { $e := true; goto #{exit_label}; }").resolve!(scope)

          when CallStatement
            called = s.declaration
            next s unless called
            # next s if called.attributes.include?(:atomic)
            # next s if called.attributes.include?(:async)
            next s unless called.body
            next [s, bpl("if ($e) { goto #{exit_label}; }").resolve!(scope)]

          when AssumeStatement
            next s unless s.attributes.include? :yield
            next [s, bpl("if ($e) { goto #{exit_label}; }").resolve!(scope)]

          when ReturnStatement
            next bpl("goto #{exit_label};").resolve!(scope)
          else
            next s
          end
        end
        proc.body.statements += exit_block.statements
      end
    end
  end
end
