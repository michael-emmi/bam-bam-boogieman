# typed: true
module Bpl
  class Atomicity < Pass

    DEFAULT_ATOMIC_ANNOTATION = :atomic

    depends :resolution, :call_graph_construction

    switch "--atomicity", "Locate atomic procedures."
    option :attribute, DEFAULT_ATOMIC_ANNOTATION
    result :atomic, {}

    flag "--atomic-attribute NAME", "Attribute NAME for atomic." do |y, name|
      y.yield :attribute, name
    end

    def has_yield?(proc)
      proc.body && proc.body.any? do |x|
        x.has_attribute? Preemption.options[:attribute]
      end
    end

    def run! program
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
