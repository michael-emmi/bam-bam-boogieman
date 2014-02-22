module Bpl
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
        warn "incompatible arguments (#{@arguments * ","}) to function #{d.signature}" \
          unless params.count == @arguments.count &&
          params.zip(@arguments).all?{|p,a| p.type.eql?(a.type)}

      end
    end

    class CallStatement
      def type_check
        return unless d = @procedure.declaration
        
        params = d.parameters.map(&:flatten).flatten
        warn "incompatible arguments (#{@arguments * ","}) to procedure #{d.signature}" \
          unless params.count == @arguments.count &&
          params.zip(@arguments).all?{|p,a| p.type.eql?(a.type)}
          
        rets = d.returns.map(&:flatten).flatten
        warn "incompatible assignments #{@assignments * ","} from procedure #{d.signature}" \
          unless rets.count == @assignments.count &&
          rets.zip(@assignments).all?{|r,a| r.type.eql?(a.type)}
      end
    end
  end
end