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

//// std/testing/mocks — Mockito-style mocks over a `behavior`: `#[mock]` synthesizes

//// the double, `when(...)` stubs a return, `verify(...)` checks call counts

//// (1.0.10-beta front 01-std, `onze-migration.md`; decision 71).

//// 

//// Lifted 100 % from the retired `onze` mocking library (`botopink/onze`, tag

//// `mocking-lib-final`). The Erlang templates are the old ones; the Node

//// templates inline what `onze.mjs` held as module globals. Only three things

//// changed with the move: the module name, the two renamed cells (`whenCall`,

//// `thenReturnCell`, `thenThrowCell` — `when`/`thenReturn`/`thenThrow` are the

//// public surface's names), and the private state keys (`'__onze_*'` →

//// `'__bp_mocks_*'`, `"onze#"` → `"mock#"`, `onze.verify:` → `mocks.verify:`).

//// Semantics are byte-for-byte the old ones, asserted by the eight tests at the

//// foot of this file — the old `test/onze_test.bp`, re-spelled.

//// 

//// **No sidecar.** `onze.mjs` existed because the recorder needs mutable,

//// identity-based state; the Erlang side never needed one (its tables live in

//// the process dictionary, inside each template). The Node side does the same

//// with a lazily created cell on `globalThis`, the shape

//// `emilia/modules/emilia/src/emilia.bp:24` uses for its stylesheet:

//// 

////     globalThis.__bp_mocks ||= { counter, calls, stubs, pending,

////                                 pendingStub, verifyMode }

//// 

//// One cell per host process, shared by every mock in the run; mock ids are

//// unique per `newMock()`, so two mocks never collide in the shared tables.

//// `libs/std/src/sidecars/` therefore still holds exactly one file

//// (`random.mjs`).

//// 

//// **STD-001.** Unlike `asserts`, the eight cells here are

//// `pub declare fn`: the code `#[mock]` adds to the CONSUMER's behavior calls

//// `invoke`/`key`/`newMock`, so they have to be exported. They carry Node and

//// Erlang templates only, so `import {mocks} from "std"` is refused on beam and

//// wasm — honestly, since `botopink test` runs on neither.

//// 

//// Two layers, as in the old library:

////   • the RUNTIME (matchers / `when` / `verify` / the host cells) — ordinary

////     botopink over the cells below.

////   • the SYNTHESIS (`#[mock]`) — a comptime decorator that reflects a

////     behavior's methods through the declaration handle (`syntax decl: unknown`) and gives the behavior the mock type

////     `Xxx.Mock` and the factory `Xxx.mock()` (decision 216). The compiler core learns nothing about mocking

////     (no lib-specific surface in core); every rule here is botopink.

const failure = require("../../std/failure.js");

// ── host cells (the one mutable seam) ────────────────────────────────────────

// 

// Node: one lazily created object on `globalThis`. Erlang: the same six tables

// in the process dictionary, one key each. The two have to be kept in step by

// hand — that is the reason there is one copy of this module and not one per

// `<lib>-test` submodule (`onze-migration.md` § Where the mocking surface goes).

// A fresh, unique mock id. `"mock#<n>"`, `n` counted per host process.

// newMock: per-call template (see annotation)
function newMock() { return (function(){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); __M.counter += 1; return "mock#" + __M.counter; })(); }
exports.newMock = newMock;

// Canonical, comparable key for any argument value (string/int/array/record).

// The same cell `asserts.canonical` carries privately, for the same reason: two

// values that render the same on a host are structurally equal there. Two

// copies rather than one, because a std module does not import another.

// key: per-call template (see annotation)
function key(v) { return JSON.stringify(v); }
exports.key = key;

// Push one matcher descriptor onto the pending stack that the next mock call

// consumes. `kind` is `"eq"` (match `k`) or `"any"` (match anything).

// pushMatcher: per-call template (see annotation)
function pushMatcher(kind, k) { return (function(__K, __V){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); __M.pending.push({ kind: __K, key: __V }); return 0; })(kind, k); }
exports.pushMatcher = pushMatcher;

// The single entry every synthesized mock method calls: record the invocation

// (or, in verify mode, assert its count), then answer the matching stub value —

// or `def`, the caller-supplied type-default of the method's return type. A

// matched `thenThrow` stub raises here, on the host.

// invoke: per-call template (see annotation)
function invoke(id, method, keys, def) { return (function(__Id, __Me, __Ks, __Df){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); var __Ms; if (__M.pending.length === __Ks.length) { __Ms = __M.pending.slice(); } else { __Ms = __Ks.map(function(__K){ return { kind: "eq", key: __K }; }); } __M.pending = []; var __Mt = function(__A, __B){ if (__A.length !== __B.length) { return false; } for (var __I = 0; __I < __B.length; __I++) { if (__A[__I].kind === "any") { continue; } if (__A[__I].key !== __B[__I]) { return false; } } return true; }; if (__M.verifyMode !== null) { var __Sp = __M.verifyMode.spec; __M.verifyMode = null; var __C = 0; for (var __J = 0; __J < __M.calls.length; __J++) { var __Cl = __M.calls[__J]; if (__Cl.id === __Id && __Cl.method === __Me && __Mt(__Ms, __Cl.keys)) { __C += 1; } } var __Ok = __Sp === -1 ? __C >= 1 : __C === __Sp; if (!__Ok) { var __W = __Sp === -1 ? "at least 1" : "exactly " + __Sp; var __R = __M.calls.filter(function(__Cl){ return __Cl.id === __Id && __Cl.method === __Me; }).map(function(__Cl){ return __Me + "(" + __Cl.keys.join(", ") + ")"; }); throw new Error("mocks.verify: " + __Me + " - expected " + __W + " matching call(s), got " + __C + (__R.length ? " [recorded: " + __R.join("; ") + "]" : " [no calls recorded]")); } return __Df; } __M.calls.push({ id: __Id, method: __Me, keys: __Ks, matchers: __Ms }); for (var __I2 = __M.stubs.length - 1; __I2 >= 0; __I2--) { var __St = __M.stubs[__I2]; if (__St.id === __Id && __St.method === __Me && __Mt(__St.matchers, __Ks)) { if (__St.action.kind === "throw") { throw new Error(__St.action.value); } return __St.action.value; } } return __Df; })(id, method, keys, def); }
exports.invoke = invoke;

// Arm verify mode: the next mock call asserts its count instead of recording.

// beginVerify: per-call template (see annotation)
function beginVerify(spec) { return (function(__S){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); __M.verifyMode = { spec: __S }; return 0; })(spec); }
exports.beginVerify = beginVerify;

// Pop the call `when(mock.m(args))` just recorded inside its own argument and

// hold it as the stub target the builder writes to. Named `whenCall` because

// `when` is the public function's name.

// whenCall: per-call template (see annotation)
function whenCall() { return (function(){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); var __C = __M.calls.pop(); __M.pendingStub = __C ? { id: __C.id, method: __C.method, matchers: __C.matchers } : null; return 0; })(); }
exports.whenCall = whenCall;

// Write a `return` action for the pending stub target. Named `thenReturnCell`

// because `thenReturn` is `Stub`'s method.

// thenReturnCell: per-call template (see annotation)
function thenReturnCell(v) { return (function(__V){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); if (__M.pendingStub) { __M.stubs.push({ id: __M.pendingStub.id, method: __M.pendingStub.method, matchers: __M.pendingStub.matchers, action: { kind: "return", value: __V } }); } __M.pendingStub = null; return 0; })(v); }
exports.thenReturnCell = thenReturnCell;

// Write a `throw` action for the pending stub target. Named `thenThrowCell`

// because `thenThrow` is `Stub`'s method.

// thenThrowCell: per-call template (see annotation)
function thenThrowCell(msg) { return (function(__V){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); if (__M.pendingStub) { __M.stubs.push({ id: __M.pendingStub.id, method: __M.pendingStub.method, matchers: __M.pendingStub.matchers, action: { kind: "throw", value: __V } }); } __M.pendingStub = null; return 0; })(msg); }
exports.thenThrowCell = thenThrowCell;

// ── argument matchers ────────────────────────────────────────────────────────

// 

// A matcher answers a dummy value of the right type (so `mock.m(matcher)`

// type-checks) and pushes a descriptor onto the host matcher stack. When the

// mock method runs, the stack decides how each argument is matched; a literal

// argument (no matcher) means exact equality on its key. Matchers compose

// across parameters — all of them, or none.

// 

// These three are MATCHERS, not assertions: they push and return, they never

// answer a `Result`. They stay here rather than joining `std/asserts`

// (`onze-migration.md` § Where the assertion surface goes — the old library

// exported no assertion at all).

// `eq(v)` — match exactly `v` (the default for a literal argument, made explicit).

function eq(v) {
    const _m = (function(__K, __V){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); __M.pending.push({ kind: __K, key: __V }); return 0; })("eq", JSON.stringify(v));
    return v;
}
exports.eq = eq;

// `anyInt()` — match any `i32` argument. A fully generic `any<T>()` would need

// a per-type default it cannot produce (`onze-migration.md` § Language gaps),

// so the concrete matchers ship per type; add one where a type needs it.

function anyInt() {
    const _m = (function(__K, __V){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); __M.pending.push({ kind: __K, key: __V }); return 0; })("any", "*");
    return 0;
}
exports.anyInt = anyInt;

// `anyString()` — match any `string` argument.

function anyString() {
    const _m = (function(__K, __V){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); __M.pending.push({ kind: __K, key: __V }); return 0; })("any", "*");
    return "";
}
exports.anyString = anyString;

// ── verification specs ───────────────────────────────────────────────────────

// 

// Encoded as an i32: -1 = at least once, n >= 0 = exactly n (0 = never).

// At least one matching call.

function atLeastOnce() {
    return (-1);
}
exports.atLeastOnce = atLeastOnce;

// Exactly `n` matching calls.

function times(n) {
    return n;
}
exports.times = times;

// No matching call at all — `times(0)`, spelled.

function never() {
    return 0;
}
exports.never = never;

// ── stubbing: when(...).thenReturn / thenThrow ───────────────────────────────

// 

// `when(mock.m(args))` evaluates `mock.m(args)` first — that records the call

// and captures it, with its matchers, as the pending stub target. The returned

// builder then writes the action. The last stub registered wins on overlap.

// The `when(...)` builder. `tag` carries nothing: the captured call lives in

// the host cell, and a record needs at least one field.

class Stub {
    constructor(tag) {
        this.tag = tag;
    }

    thenReturn(v, __bp_ty_T) {
        const _r = (function(__V){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); if (__M.pendingStub) { __M.stubs.push({ id: __M.pendingStub.id, method: __M.pendingStub.method, matchers: __M.pendingStub.matchers, action: { kind: "return", value: __V } }); } __M.pendingStub = null; return 0; })(v);
        return true;
    }

    thenThrow(message) {
        const _r = (function(__V){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); if (__M.pendingStub) { __M.stubs.push({ id: __M.pendingStub.id, method: __M.pendingStub.method, matchers: __M.pendingStub.matchers, action: { kind: "throw", value: __V } }); } __M.pendingStub = null; return 0; })(message);
        return true;
    }
}
Stub.prototype.__bp = "Stub";
exports.Stub = Stub;

// Open a stub over the call just made in the argument position.

function when(value) {
    const _w = (function(){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); var __C = __M.calls.pop(); __M.pendingStub = __C ? { id: __C.id, method: __C.method, matchers: __C.matchers } : null; return 0; })();
    return new Stub("");
}
exports.when = when;

// ── verification entry ───────────────────────────────────────────────────────

// 

// `verify(mock, spec).m(args)` runs `m` in verify mode: instead of recording,

// the synthesized method asserts the count of matching prior calls against

// `spec` and raises when it disagrees. The two-argument form is uniform —

// botopink has neither fn overloading nor default parameters:

//   verify(repo, atLeastOnce()).all();

//   verify(repo, times(1)).find(eq(7));

//   verify(repo, never()).find(eq(99));

function verify(mock, spec) {
    const _v = (function(__S){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); __M.verifyMode = { spec: __S }; return 0; })(spec);
    return mock;
}
exports.verify = verify;

// ── mock synthesis (`#[mock]`) ───────────────────────────────────────────────

// 

// A comptime annotation processor: reflect the annotated behavior's methods through

// the declaration handle (`syntax decl: unknown`) and give the behavior (a) the associated type `<Name>.Mock(__id:

// string)`, which implements `<Name>` and funnels every method through

// `invoke` (`decl.addType`), and (b) the associated fn `<Name>.mock() -> <Name>`,

// the factory (`decl.addMember`) — decision 216. The compiler core provides only the protocol (recognise →

// reflect → run the body); every rule below is botopink. The generated method

// records its call and answers the stub value, or the per-return-type default

// (`""` / `false` / `0` / `[]`).

// 

// The type and the factory are declared in the module that hosts the annotated

// behavior, so the names their text writes must resolve THERE. Inside this module they are the

// bare `invoke`, `key` and `newMock`; in a consumer they are reached through

// the handle the consumer imported this module under, which is the prefix of

// the annotation that fired: `import {testing.mocks} from "std"` and

// `#[mocks.mock]` emit `mocks.invoke(…)`, an alias `#[m.mock]` emits

// `m.invoke(…)`. A std module's decorators are registered under

// `<handle>.<fn>` by the import (`comptime/infer.zig`

// `registerStdImportDecorators`); a leaf import of `mock` is refused, since it

// would leave the emitted code no handle.

// 

// Comptime-body constraints (`libs/std/AGENTS.md`, `reference` gotchas): `if` is

// an expression (needs `else`, `;`-terminated branches); a bare `if {…}`

// statement is only legal as the last statement in a block; and the body cannot

// call sibling fns — only this one is lowered into the decorator eval script —

// so the return-type default is inlined rather than factored out.

// Internal, test scaffolding: the text a body raised, `""` when it answered —

// the shape of `asserts.throwsWith`'s own cell (`hash.panicText` is the same).

// A std module does not import the harness: an import of `testing.asserts`

// links its host-only `canonical` into every program that reaches `mocks`, and

// the wasm backend refuses each of them.

function raisedText(body) {
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
exports.raisedText = raisedText;

// ── tests ────────────────────────────────────────────────────────────────────

// The eight tests of the retired `repository/onze/test/onze_test.bp`, re-spelled

// against this module. They drive the whole surface end to end: `#[mock]`

// synthesizes the double from the behavior, a mock records its calls, `when(…)`

// stubs returns, the matchers pick the right stub, and `verify(…)` checks

// counts. Arrays are compared with `.join(",")` because `==` on arrays is

// reference equality on commonJS (a language trait, not a mocking one).

// behavior UserRepo
//   fn find(...)
//   fn all(...)
//   fn mock(...)
const UserRepo = {};
UserRepo.mock = function() {
    return new UserRepo__Mock((function(){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); __M.counter += 1; return "mock#" + __M.counter; })());
};

// A unit under test that depends only on the behavior.

class UserService {
    constructor(repo) {
        this.repo = repo;
    }

    list() {
        return this.repo.all();
    }

    name(id) {
        return this.repo.find(id);
    }
}
UserService.prototype.__bp = "UserService";

// `anyString()` is the ninth test: the old suite covered it from the example

// app rather than from `test/onze_test.bp`, and the inventory asks every row to

// be exercised where it now lives.

// behavior Greeter
//   fn greet(...)
//   fn mock(...)
const Greeter = {};
Greeter.mock = function() {
    return new Greeter__Mock((function(){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); __M.counter += 1; return "mock#" + __M.counter; })());
};

// The two rows the old suite recorded as limitations, carried here unchanged

// (`onze-migration.md` § Language gaps holds the proposed surfaces):

// 

// LIMITATION: a `thenThrow` stub matched at run time raises a HOST throw from

// `invoke`. botopink's `try … catch …` only unwraps an `Result` produced by a

// `-> Result` fn — it does not catch a host throw from a plain (non-effect)

// method call, so `try svc.name(0) catch …` does not compile: the callee is not

// `-> Result`. Modelling the throw as an effect (the synthesized method

// answering `Result<R, string>`) is a design change, not a port. The covered

// surface is what the test above asserts: a matched `thenThrow` raises, and a

// non-matching call answers the default. A caller that must observe the raise

// uses `asserts.throws` from its own module, where `std/asserts` is importable.

// 

// LIMITATION: there is no fully generic `any<T>()` matcher and no argument

// captor. `any<T>()` needs a per-type default it cannot synthesize, so the

// concrete `anyInt()` / `anyString()` ship instead (both exercised above, and

// composed independently across parameters); a captor needs a ninth host cell

// that records and reads back the captured argument.

class UserRepo__Mock {
    constructor(__id) {
        this.__id = __id;
    }

    find(id) {
        return (function(__Id, __Me, __Ks, __Df){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); var __Ms; if (__M.pending.length === __Ks.length) { __Ms = __M.pending.slice(); } else { __Ms = __Ks.map(function(__K){ return { kind: "eq", key: __K }; }); } __M.pending = []; var __Mt = function(__A, __B){ if (__A.length !== __B.length) { return false; } for (var __I = 0; __I < __B.length; __I++) { if (__A[__I].kind === "any") { continue; } if (__A[__I].key !== __B[__I]) { return false; } } return true; }; if (__M.verifyMode !== null) { var __Sp = __M.verifyMode.spec; __M.verifyMode = null; var __C = 0; for (var __J = 0; __J < __M.calls.length; __J++) { var __Cl = __M.calls[__J]; if (__Cl.id === __Id && __Cl.method === __Me && __Mt(__Ms, __Cl.keys)) { __C += 1; } } var __Ok = __Sp === -1 ? __C >= 1 : __C === __Sp; if (!__Ok) { var __W = __Sp === -1 ? "at least 1" : "exactly " + __Sp; var __R = __M.calls.filter(function(__Cl){ return __Cl.id === __Id && __Cl.method === __Me; }).map(function(__Cl){ return __Me + "(" + __Cl.keys.join(", ") + ")"; }); throw new Error("mocks.verify: " + __Me + " - expected " + __W + " matching call(s), got " + __C + (__R.length ? " [recorded: " + __R.join("; ") + "]" : " [no calls recorded]")); } return __Df; } __M.calls.push({ id: __Id, method: __Me, keys: __Ks, matchers: __Ms }); for (var __I2 = __M.stubs.length - 1; __I2 >= 0; __I2--) { var __St = __M.stubs[__I2]; if (__St.id === __Id && __St.method === __Me && __Mt(__St.matchers, __Ks)) { if (__St.action.kind === "throw") { throw new Error(__St.action.value); } return __St.action.value; } } return __Df; })(this.__id, "find", [JSON.stringify(id)], "");
    }

    all() {
        return (function(__Id, __Me, __Ks, __Df){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); var __Ms; if (__M.pending.length === __Ks.length) { __Ms = __M.pending.slice(); } else { __Ms = __Ks.map(function(__K){ return { kind: "eq", key: __K }; }); } __M.pending = []; var __Mt = function(__A, __B){ if (__A.length !== __B.length) { return false; } for (var __I = 0; __I < __B.length; __I++) { if (__A[__I].kind === "any") { continue; } if (__A[__I].key !== __B[__I]) { return false; } } return true; }; if (__M.verifyMode !== null) { var __Sp = __M.verifyMode.spec; __M.verifyMode = null; var __C = 0; for (var __J = 0; __J < __M.calls.length; __J++) { var __Cl = __M.calls[__J]; if (__Cl.id === __Id && __Cl.method === __Me && __Mt(__Ms, __Cl.keys)) { __C += 1; } } var __Ok = __Sp === -1 ? __C >= 1 : __C === __Sp; if (!__Ok) { var __W = __Sp === -1 ? "at least 1" : "exactly " + __Sp; var __R = __M.calls.filter(function(__Cl){ return __Cl.id === __Id && __Cl.method === __Me; }).map(function(__Cl){ return __Me + "(" + __Cl.keys.join(", ") + ")"; }); throw new Error("mocks.verify: " + __Me + " - expected " + __W + " matching call(s), got " + __C + (__R.length ? " [recorded: " + __R.join("; ") + "]" : " [no calls recorded]")); } return __Df; } __M.calls.push({ id: __Id, method: __Me, keys: __Ks, matchers: __Ms }); for (var __I2 = __M.stubs.length - 1; __I2 >= 0; __I2--) { var __St = __M.stubs[__I2]; if (__St.id === __Id && __St.method === __Me && __Mt(__St.matchers, __Ks)) { if (__St.action.kind === "throw") { throw new Error(__St.action.value); } return __St.action.value; } } return __Df; })(this.__id, "all", [], []);
    }
}
UserRepo__Mock.prototype.__bp = "UserRepo.Mock";
UserRepo__Mock.prototype["__bp_b_std@testing@mocks@@UserRepo"] = true;

class Greeter__Mock {
    constructor(__id) {
        this.__id = __id;
    }

    greet(name) {
        return (function(__Id, __Me, __Ks, __Df){ var __M = (globalThis.__bp_mocks ||= { counter: 0, calls: [], stubs: [], pending: [], pendingStub: null, verifyMode: null }); var __Ms; if (__M.pending.length === __Ks.length) { __Ms = __M.pending.slice(); } else { __Ms = __Ks.map(function(__K){ return { kind: "eq", key: __K }; }); } __M.pending = []; var __Mt = function(__A, __B){ if (__A.length !== __B.length) { return false; } for (var __I = 0; __I < __B.length; __I++) { if (__A[__I].kind === "any") { continue; } if (__A[__I].key !== __B[__I]) { return false; } } return true; }; if (__M.verifyMode !== null) { var __Sp = __M.verifyMode.spec; __M.verifyMode = null; var __C = 0; for (var __J = 0; __J < __M.calls.length; __J++) { var __Cl = __M.calls[__J]; if (__Cl.id === __Id && __Cl.method === __Me && __Mt(__Ms, __Cl.keys)) { __C += 1; } } var __Ok = __Sp === -1 ? __C >= 1 : __C === __Sp; if (!__Ok) { var __W = __Sp === -1 ? "at least 1" : "exactly " + __Sp; var __R = __M.calls.filter(function(__Cl){ return __Cl.id === __Id && __Cl.method === __Me; }).map(function(__Cl){ return __Me + "(" + __Cl.keys.join(", ") + ")"; }); throw new Error("mocks.verify: " + __Me + " - expected " + __W + " matching call(s), got " + __C + (__R.length ? " [recorded: " + __R.join("; ") + "]" : " [no calls recorded]")); } return __Df; } __M.calls.push({ id: __Id, method: __Me, keys: __Ks, matchers: __Ms }); for (var __I2 = __M.stubs.length - 1; __I2 >= 0; __I2--) { var __St = __M.stubs[__I2]; if (__St.id === __Id && __St.method === __Me && __Mt(__St.matchers, __Ks)) { if (__St.action.kind === "throw") { throw new Error(__St.action.value); } return __St.action.value; } } return __Df; })(this.__id, "greet", [JSON.stringify(name)], "");
    }
}
Greeter__Mock.prototype.__bp = "Greeter.Mock";
Greeter__Mock.prototype["__bp_b_std@testing@mocks@@Greeter"] = true;

Object.defineProperty(exports, "__bp_priv__", { value: { failure, newMock, key, pushMatcher, invoke, beginVerify, whenCall, thenReturnCell, thenThrowCell, eq, anyInt, anyString, atLeastOnce, times, never, Stub, when, verify, raisedText, UserRepo, UserService, Greeter, UserRepo__Mock, Greeter__Mock } });
