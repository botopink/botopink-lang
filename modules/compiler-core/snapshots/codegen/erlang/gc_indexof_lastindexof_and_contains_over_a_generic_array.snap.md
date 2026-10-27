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

----- ERLANG -- std/failure.erl
```erlang
-module(std@failure).
-export([panic/1, attempt/1, attemptTask/1, '__bp_priv__attemptOnWasm'/1, '__bp_priv__attemptTaskOnWasm'/1]).

%%% std/failure — the two records a failure that is not a typed error carries

%%% (decisions 431, 492).

%%% 

%%% `HostError` is what a host binding that writes `result: true` answers on

%%% the `Error` side: the host's message and `kind`, always `"host"`.

%%% `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`

%%% (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise

%%% from a binding without `result: true`) or `crash` (a VM or emitted-code

%%% fault, a wasm trap).

%%% 

%%% `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`

%%% for a raise it caught — the one way to contain a crash (decision 431 (3)).

%%% `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,

%%% awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read

%%% back by `await` like any failing task (decision 432). The kinds

%%% (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`

%%% and an integer overflow or division by zero are `panic`, their message

%%% the text the program wrote. A raise of a binding declared outside std without

%%% `result: true` is `host` (decision 546), its message the host's text — on

%%% commonJS an `Error`'s `message`, else `String(e)`, the call run through

%%% `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is

%%% `crash`, its message the same text. On erlang and beam a

%%% host raise is the raise of a binding declared outside std without `result:

%%% true` — a library's or the program's, whose calls are wrapped to mark it

%%% (decision 546) — its message the reason by `~tp` (decision 489's reading);

%%% a raise nothing marked, a failing match or a std binding's, is `crash`,

%%% its message the reason by `~tp` too.

%%% 

%%% Both are bodyless: each backend wraps the call (a JavaScript `try` /

%%% rejection handler, an erlang `try … catch`; beam compiles the erlang

%%% form). On wasm (decision 518) each is a private body over `caught`, the

%%% `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that

%%% catches the program's aborts (wasm exception handling), so the binding

%%% declares `needs: [.Exceptions]` and a program reaching it runs with the

%%% host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort

%%% is `panic`; a trap (an overflow or a division by zero there, a host

%%% fault) is no exception and is not caught. `attemptTask` contains what

%%% the thunk raises before the task's first `await`.

%% type HostErrorName
%%   Error
%%   Throw
%%   Exit

%% type HostError: message, kind, name, detail

%% type Failure: message, kind

% Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops

% with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.

% Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`

% inside std); `panic("not implemented")` is what `todo` was.

%% external fn panic -> erlang template
panic(Message) ->
    erlang:error({panic, Message}).

% The Node forms read an abort by the `__bp_panic` mark the backend puts on

% every one it raises — `panic`, `@todo`, an integer overflow or division

% by zero, a failed `assert` (whose mark carries its message) — or a test

% body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the

% backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,

% M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task

% (decision 432): marked `__bp_fails`, resolved with the value, rejected with

% the `Failure` (`__bp_failure`); a failing task `f` answers is read as

% `await` reads it.

%% external fn attempt -> erlang template
attempt(F) ->
    (fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)(F).

%% external fn attemptTask -> erlang template
attemptTask(F) ->
    (fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)(F).

% wasm's form (decision 518): the thunk's value, or the message of the abort

% it raised — `Error` of the abort's text, which `attempt` makes a `panic`.

% The bodies over it are compiled on every target, so it has a form on each;

% only wasm calls it (`attempt`'s own forms answer elsewhere).

%% external fn caught -> erlang template

attemptOnWasm(F) ->
    case (fun(__F) -> try {ok, __F()} catch _:__R -> {error, unicode:characters_to_binary(io_lib:format("~tp", [__R]))} end end)(F) of
        {ok, V} ->
            {ok, V};
        {error, M} ->
            {error, {std@failure@@Failure, M, <<"panic">>}}
    end.

% The task the thunk started — or the `Failure` it raised before its first

% `await` — and then its value.

%% @Async — eager lowering
attemptTaskOnWasm(F) ->
    case (fun(__F) -> try {ok, __F()} catch _:__R -> {error, unicode:characters_to_binary(io_lib:format("~tp", [__R]))} end end)(F) of
        {ok, T} ->
            {ok, T};
        {error, M} ->
            {error, {std@failure@@Failure, M, <<"panic">>}}
    end.

'__bp_priv__attemptOnWasm'(A0) -> attemptOnWasm(A0).

'__bp_priv__attemptTaskOnWasm'(A0) -> attemptTaskOnWasm(A0).
```

----- ERLANG -- std@failure@@HostErrorName.erl
```erlang
-module(std@failure@@HostErrorName).
-export(['__bp_format'/1]).

'__bp_format'(std@failure@@HostErrorName__v__error) -> {variant, "HostErrorName.Error", []};
'__bp_format'(std@failure@@HostErrorName__v__throw) -> {variant, "HostErrorName.Throw", []};
'__bp_format'(std@failure@@HostErrorName__v__exit) -> {variant, "HostErrorName.Exit", []}.
```

----- ERLANG -- std@failure@@HostError.erl
```erlang
-module(std@failure@@HostError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V);
'__bp_get'(V, kind) -> erlang:element(3, V);
'__bp_get'(V, name) -> erlang:element(4, V);
'__bp_get'(V, detail) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "HostError", [{"message", erlang:element(2, V)}, {"kind", erlang:element(3, V)}, {"name", erlang:element(4, V)}, {"detail", erlang:element(5, V)}]}.
```

----- ERLANG -- std@failure@@Failure.erl
```erlang
-module(std@failure@@Failure).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V);
'__bp_get'(V, kind) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Failure", [{"message", erlang:element(2, V)}, {"kind", erlang:element(3, V)}]}.
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

----- ERLANG -- std/testing/asserts.erl
```erlang
-module(std@testing@asserts).
-export([isTrue/1, isFalse/1, equals/2, notEquals/2, approxEquals/3, deepEquals/2, isNil/1, isNotNil/1, isOk/1, isError/1, contains/2, notContains/2, startsWith/2, endsWith/2, matches/2, isEmpty/1, isNotEmpty/1, lengthIs/2, includes/2, notIncludes/2, between/3, greaterThan/2, lessThan/2, throws/1, throwsWith/2, fail/1, errorText/1, '__bp_priv__caughtMessage'/1, '__bp_priv__parsePort'/1, '__bp_priv__explode'/0, '__bp_priv__quoteRaiser'/0]).

%%% std/testing/asserts — the canonical assertion API every test is written against

%%% (1.0.10-beta front 01-std, `asserts-api.md`; decisions 74 and 67).

%%% 

%%% Reference:

%%%   Node.js  — https://nodejs.org/api/assert.html

%%%   Erlang   — (no equivalent module; pattern matching does the same job)

%%% 

%%% Every assertion answers `-> Result<void, string>` (the return is the effect):

%%% success is `Ok`, failure is `Error(message)`. The caller writes

%%% `try asserts.equals(a, b);` and a failure propagates to the enclosing

%%% `test` body, which ends as `FAIL <name>  (<message>)  at <file>:<line>`

%%% (the test body is a fallible context — `conformance/docs.md` § Tests). A `-test`

%%% helper that is itself `-> Result<void, string>` composes an assertion

%%% with `try` and nothing else; nothing here panics.

%%% 

%%% Five rules (`asserts-api.md` § The shape of every function):

%%%   1. `-> Result<void, string>`; the `ok` position is `return;`.

%%%   2. `actual` first, `expected` second — everywhere (`matches(actual, pattern)`).

%%%   3. One literal message per function, `asserts.<fn>: <what>`; no value

%%%      rendering (a generic `T` has no `toString`). The call site's `@src()`

%%%      and the runner's `at <file>:<line>` say where; the message says which.

%%%   4. Pure botopink on the path that runs everywhere: `==`, `!=`, `== false`,

%%%      `.length`, `.contains()`, `.startsWith()`, `.endsWith()`, `.indexOf()`,

%%%      `.isOk()`, `.isError()`, `!= null` — host-backed primitives only. A

%%%      primitive `default fn` (`Bool.negate`, `Array.contains`) is not lowered

%%%      when a std module is compiled as a consumer's embedded import today,

%%%      so none is used here (measured 2026-09-20; `libs/std/AGENTS.md`).

%%%   5. No `pub declare fn` in the file, so `import {asserts} from "std"`

%%%      passes STD-001 on every target. The four functions that need a host

%%%      — `matches`, `deepEquals`, `throws`, `throwsWith` — sit on the two

%%%      PRIVATE cells `regexMatches` and `canonical`, which carry Node and

%%%      Erlang templates, and on `failure.attempt` (decisions 431, 493): beam

%%%      compiles the Erlang ones at build time, and wasm, which has no host,

%%%      refuses the module where those four call their cells — and so every

%%%      import of it (decision 146).

%%% 

%%% The module is named `asserts` (plural) because the unqualified `assert`

%%% is a reserved keyword statement; `import {asserts} from "std";` then

%%% `asserts.isTrue(x)` keeps the qualified-call style.

%%% 

%%% `==` is the language's rule: structural for primitives, reference for

%%% arrays and records on commonJS (`===`) and structural on erlang (`=:=`).

%%% `equals` on two arrays therefore passes on erlang and fails on commonJS;

%%% `deepEquals` is the cross-target answer (both sides are rendered by the

%%% same host, so key order agrees).

%% import failure, Failure

% ── boolean ──────────────────────────────────────────────────────────────────

% Fails when `condition` is false.

isTrue(Condition) ->
    case (Condition =:= false) of
        true ->
            {error, <<"asserts.isTrue: condition was false">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `condition` is true — the dual of `isTrue`, for "this must not

% happen" branches you would otherwise spell as `isTrue(!cond)`.

isFalse(Condition) ->
    case Condition of
        true ->
            {error, <<"asserts.isFalse: condition was true">>};
        _ ->
            {ok, undefined}
    end.

% ── equality ─────────────────────────────────────────────────────────────────

% Fails when `actual != expected` (the language's `==`; see the docblock).

equals(Actual, Expected) ->
    case (Actual =/= Expected) of
        true ->
            {error, <<"asserts.equals: values differ">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `actual == expected`.

notEquals(Actual, Expected) ->
    case (Actual =:= Expected) of
        true ->
            {error, <<"asserts.notEquals: values match">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `|actual - expected| > tolerance`. Pick a tolerance that fits the

% operation's numerical budget, not `0.0`. The absolute value is an inline

% `if` rather than `math.abs` — a std module does not import another.

approxEquals(Actual, Expected, Tolerance) ->
    Diff = (Actual - Expected),
    AbsDiff = case (Diff >= 0.0) of
        true ->
            Diff;
        false ->
            (0.0 - Diff)
    end,
    case (AbsDiff > Tolerance) of
        true ->
            {error, <<"asserts.approxEquals: values differ by more than tolerance">>};
        _ ->
            {ok, undefined}
    end.

% Private: a value rendered canonically by the host — `JSON.stringify` on

% Node, `io_lib:format("~0tp")` on Erlang. Lifted from the old onze's

% `onzeKey`, where it keyed the call log for the same reason: two values that

% render the same are structurally equal on that host.

%% external fn canonical -> erlang template

% Fails when the two values differ structurally — arrays and records by

% content, on every target. Needs Node or Erlang at run time (`canonical`).

deepEquals(Actual, Expected) ->
    case (iolist_to_binary(io_lib:format("~0tp", [Actual])) =/= iolist_to_binary(io_lib:format("~0tp", [Expected]))) of
        true ->
            {error, <<"asserts.deepEquals: values differ structurally">>};
        _ ->
            {ok, undefined}
    end.

% ── nil ──────────────────────────────────────────────────────────────────────

% Fails when the optional holds a value. `!= null`, never truthiness — on

% commonJS `if (x)` is false for `0`.

isNil(Value) ->
    case (Value =/= undefined) of
        true ->
            {error, <<"asserts.isNil: value was present">>};
        _ ->
            {ok, undefined}
    end.

% Fails when the optional is absent.

isNotNil(Value) ->
    case (Value =:= undefined) of
        true ->
            {error, <<"asserts.isNotNil: value was null">>};
        _ ->
            {ok, undefined}
    end.

% ── result ───────────────────────────────────────────────────────────────────

% Fails when `result` is `Error`. Read the payload at the call site with the

% builtin methods (`try equals(r.unwrapOr(0), 42);`).

isOk(Result) ->
    case (fun(__BpR) -> case __BpR of {error, _} -> true; _ -> false end end)(Result) of
        true ->
            {error, <<"asserts.isOk: result was Error">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `result` is `Ok`. To assert that a `Result`-returning body

% fails, this is the tool — `throws` is for a `panic` or a host throw.

isError(Result) ->
    case (fun(__BpR) -> case __BpR of {ok, _} -> true; _ -> false end end)(Result) of
        true ->
            {error, <<"asserts.isError: result was Ok">>};
        _ ->
            {ok, undefined}
    end.

% ── string ───────────────────────────────────────────────────────────────────

% Fails when `needle` is not a substring of `actual`.

contains(Actual, Needle) ->
    case ((string:find(Actual, Needle) =/= nomatch) =:= false) of
        true ->
            {error, <<"asserts.contains: needle not in actual">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `needle` is a substring of `actual`.

notContains(Actual, Needle) ->
    case (string:find(Actual, Needle) =/= nomatch) of
        true ->
            {error, <<"asserts.notContains: needle found in actual">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `actual` does not start with `prefix`.

startsWith(Actual, Prefix) ->
    case ((string:prefix(Actual, Prefix) =/= nomatch) =:= false) of
        true ->
            {error, <<"asserts.startsWith: prefix does not match">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `actual` does not end with `suffix`.

endsWith(Actual, Suffix) ->
    case ((fun(__S, __X) -> __N = byte_size(__S), __M = byte_size(__X), (__M =< __N) andalso (binary:part(__S, __N - __M, __M) =:= __X) end)(Actual, Suffix) =:= false) of
        true ->
            {error, <<"asserts.endsWith: suffix does not match">>};
        _ ->
            {ok, undefined}
    end.

% Private `regex.matches` twin, actual-first: inlined here rather than via a

% cross-module call so this file stays self-contained (std-internal modules

% do not import each other). PCRE-ish on both hosts.

%% external fn regexMatches -> erlang template

% Fails when the regular expression `pattern` (the host's native flavour)

% does not match `actual`. Use `contains` for a literal needle. Needs Node or

% Erlang at run time (`regexMatches`).

matches(Actual, Pattern) ->
    case ((re:run(Actual, Pattern) =/= nomatch) =:= false) of
        true ->
            {error, <<"asserts.matches: pattern did not match">>};
        _ ->
            {ok, undefined}
    end.

% ── collection ───────────────────────────────────────────────────────────────

% Fails when the array has elements.

isEmpty(Actual) ->
    case (erlang:length(Actual) =/= 0) of
        true ->
            {error, <<"asserts.isEmpty: array was not empty">>};
        _ ->
            {ok, undefined}
    end.

% Fails when the array is empty.

isNotEmpty(Actual) ->
    case (erlang:length(Actual) =:= 0) of
        true ->
            {error, <<"asserts.isNotEmpty: array was empty">>};
        _ ->
            {ok, undefined}
    end.

% Fails when the array's length is not `expected`.

lengthIs(Actual, Expected) ->
    case (erlang:length(Actual) =/= Expected) of
        true ->
            {error, <<"asserts.lengthIs: length differs">>};
        _ ->
            {ok, undefined}
    end.

% Fails when no element `==` `element` (`Array.indexOf` — reference equality

% for records on commonJS; extract with `.at(i)` and `deepEquals` instead).

includes(Actual, Element) ->
    case ((fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Actual, Element) < 0) of
        true ->
            {error, <<"asserts.includes: element not found">>};
        _ ->
            {ok, undefined}
    end.

% Fails when some element `==` `element`.

notIncludes(Actual, Element) ->
    case ((fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Actual, Element) >= 0) of
        true ->
            {error, <<"asserts.notIncludes: element found">>};
        _ ->
            {ok, undefined}
    end.

% ── numeric ──────────────────────────────────────────────────────────────────

% Fails when `actual` is outside `[low, high]` (both ends included). `i32`

% only: a generic `T` cannot be compared with `<`, and `f64` callers have

% `approxEquals`. `positive`/`negative` are `greaterThan(x, 0)`/`lessThan(x, 0)`.

between(Actual, Low, High) ->
    % Bound first: an `if (a < b || c > d)` condition does not parse today
    % (the condition grammar stops at `||`; a `val` initialiser takes the
    % whole expression) — a parser gap, recorded by the front that owns it.
    Outside = ((Actual < Low) orelse (Actual > High)),
    case Outside of
        true ->
            {error, <<"asserts.between: value out of range">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `actual <= bound`.

greaterThan(Actual, Bound) ->
    case (Actual =< Bound) of
        true ->
            {error, <<"asserts.greaterThan: value not greater">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `actual >= bound`.

lessThan(Actual, Bound) ->
    case (Actual >= Bound) of
        true ->
            {error, <<"asserts.lessThan: value not less">>};
        _ ->
            {ok, undefined}
    end.

% ── exceptions ───────────────────────────────────────────────────────────────

% Private: the message `failure.attempt` caught, or `""` for a body that

% completed.

caughtMessage(R) ->
    Text = case R of
        {ok, V} ->
            <<"">>;
        {error, F} ->
            erlang:element(2, F)
    end,
    Text.

% Fails when `body` completes normally — for a `panic` or a host raise from

% code whose return carries no `Result` (a failing `Result` is `isError`).

% Generic over the body's own type and run under `failure.attempt` (decisions

% 431, 493), so it needs Node or Erlang at run time.

throws(Body) ->
    R = std@failure:attempt(Body),
    case (fun(__BpR) -> case __BpR of {ok, _} -> true; _ -> false end end)(R) of
        true ->
            {error, <<"asserts.throws: body did not raise">>};
        _ ->
            {ok, undefined}
    end.

% Fails when `body` completes normally, or when the caught message does not

% contain `needle`. The message is `failure.attempt`'s `Failure.message`: a

% `panic(text)` / `@todo(text)` is its own `text` on every target, byte for

% byte — a needle with a `"`, a `\` or a non-ASCII character matches alike;

% any other host raise is its JS `message` (else `String(e)`) on Node and

% the reason by `~tp` on Erlang (`badarg`).

throwsWith(Body, Needle) ->
    R = std@failure:attempt(Body),
    case (fun(__BpR) -> case __BpR of {ok, _} -> true; _ -> false end end)(R) of
        true ->
            {error, <<"asserts.throwsWith: body did not raise">>};
        _ ->
            case ((string:find(caughtMessage(R), Needle) =/= nomatch) =:= false) of
                true ->
                    {error, <<"asserts.throwsWith: message does not contain needle">>};
                _ ->
                    {ok, undefined}
            end
    end.

% ── utility ──────────────────────────────────────────────────────────────────

% Always `Error("asserts.fail: <message>")` — the one function whose message

% carries caller text; the escape for a branch the test asserts is unreachable.

fail(Message) ->
    {error, <<"asserts.fail: ", Message/binary>>}.

% The `Error` payload of an assertion's result, or `""` for `Ok`. Not

% a `-> Result` fn: it is how a test reads a failure message to compare or

% snapshot it (`test-snap.md`), matching over the builtin `Result` enum in a

% function the manual-construction rule does not apply to.

errorText(R) ->
    Text = case R of
        {ok, V} ->
            <<"">>;
        {error, E} ->
            E
    end,
    Text.

% ── tests ────────────────────────────────────────────────────────────────────

% One test per function per path, written with `try`; a fail path asserts

% `isError` over the assertion's own result and pins the literal message

% through `errorText` (no host cell, no panic).

parsePort(S) ->
    case (S =:= <<"">>) of
        true ->
            {error, <<"empty input">>};
        _ ->
            {ok, 8080}
    end.

explode() ->
    erlang:error({panic, <<"boom: the widget is on fire">>}),
    0.

% boolean





% equality









% nil




% result





% string








% collection








% numeric






% exceptions




quoteRaiser() ->
    erlang:error({panic, <<"withHeader(\"Set-Cookie\", v) \\ twice">>}),
    0.




% utility



'__bp_priv__caughtMessage'(A0) -> caughtMessage(A0).

'__bp_priv__parsePort'(A0) -> parsePort(A0).

'__bp_priv__explode'() -> explode().

'__bp_priv__quoteRaiser'() -> quoteRaiser().
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

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__at'/2, '__bp_priv__lastAt'/2, '__bp_priv__holds'/2]).

%% behavior array

array_range(Start, Stop) ->
    case ((Stop - Start) =< 0) of
        true ->
            [];
        false ->
            case ((Stop - Start) =:= 1) of
                true ->
                    [Start];
                false ->
                    Count = (Stop - Start),
                    Low = array_range(Start, (Start + (Count div 2))),
                    High = array_range((Start + (Count div 2)), Stop),
                    '__bp_prim_append'(Low, High)
            end
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Half = array_repeat(Value, (Times div 2)),
            case ((Times rem 2) =:= 0) of
                true ->
                    '__bp_prim_append'(Half, Half);
                false ->
                    '__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])
            end
    end.

at(Xs, X) ->
    (fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(Xs, X).

lastAt(Xs, X) ->
    (fun(__L, __X) -> __Find = fun __F(__I, [__H | __T], __Last) -> __F(__I + 1, __T, case (__H =:= __X) of true -> __I; false -> __Last end); __F(_, [], __Last) -> __Last end, __Find(0, __L, -1) end)(Xs, X).

holds(Xs, X) ->
    lists:member(X, Xs).

main() ->
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, _} -> true; _ -> false end end)(std@testing@asserts:includes([1, 2], 2))]),
    '__bp_print'([(fun(__BpR) -> case __BpR of {ok, _} -> true; _ -> false end end)(std@testing@asserts:includes([1, 2], 3))]),
    '__bp_print'([at([2.5, 3.5], 3.5)]),
    '__bp_print'([at([<<"a">>, <<"b">>], <<"b">>)]),
    '__bp_print'([lastAt([1, 2, 1], 1)]),
    '__bp_print'([lastAt([true, false], true)]),
    '__bp_print'([holds([<<"x">>], <<"y">>)]).

%% import asserts

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) when erlang:is_function(V) -> ["fn/", erlang:integer_to_list(erlang:element(2, erlang:fun_info(V, arity)))];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    '__bp_load_siblings'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_load_siblings'() ->
    case code:which(?MODULE) of
        Path when erlang:is_list(Path) ->
            lists:foreach(fun(Src) ->
                case code:ensure_loaded(erlang:list_to_atom(filename:basename(Src, ".erl"))) of
                    {module, _} -> ok;
                    _ ->
                        case compile:file(Src, [binary, return_errors]) of
                            {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
                            Bad ->
                                io:format(standard_error, "error: ~ts does not compile - refusing to run~n  ~p~n", [Src, Bad]),
                                erlang:halt(1)
                        end
                end
            end, filelib:wildcard(filename:join(filename:dirname(Path), "*.erl")));
        _ -> ok
    end.

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__at'(A0, A1) -> at(A0, A1).

'__bp_priv__lastAt'(A0, A1) -> lastAt(A0, A1).

'__bp_priv__holds'(A0, A1) -> holds(A0, A1).
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
