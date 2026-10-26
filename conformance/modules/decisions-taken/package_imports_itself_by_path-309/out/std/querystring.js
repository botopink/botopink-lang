const __bp_surrogate = /[\uD800-\uDFFF]/;
const __bp_surrogate_k = new Array(64).fill("");
const __bp_surrogate_v = new Array(64).fill(false);
const __bp_surrogate_k2 = new Array(64).fill("");
const __bp_surrogate_v2 = new Array(64).fill(false);
function __bp_has_surrogate(s) {
    const h = s.length & 63;
    if (__bp_surrogate_k[h] === s) { return __bp_surrogate_v[h]; }
    if (__bp_surrogate_k2[h] === s) { return __bp_surrogate_v2[h]; }
    const p = __bp_surrogate.test(s);
    __bp_surrogate_k2[h] = __bp_surrogate_k[h];
    __bp_surrogate_v2[h] = __bp_surrogate_v[h];
    __bp_surrogate_k[h] = s;
    __bp_surrogate_v[h] = p;
    return p;
}

function __bp_str_count(s, u) {
    let n = 0;
    for (const c of s.substring(0, u)) { n += 1; }
    return n;
}

function __bp_string_char_at(s, i) { if (!__bp_has_surrogate(s)) { return s.at(i) ?? null; } return Array.from(s).at(i) ?? null; }

function __bp_str_length(s) {
    if (!__bp_has_surrogate(s)) { return s.length; }
    let n = 0;
    for (const c of s) { n += 1; }
    return n;
}

function __bp_str_index_of(s, sub) {
    const u = s.indexOf(sub);
    return (u <= 0 || !__bp_has_surrogate(s)) ? u : __bp_str_count(s, u);
}

function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

function __bp_eq(a, b, d) {
    if (Object.is(a, b)) {
        return true;
    }
    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        return false;
    }
    if (Array.isArray(a)) {
        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
    }
    const k = Object.keys(a);
    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

// behavior string
//   fn length(...)
//   fn split(...)
//   fn toUpper(...)
//   fn toLower(...)
//   fn contains(...)
//   fn startsWith(...)
//   fn endsWith(...)
//   fn trim(...)
//   fn trimStart(...)
//   fn trimEnd(...)
//   fn replace(...)
//   default fn slice(...)
//   fn at(...)
//   fn indexOf(...)
//   default fn toString(...)
//   fn fromCodepoint(...)
//   fn padStart(...)
//   fn padEnd(...)
//   fn repeat(...)
//   fn replaceAll(...)
//   fn chars(...)
//   fn lines(...)
//   fn words(...)
//   fn normalizeNewlines(...)
//   fn trimTrailingNewlines(...)
//   fn firstDifferingLine(...)
//   fn charCodeAt(...)
//   fn lastIndexOf(...)
//   default fn parseInt(...)
//   default fn parseFloat(...)
String.prototype.slice = function(start, end) {
    const self = this.valueOf();
    if ((end != null)) { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, end); } else { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); }
};
String.prototype.chars = function() { return (Array.from(this.valueOf())); };
String.prototype.lines = function() { return this.valueOf().split(/\r?\n/); };
String.prototype.words = function() { return this.valueOf().split(/[ \t\n\r]+/).filter(__w => __w.length > 0); };
String.prototype.normalizeNewlines = function() { return this.valueOf().replaceAll("\r\n", "\n"); };
String.prototype.trimTrailingNewlines = function() { return this.valueOf().replace(/\n+$/, ""); };
String.prototype.firstDifferingLine = function(other) { return ((__a, __b) => { const __x = __a.split("\n"), __y = __b.split("\n"); let __i = 0; while (__i < __x.length && __i < __y.length && __x[__i] === __y[__i]) __i++; return (__i === __x.length && __i === __y.length) ? 0 : __i + 1 })(this.valueOf(), other); };
String.prototype.charCodeAt = function(index) { return ((__s, __i) => { if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = __i >= 0 ? Array.from(__s)[__i] : undefined; return __c === undefined ? -1 : __c.codePointAt(0); } return (__s.codePointAt(__i) ?? -1) | 0; })(this.valueOf(), index); };
String.prototype.parseInt = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const digits = (() => { if (signed) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, 1); } else { return self; } })();
    return (() => { if ((/^[0-9]+$/.test(digits))) { return ((__s) => { const __n = BigInt(__s); return (__n >= -9223372036854775808n && __n <= 9223372036854775807n) ? { ok: (__n >= -9007199254740991n && __n <= 9007199254740991n) ? Number(__n) : __n } : { error: 'parseInt: "' + __s + '" is out of range' } })(self); } else { return ({ error: 'parseInt: "' + self + '" is not an integer' }); } })();
};
String.prototype.parseFloat = function() {
    const self = this.valueOf();
    const signed = (self.startsWith("-") || self.startsWith("+"));
    const start = (() => { if (signed) { return 1; } else { return 0; } })();
    const lowerAt = __bp_str_index_of(self, "e");
    const exponentAt = (() => { if ((lowerAt < 0)) { return __bp_str_index_of(self, "E"); } else { return lowerAt; } })();
    const mantissa = (() => { if ((exponentAt < 0)) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, start); } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, exponentAt); } })();
    const pointAt = __bp_str_index_of(self, ".");
    const pointed = ((pointAt >= 0) && (((exponentAt < 0) || (pointAt < exponentAt))));
    const whole = (() => { if (pointed) { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, start, pointAt); } else { return mantissa; } })();
    const fraction = (() => { if ((pointed === false)) { return "0"; } else { return (() => { if ((exponentAt < 0)) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (pointAt + 1)); } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (pointAt + 1), exponentAt); } })(); } })();
    const exponent = (() => { if ((exponentAt < 0)) { return "0"; } else { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 1)); } })();
    const exponentMark = (() => { if ((exponentAt < 0)) { return ""; } else { return ((__s, __a, __e) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); const __g = __e < 0 ? Math.max(__m + __e, 0) : Math.min(__e, __m); return Array.from({ length: Math.max(__g - __d, 0) }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return __s.substring(__b, Math.max(__b, __f)); })(self, (exponentAt + 1), (exponentAt + 2)); } })();
    const exponentSigned = ((exponentMark === "-") || (exponentMark === "+"));
    const exponentDigits = (() => { if (exponentSigned) { return ((__s, __a) => { if (__a == null) __a = 0; if (/[\u{D800}-\u{DFFF}\u{10000}-\u{10FFFF}]/u.test(__s)) { const __c = Array.from(__s); const __m = __c.length; const __d = __a < 0 ? Math.max(__m + __a, 0) : Math.min(__a, __m); return Array.from({ length: __m - __d }, (_, __i) => __c[__d + __i]).join(""); } const __n = __s.length; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return __s.substring(__b); })(self, (exponentAt + 2)); } else { return exponent; } })();
    const wellFormed = (((/^[0-9]+$/.test(whole)) && (/^[0-9]+$/.test(fraction))) && (/^[0-9]+$/.test(exponentDigits)));
    return (() => { if (wellFormed) { return ((__t, __w, __f, __x) => { const __n = Number((__t.startsWith('-') ? '-' : '') + __w + '.' + __f + 'e' + __x); return Number.isFinite(__n) ? { ok: __n } : { error: 'parseFloat: "' + __t + '" overflows f64' } })(self, whole, fraction, exponent); } else { return ({ error: 'parseFloat: "' + self + '" is not a number' }); } })();
};

// behavior array
//   length: i32
//   fn at(...)
//   fn push(...)
//   fn pop(...)
//   default fn slice(...)
//   fn join(...)
//   fn reverse(...)
//   fn indexOf(...)
//   default fn lastIndexOf(...)
//   fn forEach(...)
//   fn map(...)
//   fn filter(...)
//   fn zip(...)
//   fn range(...)
//   fn repeat(...)
//   default fn isEmpty(...)
//   default fn contains(...)
//   default fn first(...)
//   default fn rest(...)
//   default fn take(...)
//   default fn drop(...)
//   default fn fold(...)
//   default fn find(...)
//   default fn count(...)
//   default fn all(...)
//   default fn any(...)
//   default fn append(...)
//   default fn prepend(...)
//   default fn flatten(...)
//   default fn flatMap(...)
//   default fn toList(...)
//   default fn some(...)
//   default fn every(...)
//   default fn flat(...)
//   default fn findIndex(...)
//   default fn fill(...)
//   default fn chunked(...)
//   default fn sliding(...)
//   default fn unique(...)
Array.range = function(start, stop) { return ((__a, __b) => Array.from({ length: Math.max(0, __b - __a) }, (_, __i) => __a + __i))(start, stop); };
Array.repeat = function(value, times) { return ((__v, __n) => Array.from({ length: Math.max(0, __n) }, () => __v))(value, times); };
Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__xs, __a, __e) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return Array.from({ length: Math.max(__f - __b, 0) }, (_, __i) => __xs[__b + __i]); })(this, start, end); } else { return ((__xs, __a) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return Array.from({ length: __n - __b }, (_, __i) => __xs[__b + __i]); })(this, start); }
};
Array.prototype.indexOf = function(item) { return this.findIndex((__e) => __bp_eq(__e, item, 0)); };
Array.prototype.lastIndexOf = function(item) { return this.findLastIndex((__e) => __bp_eq(__e, item, 0)); };
Array.prototype.zip = function(other) { return this.map((__x, __i) => [__x, (other)[__i]]).slice(0, Math.min(this.length, (other).length)); };
Array.prototype.isEmpty = function() {
    return (this.length === 0);
};
Array.prototype.contains = function(x) {
    return (this.indexOf(x) !== (-1));
};
Array.prototype.first = function() {
    return __bp_array_at(this, 0);
};
Array.prototype.rest = function() {
    return this.slice(1, this.length);
};
Array.prototype.take = function(n) {
    return this.slice(0, n);
};
Array.prototype.drop = function(n) {
    return this.slice(n, this.length);
};
Array.prototype.fold = function(initial, f) {
    let acc = initial;
    this.forEach((x) => {
    acc = f(acc, x);
});
    return acc;
};
Array.prototype.count = function(pred) {
    return this.filter(pred).length;
};
Array.prototype.all = function(pred) {
    return (this.filter(pred).length === this.length);
};
Array.prototype.any = function(pred) {
    return (this.filter(pred).length !== 0);
};
Array.prototype.prepend = function(item) {
    let out = [item];
    this.forEach((x) => {
    return out.push(x);
});
    return out;
};
Array.prototype.flatten = function() {
    let out = [];
    this.forEach((inner) => {
    out = out.concat(inner);
});
    return out;
};
Array.prototype.toList = function() {
    return this;
};
Array.prototype.some = function(pred) {
    return this.any(pred);
};
Array.prototype.every = function(pred) {
    return this.all(pred);
};
Array.prototype.flat = function() {
    return this.flatten();
};
Array.prototype.findIndex = function(pred) {
    let out = (-1);
    let i = 0;
    this.forEach((x) => {
    (() => { if ((out === (-1))) { return (() => { if (pred(x)) { return out = i; } })(); } })();
    i = (i + 1);
});
    return out;
};
Array.prototype.fill = function(value) {
    return Array.repeat(value, this.length);
};
Array.prototype.chunked = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const len = this.length;
    for (const k of Array.from({length: Math.max(0, (len) - (0))}, (_, __i) => (0) + __i)) {
    (() => { if ((((k % n) + 0) === 0)) { return out = out.concat([this.slice(k, (k + n))]); } })();
}
    return out;
};
Array.prototype.sliding = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const windows = ((this.length - n) + 1);
    if ((windows <= 0)) { return out; }
    for (const k of Array.from({length: Math.max(0, (windows) - (0))}, (_, __i) => (0) + __i)) {
    out = out.concat([this.slice(k, (k + n))]);
}
    return out;
};
Array.prototype.unique = function() {
    let out = [];
    this.forEach((x) => {
    return (() => { if ((!out.any((y) => {
    return __bp_eq(y, x, 0);
}))) { return out = out.concat([x]); } })();
});
    return out;
};

//// std/querystring — the query-string codec: RFC 3986 query components and

//// the `application/x-www-form-urlencoded` flavour.

//// 

//// Reference:

////   RFC 3986 §2.1 (percent-encoding), §3.4 (query)

////   WHATWG URL — application/x-www-form-urlencoded (`+` is a space)

////   Node.js  — https://nodejs.org/api/querystring.html

////   Erlang   — https://www.erlang.org/doc/apps/stdlib/uri_string.html

//// 

//// A codec, not a splitter. `parse` / `parseForm` split on `&`, each field

//// on its FIRST `=` (a field with no `=` is a name with an empty value; an

//// empty field is dropped), and percent-decode both sides; `parseForm`

//// also reads `+` as a space, `parse` keeps it as a `+`. `stringify`

//// percent-encodes every byte outside the RFC 3986 unreserved set, so its

//// output reads back through either parser.

//// 

//// Refused, never kept as written (rakun's 03r-e rule, as a refusal): a `%`

//// not followed by two hex digits, an escape sequence that is not UTF-8, and

//// a control character (U+0000–U+001F, U+007F) — raw, or as the escape that

//// would decode to one. A parser that can produce a newline is how a newline

//// reaches a header. `stringify` refuses a control character too, so every

//// text it writes is one `parse` reads back.

//// 

//// The percent codec is `encoding`'s (`percentEncode` / `percentDecode`),

//// imported: the same bytes on commonJS and erlang, and the refusals above

//// are decided in botopink before either cell runs.

const { percentEncode, percentDecode, hexDecode } = require("../std/encoding.js");

// Strip an optional leading `?` from a URL's query portion. Idempotent.

function stripPrefix(query) {
    let query$sp = null;
    if (query.startsWith("?")) { return query.slice(1, ((query$sp ??= __bp_has_surrogate(query)) ? __bp_str_length(query) : query.length)); }
    return query;
}

function isHexDigit(c) {
    return ((c !== "") && "0123456789abcdefABCDEF".includes(c));
}

function isControl(c) {
    const code = c.charCodeAt(0);
    return ((code >= 0) && (((code < 32) || (code === 127))));
}

// Whether `%<h1><h2>` decodes to a control character: `%00`–`%1F` or `%7F`.

// A byte below 0x80 is never part of a multi-byte UTF-8 sequence, so the

// escape alone decides it.

function isControlEscape(h1, h2) {
    return (((h1 === "0") || (h1 === "1")) || (((h1 === "7") && (((h2 === "f") || (h2 === "F"))))));
}

// The first problem in one raw component from index `i`, or `""` when it may

// be decoded. Walks the string by `at`: a `%` reads its two digits by index,

// which a `split("")` piece list would only re-index.

function scan(s, i) {
    while (true) {
        let s$sp = null;
        if ((i >= ((s$sp ??= __bp_has_surrogate(s)) ? __bp_str_length(s) : s.length))) { return ""; }
        const c = (() => { const __bp_nullish = ((s$sp ??= __bp_has_surrogate(s)) ? __bp_string_char_at(s, i) : (s.at(i) ?? null)); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
        if ((c === "%")) { const h1 = (() => { const __bp_nullish = ((s$sp ??= __bp_has_surrogate(s)) ? __bp_string_char_at(s, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/querystring.bp:59:25")) : (s.at(__bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/querystring.bp:59:25")) ?? null)); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })(); const h2 = (() => { const __bp_nullish = ((s$sp ??= __bp_has_surrogate(s)) ? __bp_string_char_at(s, __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/querystring.bp:60:25")) : (s.at(__bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/querystring.bp:60:25")) ?? null)); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })(); if ((((isHexDigit(h1) && isHexDigit(h2))) === false)) { return "a `%` not followed by two hex digits"; } if (isControlEscape(h1, h2)) { return "an escape that decodes to a control character"; } { const __bp_tc1 = __bp_int((i + 3), -2147483648, 2147483647, "+ on i32 at src/querystring.bp:65:26"); i = __bp_tc1; continue; } }
        if (isControl(c)) { return "a control character"; }
        { const __bp_tc1 = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/querystring.bp:68:22"); i = __bp_tc1; continue; }
    }
}

// One raw component decoded, `+` first read as a space when `form`.

function decodeComponent(raw, form) {
    const text = (() => { if (form) { return raw.replaceAll("+", " "); } else { return raw; } })();
    const problem = scan(text, 0);
    if ((problem !== "")) { return ({ error: ("querystring.parse: " + problem) }); }
    const decoded = percentDecode(text);
    if (((_r) => "error" in _r)(decoded)) { return ({ error: "querystring.parse: an escape sequence that is not UTF-8" }); }
    return ({ ok: ((_r) => "error" in _r ? ("") : _r.ok)(decoded) });
}

// One `name=value` field, split on its FIRST `=`.

function decodeField(field, form) {
    let field$sp = null;
    const eq = ((field$sp ??= __bp_has_surrogate(field)) ? __bp_str_index_of(field, "=") : field.indexOf("="));
    const rawName = (() => { if ((eq < 0)) { return field; } else { return field.slice(0, eq); } })();
    const rawValue = (() => { if ((eq < 0)) { return ""; } else { return field.slice(__bp_int((eq + 1), -2147483648, 2147483647, "+ on i32 at src/querystring.bp:89:55"), ((field$sp ??= __bp_has_surrogate(field)) ? __bp_str_length(field) : field.length)); } })();
    const _try0 = decodeComponent(rawName, form);
    if ("error" in _try0) return _try0;
    const name = _try0.ok;
    const _try1 = decodeComponent(rawValue, form);
    if ("error" in _try1) return _try1;
    const value = _try1.ok;
    return ({ ok: [name, value] });
}

function decodeFields(fields, i, form, acc) {
    while (true) {
        if ((i >= fields.length)) { return ({ ok: acc }); }
        const _try0 = decodeField((() => { const __bp_nullish = __bp_array_at(fields, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })(), form);
        if ("error" in _try0) return _try0;
        const pair = _try0.ok;
        { const __bp_tc1 = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/querystring.bp:103:39"); const __bp_tc3 = acc.concat([pair]); i = __bp_tc1; acc = __bp_tc3; continue; }
    }
}

function decodeBody(body, form) {
    const fields = body.split("&").filter((chunk) => {
    return (chunk !== "");
});
    const none = [];
    return decodeFields(fields, 0, form, none);
}

// Parse a URL query (RFC 3986) into its ordered `#(name, value)` pairs, a

// leading `?` stripped. Duplicate names are kept in order (Node's

// `querystring.parse` folds them into arrays; the pair list leaves that to

// the caller). `+` is a `+` here — `parseForm` is the flavour that reads it

// as a space. A malformed escape, a non-UTF-8 escape sequence or a control

// character is an `Error`.

function parse(query) {
    return decodeBody(stripPrefix(query), false);
}
exports.parse = parse;

// Parse an `application/x-www-form-urlencoded` body: `parse`'s rules with

// `+` read as a space before decoding. A form body is not a URL, so a

// leading `?` is data, not stripped.

function parseForm(body) {
    return decodeBody(body, true);
}
exports.parseForm = parseForm;

function hasControlFrom(s, i) {
    while (true) {
        let s$sp = null;
        if ((i >= ((s$sp ??= __bp_has_surrogate(s)) ? __bp_str_length(s) : s.length))) { return false; }
        if (isControl((() => { const __bp_nullish = ((s$sp ??= __bp_has_surrogate(s)) ? __bp_string_char_at(s, i) : (s.at(i) ?? null)); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })())) { return true; }
        { const __bp_tc1 = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/querystring.bp:135:32"); i = __bp_tc1; continue; }
    }
}

function hasControl(s) {
    return hasControlFrom(s, 0);
}

// Serialize ordered `#(name, value)` pairs: each side percent-encoded over

// the RFC 3986 unreserved set (a space is `%20`, a `+` is `%2B`, so the text

// reads back through `parse` and `parseForm` alike), joined with `&`. Empty

// input is `""`; there is no leading `?`. A control character in a name or a

// value is an `Error` — `parse` would refuse the text it became.

function stringify(pairs) {
    const bad = pairs.filter((p) => {
    return (hasControl(p[0]) || hasControl(p[1]));
});
    if ((bad.length > 0)) { return ({ error: "querystring.stringify: a control character" }); }
    return ({ ok: pairs.map((p) => {
    return [percentEncode(p[0]), "=", percentEncode(p[1])].join("");
}).join("&") });
}
exports.stringify = stringify;

// ── tests ────────────────────────────────────────────────────────────────────

function pairsOf(r) {
    const none = [];
    return ((_r) => "error" in _r ? (none) : _r.ok)(r).map((p) => {
    return [p[0], "=>", p[1]].join("");
}).join("|");
}

function problemOf(r) {
    const text = (() => {
        const _s = r;
        if ("ok" in _s) {
            const _v = _s.ok;
            return "";
        }
        if ("error" in _s) {
            const e = _s.error;
            return e;
        }
        throw new Error("case_clause");
    })();
    return text;
}

Object.defineProperty(exports, "__bp_priv__", { value: { percentEncode, percentDecode, hexDecode, stripPrefix, isHexDigit, isControl, isControlEscape, scan, decodeComponent, decodeField, decodeFields, decodeBody, parse, parseForm, hasControlFrom, hasControl, stringify, pairsOf, problemOf } });
