module Bpl
  module AST
    class Program
      
      def normalize!
        locate_entrypoints!
        sanity_check
        put_returns_at_the_ends_of_procedures!
        wrap_entrypoint_procedures!
      end
      
      def is_entrypoint?(decl)
        decl.is_a?(ProcedureDeclaration) && decl.attributes.has_key?(:entrypoint)
      end
      
      def locate_entrypoints!
        entrypoints = @declarations.select{|d| is_entrypoint?(d)}
        
        if entrypoints.empty?
          warn "no entry points found; looking for the usual suspects, e.g. main."
          entrypoints = @declarations.select do |d| 
            d.is_a?(ProcedureDeclaration) && d.name =~ /\b[Mm]ain\b/
          end
          entrypoints.each{|d| d.attributes[:entrypoint] = []}
        end

        fail "no entry points found." if entrypoints.empty?
      end
      
      def sanity_check
        each do |elem| 
          case elem
          when CallStatement
            abort "found call to entry point procedure #{elem.procedure}." \
              if is_entrypoint?(elem.procedure.declaration)
          end
        end
      end
      
      def wrap_entrypoint_procedures!
        @declarations.select{|d| is_entrypoint?(d)}.each do |proc|
          if proc.has_body? then
            proc.body.statements.unshift( "assume {:startpoint} true;".parse )
            proc.replace do |elem|
              case elem
              when ReturnStatement
                [ "assume {:endpoint} true;".parse, "return;".parse ]
              else
                elem
              end
            end
          end
        end

      end
      
      def put_returns_at_the_ends_of_procedures!
        @declarations.each do |d|
          if d.is_a?(ProcedureDeclaration) &&
            d.has_body? &&
            !d.body.statements.last.is_a?(GotoStatement) &&
            !d.body.statements.last.is_a?(ReturnStatement)
            d.body.statements << "return;".parse
          end
        end
      end

    end
  end
end
