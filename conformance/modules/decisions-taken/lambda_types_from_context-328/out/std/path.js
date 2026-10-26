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

//// std/path — pure-botopink path manipulation (posix forward-slash).

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/path.html

////   Erlang   — https://www.erlang.org/doc/apps/stdlib/filename.html

//// 

//// Lib-self-contained: every operation composes `String` methods (`split`,

//// `slice`, `length`, `startsWith`), so the module works on every backend

//// including wat. Forward-slash separator only — Windows backslash paths

//// are not normalised here (the spec keeps `path` posix-shaped; a

//// `path_win32` sibling can land later if a target needs it).

const separator = "/";

exports.separator = separator;

const delimiter = ":";

exports.delimiter = delimiter;

// Split a path into its non-empty components. Leading-`/` paths drop the

// empty head; trailing-`/` paths drop the empty tail. A path made of pure

// separators yields the empty array. Uses `filter` rather than

// `forEach` + `push`: a `var` + `push` pattern lowers to a dead-store

// (`out ++ [p]` discarded) on Erlang because the immutable runtime never

// rebinds `Out`; `filter` round-trips through `lists:filter/2` and

// `Array.prototype.filter` directly.

function split(path) {
    const raw = path.split(separator);
    return raw.filter((p) => {
    return (p !== "");
});
}
exports.split = split;

// True when `path` starts with `/` — the posix absolute-path marker.

function isAbsolute(path) {
    return path.startsWith(separator);
}
exports.isAbsolute = isAbsolute;

// The last non-empty component of `path` (the file name, in the common

// case). Returns "" for the empty path and for pure-separator paths.

function basename(path) {
    const parts = split(path);
    const n = parts.length;
    if ((n === 0)) { return ""; }
    return (() => { const __bp_nullish = __bp_array_at(parts, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:40:23")); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
}
exports.basename = basename;

// Everything except the basename — the parent directory portion. For an

// absolute path this preserves the leading `/`. For a path with no

// separator (`"foo"`), returns `""`.

function dirname(path) {
    const parts = split(path);
    const n = parts.length;
    if ((n <= 1)) { return (() => { if (isAbsolute(path)) { return separator; } else { return ""; } })(); }
    const head = parts.slice(0, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:50:33"));
    const joined = head.join(separator);
    // String `+` lowers to numeric `+` on Erlang (badarith on binaries);;
    // use a 2-element array `.join("")` to concat instead — that goes;
    // through `lists:join("", …)` + `iolist_to_binary` on Erlang and;
    // `Array.prototype.join("")` on Node, both string-safe.;
    return (() => { if (isAbsolute(path)) { return [separator, joined].join(""); } else { return joined; } })();
}
exports.dirname = dirname;

// The trailing extension on the basename — the substring from the LAST

// `.` to the end, including the dot. Returns `""` when the basename has

// no extension (or is a dotfile with no further `.`s, e.g. `.bashrc`).

function extname(path) {
    const base = basename(path);
    const pieces = base.split(".");
    const n = pieces.length;
    if ((n <= 1)) { return ""; }
    const head = (() => { const __bp_nullish = __bp_array_at(pieces, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    const tail = (() => { const __bp_nullish = __bp_array_at(pieces, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:68:28")); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    // Dotfiles like ".bashrc" split into ["", "bashrc"] — no extension.;
    const isDotfile = ((head === "") && (n === 2));
    return (() => { if (isDotfile) { return ""; } else { return [".", tail].join(""); } })();
}
exports.extname = extname;

// Join a list of path segments with the separator. Leading separator on

// the first segment is preserved; intra-segment slashes are normalised

// (`"foo/" + "/bar"` joins to `"foo/bar"`, never `"foo//bar"`). Uses

// `map` + `filter` + `join` rather than `fold` / `flatMap`: those land

// on `array<T>` default-fn bodies that lower to a `var` + `push` shape,

// which lowers to a dead store on Erlang's immutable runtime (the same

// trap `split` sidesteps).

function join(parts) {
    const isAbs = (() => { if ((parts.length === 0)) { return false; } else { return isAbsolute((() => { const __bp_nullish = __bp_array_at(parts, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()); } })();
    const collapsed = parts.map((p) => {
    return split(p).join(separator);
});
    const joined = collapsed.filter((p) => {
    return (p !== "");
}).join(separator);
    return (() => { if (isAbs) { return [separator, joined].join(""); } else { return joined; } })();
}
exports.join = join;

// Collapse `//` and drop `.` segments via a `filter` over the split

// pieces. Full `..` pop semantics are deferred: they need a stack-shaped

// accumulator and `var` reassignment, which lowers to a dead store on

// Erlang's immutable runtime (the same trap `split`/`join` sidestep with

// `filter`/`flatMap`).

function normalize(path) {
    if ((path === "")) { return "."; }
    const isAbs = isAbsolute(path);
    const pieces = split(path).filter((p) => {
    return (p !== ".");
});
    const joined = pieces.join(separator);
    return (() => { if (isAbs) { return [separator, joined].join(""); } else { return (() => { if ((joined === "")) { return "."; } else { return joined; } })(); } })();
}
exports.normalize = normalize;

// Internal: count how many leading components two split paths share. Tail-

// recursive on `i` so the accumulator never needs a `var` rebind (which

// lowers to a dead store on Erlang's immutable runtime).

function commonPrefixCount(a, b, i) {
    if ((i >= a.length)) { return i; }
    if ((i >= b.length)) { return i; }
    const ai = (() => { const __bp_nullish = __bp_array_at(a, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    const bi = (() => { const __bp_nullish = __bp_array_at(b, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    return (() => { if (__bp_eq(ai, bi, 0)) { return commonPrefixCount(a, b, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/path.bp:114:52")); } else { return i; } })();
}

// Internal: build an array of `n` ".." strings via head/tail recursion.

// Avoids a `var` + `push` accumulator (the Erlang dead-store trap).

function makeUps(n) {
    return (() => { if ((n <= 0)) { return []; } else { return makeUps(__bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:120:42")).prepend(".."); } })();
}

// The relative path from `src` to `dst` — the path you would prefix to

// `src` to reach `dst`. Both inputs are treated structurally (no `cwd()`

// fallback — that belongs in `process` once it lands). Returns "." when

// the paths point at the same location.

// 

// `src` is named `src` rather than `from` because `from` is a reserved

// keyword (the `import { … } from "<lib>"` syntax) — it does not parse

// as a parameter name.

function relative(src, dst) {
    const srcParts = split(src);
    const dstParts = split(dst);
    const common = commonPrefixCount(srcParts, dstParts, 0);
    const ups = makeUps(__bp_int((srcParts.length - common), -2147483648, 2147483647, "- on i32 at src/path.bp:135:39"));
    const downs = dstParts.slice(common, dstParts.length);
    const combined = ups.concat(downs);
    const joined = combined.join(separator);
    return (() => { if ((joined === "")) { return "."; } else { return joined; } })();
}
exports.relative = relative;

// Internal accumulator for `resolve`: a list of normalised path parts

// plus whether the resolved-so-far path is absolute. The record carries

// the state through the tail-recursive `resolveAll` so no `var` is

// needed.

class PathAccum {
    constructor(isAbs, parts) {
        this.isAbs = isAbs;
        this.parts = parts;
    }
}
PathAccum.prototype.__bp = "PathAccum";

// Internal: apply each component of one segment (post-split) to the

// accumulator, popping for `..` and appending the rest. Head/tail

// recursive — no `var` rebinds.

function applyPieces(acc, pieces) {
    while (true) {
        if ((pieces.length === 0)) { return acc; }
        const p = (() => { const __bp_nullish = __bp_array_at(pieces, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
        const rest = pieces.slice(1, pieces.length);
        const nextAcc = (() => { if ((p === "..")) { return (() => { if ((acc.length === 0)) { return acc; } else { return acc.slice(0, __bp_int((acc.length - 1), -2147483648, 2147483647, "- on i32 at src/path.bp:159:63")); } })(); } else { return acc.concat([p]); } })();
        { acc = nextAcc; pieces = rest; continue; }
    }
}

function resolveStep(state, seg) {
    const pieces = split(seg);
    const nextIsAbs = (isAbsolute(seg) || state.isAbs);
    const baseParts = (() => { if (isAbsolute(seg)) { return []; } else { return state.parts; } })();
    return new PathAccum(nextIsAbs, applyPieces(baseParts, pieces));
}

function resolveAll(segments, i, state) {
    while (true) {
        if ((i >= segments.length)) { return state; }
        const seg = (() => { const __bp_nullish = __bp_array_at(segments, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
        const next = resolveStep(state, seg);
        { const __bp_tc1 = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/path.bp:175:35"); i = __bp_tc1; state = next; continue; }
    }
}

// Resolve a list of path segments into a single normalised path.

// Absolute segments restart the accumulator (matches Node's

// `path.resolve`); `..` pops one component; `.` drops out (already

// filtered by `split`). The empty input resolves to ".".

function resolve(segments) {
    const finalState = resolveAll(segments, 0, new PathAccum(false, []));
    const joined = finalState.parts.join(separator);
    return (() => { if (finalState.isAbs) { return [separator, joined].join(""); } else { return (() => { if ((joined === "")) { return "."; } else { return joined; } })(); } })();
}
exports.resolve = resolve;

// ── 1.0.10-beta front 01 additions ───────────────────────────────────────────

// `p` without its trailing extension: `page.bp` → `page`, `archive.tar.gz`

// → `archive.tar`, `noext` → `noext`. The extension is what `extname`

// answers, so a dotfile keeps its name.

function withoutExtension(p) {
    let p$sp = null;
    const ext = extname(p);
    let ext$sp = null;
    const n = ((p$sp ??= __bp_has_surrogate(p)) ? __bp_str_length(p) : p.length);
    const stem = (() => { if ((ext === "")) { return p; } else { return p.slice(0, __bp_int((n - ((ext$sp ??= __bp_has_surrogate(ext)) ? __bp_str_length(ext) : ext.length)), -2147483648, 2147483647, "- on i32 at src/path.bp:205:51")); } })();
    return stem;
}
exports.withoutExtension = withoutExtension;

// True when `child` resolves inside `parent` — the traversal guard front 22

// applies before it turns a request path into a file path. Both sides go

// through `resolve`, which pops `..` (`normalize` does not), and a relative

// `child` is resolved against `parent`, so `isInside("/app", "blog/x")` is

// true and `isInside("/app", "blog/../../etc")` is false. A parent is inside

// itself. The check reads the first component of the relative path: `..`

// exactly, or `../…` — a component that merely starts with two dots

// (`..foo`) is a name, not an escape.

function isInside(parent, child) {
    const up = resolve([parent]);
    const down = resolve([parent, child]);
    const rel = relative(up, down);
    const escapes = ((rel === "..") || rel.startsWith("../"));
    return (escapes === false);
}
exports.isInside = isInside;

// ── tests ────────────────────────────────────────────────────────────────────

Object.defineProperty(exports, "__bp_priv__", { value: { separator, delimiter, split, isAbsolute, basename, dirname, extname, join, normalize, commonPrefixCount, makeUps, relative, PathAccum, applyPieces, resolveStep, resolveAll, resolve, withoutExtension, isInside } });
