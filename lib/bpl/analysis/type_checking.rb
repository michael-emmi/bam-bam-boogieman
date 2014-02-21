module Bpl
  module AST
    
    class Program
      def type_check
        each do |elem|
          elem.type_check if elem.respond_to? :type_check unless elem == self

          # case elem
          # when FunctionApplication
          #   if d = elem.function.declaration then
          #     unless d.arguments.count == elem.arguments.count && 
          #       d.arguments.zip(elem.arguments).all?{|p,a| p.type == a.type}
          #       warn "incompatible arguments #{elem} to function " +
          #         "#{d.name}(#{d.arguments.map(&:type) * ","})" \
          #     end
          #   end
          # end
        end
      end
    end
    
    class FunctionApplication
      def type_check
        return unless d = @function.declaration
        
        flat_args = d.arguments.map(&:flatten).flatten
        warn "incompatible arguments #{self} to function #{d.signature.split(' returns').first}" \
          unless flat_args.count == @arguments.count &&
            flat_args.zip(@arguments).all?{|p,a| p.type.eql?(a.type)}

      end
    end
      
  end
end