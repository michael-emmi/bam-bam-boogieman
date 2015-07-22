module Bpl
  module AST
    class Node
      def is_global_var?
        is_a?(StorageIdentifier) && is_global? && is_variable?
      end
      def round(i)
        if is_global_var? then bpl("#{self}.r#{i}") else self end
      end
      def split(rounds)
        return self unless is_global_var?
        return (1..rounds-1).reduce(bpl("#{self}.r0")) do |elem,k|
          bpl_expr("if #k == #{k} then #{self}.r#{k} else #{elem}")
        end
      end
    end
    class Statement
      def split(rounds,scope)
        rounds.times.reduce(nil) do |rest,i|
          s = bpl("#{self}", scope: scope).replace! {|g| g.round(i)}
          if rest.is_a?(IfStatement)
            bpl("if (#k == #{i}) { #{s} } else #{rest}")
          elsif rest.is_a?(Statement)
            bpl("if (#k == #{i}) { #{s} } else { #{rest} }")
          else s
          end
        end
      end
    end
  end

  module Transformation
    class EqrSequentialization < Bpl::Pass
      def self.description
        "The vectorization part of the EQR sequentialization."
      end

      option :rounds, "the number of rounds"
      option :delays, "the number of delays"

      def sequentialize! program
        vectorize! program
        async_to_call! program
      end

      def vectorize! program
        return unless program.any? {|elem| elem.attributes.include?(:yield)}
        unless @rounds > 1
          program.each {|elem| elem.attributes.delete(:yield)}
          return
        end
        globals = program.global_variables
        gs = globals.map(&:idents).flatten
        old_program = Program.new(declarations: program.declarations.select do |d|
          d.respond_to?(:name) || d.respond_to?(:names)
        end)

        if globals.empty?
          program.each {|elem| elem.attributes.delete(:yield)}
          return
        end

        program << bpl("const #ROUNDS: int;")
        program << bpl("axiom #ROUNDS == #{@rounds};", scope: program)

        globals.each do |decl|
          program.declarations.delete(decl)
          decl.names.each do |g|
            program << bpl(
              "var #{@rounds.times.map{|i| "#{g}.r#{i}"} * ", "}: #{decl.type};"
            )
            program << bpl(
              "const #{@rounds.times.map{|i| "#{g}.r#{i}.0"} * ", "}: #{decl.type};"
            )
          end
        end

        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          scope = [proc.body, proc, program]
          old_scope = [proc.body, proc, old_program]

          if proc.attributes.include? :atomic
            proc.parameters << bpl("#k: int")
          else
            proc.parameters << bpl("#k.0: int")
            proc.returns << bpl("#k: int")
            proc.body.blocks.first.statements.unshift bpl("assume #k == #k.0;", scope: scope)
          end

          if proc.any? {|s| s.attributes.include? :yield}
            proc.body.declarations << bpl("var #j: int;")
          end

          new_specs = []
          proc.specifications.each do |spec|
            case spec
            when ModifiesClause
              spec.identifiers.each do |g|
                new_specs << bpl(
                  "modifies #{@rounds.times.map{|i| "#{g}.r#{i}"} * ", "};",
                  scope: scope)
                next unless proc.attributes.include?(:atomic)
                next unless proc.body.nil?
                # TODO why is it slower to include more ensures on atomic
                # procedures which also have bodies??
                @rounds.times do |i|
                  new_specs << bpl(
                    "ensures #k == #{i} || #{g}.r#{i} == old(#{g}.r#{i});",
                    scope: scope)
                end
              end
            when RequiresClause, EnsuresClause
              # TODO only throw away specs which refer to globals...
              next unless proc.attributes.include?(:atomic)
              if spec.any?(&:is_global_var?)
                @rounds.times do |i|
                  expr = bpl_expr("#{spec.expression}", scope: old_scope)
                  expr.replace! do |g|
                    if g.is_global_var? then bpl("#{g}.r#{i}") else g end
                  end
                  new_specs << bpl("ensures #k != #{i} || #{expr};", scope: scope)
                end
              else
                new_specs << spec
              end
            end
          end
          proc.specifications = new_specs

          next unless proc.body

          # # replace each global `g` by `g.split(@rounds)`
          # ignore = false
          # proc.body.traverse do |elem,phase|
          #   case elem
          #   when Trigger
          #     ignore = (phase == :pre)
          #     next nil # TODO don't throw away the triggers!
          #
          #   when AssignStatement
          #     ignore = (phase == :pre)
          #     elem.rhs.map! {|r| r.replace {|g| g.split(@rounds).resolve!(scope)}} unless ignore
          #
          #   when StorageIdentifier
          #     next elem.split(@rounds).resolve!(scope) unless ignore
          #   end
          #   elem
          # end

          # NOTE times were slightly better when only LHS-accesses resulted
          # in copied statements.

          proc.body.each do |stmt|
            case stmt
            when CallStatement
              stmt.arguments << bpl("#k", scope: scope)
              stmt.assignments << bpl("#k", scope: scope) \
                unless stmt.target && stmt.target.attributes.include?(:atomic)

            when IfStatement, WhileStatement
              next unless stmt.condition.any?(&:is_global_var?)
              stmt.condition = stmt.condition.replace! {|g| g.split(@rounds).resolve!(scope)}

            when HavocStatement
              next unless stmt.any?(&:is_global_var?)
              stmt.replace_with \
                stmt.split(@rounds,old_scope).resolve!(scope)

            when AssignStatement
              next unless stmt.any?(&:is_global_var?)
              if proc.name == "$static_init"
                stmt.replace_with \
                  bpl("#{stmt}", scope: old_scope).replace! {|g| g.round(0)}.resolve!(scope)
              elsif stmt.lhs.any? {|l| l.any?(&:is_global_var?)}
                stmt.replace_with \
                  stmt.split(@rounds,old_scope).resolve!(scope)
              else
                s = stmt.replace! do |g|
                  if g.is_a?(Statement) then g else g.split(@rounds).resolve!(scope) end
                end
                stmt.replace_with(s)
              end

            when AssertStatement, AssumeStatement
              if stmt.attributes.include? :yield then
                stmt.replace_with(
                  bpl("havoc #j;", scope: scope),
                  bpl("assume #j >= #k;", scope: scope),
                  bpl("assume #j < #{@rounds};", scope: scope),
                  bpl("#k := #j;", scope: scope))

              elsif stmt.attributes.include? :startpoint
                stmt.insert_before *(
                  gs.product(@rounds.times.to_a).map do |g,i|
                    bpl("assume #{g}.r#{i} == #{g}.r#{i}.0;", scope: scope)
                  end)
                stmt.insert_before bpl("assume #k == 0;", scope: scope)

              elsif stmt.attributes.include? :endpoint
                stmt.insert_after *(
                  gs.product((@rounds-1).times.to_a).map do |g,i|
                    bpl("assume #{g}.r#{i+1}.0 == #{g}.r#{i};", scope: scope)
                  end)

              elsif stmt.any?(&:is_global_var?)
                stmt.expression = stmt.expression.replace! {|g| g.split(@rounds).resolve!(scope)}
              end

            end
          end

        end
      end

    end
  end
end
