{module, std@url}.
{exports, [{parse, 1}, {serialize, 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}, {'__bp_priv__charToDigit', 1}, {'__bp_priv__intToDecimal', 1}, {'__bp_priv__parsePort', 1}, {'__bp_priv__parsePortWalk', 3}, {'__bp_priv__splitOnce', 2}]}.
{attributes, []}.
{labels, 208}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@url.erl", 1}]}.
    {func_info, {atom, std@url}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 20}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 22}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
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
    {call, 2, {f, 25}}.
  {label, 23}.
  {label, 21}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@url.erl", 2}]}.
    {func_info, {atom, std@url}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 26}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 25}}.
    {jump, {f, 29}}.
  {label, 28}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 25}}.
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
    {call, 2, {f, 25}}.
  {label, 29}.
  {label, 27}.
    {deallocate, 6}.
    return.
%%% std/url — pure-botopink URL parsing.
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/url.html
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/uri_string.html
%%% 
%%% The surface is `parse(s)` → `Url` and `serialize(u)` → `string`. Both
%%% are pure botopink — no host call — so the module works on every
%%% backend including wat. Parsing handles the standard authority shape
%%% 
%%%     scheme://[user[:password]@]host[:port][/path][?query][#fragment]
%%% 
%%% Authentication and port are optional; missing pieces come back as
%%% `""` (string fields) or `0` (port). URI percent-encoding is NOT
%%% applied here — pair this with `querystring` for form values.
% Internal: split `s` at the first occurrence of `delim`. Returns
% `#(head, tail)` where `tail` excludes the delimiter. If `delim` is
% not present, `head = s` and `tail = ""`. Implemented via
% `String.split` (which splits on all occurrences) + a rejoin of the
% tail with the delimiter — avoids `String.indexOf` whose Erlang host
% binding (`string:str/2`) is deprecated and reds with `function_clause`
% on binaries in OTP 25+.

{function, splitOnce, 2, 7}.
  {label, 6}.
    {line, [{location, "std@url.erl", 3}]}.
    {func_info, {atom, std@url}, {atom, splitOnce}, 2}.
  {label, 7}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 47}, [{x, 0}, {integer, 2}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {x, 0}]}}.
    {deallocate, 7}.
    return.
  {label, 47}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 50}}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 53}}.
  {label, 48}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 53}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{integer, 1}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 55}}.
  {label, 54}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 55}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 57}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 4}, {y, 6}]}}.
    {deallocate, 7}.
    return.
% Parse a URL into its component fields. Pure botopink — no host call.
% Defaults: empty strings for absent text fields; 0 for absent port.

{function, parse, 1, 9}.
  {label, 8}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, parse}, 1}.
  {label, 9}.
    {allocate, 26, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"://">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"#">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"?">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 8}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 10}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 90}, [{y, 12}, {x, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 91}}.
  {label, 90}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 57}}.
  {label, 91}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, <<"@">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 11}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 92}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 92}.
    {move, {atom, false}, {x, 0}}.
  {label, 93}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_eq, {f, 94}, [{x, 0}, {atom, true}]}.
    {move, {y, 15}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {jump, {f, 95}}.
  {label, 94}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 95}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 16}, {x, 0}}.
    {test, is_eq, {f, 96}, [{x, 0}, {atom, true}]}.
    {move, {y, 15}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {jump, {f, 97}}.
  {label, 96}.
    {move, {y, 11}, {x, 0}}.
  {label, 97}.
    {move, {x, 0}, {y, 18}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 17}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 19}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 19}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 21}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 18}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 22}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 24}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {x, 0}, {y, 25}}.
    {test_heap, 10, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@url@@Url}, {y, 2}, {y, 20}, {y, 21}, {y, 23}, {y, 25}, {y, 14}, {y, 9}, {y, 6}]}}.
    {deallocate, 26}.
    return.
% Internal: parse a numeric port from a string. Returns 0 on empty or
% malformed input. Pure botopink — walks each char via a tail-recursive
% helper that uses `String.slice(i, i+1)` to read one char at a time.
% `s.split("")` would give per-char chunks on Node (JS) but on Erlang
% `string:split(S, <<"">>, all)` returns `[S]` (a single chunk), so the
% slice form is the cross-backend portable shape.

{function, parsePort, 1, 11}.
  {label, 10}.
    {line, [{location, "std@url.erl", 5}]}.
    {func_info, {atom, std@url}, {atom, parsePort}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 98}, [{y, 0}, {x, 0}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 98}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 3, {f, 13}, 1}.

{function, parsePortWalk, 3, 13}.
  {label, 12}.
    {line, [{location, "std@url.erl", 6}]}.
    {func_info, {atom, std@url}, {atom, parsePortWalk}, 3}.
  {label, 13}.
    {allocate, 8, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 101}}.
    {test, is_ge, {f, 99}, [{y, 1}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 99}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 104}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 104}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 105}}.
  {label, 104}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/url.bp:103:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 105}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 103}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 106}, [{y, 4}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 107}}.
  {label, 106}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {integer, 10}], {x, 0}}.
    {test, is_ge, {f, 108}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 108}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 109}}.
  {label, 108}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/url.bp:105:47">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 109}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 4}], {x, 0}}.
    {test, is_ge, {f, 110}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 110}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 111}}.
  {label, 110}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/url.bp:105:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 111}.
  {label, 107}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 112}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 112}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 113}}.
  {label, 112}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/url.bp:106:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 113}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 3, {f, 13}, 8}.
% Internal: render an i32 as a decimal string by piggy-backing on
% `array<i32>.join("")` — both backends stringify numeric elements
% for `join`: Node's `Array.prototype.join` calls `String(n)` per
% element and Erlang's `lists:join` + iolist-to-binary path maps
% `is_integer(__E) -> integer_to_binary(__E)`. The single-element
% array `[n].join("")` is therefore equivalent to a host
% `int_to_string(n)` on every backend, with no hand-rolled walk
% that would have to dodge i32 division being float on Node.

{function, intToDecimal, 1, 15}.
  {label, 14}.
    {line, [{location, "std@url.erl", 7}]}.
    {func_info, {atom, std@url}, {atom, intToDecimal}, 1}.
  {label, 15}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 57}, 2}.

{function, charToDigit, 1, 17}.
  {label, 16}.
    {line, [{location, "std@url.erl", 8}]}.
    {func_info, {atom, std@url}, {atom, charToDigit}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"0">>}, {x, 0}}.
    {test, is_eq_exact, {f, 114}, [{y, 0}, {x, 0}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 114}.
    {move, {literal, <<"1">>}, {x, 0}}.
    {test, is_eq_exact, {f, 115}, [{y, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 115}.
    {move, {literal, <<"2">>}, {x, 0}}.
    {test, is_eq_exact, {f, 116}, [{y, 0}, {x, 0}]}.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 116}.
    {move, {literal, <<"3">>}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{y, 0}, {x, 0}]}.
    {move, {integer, 3}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 117}.
    {move, {literal, <<"4">>}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{y, 0}, {x, 0}]}.
    {move, {integer, 4}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 118}.
    {move, {literal, <<"5">>}, {x, 0}}.
    {test, is_eq_exact, {f, 119}, [{y, 0}, {x, 0}]}.
    {move, {integer, 5}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 119}.
    {move, {literal, <<"6">>}, {x, 0}}.
    {test, is_eq_exact, {f, 120}, [{y, 0}, {x, 0}]}.
    {move, {integer, 6}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 120}.
    {move, {literal, <<"7">>}, {x, 0}}.
    {test, is_eq_exact, {f, 121}, [{y, 0}, {x, 0}]}.
    {move, {integer, 7}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 121}.
    {move, {literal, <<"8">>}, {x, 0}}.
    {test, is_eq_exact, {f, 122}, [{y, 0}, {x, 0}]}.
    {move, {integer, 8}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 122}.
    {move, {literal, <<"9">>}, {x, 0}}.
    {test, is_eq_exact, {f, 123}, [{y, 0}, {x, 0}]}.
    {move, {integer, 9}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 123}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 124}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 124}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 125}}.
  {label, 124}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/url.bp:132:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 125}.
    {deallocate, 1}.
    return.
% Serialize a `Url` back to the standard
% `scheme://[user[:password]@]host[:port][/path][?query][#fragment]`
% shape. Inverse of `parse` on every valid URL the parser produces.
% String concat uses the cross-backend `[a, b].join("")` workaround
% (raw `+` on strings is numeric on Erlang — badarith on binaries).

{function, serialize, 1, 19}.
  {label, 18}.
    {line, [{location, "std@url.erl", 9}]}.
    {func_info, {atom, std@url}, {atom, serialize}, 1}.
  {label, 19}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 127}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 127}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 126}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 128}}.
  {label, 126}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 130}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 130}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 129}, [{x, 1}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"@">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 132}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 132}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 57}}.
    {jump, {f, 131}}.
  {label, 129}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"@">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 133}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 133}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 134}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 134}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 57}}.
  {label, 131}.
  {label, 128}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 136}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 136}.
    {test, is_eq_exact, {f, 135}, [{x, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 138}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 138}.
    {jump, {f, 137}}.
  {label, 135}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 139}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 139}.
    {call, 1, {f, 15}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<":">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 140}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 140}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 57}}.
  {label, 137}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 142}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 7, {x, 0}}.
  {label, 142}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 141}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 143}}.
  {label, 141}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 144}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 7, {x, 0}}.
  {label, 144}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"?">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 57}}.
  {label, 143}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 146}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 8, {x, 0}}.
  {label, 146}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 145}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 147}}.
  {label, 145}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 148}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 8, {x, 0}}.
  {label, 148}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"#">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 57}}.
  {label, 147}.
    {move, {x, 0}, {y, 9}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 149}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 149}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"://">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 150}, [{x, 0}, 9, {atom, std@url@@Url}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 150}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 57}, 13}.
% ── tests ────────────────────────────────────────────────────────────────────

{function, 'string_slice', 3, 103}.
  {label, 102}.
    {line, [{location, "std@url.erl", 10}]}.
    {func_info, {atom, std@url}, {atom, 'string_slice'}, 3}.
  {label, 103}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 151}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 153}, 3}.
  {label, 151}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 175}, 3}.

{function, '__bp_priv__array_range', 2, 193}.
  {label, 192}.
    {line, [{location, "std@url.erl", 12}]}.
    {func_info, {atom, std@url}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 193}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 195}.
  {label, 194}.
    {line, [{location, "std@url.erl", 13}]}.
    {func_info, {atom, std@url}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 195}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 197}.
  {label, 196}.
    {line, [{location, "std@url.erl", 14}]}.
    {func_info, {atom, std@url}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 197}.
    {call_only, 3, {f, 103}}.

{function, '__bp_priv__charToDigit', 1, 199}.
  {label, 198}.
    {line, [{location, "std@url.erl", 15}]}.
    {func_info, {atom, std@url}, {atom, '__bp_priv__charToDigit'}, 1}.
  {label, 199}.
    {call_only, 1, {f, 17}}.

{function, '__bp_priv__intToDecimal', 1, 201}.
  {label, 200}.
    {line, [{location, "std@url.erl", 16}]}.
    {func_info, {atom, std@url}, {atom, '__bp_priv__intToDecimal'}, 1}.
  {label, 201}.
    {call_only, 1, {f, 15}}.

{function, '__bp_priv__parsePort', 1, 203}.
  {label, 202}.
    {line, [{location, "std@url.erl", 17}]}.
    {func_info, {atom, std@url}, {atom, '__bp_priv__parsePort'}, 1}.
  {label, 203}.
    {call_only, 1, {f, 11}}.

{function, '__bp_priv__parsePortWalk', 3, 205}.
  {label, 204}.
    {line, [{location, "std@url.erl", 18}]}.
    {func_info, {atom, std@url}, {atom, '__bp_priv__parsePortWalk'}, 3}.
  {label, 205}.
    {call_only, 3, {f, 13}}.

{function, '__bp_priv__splitOnce', 2, 207}.
  {label, 206}.
    {line, [{location, "std@url.erl", 19}]}.
    {func_info, {atom, std@url}, {atom, '__bp_priv__splitOnce'}, 2}.
  {label, 207}.
    {call_only, 2, {f, 7}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 35}.
  {label, 34}.
    {func_info, {atom, std@url}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 35}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 37}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 39}, [{x, 0}]}.
    {jump, {f, 40}}.
  {label, 39}.
    {test, is_tuple, {f, 41}, [{x, 0}]}.
    {test, test_arity, {f, 41}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 40}}.
  {label, 41}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 40}.
    {move, {x, 0}, {y, 4}}.
  {label, 42}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 43}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 45}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 45}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 46}}.
  {label, 45}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 46}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 42}}.
  {label, 43}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 44}, [{x, 0}]}.
    {jump, {f, 38}}.
  {label, 44}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 38}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 37}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_0', 2, 31}.
  {label, 30}.
    {func_info, {atom, std@url}, {atom, '__bp_tpl_0'}, 2}.
  {label, 31}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-bp_at-', 2, 50}.
  {label, 49}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '-bp_at-'}, 2}.
  {label, 50}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 52}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 51}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 52}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 51}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 51}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 59}.
  {label, 58}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '__bp_print'}, 1}.
  {label, 59}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 63}.
  {label, 62}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '-bp_show_top-'}, 1}.
  {label, 63}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 61}}.

{function, '-bp_show_elem-', 1, 65}.
  {label, 64}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '-bp_show_elem-'}, 1}.
  {label, 65}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 61}}.

{function, '__bp_show', 2, 61}.
  {label, 60}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '__bp_show'}, 2}.
  {label, 61}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 73}, [{x, 0}]}.
    {test, is_eq, {f, 72}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 72}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 73}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 74}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 74}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 76}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 75}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 75}, [{x, 0}]}.
    {test, is_ne_exact, {f, 75}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 75}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 75}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 81}}.
  {label, 80}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 81}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 61}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 75}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 76}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 78}, [{x, 0}]}.
    {test, is_ne_exact, {f, 78}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 78}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 79}, [{x, 0}, {atom, undefined}]}.
  {label, 77}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 67}, 2}.
  {label, 78}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 79}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 67}.
  {label, 66}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '__bp_tagged'}, 2}.
  {label, 67}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 82}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 82}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 82}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 83}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 69}, 3}.
  {label, 83}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 69}.
  {label, 68}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '__bp_render'}, 1}.
  {label, 69}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 84}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 85}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 85}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 71}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 71}.
  {label, 70}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '-bp_render_pair-'}, 1}.
  {label, 71}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 61}}.
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

{function, '-bp_stringify-', 1, 87}.
  {label, 86}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '-bp_stringify-'}, 1}.
  {label, 87}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 88}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 88}.
    {test, is_integer, {f, 89}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 89}.
    {call, 1, {f, 63}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 57}.
  {label, 56}.
    {line, [{location, "std@url.erl", 4}]}.
    {func_info, {atom, std@url}, {atom, '-bp_join-'}, 2}.
  {label, 57}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 87}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '__bp_tpl_1', 1, 101}.
  {label, 100}.
    {func_info, {atom, std@url}, {atom, '__bp_tpl_1'}, 1}.
  {label, 101}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '__bp_tpl_2-t/3-fun-0-', 3, 157}.
  {label, 156}.
    {func_info, {atom, std@url}, {atom, '__bp_tpl_2-t/3-fun-0-'}, 3}.
  {label, 157}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 161}}.
  {label, 161}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 163}}.
  {label, 163}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 165}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 164}}.
  {label, 165}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 166}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 164}}.
  {label, 166}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 164}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 168}}.
  {label, 168}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 170}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 169}}.
  {label, 170}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 171}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 169}}.
  {label, 171}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 169}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 173}}.
  {label, 173}.
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

{function, '__bp_tpl_2', 3, 153}.
  {label, 152}.
    {func_info, {atom, std@url}, {atom, '__bp_tpl_2'}, 3}.
  {label, 153}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 157}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_3-t/2-fun-0-', 2, 179}.
  {label, 178}.
    {func_info, {atom, std@url}, {atom, '__bp_tpl_3-t/2-fun-0-'}, 2}.
  {label, 179}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 183}}.
  {label, 183}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 185}}.
  {label, 185}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 187}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 186}}.
  {label, 187}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 188}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 186}}.
  {label, 188}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 186}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 190}}.
  {label, 190}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_3', 2, 175}.
  {label, 174}.
    {func_info, {atom, std@url}, {atom, '__bp_tpl_3'}, 2}.
  {label, 175}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 179}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 25}.
  {label, 24}.
    {line, [{location, "std@url.erl", 11}]}.
    {func_info, {atom, std@url}, {atom, '__bp_prim_append'}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 191}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 191}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
