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

function __bp_task(p) {
    const t = p.then((r) => { if (r != null && "error" in r) { t.__bp_failure = true; throw r.error; } return (r == null) ? r : r.ok; });
    t.__bp_fails = true;
    t.catch(() => {});
    return t;
}

function __bp_await(t) {
    return (t != null && t.__bp_fails === true) ? t.then((v) => ({ ok: v }), (e) => { if (t.__bp_failure === true) { return { error: e }; } throw e; }) : t;
}

const { RunFailureKind } = require("./std/compiler.js");

class Asset {
    constructor(path, bytes, size, hash) {
        this.path = path;
        this.bytes = bytes;
        this.size = size;
        this.hash = hash;
    }
}
Asset.prototype.__bp = "Asset";

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

const { Observed } = require("./conformance-lib/observe.js");
const { Refusal } = require("./conformance-lib/records.js");

const { Diagnostic, Module, Refused } = require("./std/compiler.js");
const { attempt: __bp_run_attempt } = require("./std/failure.js");

function __bp_loaded(m, ds) {
    if ((ds.length > 0)) { return ({ error: new Refused(m, ds) }); }
    return ({ ok: m });
}
exports.__bp_loaded = __bp_loaded;

function __bp_load_module(name, path, buildOutput) {
    return Module.of(name, path, buildOutput);
}
exports.__bp_load_module = __bp_load_module;

const __bp_run_failure = require("./std/failure.js");
const { RunFailure } = require("./std/compiler.js");

function __bp_run(f) {
    try {
        const open = Module.captureOpen();
        const answer = __bp_run_attempt(f);
        const output = Module.captureClose(open);
        const _case0 = (() => {
        const _s = answer;
        if ("ok" in _s) {
            const ran = _s.ok;
            return (() => {
        const _s = ran;
        if ("ok" in _s) {
            throw ({ __bp_try: ({ ok: output }) });
        }
        if ("error" in _s) {
            const m = _s.error;
            if (m.startsWith("\0bp-off:X")) { throw ({ __bp_try: ({ error: new RunFailure(RunFailureKind.Excluded, m.slice(9, null), output) }) }); }
            if (m.startsWith("\0bp-off:R")) { throw ({ __bp_try: ({ error: new RunFailure(RunFailureKind.Refused, m.slice(9, null), output) }) }); }
            throw ({ __bp_try: ({ error: new RunFailure(RunFailureKind.Failed, m, output) }) });
        }
        throw new Error("case_clause");
    })();
        }
        if ("error" in _s) {
            const crash = _s.error;
            return ({ __bp_return: true, value: ({ error: new RunFailure(RunFailureKind.Abort, crash.message, output) }) });
        }
        throw new Error("case_clause");
    })();
        if (_case0 && _case0.__bp_return) return _case0.value;
    } catch (__e) {
        if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
        throw __e;
    }
}
exports.__bp_run = __bp_run;

function __bp_run_async(f) {
    return __bp_task((async () => {
        try {
            const open = Module.captureOpen();
            const answer = await __bp_await(__bp_run_failure.attemptTask(f));
            const output = Module.captureClose(open);
            const _case0 = (() => {
            const _s = answer;
            if ("ok" in _s) {
                const ran = _s.ok;
                return (() => {
            const _s = ran;
            if ("ok" in _s) {
                throw ({ __bp_try: ({ ok: output }) });
            }
            if ("error" in _s) {
                const m = _s.error;
                if (m.startsWith("\0bp-off:X")) { throw ({ __bp_try: ({ error: new RunFailure(RunFailureKind.Excluded, m.slice(9, null), output) }) }); }
                if (m.startsWith("\0bp-off:R")) { throw ({ __bp_try: ({ error: new RunFailure(RunFailureKind.Refused, m.slice(9, null), output) }) }); }
                throw ({ __bp_try: ({ error: new RunFailure(RunFailureKind.Failed, m, output) }) });
            }
            throw new Error("case_clause");
        })();
            }
            if ("error" in _s) {
                const crash = _s.error;
                return ({ __bp_return: true, value: ({ error: new RunFailure(RunFailureKind.Abort, crash.message, output) }) });
            }
            throw new Error("case_clause");
        })();
            if (_case0 && _case0.__bp_return) return _case0.value;
        } catch (__e) {
            if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
            throw __e;
        }
    })());
}
exports.__bp_run_async = __bp_run_async;

function __bp_run_none() {
    return ({ ok: null });
}
exports.__bp_run_none = __bp_run_none;

function __bp_run_async_none() {
    return __bp_task((async () => {
        return ({ ok: null });
    })());
}
exports.__bp_run_async_none = __bp_run_async_none;

//// A module checking itself (decision 989): each case is a package under `cases/`, loaded at build,

//// run in this program and compared with its section of `snapshot/main.snap`; a difference writes

//// `snapshot/main.snap.new` and `main` answers `Error`. Nothing here accepts a candidate.

const { buildOutput: __bp_ns_adapter__buildOutput, target: __bp_ns_adapter__target, frames: __bp_ns_adapter__frames, ranOf: __bp_ns_adapter__ranOf } = require("./conformance-lib/adapter.js");
const { finish: __bp_ns_candidate__finish } = require("./conformance-lib/candidate.js");
const { refusedAnswer: __bp_ns_observe__refusedAnswer, refusalOf: __bp_ns_observe__refusalOf, ranAnswer: __bp_ns_observe__ranAnswer } = require("./conformance-lib/observe.js");

/** The snapshot, read as a build input (decision 989 (5)). */

const accepted = "botopink-cell 2\n== decorator_add_member_duplicate\nrefused error: decorator-member-duplicate: `#[sized]` adds `size` to `Box`, which already has a member called `size`\nat src/main.bp:12:3\n== decorator_add_member_not_one\nrefused error: decorator-member-not-one-fn: `#[twice]` added a member to `Pair` that is not one `fn`: `pub fn a() -> i32 { return 1; } pub fn b() -> i32 { return 2; }`\nat src/main.bp:11:3\n== decorator_add_member_on_fn\nrefused error: decorator-member-without-type: `#[helper]` on the function `work` calls `decl.addMember`, and a member belongs to a type\nat src/main.bp:13:3\n== decorator_add_type_duplicate\nrefused error: decorator-type-duplicate: `#[table]` declares `City.Columns`, and `City` already has an associated type `Columns`\nat src/main.bp:16:3\n== decorator_add_type_name\nrefused error: decorator-type-name: `#[entity]` names an associated type of `City` `columns`, which is not a type name\nat src/main.bp:11:3\n== decorator_add_type_not_one\nrefused error: decorator-type-not-one-type: `#[entity]` declares `City.Columns` from a source that is not one type: `(id: string) fn extra() -> void {}`\nat src/main.bp:11:3\n== decorator_add_type_without_owner\nrefused error: decorator-type-without-owner: `#[helper]` on the function `work` calls `decl.addType`, and an associated type belongs to a type\nat src/main.bp:10:3\n== decorator_member_unknown\nrefused error: unknown-associated-fn: `City` has no associated fn `revisions`\nat src/main.bp:23:16\n== decorator_meta_on_member\nrefused error: decorator-meta-on-member: `#[column]` on the field `name` calls `decl.setMeta`, and meta describes a top-level declaration\nat src/main.bp:11:13\n== typeinfo_all_arguments\nrefused error: typeinfo-all-arguments: `@TypeInfo.all` takes labelled arguments, and this one has none\nat src/main.bp:11:11\n== typeinfo_all_mixed\nrefused error: typeinfo-all-mixed: `#[tagged]` is carried by the function `job` and by the type `Box`, and one query answers one kind of value\nat src/main.bp:19:11\n== typeinfo_all_needs_member\nrefused error: typeinfo-all-needs-member: `#[component]` is carried by the type `Box`, and a type is no value: name the associated fn each entry calls\nat src/main.bp:16:11\n== typeinfo_unknown_declaration\nrefused error: typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none\nat src/main.bp:7:38\n== typeinfo_all_imported\nrefused error: typeinfo-all-imported: `catalog` reads `@TypeInfo.all`, so it answers for the whole program and no module imports it\nat src/main.bp:7:9\n";

exports.accepted = accepted;

/** What each case answered, in the order the cases ran. */

let answers = [];

exports.answers = answers;

/** One case, expanded where it is called (decision 808 (2)): a refused load answers its */

/** diagnostics, a loaded one runs and answers its output. */

const __bp_comptime_0_at = 0;

exports.__bp_comptime_0_at = __bp_comptime_0_at;

function __bp_executor_0() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("decorator_add_member_duplicate", "cases/decorator_add_member_duplicate", ""), [new Diagnostic("decorator-member-duplicate", "decorator-member-duplicate: `#[sized]` adds `size` to `Box`, which already has a member called `size`", "src/main.bp", 12, 3, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("decorator_add_member_duplicate", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("decorator_add_member_duplicate", "cases/decorator_add_member_duplicate", ""), [new Diagnostic("decorator-member-duplicate", "decorator-member-duplicate: `#[sized]` adds `size` to `Box`, which already has a member called `size`", "src/main.bp", 12, 3, null, [])])).module), refusals)]);
}
exports.__bp_executor_0 = __bp_executor_0;

const __bp_init_0 = __bp_executor_0();

exports.__bp_init_0 = __bp_init_0;

function __bp_executor_1() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("decorator_add_member_not_one", "cases/decorator_add_member_not_one", ""), [new Diagnostic("decorator-member-not-one-fn", "decorator-member-not-one-fn: `#[twice]` added a member to `Pair` that is not one `fn`: `pub fn a() -> i32 { return 1; } pub fn b() -> i32 { return 2; }`", "src/main.bp", 11, 3, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("decorator_add_member_not_one", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("decorator_add_member_not_one", "cases/decorator_add_member_not_one", ""), [new Diagnostic("decorator-member-not-one-fn", "decorator-member-not-one-fn: `#[twice]` added a member to `Pair` that is not one `fn`: `pub fn a() -> i32 { return 1; } pub fn b() -> i32 { return 2; }`", "src/main.bp", 11, 3, null, [])])).module), refusals)]);
}
exports.__bp_executor_1 = __bp_executor_1;

const __bp_init_1 = __bp_executor_1();

exports.__bp_init_1 = __bp_init_1;

function __bp_executor_2() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("decorator_add_member_on_fn", "cases/decorator_add_member_on_fn", ""), [new Diagnostic("decorator-member-without-type", "decorator-member-without-type: `#[helper]` on the function `work` calls `decl.addMember`, and a member belongs to a type", "src/main.bp", 13, 3, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("decorator_add_member_on_fn", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("decorator_add_member_on_fn", "cases/decorator_add_member_on_fn", ""), [new Diagnostic("decorator-member-without-type", "decorator-member-without-type: `#[helper]` on the function `work` calls `decl.addMember`, and a member belongs to a type", "src/main.bp", 13, 3, null, [])])).module), refusals)]);
}
exports.__bp_executor_2 = __bp_executor_2;

const __bp_init_2 = __bp_executor_2();

exports.__bp_init_2 = __bp_init_2;

function __bp_executor_3() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("decorator_add_type_duplicate", "cases/decorator_add_type_duplicate", ""), [new Diagnostic("decorator-type-duplicate", "decorator-type-duplicate: `#[table]` declares `City.Columns`, and `City` already has an associated type `Columns`", "src/main.bp", 16, 3, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("decorator_add_type_duplicate", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("decorator_add_type_duplicate", "cases/decorator_add_type_duplicate", ""), [new Diagnostic("decorator-type-duplicate", "decorator-type-duplicate: `#[table]` declares `City.Columns`, and `City` already has an associated type `Columns`", "src/main.bp", 16, 3, null, [])])).module), refusals)]);
}
exports.__bp_executor_3 = __bp_executor_3;

const __bp_init_3 = __bp_executor_3();

exports.__bp_init_3 = __bp_init_3;

function __bp_executor_4() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("decorator_add_type_name", "cases/decorator_add_type_name", ""), [new Diagnostic("decorator-type-name", "decorator-type-name: `#[entity]` names an associated type of `City` `columns`, which is not a type name", "src/main.bp", 11, 3, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("decorator_add_type_name", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("decorator_add_type_name", "cases/decorator_add_type_name", ""), [new Diagnostic("decorator-type-name", "decorator-type-name: `#[entity]` names an associated type of `City` `columns`, which is not a type name", "src/main.bp", 11, 3, null, [])])).module), refusals)]);
}
exports.__bp_executor_4 = __bp_executor_4;

const __bp_init_4 = __bp_executor_4();

exports.__bp_init_4 = __bp_init_4;

function __bp_executor_5() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("decorator_add_type_not_one", "cases/decorator_add_type_not_one", ""), [new Diagnostic("decorator-type-not-one-type", "decorator-type-not-one-type: `#[entity]` declares `City.Columns` from a source that is not one type: `(id: string) fn extra() -> void {}`", "src/main.bp", 11, 3, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("decorator_add_type_not_one", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("decorator_add_type_not_one", "cases/decorator_add_type_not_one", ""), [new Diagnostic("decorator-type-not-one-type", "decorator-type-not-one-type: `#[entity]` declares `City.Columns` from a source that is not one type: `(id: string) fn extra() -> void {}`", "src/main.bp", 11, 3, null, [])])).module), refusals)]);
}
exports.__bp_executor_5 = __bp_executor_5;

const __bp_init_5 = __bp_executor_5();

exports.__bp_init_5 = __bp_init_5;

function __bp_executor_6() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("decorator_add_type_without_owner", "cases/decorator_add_type_without_owner", ""), [new Diagnostic("decorator-type-without-owner", "decorator-type-without-owner: `#[helper]` on the function `work` calls `decl.addType`, and an associated type belongs to a type", "src/main.bp", 10, 3, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("decorator_add_type_without_owner", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("decorator_add_type_without_owner", "cases/decorator_add_type_without_owner", ""), [new Diagnostic("decorator-type-without-owner", "decorator-type-without-owner: `#[helper]` on the function `work` calls `decl.addType`, and an associated type belongs to a type", "src/main.bp", 10, 3, null, [])])).module), refusals)]);
}
exports.__bp_executor_6 = __bp_executor_6;

const __bp_init_6 = __bp_executor_6();

exports.__bp_init_6 = __bp_init_6;

function __bp_executor_7() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("decorator_member_unknown", "cases/decorator_member_unknown", ""), [new Diagnostic("unknown-associated-fn", "unknown-associated-fn: `City` has no associated fn `revisions`", "src/main.bp", 23, 16, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("decorator_member_unknown", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("decorator_member_unknown", "cases/decorator_member_unknown", ""), [new Diagnostic("unknown-associated-fn", "unknown-associated-fn: `City` has no associated fn `revisions`", "src/main.bp", 23, 16, null, [])])).module), refusals)]);
}
exports.__bp_executor_7 = __bp_executor_7;

const __bp_init_7 = __bp_executor_7();

exports.__bp_init_7 = __bp_init_7;

function __bp_executor_8() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("decorator_meta_on_member", "cases/decorator_meta_on_member", ""), [new Diagnostic("decorator-meta-on-member", "decorator-meta-on-member: `#[column]` on the field `name` calls `decl.setMeta`, and meta describes a top-level declaration", "src/main.bp", 11, 13, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("decorator_meta_on_member", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("decorator_meta_on_member", "cases/decorator_meta_on_member", ""), [new Diagnostic("decorator-meta-on-member", "decorator-meta-on-member: `#[column]` on the field `name` calls `decl.setMeta`, and meta describes a top-level declaration", "src/main.bp", 11, 13, null, [])])).module), refusals)]);
}
exports.__bp_executor_8 = __bp_executor_8;

const __bp_init_8 = __bp_executor_8();

exports.__bp_init_8 = __bp_init_8;

function __bp_executor_9() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("typeinfo_all_arguments", "cases/typeinfo_all_arguments", ""), [new Diagnostic("typeinfo-all-arguments", "typeinfo-all-arguments: `@TypeInfo.all` takes labelled arguments, and this one has none", "src/main.bp", 11, 11, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("typeinfo_all_arguments", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("typeinfo_all_arguments", "cases/typeinfo_all_arguments", ""), [new Diagnostic("typeinfo-all-arguments", "typeinfo-all-arguments: `@TypeInfo.all` takes labelled arguments, and this one has none", "src/main.bp", 11, 11, null, [])])).module), refusals)]);
}
exports.__bp_executor_9 = __bp_executor_9;

const __bp_init_9 = __bp_executor_9();

exports.__bp_init_9 = __bp_init_9;

function __bp_executor_10() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("typeinfo_all_mixed", "cases/typeinfo_all_mixed", ""), [new Diagnostic("typeinfo-all-mixed", "typeinfo-all-mixed: `#[tagged]` is carried by the function `job` and by the type `Box`, and one query answers one kind of value", "src/main.bp", 19, 11, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("typeinfo_all_mixed", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("typeinfo_all_mixed", "cases/typeinfo_all_mixed", ""), [new Diagnostic("typeinfo-all-mixed", "typeinfo-all-mixed: `#[tagged]` is carried by the function `job` and by the type `Box`, and one query answers one kind of value", "src/main.bp", 19, 11, null, [])])).module), refusals)]);
}
exports.__bp_executor_10 = __bp_executor_10;

const __bp_init_10 = __bp_executor_10();

exports.__bp_init_10 = __bp_init_10;

function __bp_executor_11() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("typeinfo_all_needs_member", "cases/typeinfo_all_needs_member", ""), [new Diagnostic("typeinfo-all-needs-member", "typeinfo-all-needs-member: `#[component]` is carried by the type `Box`, and a type is no value: name the associated fn each entry calls", "src/main.bp", 16, 11, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("typeinfo_all_needs_member", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("typeinfo_all_needs_member", "cases/typeinfo_all_needs_member", ""), [new Diagnostic("typeinfo-all-needs-member", "typeinfo-all-needs-member: `#[component]` is carried by the type `Box`, and a type is no value: name the associated fn each entry calls", "src/main.bp", 16, 11, null, [])])).module), refusals)]);
}
exports.__bp_executor_11 = __bp_executor_11;

const __bp_init_11 = __bp_executor_11();

exports.__bp_init_11 = __bp_init_11;

function __bp_executor_12() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("typeinfo_unknown_declaration", "cases/typeinfo_unknown_declaration", ""), [new Diagnostic("typeinfo-unknown-declaration", "typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none", "src/main.bp", 7, 38, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("typeinfo_unknown_declaration", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("typeinfo_unknown_declaration", "cases/typeinfo_unknown_declaration", ""), [new Diagnostic("typeinfo-unknown-declaration", "typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none", "src/main.bp", 7, 38, null, [])])).module), refusals)]);
}
exports.__bp_executor_12 = __bp_executor_12;

const __bp_init_12 = __bp_executor_12();

exports.__bp_init_12 = __bp_init_12;

function __bp_executor_13() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("typeinfo_all_imported", "cases/typeinfo_all_imported", ""), [new Diagnostic("typeinfo-all-imported", "typeinfo-all-imported: `catalog` reads `@TypeInfo.all`, so it answers for the whole program and no module imports it", "src/main.bp", 7, 9, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("typeinfo_all_imported", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("typeinfo_all_imported", "cases/typeinfo_all_imported", ""), [new Diagnostic("typeinfo-all-imported", "typeinfo-all-imported: `catalog` reads `@TypeInfo.all`, so it answers for the whole program and no module imports it", "src/main.bp", 7, 9, null, [])])).module), refusals)]);
}
exports.__bp_executor_13 = __bp_executor_13;

const __bp_init_13 = __bp_executor_13();

exports.__bp_init_13 = __bp_init_13;

function main() {
    return __bp_task((async () => {
        return __bp_ns_candidate__finish(accepted, answers, __bp_ns_adapter__target());
    })());
}
exports.main = main;

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { RunFailureKind, Asset, Observed, Refusal, Diagnostic, Module, Refused, __bp_run_attempt, __bp_loaded, __bp_load_module, __bp_run_failure, RunFailure, __bp_run, __bp_run_async, __bp_run_none, __bp_run_async_none, __bp_ns_adapter__buildOutput, __bp_ns_adapter__target, __bp_ns_adapter__frames, __bp_ns_adapter__ranOf, __bp_ns_candidate__finish, __bp_ns_observe__refusedAnswer, __bp_ns_observe__refusalOf, __bp_ns_observe__ranAnswer, accepted, answers, __bp_comptime_0_at, __bp_executor_0, __bp_init_0, __bp_executor_1, __bp_init_1, __bp_executor_2, __bp_init_2, __bp_executor_3, __bp_init_3, __bp_executor_4, __bp_init_4, __bp_executor_5, __bp_init_5, __bp_executor_6, __bp_init_6, __bp_executor_7, __bp_init_7, __bp_executor_8, __bp_init_8, __bp_executor_9, __bp_init_9, __bp_executor_10, __bp_init_10, __bp_executor_11, __bp_init_11, __bp_executor_12, __bp_init_12, __bp_executor_13, __bp_init_13, main } });
