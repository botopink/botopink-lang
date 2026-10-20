//! Shared test harness for the codegen stage (moved from tests.zig).
//! Pure harness module: imports + `pub fn`/data helpers, no test blocks.

const std = @import("std");
const test_scratch = @import("test_scratch");
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

/// `codegen.generate`, the harness's one entry: every comptime evaluation
/// runs on the wasm runtime, whatever the fixture's target (decision 434).
pub fn generate(
    allocator: Allocator,
    modules: []const Module,
    io: std.Io,
    cfg: config.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    return codegen.generate(allocator, modules, io, cfg);
}

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

/// Every target: what `assertJs` and `assertJsError` record, one snapshot
/// tree `snapshots/codegen/<target>/` (decision 434: one comptime runtime).
pub const snapshot_configs = configs;
/// The two `botopink test` targets (`assertJsTestMode`).
pub const test_mode_configs = configs[0..2].*;

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

/// The build root of the test at `loc`: `codegen/<slug>` under this
/// process's `test_scratch` root, so two processes running the suite over one
/// checkout never share it (`scripts/check-test-scratch.sh`).
pub fn buildRootPathFromSrc(io: std.Io, comptime loc: std.builtin.SourceLocation) []const u8 {
    return test_scratch.path(io, "codegen/" ++ comptime slugFromSrc(loc));
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
        const file = try ctSnapshot.moduleFile(allocator, o.name);
        defer allocator.free(file);
        const body = (try ctSnapshot.renderOutcomeDiagnostic(allocator, o.src, o.outcome, file)) orelse continue;
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
    const build_root_path = buildRootPathFromSrc(io, loc);
    const slug = comptime slugFromSrc(loc);

    // H10 — compare every backend before failing, so one suite round writes
    // every `.snap.md.new` instead of stopping at the first mismatch.
    var first_err: ?anyerror = null;
    var any_module_failed = false;
    // `refused_on_wasm` splits the verdict per backend, so it keeps its own two
    // flags and leaves `any_module_failed` meaning exactly what it did.
    var must_compile_failed = false;
    var wasm_refused = false;

    for (snapshot_configs) |c| {
        var cfg = c;
        cfg.build_root = build_root_path;
        const eff: CompileExpectation = switch (expectation) {
            .refused_on_wasm => if (cfg.targetSource == .wasm) .expect_compile_error else .must_compile,
            else => expectation,
        };
        // Whether THIS backend failed. `any_module_failed` is cumulative across
        // backends, and `refused_on_wasm` needs the per-backend answer.
        var backend_failed = false;
        var outputs = try generate(
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

    for (snapshot_configs) |c| {
        var outputs = try generate(
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

        const errText = try ct_err.renderAlloc(allocator, src, "main.bp");
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
    var outputs = try generate(allocator, &.{.{ .path = "", .source = src }}, io, configs[0]);
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
    const build_root_path = buildRootPathFromSrc(io, loc);
    const slug = comptime slugFromSrc(loc);
    const modules = [_]Module{.{ .path = "", .source = src }};

    // H10 — both backends are compared before the first failure is reported.
    var first_err: ?anyerror = null;
    var any_module_failed = false;

    for (test_mode_configs) |c| { // commonJS/node + erlang
        var cfg = c;
        cfg.build_root = build_root_path;
        cfg.test_mode = true;

        var outputs = try generate(allocator, &modules, io, cfg);
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
    var outputs = try generate(
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
    cfg.build_root = test_scratch.path(io, "codegen/erlang_test_mode_contains");
    var outputs = try generate(allocator, &.{.{ .path = "", .source = src }}, io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        // The runner is the module's test unit's (decision 513).
        const code = if (o.result.test_unit) |u| u.code else return error.NoTestUnit;
        for (present) |needle| {
            if (std.mem.indexOf(u8, code, needle) == null) {
                std.debug.print("\n=== generated erlang test unit ===\n{s}\n=== missing needle: {s} ===\n", .{ code, needle });
                return error.NeedleNotFound;
            }
        }
        for (absent) |needle| {
            if (std.mem.indexOf(u8, code, needle) != null) {
                std.debug.print("\n=== generated erlang test unit ===\n{s}\n=== unexpected needle: {s} ===\n", .{ code, needle });
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
    var outputs = try generate(
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

/// The wasm backend REFUSES `src` (`Emitter.refuse` → `WasmLoweringRefused`)
/// with a diagnostic whose message contains `needle`, located at
/// `line:col`. No snapshot, no other backend: the claim is wasm's alone — a
/// lowering that cannot proceed is a located build refusal, never a module
/// that traps at run time (`00 · 110-gate-wasm`).
pub fn assertWasmRefusedAt(allocator: Allocator, src: []const u8, needle: []const u8, line: usize, col: usize) !void {
    return assertRefusedAt(allocator, configs[3], src, needle, line, col);
}

/// `assertWasmRefusedAt` for the beam backend: an `@External.Erlang` template
/// its reader refuses is a located build error naming the construct
/// (decision 141).
pub fn assertBeamRefusedAt(allocator: Allocator, src: []const u8, needle: []const u8, line: usize, col: usize) !void {
    return assertRefusedAt(allocator, configs[2], src, needle, line, col);
}

/// `assertWasmRefusedAt` for the commonJS backend: a `#[@External.Node(fn: …)]`
/// binding that names no private fn of the same signature is a located build
/// error at the annotation (decision 238 on every target).
pub fn assertJsRefusedAt(allocator: Allocator, src: []const u8, needle: []const u8, line: usize, col: usize) !void {
    return assertRefusedAt(allocator, configs[0], src, needle, line, col);
}

/// `assertWasmRefusedAt` for the erlang backend.
pub fn assertErlangRefusedAt(allocator: Allocator, src: []const u8, needle: []const u8, line: usize, col: usize) !void {
    return assertRefusedAt(allocator, configs[1], src, needle, line, col);
}

/// `assertJsRefusedAt` over a module of std's own (`Module.std_member`,
/// decision 445): what only std may write — a `std:` cell — refused for
/// what else it gets wrong (an export std-wasm lacks, other types).
pub fn assertStdModuleRefusedAt(allocator: Allocator, src: []const u8, needle: []const u8, line: usize, col: usize) !void {
    return assertRefusedAtIn(allocator, configs[0], src, true, needle, line, col);
}

/// Compiles `modules` as std's own (`Module.std_member`) for the JS backend and
/// asserts none of them is refused — a std module checked beside its siblings.
pub fn assertStdModulesCompile(allocator: Allocator, modules: []const struct { path: []const u8, source: []const u8 }) !void {
    const io = std.testing.io;
    var list: std.ArrayList(Module) = .empty;
    defer list.deinit(allocator);
    for (modules) |m| try list.append(allocator, .{ .path = m.path, .source = m.source, .std_member = true });
    var outputs = try codegen.generateWith(allocator, list.items, io, configs[0], .{ .execute = false });
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| if (o.result.diagnostic) |d| switch (d) {
        .type => |t| {
            std.debug.print("\n=== module `{s}` refused: {s}\n", .{ o.name, t.message });
            return error.ModuleRefused;
        },
        .syntax => return error.ModuleRefused,
    };
}

fn assertRefusedAt(allocator: Allocator, cfg: config.Config, src: []const u8, needle: []const u8, line: usize, col: usize) !void {
    return assertRefusedAtIn(allocator, cfg, src, false, needle, line, col);
}

fn assertRefusedAtIn(allocator: Allocator, cfg: config.Config, src: []const u8, std_member: bool, needle: []const u8, line: usize, col: usize) !void {
    const io = std.testing.io;
    var outputs = try codegen.generateWith(allocator, &.{.{ .path = "", .source = src, .std_member = std_member }}, io, cfg, .{ .execute = false });
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        const d = o.result.diagnostic orelse {
            std.debug.print("\n=== expected the {t} backend to refuse, it emitted ===\n{s}\n", .{ cfg.targetSource, o.result.js });
            return error.ExpectedCompileError;
        };
        switch (d) {
            .type => |t| {
                const l = t.loc orelse {
                    std.debug.print("\n=== refusal without a location: {s} ===\n", .{t.message});
                    return error.RefusalNotLocated;
                };
                if (std.mem.indexOf(u8, t.message, needle) == null or l.line != line or l.col != col) {
                    std.debug.print("\n=== got {d}:{d} {s}\n=== expected {d}:{d} …{s}…\n", .{ l.line, l.col, t.message, line, col, needle });
                    return error.RefusalMismatch;
                }
                return;
            },
            .syntax => return error.ExpectedCompileError,
        }
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
    var outputs = try generate(
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

/// `assertWasmRunLog` over several modules: the consumer is the one with the
/// empty path (`main`); its RUN LOG under wasmtime is compared with `expected`,
/// and a refusal of it is printed.
pub fn assertWasmRunLogModules(allocator: Allocator, modules: []const Module, expected: []const u8) !void {
    const io = std.testing.io;
    var outputs = try codegen.generateWith(allocator, modules, io, configs[3], .{ .execute = true });
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        if (o.result.diagnostic) |d| switch (d) {
            .type => |t| std.debug.print("\n=== refused: {s}\n", .{t.message}),
            .syntax => {},
        };
        const got = o.result.run_output orelse "";
        if (!std.mem.eql(u8, got, expected)) {
            std.debug.print("\n=== generated WAT ===\n{s}\n=== RUN LOG ===\n{s}\n=== expected ===\n{s}\n", .{ o.result.js, got, expected });
            return error.RunLogMismatch;
        }
        return;
    }
    return error.ModuleDidNotCompile;
}

/// `src` (a program whose `main` aborts) compiled for every backend and run
/// the way `botopink run` runs it (`runtime.executeAborting`; wasm under
/// wasmtime, its RUN LOG): each run aborts and what it writes contains
/// `needle` — the message the program raised, unchanged, whatever the
/// runtime's own frame around it (decision 430, 144 B-41). A target whose tool
/// is missing is skipped.
pub fn assertAbortWritesEveryBackend(allocator: Allocator, src: []const u8, needle: []const u8) !void {
    return abortWrites(allocator, src, needle, true);
}

/// `assertAbortWritesEveryBackend` over commonJS, erlang and beam alone: the
/// `<kind>: <message>` line an uncaught abort writes there (decision 535, the
/// `Failure` an `attempt` would answer); wasm writes it for `@panic`, `@todo`
/// and `assert` only, not yet for an overflow or a division by zero.
pub fn assertAbortWritesFailure(allocator: Allocator, src: []const u8, needle: []const u8) !void {
    return abortWrites(allocator, src, needle, false);
}

fn abortWrites(allocator: Allocator, src: []const u8, needle: []const u8, with_wasm: bool) !void {
    const io = std.testing.io;
    for (configs) |cfg| {
        const wasm = cfg.targetSource == .wasm;
        if (wasm and !with_wasm) continue;
        var outputs = if (wasm)
            try generate(allocator, &.{.{ .path = "", .source = src }}, io, cfg)
        else
            try codegen.generateWith(allocator, &.{.{ .path = "", .source = src }}, io, cfg, .{ .execute = false });
        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }
        const o = for (outputs.items) |o| {
            if (std.mem.eql(u8, o.name, "") or std.mem.eql(u8, o.name, "main")) break o;
        } else return error.ModuleDidNotCompile;
        if (o.result.failed()) return error.ModuleDidNotCompile;
        const got: []u8 = if (wasm)
            try allocator.dupe(u8, o.result.run_output orelse "")
        else
            (try @import("../runtime.zig").executeAborting(allocator, switch (cfg.targetSource) {
                .commonJS => .commonJS,
                .erlang => .erlang,
                else => .beam,
            }, o.result.js, "main", io)) orelse {
                std.debug.print("\n=== {t}: the program did not abort (or its tool is missing) ===\n", .{cfg.targetSource});
                return error.DidNotAbort;
            };
        defer allocator.free(got);
        if (wasm and got.len == 0) continue; // wasmtime missing
        if (std.mem.indexOf(u8, got, needle) == null) {
            std.debug.print("\n=== {t}: what the abort wrote ===\n{s}\n=== expected it to contain ===\n{s}\n", .{ cfg.targetSource, got, needle });
            return error.AbortTextMismatch;
        }
    }
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
    var outputs = try generate(
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

/// `assertErlangRunLog` over several modules: `files` are compiled as one
/// program for the erlang target and the RUN LOG of the module named
/// `run_module` (the one declaring `main`) must equal `expected`; `needles`
/// are looked for in that module's emitted erlang. For a row that lives on a
/// module boundary (an imported record's field, an imported fn), where an
/// all-backend snapshot would record other fronts' baselines.
pub fn assertErlangRunLogModules(
    allocator: Allocator,
    files: []const Module,
    run_module: []const u8,
    expected: []const u8,
    needles: []const []const u8,
) !void {
    const io = std.testing.io;
    var outputs = try generate(allocator, files, io, configs[1]);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, run_module)) continue;
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

/// The beam twin of `assertErlangRunLog` (front `03-beam`): compiles `src` for
/// the beam target, assembles every emitted `.S` with `erlc +from_asm`, runs
/// the entry under `erl` and asserts its RUN LOG equals `expected`, then that
/// every needle of `needles` is in the emitted BEAM assembly.
///
/// It exists for the rows whose other backends are not landed yet: an
/// all-backend snapshot would record another front's wrong answer in another
/// front's directory, and the language suite's beam cell only says pass/fail.
pub fn assertBeamRunLog(
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
        configs[2], // beam
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        const got = o.result.run_output orelse "";
        if (!std.mem.eql(u8, got, expected)) {
            std.debug.print("\n=== generated beam ===\n{s}\n=== RUN LOG ===\n{s}\n=== expected ===\n{s}\n", .{ o.result.js, got, expected });
            return error.RunLogMismatch;
        }
        for (needles) |needle| {
            if (std.mem.indexOf(u8, o.result.js, needle) == null) {
                std.debug.print("\n=== generated beam ===\n{s}\n=== missing needle: {s} ===\n", .{ o.result.js, needle });
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
        cfg.build_root = test_scratch.path(io, "codegen/test_mode_run_log");
        var outputs = try generate(allocator, &.{.{ .path = "", .source = src }}, io, cfg);
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
            const unit = o.result.test_unit orelse {
                if (first_err == null) first_err = error.NoTestUnit;
                continue;
            };
            const raw = try runtime.executeTestModule(allocator, io, target, o.result.js, unit);
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
    var outputs = try generate(
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
    var outputs = try generate(
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

/// The multi-module needle check for ONE named module (`o.name`, the module's
/// path — `"tree/api"`), when the line under test is not in the consumer.
pub fn assertModuleJs(
    allocator: Allocator,
    modules: []const Module,
    module_name: []const u8,
    present: []const []const u8,
) !void {
    const io = std.testing.io;
    var outputs = try generate(allocator, modules, io, configs[0]);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, module_name)) continue;
        for (present) |needle| {
            if (std.mem.indexOf(u8, o.result.js, needle) == null) {
                std.debug.print("\n=== {s} JS ===\n{s}\n=== missing: {s} ===\n", .{ module_name, o.result.js, needle });
                return error.NeedleNotFound;
            }
        }
        return;
    }
    return error.ModuleDidNotCompile;
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
    var outputs = try generate(allocator, modules, io, configs[0]);
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

/// `assertConsumerJs` for the beam target: generates every module (the last one
/// is the consumer `main`) and asserts the consumer's BEAM assembly contains
/// every `present` needle and none of the `absent` ones.
pub fn assertConsumerBeam(
    allocator: Allocator,
    modules: []const Module,
    present: []const []const u8,
    absent: []const []const u8,
) !void {
    const io = std.testing.io;
    var outputs = try generate(allocator, modules, io, configs[2]);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    try std.testing.expect(outputs.items.len > 0);
    const asm_text = outputs.items[outputs.items.len - 1].result.js;
    for (present) |needle| {
        if (std.mem.indexOf(u8, asm_text, needle) == null) {
            std.debug.print("\n=== consumer beam ===\n{s}\n=== missing: {s} ===\n", .{ asm_text, needle });
            return error.NeedleNotFound;
        }
    }
    for (absent) |needle| {
        if (std.mem.indexOf(u8, asm_text, needle) != null) {
            std.debug.print("\n=== consumer beam ===\n{s}\n=== unexpected: {s} ===\n", .{ asm_text, needle });
            return error.UnexpectedNeedle;
        }
    }
}

/// Decision 509 (2)'s invariant for one target: the library `lib` compiled
/// under two consumers — `plain` and `crowded`, each a full module list, the
/// libraries first — emits the same files with the same bytes (its modules'
/// code, their type units and, on commonJS, their `.d.ts`). The two programs
/// compile as package `app` over the dependencies `deps`. A difference prints
/// both texts and fails.
pub fn assertLibrarySameUnder(
    allocator: Allocator,
    target: config.TargetSource,
    deps: []const []const u8,
    lib: []const u8,
    plain: []const Module,
    crowded: []const Module,
) !void {
    const io = std.testing.io;
    var cfg: config.Config = for (configs) |c| {
        if (c.targetSource == target) break c;
    } else unreachable;
    cfg.packages = .{ .root = "app", .deps = deps };
    var a = try generate(allocator, plain, io, cfg);
    defer {
        for (a.items) |*o| o.result.deinit(allocator);
        a.deinit(allocator);
    }
    var b = try generate(allocator, crowded, io, cfg);
    defer {
        for (b.items) |*o| o.result.deinit(allocator);
        b.deinit(allocator);
    }
    var compared: usize = 0;
    for (a.items) |oa| {
        const in_lib = oa.name.len > lib.len and oa.name[lib.len] == '/' and std.mem.startsWith(u8, oa.name, lib);
        if (!in_lib) continue;
        const ob = for (b.items) |o| {
            if (std.mem.eql(u8, o.name, oa.name)) break o;
        } else return error.ModuleMissingUnderCrowded;
        compared += 1;
        try expectSameText(oa.name, oa.result.js, ob.result.js);
        try expectSameText(oa.name, oa.result.typedef orelse "", ob.result.typedef orelse "");
        try std.testing.expectEqual(oa.result.units.len, ob.result.units.len);
        for (oa.result.units, ob.result.units) |ua, ub| {
            try std.testing.expectEqualStrings(ua.atom, ub.atom);
            try expectSameText(ua.atom, ua.code, ub.code);
        }
    }
    try std.testing.expect(compared > 0);
}

fn expectSameText(name: []const u8, plain: []const u8, crowded: []const u8) !void {
    if (std.mem.eql(u8, plain, crowded)) return;
    std.debug.print("\n=== {s} under plain ===\n{s}\n=== {s} under crowded ===\n{s}\n", .{ name, plain, name, crowded });
    return error.LibraryDependsOnConsumer;
}

/// The fixture of `assertLibrarySameUnder` (decision 509 (2), 144 B-65,
/// B-66): the library `shelf` — a record read field by field, an enum whose
/// payload variants a `case` destructures — and `rival`, a second dependency
/// of `crowded` alone declaring the same names with other fields and field
/// orders. `plain` uses `shelf` alone; `crowded` uses both, and declares
/// `Queue` again in its own module.
pub const closure_shelf = Module{ .path = "shelf/items", .package = "shelf", .source =
    \\pub type Queue(label: string, size: i32)
    \\
    \\pub type Shape {
    \\    Circle(radius: i32),
    \\    Square(side: i32),
    \\    Dot,
    \\}
    \\
    \\pub fn describe(q: Queue) -> string {
    \\    return q.label + ":" + q.size.toString();
    \\}
    \\
    \\pub fn area(s: Shape) -> i32 {
    \\    val out = case s {
    \\        Circle(radius) -> radius * radius * 3;
    \\        Square(side) -> side * side;
    \\        Dot -> 0;
    \\    };
    \\    return out;
    \\}
};
pub const closure_rival = Module{ .path = "rival/items", .package = "rival", .source =
    \\pub type Queue(size: i32, label: string, extra: bool)
    \\
    \\pub type Shape {
    \\    Square(side: i32, color: string),
    \\    Circle(radius: i32),
    \\    Dot,
    \\}
    \\
    \\pub fn rivalLabel(q: Queue) -> string {
    \\    return q.label;
    \\}
};
pub const closure_plain = [_]Module{
    closure_shelf,
    .{ .path = "main", .source =
    \\import {items.Queue, items.describe} from "shelf";
    \\
    \\pub fn main() -> void {
    \\    print(describe(Queue(label: "plain", size: 1)));
    \\}
    \\
    \\import {io.terminal.print} from "std";
    },
};
pub const closure_crowded = [_]Module{
    closure_shelf,
    closure_rival,
    .{ .path = "local", .source =
    \\pub type Queue(size: i32, label: string)
    },
    .{ .path = "main", .source =
    \\import {items.Queue, items.Shape, items.describe, items.area} from "shelf";
    \\import {items.rivalLabel} from "rival";
    \\import {local};
    \\
    \\pub fn main() -> void {
    \\    print(describe(Queue(label: "crowded", size: 2)));
    \\    print(area(Shape.Square(side: 2)).toString());
    \\}
    \\
    \\import {io.terminal.print} from "std";
    },
};
