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

----- BEAM ASSEMBLY -- std/async.S
```erlang
{module, std@async}.
{exports, [{delay, 2}, {failed, 1}, {newGate, 0}, {openGate, 1}, {awaitGate, 2}, {errorText, 1}, {allOf, 1}, {all, 1}, {race, 1}, {runAll, 1}, {raceOf, 1}, {timeout, 2}, {nextDelay, 2}, {retry, 2}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__answerNow', 1}, {'__bp_priv__answered', 1}, {'__bp_priv__errorProbe', 0}, {'__bp_priv__expireAfter', 2}, {'__bp_priv__flaky', 2}, {'__bp_priv__gateBudget', 0}, {'__bp_priv__gated', 2}, {'__bp_priv__ghost', 2}, {'__bp_priv__grown', 4}, {'__bp_priv__handshake', 3}, {'__bp_priv__panicOf', 1}, {'__bp_priv__pauseText', 2}, {'__bp_priv__pauses', 2}, {'__bp_priv__policyProblem', 1}, {'__bp_priv__retryFrom', 3}, {'__bp_priv__slowOk', 2}]}.
{attributes, []}.
{labels, 406}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@async.erl", 1}]}.
    {func_info, {atom, std@async}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 117}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 118}}.
  {label, 117}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 119}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 120}}.
  {label, 119}.
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
    {call, 2, {f, 122}}.
  {label, 120}.
  {label, 118}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@async.erl", 2}]}.
    {func_info, {atom, std@async}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 123}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 124}}.
  {label, 123}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 125}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 122}}.
    {jump, {f, 126}}.
  {label, 125}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 122}}.
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
    {call, 2, {f, 122}}.
  {label, 126}.
  {label, 124}.
    {deallocate, 6}.
    return.
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
% ── instruments ──────────────────────────────────────────────────────────────
% Which backend is running. The future surface's erlang behaviour differs from
% its commonJS behaviour by design, and a test that asserts one of the two has
% to know which it is looking at. Private: the divergence is this module's to
% document, not a consumer's to branch on.
% The host's monotonic clock in milliseconds. `std/io/clock` has the same cell,
% and this root module may not import from `io/` (decision 106), so this file
% carries its own. Private — `clock.monotonicMillis()` is the public spelling.
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

{function, delay, 2, 67}.
  {label, 66}.
    {line, [{location, "std@async.erl", 3}]}.
    {func_info, {atom, std@async}, {atom, delay}, 2}.
  {label, 67}.
    {call_only, 2, {f, 61}}.
% A Async whose value is `Error(message)` — the failing instrument `allOf` and
% `timeout` are tested with. On commonJS it rejects with `message` (decision
% 432); `await` reads it as `Error(message)`.

%% @Async — eager lowering
{function, failed, 1, 7}.
  {label, 6}.
    {line, [{location, "std@async.erl", 4}]}.
    {func_info, {atom, std@async}, {atom, failed}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
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
% A new, closed gate.

{function, newGate, 0, 9}.
  {label, 8}.
    {line, [{location, "std@async.erl", 5}]}.
    {func_info, {atom, std@async}, {atom, newGate}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 128}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@async@@Gate}, {x, 0}]}}.
    {deallocate, 0}.
    return.
% Open `gate`: every task awaiting it answers, and so does every later
% `awaitGate`. Opening an open gate changes nothing.

{function, openGate, 1, 11}.
  {label, 10}.
    {line, [{location, "std@async.erl", 6}]}.
    {func_info, {atom, std@async}, {atom, openGate}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 165}, [{x, 0}, 2, {atom, std@async@@Gate}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 165}.
    {call, 1, {f, 160}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
% `true` once `gate` is open, `false` when `millis` pass first. The budget is
% not the ordering — the gate is; it only turns a gate nobody opens into a red
% assertion instead of a hang, so a test gives it a margin no scheduling delay
% can cross (seconds) and opens every gate it closes. An open gate answers at
% once and leaves no timer behind.

%% @Async — eager lowering
{function, awaitGate, 2, 13}.
  {label, 12}.
    {line, [{location, "std@async.erl", 7}]}.
    {func_info, {atom, std@async}, {atom, awaitGate}, 2}.
  {label, 13}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 181}, [{x, 0}, 2, {atom, std@async@@Gate}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 181}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 167}}.
    {deallocate, 2}.
    return.
% ── reading a settled element ────────────────────────────────────────────────
% The `Error` payload of a `Result<T, string>`, or `""` for `Ok`. `Result`
% carries `isOk`/`isError`/`unwrapOr` as builtins but no way to read the error
% side, so without this a caller can see THAT a widget failed and never WHY —
% the shape decision 67 refuses.

{function, errorText, 1, 15}.
  {label, 14}.
    {line, [{location, "std@async.erl", 8}]}.
    {func_info, {atom, std@async}, {atom, errorText}, 1}.
  {label, 15}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 183}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 182}}.
  {label, 183}.
    {test, is_tagged_tuple, {f, 184}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 182}}.
  {label, 184}.
    {case_end, {x, 0}}.
  {label, 182}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
% ── started tasks ────────────────────────────────────────────────────────────
% The values of every Async, in input order, or the FIRST `Error` in input
% order. The tasks were started by the caller (`allOf([fetchUser(1),
% fetchUser(2)])`), so on commonJS they run concurrently and this only waits;
% on erlang they already ran. `allOf([])` answers `Ok([])`.

%% @Async — eager lowering
{function, allOf, 1, 17}.
  {label, 16}.
    {line, [{location, "std@async.erl", 9}]}.
    {func_info, {atom, std@async}, {atom, allOf}, 1}.
  {label, 17}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 186}, 0, 0, {x, 0}, {list, []}}.
    {'try', {y, 2}, {f, 189}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {try_end, {y, 2}}.
    {jump, {f, 192}}.
  {label, 189}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 190}, [{x, 1}, 2, {atom, '__bp_try'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 190}.
    {test, is_tagged_tuple, {f, 191}, [{x, 1}, 2, {atom, '__bp_return'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 191}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 192}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
% The values of every Async, in input order — the infallible `allOf`.

%% @Async — eager lowering
{function, all, 1, 19}.
  {label, 18}.
    {line, [{location, "std@async.erl", 10}]}.
    {func_info, {atom, std@async}, {atom, all}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 194}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
% commonJS: the FASTEST Async to answer, `Promise.race`.
% ERLANG: ELEMENT ZERO. Every Async resolved before the call, so there is no
% timing left to measure and this answers the first element of the list. That
% is not a bug to be fixed here and no server front may depend on it — use
% `raceOf`, whose tasks are unstarted when it receives them. Both behaviours
% are pinned by `async: race ---- commonJS fastest, erlang element zero`.
% 
% `race([])` is a programming error, fatal on both targets
% (`async.race: empty task list`).

{function, race, 1, 79}.
  {label, 78}.
    {line, [{location, "std@async.erl", 11}]}.
    {func_info, {atom, std@async}, {atom, race}, 1}.
  {label, 79}.
    {call_only, 1, {f, 69}}.
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
% The public face of the cell above: a real function, so a module compiled
% separately (the BEAM backend links modules by name) can call it — a
% template-only `declare fn` has no body to export.

%% @Async — eager lowering
{function, runAll, 1, 21}.
  {label, 20}.
    {line, [{location, "std@async.erl", 12}]}.
    {func_info, {atom, std@async}, {atom, runAll}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 196}}.
    {deallocate, 1}.
    return.
% The first task to ANSWER, not the first in the list. The LOSERS keep
% running and their values are discarded: there is no cancellation surface in
% botopink, and a race that reported the loser would not be a race.
% 
% `raceOf([])` is a programming error, fatal on both targets
% (`async.raceOf: empty task list`), rather than blocking forever.

{function, raceOf, 1, 116}.
  {label, 115}.
    {line, [{location, "std@async.erl", 13}]}.
    {func_info, {atom, std@async}, {atom, raceOf}, 1}.
  {label, 116}.
    {call_only, 1, {f, 81}}.
% `task`'s value as `Ok` — the racer `timeout` puts beside the clock.

%% @Async — eager lowering
{function, answered, 1, 23}.
  {label, 22}.
    {line, [{location, "std@async.erl", 14}]}.
    {func_info, {atom, std@async}, {atom, answered}, 1}.
  {label, 23}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
% `Error("timeout")` after `millis` — the clock `timeout` races against
% `task`, whose type it answers in (decision 668: `task` binds `T`).

%% @Async — eager lowering
{function, expireAfter, 2, 25}.
  {label, 24}.
    {line, [{location, "std@async.erl", 15}]}.
    {func_info, {atom, std@async}, {atom, expireAfter}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 61}}.
    {move, {literal, <<"timeout">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% `Ok(value)` when the task answered inside the budget, `Error("timeout")`
% when it did not. A task over a `Result` keeps its own failure INSIDE the
% `Ok` (`Ok(Error(e))`): the budget and the task's outcome are two answers,
% and neither hides the other. The task KEEPS RUNNING; the caller stops
% waiting. Expressed over `raceOf` + `delay`.

%% @Async — eager lowering
{function, timeout, 2, 27}.
  {label, 26}.
    {line, [{location, "std@async.erl", 16}]}.
    {func_info, {atom, std@async}, {atom, timeout}, 2}.
  {label, 27}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 232}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 234}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 81}}.
    {deallocate, 3}.
    return.
% ── retry (1.0.11-beta front 97) ─────────────────────────────────────────────
% How a fallible task is tried again: at most `maxAttempts` attempts, a pause
% of `initialMillis` after the first failure, each later pause `multiplier`
% times the one before, none above `maxMillis`. There is no jitter and no
% field that means "for ever" (decision 67): a policy is usable only when
% `maxAttempts` is at least 1, the two delays are not negative, `maxMillis`
% is at most 2147483647 (the longest timer both targets arm) and `multiplier`
% is at least 1.0 — a backoff never shrinks, and one that could would retry
% in a near-zero-delay loop.
% Internal: why `policy` is not usable, `""` when it is.

{function, policyProblem, 1, 29}.
  {label, 28}.
    {line, [{location, "std@async.erl", 17}]}.
    {func_info, {atom, std@async}, {atom, policyProblem}, 1}.
  {label, 29}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 236}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 236}.
    {test, is_lt, {f, 235}, [{x, 0}, {integer, 1}]}.
    {move, {literal, <<"maxAttempts must be at least 1 (the first attempt)">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 235}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 238}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 238}.
    {test, is_lt, {f, 237}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"initialMillis must not be negative">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 237}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 240}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 240}.
    {test, is_lt, {f, 239}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"maxMillis must not be negative">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 239}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 242}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 242}.
    {test, is_lt, {f, 241}, [{integer, 2147483647}, {x, 0}]}.
    {move, {literal, <<"maxMillis must be at most 2147483647">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 241}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 243}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 243}.
    {test, is_ge, {f, 244}, [{x, 0}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 245}}.
  {label, 244}.
    {move, {atom, false}, {x, 0}}.
  {label, 245}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 246}, [{y, 1}, {x, 0}]}.
    {move, {literal, <<"multiplier must be at least 1.0 (a backoff never shrinks)">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 246}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 2}.
    return.
% Internal: an `i64` of milliseconds as an `f64`, and back — the whole
% milliseconds of a delay that is never negative. Not `toF64()`, which aborts
% on an integer past 2^53 that no `f64` holds: the delay is a float
% computation, and an `initialMillis` that large rounds as the float does
% (and is then capped by `maxMillis`). The Node forms take and answer
% decision 319's canonical form — `Number` reads a `BigInt` (`initialMillis`
% past 2^53 − 1), and a whole number past 2^53 − 1 answers as a `BigInt`.
% Internal: `initial × multiplier^(attempt − 1)`, never above `ceiling`. One
% multiplication per attempt — the same IEEE operations in the same order on
% both targets, where a host `pow` would not promise the same last bit — and
% none once the ceiling is reached, so it cannot overflow.

{function, grown, 4, 31}.
  {label, 30}.
    {line, [{location, "std@async.erl", 18}]}.
    {func_info, {atom, std@async}, {atom, grown}, 4}.
  {label, 31}.
    {allocate, 7, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {test, is_ge, {f, 247}, [{float, 1.0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 248}}.
  {label, 247}.
    {move, {atom, false}, {x, 0}}.
  {label, 248}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 249}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 251}, [{float, 0.0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 252}}.
  {label, 251}.
    {move, {atom, false}, {x, 0}}.
  {label, 252}.
    {jump, {f, 250}}.
  {label, 249}.
    {move, {atom, true}, {x, 0}}.
  {label, 250}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq, {f, 253}, [{x, 0}, {atom, true}]}.
    {test, is_lt, {f, 254}, [{y, 2}, {y, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 255}}.
  {label, 254}.
    {move, {y, 0}, {x, 0}}.
  {label, 255}.
    {deallocate, 7}.
    return.
  {label, 253}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {line, [{location, "std@async.erl", 19}]}.
  {label, 256}.
    {test, is_lt, {f, 258}, [{y, 6}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 259}}.
  {label, 258}.
    {move, {atom, false}, {x, 0}}.
  {label, 259}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 260}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 262}, [{y, 5}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 263}}.
  {label, 262}.
    {move, {atom, false}, {x, 0}}.
  {label, 263}.
    {jump, {f, 261}}.
  {label, 260}.
    {move, {atom, false}, {x, 0}}.
  {label, 261}.
    {test, is_eq_exact, {f, 257}, [{x, 0}, {atom, true}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 5}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 6}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 264}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 264}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 265}}.
  {label, 264}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/async.bp:335:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 265}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 256}}.
  {label, 257}.
    {test, is_lt, {f, 266}, [{y, 2}, {y, 5}]}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 267}}.
  {label, 266}.
    {move, {y, 5}, {x, 0}}.
  {label, 267}.
    {deallocate, 7}.
    return.
% The pause that follows attempt `attempt` (the first attempt is 1), in whole
% milliseconds: `initialMillis × multiplier^(attempt − 1)`, rounded down and
% never above `maxMillis`. `null` once `attempt` is past `maxAttempts` — there
% is no further attempt to wait for — and for an attempt below 1 or a policy
% that is not usable.

{function, nextDelay, 2, 33}.
  {label, 32}.
    {line, [{location, "std@async.erl", 19}]}.
    {func_info, {atom, std@async}, {atom, nextDelay}, 2}.
  {label, 33}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 268}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 269}}.
  {label, 268}.
    {move, {atom, false}, {x, 0}}.
  {label, 269}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ge, {f, 270}, [{y, 1}, {integer, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 271}}.
  {label, 270}.
    {move, {atom, false}, {x, 0}}.
  {label, 271}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 272}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 274}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 274}.
    {test, is_ge, {f, 275}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 276}}.
  {label, 275}.
    {move, {atom, false}, {x, 0}}.
  {label, 276}.
    {jump, {f, 273}}.
  {label, 272}.
    {move, {atom, false}, {x, 0}}.
  {label, 273}.
    {move, {x, 0}, {y, 3}}.
    {test, is_eq, {f, 277}, [{y, 2}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 278}}.
  {label, 277}.
    {move, {atom, false}, {x, 0}}.
  {label, 278}.
    {move, {x, 0}, {y, 4}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 279}, [{y, 4}, {x, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 279}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 284}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 284}.
    {call, 1, {f, 283}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 285}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 285}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 286}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 286}.
    {call, 1, {f, 283}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 1}, {x, 3}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 5}, {x, 0}}.
    {call, 4, {f, 31}}.
    {call_last, 1, {f, 281}, 9}.
% Internal: attempt number `attempt` of `retry`, and every one after it.

%% @Async — eager lowering
{function, retryFrom, 3, 35}.
  {label, 34}.
    {line, [{location, "std@async.erl", 20}]}.
    {func_info, {atom, std@async}, {atom, retryFrom}, 3}.
  {label, 35}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 287}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 288}}.
  {label, 287}.
    {move, {atom, false}, {x, 0}}.
  {label, 288}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 289}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 291}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 291}.
    {test, is_ge, {f, 292}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 293}}.
  {label, 292}.
    {move, {atom, false}, {x, 0}}.
  {label, 293}.
    {jump, {f, 290}}.
  {label, 289}.
    {move, {atom, true}, {x, 0}}.
  {label, 290}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq, {f, 294}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 294}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 33}}.
    {test, is_ne_exact, {f, 295}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 296}}.
  {label, 295}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 297}, [{x, 0}, 5, {atom, std@async@@RetryPolicy}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 297}.
  {label, 296}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 299}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 61}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 310}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 310}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 311}}.
  {label, 310}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/async.bp:371:54">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 311}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 35}}.
    {deallocate, 7}.
    return.
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
{function, retry, 2, 37}.
  {label, 36}.
    {line, [{location, "std@async.erl", 21}]}.
    {func_info, {atom, std@async}, {atom, retry}, 2}.
  {label, 37}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_ne_exact, {f, 312}, [{y, 2}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"async.retry: ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 316}}.
    {call, 1, {f, 314}}.
    {jump, {f, 350}}.
  {label, 312}.
  {label, 350}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 35}}.
    {deallocate, 4}.
    return.
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
% How long a test task waits on a gate before it gives up. Every gate a test
% closes is opened again, so this passes only when the code under test is
% wrong — and then as a red assertion, not a hang.

{function, gateBudget, 0, 39}.
  {label, 38}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, gateBudget}, 0}.
  {label, 39}.
    {allocate, 0, 0}.
    {move, {integer, 10000}, {x, 0}}.
    {deallocate, 0}.
    return.
% `value` once `gate` opens; a value naming the failure when it never does.

%% @Async — eager lowering
{function, gated, 2, 41}.
  {label, 40}.
    {line, [{location, "std@async.erl", 23}]}.
    {func_info, {atom, std@async}, {atom, gated}, 2}.
  {label, 41}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call, 0, {f, 39}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 13}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 351}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 352}}.
  {label, 351}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"gate never opened: ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 347}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 352}.
    {deallocate, 6}.
    return.
% Open `mine`, then answer `value` once `theirs` is open. Two of these over the
% same pair of gates, crossed, can only BOTH answer when they run at the same
% time: whichever runs first alone waits on a gate the other has not opened.

%% @Async — eager lowering
{function, handshake, 3, 43}.
  {label, 42}.
    {line, [{location, "std@async.erl", 24}]}.
    {func_info, {atom, std@async}, {atom, handshake}, 3}.
  {label, 43}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 41}}.
    {deallocate, 3}.
    return.
% `value` with no timer at all: resolved in the microtask queue on commonJS,
% the process's first reply on erlang.

%% @Async — eager lowering
{function, answerNow, 1, 45}.
  {label, 44}.
    {line, [{location, "std@async.erl", 25}]}.
    {func_info, {atom, std@async}, {atom, answerNow}, 1}.
  {label, 45}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% ── delay and failed ─────────────────────────────────────────────────────────
% ── gates ────────────────────────────────────────────────────────────────────
% ── allOf and all ────────────────────────────────────────────────────────────

%% @Async — eager lowering
{function, slowOk, 2, 47}.
  {label, 46}.
    {line, [{location, "std@async.erl", 26}]}.
    {func_info, {atom, std@async}, {atom, slowOk}, 2}.
  {label, 47}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 61}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.
% ── runAll ───────────────────────────────────────────────────────────────────
% A settled element to stand in for the `?T` fallback of `.at(i)`. `Array.at`
% answers an optional and `unwrapOr` needs a value of the element type, which
% here is itself a `Result`; this is the cheapest way to spell one.

{function, errorProbe, 0, 49}.
  {label, 48}.
    {line, [{location, "std@async.erl", 27}]}.
    {func_info, {atom, std@async}, {atom, errorProbe}, 0}.
  {label, 49}.
    {allocate, 0, 0}.
    {move, {literal, <<"async: no element">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.
% ── raceOf ───────────────────────────────────────────────────────────────────
% ── timeout ──────────────────────────────────────────────────────────────────
% The expired task of the test above: waits for `release`, opens `done` and
% answers.

%% @Async — eager lowering
{function, ghost, 2, 51}.
  {label, 50}.
    {line, [{location, "std@async.erl", 28}]}.
    {func_info, {atom, std@async}, {atom, ghost}, 2}.
  {label, 51}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"late">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 41}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.
% ── retry ────────────────────────────────────────────────────────────────────
% Internal, test scaffolding: a counter the attempts of one `retry` share —
% a closure cannot count on erlang, where a `var` it captures is a copy.
% Node: an object. Erlang: a `counters` reference.
% Count one more and answer the count.
% The text a task panics with, `""` when it answered — a panic inside a
% `-> Async` function is a rejected Promise on commonJS and a raise on erlang.

%% @Async — eager lowering
{function, panicOf, 1, 53}.
  {label, 52}.
    {line, [{location, "std@async.erl", 29}]}.
    {func_info, {atom, std@async}, {atom, panicOf}, 1}.
  {label, 53}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@failure, attemptTask, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 354}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 353}}.
  {label, 354}.
    {test, is_tagged_tuple, {f, 355}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 357}}.
    {jump, {f, 353}}.
  {label, 355}.
    {case_end, {x, 0}}.
  {label, 353}.
    {deallocate, 3}.
    return.
% Attempt `n` of a task that fails until its `succeedAt`-th call:
% `Error("failure <n>")` before it, `Ok("ok after <n>")` from it on. The test
% counts the call (`flaky(countUp(calls), …)`), so the counter's cells are
% reached from the tests alone, and a module importing `async` on a target
% with no counter (wasm) links no call of them.

%% @Async — eager lowering
{function, flaky, 2, 55}.
  {label, 54}.
    {line, [{location, "std@async.erl", 30}]}.
    {func_info, {atom, std@async}, {atom, flaky}, 2}.
  {label, 55}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_lt, {f, 362}, [{y, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"failure ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 316}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 8}.
    return.
  {label, 362}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"ok after ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 316}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 8}.
    return.
% What `nextDelay(policy, attempt)` answers, as text: the milliseconds, or
% `none`.

{function, pauseText, 2, 57}.
  {label, 56}.
    {line, [{location, "std@async.erl", 31}]}.
    {func_info, {atom, std@async}, {atom, pauseText}, 2}.
  {label, 57}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 33}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_ne_exact, {f, 363}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {jump, {f, 364}}.
  {label, 363}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 364}.
    {deallocate, 3}.
    return.
% `pauseText` for attempts 1 to `last`, joined by `,`.

{function, pauses, 2, 59}.
  {label, 58}.
    {line, [{location, "std@async.erl", 32}]}.
    {func_info, {atom, std@async}, {atom, pauses}, 2}.
  {label, 59}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 365}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 365}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 366}}.
  {label, 365}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/async.bp:727:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 366}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 368}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 316}, 6}.

{function, '__bp_priv__array_range', 2, 371}.
  {label, 370}.
    {line, [{location, "std@async.erl", 34}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 371}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 373}.
  {label, 372}.
    {line, [{location, "std@async.erl", 35}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 373}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__answerNow', 1, 375}.
  {label, 374}.
    {line, [{location, "std@async.erl", 36}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__answerNow'}, 1}.
  {label, 375}.
    {call_only, 1, {f, 45}}.

{function, '__bp_priv__answered', 1, 377}.
  {label, 376}.
    {line, [{location, "std@async.erl", 37}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__answered'}, 1}.
  {label, 377}.
    {call_only, 1, {f, 23}}.

{function, '__bp_priv__errorProbe', 0, 379}.
  {label, 378}.
    {line, [{location, "std@async.erl", 38}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__errorProbe'}, 0}.
  {label, 379}.
    {call_only, 0, {f, 49}}.

{function, '__bp_priv__expireAfter', 2, 381}.
  {label, 380}.
    {line, [{location, "std@async.erl", 39}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__expireAfter'}, 2}.
  {label, 381}.
    {call_only, 2, {f, 25}}.

{function, '__bp_priv__flaky', 2, 383}.
  {label, 382}.
    {line, [{location, "std@async.erl", 40}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__flaky'}, 2}.
  {label, 383}.
    {call_only, 2, {f, 55}}.

{function, '__bp_priv__gateBudget', 0, 385}.
  {label, 384}.
    {line, [{location, "std@async.erl", 41}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__gateBudget'}, 0}.
  {label, 385}.
    {call_only, 0, {f, 39}}.

{function, '__bp_priv__gated', 2, 387}.
  {label, 386}.
    {line, [{location, "std@async.erl", 42}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__gated'}, 2}.
  {label, 387}.
    {call_only, 2, {f, 41}}.

{function, '__bp_priv__ghost', 2, 389}.
  {label, 388}.
    {line, [{location, "std@async.erl", 43}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__ghost'}, 2}.
  {label, 389}.
    {call_only, 2, {f, 51}}.

{function, '__bp_priv__grown', 4, 391}.
  {label, 390}.
    {line, [{location, "std@async.erl", 44}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__grown'}, 4}.
  {label, 391}.
    {call_only, 4, {f, 31}}.

{function, '__bp_priv__handshake', 3, 393}.
  {label, 392}.
    {line, [{location, "std@async.erl", 45}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__handshake'}, 3}.
  {label, 393}.
    {call_only, 3, {f, 43}}.

{function, '__bp_priv__panicOf', 1, 395}.
  {label, 394}.
    {line, [{location, "std@async.erl", 46}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__panicOf'}, 1}.
  {label, 395}.
    {call_only, 1, {f, 53}}.

{function, '__bp_priv__pauseText', 2, 397}.
  {label, 396}.
    {line, [{location, "std@async.erl", 47}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__pauseText'}, 2}.
  {label, 397}.
    {call_only, 2, {f, 57}}.

{function, '__bp_priv__pauses', 2, 399}.
  {label, 398}.
    {line, [{location, "std@async.erl", 48}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__pauses'}, 2}.
  {label, 399}.
    {call_only, 2, {f, 59}}.

{function, '__bp_priv__policyProblem', 1, 401}.
  {label, 400}.
    {line, [{location, "std@async.erl", 49}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__policyProblem'}, 1}.
  {label, 401}.
    {call_only, 1, {f, 29}}.

{function, '__bp_priv__retryFrom', 3, 403}.
  {label, 402}.
    {line, [{location, "std@async.erl", 50}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__retryFrom'}, 3}.
  {label, 403}.
    {call_only, 3, {f, 35}}.

{function, '__bp_priv__slowOk', 2, 405}.
  {label, 404}.
    {line, [{location, "std@async.erl", 51}]}.
    {func_info, {atom, std@async}, {atom, '__bp_priv__slowOk'}, 2}.
  {label, 405}.
    {call_only, 2, {f, 47}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 65}.
  {label, 64}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 65}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, timer, sleep, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_0', 2, 61}.
  {label, 60}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_0'}, 2}.
  {label, 61}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 73}.
  {label, 72}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 73}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, nil]}.
    {move, {literal, <<"async.race: empty task list">>}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 1}.
  {label, 77}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, hd, 1}, 1}.

{function, '__bp_tpl_1', 1, 69}.
  {label, 68}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_1'}, 1}.
  {label, 69}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 73}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2---t/1-fun-0--fun-1--fun-2-', 4, 100}.
  {label, 99}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_2---t/1-fun-0--fun-1--fun-2-'}, 4}.
  {label, 100}.
    {allocate, 12, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {'try', {y, 11}, {f, 103}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nth, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {try_end, {y, 11}}.
    {jump, {f, 104}}.
  {label, 103}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 9}}.
    {move, {y, 7}, {y, 4}}.
    {move, {y, 8}, {y, 5}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 6}}.
    {jump, {f, 105}}.
  {label, 105}.
  {label, 104}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 1}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_2--t/1-fun-0--fun-1-', 4, 96}.
  {label, 95}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_2--t/1-fun-0--fun-1-'}, 4}.
  {label, 96}.
    {allocate, 5, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {move, {x, 3}, {y, 2}}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 100}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 3}, {y, 2}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, spawn, 1}, 5}.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 85}.
  {label, 84}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 85}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 89}, [{x, 0}, nil]}.
    {move, {literal, <<"async.raceOf: empty task list">>}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 8}.
  {label, 89}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 92}}.
  {label, 92}.
    {call_ext, 0, {extfunc, erlang, make_ref, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 94}}.
  {label, 94}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 96}, 1, 0, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, seq, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 3}}.
  {label, 107}.
    {loop_rec, {f, 108}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 111}, [{x, 0}]}.
    {test, test_arity, {f, 111}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_eq_exact, {f, 111}, [{x, 0}, {x, 1}]}.
    {move, {y, 6}, {y, 0}}.
    remove_message.
    {move, {y, 0}, {y, 3}}.
    {jump, {f, 110}}.
  {label, 111}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 0}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {loop_rec_end, {f, 107}}.
  {label, 110}.
    {jump, {f, 109}}.
  {label, 108}.
    {wait, {f, 107}}.
  {label, 109}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 113}, [{x, 0}]}.
    {test, test_arity, {f, 113}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {atom, ok}]}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 113}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 114}, [{x, 0}]}.
    {test, test_arity, {f, 114}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {get_tuple_element, {x, 0}, 2, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 114}, [{x, 0}, {atom, error}]}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, nil, {x, 2}}.
    {call_ext_last, 3, {extfunc, erlang, raise, 3}, 8}.
  {label, 114}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_2', 1, 81}.
  {label, 80}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_2'}, 1}.
  {label, 81}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 85}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_3---t/0-fun-0--fun-1--fun-2-', 1, 146}.
  {label, 145}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_3---t/0-fun-0--fun-1--fun-2-'}, 1}.
  {label, 146}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 148}, [{x, 0}]}.
    {test, test_arity, {f, 148}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 4}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 1}, {atom, bp_gate_open}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 148}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    {jump, {f, 145}}.

{function, '__bp_tpl_3---t/0-fun-0--fun-1--fun-3-', 0, 150}.
  {label, 149}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_3---t/0-fun-0--fun-1--fun-3-'}, 0}.
  {label, 150}.
    {allocate, 7, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 150}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
  {label, 153}.
    {loop_rec, {f, 154}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 157}, [{x, 0}]}.
    {test, test_arity, {f, 157}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {get_tuple_element, {x, 0}, 2, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 157}, [{x, 0}, {atom, bp_gate_wait}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {y, 1}}.
    remove_message.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 1}, {atom, bp_gate_open}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 6}}.
    {call_last, 0, {f, 150}, 7}.
  {label, 157}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 158}, [{x, 0}, {atom, bp_gate_open}]}.
    remove_message.
    {call_last, 0, {f, 150}, 7}.
  {label, 158}.
    {move, nil, {y, 2}}.
    {move, nil, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {loop_rec_end, {f, 153}}.
  {label, 154}.
    {wait, {f, 153}}.

{function, '__bp_tpl_3--t/0-fun-0--fun-1-', 1, 136}.
  {label, 135}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_3--t/0-fun-0--fun-1-'}, 1}.
  {label, 136}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 136}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
  {label, 139}.
    {loop_rec, {f, 140}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 143}, [{x, 0}]}.
    {test, test_arity, {f, 143}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {get_tuple_element, {x, 0}, 2, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 143}, [{x, 0}, {atom, bp_gate_wait}]}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 6}, {y, 1}}.
    remove_message.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_last, 1, {f, 136}, 8}.
  {label, 143}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 144}, [{x, 0}, {atom, bp_gate_open}]}.
    remove_message.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 146}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 150}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 8}.
    return.
  {label, 144}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 7}}.
    {loop_rec_end, {f, 139}}.
  {label, 140}.
    {wait, {f, 139}}.

{function, '__bp_tpl_3-t/0-fun-0-', 0, 132}.
  {label, 131}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_3-t/0-fun-0-'}, 0}.
  {label, 132}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 136}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_3', 0, 128}.
  {label, 127}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_3'}, 0}.
  {label, 128}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 132}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, spawn, 1}, 1}.

{function, '__bp_tpl_4-t/1-fun-0-', 1, 164}.
  {label, 163}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_4-t/1-fun-0-'}, 1}.
  {label, 164}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, bp_gate_open}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_4', 1, 160}.
  {label, 159}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_4'}, 1}.
  {label, 160}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 164}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_5-t/2-fun-0-', 2, 171}.
  {label, 170}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_5-t/2-fun-0-'}, 2}.
  {label, 171}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {call_ext, 0, {extfunc, erlang, make_ref, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 175}}.
  {label, 175}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_gate_wait}, {y, 3}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 3}}.
  {label, 176}.
    {loop_rec, {f, 177}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 180}, [{x, 0}]}.
    {test, test_arity, {f, 180}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 180}, [{x, 0}, {x, 1}]}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 180}, [{x, 0}, {atom, bp_gate_open}]}.
    remove_message.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 180}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 5}}.
    {loop_rec_end, {f, 176}}.
  {label, 177}.
    {wait_timeout, {f, 176}, {y, 2}}.
    timeout.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_5', 2, 167}.
  {label, 166}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_5'}, 2}.
  {label, 167}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 171}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-allOf/1-fun-0-', 2, 186}.
  {label, 185}.
    {line, [{location, "std@async.erl", 10}]}.
    {func_info, {atom, std@async}, {atom, '-allOf/1-fun-0-'}, 2}.
  {label, 186}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 187}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 188}}.
  {label, 187}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_try'}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
  {label, 188}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-all/1-fun-1-', 2, 194}.
  {label, 193}.
    {line, [{location, "std@async.erl", 11}]}.
    {func_info, {atom, std@async}, {atom, '-all/1-fun-1-'}, 2}.
  {label, 194}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_6---t/1-fun-0--fun-1--fun-2-', 4, 212}.
  {label, 211}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_6---t/1-fun-0--fun-1--fun-2-'}, 4}.
  {label, 212}.
    {allocate, 12, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {'try', {y, 11}, {f, 215}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nth, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {try_end, {y, 11}}.
    {jump, {f, 216}}.
  {label, 215}.
    {try_case, {y, 11}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 9}}.
    {move, {y, 7}, {y, 4}}.
    {move, {y, 8}, {y, 5}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, crash}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 6}}.
    {jump, {f, 217}}.
  {label, 217}.
  {label, 216}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 1}, {y, 2}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_tpl_6--t/1-fun-0--fun-1-', 4, 208}.
  {label, 207}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_6--t/1-fun-0--fun-1-'}, 4}.
  {label, 208}.
    {allocate, 5, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {move, {x, 3}, {y, 2}}.
    {test_heap, {alloc, [{words, 4}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 212}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 3}, {y, 2}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, spawn, 1}, 5}.

{function, '__bp_tpl_6-t/1-fun-0-', 1, 200}.
  {label, 199}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_6-t/1-fun-0-'}, 1}.
  {label, 200}.
    {allocate, 18, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 6}}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 0}}.
    {jump, {f, 204}}.
  {label, 204}.
    {call_ext, 0, {extfunc, erlang, make_ref, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 206}}.
  {label, 206}.
    {test_heap, {alloc, [{words, 3}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 208}, 1, 0, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 6}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, seq, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, seq, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 8}}.
  {label, 220}.
    {move, {y, 8}, {x, 0}}.
    {test, is_nonempty_list, {f, 221}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 10}, {y, 8}}.
    {move, {y, 10}, {y, 0}}.
  {label, 223}.
    {loop_rec, {f, 224}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 227}, [{x, 0}]}.
    {test, test_arity, {f, 227}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 13}}.
    {get_tuple_element, {x, 0}, 1, {y, 14}}.
    {get_tuple_element, {x, 0}, 2, {y, 15}}.
    {move, {y, 13}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {x, 1}]}.
    {move, {y, 14}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {x, 1}]}.
    {move, {y, 15}, {y, 2}}.
    remove_message.
    {move, {y, 2}, {y, 11}}.
    {jump, {f, 226}}.
  {label, 227}.
    {move, nil, {y, 12}}.
    {move, nil, {y, 2}}.
    {move, nil, {y, 13}}.
    {move, nil, {y, 14}}.
    {move, nil, {y, 15}}.
    {loop_rec_end, {f, 223}}.
  {label, 226}.
    {jump, {f, 225}}.
  {label, 224}.
    {wait, {f, 223}}.
  {label, 225}.
    {move, {y, 11}, {x, 0}}.
    {test, is_tuple, {f, 229}, [{x, 0}]}.
    {test, test_arity, {f, 229}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 14}}.
    {get_tuple_element, {x, 0}, 1, {y, 15}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {atom, ok}]}.
    {move, {y, 15}, {y, 3}}.
    {move, {y, 3}, {y, 13}}.
    {jump, {f, 228}}.
  {label, 229}.
    {move, {y, 11}, {x, 0}}.
    {test, is_tuple, {f, 230}, [{x, 0}]}.
    {test, test_arity, {f, 230}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 14}}.
    {get_tuple_element, {x, 0}, 1, {y, 15}}.
    {get_tuple_element, {x, 0}, 2, {y, 16}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 230}, [{x, 0}, {atom, crash}]}.
    {move, {y, 15}, {y, 4}}.
    {move, {y, 16}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, nil, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, raise, 3}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {y, 13}}.
    {jump, {f, 228}}.
  {label, 230}.
    {move, {y, 11}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 228}.
    {test_heap, 2, 0}.
    {put_list, {y, 13}, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {jump, {f, 220}}.
  {label, 221}.
    {move, {y, 8}, {x, 0}}.
    {test, is_nil, {f, 222}, [{x, 0}]}.
    {jump, {f, 219}}.
  {label, 222}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 8}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 219}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 18}.
    return.

{function, '__bp_tpl_6', 1, 196}.
  {label, 195}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_6'}, 1}.
  {label, 196}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 200}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '-timeout/2-fun-2-', 2, 232}.
  {label, 231}.
    {line, [{location, "std@async.erl", 17}]}.
    {func_info, {atom, std@async}, {atom, '-timeout/2-fun-2-'}, 2}.
  {label, 232}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 25}}.
    {deallocate, 2}.
    return.

{function, '-timeout/2-fun-3-', 1, 234}.
  {label, 233}.
    {line, [{location, "std@async.erl", 17}]}.
    {func_info, {atom, std@async}, {atom, '-timeout/2-fun-3-'}, 1}.
  {label, 234}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 23}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_7', 1, 281}.
  {label, 280}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_7'}, 1}.
  {label, 281}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, trunc, 1}, 1}.

{function, '__bp_tpl_8', 1, 283}.
  {label, 282}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_8'}, 1}.
  {label, 283}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, float, 1}, 1}.

{function, '__bp_tpl_9-t/1-fun-0-', 1, 303}.
  {label, 302}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_9-t/1-fun-0-'}, 1}.
  {label, 303}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, -2147483648}, {x, 1}}.
    {test, is_ge, {f, 305}, [{x, 0}, {x, 1}]}.
    {move, {integer, 2147483647}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 305}, [{x, 0}, {x, 1}]}.
    {jump, {f, 306}}.
  {label, 306}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 305}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 308}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit i32">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toI32: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 309}}.
  {label, 308}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 309}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_9', 1, 299}.
  {label, 298}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_9'}, 1}.
  {label, 299}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 303}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_10', 1, 314}.
  {label, 313}.
    {func_info, {atom, std@async}, {atom, '__bp_tpl_10'}, 1}.
  {label, 314}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_print', 1, 318}.
  {label, 317}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, '__bp_print'}, 1}.
  {label, 318}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 322}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 322}.
  {label, 321}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, '-bp_show_top-'}, 1}.
  {label, 322}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 320}}.

{function, '-bp_show_elem-', 1, 324}.
  {label, 323}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, '-bp_show_elem-'}, 1}.
  {label, 324}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 320}}.

{function, '__bp_show', 2, 320}.
  {label, 319}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, '__bp_show'}, 2}.
  {label, 320}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 332}, [{x, 0}]}.
    {test, is_eq, {f, 331}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 331}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 332}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 333}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 324}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 333}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 335}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 334}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 334}, [{x, 0}]}.
    {test, is_ne_exact, {f, 334}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 334}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 334}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 340}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 341}}.
  {label, 340}.
    {test, is_eq_exact, {f, 336}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 341}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 320}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 334}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 324}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 335}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 337}, [{x, 0}]}.
    {test, is_ne_exact, {f, 337}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 337}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 339}, [{x, 0}, {atom, undefined}]}.
  {label, 336}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 326}, 2}.
  {label, 337}.
    {move, {y, 0}, {x, 0}}.
    {test, is_function, {f, 338}, [{x, 0}]}.
    {move, {atom, arity}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, fun_info, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, erlang, integer_to_list, 1}}.
    {test_heap, 4, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {put_list, {literal, <<"fn/">>}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 338}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 339}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 326}.
  {label, 325}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, '__bp_tagged'}, 2}.
  {label, 326}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 342}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 342}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 342}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 343}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 328}, 3}.
  {label, 343}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 328}.
  {label, 327}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, '__bp_render'}, 1}.
  {label, 328}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 344}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 344}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 345}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 345}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 330}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 330}.
  {label, 329}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, '-bp_render_pair-'}, 1}.
  {label, 330}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 320}}.
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

{function, '-bp_stringify-', 1, 347}.
  {label, 346}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, '-bp_stringify-'}, 1}.
  {label, 347}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 348}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 348}.
    {test, is_integer, {f, 349}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 349}.
    {call, 1, {f, 322}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-bp_join-', 2, 316}.
  {label, 315}.
    {line, [{location, "std@async.erl", 22}]}.
    {func_info, {atom, std@async}, {atom, '-bp_join-'}, 2}.
  {label, 316}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 347}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '-bp_field-', 2, 357}.
  {label, 356}.
    {line, [{location, "std@async.erl", 30}]}.
    {func_info, {atom, std@async}, {atom, '-bp_field-'}, 2}.
  {label, 357}.
    {test, is_map, {f, 358}, [{x, 0}]}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext_only, 3, {extfunc, maps, get, 3}}.
  {label, 358}.
    {test, is_tuple, {f, 359}, [{x, 0}]}.
    {bif, element, {f, 361}, [{integer, 1}, {x, 0}], {x, 2}}.
    {test, is_atom, {f, 361}, [{x, 2}]}.
    {test_heap, 4, 3}.
    {put_list, {x, 1}, nil, {x, 3}}.
    {put_list, {x, 0}, {x, 3}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {atom, '__bp_get'}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext_only, 3, {extfunc, erlang, apply, 3}}.
  {label, 359}.
    {test, is_eq_exact, {f, 361}, [{x, 1}, {atom, length}]}.
    {test, is_list, {f, 360}, [{x, 0}]}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    return.
  {label, 360}.
    {test, is_binary, {f, 361}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 361}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '-pauses/2-fun-4-', 2, 368}.
  {label, 367}.
    {line, [{location, "std@async.erl", 33}]}.
    {func_info, {atom, std@async}, {atom, '-pauses/2-fun-4-'}, 2}.
  {label, 368}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 57}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 122}.
  {label, 121}.
    {line, [{location, "std@async.erl", 33}]}.
    {func_info, {atom, std@async}, {atom, '__bp_prim_append'}, 2}.
  {label, 122}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 369}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 369}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@async@@Gate.S
```erlang
{module, std@async@@Gate}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@async@@Gate.erl", 5}]}.
    {func_info, {atom, std@async@@Gate}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, handle}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 6}.
  {label, 5}.
    {line, [{location, "std@async@@Gate.erl", 5}]}.
    {func_info, {atom, std@async@@Gate}, {atom, '__bp_format'}, 1}.
  {label, 6}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"handle">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Gate">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@async@@RetryPolicy.S
```erlang
{module, std@async@@RetryPolicy}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@async@@RetryPolicy.erl", 17}]}.
    {func_info, {atom, std@async@@RetryPolicy}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, maxAttempts}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, initialMillis}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, multiplier}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, maxMillis}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "std@async@@RetryPolicy.erl", 17}]}.
    {func_info, {atom, std@async@@RetryPolicy}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"maxMillis">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"multiplier">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"initialMillis">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"maxAttempts">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"RetryPolicy">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@async@@Probe.S
```erlang
{module, std@async@@Probe}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@async@@Probe.erl", 22}]}.
    {func_info, {atom, std@async@@Probe}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, id}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, label}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "std@async@@Probe.erl", 22}]}.
    {func_info, {atom, std@async@@Probe}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"label">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"id">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Probe">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__doubled', 1}, {'__bp_priv__doubledF', 1}, {'__bp_priv__run', 0}]}.
{attributes, []}.
{labels, 70}.

%% @Async — eager lowering
{function, doubled, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, doubled}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 18}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 18}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@main.bp:2:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 19}.
    {deallocate, 1}.
    return.

%% @Async — eager lowering
{function, doubledF, 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, doubledF}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {float, 2.0}], {x, 0}}.
    {deallocate, 1}.
    return.

%% @Async — eager lowering
{function, run, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, run}, 0}.
  {label, 7}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@async, runAll, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 27}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@async, runAll, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 27}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 7}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 15}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.

{function, '__bp_load_siblings', 0, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, test@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 59}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 17}, 0}.
  {label, 59}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 17}.
    {test, is_nonempty_list, {f, 60}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 61}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 63}}.
  {label, 61}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 62}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 63}}.
  {label, 62}.
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
  {label, 63}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 17}, 2}.
  {label, 60}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '__bp_priv__doubled', 1, 65}.
  {label, 64}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__doubled'}, 1}.
  {label, 65}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__doubledF', 1, 67}.
  {label, 66}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__doubledF'}, 1}.
  {label, 67}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__run', 0, 69}.
  {label, 68}.
    {line, [{location, "test@main.erl", 11}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__run'}, 0}.
  {label, 69}.
    {call_only, 0, {f, 7}}.

{function, '-run/0-fun-0-', 0, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-run/0-fun-0-'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 3}}.
    {deallocate, 0}.
    return.

{function, '-run/0-fun-1-', 0, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-run/0-fun-1-'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {integer, 2}, {x, 0}}.
    {call, 1, {f, 3}}.
    {deallocate, 0}.
    return.

{function, '-run/0-fun-2-', 0, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-run/0-fun-2-'}, 0}.
  {label, 25}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {deallocate, 0}.
    return.

{function, '__bp_print', 1, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 27}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 31}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 29}}.

{function, '-bp_show_elem-', 1, 33}.
  {label, 32}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 33}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 29}}.

{function, '__bp_show', 2, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 29}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 41}, [{x, 0}]}.
    {test, is_eq, {f, 40}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 42}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 44}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 43}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 43}, [{x, 0}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 50}}.
  {label, 49}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 50}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 29}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 46}, [{x, 0}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, undefined}]}.
  {label, 45}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 35}, 2}.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_function, {f, 47}, [{x, 0}]}.
    {move, {atom, arity}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, fun_info, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, erlang, integer_to_list, 1}}.
    {test_heap, 4, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {put_list, {literal, <<"fn/">>}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 48}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 35}.
  {label, 34}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 35}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 51}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 51}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 51}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 37}, 3}.
  {label, 52}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 37}.
  {label, 36}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 37}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 53}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 54}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 39}.
  {label, 38}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 39}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 29}}.
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

{function, '-run/0-fun-3-', 0, 56}.
  {label, 55}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-run/0-fun-3-'}, 0}.
  {label, 56}.
    {allocate, 0, 0}.
    {move, {float, 2.5}, {x, 0}}.
    {call, 1, {f, 5}}.
    {deallocate, 0}.
    return.

{function, '-run/0-fun-4-', 0, 58}.
  {label, 57}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-run/0-fun-4-'}, 0}.
  {label, 58}.
    {allocate, 0, 0}.
    {move, {float, 1.5}, {x, 0}}.
    {call, 1, {f, 5}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
[2, 4, 6]
[3.0, 5.0]
```
