//! Erlang comptime prelude — descriptor walkers and host functions.
//!
//! The WAT prelude in `wat_runtime.zig` (~160 lines of inline WAT) is replaced
//! by a Pure Erlang module compiled once and loaded into the persistent `erl`
//! process at warmup time. Template and decorator bodies compiled to Erlang
//! call these functions as `botopink_comptime_prelude:lookup(Desc, Name)`.
//!
//! ## Descriptor binary format
//!
//! ```
//! [text-len: i32][text bytes...]
//! [file-len: i32][file bytes...]
//! [line: i32][col: i32][multiline: i32]
//! [scope-count: i32][scope-entry...]
//!   scope-entry = [name-len: i32][name bytes...][kind: i32]
//! [parts-count: i32][part-entry...]
//!   part-entry = [kind: i32][text-len: i32][text bytes...]
//! ```
//!
//! All integers are 4-byte big-endian. Length-prefixed strings use the
//! same 4-byte big-endian convention.

const std = @import("std");

/// Erlang prelude module — descriptor walkers, error handling, and constructors.
/// Compiled once at warmup and loaded into the persistent `erl` process.
pub const source: []const u8 =
    \\-module(botopink_comptime_prelude).
    \\-export([
    \\    text/1, file/1, line/1, col/1, multiline/1,
    \\    context/1, lookup/2, bindings/1, parts/1,
    \\    fail_raw/3, compiler_error/1
    \\]).
    \\
    \\read_u32(<<N:32/unsigned-big-integer, _/binary>>) -> N.
    \\
    \\skip_str(<<Len:32/unsigned-big-integer, _:Len/binary, Rest/binary>>) -> Rest.
    \\
    \\read_str(<<Len:32/unsigned-big-integer, Str:Len/binary, Rest/binary>>) -> {Str, Rest}.
    \\
    \\text(Desc) ->
    \\    {Text, _} = read_str(Desc),
    \\    Text.
    \\
    \\file(Desc) ->
    \\    {_, AfterText} = read_str(Desc),
    \\    {File, _} = read_str(AfterText),
    \\    File.
    \\
    \\line(Desc) ->
    \\    {_, AfterText} = read_str(Desc),
    \\    {_, AfterFile} = read_str(AfterText),
    \\    <<Line:32/unsigned-big-integer, _/binary>> = AfterFile,
    \\    Line.
    \\
    \\col(Desc) ->
    \\    {_, AfterText} = read_str(Desc),
    \\    {_, AfterFile} = read_str(AfterText),
    \\    <<_:32/unsigned-big-integer, Col:32/unsigned-big-integer, _/binary>> = AfterFile,
    \\    Col.
    \\
    \\multiline(Desc) ->
    \\    {_, AfterText} = read_str(Desc),
    \\    {_, AfterFile} = read_str(AfterText),
    \\    <<_:64/unsigned-big-integer, ML:32/unsigned-big-integer, _/binary>> = AfterFile,
    \\    ML.
    \\
    \\context(Desc) ->
    \\    {Text, AfterText} = read_str(Desc),
    \\    {File, AfterFile} = read_str(AfterText),
    \\    <<Line:32/unsigned-big-integer, Col:32/unsigned-big-integer, ML:32/unsigned-big-integer, Rest/binary>> = AfterFile,
    \\    #{
    \\        text => Text,
    \\        file => File,
    \\        line => Line,
    \\        col => Col,
    \\        multiline => ML
    \\    }.
    \\
    \\lookup(Desc, Name) ->
    \\    {_, AfterText} = read_str(Desc),
    \\    {_, AfterFile} = read_str(AfterText),
    \\    <<_:96/unsigned-big-integer, ScopeCount:32/unsigned-big-integer, ScopeRest/binary>> = AfterFile,
    \\    lookup_scope(ScopeRest, ScopeCount, Name).
    \\
    \\lookup_scope(_Rest, 0, _Name) -> not_found;
    \\lookup_scope(Rest, Count, Name) ->
    \\    {EntryName, AfterName} = read_str(Rest),
    \\    <<_Kind:32/unsigned-big-integer, NextRest/binary>> = AfterName,
    \\    case EntryName =:= Name of
    \\        true -> {EntryName, _Kind};
    \\        false -> lookup_scope(NextRest, Count - 1, Name)
    \\    end.
    \\
    \\bindings(Desc) ->
    \\    {_, AfterText} = read_str(Desc),
    \\    {_, AfterFile} = read_str(AfterText),
    \\    <<_:96/unsigned-big-integer, ScopeCount:32/unsigned-big-integer, ScopeRest/binary>> = AfterFile,
    \\    read_bindings(ScopeRest, ScopeCount, []).
    \\
    \\read_bindings(_Rest, 0, Acc) -> lists:reverse(Acc);
    \\read_bindings(Rest, Count, Acc) ->
    \\    {Name, AfterName} = read_str(Rest),
    \\    <<Kind:32/unsigned-big-integer, NextRest/binary>> = AfterName,
    \\    read_bindings(NextRest, Count - 1, [{Name, Kind} | Acc]).
    \\
    \\parts(Desc) ->
    \\    {_, AfterText} = read_str(Desc),
    \\    {_, AfterFile} = read_str(AfterText),
    \\    <<_:96/unsigned-big-integer, ScopeCount:32/unsigned-big-integer, AfterScope/binary>> = AfterFile,
    \\    PartsStart = skip_scopes(AfterScope, ScopeCount),
    \\    <<PartsCount:32/unsigned-big-integer, PartsRest/binary>> = PartsStart,
    \\    read_parts(PartsRest, PartsCount, []).
    \\
    \\skip_scopes(Bin, 0) -> Bin;
    \\skip_scopes(Bin, N) ->
    \\    AfterName = skip_str(Bin),
    \\    <<_:32/unsigned-big-integer, Rest/binary>> = AfterName,
    \\    skip_scopes(Rest, N - 1).
    \\
    \\read_parts(_Rest, 0, Acc) -> lists:reverse(Acc);
    \\read_parts(Rest, Count, Acc) ->
    \\    <<Kind:32/unsigned-big-integer, PartRest/binary>> = Rest,
    \\    {Text, NextRest} = read_str(PartRest),
    \\    read_parts(NextRest, Count - 1, [{Kind, Text} | Acc]).
    \\
    \\fail_raw(Message, Param, Span) ->
    \\    throw({comptime_fail, Message, Param, Span}).
    \\
    \\compiler_error(Message) ->
    \\    fail_raw(Message, 0, 0).
;

// ── Build integration ─────────────────────────────────────────────────────────
// See persistent_erl.zig:ensureSpawned() — the prelude module is compiled and
// loaded at warmup time alongside the server module. Tests are deferred to Step 7
// (integration with template/decorator eval).
