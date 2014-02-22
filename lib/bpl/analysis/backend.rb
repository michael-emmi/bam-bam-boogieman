module Bpl
  module AST

    class Program
      
      def prepare_for_backend! verifier
        replace_assertions_with_error_flag! verifier
        add_inline_attributes! if verifier == :boogie_fi
      end
      
      def replace_assertions_with_error_flag! verifier
        use_assertions = (verifier != :boogie_si)
        
        @declarations << "var #e: bool;".parse
        @declarations.each do |d|
          next unless d.is_a?(ProcedureDeclaration) && d.has_body?
          d.specifications << "modifies #e;".parse
          d.replace do |s|
            s.is_a?(AssertStatement) ? "#e := #e || !(#{s.expression});".parse : s
          end
          if d.is_entrypoint? then
            d.body.statements.unshift("#e := false;".parse)
            d.replace do |s|
              if s.is_a?(ReturnStatement) then
                 ["assume #e;".parse] + 
                 (use_assertions ? ["assert false;".parse] : []) + 
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
          next unless d.is_a?(ProcedureDeclaration) && d.has_body?
          next if d.is_entrypoint?
          d.attributes[:inline] = ["1".parse]
        end
      end

    end
  end
end
