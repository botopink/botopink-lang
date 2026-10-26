{module, std@io@os}.
{exports, [{hostname, 0}, {arch, 0}, {cpuCount, 0}, {tmpdir, 0}, {userInfo, 0}, {eol, 0}, {target, 0}]}.
{attributes, []}.
{labels, 76}.
%%% std/io/os — host OS introspection, cross-backend.
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/os.html
%%%              (`os.hostname()`, `os.arch()`, `os.cpus()`, `os.tmpdir()`,
%%%               `os.userInfo()`, `os.EOL`)
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/erlang.html
%%%              + https://www.erlang.org/doc/apps/stdlib/filename.html
%%%              (`inet:gethostname/0`, `erlang:system_info(schedulers_online)`,
%%%               `filename:basedir/2`, `os:getenv("USER")`)
%%% 
%%% Each Node template inlines `require('os')` at the call site —
%%% `os` is NOT a JS global so the §A2 alias path can't reach it; the
%%% arity-branched template form rolls the require + the call into a
%%% single expression that renders per call (cheap — Node caches the
%%% require).
%%% 
%%% `cpuCount()` returns the count of logical cores; `tmpdir()` is the
%%% host's temp directory; `userInfo()` returns the calling user's uid
%%% + username; `eol()` is the platform line-terminator; `target()` is the
%%% build's target, read when the program runs.
% Host hostname.
% Node: `require('os').hostname()` (re-require'd inline per call).
% Erlang: `inet:gethostname()` returns `{ok, Name}` (charlist).

{function, hostname, 0, 13}.
  {label, 12}.
    {line, [{location, "std@io@os.erl", 1}]}.
    {func_info, {atom, std@io@os}, {atom, hostname}, 0}.
  {label, 13}.
    {call_only, 0, {f, 3}}.
% Host CPU architecture string — `'x64'`, `'arm64'`, etc. std's one
% `arch`: `io.process` declared the same function (`process.arch`) and was
% folded here.
% Node: `require('os').arch()`.
% Erlang: `erlang:system_info(system_architecture)`.

{function, arch, 0, 17}.
  {label, 16}.
    {line, [{location, "std@io@os.erl", 2}]}.
    {func_info, {atom, std@io@os}, {atom, arch}, 0}.
  {label, 17}.
    {call_only, 0, {f, 15}}.
% Count of logical CPU cores available to the runtime.
% Node: `require('os').cpus().length`.
% Erlang: `erlang:system_info(schedulers_online)` returns the count
% of online schedulers — the BEAM analogue of "available cores".

{function, cpuCount, 0, 21}.
  {label, 20}.
    {line, [{location, "std@io@os.erl", 3}]}.
    {func_info, {atom, std@io@os}, {atom, cpuCount}, 0}.
  {label, 21}.
    {call_only, 0, {f, 19}}.
% Host temp directory (an absolute path).
% Node: `require('os').tmpdir()`.
% Erlang: best-effort via the `TMPDIR` env var with a fallback to
% `/tmp` — matches the POSIX convention; on Windows the BEAM-side
% fallback would need `os:getenv("TEMP")` (deferred).

{function, tmpdir, 0, 33}.
  {label, 32}.
    {line, [{location, "std@io@os.erl", 4}]}.
    {func_info, {atom, std@io@os}, {atom, tmpdir}, 0}.
  {label, 33}.
    {call_only, 0, {f, 23}}.
% Calling user's basic identity. Node returns a structured object; on
% Erlang there is no direct `os:userInfo` BIF so the template lifts the
% `USER` env var (falling back to `<<"unknown">>`) and reads the uid
% from `process_info` — best-effort, the Erlang side stays informative
% without claiming POSIX-grade accuracy. The Erlang term is the record's
% own run-time shape (13-module-identity decision 21): the tagged tuple
% `{'<module atom>@@<Type>', <fields in declared order>}`, which is
% what `u.username` reads a position out of.

{function, userInfo, 0, 48}.
  {label, 47}.
    {line, [{location, "std@io@os.erl", 5}]}.
    {func_info, {atom, std@io@os}, {atom, userInfo}, 0}.
  {label, 48}.
    {allocate, 0, 0}.
    {call, 0, {f, 35}}.
    {move, {atom, std@io@os@@UserInfo}, {x, 1}}.
    {move, {literal, [uid, username]}, {x, 2}}.
    {call_last, 3, {f, 66}, 0}.
% Platform line terminator — `"\n"` on POSIX, `"\r\n"` on Windows.
% Node reads `require('os').EOL`; Erlang branches on `os:type/0`.

{function, eol, 0, 60}.
  {label, 59}.
    {line, [{location, "std@io@os.erl", 6}]}.
    {func_info, {atom, std@io@os}, {atom, eol}, 0}.
  {label, 60}.
    {call_only, 0, {f, 50}}.
% The target the program runs on (decision 989 (7)): `commonJS`, `erlang`,
% `beam` or `wasm` — each target's own constant. The beam target reads the
% erlang cell and answers its own text instead: the assembler writes `beam`
% (`codegen/beam_asm.zig`, `os_target_template`). A run-time answer only: no
% comptime cell serves it, so a build body that reaches it is refused
% (decision 798 (4)) — comptime runs on wasm whatever the target.

{function, target, 0, 64}.
  {label, 63}.
    {line, [{location, "std@io@os.erl", 7}]}.
    {func_info, {atom, std@io@os}, {atom, target}, 0}.
  {label, 64}.
    {call_only, 0, {f, 62}}.
% ── tests ────────────────────────────────────────────────────────────────────

{function, '__bp_tpl_0-t/0-fun-0-', 0, 7}.
  {label, 6}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_0-t/0-fun-0-'}, 0}.
  {label, 7}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {call_ext, 0, {extfunc, inet, gethostname, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 10}, [{x, 0}]}.
    {test, test_arity, {f, 10}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {get_tuple_element, {x, 0}, 1, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 10}, [{x, 0}, {atom, ok}]}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 11}}.
  {label, 10}.
    {move, {y, 1}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 11}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 4}.

{function, '__bp_tpl_0', 0, 3}.
  {label, 2}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_0'}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1', 0, 15}.
  {label, 14}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_1'}, 0}.
  {label, 15}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {atom, system_architecture}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, system_info, 1}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 1}.

{function, '__bp_tpl_2', 0, 19}.
  {label, 18}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_2'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, schedulers_online}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, system_info, 1}, 0}.

{function, '__bp_tpl_3-t/0-fun-0-', 0, 27}.
  {label, 26}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_3-t/0-fun-0-'}, 0}.
  {label, 27}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {literal, [84, 77, 80, 68, 73, 82]}, {x, 0}}.
    {call_ext, 1, {extfunc, os, getenv, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, false}]}.
    {move, {literal, <<"/tmp">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 31}.
    {move, {y, 1}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 2}.

{function, '__bp_tpl_3', 0, 23}.
  {label, 22}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_3'}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_4-t/0-fun-0-', 0, 39}.
  {label, 38}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_4-t/0-fun-0-'}, 0}.
  {label, 39}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {literal, [85, 83, 69, 82]}, {x, 0}}.
    {call_ext, 1, {extfunc, os, getenv, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, false}]}.
    {move, {literal, <<"unknown">>}, {y, 2}}.
    {jump, {f, 42}}.
  {label, 43}.
    {move, {y, 1}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 2}}.
    {jump, {f, 42}}.
  {label, 42}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 46}}.
  {label, 46}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@os@@UserInfo}, {integer, 0}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_4', 0, 35}.
  {label, 34}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_4'}, 0}.
  {label, 35}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_5-t/0-fun-0-', 0, 54}.
  {label, 53}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_5-t/0-fun-0-'}, 0}.
  {label, 54}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {call_ext, 0, {extfunc, os, type, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 58}, [{x, 0}]}.
    {test, test_arity, {f, 58}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 58}, [{x, 0}, {atom, win32}]}.
    {move, {literal, <<"\r\n">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 58}.
    {move, {literal, <<"\n">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_5', 0, 50}.
  {label, 49}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_5'}, 0}.
  {label, 50}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_6', 0, 62}.
  {label, 61}.
    {func_info, {atom, std@io@os}, {atom, '__bp_tpl_6'}, 0}.
  {label, 62}.
    {allocate, 0, 0}.
    {move, {literal, <<"beam">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_adopt', 3, 66}.
  {label, 65}.
    {line, [{location, "std@io@os.erl", 5}]}.
    {func_info, {atom, std@io@os}, {atom, '__bp_adopt'}, 3}.
  {label, 66}.
    {test, is_map, {f, 71}, [{x, 0}]}.
    {allocate, 1, 3}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 68}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_tuple, 1}, 1}.
  {label, 71}.
    {test, is_list, {f, 72}, [{x, 0}]}.
    {call_only, 3, {f, 70}}.
  {label, 72}.
    {test, is_tagged_tuple, {f, 73}, [{x, 0}, 2, {atom, ok}]}.
    {allocate, 0, 3}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {call, 3, {f, 66}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 0}]}}.
    {deallocate, 0}.
    return.
  {label, 73}.
    return.

{function, '-bp_adopt_fields-', 2, 68}.
  {label, 67}.
    {line, [{location, "std@io@os.erl", 5}]}.
    {func_info, {atom, std@io@os}, {atom, '-bp_adopt_fields-'}, 2}.
  {label, 68}.
    {test, is_nonempty_list, {f, 74}, [{x, 0}]}.
    {allocate, 2, 2}.
    {move, {x, 1}, {y, 1}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext, 3, {extfunc, maps, get, 3}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 68}}.
    {test_heap, 2, 1}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 74}.
    {move, nil, {x, 0}}.
    return.

{function, '-bp_adopt_each-', 3, 70}.
  {label, 69}.
    {line, [{location, "std@io@os.erl", 5}]}.
    {func_info, {atom, std@io@os}, {atom, '-bp_adopt_each-'}, 3}.
  {label, 70}.
    {test, is_nonempty_list, {f, 75}, [{x, 0}]}.
    {allocate, 3, 3}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {call, 3, {f, 66}}.
    {move, {y, 0}, {x, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call, 3, {f, 70}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 75}.
    {move, nil, {x, 0}}.
    return.
