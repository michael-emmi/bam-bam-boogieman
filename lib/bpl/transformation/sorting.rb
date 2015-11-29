module Bpl
  module Transformation
    class Sorting < Bpl::Pass
      def self.description
        "Sort declarations."
      end

      def type_order(d,e)
        return 0 if d.class == e.class
        res = [ TypeDeclaration,
          ConstantDeclaration,
          VariableDeclaration,
          AxiomDeclaration,
          FunctionDeclaration,
          ProcedureDeclaration,
          ImplementationDeclaration
        ].each do |c|
          break -1 if d.is_a?(c)
          break 1 if e.is_a?(c)
        end
        return 0 if res.is_a?(Array)
        return res
      end

      def order(d,e)
        res = type_order(d, e)
        return res unless res == 0
        return d.names.first <=> e.names.first unless d.names.empty?
        return d.to_s <=> e.to_s
      end

      def run! program
        program.declarations.each do |d|
          next unless d.is_a?(ProcedureDeclaration)
          next unless d.body
          d.body.replace_children(:locals,
            d.body.locals.sort {|d1,d2| order(d1,d2)})
        end
        program.replace_children(:declarations,
          program.declarations.sort {|d,e| order(d,e)})
      end
    end
  end
end
