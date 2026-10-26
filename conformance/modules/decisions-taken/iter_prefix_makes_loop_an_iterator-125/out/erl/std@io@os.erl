-module(std@io@os).
-export([hostname/0, arch/0, cpuCount/0, tmpdir/0, userInfo/0, eol/0, target/0]).

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

%% external fn hostname -> erlang template
hostname() ->
    (fun() -> {ok, __H} = inet:gethostname(), list_to_binary(__H) end)().

% Host CPU architecture string — `'x64'`, `'arm64'`, etc. std's one

% `arch`: `io.process` declared the same function (`process.arch`) and was

% folded here.

% Node: `require('os').arch()`.

% Erlang: `erlang:system_info(system_architecture)`.

%% external fn arch -> erlang template
arch() ->
    list_to_binary(erlang:system_info(system_architecture)).

% Count of logical CPU cores available to the runtime.

% Node: `require('os').cpus().length`.

% Erlang: `erlang:system_info(schedulers_online)` returns the count

% of online schedulers — the BEAM analogue of "available cores".

%% external fn cpuCount -> erlang template
cpuCount() ->
    erlang:system_info(schedulers_online).

% Host temp directory (an absolute path).

% Node: `require('os').tmpdir()`.

% Erlang: best-effort via the `TMPDIR` env var with a fallback to

% `/tmp` — matches the POSIX convention; on Windows the BEAM-side

% fallback would need `os:getenv("TEMP")` (deferred).

%% external fn tmpdir -> erlang template
tmpdir() ->
    (fun() -> case os:getenv("TMPDIR") of false -> <<"/tmp">>; __V -> list_to_binary(__V) end end)().

% Calling user's basic identity. Node returns a structured object; on

% Erlang there is no direct `os:userInfo` BIF so the template lifts the

% `USER` env var (falling back to `<<"unknown">>`) and reads the uid

% from `process_info` — best-effort, the Erlang side stays informative

% without claiming POSIX-grade accuracy. The Erlang term is the record's

% own run-time shape (13-module-identity decision 21): the tagged tuple

% `{'<module atom>@@<Type>', <fields in declared order>}`, which is

% what `u.username` reads a position out of.

%% type UserInfo: uid, username

%% external fn userInfo -> erlang template
userInfo() ->
    '__bp_adopt'((fun() -> __U = case os:getenv("USER") of false -> <<"unknown">>; __V -> list_to_binary(__V) end, {'std@io@os@@UserInfo', 0, __U} end)(), std@io@os@@UserInfo, [uid, username]).

% Platform line terminator — `"\n"` on POSIX, `"\r\n"` on Windows.

% Node reads `require('os').EOL`; Erlang branches on `os:type/0`.

%% external fn eol -> erlang template
eol() ->
    (fun() -> case os:type() of {win32, _} -> <<"\r\n">>; _ -> <<"\n">> end end)().

% The target the program runs on (decision 989 (7)): `commonJS`, `erlang`,

% `beam` or `wasm` — each target's own constant. The beam target reads the

% erlang cell and answers its own text instead: the assembler writes `beam`

% (`codegen/beam_asm.zig`, `os_target_template`). A run-time answer only: no

% comptime cell serves it, so a build body that reaches it is refused

% (decision 798 (4)) — comptime runs on wasm whatever the target.

%% external fn target -> erlang template
target() ->
    <<"erlang">>.

% ── tests ────────────────────────────────────────────────────────────────────









'__bp_adopt'(V, T, Ks) when erlang:is_map(V) -> erlang:list_to_tuple([T | [maps:get(K, V, undefined) || K <- Ks]]);
'__bp_adopt'(V, T, Ks) when erlang:is_list(V) -> ['__bp_adopt'(E, T, Ks) || E <- V];
'__bp_adopt'({ok, V}, T, Ks) -> {ok, '__bp_adopt'(V, T, Ks)};
'__bp_adopt'(V, _, _) -> V.
