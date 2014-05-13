module Bpl
  module AST
    class Program
      def has_async?; any?{|e| e.attributes.include? :async} end
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
        # Bpl::Analysis::resolve! program
        # Bpl::Analysis::correct_modifies! program
        # async_to_call! program
        # bookmarks! program
        # Bpl::Analysis::resolve! program
        # Bpl::Analysis::correct_modifies! program
      end

      def excluded_variables; ['#d'] end
      def included_variables program
        program.global_variables.select{|d| (d.names & excluded_variables).empty?}
      end

      # def self.bookmarks! program
      #   bookmarks = Set.new
      #   program.replace do |elem|
      # 
      #     if elem.attributes.include? :bookmark
      #       next unless name = elem.attributes[:bookmark].first
      #       bookmarks << name.gsub(/"/,"")
      #       next [
      #         bpl("$C.#{name}[#t] := $C.#{name}[#t] + 1;"),
      #         bpl("assume $RRR(#t,$B.#{name},$C.#{name}[#t]) == #k;")
      #       ]
      # 
      #     elsif elem.attributes.include? :round
      #       next unless (ax = elem.attributes[:round]).count == 4
      #       next bpl("assume $RRR(#{ax[0]},$B.#{ax[1]},#{ax[2]}) == #{ax[3]};")
      #     end
      # 
      #     next elem
      #   end
      #   bookmarks.each_with_index do |name,i|
      #     program.declarations << bpl("const $B.#{name}: int;")
      #     program.declarations << bpl("axiom $B.#{name} == #{i};")
      #     program.declarations << bpl("var $C.#{name}: [int] int;")
      #   end
      #   program.replace do |elem|
      #     next elem unless elem.attributes.include? :startpoint
      #     next bookmarks.map do |name|
      #       bpl("assume (forall t: int :: {$C.#{name}[t]} $C.#{name}[t] == 0);")
      #     end + [elem]
      #   end
      #   program.declarations << bpl("function $RRR(int,int,int) returns (int);")
      # end
      
      def vectorize! program
        if @use_maps
          vectorize_with_maps! program
        else
          vectorize_without_maps! program
        end
      end

      def vectorize_with_maps! program
        globals = included_variables program
        gs = globals.map{|d| d.idents}.flatten
        return if gs.empty?

        # triggers
        program.declarations << bpl("function $R(int) returns (bool);")

        program.declarations << bpl("const #ROUNDS: int;")
        program.declarations << bpl("const #DELAYS: int;")
        # program.declarations << bpl("axiom #ROUNDS == #{@rounds};")
        # program.declarations << bpl("axiom #DELAYS == #{@delays};")
        program.declarations += globals.map do |decl|
          type = decl.type
          decl.type = bpl_type("[int] #{type}")
          bpl "const #{decl.names.map{|g| "#{g}.0"} * ", "}: [int] #{type};"
        end
        program.declarations << bpl("var #d: int;")

        program.declarations.each do |decl|
          case decl
          when ProcedureDeclaration

            if !decl.body && !decl.modifies.empty?
              decl.parameters << bpl("#k: int")
              decl.modifies.each do |x|
                decl.specifications <<
                  bpl("ensures (forall k: int :: {$R(k)} k != #k ==> #{x}[k] == old(#{x})[k]);")
              end
              decl.specifications.each do |spec|
                case spec
                when EnsuresClause, RequiresClause
                  spec.replace do |elem|
                    if elem.is_a?(StorageIdentifier) && elem.is_variable? && elem.is_global? then
                      next bpl("#{elem}[#k]")
                    end
                    elem
                  end
                end
              end
            end

            if decl.body then
              if decl.is_entrypoint?
                decl.body.declarations << bpl("var #k: int;")

              else
                decl.parameters << bpl("#k.0: int")
                decl.returns << bpl("#k: int")
                decl.body.statements.unshift bpl("#k := #k.0;")
              end

              decl.specifications << bpl("modifies #d;")
              decl.body.declarations << bpl("var #j: int;") \
                if decl.body.any?{|e| e.attributes.include? :yield}

              mods = (decl.modifies & gs).sort

              decl.body.replace do |elem|
                case elem
                when CallStatement
                  called = elem.procedure.declaration
                  if called && called.body
                    elem.arguments << bpl("#k")
                    elem.assignments << bpl("#k")
                  elsif called && !called.modifies.empty?
                    elem.arguments << bpl("#k")
                  end
                  next elem

                when StorageIdentifier
                  if elem.is_variable? && elem.is_global? &&
                    !excluded_variables.include?(elem.name) then
                    next bpl("#{elem}[#k]")
                  end

                when AssumeStatement
                  if elem.attributes.include? :yield then

                    next bpl(<<-end
                      if (*) {
                        havoc #j;
                        assume #j >= 1;
                        assume #k + #j < #ROUNDS;
                        // assume #d + #j <= #DELAYS;
                        assume #d + 1 <= #DELAYS;
                        #k := #k + #j;
                        // #d := #d + #j;
                        #d := #d + 1;
                      }
                    end
                    )

                  elsif elem.attributes.include? :startpoint

                    next [ bpl("#d := 0;"), bpl("#k := 0;") ] +
                      mods.map{|g| bpl("#{g} := #{g}.0;")} +
                      [elem]

                  elsif elem.attributes.include? :endpoint

                    # NEW VERSION -- independent of rounds bound.
                    next [elem] +
                      mods.map do |g|
                        bpl("assume (forall k: int :: {$R(k)} #{g}[k-1] == #{g}.0[k]);")
                      end

                    # PREVIOUS VERSION -- needs to know rounds bound.
                    # next [elem] +
                    #   (1..rounds).map do |i|
                    #     mods.map{|g| bpl("assume #{g}[#{i-1}] == #{g}.0[#{i}];")}
                    #   end.flatten

                  end
                end
                elem
              end
            end
          end
        end

      end

      def acc var
        if var.is_a?(StorageIdentifier) &&
          var.is_variable? && var.is_global? &&
          !excluded_variables.include?(var.name) then

          (1..@rounds-1).reduce(bpl("#{var}.r0")) do |elem,k|
            bpl_expr("if #k == #{k} then #{var}.r#{k} else #{elem}")
          end
        else
          var
        end
      end

      def vectorize_without_maps! program
        return unless program.any? {|elem| elem.attributes.include?(:yield)}
        return unless @rounds > 1
        globals = program.global_variables
        gs = globals.map(&:idents).flatten
        old_program = Program.new(declarations: globals)

        if globals.empty?
          program.each {|elem| elem.attributes.delete(:yield)}
          return
        end

        program.declarations << bpl("const #ROUNDS: int;")
        program.declarations << bpl("const #DELAYS: int;")
        program.declarations << bpl("axiom #ROUNDS == #{@rounds};").resolve!(program)
        program.declarations << bpl("axiom #DELAYS == #{@delays};").resolve!(program)

        globals.each do |decl|
          program.declarations.delete(decl)
          decl.names.each do |g|
            program.declarations << bpl(
              "var #{@rounds.times.map{|i| "#{g}.r#{i}"} * ", "}: #{decl.type};"
            )
            program.declarations << bpl(
              "const #{@rounds.times.map{|i| "#{g}.r#{i}.0"} * ", "}: #{decl.type};"
            )
          end
        end

        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          scope = [proc.body, proc, program]

          if proc.is_entrypoint?
            proc.body.declarations << bpl("var #k: int where #k >= 0 && #k < #{@rounds};")
          elsif proc.attributes.include? :atomic
            proc.parameters << bpl("#k: int where #k >= 0 && #k < #{@rounds}")
          else
            proc.parameters << bpl("#k.0: int where #k.0 >= 0 && #k.0 < #{@rounds}")
            proc.returns << bpl("#k: int where #k >= 0 && #k < #{@rounds}")
            proc.body.statements.unshift bpl("#k := #k.0;")
          end

          old_mods = proc.modifies
          new_specs = []
          proc.specifications.each do |spec|
            case spec
            when ModifiesClause
              spec.identifiers.each do |g|
                new_specs << bpl(
                  "modifies #{@rounds.times.map{|i| "#{g}.r#{i}"} * ", "};"
                ).resolve!(scope)
                next unless proc.attributes.include?(:atomic)
                @rounds.times do |i|
                  new_specs << bpl(
                    "ensures #k == #{i} || #{g}.r#{i} == old(#{g}.r#{i});"
                  ).resolve!(scope)
                end
              end
            when RequiresClause, EnsuresClause
              next unless proc.attributes.include?(:atomic)
              if spec.any? {|g| g.is_a?(StorageIdentifier) && g.is_global?}
                @rounds.times do |i|
                  expr = bpl_expr("#{spec.expression}").resolve!(old_program)
                  expr.replace do |g|
                    next g unless g.is_a?(StorageIdentifier) && g.is_global?
                    next bpl("#{g}.r#{i}")
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
          proc.body.replace do |stmt|
            case stmt
            when CallStatement
              stmt.arguments << bpl("#k").resolve!(scope)
              stmt.assignments << bpl("#k").resolve!(scope) \
                unless stmt.target && stmt.target.attributes.include?(:atomic)
              next stmt
            when AssumeStatement
              if stmt.attributes.include? :yield then
                temp = proc.fresh_var("#k",Type::Integer)
                next [
                  bpl("assume #{temp} >= 0;"),
                  bpl("assume #{temp} >= #k;"),
                  bpl("assume #{temp} < #{@rounds};"),
                  bpl("#k := #{temp};")
                ]
              elsif stmt.attributes.include? :startpoint
                next old_mods.product(@rounds.times.to_a).map do |g,i|
                  bpl("#{g}.r#{i} := #{g}.r#{i}.0;").resolve!(scope)
                end + [bpl("assume #k == 0;").resolve!(scope), stmt]
              elsif stmt.attributes.include? :endpoint
                next [stmt] +
                  old_mods.product((@rounds-1).times.to_a).map do |g,i|
                    bpl("assume #{g}.r#{i+1}.0 == #{g}.r#{i};").resolve!(scope)
                  end
              end
            end
            stmt
          end
          
          next

          ignore = false
          proc.traverse do |elem,phase|
            case elem
            when Trigger
              ignore = (phase == :pre)
              next nil # TODO don't throw away the triggers!

            when AssignStatement
              ignore = (phase == :pre)
              elem.rhs.map! {|rhs| rhs.replace {|e| acc(e)}} unless ignore
            when StorageIdentifier
              next acc(elem) unless ignore
            end
            elem
          end

          if proc.body then
            mods = (proc.modifies & gs).sort

            proc.body.replace do |elem|
              case elem

              when AssignStatement
                if elem.lhs.any? {|lhs| lhs.any? {|g|
                  g.is_a?(StorageIdentifier) &&
                  g.is_variable? && g.is_global? &&
                  !excluded_variables.include?(g.name)
                }} then

                  if proc.name == "$static_init"
                    elem.lhs.each {|lhs| lhs.replace {|elem|
                      if elem.is_a?(StorageIdentifier)&& elem.is_variable? &&
                        elem.is_global? && !excluded_variables.include?(elem.name)
                        then
                        bpl("#{elem}.r0")
                      else
                        elem
                      end
                    }}
                    next elem
                  end

                  next (0..@rounds-1).reduce(nil) do |rest,k|
                    lhs = elem.lhs.map {|lhs| lhs.clone.replace {|elem|
                      if elem.is_a?(StorageIdentifier) &&
                        elem.is_variable? && elem.is_global? &&
                        !excluded_variables.include?(elem.name) then
                        bpl("#{elem}.r#{k}")
                      else
                        elem
                      end
                    }}
                    if rest.is_a?(IfStatement)
                      bpl("if (#k == #{k}) { #{lhs * ", "} := #{elem.rhs * ", "}; } else #{rest}")
                    elsif rest.is_a?(Statement)
                      bpl("if (#k == #{k}) { #{lhs * ", "} := #{elem.rhs * ", "}; } else { #{rest} }")
                    else
                      bpl("#{lhs * ", "} := #{elem.rhs * ", "};")
                    end
                  end
                end
              end
              elem
            end
          end
        end
      end

    end
  end
end
