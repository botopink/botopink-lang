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

// behavior Integer extends Number
//   fn toString(...)
//   default fn isEven(...)
//   default fn isOdd(...)
//   fn toI32(...)
//   fn toI64(...)
//   fn toU32(...)
//   fn toU64(...)
//   fn toF64(...)
BigInt.prototype.isEven = Number.prototype.isEven = function() {
    const self = this.valueOf();
    return ((self % 2) === 0);
};
BigInt.prototype.isOdd = Number.prototype.isOdd = function() {
    const self = this.valueOf();
    return ((self % 2) !== 0);
};
BigInt.prototype.toI32 = Number.prototype.toI32 = function() { return ((__v) => { if (__v >= -2147483648 && __v <= 2147483647) { return Number(__v); } throw new Error("integer overflow: toI32: " + __v + " does not fit i32"); })(this.valueOf()); };
BigInt.prototype.toI64 = Number.prototype.toI64 = function() { return ((__v) => { if (__v >= -9223372036854775808n && __v <= 9223372036854775807n) { return (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; } throw new Error("integer overflow: toI64: " + __v + " does not fit i64"); })(this.valueOf()); };
BigInt.prototype.toU32 = Number.prototype.toU32 = function() { return ((__v) => { if (__v >= 0 && __v <= 4294967295) { return Number(__v); } throw new Error("integer overflow: toU32: " + __v + " does not fit u32"); })(this.valueOf()); };
BigInt.prototype.toU64 = Number.prototype.toU64 = function() { return ((__v) => { if (__v >= 0 && __v <= 18446744073709551615n) { return __v; } throw new Error("integer overflow: toU64: " + __v + " does not fit u64"); })(this.valueOf()); };
BigInt.prototype.toF64 = Number.prototype.toF64 = function() { return ((__v) => { const __f = Number(__v); if (typeof __v !== "bigint" || BigInt(__f) === __v) { return __f; } throw new Error("integer overflow: toF64: " + __v + " has no exact f64"); })(this.valueOf()); };

//// `code`, the template that builds the typed AST from code written with

//// `${…}` holes (decisions 625 (4), 637, 638, 753).

//// 

//// `` code @`Element(tag: ${tag}, kids: [${kids}])` `` reads its text into

//// `compiler.Node` records and answers what `compiler.ast` builds from them:

//// code enters the compiler written, never as a string the compiler parses

//// back (625). Each hole is read by its arrival: a `syntax` value — a

//// template's receiver, a caller's hole from `compiler.holes(t)`, any

//// `syntax` parameter — is spliced as it was written (`Syntax(e)`, 638), any

//// other value as its literal (`Lit(v)`).

//// 

//// The text is one expression of the vocabulary `Node` has: a name, a number,

//// a string, `true` / `false`, a member, a call with positional and labelled

//// arguments, `[…]`, `#(…)`, the binary operators `|| && == != < > <= >= + -

//// * / %`, the unary `-` and `!`, `if (c) a else b`, an untyped lambda

//// `{ a, b -> body }`, and a typed function `fn(a: A) -> R { return …; }`

//// whose types are the type nodes (753). Anything else — an index, a string

//// with a hole inside it, a statement other than `return` or an expression —

//// is refused at the template's call, naming what was met.

//// 

//// Imported where used: `import {code} from "std";`.

const { Node, Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType } = require("../std/compiler.js");

// ── The tokens ──────────────────────────────────────────────────────────────

// `kind` one of `name`, `int`, `float`, `str`, `punct`, `hole`, `eof`; `hole`

// the hole's index for a `hole`, a number's value its `text`.

class Tok {
    constructor(kind, text, hole) {
        this.kind = kind;
        this.text = text;
        this.hole = hole;
    }
}
Tok.prototype.__bp = "Tok";

class Lexed {
    constructor(toks, err) {
        this.toks = toks;
        this.err = err;
    }
}
Lexed.prototype.__bp = "Lexed";

function charAt(cs, i) {
    if ((i < 0)) { return ""; }
    return (() => { const __bp_nullish = __bp_array_at(cs, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
}
exports.charAt = charAt;

function isDigit(c) {
    return ((c !== "") && "0123456789".includes(c));
}
exports.isDigit = isDigit;

function isIdentStart(c) {
    return ((c !== "") && "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_".includes(c));
}
exports.isIdentStart = isIdentStart;

function isIdentPart(c) {
    return (isIdentStart(c) || isDigit(c));
}
exports.isIdentPart = isIdentPart;

function isSpace(c) {
    return ((((c === " ") || (c === "\n")) || (c === "\t")) || (c === "\r"));
}
exports.isSpace = isSpace;

// The two-character operators; every other punctuation is one character.

function isPair(two) {
    return ((((((((two === "->") || (two === "==")) || (two === "!=")) || (two === "<=")) || (two === ">=")) || (two === "&&")) || (two === "||")) || (two === "??"));
}
exports.isPair = isPair;

function isPunct(c) {
    return ((c !== "") && "()[]{},.:;+-*/%<>!#?|=".includes(c));
}
exports.isPunct = isPunct;

function escaped(c) {
    if ((c === "n")) { return "\n"; }
    if ((c === "t")) { return "\t"; }
    if ((c === "r")) { return "\r"; }
    if ((c === "0")) { return ((__c) => { if (!(__c >= 0 && __c <= 1114111) || (__c >= 55296 && __c <= 57343)) throw new RangeError('String.fromCodepoint: ' + __c + ' is not a Unicode scalar value'); return String.fromCodePoint(__c); })(0); }
    return c;
}
exports.escaped = escaped;

function lexed(toks, err) {
    return new Lexed(toks, err);
}
exports.lexed = lexed;

// The text's tokens, a hole `${…}` one token (its braces nest, a string's do

// not count — as the compiler finds the holes `compiler.holes` answers).

function tokenize(text) {
    const cs = text.chars();
    let toks = [];
    let i = 0;
    let hole = 0;
    let err = "";
    while (((err === "") && (i < cs.length))) {
    const c = charAt(cs, i);
    const next = charAt(cs, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:107:33"));
    (() => { if (isSpace(c)) { return i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:109:19"); } else { return (() => { if (((c === "/") && (next === "/"))) { while (((i < cs.length) && (charAt(cs, i) !== "\n"))) {
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:112:23");
} } else { return (() => { if (((c === "$") && (next === "{"))) { let depth = 1; let j = __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:116:23"); let quoted = false; while (((depth > 0) && (j < cs.length))) {
    const d = charAt(cs, j);
    (() => { if (quoted) { return (() => { if ((d === "\\")) { return j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:121:42"); } else { return (() => { if ((d === "\"")) { return quoted = false; } })(); } })(); } else { return (() => { if ((d === "\"")) { return quoted = true; } else { return (() => { if ((d === "{")) { return depth = __bp_int((depth + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:125:35"); } else { return (() => { if ((d === "}")) { return depth = __bp_int((depth - 1), -2147483648, 2147483647, "- on i32 at src/code.bp:127:35"); } })(); } })(); } })(); } })();
    j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:128:23");
} return (() => { if ((depth > 0)) { return err = "a `\${` with no closing `}`"; } else { toks = toks.concat([new Tok("hole", "", hole)]); hole = __bp_int((hole + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:132:29"); return i = j; } })(); } else { return (() => { if (isIdentStart(c)) { let j = i; while (isIdentPart(charAt(cs, j))) {
    j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:138:23");
} toks = toks.concat([new Tok("name", cs.slice(i, j).join(""), 0)]); return i = j; } else { return (() => { if (isDigit(c)) { let j = i; while ((isDigit(charAt(cs, j)) || (charAt(cs, j) === "_"))) {
    j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:147:23");
} let kind = "int"; (() => { if (((charAt(cs, j) === ".") && isDigit(charAt(cs, __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:150:62"))))) { kind = "float"; j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:152:23"); while ((isDigit(charAt(cs, j)) || (charAt(cs, j) === "_"))) {
    j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:154:27");
} } })(); toks = toks.concat([new Tok(kind, cs.slice(i, j).join("").replaceAll("_", ""), 0)]); return i = j; } else { return (() => { if ((c === "\"")) { let j = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:163:23"); let value = ""; let closed = false; while ((((err === "") && (!closed)) && (j < cs.length))) {
    const d = charAt(cs, j);
    (() => { if ((d === "\"")) { return closed = true; } else { return (() => { if ((d === "\\")) { value = (value + escaped(charAt(cs, __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:169:58")))); return j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:170:27"); } else { return (() => { if (((d === "$") && (charAt(cs, __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:171:53")) === "{"))) { return err = "a hole inside a string literal: write the string and the hole apart, `\"a\" + \${x}`"; } else { return value = (value + d); } })(); } })(); } })();
    j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:175:23");
} (() => { if (((err === "") && (!closed))) { return err = "a string literal with no closing `\"`"; } })(); toks = toks.concat([new Tok("str", value, 0)]); return i = j; } else { return (() => { if (isPair((c + next))) { toks = toks.concat([new Tok("punct", (c + next), 0)]); return i = __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:183:19"); } else { return (() => { if (isPunct(c)) { toks = toks.concat([new Tok("punct", c, 0)]); return i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:186:19"); } else { return err = (("`" + c) + "` is no token of the language"); } })(); } })(); } })(); } })(); } })(); } })(); } })(); } })();
}
    toks = toks.concat([new Tok("eof", "", 0)]);
    return lexed(toks, err);
}
exports.tokenize = tokenize;

// ── The parser ──────────────────────────────────────────────────────────────

// A node read and the index of the token after it; `err` the reason the text

// is no code of `Node`'s vocabulary, empty when it is.

class P {
    constructor(node, pos, err) {
        this.node = node;
        this.pos = pos;
        this.err = err;
    }
}
P.prototype.__bp = "P";

// Nodes read and the index of the token after them.

class Ps {
    constructor(nodes, pos, err) {
        this.nodes = nodes;
        this.pos = pos;
        this.err = err;
    }
}
Ps.prototype.__bp = "Ps";

class Params {
    constructor(params, pos, err) {
        this.params = params;
        this.pos = pos;
        this.err = err;
    }
}
Params.prototype.__bp = "Params";

function ok(node, pos) {
    return new P(node, pos, "");
}
exports.ok = ok;

function bad(err, pos) {
    return new P(new Lit(0), pos, err);
}
exports.bad = bad;

function tokAt(ts, i) {
    return (() => { const __bp_nullish = __bp_array_at(ts, i); if (__bp_nullish != null) { return __bp_nullish; } else { return new Tok("eof", "", 0); } })();
}
exports.tokAt = tokAt;

function isP(ts, i, text) {
    const t = tokAt(ts, i);
    return ((t.kind === "punct") && (t.text === text));
}
exports.isP = isP;

function isWord(ts, i, word) {
    const t = tokAt(ts, i);
    return ((t.kind === "name") && (t.text === word));
}
exports.isWord = isWord;

function shown(t) {
    if ((t.kind === "eof")) { return "the end of the text"; }
    if ((t.kind === "hole")) { return "a hole"; }
    if ((t.kind === "str")) { return "a string"; }
    return (("`" + t.text) + "`");
}
exports.shown = shown;

function expected(ts, i, what) {
    return bad(((("expected " + what) + ", found ") + shown(tokAt(ts, i))), i);
}
exports.expected = expected;

function parseCode(text, holes) {
    const lx = tokenize(text);
    if ((lx.err !== "")) { return bad(lx.err, 0); }
    const p = expr(lx.toks, 0, holes);
    if ((p.err !== "")) { return p; }
    if ((tokAt(lx.toks, p.pos).kind !== "eof")) { return expected(lx.toks, p.pos, "the end of the expression"); }
    return p;
}
exports.parseCode = parseCode;

function expr(ts, i, holes) {
    return binary(ts, i, holes, 1);
}
exports.expr = expr;

// The precedence of a binary operator, 0 for a token that is none.

function precedence(t) {
    if ((t.kind !== "punct")) { return 0; }
    const op = t.text;
    if ((op === "||")) { return 1; }
    if ((op === "&&")) { return 2; }
    if (((op === "==") || (op === "!="))) { return 3; }
    if (((((op === "<") || (op === ">")) || (op === "<=")) || (op === ">="))) { return 4; }
    if (((op === "+") || (op === "-"))) { return 5; }
    if ((((op === "*") || (op === "/")) || (op === "%"))) { return 6; }
    return 0;
}
exports.precedence = precedence;

function binary(ts, i, holes, least) {
    let left = unary(ts, i, holes);
    let going = (left.err === "");
    while (going) {
    const t = tokAt(ts, left.pos);
    const prec = precedence(t);
    (() => { if (((prec === 0) || (prec < least))) { return going = false; } else { const right = binary(ts, __bp_int((left.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:271:45"), holes, __bp_int((prec + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:271:62")); return (() => { if ((right.err !== "")) { left = right; return going = false; } else { return left = ok(new Binary(t.text, left.node, right.node), right.pos); } })(); } })();
}
    return left;
}
exports.binary = binary;

function unary(ts, i, holes) {
    if ((isP(ts, i, "-") || isP(ts, i, "!"))) { const operand = unary(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:283:35"), holes); if ((operand.err !== "")) { return operand; } return ok(new Unary(tokAt(ts, i).text, operand.node), operand.pos); }
    return postfix(ts, i, holes);
}
exports.unary = unary;

function postfix(ts, i, holes) {
    let cur = primary(ts, i, holes);
    let going = (cur.err === "");
    while (going) {
    (() => { if (isP(ts, cur.pos, ".")) { const t = tokAt(ts, __bp_int((cur.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:295:39")); return (() => { if ((t.kind !== "name")) { cur = expected(ts, __bp_int((cur.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:297:44"), "a member name after `.`"); return going = false; } else { return cur = ok(new Member(cur.node, t.text), __bp_int((cur.pos + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:300:17")); } })(); } else { return (() => { if (isP(ts, cur.pos, "(")) { const args = callArgs(ts, __bp_int((cur.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:302:45"), holes); return (() => { if ((args.err !== "")) { cur = bad(args.err, args.pos); return going = false; } else { return cur = ok(new Call(cur.node, args.nodes), args.pos); } })(); } else { return going = false; } })(); } })();
}
    return cur;
}
exports.postfix = postfix;

// A call's arguments after its `(`, up to and past its `)`: `name: value` an

// `Arg`, any other a positional node.

function callArgs(ts, i, holes) {
    let out = [];
    let pos = i;
    let err = "";
    while (((err === "") && (!isP(ts, pos, ")")))) {
    const labelled = ((tokAt(ts, pos).kind === "name") && isP(ts, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:319:69"), ":"));
    const start = (() => { if (labelled) { return __bp_int((pos + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:320:39"); } else { return pos; } })();
    const v = expr(ts, start, holes);
    (() => { if ((v.err !== "")) { err = v.err; return pos = v.pos; } else { (() => { if (labelled) { return out.push(new Arg(tokAt(ts, pos).text, v.node)); } else { return out.push(v.node); } })(); pos = v.pos; return (() => { if (isP(ts, pos, ",")) { return pos = __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:332:27"); } else { return (() => { if ((!isP(ts, pos, ")"))) { return err = expected(ts, pos, "`,` or `)`").err; } })(); } })(); } })();
}
    if ((err !== "")) { return new Ps(out, pos, err); }
    return new Ps(out, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:338:36"), "");
}
exports.callArgs = callArgs;

// Expressions separated by `,` up to and past `close`.

function exprList(ts, i, holes, close) {
    let out = [];
    let pos = i;
    let err = "";
    while (((err === "") && (!isP(ts, pos, close)))) {
    const v = expr(ts, pos, holes);
    (() => { if ((v.err !== "")) { err = v.err; return pos = v.pos; } else { out = out.concat([v.node]); pos = v.pos; return (() => { if (isP(ts, pos, ",")) { return pos = __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:355:27"); } else { return (() => { if ((!isP(ts, pos, close))) { return err = expected(ts, pos, (("`,` or `" + close) + "`")).err; } })(); } })(); } })();
}
    if ((err !== "")) { return new Ps(out, pos, err); }
    return new Ps(out, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:361:36"), "");
}
exports.exprList = exprList;

function intOf(text) {
    const cs = text.chars();
    let n = 0;
    let i = 0;
    while ((i < cs.length)) {
    n = __bp_int((__bp_int((n * 10), -2147483648, 2147483647, "* on i32 at src/code.bp:369:15") + (__bp_int((charAt(cs, i).charCodeAt(0) - 48), -2147483648, 2147483647, "- on i32 at src/code.bp:369:51"))), -2147483648, 2147483647, "+ on i32 at src/code.bp:369:20");
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:370:15");
}
    return n;
}
exports.intOf = intOf;

function floatOf(text) {
    const parts = text.split(".");
    const whole = intOf((() => { const __bp_nullish = __bp_array_at(parts, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return "0"; } })());
    const frac = (() => { const __bp_nullish = __bp_array_at(parts, 1); if (__bp_nullish != null) { return __bp_nullish; } else { return "0"; } })();
    let frac$sp = null;
    let scale = 1.0;
    let i = 0;
    while ((i < ((frac$sp ??= __bp_has_surrogate(frac)) ? __bp_str_length(frac) : frac.length))) {
    scale = (scale * 10.0);
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:383:15");
}
    return (whole.toF64() + (intOf(frac).toF64() / scale));
}
exports.floatOf = floatOf;

function primary(ts, i, holes) {
    const t = tokAt(ts, i);
    if ((t.kind === "hole")) { return ok((() => { const __bp_nullish = __bp_array_at(holes, t.hole); if (__bp_nullish != null) { return __bp_nullish; } else { return new Lit(0); } })(), __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:390:67")); }
    if ((t.kind === "int")) { return ok(new Lit(intOf(t.text)), __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:391:58")); }
    if ((t.kind === "float")) { return ok(new Lit(floatOf(t.text)), __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:392:62")); }
    if ((t.kind === "str")) { return ok(new Lit(t.text), __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:393:51")); }
    if ((t.kind === "name")) { if ((t.text === "true")) { return ok(new Lit(true), __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:395:54")); } if ((t.text === "false")) { return ok(new Lit(false), __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:396:56")); } if ((t.text === "if")) { return ifExpr(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:397:49"), holes); } if ((t.text === "fn")) { return fnExpr(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:398:49"), holes); } return ok(new Name(t.text), __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:399:35")); }
    if (isP(ts, i, "(")) { const inner = expr(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:402:32"), holes); if ((inner.err !== "")) { return inner; } if ((!isP(ts, inner.pos, ")"))) { return expected(ts, inner.pos, "`)`"); } return ok(inner.node, __bp_int((inner.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:405:41")); }
    if (isP(ts, i, "[")) { const items = exprList(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:408:36"), holes, "]"); if ((items.err !== "")) { return bad(items.err, items.pos); } return ok(new List(items.nodes), items.pos); }
    if ((isP(ts, i, "#") && isP(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:412:38"), "("))) { const elems = exprList(ts, __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:413:36"), holes, ")"); if ((elems.err !== "")) { return bad(elems.err, elems.pos); } return ok(new Tuple(elems.nodes), elems.pos); }
    if (isP(ts, i, "{")) { return lambda(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:417:46"), holes); }
    return expected(ts, i, "an expression");
}
exports.primary = primary;

// `if (cond) then else otherwise`, after its `if`.

function ifExpr(ts, i, holes) {
    if ((!isP(ts, i, "("))) { return expected(ts, i, "`(` after `if`"); }
    const cond = expr(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:424:27"), holes);
    if ((cond.err !== "")) { return cond; }
    if ((!isP(ts, cond.pos, ")"))) { return expected(ts, cond.pos, "`)`"); }
    const then = expr(ts, __bp_int((cond.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:427:34"), holes);
    if ((then.err !== "")) { return then; }
    if ((!isWord(ts, then.pos, "else"))) { return expected(ts, then.pos, "`else`: an `if` that answers a value has both branches"); }
    const otherwise = expr(ts, __bp_int((then.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:431:39"), holes);
    if ((otherwise.err !== "")) { return otherwise; }
    return ok(new If(cond.node, then.node, otherwise.node), otherwise.pos);
}
exports.ifExpr = ifExpr;

// `{ a, b -> body }` (or `{ -> body }`), after its `{`.

function lambda(ts, i, holes) {
    let names = [];
    let pos = i;
    let err = "";
    while (((err === "") && (!isP(ts, pos, "->")))) {
    const t = tokAt(ts, pos);
    (() => { if ((t.kind !== "name")) { return err = expected(ts, pos, "a parameter name or `->`").err; } else { names = names.concat([t.text]); pos = __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:447:23"); return (() => { if (isP(ts, pos, ",")) { return pos = __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:449:27"); } else { return (() => { if ((!isP(ts, pos, "->"))) { return err = expected(ts, pos, "`,` or `->`").err; } })(); } })(); } })();
}
    if ((err !== "")) { return bad(err, pos); }
    const body = expr(ts, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:455:29"), holes);
    if ((body.err !== "")) { return body; }
    if ((!isP(ts, body.pos, "}"))) { return expected(ts, body.pos, "`}`"); }
    return ok(new Lambda(names, body.node), __bp_int((body.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:458:64"));
}
exports.lambda = lambda;

// `fn(a: A, b: B) -> R { statements }`, after its `fn` (decision 753).

function fnExpr(ts, i, holes) {
    if ((!isP(ts, i, "("))) { return expected(ts, i, "`(` after `fn`"); }
    const ps = fnParams(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:464:29"), holes);
    if ((ps.err !== "")) { return bad(ps.err, ps.pos); }
    if ((!isP(ts, ps.pos, "->"))) { return expected(ts, ps.pos, "`->` and the return type"); }
    const ret = typeNode(ts, __bp_int((ps.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:468:35"), holes);
    if ((ret.err !== "")) { return ret; }
    if ((!isP(ts, ret.pos, "{"))) { return expected(ts, ret.pos, "`{`"); }
    const body = statements(ts, __bp_int((ret.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:471:39"), holes);
    if ((body.err !== "")) { return bad(body.err, body.pos); }
    return ok(new Fn(ps.params, ret.node, body.nodes), body.pos);
}
exports.fnExpr = fnExpr;

function fnParams(ts, i, holes) {
    let out = [];
    let pos = i;
    let err = "";
    while (((err === "") && (!isP(ts, pos, ")")))) {
    const t = tokAt(ts, pos);
    (() => { if (((t.kind !== "name") || (!isP(ts, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:482:46"), ":")))) { return err = expected(ts, pos, "a typed parameter `name: Type`").err; } else { const ann = typeNode(ts, __bp_int((pos + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:485:40"), holes); return (() => { if ((ann.err !== "")) { err = ann.err; return pos = ann.pos; } else { out = out.concat([new FnParam(t.text, ann.node)]); pos = ann.pos; return (() => { if (isP(ts, pos, ",")) { return pos = __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:493:31"); } else { return (() => { if ((!isP(ts, pos, ")"))) { return err = expected(ts, pos, "`,` or `)`").err; } })(); } })(); } })(); } })();
}
    if ((err !== "")) { return new Params(out, pos, err); }
    return new Params(out, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:500:41"), "");
}
exports.fnParams = fnParams;

// A function's statements after its `{`, up to and past its `}`: `return e;`

// a `Return`, any other an expression.

function statements(ts, i, holes) {
    let out = [];
    let pos = i;
    let err = "";
    while (((err === "") && (!isP(ts, pos, "}")))) {
    (() => { if ((tokAt(ts, pos).kind === "eof")) { return err = expected(ts, pos, "`}`").err; } else { const returned = isWord(ts, pos, "return"); const v = expr(ts, (() => { if (returned) { return __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:514:48"); } else { return pos; } })(), holes); return (() => { if ((v.err !== "")) { err = v.err; return pos = v.pos; } else { (() => { if (returned) { return out.push(new Return(v.node)); } else { return out.push(v.node); } })(); pos = v.pos; return (() => { if (isP(ts, pos, ";")) { return pos = __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:524:50"); } })(); } })(); } })();
}
    if ((err !== "")) { return new Ps(out, pos, err); }
    return new Ps(out, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:529:36"), "");
}
exports.statements = statements;

// ── The types (decision 753) ───────────────────────────────────────────────

// `A | B`, or one type.

function typeNode(ts, i, holes) {
    const first = arrayType(ts, i, holes);
    if (((first.err !== "") || (!isP(ts, first.pos, "|")))) { return first; }
    let members = [first.node];
    let pos = first.pos;
    let err = "";
    while (((err === "") && isP(ts, pos, "|"))) {
    const m = arrayType(ts, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:542:35"), holes);
    (() => { if ((m.err !== "")) { err = m.err; return pos = m.pos; } else { members = members.concat([m.node]); return pos = m.pos; } })();
}
    if ((err !== "")) { return bad(err, pos); }
    return ok(new UnionType(members), pos);
}
exports.typeNode = typeNode;

// `T[]`, `T[][]`, or one type.

function arrayType(ts, i, holes) {
    let cur = baseType(ts, i, holes);
    while ((((cur.err === "") && isP(ts, cur.pos, "[")) && isP(ts, __bp_int((cur.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:560:28"), "]"))) {
    cur = ok(new ArrayType(cur.node), __bp_int((cur.pos + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:561:53"));
}
    return cur;
}
exports.arrayType = arrayType;

function baseType(ts, i, holes) {
    const t = tokAt(ts, i);
    if ((t.kind === "hole")) { return ok((() => { const __bp_nullish = __bp_array_at(holes, t.hole); if (__bp_nullish != null) { return __bp_nullish; } else { return new Lit(0); } })(), __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:568:67")); }
    if (isP(ts, i, "?")) { const inner = arrayType(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:570:37"), holes); if ((inner.err !== "")) { return inner; } return ok(new OptionalType(inner.node), inner.pos); }
    if ((isP(ts, i, "#") && isP(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:574:38"), "("))) { return tupleType(ts, __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:575:32"), holes); }
    if (isWord(ts, i, "fn")) { if ((!isP(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:577:24"), "("))) { return expected(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:577:57"), "`(` after `fn`"); } const ps = typeList(ts, __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:578:33"), holes, ")"); if ((ps.err !== "")) { return bad(ps.err, ps.pos); } if ((!isP(ts, ps.pos, "->"))) { return expected(ts, ps.pos, "`->` and the return type"); } const ret = typeNode(ts, __bp_int((ps.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:582:39"), holes); if ((ret.err !== "")) { return ret; } return ok(new FnType(ps.nodes, ret.node), ret.pos); }
    if ((t.kind === "name")) { if (isP(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:587:23"), "<")) { const args = typeList(ts, __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:588:39"), holes, ">"); if ((args.err !== "")) { return bad(args.err, args.pos); } return ok(new GenericType(t.text, args.nodes), args.pos); } return ok(new NamedType(t.text), __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:592:40")); }
    if (isP(ts, i, "(")) { const inner = typeNode(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:595:36"), holes); if ((inner.err !== "")) { return inner; } if ((!isP(ts, inner.pos, ")"))) { return expected(ts, inner.pos, "`)`"); } return ok(inner.node, __bp_int((inner.pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:598:41")); }
    return expected(ts, i, "a type");
}
exports.baseType = baseType;

// Types separated by `,` up to and past `close`.

function typeList(ts, i, holes, close) {
    let out = [];
    let pos = i;
    let err = "";
    while (((err === "") && (!isP(ts, pos, close)))) {
    const v = typeNode(ts, pos, holes);
    (() => { if ((v.err !== "")) { err = v.err; return pos = v.pos; } else { out = out.concat([v.node]); pos = v.pos; return (() => { if (isP(ts, pos, ",")) { return pos = __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:617:27"); } else { return (() => { if ((!isP(ts, pos, close))) { return err = expected(ts, pos, (("`,` or `" + close) + "`")).err; } })(); } })(); } })();
}
    if ((err !== "")) { return new Ps(out, pos, err); }
    return new Ps(out, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:623:36"), "");
}
exports.typeList = typeList;

// `#(A, B)` or `#(a: A, b: B)`, after its `#(`.

function tupleType(ts, i, holes) {
    const labelled = ((tokAt(ts, i).kind === "name") && isP(ts, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:628:61"), ":"));
    let types = [];
    let labels = [];
    let pos = i;
    let err = "";
    while (((err === "") && (!isP(ts, pos, ")")))) {
    const t = tokAt(ts, pos);
    (() => { if ((labelled && (((t.kind !== "name") || (!isP(ts, __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:635:59"), ":")))))) { return err = expected(ts, pos, "a labelled element `name: Type`").err; } else { (() => { if (labelled) { labels = labels.concat([t.text]); return pos = __bp_int((pos + 2), -2147483648, 2147483647, "+ on i32 at src/code.bp:640:27"); } })(); const v = typeNode(ts, pos, holes); return (() => { if ((v.err !== "")) { err = v.err; return pos = v.pos; } else { types = types.concat([v.node]); pos = v.pos; return (() => { if (isP(ts, pos, ",")) { return pos = __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:650:31"); } else { return (() => { if ((!isP(ts, pos, ")"))) { return err = expected(ts, pos, "`,` or `)`").err; } })(); } })(); } })(); } })();
}
    if ((err !== "")) { return bad(err, pos); }
    if (labelled) { return ok(new LabeledTupleType(types, labels), __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:658:71")); }
    return ok(new TupleType(types), __bp_int((pos + 1), -2147483648, 2147483647, "+ on i32 at src/code.bp:659:44"));
}
exports.tupleType = tupleType;

Object.defineProperty(exports, "__bp_priv__", { value: { Node, Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType, Tok, Lexed, charAt, isDigit, isIdentStart, isIdentPart, isSpace, isPair, isPunct, escaped, lexed, tokenize, P, Ps, Params, ok, bad, tokAt, isP, isWord, shown, expected, parseCode, expr, precedence, binary, unary, postfix, callArgs, exprList, intOf, floatOf, primary, ifExpr, lambda, fnExpr, fnParams, statements, typeNode, arrayType, baseType, typeList, tupleType } });
