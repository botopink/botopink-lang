{module, std@unicode}.
{exports, [{fromCodepoint, 1}, {firstCodepoint, 1}, {codepoints, 1}, {normalize, 2}, {'__bp_priv__array_all', 2}, {'__bp_priv__array_count', 2}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__canonicalOrder', 1}, {'__bp_priv__codepointsBody', 1}, {'__bp_priv__codes', 1}, {'__bp_priv__decompose', 2}, {'__bp_priv__firstCodepointOrZeroBody', 1}, {'__bp_priv__fullDecomposition', 2}, {'__bp_priv__hangulDecomposition', 1}, {'__bp_priv__hangulLBase', 0}, {'__bp_priv__hangulLCount', 0}, {'__bp_priv__hangulNCount', 0}, {'__bp_priv__hangulSBase', 0}, {'__bp_priv__hangulSCount', 0}, {'__bp_priv__hangulTBase', 0}, {'__bp_priv__hangulTCount', 0}, {'__bp_priv__hangulVBase', 0}, {'__bp_priv__hangulVCount', 0}, {'__bp_priv__insertByClass', 3}, {'__bp_priv__isHangulSyllable', 1}, {'__bp_priv__primaryComposite', 2}, {'__bp_priv__recompose', 1}, {'__bp_priv__text', 1}, {'__bp_priv__withStarter', 3}]}.
{attributes, []}.
{labels, 345}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@unicode.erl", 1}]}.
    {func_info, {atom, std@unicode}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 60}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 61}}.
  {label, 60}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
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
    {call, 2, {f, 65}}.
  {label, 63}.
  {label, 61}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@unicode.erl", 2}]}.
    {func_info, {atom, std@unicode}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 66}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 67}}.
  {label, 66}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 65}}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 65}}.
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
    {call, 2, {f, 65}}.
  {label, 69}.
  {label, 67}.
    {deallocate, 6}.
    return.
%%% std/unicode — Unicode codepoint primitives and normalization, cross-backend.
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/
%%%              (`String.prototype.codePointAt`, `String.fromCodePoint`)
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/unicode.html
%%%              (`unicode:characters_to_list`)
%%%   UAX #15  — https://www.unicode.org/reports/tr15/ (normalization forms)
%%% 
%%% `codepoints(s)` decomposes a string into its sequence of Unicode
%%% codepoints (the i32 representation each backend hands back as an
%%% integer). `fromCodepoint(cp)` lifts a single codepoint to a string
%%% through the primitive `String.fromCodepoint` (a `fn:` body on every
%%% target); `firstCodepoint(s)` peeks the head. The carry-forward declares use
%%% the typed `#[compiler.external(.<Target>)]` annotation form (migrated in
%%% `external-target-libs-migration` F5-partial, c828308).
%%% 
%%% `normalize(s, form)` renders `s` under NFC, NFD, NFKC or NFKD by std's
%%% own botopink body on all four targets (decision 333 (A)) — no host
%%% normalizer is asked, so every target answers the same for every code
%%% point, under the one Unicode version `unicode_tables.bp` was generated
%%% from (`zig build gen-unicode`, `libs/std/AGENTS.md` § unicode): decompose
%%% (recursively; compatibility mappings too for NFKC / NFKD), put each run
%%% of non-starters in canonical order (a stable sort by combining class),
%%% then, for NFC / NFKC, recompose every unblocked pair whose primary
%%% composite is not excluded. Hangul syllables decompose and compose by the
%%% algorithm of Unicode §3.12, not by the tables.
% The one-character string of the scalar value `cp` (decision 262): every
% target runs this body, a call of the primitive `string.fromCodepoint`, so a
% `cp` that is no Unicode scalar value — negative, a surrogate, past U+10FFFF —
% aborts the program the same way everywhere.

{function, fromCodepoint, 1, 7}.
  {label, 6}.
    {line, [{location, "std@unicode.erl", 3}]}.
    {func_info, {atom, std@unicode}, {atom, fromCodepoint}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 71}, 1}.
% wasm's cell: a wasm string is UTF-8 indexed by code point (decision 240),
% so `charCodeAt(0)` of its first character IS the code point.

{function, firstCodepointOrZeroBody, 1, 9}.
  {label, 8}.
    {line, [{location, "std@unicode.erl", 4}]}.
    {func_info, {atom, std@unicode}, {atom, firstCodepointOrZeroBody}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {integer, 0}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 76}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 78}, 1}.
% First codepoint of `s`, or `null` for the empty string. Implemented
% in pure botopink over `firstCodepointOrZero` + a length check —
% keeps the host call to a single template invocation and lets the
% option wrapping shape match the rest of std.

{function, firstCodepoint, 1, 11}.
  {label, 10}.
    {line, [{location, "std@unicode.erl", 5}]}.
    {func_info, {atom, std@unicode}, {atom, firstCodepoint}, 1}.
  {label, 11}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 88}, [{x, 0}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 88}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 90}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
% Decompose a string into its sequence of Unicode codepoints.
% Node: `Array.from($0).map(c => c.codePointAt(0))` — `Array.from` on
% a string iterates by codepoint (not by UTF-16 unit), and the comma
% operator inside the arrow body keeps the expression a single template
% substitution. Erlang: `unicode:characters_to_list/2` returns an
% integer list of codepoints when given a UTF-8 binary.

{function, codepoints, 1, 59}.
  {label, 58}.
    {line, [{location, "std@unicode.erl", 6}]}.
    {func_info, {atom, std@unicode}, {atom, codepoints}, 1}.
  {label, 59}.
    {call_only, 1, {f, 57}}.
% wasm's cell: one code point per character (decision 240).

{function, codepointsBody, 1, 13}.
  {label, 12}.
    {line, [{location, "std@unicode.erl", 7}]}.
    {func_info, {atom, std@unicode}, {atom, codepointsBody}, 1}.
  {label, 13}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 100}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 110}, 0, 0, {x, 0}, {list, []}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 3}.
% Which Unicode normalization form to apply (NFC, NFD, NFKC, NFKD).
% Render `s` under the normalization form `form` (UAX #15). Text whose code
% points are all below U+00A0 is the same under every form and comes back
% as it is.

{function, normalize, 2, 15}.
  {label, 14}.
    {line, [{location, "std@unicode.erl", 8}]}.
    {func_info, {atom, std@unicode}, {atom, normalize}, 2}.
  {label, 15}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 115}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 113}}.
    {test, is_eq, {f, 111}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 111}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 119}, [{x, 0}, {atom, std@unicode@@NormalizationForm__v__nfkc}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 118}}.
  {label, 119}.
    {test, is_eq, {f, 120}, [{x, 0}, {atom, std@unicode@@NormalizationForm__v__nfkd}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 118}}.
  {label, 120}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 118}}.
  {label, 118}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 122}, [{x, 0}, {atom, std@unicode@@NormalizationForm__v__nfc}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 121}}.
  {label, 122}.
    {test, is_eq, {f, 123}, [{x, 0}, {atom, std@unicode@@NormalizationForm__v__nfkc}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 121}}.
  {label, 123}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 121}}.
  {label, 121}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 41}}.
    {call, 1, {f, 43}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq, {f, 124}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 47}}.
    {jump, {f, 125}}.
  {label, 124}.
    {move, {y, 5}, {x, 0}}.
  {label, 125}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 127}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 129}, 13}.
% ── the algorithm ────────────────────────────────────────────────────────────
% Hangul (Unicode §3.12): the syllables U+AC00…U+D7A3 are LV or LVT
% sequences of the conjoining jamo L U+1100…, V U+1161…, T U+11A7… (T index
% 0 is "no trailing consonant").

{function, hangulSBase, 0, 17}.
  {label, 16}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, hangulSBase}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {integer, 44032}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hangulLBase, 0, 19}.
  {label, 18}.
    {line, [{location, "std@unicode.erl", 10}]}.
    {func_info, {atom, std@unicode}, {atom, hangulLBase}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {integer, 4352}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hangulVBase, 0, 21}.
  {label, 20}.
    {line, [{location, "std@unicode.erl", 11}]}.
    {func_info, {atom, std@unicode}, {atom, hangulVBase}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {integer, 4449}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hangulTBase, 0, 23}.
  {label, 22}.
    {line, [{location, "std@unicode.erl", 12}]}.
    {func_info, {atom, std@unicode}, {atom, hangulTBase}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {integer, 4519}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hangulLCount, 0, 25}.
  {label, 24}.
    {line, [{location, "std@unicode.erl", 13}]}.
    {func_info, {atom, std@unicode}, {atom, hangulLCount}, 0}.
  {label, 25}.
    {allocate, 0, 0}.
    {move, {integer, 19}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hangulVCount, 0, 27}.
  {label, 26}.
    {line, [{location, "std@unicode.erl", 14}]}.
    {func_info, {atom, std@unicode}, {atom, hangulVCount}, 0}.
  {label, 27}.
    {allocate, 0, 0}.
    {move, {integer, 21}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hangulTCount, 0, 29}.
  {label, 28}.
    {line, [{location, "std@unicode.erl", 15}]}.
    {func_info, {atom, std@unicode}, {atom, hangulTCount}, 0}.
  {label, 29}.
    {allocate, 0, 0}.
    {move, {integer, 28}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hangulNCount, 0, 31}.
  {label, 30}.
    {line, [{location, "std@unicode.erl", 16}]}.
    {func_info, {atom, std@unicode}, {atom, hangulNCount}, 0}.
  {label, 31}.
    {allocate, 0, 0}.
    {move, {integer, 588}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hangulSCount, 0, 33}.
  {label, 32}.
    {line, [{location, "std@unicode.erl", 17}]}.
    {func_info, {atom, std@unicode}, {atom, hangulSCount}, 0}.
  {label, 33}.
    {allocate, 0, 0}.
    {move, {integer, 11172}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, isHangulSyllable, 1, 35}.
  {label, 34}.
    {line, [{location, "std@unicode.erl", 18}]}.
    {func_info, {atom, std@unicode}, {atom, isHangulSyllable}, 1}.
  {label, 35}.
    {allocate, 10, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 17}}.
    {test, is_ge, {f, 162}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 163}}.
  {label, 162}.
    {move, {atom, false}, {x, 0}}.
  {label, 163}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq, {f, 164}, [{y, 1}, {atom, true}]}.
    {call, 0, {f, 17}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 33}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 166}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 166}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 167}}.
  {label, 166}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/unicode.bp:132:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 167}.
    {test, is_lt, {f, 168}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 169}}.
  {label, 168}.
    {move, {atom, false}, {x, 0}}.
  {label, 169}.
    {jump, {f, 165}}.
  {label, 164}.
    {move, {atom, false}, {x, 0}}.
  {label, 165}.
    {deallocate, 10}.
    return.

{function, hangulDecomposition, 1, 37}.
  {label, 36}.
    {line, [{location, "std@unicode.erl", 19}]}.
    {func_info, {atom, std@unicode}, {atom, hangulDecomposition}, 1}.
  {label, 37}.
    {allocate, 22, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 17}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 170}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 170}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 171}}.
  {label, 170}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/unicode.bp:136:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 171}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 29}}.
    {test, is_ne_exact, {f, 172}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 173}}.
  {label, 172}.
    {move, {literal, {panic, <<"integer division by zero: % on i32 at src/unicode.bp:137:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 173}.
    {gc_bif, 'rem', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 31}}.
    {test, is_ne_exact, {f, 174}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 175}}.
  {label, 174}.
    {move, {literal, {panic, <<"integer division by zero: % on i32 at src/unicode.bp:138:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 175}.
    {gc_bif, 'rem', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {call, 0, {f, 19}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 176}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 176}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 177}}.
  {label, 176}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/unicode.bp:139:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 177}.
    {move, {x, 0}, {y, 5}}.
    {call, 0, {f, 31}}.
    {test, is_ne_exact, {f, 178}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 179}}.
  {label, 178}.
    {move, {literal, {panic, <<"integer division by zero: / on i32 at src/unicode.bp:139:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 179}.
    {gc_bif, 'div', {f, 0}, 1, [{y, 5}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 180}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 180}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 181}}.
  {label, 180}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/unicode.bp:139:40">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 181}.
    {gc_bif, '+', {f, 0}, 1, [{y, 4}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 182}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 182}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 183}}.
  {label, 182}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/unicode.bp:139:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 183}.
    {move, {x, 0}, {y, 6}}.
    {call, 0, {f, 21}}.
    {move, {x, 0}, {y, 7}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 184}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 184}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 185}}.
  {label, 184}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/unicode.bp:140:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 185}.
    {move, {x, 0}, {y, 8}}.
    {call, 0, {f, 29}}.
    {test, is_ne_exact, {f, 186}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 187}}.
  {label, 186}.
    {move, {literal, {panic, <<"integer division by zero: / on i32 at src/unicode.bp:140:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 187}.
    {gc_bif, 'div', {f, 0}, 1, [{y, 8}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 188}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 188}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 189}}.
  {label, 188}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/unicode.bp:140:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 189}.
    {gc_bif, '+', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 190}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 190}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 191}}.
  {label, 190}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/unicode.bp:140:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 191}.
    {move, {x, 0}, {y, 9}}.
    {test, is_eq_exact, {f, 192}, [{y, 2}, {integer, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 22}.
    return.
  {label, 192}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {call, 0, {f, 23}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 193}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 193}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 194}}.
  {label, 193}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/unicode.bp:142:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 194}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 22}.
    return.
% The full decomposition of `cp`: its mapping, decomposed again until no
% code point maps. A compatibility mapping is followed only when `compat`
% and the code point has no canonical one.

{function, fullDecomposition, 2, 39}.
  {label, 38}.
    {line, [{location, "std@unicode.erl", 20}]}.
    {func_info, {atom, std@unicode}, {atom, fullDecomposition}, 2}.
  {label, 39}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 35}}.
    {test, is_eq, {f, 195}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 37}, 6}.
  {label, 195}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@internal@unicode_tables, canonicalDecomposition, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 196}, [{integer, 0}, {x, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 197}}.
  {label, 196}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 198}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@internal@unicode_tables, compatibilityDecomposition, 1}}.
    {jump, {f, 199}}.
  {label, 198}.
    {move, {y, 2}, {x, 0}}.
  {label, 199}.
  {label, 197}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 200}, [{x, 0}, {integer, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 200}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 202}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, decompose, 2, 41}.
  {label, 40}.
    {line, [{location, "std@unicode.erl", 21}]}.
    {func_info, {atom, std@unicode}, {atom, decompose}, 2}.
  {label, 41}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 204}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
% The canonical ordering algorithm: every run of non-starters (combining
% class > 0) sorted by class, stably — marks of one class keep their order.

{function, canonicalOrder, 1, 43}.
  {label, 42}.
    {line, [{location, "std@unicode.erl", 22}]}.
    {func_info, {atom, std@unicode}, {atom, canonicalOrder}, 1}.
  {label, 43}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{y, 1}, {y, 2}]}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 206}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {bif, element, {f, 0}, [{integer, 1}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 3}.
% `c` (of class `k`) placed into `run`, which is sorted by class, after
% every mark whose class is at most `k`.

{function, insertByClass, 3, 45}.
  {label, 44}.
    {line, [{location, "std@unicode.erl", 23}]}.
    {func_info, {atom, std@unicode}, {atom, insertByClass}, 3}.
  {label, 45}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 212}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 210}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ne_exact, {f, 215}, [{y, 3}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 0}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {integer, 0}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 216}}.
  {label, 215}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 216}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 217}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 3}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {y, 3}], {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 218}}.
  {label, 217}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 218}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 9}.
% The canonical composition algorithm over a canonically ordered sequence:
% each character is composed with the last starter when nothing between
% them blocks it — no character in between, or the last one in between of
% a lower class than its own — and the pair has a primary composite.
% `pending` holds the characters after the starter that did not compose
% (all non-starters: a starter that does not compose becomes the next
% starter), `lastClass` the class of the last of them.

{function, recompose, 1, 47}.
  {label, 46}.
    {line, [{location, "std@unicode.erl", 24}]}.
    {func_info, {atom, std@unicode}, {atom, recompose}, 1}.
  {label, 47}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, -1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 1}, {list, [{y, 2}, {y, 1}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 220}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {bif, element, {f, 0}, [{integer, 1}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {bif, element, {f, 0}, [{integer, 3}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {bif, element, {f, 0}, [{integer, 4}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 2}, {x, 1}}.
    {call_last, 3, {f, 49}, 5}.
% `out` followed by the starter (none when negative) and what followed it.

{function, withStarter, 3, 49}.
  {label, 48}.
    {line, [{location, "std@unicode.erl", 25}]}.
    {func_info, {atom, std@unicode}, {atom, withStarter}, 3}.
  {label, 49}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_lt, {f, 237}, [{y, 1}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 6}.
  {label, 237}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 6}.
% The primary composite of `first` then `second`, or 0: Hangul LV and LVT by
% the algorithm, every other pair from the tables.

{function, primaryComposite, 2, 51}.
  {label, 50}.
    {line, [{location, "std@unicode.erl", 26}]}.
    {func_info, {atom, std@unicode}, {atom, primaryComposite}, 2}.
  {label, 51}.
    {allocate, 39, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call, 0, {f, 19}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 238}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 238}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 239}}.
  {label, 238}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/unicode.bp:239:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 239}.
    {move, {x, 0}, {y, 2}}.
    {call, 0, {f, 21}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 240}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 240}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 241}}.
  {label, 240}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/unicode.bp:240:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 241}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ge, {f, 242}, [{y, 2}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 243}}.
  {label, 242}.
    {move, {atom, false}, {x, 0}}.
  {label, 243}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 244}, [{x, 1}, {atom, true}]}.
    {call, 0, {f, 25}}.
    {test, is_lt, {f, 246}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 247}}.
  {label, 246}.
    {move, {atom, false}, {x, 0}}.
  {label, 247}.
    {jump, {f, 245}}.
  {label, 244}.
    {move, {atom, false}, {x, 0}}.
  {label, 245}.
    {move, {x, 0}, {y, 4}}.
    {test, is_ge, {f, 248}, [{y, 3}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 249}}.
  {label, 248}.
    {move, {atom, false}, {x, 0}}.
  {label, 249}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 250}, [{x, 1}, {atom, true}]}.
    {call, 0, {f, 27}}.
    {test, is_lt, {f, 252}, [{y, 3}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 253}}.
  {label, 252}.
    {move, {atom, false}, {x, 0}}.
  {label, 253}.
    {jump, {f, 251}}.
  {label, 250}.
    {move, {atom, false}, {x, 0}}.
  {label, 251}.
    {move, {x, 0}, {y, 5}}.
    {test, is_eq, {f, 255}, [{y, 4}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 256}}.
  {label, 255}.
    {move, {atom, false}, {x, 0}}.
  {label, 256}.
    {test, is_eq, {f, 254}, [{x, 0}, {atom, true}]}.
    {call, 0, {f, 17}}.
    {move, {x, 0}, {y, 6}}.
    {call, 0, {f, 27}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 257}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 257}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 258}}.
  {label, 257}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/unicode.bp:244:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 258}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 3}], {x, 0}}.
    {test, is_ge, {f, 259}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 259}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 260}}.
  {label, 259}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/unicode.bp:244:53">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 260}.
    {move, {x, 0}, {y, 7}}.
    {call, 0, {f, 29}}.
    {gc_bif, '*', {f, 0}, 1, [{y, 7}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 261}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 261}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 262}}.
  {label, 261}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/unicode.bp:244:63">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 262}.
    {gc_bif, '+', {f, 0}, 1, [{y, 6}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 263}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 263}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 264}}.
  {label, 263}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/unicode.bp:244:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 264}.
    {deallocate, 39}.
    return.
  {label, 254}.
    {call, 0, {f, 23}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 265}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 265}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 266}}.
  {label, 265}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/unicode.bp:245:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 266}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 267}, [{x, 1}, {atom, true}]}.
    {call, 0, {f, 17}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 269}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 269}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 270}}.
  {label, 269}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/unicode.bp:247:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 270}.
    {move, {x, 0}, {y, 9}}.
    {call, 0, {f, 29}}.
    {test, is_ne_exact, {f, 271}, [{x, 0}, {integer, 0}]}.
    {jump, {f, 272}}.
  {label, 271}.
    {move, {literal, {panic, <<"integer division by zero: % on i32 at src/unicode.bp:247:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 272}.
    {gc_bif, 'rem', {f, 0}, 1, [{y, 9}, {x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 273}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 274}}.
  {label, 273}.
    {move, {atom, false}, {x, 0}}.
  {label, 274}.
    {jump, {f, 268}}.
  {label, 267}.
    {move, {atom, false}, {x, 0}}.
  {label, 268}.
    {move, {x, 0}, {y, 10}}.
    {test, is_lt, {f, 275}, [{integer, 0}, {y, 8}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 276}}.
  {label, 275}.
    {move, {atom, false}, {x, 0}}.
  {label, 276}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 277}, [{x, 1}, {atom, true}]}.
    {call, 0, {f, 29}}.
    {test, is_lt, {f, 279}, [{y, 8}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 280}}.
  {label, 279}.
    {move, {atom, false}, {x, 0}}.
  {label, 280}.
    {jump, {f, 278}}.
  {label, 277}.
    {move, {atom, false}, {x, 0}}.
  {label, 278}.
    {move, {x, 0}, {y, 11}}.
    {test, is_eq, {f, 282}, [{y, 10}, {atom, true}]}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 283}}.
  {label, 282}.
    {move, {atom, false}, {x, 0}}.
  {label, 283}.
    {test, is_eq, {f, 281}, [{x, 0}, {atom, true}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 8}], {x, 0}}.
    {test, is_ge, {f, 284}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 284}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 285}}.
  {label, 284}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/unicode.bp:249:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 285}.
    {deallocate, 39}.
    return.
  {label, 281}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@internal@unicode_tables, primaryComposite, 2}, 39}.
% ── tests ────────────────────────────────────────────────────────────────────
% Non-ASCII text is built from code points: the erlang backend truncates a
% `\u{…}` literal above U+007F to one latin1 byte.

{function, text, 1, 53}.
  {label, 52}.
    {line, [{location, "std@unicode.erl", 27}]}.
    {func_info, {atom, std@unicode}, {atom, text}, 1}.
  {label, 53}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 287}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 129}, 3}.

{function, codes, 1, 55}.
  {label, 54}.
    {line, [{location, "std@unicode.erl", 28}]}.
    {func_info, {atom, std@unicode}, {atom, codes}, 1}.
  {label, 55}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 289}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 129}, 5}.

{function, 'array_all', 2, 113}.
  {label, 112}.
    {line, [{location, "std@unicode.erl", 29}]}.
    {func_info, {atom, std@unicode}, {atom, 'array_all'}, 2}.
  {label, 113}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 290}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 291}}.
  {label, 290}.
    {move, {atom, false}, {x, 0}}.
  {label, 291}.
    {deallocate, 2}.
    return.

{function, 'array_count', 2, 210}.
  {label, 209}.
    {line, [{location, "std@unicode.erl", 30}]}.
    {func_info, {atom, std@unicode}, {atom, 'array_count'}, 2}.
  {label, 210}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_priv__array_all', 2, 294}.
  {label, 293}.
    {line, [{location, "std@unicode.erl", 32}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__array_all'}, 2}.
  {label, 294}.
    {call_only, 2, {f, 113}}.

{function, '__bp_priv__array_count', 2, 296}.
  {label, 295}.
    {line, [{location, "std@unicode.erl", 33}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__array_count'}, 2}.
  {label, 296}.
    {call_only, 2, {f, 210}}.

{function, '__bp_priv__array_range', 2, 298}.
  {label, 297}.
    {line, [{location, "std@unicode.erl", 34}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 298}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 300}.
  {label, 299}.
    {line, [{location, "std@unicode.erl", 35}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 300}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__canonicalOrder', 1, 302}.
  {label, 301}.
    {line, [{location, "std@unicode.erl", 36}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__canonicalOrder'}, 1}.
  {label, 302}.
    {call_only, 1, {f, 43}}.

{function, '__bp_priv__codepointsBody', 1, 304}.
  {label, 303}.
    {line, [{location, "std@unicode.erl", 37}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__codepointsBody'}, 1}.
  {label, 304}.
    {call_only, 1, {f, 13}}.

{function, '__bp_priv__codes', 1, 306}.
  {label, 305}.
    {line, [{location, "std@unicode.erl", 38}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__codes'}, 1}.
  {label, 306}.
    {call_only, 1, {f, 55}}.

{function, '__bp_priv__decompose', 2, 308}.
  {label, 307}.
    {line, [{location, "std@unicode.erl", 39}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__decompose'}, 2}.
  {label, 308}.
    {call_only, 2, {f, 41}}.

{function, '__bp_priv__firstCodepointOrZeroBody', 1, 310}.
  {label, 309}.
    {line, [{location, "std@unicode.erl", 40}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__firstCodepointOrZeroBody'}, 1}.
  {label, 310}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__fullDecomposition', 2, 312}.
  {label, 311}.
    {line, [{location, "std@unicode.erl", 41}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__fullDecomposition'}, 2}.
  {label, 312}.
    {call_only, 2, {f, 39}}.

{function, '__bp_priv__hangulDecomposition', 1, 314}.
  {label, 313}.
    {line, [{location, "std@unicode.erl", 42}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulDecomposition'}, 1}.
  {label, 314}.
    {call_only, 1, {f, 37}}.

{function, '__bp_priv__hangulLBase', 0, 316}.
  {label, 315}.
    {line, [{location, "std@unicode.erl", 43}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulLBase'}, 0}.
  {label, 316}.
    {call_only, 0, {f, 19}}.

{function, '__bp_priv__hangulLCount', 0, 318}.
  {label, 317}.
    {line, [{location, "std@unicode.erl", 44}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulLCount'}, 0}.
  {label, 318}.
    {call_only, 0, {f, 25}}.

{function, '__bp_priv__hangulNCount', 0, 320}.
  {label, 319}.
    {line, [{location, "std@unicode.erl", 45}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulNCount'}, 0}.
  {label, 320}.
    {call_only, 0, {f, 31}}.

{function, '__bp_priv__hangulSBase', 0, 322}.
  {label, 321}.
    {line, [{location, "std@unicode.erl", 46}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulSBase'}, 0}.
  {label, 322}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__hangulSCount', 0, 324}.
  {label, 323}.
    {line, [{location, "std@unicode.erl", 47}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulSCount'}, 0}.
  {label, 324}.
    {call_only, 0, {f, 33}}.

{function, '__bp_priv__hangulTBase', 0, 326}.
  {label, 325}.
    {line, [{location, "std@unicode.erl", 48}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulTBase'}, 0}.
  {label, 326}.
    {call_only, 0, {f, 23}}.

{function, '__bp_priv__hangulTCount', 0, 328}.
  {label, 327}.
    {line, [{location, "std@unicode.erl", 49}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulTCount'}, 0}.
  {label, 328}.
    {call_only, 0, {f, 29}}.

{function, '__bp_priv__hangulVBase', 0, 330}.
  {label, 329}.
    {line, [{location, "std@unicode.erl", 50}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulVBase'}, 0}.
  {label, 330}.
    {call_only, 0, {f, 21}}.

{function, '__bp_priv__hangulVCount', 0, 332}.
  {label, 331}.
    {line, [{location, "std@unicode.erl", 51}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__hangulVCount'}, 0}.
  {label, 332}.
    {call_only, 0, {f, 27}}.

{function, '__bp_priv__insertByClass', 3, 334}.
  {label, 333}.
    {line, [{location, "std@unicode.erl", 52}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__insertByClass'}, 3}.
  {label, 334}.
    {call_only, 3, {f, 45}}.

{function, '__bp_priv__isHangulSyllable', 1, 336}.
  {label, 335}.
    {line, [{location, "std@unicode.erl", 53}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__isHangulSyllable'}, 1}.
  {label, 336}.
    {call_only, 1, {f, 35}}.

{function, '__bp_priv__primaryComposite', 2, 338}.
  {label, 337}.
    {line, [{location, "std@unicode.erl", 54}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__primaryComposite'}, 2}.
  {label, 338}.
    {call_only, 2, {f, 51}}.

{function, '__bp_priv__recompose', 1, 340}.
  {label, 339}.
    {line, [{location, "std@unicode.erl", 55}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__recompose'}, 1}.
  {label, 340}.
    {call_only, 1, {f, 47}}.

{function, '__bp_priv__text', 1, 342}.
  {label, 341}.
    {line, [{location, "std@unicode.erl", 56}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__text'}, 1}.
  {label, 342}.
    {call_only, 1, {f, 53}}.

{function, '__bp_priv__withStarter', 3, 344}.
  {label, 343}.
    {line, [{location, "std@unicode.erl", 57}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_priv__withStarter'}, 3}.
  {label, 344}.
    {call_only, 3, {f, 49}}.

{function, '__bp_tpl_0', 1, 57}.
  {label, 56}.
    {func_info, {atom, std@unicode}, {atom, '__bp_tpl_0'}, 1}.
  {label, 57}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext_last, 2, {extfunc, unicode, characters_to_list, 2}, 1}.

{function, '__bp_tpl_1', 1, 71}.
  {label, 70}.
    {func_info, {atom, std@unicode}, {atom, '__bp_tpl_1'}, 1}.
  {label, 71}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 74}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 74}, [{x, 0}]}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 75}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 82}.
  {label, 81}.
    {func_info, {atom, std@unicode}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 82}.
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
    {gc_bif, length, {f, 86}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test, is_lt, {f, 86}, [{x, 0}, {x, 1}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ge, {f, 86}, [{x, 0}, {x, 1}]}.
    {jump, {f, 87}}.
  {label, 87}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 5}.
  {label, 86}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_2', 2, 78}.
  {label, 77}.
    {func_info, {atom, std@unicode}, {atom, '__bp_tpl_2'}, 2}.
  {label, 78}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 82}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 94}.
  {label, 93}.
    {func_info, {atom, std@unicode}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 94}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_nonempty_list, {f, 98}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 3}, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 98}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_3', 1, 90}.
  {label, 89}.
    {func_info, {atom, std@unicode}, {atom, '__bp_tpl_3'}, 1}.
  {label, 90}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 94}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_4', 1, 100}.
  {label, 99}.
    {func_info, {atom, std@unicode}, {atom, '__bp_tpl_4'}, 1}.
  {label, 100}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_list, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
  {label, 104}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 105}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 3}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 107}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 107}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 108}}.
  {label, 107}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 108}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 104}}.
  {label, 105}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nil, {f, 106}, [{x, 0}]}.
    {jump, {f, 103}}.
  {label, 106}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 103}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '-codepointsBody/1-fun-0-', 1, 110}.
  {label, 109}.
    {line, [{location, "std@unicode.erl", 8}]}.
    {func_info, {atom, std@unicode}, {atom, '-codepointsBody/1-fun-0-'}, 1}.
  {label, 110}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 78}}.
    {deallocate, 1}.
    return.

{function, '-normalize/2-fun-1-', 1, 115}.
  {label, 114}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '-normalize/2-fun-1-'}, 1}.
  {label, 115}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 116}, [{y, 0}, {integer, 160}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 117}}.
  {label, 116}.
    {move, {atom, false}, {x, 0}}.
  {label, 117}.
    {deallocate, 1}.
    return.

{function, '-normalize/2-fun-2-', 1, 127}.
  {label, 126}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '-normalize/2-fun-2-'}, 1}.
  {label, 127}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {deallocate, 1}.
    return.

{function, '__bp_print', 1, 131}.
  {label, 130}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_print'}, 1}.
  {label, 131}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 135}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 135}.
  {label, 134}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '-bp_show_top-'}, 1}.
  {label, 135}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 133}}.

{function, '-bp_show_elem-', 1, 137}.
  {label, 136}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '-bp_show_elem-'}, 1}.
  {label, 137}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 133}}.

{function, '__bp_show', 2, 133}.
  {label, 132}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_show'}, 2}.
  {label, 133}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 145}, [{x, 0}]}.
    {test, is_eq, {f, 144}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 144}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 145}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 146}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 137}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 146}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 148}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 147}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 147}, [{x, 0}]}.
    {test, is_ne_exact, {f, 147}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 147}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 147}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 152}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 153}}.
  {label, 152}.
    {test, is_eq_exact, {f, 149}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 153}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 133}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 147}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 137}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 148}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 150}, [{x, 0}]}.
    {test, is_ne_exact, {f, 150}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 150}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 151}, [{x, 0}, {atom, undefined}]}.
  {label, 149}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 139}, 2}.
  {label, 150}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 151}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 139}.
  {label, 138}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_tagged'}, 2}.
  {label, 139}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 154}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 154}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 154}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 155}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 141}, 3}.
  {label, 155}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 141}.
  {label, 140}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_render'}, 1}.
  {label, 141}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 156}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 156}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 157}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 157}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 143}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 143}.
  {label, 142}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '-bp_render_pair-'}, 1}.
  {label, 143}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 133}}.
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

{function, '-bp_stringify-', 1, 159}.
  {label, 158}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '-bp_stringify-'}, 1}.
  {label, 159}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 160}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 160}.
    {test, is_integer, {f, 161}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 161}.
    {call, 1, {f, 135}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 129}.
  {label, 128}.
    {line, [{location, "std@unicode.erl", 9}]}.
    {func_info, {atom, std@unicode}, {atom, '-bp_join-'}, 2}.
  {label, 129}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 159}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '-fullDecomposition/2-fun-3-', 3, 202}.
  {label, 201}.
    {line, [{location, "std@unicode.erl", 21}]}.
    {func_info, {atom, std@unicode}, {atom, '-fullDecomposition/2-fun-3-'}, 3}.
  {label, 202}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 39}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '-decompose/2-fun-4-', 3, 204}.
  {label, 203}.
    {line, [{location, "std@unicode.erl", 22}]}.
    {func_info, {atom, std@unicode}, {atom, '-decompose/2-fun-4-'}, 3}.
  {label, 204}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 39}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '-canonicalOrder/1-fun-5-', 2, 206}.
  {label, 205}.
    {line, [{location, "std@unicode.erl", 23}]}.
    {func_info, {atom, std@unicode}, {atom, '-canonicalOrder/1-fun-5-'}, 2}.
  {label, 206}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {bif, element, {f, 0}, [{integer, 1}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {bif, element, {f, 0}, [{integer, 2}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@internal@unicode_tables, combiningClass, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test, is_eq_exact, {f, 207}, [{y, 4}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 208}}.
  {label, 207}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 0}, {x, 1}}.
    {call, 3, {f, 45}}.
    {move, {x, 0}, {y, 3}}.
  {label, 208}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {y, 3}]}}.
    {deallocate, 8}.
    return.

{function, '-insertByClass/3-fun-6-', 2, 212}.
  {label, 211}.
    {line, [{location, "std@unicode.erl", 24}]}.
    {func_info, {atom, std@unicode}, {atom, '-insertByClass/3-fun-6-'}, 2}.
  {label, 212}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@internal@unicode_tables, combiningClass, 1}}.
    {test, is_ge, {f, 213}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 214}}.
  {label, 213}.
    {move, {atom, false}, {x, 0}}.
  {label, 214}.
    {deallocate, 2}.
    return.

{function, '-recompose/1-fun-7-', 2, 220}.
  {label, 219}.
    {line, [{location, "std@unicode.erl", 25}]}.
    {func_info, {atom, std@unicode}, {atom, '-recompose/1-fun-7-'}, 2}.
  {label, 220}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {bif, element, {f, 0}, [{integer, 1}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {bif, element, {f, 0}, [{integer, 2}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {bif, element, {f, 0}, [{integer, 3}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {bif, element, {f, 0}, [{integer, 4}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@internal@unicode_tables, combiningClass, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 221}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 222}}.
  {label, 221}.
    {move, {atom, false}, {x, 0}}.
  {label, 222}.
    {move, {x, 0}, {y, 7}}.
    {test, is_ne_exact, {f, 223}, [{y, 7}, {atom, true}]}.
    {test, is_lt, {f, 225}, [{y, 5}, {y, 6}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 226}}.
  {label, 225}.
    {move, {atom, false}, {x, 0}}.
  {label, 226}.
    {jump, {f, 224}}.
  {label, 223}.
    {move, {atom, true}, {x, 0}}.
  {label, 224}.
    {move, {x, 0}, {y, 8}}.
    {test, is_ge, {f, 227}, [{y, 2}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 228}}.
  {label, 227}.
    {move, {atom, false}, {x, 0}}.
  {label, 228}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 229}, [{x, 1}, {atom, true}]}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 230}}.
  {label, 229}.
    {move, {atom, false}, {x, 0}}.
  {label, 230}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq, {f, 231}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 51}}.
    {jump, {f, 232}}.
  {label, 231}.
    {move, {integer, 0}, {x, 0}}.
  {label, 232}.
    {move, {x, 0}, {y, 10}}.
    {test, is_ne_exact, {f, 233}, [{y, 10}, {integer, 0}]}.
    {move, {y, 10}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 234}}.
  {label, 233}.
    {test, is_eq_exact, {f, 235}, [{y, 6}, {integer, 0}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 1}}.
    {call, 3, {f, 49}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {jump, {f, 236}}.
  {label, 235}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
  {label, 236}.
  {label, 234}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {deallocate, 12}.
    return.

{function, '-text/1-fun-8-', 1, 287}.
  {label, 286}.
    {line, [{location, "std@unicode.erl", 28}]}.
    {func_info, {atom, std@unicode}, {atom, '-text/1-fun-8-'}, 1}.
  {label, 287}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {deallocate, 1}.
    return.

{function, '-codes/1-fun-9-', 1, 289}.
  {label, 288}.
    {line, [{location, "std@unicode.erl", 29}]}.
    {func_info, {atom, std@unicode}, {atom, '-codes/1-fun-9-'}, 1}.
  {label, 289}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {deallocate, 1}.
    return.

{function, '__bp_prim_append', 2, 65}.
  {label, 64}.
    {line, [{location, "std@unicode.erl", 31}]}.
    {func_info, {atom, std@unicode}, {atom, '__bp_prim_append'}, 2}.
  {label, 65}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 292}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 292}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
