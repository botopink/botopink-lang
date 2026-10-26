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

function __bp_host_fail(F, e) {
    const n = e instanceof Error;
    return { error: new F.HostError(n ? e.message : String(e), "host", n ? F.HostErrorName.Error : F.HostErrorName.Throw, (n && typeof e.stack === "string") ? e.stack : null) };
}

function __bp_host_result(F, f) {
    try {
        return { ok: f() };
    } catch (e) {
        return __bp_host_fail(F, e);
    }
}

function __bp_adopt(v, C, p) { return (v == null) ? v : (p === "") ? ((typeof v === "object" && !(v instanceof C)) ? Object.assign(Object.create(C.prototype), v) : v) : (p[0] === "a") ? (Array.isArray(v) ? v.map((e) => __bp_adopt(e, C, p.slice(1))) : v) : (p[0] === "r" && typeof v === "object" && "ok" in v) ? { ok: __bp_adopt(v.ok, C, p.slice(1)) } : v; }

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function __bp_wnorm(v, u, what) {
    if (u ? (v < 0n || v > 18446744073709551615n) : (v < -9223372036854775808n || v > 9223372036854775807n)) { throw Object.defineProperty(new Error("integer overflow: " + what), "__bp_panic", { value: true }); }
    return (v >= -9007199254740991n && v <= 9007199254740991n) ? Number(v) : v;
}

function __bp_wadd(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a + b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) + BigInt(b), u, what);
}

function __bp_wsub(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a - b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) - BigInt(b), u, what);
}

function __bp_wmul(a, b, u, what) {
    if (typeof a === "number" && typeof b === "number") { const r = a * b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
    return __bp_wnorm(BigInt(a) * BigInt(b), u, what);
}

function __bp_wdiv(a, b, u, what) {
    if (b == 0) { throw Object.defineProperty(new Error("integer division by zero: " + what), "__bp_panic", { value: true }); }
    if (typeof a === "number" && typeof b === "number") { return Math.trunc(a / b) + 0; }
    return __bp_wnorm(BigInt(a) / BigInt(b), u, what);
}

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

//// std/io/clock (was std/time) — wall-clock primitives, cross-backend.

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/  (the `Date` global, the

////              `Date.now()` static method in particular)

////   Erlang   — https://www.erlang.org/doc/man/erlang.html#system_time-1

////              (`erlang:system_time(Unit)` — `Unit` may be an integer

////              divisor `1`, `1000`, `1000000`, `1000000000`)

//// 

//// `nowMillis()` returns Unix epoch milliseconds on every backend. The

//// implementation lowers to `Date.now(1000)` on Node — `Date.now/0`

//// silently ignores the extra arg (JS variadic) — and to

//// `erlang:system_time(1000)` on Erlang, where the integer `1000`

//// selects the millisecond unit. The split exists because the bare-symbol

//// `#[compiler.external(.<Target>)]` form cannot inject a literal atom-style unit on the

//// Erlang side without a richer template (tracked under

//// prim-op-annotation); the integer divisor form is universal and

//// keeps the call signature 1-arg. The `#[compiler.external(.<Target>)]`

//// annotation form (typed-enum) is the canonical surface.

//// 

//// `monotonicMillis()` returns the host's monotonic clock in

//// milliseconds — `performance.now()` on Node (DOM high-res timestamp,

//// floating point but assignable to the `i64` return on a backend that

//// has no integer-only clock without a chained `Math.floor`), and

//// `erlang:monotonic_time(1000)` on Erlang (integer divisor selects

//// milliseconds, matching the `nowMillis()` shape).

//// 

//// `measureMillis<T>(body)` composes `nowMillis()` calls — pure

//// botopink, no host call beyond what `nowMillis()` already lowers.

//// 

//// `sleep(ms)` blocks the caller (1.0.10-beta front 01): `Atomics.wait`

//// on Node, `timer:sleep/1` on Erlang. It is synchronous on purpose — the

//// `Async` spelling (`delay`) lives in `std/async`.

//// 

//// Front 01 also adds the calendar half below the readings: `parseIso8601`

//// (RFC 3339, offset required), `toCivil` (UTC breakdown, ISO weekday),

//// `offsetMinutes` (host timezone), the `Duration` builders and

//// `deadline`/`isExpired`. Front 23 moves the file to `io/clock.bp`.

//// 

//// `formatIso8601(epochMillis)` renders an RFC-3339 / ISO-8601 string

//// for an epoch-milliseconds reading. Node uses `new Date($0).toISOString()`

//// (chained host call, §A2-wired); Erlang supplies `[{unit, millisecond}]` to

//// `calendar:system_time_to_rfc3339/2`. The output is byte-identical on every

//// target, `YYYY-MM-DDTHH:MM:SS.sssZ`, milliseconds always (decision 849).

// Internal: read the host's current millisecond clock. The `unit`

// argument is `1000` for millis; Node `Date.now` ignores it, Erlang

// `erlang:system_time/1` uses it as the divisor selector.

// systemTimeWithUnit: per-call template (see annotation)

// Milliseconds since the Unix epoch. Monotonic across reasonable clock

// drift on every backend; not adjusted for leap seconds.

function nowMillis() {
    return Date.now(1000);
}
exports.nowMillis = nowMillis;

// Internal: read the host's monotonic clock. `unit` is `1000` for

// millis on Erlang (`erlang:monotonic_time/1` uses the divisor selector);

// Node uses the §A2 commonJS template form (`performance.now($0)`)

// to keep the receiver bound — the legacy

// `#[compiler.external(.JavaScript("performance", "now"))]` form aliased `const x =

// performance.now` and stripped `this`, reding with `Value of "this"

// must be of type Performance` at the first call site. The template

// renders inline at every call to `monotonicTimeWithUnit(N)`.

// The answer is an `i64`: `performance.now()` is a fractional millisecond

// count, truncated to its whole milliseconds (decision 319's canonical form).

// monotonicTimeWithUnit: per-call template (see annotation)

// Monotonic milliseconds — the host's monotonic clock, suitable for

// elapsed-time measurements (use `nowMillis()` for the wall clock).

// Two consecutive `monotonicMillis()` reads on the same backend are

// non-decreasing; the relative scale matches `nowMillis()` (millisecond

// units). On Node the absolute origin is the Unix epoch (`Date.now()`)

// until §A2 wires `performance.now()`; on Erlang it is the host's

// monotonic origin (`erlang:monotonic_time/1`).

function monotonicMillis() {
    return Math.floor(performance.now(1000));
}
exports.monotonicMillis = monotonicMillis;

// Render `epochMillis` as an ISO-8601 / RFC-3339 timestamp string.

// Node: `new Date($0).toISOString()` (renders `YYYY-MM-DDTHH:MM:SS.sssZ`).

// Erlang: `calendar:system_time_to_rfc3339/2` with the `millisecond` unit and

// the `Z` offset on the millis as they are (decision 849): milliseconds are

// always written, `YYYY-MM-DDTHH:MM:SS.sssZ`, as Node's are. The `Z` offset keeps

// `calendar` from reading the host's local time, which ERTS refuses before 1902.

// Its domain is RFC 3339's (decision 497): past it the call aborts,

// naming the value, on every target (`checkRfc3339Domain`).

// formatIso8601Host: per-call template (see annotation)

function formatIso8601(epochMillis) {
    checkRfc3339Domain("formatIso8601", epochMillis);
    return (new Date(epochMillis).toISOString());
}
exports.formatIso8601 = formatIso8601;

// The domain of `formatIso8601`, `toCivil` and `offsetMinutes` (decision

// 497): the epochs RFC 3339 writes, 0000-01-01T00:00:00Z …

// 9999-12-31T23:59:59.999Z, the same on every target. ECMAScript's `Date`

// holds a wider range and Erlang's `calendar` a different one, so the bound

// is checked here, before the host is reached.

function earliestRfc3339Millis() {
    return (-62167219200000);
}

function latestRfc3339Millis() {
    return 253402300799999;
}

// Internal: abort when `epochMillis` is past RFC 3339's domain, naming the

// function and the value.

function checkRfc3339Domain(what, epochMillis) {
    (() => { if (((epochMillis < earliestRfc3339Millis()) || (epochMillis > latestRfc3339Millis()))) { return (() => { throw Object.defineProperty(new Error(["clock.", what, ": ", epochMillis.toString(), " is past RFC 3339's range, -62167219200000 to 253402300799999"].join("")), '__bp_panic', { value: true }) })(); } })();
}

// Measure how long `body` takes to evaluate, in milliseconds. Returns

// the body's result paired with the elapsed time. Uses `nowMillis()`

// (the wall clock) rather than `monotonicMillis()` for cross-backend

// f64/i64 unifier symmetry — both readings are i64-typed, so the

// difference stays in the integer arithmetic path on every target.

function measureMillis(body) {
    const start = nowMillis();
    const result = body();
    const elapsed = __bp_wsub(nowMillis(), start, 0, "- on i64 at src/io/clock.bp:138:31");
    return [result, elapsed];
}
exports.measureMillis = measureMillis;

// ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

// 

// Parsing, the civil breakdown, the host timezone offset, durations,

// deadlines and `sleep`. The readings above are not edited.

// A UTC calendar breakdown of an epoch reading. `month` is 1–12, `day`

// 1–31, `weekday` ISO-8601 (Monday = 1 … Sunday = 7).

class Civil {
    constructor(year, month, day, hour, minute, second, weekday) {
        this.year = year;
        this.month = month;
        this.day = day;
        this.hour = hour;
        this.minute = minute;
        this.second = second;
        this.weekday = weekday;
    }
}
Civil.prototype.__bp = "Civil";
exports.Civil = Civil;

// A span of time in milliseconds. Built by `millis`/`seconds`/`minutes`/

// `hours`, combined by `add`, read back by `toMillis`.

class Duration {
    constructor(millis) {
        this.millis = millis;
    }
}
Duration.prototype.__bp = "Duration";
exports.Duration = Duration;

const { HostError } = require("../../std/failure.js");

// Parse an RFC 3339 timestamp (`2024-02-29T12:34:56Z`,

// `2024-02-29T12:34:56.789+02:00`) into epoch milliseconds. The date, the

// time AND the offset are required — a timestamp without an offset has no

// single instant, so it is an `Error`, not a guess at the host timezone.

// Node: `Date.parse` accepts far more than RFC 3339 (`"2024"`, `"Feb 1"`),

// so the template checks the RFC 3339 shape first, then parses; a shape or a

// date it refuses is its raise.

// Erlang: `calendar:rfc3339_to_system_time/2` in milliseconds; it raises on

// a malformed string.

// Both run under `result: true` (decisions 431, 490); `parseIso8601` makes

// the host's raise `ClockError.NotRfc3339` (decision 486).

function parseIso8601Host(s) { return __bp_host_result(require("../../std/failure.js"), () => (() => { const __s = String(s); const __t = /^[0-9]{4}-[0-9]{2}-[0-9]{2}[Tt ][0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]+)?([Zz]|[+-][0-9]{2}:[0-9]{2})$/.test(__s) ? Date.parse(__s) : NaN; if (Number.isNaN(__t)) throw new Error('not an RFC 3339 timestamp'); return __t })()); }

// What `parseIso8601` refuses (decision 486).

class ClockError {
    toString() {
        return __bp_text(this);
    }
}
ClockError.prototype.__bp = "ClockError";
class ClockError$NotRfc3339 extends ClockError {
}
ClockError$NotRfc3339.prototype.tag = "NotRfc3339";
ClockError.NotRfc3339 = new ClockError$NotRfc3339();
exports.ClockError = ClockError;

function parseIso8601(s) {
    const _case0 = (() => {
        const _s = parseIso8601Host(s);
        if ("ok" in _s) {
            const v = _s.ok;
            return ({ __bp_return: true, value: ({ ok: v }) });
        }
        if ("error" in _s) {
            return ({ __bp_return: true, value: ({ error: ClockError.NotRfc3339 }) });
        }
        throw new Error("case_clause");
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}
exports.parseIso8601 = parseIso8601;

// The UTC civil breakdown of `epochMillis`.

// Node: the `getUTC*` readers of a `Date`; `getUTCDay` counts Sunday = 0,

// rotated to ISO (Monday = 1).

// Erlang: `calendar:system_time_to_universal_time/2` + `day_of_the_week/3`

// (already Monday = 1).

// toCivilHost: per-call template (see annotation)

function toCivil(epochMillis) {
    checkRfc3339Domain("toCivil", epochMillis);
    return __bp_adopt((() => { const __d = new Date(epochMillis); return { year: __d.getUTCFullYear(), month: __d.getUTCMonth() + 1, day: __d.getUTCDate(), hour: __d.getUTCHours(), minute: __d.getUTCMinutes(), second: __d.getUTCSeconds(), weekday: ((__d.getUTCDay() + 6) % 7) + 1 } })(), Civil, "");
}
exports.toCivil = toCivil;

// The host timezone's offset from UTC at `epochMillis`, in minutes EAST of

// UTC (`+02:00` is `120`) — the sign RFC 3339 writes. Node's

// `getTimezoneOffset` counts minutes WEST, so the template negates it.

// Erlang: local minus universal time of the same instant. ERTS reads no

// local time before 1902 (`universaltime_to_localtime` is a `badarg`), so an

// earlier instant is read at 1902-01-01T00:00:00Z — the zone's offset there,

// its local mean time in most zones.

// offsetMinutesHost: per-call template (see annotation)

function offsetMinutes(epochMillis) {
    checkRfc3339Domain("offsetMinutes", epochMillis);
    return (0 - new Date(epochMillis).getTimezoneOffset());
}
exports.offsetMinutes = offsetMinutes;

// Internal: an `i32` read as an `i64` — std's `toI64()` (decision 319), which

// every `i32` fits, so no host cell is crossed.

function wide(n) {
    return n.toI64();
}

function millis(n) {
    return new Duration(wide(n));
}
exports.millis = millis;

function seconds(n) {
    return new Duration(__bp_wmul(wide(n), wide(1000), 0, "* on i64 at src/io/clock.bp:239:37"));
}
exports.seconds = seconds;

function minutes(n) {
    return new Duration(__bp_wmul(wide(n), wide(60000), 0, "* on i64 at src/io/clock.bp:243:37"));
}
exports.minutes = minutes;

function hours(n) {
    return new Duration(__bp_wmul(wide(n), wide(3600000), 0, "* on i64 at src/io/clock.bp:247:37"));
}
exports.hours = hours;

function add(a, b) {
    return new Duration(__bp_wadd(a.millis, b.millis, 0, "+ on i64 at src/io/clock.bp:251:38"));
}
exports.add = add;

function toMillis(d) {
    return d.millis;
}
exports.toMillis = toMillis;

// ── 1.0.11-beta front 97: a duration written as text ────────────────────────

// Internal: the largest millisecond count `parseDuration` answers — 2^53 - 1

// (decision 498). A duration is handed on as a timer delay or a JSON number,

// both `f64`, which stop counting by one past 2^53; an `i64` itself is exact

// past it on every target (decision 319).

function largestExactMillis() {
    return 9007199254740991;
}

// Internal: the unit `text` ends in — `ms` before `s`, since `5ms` ends in

// both — and `""` when it ends in none of the five.

function durationUnit(text) {
    return (() => { if (text.endsWith("ms")) { return "ms"; } else { return (() => { if (text.endsWith("s")) { return "s"; } else { return (() => { if (text.endsWith("m")) { return "m"; } else { return (() => { if (text.endsWith("h")) { return "h"; } else { return (() => { if (text.endsWith("d")) { return "d"; } else { return ""; } })(); } })(); } })(); } })(); } })();
}

// Internal: the milliseconds of one `unit` of `durationUnit`.

function unitMillis(unit) {
    return (() => { if ((unit === "ms")) { return wide(1); } else { return (() => { if ((unit === "s")) { return wide(1000); } else { return (() => { if ((unit === "m")) { return wide(60000); } else { return (() => { if ((unit === "h")) { return wide(3600000); } else { return wide(86400000); } })(); } })(); } })(); } })();
}

function durationProblem(text, what) {
    return ["clock.parseDuration: \"", text, "\" ", what].join("");
}

// Internal: the count `digits` spells — digits `0`–`9` only, no sign — or

// `-1` when it is not that and `-2` when it is but is beyond 2^53 - 1.

function durationCount(digits) {
    const signed = (digits.startsWith("+") || digits.startsWith("-"));
    if (signed) { return wide(__bp_int((0 - 1), -2147483648, 2147483647, "- on i32 at src/io/clock.bp:307:31")); }
    return (() => {
        const _s = digits.parseInt();
        if ("ok" in _s) {
            const n = _s.ok;
            return n;
        }
        if ("error" in _s) {
            const reason = _s.error;
            return wide((() => { if (reason.endsWith("is out of range")) { return __bp_int((0 - 2), -2147483648, 2147483647, "- on i32 at src/io/clock.bp:311:55"); } else { return __bp_int((0 - 1), -2147483648, 2147483647, "- on i32 at src/io/clock.bp:311:66"); } })());
        }
        throw new Error("case_clause");
    })();
}

// The milliseconds a duration spells: digits, then ONE unit — `ms`, `s`, `m`

// (minutes), `h` or `d` — and nothing else: `"30s"` is `30000`, `"250ms"` is

// `250`, `"0s"` is `0`. Refused, as an `Error` naming the text: no unit

// (`"30"`), a fraction (`"1.5s"`), a sign, whitespace anywhere (`"30 s"`), an

// uppercase unit (`"30S"`), two units (`"1h30m"`), the empty string — the

// stricter of the two parsers this replaces — and a duration beyond

// 2^53 - 1 milliseconds, which a timer delay or a JSON number (an `f64`)

// would not hold exactly (decision 498).

function parseDuration(text) {
    let text$sp = null;
    const unit = durationUnit(text);
    let unit$sp = null;
    const digits = text.slice(0, __bp_int((((text$sp ??= __bp_has_surrogate(text)) ? __bp_str_length(text) : text.length) - ((unit$sp ??= __bp_has_surrogate(unit)) ? __bp_str_length(unit) : unit.length)), -2147483648, 2147483647, "- on i32 at src/io/clock.bp:326:46"));
    const count = (() => { if ((unit === "")) { return wide(__bp_int((0 - 1), -2147483648, 2147483647, "- on i32 at src/io/clock.bp:327:40")); } else { return durationCount(digits); } })();
    if ((count === wide(__bp_int((0 - 1), -2147483648, 2147483647, "- on i32 at src/io/clock.bp:328:25")))) { return ({ error: durationProblem(text, "is not a duration: digits, then one unit of ms, s, m, h or d") }); }
    if ((count === wide(__bp_int((0 - 2), -2147483648, 2147483647, "- on i32 at src/io/clock.bp:333:25")))) { return ({ error: durationProblem(text, "is out of range") }); }
    // Compared before multiplying: a count as long as `i64` allows would;
    // overflow the product, which aborts the program, never answers.;
    if ((count > __bp_wdiv(largestExactMillis(), unitMillis(unit), 0, "/ on i64 at src/io/clock.bp:336:38"))) { return ({ error: durationProblem(text, "is out of range") }); }
    return ({ ok: __bp_wmul(count, unitMillis(unit), 0, "* on i64 at src/io/clock.bp:338:18") });
}
exports.parseDuration = parseDuration;

// Block the caller for `ms` milliseconds.

// Node: `Atomics.wait` on a scratch `SharedArrayBuffer` — a synchronous

// sleep that parks the thread instead of spinning (the value never

// changes, so the wait always times out).

// Erlang: `timer:sleep/1` — parks the calling process only.

// sleep: per-call template (see annotation)
function sleep(ms) { return (Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, Number(ms)), undefined); }
exports.sleep = sleep;

// The epoch reading `d` from now. A deadline is an absolute wall-clock

// value, so it survives being handed to another process (a cache entry, a

// session).

function deadline(d) {
    return __bp_wadd(nowMillis(), d.millis, 0, "+ on i64 at src/io/clock.bp:356:24");
}
exports.deadline = deadline;

// True once the wall clock has passed `at`.

function isExpired(at) {
    return (nowMillis() > at);
}
exports.isExpired = isExpired;

// ── tests ────────────────────────────────────────────────────────────────────

// The `Error` of `parseDuration(text)`, `""` when it parsed.

function durationRefusal(text) {
    return (() => {
        const _s = parseDuration(text);
        if ("ok" in _s) {
            return "";
        }
        if ("error" in _s) {
            const reason = _s.error;
            return reason;
        }
        throw new Error("case_clause");
    })();
}

Object.defineProperty(exports, "__bp_priv__", { value: { nowMillis, monotonicMillis, formatIso8601, earliestRfc3339Millis, latestRfc3339Millis, checkRfc3339Domain, measureMillis, Civil, Duration, HostError, parseIso8601Host, ClockError, ClockError$NotRfc3339, parseIso8601, toCivil, offsetMinutes, wide, millis, seconds, minutes, hours, add, toMillis, largestExactMillis, durationUnit, unitMillis, durationProblem, durationCount, parseDuration, sleep, deadline, isExpired, durationRefusal } });
