module Z3
class ModelParser
macro
  BLANK     \s+
  SL_COM    \*\*\*
  IDENT     [a-zA-Z_.$\#'`~^\\?][\w.$\#'`~^\\?]*
  SYMBOL    [a-zA-Z_.$\#'`~^\\?!@%-\[\]][\w.$\#'`~^\\?!@%-\[\]]*

  OPERATOR  ->|-|\(|\)
  KEYWORD   \b(else)\b

rule
          # {ML_COM_IN}(.|\n)*(?={ML_COM_OUT}){ML_COM_OUT}
          {SL_COM}.*(?=\n)

          # \"[^"]*\"         { [:STRING, text[1..-2]]}

          {BLANK}
          {OPERATOR}        { [text, text] }

          \d+               { [:NUMBER, text.to_i] }
          true|false        { [:BOOLEAN, eval(text)] }

          # \d+bv\d+          { [:BITVECTOR, [text[/(\d+)bv/,1], text[/bv(\d+)/,1]]] }
          # bv\d+\b           { [:BVTYPE, text[2..-1].to_i] }

          {KEYWORD}         { [text, text] }
          # {IDENT}           { [:IDENTIFIER, text.to_sym] }
          {SYMBOL}          { [:SYMBOL, text.to_sym] }

          .                 { [text, text] }
end
end
