-module(std@escape).
-export([html/1, attribute/1, unescapeHtml/1, jsString/1, scriptJson/1, '__bp_priv__lineSeparatorText'/0, '__bp_priv__paragraphSeparatorText'/0]).

%% behavior bool

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

html(S) ->
    Amp = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(S, <<"&">>, <<"&amp;">>),
    Lt = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Amp, <<"<">>, <<"&lt;">>),
    Gt = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Lt, <<">">>, <<"&gt;">>),
    Gt.

% An attribute value: `html` plus both quote characters, so the result is

% safe inside a double- or single-quoted attribute.

attribute(S) ->
    Base = html(S),
    Dq = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Base, <<"\"">>, <<"&quot;">>),
    (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Dq, <<"'">>, <<"&#39;">>).

% The inverse of `attribute` (and of `html`) on the five entities the two

% introduce. Any other entity is left as written.

unescapeHtml(S) ->
    Dq = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(S, <<"&quot;">>, <<"\"">>),
    Sq = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Dq, <<"&#39;">>, <<"'">>),
    Gt = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Sq, <<"&gt;">>, <<">">>),
    Lt = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Gt, <<"&lt;">>, <<"<">>),
    (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Lt, <<"&amp;">>, <<"&">>).

% A payload for a double-quoted JS string literal inside a `<script>` block.

% `\` first (the escape character itself), then `"` (the delimiter), then

% `<` as `\u003c` so the text can never spell `</script>`, then the two line

% terminators a JS string literal cannot hold raw: the newline pair and the

% Unicode LINE/PARAGRAPH SEPARATOR (U+2028 / U+2029), which are legal in a

% JSON string but end a JS string literal in engines older than ES2019.

jsString(S) ->
    Bs = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(S, <<"\\">>, <<"\\\\">>),
    Dq = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Bs, <<"\"">>, <<"\\\"">>),
    Lt = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Dq, <<"<">>, <<"\\u003c">>),
    Nl = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Lt, <<"\n">>, <<"\\n">>),
    Cr = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Nl, <<"\r">>, <<"\\r">>),
    Ls = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Cr, <<226, 128, 168>>, <<"\\u2028">>),
    (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Ls, <<226, 128, 169>>, <<"\\u2029">>).

% JSON text made safe to inline in a `<script>` element (decision 116 rule 3,

% front 01 after decision 117): `&` `<` `>` become `\u0026` `\u003c`

% `\u003e`, and U+2028 / U+2029 become `\u2028` / `\u2029`. In JSON text

% those five characters can only occur inside a string, where each `\u` form

% is a valid escape — so the result is the SAME JSON value, and it holds no

% `</script`, no `<!--` and no line terminator a script parser would see.

% Not for arbitrary text: `jsString` is the JS-string-literal payload, `html`

% the element content.

scriptJson(Json) ->
    Amp = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Json, <<"&">>, <<"\\u0026">>),
    Lt = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Amp, <<"<">>, <<"\\u003c">>),
    Gt = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Lt, <<">">>, <<"\\u003e">>),
    Ls = (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Gt, <<226, 128, 168>>, <<"\\u2028">>),
    (fun(__S, __P, __R) -> binary:replace(__S, __P, __R, [global]) end)(Ls, <<226, 128, 169>>, <<"\\u2029">>).

% Internal: U+2028 LINE SEPARATOR, built on the host (see the module doc).

%% external fn lineSeparator -> erlang template

% Internal: U+2029 PARAGRAPH SEPARATOR, built on the host.

%% external fn paragraphSeparator -> erlang template

% The wasm bodies of the two cells (decision 238): a string literal, whose

% UTF-8 bytes the wasm backend writes into the data segment as they are.

lineSeparatorText() ->
    <<"\x{E2}\x{80}\x{A8}">>.

paragraphSeparatorText() ->
    <<"\x{E2}\x{80}\x{A9}">>.

% ── tests ────────────────────────────────────────────────────────────────────














'__bp_priv__lineSeparatorText'() -> lineSeparatorText().

'__bp_priv__paragraphSeparatorText'() -> paragraphSeparatorText().
