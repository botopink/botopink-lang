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
