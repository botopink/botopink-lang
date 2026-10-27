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

----- SOURCE CODE -- std/testing/asserts.bp
```botopink
//// std/testing/asserts — the canonical assertion API every test is written against
//// (1.0.10-beta front 01-std, `asserts-api.md`; decisions 74 and 67).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/assert.html
////   Erlang   — (no equivalent module; pattern matching does the same job)
////
//// Every assertion answers `-> Result<void, string>` (the return is the effect):
//// success is `Ok`, failure is `Error(message)`. The caller writes
//// `try asserts.equals(a, b);` and a failure propagates to the enclosing
//// `test` body, which ends as `FAIL <name>  (<message>)  at <file>:<line>`
//// (the test body is a fallible context — `conformance/docs.md` § Tests). A `-test`
//// helper that is itself `-> Result<void, string>` composes an assertion
//// with `try` and nothing else; nothing here panics.
////
//// Five rules (`asserts-api.md` § The shape of every function):
////   1. `-> Result<void, string>`; the `ok` position is `return;`.
////   2. `actual` first, `expected` second — everywhere (`matches(actual, pattern)`).
////   3. One literal message per function, `asserts.<fn>: <what>`; no value
////      rendering (a generic `T` has no `toString`). The call site's `@src()`
////      and the runner's `at <file>:<line>` say where; the message says which.
////   4. Pure botopink on the path that runs everywhere: `==`, `!=`, `== false`,
////      `.length`, `.contains()`, `.startsWith()`, `.endsWith()`, `.indexOf()`,
////      `.isOk()`, `.isError()`, `!= null` — host-backed primitives only. A
////      primitive `default fn` (`Bool.negate`, `Array.contains`) is not lowered
////      when a std module is compiled as a consumer's embedded import today,
////      so none is used here (measured 2026-09-20; `libs/std/AGENTS.md`).
////   5. No `pub declare fn` in the file, so `import {asserts} from "std"`
////      passes STD-001 on every target. The four functions that need a host
////      — `matches`, `deepEquals`, `throws`, `throwsWith` — sit on the two
////      PRIVATE cells `regexMatches` and `canonical`, which carry Node and
////      Erlang templates, and on `failure.attempt` (decisions 431, 493): beam
////      compiles the Erlang ones at build time, and wasm, which has no host,
////      refuses the module where those four call their cells — and so every
////      import of it (decision 146).
////
//// The module is named `asserts` (plural) because the unqualified `assert`
//// is a reserved keyword statement; `import {asserts} from "std";` then
//// `asserts.isTrue(x)` keeps the qualified-call style.
////
//// `==` is the language's rule: structural for primitives, reference for
//// arrays and records on commonJS (`===`) and structural on erlang (`=:=`).
//// `equals` on two arrays therefore passes on erlang and fails on commonJS;
//// `deepEquals` is the cross-target answer (both sides are rendered by the
//// same host, so key order agrees).

import {failure, failure.Failure, failure.panic, compiler};

// ── boolean ──────────────────────────────────────────────────────────────────

// Fails when `condition` is false.
pub fn isTrue(condition: bool) -> Result<void, string> {
    if (condition == false) throw "asserts.isTrue: condition was false";
    return;
}

// Fails when `condition` is true — the dual of `isTrue`, for "this must not
// happen" branches you would otherwise spell as `isTrue(!cond)`.
pub fn isFalse(condition: bool) -> Result<void, string> {
    if (condition) throw "asserts.isFalse: condition was true";
    return;
}

// ── equality ─────────────────────────────────────────────────────────────────

// Fails when `actual != expected` (the language's `==`; see the docblock).
pub fn equals<T>(actual: T, expected: T) -> Result<void, string> {
    if (actual != expected) throw "asserts.equals: values differ";
    return;
}

// Fails when `actual == expected`.
pub fn notEquals<T>(actual: T, expected: T) -> Result<void, string> {
    if (actual == expected) throw "asserts.notEquals: values match";
    return;
}

// Fails when `|actual - expected| > tolerance`. Pick a tolerance that fits the
// operation's numerical budget, not `0.0`. The absolute value is an inline
// `if` rather than `math.abs` — a std module does not import another.
pub fn approxEquals(
    actual: f64,
    expected: f64,
    tolerance: f64,
) -> Result<void, string> {
    val diff = actual - expected;
    val absDiff = if (diff >= 0.0) diff else 0.0 - diff;
    if (absDiff > tolerance)
        throw "asserts.approxEquals: values differ by more than tolerance";
    return;
}

// Private: a value rendered canonically by the host — `JSON.stringify` on
// Node, `io_lib:format("~0tp")` on Erlang. Lifted from the old onze's
// `onzeKey`, where it keyed the call log for the same reason: two values that
// render the same are structurally equal on that host.
#[compiler.external(
    .JavaScript("""JSON.stringify($0)"""),
    .Erlang("""iolist_to_binary(io_lib:format("~0tp", [$0]))"""),
)]
declare fn canonical<T>(v: T) -> string;

// Fails when the two values differ structurally — arrays and records by
// content, on every target. Needs Node or Erlang at run time (`canonical`).
pub fn deepEquals<T>(actual: T, expected: T) -> Result<void, string> {
    if (canonical(actual) != canonical(expected))
        throw "asserts.deepEquals: values differ structurally";
    return;
}

// ── nil ──────────────────────────────────────────────────────────────────────

// Fails when the optional holds a value. `!= null`, never truthiness — on
// commonJS `if (x)` is false for `0`.
pub fn isNil<T>(value: ?T) -> Result<void, string> {
    if (value != null) throw "asserts.isNil: value was present";
    return;
}

// Fails when the optional is absent.
pub fn isNotNil<T>(value: ?T) -> Result<void, string> {
    if (value == null) throw "asserts.isNotNil: value was null";
    return;
}

// ── result ───────────────────────────────────────────────────────────────────

// Fails when `result` is `Error`. Read the payload at the call site with the
// builtin methods (`try equals(r.unwrapOr(0), 42);`).
pub fn isOk<T, E>(result: Result<T, E>) -> Result<void, string> {
    if (result.isError()) throw "asserts.isOk: result was Error";
    return;
}

// Fails when `result` is `Ok`. To assert that a `Result`-returning body
// fails, this is the tool — `throws` is for a `panic` or a host throw.
pub fn isError<T, E>(result: Result<T, E>) -> Result<void, string> {
    if (result.isOk()) throw "asserts.isError: result was Ok";
    return;
}

// ── string ───────────────────────────────────────────────────────────────────

// Fails when `needle` is not a substring of `actual`.
pub fn contains(actual: string, needle: string) -> Result<void, string> {
    if (actual.contains(needle) == false)
        throw "asserts.contains: needle not in actual";
    return;
}

// Fails when `needle` is a substring of `actual`.
pub fn notContains(actual: string, needle: string) -> Result<void, string> {
    if (actual.contains(needle))
        throw "asserts.notContains: needle found in actual";
    return;
}

// Fails when `actual` does not start with `prefix`.
pub fn startsWith(actual: string, prefix: string) -> Result<void, string> {
    if (actual.startsWith(prefix) == false)
        throw "asserts.startsWith: prefix does not match";
    return;
}

// Fails when `actual` does not end with `suffix`.
pub fn endsWith(actual: string, suffix: string) -> Result<void, string> {
    if (actual.endsWith(suffix) == false)
        throw "asserts.endsWith: suffix does not match";
    return;
}

// Private `regex.matches` twin, actual-first: inlined here rather than via a
// cross-module call so this file stays self-contained (std-internal modules
// do not import each other). PCRE-ish on both hosts.
#[compiler.external(.JavaScript("""(new RegExp($1).test($0))"""), .Erlang("""(re:run($0, $1) =/= nomatch)"""))]
declare fn regexMatches(actual: string, pattern: string) -> bool;

// Fails when the regular expression `pattern` (the host's native flavour)
// does not match `actual`. Use `contains` for a literal needle. Needs Node or
// Erlang at run time (`regexMatches`).
pub fn matches(actual: string, pattern: string) -> Result<void, string> {
    if (regexMatches(actual, pattern) == false)
        throw "asserts.matches: pattern did not match";
    return;
}

// ── collection ───────────────────────────────────────────────────────────────

// Fails when the array has elements.
pub fn isEmpty<T>(actual: T[]) -> Result<void, string> {
    if (actual.length != 0) throw "asserts.isEmpty: array was not empty";
    return;
}

// Fails when the array is empty.
pub fn isNotEmpty<T>(actual: T[]) -> Result<void, string> {
    if (actual.length == 0) throw "asserts.isNotEmpty: array was empty";
    return;
}

// Fails when the array's length is not `expected`.
pub fn lengthIs<T>(actual: T[], expected: i32) -> Result<void, string> {
    if (actual.length != expected) throw "asserts.lengthIs: length differs";
    return;
}

// Fails when no element `==` `element` (`Array.indexOf` — reference equality
// for records on commonJS; extract with `.at(i)` and `deepEquals` instead).
pub fn includes<T>(actual: T[], element: T) -> Result<void, string> {
    if (actual.indexOf(element) < 0)
        throw "asserts.includes: element not found";
    return;
}

// Fails when some element `==` `element`.
pub fn notIncludes<T>(actual: T[], element: T) -> Result<void, string> {
    if (actual.indexOf(element) >= 0)
        throw "asserts.notIncludes: element found";
    return;
}

// ── numeric ──────────────────────────────────────────────────────────────────

// Fails when `actual` is outside `[low, high]` (both ends included). `i32`
// only: a generic `T` cannot be compared with `<`, and `f64` callers have
// `approxEquals`. `positive`/`negative` are `greaterThan(x, 0)`/`lessThan(x, 0)`.
pub fn between(actual: i32, low: i32, high: i32) -> Result<void, string> {
    // Bound first: an `if (a < b || c > d)` condition does not parse today
    // (the condition grammar stops at `||`; a `val` initialiser takes the
    // whole expression) — a parser gap, recorded by the front that owns it.
    val outside = actual < low || actual > high;
    if (outside) throw "asserts.between: value out of range";
    return;
}

// Fails when `actual <= bound`.
pub fn greaterThan(actual: i32, bound: i32) -> Result<void, string> {
    if (actual <= bound) throw "asserts.greaterThan: value not greater";
    return;
}

// Fails when `actual >= bound`.
pub fn lessThan(actual: i32, bound: i32) -> Result<void, string> {
    if (actual >= bound) throw "asserts.lessThan: value not less";
    return;
}

// ── exceptions ───────────────────────────────────────────────────────────────

// Private: the message `failure.attempt` caught, or `""` for a body that
// completed.
fn caughtMessage<T>(r: Result<T, Failure>) -> string {
    val text = case r {
        Ok(v) -> "";
        Error(f) -> f.message;
    };
    return text;
}

// Fails when `body` completes normally — for a `panic` or a host raise from
// code whose return carries no `Result` (a failing `Result` is `isError`).
// Generic over the body's own type and run under `failure.attempt` (decisions
// 431, 493), so it needs Node or Erlang at run time.
pub fn throws<T>(body: fn() -> T) -> Result<void, string> {
    val r = failure.attempt(body);
    if (r.isOk()) throw "asserts.throws: body did not raise";
    return;
}

// Fails when `body` completes normally, or when the caught message does not
// contain `needle`. The message is `failure.attempt`'s `Failure.message`: a
// `panic(text)` / `@todo(text)` is its own `text` on every target, byte for
// byte — a needle with a `"`, a `\` or a non-ASCII character matches alike;
// any other host raise is its JS `message` (else `String(e)`) on Node and
// the reason by `~tp` on Erlang (`badarg`).
pub fn throwsWith<T>(body: fn() -> T, needle: string) -> Result<void, string> {
    val r = failure.attempt(body);
    if (r.isOk()) throw "asserts.throwsWith: body did not raise";
    if (caughtMessage(r).contains(needle) == false)
        throw "asserts.throwsWith: message does not contain needle";
    return;
}

// ── utility ──────────────────────────────────────────────────────────────────

// Always `Error("asserts.fail: <message>")` — the one function whose message
// carries caller text; the escape for a branch the test asserts is unreachable.
pub fn fail(message: string) -> Result<void, string> {
    throw "asserts.fail: " + message;
}

// The `Error` payload of an assertion's result, or `""` for `Ok`. Not
// a `-> Result` fn: it is how a test reads a failure message to compare or
// snapshot it (`test-snap.md`), matching over the builtin `Result` enum in a
// function the manual-construction rule does not apply to.
pub fn errorText(r: Result<void, string>) -> string {
    val text = case r {
        Ok(v) -> "";
        Error(e) -> e;
    };
    return text;
}

// ── tests ────────────────────────────────────────────────────────────────────
// One test per function per path, written with `try`; a fail path asserts
// `isError` over the assertion's own result and pins the literal message
// through `errorText` (no host cell, no panic).

fn parsePort(s: string) -> Result<i32, string> {
    if (s == "") throw "empty input";
    return 8080;
}

fn explode() -> i32 {
    panic("boom: the widget is on fire");
    return 0;
}

// boolean

test "asserts: isTrue passes on true" {
    try isTrue(true);
    try isTrue(1 + 1 == 2);
}

test "asserts: isTrue fails on false" {
    val r = isTrue(1 == 2);
    try isError(r);
    try equals(errorText(r), "asserts.isTrue: condition was false");
}

test "asserts: isFalse passes on false" {
    try isFalse(false);
    try isFalse("abc".startsWith("z"));
}

test "asserts: isFalse fails on true" {
    val r = isFalse(true);
    try isError(r);
    try equals(errorText(r), "asserts.isFalse: condition was true");
}

// equality

test "asserts: equals passes on equal primitives" {
    try equals(42, 42);
    try equals("hello", "hello");
    try equals(true, true);
}

test "asserts: equals fails on different values" {
    val r = equals("ana", "bob");
    try isError(r);
    try equals(errorText(r), "asserts.equals: values differ");
}

test "asserts: notEquals passes when the values differ" {
    try notEquals(1, 2);
    try notEquals("a", "b");
}

test "asserts: notEquals fails on equal values" {
    val r = notEquals(7, 7);
    try isError(r);
    try equals(errorText(r), "asserts.notEquals: values match");
}

test "asserts: approxEquals accepts a value inside the tolerance" {
    try approxEquals(3.14159, 3.14, 0.01);
    try approxEquals(0.0, 0.0, 0.0);
}

test "asserts: approxEquals fails outside the tolerance" {
    val r = approxEquals(1.0, 2.0, 0.5);
    try isError(r);
    try equals(
        errorText(r),
        "asserts.approxEquals: values differ by more than tolerance",
    );
}

test "asserts: deepEquals compares arrays by content on every target" {
    val left = [1, 2, 3];
    val right = [1, 2, 3];
    try deepEquals(left, right);
}

test "asserts: deepEquals fails on structurally different values" {
    val r = deepEquals([1, 2], [2, 1]);
    try isError(r);
    try equals(errorText(r), "asserts.deepEquals: values differ structurally");
}

// nil

test "asserts: isNil and isNotNil read an optional" {
    val xs = [10, 20, 30];
    try isNotNil(xs.at(1));
    try isNil(xs.at(9));
}

test "asserts: isNil fails on a present value" {
    val xs = [10];
    val r = isNil(xs.at(0));
    try isError(r);
    try equals(errorText(r), "asserts.isNil: value was present");
}

test "asserts: isNotNil fails on null" {
    val xs = [10];
    val r = isNotNil(xs.at(5));
    try isError(r);
    try equals(errorText(r), "asserts.isNotNil: value was null");
}

// result

test "asserts: isOk and isError read a Result" {
    try isOk(parsePort("8080"));
    try isError(parsePort(""));
}

test "asserts: the Ok payload is read with unwrapOr" {
    val port = parsePort("8080").unwrapOr(0);
    try equals(port, 8080);
}

test "asserts: isOk fails on an Error" {
    val r = isOk(parsePort(""));
    try isError(r);
    try equals(errorText(r), "asserts.isOk: result was Error");
}

test "asserts: isError fails on an Ok" {
    val r = isError(parsePort("1"));
    try isError(r);
    try equals(errorText(r), "asserts.isError: result was Ok");
}

// string

test "asserts: contains, startsWith and endsWith over a string" {
    try contains("hello world", "o w");
    try notContains("hello world", "xyz");
    try startsWith("/api/users", "/api");
    try endsWith("page.bp", ".bp");
}

test "asserts: contains fails on a missing needle" {
    val r = contains("hello", "xyz");
    try isError(r);
    try equals(errorText(r), "asserts.contains: needle not in actual");
}

test "asserts: notContains fails on a present needle" {
    val r = notContains("hello", "ell");
    try isError(r);
    try equals(errorText(r), "asserts.notContains: needle found in actual");
}

test "asserts: startsWith fails on another prefix" {
    val r = startsWith("/api", "/v2");
    try isError(r);
    try equals(errorText(r), "asserts.startsWith: prefix does not match");
}

test "asserts: endsWith fails on another suffix" {
    val r = endsWith("page.bp", ".js");
    try isError(r);
    try equals(errorText(r), "asserts.endsWith: suffix does not match");
}

test "asserts: matches takes the actual first and the pattern second" {
    try matches("555-1234", "^[0-9]{3}-[0-9]{4}$");
    try matches("abc123def", "[0-9]+");
}

test "asserts: matches fails when the pattern does not match" {
    val r = matches("abc", "^[0-9]+$");
    try isError(r);
    try equals(errorText(r), "asserts.matches: pattern did not match");
}

// collection

test "asserts: isEmpty, isNotEmpty and lengthIs over an array" {
    val none: i32[] = [];
    try isEmpty(none);
    try isNotEmpty([1]);
    try lengthIs([1, 2, 3], 3);
    try lengthIs(none, 0);
}

test "asserts: isEmpty fails on elements" {
    val r = isEmpty([1]);
    try isError(r);
    try equals(errorText(r), "asserts.isEmpty: array was not empty");
}

test "asserts: isNotEmpty fails on an empty array" {
    val none: i32[] = [];
    val r = isNotEmpty(none);
    try isError(r);
    try equals(errorText(r), "asserts.isNotEmpty: array was empty");
}

test "asserts: lengthIs fails on another length" {
    val r = lengthIs([1, 2], 3);
    try isError(r);
    try equals(errorText(r), "asserts.lengthIs: length differs");
}

test "asserts: includes and notIncludes over an array" {
    try includes([1, 2, 3], 2);
    try notIncludes(["a", "b"], "z");
}

test "asserts: includes fails on a missing element" {
    val r = includes([1, 2, 3], 4);
    try isError(r);
    try equals(errorText(r), "asserts.includes: element not found");
}

test "asserts: notIncludes fails on a present element" {
    val r = notIncludes([1, 2, 3], 2);
    try isError(r);
    try equals(errorText(r), "asserts.notIncludes: element found");
}

// numeric

test "asserts: between is inclusive on both ends" {
    try between(5, 1, 10);
    try between(1, 1, 10);
    try between(10, 1, 10);
}

test "asserts: between fails outside the range" {
    val r = between(0, 1, 10);
    try isError(r);
    try equals(errorText(r), "asserts.between: value out of range");
}

test "asserts: greaterThan and lessThan are strict" {
    try greaterThan(3, 2);
    try lessThan(2, 3);
}

test "asserts: greaterThan fails on an equal value" {
    val r = greaterThan(2, 2);
    try isError(r);
    try equals(errorText(r), "asserts.greaterThan: value not greater");
}

test "asserts: lessThan fails on a greater value" {
    val r = lessThan(3, 2);
    try isError(r);
    try equals(errorText(r), "asserts.lessThan: value not less");
}

// exceptions

test "asserts: throws catches a panicking body" {
    try throws({ ->
        explode();
        0
    });
}

test "asserts: throws fails when the body completes" {
    val r = throws({ ->
        0
    });
    try isError(r);
    try equals(errorText(r), "asserts.throws: body did not raise");
}

test "asserts: throwsWith checks the message" {
    try throwsWith({ ->
        explode();
        0
    }, "on fire");
}

fn quoteRaiser() -> i32 {
    panic("withHeader(\"Set-Cookie\", v) \\ twice");
    return 0;
}

test "asserts: throwsWith matches a needle with a quote or a backslash on every target" {
    try throwsWith({ ->
        quoteRaiser();
        0
    }, "withHeader(\"Set-Cookie\"");
    try throwsWith({ ->
        quoteRaiser();
        0
    }, "v) \\ twice");
    // The raised text itself, not a rendering of it: the escaped spelling
    // `\"` is not in the message.
    val escaped = throwsWith({ ->
        quoteRaiser();
        0
    }, "withHeader(\\\"");
    try equals(
        errorText(escaped),
        "asserts.throwsWith: message does not contain needle",
    );
}

test "asserts: throwsWith fails when the body completes" {
    val r = throwsWith({ ->
        0
    }, "anything");
    try isError(r);
    try equals(errorText(r), "asserts.throwsWith: body did not raise");
}

test "asserts: throwsWith fails on a message without the needle" {
    val r = throwsWith({ ->
        explode();
        0
    }, "not in the message");
    try isError(r);
    try equals(
        errorText(r),
        "asserts.throwsWith: message does not contain needle",
    );
}

// utility

test "asserts: fail always answers Error and carries the caller's text" {
    val r = fail("this branch is unreachable");
    try isError(r);
    try equals(errorText(r), "asserts.fail: this branch is unreachable");
}

test "asserts: errorText answers the empty string for Ok" {
    try equals(errorText(isTrue(true)), "");
}

```

----- JAVASCRIPT -- std/testing/asserts.js
```javascript
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

//// std/testing/asserts — the canonical assertion API every test is written against

//// (1.0.10-beta front 01-std, `asserts-api.md`; decisions 74 and 67).

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/assert.html

////   Erlang   — (no equivalent module; pattern matching does the same job)

//// 

//// Every assertion answers `-> Result<void, string>` (the return is the effect):

//// success is `Ok`, failure is `Error(message)`. The caller writes

//// `try asserts.equals(a, b);` and a failure propagates to the enclosing

//// `test` body, which ends as `FAIL <name>  (<message>)  at <file>:<line>`

//// (the test body is a fallible context — `conformance/docs.md` § Tests). A `-test`

//// helper that is itself `-> Result<void, string>` composes an assertion

//// with `try` and nothing else; nothing here panics.

//// 

//// Five rules (`asserts-api.md` § The shape of every function):

////   1. `-> Result<void, string>`; the `ok` position is `return;`.

////   2. `actual` first, `expected` second — everywhere (`matches(actual, pattern)`).

////   3. One literal message per function, `asserts.<fn>: <what>`; no value

////      rendering (a generic `T` has no `toString`). The call site's `@src()`

////      and the runner's `at <file>:<line>` say where; the message says which.

////   4. Pure botopink on the path that runs everywhere: `==`, `!=`, `== false`,

////      `.length`, `.contains()`, `.startsWith()`, `.endsWith()`, `.indexOf()`,

////      `.isOk()`, `.isError()`, `!= null` — host-backed primitives only. A

////      primitive `default fn` (`Bool.negate`, `Array.contains`) is not lowered

////      when a std module is compiled as a consumer's embedded import today,

////      so none is used here (measured 2026-09-20; `libs/std/AGENTS.md`).

////   5. No `pub declare fn` in the file, so `import {asserts} from "std"`

////      passes STD-001 on every target. The four functions that need a host

////      — `matches`, `deepEquals`, `throws`, `throwsWith` — sit on the two

////      PRIVATE cells `regexMatches` and `canonical`, which carry Node and

////      Erlang templates, and on `failure.attempt` (decisions 431, 493): beam

////      compiles the Erlang ones at build time, and wasm, which has no host,

////      refuses the module where those four call their cells — and so every

////      import of it (decision 146).

//// 

//// The module is named `asserts` (plural) because the unqualified `assert`

//// is a reserved keyword statement; `import {asserts} from "std";` then

//// `asserts.isTrue(x)` keeps the qualified-call style.

//// 

//// `==` is the language's rule: structural for primitives, reference for

//// arrays and records on commonJS (`===`) and structural on erlang (`=:=`).

//// `equals` on two arrays therefore passes on erlang and fails on commonJS;

//// `deepEquals` is the cross-target answer (both sides are rendered by the

//// same host, so key order agrees).

const failure = require("./std@failure");
const { Failure } = require("./std@failure");

// ── boolean ──────────────────────────────────────────────────────────────────

// Fails when `condition` is false.

function isTrue(condition) {
    if ((condition === false)) { return ({ error: "asserts.isTrue: condition was false" }); }
    return ({ ok: null });
}
exports.isTrue = isTrue;

// Fails when `condition` is true — the dual of `isTrue`, for "this must not

// happen" branches you would otherwise spell as `isTrue(!cond)`.

function isFalse(condition) {
    if (condition) { return ({ error: "asserts.isFalse: condition was true" }); }
    return ({ ok: null });
}
exports.isFalse = isFalse;

// ── equality ─────────────────────────────────────────────────────────────────

// Fails when `actual != expected` (the language's `==`; see the docblock).

function equals(actual, expected) {
    if ((!__bp_eq(actual, expected, 0))) { return ({ error: "asserts.equals: values differ" }); }
    return ({ ok: null });
}
exports.equals = equals;

// Fails when `actual == expected`.

function notEquals(actual, expected) {
    if (__bp_eq(actual, expected, 0)) { return ({ error: "asserts.notEquals: values match" }); }
    return ({ ok: null });
}
exports.notEquals = notEquals;

// Fails when `|actual - expected| > tolerance`. Pick a tolerance that fits the

// operation's numerical budget, not `0.0`. The absolute value is an inline

// `if` rather than `math.abs` — a std module does not import another.

function approxEquals(actual, expected, tolerance) {
    const diff = (actual - expected);
    const absDiff = (() => { if ((diff >= 0.0)) { return diff; } else { return (0.0 - diff); } })();
    if ((absDiff > tolerance)) { return ({ error: "asserts.approxEquals: values differ by more than tolerance" }); }
    return ({ ok: null });
}
exports.approxEquals = approxEquals;

// Private: a value rendered canonically by the host — `JSON.stringify` on

// Node, `io_lib:format("~0tp")` on Erlang. Lifted from the old onze's

// `onzeKey`, where it keyed the call log for the same reason: two values that

// render the same are structurally equal on that host.

// canonical: per-call template (see annotation)

// Fails when the two values differ structurally — arrays and records by

// content, on every target. Needs Node or Erlang at run time (`canonical`).

function deepEquals(actual, expected) {
    if ((JSON.stringify(actual) !== JSON.stringify(expected))) { return ({ error: "asserts.deepEquals: values differ structurally" }); }
    return ({ ok: null });
}
exports.deepEquals = deepEquals;

// ── nil ──────────────────────────────────────────────────────────────────────

// Fails when the optional holds a value. `!= null`, never truthiness — on

// commonJS `if (x)` is false for `0`.

function isNil(value) {
    if ((value != null)) { return ({ error: "asserts.isNil: value was present" }); }
    return ({ ok: null });
}
exports.isNil = isNil;

// Fails when the optional is absent.

function isNotNil(value) {
    if ((value == null)) { return ({ error: "asserts.isNotNil: value was null" }); }
    return ({ ok: null });
}
exports.isNotNil = isNotNil;

// ── result ───────────────────────────────────────────────────────────────────

// Fails when `result` is `Error`. Read the payload at the call site with the

// builtin methods (`try equals(r.unwrapOr(0), 42);`).

function isOk(result) {
    if (((_r) => "error" in _r)(result)) { return ({ error: "asserts.isOk: result was Error" }); }
    return ({ ok: null });
}
exports.isOk = isOk;

// Fails when `result` is `Ok`. To assert that a `Result`-returning body

// fails, this is the tool — `throws` is for a `panic` or a host throw.

function isError(result) {
    if (((_r) => !("error" in _r))(result)) { return ({ error: "asserts.isError: result was Ok" }); }
    return ({ ok: null });
}
exports.isError = isError;

// ── string ───────────────────────────────────────────────────────────────────

// Fails when `needle` is not a substring of `actual`.

function contains(actual, needle) {
    if ((actual.includes(needle) === false)) { return ({ error: "asserts.contains: needle not in actual" }); }
    return ({ ok: null });
}
exports.contains = contains;

// Fails when `needle` is a substring of `actual`.

function notContains(actual, needle) {
    if (actual.includes(needle)) { return ({ error: "asserts.notContains: needle found in actual" }); }
    return ({ ok: null });
}
exports.notContains = notContains;

// Fails when `actual` does not start with `prefix`.

function startsWith(actual, prefix) {
    if ((actual.startsWith(prefix) === false)) { return ({ error: "asserts.startsWith: prefix does not match" }); }
    return ({ ok: null });
}
exports.startsWith = startsWith;

// Fails when `actual` does not end with `suffix`.

function endsWith(actual, suffix) {
    if ((actual.endsWith(suffix) === false)) { return ({ error: "asserts.endsWith: suffix does not match" }); }
    return ({ ok: null });
}
exports.endsWith = endsWith;

// Private `regex.matches` twin, actual-first: inlined here rather than via a

// cross-module call so this file stays self-contained (std-internal modules

// do not import each other). PCRE-ish on both hosts.

// regexMatches: per-call template (see annotation)

// Fails when the regular expression `pattern` (the host's native flavour)

// does not match `actual`. Use `contains` for a literal needle. Needs Node or

// Erlang at run time (`regexMatches`).

function matches(actual, pattern) {
    if (((new RegExp(pattern).test(actual)) === false)) { return ({ error: "asserts.matches: pattern did not match" }); }
    return ({ ok: null });
}
exports.matches = matches;

// ── collection ───────────────────────────────────────────────────────────────

// Fails when the array has elements.

function isEmpty(actual) {
    if ((actual.length !== 0)) { return ({ error: "asserts.isEmpty: array was not empty" }); }
    return ({ ok: null });
}
exports.isEmpty = isEmpty;

// Fails when the array is empty.

function isNotEmpty(actual) {
    if ((actual.length === 0)) { return ({ error: "asserts.isNotEmpty: array was empty" }); }
    return ({ ok: null });
}
exports.isNotEmpty = isNotEmpty;

// Fails when the array's length is not `expected`.

function lengthIs(actual, expected) {
    if ((actual.length !== expected)) { return ({ error: "asserts.lengthIs: length differs" }); }
    return ({ ok: null });
}
exports.lengthIs = lengthIs;

// Fails when no element `==` `element` (`Array.indexOf` — reference equality

// for records on commonJS; extract with `.at(i)` and `deepEquals` instead).

function includes(actual, element) {
    if ((actual.indexOf(element) < 0)) { return ({ error: "asserts.includes: element not found" }); }
    return ({ ok: null });
}
exports.includes = includes;

// Fails when some element `==` `element`.

function notIncludes(actual, element) {
    if ((actual.indexOf(element) >= 0)) { return ({ error: "asserts.notIncludes: element found" }); }
    return ({ ok: null });
}
exports.notIncludes = notIncludes;

// ── numeric ──────────────────────────────────────────────────────────────────

// Fails when `actual` is outside `[low, high]` (both ends included). `i32`

// only: a generic `T` cannot be compared with `<`, and `f64` callers have

// `approxEquals`. `positive`/`negative` are `greaterThan(x, 0)`/`lessThan(x, 0)`.

function between(actual, low, high) {
    // Bound first: an `if (a < b || c > d)` condition does not parse today;
    // (the condition grammar stops at `||`; a `val` initialiser takes the;
    // whole expression) — a parser gap, recorded by the front that owns it.;
    const outside = ((actual < low) || (actual > high));
    if (outside) { return ({ error: "asserts.between: value out of range" }); }
    return ({ ok: null });
}
exports.between = between;

// Fails when `actual <= bound`.

function greaterThan(actual, bound) {
    if ((actual <= bound)) { return ({ error: "asserts.greaterThan: value not greater" }); }
    return ({ ok: null });
}
exports.greaterThan = greaterThan;

// Fails when `actual >= bound`.

function lessThan(actual, bound) {
    if ((actual >= bound)) { return ({ error: "asserts.lessThan: value not less" }); }
    return ({ ok: null });
}
exports.lessThan = lessThan;

// ── exceptions ───────────────────────────────────────────────────────────────

// Private: the message `failure.attempt` caught, or `""` for a body that

// completed.

function caughtMessage(r) {
    const text = (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
            return "";
        }
        if ("error" in _s) {
            const f = _s.error;
            return f.message;
        }
        throw new Error("case_clause");
    })();
    return text;
}

// Fails when `body` completes normally — for a `panic` or a host raise from

// code whose return carries no `Result` (a failing `Result` is `isError`).

// Generic over the body's own type and run under `failure.attempt` (decisions

// 431, 493), so it needs Node or Erlang at run time.

function throws(body) {
    const r = failure.attempt(body);
    if (((_r) => !("error" in _r))(r)) { return ({ error: "asserts.throws: body did not raise" }); }
    return ({ ok: null });
}
exports.throws = throws;

// Fails when `body` completes normally, or when the caught message does not

// contain `needle`. The message is `failure.attempt`'s `Failure.message`: a

// `panic(text)` / `@todo(text)` is its own `text` on every target, byte for

// byte — a needle with a `"`, a `\` or a non-ASCII character matches alike;

// any other host raise is its JS `message` (else `String(e)`) on Node and

// the reason by `~tp` on Erlang (`badarg`).

function throwsWith(body, needle) {
    const r = failure.attempt(body);
    if (((_r) => !("error" in _r))(r)) { return ({ error: "asserts.throwsWith: body did not raise" }); }
    if ((caughtMessage(r).includes(needle) === false)) { return ({ error: "asserts.throwsWith: message does not contain needle" }); }
    return ({ ok: null });
}
exports.throwsWith = throwsWith;

// ── utility ──────────────────────────────────────────────────────────────────

// Always `Error("asserts.fail: <message>")` — the one function whose message

// carries caller text; the escape for a branch the test asserts is unreachable.

function fail(message) {
    return ({ error: ("asserts.fail: " + message) });
}
exports.fail = fail;

// The `Error` payload of an assertion's result, or `""` for `Ok`. Not

// a `-> Result` fn: it is how a test reads a failure message to compare or

// snapshot it (`test-snap.md`), matching over the builtin `Result` enum in a

// function the manual-construction rule does not apply to.

function errorText(r) {
    const text = (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
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

// ── tests ────────────────────────────────────────────────────────────────────

// One test per function per path, written with `try`; a fail path asserts

// `isError` over the assertion's own result and pins the literal message

// through `errorText` (no host cell, no panic).

function parsePort(s) {
    if ((s === "")) { return ({ error: "empty input" }); }
    return ({ ok: 8080 });
}

function explode() {
    (() => { throw Object.defineProperty(new Error("boom: the widget is on fire"), '__bp_panic', { value: true }) })();
    return 0;
}

// boolean

// equality

// nil

// result

// string

// collection

// numeric

// exceptions

function quoteRaiser() {
    (() => { throw Object.defineProperty(new Error("withHeader(\"Set-Cookie\", v) \\ twice"), '__bp_panic', { value: true }) })();
    return 0;
}

// utility

Object.defineProperty(exports, "__bp_priv__", { value: { failure, Failure, isTrue, isFalse, equals, notEquals, approxEquals, deepEquals, isNil, isNotNil, isOk, isError, contains, notContains, startsWith, endsWith, matches, isEmpty, isNotEmpty, lengthIs, includes, notIncludes, between, greaterThan, lessThan, caughtMessage, throws, throwsWith, fail, errorText, parsePort, explode, quoteRaiser } });
```

----- TYPESCRIPT TYPEDEF -- std/testing/asserts.d.ts
```typescript
import * as failure from "./std@failure";
import { Failure } from "./std@failure";


export declare function isTrue(condition: boolean): { ok: void } | { error: string };


export declare function isFalse(condition: boolean): { ok: void } | { error: string };


export declare function equals<T>(actual: T, expected: T): { ok: void } | { error: string };


export declare function notEquals<T>(actual: T, expected: T): { ok: void } | { error: string };


export declare function approxEquals(actual: number, expected: number, tolerance: number): { ok: void } | { error: string };




export declare function deepEquals<T>(actual: T, expected: T): { ok: void } | { error: string };


export declare function isNil<T>(value: T | null): { ok: void } | { error: string };


export declare function isNotNil<T>(value: T | null): { ok: void } | { error: string };


export declare function isOk<T, E>(result: { ok: T } | { error: E }): { ok: void } | { error: string };


export declare function isError<T, E>(result: { ok: T } | { error: E }): { ok: void } | { error: string };


export declare function contains(actual: string, needle: string): { ok: void } | { error: string };


export declare function notContains(actual: string, needle: string): { ok: void } | { error: string };


export declare function startsWith(actual: string, prefix: string): { ok: void } | { error: string };


export declare function endsWith(actual: string, suffix: string): { ok: void } | { error: string };




export declare function matches(actual: string, pattern: string): { ok: void } | { error: string };


export declare function isEmpty<T>(actual: T[]): { ok: void } | { error: string };


export declare function isNotEmpty<T>(actual: T[]): { ok: void } | { error: string };


export declare function lengthIs<T>(actual: T[], expected: number): { ok: void } | { error: string };


export declare function includes<T>(actual: T[], element: T): { ok: void } | { error: string };


export declare function notIncludes<T>(actual: T[], element: T): { ok: void } | { error: string };


export declare function between(actual: number, low: number, high: number): { ok: void } | { error: string };


export declare function greaterThan(actual: number, bound: number): { ok: void } | { error: string };


export declare function lessThan(actual: number, bound: number): { ok: void } | { error: string };




export declare function throws<T>(body: () => T): { ok: void } | { error: string };


export declare function throwsWith<T>(body: () => T, needle: string): { ok: void } | { error: string };


export declare function fail(message: string): { ok: void } | { error: string };


export declare function errorText(r: { ok: void } | { error: string }): string;







```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
fn at<T>(xs: T[], x: T) -> i32 {
    return xs.indexOf(x);
}

fn lastAt<T>(xs: T[], x: T) -> i32 {
    return xs.lastIndexOf(x);
}

fn holds<T>(xs: T[], x: T) -> bool {
    return xs.contains(x);
}

pub fn main() -> void {
    print(asserts.includes([1, 2], 2).isOk());
    print(asserts.includes([1, 2], 3).isOk());
    print(at([2.5, 3.5], 3.5));
    print(at(["a", "b"], "b"));
    print(lastAt([1, 2, 1], 1));
    print(lastAt([true, false], true));
    print(holds(["x"], "y"));
}

import {io.terminal.print} from "std";
import {testing.asserts} from "std";
```

----- JAVASCRIPT -- main.js
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

function at(xs, x) {
    return xs.indexOf(x);
}

function lastAt(xs, x) {
    return xs.lastIndexOf(x);
}

function holds(xs, x) {
    return xs.contains(x);
}

function main() {
    __bp_print(((_r) => !("error" in _r))(asserts.includes([1, 2], 2)));
    __bp_print(((_r) => !("error" in _r))(asserts.includes([1, 2], 3)));
    __bp_print(at([2.5, 3.5], 3.5));
    __bp_print(at(["a", "b"], "b"));
    __bp_print(lastAt([1, 2, 1], 1));
    __bp_print(lastAt([true, false], true));
    __bp_print(holds(["x"], "y"));
}
exports.main = main;

const asserts = require("./std@testing@asserts");

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { at, lastAt, holds, main, asserts } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript






export declare function main(): void;

```

----- RUN LOG -----
```logs
true
false
1
1
2
0
false
```
