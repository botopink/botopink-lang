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

const __bp_run__bp_load__cases__compiler_decorator_three_kinds = () => { const __p = require.resolve("./bp_load__cases__compiler_decorator_three_kinds/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__decorator_member_captures = () => { const __p = require.resolve("./bp_load__cases__decorator_member_captures/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__external_library_source_annotation = () => { const __p = require.resolve("./bp_load__cases__external_library_source_annotation/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__external_library_source_beside_emit = () => { const __p = require.resolve("./bp_load__cases__external_library_source_beside_emit/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__external_library_source_beside_emit_split = () => { const __p = require.resolve("./bp_load__cases__external_library_source_beside_emit_split/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__external_library_source_beside_member = () => { const __p = require.resolve("./bp_load__cases__external_library_source_beside_member/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__init_executor_before_main = () => { const __p = require.resolve("./bp_load__cases__init_executor_before_main/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__type_param_generic_form = () => { const __p = require.resolve("./bp_load__cases__type_param_generic_form/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

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

const { buildOutput: __bp_ns_adapter__buildOutput, frames: __bp_ns_adapter__frames, ranOf: __bp_ns_adapter__ranOf, target: __bp_ns_adapter__target } = require("./conformance-lib/adapter.js");
const { finish: __bp_ns_candidate__finish } = require("./conformance-lib/candidate.js");
const { ranAnswer: __bp_ns_observe__ranAnswer, refusalOf: __bp_ns_observe__refusalOf, refusedAnswer: __bp_ns_observe__refusedAnswer } = require("./conformance-lib/observe.js");

/** The snapshot, read as a build input (decision 989 (5)). */

const accepted = "botopink-cell 2\n== compiler_decorator_three_kinds\nout NEGATIVE BALANCE Account positive\nout 0\nout negative balance\nout negative balance (positive)\n== decorator_member_captures\nout 0\nout Signup: invalid\n== external_library_source_annotation\nout [3, 2, 1]\n== external_library_source_beside_emit\nout hi\nout [3, 2, 1]\n== external_library_source_beside_emit_split\nout hi\nout [3, 2, 1]\n== external_library_source_beside_member\nout tagged\nout [3, 2, 1]\n== builtin_module_not_lowered\nrefused error: builtin-not-lowered: `@module()` is declared but no target lowers it\nat src/main.bp:8:13\n== compiler_output_outside_decorator\nrefused error: compiler-output-outside-decorator: `compiler.setMeta` writes to the annotated declaration, and only a decorator has one\nat src/main.bp:11:14\n== declare_in_behavior\nrefused error: declare-in-behavior: `Greeter.greet` is a `declare fn` inside a behavior — a behavior declares a member's signature, or a `default fn` with a body\nat src/main.bp:7:16\n== declare_without_implementation\nrefused error: declare-without-implementation: `now` is a bodyless `declare fn`, and no annotation implements it\nat src/main.bp:6:12\n== declare_without_implementation_method\nrefused error: declare-without-implementation: `Repo.find` is a bodyless `declare fn`, and no annotation implements it\nat src/main.bp:7:20\n== declare_without_implementation_static\nrefused error: declare-without-implementation: `Clock.ticks` is a bodyless `declare fn`, and no annotation implements it\nat src/main.bp:7:20\n== implementation_twice\nrefused error: implementation-twice: `magnitude` is implemented twice for `.JavaScript` — one implementation per target\nat src/main.bp:7:3\n== removed_type_bare_param\nrefused error[removed-type-bare-param]: the type of a type is written `type<T>`\nat src/main.bp:6:29\nlabel write `type<T>`\n== type_param_binds_mismatch\nrefused error: type mismatch: `#[provides]`'s `t` binds `T`, which is `i32` here, to `string`\nat src/main.bp:13:12\n== typeinfo_of_value\nrefused error: typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none\nat src/main.bp:10:38\n== init_executor_before_main\nout page home\nout again home\nout layout Shell\nout again Shell\nout view Shell\nout again Shell\nout hello\nout greet\nout main\nout home\nout t\nout banner\n== type_param_generic_form\nout greeting\nout hello\nout 3\nout 9\n";

exports.accepted = accepted;

/** What each case answered, in the order the cases ran. */

let answers = [];

exports.answers = answers;

/** One case, expanded where it is called (decision 808 (2)): a refused load answers its */

/** diagnostics, a loaded one runs and answers its output. */

const __bp_comptime_0_at = 0;

exports.__bp_comptime_0_at = __bp_comptime_0_at;

function __bp_executor_0() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__compiler_decorator_three_kinds));
    answers = answers.concat([__bp_ns_observe__ranAnswer("compiler_decorator_three_kinds", __bp_ns_adapter__buildOutput((__bp_load_module("compiler_decorator_three_kinds", "cases/compiler_decorator_three_kinds", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_0 = __bp_executor_0;

const __bp_init_0 = __bp_executor_0();

exports.__bp_init_0 = __bp_init_0;

function __bp_executor_1() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__decorator_member_captures));
    answers = answers.concat([__bp_ns_observe__ranAnswer("decorator_member_captures", __bp_ns_adapter__buildOutput((__bp_load_module("decorator_member_captures", "cases/decorator_member_captures", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_1 = __bp_executor_1;

const __bp_init_1 = __bp_executor_1();

exports.__bp_init_1 = __bp_init_1;

function __bp_executor_2() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__external_library_source_annotation));
    answers = answers.concat([__bp_ns_observe__ranAnswer("external_library_source_annotation", __bp_ns_adapter__buildOutput((__bp_load_module("external_library_source_annotation", "cases/external_library_source_annotation", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_2 = __bp_executor_2;

const __bp_init_2 = __bp_executor_2();

exports.__bp_init_2 = __bp_init_2;

function __bp_executor_3() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__external_library_source_beside_emit));
    answers = answers.concat([__bp_ns_observe__ranAnswer("external_library_source_beside_emit", __bp_ns_adapter__buildOutput((__bp_load_module("external_library_source_beside_emit", "cases/external_library_source_beside_emit", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_3 = __bp_executor_3;

const __bp_init_3 = __bp_executor_3();

exports.__bp_init_3 = __bp_init_3;

function __bp_executor_4() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__external_library_source_beside_emit_split));
    answers = answers.concat([__bp_ns_observe__ranAnswer("external_library_source_beside_emit_split", __bp_ns_adapter__buildOutput((__bp_load_module("external_library_source_beside_emit_split", "cases/external_library_source_beside_emit_split", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_4 = __bp_executor_4;

const __bp_init_4 = __bp_executor_4();

exports.__bp_init_4 = __bp_init_4;

function __bp_executor_5() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__external_library_source_beside_member));
    answers = answers.concat([__bp_ns_observe__ranAnswer("external_library_source_beside_member", __bp_ns_adapter__buildOutput((__bp_load_module("external_library_source_beside_member", "cases/external_library_source_beside_member", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_5 = __bp_executor_5;

const __bp_init_5 = __bp_executor_5();

exports.__bp_init_5 = __bp_init_5;

function __bp_executor_6() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("builtin_module_not_lowered", "cases/builtin_module_not_lowered", ""), [new Diagnostic("builtin-not-lowered", "builtin-not-lowered: `@module()` is declared but no target lowers it", "src/main.bp", 8, 13, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("builtin_module_not_lowered", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("builtin_module_not_lowered", "cases/builtin_module_not_lowered", ""), [new Diagnostic("builtin-not-lowered", "builtin-not-lowered: `@module()` is declared but no target lowers it", "src/main.bp", 8, 13, null, [])])).module), refusals)]);
}
exports.__bp_executor_6 = __bp_executor_6;

const __bp_init_6 = __bp_executor_6();

exports.__bp_init_6 = __bp_init_6;

function __bp_executor_7() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("compiler_output_outside_decorator", "cases/compiler_output_outside_decorator", ""), [new Diagnostic("compiler-output-outside-decorator", "compiler-output-outside-decorator: `compiler.setMeta` writes to the annotated declaration, and only a decorator has one", "src/main.bp", 11, 14, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("compiler_output_outside_decorator", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("compiler_output_outside_decorator", "cases/compiler_output_outside_decorator", ""), [new Diagnostic("compiler-output-outside-decorator", "compiler-output-outside-decorator: `compiler.setMeta` writes to the annotated declaration, and only a decorator has one", "src/main.bp", 11, 14, null, [])])).module), refusals)]);
}
exports.__bp_executor_7 = __bp_executor_7;

const __bp_init_7 = __bp_executor_7();

exports.__bp_init_7 = __bp_init_7;

function __bp_executor_8() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("declare_in_behavior", "cases/declare_in_behavior", ""), [new Diagnostic("declare-in-behavior", "declare-in-behavior: `Greeter.greet` is a `declare fn` inside a behavior — a behavior declares a member's signature, or a `default fn` with a body", "src/main.bp", 7, 16, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("declare_in_behavior", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("declare_in_behavior", "cases/declare_in_behavior", ""), [new Diagnostic("declare-in-behavior", "declare-in-behavior: `Greeter.greet` is a `declare fn` inside a behavior — a behavior declares a member's signature, or a `default fn` with a body", "src/main.bp", 7, 16, null, [])])).module), refusals)]);
}
exports.__bp_executor_8 = __bp_executor_8;

const __bp_init_8 = __bp_executor_8();

exports.__bp_init_8 = __bp_init_8;

function __bp_executor_9() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("declare_without_implementation", "cases/declare_without_implementation", ""), [new Diagnostic("declare-without-implementation", "declare-without-implementation: `now` is a bodyless `declare fn`, and no annotation implements it", "src/main.bp", 6, 12, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("declare_without_implementation", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("declare_without_implementation", "cases/declare_without_implementation", ""), [new Diagnostic("declare-without-implementation", "declare-without-implementation: `now` is a bodyless `declare fn`, and no annotation implements it", "src/main.bp", 6, 12, null, [])])).module), refusals)]);
}
exports.__bp_executor_9 = __bp_executor_9;

const __bp_init_9 = __bp_executor_9();

exports.__bp_init_9 = __bp_init_9;

function __bp_executor_10() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("declare_without_implementation_method", "cases/declare_without_implementation_method", ""), [new Diagnostic("declare-without-implementation", "declare-without-implementation: `Repo.find` is a bodyless `declare fn`, and no annotation implements it", "src/main.bp", 7, 20, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("declare_without_implementation_method", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("declare_without_implementation_method", "cases/declare_without_implementation_method", ""), [new Diagnostic("declare-without-implementation", "declare-without-implementation: `Repo.find` is a bodyless `declare fn`, and no annotation implements it", "src/main.bp", 7, 20, null, [])])).module), refusals)]);
}
exports.__bp_executor_10 = __bp_executor_10;

const __bp_init_10 = __bp_executor_10();

exports.__bp_init_10 = __bp_init_10;

function __bp_executor_11() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("declare_without_implementation_static", "cases/declare_without_implementation_static", ""), [new Diagnostic("declare-without-implementation", "declare-without-implementation: `Clock.ticks` is a bodyless `declare fn`, and no annotation implements it", "src/main.bp", 7, 20, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("declare_without_implementation_static", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("declare_without_implementation_static", "cases/declare_without_implementation_static", ""), [new Diagnostic("declare-without-implementation", "declare-without-implementation: `Clock.ticks` is a bodyless `declare fn`, and no annotation implements it", "src/main.bp", 7, 20, null, [])])).module), refusals)]);
}
exports.__bp_executor_11 = __bp_executor_11;

const __bp_init_11 = __bp_executor_11();

exports.__bp_init_11 = __bp_init_11;

function __bp_executor_12() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("implementation_twice", "cases/implementation_twice", ""), [new Diagnostic("implementation-twice", "implementation-twice: `magnitude` is implemented twice for `.JavaScript` — one implementation per target", "src/main.bp", 7, 3, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("implementation_twice", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("implementation_twice", "cases/implementation_twice", ""), [new Diagnostic("implementation-twice", "implementation-twice: `magnitude` is implemented twice for `.JavaScript` — one implementation per target", "src/main.bp", 7, 3, null, [])])).module), refusals)]);
}
exports.__bp_executor_12 = __bp_executor_12;

const __bp_init_12 = __bp_executor_12();

exports.__bp_init_12 = __bp_init_12;

function __bp_executor_13() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("removed_type_bare_param", "cases/removed_type_bare_param", ""), [new Diagnostic("removed-type-bare-param", "the type of a type is written `type<T>`", "src/main.bp", 6, 29, "write `type<T>`", [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("removed_type_bare_param", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("removed_type_bare_param", "cases/removed_type_bare_param", ""), [new Diagnostic("removed-type-bare-param", "the type of a type is written `type<T>`", "src/main.bp", 6, 29, "write `type<T>`", [])])).module), refusals)]);
}
exports.__bp_executor_13 = __bp_executor_13;

const __bp_init_13 = __bp_executor_13();

exports.__bp_init_13 = __bp_init_13;

function __bp_executor_14() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("type_param_binds_mismatch", "cases/type_param_binds_mismatch", ""), [new Diagnostic("", "type mismatch: `#[provides]`'s `t` binds `T`, which is `i32` here, to `string`", "src/main.bp", 13, 12, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("type_param_binds_mismatch", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("type_param_binds_mismatch", "cases/type_param_binds_mismatch", ""), [new Diagnostic("", "type mismatch: `#[provides]`'s `t` binds `T`, which is `i32` here, to `string`", "src/main.bp", 13, 12, null, [])])).module), refusals)]);
}
exports.__bp_executor_14 = __bp_executor_14;

const __bp_init_14 = __bp_executor_14();

exports.__bp_init_14 = __bp_init_14;

function __bp_executor_15() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("typeinfo_of_value", "cases/typeinfo_of_value", ""), [new Diagnostic("typeinfo-unknown-declaration", "typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none", "src/main.bp", 10, 38, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("typeinfo_of_value", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("typeinfo_of_value", "cases/typeinfo_of_value", ""), [new Diagnostic("typeinfo-unknown-declaration", "typeinfo-unknown-declaration: `@typeInfo` reflects a declaration this module declares or imports, and this names none", "src/main.bp", 10, 38, null, [])])).module), refusals)]);
}
exports.__bp_executor_15 = __bp_executor_15;

const __bp_init_15 = __bp_executor_15();

exports.__bp_init_15 = __bp_init_15;

function __bp_executor_16() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__init_executor_before_main));
    answers = answers.concat([__bp_ns_observe__ranAnswer("init_executor_before_main", __bp_ns_adapter__buildOutput((__bp_load_module("init_executor_before_main", "cases/init_executor_before_main", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_16 = __bp_executor_16;

const __bp_init_16 = __bp_executor_16();

exports.__bp_init_16 = __bp_init_16;

function __bp_executor_17() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__type_param_generic_form));
    answers = answers.concat([__bp_ns_observe__ranAnswer("type_param_generic_form", __bp_ns_adapter__buildOutput((__bp_load_module("type_param_generic_form", "cases/type_param_generic_form", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_17 = __bp_executor_17;

const __bp_init_17 = __bp_executor_17();

exports.__bp_init_17 = __bp_init_17;

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

Object.defineProperty(exports, "__bp_priv__", { value: { RunFailureKind, Asset, __bp_run__bp_load__cases__compiler_decorator_three_kinds, __bp_run__bp_load__cases__decorator_member_captures, __bp_run__bp_load__cases__external_library_source_annotation, __bp_run__bp_load__cases__external_library_source_beside_emit, __bp_run__bp_load__cases__external_library_source_beside_emit_split, __bp_run__bp_load__cases__external_library_source_beside_member, __bp_run__bp_load__cases__init_executor_before_main, __bp_run__bp_load__cases__type_param_generic_form, Observed, Refusal, Diagnostic, Module, Refused, __bp_run_attempt, __bp_loaded, __bp_load_module, __bp_run_failure, RunFailure, __bp_run, __bp_run_async, __bp_run_none, __bp_run_async_none, __bp_ns_adapter__buildOutput, __bp_ns_adapter__frames, __bp_ns_adapter__ranOf, __bp_ns_adapter__target, __bp_ns_candidate__finish, __bp_ns_observe__ranAnswer, __bp_ns_observe__refusalOf, __bp_ns_observe__refusedAnswer, accepted, answers, __bp_comptime_0_at, __bp_executor_0, __bp_init_0, __bp_executor_1, __bp_init_1, __bp_executor_2, __bp_init_2, __bp_executor_3, __bp_init_3, __bp_executor_4, __bp_init_4, __bp_executor_5, __bp_init_5, __bp_executor_6, __bp_init_6, __bp_executor_7, __bp_init_7, __bp_executor_8, __bp_init_8, __bp_executor_9, __bp_init_9, __bp_executor_10, __bp_init_10, __bp_executor_11, __bp_init_11, __bp_executor_12, __bp_init_12, __bp_executor_13, __bp_init_13, __bp_executor_14, __bp_init_14, __bp_executor_15, __bp_init_15, __bp_executor_16, __bp_init_16, __bp_executor_17, __bp_init_17, main } });
