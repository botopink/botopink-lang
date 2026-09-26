//! A generated comptime module, made loadable on the BEAM runtime without the
//! Erlang compiler: its text is parsed (`../wat/erl_parse.zig`, the reader
//! the wat runtime uses), lowered to BEAM instructions (`lower.zig`) and
//! assembled into `.beam` bytes (`codegen/beam/beam_file.zig`), which the
//! resident node loads with cmd 4 (`persistent_beam.evalBeamWithArg`). The
//! same instructions rendered as text (`codegen/beam/asm_text.zig`) are the
//! `COMPTIME BEAM ASSEMBLY` listing. Front 14 step 3, front 18 step 1b.
//!
//! The result is cached by module atom — the content hash of the text, so a
//! hit is the same program — for the life of the process.
//!
//! A construct the lowering does not take is a **refusal** naming it
//! (`Built.refused`), which the runtime reports as the module not compiling —
//! the channel the wat runtime uses for its own refusals. There is no second
//! way to run a module: the `.erl` staging and `compile:file` are gone
//! (decision 67 — refuse rather than fall back). `counts` is how many
//! distinct modules this process lowered and refused.
const std = @import("std");
const ep = @import("../wat/erl_parse.zig");
const lower = @import("lower.zig");
const bf = @import("../../../codegen/beam/beam_file.zig");
const asmText = @import("../../../codegen/beam/asm_text.zig");

pub const Built = union(enum) {
    ok: struct {
        /// The `.beam` bytes, module atom = the evaluator's atom.
        beam: []const u8,
        /// The module as BEAM assembly, named by the evaluator's placeholder
        /// (`template_module` / `decorator_module`) so a listing does not
        /// change with the content hash.
        listing: []const u8,
    },
    /// What the lowering did not take, and where.
    refused: []const u8,
};

pub const Error = std.mem.Allocator.Error;

const cache_alloc = std.heap.page_allocator;
var cache_lock: std.atomic.Value(u8) = .init(0);
var cache: std.StringHashMapUnmanaged(Built) = .empty;
/// How many distinct modules this process refused (ran from source instead).
var refused_count: usize = 0;
/// How many distinct modules this process lowered.
var lowered_count: usize = 0;

fn lock() void {
    while (cache_lock.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
}

fn unlock() void {
    cache_lock.store(0, .release);
}

/// Distinct modules this process lowered to BEAM and refused, so far.
pub const Counts = struct { lowered: usize, refused: usize };

pub fn counts() Counts {
    lock();
    defer unlock();
    return .{ .lowered = lowered_count, .refused = refused_count };
}

/// Build (or fetch) the loadable form of module `module` whose Erlang text is
/// `code`; `placeholder` names it in the listing. Everything answered is
/// owned by the cache and lives for the process.
pub fn build(module: []const u8, placeholder: []const u8, code: []const u8) Error!Built {
    lock();
    defer unlock();
    if (cache.get(module)) |hit| return hit;
    var arena_state = std.heap.ArenaAllocator.init(cache_alloc);
    const built = try buildUncached(arena_state.allocator(), module, placeholder, code);
    switch (built) {
        .ok => lowered_count += 1,
        .refused => refused_count += 1,
    }
    try cache.put(cache_alloc, try cache_alloc.dupe(u8, module), built);
    return built;
}

fn buildUncached(ar: std.mem.Allocator, module: []const u8, placeholder: []const u8, code: []const u8) Error!Built {
    var pf: ep.Failure = .{};
    const parsed = ep.parseModule(ar, code, &pf) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.Unsupported => return .{ .refused = try std.fmt.allocPrint(ar, "{s} (line {d} of the generated module)", .{ pf.message, pf.line }) },
        error.Syntax => return .{ .refused = try std.fmt.allocPrint(ar, "the generated module did not read back: {s} at line {d}", .{ pf.message, pf.line }) },
    };
    var lf: lower.Failure = .{};
    const lowered = lower.lowerModule(ar, parsed, placeholder, &lf) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.Unsupported => return .{ .refused = lf.message },
    };

    var aw: std.Io.Writer.Allocating = .init(ar);
    asmText.writeModule(&aw.writer, lowered.module) catch |err| switch (err) {
        error.WriteFailed => return error.OutOfMemory,
        else => return .{ .refused = try std.fmt.allocPrint(ar, "the lowered module has no listing ({s})", .{@errorName(err)}) },
    };
    const beam = bf.assemble(ar, try renamed(ar, lowered.module, module)) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return .{ .refused = try std.fmt.allocPrint(ar, "the lowered module did not assemble ({s})", .{@errorName(err)}) },
    };
    return .{ .ok = .{ .beam = beam, .listing = aw.written() } };
}

/// `m` loaded as `name`: the module atom appears in each `func_info`.
fn renamed(ar: std.mem.Allocator, m: bf.Module, name: []const u8) Error!bf.Module {
    const functions = try ar.alloc(bf.Function, m.functions.len);
    for (m.functions, 0..) |f, i| {
        const code = try ar.dupe(bf.Instr, f.code);
        for (code) |*ins| {
            if (ins.op != .func_info) continue;
            const args = try ar.dupe(bf.Arg, ins.args);
            args[0] = bf.Arg.atomOf(name);
            ins.args = args;
        }
        functions[i] = f;
        functions[i].code = code;
    }
    return .{ .name = name, .functions = functions, .source_file = m.source_file };
}

// ── tests ────────────────────────────────────────────────────────────────────

const etf = @import("../etf.zig");
const Term = @import("../../../codegen/beam/term.zig").Term;

/// One module over the constructs whose meaning the lowering has to get
/// exactly right — each error reason, `andalso`'s `badarg`, a re-raise out of
/// a `try` whose clauses do not match, both comprehension filters, the binary
/// generator, a computed binary, a binary prefix pattern, a named `fun`
/// recursing in tail position, guard sequences, `-import`, a stack binding,
/// a string prefix pattern. The expected reply is what the same text
/// answers when `erlc` compiles it (OTP 29), pasted verbatim (`~w`, so it is
/// ASCII whatever the node's encoding).
const semantics_module =
        \\-module(bp_lower_semantics).
        \\-export([main/1]).
        \\-import(lists, [reverse/1]).
        \\
        \\main({N}) ->
        \\    io_lib:format("~w", [[
        \\        catching(fun() -> 1 + a end),
        \\        catching(fun() -> {ok, X} = {error, N}, X end),
        \\        catching(fun() -> case N of 0 -> zero end end),
        \\        catching(fun() -> if N > 100 -> big end end),
        \\        catching(fun() -> N andalso true end),
        \\        catching(fun() -> maps:get(k, #{}) end),
        \\        catching(fun() -> (#{a => 1})#{b := 2} end),
        \\        catching(fun() -> <<N/binary>> end),
        \\        catching(fun() -> throw({t, N}) end),
        \\        catching(fun() -> [X || X <- improper()] end),
        \\        catching(fun() -> [X || X <- [1, 2], length(X) > 0] end),
        \\        catching(fun() -> [X || X <- [1, 2], X] end),
        \\        rethrow(),
        \\        [{A, B} || A <- [1, 2, 3], B <- [a, b], A > 1, B =/= a],
        \\        [C || <<C/utf8>> <= <<"hé!"/utf8>>],
        \\        <<"x", (integer_to_binary(N))/binary, 300, $é/utf8>>,
        \\        prefix(<<"ab-rest">>), prefix(<<"zz">>), prefix(nope),
        \\        (fun Loop(0, Acc) -> Acc; Loop(I, Acc) -> Loop(I - 1, [I | Acc]) end)(5, []),
        \\        guard(3), guard(-1), guard(<<"s">>), guard([1]), guard(x),
        \\        reverse([1, 2, 3]),
        \\        #{k => N, "s" => [N | tl([0, 1])]},
        \\        stack(),
        \\        "abc" ++ tail("abcdef")
        \\    ]]).
        \\
        \\improper() -> [1 | 2].
        \\
        \\catching(F) -> try F() catch C:R -> {C, R} end.
        \\
        \\rethrow() ->
        \\    try try erlang:error(inner) catch throw:_ -> no end catch error:E -> {outer, E} end.
        \\
        \\prefix(<<"ab", Rest/binary>>) -> {ab, Rest};
        \\prefix(B) when is_binary(B) -> {other, byte_size(B)};
        \\prefix(_) -> none.
        \\
        \\guard(X) when is_integer(X), X > 0; is_binary(X) -> pos_or_bin;
        \\guard(X) when is_list(X) andalso length(X) =:= 1 -> one;
        \\guard(X) when not is_atom(X) -> neither;
        \\guard(_) -> atom.
        \\
        \\stack() -> try erlang:error(e) catch error:e:S -> is_list(S) end.
        \\
        \\tail("abc" ++ Rest) -> Rest.
;

const semantics_reply =
    \\[{error,badarith},{error,{badmatch,{error,7}}},{error,{case_clause,7}},{error,if_clause},{error,{badarg,7}},{error,{badkey,k}},{error,{badkey,b}},{error,badarg},{throw,{t,7}},{error,{bad_generator,2}},[],[],{outer,inner},[{2,b},{3,b}],[104,233,33],<<120,55,44,195,169>>,{ab,<<45,114,101,115,116>>},{other,2},none,[1,2,3,4,5],pos_or_bin,neither,pos_or_bin,one,atom,[3,2,1],#{k => 7,[115] => [7,1]},true,[97,98,99,100,101,102]]
;

test "beam lowering: a module assembled without erlc answers what erlc's build of it answers" {
    const persistent_beam = @import("../persistent_beam.zig");
    const allocator = std.testing.allocator;
    const built = try build("bp_lower_semantics", "bp_lower_semantics", semantics_module);
    const ok = switch (built) {
        .ok => |o| o,
        .refused => |why| {
            std.debug.print("refused: {s}\n", .{why});
            return error.TestUnexpectedResult;
        },
    };
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const arg = try etf.encode(arena_state.allocator(), Term.tupleOf(&.{Term.int(7)}));
    const response = try persistent_beam.evalBeamWithArg(allocator, std.testing.io, ok.beam, "bp_lower_semantics", arg);
    defer allocator.free(response.payload());
    try std.testing.expectEqual(std.meta.Tag(persistent_beam.Response).ok, std.meta.activeTag(response));
    try std.testing.expectEqualStrings(semantics_reply, response.payload());
    // The listing is the same module as `.S` text, named by the placeholder.
    try std.testing.expect(std.mem.startsWith(u8, ok.listing, "{module, bp_lower_semantics}.\n"));
    try std.testing.expect(std.mem.indexOf(u8, ok.listing, "{call_ext, 1, {extfunc, lists, reverse, 1}}") != null);
}

test "beam lowering: a construct outside the subset is refused by name, and cached" {
    const code =
        \\-module(bp_lower_refused).
        \\-export([main/1]).
        \\main(_) -> receive X -> X end.
    ;
    const first = try build("bp_lower_refused", "bp_lower_refused", code);
    try std.testing.expect(first == .refused);
    try std.testing.expect(std.mem.indexOf(u8, first.refused, "`receive`") != null);
    const again = try build("bp_lower_refused", "bp_lower_refused", code);
    try std.testing.expectEqual(first.refused.ptr, again.refused.ptr);
}
