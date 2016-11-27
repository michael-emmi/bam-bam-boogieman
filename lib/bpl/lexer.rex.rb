#--
# DO NOT MODIFY!!!!
# This file is automatically generated by rex 1.0.5
# from lexical definition file "lexer.rex".
#++

require 'racc/parser'
module Bpl
  IDENTIFIER = /[a-zA-Z_.$\#'`~^\\?][\w.$\#'`~^\\?]*/
end

class BoogieLanguage < Racc::Parser
  require 'strscan'

  class ScanError < StandardError ; end

  attr_reader   :lineno
  attr_reader   :filename
  attr_accessor :state

  def scan_setup(str)
    @ss = StringScanner.new(str)
    @lineno =  1
    @state  = nil
  end

  def action
    yield
  end

  def scan_str(str)
    scan_setup(str)
    do_parse
  end
  alias :scan :scan_str

  def load_file( filename )
    @filename = filename
    open(filename, "r") do |f|
      scan_setup(f.read)
    end
  end

  def scan_file( filename )
    load_file(filename)
    do_parse
  end


  def next_token
    return if @ss.eos?
    
    # skips empty actions
    until token = _next_token or @ss.eos?; end
    token
  end

  def _next_token
    text = @ss.peek(1)
    @lineno  +=  1  if text == "\n"
    token = case @state
    when nil
      case
      when (text = @ss.scan(/\$\$PARSE_DECL\$\$/))
         action { [:PARSE_DECL, ""] }

      when (text = @ss.scan(/\$\$PARSE_PARAM\$\$/))
         action { [:PARSE_PARAM, ""] }

      when (text = @ss.scan(/\$\$PARSE_SPEC\$\$/))
         action { [:PARSE_SPEC, ""] }

      when (text = @ss.scan(/\$\$PARSE_BLOCKS\$\$/))
         action { [:PARSE_BLOCKS, ""] }

      when (text = @ss.scan(/\$\$PARSE_STMT\$\$/))
         action { [:PARSE_STMT, ""] }

      when (text = @ss.scan(/\$\$PARSE_EXPR\$\$/))
         action { [:PARSE_EXPR, ""] }

      when (text = @ss.scan(/\$\$PARSE_TYPE\$\$/))
         action { [:PARSE_TYPE, ""] }

      when (text = @ss.scan(/\/\*((?!\*\/)(.|\n))*\*\//))
        ;

      when (text = @ss.scan(/\/\/.*(?=\n)/))
        ;

      when (text = @ss.scan(/\"[^"]*\"/))
         action { [:STRING, text[1..-2]]}

      when (text = @ss.scan(/\s/))
        ;

      when (text = @ss.scan(/<==>|==>|\|\||&&|==|!=|<:|<=|<|>=|>|\+\+|\+|-|\*|\/|{:|:=|::|:|\|/))
         action { [text, text] }

      when (text = @ss.scan(/\d+bv\d+/))
         action { [:BITVECTOR, {value: text[/(\d+)bv/,1].to_i, base: text[/bv(\d+)/,1].to_i}] }

      when (text = @ss.scan(/\d+/))
         action { [:NUMBER, text.to_i] }

      when (text = @ss.scan(/bv\d+\b/))
         action { [:BVTYPE, text[2..-1].to_i] }

      when (text = @ss.scan(/\b(assert|assume|axiom|bool|break|bv(\d+)|call|complete|const|else|ensures|exists|false|finite|forall|free|function|goto|havoc|if|implementation|int|invariant|modifies|old|procedure|requires|return|returns|then|true|type|unique|var|where|while)\b(?![\w.$\#'`~^\\?])/))
         action { [text, Token.new(lineno)] }

      when (text = @ss.scan(/[a-zA-Z_.$\#'`~^\\?][\w.$\#'`~^\\?]*/))
         action { [:IDENTIFIER, text] }

      when (text = @ss.scan(/./))
         action { [text, text] }

      else
        text = @ss.string[@ss.pos .. -1]
        raise  ScanError, "can not match: '" + text + "'"
      end  # if

    else
      raise  ScanError, "undefined state: '" + state.to_s + "'"
    end  # case state
    token
  end  # def _next_token

end # class
