{module, std@code}.
{exports, [{charAt, 2}, {isDigit, 1}, {isIdentStart, 1}, {isIdentPart, 1}, {isSpace, 1}, {isPair, 1}, {isPunct, 1}, {escaped, 1}, {lexed, 2}, {tokenize, 1}, {ok, 2}, {bad, 2}, {tokAt, 2}, {isP, 3}, {isWord, 3}, {shown, 1}, {expected, 3}, {parseCode, 2}, {expr, 3}, {precedence, 1}, {binary, 4}, {unary, 3}, {postfix, 3}, {callArgs, 3}, {exprList, 4}, {intOf, 1}, {floatOf, 1}, {primary, 3}, {ifExpr, 3}, {lambda, 3}, {fnExpr, 3}, {fnParams, 3}, {statements, 3}, {typeNode, 3}, {arrayType, 3}, {baseType, 3}, {typeList, 4}, {tupleType, 3}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}]}.
{attributes, []}.
{labels, 1147}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@code.erl", 1}]}.
    {func_info, {atom, std@code}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 82}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 83}}.
  {label, 82}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 85}}.
  {label, 84}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 87}}.
  {label, 85}.
  {label, 83}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@code.erl", 2}]}.
    {func_info, {atom, std@code}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 88}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 89}}.
  {label, 88}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 90}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 87}}.
    {jump, {f, 91}}.
  {label, 90}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 87}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 87}}.
  {label, 91}.
  {label, 89}.
    {deallocate, 6}.
    return.
%%% `code`, the template that builds the typed AST from code written with
%%% `${…}` holes (decisions 625 (4), 637, 638, 753).
%%% 
%%% `` code @`Element(tag: ${tag}, kids: [${kids}])` `` reads its text into
%%% `compiler.Node` records and answers what `compiler.ast` builds from them:
%%% code enters the compiler written, never as a string the compiler parses
%%% back (625). Each hole is read by its arrival: a `syntax` value — a
%%% template's receiver, a caller's hole from `compiler.holes(t)`, any
%%% `syntax` parameter — is spliced as it was written (`Syntax(e)`, 638), any
%%% other value as its literal (`Lit(v)`).
%%% 
%%% The text is one expression of the vocabulary `Node` has: a name, a number,
%%% a string, `true` / `false`, a member, a call with positional and labelled
%%% arguments, `[…]`, `#(…)`, the binary operators `|| && == != < > <= >= + -
%%% * / %`, the unary `-` and `!`, `if (c) a else b`, an untyped lambda
%%% `{ a, b -> body }`, and a typed function `fn(a: A) -> R { return …; }`
%%% whose types are the type nodes (753). Anything else — an index, a string
%%% with a hole inside it, a statement other than `return` or an expression —
%%% is refused at the template's call, naming what was met.
%%% 
%%% Imported where used: `import {code} from "std";`.
% ── The tokens ──────────────────────────────────────────────────────────────
% `kind` one of `name`, `int`, `float`, `str`, `punct`, `hole`, `eof`; `hole`
% the hole's index for a `hole`, a number's value its `text`.

{function, charAt, 2, 7}.
  {label, 6}.
    {line, [{location, "std@code.erl", 3}]}.
    {func_info, {atom, std@code}, {atom, charAt}, 2}.
  {label, 7}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_lt, {f, 92}, [{y, 1}, {integer, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 92}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 95}}.
    {test, is_ne_exact, {f, 93}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 98}}.
  {label, 93}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 98}.
    {deallocate, 3}.
    return.

{function, isDigit, 1, 9}.
  {label, 8}.
    {line, [{location, "std@code.erl", 4}]}.
    {func_info, {atom, std@code}, {atom, isDigit}, 1}.
  {label, 9}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 99}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {atom, false}, {x, 0}}.
  {label, 100}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 101}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"0123456789">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 103}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {atom, true}, {x, 0}}.
  {label, 104}.
    {jump, {f, 102}}.
  {label, 101}.
    {move, {atom, false}, {x, 0}}.
  {label, 102}.
    {deallocate, 3}.
    return.

{function, isIdentStart, 1, 11}.
  {label, 10}.
    {line, [{location, "std@code.erl", 5}]}.
    {func_info, {atom, std@code}, {atom, isIdentStart}, 1}.
  {label, 11}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 105}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 106}}.
  {label, 105}.
    {move, {atom, false}, {x, 0}}.
  {label, 106}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 107}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 109}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 110}}.
  {label, 109}.
    {move, {atom, true}, {x, 0}}.
  {label, 110}.
    {jump, {f, 108}}.
  {label, 107}.
    {move, {atom, false}, {x, 0}}.
  {label, 108}.
    {deallocate, 3}.
    return.

{function, isIdentPart, 1, 13}.
  {label, 12}.
    {line, [{location, "std@code.erl", 6}]}.
    {func_info, {atom, std@code}, {atom, isIdentPart}, 1}.
  {label, 13}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 111}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 9}}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {atom, true}, {x, 0}}.
  {label, 112}.
    {deallocate, 3}.
    return.

{function, isSpace, 1, 15}.
  {label, 14}.
    {line, [{location, "std@code.erl", 7}]}.
    {func_info, {atom, std@code}, {atom, isSpace}, 1}.
  {label, 15}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {test, is_eq_exact, {f, 113}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 114}}.
  {label, 113}.
    {move, {atom, false}, {x, 0}}.
  {label, 114}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 115}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 118}}.
  {label, 117}.
    {move, {atom, false}, {x, 0}}.
  {label, 118}.
    {jump, {f, 116}}.
  {label, 115}.
    {move, {atom, true}, {x, 0}}.
  {label, 116}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 119}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"\t">>}, {x, 0}}.
    {test, is_eq_exact, {f, 121}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 122}}.
  {label, 121}.
    {move, {atom, false}, {x, 0}}.
  {label, 122}.
    {jump, {f, 120}}.
  {label, 119}.
    {move, {atom, true}, {x, 0}}.
  {label, 120}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 123}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"\r">>}, {x, 0}}.
    {test, is_eq_exact, {f, 125}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 126}}.
  {label, 125}.
    {move, {atom, false}, {x, 0}}.
  {label, 126}.
    {jump, {f, 124}}.
  {label, 123}.
    {move, {atom, true}, {x, 0}}.
  {label, 124}.
    {deallocate, 1}.
    return.
% The two-character operators; every other punctuation is one character.

{function, isPair, 1, 17}.
  {label, 16}.
    {line, [{location, "std@code.erl", 8}]}.
    {func_info, {atom, std@code}, {atom, isPair}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"->">>}, {x, 0}}.
    {test, is_eq_exact, {f, 127}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 128}}.
  {label, 127}.
    {move, {atom, false}, {x, 0}}.
  {label, 128}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 129}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"==">>}, {x, 0}}.
    {test, is_eq_exact, {f, 131}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 132}}.
  {label, 131}.
    {move, {atom, false}, {x, 0}}.
  {label, 132}.
    {jump, {f, 130}}.
  {label, 129}.
    {move, {atom, true}, {x, 0}}.
  {label, 130}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 133}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"!=">>}, {x, 0}}.
    {test, is_eq_exact, {f, 135}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 136}}.
  {label, 135}.
    {move, {atom, false}, {x, 0}}.
  {label, 136}.
    {jump, {f, 134}}.
  {label, 133}.
    {move, {atom, true}, {x, 0}}.
  {label, 134}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 137}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"<=">>}, {x, 0}}.
    {test, is_eq_exact, {f, 139}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 140}}.
  {label, 139}.
    {move, {atom, false}, {x, 0}}.
  {label, 140}.
    {jump, {f, 138}}.
  {label, 137}.
    {move, {atom, true}, {x, 0}}.
  {label, 138}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 141}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<">=">>}, {x, 0}}.
    {test, is_eq_exact, {f, 143}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 144}}.
  {label, 143}.
    {move, {atom, false}, {x, 0}}.
  {label, 144}.
    {jump, {f, 142}}.
  {label, 141}.
    {move, {atom, true}, {x, 0}}.
  {label, 142}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 145}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"&&">>}, {x, 0}}.
    {test, is_eq_exact, {f, 147}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 148}}.
  {label, 147}.
    {move, {atom, false}, {x, 0}}.
  {label, 148}.
    {jump, {f, 146}}.
  {label, 145}.
    {move, {atom, true}, {x, 0}}.
  {label, 146}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 149}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"||">>}, {x, 0}}.
    {test, is_eq_exact, {f, 151}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 152}}.
  {label, 151}.
    {move, {atom, false}, {x, 0}}.
  {label, 152}.
    {jump, {f, 150}}.
  {label, 149}.
    {move, {atom, true}, {x, 0}}.
  {label, 150}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 153}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"??">>}, {x, 0}}.
    {test, is_eq_exact, {f, 155}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 156}}.
  {label, 155}.
    {move, {atom, false}, {x, 0}}.
  {label, 156}.
    {jump, {f, 154}}.
  {label, 153}.
    {move, {atom, true}, {x, 0}}.
  {label, 154}.
    {deallocate, 1}.
    return.

{function, isPunct, 1, 19}.
  {label, 18}.
    {line, [{location, "std@code.erl", 9}]}.
    {func_info, {atom, std@code}, {atom, isPunct}, 1}.
  {label, 19}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 157}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 158}}.
  {label, 157}.
    {move, {atom, false}, {x, 0}}.
  {label, 158}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 159}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"()[]{},.:;+-*/%<>!#?|=">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 161}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 162}}.
  {label, 161}.
    {move, {atom, true}, {x, 0}}.
  {label, 162}.
    {jump, {f, 160}}.
  {label, 159}.
    {move, {atom, false}, {x, 0}}.
  {label, 160}.
    {deallocate, 3}.
    return.

{function, escaped, 1, 21}.
  {label, 20}.
    {line, [{location, "std@code.erl", 10}]}.
    {func_info, {atom, std@code}, {atom, escaped}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"n">>}, {x, 0}}.
    {test, is_eq_exact, {f, 163}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 163}.
    {move, {literal, <<"t">>}, {x, 0}}.
    {test, is_eq_exact, {f, 164}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"\t">>}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 164}.
    {move, {literal, <<"r">>}, {x, 0}}.
    {test, is_eq_exact, {f, 165}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"\r">>}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 165}.
    {move, {literal, <<"0">>}, {x, 0}}.
    {test, is_eq_exact, {f, 166}, [{y, 0}, {x, 0}]}.
    {move, {integer, 0}, {x, 0}}.
    {call_last, 1, {f, 168}, 1}.
  {label, 166}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, lexed, 2, 23}.
  {label, 22}.
    {line, [{location, "std@code.erl", 11}]}.
    {func_info, {atom, std@code}, {atom, lexed}, 2}.
  {label, 23}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Lexed}, {y, 0}, {y, 1}]}}.
    {deallocate, 2}.
    return.
% The text's tokens, a hole `${…}` one token (its braces nest, a string's do
% not count — as the compiler finds the holes `compiler.holes` answers).

{function, tokenize, 1, 25}.
  {label, 24}.
    {line, [{location, "std@code.erl", 12}]}.
    {func_info, {atom, std@code}, {atom, tokenize}, 1}.
  {label, 25}.
    {allocate, 64, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}, {y, 45}, {y, 46}, {y, 47}, {y, 48}, {y, 49}, {y, 50}, {y, 51}, {y, 52}, {y, 53}, {y, 54}, {y, 55}, {y, 56}, {y, 57}, {y, 58}, {y, 59}, {y, 60}, {y, 61}, {y, 62}, {y, 63}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 174}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@code.erl", 13}]}.
  {label, 183}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 185}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 186}}.
  {label, 185}.
    {move, {atom, false}, {x, 0}}.
  {label, 186}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 187}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 189}, [{y, 3}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 190}}.
  {label, 189}.
    {move, {atom, false}, {x, 0}}.
  {label, 190}.
    {jump, {f, 188}}.
  {label, 187}.
    {move, {atom, false}, {x, 0}}.
  {label, 188}.
    {test, is_eq_exact, {f, 184}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 191}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 191}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 192}}.
  {label, 191}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:107:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 192}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 15}}.
    {test, is_eq, {f, 193}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 194}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 194}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 195}}.
  {label, 194}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:109:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 195}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 196}}.
  {label, 193}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {test, is_eq_exact, {f, 198}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 199}}.
  {label, 198}.
    {move, {atom, false}, {x, 0}}.
  {label, 199}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 200}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {test, is_eq_exact, {f, 202}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 203}}.
  {label, 202}.
    {move, {atom, false}, {x, 0}}.
  {label, 203}.
    {jump, {f, 201}}.
  {label, 200}.
    {move, {atom, false}, {x, 0}}.
  {label, 201}.
    {test, is_eq, {f, 197}, [{x, 0}, {atom, true}]}.
    {line, [{location, "std@code.erl", 13}]}.
  {label, 204}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 206}, [{y, 3}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 207}}.
  {label, 206}.
    {move, {atom, false}, {x, 0}}.
  {label, 207}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 208}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {test, is_ne_exact, {f, 210}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 211}}.
  {label, 210}.
    {move, {atom, false}, {x, 0}}.
  {label, 211}.
    {jump, {f, 209}}.
  {label, 208}.
    {move, {atom, false}, {x, 0}}.
  {label, 209}.
    {test, is_eq_exact, {f, 205}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 212}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 212}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 213}}.
  {label, 212}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:112:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 213}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 204}}.
  {label, 205}.
    {jump, {f, 214}}.
  {label, 197}.
    {move, {literal, <<"$">>}, {x, 0}}.
    {test, is_eq_exact, {f, 216}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 217}}.
  {label, 216}.
    {move, {atom, false}, {x, 0}}.
  {label, 217}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 218}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"{">>}, {x, 0}}.
    {test, is_eq_exact, {f, 220}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 221}}.
  {label, 220}.
    {move, {atom, false}, {x, 0}}.
  {label, 221}.
    {jump, {f, 219}}.
  {label, 218}.
    {move, {atom, false}, {x, 0}}.
  {label, 219}.
    {test, is_eq, {f, 215}, [{x, 0}, {atom, true}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 222}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 222}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 223}}.
  {label, 222}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:116:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 223}.
    {move, {x, 0}, {y, 9}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {line, [{location, "std@code.erl", 13}]}.
  {label, 224}.
    {test, is_lt, {f, 226}, [{integer, 0}, {y, 8}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 227}}.
  {label, 226}.
    {move, {atom, false}, {x, 0}}.
  {label, 227}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 228}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 230}, [{y, 9}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 231}}.
  {label, 230}.
    {move, {atom, false}, {x, 0}}.
  {label, 231}.
    {jump, {f, 229}}.
  {label, 228}.
    {move, {atom, false}, {x, 0}}.
  {label, 229}.
    {test, is_eq_exact, {f, 225}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq, {f, 232}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"\\">>}, {x, 0}}.
    {test, is_eq_exact, {f, 233}, [{y, 11}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 234}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 234}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 235}}.
  {label, 234}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:121:42">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 235}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 236}}.
  {label, 233}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 237}, [{y, 11}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {jump, {f, 238}}.
  {label, 237}.
  {label, 238}.
  {label, 236}.
    {jump, {f, 239}}.
  {label, 232}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 240}, [{y, 11}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {jump, {f, 241}}.
  {label, 240}.
    {move, {literal, <<"{">>}, {x, 0}}.
    {test, is_eq_exact, {f, 242}, [{y, 11}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 8}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 243}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 243}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 244}}.
  {label, 243}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:125:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 244}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 245}}.
  {label, 242}.
    {move, {literal, <<"}">>}, {x, 0}}.
    {test, is_eq_exact, {f, 246}, [{y, 11}, {x, 0}]}.
    {gc_bif, '-', {f, 0}, 0, [{y, 8}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 247}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 247}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 248}}.
  {label, 247}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/code.bp:127:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 248}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 249}}.
  {label, 246}.
  {label, 249}.
  {label, 245}.
  {label, 241}.
  {label, 239}.
    {gc_bif, '+', {f, 0}, 0, [{y, 9}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 250}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 250}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 251}}.
  {label, 250}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:128:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 251}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 224}}.
  {label, 225}.
    {test, is_lt, {f, 252}, [{integer, 0}, {y, 8}]}.
    {move, {literal, <<"a `${` with no closing `}`">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 253}}.
  {label, 252}.
    {move, {literal, <<"hole">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Tok}, {x, 1}, {x, 0}, {y, 4}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 254}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 254}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 255}}.
  {label, 254}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:132:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 255}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
  {label, 253}.
    {jump, {f, 256}}.
  {label, 215}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test, is_eq, {f, 257}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {line, [{location, "std@code.erl", 13}]}.
  {label, 258}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call, 2, {f, 7}}.
    {call, 1, {f, 13}}.
    {test, is_eq_exact, {f, 259}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 12}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 260}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 260}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 261}}.
  {label, 260}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:138:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 261}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 258}}.
  {label, 259}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {test, is_ne_exact, {f, 262}, [{y, 12}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 12}, {y, 3}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 263}}.
  {label, 262}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 263}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 265}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Tok}, {y, 13}, {x, 0}, {integer, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 298}}.
  {label, 257}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_eq, {f, 299}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {line, [{location, "std@code.erl", 13}]}.
  {label, 300}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call, 2, {f, 7}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 302}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"_">>}, {x, 0}}.
    {test, is_eq_exact, {f, 304}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 305}}.
  {label, 304}.
    {move, {atom, false}, {x, 0}}.
  {label, 305}.
    {jump, {f, 303}}.
  {label, 302}.
    {move, {atom, true}, {x, 0}}.
  {label, 303}.
    {test, is_eq_exact, {f, 301}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 14}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 306}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 306}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 307}}.
  {label, 306}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:147:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 307}.
    {move, {x, 0}, {y, 14}}.
    {jump, {f, 300}}.
  {label, 301}.
    {move, {literal, <<"int">>}, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {test, is_eq_exact, {f, 309}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 310}}.
  {label, 309}.
    {move, {atom, false}, {x, 0}}.
  {label, 310}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 311}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 14}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 313}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 313}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 314}}.
  {label, 313}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:150:62">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 314}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 7}}.
    {call, 1, {f, 9}}.
    {jump, {f, 312}}.
  {label, 311}.
    {move, {atom, false}, {x, 0}}.
  {label, 312}.
    {test, is_eq, {f, 308}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"float">>}, {x, 0}}.
    {move, {x, 0}, {y, 15}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 14}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 315}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 315}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 316}}.
  {label, 315}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:152:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 316}.
    {move, {x, 0}, {y, 14}}.
    {line, [{location, "std@code.erl", 13}]}.
  {label, 317}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call, 2, {f, 7}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 319}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"_">>}, {x, 0}}.
    {test, is_eq_exact, {f, 321}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 322}}.
  {label, 321}.
    {move, {atom, false}, {x, 0}}.
  {label, 322}.
    {jump, {f, 320}}.
  {label, 319}.
    {move, {atom, true}, {x, 0}}.
  {label, 320}.
    {test, is_eq_exact, {f, 318}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 14}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 323}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 323}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 324}}.
  {label, 323}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:154:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 324}.
    {move, {x, 0}, {y, 14}}.
    {jump, {f, 317}}.
  {label, 318}.
    {jump, {f, 325}}.
  {label, 308}.
  {label, 325}.
    {test, is_ne_exact, {f, 332}, [{y, 14}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 14}, {y, 3}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 333}}.
  {label, 332}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 333}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 265}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"_">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 327}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Tok}, {y, 15}, {x, 0}, {integer, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 14}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 334}}.
  {label, 299}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 335}, [{y, 6}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 336}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 336}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 337}}.
  {label, 336}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:163:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 337}.
    {move, {x, 0}, {y, 16}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {line, [{location, "std@code.erl", 13}]}.
  {label, 338}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 340}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 341}}.
  {label, 340}.
    {move, {atom, false}, {x, 0}}.
  {label, 341}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 342}, [{x, 1}, {atom, true}]}.
    {move, {y, 18}, {x, 0}}.
    {test, is_eq, {f, 344}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 345}}.
  {label, 344}.
    {move, {atom, true}, {x, 0}}.
  {label, 345}.
    {jump, {f, 343}}.
  {label, 342}.
    {move, {atom, false}, {x, 0}}.
  {label, 343}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 346}, [{x, 1}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 348}, [{y, 16}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 349}}.
  {label, 348}.
    {move, {atom, false}, {x, 0}}.
  {label, 349}.
    {jump, {f, 347}}.
  {label, 346}.
    {move, {atom, false}, {x, 0}}.
  {label, 347}.
    {test, is_eq_exact, {f, 339}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 19}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 350}, [{y, 19}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {jump, {f, 351}}.
  {label, 350}.
    {move, {literal, <<"\\">>}, {x, 0}}.
    {test, is_eq_exact, {f, 352}, [{y, 19}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 16}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 353}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 353}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 354}}.
  {label, 353}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:169:58">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 354}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 7}}.
    {call, 1, {f, 21}}.
    {move, {y, 20}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 17}, {x, 0}}.
    {move, {y, 20}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 17}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 16}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 355}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 355}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 356}}.
  {label, 355}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:170:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 356}.
    {move, {x, 0}, {y, 16}}.
    {jump, {f, 357}}.
  {label, 352}.
    {move, {literal, <<"$">>}, {x, 0}}.
    {test, is_eq_exact, {f, 359}, [{y, 19}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 360}}.
  {label, 359}.
    {move, {atom, false}, {x, 0}}.
  {label, 360}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 361}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 16}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 363}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 363}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 364}}.
  {label, 363}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:171:53">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 364}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"{">>}, {x, 0}}.
    {test, is_eq_exact, {f, 365}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 366}}.
  {label, 365}.
    {move, {atom, false}, {x, 0}}.
  {label, 366}.
    {jump, {f, 362}}.
  {label, 361}.
    {move, {atom, false}, {x, 0}}.
  {label, 362}.
    {test, is_eq, {f, 358}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"a hole inside a string literal: write the string and the hole apart, `\"a\" + ${x}`">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 367}}.
  {label, 358}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 19}, {x, 0}}.
    {move, {y, 21}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 17}, {x, 0}}.
    {move, {y, 21}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 17}}.
  {label, 367}.
  {label, 357}.
  {label, 351}.
    {gc_bif, '+', {f, 0}, 0, [{y, 16}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 368}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 368}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 369}}.
  {label, 368}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:175:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 369}.
    {move, {x, 0}, {y, 16}}.
    {jump, {f, 338}}.
  {label, 339}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 371}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 372}}.
  {label, 371}.
    {move, {atom, false}, {x, 0}}.
  {label, 372}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 373}, [{x, 1}, {atom, true}]}.
    {move, {y, 18}, {x, 0}}.
    {test, is_eq, {f, 375}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 376}}.
  {label, 375}.
    {move, {atom, true}, {x, 0}}.
  {label, 376}.
    {jump, {f, 374}}.
  {label, 373}.
    {move, {atom, false}, {x, 0}}.
  {label, 374}.
    {test, is_eq, {f, 370}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"a string literal with no closing `\"`">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 377}}.
  {label, 370}.
  {label, 377}.
    {move, {literal, <<"str">>}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Tok}, {x, 0}, {y, 17}, {integer, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 16}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 378}}.
  {label, 335}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 22}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {call, 1, {f, 17}}.
    {test, is_eq, {f, 379}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"punct">>}, {x, 0}}.
    {move, {x, 0}, {y, 23}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 24}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 24}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Tok}, {y, 23}, {x, 0}, {integer, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 380}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 380}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 381}}.
  {label, 380}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:183:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 381}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 382}}.
  {label, 379}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 19}}.
    {test, is_eq, {f, 383}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"punct">>}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Tok}, {x, 0}, {y, 6}, {integer, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 384}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 384}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 385}}.
  {label, 384}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:186:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 385}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 386}}.
  {label, 383}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 25}}.
    {move, {literal, <<"` is no token of the language">>}, {x, 0}}.
    {move, {y, 25}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 25}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 25}}.
    {move, {literal, <<"`">>}, {x, 0}}.
    {move, {y, 25}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
  {label, 386}.
  {label, 382}.
  {label, 378}.
  {label, 334}.
  {label, 298}.
  {label, 256}.
  {label, 214}.
  {label, 196}.
    {jump, {f, 183}}.
  {label, 184}.
    {move, {literal, <<"eof">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Tok}, {x, 1}, {x, 0}, {integer, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_last, 2, {f, 23}, 64}.
% ── The parser ──────────────────────────────────────────────────────────────
% A node read and the index of the token after it; `err` the reason the text
% is no code of `Node`'s vocabulary, empty when it is.
% Nodes read and the index of the token after them.

{function, ok, 2, 27}.
  {label, 26}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, ok}, 2}.
  {label, 27}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@P}, {y, 0}, {y, 1}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, bad, 2, 29}.
  {label, 28}.
    {line, [{location, "std@code.erl", 14}]}.
    {func_info, {atom, std@code}, {atom, bad}, 2}.
  {label, 29}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Lit}, {integer, 0}]}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@P}, {x, 0}, {y, 1}, {y, 0}]}}.
    {deallocate, 2}.
    return.

{function, tokAt, 2, 31}.
  {label, 30}.
    {line, [{location, "std@code.erl", 15}]}.
    {func_info, {atom, std@code}, {atom, tokAt}, 2}.
  {label, 31}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 95}}.
    {test, is_ne_exact, {f, 387}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 388}}.
  {label, 387}.
    {move, {literal, <<"eof">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Tok}, {x, 1}, {x, 0}, {integer, 0}]}}.
  {label, 388}.
    {deallocate, 3}.
    return.

{function, isP, 3, 33}.
  {label, 32}.
    {line, [{location, "std@code.erl", 16}]}.
    {func_info, {atom, std@code}, {atom, isP}, 3}.
  {label, 33}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 389}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 389}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"punct">>}, {x, 0}}.
    {test, is_eq_exact, {f, 390}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 391}}.
  {label, 390}.
    {move, {atom, false}, {x, 0}}.
  {label, 391}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 392}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 394}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 394}.
    {test, is_eq_exact, {f, 395}, [{x, 0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 396}}.
  {label, 395}.
    {move, {atom, false}, {x, 0}}.
  {label, 396}.
    {jump, {f, 393}}.
  {label, 392}.
    {move, {atom, false}, {x, 0}}.
  {label, 393}.
    {deallocate, 4}.
    return.

{function, isWord, 3, 35}.
  {label, 34}.
    {line, [{location, "std@code.erl", 17}]}.
    {func_info, {atom, std@code}, {atom, isWord}, 3}.
  {label, 35}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 397}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 397}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {test, is_eq_exact, {f, 398}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 399}}.
  {label, 398}.
    {move, {atom, false}, {x, 0}}.
  {label, 399}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 400}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 402}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 402}.
    {test, is_eq_exact, {f, 403}, [{x, 0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 404}}.
  {label, 403}.
    {move, {atom, false}, {x, 0}}.
  {label, 404}.
    {jump, {f, 401}}.
  {label, 400}.
    {move, {atom, false}, {x, 0}}.
  {label, 401}.
    {deallocate, 4}.
    return.

{function, shown, 1, 37}.
  {label, 36}.
    {line, [{location, "std@code.erl", 18}]}.
    {func_info, {atom, std@code}, {atom, shown}, 1}.
  {label, 37}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 406}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 406}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"eof">>}, {x, 0}}.
    {test, is_eq_exact, {f, 405}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"the end of the text">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 405}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 408}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 408}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hole">>}, {x, 0}}.
    {test, is_eq_exact, {f, 407}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"a hole">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 407}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 410}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 410}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"str">>}, {x, 0}}.
    {test, is_eq_exact, {f, 409}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"a string">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 409}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"`">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 411}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 411}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"`">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, expected, 3, 39}.
  {label, 38}.
    {line, [{location, "std@code.erl", 19}]}.
    {func_info, {atom, std@code}, {atom, expected}, 3}.
  {label, 39}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 31}}.
    {call, 1, {f, 37}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<", found ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"expected ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 29}, 4}.

{function, parseCode, 2, 41}.
  {label, 40}.
    {line, [{location, "std@code.erl", 20}]}.
    {func_info, {atom, std@code}, {atom, parseCode}, 2}.
  {label, 41}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 413}, [{x, 0}, 3, {atom, std@code@@Lexed}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 413}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 412}, [{x, 1}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 414}, [{x, 0}, 3, {atom, std@code@@Lexed}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 414}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 29}, 4}.
  {label, 412}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 415}, [{x, 0}, 3, {atom, std@code@@Lexed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 415}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call, 3, {f, 43}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 417}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 417}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 416}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 416}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 419}, [{x, 0}, 3, {atom, std@code@@Lexed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 419}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 420}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 420}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 31}}.
    {test, is_tagged_tuple, {f, 421}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 421}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"eof">>}, {x, 0}}.
    {test, is_ne_exact, {f, 418}, [{x, 1}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 422}, [{x, 0}, 3, {atom, std@code@@Lexed}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 422}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 423}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 423}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"the end of the expression">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call_last, 3, {f, 39}, 4}.
  {label, 418}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, expr, 3, 43}.
  {label, 42}.
    {line, [{location, "std@code.erl", 21}]}.
    {func_info, {atom, std@code}, {atom, expr}, 3}.
  {label, 43}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 3}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 4, {f, 47}, 3}.
% The precedence of a binary operator, 0 for a token that is none.

{function, precedence, 1, 45}.
  {label, 44}.
    {line, [{location, "std@code.erl", 22}]}.
    {func_info, {atom, std@code}, {atom, precedence}, 1}.
  {label, 45}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 425}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 425}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"punct">>}, {x, 0}}.
    {test, is_ne_exact, {f, 424}, [{x, 1}, {x, 0}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 424}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 426}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 426}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"||">>}, {x, 0}}.
    {test, is_eq_exact, {f, 427}, [{y, 1}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 427}.
    {move, {literal, <<"&&">>}, {x, 0}}.
    {test, is_eq_exact, {f, 428}, [{y, 1}, {x, 0}]}.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 428}.
    {move, {literal, <<"==">>}, {x, 0}}.
    {test, is_eq_exact, {f, 430}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 431}}.
  {label, 430}.
    {move, {atom, false}, {x, 0}}.
  {label, 431}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 432}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"!=">>}, {x, 0}}.
    {test, is_eq_exact, {f, 434}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 435}}.
  {label, 434}.
    {move, {atom, false}, {x, 0}}.
  {label, 435}.
    {jump, {f, 433}}.
  {label, 432}.
    {move, {atom, true}, {x, 0}}.
  {label, 433}.
    {test, is_eq, {f, 429}, [{x, 0}, {atom, true}]}.
    {move, {integer, 3}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 429}.
    {move, {literal, <<"<">>}, {x, 0}}.
    {test, is_eq_exact, {f, 437}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 438}}.
  {label, 437}.
    {move, {atom, false}, {x, 0}}.
  {label, 438}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 439}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<">">>}, {x, 0}}.
    {test, is_eq_exact, {f, 441}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 442}}.
  {label, 441}.
    {move, {atom, false}, {x, 0}}.
  {label, 442}.
    {jump, {f, 440}}.
  {label, 439}.
    {move, {atom, true}, {x, 0}}.
  {label, 440}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 443}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"<=">>}, {x, 0}}.
    {test, is_eq_exact, {f, 445}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 446}}.
  {label, 445}.
    {move, {atom, false}, {x, 0}}.
  {label, 446}.
    {jump, {f, 444}}.
  {label, 443}.
    {move, {atom, true}, {x, 0}}.
  {label, 444}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 447}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<">=">>}, {x, 0}}.
    {test, is_eq_exact, {f, 449}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 450}}.
  {label, 449}.
    {move, {atom, false}, {x, 0}}.
  {label, 450}.
    {jump, {f, 448}}.
  {label, 447}.
    {move, {atom, true}, {x, 0}}.
  {label, 448}.
    {test, is_eq, {f, 436}, [{x, 0}, {atom, true}]}.
    {move, {integer, 4}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 436}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {test, is_eq_exact, {f, 452}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 453}}.
  {label, 452}.
    {move, {atom, false}, {x, 0}}.
  {label, 453}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 454}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {test, is_eq_exact, {f, 456}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 457}}.
  {label, 456}.
    {move, {atom, false}, {x, 0}}.
  {label, 457}.
    {jump, {f, 455}}.
  {label, 454}.
    {move, {atom, true}, {x, 0}}.
  {label, 455}.
    {test, is_eq, {f, 451}, [{x, 0}, {atom, true}]}.
    {move, {integer, 5}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 451}.
    {move, {literal, <<"*">>}, {x, 0}}.
    {test, is_eq_exact, {f, 459}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 460}}.
  {label, 459}.
    {move, {atom, false}, {x, 0}}.
  {label, 460}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 461}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {test, is_eq_exact, {f, 463}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 464}}.
  {label, 463}.
    {move, {atom, false}, {x, 0}}.
  {label, 464}.
    {jump, {f, 462}}.
  {label, 461}.
    {move, {atom, true}, {x, 0}}.
  {label, 462}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 465}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"%">>}, {x, 0}}.
    {test, is_eq_exact, {f, 467}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 468}}.
  {label, 467}.
    {move, {atom, false}, {x, 0}}.
  {label, 468}.
    {jump, {f, 466}}.
  {label, 465}.
    {move, {atom, true}, {x, 0}}.
  {label, 466}.
    {test, is_eq, {f, 458}, [{x, 0}, {atom, true}]}.
    {move, {integer, 6}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 458}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, binary, 4, 47}.
  {label, 46}.
    {line, [{location, "std@code.erl", 23}]}.
    {func_info, {atom, std@code}, {atom, binary}, 4}.
  {label, 47}.
    {allocate, 9, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 49}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 469}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 469}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 470}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 471}}.
  {label, 470}.
    {move, {atom, false}, {x, 0}}.
  {label, 471}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@code.erl", 24}]}.
  {label, 472}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 473}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 474}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 474}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {x, 0}, {y, 7}}.
    {test, is_eq_exact, {f, 476}, [{y, 7}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 477}}.
  {label, 476}.
    {move, {atom, false}, {x, 0}}.
  {label, 477}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 478}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 480}, [{y, 7}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 481}}.
  {label, 480}.
    {move, {atom, false}, {x, 0}}.
  {label, 481}.
    {jump, {f, 479}}.
  {label, 478}.
    {move, {atom, true}, {x, 0}}.
  {label, 479}.
    {test, is_eq, {f, 475}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 482}}.
  {label, 475}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 483}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 483}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 484}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 484}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 485}}.
  {label, 484}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:271:45">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 485}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 486}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 486}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 487}}.
  {label, 486}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:271:62">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 487}.
    {move, {y, 2}, {x, 2}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 47}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 489}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 489}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 488}, [{x, 1}, {x, 0}]}.
    {move, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 490}}.
  {label, 488}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 491}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 491}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 492}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 492}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 493}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 493}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Binary}, {x, 1}, {x, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 494}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 494}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 27}}.
    {move, {x, 0}, {y, 4}}.
  {label, 490}.
  {label, 482}.
    {jump, {f, 472}}.
  {label, 473}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, unary, 3, 49}.
  {label, 48}.
    {line, [{location, "std@code.erl", 24}]}.
    {func_info, {atom, std@code}, {atom, unary}, 3}.
  {label, 49}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 496}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"!">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {jump, {f, 497}}.
  {label, 496}.
    {move, {atom, true}, {x, 0}}.
  {label, 497}.
    {test, is_eq, {f, 495}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 498}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 498}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 499}}.
  {label, 498}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:283:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 499}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 49}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 501}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 501}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 500}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 500}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 31}}.
    {test, is_tagged_tuple, {f, 502}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 502}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 503}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 503}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Unary}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 504}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 504}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 6}.
  {label, 495}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 51}, 6}.

{function, postfix, 3, 51}.
  {label, 50}.
    {line, [{location, "std@code.erl", 25}]}.
    {func_info, {atom, std@code}, {atom, postfix}, 3}.
  {label, 51}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 61}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 505}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 505}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 506}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 507}}.
  {label, 506}.
    {move, {atom, false}, {x, 0}}.
  {label, 507}.
    {move, {x, 0}, {y, 4}}.
    {line, [{location, "std@code.erl", 26}]}.
  {label, 508}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 509}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 511}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 511}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 510}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 512}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 512}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 513}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 513}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 514}}.
  {label, 513}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:295:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 514}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 516}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 516}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {test, is_ne_exact, {f, 515}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 517}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 517}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 518}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 518}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 519}}.
  {label, 518}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:297:44">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 519}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a member name after `.`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {move, {x, 0}, {y, 3}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 520}}.
  {label, 515}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 521}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 521}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 522}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 522}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Member}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 523}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 523}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 524}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 524}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 525}}.
  {label, 524}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:300:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 525}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 27}}.
    {move, {x, 0}, {y, 3}}.
  {label, 520}.
    {jump, {f, 526}}.
  {label, 510}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 528}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 528}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"(">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 527}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 529}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 529}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 530}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 530}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 531}}.
  {label, 530}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:302:45">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 531}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 53}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 533}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 533}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 532}, [{x, 1}, {x, 0}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 534}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 534}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 535}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 535}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 29}}.
    {move, {x, 0}, {y, 3}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 536}}.
  {label, 532}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 537}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 537}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 538}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 538}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Call}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 539}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 539}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 27}}.
    {move, {x, 0}, {y, 3}}.
  {label, 536}.
    {jump, {f, 540}}.
  {label, 527}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
  {label, 540}.
  {label, 526}.
    {jump, {f, 508}}.
  {label, 509}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 7}.
    return.
% A call's arguments after its `(`, up to and past its `)`: `name: value` an
% `Arg`, any other a positional node.

{function, callArgs, 3, 53}.
  {label, 52}.
    {line, [{location, "std@code.erl", 26}]}.
    {func_info, {atom, std@code}, {atom, callArgs}, 3}.
  {label, 53}.
    {allocate, 15, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@code.erl", 27}]}.
  {label, 541}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 543}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 544}}.
  {label, 543}.
    {move, {atom, false}, {x, 0}}.
  {label, 544}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 545}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 547}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 548}}.
  {label, 547}.
    {move, {atom, true}, {x, 0}}.
  {label, 548}.
    {jump, {f, 546}}.
  {label, 545}.
    {move, {atom, false}, {x, 0}}.
  {label, 546}.
    {test, is_eq_exact, {f, 542}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 31}}.
    {test, is_tagged_tuple, {f, 549}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 549}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {test, is_eq_exact, {f, 550}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 551}}.
  {label, 550}.
    {move, {atom, false}, {x, 0}}.
  {label, 551}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 552}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 554}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 554}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 555}}.
  {label, 554}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:319:69">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 555}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {jump, {f, 553}}.
  {label, 552}.
    {move, {atom, false}, {x, 0}}.
  {label, 553}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 556}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 558}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 558}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 559}}.
  {label, 558}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:320:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 559}.
    {jump, {f, 557}}.
  {label, 556}.
    {move, {y, 4}, {x, 0}}.
  {label, 557}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 7}, {x, 1}}.
    {call, 3, {f, 43}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 561}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 561}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 560}, [{x, 1}, {x, 0}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 562}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 562}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 563}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 563}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 564}}.
  {label, 560}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 565}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 31}}.
    {test, is_tagged_tuple, {f, 566}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 566}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 567}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 567}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Arg}, {x, 1}, {x, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 568}}.
  {label, 565}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 569}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 569}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 3}}.
  {label, 568}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 570}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 570}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 571}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 572}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 572}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 573}}.
  {label, 572}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:332:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 573}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 574}}.
  {label, 571}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 576}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 577}}.
  {label, 576}.
    {move, {atom, true}, {x, 0}}.
  {label, 577}.
    {test, is_eq, {f, 575}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`,` or `)`">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 578}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 578}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 579}}.
  {label, 575}.
  {label, 579}.
  {label, 574}.
  {label, 564}.
    {jump, {f, 541}}.
  {label, 542}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 580}, [{y, 5}, {x, 0}]}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Ps}, {y, 3}, {y, 4}, {y, 5}]}}.
    {deallocate, 15}.
    return.
  {label, 580}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 581}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 581}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 582}}.
  {label, 581}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:338:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 582}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Ps}, {y, 3}, {x, 1}, {x, 0}]}}.
    {deallocate, 15}.
    return.
% Expressions separated by `,` up to and past `close`.

{function, exprList, 4, 55}.
  {label, 54}.
    {line, [{location, "std@code.erl", 27}]}.
    {func_info, {atom, std@code}, {atom, exprList}, 4}.
  {label, 55}.
    {allocate, 14, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {line, [{location, "std@code.erl", 28}]}.
  {label, 583}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 585}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 586}}.
  {label, 585}.
    {move, {atom, false}, {x, 0}}.
  {label, 586}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 587}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 589}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 590}}.
  {label, 589}.
    {move, {atom, true}, {x, 0}}.
  {label, 590}.
    {jump, {f, 588}}.
  {label, 587}.
    {move, {atom, false}, {x, 0}}.
  {label, 588}.
    {test, is_eq_exact, {f, 584}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 43}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 592}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 592}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 591}, [{x, 1}, {x, 0}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 593}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 593}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 594}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 594}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 595}}.
  {label, 591}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 596}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 596}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 597}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 597}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 598}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 599}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 599}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 600}}.
  {label, 599}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:355:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 600}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 601}}.
  {label, 598}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 603}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 604}}.
  {label, 603}.
    {move, {atom, true}, {x, 0}}.
  {label, 604}.
    {test, is_eq, {f, 602}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"`">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"`,` or `">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {y, 5}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 605}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 605}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 606}}.
  {label, 602}.
  {label, 606}.
  {label, 601}.
  {label, 595}.
    {jump, {f, 583}}.
  {label, 584}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 607}, [{y, 6}, {x, 0}]}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Ps}, {y, 4}, {y, 5}, {y, 6}]}}.
    {deallocate, 14}.
    return.
  {label, 607}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 608}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 608}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 609}}.
  {label, 608}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:361:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 609}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Ps}, {y, 4}, {x, 1}, {x, 0}]}}.
    {deallocate, 14}.
    return.

{function, intOf, 1, 57}.
  {label, 56}.
    {line, [{location, "std@code.erl", 28}]}.
    {func_info, {atom, std@code}, {atom, intOf}, 1}.
  {label, 57}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 174}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@code.erl", 29}]}.
  {label, 610}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 611}, [{y, 3}, {x, 0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {integer, 10}], {x, 0}}.
    {test, is_ge, {f, 612}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 612}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 613}}.
  {label, 612}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/code.bp:369:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 613}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 615}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 48}], {x, 0}}.
    {test, is_ge, {f, 625}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 625}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 626}}.
  {label, 625}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/code.bp:369:51">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 626}.
    {gc_bif, '+', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 627}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 627}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 628}}.
  {label, 627}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:369:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 628}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 629}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 629}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 630}}.
  {label, 629}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:370:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 630}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 610}}.
  {label, 611}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, floatOf, 1, 59}.
  {label, 58}.
    {line, [{location, "std@code.erl", 29}]}.
    {func_info, {atom, std@code}, {atom, floatOf}, 1}.
  {label, 59}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<".">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 632}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 95}}.
    {test, is_ne_exact, {f, 648}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 649}}.
  {label, 648}.
    {move, {literal, <<"0">>}, {x, 0}}.
  {label, 649}.
    {call, 1, {f, 57}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 95}}.
    {test, is_ne_exact, {f, 650}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 651}}.
  {label, 650}.
    {move, {literal, <<"0">>}, {x, 0}}.
  {label, 651}.
    {move, {x, 0}, {y, 5}}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {line, [{location, "std@code.erl", 30}]}.
  {label, 652}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 655}}.
    {test, is_lt, {f, 653}, [{y, 7}, {x, 0}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 6}, {float, 10.0}], {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 656}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 656}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 657}}.
  {label, 656}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:383:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 657}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 652}}.
  {label, 653}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 659}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 57}}.
    {call, 1, {f, 659}}.
    {test, is_ne, {f, 673}, [{y, 6}, {integer, 0}]}.
    {jump, {f, 674}}.
  {label, 673}.
    {move, {literal, {panic, <<"division by zero: / on f64 at src/code.bp:385:48">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 674}.
    {gc_bif, '/', {f, 0}, 1, [{x, 0}, {y, 6}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {deallocate, 13}.
    return.

{function, primary, 3, 61}.
  {label, 60}.
    {line, [{location, "std@code.erl", 30}]}.
    {func_info, {atom, std@code}, {atom, primary}, 3}.
  {label, 61}.
    {allocate, 10, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 676}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 676}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hole">>}, {x, 0}}.
    {test, is_eq_exact, {f, 675}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 678}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 678}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 95}}.
    {test, is_ne_exact, {f, 677}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 679}}.
  {label, 677}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Lit}, {integer, 0}]}}.
  {label, 679}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 680}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 680}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 681}}.
  {label, 680}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:390:67">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 681}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 675}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 683}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 683}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"int">>}, {x, 0}}.
    {test, is_eq_exact, {f, 682}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 684}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 684}.
    {call, 1, {f, 57}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Lit}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 685}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 685}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 686}}.
  {label, 685}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:391:58">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 686}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 682}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 688}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 688}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"float">>}, {x, 0}}.
    {test, is_eq_exact, {f, 687}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 689}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 689}.
    {call, 1, {f, 59}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Lit}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 690}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 690}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 691}}.
  {label, 690}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:392:62">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 691}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 687}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 693}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 693}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"str">>}, {x, 0}}.
    {test, is_eq_exact, {f, 692}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 694}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 694}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Lit}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 695}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 695}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 696}}.
  {label, 695}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:393:51">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 696}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 692}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 698}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 698}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {test, is_eq_exact, {f, 697}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 700}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 700}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"true">>}, {x, 0}}.
    {test, is_eq_exact, {f, 699}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Lit}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 701}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 701}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 702}}.
  {label, 701}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:395:54">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 702}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 699}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 704}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 704}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"false">>}, {x, 0}}.
    {test, is_eq_exact, {f, 703}, [{x, 1}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Lit}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 705}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 705}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 706}}.
  {label, 705}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:396:56">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 706}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 703}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 708}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 708}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"if">>}, {x, 0}}.
    {test, is_eq_exact, {f, 707}, [{x, 1}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 709}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 709}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 710}}.
  {label, 709}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:397:49">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 710}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 63}, 10}.
  {label, 707}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 712}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 712}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"fn">>}, {x, 0}}.
    {test, is_eq_exact, {f, 711}, [{x, 1}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 713}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 713}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 714}}.
  {label, 713}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:398:49">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 714}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 67}, 10}.
  {label, 711}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 715}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 715}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Name}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 716}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 716}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 717}}.
  {label, 716}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:399:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 717}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 697}.
    {move, {literal, <<"(">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 718}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 719}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 719}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 720}}.
  {label, 719}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:402:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 720}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 43}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 722}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 722}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 721}, [{x, 1}, {x, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 721}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 724}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 724}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 725}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 726}}.
  {label, 725}.
    {move, {atom, true}, {x, 0}}.
  {label, 726}.
    {test, is_eq, {f, 723}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 727}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 727}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`)`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 10}.
  {label, 723}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 728}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 728}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 729}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 729}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 730}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 730}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 731}}.
  {label, 730}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:405:41">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 731}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 718}.
    {move, {literal, <<"[">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 732}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 733}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 733}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 734}}.
  {label, 733}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:408:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 734}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"]">>}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 55}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 736}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 736}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 735}, [{x, 1}, {x, 0}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 737}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 737}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 738}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 738}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 29}, 10}.
  {label, 735}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 739}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 739}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@List}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 740}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 740}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 732}.
    {move, {literal, <<"#">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 742}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 744}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 744}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 745}}.
  {label, 744}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:412:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 745}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"(">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {jump, {f, 743}}.
  {label, 742}.
    {move, {atom, false}, {x, 0}}.
  {label, 743}.
    {test, is_eq, {f, 741}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 746}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 746}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 747}}.
  {label, 746}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:413:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 747}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 55}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 749}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 749}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 748}, [{x, 1}, {x, 0}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 750}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 750}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 751}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 751}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 29}, 10}.
  {label, 748}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 752}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 752}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Tuple}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 753}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 753}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
  {label, 741}.
    {move, {literal, <<"{">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 754}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 755}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 755}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 756}}.
  {label, 755}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:417:46">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 756}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 65}, 10}.
  {label, 754}.
    {move, {literal, <<"an expression">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 10}.
% `if (cond) then else otherwise`, after its `if`.

{function, ifExpr, 3, 63}.
  {label, 62}.
    {line, [{location, "std@code.erl", 31}]}.
    {func_info, {atom, std@code}, {atom, ifExpr}, 3}.
  {label, 63}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {literal, <<"(">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 758}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 759}}.
  {label, 758}.
    {move, {atom, true}, {x, 0}}.
  {label, 759}.
    {test, is_eq, {f, 757}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`(` after `if`">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 6}.
  {label, 757}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 760}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 760}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 761}}.
  {label, 760}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:424:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 761}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 43}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 763}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 763}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 762}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 762}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 765}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 765}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 766}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 767}}.
  {label, 766}.
    {move, {atom, true}, {x, 0}}.
  {label, 767}.
    {test, is_eq, {f, 764}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 768}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 768}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`)`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 6}.
  {label, 764}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 769}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 769}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 770}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 770}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 771}}.
  {label, 770}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:427:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 771}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 43}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 773}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 773}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 772}, [{x, 1}, {x, 0}]}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 772}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 775}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 775}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"else">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 35}}.
    {test, is_eq, {f, 776}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 777}}.
  {label, 776}.
    {move, {atom, true}, {x, 0}}.
  {label, 777}.
    {test, is_eq, {f, 774}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 778}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 778}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`else`: an `if` that answers a value has both branches">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 6}.
  {label, 774}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 779}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 779}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 780}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 780}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 781}}.
  {label, 780}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:431:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 781}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 43}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 783}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 783}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 782}, [{x, 1}, {x, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 782}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 784}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 784}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 785}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 785}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 786}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 786}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@If}, {x, 1}, {x, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 787}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 787}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 6}.
% `{ a, b -> body }` (or `{ -> body }`), after its `{`.

{function, lambda, 3, 65}.
  {label, 64}.
    {line, [{location, "std@code.erl", 32}]}.
    {func_info, {atom, std@code}, {atom, lambda}, 3}.
  {label, 65}.
    {allocate, 10, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@code.erl", 33}]}.
  {label, 788}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 790}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 791}}.
  {label, 790}.
    {move, {atom, false}, {x, 0}}.
  {label, 791}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 792}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"->">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 794}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 795}}.
  {label, 794}.
    {move, {atom, true}, {x, 0}}.
  {label, 795}.
    {jump, {f, 793}}.
  {label, 792}.
    {move, {atom, false}, {x, 0}}.
  {label, 793}.
    {test, is_eq_exact, {f, 789}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 797}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 797}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {test, is_ne_exact, {f, 796}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"a parameter name or `->`">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 798}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 798}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 799}}.
  {label, 796}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 800}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 800}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 801}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 801}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 802}}.
  {label, 801}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:447:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 802}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 803}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 804}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 804}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 805}}.
  {label, 804}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:449:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 805}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 806}}.
  {label, 803}.
    {move, {literal, <<"->">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 808}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 809}}.
  {label, 808}.
    {move, {atom, true}, {x, 0}}.
  {label, 809}.
    {test, is_eq, {f, 807}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`,` or `->`">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 810}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 810}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 811}}.
  {label, 807}.
  {label, 811}.
  {label, 806}.
  {label, 799}.
    {jump, {f, 788}}.
  {label, 789}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 812}, [{y, 5}, {x, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_last, 2, {f, 29}, 10}.
  {label, 812}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 813}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 813}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 814}}.
  {label, 813}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:455:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 814}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 43}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 816}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 816}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 815}, [{x, 1}, {x, 0}]}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 815}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 818}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 818}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"}">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 819}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 820}}.
  {label, 819}.
    {move, {atom, true}, {x, 0}}.
  {label, 820}.
    {test, is_eq, {f, 817}, [{x, 0}, {atom, true}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 821}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 821}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`}`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 10}.
  {label, 817}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 822}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 822}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Lambda}, {y, 3}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 823}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 823}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 824}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 824}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 825}}.
  {label, 824}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:458:64">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 825}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 10}.
% `fn(a: A, b: B) -> R { statements }`, after its `fn` (decision 753).

{function, fnExpr, 3, 67}.
  {label, 66}.
    {line, [{location, "std@code.erl", 33}]}.
    {func_info, {atom, std@code}, {atom, fnExpr}, 3}.
  {label, 67}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {literal, <<"(">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 827}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 828}}.
  {label, 827}.
    {move, {atom, true}, {x, 0}}.
  {label, 828}.
    {test, is_eq, {f, 826}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`(` after `fn`">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 6}.
  {label, 826}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 829}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 829}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 830}}.
  {label, 829}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:464:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 830}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 69}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 832}, [{x, 0}, 4, {atom, std@code@@Params}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 832}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 831}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 833}, [{x, 0}, 4, {atom, std@code@@Params}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 833}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 834}, [{x, 0}, 4, {atom, std@code@@Params}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 834}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 29}, 6}.
  {label, 831}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 836}, [{x, 0}, 4, {atom, std@code@@Params}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 836}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"->">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 837}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 838}}.
  {label, 837}.
    {move, {atom, true}, {x, 0}}.
  {label, 838}.
    {test, is_eq, {f, 835}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 839}, [{x, 0}, 4, {atom, std@code@@Params}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 839}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`->` and the return type">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 6}.
  {label, 835}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 840}, [{x, 0}, 4, {atom, std@code@@Params}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 840}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 841}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 841}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 842}}.
  {label, 841}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:468:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 842}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 73}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 844}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 844}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 843}, [{x, 1}, {x, 0}]}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 843}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 846}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 846}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"{">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 847}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 848}}.
  {label, 847}.
    {move, {atom, true}, {x, 0}}.
  {label, 848}.
    {test, is_eq, {f, 845}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 849}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 849}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`{`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 6}.
  {label, 845}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 850}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 850}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 851}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 851}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 852}}.
  {label, 851}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:471:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 852}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 71}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 854}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 854}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 853}, [{x, 1}, {x, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 855}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 855}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 856}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 856}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 29}, 6}.
  {label, 853}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 857}, [{x, 0}, 4, {atom, std@code@@Params}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 857}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 858}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 858}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 859}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 859}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Fn}, {x, 1}, {x, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 860}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 860}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 6}.

{function, fnParams, 3, 69}.
  {label, 68}.
    {line, [{location, "std@code.erl", 34}]}.
    {func_info, {atom, std@code}, {atom, fnParams}, 3}.
  {label, 69}.
    {allocate, 14, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@code.erl", 35}]}.
  {label, 861}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 863}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 864}}.
  {label, 863}.
    {move, {atom, false}, {x, 0}}.
  {label, 864}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 865}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 867}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 868}}.
  {label, 867}.
    {move, {atom, true}, {x, 0}}.
  {label, 868}.
    {jump, {f, 866}}.
  {label, 865}.
    {move, {atom, false}, {x, 0}}.
  {label, 866}.
    {test, is_eq_exact, {f, 862}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 870}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 870}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {test, is_ne_exact, {f, 871}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 872}}.
  {label, 871}.
    {move, {atom, false}, {x, 0}}.
  {label, 872}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 873}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 875}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 875}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 876}}.
  {label, 875}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:482:46">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 876}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 877}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 878}}.
  {label, 877}.
    {move, {atom, true}, {x, 0}}.
  {label, 878}.
    {jump, {f, 874}}.
  {label, 873}.
    {move, {atom, true}, {x, 0}}.
  {label, 874}.
    {test, is_eq, {f, 869}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"a typed parameter `name: Type`">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 879}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 879}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 880}}.
  {label, 869}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 881}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 881}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 882}}.
  {label, 881}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:485:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 882}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 73}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 884}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 884}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 883}, [{x, 1}, {x, 0}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 885}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 885}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 886}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 886}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 887}}.
  {label, 883}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 888}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 888}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 889}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 889}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@FnParam}, {x, 1}, {x, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 890}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 890}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 891}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 892}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 892}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 893}}.
  {label, 892}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:493:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 893}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 894}}.
  {label, 891}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 896}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 897}}.
  {label, 896}.
    {move, {atom, true}, {x, 0}}.
  {label, 897}.
    {test, is_eq, {f, 895}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`,` or `)`">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 898}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 898}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 899}}.
  {label, 895}.
  {label, 899}.
  {label, 894}.
  {label, 887}.
  {label, 880}.
    {jump, {f, 861}}.
  {label, 862}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 900}, [{y, 5}, {x, 0}]}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Params}, {y, 3}, {y, 4}, {y, 5}]}}.
    {deallocate, 14}.
    return.
  {label, 900}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 901}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 901}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 902}}.
  {label, 901}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:500:41">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 902}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Params}, {y, 3}, {x, 1}, {x, 0}]}}.
    {deallocate, 14}.
    return.
% A function's statements after its `{`, up to and past its `}`: `return e;`
% a `Return`, any other an expression.

{function, statements, 3, 71}.
  {label, 70}.
    {line, [{location, "std@code.erl", 35}]}.
    {func_info, {atom, std@code}, {atom, statements}, 3}.
  {label, 71}.
    {allocate, 15, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {line, [{location, "std@code.erl", 36}]}.
  {label, 903}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 905}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 906}}.
  {label, 905}.
    {move, {atom, false}, {x, 0}}.
  {label, 906}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 907}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"}">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 909}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 910}}.
  {label, 909}.
    {move, {atom, true}, {x, 0}}.
  {label, 910}.
    {jump, {f, 908}}.
  {label, 907}.
    {move, {atom, false}, {x, 0}}.
  {label, 908}.
    {test, is_eq_exact, {f, 904}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 31}}.
    {test, is_tagged_tuple, {f, 912}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 912}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"eof">>}, {x, 0}}.
    {test, is_eq_exact, {f, 911}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"`}`">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 913}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 913}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 914}}.
  {label, 911}.
    {move, {literal, <<"return">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 35}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 915}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 917}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 917}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 918}}.
  {label, 917}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:514:48">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 918}.
    {jump, {f, 916}}.
  {label, 915}.
    {move, {y, 4}, {x, 0}}.
  {label, 916}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 43}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 920}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 920}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 919}, [{x, 1}, {x, 0}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 921}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 921}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 922}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 922}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 923}}.
  {label, 919}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 924}, [{x, 0}, {atom, true}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 925}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 925}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Return}, {x, 0}]}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 926}}.
  {label, 924}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 927}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 927}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 3}}.
  {label, 926}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 928}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 928}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<";">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 929}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 930}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 930}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 931}}.
  {label, 930}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:524:50">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 931}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 932}}.
  {label, 929}.
  {label, 932}.
  {label, 923}.
  {label, 914}.
    {jump, {f, 903}}.
  {label, 904}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 933}, [{y, 5}, {x, 0}]}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Ps}, {y, 3}, {y, 4}, {y, 5}]}}.
    {deallocate, 15}.
    return.
  {label, 933}.
    {gc_bif, '+', {f, 0}, 0, [{y, 4}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 934}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 934}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 935}}.
  {label, 934}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:529:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 935}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Ps}, {y, 3}, {x, 1}, {x, 0}]}}.
    {deallocate, 15}.
    return.
% ── The types (decision 753) ───────────────────────────────────────────────
% `A | B`, or one type.

{function, typeNode, 3, 73}.
  {label, 72}.
    {line, [{location, "std@code.erl", 36}]}.
    {func_info, {atom, std@code}, {atom, typeNode}, 3}.
  {label, 73}.
    {allocate, 13, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 75}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 937}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 937}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 938}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 939}}.
  {label, 938}.
    {move, {atom, false}, {x, 0}}.
  {label, 939}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 940}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 942}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 942}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 943}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 944}}.
  {label, 943}.
    {move, {atom, true}, {x, 0}}.
  {label, 944}.
    {jump, {f, 941}}.
  {label, 940}.
    {move, {atom, true}, {x, 0}}.
  {label, 941}.
    {test, is_eq, {f, 936}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 936}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 945}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 945}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 946}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 946}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {line, [{location, "std@code.erl", 37}]}.
  {label, 947}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 949}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 950}}.
  {label, 949}.
    {move, {atom, false}, {x, 0}}.
  {label, 950}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 951}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {jump, {f, 952}}.
  {label, 951}.
    {move, {atom, false}, {x, 0}}.
  {label, 952}.
    {test, is_eq_exact, {f, 948}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 953}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 953}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 954}}.
  {label, 953}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:542:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 954}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 75}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 956}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 956}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 955}, [{x, 1}, {x, 0}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 957}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 957}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 958}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 958}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 959}}.
  {label, 955}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 960}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 960}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 961}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 961}.
    {move, {x, 0}, {y, 6}}.
  {label, 959}.
    {jump, {f, 947}}.
  {label, 948}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 962}, [{y, 7}, {x, 0}]}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_last, 2, {f, 29}, 13}.
  {label, 962}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@UnionType}, {y, 5}]}}.
    {move, {y, 6}, {x, 1}}.
    {call_last, 2, {f, 27}, 13}.
% `T[]`, `T[][]`, or one type.

{function, arrayType, 3, 75}.
  {label, 74}.
    {line, [{location, "std@code.erl", 37}]}.
    {func_info, {atom, std@code}, {atom, arrayType}, 3}.
  {label, 75}.
    {allocate, 8, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 77}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@code.erl", 38}]}.
  {label, 963}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 965}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 965}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 966}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 967}}.
  {label, 966}.
    {move, {atom, false}, {x, 0}}.
  {label, 967}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 968}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 970}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 970}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"[">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {jump, {f, 969}}.
  {label, 968}.
    {move, {atom, false}, {x, 0}}.
  {label, 969}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 971}, [{x, 1}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 973}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 973}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 974}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 974}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 975}}.
  {label, 974}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:560:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 975}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"]">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {jump, {f, 972}}.
  {label, 971}.
    {move, {atom, false}, {x, 0}}.
  {label, 972}.
    {test, is_eq_exact, {f, 964}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 976}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 976}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@ArrayType}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 977}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 977}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 978}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 978}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 979}}.
  {label, 978}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:561:53">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 979}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 27}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 963}}.
  {label, 964}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, baseType, 3, 77}.
  {label, 76}.
    {line, [{location, "std@code.erl", 38}]}.
    {func_info, {atom, std@code}, {atom, baseType}, 3}.
  {label, 77}.
    {allocate, 12, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 981}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 981}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"hole">>}, {x, 0}}.
    {test, is_eq_exact, {f, 980}, [{x, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 983}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 983}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 95}}.
    {test, is_ne_exact, {f, 982}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 984}}.
  {label, 982}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Lit}, {integer, 0}]}}.
  {label, 984}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 985}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 985}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 986}}.
  {label, 985}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:568:67">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 986}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 12}.
  {label, 980}.
    {move, {literal, <<"?">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 987}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 988}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 988}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 989}}.
  {label, 988}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:570:37">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 989}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 75}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 991}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 991}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 990}, [{x, 1}, {x, 0}]}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 990}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 992}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 992}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@OptionalType}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 993}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 993}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 12}.
  {label, 987}.
    {move, {literal, <<"#">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 995}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 997}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 997}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 998}}.
  {label, 997}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:574:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 998}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"(">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {jump, {f, 996}}.
  {label, 995}.
    {move, {atom, false}, {x, 0}}.
  {label, 996}.
    {test, is_eq, {f, 994}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 999}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 999}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1000}}.
  {label, 999}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:575:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1000}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 81}, 12}.
  {label, 994}.
    {move, {literal, <<"fn">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 35}}.
    {test, is_eq, {f, 1001}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1003}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1003}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1004}}.
  {label, 1003}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:577:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1004}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"(">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1005}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1006}}.
  {label, 1005}.
    {move, {atom, true}, {x, 0}}.
  {label, 1006}.
    {test, is_eq, {f, 1002}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1007}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1007}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1008}}.
  {label, 1007}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:577:57">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1008}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`(` after `fn`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 12}.
  {label, 1002}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 1009}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1009}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1010}}.
  {label, 1009}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:578:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1010}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 79}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1012}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1012}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1011}, [{x, 1}, {x, 0}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1013}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1013}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1014}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1014}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 29}, 12}.
  {label, 1011}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1016}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1016}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"->">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1017}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1018}}.
  {label, 1017}.
    {move, {atom, true}, {x, 0}}.
  {label, 1018}.
    {test, is_eq, {f, 1015}, [{x, 0}, {atom, true}]}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1019}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1019}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`->` and the return type">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 12}.
  {label, 1015}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1020}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1020}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1021}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1021}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1022}}.
  {label, 1021}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:582:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1022}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 73}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1024}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1024}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1023}, [{x, 1}, {x, 0}]}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 1023}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1025}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1025}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1026}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1026}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@FnType}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1027}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1027}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 12}.
  {label, 1001}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1029}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1029}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1028}, [{x, 1}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1031}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1031}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1032}}.
  {label, 1031}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:587:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1032}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"<">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1030}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 1033}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1033}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1034}}.
  {label, 1033}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:588:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1034}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<">">>}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call, 4, {f, 79}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1036}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1036}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1035}, [{x, 1}, {x, 0}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1037}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1037}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1038}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1038}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 29}, 12}.
  {label, 1035}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1039}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1039}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1040}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1040}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@GenericType}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1041}, [{x, 0}, 4, {atom, std@code@@Ps}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1041}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 12}.
  {label, 1030}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1042}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1042}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@NamedType}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1043}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1043}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1044}}.
  {label, 1043}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:592:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1044}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 12}.
  {label, 1028}.
    {move, {literal, <<"(">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1045}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1046}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1046}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1047}}.
  {label, 1046}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:595:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1047}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 73}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1049}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1049}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1048}, [{x, 1}, {x, 0}]}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 1048}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1051}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1051}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1052}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1053}}.
  {label, 1052}.
    {move, {atom, true}, {x, 0}}.
  {label, 1053}.
    {test, is_eq, {f, 1050}, [{x, 0}, {atom, true}]}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1054}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1054}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`)`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 12}.
  {label, 1050}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1055}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1055}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1056}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1056}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1057}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1057}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1058}}.
  {label, 1057}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:598:41">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1058}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 12}.
  {label, 1045}.
    {move, {literal, <<"a type">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 39}, 12}.
% Types separated by `,` up to and past `close`.

{function, typeList, 4, 79}.
  {label, 78}.
    {line, [{location, "std@code.erl", 39}]}.
    {func_info, {atom, std@code}, {atom, typeList}, 4}.
  {label, 79}.
    {allocate, 14, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {line, [{location, "std@code.erl", 40}]}.
  {label, 1059}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1061}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1062}}.
  {label, 1061}.
    {move, {atom, false}, {x, 0}}.
  {label, 1062}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1063}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1065}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1066}}.
  {label, 1065}.
    {move, {atom, true}, {x, 0}}.
  {label, 1066}.
    {jump, {f, 1064}}.
  {label, 1063}.
    {move, {atom, false}, {x, 0}}.
  {label, 1064}.
    {test, is_eq_exact, {f, 1060}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 73}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1068}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1068}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1067}, [{x, 1}, {x, 0}]}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1069}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1069}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1070}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1070}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1071}}.
  {label, 1067}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1072}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1072}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1073}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1073}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1074}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1075}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1075}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1076}}.
  {label, 1075}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:617:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1076}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 1077}}.
  {label, 1074}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 5}, {x, 1}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1079}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1080}}.
  {label, 1079}.
    {move, {atom, true}, {x, 0}}.
  {label, 1080}.
    {test, is_eq, {f, 1078}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"`">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"`,` or `">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {y, 5}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 1081}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1081}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1082}}.
  {label, 1078}.
  {label, 1082}.
  {label, 1077}.
  {label, 1071}.
    {jump, {f, 1059}}.
  {label, 1060}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1083}, [{y, 6}, {x, 0}]}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Ps}, {y, 4}, {y, 5}, {y, 6}]}}.
    {deallocate, 14}.
    return.
  {label, 1083}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1084}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1084}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1085}}.
  {label, 1084}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:623:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1085}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@code@@Ps}, {y, 4}, {x, 1}, {x, 0}]}}.
    {deallocate, 14}.
    return.
% `#(A, B)` or `#(a: A, b: B)`, after its `#(`.

{function, tupleType, 3, 81}.
  {label, 80}.
    {line, [{location, "std@code.erl", 40}]}.
    {func_info, {atom, std@code}, {atom, tupleType}, 3}.
  {label, 81}.
    {allocate, 18, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 31}}.
    {test, is_tagged_tuple, {f, 1086}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1086}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1087}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1088}}.
  {label, 1087}.
    {move, {atom, false}, {x, 0}}.
  {label, 1088}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1089}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1091}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1091}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1092}}.
  {label, 1091}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:628:61">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1092}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {jump, {f, 1090}}.
  {label, 1089}.
    {move, {atom, false}, {x, 0}}.
  {label, 1090}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {line, [{location, "std@code.erl", 41}]}.
  {label, 1093}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 1095}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1096}}.
  {label, 1095}.
    {move, {atom, false}, {x, 0}}.
  {label, 1096}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 1097}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1099}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1100}}.
  {label, 1099}.
    {move, {atom, true}, {x, 0}}.
  {label, 1100}.
    {jump, {f, 1098}}.
  {label, 1097}.
    {move, {atom, false}, {x, 0}}.
  {label, 1098}.
    {test, is_eq_exact, {f, 1094}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 8}}.
    {test, is_eq, {f, 1102}, [{y, 3}, {atom, true}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1104}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1104}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"name">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1105}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 1106}}.
  {label, 1105}.
    {move, {atom, false}, {x, 0}}.
  {label, 1106}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 1107}, [{x, 1}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1109}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1109}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1110}}.
  {label, 1109}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:635:59">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1110}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1111}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1112}}.
  {label, 1111}.
    {move, {atom, true}, {x, 0}}.
  {label, 1112}.
    {jump, {f, 1108}}.
  {label, 1107}.
    {move, {atom, true}, {x, 0}}.
  {label, 1108}.
    {jump, {f, 1103}}.
  {label, 1102}.
    {move, {atom, false}, {x, 0}}.
  {label, 1103}.
    {test, is_eq, {f, 1101}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"a labelled element `name: Type`">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 1113}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1113}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 1114}}.
  {label, 1101}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 1115}, [{x, 0}, {atom, true}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1116}, [{x, 0}, 4, {atom, std@code@@Tok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1116}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 1117}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1117}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1118}}.
  {label, 1117}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:640:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1118}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1119}}.
  {label, 1115}.
  {label, 1119}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 6}, {x, 1}}.
    {call, 3, {f, 73}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1121}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1121}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1120}, [{x, 1}, {x, 0}]}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1122}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1122}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1123}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1123}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1124}}.
  {label, 1120}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1125}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 1125}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 1126}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 1126}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1127}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1128}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1128}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1129}}.
  {label, 1128}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:650:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1129}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 1130}}.
  {label, 1127}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 33}}.
    {test, is_eq, {f, 1132}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 1133}}.
  {label, 1132}.
    {move, {atom, true}, {x, 0}}.
  {label, 1133}.
    {test, is_eq, {f, 1131}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"`,` or `)`">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 39}}.
    {test, is_tagged_tuple, {f, 1134}, [{x, 0}, 4, {atom, std@code@@P}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 1134}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 1135}}.
  {label, 1131}.
  {label, 1135}.
  {label, 1130}.
  {label, 1124}.
  {label, 1114}.
    {jump, {f, 1093}}.
  {label, 1094}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 1136}, [{y, 7}, {x, 0}]}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_last, 2, {f, 29}, 18}.
  {label, 1136}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 1137}, [{x, 0}, {atom, true}]}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@LabeledTupleType}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1138}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1138}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1139}}.
  {label, 1138}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:658:71">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1139}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 18}.
  {label, 1137}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@TupleType}, {y, 4}]}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 1140}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 1140}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 1141}}.
  {label, 1140}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/code.bp:659:44">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 1141}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 27}, 18}.

{function, '__bp_priv__array_range', 2, 1144}.
  {label, 1143}.
    {line, [{location, "std@code.erl", 42}]}.
    {func_info, {atom, std@code}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 1144}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 1146}.
  {label, 1145}.
    {line, [{location, "std@code.erl", 43}]}.
    {func_info, {atom, std@code}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 1146}.
    {call_only, 2, {f, 5}}.

{function, '-bp_at-', 2, 95}.
  {label, 94}.
    {line, [{location, "std@code.erl", 4}]}.
    {func_info, {atom, std@code}, {atom, '-bp_at-'}, 2}.
  {label, 95}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 97}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 96}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 97}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 96}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 96}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_0', 1, 168}.
  {label, 167}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_0'}, 1}.
  {label, 168}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 171}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 171}, [{x, 0}]}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 172}}.
  {label, 171}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 172}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1', 1, 174}.
  {label, 173}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_1'}, 1}.
  {label, 174}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 178}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 179}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 3}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 181}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 181}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 182}}.
  {label, 181}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 182}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 178}}.
  {label, 179}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 180}, [{x, 0}]}.
    {jump, {f, 177}}.
  {label, 180}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 177}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_print', 1, 267}.
  {label, 266}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, '__bp_print'}, 1}.
  {label, 267}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 271}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 271}.
  {label, 270}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, '-bp_show_top-'}, 1}.
  {label, 271}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 269}}.

{function, '-bp_show_elem-', 1, 273}.
  {label, 272}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, '-bp_show_elem-'}, 1}.
  {label, 273}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 269}}.

{function, '__bp_show', 2, 269}.
  {label, 268}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, '__bp_show'}, 2}.
  {label, 269}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 281}, [{x, 0}]}.
    {test, is_eq, {f, 280}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 280}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 281}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 282}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 273}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 282}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 284}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 283}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 283}, [{x, 0}]}.
    {test, is_ne_exact, {f, 283}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 283}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 283}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 288}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 289}}.
  {label, 288}.
    {test, is_eq_exact, {f, 285}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 289}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 269}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 283}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 273}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 284}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 286}, [{x, 0}]}.
    {test, is_ne_exact, {f, 286}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 286}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 287}, [{x, 0}, {atom, undefined}]}.
  {label, 285}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 275}, 2}.
  {label, 286}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 287}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 275}.
  {label, 274}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, '__bp_tagged'}, 2}.
  {label, 275}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 290}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 290}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 290}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 291}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 277}, 3}.
  {label, 291}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 277}.
  {label, 276}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, '__bp_render'}, 1}.
  {label, 277}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 292}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 292}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 293}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 293}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 279}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 279}.
  {label, 278}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, '-bp_render_pair-'}, 1}.
  {label, 279}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 269}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 295}.
  {label, 294}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, '-bp_stringify-'}, 1}.
  {label, 295}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 296}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 296}.
    {test, is_integer, {f, 297}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 297}.
    {call, 1, {f, 271}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 265}.
  {label, 264}.
    {line, [{location, "std@code.erl", 13}]}.
    {func_info, {atom, std@code}, {atom, '-bp_join-'}, 2}.
  {label, 265}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 295}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_2-t/3-fun-0-', 3, 331}.
  {label, 330}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_2-t/3-fun-0-'}, 3}.
  {label, 331}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {literal, [global]}, {x, 3}}.
    {call_ext_last, 4, {extfunc, binary, replace, 4}, 3}.

{function, '__bp_tpl_2', 3, 327}.
  {label, 326}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_2'}, 3}.
  {label, 327}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 331}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_3-t/2-fun-0-', 2, 619}.
  {label, 618}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_3-t/2-fun-0-'}, 2}.
  {label, 619}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 623}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_lt, {f, 623}, [{x, 0}, {x, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 623}, [{x, 0}, {x, 1}]}.
    {jump, {f, 624}}.
  {label, 624}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 5}.
  {label, 623}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_3', 2, 615}.
  {label, 614}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_3'}, 2}.
  {label, 615}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 619}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 636}.
  {label, 635}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 636}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 638}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 640}, [{x, 0}]}.
    {jump, {f, 641}}.
  {label, 640}.
    {test, is_tuple, {f, 642}, [{x, 0}]}.
    {test, test_arity, {f, 642}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 641}}.
  {label, 642}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 641}.
    {move, {x, 0}, {y, 4}}.
  {label, 643}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 644}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 646}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 646}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 647}}.
  {label, 646}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 647}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 643}}.
  {label, 644}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 645}, [{x, 0}]}.
    {jump, {f, 639}}.
  {label, 645}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 639}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 638}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_4', 2, 632}.
  {label, 631}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_4'}, 2}.
  {label, 632}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 636}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_5', 1, 655}.
  {label, 654}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_5'}, 1}.
  {label, 655}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '__bp_tpl_6-t/1-fun-0-', 1, 663}.
  {label, 662}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_6-t/1-fun-0-'}, 1}.
  {label, 663}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, float, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 667}}.
  {label, 667}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, trunc, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 669}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 669}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 670}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_binary, {f, 671}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" has no exact f64">>}, nil, {x, 0}}.
    {put_list, {y, 3}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toF64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 672}}.
  {label, 671}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 672}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 4}.
  {label, 670}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_6', 1, 659}.
  {label, 658}.
    {func_info, {atom, std@code}, {atom, '__bp_tpl_6'}, 1}.
  {label, 659}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 663}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 87}.
  {label, 86}.
    {line, [{location, "std@code.erl", 41}]}.
    {func_info, {atom, std@code}, {atom, '__bp_prim_append'}, 2}.
  {label, 87}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 1142}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 1142}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
