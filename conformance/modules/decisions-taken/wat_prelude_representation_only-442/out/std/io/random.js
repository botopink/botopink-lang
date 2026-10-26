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

// behavior Float extends Number
//   fn toString(...)
//   fn abs(...)
//   fn floor(...)
//   fn ceil(...)
//   fn round(...)
//   fn squareRoot(...)
BigInt.prototype.abs = Number.prototype.abs = function() { return ((__a) => (__a < 0 || Object.is(__a, -0)) ? -__a : __a)(this.valueOf()); };
BigInt.prototype.floor = Number.prototype.floor = function() { return Math.floor(this.valueOf()); };
BigInt.prototype.ceil = Number.prototype.ceil = function() { return Math.ceil(this.valueOf()); };
BigInt.prototype.round = Number.prototype.round = function() { return Math.round(this.valueOf()); };
BigInt.prototype.squareRoot = Number.prototype.squareRoot = function() { return Math.sqrt(this.valueOf()); };

//// std/io/random — pseudo-random number primitives (cross-backend).

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/  (the `Math.random` global)

////   Erlang   — https://www.erlang.org/doc/apps/stdlib/rand.html

//// 

//// `float()` returns a uniform `[0.0, 1.0)` sample on every backend.

//// Higher-level helpers (`coin`/`pick`) compose `float()` — portable +

//// no host call beyond the uniform sample. Seedable RNGs are deferred:

//// Node has no built-in seedable PRNG behind `Math.random`, so any

//// seed/state surface needs a userland PRNG; ship that in a follow-up

//// once the test infra is ready for reproducible draws.

//// 

//// NOT A CSPRNG: everything above `secureToken` is `Math.random` /

//// `rand:uniform`, predictable to anyone who sees enough draws. A token, a

//// session id, a nonce or a UUID comes from `secureToken` / `uuidV4`, which

//// read the host's cryptographic source (`crypto.randomBytes`,

//// `crypto:strong_rand_bytes/1`) — or `crypto.randomBytes` for hex.

// float: per-call template (see annotation)
function float() { return Math.random(); }
exports.float = float;

// Seed the Node-side userland PRNG (Mulberry32) shipped via the sidecar

// at `libs/std/src/sidecars/random.mjs`. After seeding, `seededFloat()`

// draws from the reproducible stream. `float()` itself stays on

// `Math.random`; explicit-stream callers opt into determinism by using

// `seededFloat` after `seed`.

// Node: `require('./sidecars/random.mjs').seed($0)` — the CLI's sidecar

// shipper copies the `.mjs` next to the emitted module.

// Erlang: `rand:seed/2` with the `exsplus` algorithm + a `{S, S, S}`

// triple. `S` is folded to an integer via the i64 input.

// seed: per-call template (see annotation)
function seed(s) { return require('./sidecars/random.mjs').seed(s); }
exports.seed = seed;

// Draw from the seeded PRNG when a `seed` call has been made; otherwise

// falls through to the unseeded `float()` baseline. Erlang's `rand`

// module reads from the process dictionary's seed state directly, so

// the same `rand:uniform/0` call after `seed` produces the reproducible

// stream automatically.

// seededFloat: per-call template (see annotation)
function seededFloat() { return require('./sidecars/random.mjs').seededFloat(); }
exports.seededFloat = seededFloat;

// 50/50 boolean draw. `float() >= 0.5` picks the upper half of the

// uniform sample — identically distributed on every backend that has

// a uniform `float()`.

function coin() {
    return (Math.random() >= 0.5);
}
exports.coin = coin;

// Random integer in the closed interval `[lo, hi]`. When `lo > hi` the

// range is empty and the result is `lo` (a defensive default — the

// alternative is to `panic`, which the @assert-style tests would

// rather catch at the call site).

function intInRange(lo, hi) {
    if ((lo >= hi)) { return lo; }
    const span = __bp_int(((__bp_int((hi - lo), -2147483648, 2147483647, "- on i32 at src/io/random.bp:66:20")) + 1), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:66:26");
    const product = (Math.random() * span);
    const offset = floorWalk(0, 1.0, product, span);
    return __bp_int((lo + offset), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:69:15");
}
exports.intInRange = intInRange;

// Pick a random element from a non-empty array. Returns `null` for the

// empty array — the call site should default with `?? …` rather

// than panic. Uses a walk-up integer floor (no `Math.floor` import) so

// the body stays self-contained.

function pick(xs) {
    const n = xs.length;
    if ((n === 0)) { return null; }
    // `float() * n` mixes f64 × i32 — inference promotes to f64.;
    const product = (Math.random() * n);
    const idx = floorWalk(0, 1.0, product, n);
    return __bp_array_at(xs, idx);
}
exports.pick = pick;

// Internal: integer floor of a non-negative `product` < `upper`. Walks

// `start` up from 0 while `threshold (= start + 1)` still fits below

// `product`. O(upper) — fine for the small `array<T>` arities `pick`

// targets in tests.

function floorWalk(start, threshold, product, upper) {
    while (true) {
        if ((__bp_int((start + 1), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:90:15") > upper)) { return start; }
        if ((threshold > product)) { return start; }
        { const __bp_tc0 = __bp_int((start + 1), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:92:28"); const __bp_tc1 = (threshold + 1.0); start = __bp_tc0; threshold = __bp_tc1; continue; }
    }
}

// Fisher-Yates shuffle. Returns a fresh array whose elements are a

// permutation of `xs`. The pure-bp shape was deferred (the deferral

// note used to live here) because `array<T>::at(i)` returns `?T` and

// extracting T without a sentinel value of T is circular. Solution:

// host-backed `pub declare fn shuffle<T>(xs)` — the host owns the

// in-place swap; the bp side only declares the signature and the

// per-target template.

// 

// Node: classic Fisher-Yates over the input array, returning a fresh

// copy (the input is not mutated — matches the immutable-by-default

// botopink contract for return values). `random.seed` from this same

// module seeds the sidecar PRNG; subsequent `shuffle` draws are

// reproducible after `seed(s)`.

// 

// Erlang: `[X || {_, X} <- lists:sort([{rand:uniform(), Y} || Y <- $0])]`

// — the Schwartzian-transform shuffle: pair each element with a

// random key, sort by key, strip the keys. Stable across `rand:seed`

// state (the same `rand` server `seed/2` controls both `uniform/0`

// here and `seededFloat()` above).

// 

// Beam/wasm: out of scope at v1 (no `lists:sort` template, no

// `Math.random` equivalent in wat3); the matrix will report

// `MissingExternalTarget` on a `shuffle(...)` call from those backends

// until the corresponding shim lands.

// shuffle: per-call template (see annotation)
function shuffle(xs) { return (function(__A){ var __O = __A.slice(); for (var __I = __O.length - 1; __I > 0; __I--) { var __J = Math.floor(Math.random() * (__I + 1)); var __T = __O[__I]; __O[__I] = __O[__J]; __O[__J] = __T; } return __O; })(xs); }
exports.shuffle = shuffle;

// ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

// 

// The CSPRNG half. Everything ABOVE is `Math.random` / `rand:uniform` — fine

// for a shuffle, wrong for anything an attacker must not guess. A token, a

// session id, a nonce or a UUID comes from the two functions below, which

// read the host's cryptographically strong source.

// `bytes` strong random bytes as base64url without padding — URL-, cookie-

// and header-safe. 32 bytes answer 43 characters.

// Node: `crypto.randomBytes(n).toString('base64url')`.

// Erlang: `crypto:strong_rand_bytes/1` + `base64:encode/2` in `urlsafe`

// mode without padding (OTP 26+).

// secureToken: per-call template (see annotation)
function secureToken(bytes) { return require('crypto').randomBytes(bytes).toString('base64url'); }
exports.secureToken = secureToken;

// A random (version 4) UUID, lowercase: 122 strong random bits with the

// version nibble set to `4` and the variant bits to `10` (RFC 9562 §5.4).

// Node: `crypto.randomUUID()`.

// Erlang: 16 strong random bytes, the version/variant bits rewritten in the

// binary pattern — the bit work lives in the template because botopink has

// no bitwise operators (`language-gaps.md`).

// uuidV4: per-call template (see annotation)
function uuidV4() { return require('crypto').randomUUID(); }
exports.uuidV4 = uuidV4;

// ── tests ────────────────────────────────────────────────────────────────────

// ── randomBytes (was `crypto.randomBytes`) ───────────────────────────────────

// `n` cryptographically-secure random bytes as a hex string of length

// `2 * n` (each byte rendered as two lowercase hex chars). The hex shape

// sidesteps the `array<u8>` cross-backend representation gap — Node

// `Buffer` and Erlang `binary()` don't share a bp-side type. Callers

// that need bytes parse the hex back themselves.

// Node: `require('crypto').randomBytes(n).toString('hex')`.

// Erlang: `crypto:strong_rand_bytes/1` + the same per-byte hex format

// string used by the hashes above.

// randomBytes: per-call template (see annotation)
function randomBytes(n) { return require('crypto').randomBytes(n).toString('hex'); }
exports.randomBytes = randomBytes;

// ── the wasm bodies (decision 238) ──────────────────────────────────────────

// wasm has no host for these cells, so each names one of the private bodies

// below with `#[compiler.external(.Wasm(fn: …))]`; commonJS and erlang call their

// host. On wasm `float()` is `std: "random.float"` — 53 bits of WASI's

// `random_get`, the host's cryptographic source — so the token, UUID and

// byte bodies draw from it a byte at a time (`randomByte`: ⌊u · 256⌋ of a

// 53-bit uniform `u` is exactly uniform). `seed` / `seededFloat` are

// std-wasm's seeded stream (decision 451, `std: "random.…"`), drawn as the

// commonJS sidecar does (Mulberry32): the same draws after the same `seed`; a

// draw before any seed is the host's (`float()`'s source). At comptime the

// same cells answer, and a draw before any seed is refused — a build has no

// entropy.

// Selection shuffle: each step moves a uniformly drawn element of what is

// left to the output — a uniform permutation, as the Node cell's

// Fisher-Yates; the elements are moved as one-element slices, never read.

function shuffleBody(xs, __bp_ty_T) {
    let rest = xs;
    let out = xs.slice(0, 0);
    while ((rest.length > 0)) {
    const j = wholeOf(((Math.random() * rest.length)).floor());
    out = out.concat(rest.slice(j, __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:319:42")));
    rest = rest.slice(0, j).concat(rest.slice(__bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:320:53"), rest.length));
}
    return out;
}

function secureTokenBody(bytes) {
    return base64UrlOf(randomBytesOf(bytes));
}

// RFC 9562 §5.4: 16 random bytes, the version nibble 4, the variant `10`.

function uuidV4Body() {
    const b = randomBytesOf(16);
    const version = __bp_int((64 + __bp_int(((() => { const __bp_nullish = __bp_array_at(b, 6); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() % 16), -2147483648, 2147483647, "% on i32 at src/io/random.bp:332:37")), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:332:22");
    const variant = __bp_int((128 + __bp_int(((() => { const __bp_nullish = __bp_array_at(b, 8); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() % 64), -2147483648, 2147483647, "% on i32 at src/io/random.bp:333:38")), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:333:23");
    return ((((((((hexOf(b.slice(0, 4)) + "-") + hexOf(b.slice(4, 6))) + "-") + hexOf([version, (() => { const __bp_nullish = __bp_array_at(b, 7); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })()])) + "-") + hexOf([variant, (() => { const __bp_nullish = __bp_array_at(b, 9); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })()])) + "-") + hexOf(b.slice(10, 16)));
}

function randomBytesBody(n) {
    return hexOf(randomBytesOf(n));
}

function randomByte() {
    return wholeOf(((Math.random() * 256.0)).floor());
}

function randomBytesOf(n) {
    let out = [];
    let i = 0;
    while ((i < n)) {
    out = out.concat([randomByte()]);
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:358:15");
}
    return out;
}

function hexDigit(n) {
    return (() => { const __bp_nullish = ("0123456789abcdef".at(n) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
}

function hexOf(bytes) {
    return bytes.map((b) => {
    return (hexDigit(__bp_int(Math.trunc((b / 16)), -2147483648, 2147483647, "/ on i32 at src/io/random.bp:368:40")) + hexDigit(__bp_int((b % 16), -2147483648, 2147483647, "% on i32 at src/io/random.bp:368:59")));
}).join("");
}

// RFC 4648 §5 base64url, unpadded.

function base64UrlOf(bytes) {
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    let out = "";
    let g = 0;
    while ((__bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/io/random.bp:376:14") < bytes.length)) {
    const n = __bp_int((bytes.length - __bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/io/random.bp:377:34")), -2147483648, 2147483647, "- on i32 at src/io/random.bp:377:30");
    const b0 = (() => { const __bp_nullish = __bp_array_at(bytes, __bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/io/random.bp:378:29")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    const b1 = (() => { if ((n > 1)) { return (() => { const __bp_nullish = __bp_array_at(bytes, __bp_int((__bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/io/random.bp:380:24") + 1), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:380:28")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })(); } else { return 0; } })();
    const b2 = (() => { if ((n > 2)) { return (() => { const __bp_nullish = __bp_array_at(bytes, __bp_int((__bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/io/random.bp:383:24") + 2), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:383:28")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })(); } else { return 0; } })();
    out = ((out + (() => { const __bp_nullish = (alphabet.at(__bp_int(Math.trunc((b0 / 4)), -2147483648, 2147483647, "/ on i32 at src/io/random.bp:386:30")) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()) + (() => { const __bp_nullish = (alphabet.at(__bp_int((__bp_int(((__bp_int((b0 % 4), -2147483648, 2147483647, "% on i32 at src/io/random.bp:387:31")) * 16), -2147483648, 2147483647, "* on i32 at src/io/random.bp:387:36") + __bp_int(Math.trunc((b1 / 16)), -2147483648, 2147483647, "/ on i32 at src/io/random.bp:387:46")), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:387:41")) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })());
    (() => { if ((n > 1)) { return out = (out + (() => { const __bp_nullish = (alphabet.at(__bp_int((__bp_int(((__bp_int((b1 % 16), -2147483648, 2147483647, "% on i32 at src/io/random.bp:388:48")) * 4), -2147483648, 2147483647, "* on i32 at src/io/random.bp:388:54") + __bp_int(Math.trunc((b2 / 64)), -2147483648, 2147483647, "/ on i32 at src/io/random.bp:388:63")), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:388:58")) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()); } })();
    (() => { if ((n > 2)) { return out = (out + (() => { const __bp_nullish = (alphabet.at(__bp_int((b2 % 64), -2147483648, 2147483647, "% on i32 at src/io/random.bp:389:47")) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()); } })();
    g = __bp_int((g + 1), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:390:15");
}
    return out;
}

// A whole `v` in [0, 2^31) as an `i32`.

function wholeOf(v) {
    let r = 0;
    let rest = v;
    let bit = 1073741824;
    let weight = 1073741824.0;
    while ((bit > 0)) {
    (() => { if ((rest >= weight)) { r = __bp_int((r + bit), -2147483648, 2147483647, "+ on i32 at src/io/random.bp:403:19"); return rest = (rest - weight); } })();
    bit = __bp_int(Math.trunc((bit / 2)), -2147483648, 2147483647, "/ on i32 at src/io/random.bp:406:19");
    weight = (weight / 2.0);
}
    return r;
}

Object.defineProperty(exports, "__bp_priv__", { value: { float, seed, seededFloat, coin, intInRange, pick, floorWalk, shuffle, secureToken, uuidV4, randomBytes, shuffleBody, secureTokenBody, uuidV4Body, randomBytesBody, randomByte, randomBytesOf, hexDigit, hexOf, base64UrlOf, wholeOf } });
