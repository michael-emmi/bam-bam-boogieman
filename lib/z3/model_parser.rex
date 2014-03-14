module Z3
class ModelParser
macro
  BLANK     \s+
  SL_COM    \*\*\*
  IDENT     [a-zA-Z_.$\#'`~^\\?][\w.$\#'`~^\\?]*

  OPERATOR  ->|-|\(|\)
  KEYWORD   \belse\b

  # OPERATOR  <==>|==>|\|\||&&|==|!=|<:|<=|<|>=|>|\+\+|\+|-|\*|\/|{:|:=|::|:
  # KEYWORD   \b(assert|assume|axiom|bool|break|bv(\d+)|call|complete|const|else|ensures|exists|false|finite|forall|free|function|goto|havoc|if|implementation|int|invariant|modifies|old|procedure|requires|return|returns|true|type|unique|var|where|while)\b
  
rule
          # {ML_COM_IN}(.|\n)*(?={ML_COM_OUT}){ML_COM_OUT}
          {SL_COM}.*(?=\n)

          # \"[^"]*\"         { [:STRING, text[1..-2]]}

          {BLANK}
          
          unique-value!\d+  { [:WEIRD, nil] }
          distinct-elems!\d+!val!\d+ { [:WEIRD, nil] }
          distinct-aux-f!!\d+ { [:WEIRD, nil] }
          {IDENT}@@\d+!\d+!\d+ { [:WEIRD, nil] }
          {IDENT}'!\d+!\d+  { [:WEIRD, nil] }
          {IDENT}!\d+       { [:WEIRD, nil] }

          {OPERATOR}        { [text, text] }

          # \d+bv\d+          { [:BITVECTOR, [text[/(\d+)bv/,1], text[/bv(\d+)/,1]]] }
          \d+               { [:NUMBER, text.to_i] }
          true|false        { [:BOOLEAN, eval(text) ]}
          # bv\d+\b           { [:BVTYPE, text[2..-1].to_i] }

          {KEYWORD}         { [text, text] }
          
          \%lbl\%(@|\+)\d+  { [:LABEL, {id: text[/(\d+)/,1]} ] }
          call\d+formal@{IDENT}@\d+ { [:FORMAL, {call_id: text[/call(\d+)/,1], parameter_name: text[/@(.*)@/,1], sequence_number: text[/@(\d+)/,1].to_i}] }

          T@U!val!\d+       { [:VALUE, {id: text[/(\d+)/,1].to_i}] }
          T@T!val!\d+       { [:TYPE, {id: text[/(\d+)/,1].to_i}] }
          {IDENT}@\d+       { [:VARIABLE, {name: text[/(.*)@/,1], sequence_number: text[/@(\d+)/,1].to_i}] }
          {IDENT}@{IDENT}   { [:WEIRD, nil] }
          {IDENT}(@@\d+)?   { [:CONSTANT, {name: text}] }

          \[2\]             { [:MAP2, {name: 'Map/2'}] }
          \[3:=\]           { [:MAP3, {name: 'Map/3'}] }
          

          {IDENT}           { [:IDENTIFIER, text.to_sym] }
          .                 { [text, text] }
end
end
