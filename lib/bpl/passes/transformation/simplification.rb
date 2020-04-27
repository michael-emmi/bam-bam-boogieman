# typed: false
module Bpl
  class Simplification < Pass

    switch "--simplification", "Various code simplifications."

    depends :resolution
    depends :modification
    depends :cfg_construction
    depends :assertion_localization

    def trivial_statement?(elem)
      mods = modification
      asserts = assertion_localization

      case elem
      when AxiomDeclaration, AssumeStatement, AssertStatement
        (expr = elem.expression) &&
        (expr.is_a?(BooleanLiteral)) &&
        (expr.value == true)
      when CallStatement
        (decl = elem.procedure.declaration) &&
        mods.modifies[decl].empty? &&
        decl.returns.empty? &&
        !asserts.has_assert[decl]
      else
        false
      end
    end

    def readonly_variable?(elem)
      elem.is_a?(VariableDeclaration) &&
      elem.bindings.none? do |b|
        b.parent &&
        ( b.parent.is_a?(HavocStatement) ||
          ( b.parent.is_a?(AssignStatement) &&
            b.parent.lhs.include?(b)
          )
        )
      end
    end

    def unused_storage?(elem)
      (elem.is_a?(VariableDeclaration) || elem.is_a?(ConstantDeclaration)) &&
      elem.bindings.map(&:parent).
        all? {|n| n.is_a?(HavocStatement) || n.is_a?(ModifiesClause)}
    end

    def trivial_implementation?(elem)
      mods = modification
      asserts = assertion_localization

      elem.is_a?(ProcedureDeclaration) &&
      elem.body &&
      !asserts.has_assert[elem] &&
      mods.modifies[elem].empty? &&
      elem.returns.
        all? {|x| x.bindings.all? {|b| b.parent.is_a?(HavocStatement)}}
    end

    def trivial_block?(elem)
      cfg = cfg_construction

      elem.is_a?(Block) &&
      elem.parent &&
      elem.statements.count == 1 &&
      elem.statements.first.is_a?(GotoStatement) &&
      elem.statements.first.identifiers.count == 1 &&
      (preds = cfg.predecessors[elem]) &&
      (preds.count <= 1) &&
      (!preds.first || preds.first.statements.last.is_a?(GotoStatement)) &&
      (!preds.first || preds.first.statements.last.identifiers.count == 1)
    end

    def trivial_branch?(elem)
      cfg = cfg_construction

      elem.is_a?(Block) &&
      cfg.successors[elem].count == 2 &&
      elem.statements.last.is_a?(GotoStatement) &&
      elem.statements.last.identifiers.count == 2 &&
      (b1, b2 = cfg.successors[elem].to_a) &&
      (b1 != b2) &&
      cfg.successors[b1].count == 1 &&
      cfg.successors[b1] == cfg.successors[b2] &&
      b1.statements.count == 1 &&
      b1.statements.last.is_a?(GotoStatement) &&
      b2.statements.count == 1 &&
      b2.statements.last.is_a?(GotoStatement)
    end

    def simplify(elem)
      cfg = cfg_construction

      case
      when trivial_statement?(elem)
        info "removing trivial element: #{elem}"
        elem.remove

        if elem.is_a?(AssertStatement)
          invalidates :assertion_localization
          redo!
        end

      when readonly_variable?(elem) && elem.parent && elem.parent.is_a?(Program)
        # NOTE Boogie does not permit local constant declarations
        info "converting read-only variable to constant: #{elem}"
        elem.replace_with(bpl("const #{elem.names * ", "}: #{elem.type};"))
        invalidates :resolution
        redo!

      when unused_storage?(elem)
        if elem.parent.is_a?(Program)
          invalidates :modification
          redo!
        end
        info "removing unused storage: #{elem.names * ", "}"
        elem.bindings.
          map {|b| b.siblings.count > 1 ? b : b.parent}.
          each(&:remove)
        elem.remove

      when trivial_implementation?(elem)
        info "removing body of procedure: #{elem.name}"
        elem.replace_children(:body, nil)

      when trivial_block?(elem)
        info "removing trivial block: #{elem.name}"
        pred = cfg.predecessors[elem].first
        pred.statements.last.replace_with(elem.statements.last) if pred
        elem.remove
        invalidates :resolution
        invalidates :cfg_construction
        redo!

      when trivial_branch?(elem)
        info "removing trivial branch: #{elem.name}"
        elem.statements.last.
          replace_with(cfg.successors[elem].first.statements.last.copy)
        cfg.successors[elem].each(&:remove)
        invalidates :cfg_construction
        redo!

      end
    end

    def run! program
      program.each(&method(:simplify))
    end

  end
end
