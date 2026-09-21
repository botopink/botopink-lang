//! The resident node's server module, as Erlang source — the text `erlc`
//! compiles **at `zig build` time** (decision 83).
//!
//! It lives apart from `persistent_erl.zig` because two programs need it: the
//! runtime, which embeds the compiled `.beam` (`@embedFile`) and describes the
//! protocol, and `render_resident.zig`, the build-time tool that writes this
//! source (and the two preludes of `prelude.zig`) for `erlc`. The renderer must
//! not import the runtime — the runtime embeds what the renderer produces —
//! so the source sits in a file with no imports of its own.
//!
//! The protocol this module speaks is documented in `persistent_erl.zig`; the
//! `.beam` that embeds it is loaded into the node by the spawn bootstrap there,
//! never from the code path.

const std = @import("std");

/// The module atom, and the name of the `.erl`/`.beam` the build produces.
pub const module_name = "botopink_comptime_server";

/// Per-eval wall-clock budget enforced by the server (`safe_call`).
pub const eval_timeout_ms = 10_000;

/// The complete Erlang source: header, the timeout macro, the body.
pub const source = server_header ++ std.fmt.comptimePrint("-define(EVAL_TIMEOUT_MS, {d}).\n", .{eval_timeout_ms}) ++ server_body;

const server_header =
    \\-module(botopink_comptime_server).
    \\-export([start/0]).
    \\
;

const server_body =
    \\start() ->
    \\    %% Frames are raw bytes; `unicode` (the default) would UTF-8-encode the
    \\    %% 4-byte length prefix and corrupt any payload >= 128 bytes.
    \\    ok = io:setopts(standard_io, [{encoding, latin1}]),
    \\    %% stdout is the frame channel, and the default logger handler writes to
    \\    %% it: a SIGTERM notice or a `logger:error/1` in a comptime body would
    \\    %% land between two frames. Send every log event to stderr instead.
    \\    _ = logger:remove_handler(default),
    \\    ok = logger:add_handler(default, logger_std_h, #{config => #{type => standard_error}}),
    \\    loop().
    \\
    \\loop() ->
    \\    case read_frame() of
    \\        eof -> ok;
    \\        {1, PathBin} ->  %% eval: compile .erl file, run main/0
    \\            write_frame(compile_then(binary_to_list(PathBin), fun(Mod) -> safe_call(Mod, []) end)),
    \\            loop();
    \\        {2, PathBin} ->  %% load: compile .erl file, answer the module atom
    \\            write_frame(compile_then(binary_to_list(PathBin), fun atom_to_binary/1)),
    \\            loop();
    \\        {3, Payload} ->  %% call: <<NameLen:16, Name, ExternalTerm>> -> main/1
    \\            <<NameLen:16/unsigned-big-integer, Rest/binary>> = Payload,
    \\            <<NameBin:NameLen/binary, ArgBin/binary>> = Rest,
    \\            Mod = binary_to_atom(NameBin, latin1),
    \\            write_frame(safe_call(Mod, [binary_to_term(ArgBin)])),
    \\            loop();
    \\        {4, Payload} ->  %% load: <<NameLen:16, Name, Beam>> -> code:load_binary, answer the atom
    \\            <<NameLen:16/unsigned-big-integer, Rest/binary>> = Payload,
    \\            <<NameBin:NameLen/binary, Beam/binary>> = Rest,
    \\            write_frame(load_beam(binary_to_atom(NameBin, latin1), Beam)),
    \\            loop()
    \\    end.
    \\
    \\%% Load `.beam` bytes assembled by the compiler (no source, no `compile:file`),
    \\%% then answer the module atom. The loader's rejection (`badfile`, an opcode
    \\%% above what this release knows) is reported on the compile-error channel:
    \\%% to the evaluators it is the same event a rejected `.erl` was.
    \\load_beam(Mod, Beam) ->
    \\    _ = code:purge(Mod),
    \\    case code:load_binary(Mod, "", Beam) of
    \\        {module, Mod} -> atom_to_binary(Mod);
    \\        {error, Reason} ->
    \\            io_lib:format("__BP_ERL_COMPILE_ERROR__:~p", [{load_binary, Mod, Reason}])
    \\    end.
    \\
    \\%% Compile and load `Path`, then answer `Then(Mod)`; a compiler rejection is
    \\%% the error frame instead. `code:purge/1` drops a previous version of the
    \\%% same atom before it becomes old code: one module now serves every call
    \\%% site of a declaration, so a reload means the declaration itself changed.
    \\compile_then(Path, Then) ->
    \\    case compile:file(Path, [binary, return]) of
    \\        {ok, Mod, Beam} -> load_then(Mod, Beam, Then);
    \\        {ok, Mod, Beam, _Warnings} -> load_then(Mod, Beam, Then);
    \\        {error, Errors, Warnings} ->
    \\            io_lib:format("__BP_ERL_COMPILE_ERROR__:~p", [{Errors, Warnings}])
    \\    end.
    \\
    \\load_then(Mod, Beam, Then) ->
    \\    _ = code:purge(Mod),
    \\    {module, _} = code:load_binary(Mod, "", Beam),
    \\    Then(Mod).
    \\
    \\%% `Mod:main(Args…)` runs in a monitored process so a runaway comptime body
    \\%% (infinite loop, blocked receive) is killed after the timeout instead of
    \\%% wedging the server — and with it every later eval of this compiler run.
    \\%% Its group leader is `standard_error`, not the server's (`user`, the frame
    \\%% channel): `io:format/1`, `io:get_line/1` and every process it spawns talk
    \\%% to stderr, so a printing body cannot desynchronise the frame stream.
    \\safe_call(Mod, Args) ->
    \\    {Pid, Ref} = spawn_monitor(fun() ->
    \\        group_leader(whereis(standard_error), self()),
    \\        Result = try {ok, apply(Mod, main, Args)}
    \\        catch
    \\            Class:Reason:Stack ->
    \\                {error, io_lib:format("__BP_ERL_RUNTIME_ERROR__:~p:~p~n~p", [Class, Reason, Stack])}
    \\        end,
    \\        exit({bp_result, Result})
    \\    end),
    \\    receive
    \\        {'DOWN', Ref, process, Pid, {bp_result, {ok, Value}}} -> Value;
    \\        {'DOWN', Ref, process, Pid, {bp_result, {error, Message}}} -> Message;
    \\        {'DOWN', Ref, process, Pid, Other} ->
    \\            io_lib:format("__BP_ERL_RUNTIME_ERROR__:exit:~p", [Other])
    \\    after ?EVAL_TIMEOUT_MS ->
    \\        exit(Pid, kill),
    \\        receive {'DOWN', Ref, process, Pid, _} -> ok end,
    \\        io_lib:format("__BP_ERL_RUNTIME_ERROR__:timeout:main did not return within ~pms", [?EVAL_TIMEOUT_MS])
    \\    end.
    \\
    \\read_frame() ->
    \\    case file:read(standard_io, 4) of
    \\        {ok, RawLen} ->
    \\            LenBin = if is_binary(RawLen) -> RawLen; true -> list_to_binary(RawLen) end,
    \\            <<Len:32/unsigned-big-integer>> = LenBin,
    \\            case file:read(standard_io, Len) of
    \\                {ok, RawPayload} ->
    \\                    PayloadBin = if is_binary(RawPayload) -> RawPayload; true -> list_to_binary(RawPayload) end,
    \\                    <<Cmd:8, Rest/binary>> = PayloadBin,
    \\                    {Cmd, Rest};
    \\                eof -> eof;
    \\                _ -> eof
    \\            end;
    \\        eof -> eof;
    \\        _ -> eof
    \\    end.
    \\
    \\%% Every response is exactly one frame. A `main` result that is not iodata
    \\%% becomes a runtime error frame rather than crashing the server.
    \\write_frame(Data) ->
    \\    B = try iolist_to_binary(Data)
    \\        catch _:_ ->
    \\            iolist_to_binary(io_lib:format("__BP_ERL_RUNTIME_ERROR__:bad_result:~p", [Data]))
    \\        end,
    \\    Len = byte_size(B),
    \\    file:write(standard_io, <<Len:32/unsigned-big-integer, B/binary>>).
;
