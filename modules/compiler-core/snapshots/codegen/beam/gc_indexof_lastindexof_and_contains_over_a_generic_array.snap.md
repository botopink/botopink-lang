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

----- BEAM ASSEMBLY -- std/failure.S
```erlang
{module, std@failure}.
{exports, [{panic, 1}, {attempt, 1}, {attemptTask, 1}, {'__bp_priv__attemptOnWasm', 1}, {'__bp_priv__attemptTaskOnWasm', 1}]}.
{attributes, []}.
{labels, 59}.
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
% Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
% with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
% Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
% inside std); `panic("not implemented")` is what `todo` was.

{function, panic, 1, 9}.
  {label, 8}.
    {line, [{location, "std@failure.erl", 1}]}.
    {func_info, {atom, std@failure}, {atom, panic}, 1}.
  {label, 9}.
    {call_only, 1, {f, 7}}.
% The Node forms read an abort by the `__bp_panic` mark the backend puts on
% every one it raises — `panic`, `@todo`, an integer overflow or division
% by zero, a failed `assert` (whose mark carries its message) — or a test
% body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
% backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
% M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
% (decision 432): marked `__bp_fails`, resolved with the value, rejected with
% the `Failure` (`__bp_failure`); a failing task `f` answers is read as
% `await` reads it.

{function, attempt, 1, 35}.
  {label, 34}.
    {line, [{location, "std@failure.erl", 2}]}.
    {func_info, {atom, std@failure}, {atom, attempt}, 1}.
  {label, 35}.
    {call_only, 1, {f, 11}}.

{function, attemptTask, 1, 37}.
  {label, 36}.
    {line, [{location, "std@failure.erl", 3}]}.
    {func_info, {atom, std@failure}, {atom, attemptTask}, 1}.
  {label, 37}.
    {call_only, 1, {f, 11}}.
% wasm's form (decision 518): the thunk's value, or the message of the abort
% it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
% The bodies over it are compiled on every target, so it has a form on each;
% only wasm calls it (`attempt`'s own forms answer elsewhere).

{function, attemptOnWasm, 1, 3}.
  {label, 2}.
    {line, [{location, "std@failure.erl", 4}]}.
    {func_info, {atom, std@failure}, {atom, attemptOnWasm}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 49}}.
  {label, 50}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {literal, <<"panic">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 49}}.
  {label, 51}.
    {case_end, {x, 0}}.
  {label, 49}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
% The task the thunk started — or the `Failure` it raised before its first
% `await` — and then its value.

%% @Async — eager lowering
{function, attemptTaskOnWasm, 1, 5}.
  {label, 4}.
    {line, [{location, "std@failure.erl", 5}]}.
    {func_info, {atom, std@failure}, {atom, attemptTaskOnWasm}, 1}.
  {label, 5}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_tagged_tuple, {f, 53}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 52}}.
  {label, 53}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {literal, <<"panic">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 52}}.
  {label, 54}.
    {case_end, {x, 0}}.
  {label, 52}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_priv__attemptOnWasm', 1, 56}.
  {label, 55}.
    {line, [{location, "std@failure.erl", 6}]}.
    {func_info, {atom, std@failure}, {atom, '__bp_priv__attemptOnWasm'}, 1}.
  {label, 56}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__attemptTaskOnWasm', 1, 58}.
  {label, 57}.
    {line, [{location, "std@failure.erl", 7}]}.
    {func_info, {atom, std@failure}, {atom, '__bp_priv__attemptTaskOnWasm'}, 1}.
  {label, 58}.
    {call_only, 1, {f, 5}}.

{function, '__bp_tpl_0', 1, 7}.
  {label, 6}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_0'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 15}.
  {label, 14}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 15}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 2}}.
    {'try', {y, 10}, {f, 18}}.
    {move, {y, 2}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {try_end, {y, 10}}.
    {jump, {f, 19}}.
  {label, 18}.
    {try_case, {y, 10}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 21}, [{x, 0}]}.
    {test, test_arity, {f, 21}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, panic}, {x, 1}}.
    {test, is_eq_exact, {f, 23}, [{x, 0}, {x, 1}]}.
    {jump, {f, 24}}.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, todo}, {x, 1}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {x, 1}]}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, integer_overflow}, {x, 1}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {x, 1}]}.
  {label, 26}.
  {label, 24}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 27}, [{x, 0}]}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {y, 1}, {x, 0}}.
    {test, is_list, {f, 21}, [{x, 0}]}.
  {label, 28}.
    {jump, {f, 22}}.
  {label, 22}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 9}, {literal, <<"panic">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 21}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 29}, [{x, 0}]}.
    {test, test_arity, {f, 29}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 3, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 9}, {literal, <<"panic">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 29}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {test, test_arity, {f, 30}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 30}, [{x, 0}]}.
    {jump, {f, 31}}.
  {label, 31}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 1}, {literal, <<"panic">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 30}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, error}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 32}, [{x, 0}]}.
    {test, test_arity, {f, 32}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, bp_host}]}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 32}, [{x, 0}]}.
    {jump, {f, 33}}.
  {label, 33}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 1}, {literal, <<"host">>}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 32}.
    {move, {y, 5}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@Failure}, {y, 7}, {literal, <<"crash">>}]}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 3}}.
    {jump, {f, 20}}.
  {label, 20}.
  {label, 19}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '__bp_tpl_1', 1, 11}.
  {label, 10}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_1'}, 1}.
  {label, 11}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 43}.
  {label, 42}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 43}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 7}, {f, 46}}.
    {move, {y, 1}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 2}}.
    {try_end, {y, 7}}.
    {jump, {f, 47}}.
  {label, 46}.
    {try_case, {y, 7}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 48}}.
  {label, 48}.
  {label, 47}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_2', 1, 39}.
  {label, 38}.
    {func_info, {atom, std@failure}, {atom, '__bp_tpl_2'}, 1}.
  {label, 39}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@failure@@HostErrorName.S
```erlang
{module, std@failure@@HostErrorName}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@failure@@HostErrorName.erl", 1}]}.
    {func_info, {atom, std@failure@@HostErrorName}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, std@failure@@HostErrorName__v__error}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName.Error">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, std@failure@@HostErrorName__v__throw}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName.Throw">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, std@failure@@HostErrorName__v__exit}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName.Exit">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"HostErrorName">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@failure@@HostError.S
```erlang
{module, std@failure@@HostError}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@failure@@HostError.erl", 1}]}.
    {func_info, {atom, std@failure@@HostError}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, message}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, kind}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, detail}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "std@failure@@HostError.erl", 1}]}.
    {func_info, {atom, std@failure@@HostError}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"detail">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"kind">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"message">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"HostError">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@failure@@Failure.S
```erlang
{module, std@failure@@Failure}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@failure@@Failure.erl", 1}]}.
    {func_info, {atom, std@failure@@Failure}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, message}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, kind}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "std@failure@@Failure.erl", 1}]}.
    {func_info, {atom, std@failure@@Failure}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"kind">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"message">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Failure">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
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

----- BEAM ASSEMBLY -- std/testing/asserts.S
```erlang
{module, std@testing@asserts}.
{exports, [{isTrue, 1}, {isFalse, 1}, {equals, 2}, {notEquals, 2}, {approxEquals, 3}, {deepEquals, 2}, {isNil, 1}, {isNotNil, 1}, {isOk, 1}, {isError, 1}, {contains, 2}, {notContains, 2}, {startsWith, 2}, {endsWith, 2}, {matches, 2}, {isEmpty, 1}, {isNotEmpty, 1}, {lengthIs, 2}, {includes, 2}, {notIncludes, 2}, {between, 3}, {greaterThan, 2}, {lessThan, 2}, {throws, 1}, {throwsWith, 2}, {fail, 1}, {errorText, 1}, {'__bp_priv__caughtMessage', 1}, {'__bp_priv__explode', 0}, {'__bp_priv__parsePort', 1}, {'__bp_priv__quoteRaiser', 0}]}.
{attributes, []}.
{labels, 187}.
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
% ── boolean ──────────────────────────────────────────────────────────────────
% Fails when `condition` is false.

{function, isTrue, 1, 3}.
  {label, 2}.
    {line, [{location, "std@testing@asserts.erl", 1}]}.
    {func_info, {atom, std@testing@asserts}, {atom, isTrue}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 64}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"asserts.isTrue: condition was false">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 64}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
% Fails when `condition` is true — the dual of `isTrue`, for "this must not
% happen" branches you would otherwise spell as `isTrue(!cond)`.

{function, isFalse, 1, 5}.
  {label, 4}.
    {line, [{location, "std@testing@asserts.erl", 2}]}.
    {func_info, {atom, std@testing@asserts}, {atom, isFalse}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 65}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"asserts.isFalse: condition was true">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 65}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
% ── equality ─────────────────────────────────────────────────────────────────
% Fails when `actual != expected` (the language's `==`; see the docblock).

{function, equals, 2, 7}.
  {label, 6}.
    {line, [{location, "std@testing@asserts.erl", 3}]}.
    {func_info, {atom, std@testing@asserts}, {atom, equals}, 2}.
  {label, 7}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 66}, [{y, 0}, {y, 1}]}.
    {move, {literal, <<"asserts.equals: values differ">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 66}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Fails when `actual == expected`.

{function, notEquals, 2, 9}.
  {label, 8}.
    {line, [{location, "std@testing@asserts.erl", 4}]}.
    {func_info, {atom, std@testing@asserts}, {atom, notEquals}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_eq_exact, {f, 67}, [{y, 0}, {y, 1}]}.
    {move, {literal, <<"asserts.notEquals: values match">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 67}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Fails when `|actual - expected| > tolerance`. Pick a tolerance that fits the
% operation's numerical budget, not `0.0`. The absolute value is an inline
% `if` rather than `math.abs` — a std module does not import another.

{function, approxEquals, 3, 11}.
  {label, 10}.
    {line, [{location, "std@testing@asserts.erl", 5}]}.
    {func_info, {atom, std@testing@asserts}, {atom, approxEquals}, 3}.
  {label, 11}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test, is_ge, {f, 68}, [{y, 3}, {float, 0.0}]}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 69}}.
  {label, 68}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {y, 3}], {x, 0}}.
  {label, 69}.
    {move, {x, 0}, {y, 4}}.
    {test, is_lt, {f, 70}, [{y, 2}, {y, 4}]}.
    {move, {literal, <<"asserts.approxEquals: values differ by more than tolerance">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 70}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
% Private: a value rendered canonically by the host — `JSON.stringify` on
% Node, `io_lib:format("~0tp")` on Erlang. Lifted from the old onze's
% `onzeKey`, where it keyed the call log for the same reason: two values that
% render the same are structurally equal on that host.
% Fails when the two values differ structurally — arrays and records by
% content, on every target. Needs Node or Erlang at run time (`canonical`).

{function, deepEquals, 2, 13}.
  {label, 12}.
    {line, [{location, "std@testing@asserts.erl", 6}]}.
    {func_info, {atom, std@testing@asserts}, {atom, deepEquals}, 2}.
  {label, 13}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 73}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 73}}.
    {test, is_ne_exact, {f, 71}, [{y, 2}, {x, 0}]}.
    {move, {literal, <<"asserts.deepEquals: values differ structurally">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 71}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
% ── nil ──────────────────────────────────────────────────────────────────────
% Fails when the optional holds a value. `!= null`, never truthiness — on
% commonJS `if (x)` is false for `0`.

{function, isNil, 1, 15}.
  {label, 14}.
    {line, [{location, "std@testing@asserts.erl", 7}]}.
    {func_info, {atom, std@testing@asserts}, {atom, isNil}, 1}.
  {label, 15}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ne_exact, {f, 74}, [{y, 0}, {atom, undefined}]}.
    {move, {literal, <<"asserts.isNil: value was present">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 74}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
% Fails when the optional is absent.

{function, isNotNil, 1, 17}.
  {label, 16}.
    {line, [{location, "std@testing@asserts.erl", 8}]}.
    {func_info, {atom, std@testing@asserts}, {atom, isNotNil}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_eq_exact, {f, 75}, [{y, 0}, {atom, undefined}]}.
    {move, {literal, <<"asserts.isNotNil: value was null">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 75}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
% ── result ───────────────────────────────────────────────────────────────────
% Fails when `result` is `Error`. Read the payload at the call site with the
% builtin methods (`try equals(r.unwrapOr(0), 42);`).

{function, isOk, 1, 19}.
  {label, 18}.
    {line, [{location, "std@testing@asserts.erl", 9}]}.
    {func_info, {atom, std@testing@asserts}, {atom, isOk}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 77}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, false}, {x, 0}}.
  {label, 78}.
    {test, is_eq, {f, 76}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"asserts.isOk: result was Error">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 76}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
% Fails when `result` is `Ok`. To assert that a `Result`-returning body
% fails, this is the tool — `throws` is for a `panic` or a host throw.

{function, isError, 1, 21}.
  {label, 20}.
    {line, [{location, "std@testing@asserts.erl", 10}]}.
    {func_info, {atom, std@testing@asserts}, {atom, isError}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 80}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {atom, false}, {x, 0}}.
  {label, 81}.
    {test, is_eq, {f, 79}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"asserts.isError: result was Ok">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 79}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
% ── string ───────────────────────────────────────────────────────────────────
% Fails when `needle` is not a substring of `actual`.

{function, contains, 2, 23}.
  {label, 22}.
    {line, [{location, "std@testing@asserts.erl", 11}]}.
    {func_info, {atom, std@testing@asserts}, {atom, contains}, 2}.
  {label, 23}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 83}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 84}}.
  {label, 83}.
    {move, {atom, true}, {x, 0}}.
  {label, 84}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 82}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"asserts.contains: needle not in actual">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 82}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Fails when `needle` is a substring of `actual`.

{function, notContains, 2, 25}.
  {label, 24}.
    {line, [{location, "std@testing@asserts.erl", 12}]}.
    {func_info, {atom, std@testing@asserts}, {atom, notContains}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 86}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 87}}.
  {label, 86}.
    {move, {atom, true}, {x, 0}}.
  {label, 87}.
    {test, is_eq, {f, 85}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"asserts.notContains: needle found in actual">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 85}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Fails when `actual` does not start with `prefix`.

{function, startsWith, 2, 27}.
  {label, 26}.
    {line, [{location, "std@testing@asserts.erl", 13}]}.
    {func_info, {atom, std@testing@asserts}, {atom, startsWith}, 2}.
  {label, 27}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 89}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {atom, true}, {x, 0}}.
  {label, 90}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 88}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"asserts.startsWith: prefix does not match">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 88}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Fails when `actual` does not end with `suffix`.

{function, endsWith, 2, 29}.
  {label, 28}.
    {line, [{location, "std@testing@asserts.erl", 14}]}.
    {func_info, {atom, std@testing@asserts}, {atom, endsWith}, 2}.
  {label, 29}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 93}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 91}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"asserts.endsWith: suffix does not match">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 91}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Private `regex.matches` twin, actual-first: inlined here rather than via a
% cross-module call so this file stays self-contained (std-internal modules
% do not import each other). PCRE-ish on both hosts.
% Fails when the regular expression `pattern` (the host's native flavour)
% does not match `actual`. Use `contains` for a literal needle. Needs Node or
% Erlang at run time (`regexMatches`).

{function, matches, 2, 31}.
  {label, 30}.
    {line, [{location, "std@testing@asserts.erl", 15}]}.
    {func_info, {atom, std@testing@asserts}, {atom, matches}, 2}.
  {label, 31}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 109}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 107}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"asserts.matches: pattern did not match">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 107}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% ── collection ───────────────────────────────────────────────────────────────
% Fails when the array has elements.

{function, isEmpty, 1, 33}.
  {label, 32}.
    {line, [{location, "std@testing@asserts.erl", 16}]}.
    {func_info, {atom, std@testing@asserts}, {atom, isEmpty}, 1}.
  {label, 33}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 110}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"asserts.isEmpty: array was not empty">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 110}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
% Fails when the array is empty.

{function, isNotEmpty, 1, 35}.
  {label, 34}.
    {line, [{location, "std@testing@asserts.erl", 17}]}.
    {func_info, {atom, std@testing@asserts}, {atom, isNotEmpty}, 1}.
  {label, 35}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 111}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"asserts.isNotEmpty: array was empty">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 111}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
% Fails when the array's length is not `expected`.

{function, lengthIs, 2, 37}.
  {label, 36}.
    {line, [{location, "std@testing@asserts.erl", 18}]}.
    {func_info, {atom, std@testing@asserts}, {atom, lengthIs}, 2}.
  {label, 37}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 112}, [{x, 0}, {y, 1}]}.
    {move, {literal, <<"asserts.lengthIs: length differs">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 112}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Fails when no element `==` `element` (`Array.indexOf` — reference equality
% for records on commonJS; extract with `.at(i)` and `deepEquals` instead).

{function, includes, 2, 39}.
  {label, 38}.
    {line, [{location, "std@testing@asserts.erl", 19}]}.
    {func_info, {atom, std@testing@asserts}, {atom, includes}, 2}.
  {label, 39}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 115}}.
    {test, is_lt, {f, 113}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"asserts.includes: element not found">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 113}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Fails when some element `==` `element`.

{function, notIncludes, 2, 41}.
  {label, 40}.
    {line, [{location, "std@testing@asserts.erl", 20}]}.
    {func_info, {atom, std@testing@asserts}, {atom, notIncludes}, 2}.
  {label, 41}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call, 3, {f, 115}}.
    {test, is_ge, {f, 118}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"asserts.notIncludes: element found">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 118}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% ── numeric ──────────────────────────────────────────────────────────────────
% Fails when `actual` is outside `[low, high]` (both ends included). `i32`
% only: a generic `T` cannot be compared with `<`, and `f64` callers have
% `approxEquals`. `positive`/`negative` are `greaterThan(x, 0)`/`lessThan(x, 0)`.

{function, between, 3, 43}.
  {label, 42}.
    {line, [{location, "std@testing@asserts.erl", 21}]}.
    {func_info, {atom, std@testing@asserts}, {atom, between}, 3}.
  {label, 43}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_lt, {f, 119}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 120}}.
  {label, 119}.
    {move, {atom, false}, {x, 0}}.
  {label, 120}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 121}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 123}, [{y, 2}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 124}}.
  {label, 123}.
    {move, {atom, false}, {x, 0}}.
  {label, 124}.
    {jump, {f, 122}}.
  {label, 121}.
    {move, {atom, true}, {x, 0}}.
  {label, 122}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq, {f, 125}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"asserts.between: value out of range">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 125}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
% Fails when `actual <= bound`.

{function, greaterThan, 2, 45}.
  {label, 44}.
    {line, [{location, "std@testing@asserts.erl", 22}]}.
    {func_info, {atom, std@testing@asserts}, {atom, greaterThan}, 2}.
  {label, 45}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 126}, [{y, 1}, {y, 0}]}.
    {move, {literal, <<"asserts.greaterThan: value not greater">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 126}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Fails when `actual >= bound`.

{function, lessThan, 2, 47}.
  {label, 46}.
    {line, [{location, "std@testing@asserts.erl", 23}]}.
    {func_info, {atom, std@testing@asserts}, {atom, lessThan}, 2}.
  {label, 47}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 127}, [{y, 0}, {y, 1}]}.
    {move, {literal, <<"asserts.lessThan: value not less">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 127}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% ── exceptions ───────────────────────────────────────────────────────────────
% Private: the message `failure.attempt` caught, or `""` for a body that
% completed.

{function, caughtMessage, 1, 49}.
  {label, 48}.
    {line, [{location, "std@testing@asserts.erl", 24}]}.
    {func_info, {atom, std@testing@asserts}, {atom, caughtMessage}, 1}.
  {label, 49}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 129}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 128}}.
  {label, 129}.
    {test, is_tagged_tuple, {f, 130}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 131}, [{x, 0}, 3, {atom, std@failure@@Failure}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 131}.
    {jump, {f, 128}}.
  {label, 130}.
    {case_end, {x, 0}}.
  {label, 128}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
% Fails when `body` completes normally — for a `panic` or a host raise from
% code whose return carries no `Result` (a failing `Result` is `isError`).
% Generic over the body's own type and run under `failure.attempt` (decisions
% 431, 493), so it needs Node or Erlang at run time.

{function, throws, 1, 51}.
  {label, 50}.
    {line, [{location, "std@testing@asserts.erl", 25}]}.
    {func_info, {atom, std@testing@asserts}, {atom, throws}, 1}.
  {label, 51}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 133}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 134}}.
  {label, 133}.
    {move, {atom, false}, {x, 0}}.
  {label, 134}.
    {test, is_eq, {f, 132}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"asserts.throws: body did not raise">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 132}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% Fails when `body` completes normally, or when the caught message does not
% contain `needle`. The message is `failure.attempt`'s `Failure.message`: a
% `panic(text)` / `@todo(text)` is its own `text` on every target, byte for
% byte — a needle with a `"`, a `\` or a non-ASCII character matches alike;
% any other host raise is its JS `message` (else `String(e)`) on Node and
% the reason by `~tp` on Erlang (`badarg`).

{function, throwsWith, 2, 53}.
  {label, 52}.
    {line, [{location, "std@testing@asserts.erl", 26}]}.
    {func_info, {atom, std@testing@asserts}, {atom, throwsWith}, 2}.
  {label, 53}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 136}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 137}}.
  {label, 136}.
    {move, {atom, false}, {x, 0}}.
  {label, 137}.
    {test, is_eq, {f, 135}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"asserts.throwsWith: body did not raise">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 135}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 49}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 139}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 140}}.
  {label, 139}.
    {move, {atom, true}, {x, 0}}.
  {label, 140}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 138}, [{x, 1}, {x, 0}]}.
    {move, {literal, <<"asserts.throwsWith: message does not contain needle">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
  {label, 138}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
% ── utility ──────────────────────────────────────────────────────────────────
% Always `Error("asserts.fail: <message>")` — the one function whose message
% carries caller text; the escape for a branch the test asserts is unreachable.

{function, fail, 1, 55}.
  {label, 54}.
    {line, [{location, "std@testing@asserts.erl", 27}]}.
    {func_info, {atom, std@testing@asserts}, {atom, fail}, 1}.
  {label, 55}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"asserts.fail: ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 170}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% The `Error` payload of an assertion's result, or `""` for `Ok`. Not
% a `-> Result` fn: it is how a test reads a failure message to compare or
% snapshot it (`test-snap.md`), matching over the builtin `Result` enum in a
% function the manual-construction rule does not apply to.

{function, errorText, 1, 57}.
  {label, 56}.
    {line, [{location, "std@testing@asserts.erl", 28}]}.
    {func_info, {atom, std@testing@asserts}, {atom, errorText}, 1}.
  {label, 57}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 174}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 173}}.
  {label, 174}.
    {test, is_tagged_tuple, {f, 175}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 173}}.
  {label, 175}.
    {case_end, {x, 0}}.
  {label, 173}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────
% One test per function per path, written with `try`; a fail path asserts
% `isError` over the assertion's own result and pins the literal message
% through `errorText` (no host cell, no panic).

{function, parsePort, 1, 59}.
  {label, 58}.
    {line, [{location, "std@testing@asserts.erl", 29}]}.
    {func_info, {atom, std@testing@asserts}, {atom, parsePort}, 1}.
  {label, 59}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 176}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"empty input">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 176}.
    {move, {integer, 8080}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, explode, 0, 61}.
  {label, 60}.
    {line, [{location, "std@testing@asserts.erl", 30}]}.
    {func_info, {atom, std@testing@asserts}, {atom, explode}, 0}.
  {label, 61}.
    {allocate, 0, 0}.
    {move, {literal, <<"boom: the widget is on fire">>}, {x, 0}}.
    {call, 1, {f, 178}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
% boolean
% equality
% nil
% result
% string
% collection
% numeric
% exceptions

{function, quoteRaiser, 0, 63}.
  {label, 62}.
    {line, [{location, "std@testing@asserts.erl", 31}]}.
    {func_info, {atom, std@testing@asserts}, {atom, quoteRaiser}, 0}.
  {label, 63}.
    {allocate, 0, 0}.
    {move, {literal, <<"withHeader(\"Set-Cookie\", v) \\ twice">>}, {x, 0}}.
    {call, 1, {f, 178}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
% utility

{function, '__bp_priv__caughtMessage', 1, 180}.
  {label, 179}.
    {line, [{location, "std@testing@asserts.erl", 32}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_priv__caughtMessage'}, 1}.
  {label, 180}.
    {call_only, 1, {f, 49}}.

{function, '__bp_priv__explode', 0, 182}.
  {label, 181}.
    {line, [{location, "std@testing@asserts.erl", 33}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_priv__explode'}, 0}.
  {label, 182}.
    {call_only, 0, {f, 61}}.

{function, '__bp_priv__parsePort', 1, 184}.
  {label, 183}.
    {line, [{location, "std@testing@asserts.erl", 34}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_priv__parsePort'}, 1}.
  {label, 184}.
    {call_only, 1, {f, 59}}.

{function, '__bp_priv__quoteRaiser', 0, 186}.
  {label, 185}.
    {line, [{location, "std@testing@asserts.erl", 35}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_priv__quoteRaiser'}, 0}.
  {label, 186}.
    {call_only, 0, {f, 63}}.

{function, '__bp_tpl_0', 1, 73}.
  {label, 72}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_tpl_0'}, 1}.
  {label, 73}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, [126, 48, 116, 112]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 2}.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 97}.
  {label, 96}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 97}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 101}}.
  {label, 101}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 103}}.
  {label, 103}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 104}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 106}}.
  {label, 104}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 105}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 106}}.
  {label, 105}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 106}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_tpl_1', 2, 93}.
  {label, 92}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_tpl_1'}, 2}.
  {label, 93}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 97}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_2', 2, 109}.
  {label, 108}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_tpl_2'}, 2}.
  {label, 109}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, re, run, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {atom, nomatch}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-bp_indexOf-', 3, 115}.
  {label, 114}.
    {line, [{location, "std@testing@asserts.erl", 20}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '-bp_indexOf-'}, 3}.
  {label, 115}.
    {test, is_nonempty_list, {f, 116}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 3}, {x, 4}}.
    {test, is_eq, {f, 117}, [{x, 3}, {x, 1}]}.
    {move, {x, 2}, {x, 0}}.
    return.
  {label, 117}.
    {move, {x, 4}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {integer, 1}], {x, 2}}.
    {call_only, 3, {f, 115}}.
  {label, 116}.
    {move, {integer, -1}, {x, 0}}.
    return.

{function, '__bp_print', 1, 142}.
  {label, 141}.
    {line, [{location, "std@testing@asserts.erl", 28}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_print'}, 1}.
  {label, 142}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 146}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 146}.
  {label, 145}.
    {line, [{location, "std@testing@asserts.erl", 28}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '-bp_show_top-'}, 1}.
  {label, 146}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 144}}.

{function, '-bp_show_elem-', 1, 148}.
  {label, 147}.
    {line, [{location, "std@testing@asserts.erl", 28}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '-bp_show_elem-'}, 1}.
  {label, 148}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 144}}.

{function, '__bp_show', 2, 144}.
  {label, 143}.
    {line, [{location, "std@testing@asserts.erl", 28}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_show'}, 2}.
  {label, 144}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 156}, [{x, 0}]}.
    {test, is_eq, {f, 155}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 155}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 156}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 157}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 148}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 157}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 159}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 158}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 158}, [{x, 0}]}.
    {test, is_ne_exact, {f, 158}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 158}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 158}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 163}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 164}}.
  {label, 163}.
    {test, is_eq_exact, {f, 160}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 164}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 144}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 158}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 148}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 159}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 161}, [{x, 0}]}.
    {test, is_ne_exact, {f, 161}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 161}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 162}, [{x, 0}, {atom, undefined}]}.
  {label, 160}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 150}, 2}.
  {label, 161}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 162}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 150}.
  {label, 149}.
    {line, [{location, "std@testing@asserts.erl", 28}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_tagged'}, 2}.
  {label, 150}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 165}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 165}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 165}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 166}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 152}, 3}.
  {label, 166}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 152}.
  {label, 151}.
    {line, [{location, "std@testing@asserts.erl", 28}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_render'}, 1}.
  {label, 152}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 167}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 167}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 168}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 168}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 154}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 154}.
  {label, 153}.
    {line, [{location, "std@testing@asserts.erl", 28}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '-bp_render_pair-'}, 1}.
  {label, 154}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 144}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 170}.
  {label, 169}.
    {line, [{location, "std@testing@asserts.erl", 28}]}.
    {func_info, {atom, std@testing@asserts}, {atom, '-bp_stringify-'}, 1}.
  {label, 170}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 171}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 171}.
    {test, is_integer, {f, 172}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 172}.
    {call, 1, {f, 146}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_3', 1, 178}.
  {label, 177}.
    {func_info, {atom, std@testing@asserts}, {atom, '__bp_tpl_3'}, 1}.
  {label, 178}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.
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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__Array_range', 2}, {'__bp_priv__Array_repeat', 2}, {'__bp_priv__at', 2}, {'__bp_priv__holds', 2}, {'__bp_priv__lastAt', 2}]}.
{attributes, []}.
{labels, 102}.

{function, 'Array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, 'Array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 22}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 27}}.
  {label, 25}.
  {label, 23}.
    {deallocate, 6}.
    return.

{function, 'Array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, 'Array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 28}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 27}}.
    {jump, {f, 31}}.
  {label, 30}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 27}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 27}}.
  {label, 31}.
  {label, 29}.
    {deallocate, 6}.
    return.

{function, at, 2, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, at}, 2}.
  {label, 7}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call_last, 3, {f, 33}, 2}.

{function, lastAt, 2, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, lastAt}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 37}, 2}.

{function, holds, 2, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, holds}, 2}.
  {label, 11}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, member, 2}, 2}.

{function, main, 0, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 13}.
    {allocate, 7, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, std@testing@asserts, includes, 2}}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 55}}.
  {label, 54}.
    {move, {atom, false}, {x, 0}}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, std@testing@asserts, includes, 2}}.
    {test, is_tagged_tuple, {f, 84}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {atom, false}, {x, 0}}.
  {label, 85}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {float, 3.5}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {float, 2.5}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {float, 3.5}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {atom, false}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"y">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 19}}.
    {call_last, 0, {f, 13}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '__bp_load_siblings', 0, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, test@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 86}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 21}, 0}.
  {label, 86}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 21}.
    {test, is_nonempty_list, {f, 87}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 90}}.
  {label, 88}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 89}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 90}}.
  {label, 89}.
    {test_heap, 4, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 1}}.
    {move, {literal, <<"error: ~ts does not compile - refusing to run~n  ~p~n">>}, {x, 0}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, standard_error}, {x, 0}}.
    {call_ext, 2, {extfunc, file, write, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, halt, 1}}.
  {label, 90}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 21}, 2}.
  {label, 87}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '__bp_priv__Array_range', 2, 93}.
  {label, 92}.
    {line, [{location, "test@main.erl", 12}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_range'}, 2}.
  {label, 93}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__Array_repeat', 2, 95}.
  {label, 94}.
    {line, [{location, "test@main.erl", 13}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_repeat'}, 2}.
  {label, 95}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__at', 2, 97}.
  {label, 96}.
    {line, [{location, "test@main.erl", 14}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__at'}, 2}.
  {label, 97}.
    {call_only, 2, {f, 7}}.

{function, '__bp_priv__holds', 2, 99}.
  {label, 98}.
    {line, [{location, "test@main.erl", 15}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__holds'}, 2}.
  {label, 99}.
    {call_only, 2, {f, 11}}.

{function, '__bp_priv__lastAt', 2, 101}.
  {label, 100}.
    {line, [{location, "test@main.erl", 16}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__lastAt'}, 2}.
  {label, 101}.
    {call_only, 2, {f, 9}}.

{function, '-bp_indexOf-', 3, 33}.
  {label, 32}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_indexOf-'}, 3}.
  {label, 33}.
    {test, is_nonempty_list, {f, 34}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 3}, {x, 4}}.
    {test, is_eq, {f, 35}, [{x, 3}, {x, 1}]}.
    {move, {x, 2}, {x, 0}}.
    return.
  {label, 35}.
    {move, {x, 4}, {x, 0}}.
    {gc_bif, '+', {f, 0}, 3, [{x, 2}, {integer, 1}], {x, 2}}.
    {call_only, 3, {f, 33}}.
  {label, 34}.
    {move, {integer, -1}, {x, 0}}.
    return.

{function, '__bp_tpl_0--t/2-fun-0--fun-1-', 4, 45}.
  {label, 44}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0--t/2-fun-0--fun-1-'}, 4}.
  {label, 45}.
    {allocate, 11, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {x, 3}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 45}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 47}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 7}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {y, 2}}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {y, 10}}.
    {jump, {f, 48}}.
  {label, 49}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {y, 10}}.
    {jump, {f, 48}}.
  {label, 50}.
    {move, {y, 9}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 48}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 10}, {x, 2}}.
    {move, {y, 0}, {x, 3}}.
    {call_last, 4, {f, 45}, 11}.
  {label, 47}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, nil]}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 51}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 0}, {x, 3}}.
    {deallocate, 11}.
    {jump, {f, 44}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 41}.
  {label, 40}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 41}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 45}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 53}}.
  {label, 53}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {integer, -1}, {x, 2}}.
    {move, {y, 0}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_0', 2, 37}.
  {label, 36}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 2}.
  {label, 37}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_print', 1, 57}.
  {label, 56}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 57}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 61}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 61}.
  {label, 60}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 61}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 59}}.

{function, '-bp_show_elem-', 1, 63}.
  {label, 62}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 63}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 59}}.

{function, '__bp_show', 2, 59}.
  {label, 58}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 59}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 71}, [{x, 0}]}.
    {test, is_eq, {f, 70}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 70}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 72}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 72}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 74}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 73}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 73}, [{x, 0}]}.
    {test, is_ne_exact, {f, 73}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 73}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 73}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 79}}.
  {label, 78}.
    {test, is_eq_exact, {f, 75}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 79}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 59}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 73}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 74}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 76}, [{x, 0}]}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 77}, [{x, 0}, {atom, undefined}]}.
  {label, 75}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 65}, 2}.
  {label, 76}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 77}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 65}.
  {label, 64}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 65}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 80}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 80}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 80}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 67}, 3}.
  {label, 81}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 67}.
  {label, 66}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 67}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 82}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 82}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 83}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 83}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 69}.
  {label, 68}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 69}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 59}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 27}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 91}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 91}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
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
