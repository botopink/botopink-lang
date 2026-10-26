-module(std@io@process).
-compile({no_auto_import,[exit/1, spawn/2]}).
-export([onSignal/2, spawn/2, start/4, exit/1, cwd/0, platform/0, pid/0, run/2, runShell/1, signalName/1, processError/3, '__bp_priv__string_slice'/3]).

%% behavior string

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

%% import HostError

% Exit the current process with the given status code.

% Node: `process.exit(code)` (chained method — §A2 template).

% Erlang: `erlang:halt(code)` (bare BIF).

%% external fn exit -> erlang template
exit(Code) ->
    erlang:halt(Code).

% Current working directory of the host process.

% Node: `process.cwd()` (method on `process` — §A2 template).

% Erlang: `file:get_cwd()` returns `{ok, Path}` (charlist); the

% template extracts and stringifies it.

%% external fn cwd -> erlang template
cwd() ->
    (fun() -> {ok, __P} = file:get_cwd(), list_to_binary(__P) end)().

% Host platform string — `'linux'`, `'darwin'`, `'win32'`, etc.

% Node: bare `process.platform` (property access).

% Erlang: `os:type()` returns `{unix, linux}` / `{win32, nt}` /

% `{unix, darwin}`; the template extracts the SECOND element (the

% flavor, matching the Node `process.platform` shape) and stringifies

% it. Read-time match — the first element is the family (unix/win32).

%% external fn platform -> erlang template
platform() ->
    (fun() -> {_, __Flavor} = os:type(), atom_to_binary(__Flavor, utf8) end)().

% Host process id.

% Node: `process.pid` (property — i32 in JS, stored as Number).

% Erlang: `os:getpid()` returns a string list; the template parses

% it to an integer.

%% external fn pid -> erlang template
pid() ->
    list_to_integer(os:getpid()).

% ── 1.0.10-beta front 01 additions ──────────────────────────────────────────

% 

% Child processes. The five introspections above are not edited. Signals

% (`onSignal`) are not here: a closure handed to a host cell is unverified on

% the Erlang target (`language-gaps.md`).

% What a child process left behind. `stderr` is split out on Node; on Erlang

% the port folds it into `stdout` (`stderr_to_stdout`) and `stderr` is `""`

% — a caller that needs the two apart on both targets redirects through a

% file and says so.

%% type Exit: status, stdout, stderr

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

%% external fn run -> erlang template
run(Cmd, Args) ->
    '__bp_adopt'((fun(__BpA0, __BpA1) -> try ((fun(__C, __A) -> __X = case string:find(__C, <<"/">>) of nomatch -> os:find_executable(binary_to_list(__C)); _ -> binary_to_list(__C) end, case __X of false -> {error, enoent}; _ -> __P = open_port({spawn_executable, __X}, [binary, exit_status, stderr_to_stdout, {args, [binary_to_list(__Y) || __Y <- __A]}]), __L = fun __F(__Acc) -> receive {__Q, {data, __D}} when __Q =:= __P -> __F([__D | __Acc]); {__Q, {exit_status, __S}} when __Q =:= __P -> {__S, iolist_to_binary(lists:reverse(__Acc))} end end, {__St, __Out} = __L([]), {ok, #{status => __St, stdout => __Out, stderr => <<>>}} end end)(__BpA0, __BpA1)) of {ok, __BpV} -> {ok, __BpV}; {error, __BpR} -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpR])), <<"host">>, 'std@failure@@HostErrorName__v__error', undefined}}; __BpV -> {ok, __BpV} catch __BpC:__BpE:__BpS -> {error, {'std@failure@@HostError', unicode:characters_to_binary(io_lib:format("~tp", [__BpE])), <<"host">>, case __BpC of error -> 'std@failure@@HostErrorName__v__error'; throw -> 'std@failure@@HostErrorName__v__throw'; exit -> 'std@failure@@HostErrorName__v__exit' end, unicode:characters_to_binary(io_lib:format("~tp", [__BpS]))}} end end)(Cmd, Args), std@io@process@@Exit, [status, stdout, stderr]).

% Run `cmd` through `/bin/sh -c` and answer its output, stdout and stderr

% together. STATUS-LOSING on both targets: the answer is text only, so a

% failing command is indistinguishable from a quiet one — `os:cmd/1` answers

% output only on Erlang, and the Node cell matches it. Use `run` when the

% status matters.

% Node: `spawnSync('/bin/sh', ['-c', 'exec 2>&1; ' + cmd])`.

% Erlang: `os:cmd/1` (which runs `/bin/sh -c` and folds stderr in).

%% external fn runShell -> erlang template
runShell(Cmd) ->
    unicode:characters_to_binary(os:cmd(binary_to_list(Cmd))).

% ── signals and spawned children (decision 506 (1)) ────────────────────────────

% 

% `onSignal` runs a handler when the process receives a signal; `spawn` starts a child

% that shares the parent's terminal and answers a `Child` the program waits for, signals

% or asks to carry the parent's own signals over (`forwardSignals`). Every failure is a

% `ProcessError` of this module (decision 431-a). There is no wasm binding: a call is

% refused at the call (`std-unsupported-on-target`, decision 518 (4)).

% The signals a program can ask to hear about, and send a child.

%% type Signal
%%   Int
%%   Term
%%   Hup
%%   Winch

% The error of `onSignal`, `spawn` and `Child.kill`.

%% type ProcessError
%%   NotFound(command)
%%   PermissionDenied(command)
%%   NoSuchProcess(pid)
%%   Unsupported(message)
%%   Other(message)

signalName(S) ->
    case S of
        std@io@process@@Signal__v__int ->
            <<"SIGINT">>;
        std@io@process@@Signal__v__term ->
            <<"SIGTERM">>;
        std@io@process@@Signal__v__hup ->
            <<"SIGHUP">>;
        std@io@process@@Signal__v__winch ->
            <<"SIGWINCH">>
    end.

% The host cells answer `<kind>|<host text>` as their error, `kind` one of `notfound`,

% `denied`, `gone`, `unsupported`, `other`.

processError(Subject, Pid, Raw) ->
    Bar = (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> erlang:length(unicode:characters_to_list(binary:part(__S, 0, __P))) end end end)(Raw, <<"|">>),
    Kind = string_slice(Raw, 0, Bar),
    Message = string_slice(Raw, '__bp_int'((Bar + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/io/process.bp:151:33">>), undefined),
    case (Kind =:= <<"notfound">>) of
        true ->
            {std@io@process@@ProcessError__v__notfound, Subject};
        _ ->
            case (Kind =:= <<"denied">>) of
                true ->
                    {std@io@process@@ProcessError__v__permissiondenied, Subject};
                _ ->
                    case (Kind =:= <<"gone">>) of
                        true ->
                            {std@io@process@@ProcessError__v__nosuchprocess, Pid};
                        _ ->
                            case (Kind =:= <<"unsupported">>) of
                                true ->
                                    {std@io@process@@ProcessError__v__unsupported, Message};
                                _ ->
                                    {std@io@process@@ProcessError__v__other, Message}
                            end
                    end
            end
    end.

% Run `handler` each time the process receives `name`.

% Node: `process.on(name, handler)`; a signal listener does not keep the process alive, and

% it replaces the default action (the process no longer exits on `SIGTERM`).

% Erlang: `os:set_signal(Signal, handle)` sends the event to `erl_signal_server`, whose

% default handler stops the node on `sigterm`; the cell removes that handler and adds one of its

% own, a module (`bp_signal_handler`) compiled and loaded on first use that calls, in order, the

% funs kept for the signal in `persistent_term`. `SIGINT` is not an `os:set_signal` signal: the VM keeps it for its

% break handler, so it is `unsupported|…` there. `SIGWINCH` needs OTP 28.

%% external fn rawOnSignal -> erlang template

% Run `handler` when the process receives `s`. A handler stays for the life of the process,

% and several for one signal all run, in the order they were added. While one is installed the

% signal no longer ends the process: ending it is the handler's business (`exit`). `Int` is

% `Unsupported` on erlang and beam, where the VM keeps `SIGINT` for itself.

onSignal(S, Handler) ->
    case (fun(__Name, __F) -> __Sig = if __Name =:= <<"SIGTERM">> -> sigterm; __Name =:= <<"SIGHUP">> -> sighup; __Name =:= <<"SIGWINCH">> -> sigwinch; true -> unsupported end, case __Sig of unsupported -> {error, iolist_to_binary([<<"unsupported|">>, __Name, <<" cannot be caught on the Erlang VM">>])}; _ -> try case code:is_loaded(bp_signal_handler) of false -> __Src = "-module(bp_signal_handler). -behaviour(gen_event). -export([init/1, handle_event/2, handle_call/2]). init(S) -> {ok, S}. handle_event(E, S) -> [F() || F <- persistent_term:get({bp_signal, E}, [])], {ok, S}. handle_call(_, S) -> {ok, ok, S}.", {ok, __Toks, _} = erl_scan:string(__Src), __Split = fun __Sp([], []) -> []; __Sp([], __A) -> [lists:reverse(__A)]; __Sp([{dot, _} = __D | __T], __A) -> [lists:reverse([__D | __A]) | __Sp(__T, [])]; __Sp([__X | __T], __A) -> __Sp(__T, [__X | __A]) end, __Forms = [begin {ok, __Fm} = erl_parse:parse_form(__Ts), __Fm end || __Ts <- __Split(__Toks, [])], {ok, __M, __B} = compile:forms(__Forms, [binary]), {module, _} = code:load_binary(__M, "bp_signal_handler.erl", __B); _ -> ok end, case lists:member(bp_signal_handler, gen_event:which_handlers(erl_signal_server)) of true -> ok; false -> _ = (catch gen_event:delete_handler(erl_signal_server, erl_signal_handler, [])), ok = gen_event:add_handler(erl_signal_server, bp_signal_handler, []) end, persistent_term:put({bp_signal, __Sig}, persistent_term:get({bp_signal, __Sig}, []) ++ [__F]), ok = os:set_signal(__Sig, handle), {ok, 0} catch _:__E -> {error, iolist_to_binary([<<"other|">>, io_lib:format("~tp", [__E])])} end end end)(signalName(S), Handler) of
        {ok, _} ->
            {ok, undefined};
        {error, M} ->
            {error, processError(<<"">>, 0, M)}
    end.

% A child process handle: the OS process id and the host's own handle, opaque.

%% type Child: pid, handle

% The handle of `cmd` started with `args`, no shell, sharing the parent's standard streams.

% `cmd` is looked up on `PATH` when it has no `/`. Failure kinds are told before anything starts.

% Node: `child_process.spawn(file, args, { stdio: 'inherit' })`, the exit read from its `exit`

% event.

% Erlang: `open_port({spawn_executable, File}, [binary, exit_status, stderr_to_stdout, …])`.

%% external fn rawSpawn -> erlang template

%% external fn rawPid -> erlang template

%% external fn rawWait -> erlang template

%% external fn rawKill -> erlang template

% Start `cmd` with `args` (no shell) and answer its `Child` without waiting for it. The child

% shares the parent's terminal; `Child.wait` waits for it, `Child.kill` signals it and

% `Child.forwardSignals` carries the parent's signals to it. `NotFound` / `PermissionDenied`

% say why nothing started. `run` is the one that waits and captures the output.

spawn(Cmd, Args) ->
    case (fun(__C, __A) -> __X = case string:find(__C, <<"/">>) of nomatch -> os:find_executable(binary_to_list(__C)); _ -> case filelib:is_file(binary_to_list(__C)) of true -> binary_to_list(__C); false -> false end end, case __X of false -> {error, iolist_to_binary([<<"notfound|">>, __C])}; _ -> case file:read_file_info(__X) of {ok, __I} when element(3, __I) =:= regular, (element(8, __I) band 8#111) =/= 0 -> try open_port({spawn_executable, __X}, [binary, exit_status, stderr_to_stdout, {args, [binary_to_list(__Y) || __Y <- __A]}]) of __P -> {ok, __P} catch _:__E -> {error, iolist_to_binary([<<"other|">>, io_lib:format("~tp", [__E])])} end; {ok, _} -> {error, iolist_to_binary([<<"denied|">>, __C])}; {error, enoent} -> {error, iolist_to_binary([<<"notfound|">>, __C])}; {error, _} -> {error, iolist_to_binary([<<"denied|">>, __C])} end end end)(Cmd, Args) of
        {ok, H} ->
            {ok, {std@io@process@@Child, proplists:get_value(os_pid, erlang:port_info(H)), H}};
        {error, M} ->
            {error, processError(Cmd, 0, M)}
    end.

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

%% external fn rawStart (no erlang target)

%% external fn rawWaitCaptured (no erlang target)

%% external fn rawStartedPid (no erlang target)

% `kill` of a started child: the host cell of `Child.kill` (`rawKill`) reads only the handle.

%% external fn rawKillStarted (no erlang target)

% A started child whose output is captured: the OS process id and the host's own handle, opaque.

%% type Captured: pid, handle

% Start `cmd` with `args` (no shell) in `cwd` with `env` added to the parent's environment, and answer its

% `Captured` without waiting for it. `NotFound` / `PermissionDenied` say why nothing started.

% commonJS only (see above).

start(Cmd, Args, Cwd, Env) ->
    case erlang:error(unreachable) of
        {ok, H} ->
            {ok, {std@io@process@@Captured, erlang:error(unreachable), H}};
        {error, M} ->
            {error, processError(Cmd, 0, M)}
    end.

% ── tests ────────────────────────────────────────────────────────────────────








string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_adopt'(V, T, Ks) when erlang:is_map(V) -> erlang:list_to_tuple([T | [maps:get(K, V, undefined) || K <- Ks]]);
'__bp_adopt'(V, T, Ks) when erlang:is_list(V) -> ['__bp_adopt'(E, T, Ks) || E <- V];
'__bp_adopt'({ok, V}, T, Ks) -> {ok, '__bp_adopt'(V, T, Ks)};
'__bp_adopt'(V, _, _) -> V.

'__bp_priv__string_slice'(A0, A1, A2) -> string_slice(A0, A1, A2).
