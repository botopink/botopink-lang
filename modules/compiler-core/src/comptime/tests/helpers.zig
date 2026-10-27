//! Shared test harness for the comptime stage (moved from tests.zig).
//! Pure harness module: imports + `pub fn`/data helpers, no test blocks.

const std = @import("std");
const test_scratch = @import("test_scratch");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const snapMod = @import("../../utils/snap.zig");
const prettyMod = @import("../../utils/pretty.zig");
const T = @import(".././types.zig");
const envMod = @import("../env.zig");
const inferMod = @import("../infer.zig");
const comptimeMod = @import("../../comptime.zig");
const errorMod = @import("../error.zig");
const snapshot = @import("../snapshot.zig");
const replyOrder = @import("../runtime/reply_order.zig");
const Module = @import("../../module.zig").Module;
const format = @import("../../format.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;

pub fn slugify(comptime s: []const u8) []const u8 {
    const n: usize = comptime blk: {
        var count: usize = 0;
        var sep = true;
        for (s) |c| {
            if (std.ascii.isAlphanumeric(c)) {
                count += 1;
                sep = false;
            } else if (!sep) {
                count += 1;
                sep = true;
            }
        }
        if (sep and count > 0) count -= 1;
        break :blk count;
    };
    const S = struct {
        const data: [n]u8 = blk: {
            var buf: [n]u8 = undefined;
            var i: usize = 0;
            var sep = true;
            for (s) |c| {
                if (std.ascii.isAlphanumeric(c)) {
                    if (i < n) {
                        buf[i] = std.ascii.toLower(c);
                        i += 1;
                    }
                    sep = false;
                } else if (!sep) {
                    if (i < n) {
                        buf[i] = '_';
                        i += 1;
                    }
                    sep = true;
                }
            }
            break :blk buf;
        };
    };
    return &S.data;
}

pub fn slugFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const desc = comptime blk: {
        const fnName = loc.fn_name;
        const afterTest = if (std.mem.startsWith(u8, fnName, "test."))
            fnName["test.".len..]
        else
            fnName;
        break :blk if (std.mem.indexOf(u8, afterTest, ": ")) |i|
            afterTest[i + 2 ..]
        else
            afterTest;
    };
    return slugify(desc);
}

/// The build root of the test at `loc`: `comptime/<slug>` under this
/// process's `test_scratch` root, so two processes running the suite over one
/// checkout never share it (`scripts/check-test-scratch.sh`).
pub fn buildRootPathFromSrc(io: std.Io, comptime loc: std.builtin.SourceLocation) []const u8 {
    return test_scratch.path(io, "comptime/" ++ comptime slugFromSrc(loc));
}

/// This process's resident set in bytes (`/proc/self/statm`); null where the
/// file is not there.
pub fn residentBytes() ?usize {
    if (@import("builtin").os.tag != .linux) return null;
    const linux = std.os.linux;
    const rc = linux.open("/proc/self/statm", .{ .ACCMODE = .RDONLY }, 0);
    if (linux.errno(rc) != .SUCCESS) return null;
    const fd: i32 = @intCast(rc);
    defer _ = linux.close(fd);
    var buf: [128]u8 = undefined;
    const n = linux.read(fd, &buf, buf.len);
    if (linux.errno(n) != .SUCCESS) return null;
    var it = std.mem.tokenizeAny(u8, buf[0..n], " \n");
    _ = it.next() orelse return null;
    const pages = std.fmt.parseInt(usize, it.next() orelse return null, 10) catch return null;
    return pages * std.heap.pageSize();
}

/// Whether a comptime snapshot test tolerates a module that does not compile.
pub const CompileExpectation = enum {
    /// Default: a parse / type / validation error fails the test (spec 06, H3+H9).
    must_compile,
    /// The test is *about* a program that does not compile; the recorded
    /// `COMPILE DIAGNOSTIC` section is the assertion. Used for documented
    /// skips — always with a comment naming the missing feature.
    expect_compile_error,
};

pub fn assertComptimeAst(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
) !void {
    return assertComptimeAstExpecting(allocator, loc, modules, .must_compile);
}

/// `assertComptimeAst` for a source that is known not to compile: the snapshot
/// records the diagnostic and the test passes only while the program *keeps*
/// failing that way. Document the missing feature at the call site.
pub fn assertComptimeCompileError(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    return assertComptimeAstExpecting(
        allocator,
        loc,
        &.{.{ .path = "", .source = src }},
        .expect_compile_error,
    );
}

pub fn assertComptimeAstExpecting(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
    expectation: CompileExpectation,
) !void {
    const trace_prev = snapMod.traceEnter(loc);
    defer snapMod.traceLeave(trace_prev);
    const io = std.testing.io;
    const base_slug = comptime slugFromSrc(loc);

    const build_root_path = buildRootPathFromSrc(io, loc);

    var session = try comptimeMod.compile(allocator, modules, io, build_root_path);
    defer session.deinit(allocator);

    var outputs = std.ArrayList(comptimeMod.ComptimeOutput).empty;
    defer outputs.deinit(allocator);
    for (session.outputs.items) |output| {
        try outputs.append(allocator, output);
    }

    // One snapshot per test, under `comptime/ast/`. The AST snapshot never
    // included the per-runtime script, so the four `comptime/{node,erlang,wasm,
    // beam}/…` copies this used to write were byte-identical by construction.
    // Record the mismatch instead of returning it: the `.new` sibling is already
    // on disk and the compile-expectation checks below have their own say.
    var first_err: ?anyerror = null;
    snapshot.assertComptimeAst(allocator, base_slug, outputs.items) catch |err| {
        first_err = err;
    };
    snapshot.assertComptimeExchange(allocator, base_slug, outputs.items) catch |err| {
        if (first_err == null) first_err = err;
    };
    // H3/H9 — the snapshot above now carries a `COMPILE DIAGNOSTIC` section for
    // every module that did not compile. Report it as a failure too, so a test
    // whose source stopped compiling cannot keep passing on a recorded error.
    var failed = false;
    for (outputs.items) |output| {
        if (output.outcome != .ok) {
            failed = true;
            // C-21 — a type error the checker raises carries a location.
            if (output.outcome == .typeError and output.outcome.typeError.loc == null) {
                std.debug.print("\n{s}: module '{s}' raised an unlocated type error\n", .{ base_slug, output.name });
                if (first_err == null) first_err = error.UnlocatedTypeError;
            }
            if (expectation == .must_compile) {
                const file = try snapshot.moduleFile(allocator, output.name);
                defer allocator.free(file);
                const body = (try snapshot.renderOutcomeDiagnostic(allocator, output.src, output.outcome, file)).?;
                defer allocator.free(body);
                std.debug.print(
                    "\n{s}: module '{s}' did not compile:\n{s}\n" ++
                        "(use `assertComptimeCompileError` if the failure is the point of the test)\n",
                    .{ base_slug, output.name, body },
                );
            }
        }
    }
    if (failed and expectation == .must_compile) {
        if (first_err == null) first_err = error.ModuleDidNotCompile;
    }
    if (!failed and expectation == .expect_compile_error) {
        std.debug.print("\n{s}: expected a compile error, but every module compiled\n", .{base_slug});
        if (first_err == null) first_err = error.ExpectedCompileError;
    }

    if (first_err) |err| return err;
}

pub fn assertComptimeAstSingle(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    return assertComptimeAst(allocator, loc, &.{.{ .path = "", .source = src }});
}

/// Shared with `comptime/snapshot.zig` (the compile-diagnostic sections use the
/// same line lookup).
pub const getSourceLine = snapshot.getSourceLine;

/// `----- SOURCE CODE` + `----- ERROR` wrapper around the shared diagnostic
/// body. The 106 `comptime/*/errors/` snapshots are recorded from this text.
pub fn renderTypeError(
    allocator: std.mem.Allocator,
    src: []const u8,
    err: errorMod.TypeError,
) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    // ----- SOURCE CODE section
    try out.appendSlice(allocator, "----- SOURCE CODE\n");
    try out.appendSlice(allocator, src);
    if (src.len > 0 and src[src.len - 1] != '\n') try out.append(allocator, '\n');
    try out.appendSlice(allocator, "\n----- ERROR\n");

    // A single-source test compiles module `main` (path ""), as every
    // `----- SOURCE CODE -- main.bp` header says.
    const body = try snapshot.renderTypeErrorBody(allocator, src, err, "main.bp");
    defer allocator.free(body);
    try out.appendSlice(allocator, body);

    return try out.toOwnedSlice(allocator);
}

pub fn assertTypeErrorSnap(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    const trace_prev = snapMod.traceEnter(loc);
    defer snapMod.traceLeave(trace_prev);
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try @import("../std_calls.zig").expand(alloc, try p.parse(alloc), null);
    defer program.deinit(alloc);

    var env = try inferMod.freshEnv(alloc, allocator);
    defer env.deinit();

    const result = inferMod.inferProgram(&env, program);
    try std.testing.expectError(error.TypeError, result);
    const err = env.lastError orelse return error.TestExpectedEqual;
    // C-21 — every type error carries a location; the snapshot's box is it.
    try std.testing.expect(err.loc != null);

    const desc = try renderTypeError(allocator, src, err);
    defer allocator.free(desc);

    const base_slug = comptime slugFromSrc(loc);

    // One snapshot per test, under `comptime/errors/`. Error messages are
    // runtime-agnostic (type inference happens before codegen), so the
    // `node/errors/` and `erlang/errors/` copies this used to write were
    // byte-identical by construction.
    var snap_buf: [512]u8 = undefined;
    const snap_slug = try std.fmt.bufPrint(&snap_buf, "comptime/errors/{s}", .{base_slug});
    try snapMod.checkText(allocator, snap_slug, desc);
}

pub fn assertInfersOk(
    allocator: std.mem.Allocator,
    src: []const u8,
) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try @import("../std_calls.zig").expand(alloc, try p.parse(alloc), null);
    defer program.deinit(alloc);

    var env = try inferMod.freshEnv(alloc, allocator);
    defer env.deinit();

    _ = inferMod.inferProgram(&env, program) catch |err| {
        if (env.lastError) |te| {
            const desc = try renderTypeError(allocator, src, te);
            defer allocator.free(desc);
            std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
        }
        return err;
    };
}

/// How many `return` / `throw` sites inference recorded with the lowering
/// `kind` (`Env.result_jump_lowerings`) — `src` must type-check. A checker
/// test reads off it which jumps it made the enclosing function's.
pub fn resultJumpLoweringCount(
    allocator: std.mem.Allocator,
    src: []const u8,
    kind: envMod.ResultJumpLowering,
) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try @import("../std_calls.zig").expand(alloc, try p.parse(alloc), null);
    defer program.deinit(alloc);

    var env = try inferMod.freshEnv(alloc, allocator);
    defer env.deinit();
    _ = try inferMod.inferProgram(&env, program);

    var n: usize = 0;
    var it = env.result_jump_lowerings.valueIterator();
    while (it.next()) |v| {
        if (v.* == kind) n += 1;
    }
    return n;
}

/// Front 14 step 3 — the term round trip, read off the replies: `modules` is
/// compiled (the capture or the `@Decl` handle reaches the wasm comptime
/// runtime as external-term bytes in its linear memory, `codegen/beam/etf.zig`),
/// every module must compile, at least one evaluation must run, and each
/// evaluation's reply — the `COMPTIME REPLY` section, keys sorted — is
/// returned in evaluation order (owned by `arena`), for the caller's own
/// assertions on what the body read back.
pub fn canonicalReplies(
    allocator: std.mem.Allocator,
    arena: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
) ![]const []const u8 {
    const io = std.testing.io;
    const build_root = buildRootPathFromSrc(io, loc);
    var session = try comptimeMod.compile(allocator, modules, io, build_root);
    defer session.deinit(allocator);

    var replies: std.ArrayListUnmanaged([]const u8) = .empty;
    for (session.outputs.items) |o| {
        if (o.outcome != .ok) {
            std.debug.print("\nmodule '{s}' did not compile ({s})\n", .{ o.name, @tagName(o.outcome) });
            return error.ModuleDidNotCompile;
        }
        for (o.outcome.ok.comptime_traces) |e| {
            // The section a snapshot records: the reply read with sorted keys
            // (`runtime/reply_order.zig`); a non-JSON reply as is.
            try replies.append(arena, (try replyOrder.canonical(arena, e.reply)) orelse e.reply);
        }
    }
    try std.testing.expect(replies.items.len > 0);
    return replies.items;
}
