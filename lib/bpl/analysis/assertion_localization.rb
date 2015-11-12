module Bpl
  module Analysis
    class AssertionLocalization < Bpl::Pass
      def self.description
        "Mark procedures which can reach assertions."
      end

      depends :resolution, :call_graph_construction

      def run! program
        work_list = program.declarations.select do |decl|
          decl.is_a?(ProcedureDeclaration) &&
          decl.any? {|elem| elem.is_a?(AssertStatement)}
        end
        until work_list.empty?
          decl = work_list.shift
          decl.add_attribute :has_assertion
          decl.callers.each do |caller|
            work_list |= [caller] unless caller.has_attribute?(:has_assertion)
          end
        end
      end
    end
  end
end
