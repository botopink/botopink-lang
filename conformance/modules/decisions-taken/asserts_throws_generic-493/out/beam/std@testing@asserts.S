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
