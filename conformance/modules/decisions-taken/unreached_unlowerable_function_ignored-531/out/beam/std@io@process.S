{module, std@io@process}.
{exports, [{exit, 1}, {cwd, 0}, {platform, 0}, {pid, 0}, {run, 2}, {runShell, 1}, {onSignal, 2}, {spawn, 2}, {start, 4}, {signalName, 1}, {processError, 3}, {'__bp_priv__string_slice', 3}]}.
{attributes, []}.
{labels, 287}.
%%% std/io/process — host process introspection, cross-backend.
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/process.html
%%%              (`process.exit`, `process.cwd`, `process.platform`,
%%%               `process.pid`)
%%%   Erlang   — https://www.erlang.org/doc/apps/stdlib/erlang.html#halt-1
%%%              (`erlang:halt/1`, `file:get_cwd/0`, `os:type/0`,
%%%               `os:getpid/0`)
%%% 
%%% Most calls are method-on-class chains (`process.cwd()`, `os.getpid()`)
%%% or property reads (`process.platform`). The §A2 commonJS template
%%% dispatch (`a7c6d07`) + erlang twin (`52d6101`) make both shapes
%%% feasible without the legacy alias path that strips the receiver.
%%% 
%%% The 0-arg fns use the `when(argc == 0): "<tmpl>"` arity-branched
%%% shape rather than a bare template string —
%%% `primOpTemplate.looksLikeTemplate` reads the `$` discriminator, and
%%% a 0-arg lowering has no `$N` to embed, so the arity branch keeps
%%% the template-path dispatch.
% Exit the current process with the given status code.
% Node: `process.exit(code)` (chained method — §A2 template).
% Erlang: `erlang:halt(code)` (bare BIF).

{function, exit, 1, 13}.
  {label, 12}.
    {line, [{location, "std@io@process.erl", 1}]}.
    {func_info, {atom, std@io@process}, {atom, exit}, 1}.
  {label, 13}.
    {call_ext_only, 1, {extfunc, erlang, halt, 1}}.
% Current working directory of the host process.
% Node: `process.cwd()` (method on `process` — §A2 template).
% Erlang: `file:get_cwd()` returns `{ok, Path}` (charlist); the
% template extracts and stringifies it.

{function, cwd, 0, 25}.
  {label, 24}.
    {line, [{location, "std@io@process.erl", 2}]}.
    {func_info, {atom, std@io@process}, {atom, cwd}, 0}.
  {label, 25}.
    {call_only, 0, {f, 15}}.
% Host platform string — `'linux'`, `'darwin'`, `'win32'`, etc.
% Node: bare `process.platform` (property access).
% Erlang: `os:type()` returns `{unix, linux}` / `{win32, nt}` /
% `{unix, darwin}`; the template extracts the SECOND element (the
% flavor, matching the Node `process.platform` shape) and stringifies
% it. Read-time match — the first element is the family (unix/win32).

{function, platform, 0, 37}.
  {label, 36}.
    {line, [{location, "std@io@process.erl", 3}]}.
    {func_info, {atom, std@io@process}, {atom, platform}, 0}.
  {label, 37}.
    {call_only, 0, {f, 27}}.
% Host process id.
% Node: `process.pid` (property — i32 in JS, stored as Number).
% Erlang: `os:getpid()` returns a string list; the template parses
% it to an integer.

{function, pid, 0, 41}.
  {label, 40}.
    {line, [{location, "std@io@process.erl", 4}]}.
    {func_info, {atom, std@io@process}, {atom, pid}, 0}.
  {label, 41}.
    {call_only, 0, {f, 39}}.
% ── 1.0.10-beta front 01 additions ──────────────────────────────────────────
% 
% Child processes. The five introspections above are not edited. Signals
% (`onSignal`) are not here: a closure handed to a host cell is unverified on
% the Erlang target (`language-gaps.md`).
% What a child process left behind. `stderr` is split out on Node; on Erlang
% the port folds it into `stdout` (`stderr_to_stdout`) and `stderr` is `""`
% — a caller that needs the two apart on both targets redirects through a
% file and says so.
% Run the executable `cmd` (looked up on `PATH` when it has no `/`) with
% `args`, no shell, and wait for it. A process that RAN is `Ok` whatever its
% status — a non-zero exit is an `Exit` carrying that status. `Error` means
% it could not be started (not found, not executable).
% Node: `child_process.spawnSync`; a start failure is `r.error`, which the
% template throws.
% Erlang: `open_port({spawn_executable, Path}, [exit_status, …])`, the path
% from `os:find_executable/1`, the output gathered until `exit_status`; a
% missing executable is `{error, enoent}`, a port that cannot open raises.
% Both run under `result: true` (decisions 431, 490); the answer is the host's
% `HostError`, not a `ProcessError` of std's own: a public function over the
% cell would be a body calling a cell with no wasm binding, which wasm refuses
% for the whole module — `import {io.process}` would stop compiling there.

{function, run, 2, 93}.
  {label, 92}.
    {line, [{location, "std@io@process.erl", 5}]}.
    {func_info, {atom, std@io@process}, {atom, run}, 2}.
  {label, 93}.
    {allocate, 0, 2}.
    {call, 2, {f, 43}}.
    {move, {atom, std@io@process@@Exit}, {x, 1}}.
    {move, {literal, [status, stdout, stderr]}, {x, 2}}.
    {call_last, 3, {f, 99}, 0}.
% Run `cmd` through `/bin/sh -c` and answer its output, stdout and stderr
% together. STATUS-LOSING on both targets: the answer is text only, so a
% failing command is indistinguishable from a quiet one — `os:cmd/1` answers
% output only on Erlang, and the Node cell matches it. Use `run` when the
% status matters.
% Node: `spawnSync('/bin/sh', ['-c', 'exec 2>&1; ' + cmd])`.
% Erlang: `os:cmd/1` (which runs `/bin/sh -c` and folds stderr in).

{function, runShell, 1, 97}.
  {label, 96}.
    {line, [{location, "std@io@process.erl", 6}]}.
    {func_info, {atom, std@io@process}, {atom, runShell}, 1}.
  {label, 97}.
    {call_only, 1, {f, 95}}.
% ── signals and spawned children (decision 506 (1)) ────────────────────────────
% 
% `onSignal` runs a handler when the process receives a signal; `spawn` starts a child
% that shares the parent's terminal and answers a `Child` the program waits for, signals
% or asks to carry the parent's own signals over (`forwardSignals`). Every failure is a
% `ProcessError` of this module (decision 431-a). There is no wasm binding: a call is
% refused at the call (`std-unsupported-on-target`, decision 518 (4)).
% The signals a program can ask to hear about, and send a child.
% The error of `onSignal`, `spawn` and `Child.kill`.

{function, signalName, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@process.erl", 7}]}.
    {func_info, {atom, std@io@process}, {atom, signalName}, 1}.
  {label, 3}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 110}, [{x, 0}, {atom, std@io@process@@Signal__v__int}]}.
    {move, {literal, <<"SIGINT">>}, {x, 0}}.
    {jump, {f, 109}}.
  {label, 110}.
    {test, is_eq, {f, 111}, [{x, 0}, {atom, std@io@process@@Signal__v__term}]}.
    {move, {literal, <<"SIGTERM">>}, {x, 0}}.
    {jump, {f, 109}}.
  {label, 111}.
    {test, is_eq, {f, 112}, [{x, 0}, {atom, std@io@process@@Signal__v__hup}]}.
    {move, {literal, <<"SIGHUP">>}, {x, 0}}.
    {jump, {f, 109}}.
  {label, 112}.
    {test, is_eq, {f, 113}, [{x, 0}, {atom, std@io@process@@Signal__v__winch}]}.
    {move, {literal, <<"SIGWINCH">>}, {x, 0}}.
    {jump, {f, 109}}.
  {label, 113}.
    {case_end, {x, 0}}.
  {label, 109}.
    {deallocate, 5}.
    return.
% The host cells answer `<kind>|<host text>` as their error, `kind` one of `notfound`,
% `denied`, `gone`, `unsupported`, `other`.

{function, processError, 3, 5}.
  {label, 4}.
    {line, [{location, "std@io@process.erl", 8}]}.
    {func_info, {atom, std@io@process}, {atom, processError}, 3}.
  {label, 5}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {literal, <<"|">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 115}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 3, {f, 129}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 130}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 130}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 131}}.
  {label, 130}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/io/process.bp:151:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 131}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 3, {f, 129}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"notfound">>}, {x, 0}}.
    {test, is_eq_exact, {f, 132}, [{y, 4}, {x, 0}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@process@@ProcessError__v__notfound}, {y, 0}]}}.
    {deallocate, 6}.
    return.
  {label, 132}.
    {move, {literal, <<"denied">>}, {x, 0}}.
    {test, is_eq_exact, {f, 133}, [{y, 4}, {x, 0}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@process@@ProcessError__v__permissiondenied}, {y, 0}]}}.
    {deallocate, 6}.
    return.
  {label, 133}.
    {move, {literal, <<"gone">>}, {x, 0}}.
    {test, is_eq_exact, {f, 134}, [{y, 4}, {x, 0}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@process@@ProcessError__v__nosuchprocess}, {y, 1}]}}.
    {deallocate, 6}.
    return.
  {label, 134}.
    {move, {literal, <<"unsupported">>}, {x, 0}}.
    {test, is_eq_exact, {f, 135}, [{y, 4}, {x, 0}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@process@@ProcessError__v__unsupported}, {y, 5}]}}.
    {deallocate, 6}.
    return.
  {label, 135}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@process@@ProcessError__v__other}, {y, 5}]}}.
    {deallocate, 6}.
    return.
% Run `handler` each time the process receives `name`.
% Node: `process.on(name, handler)`; a signal listener does not keep the process alive, and
% it replaces the default action (the process no longer exits on `SIGTERM`).
% Erlang: `os:set_signal(Signal, handle)` sends the event to `erl_signal_server`, whose
% default handler stops the node on `sigterm`; the cell removes that handler and adds one of its
% own, a module (`bp_signal_handler`) compiled and loaded on first use that calls, in order, the
% funs kept for the signal in `persistent_term`. `SIGINT` is not an `os:set_signal` signal: the VM keeps it for its
% break handler, so it is `unsupported|…` there. `SIGWINCH` needs OTP 28.
% Run `handler` when the process receives `s`. A handler stays for the life of the process,
% and several for one signal all run, in the order they were added. While one is installed the
% signal no longer ends the process: ending it is the handler's business (`exit`). `Int` is
% `Unsupported` on erlang and beam, where the VM keeps `SIGINT` for itself.

{function, onSignal, 2, 7}.
  {label, 6}.
    {line, [{location, "std@io@process.erl", 9}]}.
    {func_info, {atom, std@io@process}, {atom, onSignal}, 2}.
  {label, 7}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 137}}.
    {test, is_tagged_tuple, {f, 200}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 199}}.
  {label, 200}.
    {test, is_tagged_tuple, {f, 201}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 3}.
    return.
    {jump, {f, 199}}.
  {label, 201}.
    {case_end, {x, 0}}.
  {label, 199}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
% A child process handle: the OS process id and the host's own handle, opaque.
% The handle of `cmd` started with `args`, no shell, sharing the parent's standard streams.
% `cmd` is looked up on `PATH` when it has no `/`. Failure kinds are told before anything starts.
% Node: `child_process.spawn(file, args, { stdio: 'inherit' })`, the exit read from its `exit`
% event.
% Erlang: `open_port({spawn_executable, File}, [binary, exit_status, stderr_to_stdout, …])`.
% Start `cmd` with `args` (no shell) and answer its `Child` without waiting for it. The child
% shares the parent's terminal; `Child.wait` waits for it, `Child.kill` signals it and
% `Child.forwardSignals` carries the parent's signals to it. `NotFound` / `PermissionDenied`
% say why nothing started. `run` is the one that waits and captures the output.

{function, spawn, 2, 9}.
  {label, 8}.
    {line, [{location, "std@io@process.erl", 13}]}.
    {func_info, {atom, std@io@process}, {atom, spawn}, 2}.
  {label, 9}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 203}}.
    {test, is_tagged_tuple, {f, 238}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 240}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@process@@Child}, {x, 0}, {y, 2}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 237}}.
  {label, 238}.
    {test, is_tagged_tuple, {f, 241}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
    {jump, {f, 237}}.
  {label, 241}.
    {case_end, {x, 0}}.
  {label, 237}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.
% ── captured children (decision 790, 798 (6)) ───────────────────────────────────
% 
% `start` is `spawn` with the child's output captured apart: stdout and stderr each into a
% string, the answer of `Captured.wait` an `Exit`. Several started children run at once, and
% their `wait`s may be awaited together (`async.runAll`). It exists on commonJS alone: an erlang port
% folds stderr into stdout, and `Captured` keeps the two apart. The host declarations below have no
% erlang, beam or wasm binding, so a call to `start` is refused at the call there
% (`std-unsupported-on-target`, decisions 518 (4), 906) while the module still imports and `run` / `spawn`
% are unchanged. The programs that need the two apart (`cell check`'s, decision 790) run on commonJS.
% Start `cmd` with `args` (no shell), in `cwd` (the parent's when absent), with the parent's environment
% plus `env` (each entry `NAME=value`, the first `=` ends the name). `cmd` is looked up on `PATH` when it has no `/`;
% a `/` path is read from `cwd`. Failure kinds are told before anything starts, as in `spawn`; an `env` entry
% with no `=` or an empty name answers `Other` naming it.
% Node: `child_process.spawn(file, args, { cwd, env, stdio: ['ignore', 'pipe', 'pipe'] })`, the
% exit read from its `close` event.
% `kill` of a started child: the host cell of `Child.kill` (`rawKill`) reads only the handle.
% A started child whose output is captured: the OS process id and the host's own handle, opaque.
% Start `cmd` with `args` (no shell) in `cwd` with `env` added to the parent's environment, and answer its
% `Captured` without waiting for it. `NotFound` / `PermissionDenied` say why nothing started.
% commonJS only (see above).

{function, start, 4, 11}.
  {label, 10}.
    {line, [{location, "std@io@process.erl", 16}]}.
    {func_info, {atom, std@io@process}, {atom, start}, 4}.
  {label, 11}.
    {allocate, 6, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {atom, unreachable}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {test, is_tagged_tuple, {f, 243}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, {atom, unreachable}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@io@process@@Captured}, {x, 0}, {y, 4}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 6}.
    return.
    {jump, {f, 242}}.
  {label, 243}.
    {test, is_tagged_tuple, {f, 244}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 2}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 6}.
    return.
    {jump, {f, 242}}.
  {label, 244}.
    {case_end, {x, 0}}.
  {label, 242}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 6}.
    return.
% ── tests ────────────────────────────────────────────────────────────────────

{function, 'string_slice', 3, 129}.
  {label, 128}.
    {line, [{location, "std@io@process.erl", 17}]}.
    {func_info, {atom, std@io@process}, {atom, 'string_slice'}, 3}.
  {label, 129}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 245}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 247}, 3}.
  {label, 245}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 269}, 3}.

{function, '__bp_priv__string_slice', 3, 286}.
  {label, 285}.
    {line, [{location, "std@io@process.erl", 18}]}.
    {func_info, {atom, std@io@process}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 286}.
    {call_only, 3, {f, 129}}.

{function, '__bp_tpl_0-t/0-fun-0-', 0, 19}.
  {label, 18}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_0-t/0-fun-0-'}, 0}.
  {label, 19}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {call_ext, 0, {extfunc, file, get_cwd, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 22}, [{x, 0}]}.
    {test, test_arity, {f, 22}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 2}}.
    {get_tuple_element, {x, 0}, 1, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 22}, [{x, 0}, {atom, ok}]}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {y, 1}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 4}.

{function, '__bp_tpl_0', 0, 15}.
  {label, 14}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_0'}, 0}.
  {label, 15}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1-t/0-fun-0-', 0, 31}.
  {label, 30}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_1-t/0-fun-0-'}, 0}.
  {label, 31}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {call_ext, 0, {extfunc, os, type, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 34}, [{x, 0}]}.
    {test, test_arity, {f, 34}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 1, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {y, 1}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, utf8}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, atom_to_binary, 2}, 3}.

{function, '__bp_tpl_1', 0, 27}.
  {label, 26}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_1'}, 0}.
  {label, 27}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_2', 0, 39}.
  {label, 38}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_2'}, 0}.
  {label, 39}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {call_ext, 0, {extfunc, os, getpid, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_integer, 1}, 1}.

{function, '__bp_tpl_3--t/2-fun-0--fun-1-', 2, 67}.
  {label, 66}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_3--t/2-fun-0--fun-1-'}, 2}.
  {label, 67}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 67}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
  {label, 70}.
    {loop_rec, {f, 71}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 74}, [{x, 0}]}.
    {test, test_arity, {f, 74}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 74}, [{x, 0}]}.
    {test, test_arity, {f, 74}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {atom, data}]}.
    {move, {y, 9}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {x, 1}]}.
    {jump, {f, 75}}.
  {label, 75}.
    remove_message.
    {test_heap, 2, 0}.
    {put_list, {y, 3}, {y, 4}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 67}, 11}.
  {label, 74}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 76}, [{x, 0}]}.
    {test, test_arity, {f, 76}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 76}, [{x, 0}]}.
    {test, test_arity, {f, 76}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {atom, exit_status}]}.
    {move, {y, 9}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {x, 1}]}.
    {jump, {f, 77}}.
  {label, 77}.
    remove_message.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 2}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 76}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 7}}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 9}}.
    {move, nil, {y, 10}}.
    {loop_rec_end, {f, 70}}.
  {label, 71}.
    {wait, {f, 70}}.

{function, '__bp_tpl_3-t/2-fun-0-', 2, 49}.
  {label, 48}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_3-t/2-fun-0-'}, 2}.
  {label, 49}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"/">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, find, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, nomatch}]}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, os, find_executable, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 52}}.
  {label, 53}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 52}}.
  {label, 52}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 56}}.
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 58}, [{x, 0}, {atom, false}]}.
    {move, {literal, {error, enoent}}, {x, 0}}.
    {deallocate, 10}.
    return.
  {label, 58}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, spawn_executable}, {y, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {y, 6}}.
    {move, {y, 4}, {y, 7}}.
  {label, 61}.
    {move, {y, 7}, {x, 0}}.
    {test, is_nonempty_list, {f, 62}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 8}, {y, 7}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 2, 0}.
    {put_list, {y, 9}, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {jump, {f, 61}}.
  {label, 62}.
    {move, {y, 7}, {x, 0}}.
    {test, is_nil, {f, 63}, [{x, 0}]}.
    {jump, {f, 60}}.
  {label, 63}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 7}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 60}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, args}, {y, 7}]}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 8, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {put_list, {atom, stderr_to_stdout}, {x, 0}, {x, 0}}.
    {put_list, {atom, exit_status}, {x, 0}, {x, 0}}.
    {put_list, {atom, binary}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, open_port, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 65}}.
  {label, 65}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 67}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 79}}.
  {label, 79}.
    {move, nil, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 80}, [{x, 0}]}.
    {test, test_arity, {f, 80}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {y, 5}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 81}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, status}, {y, 1}, {atom, stdout}, {y, 2}, {atom, stderr}, {literal, <<"">>}]}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 10}.
    return.

{function, '__bp_tpl_3', 2, 43}.
  {label, 42}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_3'}, 2}.
  {label, 43}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {'try', {y, 12}, {f, 46}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 49}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 7}}.
    {try_end, {y, 12}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 83}, [{x, 0}]}.
    {test, test_arity, {f, 83}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 83}, [{x, 0}, {atom, ok}]}.
    {move, {y, 9}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 82}}.
  {label, 83}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 84}, [{x, 0}]}.
    {test, test_arity, {f, 84}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {atom, error}]}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 10}, {literal, <<"host">>}, {atom, std@failure@@HostErrorName__v__error}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 5}}.
    {jump, {f, 82}}.
  {label, 84}.
    {move, {y, 7}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 5}}.
    {jump, {f, 82}}.
  {label, 82}.
    {jump, {f, 47}}.
  {label, 46}.
    {try_case, {y, 12}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    build_stacktrace.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 89}, [{x, 0}, {atom, error}]}.
    {move, {atom, std@failure@@HostErrorName__v__error}, {y, 10}}.
    {jump, {f, 88}}.
  {label, 89}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 90}, [{x, 0}, {atom, throw}]}.
    {move, {atom, std@failure@@HostErrorName__v__throw}, {y, 10}}.
    {jump, {f, 88}}.
  {label, 90}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 91}, [{x, 0}, {atom, exit}]}.
    {move, {atom, std@failure@@HostErrorName__v__exit}, {y, 10}}.
    {jump, {f, 88}}.
  {label, 91}.
    {move, {y, 0}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 88}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@failure@@HostError}, {y, 9}, {literal, <<"host">>}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 86}}.
  {label, 86}.
  {label, 47}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_4', 1, 95}.
  {label, 94}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_4'}, 1}.
  {label, 95}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, os, cmd, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 2}.

{function, '__bp_adopt', 3, 99}.
  {label, 98}.
    {line, [{location, "std@io@process.erl", 5}]}.
    {func_info, {atom, std@io@process}, {atom, '__bp_adopt'}, 3}.
  {label, 99}.
    {test, is_map, {f, 104}, [{x, 0}]}.
    {allocate, 1, 3}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 101}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_tuple, 1}, 1}.
  {label, 104}.
    {test, is_list, {f, 105}, [{x, 0}]}.
    {call_only, 3, {f, 103}}.
  {label, 105}.
    {test, is_tagged_tuple, {f, 106}, [{x, 0}, 2, {atom, ok}]}.
    {allocate, 0, 3}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {call, 3, {f, 99}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 0}]}}.
    {deallocate, 0}.
    return.
  {label, 106}.
    return.

{function, '-bp_adopt_fields-', 2, 101}.
  {label, 100}.
    {line, [{location, "std@io@process.erl", 5}]}.
    {func_info, {atom, std@io@process}, {atom, '-bp_adopt_fields-'}, 2}.
  {label, 101}.
    {test, is_nonempty_list, {f, 107}, [{x, 0}]}.
    {allocate, 2, 2}.
    {move, {x, 1}, {y, 1}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext, 3, {extfunc, maps, get, 3}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 101}}.
    {test_heap, 2, 1}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 107}.
    {move, nil, {x, 0}}.
    return.

{function, '-bp_adopt_each-', 3, 103}.
  {label, 102}.
    {line, [{location, "std@io@process.erl", 5}]}.
    {func_info, {atom, std@io@process}, {atom, '-bp_adopt_each-'}, 3}.
  {label, 103}.
    {test, is_nonempty_list, {f, 108}, [{x, 0}]}.
    {allocate, 3, 3}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {get_list, {x, 0}, {x, 0}, {y, 0}}.
    {call, 3, {f, 99}}.
    {move, {y, 0}, {x, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call, 3, {f, 103}}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 108}.
    {move, nil, {x, 0}}.
    return.

{function, '__bp_tpl_5-t/2-fun-0-', 2, 119}.
  {label, 118}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_5-t/2-fun-0-'}, 2}.
  {label, 119}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 123}, [{x, 0}, {literal, <<"">>}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 123}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 126}, [{x, 0}, {atom, nomatch}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 126}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 127}, [{x, 0}]}.
    {test, test_arity, {f, 127}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 6}.
  {label, 127}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_5', 2, 115}.
  {label, 114}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_5'}, 2}.
  {label, 115}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 119}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_6--t/2-fun-0--fun-1-', 2, 167}.
  {label, 166}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_6--t/2-fun-0--fun-1-'}, 2}.
  {label, 167}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 167}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 169}, [{x, 0}, nil]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 169}, [{x, 0}, nil]}.
    {move, nil, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 169}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 170}, [{x, 0}, nil]}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 2, 0}.
    {put_list, {y, 4}, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 170}.
    {move, {y, 2}, {x, 0}}.
    {test, is_nonempty_list, {f, 171}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 171}, [{x, 0}]}.
    {test, test_arity, {f, 171}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 171}, [{x, 0}, {atom, dot}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 1}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call, 2, {f, 167}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 171}.
    {move, {y, 2}, {x, 0}}.
    {test, is_nonempty_list, {f, 172}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_last, 2, {f, 167}, 9}.
  {label, 172}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {deallocate, 9}.
    {jump, {f, 166}}.

{function, '__bp_tpl_6-t/2-fun-0-', 2, 141}.
  {label, 140}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_6-t/2-fun-0-'}, 2}.
  {label, 141}.
    {allocate, 17, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"SIGTERM">>}, {x, 1}}.
    {test, is_eq_exact, {f, 145}, [{x, 0}, {x, 1}]}.
    {jump, {f, 146}}.
  {label, 146}.
    {move, {atom, sigterm}, {y, 5}}.
    {jump, {f, 144}}.
  {label, 145}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"SIGHUP">>}, {x, 1}}.
    {test, is_eq_exact, {f, 147}, [{x, 0}, {x, 1}]}.
    {jump, {f, 148}}.
  {label, 148}.
    {move, {atom, sighup}, {y, 5}}.
    {jump, {f, 144}}.
  {label, 147}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"SIGWINCH">>}, {x, 1}}.
    {test, is_eq_exact, {f, 149}, [{x, 0}, {x, 1}]}.
    {jump, {f, 150}}.
  {label, 150}.
    {move, {atom, sigwinch}, {y, 5}}.
    {jump, {f, 144}}.
  {label, 149}.
    {jump, {f, 152}}.
  {label, 152}.
    {move, {atom, unsupported}, {y, 5}}.
    {jump, {f, 144}}.
  {label, 144}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 154}}.
  {label, 154}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 156}, [{x, 0}, {atom, unsupported}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" cannot be caught on the Erlang VM">>}, nil, {x, 0}}.
    {put_list, {y, 3}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"unsupported|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 17}.
    return.
  {label, 156}.
    {'try', {y, 16}, {f, 158}}.
    {move, {atom, bp_signal_handler}, {x, 0}}.
    {call_ext, 1, {extfunc, code, is_loaded, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 161}, [{x, 0}, {atom, false}]}.
    {move, {literal, [45, 109, 111, 100, 117, 108, 101, 40, 98, 112, 95, 115, 105, 103, 110, 97, 108, 95, 104, 97, 110, 100, 108, 101, 114, 41, 46, 32, 45, 98, 101, 104, 97, 118, 105, 111, 117, 114, 40, 103, 101, 110, 95, 101, 118, 101, 110, 116, 41, 46, 32, 45, 101, 120, 112, 111, 114, 116, 40, 91, 105, 110, 105, 116, 47, 49, 44, 32, 104, 97, 110, 100, 108, 101, 95, 101, 118, 101, 110, 116, 47, 50, 44, 32, 104, 97, 110, 100, 108, 101, 95, 99, 97, 108, 108, 47, 50, 93, 41, 46, 32, 105, 110, 105, 116, 40, 83, 41, 32, 45, 62, 32, 123, 111, 107, 44, 32, 83, 125, 46, 32, 104, 97, 110, 100, 108, 101, 95, 101, 118, 101, 110, 116, 40, 69, 44, 32, 83, 41, 32, 45, 62, 32, 91, 70, 40, 41, 32, 124, 124, 32, 70, 32, 60, 45, 32, 112, 101, 114, 115, 105, 115, 116, 101, 110, 116, 95, 116, 101, 114, 109, 58, 103, 101, 116, 40, 123, 98, 112, 95, 115, 105, 103, 110, 97, 108, 44, 32, 69, 125, 44, 32, 91, 93, 41, 93, 44, 32, 123, 111, 107, 44, 32, 83, 125, 46, 32, 104, 97, 110, 100, 108, 101, 95, 99, 97, 108, 108, 40, 95, 44, 32, 83, 41, 32, 45, 62, 32, 123, 111, 107, 44, 32, 111, 107, 44, 32, 83, 125, 46]}, {y, 1}}.
    {jump, {f, 163}}.
  {label, 163}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erl_scan, string, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 164}, [{x, 0}]}.
    {test, test_arity, {f, 164}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 164}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 1}}.
    {jump, {f, 165}}.
  {label, 164}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 165}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 167}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 2}}.
    {jump, {f, 174}}.
  {label, 174}.
    {move, nil, {y, 8}}.
    {move, {y, 1}, {x, 0}}.
    {move, nil, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 9}}.
  {label, 176}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nonempty_list, {f, 177}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 11}, {y, 9}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erl_parse, parse_form, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 179}, [{x, 0}]}.
    {test, test_arity, {f, 179}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 13}}.
    {get_tuple_element, {x, 0}, 1, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 179}, [{x, 0}, {atom, ok}]}.
    {move, {y, 14}, {y, 2}}.
    {jump, {f, 180}}.
  {label, 179}.
    {move, {y, 12}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 180}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 176}}.
  {label, 177}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nil, {f, 178}, [{x, 0}]}.
    {jump, {f, 175}}.
  {label, 178}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 9}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 175}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 182}}.
  {label, 182}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [binary]}, {x, 1}}.
    {call_ext, 2, {extfunc, compile, forms, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 183}, [{x, 0}]}.
    {test, test_arity, {f, 183}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 183}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 1}}.
    {move, {y, 11}, {y, 2}}.
    {jump, {f, 184}}.
  {label, 183}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 184}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [98, 112, 95, 115, 105, 103, 110, 97, 108, 95, 104, 97, 110, 100, 108, 101, 114, 46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 185}, [{x, 0}]}.
    {test, test_arity, {f, 185}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 185}, [{x, 0}, {atom, module}]}.
    {jump, {f, 186}}.
  {label, 185}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 186}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 160}}.
  {label, 161}.
    {move, {atom, ok}, {y, 7}}.
    {jump, {f, 160}}.
  {label, 160}.
    {move, {atom, erl_signal_server}, {x, 0}}.
    {call_ext, 1, {extfunc, gen_event, which_handlers, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {atom, bp_signal_handler}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 189}, [{x, 0}, {atom, true}]}.
    {move, {atom, ok}, {y, 7}}.
    {jump, {f, 188}}.
  {label, 189}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 190}, [{x, 0}, {atom, false}]}.
    {'catch', {y, 15}, {f, 191}}.
    {move, {atom, erl_signal_server}, {x, 0}}.
    {move, {atom, erl_signal_handler}, {x, 1}}.
    {move, nil, {x, 2}}.
    {call_ext, 3, {extfunc, gen_event, delete_handler, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
  {label, 191}.
    {catch_end, {y, 15}}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 193}}.
  {label, 193}.
    {move, {atom, erl_signal_server}, {x, 0}}.
    {move, {atom, bp_signal_handler}, {x, 1}}.
    {move, nil, {x, 2}}.
    {call_ext, 3, {extfunc, gen_event, add_handler, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 194}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 195}}.
  {label, 194}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 195}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 188}}.
  {label, 190}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 188}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_signal}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_signal}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 4}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, handle}, {x, 1}}.
    {call_ext, 2, {extfunc, os, set_signal, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 196}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 197}}.
  {label, 196}.
    {move, {y, 6}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 197}.
    {move, {literal, {ok, 0}}, {y, 5}}.
    {try_end, {y, 16}}.
    {jump, {f, 159}}.
  {label, 158}.
    {try_case, {y, 16}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 4, 0}.
    {put_list, {y, 9}, nil, {x, 0}}.
    {put_list, {literal, <<"other|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 198}}.
  {label, 198}.
  {label, 159}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 17}.
    return.

{function, '__bp_tpl_6', 2, 137}.
  {label, 136}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_6'}, 2}.
  {label, 137}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 141}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_7-t/2-fun-0-', 2, 207}.
  {label, 206}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_7-t/2-fun-0-'}, 2}.
  {label, 207}.
    {allocate, 14, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, <<"/">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, find, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{x, 0}, {atom, nomatch}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, os, find_executable, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 210}}.
  {label, 211}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, filelib, is_file, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 214}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 213}}.
  {label, 214}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 215}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 7}}.
    {jump, {f, 213}}.
  {label, 215}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 213}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 210}}.
  {label, 210}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 217}}.
  {label, 217}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 219}, [{x, 0}, {atom, false}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {put_list, {literal, <<"notfound|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 14}.
    return.
  {label, 219}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, file, read_file_info, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 222}, [{x, 0}]}.
    {test, test_arity, {f, 222}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {get_tuple_element, {x, 0}, 1, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 222}, [{x, 0}, {atom, ok}]}.
    {move, {y, 6}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {bif, element, {f, 222}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {atom, regular}, {x, 1}}.
    {test, is_eq_exact, {f, 222}, [{x, 0}, {x, 1}]}.
    {move, {integer, 8}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {bif, element, {f, 222}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 73}, {x, 1}}.
    {gc_bif, 'band', {f, 222}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 222}, [{x, 0}, {x, 1}]}.
    {jump, {f, 223}}.
  {label, 223}.
    {'try', {y, 13}, {f, 224}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, spawn_executable}, {y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, nil, {y, 9}}.
    {move, {y, 3}, {y, 10}}.
  {label, 227}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nonempty_list, {f, 228}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 11}, {y, 10}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 2, 0}.
    {put_list, {y, 12}, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {jump, {f, 227}}.
  {label, 228}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 229}, [{x, 0}]}.
    {jump, {f, 226}}.
  {label, 229}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 10}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 226}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, args}, {y, 10}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 8, 0}.
    {put_list, {y, 9}, nil, {x, 0}}.
    {put_list, {atom, stderr_to_stdout}, {x, 0}, {x, 0}}.
    {put_list, {atom, exit_status}, {x, 0}, {x, 0}}.
    {put_list, {atom, binary}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, open_port, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 9}}.
    {try_end, {y, 13}}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 1}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 7}}.
    {jump, {f, 230}}.
  {label, 230}.
    {jump, {f, 225}}.
  {label, 224}.
    {try_case, {y, 13}}.
    {move, {x, 0}, {y, 8}}.
    {move, {x, 1}, {y, 9}}.
    {move, {x, 2}, {y, 10}}.
    {move, {y, 9}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 11}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 4, 0}.
    {put_list, {y, 11}, nil, {x, 0}}.
    {put_list, {literal, <<"other|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 11}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 11}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 7}}.
    {jump, {f, 232}}.
  {label, 232}.
  {label, 225}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 14}.
    return.
  {label, 222}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 234}, [{x, 0}]}.
    {test, test_arity, {f, 234}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 234}, [{x, 0}, {atom, ok}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {put_list, {literal, <<"denied|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 14}.
    return.
  {label, 234}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 235}, [{x, 0}, {literal, {error, enoent}}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {put_list, {literal, <<"notfound|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 14}.
    return.
  {label, 235}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 236}, [{x, 0}]}.
    {test, test_arity, {f, 236}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 236}, [{x, 0}, {atom, error}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 2}, nil, {x, 0}}.
    {put_list, {literal, <<"denied|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 6}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 14}.
    return.
  {label, 236}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_7', 2, 203}.
  {label, 202}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_7'}, 2}.
  {label, 203}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 207}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_8', 1, 240}.
  {label, 239}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_8'}, 1}.
  {label, 240}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, port_info, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, os_pid}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, proplists, get_value, 2}, 2}.

{function, '__bp_tpl_9-t/3-fun-0-', 3, 251}.
  {label, 250}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_9-t/3-fun-0-'}, 3}.
  {label, 251}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 255}}.
  {label, 255}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 257}}.
  {label, 257}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 259}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 258}}.
  {label, 259}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 260}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 258}}.
  {label, 260}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 258}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 262}}.
  {label, 262}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 264}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 263}}.
  {label, 264}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 265}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 263}}.
  {label, 265}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 263}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 267}}.
  {label, 267}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_9', 3, 247}.
  {label, 246}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_9'}, 3}.
  {label, 247}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 251}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_10-t/2-fun-0-', 2, 273}.
  {label, 272}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_10-t/2-fun-0-'}, 2}.
  {label, 273}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 277}}.
  {label, 277}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 279}}.
  {label, 279}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 281}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 280}}.
  {label, 281}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 282}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 280}}.
  {label, 282}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 280}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 284}}.
  {label, 284}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_10', 2, 269}.
  {label, 268}.
    {func_info, {atom, std@io@process}, {atom, '__bp_tpl_10'}, 2}.
  {label, 269}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 273}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
