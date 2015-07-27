module Bpl
  module Transformation
    class StaticSegments < Bpl::Pass
      def self.description
        "I don’t know what this does."
      end

      def run! program
      end
    end
  end

  module AST
    class Program
      def static_segments_sequentialize!

        globals = global_variables
        gs = globals.map{|d| d.idents}.flatten
        return if gs.empty?

        threads = []
        @declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration) && proc.body
          proc.replace do |call|
            next call unless call.is_a?(CallStatement) && \
              call.attributes.include?(:async)
            abort "static thread creation only allowed in entry points." \
              unless proc.is_entrypoint?
            threads << call
            nil
          end
        end

        @declarations << bpl("var #s: int;")
        @declarations << bpl("var #d: int;")
        @declarations += globals.map do |decl|
          bpl "const #{decl.names.map{|g| "$S.#{g}"} * ", "}: [int] #{decl.type};"
        end

        @declarations << bpl("function $pos(int) returns (int);")
        @declarations << bpl("axiom $pos(0) == 0;")
        @declarations << bpl("axiom (forall i: int :: i > 0 ==> $pos(i) > 0);")
        @declarations << bpl("axiom (forall i: int :: i < #S ==> $pos(i) < #S);")
        @declarations << bpl("axiom (forall i,j: int :: $pos(i) == $pos(j) ==> i == j);")

        @declarations << bpl("const #S: int;")
        @declarations << bpl("const #DELAYS: int;")
        @declarations << bpl("const #ROUNDS: int;")

        @declarations.each do |decl|
          case decl
          when ProcedureDeclaration
            next unless decl.body

            mods = gs - decl.modifies
            decl.specifications << bpl("modifies #s, #d;")
            decl.specifications << bpl("modifies #{mods * ", "};") unless mods.empty?

            decl.body.replace do |elem|
              case elem
              when AssumeStatement
                if elem.attributes.include? :startpoint
                  next [
                    bpl("#s := 0;"),
                    bpl("#d := 0;"),
                    elem
                  ]

                elsif elem.attributes.include? :endpoint
                  next [
                    elem,
                    gs.map{|g| bpl("assume #{g} == $S.#{g}[$pos(#s)+1];")},
                    threads.map.with_index do |call,i|
                      seq_number = call.attributes[:async].first
                      call.attributes.delete :async
                      bpl(<<-end
                        if (true) {
                          #s := #s + 1;
                          assume $pos(#s) == #{seq_number || "#s-#d"};
                          #{gs.map{|g| bpl("#{g} := $S.#{g}[$pos(#s)];")} * "\n"}
                          #{call}
                          #{gs.map{|g| bpl("assume #{g} == $S.#{g}[$pos(#s)+1];")} * "\n"}
                        }
                      end
                      )
                    end,
                    bpl("assume #s+1 == #S;")
                  ].flatten

                elsif elem.attributes.include? :yield
                  seq_number = elem.attributes[:yield].first
                  next bpl(<<-end
                    if (#{seq_number ? "true" : "*"}) {
                      assume #d < #DELAYS;
                      #{gs.map{|g| bpl("assume #{g} == $S.#{g}[$pos(#s)+1];")} * "\n"}
                      assume $pos(#s) < $pos(#s+1);
                      #d := #d + 1;
                      #s := #s + 1;
                      // Q: how to determine the scheduler here?
                      assume $pos(#s) == #{seq_number || "$pos(#s)"};
                      #{gs.map{|g| bpl("#{g} := $S.#{g}[$pos(#s)];")} * "\n"}
                    }
                  end
                  )

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
