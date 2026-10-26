{module, std@beam}.
{exports, [{etsWhereis, 1}, {etsNew, 2}, {etsGet, 3}, {etsPut, 2}, {etsSwap, 2}, {ptGet, 1}, {ptPut, 2}, {ptSwap, 2}]}.
{attributes, []}.
{labels, 42}.
%%% std/beam — the BEAM memory host primitives, layer 1 of `beamMemory`.
%%% 
%%% Eight `declare fn`s over two BEAM storage families: ETS (`ets:whereis/
%%% new/lookup_element/insert/select_replace`) and `persistent_term`
%%% (`persistent_term:get/put`). Nothing else. Each one is a single host
%%% call with the host's own arity — no composition, no policy — except
%%% `etsSwap` and `ptSwap`, the compare-and-swap loop and the locked
%%% read-compute-put a module `var`'s `x = f(x)` is (decisions 547 (ii), 877, 903).
%%% 
%%% Why a module and not `.zig` (decision 43): `beamMemory` lives in two
%%% layers. **Layer 1 is this file** — the host vocabulary, as template
%%% text, editable without recompiling the compiler, exactly the property
%%% `codegen/erlang.zig:184-206` claims for the auto-imported BIF table it
%%% reads out of `erlang.bp`. **Layer 2 is the core** — two mode names
%%% (`Ets`, `PersistentTerm`) and how a binding's read and its write lower
%%% onto the functions below.
%%% 
%%% Why these and not the shapes: the shapes layer 2 composes are
%%% compositions of these calls, not host calls of their own. The
%%% `whereis`-guarded initialisation is `etsWhereis` answering `undefined`
%%% and then `etsNew` under a `try` — two primitives and a `case`, because
%%% a module cannot create its table at load time (`-on_load` runs in a
%%% temporary process: a `persistent_term` write survives it, an ETS table
%%% does not — `ets:whereis` answers `undefined` the moment the loader
%%% exits). Which process then owns the table is layer 2's, and it is the
%%% registered-owner question the front tracks; nothing here decides it.
%%% 
%%% Why `unknown` on every parameter and every return: the precedent is
%%% `erlang.bp`, which types every one of its declarations the same way,
%%% and these arguments are host terms with no botopink type — an ETS
%%% table identifier, a registered name atom, the `{Key, Value}` tuple
%%% `ets:insert` takes, the option list `ets:new` takes. `unknown` takes
%%% any value (`beam.pdPut("k", 1)` checks), and what a call answers is
%%% tested with `is` before it is used as another type. The spelling was
%%% `any` until decision 31 (1.0.5) deleted it: `any` was a closed type no
%%% botopink value inhabited, so `beam.pdPut("k", 1)` read `expected any,
%%% got string`.
%%% 
%%% Targets: `compiler.external(.Erlang)` covers **both** BEAM targets — `codegen.zig:74-77`
%%% maps `.erlang` and `.beam` alike to the `"erlang"` lookup name. On
%%% `commonJS` and `wasm` importing this module is `std-unsupported-on-target`
%%% (`comptime/infer.zig:100`), and that is the intended answer: a target
%%% with one execution context has no BEAM storage, so the annotation is
%%% refused there too, at the annotation (decision 167, which amended
%%% decision 43's no-op), and an import asks for the host primitives by name
%%% and there are none.
%%% 
%%% How a qualified std host call reaches these, measured: on the erlang
%%% backend `beam.pdPut(t, t)` is emitted as a call to the std module
%%% itself (`std@beam:pdPut(T, T)`), so the emitted `out/erl/std@beam.erl`
%%% has to define and export a `pdPut/2` of its own. It used to be
%%% `-module(std@beam).` and nothing else — no export, no function — and
%%% every call through it answered `undef` at run time (`std@erlang:self()`
%%% the same), while commonJS emitted real wrappers (`function cwd() {
%%% return process.cwd(); }`). Decision 64 closed the erlang half: the
%%% backend emits a wrapper and an export per `pub` host-backed `declare
%%% fn`, whether or not the current build imports it by name. The beam
%%% backend does the same for a plain `"<mod>", "<symbol>"` target — every
%%% declaration below — since front 17 step 5 lowered a module `var`'s
%%% reads and writes onto these calls on both BEAM targets.
%%% 
%%% Adding a primitive: one `#[compiler.external(.Erlang("<mod>", "<symbol>"))] pub
%%% declare fn <camelCase>(…) -> unknown;`. `root.bp` already declares this
%%% module, and `build.zig` derives the std module set from `root.bp`.
% ── ETS — shared across processes, created by the first caller, owned by one

{function, etsWhereis, 1, 3}.
  {label, 2}.
    {line, [{location, "std@beam.erl", 1}]}.
    {func_info, {atom, std@beam}, {atom, etsWhereis}, 1}.
  {label, 3}.
    {call_ext_only, 1, {extfunc, ets, whereis, 1}}.

{function, etsNew, 2, 5}.
  {label, 4}.
    {line, [{location, "std@beam.erl", 2}]}.
    {func_info, {atom, std@beam}, {atom, etsNew}, 2}.
  {label, 5}.
    {call_ext_only, 2, {extfunc, ets, new, 2}}.

{function, etsGet, 3, 7}.
  {label, 6}.
    {line, [{location, "std@beam.erl", 3}]}.
    {func_info, {atom, std@beam}, {atom, etsGet}, 3}.
  {label, 7}.
    {call_ext_only, 3, {extfunc, ets, lookup_element, 3}}.

{function, etsPut, 2, 9}.
  {label, 8}.
    {line, [{location, "std@beam.erl", 4}]}.
    {func_info, {atom, std@beam}, {atom, etsPut}, 2}.
  {label, 9}.
    {call_ext_only, 2, {extfunc, ets, insert, 2}}.
% `tid`'s one row `{tid, V}` rewritten to `{tid, f(V)}` only while it still holds the `V`
% read, read again and retried when another process wrote between (`ets:select_replace`,
% decisions 547 (ii), 877) — the one composed primitive: a module `var` with no annotation
% is one value for the whole program, and `x = f(x)` loses no write. The match spec
% compares with `=:=` against the value read as a constant, so no value is a pattern; its
% variable `'$1'` is built from its characters (`[36, 49]`), as `$1` in a template is the
% second argument.

{function, etsSwap, 2, 25}.
  {label, 24}.
    {line, [{location, "std@beam.erl", 5}]}.
    {func_info, {atom, std@beam}, {atom, etsSwap}, 2}.
  {label, 25}.
    {call_only, 2, {f, 11}}.
% ── persistent_term — read-cheap, write-expensive, written at load time

{function, ptGet, 1, 27}.
  {label, 26}.
    {line, [{location, "std@beam.erl", 6}]}.
    {func_info, {atom, std@beam}, {atom, ptGet}, 1}.
  {label, 27}.
    {call_ext_only, 1, {extfunc, persistent_term, get, 1}}.

{function, ptPut, 2, 29}.
  {label, 28}.
    {line, [{location, "std@beam.erl", 7}]}.
    {func_info, {atom, std@beam}, {atom, ptPut}, 2}.
  {label, 29}.
    {call_ext_only, 2, {extfunc, persistent_term, put, 2}}.
% `key`'s value rewritten to `f(V)` for the `V` it holds, read, computed and put under the
% lock of that key, so two writers never interleave and no write is lost (decisions 547 (ii),
% 903). The lock is `global:trans`'s, taken on this node alone, with the writer as its
% requester: the global lock server drops a lock whose requester died, so a writer that ends
% any way — returns, raises, is killed — releases it, with no timeout to guess. Readers never
% take it (`ptGet` stays lock-free).

{function, ptSwap, 2, 41}.
  {label, 40}.
    {line, [{location, "std@beam.erl", 8}]}.
    {func_info, {atom, std@beam}, {atom, ptSwap}, 2}.
  {label, 41}.
    {call_only, 2, {f, 31}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 15}.
  {label, 14}.
    {func_info, {atom, std@beam}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 15}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext, 3, {extfunc, ets, lookup_element, 3}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 19}}.
  {label, 19}.
    {move, {literal, [36, 49]}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 21}}.
  {label, 21}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {y, 1}]}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, const}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, '=:='}, {y, 1}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 2, 0}.
    {put_list, {y, 5}, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, const}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 2, 0}.
    {put_list, {y, 4}, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, ets, select_replace, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 23}, [{x, 0}, {integer, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 23}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_last, 2, {f, 15}, 7}.

{function, '__bp_tpl_0', 2, 11}.
  {label, 10}.
    {func_info, {atom, std@beam}, {atom, '__bp_tpl_0'}, 2}.
  {label, 11}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1--t/2-fun-0--fun-1-', 2, 39}.
  {label, 38}.
    {func_info, {atom, std@beam}, {atom, '__bp_tpl_1--t/2-fun-0--fun-1-'}, 2}.
  {label, 39}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, get, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext_last, 2, {extfunc, persistent_term, put, 2}, 3}.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 35}.
  {label, 34}.
    {func_info, {atom, std@beam}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 35}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, '$bp_persistent_term'}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {call_ext, 0, {extfunc, erlang, node, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 2, 0}.
    {put_list, {y, 4}, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext_last, 3, {extfunc, global, trans, 3}, 5}.

{function, '__bp_tpl_1', 2, 31}.
  {label, 30}.
    {func_info, {atom, std@beam}, {atom, '__bp_tpl_1'}, 2}.
  {label, 31}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
