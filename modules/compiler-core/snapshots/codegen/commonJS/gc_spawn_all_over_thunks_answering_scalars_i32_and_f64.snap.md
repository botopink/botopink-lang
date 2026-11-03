----- SOURCE CODE -- std/failure.bp
```botopink
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

import {compiler};

pub type HostErrorName {
    Error,
    Throw,
    Exit,
}

pub type HostError(message: string, kind: string, name: HostErrorName, detail: ?string)

pub type Failure(message: string, kind: string)

// Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
// with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
// Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
// inside std); `panic("not implemented")` is what `todo` was.
#[compiler.external(
    .Erlang("erlang:error({panic, $0})"),
    .JavaScript("(() => { throw Object.defineProperty(new Error($0), '__bp_panic', { value: true }) })()"),
)]
pub declare fn panic(message: string = "panic") -> noreturn;

// The Node forms read an abort by the `__bp_panic` mark the backend puts on
// every one it raises — `panic`, `@todo`, an integer overflow or division
// by zero, a failed `assert` (whose mark carries its message) — or a test
// body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
// backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
// M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
// (decision 432): marked `__bp_fails`, resolved with the value, rejected with
// the `Failure` (`__bp_failure`); a failing task `f` answers is read as
// `await` reads it.
#[compiler.external(
    .JavaScript("""((__f, __k) => { try { return { ok: __f() }; } catch (__e) { return { error: __k(__e) }; } })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptOnWasm),
)]
pub declare fn attempt<T>(f: fn() -> T) -> Result<T, Failure>;

#[compiler.external(
    .JavaScript("""((__f, __k) => { const __t = (async () => { const __x = __f(); return (__x != null && __x.__bp_fails === true) ? await __x.then((__v) => ({ ok: __v }), (__e) => { if (__x.__bp_failure === true) { return { error: __e }; } throw __e; }) : await __x; })().then((__v) => __v, (__e) => { __t.__bp_failure = true; throw __k(__e); }); __t.__bp_fails = true; __t.catch(() => {}); return __t; })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptTaskOnWasm),
)]
pub declare fn attemptTask<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>>;

// wasm's form (decision 518): the thunk's value, or the message of the abort
// it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
// The bodies over it are compiled on every target, so it has a form on each;
// only wasm calls it (`attempt`'s own forms answer elsewhere).
#[compiler.external(
    .JavaScript("""((__f) => { try { return { ok: __f() }; } catch (__e) { return { error: (__e instanceof Error) ? __e.message : String(__e) }; } })($0)"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch _:__R -> {error, unicode:characters_to_binary(io_lib:format("~tp", [__R]))} end end)($0)"""),
    .Wasm(wasi: .Attempt, needs: [.Exceptions]),
)]
declare fn caught<T>(f: fn() -> T) -> Result<T, string>;

fn attemptOnWasm<T>(f: fn() -> T) -> Result<T, Failure> {
    case caught(f) {
        Ok(v) -> return v;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

// The task the thunk started — or the `Failure` it raised before its first
// `await` — and then its value.
async fn attemptTaskOnWasm<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>> {
    case caught(f) {
        Ok(t) -> return await t;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

```

----- JAVASCRIPT -- std/failure.js
```javascript
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
    if ((typeof v === "function")) return ("fn/" + (v.__bp_arity ?? v.length));
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
```

----- TYPESCRIPT TYPEDEF -- std/failure.d.ts
```typescript
export declare class HostErrorName {
    readonly tag: "Error" | "Throw" | "Exit";
    static readonly Error: HostErrorName;
    static readonly Throw: HostErrorName;
    static readonly Exit: HostErrorName;
}


export declare class HostError {
    readonly message: string;
    readonly kind: string;
    readonly name: HostErrorName;
    readonly detail: string | null;
    constructor(message: string, kind: string, name: HostErrorName, detail: string | null);
}


export declare class Failure {
    readonly message: string;
    readonly kind: string;
    constructor(message: string, kind: string);
}


export declare function panic(message: string): never;


export declare function attempt<T>(f: () => T): { ok: T } | { error: Failure };


/** @throws {Failure} */
export declare function attemptTask<T>(f: () => Promise<T>): Promise<T>;







```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/async.bp
```botopink
//// std/async — combinators over `Async<T>` (decisions 120 and 121 of
//// 1.0.10-beta, front 24 step E7).
////
//// An operation that can go wrong answers `Async<Result<T, E>>` — the task
//// that fails with `E` (decision 432): on commonJS its Promise rejects with
//// `E`, and `await` reads the rejection back as `Error(e)`. The combinators
//// here read that `Result`: a host cell that awaits the tasks itself
//// (`runAll`, `raceOf`, `race`) reads a failing task's rejection as the
//// `{ error }` value `await` would answer, so nothing here hides a failure
//// by swallowing one, and a crash stays a crash.
////
//// THE ERLANG DIVERGENCE, AT THE TOP RATHER THAN IN A FOOTNOTE.
//// `Async<T>` lowers EAGERLY on the erlang backend: a `-> Async` fn is a plain
//// function, `await` is identity, and a Async is therefore a value that has
//// already run (`codegen/erlang.zig` — the `Async — eager lowering` arm;
//// `libs/std/src/http.bp` says the same for `http.fetch`). By the time an
//// `Array<Async<T>>` reaches a combinator on erlang, every element has already
//// finished, in list order, serially.
////
//// So this module has TWO surfaces and they do not make the same promise.
////
////   STARTED TASKS — `allOf`, `all`, `race`.
////   Take `Array<Async<…>>`, the shape the guide writes
////   (`async.allOf([fetchUser(1), fetchUser(2)])`). Concurrent on commonJS,
////   where each Async is a live Promise. On erlang it is honest rather than
////   concurrent: the Tasks resolved before the call, so `allOf` / `all` read
////   values in order and `race` answers ELEMENT ZERO rather than the fastest.
////   Both behaviours are asserted by the tests at the foot of this file, so a
////   backend change that makes erlang lazy reds a test and forces this
////   docblock to be rewritten instead of silently making it a lie.
////
////   UNSTARTED TASKS — `runAll`, `raceOf`, `timeout`, `retry`.
////   Take `fn() -> Async<T>` thunks. Because nothing has run when the
////   combinator receives them, the erlang cell can `spawn` one process per
////   task and gather the replies by index, and the commonJS cell can call each
////   thunk into `Promise.all`. Real concurrency on BOTH targets. This is the
////   surface a server front uses.
////
//// `allOf` stops at the FIRST error in input order (front 24 README, E7) — the
//// `E` is the tasks' own type, so there is no message to join; `runAll` over
//// `Async<Result<…>>` thunks answers every `Result` when the caller wants
//// them all. `allSettled` and `settleOf` left with the rejection they settled:
//// a Async has no failure to settle, and a `Result` element IS the settled
//// outcome (`specs/1.0.10-beta/decisions-pending.md` 24-g).
////
//// NO CANCELLATION. `raceOf`'s losers and `timeout`'s expired task keep
//// running to completion; there is no cancellation surface in the language.
////
//// Reference:
////   Promise.all       — https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all
////   Erlang processes  — https://www.erlang.org/doc/system/ref_man_processes.html

import {failure, failure.panic, compiler};

// ── instruments ──────────────────────────────────────────────────────────────

// Which backend is running. The future surface's erlang behaviour differs from
// its commonJS behaviour by design, and a test that asserts one of the two has
// to know which it is looking at. Private: the divergence is this module's to
// document, not a consumer's to branch on.
#[compiler.external(.JavaScript("""'commonJS'"""), .Erlang("""<<"erlang">>"""))]
declare fn hostTarget() -> string;

// The host's monotonic clock in milliseconds. `std/io/clock` has the same cell,
// and this root module may not import from `io/` (decision 106), so this file
// carries its own. Private — `clock.monotonicMillis()` is the public spelling.
#[compiler.external(.JavaScript("""Math.floor(performance.now())"""), .Erlang("erlang:monotonic_time(1000)"))]
declare fn monoMillis() -> i64;

// Answer `value` after at least `millis` milliseconds of the host's monotonic
// clock — the promise `monoMillis()` measures it by.
// Node: `setTimeout` alone does not keep that promise. A timer starts from
// libuv's CACHED loop time (whole milliseconds, read when the loop last woke),
// so a timer armed after a long synchronous stretch — a loaded machine, a busy
// test runner — fires early by that stretch. The cell reads `performance.now()`
// when it is called and re-arms for whatever is left, so it never answers
// early. The first wait is always a timer, so `delay(0, v)` still yields to the
// timers phase rather than answering in the same microtask queue.
// Erlang: `timer:sleep/1` never wakes early.
#[compiler.external(
    .JavaScript("""((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))($0, $1)"""),
    .Erlang("""(fun(__M, __V) -> timer:sleep(__M), __V end)($0, $1)"""),
    .Wasm(wasi: .Delay),
)]
pub declare fn delay<T>(millis: i32, value: T) -> Async<T>;

// A Async whose value is `Error(message)` — the failing instrument `allOf` and
// `timeout` are tested with. On commonJS it rejects with `message` (decision
// 432); `await` reads it as `Error(message)`.
pub async fn failed<T>(comptime t: type<T>, message: string) -> Async<Result<T, string>> {
    throw message;
}

// ── gates ────────────────────────────────────────────────────────────────────

// A one-shot signal between tasks: closed until `openGate`, open for good
// after. The instrument a test orders tasks with WITHOUT a clock — "task B
// answers only after task A has run" is a gate A opens and B awaits, where a
// pair of `delay`s only says "probably, unless the machine is busy".
// Node: an object holding the waiters' resolvers.
// Erlang: a process that queues `{bp_gate_wait, Pid, Ref}` requests until it
// receives `bp_gate_open`, then answers each and every later one at once —
// a pid, so the gate crosses into a spawned task like any value. It is never
// stopped: it is parked in `receive` and dies with the node.
pub type Gate(handle: unknown)

#[compiler.external(
    .JavaScript("""({ opened: false, waiters: [] })"""),
    .Erlang("""erlang:spawn(fun() -> (fun BpGateClosed(__W) -> receive {bp_gate_wait, __P, __R} -> BpGateClosed([{__P, __R} | __W]); bp_gate_open -> lists:foreach(fun({__P2, __R2}) -> __P2 ! {__R2, bp_gate_open} end, __W), (fun BpGateOpen() -> receive {bp_gate_wait, __P3, __R3} -> __P3 ! {__R3, bp_gate_open}, BpGateOpen(); bp_gate_open -> BpGateOpen() end end)() end end)([]) end)"""),
    .Wasm(wasi: .GateNew),
)]
declare fn gateHandle() -> unknown;

#[compiler.external(
    .JavaScript("""((__g) => { __g.opened = true; for (const __w of __g.waiters.splice(0)) { __w(); } return undefined; })($0)"""),
    .Erlang("""(fun(__G) -> __G ! bp_gate_open, undefined end)($0)"""),
    .Wasm(wasi: .GateOpen),
)]
declare fn gateOpen(handle: unknown) -> void;

#[compiler.external(
    .JavaScript("""((__g, __ms) => __g.opened ? Promise.resolve(true) : new Promise((__r) => { const __on = () => { clearTimeout(__t); __r(true); }; const __t = setTimeout(() => { __g.waiters = __g.waiters.filter((__w) => __w !== __on); __r(false); }, __ms); __g.waiters.push(__on); }))($0, $1)"""),
    .Erlang("""(fun(__G, __Ms) -> BpGateRef = erlang:make_ref(), __G ! {bp_gate_wait, self(), BpGateRef}, receive {BpGateRef, bp_gate_open} -> true after __Ms -> false end end)($0, $1)"""),
    .Wasm(wasi: .GateAwait),
)]
declare fn gateAwait(handle: unknown, millis: i32) -> Async<bool>;

// A new, closed gate.
pub fn newGate() -> Gate {
    return Gate(handle: gateHandle());
}

// Open `gate`: every task awaiting it answers, and so does every later
// `awaitGate`. Opening an open gate changes nothing.
pub fn openGate(gate: Gate) -> void {
    gateOpen(gate.handle);
}

// `true` once `gate` is open, `false` when `millis` pass first. The budget is
// not the ordering — the gate is; it only turns a gate nobody opens into a red
// assertion instead of a hang, so a test gives it a margin no scheduling delay
// can cross (seconds) and opens every gate it closes. An open gate answers at
// once and leaves no timer behind.
pub async fn awaitGate(gate: Gate, millis: i32) -> Async<bool> {
    return await gateAwait(gate.handle, millis);
}

// ── reading a settled element ────────────────────────────────────────────────

// The `Error` payload of a `Result<T, string>`, or `""` for `Ok`. `Result`
// carries `isOk`/`isError`/`unwrapOr` as builtins but no way to read the error
// side, so without this a caller can see THAT a widget failed and never WHY —
// the shape decision 67 refuses.
pub fn errorText<T>(settled: Result<T, string>) -> string {
    val text = case settled {
        Ok(_v) -> "";
        Error(e) -> e;
    };
    return text;
}

// ── started tasks ────────────────────────────────────────────────────────────

// The values of every Async, in input order, or the FIRST `Error` in input
// order. The tasks were started by the caller (`allOf([fetchUser(1),
// fetchUser(2)])`), so on commonJS they run concurrently and this only waits;
// on erlang they already ran. `allOf([])` answers `Ok([])`.
pub async fn allOf<T, E>(
    tasks: array<Async<Result<T, E>>>,
) -> Async<Result<array<T>, E>> {
    var out: array<T> = [];
    for (tasks) { t ->
        val v = try await t;
        out.push(v);
    }
    return out;
}

// The values of every Async, in input order — the infallible `allOf`.
pub async fn all<T>(tasks: array<Async<T>>) -> Async<array<T>> {
    var out: array<T> = [];
    for (tasks) { t ->
        val v = await t;
        out.push(v);
    }
    return out;
}

// commonJS: the FASTEST Async to answer, `Promise.race`.
// ERLANG: ELEMENT ZERO. Every Async resolved before the call, so there is no
// timing left to measure and this answers the first element of the list. That
// is not a bug to be fixed here and no server front may depend on it — use
// `raceOf`, whose tasks are unstarted when it receives them. Both behaviours
// are pinned by `async: race ---- commonJS fastest, erlang element zero`.
//
// `race([])` is a programming error, fatal on both targets
// (`async.race: empty task list`).
#[compiler.external(
    .JavaScript("""((__fs) => __fs.length === 0 ? Promise.reject(new Error('async.race: empty task list')) : Promise.race(__fs.map(((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t))))($0)"""),
    .Erlang("""(fun(__Fs) -> case __Fs of [] -> erlang:error(<<"async.race: empty task list">>); _ -> hd(__Fs) end end)($0)"""),
    .Wasm(wasi: .Race),
)]
pub declare fn race<T>(tasks: array<Async<T>>) -> Async<T>;

// ── unstarted tasks ──────────────────────────────────────────────────────────

// Run every task concurrently and answer their values in the ORDER OF THE
// INPUT rather than the order they finished. A task over a `Result` answers
// its `Result` in its slot, so `runAll` of fallible tasks is the settled
// view: nothing is hidden and nothing stops early.
//
// Node: each thunk is called and the Promises go to `Promise.all`, a failing
// task (decision 432) read as the `{ ok }` / `{ error }` value `await` reads.
// Erlang: `spawn` one process per task, each tagged `{Ref, I, Outcome}` with a
// `make_ref()` unique to THIS call — without the ref a later combinator in the
// same process would receive a loser's leftover reply — and gather by index, so
// a task that finishes first does not take another task's slot. A task that
// crashes is a crash (a crash is a bug, never a failure), re-raised here
// rather than left to block the gather.
#[compiler.external(
    .JavaScript("""Promise.all(($0).map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)())))"""),
    .Erlang("""(fun(__Ts) -> __Me = self(), BpRef = erlang:make_ref(), lists:foreach(fun(__I) -> erlang:spawn(fun() -> __Me ! {BpRef, __I, try {ok, (lists:nth(__I, __Ts))()} catch __C:__E -> {crash, __C, __E} end} end) end, lists:seq(1, length(__Ts))), [case (receive {BpRef, BpJ, __X} -> __X end) of {ok, __V} -> __V; {crash, __C2, __E2} -> erlang:raise(__C2, __E2, []) end || BpJ <- lists:seq(1, length(__Ts))] end)($0)"""),
    .Wasm(wasi: .SpawnAll),
)]
declare fn spawnAll<T>(tasks: array<fn() -> Async<T>>) -> Async<array<T>>;

// The public face of the cell above: a real function, so a module compiled
// separately (the BEAM backend links modules by name) can call it — a
// template-only `declare fn` has no body to export.
pub async fn runAll<T>(tasks: array<fn() -> Async<T>>) -> Async<array<T>> {
    return await spawnAll(tasks);
}

// The first task to ANSWER, not the first in the list. The LOSERS keep
// running and their values are discarded: there is no cancellation surface in
// botopink, and a race that reported the loser would not be a race.
//
// `raceOf([])` is a programming error, fatal on both targets
// (`async.raceOf: empty task list`), rather than blocking forever.
#[compiler.external(
    .JavaScript("""((__ts) => __ts.length === 0 ? Promise.reject(new Error('async.raceOf: empty task list')) : Promise.race(__ts.map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)()))))($0)"""),
    .Erlang("""(fun(__Ts) -> case __Ts of [] -> erlang:error(<<"async.raceOf: empty task list">>); _ -> __Me = self(), BpRef = erlang:make_ref(), lists:foreach(fun(__I) -> erlang:spawn(fun() -> __Me ! {BpRef, try {ok, (lists:nth(__I, __Ts))()} catch __C:__E -> {error, __C, __E} end} end) end, lists:seq(1, length(__Ts))), case (receive {BpRef, __W} -> __W end) of {ok, __V} -> __V; {error, __C2, __E2} -> erlang:raise(__C2, __E2, []) end end end)($0)"""),
    .Wasm(wasi: .RaceOf),
)]
pub declare fn raceOf<T>(tasks: array<fn() -> Async<T>>) -> Async<T>;

// `task`'s value as `Ok` — the racer `timeout` puts beside the clock.
async fn answered<T>(task: fn() -> Async<T>) -> Async<Result<T, string>> {
    return await task();
}

// `Error("timeout")` after `millis` — the clock `timeout` races against
// `task`, whose type it answers in (decision 668: `task` binds `T`).
async fn expireAfter<T>(task: fn() -> Async<T>, millis: i32) -> Async<Result<T, string>> {
    await delay(millis, 0);
    throw "timeout";
}

// `Ok(value)` when the task answered inside the budget, `Error("timeout")`
// when it did not. A task over a `Result` keeps its own failure INSIDE the
// `Ok` (`Ok(Error(e))`): the budget and the task's outcome are two answers,
// and neither hides the other. The task KEEPS RUNNING; the caller stops
// waiting. Expressed over `raceOf` + `delay`.
pub async fn timeout<T>(
    task: fn() -> Async<T>,
    millis: i32,
) -> Async<Result<T, string>> {
    return await raceOf(
        [
            { -> answered(task) },
            { -> expireAfter(task, millis) },
        ],
    );
}

// ── retry (1.0.11-beta front 97) ─────────────────────────────────────────────

// How a fallible task is tried again: at most `maxAttempts` attempts, a pause
// of `initialMillis` after the first failure, each later pause `multiplier`
// times the one before, none above `maxMillis`. There is no jitter and no
// field that means "for ever" (decision 67): a policy is usable only when
// `maxAttempts` is at least 1, the two delays are not negative, `maxMillis`
// is at most 2147483647 (the longest timer both targets arm) and `multiplier`
// is at least 1.0 — a backoff never shrinks, and one that could would retry
// in a near-zero-delay loop.
pub type RetryPolicy(
    maxAttempts: i32,
    initialMillis: i64,
    multiplier: f64,
    maxMillis: i64,
)

// Internal: why `policy` is not usable, `""` when it is.
fn policyProblem(policy: RetryPolicy) -> string {
    if (policy.maxAttempts < 1)
        return "maxAttempts must be at least 1 (the first attempt)";
    if (policy.initialMillis < 0) return "initialMillis must not be negative";
    if (policy.maxMillis < 0) return "maxMillis must not be negative";
    if (policy.maxMillis > 2147483647)
        return "maxMillis must be at most 2147483647";
    val grows = policy.multiplier >= 1.0;
    if (grows == false)
        return "multiplier must be at least 1.0 (a backoff never shrinks)";
    return "";
}

// Internal: an `i64` of milliseconds as an `f64`, and back — the whole
// milliseconds of a delay that is never negative. Not `toF64()`, which aborts
// on an integer past 2^53 that no `f64` holds: the delay is a float
// computation, and an `initialMillis` that large rounds as the float does
// (and is then capped by `maxMillis`). The Node forms take and answer
// decision 319's canonical form — `Number` reads a `BigInt` (`initialMillis`
// past 2^53 − 1), and a whole number past 2^53 − 1 answers as a `BigInt`.
#[compiler.external(.JavaScript("""Number($0)"""), .Erlang("""float($0)"""), .Wasm(op: "f64.convert_i64_s"))]
declare fn millisAsFloat(n: i64) -> f64;

#[compiler.external(
    .JavaScript("""((__x) => { const __f = Math.floor(__x); return Number.isSafeInteger(__f) ? __f : BigInt(__f); })($0)"""),
    .Erlang("""trunc($0)"""),
    .Wasm(op: "i64.trunc_f64_s"),
)]
declare fn wholeMillis(x: f64) -> i64;

// Internal: `initial × multiplier^(attempt − 1)`, never above `ceiling`. One
// multiplication per attempt — the same IEEE operations in the same order on
// both targets, where a host `pow` would not promise the same last bit — and
// none once the ceiling is reached, so it cannot overflow.
fn grown(initial: f64, multiplier: f64, ceiling: f64, attempt: i32) -> f64 {
    val steady = multiplier <= 1.0 || initial <= 0.0;
    if (steady) return if (initial > ceiling) ceiling else initial;
    var pause = initial;
    var step = 1;
    while (step < attempt && pause < ceiling) {
        pause = pause * multiplier;
        step = step + 1;
    }
    return if (pause > ceiling) ceiling else pause;
}

// The pause that follows attempt `attempt` (the first attempt is 1), in whole
// milliseconds: `initialMillis × multiplier^(attempt − 1)`, rounded down and
// never above `maxMillis`. `null` once `attempt` is past `maxAttempts` — there
// is no further attempt to wait for — and for an attempt below 1 or a policy
// that is not usable.
pub fn nextDelay(policy: RetryPolicy, attempt: i32) -> ?i64 {
    val usable = policyProblem(policy) == "";
    val inside = attempt >= 1 && attempt <= policy.maxAttempts;
    val answers = usable && inside;
    if (answers == false) return null;
    return wholeMillis(
        grown(
            millisAsFloat(policy.initialMillis),
            policy.multiplier,
            millisAsFloat(policy.maxMillis),
            attempt,
        ),
    );
}

// Internal: attempt number `attempt` of `retry`, and every one after it.
async fn retryFrom<T, E>(
    policy: RetryPolicy,
    work: fn() -> Async<Result<T, E>>,
    attempt: i32,
) -> Async<Result<T, E>> {
    val outcome = await work();
    val settled = outcome.isOk() || attempt >= policy.maxAttempts;
    if (settled) return try outcome;
    val pause = nextDelay(policy, attempt) ?? policy.maxMillis;
    await delay(pause.toI32(), 0);
    return try await retryFrom(policy, work, attempt + 1);
}

// Run `work` until it answers `Ok`, at most `policy.maxAttempts` times, pausing
// `nextDelay(policy, n)` after failed attempt `n`. `Ok` is answered as soon as
// an attempt succeeds; when every attempt fails, the LAST `Error` is answered —
// the task fails with it, in `timeout`'s shape. `work` is a thunk because
// each attempt has to start the task again; a plain `Async<T>` never fails
// (decisions 120, 432), so there is nothing to retry over one.
//
// A policy that is not usable is a programming error, fatal on both targets
// (`async.retry: maxAttempts must be at least 1 (the first attempt)`), like
// `race([])` — not an `Error` a caller could mistake for the work's own.
pub async fn retry<T, E>(
    policy: RetryPolicy,
    work: fn() -> Async<Result<T, E>>,
) -> Async<Result<T, E>> {
    val problem = policyProblem(policy);
    if (problem != "") panic(["async.retry: ", problem].join(""));
    return try await retryFrom(policy, work, 1);
}

// ── tests ────────────────────────────────────────────────────────────────────
// Inline, the way every std module does it, run by `botopink test` and
// `botopink test --target erlang` from `libs/std/`. Every verdict here is the
// same on an idle machine and a loaded one. Three kinds of assertion:
//   · results and order — deterministic on both targets;
//   · ORDER BY SIGNAL — "a concurrent combinator ran task B while task A was
//     still waiting", "the race was won by the task that answered" — told with
//     a gate one task opens and another awaits, never with a pair of `delay`s
//     and an elapsed-time budget: under load a 10 ms timer can fire after an
//     80 ms one on erlang, and a sequential map can still finish inside
//     "roughly double the longest task". A gate's budget (`gateBudget`) only
//     turns a gate nobody opens into a red assertion instead of a hang;
//   · a LOWER bound on elapsed time where the behaviour is a duration
//     (`delay`, `timeout`'s budget) — a promise the cells keep however busy the
//     machine is. There is no upper bound anywhere: an upper bound on elapsed
//     time measures the machine, not the code;
// plus DOCUMENTED DIVERGENCE (the started surface's erlang behaviour asserted
// as itself, so a backend change that makes erlang lazy reds a test instead of
// silently making the docblock a lie).
//
// `async` is not snapshotted (`01-std/test-snap.md`).

type Probe(id: i32, label: string)

// How long a test task waits on a gate before it gives up. Every gate a test
// closes is opened again, so this passes only when the code under test is
// wrong — and then as a red assertion, not a hang.
val gateBudget = 10000;

// `value` once `gate` opens; a value naming the failure when it never does.
async fn gated(gate: Gate, value: string) -> Async<string> {
    val opened = await awaitGate(gate, gateBudget);
    return if (opened) value else "gate never opened: " + value;
}

// Open `mine`, then answer `value` once `theirs` is open. Two of these over the
// same pair of gates, crossed, can only BOTH answer when they run at the same
// time: whichever runs first alone waits on a gate the other has not opened.
async fn handshake(mine: Gate, theirs: Gate, value: string) -> Async<string> {
    openGate(mine);
    return await gated(theirs, value);
}

// `value` with no timer at all: resolved in the microtask queue on commonJS,
// the process's first reply on erlang.
async fn answerNow(value: string) -> Async<string> {
    return value;
}

// ── delay and failed ─────────────────────────────────────────────────────────

test "async: delay ---- answers its value" {
    val v = await delay(20, "x");
    assert v == "x";
}

test "async: delay ---- takes at least the requested time" {
    val start = monoMillis();
    val v = await delay(20, "x");
    val elapsed = monoMillis() - start;
    assert v == "x";
    assert elapsed >= 20;
}

test "async: delay ---- binds T to a record as well as to a string" {
    val p = await delay(5, Probe(id: 7, label: "seven"));
    assert p.id == 7;
    assert p.label == "seven";
}

test "async: failed ---- await answers its Error value" {
    val r = await failed(string, "down");
    assert r.isError();
    assert errorText(r) == "down";
}

// ── gates ────────────────────────────────────────────────────────────────────

test "async: gate ---- a waiter answers once the gate opens, and later waiters at once" {
    val gate = newGate();
    val values = await runAll(
        [
            { -> gated(gate, "waited") },
            { -> handshake(gate, gate, "opened") },
        ],
    );
    assert values.join(",") == "waited,opened";
    assert await awaitGate(gate, gateBudget);
}

test "async: gate ---- a gate nobody opens answers false after its budget" {
    val start = monoMillis();
    val opened = await awaitGate(newGate(), 20);
    val elapsed = monoMillis() - start;
    assert opened == false;
    assert elapsed >= 20;
}

// ── allOf and all ────────────────────────────────────────────────────────────

async fn slowOk(millis: i32, value: string) -> Async<Result<string, string>> {
    return await delay(millis, value);
}

test "async: allOf ---- answers input order, not completion order" {
    val r = await allOf([slowOk(60, "a"), slowOk(20, "b"), slowOk(40, "c")]);
    assert r.isOk();
    assert r.unwrapOr([]).join(",") == "a,b,c";
}

test "async: allOf ---- stops at the first error in input order" {
    val r = await allOf([slowOk(5, "a"), failed(string, "down"), failed(string, "later")]);
    assert r.isError();
    val msg = case r {
        Ok(_v) -> "";
        Error(e) -> e;
    };
    assert msg == "down";
}

test "async: allOf ---- of no tasks answers no values" {
    val tasks: array<Async<Result<string, string>>> = [];
    val r = await allOf(tasks);
    assert r.unwrapOr(["x"]).length == 0;
}

test "async: all ---- answers input order" {
    val values = await all([delay(40, "a"), delay(10, "b"), delay(25, "c")]);
    assert values.join(",") == "a,b,c";
}

test "async: race ---- fastest on commonJS, element zero on erlang" {
    // The divergence, written as a test rather than as prose. `Async<T>` is
    // eager on erlang: both Tasks have resolved by the time `race` is called,
    // in list order, so `race` answers the FIRST element even though the other
    // one is instant. On commonJS the Promises are live and the one that
    // answers wins — element zero waits on a gate opened only after the race,
    // so it cannot. (A gate cannot be used on erlang: the eager Async would wait
    // on it before `race` is even called.) If a backend change ever makes
    // erlang lazy, this reds.
    if (hostTarget() == "erlang") {
        val first = await race([delay(20, "zero"), answerNow("one")]);
        assert first == "zero";
    } else {
        val gate = newGate();
        val first = await race([gated(gate, "zero"), delay(0, "one")]);
        openGate(gate);
        assert first == "one";
    }
}

// ── runAll ───────────────────────────────────────────────────────────────────

test "async: runAll ---- answers input order, not completion order" {
    val values = await runAll(
        [
            { -> delay(60, "a") },
            { -> delay(20, "b") },
            { -> delay(40, "c") },
        ],
    );
    assert values.join(",") == "a,b,c";
}

test "async: runAll ---- runs its tasks concurrently" {
    // Each task opens its own gate and then waits for the other's. A sequential
    // map, in either order, leaves the first task waiting on a gate the second
    // has not opened yet, and it answers "gate never opened".
    val left = newGate();
    val right = newGate();
    val values = await runAll(
        [
            { -> handshake(left, right, "a") },
            { -> handshake(right, left, "b") },
        ],
    );
    assert values.join(",") == "a,b";
}

test "async: runAll ---- a fallible task answers its Result in its slot" {
    val settled = await runAll(
        [
            { -> slowOk(40, "slow") },
            { -> failed(string, "broken") },
            { -> slowOk(5, "fast") },
        ],
    );
    assert settled.length == 3;
    val absent = errorProbe();
    assert errorText(settled.at(0) ?? absent) == "";
    assert errorText(settled.at(1) ?? absent) == "broken";
    assert (settled.at(2) ?? absent).unwrapOr("") == "fast";
}

// A settled element to stand in for the `?T` fallback of `.at(i)`. `Array.at`
// answers an optional and `unwrapOr` needs a value of the element type, which
// here is itself a `Result`; this is the cheapest way to spell one.
fn errorProbe() -> Result<string, string> {
    throw "async: no element";
}

// ── raceOf ───────────────────────────────────────────────────────────────────

test "async: raceOf ---- answers the fastest task, not the first" {
    // The first task in the list cannot answer before its gate opens, and the
    // gate opens only once the race is over.
    val gate = newGate();
    val first = await raceOf(
        [
            { -> gated(gate, "slow") },
            { -> delay(10, "fast") },
        ],
    );
    openGate(gate);
    assert first == "fast";
}

test "async: raceOf ---- a loser's answer is dropped, on purpose" {
    // There is no cancellation surface: the slow task runs to completion and
    // its value goes nowhere. Asserted rather than only written down.
    val first = await raceOf(
        [
            { -> failed(string, "slow failure") },
            { -> slowOk(10, "winner") },
        ],
    );
    assert first.isOk() || first.isError();
}

// ── timeout ──────────────────────────────────────────────────────────────────

test "async: timeout ---- a fast task under a wide budget answers Ok" {
    // The task answers with no timer. On commonJS that settles the race in the
    // microtask queue, before any timer can fire, so the budget is irrelevant
    // and stays short (the expired clock keeps the event loop open until it
    // fires). On erlang the two racers are processes, so the budget has to
    // dwarf any scheduling delay.
    val budget = if (hostTarget() == "erlang") gateBudget else 100;
    val answered = await timeout({ -> answerNow("in time") }, budget);
    assert answered.isOk();
    assert answered.unwrapOr("") == "in time";
}

test "async: timeout ---- a slow task under a narrow budget answers Error timeout" {
    // The task waits on a gate opened only after `timeout` answered, so it
    // cannot answer first; a `timeout` that waited for its task would answer
    // `Ok("gate never opened: …")` instead.
    val gate = newGate();
    val start = monoMillis();
    val answered = await timeout({ -> gated(gate, "too late") }, 50);
    val elapsed = monoMillis() - start;
    openGate(gate);
    assert answered.isError();
    assert errorText(answered) == "timeout";
    assert elapsed >= 50;
}

test "async: timeout ---- an expired task cannot corrupt a later answer" {
    // The expired task is released only once `timeout` stopped waiting for it,
    // and lands in the same host process while the `runAll` below is still
    // gathering: `runAll`'s first task opens `release`, then waits until the
    // expired task has answered (`ghostDone`) before answering itself. The
    // erlang cells tag every reply with a `make_ref()` unique to their own
    // call for exactly this: `runAll` must read its own replies, not the ghost
    // of a task nobody is waiting for any more.
    val release = newGate();
    val ghostDone = newGate();
    val answered = await timeout({ -> ghost(release, ghostDone) }, 30);
    assert answered.isError();
    val values = await runAll(
        [
            { -> handshake(release, ghostDone, "a") },
            { -> answerNow("b") },
        ],
    );
    assert values.join(",") == "a,b";
}

// The expired task of the test above: waits for `release`, opens `done` and
// answers.
async fn ghost(release: Gate, done: Gate) -> Async<string> {
    val v = await gated(release, "late");
    openGate(done);
    return v;
}

// ── retry ────────────────────────────────────────────────────────────────────

// Internal, test scaffolding: a counter the attempts of one `retry` share —
// a closure cannot count on erlang, where a `var` it captures is a copy.
// Node: an object. Erlang: a `counters` reference.
#[compiler.external(.JavaScript("""({ n: 0 })"""), .Erlang("""counters:new(1, [])"""))]
declare fn newCounter() -> unknown;

// Count one more and answer the count.
#[compiler.external(
    .JavaScript("""((__c) => { __c.n = __c.n + 1; return __c.n })($0)"""),
    .Erlang("""(fun(__C) -> counters:add(__C, 1, 1), counters:get(__C, 1) end)($0)"""),
)]
declare fn countUp(counter: unknown) -> i32;

#[compiler.external(.JavaScript("""(($0).n)"""), .Erlang("""counters:get($0, 1)"""))]
declare fn countOf(counter: unknown) -> i32;

// The text a task panics with, `""` when it answered — a panic inside a
// `-> Async` function is a rejected Promise on commonJS and a raise on erlang.
async fn panicOf<T>(body: fn() -> Async<T>) -> Async<string> {
    val r = await failure.attemptTask(body);
    return case r {
        Ok(_) -> "";
        Error(f) -> f.message;
    };
}

// Attempt `n` of a task that fails until its `succeedAt`-th call:
// `Error("failure <n>")` before it, `Ok("ok after <n>")` from it on. The test
// counts the call (`flaky(countUp(calls), …)`), so the counter's cells are
// reached from the tests alone, and a module importing `async` on a target
// with no counter (wasm) links no call of them.
async fn flaky(n: i32, succeedAt: i32) -> Async<Result<string, string>> {
    if (n < succeedAt) throw ["failure ", n.toString()].join("");
    return ["ok after ", n.toString()].join("");
}

// What `nextDelay(policy, attempt)` answers, as text: the milliseconds, or
// `none`.
fn pauseText(policy: RetryPolicy, attempt: i32) -> string {
    val pause = nextDelay(policy, attempt);
    return if (pause != null) pause.toString() else "none";
}

// `pauseText` for attempts 1 to `last`, joined by `,`.
fn pauses(policy: RetryPolicy, last: i32) -> string {
    return array
        .range(1, last + 1)
        .map({ attempt -> pauseText(policy, attempt) })
        .join(",");
}

test "async: nextDelay ---- grows by the multiplier and ends past maxAttempts" {
    val policy = RetryPolicy(3, 100, 2.0, 1000);
    assert pauseText(policy, 1) == "100";
    assert pauseText(policy, 2) == "200";
    assert pauseText(policy, 3) == "400";
    assert nextDelay(policy, 4) == null;
    assert nextDelay(policy, 3) != null;
    assert pauses(policy, 4) == "100,200,400,none";
    assert pauseText(policy, 0) == "none";
    assert pauseText(policy, 0 - 1) == "none";
}

test "async: nextDelay ---- never answers above maxMillis" {
    assert pauses(RetryPolicy(7, 100, 2.0, 1000), 8)
        == "100,200,400,800,1000,1000,1000,none";
    assert pauses(RetryPolicy(3, 5000, 2.0, 1000), 3) == "1000,1000,1000";
    assert pauses(RetryPolicy(12, 1, 10.0, 2147483647), 12).endsWith(
        "100000000,1000000000,2147483647,2147483647",
    );
    assert pauseText(RetryPolicy(2000000000, 1, 1.5, 2147483647), 1999999999)
        == "2147483647";
    // An `initialMillis` past 2^53 (a `BigInt` on commonJS, decision 319) is
    // read as the float it rounds to, then capped.
    assert pauses(RetryPolicy(2, 9007199254740993l, 2.0, 1000), 2)
        == "1000,1000";
}

test "async: nextDelay ---- rounds a fractional delay down, a multiplier of one keeps it" {
    assert pauses(RetryPolicy(5, 100, 1.5, 10000), 5) == "100,150,225,337,506";
    assert pauses(RetryPolicy(4, 250, 1.0, 1000), 5) == "250,250,250,250,none";
    assert pauses(RetryPolicy(3, 0, 2.0, 1000), 3) == "0,0,0";
    assert pauses(RetryPolicy(1, 100, 2.0, 1000), 2) == "100,none";
}

test "async: nextDelay ---- a policy that is not usable names no delay" {
    assert pauseText(RetryPolicy(0, 100, 2.0, 1000), 1) == "none";
    assert pauseText(RetryPolicy(3, 0 - 1, 2.0, 1000), 1) == "none";
    assert pauseText(RetryPolicy(3, 100, 2.0, 0 - 1), 1) == "none";
    assert pauseText(RetryPolicy(3, 100, 0.5, 1000), 1) == "none";
    assert pauseText(RetryPolicy(3, 100, 0.0, 1000), 1) == "none";
}

test "async: retry ---- a task that fails twice answers Ok after three calls" {
    val calls = newCounter();
    val answer = await retry(
        RetryPolicy(5, 1, 2.0, 10),
        { -> flaky(countUp(calls), 3) },
    );
    assert answer.isOk();
    assert answer.unwrapOr("") == "ok after 3";
    assert countOf(calls) == 3;
}

test "async: retry ---- a task that always fails answers its last Error after maxAttempts" {
    val calls = newCounter();
    val answer = await retry(
        RetryPolicy(3, 1, 2.0, 10),
        { -> flaky(countUp(calls), 99) },
    );
    assert answer.isError();
    assert errorText(answer) == "failure 3";
    assert countOf(calls) == 3;
}

test "async: retry ---- a task that answers Ok at once is called once" {
    val calls = newCounter();
    val answer = await retry(
        RetryPolicy(4, 1, 2.0, 10),
        { -> flaky(countUp(calls), 1) },
    );
    assert answer.unwrapOr("") == "ok after 1";
    assert countOf(calls) == 1;
}

test "async: retry ---- one attempt is one call and its Error" {
    val calls = newCounter();
    val answer = await retry(
        RetryPolicy(1, 1, 2.0, 10),
        { -> flaky(countUp(calls), 99) },
    );
    assert errorText(answer) == "failure 1";
    assert countOf(calls) == 1;
}

test "async: retry ---- pauses at least the policy's delays between attempts" {
    // Two failures: a pause of 20 ms, then one of 40 ms. A LOWER bound only.
    val calls = newCounter();
    val start = monoMillis();
    val answer = await retry(
        RetryPolicy(3, 20, 2.0, 1000),
        { -> flaky(countUp(calls), 3) },
    );
    val elapsed = monoMillis() - start;
    assert answer.unwrapOr("") == "ok after 3";
    assert elapsed >= 60;
}

test "async: retry ---- a policy that is not usable is fatal, and the task is never called" {
    val calls = newCounter();
    val raised = await panicOf(
        { -> retry(RetryPolicy(0, 1, 2.0, 10), { -> flaky(countUp(calls), 1) }) },
    );
    assert raised
        == "async.retry: maxAttempts must be at least 1 (the first attempt)";
    val shrinking = await panicOf(
        { -> retry(RetryPolicy(3, 1, 0.5, 10), { -> flaky(countUp(calls), 1) }) },
    );
    assert shrinking
        == "async.retry: multiplier must be at least 1.0 (a backoff never shrinks)";
    assert countOf(calls) == 0;
}

```

----- JAVASCRIPT -- std/async.js
```javascript
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

function __bp_task(p) {
    const t = p.then((r) => { if (r != null && "error" in r) { t.__bp_failure = true; throw r.error; } return (r == null) ? r : r.ok; });
    t.__bp_fails = true;
    t.catch(() => {});
    return t;
}

function __bp_await(t) {
    return (t != null && t.__bp_fails === true) ? t.then((v) => ({ ok: v }), (e) => { if (t.__bp_failure === true) { return { error: e }; } throw e; }) : t;
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

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

//// std/async — combinators over `Async<T>` (decisions 120 and 121 of

//// 1.0.10-beta, front 24 step E7).

//// 

//// An operation that can go wrong answers `Async<Result<T, E>>` — the task

//// that fails with `E` (decision 432): on commonJS its Promise rejects with

//// `E`, and `await` reads the rejection back as `Error(e)`. The combinators

//// here read that `Result`: a host cell that awaits the tasks itself

//// (`runAll`, `raceOf`, `race`) reads a failing task's rejection as the

//// `{ error }` value `await` would answer, so nothing here hides a failure

//// by swallowing one, and a crash stays a crash.

//// 

//// THE ERLANG DIVERGENCE, AT THE TOP RATHER THAN IN A FOOTNOTE.

//// `Async<T>` lowers EAGERLY on the erlang backend: a `-> Async` fn is a plain

//// function, `await` is identity, and a Async is therefore a value that has

//// already run (`codegen/erlang.zig` — the `Async — eager lowering` arm;

//// `libs/std/src/http.bp` says the same for `http.fetch`). By the time an

//// `Array<Async<T>>` reaches a combinator on erlang, every element has already

//// finished, in list order, serially.

//// 

//// So this module has TWO surfaces and they do not make the same promise.

//// 

////   STARTED TASKS — `allOf`, `all`, `race`.

////   Take `Array<Async<…>>`, the shape the guide writes

////   (`async.allOf([fetchUser(1), fetchUser(2)])`). Concurrent on commonJS,

////   where each Async is a live Promise. On erlang it is honest rather than

////   concurrent: the Tasks resolved before the call, so `allOf` / `all` read

////   values in order and `race` answers ELEMENT ZERO rather than the fastest.

////   Both behaviours are asserted by the tests at the foot of this file, so a

////   backend change that makes erlang lazy reds a test and forces this

////   docblock to be rewritten instead of silently making it a lie.

//// 

////   UNSTARTED TASKS — `runAll`, `raceOf`, `timeout`, `retry`.

////   Take `fn() -> Async<T>` thunks. Because nothing has run when the

////   combinator receives them, the erlang cell can `spawn` one process per

////   task and gather the replies by index, and the commonJS cell can call each

////   thunk into `Promise.all`. Real concurrency on BOTH targets. This is the

////   surface a server front uses.

//// 

//// `allOf` stops at the FIRST error in input order (front 24 README, E7) — the

//// `E` is the tasks' own type, so there is no message to join; `runAll` over

//// `Async<Result<…>>` thunks answers every `Result` when the caller wants

//// them all. `allSettled` and `settleOf` left with the rejection they settled:

//// a Async has no failure to settle, and a `Result` element IS the settled

//// outcome (`specs/1.0.10-beta/decisions-pending.md` 24-g).

//// 

//// NO CANCELLATION. `raceOf`'s losers and `timeout`'s expired task keep

//// running to completion; there is no cancellation surface in the language.

//// 

//// Reference:

////   Promise.all       — https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all

////   Erlang processes  — https://www.erlang.org/doc/system/ref_man_processes.html

const failure = require("./std@failure");

// ── instruments ──────────────────────────────────────────────────────────────

// Which backend is running. The future surface's erlang behaviour differs from

// its commonJS behaviour by design, and a test that asserts one of the two has

// to know which it is looking at. Private: the divergence is this module's to

// document, not a consumer's to branch on.

// hostTarget: per-call template (see annotation)

// The host's monotonic clock in milliseconds. `std/io/clock` has the same cell,

// and this root module may not import from `io/` (decision 106), so this file

// carries its own. Private — `clock.monotonicMillis()` is the public spelling.

// monoMillis: per-call template (see annotation)

// Answer `value` after at least `millis` milliseconds of the host's monotonic

// clock — the promise `monoMillis()` measures it by.

// Node: `setTimeout` alone does not keep that promise. A timer starts from

// libuv's CACHED loop time (whole milliseconds, read when the loop last woke),

// so a timer armed after a long synchronous stretch — a loaded machine, a busy

// test runner — fires early by that stretch. The cell reads `performance.now()`

// when it is called and re-arms for whatever is left, so it never answers

// early. The first wait is always a timer, so `delay(0, v)` still yields to the

// timers phase rather than answering in the same microtask queue.

// Erlang: `timer:sleep/1` never wakes early.

// delay: per-call template (see annotation)
function delay(millis, value) { return ((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))(millis, value); }
exports.delay = delay;

// A Async whose value is `Error(message)` — the failing instrument `allOf` and

// `timeout` are tested with. On commonJS it rejects with `message` (decision

// 432); `await` reads it as `Error(message)`.

function failed(message) {
    return __bp_task((async () => {
        return ({ error: message });
    })());
}
exports.failed = failed;

// ── gates ────────────────────────────────────────────────────────────────────

// A one-shot signal between tasks: closed until `openGate`, open for good

// after. The instrument a test orders tasks with WITHOUT a clock — "task B

// answers only after task A has run" is a gate A opens and B awaits, where a

// pair of `delay`s only says "probably, unless the machine is busy".

// Node: an object holding the waiters' resolvers.

// Erlang: a process that queues `{bp_gate_wait, Pid, Ref}` requests until it

// receives `bp_gate_open`, then answers each and every later one at once —

// a pid, so the gate crosses into a spawned task like any value. It is never

// stopped: it is parked in `receive` and dies with the node.

class Gate {
    constructor(handle) {
        this.handle = handle;
    }
}
Gate.prototype.__bp = "Gate";
exports.Gate = Gate;

// gateHandle: per-call template (see annotation)

// gateOpen: per-call template (see annotation)

// gateAwait: per-call template (see annotation)

// A new, closed gate.

function newGate() {
    return new Gate(({ opened: false, waiters: [] }));
}
exports.newGate = newGate;

// Open `gate`: every task awaiting it answers, and so does every later

// `awaitGate`. Opening an open gate changes nothing.

function openGate(gate) {
    ((__g) => { __g.opened = true; for (const __w of __g.waiters.splice(0)) { __w(); } return undefined; })(gate.handle);
}
exports.openGate = openGate;

// `true` once `gate` is open, `false` when `millis` pass first. The budget is

// not the ordering — the gate is; it only turns a gate nobody opens into a red

// assertion instead of a hang, so a test gives it a margin no scheduling delay

// can cross (seconds) and opens every gate it closes. An open gate answers at

// once and leaves no timer behind.

async function awaitGate(gate, millis) {
    return await ((__g, __ms) => __g.opened ? Promise.resolve(true) : new Promise((__r) => { const __on = () => { clearTimeout(__t); __r(true); }; const __t = setTimeout(() => { __g.waiters = __g.waiters.filter((__w) => __w !== __on); __r(false); }, __ms); __g.waiters.push(__on); }))(gate.handle, millis);
}
exports.awaitGate = awaitGate;

// ── reading a settled element ────────────────────────────────────────────────

// The `Error` payload of a `Result<T, string>`, or `""` for `Ok`. `Result`

// carries `isOk`/`isError`/`unwrapOr` as builtins but no way to read the error

// side, so without this a caller can see THAT a widget failed and never WHY —

// the shape decision 67 refuses.

function errorText(settled) {
    const text = (() => {
        const _s = settled;
        if ("ok" in _s) {
            const _v = _s.ok;
            return "";
        }
        if ("error" in _s) {
            const e = _s.error;
            return e;
        }
        throw new Error("case_clause");
    })();
    return text;
}
exports.errorText = errorText;

// ── started tasks ────────────────────────────────────────────────────────────

// The values of every Async, in input order, or the FIRST `Error` in input

// order. The tasks were started by the caller (`allOf([fetchUser(1),

// fetchUser(2)])`), so on commonJS they run concurrently and this only waits;

// on erlang they already ran. `allOf([])` answers `Ok([])`.

function allOf(tasks) {
    return __bp_task((async () => {
        let out = [];
        for (const t of tasks) {
    const _try0 = await __bp_await(t);
        if ("error" in _try0) return _try0;
        const v = _try0.ok;
    out = out.concat([v]);
}
        return ({ ok: out });
    })());
}
exports.allOf = allOf;

// The values of every Async, in input order — the infallible `allOf`.

async function all(tasks) {
    let out = [];
    for (const t of tasks) {
    const v = await __bp_await(t);
    out = out.concat([v]);
}
    return out;
}
exports.all = all;

// commonJS: the FASTEST Async to answer, `Promise.race`.

// ERLANG: ELEMENT ZERO. Every Async resolved before the call, so there is no

// timing left to measure and this answers the first element of the list. That

// is not a bug to be fixed here and no server front may depend on it — use

// `raceOf`, whose tasks are unstarted when it receives them. Both behaviours

// are pinned by `async: race ---- commonJS fastest, erlang element zero`.

// 

// `race([])` is a programming error, fatal on both targets

// (`async.race: empty task list`).

// race: per-call template (see annotation)
function race(tasks) { return ((__fs) => __fs.length === 0 ? Promise.reject(new Error('async.race: empty task list')) : Promise.race(__fs.map(((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t))))(tasks); }
exports.race = race;

// ── unstarted tasks ──────────────────────────────────────────────────────────

// Run every task concurrently and answer their values in the ORDER OF THE

// INPUT rather than the order they finished. A task over a `Result` answers

// its `Result` in its slot, so `runAll` of fallible tasks is the settled

// view: nothing is hidden and nothing stops early.

// 

// Node: each thunk is called and the Promises go to `Promise.all`, a failing

// task (decision 432) read as the `{ ok }` / `{ error }` value `await` reads.

// Erlang: `spawn` one process per task, each tagged `{Ref, I, Outcome}` with a

// `make_ref()` unique to THIS call — without the ref a later combinator in the

// same process would receive a loser's leftover reply — and gather by index, so

// a task that finishes first does not take another task's slot. A task that

// crashes is a crash (a crash is a bug, never a failure), re-raised here

// rather than left to block the gather.

// spawnAll: per-call template (see annotation)

// The public face of the cell above: a real function, so a module compiled

// separately (the BEAM backend links modules by name) can call it — a

// template-only `declare fn` has no body to export.

async function runAll(tasks) {
    return await Promise.all((tasks).map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)())));
}
exports.runAll = runAll;

// The first task to ANSWER, not the first in the list. The LOSERS keep

// running and their values are discarded: there is no cancellation surface in

// botopink, and a race that reported the loser would not be a race.

// 

// `raceOf([])` is a programming error, fatal on both targets

// (`async.raceOf: empty task list`), rather than blocking forever.

// raceOf: per-call template (see annotation)
function raceOf(tasks) { return ((__ts) => __ts.length === 0 ? Promise.reject(new Error('async.raceOf: empty task list')) : Promise.race(__ts.map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)()))))(tasks); }
exports.raceOf = raceOf;

// `task`'s value as `Ok` — the racer `timeout` puts beside the clock.

function answered(task) {
    return __bp_task((async () => {
        return ({ ok: await __bp_await(task()) });
    })());
}

// `Error("timeout")` after `millis` — the clock `timeout` races against

// `task`, whose type it answers in (decision 668: `task` binds `T`).

function expireAfter(task, millis) {
    return __bp_task((async () => {
        await ((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))(millis, 0);
        return ({ error: "timeout" });
    })());
}

// `Ok(value)` when the task answered inside the budget, `Error("timeout")`

// when it did not. A task over a `Result` keeps its own failure INSIDE the

// `Ok` (`Ok(Error(e))`): the budget and the task's outcome are two answers,

// and neither hides the other. The task KEEPS RUNNING; the caller stops

// waiting. Expressed over `raceOf` + `delay`.

function timeout(task, millis) {
    return __bp_task((async () => {
        return await __bp_await(((__ts) => __ts.length === 0 ? Promise.reject(new Error('async.raceOf: empty task list')) : Promise.race(__ts.map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)()))))([() => {
    return answered(task);
}, () => {
    return expireAfter(task, millis);
}]));
    })());
}
exports.timeout = timeout;

// ── retry (1.0.11-beta front 97) ─────────────────────────────────────────────

// How a fallible task is tried again: at most `maxAttempts` attempts, a pause

// of `initialMillis` after the first failure, each later pause `multiplier`

// times the one before, none above `maxMillis`. There is no jitter and no

// field that means "for ever" (decision 67): a policy is usable only when

// `maxAttempts` is at least 1, the two delays are not negative, `maxMillis`

// is at most 2147483647 (the longest timer both targets arm) and `multiplier`

// is at least 1.0 — a backoff never shrinks, and one that could would retry

// in a near-zero-delay loop.

class RetryPolicy {
    constructor(maxAttempts, initialMillis, multiplier, maxMillis) {
        this.maxAttempts = maxAttempts;
        this.initialMillis = initialMillis;
        this.multiplier = multiplier;
        this.maxMillis = maxMillis;
    }
}
RetryPolicy.prototype.__bp = "RetryPolicy";
RetryPolicy.prototype.__bp_s = { multiplier: "f" };
exports.RetryPolicy = RetryPolicy;

// Internal: why `policy` is not usable, `""` when it is.

function policyProblem(policy) {
    if ((policy.maxAttempts < 1)) { return "maxAttempts must be at least 1 (the first attempt)"; }
    if ((policy.initialMillis < 0)) { return "initialMillis must not be negative"; }
    if ((policy.maxMillis < 0)) { return "maxMillis must not be negative"; }
    if ((policy.maxMillis > 2147483647)) { return "maxMillis must be at most 2147483647"; }
    const grows = (policy.multiplier >= 1.0);
    if ((grows === false)) { return "multiplier must be at least 1.0 (a backoff never shrinks)"; }
    return "";
}

// Internal: an `i64` of milliseconds as an `f64`, and back — the whole

// milliseconds of a delay that is never negative. Not `toF64()`, which aborts

// on an integer past 2^53 that no `f64` holds: the delay is a float

// computation, and an `initialMillis` that large rounds as the float does

// (and is then capped by `maxMillis`). The Node forms take and answer

// decision 319's canonical form — `Number` reads a `BigInt` (`initialMillis`

// past 2^53 − 1), and a whole number past 2^53 − 1 answers as a `BigInt`.

// millisAsFloat: per-call template (see annotation)

// wholeMillis: per-call template (see annotation)

// Internal: `initial × multiplier^(attempt − 1)`, never above `ceiling`. One

// multiplication per attempt — the same IEEE operations in the same order on

// both targets, where a host `pow` would not promise the same last bit — and

// none once the ceiling is reached, so it cannot overflow.

function grown(initial, multiplier, ceiling, attempt) {
    const steady = ((multiplier <= 1.0) || (initial <= 0.0));
    if (steady) { return (() => { if ((initial > ceiling)) { return ceiling; } else { return initial; } })(); }
    let pause = initial;
    let step = 1;
    while (((step < attempt) && (pause < ceiling))) {
    pause = (pause * multiplier);
    step = __bp_int((step + 1), -2147483648, 2147483647, "+ on i32 at src/async.bp:335:21");
}
    return (() => { if ((pause > ceiling)) { return ceiling; } else { return pause; } })();
}

// The pause that follows attempt `attempt` (the first attempt is 1), in whole

// milliseconds: `initialMillis × multiplier^(attempt − 1)`, rounded down and

// never above `maxMillis`. `null` once `attempt` is past `maxAttempts` — there

// is no further attempt to wait for — and for an attempt below 1 or a policy

// that is not usable.

function nextDelay(policy, attempt) {
    const usable = (policyProblem(policy) === "");
    const inside = ((attempt >= 1) && (attempt <= policy.maxAttempts));
    const answers = (usable && inside);
    if ((answers === false)) { return null; }
    return ((__x) => { const __f = Math.floor(__x); return Number.isSafeInteger(__f) ? __f : BigInt(__f); })(grown(Number(policy.initialMillis), policy.multiplier, Number(policy.maxMillis), attempt));
}
exports.nextDelay = nextDelay;

// Internal: attempt number `attempt` of `retry`, and every one after it.

function retryFrom(policy, work, attempt, __bp_ty_T, __bp_ty_E) {
    return __bp_task((async () => {
        const outcome = await __bp_await(work());
        const settled = (((_r) => !("error" in _r))(outcome) || (attempt >= policy.maxAttempts));
        if (settled) { return outcome; }
        const pause = (() => { const __bp_nullish = nextDelay(policy, attempt); if (__bp_nullish != null) { return __bp_nullish; } else { return policy.maxMillis; } })();
        await ((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))(pause.toI32(), 0);
        return await __bp_await(retryFrom(policy, work, __bp_int((attempt + 1), -2147483648, 2147483647, "+ on i32 at src/async.bp:371:54")));
    })());
}
retryFrom.__bp_arity = 3;

// Run `work` until it answers `Ok`, at most `policy.maxAttempts` times, pausing

// `nextDelay(policy, n)` after failed attempt `n`. `Ok` is answered as soon as

// an attempt succeeds; when every attempt fails, the LAST `Error` is answered —

// the task fails with it, in `timeout`'s shape. `work` is a thunk because

// each attempt has to start the task again; a plain `Async<T>` never fails

// (decisions 120, 432), so there is nothing to retry over one.

// 

// A policy that is not usable is a programming error, fatal on both targets

// (`async.retry: maxAttempts must be at least 1 (the first attempt)`), like

// `race([])` — not an `Error` a caller could mistake for the work's own.

function retry(policy, work, __bp_ty_T, __bp_ty_E) {
    return __bp_task((async () => {
        const problem = policyProblem(policy);
        (() => { if ((problem !== "")) { return (() => { throw Object.defineProperty(new Error(["async.retry: ", problem].join("")), '__bp_panic', { value: true }) })(); } })();
        return await __bp_await(retryFrom(policy, work, 1));
    })());
}
retry.__bp_arity = 2;
exports.retry = retry;

// ── tests ────────────────────────────────────────────────────────────────────

// Inline, the way every std module does it, run by `botopink test` and

// `botopink test --target erlang` from `libs/std/`. Every verdict here is the

// same on an idle machine and a loaded one. Three kinds of assertion:

//   · results and order — deterministic on both targets;

//   · ORDER BY SIGNAL — "a concurrent combinator ran task B while task A was

//     still waiting", "the race was won by the task that answered" — told with

//     a gate one task opens and another awaits, never with a pair of `delay`s

//     and an elapsed-time budget: under load a 10 ms timer can fire after an

//     80 ms one on erlang, and a sequential map can still finish inside

//     "roughly double the longest task". A gate's budget (`gateBudget`) only

//     turns a gate nobody opens into a red assertion instead of a hang;

//   · a LOWER bound on elapsed time where the behaviour is a duration

//     (`delay`, `timeout`'s budget) — a promise the cells keep however busy the

//     machine is. There is no upper bound anywhere: an upper bound on elapsed

//     time measures the machine, not the code;

// plus DOCUMENTED DIVERGENCE (the started surface's erlang behaviour asserted

// as itself, so a backend change that makes erlang lazy reds a test instead of

// silently making the docblock a lie).

// 

// `async` is not snapshotted (`01-std/test-snap.md`).

class Probe {
    constructor(id, label) {
        this.id = id;
        this.label = label;
    }
}
Probe.prototype.__bp = "Probe";

// How long a test task waits on a gate before it gives up. Every gate a test

// closes is opened again, so this passes only when the code under test is

// wrong — and then as a red assertion, not a hang.

const gateBudget = 10000;

// `value` once `gate` opens; a value naming the failure when it never does.

async function gated(gate, value) {
    const opened = await awaitGate(gate, gateBudget);
    return (() => { if (opened) { return value; } else { return ("gate never opened: " + value); } })();
}

// Open `mine`, then answer `value` once `theirs` is open. Two of these over the

// same pair of gates, crossed, can only BOTH answer when they run at the same

// time: whichever runs first alone waits on a gate the other has not opened.

async function handshake(mine, theirs, value) {
    openGate(mine);
    return await gated(theirs, value);
}

// `value` with no timer at all: resolved in the microtask queue on commonJS,

// the process's first reply on erlang.

async function answerNow(value) {
    return value;
}

// ── delay and failed ─────────────────────────────────────────────────────────

// ── gates ────────────────────────────────────────────────────────────────────

// ── allOf and all ────────────────────────────────────────────────────────────

function slowOk(millis, value) {
    return __bp_task((async () => {
        return ({ ok: await ((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))(millis, value) });
    })());
}

// ── runAll ───────────────────────────────────────────────────────────────────

// A settled element to stand in for the `?T` fallback of `.at(i)`. `Array.at`

// answers an optional and `unwrapOr` needs a value of the element type, which

// here is itself a `Result`; this is the cheapest way to spell one.

function errorProbe() {
    return ({ error: "async: no element" });
}

// ── raceOf ───────────────────────────────────────────────────────────────────

// ── timeout ──────────────────────────────────────────────────────────────────

// The expired task of the test above: waits for `release`, opens `done` and

// answers.

async function ghost(release, done) {
    const v = await gated(release, "late");
    openGate(done);
    return v;
}

// ── retry ────────────────────────────────────────────────────────────────────

// Internal, test scaffolding: a counter the attempts of one `retry` share —

// a closure cannot count on erlang, where a `var` it captures is a copy.

// Node: an object. Erlang: a `counters` reference.

// newCounter: per-call template (see annotation)

// Count one more and answer the count.

// countUp: per-call template (see annotation)

// countOf: per-call template (see annotation)

// The text a task panics with, `""` when it answered — a panic inside a

// `-> Async` function is a rejected Promise on commonJS and a raise on erlang.

async function panicOf(body) {
    const r = await __bp_await(failure.attemptTask(body));
    return (() => {
        const _s = r;
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

// Attempt `n` of a task that fails until its `succeedAt`-th call:

// `Error("failure <n>")` before it, `Ok("ok after <n>")` from it on. The test

// counts the call (`flaky(countUp(calls), …)`), so the counter's cells are

// reached from the tests alone, and a module importing `async` on a target

// with no counter (wasm) links no call of them.

function flaky(n, succeedAt) {
    return __bp_task((async () => {
        if ((n < succeedAt)) { return ({ error: ["failure ", n.toString()].join("") }); }
        return ({ ok: ["ok after ", n.toString()].join("") });
    })());
}

// What `nextDelay(policy, attempt)` answers, as text: the milliseconds, or

// `none`.

function pauseText(policy, attempt) {
    const pause = nextDelay(policy, attempt);
    return (() => { if ((pause != null)) { return pause.toString(); } else { return "none"; } })();
}

// `pauseText` for attempts 1 to `last`, joined by `,`.

function pauses(policy, last) {
    return Array.range(1, __bp_int((last + 1), -2147483648, 2147483647, "+ on i32 at src/async.bp:727:24")).map((attempt) => {
    return pauseText(policy, attempt);
}).join(",");
}

Object.defineProperty(exports, "__bp_priv__", { value: { failure, delay, failed, Gate, newGate, openGate, awaitGate, errorText, allOf, all, race, runAll, raceOf, answered, expireAfter, timeout, RetryPolicy, policyProblem, grown, nextDelay, retryFrom, retry, Probe, gateBudget, gated, handshake, answerNow, slowOk, errorProbe, ghost, panicOf, flaky, pauseText, pauses } });
```

----- TYPESCRIPT TYPEDEF -- std/async.d.ts
```typescript




export declare function delay<T>(millis: number, value: T): Promise<T>;


/** @throws {string} */
export declare function failed<T>(t: any, message: string): Promise<T>;


export declare class Gate {
    readonly handle: unknown;
    constructor(handle: unknown);
}








export declare function newGate(): Gate;


export declare function openGate(gate: Gate): void;


export declare function awaitGate(gate: Gate, millis: number): Promise<boolean>;


export declare function errorText<T>(settled: { ok: T } | { error: string }): string;


/** @throws {E} */
export declare function allOf<T, E>(tasks: Promise<T>[]): Promise<T[]>;


export declare function all<T>(tasks: Promise<T>[]): Promise<T[]>;


export declare function race<T>(tasks: Promise<T>[]): Promise<T>;




export declare function runAll<T>(tasks: () => Promise<T>[]): Promise<T[]>;


export declare function raceOf<T>(tasks: () => Promise<T>[]): Promise<T>;






/** @throws {string} */
export declare function timeout<T>(task: () => Promise<T>, millis: number): Promise<T>;


export declare class RetryPolicy {
    readonly maxAttempts: number;
    readonly initialMillis: number | bigint;
    readonly multiplier: number;
    readonly maxMillis: number | bigint;
    constructor(maxAttempts: number, initialMillis: number | bigint, multiplier: number, maxMillis: number | bigint);
}










export declare function nextDelay(policy: RetryPolicy, attempt: number): number | bigint | null;




/** @throws {E} */
export declare function retry<T, E>(policy: RetryPolicy, work: () => Promise<T>): Promise<T>;































```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
async fn doubled(n: i32) -> Async<i32> {
    return n * 2;
}
async fn doubledF(n: f64) -> Async<f64> {
    return n * 2.0;
}
async fn run() -> Async<void> {
    val ints = await async.runAll([
        { -> doubled(1) },
        { -> doubled(2) },
        { -> doubled(3) },
    ]);
    print(ints);
    val floats = await async.runAll([
        { -> doubledF(1.5) },
        { -> doubledF(2.5) },
    ]);
    print(floats);
}
pub fn main() -> void {
    run();
}

import {io.terminal.print, async} from "std";
```

----- JAVASCRIPT -- main.js
```javascript
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
    if ((typeof v === "function")) return ("fn/" + (v.__bp_arity ?? v.length));
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

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_print_as(shapes) {
    const a = [];
    const f = Array.from(Array.from(arguments).slice(1), (v, i) => __bp_show(v, shapes[i], true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

async function doubled(n) {
    return __bp_int((n * 2), -2147483648, 2147483647, "* on i32 at main.bp:2:14");
}

async function doubledF(n) {
    return (n * 2.0);
}

async function run() {
    const ints = await async.runAll([() => {
    return doubled(1);
}, () => {
    return doubled(2);
}, () => {
    return doubled(3);
}]);
    __bp_print(ints);
    const floats = await async.runAll([() => {
    return doubledF(1.5);
}, () => {
    return doubledF(2.5);
}]);
    __bp_print_as([["[", "f"]], floats);
}

function main() {
    run();
}
exports.main = main;

const async = require("./std@async");

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { doubled, doubledF, run, main, async } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript






export declare function main(): void;

```

----- RUN LOG -----
```logs
[2, 4, 6]
[3.0, 5.0]
```
