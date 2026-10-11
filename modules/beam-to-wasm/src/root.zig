//! beam-to-wasm — `.beam` bytecode translated to wasm (decisions 434 (3),
//! 438).
//!
//! A standalone utility: `.beam` files in — any, whatever compiled them
//! (`erlc`, botopink's own assembler, Elixir's, Gleam's) — wasm functions
//! out, whole module by module (`translateSet`), a call from one module of
//! the set to a function another exports followed. It reads the chunks
//! (`chunks.zig`) and the instruction stream (`code.zig`) and lowers each
//! function (`lower.zig`) to wasm over a runtime's term ABI (`ir.zig`,
//! `lower.runtime`); a BIF or OTP call binds to the export the caller's
//! table names (`Bif`) — the comptime runtime's, whose OTP functions are
//! std-wasm's implementations, never OTP's own `.beam`. It knows nothing of
//! botopink the language: it imports Zig's `std` alone (and may import
//! std-wasm, nothing else — root `build.zig` checks the module graph).
//!
//! Anything it does not convert — an opcode, a call nothing serves, an
//! operand or a literal of another kind — refuses the function that holds
//! it, naming what is missing (`ir.Function.refused`); the module still
//! translates, and the refusal reaches a caller only when the function is
//! reached (`refusalReaching`).
const std = @import("std");

pub const chunks = @import("chunks.zig");
pub const code = @import("code.zig");
pub const ir = @import("ir.zig");
pub const lower = @import("lower.zig");

pub const Bif = lower.Bif;
pub const runtime = lower.runtime;

/// What is not converted, and where: `what` names it (`opcode 4 (call)`,
/// `` `re:run/3` ``, a malformed file); `module` and `function` locate it
/// when it is a function's.
pub const Refusal = struct {
    what: []const u8,
    module: []const u8 = "",
    /// `<name>/<arity>`.
    function: []const u8 = "",

    pub fn format(r: Refusal, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.writeAll(r.what);
        if (r.function.len > 0) try w.print(" in `{s}:{s}`", .{ r.module, r.function });
    }
};

pub const Result = union(enum) {
    ok: ir.Module,
    refused: Refusal,
};

pub const SetResult = union(enum) {
    /// One module per file, in the order given.
    ok: []const ir.Module,
    refused: Refusal,
};

/// Translate the `.beam` files `files` as one set: a call from one to a
/// function another exports is a `call` of it; any other call binds through
/// `bifs`. Refused as a whole only for a file that does not read as BEAM,
/// or two files of one module; a function that does not convert carries its
/// refusal. Everything answered lives in `arena`.
pub fn translateSet(arena: std.mem.Allocator, files: []const []const u8, bifs: []const Bif) error{OutOfMemory}!SetResult {
    const beams = try arena.alloc(chunks.Beam, files.len);
    for (files, beams) |bytes, *b| b.* = chunks.read(arena, bytes) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        error.BadBeam => return .{ .refused = .{ .what = "a file that does not read as BEAM" } },
    };
    for (beams, 0..) |b, i| for (beams[0..i]) |a| {
        if (std.mem.eql(u8, a.moduleName(), b.moduleName()))
            return .{ .refused = .{ .what = try std.fmt.allocPrint(arena, "two files of module `{s}`", .{b.moduleName()}) } };
    };
    const out = try arena.alloc(ir.Module, beams.len);
    for (beams, out) |b, *m| {
        const decoded = code.decode(arena, b.code) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            error.BadBeam => return .{ .refused = .{ .what = "a Code chunk that does not decode", .module = b.moduleName() } },
        };
        if (decoded.unknown) |op| return .{ .refused = .{
            .what = try std.fmt.allocPrint(arena, "opcode {d}, which genop.tab (OTP 28) does not number", .{op}),
            .module = b.moduleName(),
        } };
        var l: lower.Lowerer = .{ .ar = arena, .beam = b, .modules = beams, .bifs = bifs };
        const functions = l.lowerAll(decoded.instrs) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            error.Refused => return .{ .refused = .{ .what = l.refusal, .module = b.moduleName() } },
        };
        m.* = .{ .name = b.moduleName(), .functions = functions };
    }
    return .{ .ok = out };
}

/// Translate one `.beam` file (a set of one).
pub fn translate(arena: std.mem.Allocator, bytes: []const u8, bifs: []const Bif) error{OutOfMemory}!Result {
    return switch (try translateSet(arena, &.{bytes}, bifs)) {
        .ok => |ms| .{ .ok = ms[0] },
        .refused => |r| .{ .refused = r },
    };
}

/// Function `function` (`<name>/<arity>`) of module `module` of `set`.
pub fn find(set: []const ir.Module, module: []const u8, function: []const u8) ?*const ir.Function {
    for (set) |m| if (std.mem.eql(u8, m.name, module)) return m.find(function);
    return null;
}

/// The refusal a call of `module:function` meets: the first function it
/// reaches — itself, or one it calls, in any module of `set` — that did not
/// convert, or a function no module of the set has; null when everything
/// it reaches converted.
pub fn refusalReaching(arena: std.mem.Allocator, set: []const ir.Module, module: []const u8, function: []const u8) error{OutOfMemory}!?Refusal {
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    var queue: std.ArrayListUnmanaged(ir.Call) = .empty;
    try queue.append(arena, .{ .module = module, .function = function, .arity = 0 });
    var i: usize = 0;
    while (i < queue.items.len) : (i += 1) {
        const c = queue.items[i];
        const key = try std.fmt.allocPrint(arena, "{s}:{s}", .{ c.module, c.function });
        if ((try seen.getOrPut(arena, key)).found_existing) continue;
        const f = find(set, c.module, c.function) orelse
            return .{ .what = try std.fmt.allocPrint(arena, "`{s}:{s}`, which no module given has", .{ c.module, c.function }) };
        if (f.refused) |why| return .{ .what = why, .module = c.module, .function = f.name };
        try callsIn(arena, f.body, &queue);
    }
    return null;
}

fn callsIn(arena: std.mem.Allocator, body: []const ir.Instr, out: *std.ArrayListUnmanaged(ir.Call)) error{OutOfMemory}!void {
    for (body) |i| switch (i) {
        .call => |c| try out.append(arena, c),
        .block => |b| try callsIn(arena, b.body, out),
        else => {},
    };
}

/// The fixtures the unit tests read, for a caller's own tests (compiler-core
/// runs the `erlc` ones on its comptime runtime). Referenced only by tests.
pub const testdata = struct {
    /// `erlc` (OTP 28, `+deterministic`) output of `testdata/erlc/*.erl`.
    pub const greeting = @embedFile("testdata/erlc/greeting.beam");
    pub const greeting_text = @embedFile("testdata/erlc/greeting_text.beam");
};

const test_bifs = [_]Bif{
    .{ .module = "erlang", .name = "iolist_to_binary", .arity = 1, .rt = "rt_erlang_iolist_to_binary" },
    .{ .module = "erlang", .name = "error", .arity = 1, .rt = "rt_error" },
    .{ .module = "lists", .name = "reverse", .arity = 1, .rt = "rt_lists_reverse" },
    .{ .module = "string", .name = "uppercase", .arity = 1, .rt = "rt_string_uppercase" },
    .{ .module = "string", .name = "titlecase", .arity = 1, .rt = "rt_string_titlecase" },
};

test {
    _ = chunks;
    _ = code;
}

test "translate: a cell the compiler assembled, one function over the measured subset" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const r = try translate(arena_state.allocator(), @embedFile("testdata/bp_cell_bang.beam"), &test_bifs);
    const m = r.ok;
    try std.testing.expectEqualStrings("bp_cell_bang", m.name);
    try std.testing.expectEqual(@as(usize, 1), m.functions.len);
    const f = m.functions[0];
    try std.testing.expectEqual(@as(?[]const u8, null), f.refused);
    try std.testing.expectEqualStrings("t/1", f.name);
    try std.testing.expectEqual(@as(u32, 1), f.arity);
    try std.testing.expectEqual(@as(u32, 2), f.y_regs);
    // pc = entry label 2, then the raise block, then the raised answer.
    try std.testing.expectEqual(ir.Instr{ .i32_const = 2 }, f.body[0]);
    try std.testing.expectEqualStrings("raise", f.body[2].block.label);
    try std.testing.expect(f.body[2].block.body[0].block.loop);
}

/// Every runtime call and translated-function call a body makes, in order.
fn calls(ar: std.mem.Allocator, body: []const ir.Instr, out: *std.ArrayListUnmanaged([]const u8)) !void {
    for (body) |i| switch (i) {
        .rt => |n| try out.append(ar, n),
        .call => |c| try out.append(ar, try std.fmt.allocPrint(ar, "{s}:{s}", .{ c.module, c.function })),
        .block => |b| try calls(ar, b.body, out),
        else => {},
    };
}

fn expectCalls(ar: std.mem.Allocator, f: ir.Function, want: []const []const u8) !void {
    var got: std.ArrayListUnmanaged([]const u8) = .empty;
    try calls(ar, f.body, &got);
    var filtered: std.ArrayListUnmanaged([]const u8) = .empty;
    // `nil` and `pending` are everywhere; the rest is the shape.
    for (got.items) |c| if (!std.mem.eql(u8, c, "rt_nil") and !std.mem.eql(u8, c, "rt_pending")) try filtered.append(ar, c);
    errdefer for (filtered.items) |c| std.debug.print("  {s}\n", .{c});
    try std.testing.expectEqual(want.len, filtered.items.len);
    for (want, filtered.items) |w, g| try std.testing.expectEqualStrings(w, g);
}

test "translate: call_ext binds the BIF, put_list conses, is_binary tests, literals materialise" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    const r = try translate(ar, @embedFile("testdata/bp_cell_wrap.beam"), &test_bifs);
    try expectCalls(ar, r.ok.functions[0], &.{
        "rt_function_clause", // label 1: func_info
        "rt_is", // label 2: is_binary
        "rt_bin", "rt_cons", // put_list <<">">>, nil
        "rt_cons", // put_list y0
        "rt_bin", "rt_cons", // put_list <<"<">>
        "rt_erlang_iolist_to_binary", // call_ext
        "rt_atom", "rt_error", // label 5: error(badarg)
    });
}

test "translate: a call the runtime has no BIF for refuses the function, named" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    const only_error = [_]Bif{test_bifs[1]};
    const m = (try translate(ar, @embedFile("testdata/bp_cell_bang.beam"), &only_error)).ok;
    try std.testing.expectEqualStrings("`erlang:iolist_to_binary/1`", m.functions[0].refused.?);
    const r = (try refusalReaching(ar, &.{m}, "bp_cell_bang", "t/1")).?;
    try std.testing.expectEqualStrings("`erlang:iolist_to_binary/1` in `bp_cell_bang:t/1`", try std.fmt.allocPrint(ar, "{f}", .{r}));
}

test "translate: an opcode outside the converted ones refuses the function, named" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    // The bang cell with its `allocate` (12, two operands) patched to
    // `send` (20, none) followed by `remove_message` (21, none).
    const original = @embedFile("testdata/bp_cell_bang.beam");
    const bytes = try ar.dupe(u8, original);
    const beam = try chunks.read(ar, original);
    const code_at = @intFromPtr(beam.code.ptr) - @intFromPtr(original.ptr);
    const at = std.mem.indexOfScalarPos(u8, bytes, code_at, 12).?;
    bytes[at] = 20;
    bytes[at + 1] = 21;
    bytes[at + 2] = 21;
    const m = (try translate(ar, bytes, &test_bifs)).ok;
    try std.testing.expectEqualStrings("opcode 20 (send)", m.functions[0].refused.?);
}

test "translate: not a BEAM file" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const r = try translate(arena_state.allocator(), "not beam", &test_bifs);
    try std.testing.expectEqualStrings("a file that does not read as BEAM", r.refused.what);
}

test "translateSet: erlc's modules, whole — a call between them followed, local and tail calls, OTP 28's compact atoms" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    const set = (try translateSet(ar, &.{ testdata.greeting, testdata.greeting_text }, &test_bifs)).ok;
    try std.testing.expectEqualStrings("greeting", set[0].name);
    try std.testing.expectEqualStrings("greeting_text", set[1].name);

    // hello/1: is_binary, the call into greeting_text, bs_create_bin.
    const hello = set[0].find("hello/1").?;
    try std.testing.expectEqual(@as(?[]const u8, null), hello.refused);
    try expectCalls(ar, hello.*, &.{
        "rt_function_clause",
        "rt_is",
        "greeting_text:title/1",
        "rt_bb_new",
        "rt_bin",
        "rt_bb_bin",
        "rt_bb_bin",
        "rt_bin",
        "rt_bb_bin",
        "rt_bb_end",
    });
    // shout_all/2: get_list, string:uppercase/1, a local tail call, is_nil.
    try expectCalls(ar, set[0].find("shout_all/2").?.*, &.{
        "rt_function_clause",
        "rt_is",
        "rt_hd",
        "rt_tl",
        "rt_string_uppercase",
        "rt_cons",
        "greeting:shout_all/2",
        "rt_is",
    });
    // count/2: get_tl, the `+` operator, call_only.
    try expectCalls(ar, set[0].find("count/2").?.*, &.{
        "rt_function_clause", "rt_is", "rt_tl", "rt_int", "rt_add", "greeting:count/2", "rt_is",
    });
    // greeting_text:title/1: is_eq_exact against a literal, call_ext_only.
    try expectCalls(ar, set[1].find("title/1").?.*, &.{
        "rt_function_clause", "rt_bin", "rt_eqx", "rt_bin", "rt_string_titlecase",
    });

    // module_info/0,1 call erlang:get_module_info/1,2, which nothing serves:
    // refused there, and only there.
    try std.testing.expectEqualStrings("`erlang:get_module_info/1`", set[0].find("module_info/0").?.refused.?);
    try std.testing.expectEqual(@as(?Refusal, null), try refusalReaching(ar, set, "greeting", "hello/1"));
    try std.testing.expectEqual(@as(?Refusal, null), try refusalReaching(ar, set, "greeting", "shout_all/1"));
    const mi = (try refusalReaching(ar, set, "greeting", "module_info/1")).?;
    try std.testing.expectEqualStrings("greeting", mi.module);
    try std.testing.expectEqualStrings("module_info/1", mi.function);
}

test "translateSet: a module not given is a call nothing serves, refused where it is made" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    // greeting alone: greeting_text:title/1 is no BIF and no module of the set.
    const set = (try translateSet(ar, &.{testdata.greeting}, &test_bifs)).ok;
    try std.testing.expectEqualStrings("`greeting_text:title/1`", set[0].find("hello/1").?.refused.?);
    // shout_all/1 does not reach it.
    try std.testing.expectEqual(@as(?Refusal, null), try refusalReaching(ar, set, "greeting", "shout_all/1"));
    const r = (try refusalReaching(ar, set, "greeting", "hello/1")).?;
    try std.testing.expectEqualStrings("`greeting_text:title/1` in `greeting:hello/1`", try std.fmt.allocPrint(ar, "{f}", .{r}));
}

test "translateSet: an OTP function the caller's runtime does not serve is refused, named" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    const set = (try translateSet(ar, &.{ testdata.greeting, testdata.greeting_text }, test_bifs[0..4])).ok;
    const r = (try refusalReaching(ar, set, "greeting", "hello/1")).?;
    try std.testing.expectEqualStrings("`string:titlecase/1` in `greeting_text:title/1`", try std.fmt.allocPrint(ar, "{f}", .{r}));
}

test "translateSet: two files of one module" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const r = try translateSet(arena_state.allocator(), &.{ testdata.greeting, testdata.greeting }, &test_bifs);
    try std.testing.expectEqualStrings("two files of module `greeting`", r.refused.what);
}
