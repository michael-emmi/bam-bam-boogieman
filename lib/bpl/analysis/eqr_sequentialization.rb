module Bpl
  module AST
    class Program
      def has_async?; any?{|e| e.attributes.include? :async} end
    end
  end

  module Analysis
    def self.eqr_sequentialize! program, rounds, delays
      vectorize! program, rounds, delays
      resolve! program
      puts program.inspect

      async_to_call! program
      # bookmarks! program
      correct_modifies! program
      resolve! program
    end

    def self.excluded_variables; ['#d'] end
    def self.included_variables program
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

    def self.vectorize_with_maps! program, rounds, delays
      globals = included_variables program
      gs = globals.map{|d| d.idents}.flatten
      return if gs.empty?

      # triggers
      program.declarations << bpl("function $R(int) returns (bool);")

      program.declarations << bpl("const #ROUNDS: int;")
      program.declarations << bpl("const #DELAYS: int;")
      # program.declarations << bpl("axiom #ROUNDS == #{rounds};")
      # program.declarations << bpl("axiom #DELAYS == #{delays};")
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
                proc = elem.procedure.declaration
                if proc && proc.body
                  elem.arguments << bpl("#k")
                  elem.assignments << bpl("#k")
                elsif proc && !proc.modifies.empty?
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

    def self.acc var, rounds
      (1..rounds-1).reduce(bpl("#{var}.r0")) do |elem,k|
        bpl_expr("if #k == #{k} then #{var}.r#{k} else #{elem}")
      end
    end

    def self.vectorize! program, rounds, delays
      globals = included_variables program
      gs = globals.map{|d| d.idents}.flatten
      return if gs.empty?

      program.declarations << bpl("const #ROUNDS: int;")
      program.declarations << bpl("const #DELAYS: int;")
      # program.declarations << bpl("axiom #ROUNDS == #{rounds};")
      # program.declarations << bpl("axiom #DELAYS == #{delays};")

      program.declarations += globals.map do |decl|
        names = decl.names.map{|n| n}
        type = decl.type
        decl.names.map! {|g| "#{g}.r0"}

        (1..rounds-1).map do |k|
          [ bpl("var #{names.map {|g| "#{g}.r#{k}"} * ", "}: #{type};"),
            bpl("const #{names.map {|g| "#{g}.r#{k}.0"} * ", "}: #{type};") ]
        end
      end.flatten
      program.declarations << bpl("var #d: int;")

      program.declarations.each do |decl|
        case decl
        when ProcedureDeclaration

          if !decl.body && !decl.modifies.empty?
            decl.parameters << bpl("#k: int")
            decl.modifies.each do |g|
              (0..rounds-1).map do |k|
                decl.specifications <<
                  bpl("ensures #k == #{k} || #{g}.r#{k} == old(#{g}.r#{k});")
              end
            end
            decl.specifications.each do |spec|
              case spec
              when EnsuresClause, RequiresClause
                spec.replace do |elem|
                  if elem.is_a?(StorageIdentifier) && elem.is_variable? && elem.is_global? then
                    next acc(elem,rounds)
                  end
                  elem
                end
              when ModifiesClause
                spec.replace do |elem|
                  if elem.is_a?(StorageIdentifier) then
                    next (0..rounds-1).map {|k| bpl("#{elem}.r#{k}")}
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

            decl.specifications.each do |spec|
              case spec
              when ModifiesClause
                spec.replace do |elem|
                  if elem.is_a?(StorageIdentifier) then
                    next (0..rounds-1).map {|k| bpl("#{elem}.r#{k}")}
                  end
                  elem
                end
              end
            end
            decl.specifications << bpl("modifies #d;")
            decl.body.declarations << bpl("var #j: int;") \
              if decl.body.any?{|e| e.attributes.include? :yield}

            mods = (decl.modifies & gs).sort

            decl.body.each do |stmt|
              case stmt
              when AssignStatement
                stmt.rhs.each {|rhs| rhs.replace {|elem|
                  if elem.is_a?(StorageIdentifier) &&
                    elem.is_variable? && elem.is_global? &&
                    !excluded_variables.include?(elem.name) then
                    next acc(elem,rounds)
                  end
                  elem
                }}
              when AssumeStatement, AssertStatement
                stmt.replace do |elem|
                  if elem.is_a?(StorageIdentifier) &&
                    elem.is_variable? && elem.is_global? &&
                    !excluded_variables.include?(elem.name) then
                    next acc(elem,rounds)
                  end
                  elem
                end
              when IfStatement
                stmt.condition = stmt.condition.replace do |elem|
                  if elem.is_a?(StorageIdentifier) &&
                    elem.is_variable? && elem.is_global? &&
                    !excluded_variables.include?(elem.name) then
                    next acc(elem,rounds)
                  end
                  elem
                end
              end
            end

            decl.body.replace do |elem|
              case elem
              when CallStatement
                proc = elem.procedure.declaration
                if proc && proc.body
                  elem.arguments << bpl("#k")
                  elem.assignments << bpl("#k")
                elsif proc && !proc.modifies.empty?
                  elem.arguments << bpl("#k")
                end
                next elem

              when AssignStatement
                if elem.lhs.any? {|lhs| lhs.any? {|g|
                  g.is_a?(StorageIdentifier) &&
                  g.is_variable? && g.is_global? &&
                  !excluded_variables.include?(g.name)
                }} then
                  next (0..rounds-1).reduce(nil) do |rest,k|
                    lhs = elem.lhs.map {|lhs| lhs.clone.replace {|elem|
                      if elem.is_a?(StorageIdentifier) &&
                        elem.is_variable? && elem.is_global? &&
                        !excluded_variables.include?(elem.name) then
                        bpl("#{elem}.r#{k}")
                      else
                        elem
                      end
                    }}
                    if rest
                      bpl("if (#k == #{k}) { #{lhs * ", "} := #{elem.rhs * ", "}; } else #{rest}")
                    else
                      bpl("if (true) { #{lhs * ", "} := #{elem.rhs * ", "}; }")
                    end
                  end
                end

              # when StorageIdentifier
              #   if elem.is_variable? && elem.is_global? &&
              #     !excluded_variables.include?(elem.name) then
              #     next acc(elem,rounds)
              #   end

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
                    mods.product((1..rounds-1).entries).map do |g,k|
                      bpl("#{g}.r#{k} := #{g}.r#{k}.0;")
                    end +
                    [elem]

                elsif elem.attributes.include? :endpoint

                  next [elem] +
                    mods.product((1..rounds-1).entries).map do |g,k|
                      bpl("assume #{g}.r#{k}.0 == #{g}.r#{k-1};")
                    end

                end
              end
              elem
            end
          end
        end
      end

    end

    def self.async_to_call! program
      globals = included_variables program
      gs = globals.map{|d| d.idents}.flatten
      return if gs.empty?

      program.declarations << bpl("var #tasks: int;")
      program.declarations += globals.map do |decl|
        bpl "var #{decl.names.map{|g| "#{g}.next"} * ", "}: #{decl.type};"
      end

      program.declarations.each do |decl|
        case decl
        when ProcedureDeclaration
          next unless decl.body

          accs = (decl.accesses & gs).sort
          mods = accs - decl.modifies

          decl.specifications << bpl("modifies #{mods * ", "};") \
            unless mods.empty?
          decl.specifications << bpl("modifies #{accs.map{|g| "#{g}.next"} * ", "};") \
            unless accs.empty?

          # TODO why did I write this?!
          # decl.add_modifies! (gs-mods) \
          #   if decl.body.any?{|s| s.attributes.include? :async}

          decl.specifications << bpl("modifies #tasks;")

          if decl.is_entrypoint?
            decl.body.declarations << bpl("var #t: int;")
            decl.body.declarations += globals.map do |decl|
              bpl "var #{decl.names.map{|g| "#{g}.start"} * ", "}: #{decl.type};"
            end
          else
            decl.parameters << bpl("#t: int")
          end

          if decl.body.any?{|elem| elem.attributes.include?(:async)}
            decl.body.declarations += globals.map do |decl|
              bpl "var #{decl.names.map{|g| ["#{g}.save", "#{g}.guess"]}.flatten * ", "}: #{decl.type};"
            end
          end

          decl.body.replace do |elem|
            case elem
            when AssumeStatement
              if elem.attributes.include? :startpoint
                next [bpl("#tasks := 0;")] +
                  [bpl("#t := 0;")] +
                  accs.map{|g| bpl("#{g}.next := #{g}.start;")} +
                  [elem]

              elsif elem.attributes.include? :endpoint
                next [elem] +
                  accs.map{|g| bpl("assume #{g} == #{g}.start;")} +
                  accs.map{|g| bpl("#{g} := #{g}.next;")}
                elem
              end

            when CallStatement
              proc = elem.procedure.declaration

              if elem.attributes.include? :async then

                var = elem.attributes[:async].first

                elem.attributes.delete :async
                elem.arguments << bpl("#tasks") if proc && proc.body

                # replace the return assignments with dummy assignments
                elem.assignments.map! do |x|
                  elem.parent.fresh_var(x.declaration.type).idents.first
                end

                # make sure to pass the 'save'd version of any globals
                elem.arguments.map! do |e|
                  e.replace do |e|
                    e.is_a?(Identifier) && globals.include?(e.declaration) ? e.save : e
                  end
                end

                call_mods = (proc ? proc.modifies & gs : gs).sort
                call_accs = (proc ? proc.accesses & gs : gs).sort

                # some async-simulating guessing magic
                next call_accs.map{|g| bpl("#{g}.save := #{g};")} +
                  call_accs.map{|g| bpl("#{g} := #{g}.next;")} +
                  call_mods.map{|g| bpl("havoc #{g}.guess;")} +
                  call_mods.map{|g| bpl("#{g}.next := #{g}.guess;")} +
                  [ bpl("#tasks := #tasks + 1;") ] +
                  (var ? [bpl("#{var} := #tasks;")] : []) +
                  [ elem ] +
                  call_mods.map{|g| bpl("assume #{g} == #{g}.guess;")} +
                  call_accs.map{|g| bpl("#{g} := #{g}.save;")}

              else # a synchronous procedure call
                elem.arguments << bpl("#t") if proc && proc.body

              end
            end

            elem
          end
        end
      end
    end
  end

end
