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

//// std/encoding — the wire formats: base64, base64url, hex, percent

//// encoding and the percent-aware form codec, cross-backend.

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/buffer.html (`Buffer.from(s, 'utf8').toString('base64' | 'base64url' | 'hex')`)

////              https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent

////   Erlang   — https://www.erlang.org/doc/apps/stdlib/base64.html

////              https://www.erlang.org/doc/apps/stdlib/binary.html (`encode_hex/1`, `decode_hex/1`)

////              https://www.erlang.org/doc/apps/stdlib/uri_string.html (`quote/1`, `unquote/1`)

////   RFC 4648 (base64, base64url), RFC 3986 §2.1 (percent-encoding)

//// 

//// One import for the whole wire-format surface. Every encoder answers a

//// string; every decoder that can meet malformed input answers

//// `Result<…, EncodingError>` (decision 486): the host cell writes

//// `result: true` (decisions 431, 490) and answers `Result<…, HostError>`,

//// and the public function maps it — nothing here returns a sentinel. The text

//// codecs read and write the UTF-8 bytes of a `string`: `base64Decode` and

//// `hexDecode` answer the bytes read back as UTF-8 (a non-UTF-8 payload is

//// lossy). Bytes cross losslessly through the `Bytes` bridges

//// (decision 346): `base64EncodeBytes` / `base64DecodeBytes` and

//// `hexEncodeBytes` / `hexDecodeBytes`.

//// 

//// Was also `base64` (decision 106): its `encode`/`decode`/`encodeUrlSafe`/

//// `decodeUrlSafe` are `base64Encode`/`base64Decode`/`base64UrlEncode`/

//// `base64UrlDecode` here, and its four tests sit at the foot of this file.

const { HostError, HostErrorName } = require("../std/failure.js");

// What a decoder refuses (decision 486): the text is not in the codec's form.

class EncodingError {
    toString() {
        return __bp_text(this);
    }
}
EncodingError.prototype.__bp = "EncodingError";
class EncodingError$NotBase64 extends EncodingError {
}
EncodingError$NotBase64.prototype.tag = "NotBase64";
class EncodingError$NotHex extends EncodingError {
}
EncodingError$NotHex.prototype.tag = "NotHex";
class EncodingError$NotPercentEncoded extends EncodingError {
}
EncodingError$NotPercentEncoded.prototype.tag = "NotPercentEncoded";
EncodingError.NotBase64 = new EncodingError$NotBase64();
EncodingError.NotHex = new EncodingError$NotHex();
EncodingError.NotPercentEncoded = new EncodingError$NotPercentEncoded();
exports.EncodingError = EncodingError;

// Standard base64 (RFC 4648 §4) of the UTF-8 bytes of `s`, with `=` padding.

// base64Encode: per-call template (see annotation)
function base64Encode(s) { return Buffer.from(s, 'utf8').toString('base64'); }
exports.base64Encode = base64Encode;

// The inverse of `base64Encode`. Malformed input is an `Error`: Node's

// `Buffer.from(_, 'base64')` silently drops what it cannot read, so the

// template re-encodes and compares to detect it; Erlang's `base64:decode/1`

// raises, and the template catches.

function base64DecodeHost(b) { return __bp_host_result(require("../std/failure.js"), () => (() => { const __s = String(b).replace(/=+$/, ''); const __b = Buffer.from(__s, 'base64'); if (__b.toString('base64').replace(/=+$/, '') !== __s) throw new Error('not base64'); return __b.toString('utf8') })()); }

function base64Decode(b) {
    const _case0 = (() => {
        const _s = base64DecodeHost(b);
        if ("ok" in _s) {
            const v = _s.ok;
            return ({ __bp_return: true, value: ({ ok: v }) });
        }
        if ("error" in _s) {
            return ({ __bp_return: true, value: ({ error: EncodingError.NotBase64 }) });
        }
        throw new Error("case_clause");
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}
exports.base64Decode = base64Decode;

// base64url (RFC 4648 §5): the `-_` alphabet, no `=` padding — the form

// JWS/JWT (RFC 7515) and `random.secureToken` use. Pure over `base64Encode`,

// with `replaceAll` (not `replace`, which stops at the first occurrence).

function base64UrlEncode(s) {
    const raw = Buffer.from(s, 'utf8').toString('base64');
    const noPlus = raw.replaceAll("+", "-");
    const noSlash = noPlus.replaceAll("/", "_");
    return noSlash.replaceAll("=", "");
}
exports.base64UrlEncode = base64UrlEncode;

// The inverse of `base64UrlEncode`: restore the `+/` alphabet, re-pad to a

// multiple of four, decode.

function base64UrlDecode(b) {
    const noDash = b.replaceAll("-", "+");
    const noUnder = noDash.replaceAll("_", "/");
    const padded = padToMultipleOfFour(noUnder);
    return base64Decode(padded);
}
exports.base64UrlDecode = base64UrlDecode;

// Internal: append `=` until the length is a multiple of four. Tail-recursive;

// at most three steps.

function padToMultipleOfFour(s) {
    let s$sp = null;
    const remainder = __bp_int((((s$sp ??= __bp_has_surrogate(s)) ? __bp_str_length(s) : s.length) % 4), -2147483648, 2147483647, "% on i32 at src/encoding.bp:84:30");
    return (() => { if ((remainder === 0)) { return s; } else { return padToMultipleOfFour([s, "="].join("")); } })();
}

// Lowercase hex of the UTF-8 bytes of `s`: `"hi"` → `6869`.

// hexEncode: per-call template (see annotation)
function hexEncode(s) { return Buffer.from(s, 'utf8').toString('hex'); }
exports.hexEncode = hexEncode;

// The inverse of `hexEncode`, either case. An odd length or a non-hex digit

// is an `Error` (Node's `Buffer.from(_, 'hex')` truncates silently at the

// first bad digit, so the template validates first; Erlang's

// `binary:decode_hex/1` raises `badarg`, caught).

function hexDecodeHost(s) { return __bp_host_result(require("../std/failure.js"), () => (() => { const __s = String(s); if (!/^([0-9a-fA-F]{2})*$/.test(__s)) throw new Error('not hex'); return Buffer.from(__s, 'hex').toString('utf8') })()); }

function hexDecode(s) {
    const _case0 = (() => {
        const _s = hexDecodeHost(s);
        if ("ok" in _s) {
            const v = _s.ok;
            return ({ __bp_return: true, value: ({ ok: v }) });
        }
        if ("error" in _s) {
            return ({ __bp_return: true, value: ({ error: EncodingError.NotHex }) });
        }
        throw new Error("case_clause");
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}
exports.hexDecode = hexDecode;

// ── the `bytes` bridges (decision 346) ───────────────────────────────────────

// The codecs above over `bytes`, lossless: an encoder answers the text of the

// bytes as they are, a decoder the bytes the text spells — with the text

// codecs' rules (the Node cell's base64: trailing `=` optional, no length of

// the form 4k + 1, zero bits after the last whole byte; hex either case, an

// even length) and their `Error` texts. On wasm and at comptime std-wasm

// answers (`encoding.zig`); a decoder's cell answers `?bytes`, absent for text

// that is not one, and the public function makes it the `Error`.

// Standard base64 (RFC 4648 §4) of `b`, with `=` padding.

// base64EncodeBytes: per-call template (see annotation)
function base64EncodeBytes(b) { return Buffer.from(b).toString('base64'); }
exports.base64EncodeBytes = base64EncodeBytes;

// The bytes the base64 text `s` spells; anything `base64Decode` refuses is

// the same `Error`.

function base64DecodeBytes(s) {
    const b = ((__s) => { const __t = __s.replace(/=+$/, ''); if (__t.length % 4 === 1 || !/^[A-Za-z0-9+/]*$/.test(__t)) return null; const __b = Buffer.from(__t, 'base64'); return __b.toString('base64').replace(/=+$/, '') === __t ? new Uint8Array(__b) : null; })(s);
    if ((b == null)) { return ({ error: EncodingError.NotBase64 }); }
    return ({ ok: b });
}
exports.base64DecodeBytes = base64DecodeBytes;

// base64BytesOf: per-call template (see annotation)

// Lowercase hex of `b`: the bytes `0x68 0x69` are `6869`.

// hexEncodeBytes: per-call template (see annotation)
function hexEncodeBytes(b) { return Buffer.from(b).toString('hex'); }
exports.hexEncodeBytes = hexEncodeBytes;

// The bytes the hex text `s` spells, either case; an odd length or a non-hex

// digit is `hexDecode`'s `Error`.

function hexDecodeBytes(s) {
    const b = (/^([0-9a-fA-F]{2})*$/.test(s) ? new Uint8Array(Buffer.from(s, 'hex')) : null);
    if ((b == null)) { return ({ error: EncodingError.NotHex }); }
    return ({ ok: b });
}
exports.hexDecodeBytes = hexDecodeBytes;

// hexBytesOf: per-call template (see annotation)

// RFC 3986 percent-encoding of a component: every byte of the UTF-8 form

// outside the unreserved set `A-Z a-z 0-9 - . _ ~` becomes `%XX`, uppercase.

// `uri_string:quote/1` is exactly that; `encodeURIComponent` leaves

// `! ' ( ) *` unencoded (RFC 2396's mark set), so the Node template encodes

// those five too — the two targets answer the same bytes for the same input.

// percentEncode: per-call template (see annotation)
function percentEncode(s) { return encodeURIComponent(s).replace(/[!'()*]/g, __c => '%' + __c.charCodeAt(0).toString(16).toUpperCase()); }
exports.percentEncode = percentEncode;

// The inverse of `percentEncode`. A `%` not followed by two hex digits, or a

// sequence that is not UTF-8, is an `Error`. `+` is left as `+` — the form

// codec below is what reads `+` as a space.

function percentDecodeHost(s) { return __bp_host_result(require("../std/failure.js"), () => decodeURIComponent(s)); }

function percentDecode(s) {
    const _case0 = (() => {
        const _s = percentDecodeHost(s);
        if ("ok" in _s) {
            const v = _s.ok;
            return ({ __bp_return: true, value: ({ ok: v }) });
        }
        if ("error" in _s) {
            return ({ __bp_return: true, value: ({ error: EncodingError.NotPercentEncoded }) });
        }
        throw new Error("case_clause");
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}
exports.percentDecode = percentDecode;

// `application/x-www-form-urlencoded`, the escaping form: each pair is

// `percentEncode(name)=percentEncode(value)`, joined with `&`.

// `querystring.stringify` writes the same text and refuses a control

// character, which this does not.

function formStringify(pairs) {
    return pairs.map((p) => {
    return [encodeURIComponent(p[0]).replace(/[!'()*]/g, __c => '%' + __c.charCodeAt(0).toString(16).toUpperCase()), "=", encodeURIComponent(p[1]).replace(/[!'()*]/g, __c => '%' + __c.charCodeAt(0).toString(16).toUpperCase())].join("");
}).join("&");
}
exports.formStringify = formStringify;

// The inverse of `formStringify`, percent-aware: split on `&`, each field on

// its FIRST `=` (a field with no `=` is a name with an empty value), `+` read

// as a space (the form encoding's rule), then percent-decoded. A field that

// does not decode keeps its raw text — a parse over user input must not

// throw, and a malformed pair is still a pair. Empty fields (`a=1&&b=2`)

// are dropped. `querystring.parseForm` is the refusing reader: a malformed

// escape or a control character is its `Error`, not a raw field.

function formParse(q) {
    const fields = q.split("&").filter((f) => {
    return (f !== "");
});
    return fields.map((f) => {
    return formField(f);
});
}
exports.formParse = formParse;

// Internal: one `name=value` field into its decoded pair.

function formField(f) {
    let f$sp = null;
    const eq = ((f$sp ??= __bp_has_surrogate(f)) ? __bp_str_index_of(f, "=") : f.indexOf("="));
    const rawName = (() => { if ((eq < 0)) { return f; } else { return f.slice(0, eq); } })();
    const rawValue = (() => { if ((eq < 0)) { return ""; } else { return f.slice(__bp_int((eq + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:224:51"), ((f$sp ??= __bp_has_surrogate(f)) ? __bp_str_length(f) : f.length)); } })();
    return [formDecode(rawName), formDecode(rawValue)];
}

// Internal: `+` to space, then percent-decode, falling back to the raw text.

function formDecode(s) {
    const spaced = s.replaceAll("+", " ");
    return ((_r) => "error" in _r ? (spaced) : _r.ok)(percentDecode(spaced));
}

// ── the wasm bodies (decision 238) ───────────────────────────────────────────

// wasm has no host to encode with, so each cell above names one of these

// private bodies with `#[compiler.external(.Wasm(fn: …))]`. They run only on wasm and

// answer what the Node cell answers: a string's bytes are its UTF-8, a decoded

// byte string is read back as Node's `toString('utf8')` reads it (WHATWG UTF-8:

// each maximal ill-formed subsequence one U+FFFD), and the text is built from

// code points with `string.fromCodepoint` (decision 262).

function base64EncodeBody(s) {
    return base64Text(utf8Of(s));
}

// What the wasm bodies refuse with: the `HostError` a host's raise would be.

function refused(message) {
    return new HostError(message, "host", HostErrorName.Error, null);
}

// The Node cell's rule: strip trailing `=`, decode, and accept only what

// re-encodes to the same text — the `+/` alphabet only, no length of the form

// 4k + 1, zero bits after the last whole byte.

function base64DecodeBody(b) {
    const cs = b.chars();
    let n = cs.length;
    while (((n > 0) && (((() => { const __bp_nullish = __bp_array_at(cs, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/encoding.bp:262:30")); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()) === "="))) {
    n = __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/encoding.bp:263:15");
}
    if ((__bp_int((n % 4), -2147483648, 2147483647, "% on i32 at src/encoding.bp:265:11") === 1)) { return ({ error: refused("not base64") }); }
    let sextets = [];
    let i = 0;
    while ((i < n)) {
    const v = base64Value((() => { const __bp_nullish = __bp_array_at(cs, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })());
    if ((v < 0)) { return ({ error: refused("not base64") }); }
    sextets = sextets.concat([v]);
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:272:15");
}
    const last = (() => { const __bp_nullish = __bp_array_at(sextets, __bp_int((n - 1), -2147483648, 2147483647, "- on i32 at src/encoding.bp:274:29")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    if (((__bp_int((n % 4), -2147483648, 2147483647, "% on i32 at src/encoding.bp:275:11") === 2) && (__bp_int((last % 16), -2147483648, 2147483647, "% on i32 at src/encoding.bp:275:28") !== 0))) { return ({ error: refused("not base64") }); }
    if (((__bp_int((n % 4), -2147483648, 2147483647, "% on i32 at src/encoding.bp:276:11") === 3) && (__bp_int((last % 4), -2147483648, 2147483647, "% on i32 at src/encoding.bp:276:28") !== 0))) { return ({ error: refused("not base64") }); }
    let bytes = [];
    let g = 0;
    while ((g < n)) {
    const s0 = (() => { const __bp_nullish = __bp_array_at(sextets, g); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    const s1 = (() => { const __bp_nullish = __bp_array_at(sextets, __bp_int((g + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:281:31")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    const s2 = (() => { const __bp_nullish = __bp_array_at(sextets, __bp_int((g + 2), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:282:31")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    const s3 = (() => { const __bp_nullish = __bp_array_at(sextets, __bp_int((g + 3), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:283:31")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    bytes = bytes.concat([__bp_int((__bp_int((s0 * 4), -2147483648, 2147483647, "* on i32 at src/encoding.bp:284:23") + __bp_int(Math.trunc((s1 / 16)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:284:32")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:284:27")]);
    (() => { if ((__bp_int((g + 2), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:285:15") < n)) { return bytes.push(__bp_int((__bp_int(((__bp_int((s1 % 16), -2147483648, 2147483647, "% on i32 at src/encoding.bp:285:39")) * 16), -2147483648, 2147483647, "* on i32 at src/encoding.bp:285:45") + __bp_int(Math.trunc((s2 / 4)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:285:55")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:285:50")); } })();
    (() => { if ((__bp_int((g + 3), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:286:15") < n)) { return bytes.push(__bp_int((__bp_int(((__bp_int((s2 % 4), -2147483648, 2147483647, "% on i32 at src/encoding.bp:286:39")) * 64), -2147483648, 2147483647, "* on i32 at src/encoding.bp:286:44") + s3), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:286:49")); } })();
    g = __bp_int((g + 4), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:287:15");
}
    return ({ ok: textOfUtf8(bytes) });
}

function hexEncodeBody(s) {
    return utf8Of(s).map((b) => {
    return (hexDigit(__bp_int(Math.trunc((b / 16)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:293:44")) + hexDigit(__bp_int((b % 16), -2147483648, 2147483647, "% on i32 at src/encoding.bp:293:63")));
}).join("");
}

function hexDecodeBody(s) {
    const cs = s.chars();
    if ((__bp_int((cs.length % 2), -2147483648, 2147483647, "% on i32 at src/encoding.bp:298:19") !== 0)) { return ({ error: refused("not hex") }); }
    let bytes = [];
    let i = 0;
    while ((i < cs.length)) {
    const hi = hexValue((() => { const __bp_nullish = __bp_array_at(cs, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })());
    const lo = hexValue((() => { const __bp_nullish = __bp_array_at(cs, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:303:35")); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })());
    if (((hi < 0) || (lo < 0))) { return ({ error: refused("not hex") }); }
    bytes = bytes.concat([__bp_int((__bp_int((hi * 16), -2147483648, 2147483647, "* on i32 at src/encoding.bp:305:23") + lo), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:305:28")]);
    i = __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:306:15");
}
    return ({ ok: textOfUtf8(bytes) });
}

// `encodeURIComponent` plus the five marks the Node cell escapes too: every

// UTF-8 byte outside `A-Z a-z 0-9 - . _ ~` as `%XX`, uppercase.

function percentEncodeBody(s) {
    return s.chars().map((c) => {
    return (() => { if (isUnreserved(c.charCodeAt(0))) { return c; } else { return utf8Bytes(c.charCodeAt(0)).map((b) => {
    return (("%" + upperHexDigit(__bp_int(Math.trunc((b / 16)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:322:54"))) + upperHexDigit(__bp_int((b % 16), -2147483648, 2147483647, "% on i32 at src/encoding.bp:322:78")));
}).join(""); } })();
}).join("");
}

// `decodeURIComponent`: a `%` reads two hex digits; a byte below 0x80 is its

// character, a lead byte takes the continuation escapes its length says, and

// the sequence must be well-formed UTF-8 (no overlong form, no surrogate,

// nothing past U+10FFFF) — anything else is the `Error`. Other text passes.

function percentDecodeBody(s) {
    const cs = s.chars();
    let out = [];
    let i = 0;
    while ((i < cs.length)) {
    const c = (() => { const __bp_nullish = __bp_array_at(cs, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    if ((c !== "%")) { out = out.concat([c]); i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:341:19"); } else { const b = escapedByte(cs, i); if ((b < 0)) { return ({ error: refused("not percent-encoded") }); } if ((b < 128)) { out = out.concat([((__c) => { if (!(__c >= 0 && __c <= 1114111) || (__c >= 55296 && __c <= 57343)) throw new RangeError('String.fromCodepoint: ' + __c + ' is not a Unicode scalar value'); return String.fromCodePoint(__c); })(b)]); i = __bp_int((i + 3), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:347:23"); } else { const len = (() => { if (((b >= 192) && (b < 224))) { return 2; } else { return (() => { if (((b >= 224) && (b < 240))) { return 3; } else { return (() => { if (((b >= 240) && (b < 248))) { return 4; } else { return 0; } })(); } })(); } })(); if ((len === 0)) { return ({ error: refused("not percent-encoded") }); } let cp = (() => { if ((len === 2)) { return __bp_int((b - 192), -2147483648, 2147483647, "- on i32 at src/encoding.bp:359:23"); } else { return (() => { if ((len === 3)) { return __bp_int((b - 224), -2147483648, 2147483647, "- on i32 at src/encoding.bp:361:23"); } else { return __bp_int((b - 240), -2147483648, 2147483647, "- on i32 at src/encoding.bp:363:23"); } })(); } })(); let k = 1; while ((k < len)) {
    const cb = escapedByte(cs, __bp_int((i + __bp_int((3 * k), -2147483648, 2147483647, "* on i32 at src/encoding.bp:366:52")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:366:48"));
    if (((cb < 128) || (cb >= 192))) { return ({ error: refused("not percent-encoded") }); }
    cp = __bp_int((__bp_int((cp * 64), -2147483648, 2147483647, "* on i32 at src/encoding.bp:369:29") + (__bp_int((cb - 128), -2147483648, 2147483647, "- on i32 at src/encoding.bp:369:40"))), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:369:34");
    k = __bp_int((k + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:370:27");
} const least = (() => { if ((len === 2)) { return 128; } else { return (() => { if ((len === 3)) { return 2048; } else { return 65536; } })(); } })(); if ((((cp < least) || (cp > 1114111)) || (((cp >= 55296) && (cp <= 57343))))) { return ({ error: refused("not percent-encoded") }); } out = out.concat([((__c) => { if (!(__c >= 0 && __c <= 1114111) || (__c >= 55296 && __c <= 57343)) throw new RangeError('String.fromCodepoint: ' + __c + ' is not a Unicode scalar value'); return String.fromCodePoint(__c); })(cp)]); i = __bp_int((i + __bp_int((3 * len), -2147483648, 2147483647, "* on i32 at src/encoding.bp:381:27")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:381:23"); } }
}
    return ({ ok: out.join("") });
}

// The byte `%XX` at index `i` spells, or -1 when `i` holds no `%` followed by

// two hex digits.

function escapedByte(cs, i) {
    if (((() => { const __bp_nullish = __bp_array_at(cs, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })() !== "%")) { return (-1); }
    const hi = hexValue((() => { const __bp_nullish = __bp_array_at(cs, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:392:31")); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })());
    const lo = hexValue((() => { const __bp_nullish = __bp_array_at(cs, __bp_int((i + 2), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:393:31")); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })());
    if (((hi < 0) || (lo < 0))) { return (-1); }
    return __bp_int((__bp_int((hi * 16), -2147483648, 2147483647, "* on i32 at src/encoding.bp:395:15") + lo), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:395:20");
}

function isUnreserved(cp) {
    return (((((((((cp >= 65) && (cp <= 90))) || (((cp >= 97) && (cp <= 122)))) || (((cp >= 48) && (cp <= 57)))) || (cp === 45)) || (cp === 46)) || (cp === 95)) || (cp === 126));
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
    if ((cp < 2048)) { return [__bp_int((192 + __bp_int(Math.trunc((cp / 64)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:421:37")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:421:32"), __bp_int((128 + __bp_int((cp % 64), -2147483648, 2147483647, "% on i32 at src/encoding.bp:421:52")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:421:47")]; }
    if ((cp < 65536)) { return [__bp_int((224 + __bp_int(Math.trunc((cp / 4096)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:423:26")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:423:21"), __bp_int((128 + __bp_int(((__bp_int(Math.trunc((cp / 64)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:423:44")) % 64), -2147483648, 2147483647, "% on i32 at src/encoding.bp:423:50")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:423:38"), __bp_int((128 + __bp_int((cp % 64), -2147483648, 2147483647, "% on i32 at src/encoding.bp:423:65")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:423:60")]; }
    return [__bp_int((240 + __bp_int(Math.trunc((cp / 262144)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:425:18")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:425:13"), __bp_int((128 + __bp_int(((__bp_int(Math.trunc((cp / 4096)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:426:19")) % 64), -2147483648, 2147483647, "% on i32 at src/encoding.bp:426:27")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:426:13"), __bp_int((128 + __bp_int(((__bp_int(Math.trunc((cp / 64)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:427:19")) % 64), -2147483648, 2147483647, "% on i32 at src/encoding.bp:427:25")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:427:13"), __bp_int((128 + __bp_int((cp % 64), -2147483648, 2147483647, "% on i32 at src/encoding.bp:428:18")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:428:13")];
}

// `bytes` read as UTF-8 the way the WHATWG decoder (and so Node's

// `toString('utf8')`) reads them: a byte that cannot start a sequence, a

// sequence cut short, an overlong or surrogate form, and a sequence past

// U+10FFFF each answer U+FFFD for their maximal ill-formed subsequence.

function textOfUtf8(bytes) {
    let out = [];
    let need = 0;
    let seen = 0;
    let cp = 0;
    let lower = 128;
    let upper = 191;
    let i = 0;
    while ((i < bytes.length)) {
    const b = (() => { const __bp_nullish = __bp_array_at(bytes, i); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    (() => { if ((need === 0)) { (() => { if ((b < 128)) { return out.push(((__c) => { if (!(__c >= 0 && __c <= 1114111) || (__c >= 55296 && __c <= 57343)) throw new RangeError('String.fromCodepoint: ' + __c + ' is not a Unicode scalar value'); return String.fromCodePoint(__c); })(b)); } else { return (() => { if (((b >= 194) && (b <= 223))) { need = 1; return cp = __bp_int((b - 192), -2147483648, 2147483647, "- on i32 at src/encoding.bp:450:24"); } else { return (() => { if (((b >= 224) && (b <= 239))) { (() => { if ((b === 224)) { return lower = 160; } })(); (() => { if ((b === 237)) { return upper = 159; } })(); need = 2; return cp = __bp_int((b - 224), -2147483648, 2147483647, "- on i32 at src/encoding.bp:455:24"); } else { return (() => { if (((b >= 240) && (b <= 244))) { (() => { if ((b === 240)) { return lower = 144; } })(); (() => { if ((b === 244)) { return upper = 143; } })(); need = 3; return cp = __bp_int((b - 240), -2147483648, 2147483647, "- on i32 at src/encoding.bp:460:24"); } else { return out.push(((__c) => { if (!(__c >= 0 && __c <= 1114111) || (__c >= 55296 && __c <= 57343)) throw new RangeError('String.fromCodepoint: ' + __c + ' is not a Unicode scalar value'); return String.fromCodePoint(__c); })(65533)); } })(); } })(); } })(); } })(); return i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:462:19"); } else { return (() => { if (((b < lower) || (b > upper))) { need = 0; seen = 0; cp = 0; lower = 128; upper = 191; return out.push(((__c) => { if (!(__c >= 0 && __c <= 1114111) || (__c >= 55296 && __c <= 57343)) throw new RangeError('String.fromCodepoint: ' + __c + ' is not a Unicode scalar value'); return String.fromCodePoint(__c); })(65533)); } else { lower = 128; upper = 191; cp = __bp_int((__bp_int((cp * 64), -2147483648, 2147483647, "* on i32 at src/encoding.bp:473:21") + (__bp_int((b - 128), -2147483648, 2147483647, "- on i32 at src/encoding.bp:473:31"))), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:473:26"); seen = __bp_int((seen + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:474:25"); (() => { if ((seen === need)) { out = out.concat([((__c) => { if (!(__c >= 0 && __c <= 1114111) || (__c >= 55296 && __c <= 57343)) throw new RangeError('String.fromCodepoint: ' + __c + ' is not a Unicode scalar value'); return String.fromCodePoint(__c); })(cp)]); need = 0; seen = 0; return cp = 0; } })(); return i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:481:19"); } })(); } })();
}
    (() => { if ((need !== 0)) { return out.push(((__c) => { if (!(__c >= 0 && __c <= 1114111) || (__c >= 55296 && __c <= 57343)) throw new RangeError('String.fromCodepoint: ' + __c + ' is not a Unicode scalar value'); return String.fromCodePoint(__c); })(65533)); } })();
    return out.join("");
}

function base64Text(bytes) {
    const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let out = [];
    let g = 0;
    while ((g < bytes.length)) {
    const n = __bp_int((bytes.length - g), -2147483648, 2147483647, "- on i32 at src/encoding.bp:493:30");
    const b0 = (() => { const __bp_nullish = __bp_array_at(bytes, g); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    const b1 = (() => { if ((n > 1)) { return (() => { const __bp_nullish = __bp_array_at(bytes, __bp_int((g + 1), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:496:24")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })(); } else { return 0; } })();
    const b2 = (() => { if ((n > 2)) { return (() => { const __bp_nullish = __bp_array_at(bytes, __bp_int((g + 2), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:499:24")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })(); } else { return 0; } })();
    out = out.concat([(() => { const __bp_nullish = (alphabet.at(__bp_int(Math.trunc((b0 / 4)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:501:33")) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()]);
    out = out.concat([(() => { const __bp_nullish = (alphabet.at(__bp_int((__bp_int(((__bp_int((b0 % 4), -2147483648, 2147483647, "% on i32 at src/encoding.bp:502:34")) * 16), -2147483648, 2147483647, "* on i32 at src/encoding.bp:502:39") + __bp_int(Math.trunc((b1 / 16)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:502:49")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:502:44")) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()]);
    out = out.concat([(() => { if ((n > 1)) { return (() => { const __bp_nullish = (alphabet.at(__bp_int((__bp_int(((__bp_int((b1 % 16), -2147483648, 2147483647, "% on i32 at src/encoding.bp:505:33")) * 4), -2147483648, 2147483647, "* on i32 at src/encoding.bp:505:39") + __bp_int(Math.trunc((b2 / 64)), -2147483648, 2147483647, "/ on i32 at src/encoding.bp:505:48")), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:505:43")) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })(); } else { return "="; } })()]);
    out = out.concat([(() => { if ((n > 2)) { return (() => { const __bp_nullish = (alphabet.at(__bp_int((b2 % 64), -2147483648, 2147483647, "% on i32 at src/encoding.bp:510:32")) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })(); } else { return "="; } })()]);
    g = __bp_int((g + 3), -2147483648, 2147483647, "+ on i32 at src/encoding.bp:513:15");
}
    return out.join("");
}

// The value of one character of the `+/` alphabet, or -1.

function base64Value(c) {
    if ((c === "")) { return (-1); }
    return "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".indexOf(c);
}

function hexDigit(n) {
    return (() => { const __bp_nullish = ("0123456789abcdef".at(n) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
}

function upperHexDigit(n) {
    return (() => { const __bp_nullish = ("0123456789ABCDEF".at(n) ?? null); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
}

// The value of one hex digit, either case, or -1.

function hexValue(c) {
    if ((c === "")) { return (-1); }
    const lowerAt = "0123456789abcdef".indexOf(c);
    if ((lowerAt >= 0)) { return lowerAt; }
    return "0123456789ABCDEF".indexOf(c);
}

// ── tests ────────────────────────────────────────────────────────────────────

// ── the tests of the retired `base64` module, over the names that replaced it ──

Object.defineProperty(exports, "__bp_priv__", { value: { HostError, HostErrorName, EncodingError, EncodingError$NotBase64, EncodingError$NotHex, EncodingError$NotPercentEncoded, base64Encode, base64DecodeHost, base64Decode, base64UrlEncode, base64UrlDecode, padToMultipleOfFour, hexEncode, hexDecodeHost, hexDecode, base64EncodeBytes, base64DecodeBytes, hexEncodeBytes, hexDecodeBytes, percentEncode, percentDecodeHost, percentDecode, formStringify, formParse, formField, formDecode, base64EncodeBody, refused, base64DecodeBody, hexEncodeBody, hexDecodeBody, percentEncodeBody, percentDecodeBody, escapedByte, isUnreserved, utf8Of, utf8Bytes, textOfUtf8, base64Text, base64Value, hexDigit, upperHexDigit, hexValue } });
