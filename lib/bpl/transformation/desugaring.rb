module Bpl
  module Transformation
    class Desugaring < Bpl::Pass
      def self.description
        "Get rid of structured control flow."
      end

      def run! program
        program.each do |stmt|
          case stmt
          when IfStatement
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
            head = bpl("$HEAD: ")
            body = bpl("$BODY: ")
            exit = bpl("$EXIT: ")

            ## TODO finish this
          end
        end
      end

    end
  end
end
