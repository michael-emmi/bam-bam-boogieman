module Bpl
  module Analysis
    class TypeChecking < Bpl::Pass
      def self.description
        "Ensure correct typing."
      end

      def run! program
        program.each {|elem| elem.type_check if elem.respond_to?(:type_check)}
      end
    end
  end

  module AST
    class FunctionApplication
      def type_check
        return unless d = @function.declaration

        params = d.arguments # .map(&:flatten).flatten
        unless params.count == arguments.count
          warn "wrong number of arguments to function #{d.signature}" \
            "\n  #{hilite.underline}"
        end

        arguments.each.with_index do |a,i|
          break unless i < params.count
          unless params[i].type.expand.to_s == a.type.expand.to_s
            warn "invalid type for argument #{i} in application of #{d.signature}" \
              "\n  #{hilite.underline}"
          end
        end

      end
    end

    class CallStatement
      def type_check
        return unless d = @procedure.declaration

        params = d.parameters # .map(&:flatten).flatten
        rets = d.returns # .map(&:flatten).flatten

        unless params.count == arguments.count
          warn "wrong number of arguments in call of #{d.signature}" \
            "\n  #{hilite.underline}"
        end

        arguments.each.with_index do |a,i|
          break unless i < params.count
          unless params[i].type.expand.to_s == a.type.expand.to_s
            warn "invalid type for argument #{i} in call of #{d.signature}" \
              "\n  #{hilite.underline}"
          end
        end

        unless rets.count == assignments.count
          warn "wrong number of return assignments in call of #{d.signature}" \
            "\n  #{hilite.underline}"
        end

        assignments.each.with_index do |a,i|
          break unless i < rets.count
          unless rets[i].type.expand.to_s == a.type.expand.to_s
            warn "invalid type for return assignment #{i} in call of #{d.signature}" \
              "\n  #{hilite.underline}"
          end
        end

      end
    end

  end
end
