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
        
        @declarations << bpl("var #e: bool;")
        @declarations.each do |d|
          next unless d.is_a?(ProcedureDeclaration) && d.body
          d.specifications << bpl("modifies #e;")
          d.body.replace do |s|
            s.is_a?(AssertStatement) ? bpl("#e := #e || !(#{s.expression});") : s
          end
          if d.is_entrypoint? then
            d.body.statements.unshift bpl("#e := false;")
            d.replace do |s|
              if s.is_a?(ReturnStatement) then
                 [bpl("assume #e;")] + 
                 (use_assertions ? [bpl("assert false;")] : []) + 
                 [s]
              else
                s
              end
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
        @declarations << bpl("procedure boogie_si_record_int(x:int);") \
          if any?{|s| s.is_a?(CallStatement) && s.procedure.name == "boogie_si_record_int"}
      end

    end
  end
end
