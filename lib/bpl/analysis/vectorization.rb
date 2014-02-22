
module Bpl
  module AST
    class Program

      def vectorize!(rounds,delays)

        replace do |elem|
          case elem
          # when Identifier
          #   if elem.is_variable? && elem.is_global? then
          #     "#{expr}[k]".parse
          #   else
          #     elem
          #   end

          when AssumeStatement
            if elem.attributes.include? :yield then
              elem.attributes.delete :yield
              # TODO translate the yield...

            end
            elem

          else
            elem
          end
        end

      end

    end
  end
end
