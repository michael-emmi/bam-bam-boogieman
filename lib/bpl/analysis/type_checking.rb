module Bpl
  module Analysis
    class TypeChecking < Bpl::Pass
      def self.description
        "Ensure correct typing."
      end

      def run! program
        program.type_check
      end
    end
  end

  module AST
    class Program
      def type_check
        each {|e| e.type_check if e.respond_to? :type_check unless e == self}
      end
    end

    class FunctionApplication
      def type_check
        return unless d = @function.declaration

        params = d.arguments.map(&:flatten).flatten
        unless params.count == @arguments.count &&
        params.zip(@arguments).all?{|p,a| p.type.eql?(a.type)}
          warn "incompatible arguments (#{@arguments * ","}) to function #{d.signature}\n  #{inspect}\n\n"
        end
      end
    end

    class CallStatement
      def type_check
        return unless d = @procedure.declaration

        params = d.parameters.map(&:flatten).flatten
        unless params.count == @arguments.count &&
        params.zip(@arguments).all?{|p,a| p.type.eql?(a.type)}
          warn "incompatible arguments (#{@arguments * ","}) to procedure #{d.signature}:\n  #{inspect}\n\n"
        end

        rets = d.returns.map(&:flatten).flatten
        unless rets.count == @assignments.count &&
        rets.zip(@assignments).all?{|r,a| r.type.eql?(a.type)}
          warn "incompatible assignments (#{@assignments * ","}) from procedure #{d.signature}:\n  #{inspect}\n\n"
        end
      end
    end
  end
end
