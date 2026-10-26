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
