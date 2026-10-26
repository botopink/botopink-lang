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

//// The records of one case's answer (decisions 457, 475, 485, 789, 868, 989 (5)) — the port of

//// `conformance/check/src/records.bp`, itself the port of `cell_snap.zig`, plus decision 789's

//// `build` record. A module's `snapshot/main.snap` (`sections.bp`) holds one run of these records

//// per case; `parseBody` and `renderBody` read and write that run without the file's header.

//// 

//// A run of records is one case's answer on one or every target, a record per line:

//// 

////     botopink-cell 1                 the format and its version, always line 1

////     refused <message line>          the compiler refuses the module: its

////     at <file>:<line>:<col>            `error…` line, and where (when located)

////     label <text>                    the label printed beside the caret (485)

////     from <file>:<line>:<col>        one `called from` line of a raise at build,

////                                       innermost first (868)

////     build <text>                    one line a build body printed (789; `build`

////                                       alone for an empty line)

////     out <text>                      one line the program printed (`out` alone

////                                       for an empty line)

////     no-final-newline                the last `out` line ended without `\n`

////     abort                           the program exits non-zero

////     stderr <text>                   with `abort`: the program's stderr contains

////                                       this text

//// 

//// The records come in the console's order (decision 904) — `build` lines, then the

//// refusals (`refused`, `at`, `label`, `from`) or the output, then `abort`, then the

//// `stderr` claims; nothing prints after a refusal, so a `build` after a `refused` is

//// malformed — and a

//// file has exactly one spelling: it parses only when rendering what it parsed

//// gives back its text. A refusal and an output never share a file. The header

//// alone is the empty answer.

//// 

//// Everything but `stderr` is compared exactly; a `stderr` line is a claim the

//// abort's stderr contains.

//// 

//// Text, not bytes: the program runs on commonJS, where a string is UTF-16. Every

//// cut here is at an ASCII `\n` or ` `, which no UTF-8 multi-byte sequence holds,

//// so each piece is the same text `cell_snap.zig` cuts from the file's bytes.

/** The header the records grammar below is written against (a section carries none: the file's */

/** line 1 is `sections.HEADER`). */

const HEADER = "botopink-cell 1";

exports.HEADER = HEADER;

/** A candidate's suffix, beside the accepted file it would replace. */

const NEW_SUFFIX = ".new";

exports.NEW_SUFFIX = NEW_SUFFIX;

/** One refusal of a module: the compiler's `error…` line, its location when the */

/** diagnostic carries one, the label beside the caret, and the `called from` */

/** frames (`from` records; `from` is a reserved word, so the field is `frames`). */

class Refusal {
    constructor(message, at, label, frames) {
        this.message = message;
        this.at = at;
        this.label = label;
        this.frames = frames;
    }
}
Refusal.prototype.__bp = "Refusal";
exports.Refusal = Refusal;

/** One module's answer. */

class Snap {
    constructor(refusals, build, stdout, abort, stderr) {
        this.refusals = refusals;
        this.build = build;
        this.stdout = stdout;
        this.abort = abort;
        this.stderr = stderr;
    }

    isEmpty() {
        return (((((this.refusals.length === 0) && (this.build.length === 0)) && (this.stdout === "")) && (!this.abort)) && (this.stderr.length === 0));
    }
}
Snap.prototype.__bp = "Snap";
exports.Snap = Snap;

/** Why a `.snap` did not parse: its 1-based line and the reason. */

class Malformed {
    constructor(line, reason) {
        this.line = line;
        this.reason = reason;
    }
}
Malformed.prototype.__bp = "Malformed";
exports.Malformed = Malformed;

function fail(line, reason) {
    return ({ error: new Malformed(line, reason) });
}

function withAt(r, at) {
    return new Refusal(r.message, at, r.label, r.frames);
}

function withLabel(r, label) {
    return new Refusal(r.message, r.at, label, r.frames);
}

function withFrame(r, frame) {
    return new Refusal(r.message, r.at, r.label, r.frames.concat([frame]));
}

/** Parse a `.snap`; a malformed one answers its line and the reason. */

function parse(text) {
    let text$sp = null;
    if (((text === "") || (!text.endsWith("\n")))) { return fail(text.split("\n").length, "every record ends with a newline"); }
    const lines = text.slice(0, __bp_int((((text$sp ??= __bp_has_surrogate(text)) ? __bp_str_length(text) : text.length) - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:98:43")).split("\n");
    let refusals = [];
    let build = [];
    let stdout = "";
    let stderr = [];
    let abort = false;
    // 0 start · 1 build · 2 output · 3 after `no-final-newline` · 4 after `abort` · 5 stderr · 6 refusals;
    let phase = 0;
    let lastOutEmpty = false;
    let n = 0;
    while ((n < lines.length)) {
    const line = (() => { const __bp_nullish = __bp_array_at(lines, n); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    let line$sp = null;
    n = __bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:110:15");
    if ((n === 1)) { if ((!__bp_eq(line, HEADER, 0))) { return fail(n, "line 1 must be `botopink-cell 1`"); } continue; }
    const space = ((line$sp ??= __bp_has_surrogate(line)) ? __bp_str_index_of(line, " ") : line.indexOf(" "));
    const word = (() => { if ((space < 0)) { return line; } else { return line.slice(0, space); } })();
    const hasRest = (space >= 0);
    const rest = (() => { if ((space < 0)) { return ""; } else { return line.slice(__bp_int((space + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:119:60"), null); } })();
    if ((hasRest && (rest === ""))) { return fail(n, "a record's text is never empty (an empty output line is `out` alone)"); }
    const count = refusals.length;
    const last = __bp_array_at(refusals, __bp_int((count - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:123:48"));
    if ((word === "refused")) { if (((phase > 1) && (phase !== 6))) { return fail(n, "`refused` comes before any output"); } phase = 6; if ((!hasRest)) { return fail(n, "`refused` names the compiler's message"); } refusals = refusals.concat([new Refusal(rest, null, null, [])]); } else { if ((word === "at")) { if ((!hasRest)) { return fail(n, "`at` names `<file>:<line>:<col>`"); } if ((((phase !== 6) || (count === 0)) || (last?.at != null))) { return fail(n, "`at` follows its `refused` line"); } refusals = refusals.slice(0, __bp_int((count - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:137:33")).concat([withAt((() => { const __bp_nullish = last; if (__bp_nullish != null) { return __bp_nullish; } else { return new Refusal("", null, null, []); } })(), rest)]); } else { if ((word === "label")) { if ((!hasRest)) { return fail(n, "`label` names the text printed beside the caret"); } if (((((phase !== 6) || (count === 0)) || (last?.at == null)) || (last?.label != null))) { return fail(n, "`label` follows its `at` line"); } refusals = refusals.slice(0, __bp_int((count - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:148:33")).concat([withLabel((() => { const __bp_nullish = last; if (__bp_nullish != null) { return __bp_nullish; } else { return new Refusal("", null, null, []); } })(), rest)]); } else { if ((word === "from")) { if ((!hasRest)) { return fail(n, "`from` names `<file>:<line>:<col>`"); } if ((((phase !== 6) || (count === 0)) || (last?.at == null))) { return fail(n, "`from` follows its `at` line"); } refusals = refusals.slice(0, __bp_int((count - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:155:33")).concat([withFrame((() => { const __bp_nullish = last; if (__bp_nullish != null) { return __bp_nullish; } else { return new Refusal("", null, null, []); } })(), rest)]); } else { if ((word === "build")) { if ((phase === 6)) { return fail(n, "`build` comes before `refused`: nothing prints after a refusal"); } if ((phase > 1)) { return fail(n, "`build` comes before `out`, `no-final-newline`, `abort` and `stderr`"); } phase = 1; build = build.concat([rest]); } else { if ((word === "out")) { if ((count > 0)) { return fail(n, "a refused module prints nothing"); } if ((phase > 2)) { return fail(n, "`out` comes before `no-final-newline`, `abort` and `stderr`"); } phase = 2; stdout = ((stdout + rest) + "\n"); lastOutEmpty = (!hasRest); } else { if ((word === "no-final-newline")) { if (hasRest) { return fail(n, "`no-final-newline` takes no text"); } if ((phase !== 2)) { return fail(n, "`no-final-newline` follows the last `out` line"); } if (lastOutEmpty) { return fail(n, "`no-final-newline` after an empty `out` line has one spelling: drop both"); } stdout = stdout.slice(0, __bp_int((__bp_str_length(stdout) - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:177:52")); phase = 3; } else { if ((word === "abort")) { if (hasRest) { return fail(n, "`abort` takes no text — the exit status is never pinned"); } if ((count > 0)) { return fail(n, "a refused module does not run"); } if ((phase > 3)) { return fail(n, "`abort` is written once, after the output"); } abort = true; phase = 4; } else { if ((word === "stderr")) { if ((!hasRest)) { return fail(n, "`stderr` names the text the abort's stderr contains"); } if ((!abort)) { return fail(n, "`stderr` names an abort: it follows `abort`"); } phase = 5; stderr = stderr.concat([rest]); } else { return fail(n, "unknown record (refused, at, label, from, build, out, no-final-newline, abort, stderr)"); } } } } } } } } }
}
    const snap = new Snap(refusals, build, stdout, abort, stderr);
    // One spelling: whatever the rules above let through must render back.;
    if ((render(snap) !== text)) { return fail(n, "not the canonical spelling of its records"); }
    return ({ ok: snap });
}
exports.parse = parse;

function record(word, text) {
    return (() => { if ((text === "")) { return (word + "\n"); } else { return (((word + " ") + text) + "\n"); } })();
}

/** The one spelling of `snap`. */

function render(snap) {
    let out = (HEADER + "\n");
    for (const b of snap.build) {
    out = (out + record("build", b));
}
    for (const r of snap.refusals) {
    out = (((out + "refused ") + r.message) + "\n");
    (() => { const at = r.at; if (at != null) { return out = (((out + "at ") + at) + "\n"); } })();
    (() => { const l = r.label; if (l != null) { return out = (((out + "label ") + l) + "\n"); } })();
    for (const f of r.frames) {
    out = (((out + "from ") + f) + "\n");
}
}
    (() => { if ((snap.stdout !== "")) { const ends = snap.stdout.endsWith("\n"); const body = (() => { if (ends) { return snap.stdout.slice(0, __bp_int((__bp_str_length(snap.stdout) - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:230:53")); } else { return snap.stdout; } })(); for (const line of body.split("\n")) {
    out = (out + record("out", line));
} return (() => { if ((!ends)) { return out = (out + "no-final-newline\n"); } })(); } })();
    (() => { if (snap.abort) { return out = (out + "abort\n"); } })();
    for (const s of snap.stderr) {
    out = (((out + "stderr ") + s) + "\n");
}
    return out;
}
exports.render = render;

function sameLines(a, b) {
    if ((a.length !== b.length)) { return false; }
    let i = 0;
    while ((i < a.length)) {
    if ((!__bp_eq(((() => { const __bp_nullish = __bp_array_at(a, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()), ((() => { const __bp_nullish = __bp_array_at(b, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()), 0))) { return false; }
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:250:15");
}
    return true;
}

function sameRefusal(e, o) {
    return ((((e.message === o.message) && (e.at === o.at)) && (e.label === o.label)) && sameLines(e.frames, o.frames));
}

/** Whether the observed answer is the accepted one: the refusals, the build */

/** lines, the output and the abort equal, and every `stderr` claim contained in */

/** `observedStderr`. */

function matches(expected, observed, observedStderr) {
    if ((expected.refusals.length !== observed.refusals.length)) { return false; }
    let i = 0;
    while ((i < expected.refusals.length)) {
    const e = (() => { const __bp_nullish = __bp_array_at(expected.refusals, i); if (__bp_nullish != null) { return __bp_nullish; } else { return new Refusal("", null, null, []); } })();
    const o = (() => { const __bp_nullish = __bp_array_at(observed.refusals, i); if (__bp_nullish != null) { return __bp_nullish; } else { return new Refusal("", null, null, []); } })();
    if ((!sameRefusal(e, o))) { return false; }
    i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:272:15");
}
    if ((!sameLines(expected.build, observed.build))) { return false; }
    if ((expected.stdout !== observed.stdout)) { return false; }
    if ((expected.abort !== observed.abort)) { return false; }
    return expected.stderr.all((s) => {
    return observedStderr.includes(s);
});
}
exports.matches = matches;

/** The candidate for an observed answer: what it was, plus the accepted file's */

/** `stderr` claims that still hold (a candidate never invents one). */

function candidate(expected, observed, observedStderr) {
    let kept = [];
    (() => { if (observed.abort) { return (() => { const e = expected; if (e != null) { return kept = e.stderr.filter((s) => {
    return observedStderr.includes(s);
}); } })(); } })();
    return new Snap(observed.refusals, observed.build, observed.stdout, observed.abort, kept);
}
exports.candidate = candidate;

function splitLines(text) {
    let text$sp = null;
    if ((text === "")) { return []; }
    const body = (() => { if (text.endsWith("\n")) { return text.slice(0, __bp_int((((text$sp ??= __bp_has_surrogate(text)) ? __bp_str_length(text) : text.length) - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:295:35")); } else { return text; } })();
    return body.split("\n");
}

/** A line diff of `before` against `after`: `- ` a line only `before` has, `+ ` */

/** a line only `after` has, `  ` a line both keep (longest common subsequence). */

function diff(before, after) {
    const a = splitLines(before);
    const b = splitLines(after);
    // rows[i][j]: the common length of a[i..] and b[j..], built from the last row up.;
    let below = Array.repeat(0, __bp_int((b.length + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:307:49"));
    let rows = [below];
    let i = a.length;
    while ((i > 0)) {
    i = __bp_int((i - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:311:15");
    let row = [0];
    let j = b.length;
    while ((j > 0)) {
    j = __bp_int((j - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:315:19");
    // `row` holds, reversed, the cells j+1 … b.length of this row.;
    const right = (() => { const __bp_nullish = __bp_array_at(row, 0); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
    const cell = (() => { if (__bp_eq(((() => { const __bp_nullish = __bp_array_at(a, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()), ((() => { const __bp_nullish = __bp_array_at(b, j); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })()), 0)) { return __bp_int((((() => { const __bp_nullish = __bp_array_at(below, __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:319:29")); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })()) + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:319:40"); } else { return (() => { if ((((() => { const __bp_nullish = __bp_array_at(below, j); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })()) > right)) { return (() => { const __bp_nullish = __bp_array_at(below, j); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })(); } else { return right; } })(); } })();
    row = row.prepend(cell);
}
    below = row;
    rows = rows.prepend(row);
}
    let out = "";
    i = 0;
    let j = 0;
    while (((i < a.length) || (j < b.length))) {
    const ai = (() => { const __bp_nullish = __bp_array_at(a, i); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    const bj = (() => { const __bp_nullish = __bp_array_at(b, j); if (__bp_nullish != null) { return __bp_nullish; } else { return ""; } })();
    (() => { if ((((i < a.length) && (j < b.length)) && __bp_eq(ai, bj, 0))) { out = (((out + "  ") + ai) + "\n"); i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:336:19"); return j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:337:19"); } else { return (() => { if (((i < a.length) && (((j === b.length) || (lcs(rows, __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:339:46"), j) >= lcs(rows, i, __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:339:72"))))))) { out = (((out + "- ") + ai) + "\n"); return i = __bp_int((i + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:341:19"); } else { out = (((out + "+ ") + bj) + "\n"); return j = __bp_int((j + 1), -2147483648, 2147483647, "+ on i32 at src/records.bp:344:19"); } })(); } })();
}
    return out;
}
exports.diff = diff;

function lcs(rows, i, j) {
    return (() => { const __bp_nullish = __bp_array_at(((() => { const __bp_nullish = __bp_array_at(rows, i); if (__bp_nullish != null) { return __bp_nullish; } else { return []; } })()), j); if (__bp_nullish != null) { return __bp_nullish; } else { return 0; } })();
}

/** Parse the records of one section's body (no header; an empty body is the empty answer). */

/** A malformed body answers its 1-based line within the body and the reason. */

function parseBody(body) {
    try {
        const snap = (() => { const _try0 = parse(((HEADER + "\n") + body)); if ("error" in _try0) { const m = _try0.error; return ((() => {
        const _s = true;
        {
            throw ({ __bp_try: ({ error: new Malformed((() => { if ((m.line > 1)) { return __bp_int((m.line - 1), -2147483648, 2147483647, "- on i32 at src/records.bp:359:20"); } else { return 1; } })(), m.reason) }) });
        }
    })()); } return _try0.ok; })();
        return ({ ok: snap });
    } catch (__e) {
        if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
        throw __e;
    }
}
exports.parseBody = parseBody;

/** The one spelling of a section's body: `render` without the header line. */

function renderBody(snap) {
    const header = (HEADER + "\n");
    let header$sp = null;
    return render(snap).slice(((header$sp ??= __bp_has_surrogate(header)) ? __bp_str_length(header) : header.length), null);
}
exports.renderBody = renderBody;

Object.defineProperty(exports, "__bp_priv__", { value: { HEADER, NEW_SUFFIX, Refusal, Snap, Malformed, fail, withAt, withLabel, withFrame, parse, record, render, sameLines, sameRefusal, matches, candidate, splitLines, diff, lcs, parseBody, renderBody } });
