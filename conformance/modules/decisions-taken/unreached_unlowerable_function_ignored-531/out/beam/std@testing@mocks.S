{module, std@testing@mocks}.
{exports, [{newMock, 0}, {key, 1}, {pushMatcher, 2}, {invoke, 4}, {beginVerify, 1}, {whenCall, 0}, {thenReturnCell, 1}, {thenThrowCell, 1}, {eq, 1}, {anyInt, 0}, {anyString, 0}, {atLeastOnce, 0}, {times, 1}, {never, 0}, {'when', 1}, {verify, 2}, {raisedText, 1}, {'__bp_priv__Greeter_mock', 0}, {'__bp_priv__UserRepo_mock', 0}]}.
{attributes, []}.
{labels, 208}.
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
% ── host cells (the one mutable seam) ────────────────────────────────────────
% 
% Node: one lazily created object on `globalThis`. Erlang: the same six tables
% in the process dictionary, one key each. The two have to be kept in step by
% hand — that is the reason there is one copy of this module and not one per
% `<lib>-test` submodule (`onze-migration.md` § Where the mocking surface goes).
% A fresh, unique mock id. `"mock#<n>"`, `n` counted per host process.

{function, newMock, 0, 38}.
  {label, 37}.
    {line, [{location, "std@testing@mocks.erl", 1}]}.
    {func_info, {atom, std@testing@mocks}, {atom, newMock}, 0}.
  {label, 38}.
    {call_only, 0, {f, 25}}.
% Canonical, comparable key for any argument value (string/int/array/record).
% The same cell `asserts.canonical` carries privately, for the same reason: two
% values that render the same on a host are structurally equal there. Two
% copies rather than one, because a std module does not import another.

{function, key, 1, 42}.
  {label, 41}.
    {line, [{location, "std@testing@mocks.erl", 2}]}.
    {func_info, {atom, std@testing@mocks}, {atom, key}, 1}.
  {label, 42}.
    {call_only, 1, {f, 40}}.
% Push one matcher descriptor onto the pending stack that the next mock call
% consumes. `kind` is `"eq"` (match `k`) or `"any"` (match anything).

{function, pushMatcher, 2, 57}.
  {label, 56}.
    {line, [{location, "std@testing@mocks.erl", 3}]}.
    {func_info, {atom, std@testing@mocks}, {atom, pushMatcher}, 2}.
  {label, 57}.
    {call_only, 2, {f, 44}}.
% The single entry every synthesized mock method calls: record the invocation
% (or, in verify mode, assert its count), then answer the matching stub value —
% or `def`, the caller-supplied type-default of the method's return type. A
% matched `thenThrow` stub raises here, on the host.

{function, invoke, 4, 138}.
  {label, 137}.
    {line, [{location, "std@testing@mocks.erl", 4}]}.
    {func_info, {atom, std@testing@mocks}, {atom, invoke}, 4}.
  {label, 138}.
    {call_only, 4, {f, 59}}.
% Arm verify mode: the next mock call asserts its count instead of recording.

{function, beginVerify, 1, 146}.
  {label, 145}.
    {line, [{location, "std@testing@mocks.erl", 5}]}.
    {func_info, {atom, std@testing@mocks}, {atom, beginVerify}, 1}.
  {label, 146}.
    {call_only, 1, {f, 140}}.
% Pop the call `when(mock.m(args))` just recorded inside its own argument and
% hold it as the stub target the builder writes to. Named `whenCall` because
% `when` is the public function's name.

{function, whenCall, 0, 164}.
  {label, 163}.
    {line, [{location, "std@testing@mocks.erl", 6}]}.
    {func_info, {atom, std@testing@mocks}, {atom, whenCall}, 0}.
  {label, 164}.
    {call_only, 0, {f, 148}}.
% Write a `return` action for the pending stub target. Named `thenReturnCell`
% because `thenReturn` is `Stub`'s method.

{function, thenReturnCell, 1, 179}.
  {label, 178}.
    {line, [{location, "std@testing@mocks.erl", 7}]}.
    {func_info, {atom, std@testing@mocks}, {atom, thenReturnCell}, 1}.
  {label, 179}.
    {call_only, 1, {f, 166}}.
% Write a `throw` action for the pending stub target. Named `thenThrowCell`
% because `thenThrow` is `Stub`'s method.

{function, thenThrowCell, 1, 194}.
  {label, 193}.
    {line, [{location, "std@testing@mocks.erl", 8}]}.
    {func_info, {atom, std@testing@mocks}, {atom, thenThrowCell}, 1}.
  {label, 194}.
    {call_only, 1, {f, 181}}.
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

{function, eq, 1, 3}.
  {label, 2}.
    {line, [{location, "std@testing@mocks.erl", 9}]}.
    {func_info, {atom, std@testing@mocks}, {atom, eq}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"eq">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 40}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 44}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.
% `anyInt()` — match any `i32` argument. A fully generic `any<T>()` would need
% a per-type default it cannot produce (`onze-migration.md` § Language gaps),
% so the concrete matchers ship per type; add one where a type needs it.

{function, anyInt, 0, 5}.
  {label, 4}.
    {line, [{location, "std@testing@mocks.erl", 10}]}.
    {func_info, {atom, std@testing@mocks}, {atom, anyInt}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, <<"any">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"*">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 44}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% `anyString()` — match any `string` argument.

{function, anyString, 0, 7}.
  {label, 6}.
    {line, [{location, "std@testing@mocks.erl", 11}]}.
    {func_info, {atom, std@testing@mocks}, {atom, anyString}, 0}.
  {label, 7}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, <<"any">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"*">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 44}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {deallocate, 1}.
    return.
% ── verification specs ───────────────────────────────────────────────────────
% 
% Encoded as an i32: -1 = at least once, n >= 0 = exactly n (0 = never).
% At least one matching call.

{function, atLeastOnce, 0, 9}.
  {label, 8}.
    {line, [{location, "std@testing@mocks.erl", 12}]}.
    {func_info, {atom, std@testing@mocks}, {atom, atLeastOnce}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 0}.
    return.
% Exactly `n` matching calls.

{function, times, 1, 11}.
  {label, 10}.
    {line, [{location, "std@testing@mocks.erl", 13}]}.
    {func_info, {atom, std@testing@mocks}, {atom, times}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% No matching call at all — `times(0)`, spelled.

{function, never, 0, 13}.
  {label, 12}.
    {line, [{location, "std@testing@mocks.erl", 14}]}.
    {func_info, {atom, std@testing@mocks}, {atom, never}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
% ── stubbing: when(...).thenReturn / thenThrow ───────────────────────────────
% 
% `when(mock.m(args))` evaluates `mock.m(args)` first — that records the call
% and captures it, with its matchers, as the pending stub target. The returned
% builder then writes the action. The last stub registered wins on overlap.
% The `when(...)` builder. `tag` carries nothing: the captured call lives in
% the host cell, and a record needs at least one field.
% Open a stub over the call just made in the argument position.

{function, 'when', 1, 15}.
  {label, 14}.
    {line, [{location, "std@testing@mocks.erl", 17}]}.
    {func_info, {atom, std@testing@mocks}, {atom, 'when'}, 1}.
  {label, 15}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 148}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@testing@mocks@@Stub}, {x, 0}]}}.
    {deallocate, 2}.
    return.
% ── verification entry ───────────────────────────────────────────────────────
% 
% `verify(mock, spec).m(args)` runs `m` in verify mode: instead of recording,
% the synthesized method asserts the count of matching prior calls against
% `spec` and raises when it disagrees. The two-argument form is uniform —
% botopink has neither fn overloading nor default parameters:
%   verify(repo, atLeastOnce()).all();
%   verify(repo, times(1)).find(eq(7));
%   verify(repo, never()).find(eq(99));

{function, verify, 2, 17}.
  {label, 16}.
    {line, [{location, "std@testing@mocks.erl", 18}]}.
    {func_info, {atom, std@testing@mocks}, {atom, verify}, 2}.
  {label, 17}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 140}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 3}.
    return.
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

{function, raisedText, 1, 19}.
  {label, 18}.
    {line, [{location, "std@testing@mocks.erl", 19}]}.
    {func_info, {atom, std@testing@mocks}, {atom, raisedText}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {test, is_tagged_tuple, {f, 196}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 195}}.
  {label, 196}.
    {test, is_tagged_tuple, {f, 197}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 199}}.
    {jump, {f, 195}}.
  {label, 197}.
    {case_end, {x, 0}}.
  {label, 195}.
    {deallocate, 2}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────
% The eight tests of the retired `repository/onze/test/onze_test.bp`, re-spelled
% against this module. They drive the whole surface end to end: `#[mock]`
% synthesizes the double from the behavior, a mock records its calls, `when(…)`
% stubs returns, the matchers pick the right stub, and `verify(…)` checks
% counts. Arrays are compared with `.join(",")` because `==` on arrays is
% reference equality on commonJS (a language trait, not a mocking one).

{function, 'UserRepo_mock', 0, 21}.
  {label, 20}.
    {line, [{location, "std@testing@mocks.erl", 20}]}.
    {func_info, {atom, std@testing@mocks}, {atom, 'UserRepo_mock'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {call, 0, {f, 25}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@testing@mocks@@UserRepo__Mock}, {x, 0}]}}.
    {deallocate, 0}.
    return.
% A unit under test that depends only on the behavior.
% `anyString()` is the ninth test: the old suite covered it from the example
% app rather than from `test/onze_test.bp`, and the inventory asks every row to
% be exercised where it now lives.

{function, 'Greeter_mock', 0, 23}.
  {label, 22}.
    {line, [{location, "std@testing@mocks.erl", 23}]}.
    {func_info, {atom, std@testing@mocks}, {atom, 'Greeter_mock'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {call, 0, {f, 25}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@testing@mocks@@Greeter__Mock}, {x, 0}]}}.
    {deallocate, 0}.
    return.
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

{function, '__bp_priv__Greeter_mock', 0, 205}.
  {label, 204}.
    {line, [{location, "std@testing@mocks.erl", 27}]}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_priv__Greeter_mock'}, 0}.
  {label, 205}.
    {call_only, 0, {f, 23}}.

{function, '__bp_priv__UserRepo_mock', 0, 207}.
  {label, 206}.
    {line, [{location, "std@testing@mocks.erl", 28}]}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_priv__UserRepo_mock'}, 0}.
  {label, 207}.
    {call_only, 0, {f, 21}}.

{function, '__bp_tpl_0-t/0-fun-0-', 0, 29}.
  {label, 28}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_0-t/0-fun-0-'}, 0}.
  {label, 29}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {atom, '__bp_mocks_counter'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, {atom, undefined}]}.
    {move, {integer, 1}, {y, 2}}.
    {jump, {f, 32}}.
  {label, 33}.
    {move, {y, 1}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 2}}.
    {jump, {f, 32}}.
  {label, 32}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 36}}.
  {label, 36}.
    {move, {atom, '__bp_mocks_counter'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {put_list, {literal, <<"mock#">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 4}.

{function, '__bp_tpl_0', 0, 25}.
  {label, 24}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_0'}, 0}.
  {label, 25}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1', 1, 40}.
  {label, 39}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_1'}, 1}.
  {label, 40}.
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

{function, '__bp_tpl_2-t/2-fun-0-', 2, 48}.
  {label, 47}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 48}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {atom, '__bp_mocks_pending'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 4}}.
    {jump, {f, 51}}.
  {label, 52}.
    {move, {y, 3}, {y, 0}}.
    {move, {y, 0}, {y, 4}}.
    {jump, {f, 51}}.
  {label, 51}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 55}}.
  {label, 55}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 2, 0}.
    {put_list, {y, 3}, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {atom, '__bp_mocks_pending'}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_2', 2, 44}.
  {label, 43}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_2'}, 2}.
  {label, 44}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_3---t/4-fun-0--fun-1--fun-2-', 1, 88}.
  {label, 87}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_3---t/4-fun-0--fun-1--fun-2-'}, 1}.
  {label, 88}.
    {allocate, 11, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 90}, [{x, 0}]}.
    {test, test_arity, {f, 90}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 90}, [{x, 0}]}.
    {test, test_arity, {f, 90}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 5}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"any">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 91}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 8}}.
    {jump, {f, 93}}.
  {label, 91}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {y, 8}}.
    {jump, {f, 93}}.
  {label, 92}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 9}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 93}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 90}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 11}.
    {jump, {f, 87}}.

{function, '__bp_tpl_3--t/4-fun-0--fun-1-', 2, 81}.
  {label, 80}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_3--t/4-fun-0--fun-1-'}, 2}.
  {label, 81}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 88}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, zip, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, all, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 86}}.
  {label, 84}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 85}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 86}}.
  {label, 85}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 86}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_3-t/4-fun-0-', 4, 63}.
  {label, 62}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_3-t/4-fun-0-'}, 4}.
  {label, 63}.
    {allocate, 20, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 9}}.
    {move, {x, 3}, {y, 10}}.
    {move, {atom, '__bp_mocks_pending'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 12}}.
    {jump, {f, 66}}.
  {label, 67}.
    {move, {y, 11}, {y, 0}}.
    {move, {y, 0}, {y, 12}}.
    {jump, {f, 66}}.
  {label, 66}.
    {move, {y, 12}, {y, 0}}.
    {jump, {f, 70}}.
  {label, 70}.
    {move, {atom, '__bp_mocks_pending'}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 72}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {y, 12}}.
    {jump, {f, 71}}.
  {label, 72}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, false}]}.
    {move, nil, {y, 13}}.
    {move, {y, 9}, {y, 14}}.
  {label, 75}.
    {move, {y, 14}, {x, 0}}.
    {test, is_nonempty_list, {f, 76}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 15}, {y, 14}}.
    {move, {y, 15}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"eq">>}, {y, 0}]}}.
    {move, {x, 0}, {y, 16}}.
    {test_heap, 2, 0}.
    {put_list, {y, 16}, {y, 13}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {jump, {f, 75}}.
  {label, 76}.
    {move, {y, 14}, {x, 0}}.
    {test, is_nil, {f, 77}, [{x, 0}]}.
    {jump, {f, 74}}.
  {label, 77}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 14}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 74}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 12}}.
    {jump, {f, 71}}.
  {label, 73}.
    {move, {y, 11}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 71}.
    {move, {y, 12}, {y, 0}}.
    {jump, {f, 79}}.
  {label, 79}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 81}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 1}}.
    {jump, {f, 95}}.
  {label, 95}.
    {move, {atom, '__bp_mocks_calls'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 97}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 12}}.
    {jump, {f, 96}}.
  {label, 97}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 2}, {y, 12}}.
    {jump, {f, 96}}.
  {label, 96}.
    {move, {y, 12}, {y, 2}}.
    {jump, {f, 100}}.
  {label, 100}.
    {move, {atom, '__bp_mocks_verify'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_eq_exact, {f, 102}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 7}, {y, 8}, {y, 9}, {y, 0}]}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 2, 0}.
    {put_list, {y, 12}, nil, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {atom, '__bp_mocks_calls'}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, nil, {y, 12}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 105}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 15}}.
    {jump, {f, 104}}.
  {label, 105}.
    {move, {y, 14}, {y, 3}}.
    {move, {y, 3}, {y, 15}}.
    {jump, {f, 104}}.
  {label, 104}.
    {move, {y, 15}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 13}}.
  {label, 107}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nonempty_list, {f, 108}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 15}, {y, 13}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_tuple, {f, 107}, [{x, 0}]}.
    {test, test_arity, {f, 107}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 16}}.
    {get_tuple_element, {x, 0}, 1, {y, 17}}.
    {get_tuple_element, {x, 0}, 2, {y, 18}}.
    {move, {y, 16}, {y, 4}}.
    {move, {y, 17}, {y, 3}}.
    {move, {y, 18}, {y, 5}}.
    {move, {y, 15}, {y, 6}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test, is_eq_exact, {f, 107}, [{x, 0}, {x, 1}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test, is_eq_exact, {f, 107}, [{x, 0}, {x, 1}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 110}, [{x, 0}, {atom, true}]}.
    {jump, {f, 112}}.
  {label, 110}.
    {move, {y, 19}, {x, 0}}.
    {test, is_eq_exact, {f, 111}, [{x, 0}, {atom, false}]}.
    {jump, {f, 107}}.
  {label, 111}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 19}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 112}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 107}}.
  {label, 108}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nil, {f, 109}, [{x, 0}]}.
    {jump, {f, 103}}.
  {label, 109}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 103}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 3}}.
    {jump, {f, 114}}.
  {label, 114}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 116}, [{x, 0}, nil]}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 116}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 117}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 117}, [{x, 0}]}.
    {test, test_arity, {f, 117}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {get_tuple_element, {x, 0}, 4, {y, 15}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{x, 0}, {atom, return}]}.
    {move, {y, 15}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 117}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 118}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 12}, {y, 13}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 118}, [{x, 0}]}.
    {test, test_arity, {f, 118}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 3, {y, 14}}.
    {get_tuple_element, {x, 0}, 4, {y, 15}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, throw}]}.
    {move, {y, 15}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 20}.
  {label, 118}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 102}.
    {move, {y, 11}, {y, 3}}.
    {move, nil, {y, 12}}.
    {move, {y, 2}, {y, 13}}.
  {label, 121}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nonempty_list, {f, 122}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 14}, {y, 13}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_tuple, {f, 121}, [{x, 0}]}.
    {test, test_arity, {f, 121}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 15}}.
    {get_tuple_element, {x, 0}, 1, {y, 16}}.
    {get_tuple_element, {x, 0}, 2, {y, 17}}.
    {move, {y, 15}, {y, 2}}.
    {move, {y, 16}, {y, 4}}.
    {move, {y, 17}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test, is_eq_exact, {f, 121}, [{x, 0}, {x, 1}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test, is_eq_exact, {f, 121}, [{x, 0}, {x, 1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, true}]}.
    {jump, {f, 126}}.
  {label, 124}.
    {move, {y, 18}, {x, 0}}.
    {test, is_eq_exact, {f, 125}, [{x, 0}, {atom, false}]}.
    {jump, {f, 121}}.
  {label, 125}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_filter}, {y, 18}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 126}.
    {test_heap, 2, 0}.
    {put_list, {atom, x}, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {jump, {f, 121}}.
  {label, 122}.
    {move, {y, 13}, {x, 0}}.
    {test, is_nil, {f, 123}, [{x, 0}]}.
    {jump, {f, 120}}.
  {label, 123}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 13}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 120}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 0}}.
    {jump, {f, 128}}.
  {label, 128}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 130}, [{x, 0}, {integer, -1}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 12}}.
    {jump, {f, 129}}.
  {label, 130}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {y, 12}}.
    {jump, {f, 129}}.
  {label, 129}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 133}, [{x, 0}, {atom, true}]}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 20}.
    return.
  {label, 133}.
    {move, {y, 12}, {x, 0}}.
    {test, is_eq_exact, {f, 134}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 136}, [{x, 0}, {integer, -1}]}.
    {move, {literal, <<"at least 1">>}, {y, 13}}.
    {jump, {f, 135}}.
  {label, 136}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 4, 0}.
    {put_list, {y, 14}, nil, {x, 0}}.
    {put_list, {literal, <<"exactly ">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {y, 13}}.
    {jump, {f, 135}}.
  {label, 135}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 14}}.
    {test_heap, 12, 0}.
    {put_list, {y, 14}, nil, {x, 0}}.
    {put_list, {literal, <<" matching call(s), got ">>}, {x, 0}, {x, 0}}.
    {put_list, {y, 13}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<" - expected ">>}, {x, 0}, {x, 0}}.
    {put_list, {y, 8}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"mocks.verify: ">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 20}.
  {label, 134}.
    {move, {y, 12}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_3', 4, 59}.
  {label, 58}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_3'}, 4}.
  {label, 59}.
    {allocate, 5, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {move, {y, 4}, {x, 4}}.
    {call_fun, 4}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_4-t/1-fun-0-', 1, 144}.
  {label, 143}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_4-t/1-fun-0-'}, 1}.
  {label, 144}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, '__bp_mocks_verify'}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_4', 1, 140}.
  {label, 139}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_4'}, 1}.
  {label, 140}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 144}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_5-t/0-fun-0-', 0, 152}.
  {label, 151}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_5-t/0-fun-0-'}, 0}.
  {label, 152}.
    {allocate, 11, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {atom, '__bp_mocks_calls'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 156}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 5}}.
    {jump, {f, 155}}.
  {label, 156}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {y, 5}}.
    {jump, {f, 155}}.
  {label, 155}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 159}, [{x, 0}, nil]}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 158}}.
  {label, 159}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, last, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 161}, [{x, 0}]}.
    {test, test_arity, {f, 161}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {get_tuple_element, {x, 0}, 3, {y, 10}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 9}, {y, 2}}.
    {move, {y, 10}, {y, 3}}.
    {jump, {f, 162}}.
  {label, 161}.
    {move, {y, 7}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 162}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, droplast, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, '__bp_mocks_calls'}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 158}}.
  {label, 158}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '__bp_tpl_5', 0, 148}.
  {label, 147}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_5'}, 0}.
  {label, 148}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 152}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_6-t/1-fun-0-', 1, 170}.
  {label, 169}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_6-t/1-fun-0-'}, 1}.
  {label, 170}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 174}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 6}}.
    {jump, {f, 173}}.
  {label, 174}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 175}, [{x, 0}]}.
    {test, test_arity, {f, 175}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {get_tuple_element, {x, 0}, 2, {y, 9}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 9}, {y, 2}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 177}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 11}}.
    {jump, {f, 176}}.
  {label, 177}.
    {move, {y, 10}, {y, 3}}.
    {move, {y, 3}, {y, 11}}.
    {jump, {f, 176}}.
  {label, 176}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}, {atom, return}, {y, 4}]}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 2, 0}.
    {put_list, {y, 12}, nil, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 6}}.
    {jump, {f, 173}}.
  {label, 175}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 173}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_6', 1, 166}.
  {label, 165}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_6'}, 1}.
  {label, 166}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 170}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_7-t/1-fun-0-', 1, 185}.
  {label, 184}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_7-t/1-fun-0-'}, 1}.
  {label, 185}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 189}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 6}}.
    {jump, {f, 188}}.
  {label, 189}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 190}, [{x, 0}]}.
    {test, test_arity, {f, 190}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {get_tuple_element, {x, 0}, 2, {y, 9}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 9}, {y, 2}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 192}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 11}}.
    {jump, {f, 191}}.
  {label, 192}.
    {move, {y, 10}, {y, 3}}.
    {move, {y, 3}, {y, 11}}.
    {jump, {f, 191}}.
  {label, 191}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}, {atom, throw}, {y, 4}]}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 2, 0}.
    {put_list, {y, 12}, nil, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 6}}.
    {jump, {f, 188}}.
  {label, 190}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 188}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_7', 1, 181}.
  {label, 180}.
    {func_info, {atom, std@testing@mocks}, {atom, '__bp_tpl_7'}, 1}.
  {label, 181}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 185}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '-bp_field-', 2, 199}.
  {label, 198}.
    {line, [{location, "std@testing@mocks.erl", 20}]}.
    {func_info, {atom, std@testing@mocks}, {atom, '-bp_field-'}, 2}.
  {label, 199}.
    {test, is_map, {f, 200}, [{x, 0}]}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext_only, 3, {extfunc, maps, get, 3}}.
  {label, 200}.
    {test, is_tuple, {f, 201}, [{x, 0}]}.
    {bif, element, {f, 203}, [{integer, 1}, {x, 0}], {x, 2}}.
    {test, is_atom, {f, 203}, [{x, 2}]}.
    {test_heap, 4, 3}.
    {put_list, {x, 1}, nil, {x, 3}}.
    {put_list, {x, 0}, {x, 3}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {atom, '__bp_get'}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext_only, 3, {extfunc, erlang, apply, 3}}.
  {label, 201}.
    {test, is_eq_exact, {f, 203}, [{x, 1}, {atom, length}]}.
    {test, is_list, {f, 202}, [{x, 0}]}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    return.
  {label, 202}.
    {test, is_binary, {f, 203}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 203}.
    {move, {atom, undefined}, {x, 0}}.
    return.
