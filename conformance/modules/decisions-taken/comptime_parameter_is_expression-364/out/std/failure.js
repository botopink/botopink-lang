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

function __bp_task(p) {
    const t = p.then((r) => { if (r != null && "error" in r) { t.__bp_failure = true; throw r.error; } return (r == null) ? r : r.ok; });
    t.__bp_fails = true;
    t.catch(() => {});
    return t;
}

function __bp_await(t) {
    return (t != null && t.__bp_fails === true) ? t.then((v) => ({ ok: v }), (e) => { if (t.__bp_failure === true) { return { error: e }; } throw e; }) : t;
}

//// std/failure — the two records a failure that is not a typed error carries

//// (decisions 431, 492).

//// 

//// `HostError` is what a host binding that writes `result: true` answers on

//// the `Error` side: the host's message and `kind`, always `"host"`.

//// `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`

//// (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise

//// from a binding without `result: true`) or `crash` (a VM or emitted-code

//// fault, a wasm trap).

//// 

//// `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`

//// for a raise it caught — the one way to contain a crash (decision 431 (3)).

//// `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,

//// awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read

//// back by `await` like any failing task (decision 432). The kinds

//// (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`

//// and an integer overflow or division by zero are `panic`, their message

//// the text the program wrote. A raise of a binding declared outside std without

//// `result: true` is `host` (decision 546), its message the host's text — on

//// commonJS an `Error`'s `message`, else `String(e)`, the call run through

//// `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is

//// `crash`, its message the same text. On erlang and beam a

//// host raise is the raise of a binding declared outside std without `result:

//// true` — a library's or the program's, whose calls are wrapped to mark it

//// (decision 546) — its message the reason by `~tp` (decision 489's reading);

//// a raise nothing marked, a failing match or a std binding's, is `crash`,

//// its message the reason by `~tp` too.

//// 

//// Both are bodyless: each backend wraps the call (a JavaScript `try` /

//// rejection handler, an erlang `try … catch`; beam compiles the erlang

//// form). On wasm (decision 518) each is a private body over `caught`, the

//// `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that

//// catches the program's aborts (wasm exception handling), so the binding

//// declares `needs: [.Exceptions]` and a program reaching it runs with the

//// host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort

//// is `panic`; a trap (an overflow or a division by zero there, a host

//// fault) is no exception and is not caught. `attemptTask` contains what

//// the thunk raises before the task's first `await`.

class HostErrorName {
    toString() {
        return __bp_text(this);
    }
}
HostErrorName.prototype.__bp = "HostErrorName";
class HostErrorName$Error extends HostErrorName {
}
HostErrorName$Error.prototype.tag = "Error";
class HostErrorName$Throw extends HostErrorName {
}
HostErrorName$Throw.prototype.tag = "Throw";
class HostErrorName$Exit extends HostErrorName {
}
HostErrorName$Exit.prototype.tag = "Exit";
HostErrorName.Error = new HostErrorName$Error();
HostErrorName.Throw = new HostErrorName$Throw();
HostErrorName.Exit = new HostErrorName$Exit();
exports.HostErrorName = HostErrorName;

class HostError {
    constructor(message, kind, name, detail) {
        this.message = message;
        this.kind = kind;
        this.name = name;
        this.detail = detail;
    }
}
HostError.prototype.__bp = "HostError";
exports.HostError = HostError;

class Failure {
    constructor(message, kind) {
        this.message = message;
        this.kind = kind;
    }
}
Failure.prototype.__bp = "Failure";
exports.Failure = Failure;

// Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops

// with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.

// Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`

// inside std); `panic("not implemented")` is what `todo` was.

// panic: per-call template (see annotation)
function panic(message) { return (() => { throw Object.defineProperty(new Error(message), '__bp_panic', { value: true }) })(); }
exports.panic = panic;

// The Node forms read an abort by the `__bp_panic` mark the backend puts on

// every one it raises — `panic`, `@todo`, an integer overflow or division

// by zero, a failed `assert` (whose mark carries its message) — or a test

// body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the

// backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,

// M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task

// (decision 432): marked `__bp_fails`, resolved with the value, rejected with

// the `Failure` (`__bp_failure`); a failing task `f` answers is read as

// `await` reads it.

// attempt: per-call template (see annotation)
function attempt(f) { return ((__f, __k) => { try { return { ok: __f() }; } catch (__e) { return { error: __k(__e) }; } })(f, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash"))); }
exports.attempt = attempt;

// attemptTask: per-call template (see annotation)
function attemptTask(f) { return ((__f, __k) => { const __t = (async () => { const __x = __f(); return (__x != null && __x.__bp_fails === true) ? await __x.then((__v) => ({ ok: __v }), (__e) => { if (__x.__bp_failure === true) { return { error: __e }; } throw __e; }) : await __x; })().then((__v) => __v, (__e) => { __t.__bp_failure = true; throw __k(__e); }); __t.__bp_fails = true; __t.catch(() => {}); return __t; })(f, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash"))); }
exports.attemptTask = attemptTask;

// wasm's form (decision 518): the thunk's value, or the message of the abort

// it raised — `Error` of the abort's text, which `attempt` makes a `panic`.

// The bodies over it are compiled on every target, so it has a form on each;

// only wasm calls it (`attempt`'s own forms answer elsewhere).

// caught: per-call template (see annotation)

function attemptOnWasm(f) {
    const _case0 = (() => {
        const _s = ((__f) => { try { return { ok: __f() }; } catch (__e) { return { error: (__e instanceof Error) ? __e.message : String(__e) }; } })(f);
        if ("ok" in _s) {
            const v = _s.ok;
            return ({ __bp_return: true, value: ({ ok: v }) });
        }
        if ("error" in _s) {
            const m = _s.error;
            return ({ __bp_return: true, value: ({ error: new Failure(m, "panic") }) });
        }
        throw new Error("case_clause");
    })();
    if (_case0 && _case0.__bp_return) return _case0.value;
}

// The task the thunk started — or the `Failure` it raised before its first

// `await` — and then its value.

function attemptTaskOnWasm(f) {
    return __bp_task((async () => {
        const _case0 = await (async () => {
            const _s = ((__f) => { try { return { ok: __f() }; } catch (__e) { return { error: (__e instanceof Error) ? __e.message : String(__e) }; } })(f);
            if ("ok" in _s) {
                const t = _s.ok;
                return ({ __bp_return: true, value: ({ ok: await __bp_await(t) }) });
            }
            if ("error" in _s) {
                const m = _s.error;
                return ({ __bp_return: true, value: ({ error: new Failure(m, "panic") }) });
            }
            throw new Error("case_clause");
        })();
        if (_case0 && _case0.__bp_return) return _case0.value;
    })());
}

Object.defineProperty(exports, "__bp_priv__", { value: { HostErrorName, HostErrorName$Error, HostErrorName$Throw, HostErrorName$Exit, HostError, Failure, panic, attempt, attemptTask, attemptOnWasm, attemptTaskOnWasm } });
