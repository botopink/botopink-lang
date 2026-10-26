{module, std@escape}.
{exports, [{html, 1}, {attribute, 1}, {unescapeHtml, 1}, {jsString, 1}, {scriptJson, 1}, {'__bp_priv__lineSeparatorText', 0}, {'__bp_priv__paragraphSeparatorText', 0}]}.
{attributes, []}.
{labels, 30}.
%%% std/escape — HTML/attribute escaping for server-rendered markup.
%%% 
%%% Reference:
%%%   OWASP — https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
%%%   WHATWG — https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state
%%% 
%%% Lib-self-contained: every function composes `String.replaceAll`, so the
%%% module runs on every backend including wat. `&` is replaced FIRST; any
%%% other order re-escapes the ampersands the later rules introduce.
%%% `unescapeHtml` runs the same five rules in reverse, `&amp;` LAST, so the
%%% two are inverses on the five entities.
%%% 
%%% No import (decision 106: a root module). Two private host cells, and
%%% only because of a codegen defect: the erlang backend lowers a string
%%% literal's `\u{…}` above U+007F to ONE latin1 byte (`"\u{2028}"` becomes
%%% `<<40>>`, the byte of `(`), so `replaceAll("\u{2028}", …)` rewrote every
%%% parenthesis on erlang. `lineSeparator()` / `paragraphSeparator()` build
%%% the two characters on the host instead; they go when the literal lowers
%%% to UTF-8.
% Text content: the three characters that open or close markup.

{function, html, 1, 3}.
  {label, 2}.
    {line, [{location, "std@escape.erl", 1}]}.
    {func_info, {atom, std@escape}, {atom, html}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"&">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"&amp;">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"<">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"&lt;">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<">">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"&gt;">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
% An attribute value: `html` plus both quote characters, so the result is
% safe inside a double- or single-quoted attribute.

{function, attribute, 1, 5}.
  {label, 4}.
    {line, [{location, "std@escape.erl", 2}]}.
    {func_info, {atom, std@escape}, {atom, attribute}, 1}.
  {label, 5}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"&quot;">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"'">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"&#39;">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 3, {f, 17}, 3}.
% The inverse of `attribute` (and of `html`) on the five entities the two
% introduce. Any other entity is left as written.

{function, unescapeHtml, 1, 7}.
  {label, 6}.
    {line, [{location, "std@escape.erl", 3}]}.
    {func_info, {atom, std@escape}, {atom, unescapeHtml}, 1}.
  {label, 7}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"&quot;">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"&#39;">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"'">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"&gt;">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<">">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"&lt;">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"<">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"&amp;">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"&">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 3, {f, 17}, 5}.
% A payload for a double-quoted JS string literal inside a `<script>` block.
% `\` first (the escape character itself), then `"` (the delimiter), then
% `<` as `\u003c` so the text can never spell `</script>`, then the two line
% terminators a JS string literal cannot hold raw: the newline pair and the
% Unicode LINE/PARAGRAPH SEPARATOR (U+2028 / U+2029), which are legal in a
% JSON string but end a JS string literal in engines older than ES2019.

{function, jsString, 1, 9}.
  {label, 8}.
    {line, [{location, "std@escape.erl", 4}]}.
    {func_info, {atom, std@escape}, {atom, jsString}, 1}.
  {label, 9}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"\\">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\\\">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\\"">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"<">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\u003c">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\n">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"\r">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\r">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 5}}.
    {call, 0, {f, 23}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\u2028">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 5}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 6}}.
    {call, 0, {f, 25}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\u2029">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 6}, {x, 0}}.
    {call_last, 3, {f, 17}, 13}.
% JSON text made safe to inline in a `<script>` element (decision 116 rule 3,
% front 01 after decision 117): `&` `<` `>` become `\u0026` `\u003c`
% `\u003e`, and U+2028 / U+2029 become `\u2028` / `\u2029`. In JSON text
% those five characters can only occur inside a string, where each `\u` form
% is a valid escape — so the result is the SAME JSON value, and it holds no
% `</script`, no `<!--` and no line terminator a script parser would see.
% Not for arbitrary text: `jsString` is the JS-string-literal payload, `html`
% the element content.

{function, scriptJson, 1, 11}.
  {label, 10}.
    {line, [{location, "std@escape.erl", 5}]}.
    {func_info, {atom, std@escape}, {atom, scriptJson}, 1}.
  {label, 11}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"&">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\u0026">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"<">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\u003c">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<">">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\u003e">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 3}}.
    {call, 0, {f, 23}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\u2028">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call, 3, {f, 17}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 25}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"\\u2029">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 3, {f, 17}, 11}.
% Internal: U+2028 LINE SEPARATOR, built on the host (see the module doc).
% Internal: U+2029 PARAGRAPH SEPARATOR, built on the host.
% The wasm bodies of the two cells (decision 238): a string literal, whose
% UTF-8 bytes the wasm backend writes into the data segment as they are.

{function, lineSeparatorText, 0, 13}.
  {label, 12}.
    {line, [{location, "std@escape.erl", 6}]}.
    {func_info, {atom, std@escape}, {atom, lineSeparatorText}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"\x{E2}\x{80}\x{A8}">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, paragraphSeparatorText, 0, 15}.
  {label, 14}.
    {line, [{location, "std@escape.erl", 7}]}.
    {func_info, {atom, std@escape}, {atom, paragraphSeparatorText}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"\x{E2}\x{80}\x{A9}">>}, {x, 0}}.
    {deallocate, 0}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────

{function, '__bp_priv__lineSeparatorText', 0, 27}.
  {label, 26}.
    {line, [{location, "std@escape.erl", 8}]}.
    {func_info, {atom, std@escape}, {atom, '__bp_priv__lineSeparatorText'}, 0}.
  {label, 27}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__paragraphSeparatorText', 0, 29}.
  {label, 28}.
    {line, [{location, "std@escape.erl", 9}]}.
    {func_info, {atom, std@escape}, {atom, '__bp_priv__paragraphSeparatorText'}, 0}.
  {label, 29}.
    {call_only, 0, {f, 15}}.

{function, '__bp_tpl_0-t/3-fun-0-', 3, 21}.
  {label, 20}.
    {func_info, {atom, std@escape}, {atom, '__bp_tpl_0-t/3-fun-0-'}, 3}.
  {label, 21}.
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

{function, '__bp_tpl_0', 3, 17}.
  {label, 16}.
    {func_info, {atom, std@escape}, {atom, '__bp_tpl_0'}, 3}.
  {label, 17}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1', 0, 23}.
  {label, 22}.
    {func_info, {atom, std@escape}, {atom, '__bp_tpl_1'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {literal, <<"\x{E2}\x{80}\x{A8}">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_tpl_2', 0, 25}.
  {label, 24}.
    {func_info, {atom, std@escape}, {atom, '__bp_tpl_2'}, 0}.
  {label, 25}.
    {allocate, 0, 0}.
    {move, {literal, <<"\x{E2}\x{80}\x{A9}">>}, {x, 0}}.
    {deallocate, 0}.
    return.
