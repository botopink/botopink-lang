-module(std@testing@mocks).
-export([eq/1, anyInt/0, anyString/0, atLeastOnce/0, times/1, never/0, 'when'/1, verify/2, raisedText/1, newMock/0, key/1, pushMatcher/2, invoke/4, beginVerify/1, whenCall/0, thenReturnCell/1, thenThrowCell/1, '__bp_priv__userRepo_mock'/0, '__bp_priv__greeter_mock'/0]).

%% behavior string

%%% std/testing/mocks — Mockito-style mocks over a `behavior`: `#[mock]` synthesizes

%%% the double, `when(...)` stubs a return, `verify(...)` checks call counts

%%% (1.0.10-beta front 01-std, `onze-migration.md`; decision 71).

%%% 

%%% Lifted 100 % from the retired `onze` mocking library (`botopink/onze`, tag

%%% `mocking-lib-final`). The Erlang templates are the old ones; the Node

%%% templates inline what `onze.mjs` held as module globals. Only three things

%%% changed with the move: the module name, the two renamed cells (`whenCall`,

%%% `thenReturnCell`, `thenThrowCell` — `when`/`thenReturn`/`thenThrow` are the

%%% public surface's names), and the private state keys (`'__onze_*'` →

%%% `'__bp_mocks_*'`, `"onze#"` → `"mock#"`, `onze.verify:` → `mocks.verify:`).

%%% Semantics are byte-for-byte the old ones, asserted by the eight tests at the

%%% foot of this file — the old `test/onze_test.bp`, re-spelled.

%%% 

%%% **No sidecar.** `onze.mjs` existed because the recorder needs mutable,

%%% identity-based state; the Erlang side never needed one (its tables live in

%%% the process dictionary, inside each template). The Node side does the same

%%% with a lazily created cell on `globalThis`, the shape

%%% `emilia/modules/emilia/src/emilia.bp:24` uses for its stylesheet:

%%% 

%%%     globalThis.__bp_mocks ||= { counter, calls, stubs, pending,

%%%                                 pendingStub, verifyMode }

%%% 

%%% One cell per host process, shared by every mock in the run; mock ids are

%%% unique per `newMock()`, so two mocks never collide in the shared tables.

%%% `libs/std/src/sidecars/` therefore still holds exactly one file

%%% (`random.mjs`).

%%% 

%%% **STD-001.** Unlike `asserts`, the eight cells here are

%%% `pub declare fn`: the code `#[mock]` adds to the CONSUMER's behavior calls

%%% `invoke`/`key`/`newMock`, so they have to be exported. They carry Node and

%%% Erlang templates only, so `import {mocks} from "std"` is refused on beam and

%%% wasm — honestly, since `botopink test` runs on neither.

%%% 

%%% Two layers, as in the old library:

%%%   • the RUNTIME (matchers / `when` / `verify` / the host cells) — ordinary

%%%     botopink over the cells below.

%%%   • the SYNTHESIS (`#[mock]`) — a comptime decorator that reflects a

%%%     behavior's methods through the declaration handle (`syntax decl: unknown`) and gives the behavior the mock type

%%%     `Xxx.Mock` and the factory `Xxx.mock()` (decision 216). The compiler core learns nothing about mocking

%%%     (no lib-specific surface in core); every rule here is botopink.

%% import failure

% ── host cells (the one mutable seam) ────────────────────────────────────────

% 

% Node: one lazily created object on `globalThis`. Erlang: the same six tables

% in the process dictionary, one key each. The two have to be kept in step by

% hand — that is the reason there is one copy of this module and not one per

% `<lib>-test` submodule (`onze-migration.md` § Where the mocking surface goes).

% A fresh, unique mock id. `"mock#<n>"`, `n` counted per host process.

%% external fn newMock -> erlang template
newMock() ->
    (fun() -> OzN__ = case get('__bp_mocks_counter') of undefined -> 1; OzC__ -> OzC__ + 1 end, put('__bp_mocks_counter', OzN__), iolist_to_binary([<<"mock#">>, integer_to_binary(OzN__)]) end)().

% Canonical, comparable key for any argument value (string/int/array/record).

% The same cell `asserts.canonical` carries privately, for the same reason: two

% values that render the same on a host are structurally equal there. Two

% copies rather than one, because a std module does not import another.

%% external fn key -> erlang template
key(V) ->
    iolist_to_binary(io_lib:format("~0tp", [V])).

% Push one matcher descriptor onto the pending stack that the next mock call

% consumes. `kind` is `"eq"` (match `k`) or `"any"` (match anything).

%% external fn pushMatcher -> erlang template
pushMatcher(Kind, K) ->
    (fun(OzK__, OzV__) -> OzP__ = case get('__bp_mocks_pending') of undefined -> []; OzL__ -> OzL__ end, put('__bp_mocks_pending', OzP__ ++ [{OzK__, OzV__}]), 0 end)(Kind, K).

% The single entry every synthesized mock method calls: record the invocation

% (or, in verify mode, assert its count), then answer the matching stub value —

% or `def`, the caller-supplied type-default of the method's return type. A

% matched `thenThrow` stub raises here, on the host.

%% external fn invoke -> erlang template
invoke(Id, Method, Keys, Def) ->
    (fun(OzId__, OzM__, OzKs__, OzDef__) -> OzP__ = case get('__bp_mocks_pending') of undefined -> []; OzL1__ -> OzL1__ end, put('__bp_mocks_pending', []), OzMs__ = case length(OzP__) =:= length(OzKs__) of true -> OzP__; false -> [{<<"eq">>, OzK__} || OzK__ <- OzKs__] end, OzMatch__ = fun(OzMx__, OzKx__) -> length(OzMx__) =:= length(OzKx__) andalso lists:all(fun({{OzKind__, OzKey__}, OzArg__}) -> OzKind__ =:= <<"any">> orelse OzKey__ =:= OzArg__ end, lists:zip(OzMx__, OzKx__)) end, OzCalls__ = case get('__bp_mocks_calls') of undefined -> []; OzL2__ -> OzL2__ end, case erase('__bp_mocks_verify') of undefined -> put('__bp_mocks_calls', OzCalls__ ++ [{OzId__, OzM__, OzKs__, OzMs__}]), OzHit__ = [OzSt__ || {OzSId__, OzSM__, OzSMs__, _, _} = OzSt__ <- lists:reverse(case get('__bp_mocks_stubs') of undefined -> []; OzL3__ -> OzL3__ end), OzSId__ =:= OzId__, OzSM__ =:= OzM__, OzMatch__(OzSMs__, OzKs__)], case OzHit__ of [] -> OzDef__; [{_, _, _, return, OzRv__} | _] -> OzRv__; [{_, _, _, throw, OzMsg__} | _] -> erlang:error(OzMsg__) end; OzSpec__ -> OzCount__ = length([x || {OzCId__, OzCM__, OzCKs__, _} <- OzCalls__, OzCId__ =:= OzId__, OzCM__ =:= OzM__, OzMatch__(OzMs__, OzCKs__)]), case (case OzSpec__ of -1 -> OzCount__ >= 1; _ -> OzCount__ =:= OzSpec__ end) of true -> OzDef__; false -> erlang:error(iolist_to_binary([<<"mocks.verify: ">>, OzM__, <<" - expected ">>, case OzSpec__ of -1 -> <<"at least 1">>; _ -> [<<"exactly ">>, integer_to_binary(OzSpec__)] end, <<" matching call(s), got ">>, integer_to_binary(OzCount__)])) end end end)(Id, Method, Keys, Def).

% Arm verify mode: the next mock call asserts its count instead of recording.

%% external fn beginVerify -> erlang template
beginVerify(Spec) ->
    (fun(OzS__) -> put('__bp_mocks_verify', OzS__), 0 end)(Spec).

% Pop the call `when(mock.m(args))` just recorded inside its own argument and

% hold it as the stub target the builder writes to. Named `whenCall` because

% `when` is the public function's name.

%% external fn whenCall -> erlang template
whenCall() ->
    (fun() -> case case get('__bp_mocks_calls') of undefined -> []; OzL__ -> OzL__ end of [] -> put('__bp_mocks_pending_stub', undefined); OzCs__ -> {OzId__, OzM__, _, OzMs__} = lists:last(OzCs__), put('__bp_mocks_calls', lists:droplast(OzCs__)), put('__bp_mocks_pending_stub', {OzId__, OzM__, OzMs__}) end, 0 end)().

% Write a `return` action for the pending stub target. Named `thenReturnCell`

% because `thenReturn` is `Stub`'s method.

%% external fn thenReturnCell -> erlang template
thenReturnCell(V) ->
    (fun(OzV__) -> case get('__bp_mocks_pending_stub') of undefined -> ok; {OzId__, OzM__, OzMs__} -> put('__bp_mocks_stubs', case get('__bp_mocks_stubs') of undefined -> []; OzL__ -> OzL__ end ++ [{OzId__, OzM__, OzMs__, return, OzV__}]) end, put('__bp_mocks_pending_stub', undefined), 0 end)(V).

% Write a `throw` action for the pending stub target. Named `thenThrowCell`

% because `thenThrow` is `Stub`'s method.

%% external fn thenThrowCell -> erlang template
thenThrowCell(Msg) ->
    (fun(OzV__) -> case get('__bp_mocks_pending_stub') of undefined -> ok; {OzId__, OzM__, OzMs__} -> put('__bp_mocks_stubs', case get('__bp_mocks_stubs') of undefined -> []; OzL__ -> OzL__ end ++ [{OzId__, OzM__, OzMs__, throw, OzV__}]) end, put('__bp_mocks_pending_stub', undefined), 0 end)(Msg).

% ── argument matchers ────────────────────────────────────────────────────────

% 

% A matcher answers a dummy value of the right type (so `mock.m(matcher)`

% type-checks) and pushes a descriptor onto the host matcher stack. When the

% mock method runs, the stack decides how each argument is matched; a literal

% argument (no matcher) means exact equality on its key. Matchers compose

% across parameters — all of them, or none.

% 

% These three are MATCHERS, not assertions: they push and return, they never

% answer a `Result`. They stay here rather than joining `std/asserts`

% (`onze-migration.md` § Where the assertion surface goes — the old library

% exported no assertion at all).

% `eq(v)` — match exactly `v` (the default for a literal argument, made explicit).

eq(V) ->
    _m = (fun(OzK__, OzV__) -> OzP__ = case get('__bp_mocks_pending') of undefined -> []; OzL__ -> OzL__ end, put('__bp_mocks_pending', OzP__ ++ [{OzK__, OzV__}]), 0 end)(<<"eq">>, iolist_to_binary(io_lib:format("~0tp", [V]))),
    V.

% `anyInt()` — match any `i32` argument. A fully generic `any<T>()` would need

% a per-type default it cannot produce (`onze-migration.md` § Language gaps),

% so the concrete matchers ship per type; add one where a type needs it.

anyInt() ->
    _m = (fun(OzK__, OzV__) -> OzP__ = case get('__bp_mocks_pending') of undefined -> []; OzL__ -> OzL__ end, put('__bp_mocks_pending', OzP__ ++ [{OzK__, OzV__}]), 0 end)(<<"any">>, <<"*">>),
    0.

% `anyString()` — match any `string` argument.

anyString() ->
    _m = (fun(OzK__, OzV__) -> OzP__ = case get('__bp_mocks_pending') of undefined -> []; OzL__ -> OzL__ end, put('__bp_mocks_pending', OzP__ ++ [{OzK__, OzV__}]), 0 end)(<<"any">>, <<"*">>),
    <<"">>.

% ── verification specs ───────────────────────────────────────────────────────

% 

% Encoded as an i32: -1 = at least once, n >= 0 = exactly n (0 = never).

% At least one matching call.

atLeastOnce() ->
    (-1).

% Exactly `n` matching calls.

times(N) ->
    N.

% No matching call at all — `times(0)`, spelled.

never() ->
    0.

% ── stubbing: when(...).thenReturn / thenThrow ───────────────────────────────

% 

% `when(mock.m(args))` evaluates `mock.m(args)` first — that records the call

% and captures it, with its matchers, as the pending stub target. The returned

% builder then writes the action. The last stub registered wins on overlap.

% The `when(...)` builder. `tag` carries nothing: the captured call lives in

% the host cell, and a record needs at least one field.

%% type Stub: tag

% Open a stub over the call just made in the argument position.

'when'(Value) ->
    _w = (fun() -> case case get('__bp_mocks_calls') of undefined -> []; OzL__ -> OzL__ end of [] -> put('__bp_mocks_pending_stub', undefined); OzCs__ -> {OzId__, OzM__, _, OzMs__} = lists:last(OzCs__), put('__bp_mocks_calls', lists:droplast(OzCs__)), put('__bp_mocks_pending_stub', {OzId__, OzM__, OzMs__}) end, 0 end)(),
    {std@testing@mocks@@Stub, <<"">>}.

% ── verification entry ───────────────────────────────────────────────────────

% 

% `verify(mock, spec).m(args)` runs `m` in verify mode: instead of recording,

% the synthesized method asserts the count of matching prior calls against

% `spec` and raises when it disagrees. The two-argument form is uniform —

% botopink has neither fn overloading nor default parameters:

%   verify(repo, atLeastOnce()).all();

%   verify(repo, times(1)).find(eq(7));

%   verify(repo, never()).find(eq(99));

verify(Mock, Spec) ->
    _v = (fun(OzS__) -> put('__bp_mocks_verify', OzS__), 0 end)(Spec),
    Mock.

% ── mock synthesis (`#[mock]`) ───────────────────────────────────────────────

% 

% A comptime annotation processor: reflect the annotated behavior's methods through

% the declaration handle (`syntax decl: unknown`) and give the behavior (a) the associated type `<Name>.Mock(__id:

% string)`, which implements `<Name>` and funnels every method through

% `invoke` (`decl.addType`), and (b) the associated fn `<Name>.mock() -> <Name>`,

% the factory (`decl.addMember`) — decision 216. The compiler core provides only the protocol (recognise →

% reflect → run the body); every rule below is botopink. The generated method

% records its call and answers the stub value, or the per-return-type default

% (`""` / `false` / `0` / `[]`).

% 

% The type and the factory are declared in the module that hosts the annotated

% behavior, so the names their text writes must resolve THERE. Inside this module they are the

% bare `invoke`, `key` and `newMock`; in a consumer they are reached through

% the handle the consumer imported this module under, which is the prefix of

% the annotation that fired: `import {testing.mocks} from "std"` and

% `#[mocks.mock]` emit `mocks.invoke(…)`, an alias `#[m.mock]` emits

% `m.invoke(…)`. A std module's decorators are registered under

% `<handle>.<fn>` by the import (`comptime/infer.zig`

% `registerStdImportDecorators`); a leaf import of `mock` is refused, since it

% would leave the emitted code no handle.

% 

% Comptime-body constraints (`libs/std/AGENTS.md`, `reference` gotchas): `if` is

% an expression (needs `else`, `;`-terminated branches); a bare `if {…}`

% statement is only legal as the last statement in a block; and the body cannot

% call sibling fns — only this one is lowered into the decorator eval script —

% so the return-type default is inlined rather than factored out.

% Internal, test scaffolding: the text a body raised, `""` when it answered —

% the shape of `asserts.throwsWith`'s own cell (`hash.panicText` is the same).

% A std module does not import the harness: an import of `testing.asserts`

% links its host-only `canonical` into every program that reaches `mocks`, and

% the wasm backend refuses each of them.

raisedText(Body) ->
    case std@failure:attempt(Body) of
        {ok, _} ->
            <<"">>;
        {error, F} ->
            '__bp_field'(F, message)
    end.

% ── tests ────────────────────────────────────────────────────────────────────

% The eight tests of the retired `repository/onze/test/onze_test.bp`, re-spelled

% against this module. They drive the whole surface end to end: `#[mock]`

% synthesizes the double from the behavior, a mock records its calls, `when(…)`

% stubs returns, the matchers pick the right stub, and `verify(…)` checks

% counts. Arrays are compared with `.join(",")` because `==` on arrays is

% reference equality on commonJS (a language trait, not a mocking one).

%% behavior UserRepo

userRepo_mock() ->
    {std@testing@mocks@@UserRepo__Mock, (fun() -> OzN__ = case get('__bp_mocks_counter') of undefined -> 1; OzC__ -> OzC__ + 1 end, put('__bp_mocks_counter', OzN__), iolist_to_binary([<<"mock#">>, integer_to_binary(OzN__)]) end)()}.

% A unit under test that depends only on the behavior.

%% type UserService: repo










% `anyString()` is the ninth test: the old suite covered it from the example

% app rather than from `test/onze_test.bp`, and the inventory asks every row to

% be exercised where it now lives.

%% behavior Greeter

greeter_mock() ->
    {std@testing@mocks@@Greeter__Mock, (fun() -> OzN__ = case get('__bp_mocks_counter') of undefined -> 1; OzC__ -> OzC__ + 1 end, put('__bp_mocks_counter', OzN__), iolist_to_binary([<<"mock#">>, integer_to_binary(OzN__)]) end)()}.


% The two rows the old suite recorded as limitations, carried here unchanged

% (`onze-migration.md` § Language gaps holds the proposed surfaces):

% 

% LIMITATION: a `thenThrow` stub matched at run time raises a HOST throw from

% `invoke`. botopink's `try … catch …` only unwraps an `Result` produced by a

% `-> Result` fn — it does not catch a host throw from a plain (non-effect)

% method call, so `try svc.name(0) catch …` does not compile: the callee is not

% `-> Result`. Modelling the throw as an effect (the synthesized method

% answering `Result<R, string>`) is a design change, not a port. The covered

% surface is what the test above asserts: a matched `thenThrow` raises, and a

% non-matching call answers the default. A caller that must observe the raise

% uses `asserts.throws` from its own module, where `std/asserts` is importable.

% 

% LIMITATION: there is no fully generic `any<T>()` matcher and no argument

% captor. `any<T>()` needs a per-type default it cannot synthesize, so the

% concrete `anyInt()` / `anyString()` ship instead (both exercised above, and

% composed independently across parameters); a captor needs a ninth host cell

% that records and reads back the captured argument.

%% type UserRepo__Mock: __id

%% type Greeter__Mock: __id

'__bp_field'(V, F) when erlang:is_map(V) -> maps:get(F, V);
'__bp_field'(V, F) -> erlang:apply(erlang:element(1, V), '__bp_get', [V, F]).

'__bp_priv__userRepo_mock'() -> userRepo_mock().

'__bp_priv__greeter_mock'() -> greeter_mock().
