module Bpl
  class Unrolling < Pass

    flag "--unrolling BOUND", Integer, "Unroll loops." do |n|
      option :bound, n
    end
    depends :unstructuring
    depends :loop_identification

    def unroll(head, looop, count)
      names = Set.new(looop.map(&:names).flatten)
      blocks = (count+1).times.map {looop.map(&:copy)}
      blocks.each_with_index do |bs, i|
        bs.each do |b|
          b.instance_variable_set("@names",
            b.names.map {|n| "#{n}.unroll.#{i}"})
          b.each do |id|
            if id.is_a?(LabelIdentifier) && names.include?(id.name)
              if id.name == head.name && i < count
                id.replace_with(LabelIdentifier.new(name: "#{id}.unroll.#{i+1}"))
              elsif id.name == head.name
                id.parent.parent.replace_children(:statements,
                  bpl("assume false;"))
              else
                id.replace_with(LabelIdentifier.new(name: "#{id}.unroll.#{i}"))
              end
            end
          end
        end
      end
      head.bindings.each do |id|
        id.replace_with(LabelIdentifier.new(name: "#{id.name}.unroll.0"))
      end
      blocks.flatten
    end

    def run! program
      loop_identification.loops.each do |head, looop|
        looop.to_a.last.insert_after(*unroll(head, looop, bound))
        looop.each(&:remove)
        invalidates :all
      end
    end
  end
end
