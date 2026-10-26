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

//// std/io/process — host process introspection, cross-backend.

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/process.html

////              (`process.exit`, `process.cwd`, `process.platform`,

////               `process.pid`)

////   Erlang   — https://www.erlang.org/doc/apps/stdlib/erlang.html#halt-1

////              (`erlang:halt/1`, `file:get_cwd/0`, `os:type/0`,

////               `os:getpid/0`)

//// 

//// Most calls are method-on-class chains (`process.cwd()`, `os.getpid()`)

//// or property reads (`process.platform`). The §A2 commonJS template

//// dispatch (`a7c6d07`) + erlang twin (`52d6101`) make both shapes

//// feasible without the legacy alias path that strips the receiver.

//// 

//// The 0-arg fns use the `when(argc == 0): "<tmpl>"` arity-branched

//// shape rather than a bare template string —

//// `primOpTemplate.looksLikeTemplate` reads the `$` discriminator, and

//// a 0-arg lowering has no `$N` to embed, so the arity branch keeps

//// the template-path dispatch.

const { HostError } = require("../../std/failure.js");

// Exit the current process with the given status code.

// Node: `process.exit(code)` (chained method — §A2 template).

// Erlang: `erlang:halt(code)` (bare BIF).

// exit: per-call template (see annotation)
function exit(code) { return process.exit(code); }
exports.exit = exit;

// Current working directory of the host process.

// Node: `process.cwd()` (method on `process` — §A2 template).

// Erlang: `file:get_cwd()` returns `{ok, Path}` (charlist); the

// template extracts and stringifies it.

// cwd: per-call template (see annotation)
function cwd() { return process.cwd(); }
exports.cwd = cwd;

// Host platform string — `'linux'`, `'darwin'`, `'win32'`, etc.

// Node: bare `process.platform` (property access).

// Erlang: `os:type()` returns `{unix, linux}` / `{win32, nt}` /

// `{unix, darwin}`; the template extracts the SECOND element (the

// flavor, matching the Node `process.platform` shape) and stringifies

// it. Read-time match — the first element is the family (unix/win32).

// platform: per-call template (see annotation)
function platform() { return process.platform; }
exports.platform = platform;

// Host process id.

// Node: `process.pid` (property — i32 in JS, stored as Number).

// Erlang: `os:getpid()` returns a string list; the template parses

// it to an integer.

// pid: per-call template (see annotation)
function pid() { return process.pid; }
exports.pid = pid;

// ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

// 

// Child processes. The five introspections above are not edited. Signals

// (`onSignal`) are not here: a closure handed to a host cell is unverified on

// the Erlang target (`language-gaps.md`).

// What a child process left behind. `stderr` is split out on Node; on Erlang

// the port folds it into `stdout` (`stderr_to_stdout`) and `stderr` is `""`

// — a caller that needs the two apart on both targets redirects through a

// file and says so.

class Exit {
    constructor(status, stdout, stderr) {
        this.status = status;
        this.stdout = stdout;
        this.stderr = stderr;
    }
}
Exit.prototype.__bp = "Exit";
exports.Exit = Exit;

// Run the executable `cmd` (looked up on `PATH` when it has no `/`) with

// `args`, no shell, and wait for it. A process that RAN is `Ok` whatever its

// status — a non-zero exit is an `Exit` carrying that status. `Error` means

// it could not be started (not found, not executable).

// Node: `child_process.spawnSync`; a start failure is `r.error`, which the

// template throws.

// Erlang: `open_port({spawn_executable, Path}, [exit_status, …])`, the path

// from `os:find_executable/1`, the output gathered until `exit_status`; a

// missing executable is `{error, enoent}`, a port that cannot open raises.

// Both run under `result: true` (decisions 431, 490); the answer is the host's

// `HostError`, not a `ProcessError` of std's own: a public function over the

// cell would be a body calling a cell with no wasm binding, which wasm refuses

// for the whole module — `import {io.process}` would stop compiling there.

function run(cmd, args) { return __bp_host_result(require("../../std/failure.js"), () => __bp_adopt((() => { const __r = require('child_process').spawnSync(cmd, args, { encoding: 'utf8' }); if (__r.error) throw __r.error; return { status: __r.status ?? -1, stdout: __r.stdout ?? '', stderr: __r.stderr ?? '' } })(), Exit, "")); }
exports.run = run;

// Run `cmd` through `/bin/sh -c` and answer its output, stdout and stderr

// together. STATUS-LOSING on both targets: the answer is text only, so a

// failing command is indistinguishable from a quiet one — `os:cmd/1` answers

// output only on Erlang, and the Node cell matches it. Use `run` when the

// status matters.

// Node: `spawnSync('/bin/sh', ['-c', 'exec 2>&1; ' + cmd])`.

// Erlang: `os:cmd/1` (which runs `/bin/sh -c` and folds stderr in).

// runShell: per-call template (see annotation)
function runShell(cmd) { return (require('child_process').spawnSync('/bin/sh', ['-c', 'exec 2>&1; ' + cmd], { encoding: 'utf8' }).stdout ?? ''); }
exports.runShell = runShell;

// ── signals and spawned children (decision 506 (1)) ────────────────────────────

// 

// `onSignal` runs a handler when the process receives a signal; `spawn` starts a child

// that shares the parent's terminal and answers a `Child` the program waits for, signals

// or asks to carry the parent's own signals over (`forwardSignals`). Every failure is a

// `ProcessError` of this module (decision 431-a). There is no wasm binding: a call is

// refused at the call (`std-unsupported-on-target`, decision 518 (4)).

// The signals a program can ask to hear about, and send a child.

class Signal {
    toString() {
        return __bp_text(this);
    }
}
Signal.prototype.__bp = "Signal";
class Signal$Int extends Signal {
}
Signal$Int.prototype.tag = "Int";
class Signal$Term extends Signal {
}
Signal$Term.prototype.tag = "Term";
class Signal$Hup extends Signal {
}
Signal$Hup.prototype.tag = "Hup";
class Signal$Winch extends Signal {
}
Signal$Winch.prototype.tag = "Winch";
Signal.Int = new Signal$Int();
Signal.Term = new Signal$Term();
Signal.Hup = new Signal$Hup();
Signal.Winch = new Signal$Winch();
exports.Signal = Signal;

// The error of `onSignal`, `spawn` and `Child.kill`.

class ProcessError {
    static NotFound(command) {
        return new ProcessError$NotFound(command);
    }

    static PermissionDenied(command) {
        return new ProcessError$PermissionDenied(command);
    }

    static NoSuchProcess(pid) {
        return new ProcessError$NoSuchProcess(pid);
    }

    static Unsupported(message) {
        return new ProcessError$Unsupported(message);
    }

    static Other(message) {
        return new ProcessError$Other(message);
    }

    toString() {
        return __bp_text(this);
    }
}
ProcessError.prototype.__bp = "ProcessError";
class ProcessError$NotFound extends ProcessError {
    constructor(command) {
        super();
        this.command = command;
    }

    get $0() {
        return this.command;
    }
}
ProcessError$NotFound.prototype.tag = "NotFound";
class ProcessError$PermissionDenied extends ProcessError {
    constructor(command) {
        super();
        this.command = command;
    }

    get $0() {
        return this.command;
    }
}
ProcessError$PermissionDenied.prototype.tag = "PermissionDenied";
class ProcessError$NoSuchProcess extends ProcessError {
    constructor(pid) {
        super();
        this.pid = pid;
    }

    get $0() {
        return this.pid;
    }
}
ProcessError$NoSuchProcess.prototype.tag = "NoSuchProcess";
class ProcessError$Unsupported extends ProcessError {
    constructor(message) {
        super();
        this.message = message;
    }

    get $0() {
        return this.message;
    }
}
ProcessError$Unsupported.prototype.tag = "Unsupported";
class ProcessError$Other extends ProcessError {
    constructor(message) {
        super();
        this.message = message;
    }

    get $0() {
        return this.message;
    }
}
ProcessError$Other.prototype.tag = "Other";
exports.ProcessError = ProcessError;

function signalName(s) {
    return (() => {
        const _s = s;
        if (_s.tag === "Int") return "SIGINT";
        if (_s.tag === "Term") return "SIGTERM";
        if (_s.tag === "Hup") return "SIGHUP";
        if (_s.tag === "Winch") return "SIGWINCH";
        throw new Error("case_clause");
    })();
}

// The host cells answer `<kind>|<host text>` as their error, `kind` one of `notfound`,

// `denied`, `gone`, `unsupported`, `other`.

function processError(subject, pid, raw) {
    let raw$sp = null;
    const bar = ((raw$sp ??= __bp_has_surrogate(raw)) ? __bp_str_index_of(raw, "|") : raw.indexOf("|"));
    const kind = raw.slice(0, bar);
    const message = raw.slice(__bp_int((bar + 1), -2147483648, 2147483647, "+ on i32 at src/io/process.bp:151:33"), null);
    if ((kind === "notfound")) { return ProcessError.NotFound(subject); }
    if ((kind === "denied")) { return ProcessError.PermissionDenied(subject); }
    if ((kind === "gone")) { return ProcessError.NoSuchProcess(pid); }
    if ((kind === "unsupported")) { return ProcessError.Unsupported(message); }
    return ProcessError.Other(message);
}

// Run `handler` each time the process receives `name`.

// Node: `process.on(name, handler)`; a signal listener does not keep the process alive, and

// it replaces the default action (the process no longer exits on `SIGTERM`).

// Erlang: `os:set_signal(Signal, handle)` sends the event to `erl_signal_server`, whose

// default handler stops the node on `sigterm`; the cell removes that handler and adds one of its

// own, a module (`bp_signal_handler`) compiled and loaded on first use that calls, in order, the

// funs kept for the signal in `persistent_term`. `SIGINT` is not an `os:set_signal` signal: the VM keeps it for its

// break handler, so it is `unsupported|…` there. `SIGWINCH` needs OTP 28.

// rawOnSignal: per-call template (see annotation)

// Run `handler` when the process receives `s`. A handler stays for the life of the process,

// and several for one signal all run, in the order they were added. While one is installed the

// signal no longer ends the process: ending it is the handler's business (`exit`). `Int` is

// `Unsupported` on erlang and beam, where the VM keeps `SIGINT` for itself.

function onSignal(s, handler) {
    const _case0 = (() => {
        const _s = (() => { try { process.on(signalName(s), handler); return { ok: 0 } } catch (__e) { return { error: 'other|' + (__e && __e.message ? __e.message : String(__e)) } } })();
        if ("ok" in _s) {
            return ({ __bp_return: true, value: ({ ok: null }) });
        }
        if ("error" in _s) {
            const m = _s.error;
            return ({ __bp_return: true, value: ({ error: processError("", 0, m) }) });
        }
        throw new Error("case_clause");
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}
exports.onSignal = onSignal;

// A child process handle: the OS process id and the host's own handle, opaque.

class Child {
    constructor(pid, handle) {
        this.pid = pid;
        this.handle = handle;
    }

    async wait() {
        return await this.handle.bpDone;
    }

    kill(s) {
        const _case1 = (() => {
            const _s = (() => { const __h = this.handle; if (__h.exitCode !== null || __h.signalCode !== null) return { error: 'gone|' + __h.pid }; try { process.kill(__h.pid, signalName(s)); return { ok: 0 }; } catch (__e) { return { error: (__e && __e.code === 'ESRCH' ? 'gone' : 'other') + '|' + (__e && __e.message ? __e.message : String(__e)) } } })();
            if ("ok" in _s) {
                return ({ __bp_return: true, value: ({ ok: null }) });
            }
            if ("error" in _s) {
                const m = _s.error;
                return ({ __bp_return: true, value: ({ error: processError("", this.pid, m) }) });
            }
            throw new Error("case_clause");
        })();
        if (_case1 && _case1.__bp_return) return _case1.value;
    }

    forwardSignals() {
        try {
            const h = this.handle;
            for (const s of [Signal.Int, Signal.Term, Signal.Hup, Signal.Winch]) {
    const name = signalName(s);
    (() => {
            const _s = (() => { try { process.on(name, () => {
    return (() => { const __h = h; if (__h.exitCode !== null || __h.signalCode !== null) return { error: 'gone|' + __h.pid }; try { process.kill(__h.pid, name); return { ok: 0 }; } catch (__e) { return { error: (__e && __e.code === 'ESRCH' ? 'gone' : 'other') + '|' + (__e && __e.message ? __e.message : String(__e)) } } })();
}); return { ok: 0 } } catch (__e) { return { error: 'other|' + (__e && __e.message ? __e.message : String(__e)) } } })();
            if ("ok" in _s) {
                return;
            }
            if ("error" in _s) {
                const m = _s.error;
                const e = processError("", this.pid, m);
                return (() => {
                    const _s = e;
                    if (_s.tag === "Unsupported") {
                        return;
                    }
                    throw ({ __bp_try: ({ error: e }) });
                })();
            }
            throw new Error("case_clause");
        })();
}
            return ({ ok: null });
        } catch (__e) {
            if (__e !== null && typeof __e === "object" && "__bp_try" in __e) { return __e.__bp_try; }
            throw __e;
        }
    }
}
Child.prototype.__bp = "Child";
exports.Child = Child;

// The handle of `cmd` started with `args`, no shell, sharing the parent's standard streams.

// `cmd` is looked up on `PATH` when it has no `/`. Failure kinds are told before anything starts.

// Node: `child_process.spawn(file, args, { stdio: 'inherit' })`, the exit read from its `exit`

// event.

// Erlang: `open_port({spawn_executable, File}, [binary, exit_status, stderr_to_stdout, …])`.

// rawSpawn: per-call template (see annotation)

// rawPid: per-call template (see annotation)

// rawWait: per-call template (see annotation)

// rawKill: per-call template (see annotation)

// Start `cmd` with `args` (no shell) and answer its `Child` without waiting for it. The child

// shares the parent's terminal; `Child.wait` waits for it, `Child.kill` signals it and

// `Child.forwardSignals` carries the parent's signals to it. `NotFound` / `PermissionDenied`

// say why nothing started. `run` is the one that waits and captures the output.

function spawn(cmd, args) {
    const _case0 = (() => {
        const _s = (() => { const __fs = require('fs'); const __cp = require('child_process'); const __c = cmd; let __f = null; if (__c.includes('/')) { __f = __c; } else { for (const __d of (process.env.PATH ?? '').split(':')) { if (!__d) continue; const __p = __d + '/' + __c; try { __fs.accessSync(__p, __fs.constants.X_OK); if (__fs.statSync(__p).isFile()) { __f = __p; break; } } catch (__e) {} } } if (__f === null) return { error: 'notfound|' + __c }; try { __fs.accessSync(__f, __fs.constants.F_OK); } catch (__e) { return { error: 'notfound|' + __c }; } try { if (__fs.statSync(__f).isDirectory()) return { error: 'denied|' + __c }; __fs.accessSync(__f, __fs.constants.X_OK); } catch (__e) { return { error: 'denied|' + __c }; } try { const __h = __cp.spawn(__f, args, { stdio: 'inherit' }); __h.bpDone = new Promise((__r) => { __h.on('exit', (__code, __sig) => __r(__code ?? (128 + (require('os').constants.signals[__sig] ?? 0)))); __h.on('error', () => __r(-1)); }); return { ok: __h }; } catch (__e) { return { error: 'other|' + (__e && __e.message ? __e.message : String(__e)) } } })();
        if ("ok" in _s) {
            const h = _s.ok;
            return ({ __bp_return: true, value: ({ ok: new Child(h.pid, h) }) });
        }
        if ("error" in _s) {
            const m = _s.error;
            return ({ __bp_return: true, value: ({ error: processError(cmd, 0, m) }) });
        }
        throw new Error("case_clause");
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}
exports.spawn = spawn;

// ── captured children (decision 790, 798 (6)) ───────────────────────────────────

// 

// `start` is `spawn` with the child's output captured apart: stdout and stderr each into a

// string, the answer of `Captured.wait` an `Exit`. Several started children run at once, and

// their `wait`s may be awaited together (`async.runAll`). It exists on commonJS alone: an erlang port

// folds stderr into stdout, and `Captured` keeps the two apart. The host declarations below have no

// erlang, beam or wasm binding, so a call to `start` is refused at the call there

// (`std-unsupported-on-target`, decisions 518 (4), 906) while the module still imports and `run` / `spawn`

// are unchanged. The programs that need the two apart (`cell check`'s, decision 790) run on commonJS.

// Start `cmd` with `args` (no shell), in `cwd` (the parent's when absent), with the parent's environment

// plus `env` (each entry `NAME=value`, the first `=` ends the name). `cmd` is looked up on `PATH` when it has no `/`;

// a `/` path is read from `cwd`. Failure kinds are told before anything starts, as in `spawn`; an `env` entry

// with no `=` or an empty name answers `Other` naming it.

// Node: `child_process.spawn(file, args, { cwd, env, stdio: ['ignore', 'pipe', 'pipe'] })`, the

// exit read from its `close` event.

// rawStart: per-call template (see annotation)

// rawWaitCaptured: per-call template (see annotation)

// rawStartedPid: per-call template (see annotation)

// `kill` of a started child: the host cell of `Child.kill` (`rawKill`) reads only the handle.

// rawKillStarted: per-call template (see annotation)

// A started child whose output is captured: the OS process id and the host's own handle, opaque.

class Captured {
    constructor(pid, handle) {
        this.pid = pid;
        this.handle = handle;
    }

    async wait() {
        return await this.handle.bpDone;
    }

    kill(s) {
        const _case1 = (() => {
            const _s = (() => { const __h = this.handle; if (__h.exitCode !== null || __h.signalCode !== null) return { error: 'gone|' + __h.pid }; try { process.kill(__h.pid, signalName(s)); return { ok: 0 }; } catch (__e) { return { error: (__e && __e.code === 'ESRCH' ? 'gone' : 'other') + '|' + (__e && __e.message ? __e.message : String(__e)) } } })();
            if ("ok" in _s) {
                return ({ __bp_return: true, value: ({ ok: null }) });
            }
            if ("error" in _s) {
                const m = _s.error;
                return ({ __bp_return: true, value: ({ error: processError("", this.pid, m) }) });
            }
            throw new Error("case_clause");
        })();
        if (_case1 && _case1.__bp_return) return _case1.value;
    }
}
Captured.prototype.__bp = "Captured";
exports.Captured = Captured;

// Start `cmd` with `args` (no shell) in `cwd` with `env` added to the parent's environment, and answer its

// `Captured` without waiting for it. `NotFound` / `PermissionDenied` say why nothing started.

// commonJS only (see above).

function start(cmd, args, cwd, env) {
    const _case0 = (() => {
        const _s = (() => { const __fs = require('fs'); const __cp = require('child_process'); const __pa = require('path'); const __c = cmd; const __cwd = cwd ?? undefined; let __f = null; if (__c.includes('/')) { __f = __pa.resolve(__cwd ?? process.cwd(), __c); } else { for (const __d of (process.env.PATH ?? '').split(':')) { if (!__d) continue; const __p = __d + '/' + __c; try { __fs.accessSync(__p, __fs.constants.X_OK); if (__fs.statSync(__p).isFile()) { __f = __p; break; } } catch (__e) {} } } if (__f === null) return { error: 'notfound|' + __c }; try { __fs.accessSync(__f, __fs.constants.F_OK); } catch (__e) { return { error: 'notfound|' + __c }; } try { if (__fs.statSync(__f).isDirectory()) return { error: 'denied|' + __c }; __fs.accessSync(__f, __fs.constants.X_OK); } catch (__e) { return { error: 'denied|' + __c }; } const __env = Object.assign({}, process.env); for (const __kv of env) { const __i = __kv.indexOf('='); if (__i <= 0) return { error: 'other|env entry `' + __kv + '` is not NAME=value' }; __env[__kv.slice(0, __i)] = __kv.slice(__i + 1); } try { const __h = __cp.spawn(__f, args, { cwd: __cwd, env: __env, stdio: ['ignore', 'pipe', 'pipe'] }); let __o = ''; let __e = ''; __h.stdout.setEncoding('utf8'); __h.stderr.setEncoding('utf8'); __h.stdout.on('data', (__d) => { __o += __d; }); __h.stderr.on('data', (__d) => { __e += __d; }); __h.bpDone = new Promise((__r) => { __h.on('close', (__code, __sig) => __r({ status: __code ?? (128 + (require('os').constants.signals[__sig] ?? 0)), stdout: __o, stderr: __e })); __h.on('error', (__x) => __r({ status: -1, stdout: __o, stderr: __e + String(__x && __x.message ? __x.message : __x) })); }); return { ok: __h }; } catch (__e) { return { error: 'other|' + (__e && __e.message ? __e.message : String(__e)) } } })();
        if ("ok" in _s) {
            const h = _s.ok;
            return ({ __bp_return: true, value: ({ ok: new Captured(h.pid, h) }) });
        }
        if ("error" in _s) {
            const m = _s.error;
            return ({ __bp_return: true, value: ({ error: processError(cmd, 0, m) }) });
        }
        throw new Error("case_clause");
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}
exports.start = start;

// ── tests ────────────────────────────────────────────────────────────────────

Object.defineProperty(exports, "__bp_priv__", { value: { HostError, exit, cwd, platform, pid, Exit, run, runShell, Signal, Signal$Int, Signal$Term, Signal$Hup, Signal$Winch, ProcessError, ProcessError$NotFound, ProcessError$PermissionDenied, ProcessError$NoSuchProcess, ProcessError$Unsupported, ProcessError$Other, signalName, processError, onSignal, Child, spawn, Captured, start } });
