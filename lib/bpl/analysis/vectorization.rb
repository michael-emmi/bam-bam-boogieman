
module Bpl
  module AST
        
    class Program

      def vectorize! # (rounds,delays)
        
        gs = global_variables.map{|d| d.idents}.flatten        
        return if gs.empty?
        
        @declarations << bpl("const #ROUNDS: int;")
        @declarations << bpl("const #DELAYS: int;")
        # @declarations << bpl("axiom #ROUNDS == #{rounds};")
        # @declarations << bpl("axiom #DELAYS == #{delays};")
        @declarations += global_variables.map do |decl|
          type = decl.type
          decl.type = bpl_type("[int] #{type}")
          bpl "const #{decl.names.map{|g| "#{g}.0"} * ", "}: [int] #{type};"
        end
        @declarations << bpl("var #d: int;")

        @declarations.each do |decl|
          case decl
          when ProcedureDeclaration
            
            if !decl.body && !decl.modifies.empty?
              decl.parameters << bpl("#k: int")
              decl.modifies.each do |x|
                decl.specifications << 
                  bpl("ensures (forall k: int :: k != #k ==> #{x}[k] == old(#{x})[k]);")
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
                decl.body.statements.unshift bpl("call boogie_si_record_int(#k);")
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
                  if elem.is_variable? && elem.is_global? then
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
                        call boogie_si_record_int(#k);
                      }
                    end
                    )
                    
                  elsif elem.attributes.include? :startpoint

                    next [ bpl("#d := 0;"),
                      bpl("#k := 0;"),
                      bpl("call boogie_si_record_int(#ROUNDS);"),
                      bpl("call boogie_si_record_int(#DELAYS);") ] +
                      mods.map{|g| bpl("#{g} := #{g}.0;")} +
                      [elem]

                  elsif elem.attributes.include? :endpoint

                    # NEW VERSION -- independent of rounds bound.
                    next [elem] +
                      mods.map do |g|
                        bpl(<<-end
                        assume (forall i: int ::
                          {#{g}.0[i]} {#{g}[i-1]}
                          i > 0 && i <= #ROUNDS ==> #{g}[i-1] == #{g}.0[i]
                        );
                      end
                      ) end

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

    end
  end
end
