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

function __bp_f64(v) {
    if (Number.isNaN(v)) { return "NaN"; }
    if (!Number.isFinite(v)) { return (v < 0) ? "-Infinity" : "Infinity"; }
    if (v === 0) { return Object.is(v, -0) ? "-0.0" : "0.0"; }
    const t = Math.abs(v).toExponential();
    const i = t.indexOf("e");
    const d = t.slice(0, i).replace(".", "");
    const e = Number(t.slice(i + 1));
    const g = (v < 0) ? "-" : "";
    const x = g + d[0] + "." + ((d.length > 1) ? d.slice(1) : "0") + "e" + e;
    const p = e + 1;
    const f = g + ((p <= 0) ? "0." + "0".repeat(-p) + d : (p >= d.length) ? d + "0".repeat(p - d.length) + ".0" : d.slice(0, p) + "." + d.slice(p));
    return ((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x;
}

function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], v.__bp_s?.[n], false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
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

//// std/unicode — Unicode codepoint primitives and normalization, cross-backend.

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/

////              (`String.prototype.codePointAt`, `String.fromCodePoint`)

////   Erlang   — https://www.erlang.org/doc/apps/stdlib/unicode.html

////              (`unicode:characters_to_list`)

////   UAX #15  — https://www.unicode.org/reports/tr15/ (normalization forms)

//// 

//// `codepoints(s)` decomposes a string into its sequence of Unicode

//// codepoints (the i32 representation each backend hands back as an

//// integer). `fromCodepoint(cp)` lifts a single codepoint to a string

//// through the primitive `String.fromCodepoint` (a `fn:` body on every

//// target); `firstCodepoint(s)` peeks the head. The carry-forward declares use

//// the typed `#[compiler.external(.<Target>)]` annotation form (migrated in

//// `external-target-libs-migration` F5-partial, c828308).

//// 

//// `normalize(s, form)` renders `s` under NFC, NFD, NFKC or NFKD by std's

//// own botopink body on all four targets (decision 333 (A)) — no host

//// normalizer is asked, so every target answers the same for every code

//// point, under the one Unicode version `unicode_tables.bp` was generated

//// from (`zig build gen-unicode`, `libs/std/AGENTS.md` § unicode): decompose

//// (recursively; compatibility mappings too for NFKC / NFKD), put each run

//// of non-starters in canonical order (a stable sort by combining class),

//// then, for NFC / NFKC, recompose every unblocked pair whose primary

//// composite is not excluded. Hangul syllables decompose and compose by the

//// algorithm of Unicode §3.12, not by the tables.

const tables = require("../std/internal/unicode_tables.js");

// The one-character string of the scalar value `cp` (decision 262): every

// target runs this body, a call of the primitive `string.fromCodepoint`, so a

// `cp` that is no Unicode scalar value — negative, a surrogate, past U+10FFFF —

// aborts the program the same way everywhere.

function fromCodepoint(cp) {
    return ((__c) => { if (!(__c >= 0 && __c <= 1114111) || (__c >= 55296 && __c <= 57343)) throw new RangeError('String.fromCodepoint: ' + __c + ' is not a Unicode scalar value'); return String.fromCodePoint(__c); })(cp);
}
exports.fromCodepoint = fromCodepoint;

// firstCodepointOrZero: per-call template (see annotation)

// wasm's cell: a wasm string is UTF-8 indexed by code point (decision 240),

// so `charCodeAt(0)` of its first character IS the code point.

function firstCodepointOrZeroBody(s) {
    let s$sp = null;
    if ((((s$sp ??= __bp_has_surrogate(s)) ? __bp_str_length(s) : s.length) === 0)) { return 0; }
    return s.charCodeAt(0);
}

// First codepoint of `s`, or `null` for the empty string. Implemented

// in pure botopink over `firstCodepointOrZero` + a length check —

// keeps the host call to a single template invocation and lets the

// option wrapping shape match the rest of std.

function firstCodepoint(s) {
    let s$sp = null;
    if ((((s$sp ??= __bp_has_surrogate(s)) ? __bp_str_length(s) : s.length) === 0)) { return null; }
    const cp = (s.codePointAt(0) ?? 0);
    return cp;
}
exports.firstCodepoint = firstCodepoint;

// Decompose a string into its sequence of Unicode codepoints.

// Node: `Array.from($0).map(c => c.codePointAt(0))` — `Array.from` on

// a string iterates by codepoint (not by UTF-16 unit), and the comma

// operator inside the arrow body keeps the expression a single template

// substitution. Erlang: `unicode:characters_to_list/2` returns an

// integer list of codepoints when given a UTF-8 binary.

// codepoints: per-call template (see annotation)
function codepoints(s) { return (Array.from(s).map((__c) => __c.codePointAt(0))); }
exports.codepoints = codepoints;

// wasm's cell: one code point per character (decision 240).

function codepointsBody(s) {
    return s.chars().map((c) => {
    return c.charCodeAt(0);
});
}

// Which Unicode normalization form to apply (NFC, NFD, NFKC, NFKD).

class NormalizationForm {
    toString() {
        return __bp_text(this);
    }
}
NormalizationForm.prototype.__bp = "NormalizationForm";
class NormalizationForm$NFC extends NormalizationForm {
}
NormalizationForm$NFC.prototype.tag = "NFC";
class NormalizationForm$NFD extends NormalizationForm {
}
NormalizationForm$NFD.prototype.tag = "NFD";
class NormalizationForm$NFKC extends NormalizationForm {
}
NormalizationForm$NFKC.prototype.tag = "NFKC";
class NormalizationForm$NFKD extends NormalizationForm {
}
NormalizationForm$NFKD.prototype.tag = "NFKD";
NormalizationForm.NFC = new NormalizationForm$NFC();
NormalizationForm.NFD = new NormalizationForm$NFD();
NormalizationForm.NFKC = new NormalizationForm$NFKC();
NormalizationForm.NFKD = new NormalizationForm$NFKD();
exports.NormalizationForm = NormalizationForm;

// Render `s` under the normalization form `form` (UAX #15). Text whose code

// points are all below U+00A0 is the same under every form and comes back

// as it is.

function normalize(s, form) {
    const cps = (Array.from(s).map((__c) => __c.codePointAt(0)));
    if (cps.all((c) => {
    return (c < 160);
})) { return s; }
    // One arm per form: beam lowers an or-pattern `NFKC | NFKD` to no test at;
    // all (front 97's compiler residual 10).;
    const compat = (() => {
        const _s = form;
        if (_s.tag === "NFKC") return true;
        if (_s.tag === "NFKD") return true;
        return false;
    })();
    const compose = (() => {
        const _s = form;
        if (_s.tag === "NFC") return true;
        if (_s.tag === "NFKC") return true;
        return false;
    })();
    const ordered = canonicalOrder(decompose(cps, compat));
    const out = (() => { if (compose) { return recompose(ordered); } else { return ordered; } })();
    return out.map((c) => {
    return fromCodepoint(c);
}).join("");
}
exports.normalize = normalize;

// ── the algorithm ────────────────────────────────────────────────────────────

// Hangul (Unicode §3.12): the syllables U+AC00…U+D7A3 are LV or LVT

// sequences of the conjoining jamo L U+1100…, V U+1161…, T U+11A7… (T index

// 0 is "no trailing consonant").

const hangulSBase = 44032;

const hangulLBase = 4352;

const hangulVBase = 4449;

const hangulTBase = 4519;

const hangulLCount = 19;

const hangulVCount = 21;

const hangulTCount = 28;

const hangulNCount = 588;

const hangulSCount = 11172;

function isHangulSyllable(cp) {
    const above = (cp >= hangulSBase);
    return (above && (cp < __bp_int((hangulSBase + hangulSCount), -2147483648, 2147483647, "+ on i32 at src/unicode.bp:132:38")));
}

function hangulDecomposition(cp) {
    const index = __bp_int((cp - hangulSBase), -2147483648, 2147483647, "- on i32 at src/unicode.bp:136:20");
    const t = __bp_int((index % hangulTCount), -2147483648, 2147483647, "% on i32 at src/unicode.bp:137:19");
    const vt = __bp_int((index % hangulNCount), -2147483648, 2147483647, "% on i32 at src/unicode.bp:138:20");
    const l = __bp_int((hangulLBase + __bp_int(Math.trunc(((__bp_int((index - vt), -2147483648, 2147483647, "- on i32 at src/unicode.bp:139:34")) / hangulNCount)), -2147483648, 2147483647, "/ on i32 at src/unicode.bp:139:40")), -2147483648, 2147483647, "+ on i32 at src/unicode.bp:139:25");
    const v = __bp_int((hangulVBase + __bp_int(Math.trunc(((__bp_int((vt - t), -2147483648, 2147483647, "- on i32 at src/unicode.bp:140:31")) / hangulTCount)), -2147483648, 2147483647, "/ on i32 at src/unicode.bp:140:36")), -2147483648, 2147483647, "+ on i32 at src/unicode.bp:140:25");
    if ((t === 0)) { return [l, v]; }
    return [l, v, __bp_int((hangulTBase + t), -2147483648, 2147483647, "+ on i32 at src/unicode.bp:142:31")];
}

// The full decomposition of `cp`: its mapping, decomposed again until no

// code point maps. A compatibility mapping is followed only when `compat`

// and the code point has no canonical one.

function fullDecomposition(cp, compat) {
    if (isHangulSyllable(cp)) { return hangulDecomposition(cp); }
    const canonical = tables.canonicalDecomposition(cp);
    const mapping = (() => { if ((canonical.length > 0)) { return canonical; } else { return (() => { if (compat) { return tables.compatibilityDecomposition(cp); } else { return canonical; } })(); } })();
    if ((mapping.length === 0)) { return [cp]; }
    let out = [];
    for (const m of mapping) {
    out = out.concat(fullDecomposition(m, compat));
}
    return out;
}

function decompose(cps, compat) {
    let out = [];
    for (const c of cps) {
    out = out.concat(fullDecomposition(c, compat));
}
    return out;
}

// The canonical ordering algorithm: every run of non-starters (combining

// class > 0) sorted by class, stably — marks of one class keep their order.

function canonicalOrder(cps) {
    let out = [];
    let run = [];
    for (const c of cps) {
    const k = tables.combiningClass(c);
    (() => { if ((k === 0)) { out = out.concat(run).concat([c]); return run = []; } else { return run = insertByClass(run, c, k); } })();
}
    return out.concat(run);
}

// `c` (of class `k`) placed into `run`, which is sorted by class, after

// every mark whose class is at most `k`.

function insertByClass(run, c, k) {
    const at = run.count((x) => {
    return (tables.combiningClass(x) <= k);
});
    return run.slice(0, at).concat([c]).concat(run.slice(at, run.length));
}

// The canonical composition algorithm over a canonically ordered sequence:

// each character is composed with the last starter when nothing between

// them blocks it — no character in between, or the last one in between of

// a lower class than its own — and the pair has a primary composite.

// `pending` holds the characters after the starter that did not compose

// (all non-starters: a starter that does not compose becomes the next

// starter), `lastClass` the class of the last of them.

function recompose(cps) {
    let out = [];
    let starter = (-1);
    let pending = [];
    let lastClass = 0;
    for (const c of cps) {
    const k = tables.combiningClass(c);
    const adjacent = (pending.length === 0);
    const unblocked = (adjacent || (lastClass < k));
    const open = ((starter >= 0) && unblocked);
    const composite = (() => { if (open) { return primaryComposite(starter, c); } else { return 0; } })();
    (() => { if ((composite !== 0)) { return starter = composite; } else { return (() => { if ((k === 0)) { out = withStarter(out, starter, pending); starter = c; pending = []; return lastClass = 0; } else { pending = pending.concat([c]); return lastClass = k; } })(); } })();
}
    return withStarter(out, starter, pending);
}

// `out` followed by the starter (none when negative) and what followed it.

function withStarter(out, starter, pending) {
    if ((starter < 0)) { return out.concat(pending); }
    return out.concat([starter]).concat(pending);
}

// The primary composite of `first` then `second`, or 0: Hangul LV and LVT by

// the algorithm, every other pair from the tables.

function primaryComposite(first, second) {
    const lIndex = __bp_int((first - hangulLBase), -2147483648, 2147483647, "- on i32 at src/unicode.bp:239:24");
    const vIndex = __bp_int((second - hangulVBase), -2147483648, 2147483647, "- on i32 at src/unicode.bp:240:25");
    const isL = ((lIndex >= 0) && (lIndex < hangulLCount));
    const isV = ((vIndex >= 0) && (vIndex < hangulVCount));
    if ((isL && isV)) { return __bp_int((hangulSBase + __bp_int(((__bp_int((__bp_int((lIndex * hangulVCount), -2147483648, 2147483647, "* on i32 at src/unicode.bp:244:38") + vIndex), -2147483648, 2147483647, "+ on i32 at src/unicode.bp:244:53")) * hangulTCount), -2147483648, 2147483647, "* on i32 at src/unicode.bp:244:63")), -2147483648, 2147483647, "+ on i32 at src/unicode.bp:244:28"); }
    const tIndex = __bp_int((second - hangulTBase), -2147483648, 2147483647, "- on i32 at src/unicode.bp:245:25");
    const isLv = (isHangulSyllable(first) && (__bp_int(((__bp_int((first - hangulSBase), -2147483648, 2147483647, "- on i32 at src/unicode.bp:247:19")) % hangulTCount), -2147483648, 2147483647, "% on i32 at src/unicode.bp:247:34") === 0));
    const isT = ((tIndex > 0) && (tIndex < hangulTCount));
    if ((isLv && isT)) { return __bp_int((first + tIndex), -2147483648, 2147483647, "+ on i32 at src/unicode.bp:249:35"); }
    return tables.primaryComposite(first, second);
}

// ── tests ────────────────────────────────────────────────────────────────────

// Non-ASCII text is built from code points: the erlang backend truncates a

// `\u{…}` literal above U+007F to one latin1 byte.

function text(cps) {
    return cps.map((c) => {
    return fromCodepoint(c);
}).join("");
}

function codes(s) {
    return (Array.from(s).map((__c) => __c.codePointAt(0))).map((c) => {
    return c.toString();
}).join(" ");
}

Object.defineProperty(exports, "__bp_priv__", { value: { tables, fromCodepoint, firstCodepointOrZeroBody, firstCodepoint, codepoints, codepointsBody, NormalizationForm, NormalizationForm$NFC, NormalizationForm$NFD, NormalizationForm$NFKC, NormalizationForm$NFKD, normalize, hangulSBase, hangulLBase, hangulVBase, hangulTBase, hangulLCount, hangulVCount, hangulTCount, hangulNCount, hangulSCount, isHangulSyllable, hangulDecomposition, fullDecomposition, decompose, canonicalOrder, insertByClass, recompose, withStarter, primaryComposite, text, codes } });
