module Bpl
  module Analysis
    class AssertionLocalization < Bpl::Pass

      depends :resolution, :call_graph_construction
      flag "--assertion-localization", "Mark assertion-reaching procedures."
      result :has_assert, {}

      def run! program
        work_list = []
        program.declarations.each do |decl|
          next unless decl.is_a?(ProcedureDeclaration)
          has_assert[decl] = decl.any? {|elem| elem.is_a?(AssertStatement)}
          work_list << decl if has_assert[decl]
        end
        until work_list.empty?
          decl = work_list.shift
          has_assert[decl] = true
          call_graph_construction.callers[decl].each do |caller|
            work_list |= [caller] unless has_assert[caller]
          end
        end
      end
    end
  end
end
