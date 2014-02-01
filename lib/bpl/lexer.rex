class BoogieLanguage
macro
  BLANK     \s+
  REM_IN    \/\*
  REM_OUT   \*\/
  REM       \/\/
  OPERATOR  <==>|==>|\|\||&&|==|!=|<:|<=|<|>=|>|\+\+|\+|-|\*|\/|{:|:=|::|:
  KEYWORD   \b(assert|assume|axiom|bool|break|bv(\d+)|call|complete|const|else|ensures|exists|false|finite|forall|free|function|goto|havoc|if|implementation|int|invariant|modifies|old|procedure|requires|return|returns|true|type|unique|var|where|while)\b
  
rule

          {REM_IN}          { state = :REMS;  [:rem_in, text] }
  :REMS   {REM_OUT}         { state = nil;    [:rem_out, text] }
  :REMS   .*(?={REM_OUT})   {                 [:remark, text] }
          {REM}             { state = :REM;   [:rem_in, text] }
  :REM    \n                { state = nil;    [:rem_out, text] }
  :REM    .*(?=$)           {                 [:remark, text] }

          \"[^"]*\"         { [:STRING, text[1..-2]]}

          {BLANK}

          {OPERATOR}        { [text, text] }

          \d+bv\d+          { [:BITVECTOR, [text[/(\d+)bv/,1], text[/bv(\d+)/,1]]] }
          \d+               { [:NUMBER, text.to_i] }
          bv\d+\b           { [:BVTYPE, text[2..-1].to_i] }

          {KEYWORD}         { [text, text] }

          \w+               { [:IDENTIFIER, text] }
          .                 { [text, text] }
end