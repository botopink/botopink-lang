//! Shared test harness for the codegen stage (moved from tests.zig).
//! Pure harness module: imports + `pub fn`/data helpers, no test blocks.

const std = @import("std");
const Allocator = std.mem.Allocator;
const codegen = @import("../../codegen.zig");
const snap = @import(".././snapshot.zig");
const snapUtil = @import("../../utils/snap.zig");
const config = @import(".././config.zig");
const crossModule = @import(".././crossModule.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const Module = codegen.Module;
const ModuleOutput = @import(".././moduleOutput.zig").ModuleOutput;
const GenerateResult = @import(".././moduleOutput.zig").GenerateResult;
const comptimeMod = @import("../../comptime.zig");
const validation = @import("../../comptime/error.zig");
const ctSnapshot = @import("../../comptime/snapshot.zig");

/// Every target the harness compiles for. `packages` is the implicit test
/// manifest (decision 109): an erlang/BEAM module atom starts with its
/// package, a compilation with no `botopink.json` is refused, so the harness
/// compiles as package `test` — `test@main`, `test@main@@Person`.
pub const configs = [_]config.Config{
    .{
        .targetSource = .commonJS,
        .typeDefLanguage = .typescript,
        .packages = crossModule.test_packages,
    },
    .{
        .targetSource = .erlang,
        .typeDefLanguage = null,
        .packages = crossModule.test_packages,
    },
    .{
        .targetSource = .beam,
        .typeDefLanguage = null,
        .packages = crossModule.test_packages,
    },
    .{
        .targetSource = .wasm,
        .typeDefLanguage = null,
        .packages = crossModule.test_packages,
    },
};

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
    return comptime std.fmt.comptimePrint(".botopinkbuild/codegen/{s}", .{slug});
}

pub fn freshEnv(arena_alloc: std.mem.Allocator, gpa: Allocator) !comptimeMod.Env_ {
    var env = comptimeMod.Env_.init(arena_alloc);
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, gpa);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));
    return env;
}

/// Whether a codegen snapshot test tolerates a module that does not compile.
pub const CompileExpectation = enum {
    /// Default: a parse / type / validation error fails the test (spec 06, H3+H9).
    must_compile,
    /// The test is *about* a program that does not compile; the recorded
    /// `COMPILE DIAGNOSTIC` section is the assertion. Used for documented
    /// skips — always with a comment naming the missing feature.
    expect_compile_error,
    /// The program compiles on commonJS, erlang and beam and is **refused** on
    /// wasm. The shape of a host-backed `declare fn` that names another target
    /// and no `wasm` one: there is no symbol on this backend and none was ever
    /// promised, so decision 67 refuses the call where it is written instead of
    /// lowering it to a trap the program only meets at run time. The wasm
    /// snapshot records the `COMPILE DIAGNOSTIC` section; the other three still
    /// have to compile, and the test fails if wasm ever starts accepting it.
    refused_on_wasm,
};

/// The name `comptime.compile` gives a module (mirrors `comptime.zig`).
fn moduleName(m: Module) []const u8 {
    return if (m.path.len > 0) m.path else "main";
}

const CompileDiagnostic = struct {
    name: []const u8,
    src: []const u8,
    text: []u8,
};

/// Re-runs the comptime front end for `modules` to recover the diagnostics the
/// backends discard (`.parseError` / `.typeError` modules are `continue`d, so
/// `codegen.generate` returns no output at all for them). Only called when a
/// module is already known to be missing, so the extra compile is off the
/// happy path. Caller frees each `text`.
fn collectCompileDiagnostics(
    allocator: Allocator,
    modules: []const Module,
    cfg: config.Config,
    out: *std.ArrayList(CompileDiagnostic),
) !void {
    const io = std.testing.io;
    const target_name: []const u8 = switch (cfg.targetSource) {
        .commonJS => "node",
        .erlang, .beam => "erlang",
        .wasm => "wasm",
    };
    var session = try comptimeMod.compile(allocator, modules, io, cfg.build_root, target_name);
    defer session.deinit(allocator);

    for (session.outputs.items) |o| {
        const body = (try ctSnapshot.renderOutcomeDiagnostic(allocator, o.src, o.outcome)) orelse continue;
        try out.append(allocator, .{ .name = o.name, .src = o.src, .text = body });
    }
    if (out.items.len > 0) return;

    // The module compiled through the front end and was refused by the
    // **backend** — a host-backed `declare fn` with no target for it (06 C13's
    // `MissingExternal`, which every backend raises and wasm raises under
    // decision 67). `codegen.generate` drops such a module, so the harness sees
    // it as "missing" with nothing to say; `generateWith` hands it back with the
    // diagnostic attached. Without this the snapshot recorded "no diagnostic
    // available", which is exactly the text a refusal must not be recorded as.
    var full = try codegen.generateWith(allocator, modules, io, cfg, .{ .execute = false });
    defer {
        for (full.items) |*o| o.result.deinit(allocator);
        full.deinit(allocator);
    }
    for (full.items) |o| {
        const d = o.result.diagnostic orelse continue;
        const text = switch (d) {
            .type => |t| try renderLocatedMessage(allocator, o.src, t.message, t.loc),
            .syntax => continue,
        };
        try out.append(allocator, .{ .name = o.name, .src = o.src, .text = text });
    }
}

/// A backend diagnostic (`moduleOutput.Diagnostic.type`) in the layout
/// `renderTypeErrorBody` gives a checker one — the message, then the location
/// box. It is its own renderer because a backend refusal is not a `TypeError`:
/// it carries a rendered message and a location, and nothing else.
fn renderLocatedMessage(
    allocator: Allocator,
    src: []const u8,
    message: []const u8,
    loc: anytype,
) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.appendSlice(allocator, "error: ");
    try out.appendSlice(allocator, message);
    try out.append(allocator, '\n');
    if (loc) |l| {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const tmp = arena.allocator();
        const line_text = ctSnapshot.getSourceLine(src, l.line);
        try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "  \u{250c}\u{2500} :{d}:{d}\n", .{ l.line, l.col }));
        try out.appendSlice(allocator, "  \u{2502}\n");
        try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "{d} \u{2502} {s}\n", .{ l.line, line_text }));
        try out.appendSlice(allocator, "  \u{2502} ");
        for (0..(if (l.col > 0) l.col - 1 else 0)) |_| try out.append(allocator, ' ');
        try out.appendSlice(allocator, "^\n");
    }
    return out.toOwnedSlice(allocator);
}

pub fn assertJs(
    allocator: Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
) !void {
    return assertJsExpecting(allocator, loc, modules, .must_compile);
}

/// `assertJsSingle` for a source that is known not to compile: the snapshot
/// records the diagnostic on all four backends and the test passes only while
/// the program *keeps* failing that way. Document the missing feature at the
/// call site.
pub fn assertJsCompileError(
    allocator: Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    return assertJsExpecting(
        allocator,
        loc,
        &.{.{ .path = "", .source = src }},
        .expect_compile_error,
    );
}

/// `assertJsSingle` for a program that compiles on commonJS, erlang and beam
/// and is **refused** on wasm — a call to a host-backed `declare fn` that names
/// another target and no `wasm` one (decision 67). The wasm snapshot records
/// the refusal as its `COMPILE DIAGNOSTIC` section.
pub fn assertJsRefusedOnWasm(
    allocator: Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    return assertJsExpecting(
        allocator,
        loc,
        &.{.{ .path = "", .source = src }},
        .refused_on_wasm,
    );
}

pub fn assertJsExpecting(
    allocator: Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
    expectation: CompileExpectation,
) !void {
    const trace_prev = snapUtil.traceEnter(loc);
    defer snapUtil.traceLeave(trace_prev);
    const io = std.testing.io;
    const build_root_path = comptime buildRootPathFromSrc(loc);
    const slug = comptime slugFromSrc(loc);

    // H10 — compare every backend before failing, so one suite round writes
    // every `.snap.md.new` instead of stopping at the first mismatch.
    var first_err: ?anyerror = null;
    var any_module_failed = false;
    // `refused_on_wasm` splits the verdict per backend, so it keeps its own two
    // flags and leaves `any_module_failed` meaning exactly what it did.
    var must_compile_failed = false;
    var wasm_refused = false;

    for (configs) |c| {
        var cfg = c;
        cfg.build_root = build_root_path;
        const eff: CompileExpectation = switch (expectation) {
            .refused_on_wasm => if (cfg.targetSource == .wasm) .expect_compile_error else .must_compile,
            else => expectation,
        };
        // Whether THIS backend failed. `any_module_failed` is cumulative across
        // backends, and `refused_on_wasm` needs the per-backend answer.
        var backend_failed = false;
        var outputs = try codegen.generate(
            allocator,
            modules,
            io,
            cfg,
        );

        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }

        // Build snapshot data for each module
        var snapOutputs = std.ArrayList(snap.SnapInput).empty;
        defer snapOutputs.deinit(allocator);

        for (outputs.items) |o| {
            try snapOutputs.append(allocator, .{
                .name = o.name,
                .src = o.src,
                .result = o.result,
            });
            if (o.result.comptime_err != null) {
                any_module_failed = true;
                backend_failed = true;
            }
        }

        // H3 — every module the backend dropped (parse / type error) still gets
        // a section, carrying the diagnostic that stopped it.
        var diagnostics = std.ArrayList(CompileDiagnostic).empty;
        defer {
            for (diagnostics.items) |d| allocator.free(d.text);
            diagnostics.deinit(allocator);
        }
        var missing = false;
        for (modules) |m| {
            const name = moduleName(m);
            var found = false;
            for (outputs.items) |o| {
                if (std.mem.eql(u8, o.name, name)) found = true;
            }
            if (!found) missing = true;
        }
        if (missing) {
            any_module_failed = true;
            backend_failed = true;
            try collectCompileDiagnostics(allocator, modules, cfg, &diagnostics);
            for (modules) |m| {
                const name = moduleName(m);
                var found = false;
                for (outputs.items) |o| {
                    if (std.mem.eql(u8, o.name, name)) found = true;
                }
                if (found) continue;
                var text: []const u8 = "error: the module did not compile (no diagnostic available)\n";
                for (diagnostics.items) |d| {
                    if (std.mem.eql(u8, d.name, name)) text = d.text;
                }
                try snapOutputs.append(allocator, .{
                    .name = name,
                    .src = m.source,
                    .result = null,
                    .diagnostic = text,
                });
                if (eff == .must_compile) {
                    std.debug.print(
                        "\n{s} [{s}]: module '{s}' did not compile:\n{s}\n" ++
                            "(use `assertJsCompileError` if the failure is the point of the test)\n",
                        .{ slug, @tagName(cfg.targetSource), name, text },
                    );
                }
            }
        }

        if (backend_failed) {
            if (eff == .must_compile) must_compile_failed = true;
            if (cfg.targetSource == .wasm) wasm_refused = true;
        }

        snap.assertCodegen(allocator, slug, snapOutputs.items, c) catch |err| {
            if (first_err == null) first_err = err;
        };
    }

    // H3/H9 — a program that does not compile must not pass as a snapshot of
    // "nothing", whichever backend noticed.
    switch (expectation) {
        .must_compile => if (any_module_failed and first_err == null) {
            first_err = error.ModuleDidNotCompile;
        },
        .expect_compile_error => if (!any_module_failed) {
            std.debug.print("\n{s}: expected a compile error, but every module compiled\n", .{slug});
            if (first_err == null) first_err = error.ExpectedCompileError;
        },
        .refused_on_wasm => {
            if (must_compile_failed and first_err == null) first_err = error.ModuleDidNotCompile;
            if (!wasm_refused) {
                std.debug.print("\n{s}: expected wasm to refuse the program, but it compiled\n", .{slug});
                if (first_err == null) first_err = error.ExpectedCompileError;
            }
        },
    }

    if (first_err) |err| return err;
}

pub fn assertJsError(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const trace_prev = snapUtil.traceEnter(loc);
    defer snapUtil.traceLeave(trace_prev);
    const io = std.testing.io;
    const slug = comptime slugFromSrc(loc);

    // H10 — every backend is compared before the first failure is reported.
    var first_err: ?anyerror = null;

    for (configs) |c| {
        var outputs = try codegen.generate(
            allocator,
            &.{.{ .path = "", .source = src }},
            io,
            c,
        ); // var: deinit needs *Self
        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }
        var ct_err_opt: ?comptimeMod.ComptimeError = null;
        for (outputs.items) |o| {
            if (o.result.comptime_err) |ct_err| {
                ct_err_opt = ct_err;
                break;
            }
        }

        if (ct_err_opt == null) {
            ct_err_opt = try extractComptimeValidationError(allocator, src);
        }
        const ct_err = ct_err_opt orelse {
            if (first_err == null) first_err = error.ExpectedComptimeError;
            continue;
        };

        const errText = try ct_err.renderAlloc(allocator, src);
        defer allocator.free(errText);

        snap.assertCodegenError(allocator, slug, src, errText, c) catch |err| {
            if (first_err == null) first_err = err;
        };
    }

    if (first_err) |err| return err;
}

pub fn extractComptimeValidationError(allocator: Allocator, src: []const u8) !?comptimeMod.ComptimeError {
    switch (try probeComptimeValidationError(allocator, src)) {
        .err => |err| return err,
        .noError => return null,
        .parseError => {},
    }

    var end = src.len;
    while (end > 0) {
        const maybe_nl = std.mem.lastIndexOfScalar(u8, src[0..end], '\n');
        if (maybe_nl == null) break;
        end = maybe_nl.?;
        var prefix_end = end;
        while (prefix_end > 0) {
            const c = src[prefix_end - 1];
            if (c == ' ' or c == '\t' or c == '\r' or c == '\n') {
                prefix_end -= 1;
            } else break;
        }
        const prefix = src[0..prefix_end];
        if (prefix.len == 0) continue;
        switch (try probeComptimeValidationError(allocator, prefix)) {
            .err => |err| return err,
            .noError => return null,
            .parseError => continue,
        }
    }

    return null;
}

pub const ValidationProbe = union(enum) {
    parseError,
    noError,
    err: comptimeMod.ComptimeError,
};

pub fn probeComptimeValidationError(allocator: Allocator, src: []const u8) !ValidationProbe {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.init(tokens);
    const program = p.parse(alloc) catch return .parseError;
    if (validation.validateComptime(program)) |err| {
        return .{ .err = err };
    }
    return .noError;
}

pub fn assertJsSingle(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    return assertJs(allocator, loc, &.{.{ .path = "", .source = src }});
}

/// Generate CommonJS for a single-module program and return the JS as an owned
/// slice (caller frees). Used to assert two source forms lower identically.
pub fn generateJs(allocator: Allocator, src: []const u8) ![]u8 {
    const io = std.testing.io;
    var outputs = try codegen.generate(allocator, &.{.{ .path = "", .source = src }}, io, configs[0]);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    return allocator.dupe(u8, outputs.items[0].result.js);
}

/// Snapshot a single module compiled in **test mode** (commonJS + erlang):
/// `test { … }` blocks emit as test functions plus a registry + runner
/// entry, and `assert` lowers to a recoverable per-test failure.
pub fn assertJsTestMode(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const trace_prev = snapUtil.traceEnter(loc);
    defer snapUtil.traceLeave(trace_prev);
    const io = std.testing.io;
    const build_root_path = comptime buildRootPathFromSrc(loc);
    const slug = comptime slugFromSrc(loc);
    const modules = [_]Module{.{ .path = "", .source = src }};

    // H10 — both backends are compared before the first failure is reported.
    var first_err: ?anyerror = null;
    var any_module_failed = false;

    for (configs[0..2]) |c| { // commonJS/node + erlang
        var cfg = c;
        cfg.build_root = build_root_path;
        cfg.test_mode = true;

        var outputs = try codegen.generate(allocator, &modules, io, cfg);
        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }

        var snapOutputs = std.ArrayList(snap.SnapInput).empty;
        defer snapOutputs.deinit(allocator);
        for (outputs.items) |o| {
            try snapOutputs.append(allocator, .{
                .name = o.name,
                .src = o.src,
                .result = o.result,
            });
            if (o.result.comptime_err != null) any_module_failed = true;
        }

        // H3 — record the diagnostic for a module the backend dropped.
        var diagnostics = std.ArrayList(CompileDiagnostic).empty;
        defer {
            for (diagnostics.items) |d| allocator.free(d.text);
            diagnostics.deinit(allocator);
        }
        if (outputs.items.len == 0) {
            any_module_failed = true;
            try collectCompileDiagnostics(allocator, &modules, cfg, &diagnostics);
            const text: []const u8 = if (diagnostics.items.len > 0)
                diagnostics.items[0].text
            else
                "error: the module did not compile (no diagnostic available)\n";
            try snapOutputs.append(allocator, .{
                .name = "main",
                .src = src,
                .result = null,
                .diagnostic = text,
            });
            std.debug.print(
                "\n{s} [{s}, test mode]: the module did not compile:\n{s}\n",
                .{ slug, @tagName(cfg.targetSource), text },
            );
        }

        snap.assertCodegen(allocator, slug, snapOutputs.items, cfg) catch |err| {
            if (first_err == null) first_err = err;
        };
    }

    if (any_module_failed and first_err == null) first_err = error.ModuleDidNotCompile;
    if (first_err) |err| return err;
}

pub fn assertJsContains(allocator: Allocator, src: []const u8, needles: []const []const u8) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(
        allocator,
        &.{.{ .path = "", .source = src }},
        io,
        configs[0], // commonJS / node
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    try std.testing.expect(outputs.items.len > 0);
    const js = outputs.items[outputs.items.len - 1].result.js;
    for (needles) |needle| {
        if (std.mem.indexOf(u8, js, needle) == null) {
            std.debug.print(
                "\n=== generated JS ===\n{s}\n=== missing needle: {s} ===\n",
                .{ js, needle },
            );
            return error.NeedleNotFound;
        }
    }
}

/// Asserts the **test-mode** erlang of `src`'s entry module contains every
/// `present` needle and none of the `absent` ones. For a claim about the
/// emitted `botopink test` runner itself — the sibling loader and what it does
/// with a module that does not compile — which is code no `test { }` block can
/// observe from the inside and no snapshot of a green program shows.
pub fn assertErlangTestModeContains(
    allocator: Allocator,
    src: []const u8,
    present: []const []const u8,
    absent: []const []const u8,
) !void {
    const io = std.testing.io;
    var cfg = configs[1]; // erlang
    cfg.test_mode = true;
    cfg.build_root = ".botopinkbuild/codegen/erlang_test_mode_contains";
    var outputs = try codegen.generate(allocator, &.{.{ .path = "", .source = src }}, io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        for (present) |needle| {
            if (std.mem.indexOf(u8, o.result.js, needle) == null) {
                std.debug.print("\n=== generated erlang (test mode) ===\n{s}\n=== missing needle: {s} ===\n", .{ o.result.js, needle });
                return error.NeedleNotFound;
            }
        }
        for (absent) |needle| {
            if (std.mem.indexOf(u8, o.result.js, needle) != null) {
                std.debug.print("\n=== generated erlang (test mode) ===\n{s}\n=== unexpected needle: {s} ===\n", .{ o.result.js, needle });
                return error.UnexpectedNeedle;
            }
        }
        return;
    }
    return error.ModuleDidNotCompile;
}

/// Compiles `src` as `main` for commonJS, runs it with node (sibling modules
/// such as `std/<mod>.js` written next to it) and asserts its RUN LOG equals
/// `expected`. For behaviour that lives in a module other than the entry, which
/// a single-module snapshot does not show.
pub fn assertJsRunLog(allocator: Allocator, src: []const u8, expected: []const u8) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(
        allocator,
        &.{.{ .path = "", .source = src }},
        io,
        configs[0], // commonJS / node
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        const got = o.result.run_output orelse "";
        if (!std.mem.eql(u8, got, expected)) {
            std.debug.print("\n=== generated JS ===\n{s}\n=== RUN LOG ===\n{s}\n=== expected ===\n{s}\n", .{ o.result.js, got, expected });
            return error.RunLogMismatch;
        }
        return;
    }
    return error.ModuleDidNotCompile;
}

/// The wasm twin of `assertJsRunLog`: compiles `src` as `main` for wasm, runs
/// the module under wasmtime and asserts its RUN LOG equals `expected`.
///
/// It exists for the programs an all-backend snapshot cannot hold: decision 8
/// §10's `break <value>` out of a condition loop does not compile on erlang at
/// all (`ConditionLoopValueUnsupported`), so `assertJsSingle` aborts before it
/// can record wasm's answer. `04-js` recorded the same programs with
/// `assertJsRunLog` for the same reason.
pub fn assertWasmRunLog(allocator: Allocator, src: []const u8, expected: []const u8) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(
        allocator,
        &.{.{ .path = "", .source = src }},
        io,
        configs[3], // wasm / wasmtime
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        const got = o.result.run_output orelse "";
        if (!std.mem.eql(u8, got, expected)) {
            std.debug.print("\n=== generated WAT ===\n{s}\n=== RUN LOG ===\n{s}\n=== expected ===\n{s}\n", .{ o.result.js, got, expected });
            return error.RunLogMismatch;
        }
        return;
    }
    return error.ModuleDidNotCompile;
}

/// The erlang twin of `assertJsRunLog` (front `02-erlang`): compiles `src` for
/// the erlang target, runs the emitted module and asserts its RUN LOG equals
/// `expected`, then that every needle of `needles` is in the emitted erlang.
///
/// It exists because the commonJS helpers above cannot see an erlang-only
/// defect, and because a row whose fixture does not yet type-check on the
/// §5.1 arm forms (`01-checker` step 4) still has a statement-position shape
/// that compiles today — running it is the only assertion that proves the
/// emitted erlang is *loadable*, which `escript` decides and a snapshot does
/// not.
pub fn assertErlangRunLog(
    allocator: Allocator,
    src: []const u8,
    expected: []const u8,
    needles: []const []const u8,
) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(
        allocator,
        &.{.{ .path = "", .source = src }},
        io,
        configs[1], // erlang
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        const got = o.result.run_output orelse "";
        if (!std.mem.eql(u8, got, expected)) {
            std.debug.print("\n=== generated erlang ===\n{s}\n=== RUN LOG ===\n{s}\n=== expected ===\n{s}\n", .{ o.result.js, got, expected });
            return error.RunLogMismatch;
        }
        for (needles) |needle| {
            if (std.mem.indexOf(u8, o.result.js, needle) == null) {
                std.debug.print("\n=== generated erlang ===\n{s}\n=== missing needle: {s} ===\n", .{ o.result.js, needle });
                return error.NeedleNotFound;
            }
        }
        return;
    }
    return error.ModuleDidNotCompile;
}

/// The test-mode twin of `assertJsRunLog` (1.0.10-beta decision 74): compiles
/// `src` in **test mode** for both `botopink test` targets (commonJS + erlang),
/// runs each module the way the CLI does (`runtime.executeTestModule`) and
/// asserts that the runner's output equals `expected` on both — whatever the
/// exit status, because the output a failing test prints is the point. The
/// nondeterministic `  duration <ms>ms` lines are dropped before comparing.
/// Writes no snapshot: `assertJsTestMode` records the code; this records what
/// running it prints, which the snapshot harness cannot (a non-zero exit is an
/// empty RUN LOG there, and erlang test modules are never executed by it).
pub fn assertTestModeRunLog(allocator: Allocator, src: []const u8, expected: []const u8) !void {
    const io = std.testing.io;
    const runtime = @import("../runtime.zig");
    var first_err: ?anyerror = null;
    for (configs[0..2]) |c| {
        var cfg = c;
        cfg.test_mode = true;
        cfg.build_root = ".botopinkbuild/codegen/test_mode_run_log";
        var outputs = try codegen.generate(allocator, &.{.{ .path = "", .source = src }}, io, cfg);
        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }
        var ran_one = false;
        for (outputs.items) |o| {
            if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
            if (o.result.failed()) break;
            ran_one = true;
            const target: runtime.TestTarget = if (cfg.targetSource == .commonJS) .commonJS else .erlang;
            const raw = try runtime.executeTestModule(allocator, io, target, o.result.js);
            defer allocator.free(raw);
            const got = try stripDurationLines(allocator, raw);
            defer allocator.free(got);
            if (!std.mem.eql(u8, got, expected)) {
                std.debug.print("\n=== generated {s} (test mode) ===\n{s}\n=== RUN LOG ===\n{s}\n=== expected ===\n{s}\n", .{ @tagName(cfg.targetSource), o.result.js, got, expected });
                if (first_err == null) first_err = error.RunLogMismatch;
            }
        }
        if (!ran_one and first_err == null) first_err = error.ModuleDidNotCompile;
    }
    if (first_err) |err| return err;
}

/// `text` without its `  duration <ms>ms` lines (the one nondeterministic line
/// of the `botopink test` envelope).
fn stripDurationLines(allocator: Allocator, text: []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    var it = std.mem.splitScalar(u8, text, '\n');
    var first = true;
    while (it.next()) |line| {
        if (std.mem.startsWith(u8, line, "  duration ") and std.mem.endsWith(u8, line, "ms")) continue;
        if (!first) try out.append(allocator, '\n');
        first = false;
        try out.appendSlice(allocator, line);
    }
    return out.toOwnedSlice(allocator);
}

/// Asserts that none of `needles` appear in the generated commonJS output.
pub fn assertJsNotContains(allocator: Allocator, src: []const u8, needles: []const []const u8) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(
        allocator,
        &.{.{ .path = "", .source = src }},
        io,
        configs[0], // commonJS / node
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    try std.testing.expect(outputs.items.len > 0);
    const js = outputs.items[outputs.items.len - 1].result.js;
    for (needles) |needle| {
        if (std.mem.indexOf(u8, js, needle) != null) {
            std.debug.print(
                "\n=== generated JS ===\n{s}\n=== unexpected needle: {s} ===\n",
                .{ js, needle },
            );
            return error.UnexpectedNeedle;
        }
    }
}

/// Asserts the emitted `.d.ts` of `src` contains every `present` needle and none
/// of the `absent` ones. For a typedef row whose point is the `.d.ts` alone: a
/// snapshot would carry the same program's JavaScript through every backend,
/// and the typedef is the only output that moves.
pub fn assertDtsContains(
    allocator: Allocator,
    src: []const u8,
    present: []const []const u8,
    absent: []const []const u8,
) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(
        allocator,
        &.{.{ .path = "", .source = src }},
        io,
        configs[0], // commonJS / node — the only config with a typedef language
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    try std.testing.expect(outputs.items.len > 0);
    const dts = outputs.items[outputs.items.len - 1].result.typedef orelse return error.MissingTypedef;
    for (present) |needle| {
        if (std.mem.indexOf(u8, dts, needle) == null) {
            std.debug.print("\n=== generated .d.ts ===\n{s}\n=== missing needle: {s} ===\n", .{ dts, needle });
            return error.NeedleNotFound;
        }
    }
    for (absent) |needle| {
        if (std.mem.indexOf(u8, dts, needle) != null) {
            std.debug.print("\n=== generated .d.ts ===\n{s}\n=== unexpected needle: {s} ===\n", .{ dts, needle });
            return error.UnexpectedNeedle;
        }
    }
}

/// Multi-module variant of `assertJsContains`/`assertJsNotContains`: generates
/// every module (last one is the consumer `main`) and asserts the consumer's JS
/// both contains every `present` needle and contains none of the `absent` ones.
pub fn assertConsumerJs(
    allocator: Allocator,
    modules: []const Module,
    present: []const []const u8,
    absent: []const []const u8,
) !void {
    const io = std.testing.io;
    var outputs = try codegen.generate(allocator, modules, io, configs[0]);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    try std.testing.expect(outputs.items.len > 0);
    const js = outputs.items[outputs.items.len - 1].result.js;
    for (present) |needle| {
        if (std.mem.indexOf(u8, js, needle) == null) {
            std.debug.print("\n=== consumer JS ===\n{s}\n=== missing: {s} ===\n", .{ js, needle });
            return error.NeedleNotFound;
        }
    }
    for (absent) |needle| {
        if (std.mem.indexOf(u8, js, needle) != null) {
            std.debug.print("\n=== consumer JS ===\n{s}\n=== unexpected: {s} ===\n", .{ js, needle });
            return error.UnexpectedNeedle;
        }
    }
}
