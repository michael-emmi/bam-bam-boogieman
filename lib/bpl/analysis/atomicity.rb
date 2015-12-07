module Bpl
  module Analysis
    class Atomicity < Bpl::Pass

      DEFAULT_ATOMIC_ANNOTATION = :atomic

      depends :resolution, :call_graph_construction

      flag "--atomicity", "Locate atomic procedures."
      option :attribute, DEFAULT_ATOMIC_ANNOTATION
      result :atomic, {}

      flag "--atomic-attribute NAME", "Attribute NAME for atomic." do |name|
        option :attribute, name
      end

      def has_yield?(proc)
        proc.body && proc.body.any? {|x| x.has_attribute? :yield}
      end

      def run! program
        atomic.clear
        work_list = []
        program.declarations.each do |proc|
          next unless proc.is_a?(ProcedureDeclaration)
          atomic[proc] = proc.has_attribute?(attribute) || !has_yield?(proc)
          work_list << proc unless atomic[proc]
        end

        until work_list.empty?
          decl = work_list.shift
          sources = Set.new(call_graph_construction.callers[decl])
          sources << decl.declaration if decl.is_a?(ImplementationDeclaration)
          sources.each do |p|
            next unless atomic[p]
            atomic[p] = false
            work_list |= [p]
          end

        end
      end

    end
  end
end
