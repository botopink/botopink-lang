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

const __bp_run__bp_load__cases__optional_enum_method_call = () => { const __p = require.resolve("./bp_load__cases__optional_enum_method_call/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_float_function_value = () => { const __p = require.resolve("./bp_load__cases__optional_float_function_value/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_if_null_initializer = () => { const __p = require.resolve("./bp_load__cases__optional_if_null_initializer/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_member_default = () => { const __p = require.resolve("./bp_load__cases__optional_member_default/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_method_absent_receiver = () => { const __p = require.resolve("./bp_load__cases__optional_method_absent_receiver/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_operators = () => { const __p = require.resolve("./bp_load__cases__optional_operators/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_record_method_absent_receiver = () => { const __p = require.resolve("./bp_load__cases__optional_record_method_absent_receiver/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__std_type_field_associated = () => { const __p = require.resolve("./bp_load__cases__std_type_field_associated/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__nullish_default_namespace_call = () => { const __p = require.resolve("./bp_load__cases__nullish_default_namespace_call/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__nullish_optional_call_default = () => { const __p = require.resolve("./bp_load__cases__nullish_optional_call_default/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_array_at_record = () => { const __p = require.resolve("./bp_load__cases__optional_array_at_record/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_call_operator = () => { const __p = require.resolve("./bp_load__cases__optional_call_operator/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_call_param_wasm = () => { const __p = require.resolve("./bp_load__cases__optional_call_param_wasm/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_call_plain_answers = () => { const __p = require.resolve("./bp_load__cases__optional_call_plain_answers/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_chain_absent_array_length = () => { const __p = require.resolve("./bp_load__cases__optional_chain_absent_array_length/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_chain_field_after_call = () => { const __p = require.resolve("./bp_load__cases__optional_chain_field_after_call/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_chain_lambda_array_method = () => { const __p = require.resolve("./bp_load__cases__optional_chain_lambda_array_method/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_chain_lambda_generic = () => { const __p = require.resolve("./bp_load__cases__optional_chain_lambda_generic/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_chain_nested_array = () => { const __p = require.resolve("./bp_load__cases__optional_chain_nested_array/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_chain_present_array_length = () => { const __p = require.resolve("./bp_load__cases__optional_chain_present_array_length/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_chain_record_fields = () => { const __p = require.resolve("./bp_load__cases__optional_chain_record_fields/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_enum_method_absent_receiver = () => { const __p = require.resolve("./bp_load__cases__optional_enum_method_absent_receiver/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

const __bp_run__bp_load__cases__optional_index_record_field = () => { const __p = require.resolve("./bp_load__cases__optional_index_record_field/main.js"); const __d = require("path").dirname(__p) + require("path").sep; for (const __k of Object.keys(require.cache)) { if (__k.startsWith(__d)) { delete require.cache[__k]; } } return require(__p).__bp_loaded_main(); };

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

const { buildOutput: __bp_ns_adapter__buildOutput, ranOf: __bp_ns_adapter__ranOf, frames: __bp_ns_adapter__frames, target: __bp_ns_adapter__target } = require("./conformance-lib/adapter.js");
const { finish: __bp_ns_candidate__finish } = require("./conformance-lib/candidate.js");
const { refusalOf: __bp_ns_observe__refusalOf, ranAnswer: __bp_ns_observe__ranAnswer, refusedAnswer: __bp_ns_observe__refusedAnswer } = require("./conformance-lib/observe.js");

/** The snapshot, read as a build input (decision 989 (5)). */

const accepted = "botopink-cell 2\n== optional_enum_method_call\nout find\nout a\nout find\nout 42\n== optional_float_function_value\nout 1.5\nout 1.5\nout -1.0\nout v=1.5\nout none\nout 0.5\nout 1.25\nout 10000000000\nout -1\n== optional_if_null_initializer\nout -1\nout 0\nout -1\nout 0\nout 2\nout 1\nout -1\nout 0.5\nout -1.0\nout 0\nout true\nout null\nout 0\n== optional_member_default\nout 7\nout 0\nout a\nout 5\nout 20\nout 8\nout 0\n== optional_method_absent_receiver\nout -1\nout 5\nout null\nout 5\nout none\nout FOUND\nout false\nout true\nout -7\nout lp\nout none\n== optional_operators\nout 20\nout -1\nout -2\nout none\nout t0\nout a\nout 10\n== optional_record_method_absent_receiver\nout 0\nout 1.5\nout -1.0\nout true\nout false\nout 0\nout -1\nout 1\nout -1\nout 0\nout 1\nout -1\nout 0\n== std_type_field_associated\nout none\n== assoc_type_named_like_member\nrefused error[assoc-type-duplicate]: a type declared in a type's body is named through it, and this name is already a member of it\nat src/main.bp:12:14\nlabel `Owner.Name` names one thing\n== bang_never_null\nrefused error: optional-operator-never-null: `!` over a value that is never null — this is `i32`, not `?i32`\nat src/main.bp:8:12\n== nullish_beside_logical\nrefused error[nullish-beside-logical]: `??` beside `&&` or `||` takes parentheses\nat src/main.bp:11:22\nlabel parenthesise the `??` or the logical operand\n== nullish_never_null\nrefused error: optional-operator-never-null: `??` over a value that is never null — this is `string`, not `?string`\nat src/main.bp:8:13\n== optional_has_no_methods\nrefused error: optional-has-no-methods: unknown method `unwrapOr` on `?string` — an optional has no methods\nat src/main.bp:11:21\n== optional_operator_never_null\nrefused error: optional-operator-never-null: `?.` over a value that is never null — this is `string`, not `?string`\nat src/main.bp:9:14\n== result_namespace_removed\nrefused error: unbound variable 'result'\nat src/main.bp:13:11\n== nullish_default_namespace_call\nout found\nout data.txt\nout 4\nout found\nout anon\n== nullish_optional_call_default\nout 11\nout backup\nout 101\nout backup\nout -1\nout bo\nout hi you\nout nobody\nout 6\n== optional_array_at_record\nout tick\nout none\nout tick\nout none\n== optional_call_operator\nout 42\nout -3\n== optional_call_param_wasm\nout 4\nout -1\nout 4\nout -1\n== optional_call_plain_answers\nout 1\nout 0\nout -1\nout 0\nout null\nout hi bo\nout nobody\nout true\nout true\nout 8\nout -1\n== optional_chain_absent_array_length\nout start\nout 0\nout 0\nout 0\n== optional_chain_field_after_call\nout p\nout 7\nout p\nout -1\nout p\nout 3\nout p\nout -1\nout p\nout 5\nout p\nout none\n== optional_chain_lambda_array_method\nout 2\nout 0\nout 1\n== optional_chain_lambda_generic\nout a\nout none\nout x\n== optional_chain_nested_array\nout email\nout email\nout email\nout none\nout none\n== optional_chain_present_array_length\nout 2\nout 0\nout 0\nout 3\n== optional_chain_record_fields\nout Main\nout none\nout none\nout none\nout 4\nout -1\nout -1\nout 2\nout -1\nout CY\nout none\n== optional_enum_method_absent_receiver\nout find\nout none\nout find\nout -1\nout find\nout -2\nout find\nout 42\n== optional_index_record_field\nout email\nout email\nout no message\nout no field\nout tag\n";

exports.accepted = accepted;

/** What each case answered, in the order the cases ran. */

let answers = [];

exports.answers = answers;

/** One case, expanded where it is called (decision 808 (2)): a refused load answers its */

/** diagnostics, a loaded one runs and answers its output. */

const __bp_comptime_0_at = 0;

exports.__bp_comptime_0_at = __bp_comptime_0_at;

function __bp_executor_0() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_enum_method_call));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_enum_method_call", __bp_ns_adapter__buildOutput((__bp_load_module("optional_enum_method_call", "cases/optional_enum_method_call", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_0 = __bp_executor_0;

const __bp_init_0 = __bp_executor_0();

exports.__bp_init_0 = __bp_init_0;

function __bp_executor_1() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_float_function_value));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_float_function_value", __bp_ns_adapter__buildOutput((__bp_load_module("optional_float_function_value", "cases/optional_float_function_value", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_1 = __bp_executor_1;

const __bp_init_1 = __bp_executor_1();

exports.__bp_init_1 = __bp_init_1;

function __bp_executor_2() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_if_null_initializer));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_if_null_initializer", __bp_ns_adapter__buildOutput((__bp_load_module("optional_if_null_initializer", "cases/optional_if_null_initializer", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_2 = __bp_executor_2;

const __bp_init_2 = __bp_executor_2();

exports.__bp_init_2 = __bp_init_2;

function __bp_executor_3() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_member_default));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_member_default", __bp_ns_adapter__buildOutput((__bp_load_module("optional_member_default", "cases/optional_member_default", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_3 = __bp_executor_3;

const __bp_init_3 = __bp_executor_3();

exports.__bp_init_3 = __bp_init_3;

function __bp_executor_4() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_method_absent_receiver));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_method_absent_receiver", __bp_ns_adapter__buildOutput((__bp_load_module("optional_method_absent_receiver", "cases/optional_method_absent_receiver", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_4 = __bp_executor_4;

const __bp_init_4 = __bp_executor_4();

exports.__bp_init_4 = __bp_init_4;

function __bp_executor_5() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_operators));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_operators", __bp_ns_adapter__buildOutput((__bp_load_module("optional_operators", "cases/optional_operators", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_5 = __bp_executor_5;

const __bp_init_5 = __bp_executor_5();

exports.__bp_init_5 = __bp_init_5;

function __bp_executor_6() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_record_method_absent_receiver));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_record_method_absent_receiver", __bp_ns_adapter__buildOutput((__bp_load_module("optional_record_method_absent_receiver", "cases/optional_record_method_absent_receiver", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_6 = __bp_executor_6;

const __bp_init_6 = __bp_executor_6();

exports.__bp_init_6 = __bp_init_6;

function __bp_executor_7() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__std_type_field_associated));
    answers = answers.concat([__bp_ns_observe__ranAnswer("std_type_field_associated", __bp_ns_adapter__buildOutput((__bp_load_module("std_type_field_associated", "cases/std_type_field_associated", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_7 = __bp_executor_7;

const __bp_init_7 = __bp_executor_7();

exports.__bp_init_7 = __bp_init_7;

function __bp_executor_8() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("assoc_type_named_like_member", "cases/assoc_type_named_like_member", ""), [new Diagnostic("assoc-type-duplicate", "a type declared in a type's body is named through it, and this name is already a member of it", "src/main.bp", 12, 14, "`Owner.Name` names one thing", [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("assoc_type_named_like_member", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("assoc_type_named_like_member", "cases/assoc_type_named_like_member", ""), [new Diagnostic("assoc-type-duplicate", "a type declared in a type's body is named through it, and this name is already a member of it", "src/main.bp", 12, 14, "`Owner.Name` names one thing", [])])).module), refusals)]);
}
exports.__bp_executor_8 = __bp_executor_8;

const __bp_init_8 = __bp_executor_8();

exports.__bp_init_8 = __bp_init_8;

function __bp_executor_9() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("bang_never_null", "cases/bang_never_null", ""), [new Diagnostic("optional-operator-never-null", "optional-operator-never-null: `!` over a value that is never null — this is `i32`, not `?i32`", "src/main.bp", 8, 12, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("bang_never_null", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("bang_never_null", "cases/bang_never_null", ""), [new Diagnostic("optional-operator-never-null", "optional-operator-never-null: `!` over a value that is never null — this is `i32`, not `?i32`", "src/main.bp", 8, 12, null, [])])).module), refusals)]);
}
exports.__bp_executor_9 = __bp_executor_9;

const __bp_init_9 = __bp_executor_9();

exports.__bp_init_9 = __bp_init_9;

function __bp_executor_10() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("nullish_beside_logical", "cases/nullish_beside_logical", ""), [new Diagnostic("nullish-beside-logical", "`??` beside `&&` or `||` takes parentheses", "src/main.bp", 11, 22, "parenthesise the `??` or the logical operand", [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("nullish_beside_logical", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("nullish_beside_logical", "cases/nullish_beside_logical", ""), [new Diagnostic("nullish-beside-logical", "`??` beside `&&` or `||` takes parentheses", "src/main.bp", 11, 22, "parenthesise the `??` or the logical operand", [])])).module), refusals)]);
}
exports.__bp_executor_10 = __bp_executor_10;

const __bp_init_10 = __bp_executor_10();

exports.__bp_init_10 = __bp_init_10;

function __bp_executor_11() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("nullish_never_null", "cases/nullish_never_null", ""), [new Diagnostic("optional-operator-never-null", "optional-operator-never-null: `??` over a value that is never null — this is `string`, not `?string`", "src/main.bp", 8, 13, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("nullish_never_null", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("nullish_never_null", "cases/nullish_never_null", ""), [new Diagnostic("optional-operator-never-null", "optional-operator-never-null: `??` over a value that is never null — this is `string`, not `?string`", "src/main.bp", 8, 13, null, [])])).module), refusals)]);
}
exports.__bp_executor_11 = __bp_executor_11;

const __bp_init_11 = __bp_executor_11();

exports.__bp_init_11 = __bp_init_11;

function __bp_executor_12() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("optional_has_no_methods", "cases/optional_has_no_methods", ""), [new Diagnostic("optional-has-no-methods", "optional-has-no-methods: unknown method `unwrapOr` on `?string` — an optional has no methods", "src/main.bp", 11, 21, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("optional_has_no_methods", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("optional_has_no_methods", "cases/optional_has_no_methods", ""), [new Diagnostic("optional-has-no-methods", "optional-has-no-methods: unknown method `unwrapOr` on `?string` — an optional has no methods", "src/main.bp", 11, 21, null, [])])).module), refusals)]);
}
exports.__bp_executor_12 = __bp_executor_12;

const __bp_init_12 = __bp_executor_12();

exports.__bp_init_12 = __bp_init_12;

function __bp_executor_13() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("optional_operator_never_null", "cases/optional_operator_never_null", ""), [new Diagnostic("optional-operator-never-null", "optional-operator-never-null: `?.` over a value that is never null — this is `string`, not `?string`", "src/main.bp", 9, 14, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("optional_operator_never_null", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("optional_operator_never_null", "cases/optional_operator_never_null", ""), [new Diagnostic("optional-operator-never-null", "optional-operator-never-null: `?.` over a value that is never null — this is `string`, not `?string`", "src/main.bp", 9, 14, null, [])])).module), refusals)]);
}
exports.__bp_executor_13 = __bp_executor_13;

const __bp_init_13 = __bp_executor_13();

exports.__bp_init_13 = __bp_init_13;

function __bp_executor_14() {
    let refusals = [];
    for (const d of (new Refused(__bp_load_module("result_namespace_removed", "cases/result_namespace_removed", ""), [new Diagnostic("", "unbound variable 'result'", "src/main.bp", 13, 11, null, [])])).diagnostics) {
    refusals = refusals.concat([__bp_ns_observe__refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, __bp_ns_adapter__frames(d))]);
}
    answers = answers.concat([__bp_ns_observe__refusedAnswer("result_namespace_removed", __bp_ns_adapter__buildOutput((new Refused(__bp_load_module("result_namespace_removed", "cases/result_namespace_removed", ""), [new Diagnostic("", "unbound variable 'result'", "src/main.bp", 13, 11, null, [])])).module), refusals)]);
}
exports.__bp_executor_14 = __bp_executor_14;

const __bp_init_14 = __bp_executor_14();

exports.__bp_init_14 = __bp_init_14;

function __bp_executor_15() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__nullish_default_namespace_call));
    answers = answers.concat([__bp_ns_observe__ranAnswer("nullish_default_namespace_call", __bp_ns_adapter__buildOutput((__bp_load_module("nullish_default_namespace_call", "cases/nullish_default_namespace_call", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_15 = __bp_executor_15;

const __bp_init_15 = __bp_executor_15();

exports.__bp_init_15 = __bp_init_15;

function __bp_executor_16() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__nullish_optional_call_default));
    answers = answers.concat([__bp_ns_observe__ranAnswer("nullish_optional_call_default", __bp_ns_adapter__buildOutput((__bp_load_module("nullish_optional_call_default", "cases/nullish_optional_call_default", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_16 = __bp_executor_16;

const __bp_init_16 = __bp_executor_16();

exports.__bp_init_16 = __bp_init_16;

function __bp_executor_17() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_array_at_record));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_array_at_record", __bp_ns_adapter__buildOutput((__bp_load_module("optional_array_at_record", "cases/optional_array_at_record", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_17 = __bp_executor_17;

const __bp_init_17 = __bp_executor_17();

exports.__bp_init_17 = __bp_init_17;

function __bp_executor_18() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_call_operator));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_call_operator", __bp_ns_adapter__buildOutput((__bp_load_module("optional_call_operator", "cases/optional_call_operator", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_18 = __bp_executor_18;

const __bp_init_18 = __bp_executor_18();

exports.__bp_init_18 = __bp_init_18;

function __bp_executor_19() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_call_param_wasm));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_call_param_wasm", __bp_ns_adapter__buildOutput((__bp_load_module("optional_call_param_wasm", "cases/optional_call_param_wasm", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_19 = __bp_executor_19;

const __bp_init_19 = __bp_executor_19();

exports.__bp_init_19 = __bp_init_19;

function __bp_executor_20() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_call_plain_answers));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_call_plain_answers", __bp_ns_adapter__buildOutput((__bp_load_module("optional_call_plain_answers", "cases/optional_call_plain_answers", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_20 = __bp_executor_20;

const __bp_init_20 = __bp_executor_20();

exports.__bp_init_20 = __bp_init_20;

function __bp_executor_21() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_chain_absent_array_length));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_chain_absent_array_length", __bp_ns_adapter__buildOutput((__bp_load_module("optional_chain_absent_array_length", "cases/optional_chain_absent_array_length", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_21 = __bp_executor_21;

const __bp_init_21 = __bp_executor_21();

exports.__bp_init_21 = __bp_init_21;

function __bp_executor_22() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_chain_field_after_call));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_chain_field_after_call", __bp_ns_adapter__buildOutput((__bp_load_module("optional_chain_field_after_call", "cases/optional_chain_field_after_call", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_22 = __bp_executor_22;

const __bp_init_22 = __bp_executor_22();

exports.__bp_init_22 = __bp_init_22;

function __bp_executor_23() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_chain_lambda_array_method));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_chain_lambda_array_method", __bp_ns_adapter__buildOutput((__bp_load_module("optional_chain_lambda_array_method", "cases/optional_chain_lambda_array_method", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_23 = __bp_executor_23;

const __bp_init_23 = __bp_executor_23();

exports.__bp_init_23 = __bp_init_23;

function __bp_executor_24() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_chain_lambda_generic));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_chain_lambda_generic", __bp_ns_adapter__buildOutput((__bp_load_module("optional_chain_lambda_generic", "cases/optional_chain_lambda_generic", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_24 = __bp_executor_24;

const __bp_init_24 = __bp_executor_24();

exports.__bp_init_24 = __bp_init_24;

function __bp_executor_25() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_chain_nested_array));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_chain_nested_array", __bp_ns_adapter__buildOutput((__bp_load_module("optional_chain_nested_array", "cases/optional_chain_nested_array", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_25 = __bp_executor_25;

const __bp_init_25 = __bp_executor_25();

exports.__bp_init_25 = __bp_init_25;

function __bp_executor_26() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_chain_present_array_length));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_chain_present_array_length", __bp_ns_adapter__buildOutput((__bp_load_module("optional_chain_present_array_length", "cases/optional_chain_present_array_length", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_26 = __bp_executor_26;

const __bp_init_26 = __bp_executor_26();

exports.__bp_init_26 = __bp_init_26;

function __bp_executor_27() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_chain_record_fields));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_chain_record_fields", __bp_ns_adapter__buildOutput((__bp_load_module("optional_chain_record_fields", "cases/optional_chain_record_fields", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_27 = __bp_executor_27;

const __bp_init_27 = __bp_executor_27();

exports.__bp_init_27 = __bp_init_27;

function __bp_executor_28() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_enum_method_absent_receiver));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_enum_method_absent_receiver", __bp_ns_adapter__buildOutput((__bp_load_module("optional_enum_method_absent_receiver", "cases/optional_enum_method_absent_receiver", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_28 = __bp_executor_28;

const __bp_init_28 = __bp_executor_28();

exports.__bp_init_28 = __bp_init_28;

function __bp_executor_29() {
    const ran = __bp_ns_adapter__ranOf(__bp_run(__bp_run__bp_load__cases__optional_index_record_field));
    answers = answers.concat([__bp_ns_observe__ranAnswer("optional_index_record_field", __bp_ns_adapter__buildOutput((__bp_load_module("optional_index_record_field", "cases/optional_index_record_field", ""))), ran.printed, ran.failed, ran.failure)]);
}
exports.__bp_executor_29 = __bp_executor_29;

const __bp_init_29 = __bp_executor_29();

exports.__bp_init_29 = __bp_init_29;

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

Object.defineProperty(exports, "__bp_priv__", { value: { RunFailureKind, Asset, __bp_run__bp_load__cases__optional_enum_method_call, __bp_run__bp_load__cases__optional_float_function_value, __bp_run__bp_load__cases__optional_if_null_initializer, __bp_run__bp_load__cases__optional_member_default, __bp_run__bp_load__cases__optional_method_absent_receiver, __bp_run__bp_load__cases__optional_operators, __bp_run__bp_load__cases__optional_record_method_absent_receiver, __bp_run__bp_load__cases__std_type_field_associated, __bp_run__bp_load__cases__nullish_default_namespace_call, __bp_run__bp_load__cases__nullish_optional_call_default, __bp_run__bp_load__cases__optional_array_at_record, __bp_run__bp_load__cases__optional_call_operator, __bp_run__bp_load__cases__optional_call_param_wasm, __bp_run__bp_load__cases__optional_call_plain_answers, __bp_run__bp_load__cases__optional_chain_absent_array_length, __bp_run__bp_load__cases__optional_chain_field_after_call, __bp_run__bp_load__cases__optional_chain_lambda_array_method, __bp_run__bp_load__cases__optional_chain_lambda_generic, __bp_run__bp_load__cases__optional_chain_nested_array, __bp_run__bp_load__cases__optional_chain_present_array_length, __bp_run__bp_load__cases__optional_chain_record_fields, __bp_run__bp_load__cases__optional_enum_method_absent_receiver, __bp_run__bp_load__cases__optional_index_record_field, Observed, Refusal, Diagnostic, Module, Refused, __bp_run_attempt, __bp_loaded, __bp_load_module, __bp_run_failure, RunFailure, __bp_run, __bp_run_async, __bp_run_none, __bp_run_async_none, __bp_ns_adapter__buildOutput, __bp_ns_adapter__ranOf, __bp_ns_adapter__frames, __bp_ns_adapter__target, __bp_ns_candidate__finish, __bp_ns_observe__refusalOf, __bp_ns_observe__ranAnswer, __bp_ns_observe__refusedAnswer, accepted, answers, __bp_comptime_0_at, __bp_executor_0, __bp_init_0, __bp_executor_1, __bp_init_1, __bp_executor_2, __bp_init_2, __bp_executor_3, __bp_init_3, __bp_executor_4, __bp_init_4, __bp_executor_5, __bp_init_5, __bp_executor_6, __bp_init_6, __bp_executor_7, __bp_init_7, __bp_executor_8, __bp_init_8, __bp_executor_9, __bp_init_9, __bp_executor_10, __bp_init_10, __bp_executor_11, __bp_init_11, __bp_executor_12, __bp_init_12, __bp_executor_13, __bp_init_13, __bp_executor_14, __bp_init_14, __bp_executor_15, __bp_init_15, __bp_executor_16, __bp_init_16, __bp_executor_17, __bp_init_17, __bp_executor_18, __bp_init_18, __bp_executor_19, __bp_init_19, __bp_executor_20, __bp_init_20, __bp_executor_21, __bp_init_21, __bp_executor_22, __bp_init_22, __bp_executor_23, __bp_init_23, __bp_executor_24, __bp_init_24, __bp_executor_25, __bp_init_25, __bp_executor_26, __bp_init_26, __bp_executor_27, __bp_init_27, __bp_executor_28, __bp_init_28, __bp_executor_29, __bp_init_29, main } });
