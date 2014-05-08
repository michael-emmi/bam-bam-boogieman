module Bpl
  module Analysis
    def self.flat_sequentialize! program, rounds, delays, unroll
      wrap_async_calls! program
      add_inline_annotations! program, unroll
      program.declarations = inline(program).declarations
      duplicate_blocks! program, rounds
      add_jumps! program, rounds
      resolve! program
      correct_modifies! program
      puts program.inspect
    end
    
    def self.wrap_async_calls! program
      program.replace do |elem|
        case elem
        when CallStatement
          if elem.attributes.include?(:async)
            elem.attributes.delete :async
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
          elem.body.declarations << bpl("var #round: int;")
        end
        elem
      end
    end
    
    def self.duplicate_blocks! program, rounds
      program.declarations.each do |decl|
        case decl
        when VariableDeclaration
          decl.names = decl.names.product((0..rounds-1).to_a).map{|name,i| "#{name}.r#{i}"}

        when ProcedureDeclaration
          
          mods = decl.specifications.select{|m| m.is_a?(ModifiesClause)}
          decl.specifications -= mods
          (0..rounds-1).each do |i|
            decl.specifications += mods.map do |m|
              bpl("modifies #{m.identifiers.map{|id| "#{id}.r#{i}"} * ", "};")
            end
          end

          next unless decl.body

          copies = (1..rounds).map { bpl("#{decl}") } # "clone"
          copies.each_with_index do |copy,i|

            isStartBlock = false

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
              when GotoStatement
                isStartBlock = false
              end
              next nil if isStartBlock && i > 0
              elem
            end
          end
          decl.body[0].statements = copies.map{|copy| copy.body[0].statements}.flatten
        end
      end
    end

    def self.add_jumps! program, rounds
      isReturn = false
      isJump = false
      program.replace do |elem|
        case elem
        when AssumeStatement
          var = elem.find{|x| x.is_a?(StorageIdentifier)}
          next bpl("#{var} := #{elem.attributes[:pause].first};") \
            if elem.attributes.include?(:pause)
          next bpl("assume #{var} == #{elem.attributes[:resume].first};") \
            if elem.attributes.include?(:resume)
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
              (k.to_i..rounds-1).map{|i| LabelIdentifier.new(name: "#{name}.r#{i}")}
            end.flatten
          end
          isReturn = isJump = false
        when Statement
          isReturn = isJump = false
        end
        elem
      end
    end

  end
end
