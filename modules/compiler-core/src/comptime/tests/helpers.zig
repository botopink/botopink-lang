//! Shared test harness for the comptime stage (moved from tests.zig).
//! Pure harness module: imports + `pub fn`/data helpers, no test blocks.

const std = @import("std");
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
const hostRuntime = @import("../runtime/runtime.zig");
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

pub fn buildRootPathFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const slug = comptime slugFromSrc(loc);
    return comptime std.fmt.comptimePrint(".botopinkbuild/comptime/{s}", .{slug});
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

    var build_root_buf: [512]u8 = undefined;
    const build_root_path = try std.fmt.bufPrint(&build_root_buf, ".botopinkbuild/comptime/{s}", .{base_slug});

    // The session is compiled once per comptime runtime (front 18 step 4):
    // the AST is recorded from the BEAM pass and must be the same text on
    // wat; each pass's decorator/template exchanges are recorded under
    // `comptime/runtime/<runtime>/`.
    const prev_rt = hostRuntime.force(.beam);
    defer _ = hostRuntime.force(prev_rt);
    var session = try comptimeMod.compile(allocator, modules, io, build_root_path, null);
    defer session.deinit(allocator);

    var outputs = std.ArrayList(comptimeMod.ComptimeOutput).empty;
    defer outputs.deinit(allocator);
    for (session.outputs.items) |output| {
        try outputs.append(allocator, output);
    }

    _ = hostRuntime.force(.wat);
    var wat_session = try comptimeMod.compile(allocator, modules, io, build_root_path, null);
    defer wat_session.deinit(allocator);
    _ = hostRuntime.force(.beam);

    // One snapshot per test, under `comptime/ast/`. The AST snapshot never
    // included the per-runtime script, so the four `comptime/{node,erlang,wasm,
    // beam}/…` copies this used to write were byte-identical by construction.
    // Record the mismatch instead of returning it: the `.new` sibling is already
    // on disk and the compile-expectation checks below have their own say.
    var first_err: ?anyerror = null;
    snapshot.assertComptimeAst(allocator, base_slug, outputs.items) catch |err| {
        first_err = err;
    };
    snapshot.assertComptimeExchange(allocator, "beam", base_slug, outputs.items) catch |err| {
        if (first_err == null) first_err = err;
    };
    snapshot.assertComptimeExchange(allocator, "wat", base_slug, wat_session.outputs.items) catch |err| {
        if (first_err == null) first_err = err;
    };
    {
        const beam_ast = try snapshot.buildSnapshotMulti(allocator, outputs.items);
        defer allocator.free(beam_ast);
        const wat_ast = try snapshot.buildSnapshotMulti(allocator, wat_session.outputs.items);
        defer allocator.free(wat_ast);
        if (!std.mem.eql(u8, beam_ast, wat_ast)) {
            std.debug.print("\n{s}: the typed AST differs between the comptime runtimes\n--- beam\n{s}\n--- wat\n{s}\n", .{ base_slug, beam_ast, wat_ast });
            if (first_err == null) first_err = error.ComptimeAstDiffersByRuntime;
        }
    }

    // H3/H9 — the snapshot above now carries a `COMPILE DIAGNOSTIC` section for
    // every module that did not compile. Report it as a failure too, so a test
    // whose source stopped compiling cannot keep passing on a recorded error.
    var failed = false;
    for (outputs.items) |output| {
        if (output.outcome != .ok) {
            failed = true;
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
    var program = try p.parse(alloc);
    defer program.deinit(alloc);

    var env = try inferMod.freshEnv(alloc, allocator);
    defer env.deinit();

    const result = inferMod.inferProgram(&env, program);
    try std.testing.expectError(error.TypeError, result);
    const err = env.lastError orelse return error.TestExpectedEqual;

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
    var program = try p.parse(alloc);
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
