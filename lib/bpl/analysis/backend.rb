module Bpl
  module AST

    class Program
      
      def prepare_for_backend! verifier
        replace_assertions_with_error_flag! verifier
        add_inline_attributes! if verifier == :boogie_fi
        add_si_record_procedures!
      end
      
      def replace_assertions_with_error_flag! verifier
        use_assertions = (verifier != :boogie_si)
        
        @declarations << bpl("var $e: bool;")
        @declarations.each do |d|
          next unless d.is_a?(ProcedureDeclaration) && d.body
          d.specifications << bpl("modifies $e;")
          d.body.replace do |s|
            case s
            when AssertStatement
              next bpl(<<-end
                if (!#{s.expression}) {
                  $e := true;
                  goto $exit;
                }
              end
              )
            when CallStatement
              next s unless (called = s.declaration) && called.body
              next [ s, bpl("if ($e) { goto $exit; }") ]
            else
              next s
            end
          end
          if d.is_entrypoint? then
            d.body.statements.unshift bpl("$e := false;")
            d.replace do |s|
              next s unless s.is_a?(ReturnStatement)
              next [
                bpl("assume $e;"),
                (bpl("assert false;") if use_assertions),
                s
              ].compact
            end
          end
        end
      end
      
      def add_inline_attributes!
        @declarations.each do |d|
          if d.is_a?(ProcedureDeclaration) && d.body && !d.is_entrypoint?
            d.attributes[:inline] = [bpl("1")]
          end
        end
      end

      def add_si_record_procedures!        
        ["boogie_si_record_int"].each do |proc|
          next if any?{|s| s.is_a?(ProcedureDeclaration) && s.name == proc}
          next unless any?{|s| s.is_a?(CallStatement) && s.procedure.name == proc}
          @declarations << bpl("procedure boogie_si_record_int(x:int);")
        end
      end

    end
  end
end
