{module, std@querystring}.
{exports, [{parse, 1}, {parseForm, 1}, {stringify, 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__decodeBody', 2}, {'__bp_priv__decodeComponent', 2}, {'__bp_priv__decodeField', 2}, {'__bp_priv__decodeFields', 4}, {'__bp_priv__hasControl', 1}, {'__bp_priv__hasControlFrom', 2}, {'__bp_priv__isControl', 1}, {'__bp_priv__isControlEscape', 2}, {'__bp_priv__isHexDigit', 1}, {'__bp_priv__pairsOf', 1}, {'__bp_priv__problemOf', 1}, {'__bp_priv__scan', 2}, {'__bp_priv__stripPrefix', 1}]}.
{attributes, []}.
{labels, 339}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@querystring.erl", 1}]}.
    {func_info, {atom, std@querystring}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 38}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 39}}.
  {label, 38}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 41}}.
  {label, 40}.
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
    {call, 2, {f, 43}}.
  {label, 41}.
  {label, 39}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@querystring.erl", 2}]}.
    {func_info, {atom, std@querystring}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 44}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 45}}.
  {label, 44}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 43}}.
    {jump, {f, 47}}.
  {label, 46}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 43}}.
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
    {call, 2, {f, 43}}.
  {label, 47}.
  {label, 45}.
    {deallocate, 6}.
    return.
%%% std/querystring — the query-string codec: RFC 3986 query components and
%%% the `application/x-www-form-urlencoded` flavour.
%%% 
%%% Reference:
%%%   RFC 3986 §2.1 (percent-encoding), §3.4 (query)
%%%   WHATWG URL — application/x-www-form-urlencoded (`+` is a space)
%%%   Node.js  — https://nodejs.org/api/querystring.html
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/uri_string.html
%%% 
%%% A codec, not a splitter. `parse` / `parseForm` split on `&`, each field
%%% on its FIRST `=` (a field with no `=` is a name with an empty value; an
%%% empty field is dropped), and percent-decode both sides; `parseForm`
%%% also reads `+` as a space, `parse` keeps it as a `+`. `stringify`
%%% percent-encodes every byte outside the RFC 3986 unreserved set, so its
%%% output reads back through either parser.
%%% 
%%% Refused, never kept as written (rakun's 03r-e rule, as a refusal): a `%`
%%% not followed by two hex digits, an escape sequence that is not UTF-8, and
%%% a control character (U+0000–U+001F, U+007F) — raw, or as the escape that
%%% would decode to one. A parser that can produce a newline is how a newline
%%% reaches a header. `stringify` refuses a control character too, so every
%%% text it writes is one `parse` reads back.
%%% 
%%% The percent codec is `encoding`'s (`percentEncode` / `percentDecode`),
%%% imported: the same bytes on commonJS and erlang, and the refusals above
%%% are decided in botopink before either cell runs.
% Strip an optional leading `?` from a URL's query portion. Idempotent.

{function, stripPrefix, 1, 7}.
  {label, 6}.
    {line, [{location, "std@querystring.erl", 3}]}.
    {func_info, {atom, std@querystring}, {atom, stripPrefix}, 1}.
  {label, 7}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"?">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 49}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 50}}.
  {label, 49}.
    {move, {atom, true}, {x, 0}}.
  {label, 50}.
    {test, is_eq, {f, 48}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 52}, 4}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, isHexDigit, 1, 9}.
  {label, 8}.
    {line, [{location, "std@querystring.erl", 4}]}.
    {func_info, {atom, std@querystring}, {atom, isHexDigit}, 1}.
  {label, 9}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 53}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 54}}.
  {label, 53}.
    {move, {atom, false}, {x, 0}}.
  {label, 54}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 55}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"0123456789abcdefABCDEF">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 57}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {atom, true}, {x, 0}}.
  {label, 58}.
    {jump, {f, 56}}.
  {label, 55}.
    {move, {atom, false}, {x, 0}}.
  {label, 56}.
    {deallocate, 3}.
    return.

{function, isControl, 1, 11}.
  {label, 10}.
    {line, [{location, "std@querystring.erl", 5}]}.
    {func_info, {atom, std@querystring}, {atom, isControl}, 1}.
  {label, 11}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 60}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_ge, {f, 70}, [{y, 1}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, false}, {x, 0}}.
  {label, 71}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 72}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 74}, [{y, 1}, {integer, 32}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {atom, false}, {x, 0}}.
  {label, 75}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 76}, [{x, 1}, {atom, true}]}.
    {test, is_eq_exact, {f, 78}, [{y, 1}, {integer, 127}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 78}.
    {move, {atom, false}, {x, 0}}.
  {label, 79}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {atom, true}, {x, 0}}.
  {label, 77}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {atom, false}, {x, 0}}.
  {label, 73}.
    {deallocate, 2}.
    return.
% Whether `%<h1><h2>` decodes to a control character: `%00`–`%1F` or `%7F`.
% A byte below 0x80 is never part of a multi-byte UTF-8 sequence, so the
% escape alone decides it.

{function, isControlEscape, 2, 13}.
  {label, 12}.
    {line, [{location, "std@querystring.erl", 6}]}.
    {func_info, {atom, std@querystring}, {atom, isControlEscape}, 2}.
  {label, 13}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"0">>}, {x, 0}}.
    {test, is_eq_exact, {f, 80}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {atom, false}, {x, 0}}.
  {label, 81}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 82}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"1">>}, {x, 0}}.
    {test, is_eq_exact, {f, 84}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {atom, false}, {x, 0}}.
  {label, 85}.
    {jump, {f, 83}}.
  {label, 82}.
    {move, {atom, true}, {x, 0}}.
  {label, 83}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 86}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"7">>}, {x, 0}}.
    {test, is_eq_exact, {f, 88}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 89}}.
  {label, 88}.
    {move, {atom, false}, {x, 0}}.
  {label, 89}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 90}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"f">>}, {x, 0}}.
    {test, is_eq_exact, {f, 92}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 92}.
    {move, {atom, false}, {x, 0}}.
  {label, 93}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 94}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"F">>}, {x, 0}}.
    {test, is_eq_exact, {f, 96}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 97}}.
  {label, 96}.
    {move, {atom, false}, {x, 0}}.
  {label, 97}.
    {jump, {f, 95}}.
  {label, 94}.
    {move, {atom, true}, {x, 0}}.
  {label, 95}.
    {jump, {f, 91}}.
  {label, 90}.
    {move, {atom, false}, {x, 0}}.
  {label, 91}.
    {jump, {f, 87}}.
  {label, 86}.
    {move, {atom, true}, {x, 0}}.
  {label, 87}.
    {deallocate, 2}.
    return.
% The first problem in one raw component from index `i`, or `""` when it may
% be decoded. Walks the string by `at`: a `%` reads its two digits by index,
% which a `split("")` piece list would only re-index.

{function, scan, 2, 15}.
  {label, 14}.
    {line, [{location, "std@querystring.erl", 7}]}.
    {func_info, {atom, std@querystring}, {atom, scan}, 2}.
  {label, 15}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 98}, [{y, 1}, {x, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 98}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 101}}.
    {test, is_ne_exact, {f, 99}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 123}}.
  {label, 99}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 123}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"%">>}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{y, 3}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 126}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 126}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 127}}.
  {label, 126}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/querystring.bp:59:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 127}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 101}}.
    {test, is_ne_exact, {f, 125}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 128}}.
  {label, 125}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 128}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 130}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 130}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 131}}.
  {label, 130}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/querystring.bp:60:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 131}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 101}}.
    {test, is_ne_exact, {f, 129}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 132}}.
  {label, 129}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 132}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 134}, [{x, 1}, {atom, true}]}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 9}}.
    {jump, {f, 135}}.
  {label, 134}.
    {move, {atom, false}, {x, 0}}.
  {label, 135}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 133}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"a `%` not followed by two hex digits">>}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 133}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call, 2, {f, 13}}.
    {test, is_eq, {f, 136}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"an escape that decodes to a control character">>}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 136}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 137}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 137}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 138}}.
  {label, 137}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/querystring.bp:65:26">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 138}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 2, {f, 15}, 12}.
  {label, 124}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test, is_eq, {f, 139}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"a control character">>}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 139}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 140}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 140}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 141}}.
  {label, 140}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/querystring.bp:68:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 141}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 2, {f, 15}, 12}.
% One raw component decoded, `+` first read as a space when `form`.

{function, decodeComponent, 2, 17}.
  {label, 16}.
    {line, [{location, "std@querystring.erl", 8}]}.
    {func_info, {atom, std@querystring}, {atom, decodeComponent}, 2}.
  {label, 17}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 142}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 145}}.
    {jump, {f, 143}}.
  {label, 142}.
    {move, {y, 0}, {x, 0}}.
  {label, 143}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 15}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 150}, [{y, 3}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"querystring.parse: ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 180}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 6}.
    return.
  {label, 150}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, std@encoding, percentDecode, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 184}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 185}}.
  {label, 184}.
    {move, {atom, false}, {x, 0}}.
  {label, 185}.
    {test, is_eq, {f, 183}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"querystring.parse: an escape sequence that is not UTF-8">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 6}.
    return.
  {label, 183}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 186}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 187}}.
  {label, 186}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 187}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 6}.
    return.
% One `name=value` field, split on its FIRST `=`.

{function, decodeField, 2, 19}.
  {label, 18}.
    {line, [{location, "std@querystring.erl", 9}]}.
    {func_info, {atom, std@querystring}, {atom, decodeField}, 2}.
  {label, 19}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 189}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_lt, {f, 202}, [{y, 2}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 203}}.
  {label, 202}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 3, {f, 52}}.
  {label, 203}.
    {move, {x, 0}, {y, 3}}.
    {test, is_lt, {f, 204}, [{y, 2}, {integer, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 205}}.
  {label, 204}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 206}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 206}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 207}}.
  {label, 206}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/querystring.bp:89:55">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 207}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 52}}.
  {label, 205}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 17}}.
    {test, is_tagged_tuple, {f, 208}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 209}}.
  {label, 208}.
    {deallocate, 10}.
    return.
  {label, 209}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 17}}.
    {test, is_tagged_tuple, {f, 210}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 211}}.
  {label, 210}.
    {deallocate, 10}.
    return.
  {label, 211}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 6}, {y, 7}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 10}.
    return.

{function, decodeFields, 4, 21}.
  {label, 20}.
    {line, [{location, "std@querystring.erl", 10}]}.
    {func_info, {atom, std@querystring}, {atom, decodeFields}, 4}.
  {label, 21}.
    {allocate, 11, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 212}, [{y, 1}, {x, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 11}.
    return.
  {label, 212}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 215}}.
    {test, is_ne_exact, {f, 213}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 218}}.
  {label, 213}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 218}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 19}}.
    {test, is_tagged_tuple, {f, 219}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 220}}.
  {label, 219}.
    {deallocate, 11}.
    return.
  {label, 220}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 221}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 221}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 222}}.
  {label, 221}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/querystring.bp:103:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 222}.
    {move, {x, 0}, {y, 6}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {y, 6}, {x, 1}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 4, {f, 21}, 11}.

{function, decodeBody, 2, 23}.
  {label, 22}.
    {line, [{location, "std@querystring.erl", 11}]}.
    {func_info, {atom, std@querystring}, {atom, decodeBody}, 2}.
  {label, 23}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"&">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 224}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 241}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 3}}.
    {move, {y, 1}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 4, {f, 21}, 6}.
% Parse a URL query (RFC 3986) into its ordered `#(name, value)` pairs, a
% leading `?` stripped. Duplicate names are kept in order (Node's
% `querystring.parse` folds them into arrays; the pair list leaves that to
% the caller). `+` is a `+` here — `parseForm` is the flavour that reads it
% as a space. A malformed escape, a non-UTF-8 escape sequence or a control
% character is an `Error`.

{function, parse, 1, 25}.
  {label, 24}.
    {line, [{location, "std@querystring.erl", 12}]}.
    {func_info, {atom, std@querystring}, {atom, parse}, 1}.
  {label, 25}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 23}, 1}.
% Parse an `application/x-www-form-urlencoded` body: `parse`'s rules with
% `+` read as a space before decoding. A form body is not a URL, so a
% leading `?` is data, not stripped.

{function, parseForm, 1, 27}.
  {label, 26}.
    {line, [{location, "std@querystring.erl", 13}]}.
    {func_info, {atom, std@querystring}, {atom, parseForm}, 1}.
  {label, 27}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 2, {f, 23}, 1}.

{function, hasControlFrom, 2, 29}.
  {label, 28}.
    {line, [{location, "std@querystring.erl", 14}]}.
    {func_info, {atom, std@querystring}, {atom, hasControlFrom}, 2}.
  {label, 29}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ge, {f, 244}, [{y, 1}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 244}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 101}}.
    {test, is_ne_exact, {f, 246}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 247}}.
  {label, 246}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 247}.
    {call, 1, {f, 11}}.
    {test, is_eq, {f, 245}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 245}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 248}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 248}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 249}}.
  {label, 248}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/querystring.bp:135:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 249}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 2, {f, 29}, 5}.

{function, hasControl, 1, 31}.
  {label, 30}.
    {line, [{location, "std@querystring.erl", 15}]}.
    {func_info, {atom, std@querystring}, {atom, hasControl}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 29}, 1}.
% Serialize ordered `#(name, value)` pairs: each side percent-encoded over
% the RFC 3986 unreserved set (a space is `%20`, a `+` is `%2B`, so the text
% reads back through `parse` and `parseForm` alike), joined with `&`. Empty
% input is `""`; there is no leading `?`. A control character in a name or a
% value is an `Error` — `parse` would refuse the text it became.

{function, stringify, 1, 33}.
  {label, 32}.
    {line, [{location, "std@querystring.erl", 16}]}.
    {func_info, {atom, std@querystring}, {atom, stringify}, 1}.
  {label, 33}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 251}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 254}, [{integer, 0}, {x, 0}]}.
    {move, {literal, <<"querystring.stringify: a control character">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 254}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 256}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"&">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 258}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────

{function, pairsOf, 1, 35}.
  {label, 34}.
    {line, [{location, "std@querystring.erl", 17}]}.
    {func_info, {atom, std@querystring}, {atom, pairsOf}, 1}.
  {label, 35}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 259}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 260}}.
  {label, 259}.
    {move, {y, 1}, {x, 0}}.
  {label, 260}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 262}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 258}, 6}.

{function, problemOf, 1, 37}.
  {label, 36}.
    {line, [{location, "std@querystring.erl", 18}]}.
    {func_info, {atom, std@querystring}, {atom, problemOf}, 1}.
  {label, 37}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 264}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 263}}.
  {label, 264}.
    {test, is_tagged_tuple, {f, 265}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 263}}.
  {label, 265}.
    {case_end, {x, 0}}.
  {label, 263}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, 'string_slice', 3, 52}.
  {label, 51}.
    {line, [{location, "std@querystring.erl", 19}]}.
    {func_info, {atom, std@querystring}, {atom, 'string_slice'}, 3}.
  {label, 52}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 266}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 268}, 3}.
  {label, 266}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 290}, 3}.

{function, '__bp_priv__array_range', 2, 308}.
  {label, 307}.
    {line, [{location, "std@querystring.erl", 21}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 308}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 310}.
  {label, 309}.
    {line, [{location, "std@querystring.erl", 22}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 310}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 312}.
  {label, 311}.
    {line, [{location, "std@querystring.erl", 23}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 312}.
    {call_only, 3, {f, 52}}.

{function, '__bp_priv__decodeBody', 2, 314}.
  {label, 313}.
    {line, [{location, "std@querystring.erl", 24}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__decodeBody'}, 2}.
  {label, 314}.
    {call_only, 2, {f, 23}}.

{function, '__bp_priv__decodeComponent', 2, 316}.
  {label, 315}.
    {line, [{location, "std@querystring.erl", 25}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__decodeComponent'}, 2}.
  {label, 316}.
    {call_only, 2, {f, 17}}.

{function, '__bp_priv__decodeField', 2, 318}.
  {label, 317}.
    {line, [{location, "std@querystring.erl", 26}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__decodeField'}, 2}.
  {label, 318}.
    {call_only, 2, {f, 19}}.

{function, '__bp_priv__decodeFields', 4, 320}.
  {label, 319}.
    {line, [{location, "std@querystring.erl", 27}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__decodeFields'}, 4}.
  {label, 320}.
    {call_only, 4, {f, 21}}.

{function, '__bp_priv__hasControl', 1, 322}.
  {label, 321}.
    {line, [{location, "std@querystring.erl", 28}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__hasControl'}, 1}.
  {label, 322}.
    {call_only, 1, {f, 31}}.

{function, '__bp_priv__hasControlFrom', 2, 324}.
  {label, 323}.
    {line, [{location, "std@querystring.erl", 29}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__hasControlFrom'}, 2}.
  {label, 324}.
    {call_only, 2, {f, 29}}.

{function, '__bp_priv__isControl', 1, 326}.
  {label, 325}.
    {line, [{location, "std@querystring.erl", 30}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__isControl'}, 1}.
  {label, 326}.
    {call_only, 1, {f, 11}}.

{function, '__bp_priv__isControlEscape', 2, 328}.
  {label, 327}.
    {line, [{location, "std@querystring.erl", 31}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__isControlEscape'}, 2}.
  {label, 328}.
    {call_only, 2, {f, 13}}.

{function, '__bp_priv__isHexDigit', 1, 330}.
  {label, 329}.
    {line, [{location, "std@querystring.erl", 32}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__isHexDigit'}, 1}.
  {label, 330}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__pairsOf', 1, 332}.
  {label, 331}.
    {line, [{location, "std@querystring.erl", 33}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__pairsOf'}, 1}.
  {label, 332}.
    {call_only, 1, {f, 35}}.

{function, '__bp_priv__problemOf', 1, 334}.
  {label, 333}.
    {line, [{location, "std@querystring.erl", 34}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__problemOf'}, 1}.
  {label, 334}.
    {call_only, 1, {f, 37}}.

{function, '__bp_priv__scan', 2, 336}.
  {label, 335}.
    {line, [{location, "std@querystring.erl", 35}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__scan'}, 2}.
  {label, 336}.
    {call_only, 2, {f, 15}}.

{function, '__bp_priv__stripPrefix', 1, 338}.
  {label, 337}.
    {line, [{location, "std@querystring.erl", 36}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_priv__stripPrefix'}, 1}.
  {label, 338}.
    {call_only, 1, {f, 7}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 64}.
  {label, 63}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 64}.
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
    {gc_bif, length, {f, 68}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_lt, {f, 68}, [{x, 0}, {x, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 68}, [{x, 0}, {x, 1}]}.
    {jump, {f, 69}}.
  {label, 69}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 5}.
  {label, 68}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_0', 2, 60}.
  {label, 59}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_0'}, 2}.
  {label, 60}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 105}.
  {label, 104}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 105}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 109}}.
  {label, 109}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 111}}.
  {label, 111}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 112}}.
  {label, 113}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 114}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {y, 6}}.
    {jump, {f, 112}}.
  {label, 114}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 112}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 116}}.
  {label, 116}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 119}}.
  {label, 117}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 119}}.
  {label, 118}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 119}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 121}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nth, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 8}.
  {label, 121}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 122}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 122}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_1', 2, 101}.
  {label, 100}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_1'}, 2}.
  {label, 101}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 105}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_2-t/3-fun-0-', 3, 149}.
  {label, 148}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_2-t/3-fun-0-'}, 3}.
  {label, 149}.
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

{function, '__bp_tpl_2', 3, 145}.
  {label, 144}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_2'}, 3}.
  {label, 145}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 149}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_print', 1, 152}.
  {label, 151}.
    {line, [{location, "std@querystring.erl", 9}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_print'}, 1}.
  {label, 152}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 156}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 156}.
  {label, 155}.
    {line, [{location, "std@querystring.erl", 9}]}.
    {func_info, {atom, std@querystring}, {atom, '-bp_show_top-'}, 1}.
  {label, 156}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 154}}.

{function, '-bp_show_elem-', 1, 158}.
  {label, 157}.
    {line, [{location, "std@querystring.erl", 9}]}.
    {func_info, {atom, std@querystring}, {atom, '-bp_show_elem-'}, 1}.
  {label, 158}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 154}}.

{function, '__bp_show', 2, 154}.
  {label, 153}.
    {line, [{location, "std@querystring.erl", 9}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_show'}, 2}.
  {label, 154}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 166}, [{x, 0}]}.
    {test, is_eq, {f, 165}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 165}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 166}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 167}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 158}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 167}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 169}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 168}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 168}, [{x, 0}]}.
    {test, is_ne_exact, {f, 168}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 168}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 168}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 173}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 174}}.
  {label, 173}.
    {test, is_eq_exact, {f, 170}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 174}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 154}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 168}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 158}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 169}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 171}, [{x, 0}]}.
    {test, is_ne_exact, {f, 171}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 171}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 172}, [{x, 0}, {atom, undefined}]}.
  {label, 170}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 160}, 2}.
  {label, 171}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 172}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 160}.
  {label, 159}.
    {line, [{location, "std@querystring.erl", 9}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tagged'}, 2}.
  {label, 160}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 175}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 175}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 175}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 176}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 162}, 3}.
  {label, 176}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 162}.
  {label, 161}.
    {line, [{location, "std@querystring.erl", 9}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_render'}, 1}.
  {label, 162}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 177}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 177}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 178}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 178}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 164}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 164}.
  {label, 163}.
    {line, [{location, "std@querystring.erl", 9}]}.
    {func_info, {atom, std@querystring}, {atom, '-bp_render_pair-'}, 1}.
  {label, 164}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 154}}.
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

{function, '-bp_stringify-', 1, 180}.
  {label, 179}.
    {line, [{location, "std@querystring.erl", 9}]}.
    {func_info, {atom, std@querystring}, {atom, '-bp_stringify-'}, 1}.
  {label, 180}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 181}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 181}.
    {test, is_integer, {f, 182}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 182}.
    {call, 1, {f, 156}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_3-t/2-fun-0-', 2, 193}.
  {label, 192}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_3-t/2-fun-0-'}, 2}.
  {label, 193}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 197}, [{x, 0}, {literal, <<"">>}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 197}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 200}, [{x, 0}, {atom, nomatch}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 200}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 201}, [{x, 0}]}.
    {test, test_arity, {f, 201}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 6}.
  {label, 201}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_3', 2, 189}.
  {label, 188}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_3'}, 2}.
  {label, 189}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 193}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-bp_at-', 2, 215}.
  {label, 214}.
    {line, [{location, "std@querystring.erl", 11}]}.
    {func_info, {atom, std@querystring}, {atom, '-bp_at-'}, 2}.
  {label, 215}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 217}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 216}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 217}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 216}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 216}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 228}.
  {label, 227}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 228}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 230}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 232}, [{x, 0}]}.
    {jump, {f, 233}}.
  {label, 232}.
    {test, is_tuple, {f, 234}, [{x, 0}]}.
    {test, test_arity, {f, 234}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 233}}.
  {label, 234}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 233}.
    {move, {x, 0}, {y, 4}}.
  {label, 235}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 236}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 238}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 238}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 239}}.
  {label, 238}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 239}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 235}}.
  {label, 236}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 237}, [{x, 0}]}.
    {jump, {f, 231}}.
  {label, 237}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 231}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 230}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_4', 2, 224}.
  {label, 223}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_4'}, 2}.
  {label, 224}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 228}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-decodeBody/2-fun-0-', 1, 241}.
  {label, 240}.
    {line, [{location, "std@querystring.erl", 12}]}.
    {func_info, {atom, std@querystring}, {atom, '-decodeBody/2-fun-0-'}, 1}.
  {label, 241}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 242}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 243}}.
  {label, 242}.
    {move, {atom, false}, {x, 0}}.
  {label, 243}.
    {deallocate, 1}.
    return.

{function, '-stringify/1-fun-1-', 1, 251}.
  {label, 250}.
    {line, [{location, "std@querystring.erl", 17}]}.
    {func_info, {atom, std@querystring}, {atom, '-stringify/1-fun-1-'}, 1}.
  {label, 251}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call, 1, {f, 31}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 252}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call, 1, {f, 31}}.
    {jump, {f, 253}}.
  {label, 252}.
    {move, {atom, true}, {x, 0}}.
  {label, 253}.
    {deallocate, 3}.
    return.

{function, '-bp_join-', 2, 258}.
  {label, 257}.
    {line, [{location, "std@querystring.erl", 17}]}.
    {func_info, {atom, std@querystring}, {atom, '-bp_join-'}, 2}.
  {label, 258}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 180}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '-stringify/1-fun-2-', 1, 256}.
  {label, 255}.
    {line, [{location, "std@querystring.erl", 17}]}.
    {func_info, {atom, std@querystring}, {atom, '-stringify/1-fun-2-'}, 1}.
  {label, 256}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, uri_string, quote, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, uri_string, quote, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 258}}.
    {deallocate, 4}.
    return.

{function, '-pairsOf/1-fun-3-', 1, 262}.
  {label, 261}.
    {line, [{location, "std@querystring.erl", 18}]}.
    {func_info, {atom, std@querystring}, {atom, '-pairsOf/1-fun-3-'}, 1}.
  {label, 262}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"=>">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 258}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_5-t/3-fun-0-', 3, 272}.
  {label, 271}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_5-t/3-fun-0-'}, 3}.
  {label, 272}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 276}}.
  {label, 276}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 278}}.
  {label, 278}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 280}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 279}}.
  {label, 280}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 281}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 279}}.
  {label, 281}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 279}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 283}}.
  {label, 283}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 285}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 284}}.
  {label, 285}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 286}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 284}}.
  {label, 286}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 284}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 288}}.
  {label, 288}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_5', 3, 268}.
  {label, 267}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_5'}, 3}.
  {label, 268}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 272}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_6-t/2-fun-0-', 2, 294}.
  {label, 293}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_6-t/2-fun-0-'}, 2}.
  {label, 294}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 298}}.
  {label, 298}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 300}}.
  {label, 300}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 302}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 301}}.
  {label, 302}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 303}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 301}}.
  {label, 303}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 301}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 305}}.
  {label, 305}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_6', 2, 290}.
  {label, 289}.
    {func_info, {atom, std@querystring}, {atom, '__bp_tpl_6'}, 2}.
  {label, 290}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 294}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 43}.
  {label, 42}.
    {line, [{location, "std@querystring.erl", 20}]}.
    {func_info, {atom, std@querystring}, {atom, '__bp_prim_append'}, 2}.
  {label, 43}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 306}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 306}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
