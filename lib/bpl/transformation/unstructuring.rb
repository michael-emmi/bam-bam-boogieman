module Bpl
  module Transformation
    class Unstructuring < Bpl::Pass

      flag "--unstructuring", "Reduce structured control flow."
      # depends :cfg_construction

      def fresh_id
        @id ||= 0
        @id += 1
      end

      def cond(expr, polarity)
        if expr == Expression::Wildcard
          bpl("true")
        elsif polarity
          expr
        else
          bpl("!#{expr}")
        end
      end

      def unstructure_conditional(stmt)
        return unless stmt.is_a?(IfStatement)

        block = stmt.parent
        post = block.statements.chunk{|s| s == stmt}.map{|_,s| s}[2]
        id = fresh_id

        stmt.replace_with(bpl("goto $then.#{id}, $else.#{id};"))
        left = []
        right = []

        left << bpl("$then.#{id}: assume #{cond(stmt.condition,true)};").
          append_children(:statements, *stmt.blocks.first.statements.dup)
        left.push(*stmt.blocks.drop(1))
        left.last.append_children(:statements, bpl("goto $merge.#{id};"))

        right << bpl("$else.#{id}: assume #{cond(stmt.condition,false)};")
        if stmt.else.is_a?(IfStatement)
          right.first.append_children(:statements, stmt.else)
        elsif stmt.else
          right.first.append_children(:statements,
            *stmt.else.first.statements.dup)
          right.push(*stmt.else.drop(1))
        end
        right.last.append_children(:statements, bpl("goto $merge.#{id};"))

        tail = bpl("$merge.#{id}: assume true;").
          append_children(:statements, *post)

        block.insert_after(*left, *right, tail)

        return block.parent
      end

      def unstructure_loop(stmt)
        return unless stmt.is_a?(WhileStatement)

        block = stmt.parent
        post = block.statements.chunk{|s| s == stmt}.map{|_,s| s}[2]
        id = fresh_id

        stmt.replace_with(bpl("goto $head.#{id};"))

        head = bpl("$head.#{id}: goto $body.#{id}, $exit.#{id};").
          prepend_children(:statements,
            *stmt.invariants.reverse.map {|i| bpl("assert #{i.expression};")})

        body = []
        body << bpl("$body.#{id}: assume #{cond(stmt.condition,true)};").
          append_children(:statements, *stmt.blocks.first.statements.dup)
        body.push(*stmt.blocks.drop(1))
        body.last.append_children(:statements, bpl("goto $head.#{id};"))

        exit = bpl("$exit.#{id}: assume #{cond(stmt.condition,false)};").
          append_children(:statements, *post)

        block.insert_after(head, *body, exit)

        return block.parent
      end

      def run! program
        changed = false
        work_list = []
        work_list << program

        until work_list.empty?
          root = work_list.shift
          root.each do |stmt|
            if elem = unstructure_conditional(stmt) || unstructure_loop(stmt)
              changed = true
              work_list.unshift root
              work_list.unshift elem
              break
            end
          end
        end

        changed
      end

    end
  end
end
