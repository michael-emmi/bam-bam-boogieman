module Bpl
  module Transformation
    class Unstructuring < Bpl::Pass

      flag "--unstructuring", "Reduce structured control flow."
      # depends :cfg_construction

      def run! program
        changed = false
        id = 0
        # cfg = cfg_construction
        program.each do |stmt|
          case stmt
          when IfStatement
            next # TODO translate this

            block = stmt.block
            body = block.body
            idx = block.index(stmt)
            new_blocks = []

            ## TODO REsTRuCTURE, AND USE UNIQUE NAMES

            then_block = stmt.blocks.first
            then_block.unshift bpl("assume #{stmt.condition};", scope: stmt)
            then_block.names << "$IF" if then_block.names.empty?
            stmt.blocks.last << bpl("goto $CONTINUE;")
            new_blocks += stmt.blocks

            case stmt.else
            when IfStatement
            when Enumerable
            else
              new_blocks << bpl(<<-END)
              $ELSE:
                assume !#{stmt.condition};
                goto $CONTINUE;
              END
            end

            new_blocks << continue_block = bpl("$CONTINUE: ")

            stmt.replace_with bpl("goto $IF, $ELSE;", scope: stmt)
            block[idx+1..-1].each do |stmt|
              continue_block << stmt
              block.delete(stmt)
            end

            block.insert_after *new_blocks

          when WhileStatement
            block = stmt.parent
            _, _, post = block.statements.chunk{|s| s == stmt}.map{|_,s| s}

            stmt.replace_with(bpl("goto $head.#{id};"))
            stmt.blocks.first.prepend_children(:statements,
              bpl("assume #{stmt.condition};")
            )
            stmt.blocks.last.append_children(:statements,
              bpl("goto $head.#{id};")
            )
            head = Block.new(names: ["$head.#{id}"], statements: [])
            body = Block.new(names: ["$body.#{id}"] + stmt.blocks.first.names,
              statements: stmt.blocks.first.statements)
            tail = Block.new(names: ["$post.#{id}"], statements: [])

            head.append_children(:statements,
              *stmt.invariants.map {|i| bpl("assert #{i.expression};")},
              bpl("goto $body.#{id}, $post.#{id};"))

            tail.append_children(:statements,
              bpl("assume !#{stmt.condition};"),
              *post)

            block.insert_after(head, body, *stmt.blocks.drop(1), tail)

            id += 1
            changed = true
          end
        end

        changed
      end

    end
  end
end
