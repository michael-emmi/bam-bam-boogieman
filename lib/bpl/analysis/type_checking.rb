module Bpl
  module AST
    
    class Program
      def type_check
        each do |elem|
          case elem
          when FunctionApplication
            if d = elem.function.declaration then
              unless d.arguments.count == elem.arguments.count && 
                d.arguments.zip(elem.arguments).all?{|p,a| p.type == a.type}
                warn "incompatible arguments #{elem} to function " +
                  "#{d.name}(#{d.arguments.map(&:type) * ","})" \
              end
            end
          end
        end
      end
    end
    
    class FunctionApplication
      def type_check?
        return unless d = @function.declaration
        d.arguments.count == @arguments.count &&
        d.arguments.zip(@arguments).all? do |p,a| p.type == a.type end        
      end
    end
      
  end
end