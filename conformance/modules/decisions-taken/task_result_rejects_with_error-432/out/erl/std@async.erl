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
