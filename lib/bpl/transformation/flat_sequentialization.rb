module Bpl
  module Transformation
    class FlatSequentialization < Bpl::Pass

      def self.description
        "I don’t know what this does."
      end

      option :rounds, "the number of rounds"
      option :delays, "the number of delays"
      option :unroll, "the unrolling depth"

      def sequentialize! program
        globals = program.global_variables
        gs = globals.map{|d| d.idents}.flatten

        timed("wrapping") do
          wrap_async_calls! program
        end
        timed("adding inline attributes") do
          Bpl::Analysis::add_inline_annotations! program, @unroll
        end
        timed("inlining") do
          program.declarations = Bpl::Analysis::inline(program).declarations
        end
        timed("duplicating") do
          duplicate_blocks! program
        end
        timed("adding jumps & constraints") do
          add_jumps! program
          add_round_constraints! program, gs
        end
        timed("resolution") do
          Bpl::Analysis::resolve! program
        end
        timed("modifies correction") do
          Bpl::Analysis::correct_modifies! program
        end
        timed("async to call") do
          async_to_call! program
        end
        timed("resolution") do
          Bpl::Analysis::resolve! program
        end
        timed("modifies correction") do
          Bpl::Analysis::correct_modifies! program
        end
      end

      def wrap_async_calls! program
        program.replace do |elem|
          case elem
          when CallStatement
            if elem.attributes.include?(:async)
              elem.attributes.delete :async

              # replace the return assignments with dummy assignments
              elem.assignments.map! do |x|
                elem.parent.fresh_var(x.declaration.type)
              end

              # make sure to pass the 'save'd version of any globals
              elem.arguments.map! do |e|
                e.replace do |e|
                  e.is_a?(Identifier) && globals.include?(e.declaration) ? e.save : e
                end
              end

              next [ bpl("assume {:pause} #round == #round;"),
                elem, bpl("assume {:resume} #round == #round;") ]
            end
          when AssumeStatement
            if elem.attributes.include?(:yield)
              next bpl("assume {:jump} true;")
            end
          when ReturnStatement
            next [ bpl("assume {:isreturn} true;"), elem ]
          when ProcedureDeclaration
            elem.body.declarations << bpl("var #round: int;") if elem.body
          end
          elem
        end
      end

      def is_global?(g) g.is_a?(StorageIdentifier) && g.is_variable? && g.is_global? end
      def index(g,i) is_global?(g) ? bpl("#{g}.r#{i}") : g end

      def duplicate_blocks! program

        # first clone the blocks...
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)

          unless proc.body || proc.is_entrypoint?
            proc.parameters << bpl("#k: int")
            proc.specifications.select{|s| s.is_a?(EnsuresClause)}.each do |s|
              next unless s.any? {|g| is_global?(g)}
              proc.specifications.delete s
              (0..@rounds-1).map do |i|
                spec = bpl("ensures #k != #{i} || #{s.expression};")
                spec.replace do |elem|
                  case elem
                  when StorageIdentifier
                    var = program.resolve(elem)
                    next bpl("#{elem}.r#{i}") if var && var.is_a?(VariableDeclaration)
                  end
                  elem
                end
                proc.specifications << spec
              end
            end
            proc.modifies.each do |g|
              (0..@rounds-1).map do |k|
                proc.specifications <<
                  bpl("ensures #k == #{k} || #{g}.r#{k} == old(#{g}.r#{k});")
              end
            end
          end

          mods = proc.specifications.select{|m| m.is_a?(ModifiesClause)}
          proc.specifications -= mods
          (0..@rounds-1).each do |i|
            proc.specifications += mods.map do |m|
              bpl("modifies #{m.identifiers.map{|id| "#{id}.r#{i}"} * ", "};")
            end
          end

          next unless proc.body

          copies = (1..@rounds).map { bpl("#{proc}") } # "clone"
          copies.each_with_index do |copy,i|

            isStartBlock = false
            isEndBlock = false

            copy.replace do |elem|
              case elem
              when StorageIdentifier
                var = program.resolve(elem)
                next bpl("#{elem}.r#{i}") if var && var.is_a?(VariableDeclaration)
              when Label
                next Label.new(name: "#{elem}.r#{i}")
              when LabelIdentifier
                next LabelIdentifier.new(name: "#{elem}.r#{i}")
              when AssumeStatement
                elem.attributes[:pause] = [i] if elem.attributes.include?(:pause)
                elem.attributes[:resume] = [i] if elem.attributes.include?(:resume)
                isStartBlock ||= elem.attributes.include?(:startpoint)
                isEndBlock ||= elem.attributes.include?(:endpoint)
              when GotoStatement
                isStartBlock = isEndBlock = false
              when ReturnStatement
                if isEndBlock && i < @rounds-1
                  isEndBlock = false
                  next bpl("goto $exit.r#{@rounds-1};")
                end
              when CallStatement # only the bodiless procedures (not inlined)
                elem.arguments << bpl("#{i}")
              end
              next nil if isStartBlock && i > 0 || isEndBlock && i < @rounds-1
              elem
            end
          end
          proc.body.statements = copies.map{|copy| copy.body.statements}.flatten
        end

        # then clone the variables
        program.declarations.each do |decl|
          next unless decl.is_a?(VariableDeclaration)
          inits = decl.names.product((1..@rounds-1).to_a).map{|name,i| "#{name}.r#{i}.0"}
          program.declarations << bpl("const #{inits * ", "}: #{decl.type};") unless inits.empty?
          decl.names = decl.names.product((0..@rounds-1).to_a).map{|name,i| "#{name}.r#{i}"}
        end
      end

      def add_jumps! program
        # program.declarations << bpl("var #d: int;")
        # program.declarations << bpl("const #DELAYS: int;")
        isReturn = false
        isJump = false
        program.replace do |elem|
          case elem
          when AssumeStatement
            var = elem.find{|x| x.is_a?(StorageIdentifier)}
            if elem.attributes.include?(:pause)
              next [
                bpl("#{var} := #{elem.attributes[:pause].first};"),
                bpl("assume {:pause} true;")
              ]
            elsif elem.attributes.include?(:resume)
              next [
                bpl("assume {:resume} true;"),
                bpl("assume #{var} == #{elem.attributes[:resume].first};")
              ]
            end
            isReturn = elem.attributes.include?(:isreturn)
            isJump = elem.attributes.include?(:jump)
            next nil if isReturn # || isJump
          when GotoStatement
            if isReturn
              elem.identifiers = elem.identifiers.map do |id|
                name, k = /^(.*)\.r(\d+)$/.match(id.name).to_a.drop(1)
                (0..k.to_i).map{|i| LabelIdentifier.new(name: "#{name}.r#{i}")}
              end.flatten
            elsif isJump
              elem.identifiers = elem.identifiers.map do |id|
                name, k = /^(.*)\.r(\d+)$/.match(id.name).to_a.drop(1)
                (k.to_i..@rounds-1).map{|i| LabelIdentifier.new(name: "#{name}.r#{i}")}
              end.flatten
            end
            isReturn = isJump = false
          when Statement
            isReturn = isJump = false
          end
          elem
        end
      end

      def add_round_constraints! program, gs
        program.replace do |elem|
          case elem
          when AssumeStatement
            if elem.attributes.include? :startpoint
              next [ gs.product((1..@rounds-1).to_a).map do |g,i|
                bpl("assume #{g}.r#{i}.0 == #{g}.r#{i};")
              end, elem ]
            elsif elem.attributes.include? :endpoint
              next [ elem, gs.product((1..@rounds-1).to_a).map do |g,i|
                bpl("assume #{g}.r#{i}.0 == #{g}.r#{i-1};")
              end ]
            end
          end
          elem
        end
      end

    end
  end
end
