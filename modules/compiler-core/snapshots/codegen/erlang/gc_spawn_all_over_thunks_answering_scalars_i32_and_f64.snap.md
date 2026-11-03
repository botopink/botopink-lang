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

----- ERLANG -- std/async.erl
```erlang
-module(std@async).
-export([failed/1, newGate/0, openGate/1, awaitGate/2, errorText/1, allOf/1, all/1, runAll/1, timeout/2, nextDelay/2, retry/2, delay/2, race/1, raceOf/1, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__answered'/1, '__bp_priv__expireAfter'/2, '__bp_priv__policyProblem'/1, '__bp_priv__grown'/4, '__bp_priv__retryFrom'/3, '__bp_priv__gateBudget'/0, '__bp_priv__gated'/2, '__bp_priv__handshake'/3, '__bp_priv__answerNow'/1, '__bp_priv__slowOk'/2, '__bp_priv__errorProbe'/0, '__bp_priv__ghost'/2, '__bp_priv__panicOf'/1, '__bp_priv__flaky'/2, '__bp_priv__pauseText'/2, '__bp_priv__pauses'/2]).

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

%% behavior Integer

%%% std/async — combinators over `Async<T>` (decisions 120 and 121 of

%%% 1.0.10-beta, front 24 step E7).

%%% 

%%% An operation that can go wrong answers `Async<Result<T, E>>` — the task

%%% that fails with `E` (decision 432): on commonJS its Promise rejects with

%%% `E`, and `await` reads the rejection back as `Error(e)`. The combinators

%%% here read that `Result`: a host cell that awaits the tasks itself

%%% (`runAll`, `raceOf`, `race`) reads a failing task's rejection as the

%%% `{ error }` value `await` would answer, so nothing here hides a failure

%%% by swallowing one, and a crash stays a crash.

%%% 

%%% THE ERLANG DIVERGENCE, AT THE TOP RATHER THAN IN A FOOTNOTE.

%%% `Async<T>` lowers EAGERLY on the erlang backend: a `-> Async` fn is a plain

%%% function, `await` is identity, and a Async is therefore a value that has

%%% already run (`codegen/erlang.zig` — the `Async — eager lowering` arm;

%%% `libs/std/src/http.bp` says the same for `http.fetch`). By the time an

%%% `Array<Async<T>>` reaches a combinator on erlang, every element has already

%%% finished, in list order, serially.

%%% 

%%% So this module has TWO surfaces and they do not make the same promise.

%%% 

%%%   STARTED TASKS — `allOf`, `all`, `race`.

%%%   Take `Array<Async<…>>`, the shape the guide writes

%%%   (`async.allOf([fetchUser(1), fetchUser(2)])`). Concurrent on commonJS,

%%%   where each Async is a live Promise. On erlang it is honest rather than

%%%   concurrent: the Tasks resolved before the call, so `allOf` / `all` read

%%%   values in order and `race` answers ELEMENT ZERO rather than the fastest.

%%%   Both behaviours are asserted by the tests at the foot of this file, so a

%%%   backend change that makes erlang lazy reds a test and forces this

%%%   docblock to be rewritten instead of silently making it a lie.

%%% 

%%%   UNSTARTED TASKS — `runAll`, `raceOf`, `timeout`, `retry`.

%%%   Take `fn() -> Async<T>` thunks. Because nothing has run when the

%%%   combinator receives them, the erlang cell can `spawn` one process per

%%%   task and gather the replies by index, and the commonJS cell can call each

%%%   thunk into `Promise.all`. Real concurrency on BOTH targets. This is the

%%%   surface a server front uses.

%%% 

%%% `allOf` stops at the FIRST error in input order (front 24 README, E7) — the

%%% `E` is the tasks' own type, so there is no message to join; `runAll` over

%%% `Async<Result<…>>` thunks answers every `Result` when the caller wants

%%% them all. `allSettled` and `settleOf` left with the rejection they settled:

%%% a Async has no failure to settle, and a `Result` element IS the settled

%%% outcome (`specs/1.0.10-beta/decisions-pending.md` 24-g).

%%% 

%%% NO CANCELLATION. `raceOf`'s losers and `timeout`'s expired task keep

%%% running to completion; there is no cancellation surface in the language.

%%% 

%%% Reference:

%%%   Promise.all       — https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all

%%%   Erlang processes  — https://www.erlang.org/doc/system/ref_man_processes.html

%% import failure

% ── instruments ──────────────────────────────────────────────────────────────

% Which backend is running. The future surface's erlang behaviour differs from

% its commonJS behaviour by design, and a test that asserts one of the two has

% to know which it is looking at. Private: the divergence is this module's to

% document, not a consumer's to branch on.

%% external fn hostTarget -> erlang template

% The host's monotonic clock in milliseconds. `std/io/clock` has the same cell,

% and this root module may not import from `io/` (decision 106), so this file

% carries its own. Private — `clock.monotonicMillis()` is the public spelling.

%% external fn monoMillis -> erlang template

% Answer `value` after at least `millis` milliseconds of the host's monotonic

% clock — the promise `monoMillis()` measures it by.

% Node: `setTimeout` alone does not keep that promise. A timer starts from

% libuv's CACHED loop time (whole milliseconds, read when the loop last woke),

% so a timer armed after a long synchronous stretch — a loaded machine, a busy

% test runner — fires early by that stretch. The cell reads `performance.now()`

% when it is called and re-arms for whatever is left, so it never answers

% early. The first wait is always a timer, so `delay(0, v)` still yields to the

% timers phase rather than answering in the same microtask queue.

% Erlang: `timer:sleep/1` never wakes early.

%% external fn delay -> erlang template
delay(Millis, Value) ->
    (fun(__M, __V) -> timer:sleep(__M), __V end)(Millis, Value).

% A Async whose value is `Error(message)` — the failing instrument `allOf` and

% `timeout` are tested with. On commonJS it rejects with `message` (decision

% 432); `await` reads it as `Error(message)`.

%% @Async — eager lowering
failed(Message) ->
    {error, Message}.

% ── gates ────────────────────────────────────────────────────────────────────

% A one-shot signal between tasks: closed until `openGate`, open for good

% after. The instrument a test orders tasks with WITHOUT a clock — "task B

% answers only after task A has run" is a gate A opens and B awaits, where a

% pair of `delay`s only says "probably, unless the machine is busy".

% Node: an object holding the waiters' resolvers.

% Erlang: a process that queues `{bp_gate_wait, Pid, Ref}` requests until it

% receives `bp_gate_open`, then answers each and every later one at once —

% a pid, so the gate crosses into a spawned task like any value. It is never

% stopped: it is parked in `receive` and dies with the node.

%% type Gate: handle

%% external fn gateHandle -> erlang template

%% external fn gateOpen -> erlang template

%% external fn gateAwait -> erlang template

% A new, closed gate.

newGate() ->
    {std@async@@Gate, erlang:spawn(fun() -> (fun BpGateClosed(__W) -> receive {bp_gate_wait, __P, __R} -> BpGateClosed([{__P, __R} | __W]); bp_gate_open -> lists:foreach(fun({__P2, __R2}) -> __P2 ! {__R2, bp_gate_open} end, __W), (fun BpGateOpen() -> receive {bp_gate_wait, __P3, __R3} -> __P3 ! {__R3, bp_gate_open}, BpGateOpen(); bp_gate_open -> BpGateOpen() end end)() end end)([]) end)}.

% Open `gate`: every task awaiting it answers, and so does every later

% `awaitGate`. Opening an open gate changes nothing.

openGate(Gate) ->
    (fun(__G) -> __G ! bp_gate_open, undefined end)(erlang:element(2, Gate)).

% `true` once `gate` is open, `false` when `millis` pass first. The budget is

% not the ordering — the gate is; it only turns a gate nobody opens into a red

% assertion instead of a hang, so a test gives it a margin no scheduling delay

% can cross (seconds) and opens every gate it closes. An open gate answers at

% once and leaves no timer behind.

%% @Async — eager lowering
awaitGate(Gate, Millis) ->
    (fun(__G, __Ms) -> BpGateRef = erlang:make_ref(), __G ! {bp_gate_wait, self(), BpGateRef}, receive {BpGateRef, bp_gate_open} -> true after __Ms -> false end end)(erlang:element(2, Gate), Millis).

% ── reading a settled element ────────────────────────────────────────────────

% The `Error` payload of a `Result<T, string>`, or `""` for `Ok`. `Result`

% carries `isOk`/`isError`/`unwrapOr` as builtins but no way to read the error

% side, so without this a caller can see THAT a widget failed and never WHY —

% the shape decision 67 refuses.

errorText(Settled) ->
    Text = case Settled of
        {ok, _v} ->
            <<"">>;
        {error, E} ->
            E
    end,
    Text.

% ── started tasks ────────────────────────────────────────────────────────────

% The values of every Async, in input order, or the FIRST `Error` in input

% order. The tasks were started by the caller (`allOf([fetchUser(1),

% fetchUser(2)])`), so on commonJS they run concurrently and this only waits;

% on erlang they already ran. `allOf([])` answers `Ok([])`.

%% @Async — eager lowering
allOf(Tasks) ->
    try
        Out = [],
        Out@3 = lists:foldl(fun(T, Out@1) ->
            V = case T of
                {ok, _TryV0} -> _TryV0;
                {error, _TryE0} -> erlang:throw({'__bp_try', {error, _TryE0}})
            end,
            Out@2 = (Out@1 ++ [V]),
            Out@2
        end, Out, Tasks),
        {ok, Out@3}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% The values of every Async, in input order — the infallible `allOf`.

%% @Async — eager lowering
all(Tasks) ->
    Out = [],
    Out@3 = lists:foldl(fun(T, Out@1) ->
        V = T,
        Out@2 = (Out@1 ++ [V]),
        Out@2
    end, Out, Tasks),
    Out@3.

% commonJS: the FASTEST Async to answer, `Promise.race`.

% ERLANG: ELEMENT ZERO. Every Async resolved before the call, so there is no

% timing left to measure and this answers the first element of the list. That

% is not a bug to be fixed here and no server front may depend on it — use

% `raceOf`, whose tasks are unstarted when it receives them. Both behaviours

% are pinned by `async: race ---- commonJS fastest, erlang element zero`.

% 

% `race([])` is a programming error, fatal on both targets

% (`async.race: empty task list`).

%% external fn race -> erlang template
race(Tasks) ->
    (fun(__Fs) -> case __Fs of [] -> erlang:error(<<"async.race: empty task list">>); _ -> hd(__Fs) end end)(Tasks).

% ── unstarted tasks ──────────────────────────────────────────────────────────

% Run every task concurrently and answer their values in the ORDER OF THE

% INPUT rather than the order they finished. A task over a `Result` answers

% its `Result` in its slot, so `runAll` of fallible tasks is the settled

% view: nothing is hidden and nothing stops early.

% 

% Node: each thunk is called and the Promises go to `Promise.all`, a failing

% task (decision 432) read as the `{ ok }` / `{ error }` value `await` reads.

% Erlang: `spawn` one process per task, each tagged `{Ref, I, Outcome}` with a

% `make_ref()` unique to THIS call — without the ref a later combinator in the

% same process would receive a loser's leftover reply — and gather by index, so

% a task that finishes first does not take another task's slot. A task that

% crashes is a crash (a crash is a bug, never a failure), re-raised here

% rather than left to block the gather.

%% external fn spawnAll -> erlang template

% The public face of the cell above: a real function, so a module compiled

% separately (the BEAM backend links modules by name) can call it — a

% template-only `declare fn` has no body to export.

%% @Async — eager lowering
runAll(Tasks) ->
    (fun(__Ts) -> __Me = self(), BpRef = erlang:make_ref(), lists:foreach(fun(__I) -> erlang:spawn(fun() -> __Me ! {BpRef, __I, try {ok, (lists:nth(__I, __Ts))()} catch __C:__E -> {crash, __C, __E} end} end) end, lists:seq(1, length(__Ts))), [case (receive {BpRef, BpJ, __X} -> __X end) of {ok, __V} -> __V; {crash, __C2, __E2} -> erlang:raise(__C2, __E2, []) end || BpJ <- lists:seq(1, length(__Ts))] end)(Tasks).

% The first task to ANSWER, not the first in the list. The LOSERS keep

% running and their values are discarded: there is no cancellation surface in

% botopink, and a race that reported the loser would not be a race.

% 

% `raceOf([])` is a programming error, fatal on both targets

% (`async.raceOf: empty task list`), rather than blocking forever.

%% external fn raceOf -> erlang template
raceOf(Tasks) ->
    (fun(__Ts) -> case __Ts of [] -> erlang:error(<<"async.raceOf: empty task list">>); _ -> __Me = self(), BpRef = erlang:make_ref(), lists:foreach(fun(__I) -> erlang:spawn(fun() -> __Me ! {BpRef, try {ok, (lists:nth(__I, __Ts))()} catch __C:__E -> {error, __C, __E} end} end) end, lists:seq(1, length(__Ts))), case (receive {BpRef, __W} -> __W end) of {ok, __V} -> __V; {error, __C2, __E2} -> erlang:raise(__C2, __E2, []) end end end)(Tasks).

% `task`'s value as `Ok` — the racer `timeout` puts beside the clock.

%% @Async — eager lowering
answered(Task) ->
    {ok, Task()}.

% `Error("timeout")` after `millis` — the clock `timeout` races against

% `task`, whose type it answers in (decision 668: `task` binds `T`).

%% @Async — eager lowering
expireAfter(Task, Millis) ->
    (fun(__M, __V) -> timer:sleep(__M), __V end)(Millis, 0),
    {error, <<"timeout">>}.

% `Ok(value)` when the task answered inside the budget, `Error("timeout")`

% when it did not. A task over a `Result` keeps its own failure INSIDE the

% `Ok` (`Ok(Error(e))`): the budget and the task's outcome are two answers,

% and neither hides the other. The task KEEPS RUNNING; the caller stops

% waiting. Expressed over `raceOf` + `delay`.

%% @Async — eager lowering
timeout(Task, Millis) ->
    (fun(__Ts) -> case __Ts of [] -> erlang:error(<<"async.raceOf: empty task list">>); _ -> __Me = self(), BpRef = erlang:make_ref(), lists:foreach(fun(__I) -> erlang:spawn(fun() -> __Me ! {BpRef, try {ok, (lists:nth(__I, __Ts))()} catch __C:__E -> {error, __C, __E} end} end) end, lists:seq(1, length(__Ts))), case (receive {BpRef, __W} -> __W end) of {ok, __V} -> __V; {error, __C2, __E2} -> erlang:raise(__C2, __E2, []) end end end)([fun() ->
        answered(Task)
    end, fun() ->
        expireAfter(Task, Millis)
    end]).

% ── retry (1.0.11-beta front 97) ─────────────────────────────────────────────

% How a fallible task is tried again: at most `maxAttempts` attempts, a pause

% of `initialMillis` after the first failure, each later pause `multiplier`

% times the one before, none above `maxMillis`. There is no jitter and no

% field that means "for ever" (decision 67): a policy is usable only when

% `maxAttempts` is at least 1, the two delays are not negative, `maxMillis`

% is at most 2147483647 (the longest timer both targets arm) and `multiplier`

% is at least 1.0 — a backoff never shrinks, and one that could would retry

% in a near-zero-delay loop.

%% type RetryPolicy: maxAttempts, initialMillis, multiplier, maxMillis

% Internal: why `policy` is not usable, `""` when it is.

policyProblem(Policy) ->
    case (erlang:element(2, Policy) < 1) of
        true ->
            <<"maxAttempts must be at least 1 (the first attempt)">>;
        _ ->
            case (erlang:element(3, Policy) < 0) of
                true ->
                    <<"initialMillis must not be negative">>;
                _ ->
                    case (erlang:element(5, Policy) < 0) of
                        true ->
                            <<"maxMillis must not be negative">>;
                        _ ->
                            case (erlang:element(5, Policy) > 2147483647) of
                                true ->
                                    <<"maxMillis must be at most 2147483647">>;
                                _ ->
                                    Grows = (erlang:element(4, Policy) >= 1.0),
                                    case (Grows =:= false) of
                                        true ->
                                            <<"multiplier must be at least 1.0 (a backoff never shrinks)">>;
                                        _ ->
                                            <<"">>
                                    end
                            end
                    end
            end
    end.

% Internal: an `i64` of milliseconds as an `f64`, and back — the whole

% milliseconds of a delay that is never negative. Not `toF64()`, which aborts

% on an integer past 2^53 that no `f64` holds: the delay is a float

% computation, and an `initialMillis` that large rounds as the float does

% (and is then capped by `maxMillis`). The Node forms take and answer

% decision 319's canonical form — `Number` reads a `BigInt` (`initialMillis`

% past 2^53 − 1), and a whole number past 2^53 − 1 answers as a `BigInt`.

%% external fn millisAsFloat -> erlang template

%% external fn wholeMillis -> erlang template

% Internal: `initial × multiplier^(attempt − 1)`, never above `ceiling`. One

% multiplication per attempt — the same IEEE operations in the same order on

% both targets, where a host `pow` would not promise the same last bit — and

% none once the ceiling is reached, so it cannot overflow.

grown(Initial, Multiplier, Ceiling, Attempt) ->
    Steady = ((Multiplier =< 1.0) orelse (Initial =< 0.0)),
    case Steady of
        true ->
            case (Initial > Ceiling) of
                true ->
                    Ceiling;
                false ->
                    Initial
            end;
        _ ->
            Pause = Initial,
            Step = 1,
            {Pause@3, Step@3} = (fun __BpLoop({Pause@1, Step@1}) ->
                case ((Step@1 < Attempt) andalso (Pause@1 < Ceiling)) of
                    true ->
                        Pause@2 = (Pause@1 * Multiplier),
                        Step@2 = '__bp_int'((Step@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/async.bp:335:21">>),
                        __BpLoop({Pause@2, Step@2});
                    _ -> {Pause@1, Step@1}
                end
            end)({Pause, Step}),
            case (Pause@3 > Ceiling) of
                true ->
                    Ceiling;
                false ->
                    Pause@3
            end
    end.

% The pause that follows attempt `attempt` (the first attempt is 1), in whole

% milliseconds: `initialMillis × multiplier^(attempt − 1)`, rounded down and

% never above `maxMillis`. `null` once `attempt` is past `maxAttempts` — there

% is no further attempt to wait for — and for an attempt below 1 or a policy

% that is not usable.

nextDelay(Policy, Attempt) ->
    Usable = (policyProblem(Policy) =:= <<"">>),
    Inside = ((Attempt >= 1) andalso (Attempt =< erlang:element(2, Policy))),
    Answers = (Usable andalso Inside),
    case (Answers =:= false) of
        true ->
            undefined;
        _ ->
            trunc(grown(float(erlang:element(3, Policy)), erlang:element(4, Policy), float(erlang:element(5, Policy)), Attempt))
    end.

% Internal: attempt number `attempt` of `retry`, and every one after it.

%% @Async — eager lowering
retryFrom(Policy, Work, Attempt) ->
    Outcome = Work(),
    Settled = ((fun(__BpR) -> case __BpR of {ok, _} -> true; _ -> false end end)(Outcome) orelse (Attempt >= erlang:element(2, Policy))),
    case Settled of
        true ->
            Outcome;
        _ ->
            Pause = case nextDelay(Policy, Attempt) of
                undefined ->
                    erlang:element(5, Policy);
                __bp_nullish ->
                    __bp_nullish
            end,
            (fun(__M, __V) -> timer:sleep(__M), __V end)((fun(__V) when __V >= -2147483648, __V =< 2147483647 -> __V; (__V) -> erlang:error({integer_overflow, <<"toI32: ", (integer_to_binary(__V))/binary, " does not fit i32">>}) end)(Pause), 0),
            retryFrom(Policy, Work, '__bp_int'((Attempt + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/async.bp:371:54">>))
    end.

% Run `work` until it answers `Ok`, at most `policy.maxAttempts` times, pausing

% `nextDelay(policy, n)` after failed attempt `n`. `Ok` is answered as soon as

% an attempt succeeds; when every attempt fails, the LAST `Error` is answered —

% the task fails with it, in `timeout`'s shape. `work` is a thunk because

% each attempt has to start the task again; a plain `Async<T>` never fails

% (decisions 120, 432), so there is nothing to retry over one.

% 

% A policy that is not usable is a programming error, fatal on both targets

% (`async.retry: maxAttempts must be at least 1 (the first attempt)`), like

% `race([])` — not an `Error` a caller could mistake for the work's own.

%% @Async — eager lowering
retry(Policy, Work) ->
    Problem = policyProblem(Policy),
    case (Problem =/= <<"">>) of
        true ->
            erlang:error({panic, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<"async.retry: ">>, Problem])))});
        _ -> ok
    end,
    retryFrom(Policy, Work, 1).

% ── tests ────────────────────────────────────────────────────────────────────

% Inline, the way every std module does it, run by `botopink test` and

% `botopink test --target erlang` from `libs/std/`. Every verdict here is the

% same on an idle machine and a loaded one. Three kinds of assertion:

%   · results and order — deterministic on both targets;

%   · ORDER BY SIGNAL — "a concurrent combinator ran task B while task A was

%     still waiting", "the race was won by the task that answered" — told with

%     a gate one task opens and another awaits, never with a pair of `delay`s

%     and an elapsed-time budget: under load a 10 ms timer can fire after an

%     80 ms one on erlang, and a sequential map can still finish inside

%     "roughly double the longest task". A gate's budget (`gateBudget`) only

%     turns a gate nobody opens into a red assertion instead of a hang;

%   · a LOWER bound on elapsed time where the behaviour is a duration

%     (`delay`, `timeout`'s budget) — a promise the cells keep however busy the

%     machine is. There is no upper bound anywhere: an upper bound on elapsed

%     time measures the machine, not the code;

% plus DOCUMENTED DIVERGENCE (the started surface's erlang behaviour asserted

% as itself, so a backend change that makes erlang lazy reds a test instead of

% silently making the docblock a lie).

% 

% `async` is not snapshotted (`01-std/test-snap.md`).

%% type Probe: id, label

% How long a test task waits on a gate before it gives up. Every gate a test

% closes is opened again, so this passes only when the code under test is

% wrong — and then as a red assertion, not a hang.

gateBudget() ->
    10000.

% `value` once `gate` opens; a value naming the failure when it never does.

%% @Async — eager lowering
gated(Gate, Value) ->
    Opened = awaitGate(Gate, gateBudget()),
    case Opened of
        true ->
            Value;
        false ->
            <<"gate never opened: ", Value/binary>>
    end.

% Open `mine`, then answer `value` once `theirs` is open. Two of these over the

% same pair of gates, crossed, can only BOTH answer when they run at the same

% time: whichever runs first alone waits on a gate the other has not opened.

%% @Async — eager lowering
handshake(Mine, Theirs, Value) ->
    openGate(Mine),
    gated(Theirs, Value).

% `value` with no timer at all: resolved in the microtask queue on commonJS,

% the process's first reply on erlang.

%% @Async — eager lowering
answerNow(Value) ->
    Value.

% ── delay and failed ─────────────────────────────────────────────────────────





% ── gates ────────────────────────────────────────────────────────────────────



% ── allOf and all ────────────────────────────────────────────────────────────

%% @Async — eager lowering
slowOk(Millis, Value) ->
    {ok, (fun(__M, __V) -> timer:sleep(__M), __V end)(Millis, Value)}.






% ── runAll ───────────────────────────────────────────────────────────────────




% A settled element to stand in for the `?T` fallback of `.at(i)`. `Array.at`

% answers an optional and `unwrapOr` needs a value of the element type, which

% here is itself a `Result`; this is the cheapest way to spell one.

errorProbe() ->
    {error, <<"async: no element">>}.

% ── raceOf ───────────────────────────────────────────────────────────────────



% ── timeout ──────────────────────────────────────────────────────────────────




% The expired task of the test above: waits for `release`, opens `done` and

% answers.

%% @Async — eager lowering
ghost(Release, Done) ->
    V = gated(Release, <<"late">>),
    openGate(Done),
    V.

% ── retry ────────────────────────────────────────────────────────────────────

% Internal, test scaffolding: a counter the attempts of one `retry` share —

% a closure cannot count on erlang, where a `var` it captures is a copy.

% Node: an object. Erlang: a `counters` reference.

%% external fn newCounter -> erlang template

% Count one more and answer the count.

%% external fn countUp -> erlang template

%% external fn countOf -> erlang template

% The text a task panics with, `""` when it answered — a panic inside a

% `-> Async` function is a rejected Promise on commonJS and a raise on erlang.

%% @Async — eager lowering
panicOf(Body) ->
    R = std@failure:attemptTask(Body),
    case R of
        {ok, _} ->
            <<"">>;
        {error, F} ->
            '__bp_field'(F, message)
    end.

% Attempt `n` of a task that fails until its `succeedAt`-th call:

% `Error("failure <n>")` before it, `Ok("ok after <n>")` from it on. The test

% counts the call (`flaky(countUp(calls), …)`), so the counter's cells are

% reached from the tests alone, and a module importing `async` on a target

% with no counter (wasm) links no call of them.

%% @Async — eager lowering
flaky(N, SucceedAt) ->
    case (N < SucceedAt) of
        true ->
            {error, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<"failure ">>, erlang:integer_to_binary(N)])))};
        _ ->
            {ok, iolist_to_binary(lists:join(<<"">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, [<<"ok after ">>, erlang:integer_to_binary(N)])))}
    end.

% What `nextDelay(policy, attempt)` answers, as text: the milliseconds, or

% `none`.

pauseText(Policy, Attempt) ->
    Pause = nextDelay(Policy, Attempt),
    case (Pause =/= undefined) of
        true ->
            erlang:integer_to_binary(Pause);
        false ->
            <<"none">>
    end.

% `pauseText` for attempts 1 to `last`, joined by `,`.

pauses(Policy, Last) ->
    iolist_to_binary(lists:join(<<",">>, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, lists:map(fun(Attempt) ->
        pauseText(Policy, Attempt)
    end, array_range(1, '__bp_int'((Last + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/async.bp:727:24">>)))))).











'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__answered'(A0) -> answered(A0).

'__bp_priv__expireAfter'(A0, A1) -> expireAfter(A0, A1).

'__bp_priv__policyProblem'(A0) -> policyProblem(A0).

'__bp_priv__grown'(A0, A1, A2, A3) -> grown(A0, A1, A2, A3).

'__bp_priv__retryFrom'(A0, A1, A2) -> retryFrom(A0, A1, A2).

'__bp_priv__gateBudget'() -> gateBudget().

'__bp_priv__gated'(A0, A1) -> gated(A0, A1).

'__bp_priv__handshake'(A0, A1, A2) -> handshake(A0, A1, A2).

'__bp_priv__answerNow'(A0) -> answerNow(A0).

'__bp_priv__slowOk'(A0, A1) -> slowOk(A0, A1).

'__bp_priv__errorProbe'() -> errorProbe().

'__bp_priv__ghost'(A0, A1) -> ghost(A0, A1).

'__bp_priv__panicOf'(A0) -> panicOf(A0).

'__bp_priv__flaky'(A0, A1) -> flaky(A0, A1).

'__bp_priv__pauseText'(A0, A1) -> pauseText(A0, A1).

'__bp_priv__pauses'(A0, A1) -> pauses(A0, A1).
```

----- ERLANG -- std@async@@Gate.erl
```erlang
-module(std@async@@Gate).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, handle) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Gate", [{"handle", erlang:element(2, V)}]}.
```

----- ERLANG -- std@async@@RetryPolicy.erl
```erlang
-module(std@async@@RetryPolicy).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, maxAttempts) -> erlang:element(2, V);
'__bp_get'(V, initialMillis) -> erlang:element(3, V);
'__bp_get'(V, multiplier) -> erlang:element(4, V);
'__bp_get'(V, maxMillis) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "RetryPolicy", [{"maxAttempts", erlang:element(2, V)}, {"initialMillis", erlang:element(3, V)}, {"multiplier", erlang:element(4, V)}, {"maxMillis", erlang:element(5, V)}]}.
```

----- ERLANG -- std@async@@Probe.erl
```erlang
-module(std@async@@Probe).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, id) -> erlang:element(2, V);
'__bp_get'(V, label) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Probe", [{"id", erlang:element(2, V)}, {"label", erlang:element(3, V)}]}.
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

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__doubled'/1, '__bp_priv__doubledF'/1, '__bp_priv__run'/0]).

%% @Async — eager lowering
doubled(N) ->
    '__bp_int'((N * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:2:14">>).

%% @Async — eager lowering
doubledF(N) ->
    (N * 2.0).

%% @Async — eager lowering
run() ->
    Ints = std@async:runAll([fun() ->
        doubled(1)
    end, fun() ->
        doubled(2)
    end, fun() ->
        doubled(3)
    end]),
    '__bp_print'([Ints]),
    Floats = std@async:runAll([fun() ->
        doubledF(1.5)
    end, fun() ->
        doubledF(2.5)
    end]),
    '__bp_print'([Floats]).

main() ->
    run().

%% import async

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__doubled'(A0) -> doubled(A0).

'__bp_priv__doubledF'(A0) -> doubledF(A0).

'__bp_priv__run'() -> run().
```

----- RUN LOG -----
```logs
[2, 4, 6]
[3.0, 5.0]
```
