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

function __bp_trim(s) {
    return s.replace(/^[ \t\n\r\v\f]+|[ \t\n\r\v\f]+$/g, "");
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

//// std/hash — every hash std has, pure functions all (decision 106): the hex

//// digests (`sha256`, `sha512`, `md5`, `hmacSha256` — was `crypto`), the

//// digests the security fronts need in the shape they are compared in

//// (base64url of the raw digest, RFC 7515; SHA-1 for the WebSocket accept

//// key, RFC 6455; a constant-time compare), and the content hashes for cache

//// keys, ETags and asset fingerprints (was `content_hash`). `crypto`'s

//// `randomBytes` reads entropy and lives in `io/random.bp`.

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/crypto.html

////              (`createHash`, `createHmac`, `.digest('base64' | 'base64url')`,

////               `timingSafeEqual`, `pbkdf2Sync`)

////   Erlang   — https://www.erlang.org/doc/apps/crypto/crypto.html

////              (`crypto:hash/2`, `crypto:mac/4`, `crypto:hash_equals/2`,

////               `crypto:pbkdf2_hmac/5`)

////              https://www.erlang.org/doc/apps/stdlib/base64.html

////              (`base64:encode/2` with `#{mode => urlsafe, padding => false}`)

////   RFC 4648 §5 (base64url), RFC 4231 (HMAC-SHA256), RFC 6455 §1.3

//// 

//// Each cell calls `crypto:hash/2` / `createHash` itself rather than a

//// sibling function — the duplication is in the template string, not in

//// behaviour.

//// 

//// Text in: every input is the UTF-8 bytes of a `string` (there is no

//// byte type — `language-gaps.md`), so an HMAC key is text too.

const failure = require("../std/failure.js");

// base64url (no padding) of the raw HMAC-SHA256 of `data` under `key` —

// the JWS HS256 signature (RFC 7515 §3) and a session-cookie MAC.

// hmacSha256Base64Url: per-call template (see annotation)
function hmacSha256Base64Url(key, data) { return require('crypto').createHmac('sha256', key).update(data).digest('base64url'); }
exports.hmacSha256Base64Url = hmacSha256Base64Url;

// Standard base64 (with padding) of the raw SHA-1 of `data` — the

// `Sec-WebSocket-Accept` value of RFC 6455 §1.3. SHA-1 is here for that

// handshake only; it is not a signature primitive.

// sha1Base64: per-call template (see annotation)
function sha1Base64(data) { return require('crypto').createHash('sha1').update(data).digest('base64'); }
exports.sha1Base64 = sha1Base64;

// base64url (no padding) of the raw SHA-256 of `data` — 43 characters.

// sha256Base64Url: per-call template (see annotation)
function sha256Base64Url(data) { return require('crypto').createHash('sha256').update(data).digest('base64url'); }
exports.sha256Base64Url = sha256Base64Url;

// `a == b` in time that depends only on the length, not on where the two

// first differ — the compare a signature check must use (`==` on two

// signature strings is a byte-at-a-time timing oracle on both backends).

// Different lengths answer `false` without throwing: `timingSafeEqual` and

// `crypto:hash_equals/2` both raise on a length mismatch, so each template

// checks the byte length first (the length of a MAC is not secret).

// equalsConstantTime: per-call template (see annotation)
function equalsConstantTime(a, b) { return (() => { const __a = Buffer.from(a, 'utf8'); const __b = Buffer.from(b, 'utf8'); return __a.length === __b.length && require('crypto').timingSafeEqual(__a, __b) })(); }
exports.equalsConstantTime = equalsConstantTime;

// ── 1.0.11-beta front 97: PBKDF2 ─────────────────────────────────────────────

// The cell behind `pbkdf2Sha256`: base64url (no padding) of the derived key.

// Node: `crypto.pbkdf2Sync(password, salt, iterations, length, 'sha256')`.

// Erlang: `crypto:pbkdf2_hmac(sha256, Password, Salt, Iterations, Length)`.

// pbkdf2Derive: per-call template (see annotation)

// PBKDF2-HMAC-SHA256 (RFC 8018 §5.2): `length` BYTES of key derived from

// `password` over `salt` in `iterations` rounds, as unpadded base64url — the

// shape a stored password hash is compared in (`equalsConstantTime`).

// `password` and `salt` are TEXT, their UTF-8 bytes (decision 175; there is no

// byte type): a salt that is itself base64 is derived over its characters,

// not over the bytes it encodes. The same answer on both targets for every

// input — the published vectors are the tests.

// 

// `iterations` and `length` are at least 1; anything else is a programming

// error, a panic with one text on both targets (each host raises its own

// otherwise), never an empty key.

function pbkdf2Sha256(password, salt, iterations, length) {
    const refused = ((iterations < 1) || (length < 1));
    (() => { if (refused) { return (() => { throw Object.defineProperty(new Error("hash.pbkdf2Sha256: iterations and length must be at least 1"), '__bp_panic', { value: true }) })(); } })();
    return require('crypto').pbkdf2Sync(password, salt, iterations, length, 'sha256').toString('base64url');
}
exports.pbkdf2Sha256 = pbkdf2Sha256;

// Internal, test scaffolding: the text a body panics with, `""` when it

// answered — `attempt` (decision 431), which a root module may import: it is

// not the harness.

function panicText(body) {
    return (() => {
        const _s = failure.attempt(body);
        if ("ok" in _s) {
            return "";
        }
        if ("error" in _s) {
            const f = _s.error;
            return f.message;
        }
        throw new Error("case_clause");
    })();
}

// ── tests ────────────────────────────────────────────────────────────────────

// ── hex digests (was `crypto`) ───────────────────────────────────────────────

// sha256: per-call template (see annotation)
function sha256(data) { return require('crypto').createHash('sha256').update(data).digest('hex'); }
exports.sha256 = sha256;

// sha512: per-call template (see annotation)
function sha512(data) { return require('crypto').createHash('sha512').update(data).digest('hex'); }
exports.sha512 = sha512;

// md5: per-call template (see annotation)
function md5(data) { return require('crypto').createHash('md5').update(data).digest('hex'); }
exports.md5 = md5;

// HMAC-SHA256. `key` is the secret material; `data` is the message.

// Both lower to the host's keyed-hash primitive — Node's

// `crypto.createHmac('sha256', key).update(data).digest('hex')` and

// Erlang's `crypto:mac(hmac, sha256, key, data)`.

// hmacSha256: per-call template (see annotation)
function hmacSha256(key, data) { return require('crypto').createHmac('sha256', key).update(data).digest('hex'); }
exports.hmacSha256 = hmacSha256;

// ── tests ────────────────────────────────────────────────────────────────────

// ── content hashes (was `content_hash`) ──────────────────────────────────────

// Stable hashes for cache keys, ETags and asset fingerprints (1.0.10-beta

// `01-std` front 03).

// 

// Reference:

//   RFC 9110 § 8.8.3 — https://www.rfc-editor.org/rfc/rfc9110#field.etag

//   Next.js caching  — https://nextjs.org/docs/app/getting-started/caching

//   Erlang           — https://www.erlang.org/doc/apps/crypto/crypto.html#hash/2

// 

// `strongHash` carries its own SHA-256 cell rather than calling `sha256`

// above; the truncation lives in the template.

// 

// TWO hashes, and the choice is not a matter of taste. `contentHash` is a

// djb2 fold rendered as lowercase hex: fast, stable across both targets,

// and TRIVIAL TO COLLIDE ON PURPOSE. Use it when a collision costs a wrong

// cache hit you control — an asset filename, an internal fingerprint.

// `strongHash` is SHA-256 truncated to 32 hex characters. Use it whenever

// the hashed value came from outside: a request header, a client-supplied

// tag, a key that spans a user boundary.

// 

// The `contentHash` templates were lifted from

// `repository/emilia/modules/emilia/src/emilia.bp` (`hashHex`). Every target

// folds the string's CODE POINTS (decision 260, decision 169's unit):

// `contentHash("🎉")` is `djb2([127881])` everywhere — the Node cell walks

// `Array.from(s)`, which iterates by code point, where `hashHex` still folds

// UTF-16 units and so differs from it for a character above U+FFFF.

// Collapsing `emilia.hashHex` onto std is an `emilia`-owned change. On wasm,

// and at comptime on every target, it is std-wasm's (`modules/std-wasm`,

// decision 440): its `std:` cell is the one implementation both read.

// contentHash: per-call template (see annotation)
function contentHash(value) { return (function(__S){ var __H = 5381; for (const __C of Array.from(__S)) { __H = (Math.imul(__H, 33) + __C.codePointAt(0)) >>> 0; } return __H.toString(16); })(value); }
exports.contentHash = contentHash;

// strongHash: per-call template (see annotation)
function strongHash(value) { return require('crypto').createHash('sha256').update(value).digest('hex').slice(0, 32); }
exports.strongHash = strongHash;

// ── cache keys — framed, never joined ────────────────────────────────────────

// A key over several parts. Each part is length-prefixed, so no two different

// part lists can collide: ["user:1", "profile"] and ["user", "1:profile"] frame

// to `6:user:1|7:profile` and `4:user|9:1:profile` and therefore hash to

// different keys. A cache that collides across a user boundary serves one user

// another user's page, so the framing is the whole reason this function exists

// instead of a `join`.

function cacheKey(parts) {
    return (function(__S){ var __H = 5381; for (const __C of Array.from(__S)) { __H = (Math.imul(__H, 33) + __C.codePointAt(0)) >>> 0; } return __H.toString(16); })(frame(parts));
}
exports.cacheKey = cacheKey;

// The same framing over the strong hash, for keys built from input the caller

// did not choose.

function strongCacheKey(parts) {
    return require('crypto').createHash('sha256').update(frame(parts)).digest('hex').slice(0, 32);
}
exports.strongCacheKey = strongCacheKey;

// `<length>:<part>` per part, `|` between parts. The one place a multi-part

// key is rendered, so no function in this module joins parts unframed.

function frame(parts) {
    return parts.map((p) => {
    return ((__bp_str_length(p).toString() + ":") + p);
}).join("|");
}

// ── ETags (RFC 9110 § 8.8.3) ─────────────────────────────────────────────────

// A strong ETag, quoted as RFC 9110 requires. The quotes are part of the value:

// a caller who has to remember to add them is a caller who will forget.

function etag(body) {
    return (("\"" + (function(__S){ var __H = 5381; for (const __C of Array.from(__S)) { __H = (Math.imul(__H, 33) + __C.codePointAt(0)) >>> 0; } return __H.toString(16); })(body)) + "\"");
}
exports.etag = etag;

function weakEtag(body) {
    return (("W/\"" + (function(__S){ var __H = 5381; for (const __C of Array.from(__S)) { __H = (Math.imul(__H, 33) + __C.codePointAt(0)) >>> 0; } return __H.toString(16); })(body)) + "\"");
}
exports.weakEtag = weakEtag;

// The 304 decision. Handles the three shapes a handler actually receives: an

// exact match, the `*` wildcard, and a comma-separated candidate list. The

// membership test is `indexOf`, not `Array.contains`: `contains` is a

// `default fn`, which a consumer's embedded copy of this module emits

// verbatim on commonJS (`libs/std/AGENTS.md` § Conventions).

function matches(body, ifNoneMatch) {
    const header = __bp_trim(ifNoneMatch);
    const wildcard = (header === "*");
    const current = etag(body);
    const weak = weakEtag(body);
    const candidates = header.split(",").map((c) => {
    return __bp_trim(c);
});
    const exact = (candidates.indexOf(current) !== (-1));
    const loose = (candidates.indexOf(weak) !== (-1));
    const hit = (() => { if (exact) { return true; } else { return loose; } })();
    return (() => { if (wildcard) { return true; } else { return hit; } })();
}
exports.matches = matches;

// ── fingerprints ─────────────────────────────────────────────────────────────

// `app.js` → `app.<hash>.js`. The extension stays last: a browser and a CDN

// both dispatch on it, and a hash appended after it breaks both. A leading

// dot (`.gitignore`) is not an extension boundary, and a name without an

// extension gains no trailing dot (`LICENSE` → `LICENSE.<hash>`).

// 

// The extension is measured as the last `.`-separated piece. It was written

// that way when Erlang's `lastIndexOf` answered a BYTE offset while

// `length`/`slice` counted characters; the four agree now (decision 169), and

// the piece measure stays because it is the same cut.

function fingerprint(fileName, contents) {
    let fileName$sp = null;
    const hash = (function(__S){ var __H = 5381; for (const __C of Array.from(__S)) { __H = (Math.imul(__H, 33) + __C.codePointAt(0)) >>> 0; } return __H.toString(16); })(contents);
    const pieces = fileName.split(".");
    const tail = __bp_array_at(pieces, __bp_int((pieces.length - 1), -2147483648, 2147483647, "- on i32 at src/hash.bp:390:40"));
    let tail$sp = null;
    const extLen = (() => { if ((tail != null)) { return __bp_int((((tail$sp ??= __bp_has_surrogate(tail)) ? __bp_str_length(tail) : tail.length) + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:391:50"); } else { return 0; } })();
    const hasExt = (() => { if ((pieces.length > 1)) { return (extLen < ((fileName$sp ??= __bp_has_surrogate(fileName)) ? __bp_str_length(fileName) : fileName.length)); } else { return false; } })();
    const cut = __bp_int((((fileName$sp ??= __bp_has_surrogate(fileName)) ? __bp_str_length(fileName) : fileName.length) - extLen), -2147483648, 2147483647, "- on i32 at src/hash.bp:393:33");
    const stem = (() => { if (hasExt) { return fileName.slice(0, cut); } else { return fileName; } })();
    const ext = (() => { if (hasExt) { return fileName.slice(cut, ((fileName$sp ??= __bp_has_surrogate(fileName)) ? __bp_str_length(fileName) : fileName.length)); } else { return ""; } })();
    return (((stem + ".") + hash) + ext);
}
exports.fingerprint = fingerprint;

// ── tests ────────────────────────────────────────────────────────────────────

// 

// Every expected hex below is a LITERAL, not a second call: a literal is the

// only form that catches the two targets drifting apart.

// ── the wasm bodies (decision 238) ──────────────────────────────────────────

// wasm has no host to hash with, so each cell above names one of these

// private bodies with `#[compiler.external(.Wasm(fn: …))]`. They run only on wasm —

// commonJS and erlang call their host — and they answer what Node's `crypto`

// answers: SHA-256 and SHA-512 (FIPS 180-4), SHA-1 (RFC 3174), MD5

// (RFC 1321), HMAC (RFC 2104), PBKDF2 (RFC 8018 §5.2), base64 (RFC 4648 §4,

// §5) and the djb2 fold over code points (decision 260). botopink has no bit operation and wasm no `i64` this backend

// lowers, so a 32-bit word is a whole `f64` in [0, 2^32), its bit

// operations exact arithmetic (`wrap32`, `rotr32`, `mix`, `bits32`); a

// 64-bit SHA-512 word is two of them. A word is stored in an

// `array<i32>` as two 16-bit halves, since a float in an array keeps only

// its `f32`; a constant is the hex its standard prints. A byte is an `i32` in 0..255; a string's bytes are its UTF-8.

function sha256Body(data) {
    return hexOf(sha256Bytes(utf8Of(data)));
}

function sha256Base64UrlBody(data) {
    return base64Of(sha256Bytes(utf8Of(data)), true, false);
}

function strongHashBody(value) {
    return hexOf(sha256Bytes(utf8Of(value)).slice(0, 16));
}

function sha512Body(data) {
    return hexOf(sha512Bytes(utf8Of(data)));
}

function md5Body(data) {
    return hexOf(md5Bytes(utf8Of(data)));
}

function sha1Base64Body(data) {
    return base64Of(sha1Bytes(utf8Of(data)), false, true);
}

function hmacSha256Body(key, data) {
    return hexOf(hmacSha256Bytes(hmacKeyBlock(utf8Of(key)), utf8Of(data)));
}

function hmacSha256Base64UrlBody(key, data) {
    return base64Of(hmacSha256Bytes(hmacKeyBlock(utf8Of(key)), utf8Of(data)), true, false);
}

// Every byte compared, no early exit; a length mismatch is `false`.

function equalsConstantTimeBody(a, b) {
    const x = utf8Of(a);
    const y = utf8Of(b);
    if ((x.length !== y.length)) { return false; }
    let diff = 0.0;
    let i = 0;
    while ((i < x.length)) {
    const d = __bp_int(((() => { const __bp_nullish = __bp_array_at(x, i); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() - ((() => { const __bp_nullish = __bp_array_at(y, i); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })())), -2147483648, 2147483647, "- on i32 at src/hash.bp:570:30");
    diff = (diff + (__bp_int((d * d), -2147483648, 2147483647, "* on i32 at src/hash.bp:571:25") * 1.0));
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:572:15");
}
    return Object.is(diff, 0.0);
}

// RFC 8018 §5.2 over HMAC-SHA256: block `i` is U1 ^ … ^ Uc, U1 the HMAC of

// the salt and `i` (four bytes, big-endian), each next U the HMAC of the

// last; the key is the blocks' first `length` bytes.

function pbkdf2DeriveBody(password, salt, iterations, length) {
    const key = hmacKeyBlock(utf8Of(password));
    const inner = padOf(key, 54);
    const outer = padOf(key, 92);
    const s = utf8Of(salt);
    let out = [];
    let block = 1;
    while ((out.length < length)) {
    const index = [__bp_int(Math.trunc((block / 16777216)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:594:19"), __bp_int(((__bp_int(Math.trunc((block / 65536)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:595:20")) % 256), -2147483648, 2147483647, "% on i32 at src/hash.bp:595:29"), __bp_int(((__bp_int(Math.trunc((block / 256)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:596:20")) % 256), -2147483648, 2147483647, "% on i32 at src/hash.bp:596:27"), __bp_int((block % 256), -2147483648, 2147483647, "% on i32 at src/hash.bp:597:19")];
    let u = hmacWithPads(inner, outer, s.concat(index));
    let t = u;
    let j = 1;
    while ((j < iterations)) {
    u = hmacWithPads(inner, outer, u);
    t = xorBytes(t, u);
    j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:605:19");
}
    out = out.concat(t);
    block = __bp_int((block + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:608:23");
}
    return base64Of(out.slice(0, length), true, false);
}

// ── bytes and text ──

function utf8Of(s) {
    const parts = s.chars().map((c) => {
    return utf8Bytes(c.charCodeAt(0));
});
    return parts.flatten();
}

function utf8Bytes(cp) {
    if ((cp < 128)) { return [cp]; }
    if ((cp < 2048)) { return [__bp_int((192 + __bp_int(Math.trunc((cp / 64)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:626:37")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:626:32"), __bp_int((128 + __bp_int((cp % 64), -2147483648, 2147483647, "% on i32 at src/hash.bp:626:52")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:626:47")]; }
    if ((cp < 65536)) { return [__bp_int((224 + __bp_int(Math.trunc((cp / 4096)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:628:26")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:628:21"), __bp_int((128 + __bp_int(((__bp_int(Math.trunc((cp / 64)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:628:44")) % 64), -2147483648, 2147483647, "% on i32 at src/hash.bp:628:50")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:628:38"), __bp_int((128 + __bp_int((cp % 64), -2147483648, 2147483647, "% on i32 at src/hash.bp:628:65")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:628:60")]; }
    return [__bp_int((240 + __bp_int(Math.trunc((cp / 262144)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:630:18")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:630:13"), __bp_int((128 + __bp_int(((__bp_int(Math.trunc((cp / 4096)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:631:19")) % 64), -2147483648, 2147483647, "% on i32 at src/hash.bp:631:27")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:631:13"), __bp_int((128 + __bp_int(((__bp_int(Math.trunc((cp / 64)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:632:19")) % 64), -2147483648, 2147483647, "% on i32 at src/hash.bp:632:25")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:632:13"), __bp_int((128 + __bp_int((cp % 64), -2147483648, 2147483647, "% on i32 at src/hash.bp:633:18")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:633:13")];
}

function hexDigit(n) {
    return (() => { const __bp_nullish = ("0123456789abcdef".at(n) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
}

function hexOf(bytes) {
    return bytes.map((b) => {
    return (hexDigit(__bp_int(Math.trunc((b / 16)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:642:40")) + hexDigit(__bp_int((b % 16), -2147483648, 2147483647, "% on i32 at src/hash.bp:642:59")));
}).join("");
}

// RFC 4648 base64: §5's alphabet when `url`, `=` padding when `pad`.

function base64Of(bytes, url, pad) {
    const alphabet = (() => { if (url) { return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"; } else { return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"; } })();
    let out = "";
    let g = 0;
    while ((__bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/hash.bp:653:14") < bytes.length)) {
    out = (out + base64Group(bytes, g, alphabet, pad));
    g = __bp_int((g + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:655:15");
}
    return out;
}

function base64Group(bytes, g, alphabet, pad) {
    let alphabet$sp = null;
    const n = __bp_int((bytes.length - __bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/hash.bp:666:30")), -2147483648, 2147483647, "- on i32 at src/hash.bp:666:26");
    const b0 = (() => { const __bp_nullish = __bp_array_at(bytes, __bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/hash.bp:667:25")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    const b1 = (() => { if ((n > 1)) { return (() => { const __bp_nullish = __bp_array_at(bytes, __bp_int((__bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/hash.bp:669:20") + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:669:24")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })(); } else { return 0; } })();
    const b2 = (() => { if ((n > 2)) { return (() => { const __bp_nullish = __bp_array_at(bytes, __bp_int((__bp_int((3 * g), -2147483648, 2147483647, "* on i32 at src/hash.bp:672:20") + 2), -2147483648, 2147483647, "+ on i32 at src/hash.bp:672:24")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })(); } else { return 0; } })();
    const fill = (() => { if (pad) { return "="; } else { return ""; } })();
    const c0 = (() => { const __bp_nullish = ((alphabet$sp ??= __bp_has_surrogate(alphabet)) ? __bp_string_char_at(alphabet, __bp_int(Math.trunc((b0 / 4)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:675:29")) : (alphabet.at(__bp_int(Math.trunc((b0 / 4)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:675:29")) ?? null)); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    const c1 = (() => { const __bp_nullish = ((alphabet$sp ??= __bp_has_surrogate(alphabet)) ? __bp_string_char_at(alphabet, __bp_int((__bp_int(((__bp_int((b0 % 4), -2147483648, 2147483647, "% on i32 at src/hash.bp:676:30")) * 16), -2147483648, 2147483647, "* on i32 at src/hash.bp:676:35") + __bp_int(Math.trunc((b1 / 16)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:676:45")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:676:40")) : (alphabet.at(__bp_int((__bp_int(((__bp_int((b0 % 4), -2147483648, 2147483647, "% on i32 at src/hash.bp:676:30")) * 16), -2147483648, 2147483647, "* on i32 at src/hash.bp:676:35") + __bp_int(Math.trunc((b1 / 16)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:676:45")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:676:40")) ?? null)); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    const c2 = (() => { if ((n > 1)) { return (() => { const __bp_nullish = ((alphabet$sp ??= __bp_has_surrogate(alphabet)) ? __bp_string_char_at(alphabet, __bp_int((__bp_int(((__bp_int((b1 % 16), -2147483648, 2147483647, "% on i32 at src/hash.bp:678:25")) * 4), -2147483648, 2147483647, "* on i32 at src/hash.bp:678:31") + __bp_int(Math.trunc((b2 / 64)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:678:40")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:678:35")) : (alphabet.at(__bp_int((__bp_int(((__bp_int((b1 % 16), -2147483648, 2147483647, "% on i32 at src/hash.bp:678:25")) * 4), -2147483648, 2147483647, "* on i32 at src/hash.bp:678:31") + __bp_int(Math.trunc((b2 / 64)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:678:40")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:678:35")) ?? null)); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })(); } else { return fill; } })();
    const c3 = (() => { if ((n > 2)) { return (() => { const __bp_nullish = ((alphabet$sp ??= __bp_has_surrogate(alphabet)) ? __bp_string_char_at(alphabet, __bp_int((b2 % 64), -2147483648, 2147483647, "% on i32 at src/hash.bp:681:24")) : (alphabet.at(__bp_int((b2 % 64), -2147483648, 2147483647, "% on i32 at src/hash.bp:681:24")) ?? null)); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })(); } else { return fill; } })();
    return (((c0 + c1) + c2) + c3);
}

// `n` zero bytes, by doubling (`array.repeat` and `array.range` recurse once

// per element).

function zeroBytes(n) {
    let zeros = [0];
    while ((zeros.length < n)) {
    zeros = zeros.concat(zeros);
}
    return zeros.slice(0, n);
}

function xorByte(a, b) {
    let r = 0;
    let x = a;
    let y = b;
    let bit = 1;
    while ((bit < 256)) {
    (() => { if ((__bp_int((x % 2), -2147483648, 2147483647, "% on i32 at src/hash.bp:702:15") !== __bp_int((y % 2), -2147483648, 2147483647, "% on i32 at src/hash.bp:702:24"))) { return r = __bp_int((r + bit), -2147483648, 2147483647, "+ on i32 at src/hash.bp:702:35"); } })();
    x = __bp_int(Math.trunc((x / 2)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:703:15");
    y = __bp_int(Math.trunc((y / 2)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:704:15");
    bit = __bp_int((bit * 2), -2147483648, 2147483647, "* on i32 at src/hash.bp:705:19");
}
    return r;
}

function xorBytes(a, b) {
    return a.zip(b).map((p) => {
    return xorByte(p[0], p[1]);
});
}

// ── words ──

function wrap32(x) {
    return (x - (((x / 4294967296.0)).floor() * 4294967296.0));
}

// `x` rotated right by n bits, `p` = 2^n.

function rotr32(x, p) {
    return mix(x, x, p);
}

// The low 32 bits of (y:x) >> n, `p` = 2^n: x's bits shifted down and y's

// low n bits above them.

function mix(x, y, p) {
    const down = ((x / p)).floor();
    const low = (y - (((y / p)).floor() * p));
    return (down + (low * ((4294967296.0 / p))));
}

// One of four bitwise functions of three words, bit by bit: `mode` 0 is

// x ^ y ^ z, 1 chooses y where x is set and z elsewhere, 2 is the

// majority, 3 is MD5's y ^ (x | ~z).

function bits32(x, y, z, mode) {
    let a = x;
    let b = y;
    let c = z;
    let r = 0.0;
    let weight = 1.0;
    let i = 0;
    while ((i < 32)) {
    const ha = ((a / 2.0)).floor();
    const hb = ((b / 2.0)).floor();
    const hc = ((c / 2.0)).floor();
    const ba = (a - (2.0 * ha));
    const bb = (b - (2.0 * hb));
    const bc = (c - (2.0 * hc));
    const sum = ((ba + bb) + bc);
    let on = false;
    (() => { if ((mode === 0)) { return on = (Object.is(sum, 1.0) || Object.is(sum, 3.0)); } })();
    (() => { if ((mode === 1)) { return on = (((Object.is(ba, 1.0) && Object.is(bb, 1.0))) || ((Object.is(ba, 0.0) && Object.is(bc, 1.0)))); } })();
    (() => { if ((mode === 2)) { return on = (sum >= 2.0); } })();
    (() => { if ((mode === 3)) { const either = (() => { if ((Object.is(ba, 1.0) || Object.is(bc, 0.0))) { return 1.0; } else { return 0.0; } })(); return on = Object.is((bb + either), 1.0); } })();
    (() => { if (on) { return r = (r + weight); } })();
    a = ha;
    b = hb;
    c = hc;
    weight = (weight * 2.0);
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:765:15");
}
    return r;
}

// A whole `v` in 0..65535 as an `i32`.

function smallInt(v) {
    let r = 0;
    let rest = v;
    let bit = 32768;
    let weight = 32768.0;
    while ((bit > 0)) {
    (() => { if ((rest >= weight)) { r = __bp_int((r + bit), -2147483648, 2147483647, "+ on i32 at src/hash.bp:778:19"); return rest = (rest - weight); } })();
    bit = __bp_int(Math.trunc((bit / 2)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:781:19");
    weight = (weight / 2.0);
}
    return r;
}

function upperHalf(w) {
    return smallInt(((w / 65536.0)).floor());
}

function lowerHalf(w) {
    return smallInt((w - (((w / 65536.0)).floor() * 65536.0)));
}

// Word `i` of a halves array.

function wordOf(h, i) {
    return (((() => { const __bp_nullish = __bp_array_at(h, __bp_int((2 * i), -2147483648, 2147483647, "* on i32 at src/hash.bp:797:19")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 65536.0) + ((() => { const __bp_nullish = __bp_array_at(h, __bp_int((__bp_int((2 * i), -2147483648, 2147483647, "* on i32 at src/hash.bp:797:48") + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:797:52")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 1.0));
}

function wordBE(m, i) {
    return (((((() => { const __bp_nullish = __bp_array_at(m, i); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 16777216.0) + ((() => { const __bp_nullish = __bp_array_at(m, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:802:18")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 65536.0)) + ((() => { const __bp_nullish = __bp_array_at(m, __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/hash.bp:803:18")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 256.0)) + ((() => { const __bp_nullish = __bp_array_at(m, __bp_int((i + 3), -2147483648, 2147483647, "+ on i32 at src/hash.bp:804:18")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 1.0));
}

function wordLE(m, i) {
    return (((((() => { const __bp_nullish = __bp_array_at(m, __bp_int((i + 3), -2147483648, 2147483647, "+ on i32 at src/hash.bp:808:19")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 16777216.0) + ((() => { const __bp_nullish = __bp_array_at(m, __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/hash.bp:809:18")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 65536.0)) + ((() => { const __bp_nullish = __bp_array_at(m, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:810:18")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 256.0)) + ((() => { const __bp_nullish = __bp_array_at(m, i); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })() * 1.0));
}

// The `count` hex digits of `w` from `start` as a whole number.

function hexValue(w, start, count) {
    let v = 0.0;
    let i = 0;
    while ((i < count)) {
    const c = w.charCodeAt(__bp_int((start + i), -2147483648, 2147483647, "+ on i32 at src/hash.bp:819:36"));
    const digit = (() => { if ((c < 58)) { return __bp_int((c - 48), -2147483648, 2147483647, "- on i32 at src/hash.bp:820:35"); } else { return __bp_int((c - 87), -2147483648, 2147483647, "- on i32 at src/hash.bp:820:47"); } })();
    v = ((v * 16.0) + (digit * 1.0));
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:822:15");
}
    return v;
}

// Space-separated hex words of `digits` (8 or 16) digits as 16-bit halves.

function halvesOf(text, digits) {
    let text$sp = null;
    let out = [];
    let at = 0;
    while ((at < ((text$sp ??= __bp_has_surrogate(text)) ? __bp_str_length(text) : text.length))) {
    const v = hexValue(text, at, 8);
    out = out.concat([upperHalf(v), lowerHalf(v)]);
    at = (() => { if ((__bp_int(((__bp_int((at + 8), -2147483648, 2147483647, "+ on i32 at src/hash.bp:834:22")) % (__bp_int((digits + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:834:37"))), -2147483648, 2147483647, "% on i32 at src/hash.bp:834:27") === digits)) { return __bp_int((at + 9), -2147483648, 2147483647, "+ on i32 at src/hash.bp:834:56"); } else { return __bp_int((at + 8), -2147483648, 2147483647, "+ on i32 at src/hash.bp:834:68"); } })();
}
    return out;
}

// Halves to bytes, each word big-endian.

function bytesBE(h) {
    const parts = h.map((x) => {
    return [__bp_int(Math.trunc((x / 256)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:841:52"), __bp_int((x % 256), -2147483648, 2147483647, "% on i32 at src/hash.bp:841:61")];
});
    return parts.flatten();
}

// Halves to bytes, each word little-endian (MD5).

function bytesLE(h) {
    let out = [];
    let i = 0;
    while ((i < h.length)) {
    const upper = (() => { const __bp_nullish = __bp_array_at(h, i); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    const lower = (() => { const __bp_nullish = __bp_array_at(h, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:851:28")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    out = out.concat([__bp_int((lower % 256), -2147483648, 2147483647, "% on i32 at src/hash.bp:852:33"), __bp_int(Math.trunc((lower / 256)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:852:46"), __bp_int((upper % 256), -2147483648, 2147483647, "% on i32 at src/hash.bp:852:59"), __bp_int(Math.trunc((upper / 256)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:852:72")]);
    i = __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/hash.bp:853:15");
}
    return out;
}

// The message, `0x80`, zeros, and its length in bits in the last

// `lengthBytes` bytes of a `block`-byte block.

function padded(msg, block, lengthBytes, bigEndian) {
    const bits = __bp_int((msg.length * 8), -2147483648, 2147483647, "* on i32 at src/hash.bp:866:27");
    const zeros = __bp_int(((__bp_int((block - __bp_int(((__bp_int((__bp_int((msg.length + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:867:38") + lengthBytes), -2147483648, 2147483647, "+ on i32 at src/hash.bp:867:42")) % block), -2147483648, 2147483647, "% on i32 at src/hash.bp:867:57")), -2147483648, 2147483647, "- on i32 at src/hash.bp:867:24")) % block), -2147483648, 2147483647, "% on i32 at src/hash.bp:867:66");
    const be = [__bp_int(Math.trunc((bits / 16777216)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:869:14"), __bp_int(((__bp_int(Math.trunc((bits / 65536)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:870:15")) % 256), -2147483648, 2147483647, "% on i32 at src/hash.bp:870:24"), __bp_int(((__bp_int(Math.trunc((bits / 256)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:871:15")) % 256), -2147483648, 2147483647, "% on i32 at src/hash.bp:871:22"), __bp_int((bits % 256), -2147483648, 2147483647, "% on i32 at src/hash.bp:872:14")];
    const size = (() => { if (bigEndian) { return zeroBytes(__bp_int((lengthBytes - 4), -2147483648, 2147483647, "- on i32 at src/hash.bp:875:31")).concat(be); } else { return be.toReversed().concat(zeroBytes(__bp_int((lengthBytes - 4), -2147483648, 2147483647, "- on i32 at src/hash.bp:877:51"))); } })();
    return msg.concat([128].concat(zeroBytes(zeros)).concat(size));
}

// ── HMAC ──

// The key as HMAC's 64-byte block: hashed when longer, zero-padded.

function hmacKeyBlock(key) {
    const short = (() => { if ((key.length > 64)) { return sha256Bytes(key); } else { return key; } })();
    return short.concat(zeroBytes(__bp_int((64 - short.length), -2147483648, 2147483647, "- on i32 at src/hash.bp:886:38")));
}

function hmacSha256Bytes(block, msg) {
    return hmacWithPads(padOf(block, 54), padOf(block, 92), msg);
}

// The key block with every byte xored with `pad` (0x36 inner, 0x5c outer).

function padOf(block, pad) {
    return block.map((b) => {
    return xorByte(b, pad);
});
}

function hmacWithPads(inner, outer, msg) {
    return sha256Bytes(outer.concat(sha256Bytes(inner.concat(msg))));
}

// ── SHA-256 ──

function sha256Bytes(msg) {
    const m = padded(msg, 64, 8, true);
    const k = sha256Constants();
    let h = halvesOf(sha256Initial(), 8);
    let at = 0;
    while ((at < m.length)) {
    h = sha256Block(h, m, at, k);
    at = __bp_int((at + 64), -2147483648, 2147483647, "+ on i32 at src/hash.bp:915:17");
}
    return bytesBE(h);
}

function sha256Block(h, m, at, k) {
    let a = wordOf(h, 0);
    let b = wordOf(h, 1);
    let c = wordOf(h, 2);
    let d = wordOf(h, 3);
    let e = wordOf(h, 4);
    let f = wordOf(h, 5);
    let g = wordOf(h, 6);
    let hh = wordOf(h, 7);
    let w0 = wordBE(m, at);
    let w1 = wordBE(m, __bp_int((at + 4), -2147483648, 2147483647, "+ on i32 at src/hash.bp:930:27"));
    let w2 = wordBE(m, __bp_int((at + 8), -2147483648, 2147483647, "+ on i32 at src/hash.bp:931:27"));
    let w3 = wordBE(m, __bp_int((at + 12), -2147483648, 2147483647, "+ on i32 at src/hash.bp:932:27"));
    let w4 = wordBE(m, __bp_int((at + 16), -2147483648, 2147483647, "+ on i32 at src/hash.bp:933:27"));
    let w5 = wordBE(m, __bp_int((at + 20), -2147483648, 2147483647, "+ on i32 at src/hash.bp:934:27"));
    let w6 = wordBE(m, __bp_int((at + 24), -2147483648, 2147483647, "+ on i32 at src/hash.bp:935:27"));
    let w7 = wordBE(m, __bp_int((at + 28), -2147483648, 2147483647, "+ on i32 at src/hash.bp:936:27"));
    let w8 = wordBE(m, __bp_int((at + 32), -2147483648, 2147483647, "+ on i32 at src/hash.bp:937:27"));
    let w9 = wordBE(m, __bp_int((at + 36), -2147483648, 2147483647, "+ on i32 at src/hash.bp:938:27"));
    let w10 = wordBE(m, __bp_int((at + 40), -2147483648, 2147483647, "+ on i32 at src/hash.bp:939:28"));
    let w11 = wordBE(m, __bp_int((at + 44), -2147483648, 2147483647, "+ on i32 at src/hash.bp:940:28"));
    let w12 = wordBE(m, __bp_int((at + 48), -2147483648, 2147483647, "+ on i32 at src/hash.bp:941:28"));
    let w13 = wordBE(m, __bp_int((at + 52), -2147483648, 2147483647, "+ on i32 at src/hash.bp:942:28"));
    let w14 = wordBE(m, __bp_int((at + 56), -2147483648, 2147483647, "+ on i32 at src/hash.bp:943:28"));
    let w15 = wordBE(m, __bp_int((at + 60), -2147483648, 2147483647, "+ on i32 at src/hash.bp:944:28"));
    let t = 0;
    while ((t < 64)) {
    const s1 = bits32(rotr32(e, 64.0), rotr32(e, 2048.0), rotr32(e, 33554432.0), 0);
    const t1 = ((((hh + s1) + bits32(e, f, g, 1)) + hexValue(k, __bp_int((9 * t), -2147483648, 2147483647, "* on i32 at src/hash.bp:953:63"), 8)) + w0);
    const s0 = bits32(rotr32(a, 4.0), rotr32(a, 8192.0), rotr32(a, 4194304.0), 0);
    const t2 = (s0 + bits32(a, b, c, 2));
    hh = g;
    g = f;
    f = e;
    e = wrap32((d + t1));
    d = c;
    c = b;
    b = a;
    a = wrap32((t1 + t2));
    const g0 = bits32(rotr32(w1, 128.0), rotr32(w1, 262144.0), ((w1 / 8.0)).floor(), 0);
    const g1 = bits32(rotr32(w14, 131072.0), rotr32(w14, 524288.0), ((w14 / 1024.0)).floor(), 0);
    const next = wrap32((((g1 + w9) + g0) + w0));
    w0 = w1;
    w1 = w2;
    w2 = w3;
    w3 = w4;
    w4 = w5;
    w5 = w6;
    w6 = w7;
    w7 = w8;
    w8 = w9;
    w9 = w10;
    w10 = w11;
    w11 = w12;
    w12 = w13;
    w13 = w14;
    w14 = w15;
    w15 = next;
    t = __bp_int((t + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:998:15");
}
    const n0 = wrap32((wordOf(h, 0) + a));
    const n1 = wrap32((wordOf(h, 1) + b));
    const n2 = wrap32((wordOf(h, 2) + c));
    const n3 = wrap32((wordOf(h, 3) + d));
    const n4 = wrap32((wordOf(h, 4) + e));
    const n5 = wrap32((wordOf(h, 5) + f));
    const n6 = wrap32((wordOf(h, 6) + g));
    const n7 = wrap32((wordOf(h, 7) + hh));
    return [upperHalf(n0), lowerHalf(n0), upperHalf(n1), lowerHalf(n1), upperHalf(n2), lowerHalf(n2), upperHalf(n3), lowerHalf(n3), upperHalf(n4), lowerHalf(n4), upperHalf(n5), lowerHalf(n5), upperHalf(n6), lowerHalf(n6), upperHalf(n7), lowerHalf(n7)];
}

// ── SHA-1 ──

function sha1Bytes(msg) {
    const m = padded(msg, 64, 8, true);
    let h = halvesOf("67452301 efcdab89 98badcfe 10325476 c3d2e1f0", 8);
    let at = 0;
    while ((at < m.length)) {
    h = sha1Block(h, m, at);
    at = __bp_int((at + 64), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1036:17");
}
    return bytesBE(h);
}

function sha1Block(h, m, at) {
    let a = wordOf(h, 0);
    let b = wordOf(h, 1);
    let c = wordOf(h, 2);
    let d = wordOf(h, 3);
    let e = wordOf(h, 4);
    let w0 = wordBE(m, at);
    let w1 = wordBE(m, __bp_int((at + 4), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1048:27"));
    let w2 = wordBE(m, __bp_int((at + 8), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1049:27"));
    let w3 = wordBE(m, __bp_int((at + 12), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1050:27"));
    let w4 = wordBE(m, __bp_int((at + 16), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1051:27"));
    let w5 = wordBE(m, __bp_int((at + 20), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1052:27"));
    let w6 = wordBE(m, __bp_int((at + 24), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1053:27"));
    let w7 = wordBE(m, __bp_int((at + 28), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1054:27"));
    let w8 = wordBE(m, __bp_int((at + 32), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1055:27"));
    let w9 = wordBE(m, __bp_int((at + 36), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1056:27"));
    let w10 = wordBE(m, __bp_int((at + 40), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1057:28"));
    let w11 = wordBE(m, __bp_int((at + 44), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1058:28"));
    let w12 = wordBE(m, __bp_int((at + 48), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1059:28"));
    let w13 = wordBE(m, __bp_int((at + 52), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1060:28"));
    let w14 = wordBE(m, __bp_int((at + 56), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1061:28"));
    let w15 = wordBE(m, __bp_int((at + 60), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1062:28"));
    let t = 0;
    while ((t < 80)) {
    const f = (() => { if ((t < 20)) { return (bits32(b, c, d, 1) + 1518500249.0); } else { return (() => { if ((t < 40)) { return (bits32(b, c, d, 0) + 1859775393.0); } else { return (() => { if ((t < 60)) { return (bits32(b, c, d, 2) + 2400959708.0); } else { return (bits32(b, c, d, 0) + 3395469782.0); } })(); } })(); } })();
    const temp = wrap32((((rotr32(a, 134217728.0) + f) + e) + w0));
    e = d;
    d = c;
    c = rotr32(b, 4.0);
    b = a;
    a = temp;
    const mixed = bits32(bits32(w13, w8, w2, 0), w0, 0.0, 0);
    const next = rotr32(mixed, 2147483648.0);
    w0 = w1;
    w1 = w2;
    w2 = w3;
    w3 = w4;
    w4 = w5;
    w5 = w6;
    w6 = w7;
    w7 = w8;
    w8 = w9;
    w9 = w10;
    w10 = w11;
    w11 = w12;
    w12 = w13;
    w13 = w14;
    w14 = w15;
    w15 = next;
    t = __bp_int((t + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1097:15");
}
    const n0 = wrap32((wordOf(h, 0) + a));
    const n1 = wrap32((wordOf(h, 1) + b));
    const n2 = wrap32((wordOf(h, 2) + c));
    const n3 = wrap32((wordOf(h, 3) + d));
    const n4 = wrap32((wordOf(h, 4) + e));
    return [upperHalf(n0), lowerHalf(n0), upperHalf(n1), lowerHalf(n1), upperHalf(n2), lowerHalf(n2), upperHalf(n3), lowerHalf(n3), upperHalf(n4), lowerHalf(n4)];
}

// ── MD5 ──

function md5Bytes(msg) {
    const m = padded(msg, 64, 8, false);
    const k = md5Constants();
    // 2^(32 − s) for each round's four left-rotation amounts s.;
    const shifts = [33554432, 1048576, 32768, 1024, 134217728, 8388608, 262144, 4096, 268435456, 2097152, 65536, 512, 67108864, 4194304, 131072, 2048];
    let h = halvesOf("67452301 efcdab89 98badcfe 10325476", 8);
    let at = 0;
    while ((at < m.length)) {
    h = md5Block(h, m, at, k, shifts);
    at = __bp_int((at + 64), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1146:17");
}
    return bytesLE(h);
}

function md5Block(h, m, at, k, shifts) {
    let a = wordOf(h, 0);
    let b = wordOf(h, 1);
    let c = wordOf(h, 2);
    let d = wordOf(h, 3);
    let i = 0;
    while ((i < 64)) {
    const round = __bp_int(Math.trunc((i / 16)), -2147483648, 2147483647, "/ on i32 at src/hash.bp:1164:23");
    const f = (() => { if ((round === 0)) { return bits32(b, c, d, 1); } else { return (() => { if ((round === 1)) { return bits32(d, b, c, 1); } else { return (() => { if ((round === 2)) { return bits32(b, c, d, 0); } else { return bits32(b, c, d, 3); } })(); } })(); } })();
    const g = (() => { if ((round === 0)) { return i; } else { return (() => { if ((round === 1)) { return __bp_int(((__bp_int((__bp_int((5 * i), -2147483648, 2147483647, "* on i32 at src/hash.bp:1176:16") + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1176:20")) % 16), -2147483648, 2147483647, "% on i32 at src/hash.bp:1176:25"); } else { return (() => { if ((round === 2)) { return __bp_int(((__bp_int((__bp_int((3 * i), -2147483648, 2147483647, "* on i32 at src/hash.bp:1178:16") + 5), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1178:20")) % 16), -2147483648, 2147483647, "% on i32 at src/hash.bp:1178:25"); } else { return __bp_int(((__bp_int((7 * i), -2147483648, 2147483647, "* on i32 at src/hash.bp:1180:16")) % 16), -2147483648, 2147483647, "% on i32 at src/hash.bp:1180:21"); } })(); } })(); } })();
    const sum = wrap32((((f + a) + hexValue(k, __bp_int((9 * i), -2147483648, 2147483647, "* on i32 at src/hash.bp:1181:48"), 8)) + wordLE(m, __bp_int((at + __bp_int((4 * g), -2147483648, 2147483647, "* on i32 at src/hash.bp:1181:75")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1181:71"))));
    const p = ((() => { const __bp_nullish = __bp_array_at(shifts, __bp_int((__bp_int((round * 4), -2147483648, 2147483647, "* on i32 at src/hash.bp:1182:33") + __bp_int((i % 4), -2147483648, 2147483647, "% on i32 at src/hash.bp:1182:41")), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1182:37")); if (__bp_nullish != null) { return __bp_nullish; } else { return 1; } })() * 1.0);
    a = d;
    d = c;
    c = b;
    b = wrap32((b + rotr32(sum, p)));
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1187:15");
}
    const n0 = wrap32((wordOf(h, 0) + a));
    const n1 = wrap32((wordOf(h, 1) + b));
    const n2 = wrap32((wordOf(h, 2) + c));
    const n3 = wrap32((wordOf(h, 3) + d));
    return [upperHalf(n0), lowerHalf(n0), upperHalf(n1), lowerHalf(n1), upperHalf(n2), lowerHalf(n2), upperHalf(n3), lowerHalf(n3)];
}

// ── SHA-512 ──

function sha512Bytes(msg) {
    const m = padded(msg, 128, 16, true);
    const k = sha512Constants();
    let h = halvesOf(sha512Initial(), 16);
    let at = 0;
    while ((at < m.length)) {
    h = sha512Block(h, m, at, k);
    at = __bp_int((at + 128), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1214:17");
}
    return bytesBE(h);
}

function sha512Block(h, m, at, k) {
    let ah = wordOf(h, 0);
    let al = wordOf(h, 1);
    let bh = wordOf(h, 2);
    let bl = wordOf(h, 3);
    let ch = wordOf(h, 4);
    let cl = wordOf(h, 5);
    let dh = wordOf(h, 6);
    let dl = wordOf(h, 7);
    let eh = wordOf(h, 8);
    let el = wordOf(h, 9);
    let fh = wordOf(h, 10);
    let fl = wordOf(h, 11);
    let gh = wordOf(h, 12);
    let gl = wordOf(h, 13);
    let hh = wordOf(h, 14);
    let hl = wordOf(h, 15);
    let w0h = wordBE(m, __bp_int((at + 0), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1236:28"));
    let w0l = wordBE(m, __bp_int((at + 4), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1237:28"));
    let w1h = wordBE(m, __bp_int((at + 8), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1238:28"));
    let w1l = wordBE(m, __bp_int((at + 12), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1239:28"));
    let w2h = wordBE(m, __bp_int((at + 16), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1240:28"));
    let w2l = wordBE(m, __bp_int((at + 20), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1241:28"));
    let w3h = wordBE(m, __bp_int((at + 24), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1242:28"));
    let w3l = wordBE(m, __bp_int((at + 28), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1243:28"));
    let w4h = wordBE(m, __bp_int((at + 32), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1244:28"));
    let w4l = wordBE(m, __bp_int((at + 36), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1245:28"));
    let w5h = wordBE(m, __bp_int((at + 40), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1246:28"));
    let w5l = wordBE(m, __bp_int((at + 44), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1247:28"));
    let w6h = wordBE(m, __bp_int((at + 48), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1248:28"));
    let w6l = wordBE(m, __bp_int((at + 52), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1249:28"));
    let w7h = wordBE(m, __bp_int((at + 56), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1250:28"));
    let w7l = wordBE(m, __bp_int((at + 60), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1251:28"));
    let w8h = wordBE(m, __bp_int((at + 64), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1252:28"));
    let w8l = wordBE(m, __bp_int((at + 68), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1253:28"));
    let w9h = wordBE(m, __bp_int((at + 72), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1254:28"));
    let w9l = wordBE(m, __bp_int((at + 76), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1255:28"));
    let w10h = wordBE(m, __bp_int((at + 80), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1256:29"));
    let w10l = wordBE(m, __bp_int((at + 84), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1257:29"));
    let w11h = wordBE(m, __bp_int((at + 88), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1258:29"));
    let w11l = wordBE(m, __bp_int((at + 92), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1259:29"));
    let w12h = wordBE(m, __bp_int((at + 96), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1260:29"));
    let w12l = wordBE(m, __bp_int((at + 100), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1261:29"));
    let w13h = wordBE(m, __bp_int((at + 104), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1262:29"));
    let w13l = wordBE(m, __bp_int((at + 108), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1263:29"));
    let w14h = wordBE(m, __bp_int((at + 112), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1264:29"));
    let w14l = wordBE(m, __bp_int((at + 116), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1265:29"));
    let w15h = wordBE(m, __bp_int((at + 120), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1266:29"));
    let w15l = wordBE(m, __bp_int((at + 124), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1267:29"));
    let t = 0;
    while ((t < 80)) {
    const s1h = bits32(mix(eh, el, 16384.0), mix(eh, el, 262144.0), mix(el, eh, 512.0), 0);
    const s1l = bits32(mix(el, eh, 16384.0), mix(el, eh, 262144.0), mix(eh, el, 512.0), 0);
    const t1l = ((((hl + s1l) + bits32(el, fl, gl, 1)) + hexValue(k, __bp_int((__bp_int((17 * t), -2147483648, 2147483647, "* on i32 at src/hash.bp:1285:30") + 8), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1285:34"), 8)) + w0l);
    const t1h = wrap32((((((hh + s1h) + bits32(eh, fh, gh, 1)) + hexValue(k, __bp_int((17 * t), -2147483648, 2147483647, "* on i32 at src/hash.bp:1291:34"), 8)) + w0h) + ((t1l / 4294967296.0)).floor()));
    const t1lw = wrap32(t1l);
    const s0h = bits32(mix(ah, al, 268435456.0), mix(al, ah, 4.0), mix(al, ah, 128.0), 0);
    const s0l = bits32(mix(al, ah, 268435456.0), mix(ah, al, 4.0), mix(ah, al, 128.0), 0);
    const t2l = (s0l + bits32(al, bl, cl, 2));
    const t2h = (s0h + bits32(ah, bh, ch, 2));
    hh = gh;
    hl = gl;
    gh = fh;
    gl = fl;
    fh = eh;
    fl = el;
    const el2 = (dl + t1lw);
    eh = wrap32(((dh + t1h) + ((el2 / 4294967296.0)).floor()));
    el = wrap32(el2);
    dh = ch;
    dl = cl;
    ch = bh;
    cl = bl;
    bh = ah;
    bl = al;
    const al2 = (t1lw + t2l);
    ah = wrap32(((t1h + t2h) + ((al2 / 4294967296.0)).floor()));
    al = wrap32(al2);
    const g0h = bits32(mix(w1h, w1l, 2.0), mix(w1h, w1l, 256.0), ((w1h / 128.0)).floor(), 0);
    const g0l = bits32(mix(w1l, w1h, 2.0), mix(w1l, w1h, 256.0), mix(w1l, w1h, 128.0), 0);
    const g1h = bits32(mix(w14h, w14l, 524288.0), mix(w14l, w14h, 536870912.0), ((w14h / 64.0)).floor(), 0);
    const g1l = bits32(mix(w14l, w14h, 524288.0), mix(w14h, w14l, 536870912.0), mix(w14l, w14h, 64.0), 0);
    const nl = (((g1l + w9l) + g0l) + w0l);
    const nh = wrap32(((((g1h + w9h) + g0h) + w0h) + ((nl / 4294967296.0)).floor()));
    w0h = w1h;
    w0l = w1l;
    w1h = w2h;
    w1l = w2l;
    w2h = w3h;
    w2l = w3l;
    w3h = w4h;
    w3l = w4l;
    w4h = w5h;
    w4l = w5l;
    w5h = w6h;
    w5l = w6l;
    w6h = w7h;
    w6l = w7l;
    w7h = w8h;
    w7l = w8l;
    w8h = w9h;
    w8l = w9l;
    w9h = w10h;
    w9l = w10l;
    w10h = w11h;
    w10l = w11l;
    w11h = w12h;
    w11l = w12l;
    w12h = w13h;
    w12l = w13l;
    w13h = w14h;
    w13l = w14l;
    w14h = w15h;
    w14l = w15l;
    w15h = nh;
    w15l = wrap32(nl);
    t = __bp_int((t + 1), -2147483648, 2147483647, "+ on i32 at src/hash.bp:1386:15");
}
    const n0l = (wordOf(h, 1) + al);
    const n0h = wrap32(((wordOf(h, 0) + ah) + ((n0l / 4294967296.0)).floor()));
    const n0lw = wrap32(n0l);
    const n1l = (wordOf(h, 3) + bl);
    const n1h = wrap32(((wordOf(h, 2) + bh) + ((n1l / 4294967296.0)).floor()));
    const n1lw = wrap32(n1l);
    const n2l = (wordOf(h, 5) + cl);
    const n2h = wrap32(((wordOf(h, 4) + ch) + ((n2l / 4294967296.0)).floor()));
    const n2lw = wrap32(n2l);
    const n3l = (wordOf(h, 7) + dl);
    const n3h = wrap32(((wordOf(h, 6) + dh) + ((n3l / 4294967296.0)).floor()));
    const n3lw = wrap32(n3l);
    const n4l = (wordOf(h, 9) + el);
    const n4h = wrap32(((wordOf(h, 8) + eh) + ((n4l / 4294967296.0)).floor()));
    const n4lw = wrap32(n4l);
    const n5l = (wordOf(h, 11) + fl);
    const n5h = wrap32(((wordOf(h, 10) + fh) + ((n5l / 4294967296.0)).floor()));
    const n5lw = wrap32(n5l);
    const n6l = (wordOf(h, 13) + gl);
    const n6h = wrap32(((wordOf(h, 12) + gh) + ((n6l / 4294967296.0)).floor()));
    const n6lw = wrap32(n6l);
    const n7l = (wordOf(h, 15) + hl);
    const n7h = wrap32(((wordOf(h, 14) + hh) + ((n7l / 4294967296.0)).floor()));
    const n7lw = wrap32(n7l);
    return [upperHalf(n0h), lowerHalf(n0h), upperHalf(n0lw), lowerHalf(n0lw), upperHalf(n1h), lowerHalf(n1h), upperHalf(n1lw), lowerHalf(n1lw), upperHalf(n2h), lowerHalf(n2h), upperHalf(n2lw), lowerHalf(n2lw), upperHalf(n3h), lowerHalf(n3h), upperHalf(n3lw), lowerHalf(n3lw), upperHalf(n4h), lowerHalf(n4h), upperHalf(n4lw), lowerHalf(n4lw), upperHalf(n5h), lowerHalf(n5h), upperHalf(n5lw), lowerHalf(n5lw), upperHalf(n6h), lowerHalf(n6h), upperHalf(n6lw), lowerHalf(n6lw), upperHalf(n7h), lowerHalf(n7h), upperHalf(n7lw), lowerHalf(n7lw)];
}

// ── constants, as the hex the standards print ──

// One literal each, read in place (`hexValue` at `9 · i`, or `17 · i` for a

// 64-bit word), so a digest allocates none of its tables.

// FIPS 180-4 §5.3.3: the square roots of the first 8 primes.

function sha256Initial() {
    return "6a09e667 bb67ae85 3c6ef372 a54ff53a 510e527f 9b05688c 1f83d9ab 5be0cd19";
}

// FIPS 180-4 §4.2.2: the cube roots of the first 64 primes.

function sha256Constants() {
    return "428a2f98 71374491 b5c0fbcf e9b5dba5 3956c25b 59f111f1 923f82a4 ab1c5ed5 d807aa98 12835b01 243185be 550c7dc3 72be5d74 80deb1fe 9bdc06a7 c19bf174 e49b69c1 efbe4786 0fc19dc6 240ca1cc 2de92c6f 4a7484aa 5cb0a9dc 76f988da 983e5152 a831c66d b00327c8 bf597fc7 c6e00bf3 d5a79147 06ca6351 14292967 27b70a85 2e1b2138 4d2c6dfc 53380d13 650a7354 766a0abb 81c2c92e 92722c85 a2bfe8a1 a81a664b c24b8b70 c76c51a3 d192e819 d6990624 f40e3585 106aa070 19a4c116 1e376c08 2748774c 34b0bcb5 391c0cb3 4ed8aa4a 5b9cca4f 682e6ff3 748f82ee 78a5636f 84c87814 8cc70208 90befffa a4506ceb bef9a3f7 c67178f2";
}

// FIPS 180-4 §5.3.5: the square roots of the first 8 primes, 64 bits.

function sha512Initial() {
    return "6a09e667f3bcc908 bb67ae8584caa73b 3c6ef372fe94f82b a54ff53a5f1d36f1 510e527fade682d1 9b05688c2b3e6c1f 1f83d9abfb41bd6b 5be0cd19137e2179";
}

// FIPS 180-4 §4.2.3: the cube roots of the first 80 primes, 64 bits.

function sha512Constants() {
    return "428a2f98d728ae22 7137449123ef65cd b5c0fbcfec4d3b2f e9b5dba58189dbbc 3956c25bf348b538 59f111f1b605d019 923f82a4af194f9b ab1c5ed5da6d8118 d807aa98a3030242 12835b0145706fbe 243185be4ee4b28c 550c7dc3d5ffb4e2 72be5d74f27b896f 80deb1fe3b1696b1 9bdc06a725c71235 c19bf174cf692694 e49b69c19ef14ad2 efbe4786384f25e3 0fc19dc68b8cd5b5 240ca1cc77ac9c65 2de92c6f592b0275 4a7484aa6ea6e483 5cb0a9dcbd41fbd4 76f988da831153b5 983e5152ee66dfab a831c66d2db43210 b00327c898fb213f bf597fc7beef0ee4 c6e00bf33da88fc2 d5a79147930aa725 06ca6351e003826f 142929670a0e6e70 27b70a8546d22ffc 2e1b21385c26c926 4d2c6dfc5ac42aed 53380d139d95b3df 650a73548baf63de 766a0abb3c77b2a8 81c2c92e47edaee6 92722c851482353b a2bfe8a14cf10364 a81a664bbc423001 c24b8b70d0f89791 c76c51a30654be30 d192e819d6ef5218 d69906245565a910 f40e35855771202a 106aa07032bbd1b8 19a4c116b8d2d0c8 1e376c085141ab53 2748774cdf8eeb99 34b0bcb5e19b48a8 391c0cb3c5c95a63 4ed8aa4ae3418acb 5b9cca4f7763e373 682e6ff3d6b2b8a3 748f82ee5defb2fc 78a5636f43172f60 84c87814a1f0ab72 8cc702081a6439ec 90befffa23631e28 a4506cebde82bde9 bef9a3f7b2c67915 c67178f2e372532b ca273eceea26619c d186b8c721c0c207 eada7dd6cde0eb1e f57d4f7fee6ed178 06f067aa72176fba 0a637dc5a2c898a6 113f9804bef90dae 1b710b35131c471b 28db77f523047d84 32caab7b40c72493 3c9ebe0a15c9bebc 431d67c49c100d4c 4cc5d4becb3e42b6 597f299cfc657e2a 5fcb6fab3ad6faec 6c44198c4a475817";
}

// RFC 1321 §3.4: floor(2^32 · |sin(i + 1)|).

function md5Constants() {
    return "d76aa478 e8c7b756 242070db c1bdceee f57c0faf 4787c62a a8304613 fd469501 698098d8 8b44f7af ffff5bb1 895cd7be 6b901122 fd987193 a679438e 49b40821 f61e2562 c040b340 265e5a51 e9b6c7aa d62f105d 02441453 d8a1e681 e7d3fbc8 21e1cde6 c33707d6 f4d50d87 455a14ed a9e3e905 fcefa3f8 676f02d9 8d2a4c8a fffa3942 8771f681 6d9d6122 fde5380c a4beea44 4bdecfa9 f6bb4b60 bebfbc70 289b7ec6 eaa127fa d4ef3085 04881d05 d9d4d039 e6db99e5 1fa27cf8 c4ac5665 f4292244 432aff97 ab9423a7 fc93a039 655b59c3 8f0ccc92 ffeff47d 85845dd1 6fa87e4f fe2ce6e0 a3014314 4e0811a1 f7537e82 bd3af235 2ad7d2bb eb86d391";
}

Object.defineProperty(exports, "__bp_priv__", { value: { failure, hmacSha256Base64Url, sha1Base64, sha256Base64Url, equalsConstantTime, pbkdf2Sha256, panicText, sha256, sha512, md5, hmacSha256, contentHash, strongHash, cacheKey, strongCacheKey, frame, etag, weakEtag, matches, fingerprint, sha256Body, sha256Base64UrlBody, strongHashBody, sha512Body, md5Body, sha1Base64Body, hmacSha256Body, hmacSha256Base64UrlBody, equalsConstantTimeBody, pbkdf2DeriveBody, utf8Of, utf8Bytes, hexDigit, hexOf, base64Of, base64Group, zeroBytes, xorByte, xorBytes, wrap32, rotr32, mix, bits32, smallInt, upperHalf, lowerHalf, wordOf, wordBE, wordLE, hexValue, halvesOf, bytesBE, bytesLE, padded, hmacKeyBlock, hmacSha256Bytes, padOf, hmacWithPads, sha256Bytes, sha256Block, sha1Bytes, sha1Block, md5Bytes, md5Block, sha512Bytes, sha512Block, sha256Initial, sha256Constants, sha512Initial, sha512Constants, md5Constants } });
