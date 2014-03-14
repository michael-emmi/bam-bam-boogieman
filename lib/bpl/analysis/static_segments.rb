module Bpl
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
        @declarations << bpl("var #r: int;")
        @declarations << bpl("var $R: [int] int;")
        @declarations << bpl("const $R.0: [int] int;")

        # @declarations << bpl("function $T(int) returns (bool);")
        # @declarations << bpl("function $ord(int,int) returns (bool);")
        # @declarations << bpl("axiom (forall i: int :: $ord(i,i));")
        # @declarations << bpl("axiom (forall i,j: int :: $ord(i,j) && $ord(j,i) ==> i == j);")
        # @declarations << bpl("axiom (forall i,j: int :: $ord(i,j) || $ord(j,i));")
        # @declarations << bpl("axiom (forall i: int :: i >= 0 && i < #S ==> $ord(0,i) && $ord(i,#S));")
        # 
        # @declarations << bpl("function $next(int) returns (int);")
        # @declarations << bpl("axiom (forall i: int :: $ord(i,$next(i)));")
        # @declarations << bpl("axiom (forall i: int :: $next(i) != i);")
        # @declarations << bpl("axiom (forall i,j: int :: $next(i) == $next(j) ==> i == j);")
        # @declarations << bpl("axiom (forall i: int :: i >= 0 && i < #S ==> $next(i) > 0 && $next(i) <= #S );")

        @declarations << bpl("const #S: int;")
        @declarations << bpl("const #DELAYS: int;")
        @declarations << bpl("const #ROUNDS: int;")
        @declarations << bpl("axiom (#S <= 1 + #{threads.count} + #DELAYS);")
        @declarations << bpl("axiom (#S > 0);")
        
        @declarations << bpl("var $X: [int] bool;")
        
        @declarations << bpl("function $T(int) returns (bool);")
        @declarations << bpl("axiom $T(0);")
        @declarations << bpl("axiom (forall s: int :: s > 0 && $T(s) ==> $T(s-1));")
        @declarations << bpl("axiom (forall s: int :: $T(s) ==> s < #S);")
        @declarations << bpl("axiom (forall s: int :: $T(s) ==> s >= 0);")

        @declarations.each do |decl|
          case decl
          when ProcedureDeclaration
            next unless decl.body

            mods = gs - decl.modifies 
            decl.specifications << bpl("modifies #s, #d, $X, #r, $R;")
            decl.specifications << bpl("modifies #{mods * ", "};") unless mods.empty?

            decl.body.replace do |elem|
              case elem
              when AssumeStatement
                if elem.attributes.include? :startpoint
                  next [ 
                    bpl("#s := 0;"),
                    bpl("#d := 0;"),
                    bpl("#r := 0;"),
                    bpl("$R := $R.0;"),
                    bpl("assume $R.0[0] == 0;"),
                    bpl("$R[0] := $R[0] + 1;"),
                    bpl("assume (forall s: int :: {$T(s)} !$X[s]);"),
                    bpl("$X[0] := true;"),
                    elem
                  ]
                  
                elsif elem.attributes.include? :endpoint
                  next [
                    elem,
                    gs.map{|g| bpl("assume #{g} == $S.#{g}[#s+1];")},
                    threads.map do |call|
                      seq_number = call.attributes[:async].first
                      call.attributes.delete :async
                      bpl(<<-end
                        if (true) {
                          havoc #s;
                          #r := 0;
                          assume #s == #{seq_number || "#s"};
                          assume $R[#r] == #s;
                          $R[#r] := $R[#r] + 1;
                          assume $T(#s);
                          assume !$X[#s];
                          $X[#s] := true;
                          #{gs.map{|g| bpl("#{g} := $S.#{g}[#s];")} * "\n"}
                          #{call}
                          #{gs.map{|g| bpl("assume #{g} == $S.#{g}[#s+1];")} * "\n"}
                        }
                      end
                      )
                    end,
                    bpl("assume (forall s: int :: $T(s) ==> $X[s]);"),
                    bpl("assume (forall r: int :: $R.0[r] == $R[r-1]);")
                  ].flatten
                  
                elsif elem.attributes.include? :yield
                  seq_number = elem.attributes[:yield].first
                  next bpl(<<-end
                    if (#{seq_number ? "true" : "*"}) {
                      assume #d < #DELAYS;
                      #{gs.map{|g| bpl("assume #{g} == $S.#{g}[#s+1];")} * "\n"}
                      #d := #d + 1;
                      #r := #r + 1;
                      havoc #s;
                      assume #s == #{seq_number || "#s"};
                      assume $R[#r] == #s;
                      $R[#r] := $R[#r] + 1;
                      assume $T(#s);
                      assume !$X[#s];
                      $X[#s] := true;
                      #{gs.map{|g| bpl("#{g} := $S.#{g}[#s];")} * "\n"}
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
