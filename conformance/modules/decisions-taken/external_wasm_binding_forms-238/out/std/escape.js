// behavior bool
//   fn toString(...)
//   default fn negate(...)
//   default fn nor(...)
//   default fn nand(...)
//   default fn exclusiveOr(...)
//   default fn exclusiveNor(...)
Boolean.prototype.negate = function() {
    const self = this.valueOf();
    return (!self);
};
Boolean.prototype.nor = function(other) {
    const self = this.valueOf();
    return (!((self || other)));
};
Boolean.prototype.nand = function(other) {
    const self = this.valueOf();
    return (!((self && other)));
};
Boolean.prototype.exclusiveOr = function(other) {
    const self = this.valueOf();
    return (self !== other);
};
Boolean.prototype.exclusiveNor = function(other) {
    const self = this.valueOf();
    return (self === other);
};

//// std/escape — HTML/attribute escaping for server-rendered markup.

//// 

//// Reference:

////   OWASP — https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html

////   WHATWG — https://html.spec.whatwg.org/multipage/parsing.html#character-reference-state

//// 

//// Lib-self-contained: every function composes `String.replaceAll`, so the

//// module runs on every backend including wat. `&` is replaced FIRST; any

//// other order re-escapes the ampersands the later rules introduce.

//// `unescapeHtml` runs the same five rules in reverse, `&amp;` LAST, so the

//// two are inverses on the five entities.

//// 

//// No import (decision 106: a root module). Two private host cells, and

//// only because of a codegen defect: the erlang backend lowers a string

//// literal's `\u{…}` above U+007F to ONE latin1 byte (`"\u{2028}"` becomes

//// `<<40>>`, the byte of `(`), so `replaceAll("\u{2028}", …)` rewrote every

//// parenthesis on erlang. `lineSeparator()` / `paragraphSeparator()` build

//// the two characters on the host instead; they go when the literal lowers

//// to UTF-8.

// Text content: the three characters that open or close markup.

function html(s) {
    const amp = s.replaceAll("&", "&amp;");
    const lt = amp.replaceAll("<", "&lt;");
    const gt = lt.replaceAll(">", "&gt;");
    return gt;
}
exports.html = html;

// An attribute value: `html` plus both quote characters, so the result is

// safe inside a double- or single-quoted attribute.

function attribute(s) {
    const base = html(s);
    const dq = base.replaceAll("\"", "&quot;");
    return dq.replaceAll("'", "&#39;");
}
exports.attribute = attribute;

// The inverse of `attribute` (and of `html`) on the five entities the two

// introduce. Any other entity is left as written.

function unescapeHtml(s) {
    const dq = s.replaceAll("&quot;", "\"");
    const sq = dq.replaceAll("&#39;", "'");
    const gt = sq.replaceAll("&gt;", ">");
    const lt = gt.replaceAll("&lt;", "<");
    return lt.replaceAll("&amp;", "&");
}
exports.unescapeHtml = unescapeHtml;

// A payload for a double-quoted JS string literal inside a `<script>` block.

// `\` first (the escape character itself), then `"` (the delimiter), then

// `<` as `\u003c` so the text can never spell `</script>`, then the two line

// terminators a JS string literal cannot hold raw: the newline pair and the

// Unicode LINE/PARAGRAPH SEPARATOR (U+2028 / U+2029), which are legal in a

// JSON string but end a JS string literal in engines older than ES2019.

function jsString(s) {
    const bs = s.replaceAll("\\", "\\\\");
    const dq = bs.replaceAll("\"", "\\\"");
    const lt = dq.replaceAll("<", "\\u003c");
    const nl = lt.replaceAll("\n", "\\n");
    const cr = nl.replaceAll("\r", "\\r");
    const ls = cr.replaceAll(String.fromCharCode(8232), "\\u2028");
    return ls.replaceAll(String.fromCharCode(8233), "\\u2029");
}
exports.jsString = jsString;

// JSON text made safe to inline in a `<script>` element (decision 116 rule 3,

// front 01 after decision 117): `&` `<` `>` become `\u0026` `\u003c`

// `\u003e`, and U+2028 / U+2029 become `\u2028` / `\u2029`. In JSON text

// those five characters can only occur inside a string, where each `\u` form

// is a valid escape — so the result is the SAME JSON value, and it holds no

// `</script`, no `<!--` and no line terminator a script parser would see.

// Not for arbitrary text: `jsString` is the JS-string-literal payload, `html`

// the element content.

function scriptJson(json) {
    const amp = json.replaceAll("&", "\\u0026");
    const lt = amp.replaceAll("<", "\\u003c");
    const gt = lt.replaceAll(">", "\\u003e");
    const ls = gt.replaceAll(String.fromCharCode(8232), "\\u2028");
    return ls.replaceAll(String.fromCharCode(8233), "\\u2029");
}
exports.scriptJson = scriptJson;

// Internal: U+2028 LINE SEPARATOR, built on the host (see the module doc).

// lineSeparator: per-call template (see annotation)

// Internal: U+2029 PARAGRAPH SEPARATOR, built on the host.

// paragraphSeparator: per-call template (see annotation)

// The wasm bodies of the two cells (decision 238): a string literal, whose

// UTF-8 bytes the wasm backend writes into the data segment as they are.

function lineSeparatorText() {
    return "\u{2028}";
}

function paragraphSeparatorText() {
    return "\u{2029}";
}

// ── tests ────────────────────────────────────────────────────────────────────

Object.defineProperty(exports, "__bp_priv__", { value: { html, attribute, unescapeHtml, jsString, scriptJson, lineSeparatorText, paragraphSeparatorText } });
