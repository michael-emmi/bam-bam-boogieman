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
  end

  module Analysis
    class EqrSequentialization

      include DFAsyncRemoval

      attr_accessor :rounds, :delays

      def initialize(rounds, delays)
        @rounds = rounds
        @delays = delays
        @use_maps = false
      end

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
        program << bpl("const #DELAYS: int;")
        program << bpl("axiom #ROUNDS == #{@rounds};").resolve!(program)
        program << bpl("axiom #DELAYS == #{@delays};").resolve!(program)

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
            proc.body.statements.unshift bpl("assume #k == #k.0;").resolve!(scope)
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
                  "modifies #{@rounds.times.map{|i| "#{g}.r#{i}"} * ", "};"
                ).resolve!(scope)
                next unless proc.attributes.include?(:atomic)
                next unless proc.body.nil?
                # TODO why is it slower to include more ensures on atomic
                # procedures which also have bodies??
                @rounds.times do |i|
                  new_specs << bpl(
                    "ensures #k == #{i} || #{g}.r#{i} == old(#{g}.r#{i});"
                  ).resolve!(scope)
                end
              end
            when RequiresClause, EnsuresClause
              # TODO only throw away specs which refer to globals...
              next unless proc.attributes.include?(:atomic)
              if spec.any?(&:is_global_var?)
                @rounds.times do |i|
                  expr = bpl_expr("#{spec.expression}").resolve!(old_scope)
                  expr.replace do |g|
                    if g.is_global_var? then bpl("#{g}.r#{i}") else g end
                  end
                  new_specs << bpl("ensures #k != #{i} || #{expr};").resolve!(scope)
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

          proc.body.replace do |stmt|
            case stmt
            when CallStatement
              stmt.arguments << bpl("#k").resolve!(scope)
              stmt.assignments << bpl("#k").resolve!(scope) \
                unless stmt.target && stmt.target.attributes.include?(:atomic)
              next stmt
              
            when IfStatement, WhileStatement
              next stmt unless stmt.condition.any?(&:is_global_var?)
              stmt.condition = stmt.condition.replace {|g| g.split(@rounds).resolve!(scope)}

            when AssertStatement, AssumeStatement, HavocStatement, AssignStatement
              if stmt.attributes.include? :yield then
                next [
                  bpl("havoc #j;").resolve!(scope),
                  bpl("assume #j >= #k;").resolve!(scope),
                  bpl("assume #j < #{@rounds};").resolve!(scope),
                  bpl("#k := #j;").resolve!(scope)
                ]

              elsif stmt.attributes.include? :startpoint
                next gs.product(@rounds.times.to_a).map do |g,i|
                  bpl("assume #{g}.r#{i} == #{g}.r#{i}.0;").resolve!(scope)
                end + [bpl("assume #k == 0;").resolve!(scope), stmt]

              elsif stmt.attributes.include? :endpoint
                next [stmt] +
                  gs.product((@rounds-1).times.to_a).map do |g,i|
                    bpl("assume #{g}.r#{i+1}.0 == #{g}.r#{i};").resolve!(scope)
                  end
              end

              next stmt unless stmt.any?(&:is_global_var?)

              if proc.name == "$static_init"
                next bpl("#{stmt}").resolve!(old_scope).replace {|g| g.round(0)}.resolve!(scope)
              end

              next @rounds.times.reduce(nil) do |rest,i|
                s = bpl("#{stmt}").resolve!(old_scope).replace {|g| g.round(i)}
                if rest.is_a?(IfStatement)
                  bpl("if (#k == #{i}) { #{s} } else #{rest}")
                elsif rest.is_a?(Statement)
                  bpl("if (#k == #{i}) { #{s} } else { #{rest} }")
                else s
                end
              end.resolve!(scope)
            end
            stmt
          end

        end
      end

    end
  end
end
