
module Bpl
  module AST
    class Program

      def vectorize!
        n = 4

        replace do |expr|
          if expr.is_a?(Identifier) && expr.is_variable? && expr.is_global? then
            "#{expr}[k]".parse
          else
            expr
          end
        end

      end

    end
  end
end
