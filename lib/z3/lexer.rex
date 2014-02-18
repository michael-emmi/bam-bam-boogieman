class Z3Model
macro
  BLANK     \s+
  # ML_COM_IN    \/\*
  # ML_COM_OUT   \*\/
  # SL_COM       \/\/
  SL_COM    \*\*\*
  IDENT     [a-zA-Z_.$\#'`~^\\?@!%+\[\]:=][\w.$\#'`~^\\?@!%+\[\]:=-]*
  
  OPERATOR  ->|-|\(|\)
  KEYWORD   \belse\b

  # OPERATOR  <==>|==>|\|\||&&|==|!=|<:|<=|<|>=|>|\+\+|\+|-|\*|\/|{:|:=|::|:
  # KEYWORD   \b(assert|assume|axiom|bool|break|bv(\d+)|call|complete|const|else|ensures|exists|false|finite|forall|free|function|goto|havoc|if|implementation|int|invariant|modifies|old|procedure|requires|return|returns|true|type|unique|var|where|while)\b
  
rule
          # {ML_COM_IN}(.|\n)*(?={ML_COM_OUT}){ML_COM_OUT}
          {SL_COM}.*(?=\n)

          # \"[^"]*\"         { [:STRING, text[1..-2]]}

          {BLANK}

          {OPERATOR}        { [text, text] }

          # \d+bv\d+          { [:BITVECTOR, [text[/(\d+)bv/,1], text[/bv(\d+)/,1]]] }
          \d+               { [:NUMBER, text.to_i] }
          true|false        { [:BOOLEAN, eval(text) ]}
          # bv\d+\b           { [:BVTYPE, text[2..-1].to_i] }

          {KEYWORD}         { [text, text] }

          {IDENT}           { [:IDENTIFIER, text.to_sym] }
          .                 { [text, text] }
end