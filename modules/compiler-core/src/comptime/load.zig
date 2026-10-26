//! Decisions 780–783, 786, 982 — `comptime compiler.load(path)`: a package
//! directory (its own `botopink.json` and `src/main.bp`, `load-not-a-package`
//! otherwise) compiled at build under its own manifest, answered as its
//! `Module` and its refusals.
//!
//! - `parser/compiler_surface.zig` reads `compiler.load(p)` onto the builtin
//!   `surface.load_builtin`; the checker (`infer.zig` `inferLoadBuiltin`, beside
//!   `@embed`'s) reads the path by `@embed`'s rules and calls `compileFile`.
//! - `compileFile` gathers the package's `src/main.bp` and its `mod` tree
//!   through a reader rooted at the package (`PackageFiles.under`), so a
//!   `Diagnostic`'s `file` is relative to it; reads its `botopink.json` — its
//!   name (`Module.name`), its targets (833's check) and the dependencies it
//!   names, each the build's module of that package —, and runs `comptime.compile` on them —
//!   no target, which comptime never reads (decision 798 (4)): a refusal
//!   that depends on the target is the emit's — captured: nothing is printed, and the caller's
//!   program never sees the modules. Each refused module is one `Diagnostic`,
//!   in the order `botopink build` prints them, with the text and the place it
//!   prints (decision 780 (2), 781).
//! - The answer is code (`rewrite`): `__bp_loaded(__bp_load_module(…),
//!   [Bp__LoadDiagnostic(…), …])`, a call of the function `withLoadHelper`
//!   declares in the module that loads (`Ok(m)` for `[]`, `Error(Refused(m,
//!   ds))` otherwise, decisions 782, 786), std's `compiler.Module`,
//!   `compiler.Refused` and `compiler.Diagnostic` imported under names no
//!   source writes. The `Module` is the loaded package's (`Loaded`): `name`
//!   its manifest's, `path` the directory as written — no target (decision
//!   805 (4)).
//! - A nested compile re-enters nothing of std's one-time initialisation: it
//!   runs only once std's template is ready (`comptime.stdlibTemplateReady`),
//!   and a file that loads itself through a chain of loads is refused
//!   (`load-cycle`) instead of compiling forever.
//! - Decisions 787, 792 — `m.run()`: a read in a body that runs at build is
//!   answered before the body runs (`runtimeAnswer`), a captured `Module`
//!   written back as its constructor (`recordSource`); a `run()` an executor
//!   writes brings the file into the program as a package of its own
//!   (`packageModules`, `bp_load__<path>`), compiled again by
//!   `comptime.compileWith` with it, the call rewritten to `run_fn` over the
//!   package's `loaded_main_fn` (`runRewrite`, `withRunImports`), answering
//!   std's `compiler.RunFailure` (decision 806).

const std = @import("std");
const ast = @import("../ast.zig");
const moduleMod = @import("../module.zig");
const Module = moduleMod.Module;
const PackageFiles = moduleMod.PackageFiles;
const surface = @import("../parser/compiler_surface.zig");
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const printErrors = @import("../print.zig");
const blockEval = @import("block_eval.zig");
const targetCheck = @import("../codegen/target_check.zig");

/// The function `withLoadHelper` declares: `Ok(m)` for no refusal,
/// `Error(Refused(m, ds))` otherwise.
pub const helper_fn = "__bp_loaded";
/// The local name of std's `compiler.Diagnostic` in a module that loads.
pub const diagnostic_alias = "Bp__LoadDiagnostic";
/// The local name of std's `compiler.Module` in a module that loads.
pub const module_alias = "Bp__LoadModule";
/// Decision 811 (4) — the method of std's opaque `compiler.Module` written
/// without `pub` that makes one: the lowering's call, no program's.
pub const module_maker = "of";
/// The function `withLoadHelper` declares over `module_maker`:
/// `__bp_load_module(name:, path:, buildOutput:, mainAsync:)` answers `Bp__LoadModule.of(…)`. A read's
/// answer and an executor's captured `Module` are written as its call.
pub const module_fn = "__bp_load_module";
/// The local name of std's `compiler.Refused` in a module that loads.
pub const refused_alias = "Bp__LoadRefused";

/// The fields of the records the answer builds, in the order `rewrite`
/// writes them — std's `compiler.Module`, `compiler.Refused` and
/// `compiler.Diagnostic`, record for record (`tests/compiler_members.zig`).
pub const records = [_]struct { name: []const u8, fields: []const []const u8 }{
    .{ .name = "Module", .fields = &.{ "name", "path", "buildOutput", "mainAsync" } },
    .{ .name = "Refused", .fields = &.{ "module", "diagnostics" } },
    .{ .name = "Diagnostic", .fields = &.{ "code", "message", "file", "line", "column", "label", "from" } },
};

/// Where the helper's lines are parsed: past every line of the module and of
/// a typed meta read's helper (`typed_meta.helper_first_line`).
const helper_first_line: usize = 3_000_000;
/// Where each rewrite's line is: one line per call, from its location.
const rewrite_first_line: usize = 4_000_000;

/// The caller build's modules, for the dependencies a loaded file's package
/// shares with its caller (the caller's manifest): set by `comptime.compile`
/// around each compile, restored after it (a nested compile sets its own).
pub threadlocal var build_modules: []const Module = &.{};

/// Decision 792 (5) — the prefix of a loaded package's name: `bp_load__`
/// and the file's path, each `/` a `__`, `.bp` dropped
/// (`src/cases/fine/mod.bp` → `bp_load__src__cases__fine__mod`).
pub const package_prefix = "bp_load__";

/// The function a loaded package's root gains (decision 787 (2)): its
/// `main`, answering `Error` with the text of the `Error(e)` a `main`
/// answering a `Result` returned, so `run` answers `.Failed` (806 (1)).
pub const loaded_main_fn = "__bp_loaded_main";

/// Decision 989 (3) — the functions a loaded package's root gains beside
/// `loaded_main_fn`, read and rewritten at `emit` for the target built
/// (`codegen/loaded_targets.zig`): `loaded_main_off_fn` is the
/// `loaded_main_fn` of the root the emit puts in place of a package the
/// target refuses — it throws `off_marker`, the kind's letter (`R` refused,
/// `X` excluded) and the refusal's text, which `run_fn` reads —; and
/// `loaded_info_fn` answers the package's path and its manifest's
/// `targets` (`<path>|<t>,<t>`, `*` when it declares none).
pub const loaded_main_off_fn = "__bp_loaded_main_off";
pub const loaded_info_fn = "__bp_loaded_info";
/// Whether `name` is a loaded package's entry — `loaded_main_fn`, or the
/// `loaded_tests_fn` a `` `test`() `` calls (decision 993 (3)): each begins
/// with the package's initialisers, run anew at every call (806 (3)).
pub fn isLoadedEntry(name: []const u8) bool {
    return std.mem.eql(u8, name, loaded_main_fn) or std.mem.eql(u8, name, loaded_tests_fn);
}

/// `isLoadedEntry` over a name a backend mangled with a prefix.
pub fn endsWithLoadedEntry(name: []const u8) bool {
    return std.mem.endsWith(u8, name, loaded_main_fn) or std.mem.endsWith(u8, name, loaded_tests_fn);
}

/// What the `Error` of a refused package's `loaded_main_fn` begins with, as
/// a string literal's lexeme (a NUL no `main`'s error text starts with).
pub const off_marker = "\\0bp-off:";

/// The package a loaded file is compiled into when a `run` reaches it: an
/// identifier, since its aliases are names in the program (`runAlias`,
/// `testsAlias`) — each `/` is `__`, any other byte that is not a letter, a
/// digit or `_` is `_x<hex>` (a resolver's directory, decision 993 (2), is a
/// whole path: `botopink-lang`, `.tasks`).
pub fn packageName(arena: std.mem.Allocator, path: []const u8) ![]const u8 {
    const stem = if (std.mem.endsWith(u8, path, ".bp")) path[0 .. path.len - 3] else path;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    try out.appendSlice(arena, package_prefix);
    for (stem) |c| switch (c) {
        '/' => try out.appendSlice(arena, "__"),
        'a'...'z', 'A'...'Z', '0'...'9', '_' => try out.append(arena, c),
        else => try out.print(arena, "_x{x:0>2}", .{c}),
    };
    return out.items;
}

/// Whether `package` is a loaded file's (`packageName`).
pub fn isLoadedPackage(package: []const u8) bool {
    return std.mem.startsWith(u8, package, package_prefix);
}

/// What one top-level compile knows of a loaded file (decisions 787, 792):
/// the answer of its load — kept so the reads of one compile, and the
/// compile again with the packages its `run`s reach, compile the file once —
/// and what a `run` of it needs.
pub const Entry = struct {
    path: []const u8,
    /// Decision 982 (4) — the loaded package's manifest name.
    name: []const u8 = "",
    /// Decision 989 (4) — what the package's build bodies printed (a top-level
    /// `comptime` block's `print`), in order, each line ending in `\n`, before
    /// its refusals (decision 904); `""` when none.
    build_output: []const u8 = "",
    /// The refusals, empty when the file compiled.
    diagnostics: []const Diagnostic,
    /// The file and its `mod` tree (`gatherTree`), children first, each
    /// named by its logical path in the package.
    modules: []const Module,
    /// Whether the file declares a `main`, whether that `main` answers a
    /// `Result` (inside its `Async` when it is `async`), and whether it is
    /// `async` (decision 989 (2)).
    has_main: bool,
    main_result: bool,
    main_async: bool = false,
    /// Decision 989 (3) — the targets its manifest declares, null when it
    /// declares none.
    targets: ?moduleMod.Targets = null,
    /// Decision 993 (1) — the package's own dependencies, as the CLI's
    /// resolver answered them (`resolver`), dependencies before dependents:
    /// a `run()` of the package joins them to the program before it. Empty
    /// with no resolver (the caller's modules are the package's then). They
    /// live as long as the process.
    dependencies: []const Module = &.{},
    /// Decision 993 (3) — the package's `test/` suite (`testSuite`): every
    /// `.bp` file under its `test/` directory, each named by its path there
    /// without `.bp`, as `botopink test` names them. They join the program
    /// only when a `` `test`() `` reaches the package (`packageModules`).
    test_modules: []const Module = &.{},
};

/// The state of one top-level compile (`comptime.compileWith` enters and
/// leaves it): the loaded files' entries and the files a `run` reaches.
pub const State = struct {
    arena: ?*std.heap.ArenaAllocator = null,
    entries: std.StringHashMapUnmanaged(Entry) = .empty,
    /// The paths a `run` reached, in the order first reached.
    runs: std.ArrayListUnmanaged([]const u8) = .empty,
    /// Decisions 993 (3), 994 (L3) — the paths a `test()` reached: kept for
    /// the whole top-level compile (a compile again lowers their tests,
    /// `withTestFns`), never cleared with the runs.
    tests: std.ArrayListUnmanaged([]const u8) = .empty,
    /// Decision 998 (1) — the paths a `run()` written by an expansion at a
    /// run-time call reached (`expand_call.zig` `RunMark`): kept for the
    /// whole top-level compile, so a compile again imports their mains
    /// (`withRunImports`).
    expanded_runs: std.ArrayListUnmanaged([]const u8) = .empty,
    /// Whether a loaded package's tests are `async` (`testsAsync`), by path.
    tests_async: std.StringHashMapUnmanaged(bool) = .empty,
    /// The name of the test each lowered test function is (`withTestFns`),
    /// by `<module path>\x00<function>`: `@src().fnName` inside it.
    test_names: std.StringHashMapUnmanaged([]const u8) = .empty,
};

threadlocal var state: State = .{};

/// A fresh state for a top-level compile; the one it replaces, which
/// `leave` gives back.
pub fn enter() !State {
    const saved = state;
    const a = try std.heap.page_allocator.create(std.heap.ArenaAllocator);
    a.* = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    state = .{ .arena = a };
    return saved;
}

pub fn leave(saved: State) void {
    if (state.arena) |a| {
        a.deinit();
        std.heap.page_allocator.destroy(a);
    }
    state = saved;
}

fn stateArena() std.mem.Allocator {
    return if (state.arena) |a| a.allocator() else std.heap.page_allocator;
}

/// The key a load's entry is kept under: the package's directory relative
/// to the top-level package — `path` as written, under the directory of the
/// loaded package that writes it (`files.dir`, empty for the top-level
/// package's own loads). Two loaded packages loading `cases/<case>` each load
/// their own; a loaded package that loads and runs its own (the conformance
/// suite's root running its modules, each running its cases) keys each apart.
pub fn keyOf(arena: std.mem.Allocator, files: ?PackageFiles, path: []const u8) error{OutOfMemory}![]const u8 {
    const f = files orelse return path;
    if (f.dir.len == 0) return path;
    return std.fs.path.join(arena, &.{ f.dir, path });
}

/// The entry of `path` (a `keyOf` key), when this compile loaded it.
pub fn entryOf(path: []const u8) ?Entry {
    return state.entries.get(path);
}

/// Decision 1000 — where a module wrote `compiler.load(path)`: the audit of
/// `codegen/loaded_targets.zig` (at emit, after the compile's `State` is
/// gone) locates its refusal there. Kept per (module, path), the last write
/// winning; the module's name is the output's (`ComptimeOutput.name`).
const LoadSite = struct { module: []const u8, path: []const u8, loc: ast.Loc };
var load_sites: std.ArrayListUnmanaged(LoadSite) = .empty;
var load_sites_lock: std.atomic.Mutex = .unlocked;

fn lockSites() void {
    while (!load_sites_lock.tryLock()) std.Thread.yield() catch {};
}

/// Note that `module` wrote `compiler.load(path)` at `loc`.
pub fn noteLoadSite(module: []const u8, path: []const u8, loc: ast.Loc) !void {
    lockSites();
    defer load_sites_lock.unlock();
    for (load_sites.items) |*s| if (std.mem.eql(u8, s.module, module) and std.mem.eql(u8, s.path, path)) {
        s.loc = loc;
        return;
    };
    try load_sites.append(std.heap.page_allocator, .{
        .module = try std.heap.page_allocator.dupe(u8, module),
        .path = try std.heap.page_allocator.dupe(u8, path),
        .loc = loc,
    });
}

/// Where `module` wrote `compiler.load(path)`, else where any module did.
pub fn loadSite(module: []const u8, path: []const u8) ?ast.Loc {
    lockSites();
    defer load_sites_lock.unlock();
    var any: ?ast.Loc = null;
    for (load_sites.items) |s| if (std.mem.eql(u8, s.path, path)) {
        if (std.mem.eql(u8, s.module, module)) return s.loc;
        if (any == null) any = s.loc;
    };
    return any;
}

/// Record that a `run` reaches `path` (decision 787 (2)).
pub fn noteRun(path: []const u8) !void {
    for (state.runs.items) |p| if (std.mem.eql(u8, p, path)) return;
    try state.runs.append(stateArena(), try stateArena().dupe(u8, path));
}

/// The paths a `run` reached in this compile.
pub fn runs() []const []const u8 {
    return state.runs.items;
}

/// Forget the runs (a compile again records its own).
pub fn clearRuns() void {
    state.runs.clearRetainingCapacity();
}

/// Decision 998 (1) — record that a `run()` an expansion wrote reaches
/// `path`.
pub fn noteExpandedRun(path: []const u8) !void {
    for (state.expanded_runs.items) |p| if (std.mem.eql(u8, p, path)) return;
    try state.expanded_runs.append(stateArena(), try stateArena().dupe(u8, path));
}

/// Decision 993 (3) — record that a `test()` reaches `path`: the package
/// joins the program (`noteRun`) with its tests lowered (`withTestFns`).
pub fn noteTest(path: []const u8) !void {
    try noteRun(path);
    for (state.tests.items) |p| if (std.mem.eql(u8, p, path)) return;
    try state.tests.append(stateArena(), try stateArena().dupe(u8, path));
}

/// The entry of the loaded package `package` (`packageName`) a `test()`
/// reached in this compile, or null.
pub fn testedEntry(arena: std.mem.Allocator, package: []const u8) !?Entry {
    for (state.tests.items) |p| if (std.mem.eql(u8, try packageName(arena, p), package)) return entryOf(p);
    return null;
}

/// Decision 993 (3) — `@src().file` inside a loaded package is prefixed by
/// the directory it was loaded from: the path of the load whose package is
/// `package`, or null for a package no load of this compile names.
pub fn loadDirOf(arena: std.mem.Allocator, package: []const u8) !?[]const u8 {
    if (!isLoadedPackage(package)) return null;
    var it = state.entries.keyIterator();
    while (it.next()) |p| if (std.mem.eql(u8, try packageName(arena, p.*), package)) return p.*;
    return null;
}

/// `src_path` of a module of the loaded package `package` prefixed by its
/// load directory (`loadDirOf`), the text kept for the process as the
/// package's source is (`lasting`): an emitted literal slices it. Null for a
/// package no load names.
pub fn loadedSrcPath(arena: std.mem.Allocator, package: []const u8, src_path: []const u8) !?[]const u8 {
    const dir = (try loadDirOf(arena, package)) orelse return null;
    return try lasting(try std.fmt.allocPrint(arena, "{s}/{s}", .{ dir, src_path }));
}

/// The name of the test `function` of module `module_path` was lowered from
/// (`withTestFns`), or null for any other function.
pub fn testNameOf(arena: std.mem.Allocator, module_path: []const u8, function: []const u8) !?[]const u8 {
    if (!std.mem.startsWith(u8, function, test_case_prefix)) return null;
    return state.test_names.get(try std.mem.concat(arena, u8, &.{ module_path, "\x00", function }));
}

/// The files being loaded on this thread, outermost first — a file loading
/// one of them is a cycle.
threadlocal var loading: std.ArrayListUnmanaged([]const u8) = .empty;

/// One refusal of a loaded file — std's `compiler.Diagnostic`.
pub const Diagnostic = struct {
    code: []const u8,
    message: []const u8,
    file: []const u8,
    line: usize,
    column: usize,
    label: ?[]const u8 = null,
    /// Decision 989 (4) — the decision names it `from`, a reserved word: the calls (decision 532) a refusal raised at build
    /// crossed after the innermost one, each `<file>:<line>:<col>`, innermost
    /// first; empty when there are none.
    /// Decision 991 — `` `from` `` in std (a keyword, between backticks, 561).
    from: []const []const u8 = &.{},
};

// ── finding the reads ────────────────────────────────────────────────────────

fn isLoadCall(e: ast.Expr) bool {
    return e == .call and e.call.kind == .call and e.call.kind.call.is_builtin and std.mem.eql(u8, e.call.kind.call.callee, surface.load_builtin);
}

/// Whether `a` is `package: …` (decision 993 (2)).
pub fn isPackageArg(a: ast.CallArg) bool {
    return a.label != null and std.mem.eql(u8, a.label.?, package_label);
}

fn mayHoldExpr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union" => T != ast.Loc and T != ast.TypeRef,
        .optional => |o| mayHoldExpr(o.child),
        .pointer => |pi| pi.child != u8 and mayHoldExpr(pi.child),
        else => false,
    };
}

const Finder = struct {
    arena: std.mem.Allocator,
    found: bool = false,
    /// The paths of the reads known as written (`literalPaths`, `foldedPath`).
    paths: std.ArrayListUnmanaged([]const u8) = .empty,

    fn walk(self: *Finder, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.Expr) if (isLoadCall(v)) {
            self.found = true;
            const args = v.call.kind.call.args;
            // A literal, or a `+` of literals — what a `comptime` parameter
            // expanded at a top-level block's call leaves (decision 788).
            if (args.len == 1 and !isPackageArg(args[0])) if (try foldedPath(self.arena, args[0].value)) |p| try self.paths.append(self.arena, p);
        };
        if (comptime !mayHoldExpr(T)) return;
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => if (@typeInfo(ptr.child) != .@"fn" and @typeInfo(ptr.child) != .@"opaque") try self.walk(ptr.child, v.*),
                .slice => for (v) |item| try self.walk(ptr.child, item),
                else => {},
            },
            .optional => |o| if (v) |x| try self.walk(o.child, x),
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (!fl.is_comptime) try self.walk(fl.type, @field(v, fl.name));
            },
            .@"union" => |un| if (un.tag_type != null) switch (v) {
                inline else => |payload| try self.walk(@TypeOf(payload), payload),
            },
            else => {},
        }
    }
};

/// The paths a program's `compiler.load` reads write as string literals,
/// as the program names them (package-root-relative): the files a package's
/// module tree leaves out (decision 780 (1) over 677 — the CLI's resolver).
pub fn literalPaths(arena: std.mem.Allocator, program: ast.Program) ![]const []const u8 {
    var f: Finder = .{ .arena = arena };
    for (program.decls) |d| try f.walk(ast.DeclKind, d);
    return f.paths.items;
}

/// `program` with what its `compiler.load` reads are rewritten to call — the
/// import of std's `compiler.Diagnostic` under `diagnostic_alias` and the
/// function `helper_fn`, inferred with the module so every backend lowers a
/// typed body —, or `program` itself when it reads none.
pub fn withLoadHelper(arena: std.mem.Allocator, program: ast.Program) !ast.Program {
    var f: Finder = .{ .arena = arena };
    for (program.decls) |d| {
        try f.walk(ast.DeclKind, d);
        if (f.found) break;
    }
    if (!f.found) return program;
    for (program.decls) |d| switch (d) {
        .@"fn" => |fd| if (std.mem.eql(u8, fd.name, helper_fn)) return program,
        else => {},
    };
    const base = "import {compiler.Diagnostic as " ++ diagnostic_alias ++ ", compiler.Module as " ++ module_alias ++ ", compiler.Refused as " ++ refused_alias ++ ", failure.attempt as " ++ attempt_alias ++ "} from \"std\";\n" ++
        "fn " ++ helper_fn ++ "(m: " ++ module_alias ++ ", ds: " ++ diagnostic_alias ++ "[]) -> Result<" ++ module_alias ++ ", " ++ refused_alias ++ "> { if (ds.length > 0) throw " ++ refused_alias ++ "(module: m, diagnostics: ds); return m; }\n" ++
        "fn " ++ module_fn ++ "(name: string, path: string, buildOutput: string, mainAsync: bool) -> " ++ module_alias ++ " { return " ++ module_alias ++ "." ++ module_maker ++ "(name: name, path: path, buildOutput: buildOutput, mainAsync: mainAsync); }\n";
    // A module that writes a `run()` also gets what the call is rewritten to
    // (`runRewrite`): std's `compiler.RunFailure` and `run_fn` (decision 806).
    var runs_found: RunFinder = .{ .arena = arena, .collect_all = true };
    for (program.decls) |d| try runs_found.walk(ast.DeclKind, d);
    // A `` `test`() `` call (decision 993 (3)) also gets `test_run_fn` and
    // std's `compiler.TestReport` / `compiler.TestCase`.
    const tests_called = for (runs_found.calls.items) |c| {
        if (c.kind == .test_) break true;
    } else false;
    const run_base = base ++ "import {compiler.RunFailure as " ++ run_failure_alias ++ ", failure as " ++ failure_alias ++ "} from \"std\";\n" ++ run_fn_src;
    const src: []const u8 = if (runs_found.calls.items.len == 0)
        base
    else if (tests_called)
        run_base ++ test_imports_src ++ test_run_src
    else
        run_base;
    const helper = try parseShifted(arena, src, helper_first_line, null);
    markLowering(ast.Program, @constCast(&helper));
    // Both first: an alias of an imported type names it in a signature only
    // of a function declared after the import and before its callers.
    const decls = try arena.alloc(ast.DeclKind, program.decls.len + helper.decls.len);
    @memcpy(decls[0..helper.decls.len], helper.decls);
    @memcpy(decls[helper.decls.len..], program.decls);
    var out = program;
    out.decls = decls;
    return out;
}

/// Decision 830 (811-c) — every call of `ptr` (the parsed helper) marked as
/// the compiler's own lowering (`CallExpr.lowering`): the opaque checks admit
/// a marked call to build an opaque type or name a method without `pub`.
fn markLowering(comptime T: type, ptr: *T) void {
    if (T == ast.Expr) if (ptr.* == .call and ptr.call.kind == .call) {
        ptr.call.kind.call.lowering = true;
    };
    if (comptime !mayHoldExpr(T)) return;
    switch (@typeInfo(T)) {
        .@"struct" => |st| inline for (st.fields) |fl| {
            if (!fl.is_comptime) markLowering(fl.type, &@field(ptr.*, fl.name));
        },
        .@"union" => |un| if (un.tag_type != null) switch (ptr.*) {
            inline else => |*payload| markLowering(@TypeOf(payload.*), payload),
        },
        .optional => |o| if (ptr.*) |*inner| markLowering(o.child, inner),
        .pointer => |p| switch (p.size) {
            .one => if (@typeInfo(p.child) != .@"fn" and @typeInfo(p.child) != .@"opaque") markLowering(p.child, @constCast(ptr.*)),
            .slice => for (ptr.*) |*e| markLowering(p.child, @constCast(e)),
            else => {},
        },
        else => {},
    }
}

/// `src` parsed with every token moved to line `first + its line - 1` (and,
/// when `col` is given, to that column): lines no module writes.
fn parseShifted(arena: std.mem.Allocator, src: []const u8, first: usize, col: ?usize) !ast.Program {
    var lx = Lexer.init(src);
    const tokens = try arena.dupe(@import("../lexer.zig").Token, try lx.scanAll(arena));
    for (tokens) |*t| {
        t.line += first - 1;
        if (col) |c| t.col += c;
    }
    var p = Parser.init(tokens);
    return p.parse(arena);
}

// ── the answer as code ───────────────────────────────────────────────────────

/// The loaded package's `Module` (decisions 786 (1), 805 (4), 982 (4)).
pub const Loaded = struct {
    /// The package's directory as written (`cases/<case>`).
    path: []const u8,
    /// Its entry's key (`keyOf`), when it differs from `path`.
    key: ?[]const u8 = null,

    /// `name`: the loaded package's manifest name, as its load read it;
    /// `""` before the load answered.
    pub fn name(self: Loaded) []const u8 {
        const e = entryOf(self.key orelse self.path) orelse return "";
        return e.name;
    }

    /// `buildOutput`: what the loaded package's build printed; `""` before
    /// the load answered.
    pub fn buildOutput(self: Loaded) []const u8 {
        const e = entryOf(self.key orelse self.path) orelse return "";
        return e.build_output;
    }

    /// Decision 998 (4) — `mainAsync`: whether the loaded package's `main`
    /// is `async` (what `run()`'s type follows, 989 (2)); `false` before the
    /// load answered.
    pub fn mainAsync(self: Loaded) bool {
        const e = entryOf(self.path) orelse return false;
        return e.main_async;
    }
};

/// The call a read at `loc` is rewritten to: `__bp_loaded(__bp_load_module(…),
/// […])`, one `Bp__LoadDiagnostic(…)` per refusal, on a line of its own.
pub fn rewrite(arena: std.mem.Allocator, loc: ast.Loc, loaded: Loaded, ds: []const Diagnostic) error{OutOfMemory}!*ast.Expr {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.appendSlice(arena, "fn __bp_load_rewrite() { " ++ helper_fn ++ "(");
    try writeModule(arena, &text, loaded);
    try text.appendSlice(arena, ", ");
    try writeDiagnosticList(arena, &text, ds);
    try text.appendSlice(arena, "); }");
    // A line per call: its line and column folded into one line number.
    const line = rewrite_first_line + loc.line * 4096 + @min(loc.col, 4095);
    // The text is the compiler's own, every string escaped: it parses.
    const program = parseShifted(arena, text.items, line, null) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("compiler.load: the answer's code does not parse"),
    };
    const body = program.decls[0].@"fn".body;
    const out = try arena.create(ast.Expr);
    out.* = body[0].expr;
    return out;
}

// ── a read in a body that runs at build (decisions 787, 792) ─────────────────

/// The path a read writes, when it is known where the read stands: a string
/// literal, or a `+` of such (what a `comptime` parameter expanded at its
/// call leaves, `"src/cases/" + "fine" + "/mod.bp"`, decision 788). Null for
/// any other argument.
pub fn foldedPath(arena: std.mem.Allocator, e: *const ast.Expr) std.mem.Allocator.Error!?[]const u8 {
    switch (e.*) {
        .literal => |l| if (l.kind == .stringLit) return try @import("template_eval.zig").lexemeBytes(arena, l.kind.stringLit),
        .binaryOp => |b| if (b.op == .add) {
            const lhs = (try foldedPath(arena, b.lhs)) orelse return null;
            const rhs = (try foldedPath(arena, b.rhs)) orelse return null;
            return try std.mem.concat(arena, u8, &.{ lhs, rhs });
        },
        .comptime_ => |c| switch (c.kind) {
            .comptimeExpr => |inner| return foldedPath(arena, inner),
            else => {},
        },
        else => {},
    }
    return null;
}

/// `v` with each `compiler.load` read replaced by what `ctx.answer(call)`
/// gives (null keeps the read): a body that runs at build reads the answer
/// as a value the comptime runtime builds (`runtimeAnswer`).
pub fn replaceReads(arena: std.mem.Allocator, comptime T: type, v: T, ctx: anytype) anyerror!T {
    if (T == ast.Expr) if (isLoadCall(v)) {
        if (try ctx.answer(v)) |r| return r;
    };
    if (comptime !mayHoldExpr(T)) return v;
    switch (@typeInfo(T)) {
        .pointer => |ptr| switch (ptr.size) {
            .one => {
                if (@typeInfo(ptr.child) == .@"fn" or @typeInfo(ptr.child) == .@"opaque") return v;
                const n = try arena.create(ptr.child);
                n.* = try replaceReads(arena, ptr.child, v.*, ctx);
                return n;
            },
            .slice => {
                const out = try arena.alloc(ptr.child, v.len);
                for (v, 0..) |item, i| out[i] = try replaceReads(arena, ptr.child, item, ctx);
                return out;
            },
            else => return v,
        },
        .optional => |o| return if (v) |x| try replaceReads(arena, o.child, x, ctx) else null,
        .@"struct" => |st| {
            var out = v;
            inline for (st.fields) |fl| {
                if (!fl.is_comptime) @field(out, fl.name) = try replaceReads(arena, fl.type, @field(v, fl.name), ctx);
            }
            return out;
        },
        .@"union" => |un| {
            if (un.tag_type == null) return v;
            switch (v) {
                inline else => |payload, tag| return @unionInit(T, @tagName(tag), try replaceReads(arena, @TypeOf(payload), payload, ctx)),
            }
        },
        else => return v,
    }
}

/// Whether `fd`'s body reads `compiler.load`.
pub fn fnReads(arena: std.mem.Allocator, fd: ast.FnDecl) !bool {
    var f: Finder = .{ .arena = arena };
    try f.walk(ast.FnDecl, fd);
    return f.found;
}

/// The answer of a read in a body that runs at build, as code the comptime
/// runtime builds: `Ok(Bp__LoadModule(…))`, or `Error(Bp__LoadRefused(module:
/// …, diagnostics: […]))` — the records are the runtime's maps
/// (`decorator_eval`'s host records), no target (decision 805 (4)).
pub fn runtimeAnswer(arena: std.mem.Allocator, loc: ast.Loc, loaded: Loaded, ds: []const Diagnostic) error{OutOfMemory}!ast.Expr {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.appendSlice(arena, "fn __bp_load_rewrite() { ");
    try text.appendSlice(arena, if (ds.len == 0) "Ok(" else "Error(" ++ refused_alias ++ "(module: ");
    // The comptime runtime's host record (`decorator_eval`), built by its
    // constructor: no program reads it, and an executor writes it back as
    // `__bp_load_module(…)` (`recordSource`).
    try text.print(arena, module_alias ++ "(name: \"{s}\", path: \"{s}\", buildOutput: \"{s}\", mainAsync: {})", .{
        try blockEval.stringLexeme(arena, loaded.name()),
        try blockEval.stringLexeme(arena, loaded.path),
        try blockEval.stringLexeme(arena, loaded.buildOutput()),
        loaded.mainAsync(),
    });
    if (ds.len > 0) {
        try text.appendSlice(arena, ", diagnostics: ");
        try writeDiagnostics(arena, &text, ds);
        try text.append(arena, ')');
    }
    try text.appendSlice(arena, "); }");
    const line = rewrite_first_line + loc.line * 4096 + @min(loc.col, 4095);
    const program = parseShifted(arena, text.items, line, null) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("compiler.load: the build answer's code does not parse"),
    };
    return program.decls[0].@"fn".body[0].expr;
}

/// Decision 787 — a value a body that runs at build handed an executor
/// (the runtime's JSON of the record), written back as the source of the
/// record a `compiler.load` read answers: a `Module`, a `Refused`, a
/// `Diagnostic`, an array of those. Null for any other value.
pub fn recordSource(arena: std.mem.Allocator, v: std.json.Value) !?[]const u8 {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    if (!try writeRecord(arena, &text, v)) return null;
    return text.items;
}

fn jsonString(o: std.json.ObjectMap, key: []const u8) ?[]const u8 {
    const v = o.get(key) orelse return null;
    return if (v == .string) v.string else null;
}

fn jsonStrings(arena: std.mem.Allocator, o: std.json.ObjectMap, key: []const u8) ![]const []const u8 {
    const v = o.get(key) orelse return &.{};
    if (v != .array) return &.{};
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (v.array.items) |x| if (x == .string) try out.append(arena, x.string);
    return out.items;
}

fn jsonInt(o: std.json.ObjectMap, key: []const u8) ?usize {
    const v = o.get(key) orelse return null;
    return switch (v) {
        .integer => |i| if (i >= 0) @intCast(i) else null,
        else => null,
    };
}

fn writeRecord(arena: std.mem.Allocator, text: *std.ArrayListUnmanaged(u8), v: std.json.Value) !bool {
    switch (v) {
        .array => |items| {
            try text.append(arena, '[');
            for (items.items, 0..) |x, i| {
                if (i > 0) try text.appendSlice(arena, ", ");
                if (!try writeRecord(arena, text, x)) return false;
            }
            try text.append(arena, ']');
            return true;
        },
        .object => |o| {
            if (o.get("diagnostics")) |ds| {
                const m = o.get("module") orelse return false;
                try text.appendSlice(arena, refused_alias ++ "(module: ");
                if (!try writeRecord(arena, text, m)) return false;
                try text.appendSlice(arena, ", diagnostics: ");
                if (!try writeRecord(arena, text, ds)) return false;
                try text.append(arena, ')');
                return true;
            }
            if (o.get("message") != null) {
                const d: Diagnostic = .{
                    .code = jsonString(o, "code") orelse return false,
                    .message = jsonString(o, "message") orelse return false,
                    .file = jsonString(o, "file") orelse return false,
                    .line = jsonInt(o, "line") orelse return false,
                    .column = jsonInt(o, "column") orelse return false,
                    .label = jsonString(o, "label"),
                    .from = try jsonStrings(arena, o, "from"),
                };
                var one: std.ArrayListUnmanaged(u8) = .empty;
                try writeDiagnostics(arena, &one, &.{d});
                // `[…]` around the one written: the record alone.
                try text.appendSlice(arena, one.items[1 .. one.items.len - 1]);
                return true;
            }
            const path = jsonString(o, "path") orelse return false;
            const name = jsonString(o, "name") orelse return false;
            try text.print(arena, module_fn ++ "(name: \"{s}\", path: \"{s}\", buildOutput: \"{s}\", mainAsync: {})", .{
                try blockEval.stringLexeme(arena, name),
                try blockEval.stringLexeme(arena, path),
                try blockEval.stringLexeme(arena, jsonString(o, "buildOutput") orelse ""),
                if (o.get("mainAsync")) |ma| ma == .bool and ma.bool else false,
            });
            return true;
        },
        else => return false,
    }
}

// ── `Module.run()` (decisions 787, 792) ─────────────────────────────────────

/// The local name of std's `failure.attempt` in a module that runs a loaded
/// file (`withRunImports`).
pub const attempt_alias = "__bp_run_attempt";
/// The local name of std's `compiler.RunFailure` in a module that loads.
pub const run_failure_alias = "Bp__RunFailure";
/// The function a `run()` is rewritten to call (decisions 806, 989): std's
/// `attempt` over the loaded package's `loaded_main_fn`, inside the capture
/// std's `Module` opens and closes (`capture_open`, `capture_close`), its
/// answer read as `Ok` of the text the package wrote, or a `RunFailure` —
/// `.Failed` with the text of the `Error` the loaded `main` returned, `.Abort`
/// with the crash's text for anything the package's body, executors or `main`
/// raised —, its `output` the text written before. Nothing propagates out of
/// it.
/// Decision 989 (3): an `Error` that begins with `off_marker` is the root
/// the emit put in place of a package the target refuses — `.Refused` (`R`)
/// or `.Excluded` (`X`) with the refusal's text, nothing of the package run.
pub const run_fn = "__bp_run";
/// `run_fn` for a loaded `async` `main` (decision 989 (2)): std's
/// `failure.attemptTask` over it, awaited, answering `Async` of `run_fn`'s answer.
pub const run_async_fn = "__bp_run_async";
/// The local name of std's `failure` module in a module that runs a loaded
/// file, `run_async_fn` calling its `attemptTask` through it: a call of the
/// function imported under an alias of its own loses its `await` on wasm.
pub const failure_alias = "__bp_run_failure";
/// Decision 989 (1) — the methods of std's `compiler.Module` without `pub`
/// that open and close a run's capture: the lowering's calls, no program's.
pub const capture_open = "captureOpen";
pub const capture_close = "captureClose";
/// Decisions 772, 993 (3) — the methods of std's `compiler.Module` without
/// `pub` a lowered `` `test`() `` calls, as `botopink test`'s runner sets the
/// same variables: `BOTOPINK_TEST_TMPDIR` names a scratch directory of the
/// call's own while its tests run (`tmp_open` / `tmp_close`), and
/// `BOTOPINK_TEST_NAME` the running test's name while its body runs
/// (`name_open` / `name_close`); each close restores what its open replaced.
pub const tmp_open = "testTmpOpen";
pub const tmp_close = "testTmpClose";
pub const name_open = "testNameOpen";
pub const name_close = "testNameClose";
/// What `runRewrite` runs while the loaded package is not yet in the program.
const run_none_fn = "__bp_run_none";
const run_async_none_fn = "__bp_run_async_none";
/// A loaded `main`'s `Error(m)` read as a `RunFailure` (decision 989 (3):
/// `off_marker` first).
const run_failed_src =
    "{\n" ++
    "                if (m.startsWith(\"" ++ off_marker ++ "X\")) {\n" ++
    "                    throw " ++ run_failure_alias ++ "(kind: .Excluded, message: m.slice(9), output: output);\n" ++
    "                }\n" ++
    "                if (m.startsWith(\"" ++ off_marker ++ "R\")) {\n" ++
    "                    throw " ++ run_failure_alias ++ "(kind: .Refused, message: m.slice(9), output: output);\n" ++
    "                }\n" ++
    "                throw " ++ run_failure_alias ++ "(kind: .Failed, message: m, output: output);\n" ++
    "            }\n";
const run_fn_src =
    "fn " ++ run_fn ++ "(f: fn() -> Result<void, string>) -> Result<string, " ++ run_failure_alias ++ "> {\n" ++
    "    val open = " ++ module_alias ++ "." ++ capture_open ++ "();\n" ++
    "    val answer = " ++ attempt_alias ++ "(f);\n" ++
    "    val output = " ++ module_alias ++ "." ++ capture_close ++ "(open);\n" ++
    "    case answer {\n" ++
    "        Ok(ran) -> case ran {\n" ++
    "            Ok(_) -> return output;\n" ++
    "            Error(m) -> " ++ run_failed_src ++
    "        }\n" ++
    "        Error(crash) -> throw " ++ run_failure_alias ++ "(kind: .Abort, message: crash.message, output: output);\n" ++
    "    }\n" ++
    "}\n" ++
    "async fn " ++ run_async_fn ++ "(f: fn() -> Async<Result<void, string>>) -> Async<Result<string, " ++ run_failure_alias ++ ">> {\n" ++
    "    val open = " ++ module_alias ++ "." ++ capture_open ++ "();\n" ++
    "    val answer = await " ++ failure_alias ++ ".attemptTask(f);\n" ++
    "    val output = " ++ module_alias ++ "." ++ capture_close ++ "(open);\n" ++
    "    case answer {\n" ++
    "        Ok(ran) -> case ran {\n" ++
    "            Ok(_) -> return output;\n" ++
    "            Error(m) -> " ++ run_failed_src ++
    "        }\n" ++
    "        Error(crash) -> throw " ++ run_failure_alias ++ "(kind: .Abort, message: crash.message, output: output);\n" ++
    "    }\n" ++
    "}\n" ++
    "fn " ++ run_none_fn ++ "() -> Result<void, string> {\n    return;\n}\n" ++
    "async fn " ++ run_async_none_fn ++ "() -> Async<Result<void, string>> {\n    return;\n}\n";
/// The prefix of the local name a loaded package's `loaded_main_fn` is
/// imported under: `__bp_run__<package>`.
pub const run_alias_prefix = "__bp_run__";

/// The path of the `Module` a `run()` is called on, read off the receiver as
/// an executor holds it (`recordSource`): `__bp_load_module(…, path: "…")`,
/// or `Bp__LoadRefused(module: …, …).module`. Null for any other receiver.
pub fn receiverPath(arena: std.mem.Allocator, written: *const ast.Expr) !?[]const u8 {
    // A splice stands parenthesised: `(__bp_load_module(…)).run()`.
    var e = written;
    while (e.* == .collection and e.collection.kind == .grouped) e = e.collection.kind.grouped;
    switch (e.*) {
        .call => |c| if (c.kind == .call) {
            const cc = c.kind.call;
            // `__bp_load_module(…, path: "…")` (decision 811 (4)).
            if (cc.receiver != null or cc.is_builtin) return null;
            if (!std.mem.eql(u8, cc.callee, module_fn)) return null;
            for (cc.args) |a| if (a.label) |l| if (std.mem.eql(u8, l, "path")) return foldedPath(arena, a.value);
        },
        .identifier => |id| switch (id.kind) {
            .identAccess => |acc| if (std.mem.eql(u8, acc.member, "module") and acc.receiver.* == .call and acc.receiver.call.kind == .call) {
                const cc = acc.receiver.call.kind.call;
                if (cc.receiver != null or !std.mem.eql(u8, cc.callee, refused_alias)) return null;
                for (cc.args) |a| if (a.label) |l| if (std.mem.eql(u8, l, "module")) return receiverPath(arena, a.value);
            },
            else => {},
        },
        else => {},
    }
    return null;
}

/// `run()` rewritten: `__bp_run(__bp_run__<package>)` — `run_fn` over the
/// loaded package's `loaded_main_fn`, `run_async_fn` for an `async` `main`
/// (decision 989 (2)) —, or, while the package is not yet in the program (the
/// compile that finds the `run`, compiled again with it,
/// `comptime.compileWith`), over a function that does nothing.
pub fn runRewrite(arena: std.mem.Allocator, loc: ast.Loc, alias: ?[]const u8, async_: bool) error{OutOfMemory}!*ast.Expr {
    const text = try std.fmt.allocPrint(arena, "fn __bp_run_rewrite() {{ {s}({s}); }}", .{
        if (async_) run_async_fn else run_fn,
        alias orelse if (async_) run_async_none_fn else run_none_fn,
    });
    const line = rewrite_first_line + loc.line * 4096 + @min(loc.col, 4095);
    const program = parseShifted(arena, text, line, null) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("Module.run: the rewrite does not parse"),
    };
    const out = try arena.create(ast.Expr);
    out.* = program.decls[0].@"fn".body[0].expr;
    return out;
}

/// The local name `withRunImports` gives the loaded package `package`'s
/// `loaded_main_fn`.
pub fn runAlias(arena: std.mem.Allocator, package: []const u8) ![]const u8 {
    return std.mem.concat(arena, u8, &.{ run_alias_prefix, package });
}

/// A `run()` call as written: where, and on what — or a `` `test`() `` call
/// (decision 993 (3)), `kind` `.test_`.
pub const RunCall = struct { loc: ast.Loc, receiver: *const ast.Expr, kind: CallKind = .run };

/// Which of `Module`'s lowered methods a call names: `run()` or
/// `` `test`() `` (decision 993 (3)).
pub const CallKind = enum { run, test_ };

/// The lowered method `callee` names on a `Module`, or null.
pub fn moduleCallKind(callee: []const u8) ?CallKind {
    if (std.mem.eql(u8, callee, "run")) return .run;
    if (std.mem.eql(u8, callee, test_method)) return .test_;
    return null;
}

/// Every `x.run()` of `func`'s body — the calls an executor writes, before
/// the locals it captures are spliced (`infer.zig` `refuseExecutorRuns`).
pub fn runCalls(arena: std.mem.Allocator, func: ast.FunctionExpr) ![]const RunCall {
    var f: RunFinder = .{ .arena = arena, .collect_all = true };
    try f.walk([]const ast.Stmt, func.kind.body);
    return f.calls.items;
}

/// The path of the `Module` a captured local's value (the runtime's JSON,
/// `recordSource`) is: a `Module`'s own, or the `module` of a `Refused`
/// when `member` is `module`.
pub fn valuePath(v: std.json.Value, member: ?[]const u8) ?[]const u8 {
    if (v != .object) return null;
    if (member) |m| {
        if (!std.mem.eql(u8, m, "module")) return null;
        const inner = v.object.get("module") orelse return null;
        return valuePath(inner, null);
    }
    return jsonString(v.object, "path");
}

/// Decision 792 (4), (7) — `run()` on a local alias of a `Module` the
/// executor holds (`val m2 = m; m2.run()`, `m` spliced as its constructor,
/// `recordSource`): the receiver is written as the constructor the alias was
/// bound to, so `receiverPath` reads its file. A `val` whose value is traced
/// (a spliced constructor, a `Refused`'s `module`, or another traced alias)
/// binds its name for the statements after it in its block; any other `val`
/// and a lambda's parameter shadow the name.
const AliasTracer = struct {
    arena: std.mem.Allocator,
    scope: std.ArrayListUnmanaged(struct { name: []const u8, value: ?*const ast.Expr }) = .empty,

    fn lookup(self: *AliasTracer, name: []const u8) ?*const ast.Expr {
        var i = self.scope.items.len;
        while (i > 0) {
            i -= 1;
            if (std.mem.eql(u8, self.scope.items[i].name, name)) return self.scope.items[i].value;
        }
        return null;
    }

    fn traced(self: *AliasTracer, e: *const ast.Expr) std.mem.Allocator.Error!?*const ast.Expr {
        if ((try receiverPath(self.arena, e)) != null) return e;
        var x = e;
        while (x.* == .collection and x.collection.kind == .grouped) x = x.collection.kind.grouped;
        if (x.* == .identifier and x.identifier.kind == .ident) return self.lookup(x.identifier.kind.ident);
        return null;
    }

    fn walk(self: *AliasTracer, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == []const ast.Stmt or T == []ast.Stmt) {
            const mark = self.scope.items.len;
            defer self.scope.shrinkRetainingCapacity(mark);
            for (v) |st| {
                try self.walk(ast.Expr, st.expr);
                if (st.expr == .binding and st.expr.binding.kind == .localBind) {
                    const lb = st.expr.binding.kind.localBind;
                    const value = if (lb.mutable) null else try self.traced(lb.value);
                    try self.scope.append(self.arena, .{ .name = lb.name, .value = value });
                }
            }
            return;
        }
        if (T == ast.Expr) {
            if (v == .call and v.call.kind == .call) {
                const cc = v.call.kind.call;
                if (moduleCallKind(cc.callee) != null and cc.args.len == 0 and !cc.is_builtin) if (cc.receiver) |r| {
                    if (r.* == .identifier and r.identifier.kind == .ident) if (self.lookup(r.identifier.kind.ident)) |m| {
                        r.* = m.*;
                    };
                };
            }
            if (v == .function) {
                const mark = self.scope.items.len;
                defer self.scope.shrinkRetainingCapacity(mark);
                for (v.function.kind.params) |p| try self.scope.append(self.arena, .{ .name = p, .value = null });
                try self.walk(@TypeOf(v.function.kind.body), v.function.kind.body);
                return;
            }
        }
        if (comptime !mayHoldExpr(T)) return;
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => if (@typeInfo(ptr.child) != .@"fn" and @typeInfo(ptr.child) != .@"opaque") try self.walk(ptr.child, v.*),
                .slice => for (v) |item| try self.walk(ptr.child, item),
                else => {},
            },
            .optional => |o| if (v) |x| try self.walk(o.child, x),
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (!fl.is_comptime) try self.walk(fl.type, @field(v, fl.name));
            },
            .@"union" => |un| if (un.tag_type != null) switch (v) {
                inline else => |payload| try self.walk(@TypeOf(payload), payload),
            },
            else => {},
        }
    }
};

const RunFinder = struct {
    arena: std.mem.Allocator,
    paths: std.ArrayListUnmanaged([]const u8) = .empty,
    /// The paths of the `` `test`() `` calls (decision 993 (3)).
    test_paths: std.ArrayListUnmanaged([]const u8) = .empty,
    collect_all: bool = false,
    calls: std.ArrayListUnmanaged(RunCall) = .empty,

    fn walk(self: *RunFinder, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.Expr) if (v == .call and v.call.kind == .call) {
            const cc = v.call.kind.call;
            if (moduleCallKind(cc.callee)) |kind| if (cc.args.len == 0 and !cc.is_builtin) if (cc.receiver) |r| {
                if (self.collect_all) try self.calls.append(self.arena, .{ .loc = v.call.loc, .receiver = r, .kind = kind });
                if (try receiverPath(self.arena, r)) |p| try (if (kind == .run) &self.paths else &self.test_paths).append(self.arena, p);
            };
        };
        if (comptime !mayHoldExpr(T)) return;
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => if (@typeInfo(ptr.child) != .@"fn" and @typeInfo(ptr.child) != .@"opaque") try self.walk(ptr.child, v.*),
                .slice => for (v) |item| try self.walk(ptr.child, item),
                else => {},
            },
            .optional => |o| if (v) |x| try self.walk(o.child, x),
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (!fl.is_comptime) try self.walk(fl.type, @field(v, fl.name));
            },
            .@"union" => |un| if (un.tag_type != null) switch (v) {
                inline else => |payload| try self.walk(@TypeOf(payload), payload),
            },
            else => {},
        }
    }
};

/// `program` with the imports its `run()` calls are rewritten to name
/// (`runRewrite`): std's `failure.attempt` under `attempt_alias`, and the
/// `loaded_main_fn` of each loaded package already in the program under
/// `runAlias`. `program` itself when it calls none.
pub fn withRunImports(arena: std.mem.Allocator, program: ast.Program, files: ?PackageFiles) !ast.Program {
    var t: AliasTracer = .{ .arena = arena };
    for (program.decls) |d| try t.walk(ast.DeclKind, d);
    var f: RunFinder = .{ .arena = arena, .collect_all = true };
    for (program.decls) |d| try f.walk(ast.DeclKind, d);
    // Decision 998 (1) — a `run()` whose receiver is traced only where a
    // function expanded at a run-time call writes it (`loaded.run()`,
    // `loaded` bound at build, `expand_call.zig` `initHere`): the packages
    // those expansions ran (`noteExpandedRun`) are named.
    for (f.calls.items) |c| if (c.kind == .run and (try receiverPath(arena, c.receiver)) == null) {
        try f.paths.appendSlice(arena, state.expanded_runs.items);
        break;
    };
    if (f.paths.items.len == 0 and f.test_paths.items.len == 0) return program;
    var src: std.ArrayListUnmanaged(u8) = .empty;
    var has_attempt = false;
    var has_attempt_task = false;
    var has_failure = false;
    var has_module = false;
    var has_run_fn = false;
    var has_report = false;
    var has_test_run_fn = false;
    for (program.decls) |d| switch (d) {
        .use => |u| for (u.imports) |imp| {
            if (imp.alias) |a| {
                if (std.mem.eql(u8, a, attempt_alias)) has_attempt = true;
                if (std.mem.eql(u8, a, failure_alias)) has_attempt_task = true;
                if (std.mem.eql(u8, a, run_failure_alias)) has_failure = true;
                if (std.mem.eql(u8, a, module_alias)) has_module = true;
                if (std.mem.eql(u8, a, test_report_alias)) has_report = true;
            }
        },
        .@"fn" => |fd| {
            if (std.mem.eql(u8, fd.name, run_fn)) has_run_fn = true;
            if (std.mem.eql(u8, fd.name, test_run_fn)) has_test_run_fn = true;
        },
        else => {},
    };
    if (!has_attempt) try src.appendSlice(arena, "import {failure.attempt as " ++ attempt_alias ++ "} from \"std\";\n");
    if (!has_attempt_task) try src.appendSlice(arena, "import {failure as " ++ failure_alias ++ "} from \"std\";\n");
    if (!has_failure) try src.appendSlice(arena, "import {compiler.RunFailure as " ++ run_failure_alias ++ "} from \"std\";\n");
    if (!has_module) try src.appendSlice(arena, "import {compiler.Module as " ++ module_alias ++ "} from \"std\";\n");
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    for (f.paths.items) |p| {
        const pkg = try packageName(arena, try keyOf(arena, files, p));
        if (seen.contains(pkg)) continue;
        try seen.put(arena, pkg, {});
        const present = for (build_modules) |m| {
            if (std.mem.eql(u8, m.package, pkg)) break true;
        } else false;
        if (!present) continue;
        try src.print(arena, "import {{" ++ loaded_main_fn ++ " as {s}}} from \"{s}\";\n", .{ try runAlias(arena, pkg), pkg });
    }
    // Decision 993 (3) — a `` `test`() `` names the package's
    // `loaded_tests_fn` under `testsAlias`.
    var seen_tests: std.StringHashMapUnmanaged(void) = .empty;
    for (f.test_paths.items) |p| {
        const pkg = try packageName(arena, p);
        if (seen_tests.contains(pkg)) continue;
        try seen_tests.put(arena, pkg, {});
        const present = for (build_modules) |m| {
            if (std.mem.eql(u8, m.package, pkg)) break true;
        } else false;
        if (!present) continue;
        try src.print(arena, "import {{" ++ loaded_tests_fn ++ " as {s}}} from \"{s}\";\n", .{ try testsAlias(arena, pkg), pkg });
    }
    if (!has_run_fn) try src.appendSlice(arena, run_fn_src);
    if (f.test_paths.items.len > 0) {
        if (!has_report) try src.appendSlice(arena, test_imports_src);
        if (!has_test_run_fn) try src.appendSlice(arena, test_run_src);
    }
    if (src.items.len == 0) return program;
    const imports = try parseShifted(arena, src.items, helper_first_line + 100, null);
    // The capture's calls name methods of `Module` without `pub` (989 (1)).
    markLowering(ast.Program, @constCast(&imports));
    const decls = try arena.alloc(ast.DeclKind, program.decls.len + imports.decls.len);
    @memcpy(decls[0..imports.decls.len], imports.decls);
    @memcpy(decls[imports.decls.len..], program.decls);
    var out = program;
    out.decls = decls;
    return out;
}

// ── `Module.test()` (decisions 993 (3), 994 (L3)) ───────────────────────────

/// The method's name as `compiler.bp` declares it: `test` is a keyword, so
/// the name is written between backticks (decision 561) — `` m.`test`() ``.
pub const test_method = "`test`";
/// The function a tested package's root gains (`withTestFns`): its tests,
/// one `test_entry_type` each, every module's — its body and the package's
/// run first, anew at every `` `test`() `` as at every `run()` (806 (3)).
pub const loaded_tests_fn = "__bp_loaded_tests";
/// The local name of the `k`-th `test/` suite module's `tests_fn` in a
/// tested package's root (`withTestFns`).
const suite_alias_prefix = "__bp_suite_";
/// `loaded_tests_fn` of the root the emit puts in place of a package the
/// target refuses (`codegen/loaded_targets.zig`, decision 989 (3)): it throws
/// `off_marker` as `loaded_main_off_fn` does.
pub const loaded_tests_off_fn = "__bp_loaded_tests_off";
/// The function every module of a tested package gains: its own tests and
/// those of each module it declares (`mod m;`), in source order.
pub const tests_fn = "__bp_tests";
/// The prefix of the function each `test` block is lowered to:
/// `__bp_case_<k>`, `k` its index in its module.
pub const test_case_prefix = "__bp_case_";
/// The function a `` `test`() `` is rewritten to call: each test of the
/// package run inside its own capture and `attempt`, its answer a
/// `TestCase` — nothing a test raises ends the run (806 (2)) —, the whole a
/// `TestReport`; `Error(RunFailure)` only for a package the target refuses
/// (`.Refused`, `.Excluded`) or a crash outside every test (`.Abort`).
pub const test_run_fn = "__bp_test_run";
/// `test_run_fn` for a package whose tests are `async` (`testsAsync`):
/// each awaited in turn, answering `Async` of `test_run_fn`'s answer.
pub const test_run_async_fn = "__bp_test_run_async";
/// The prefix of the local name a tested package's `loaded_tests_fn` is
/// imported under: `__bp_tests__<package>`.
pub const tests_alias_prefix = "__bp_tests__";
/// The local names of std's `compiler.TestReport` and `compiler.TestCase`.
pub const test_report_alias = "Bp__TestReport";
pub const test_case_alias = "Bp__TestCase";
/// std's `compiler.TestCase`, field for field (`tests/compiler_members.zig`):
/// `botopink test --json`'s fields (decision 993 (3)).
pub const test_case_fields = [_][]const u8{ "name", "file", "line", "ok", "output", "message", "at", "durationMs" };
/// One test as the registry lists it: its name, its file (relative to the
/// package), its line, and the function it was lowered to.
const test_entry_sync = "#(string, string, i32, fn() -> Result<void, string>)";
const test_entry_async = "#(string, string, i32, fn() -> Async<Result<void, string>>)";
const test_none_fn = "__bp_tests_none";
const test_async_none_fn = "__bp_tests_async_none";
const test_case_fn = "__bp_test_case";
const test_answer_fn = "__bp_test_answer";
const test_failure_alias = "Bp__TestFailure";
const test_cases_fn = "__bp_test_cases";
const test_run_in_fn = "__bp_test_run_in";
const test_run_async_in_fn = "__bp_test_run_async_in";
const test_cases_async_fn = "__bp_test_cases_async";

const test_imports_src = "import {compiler.TestReport as " ++ test_report_alias ++ ", compiler.TestCase as " ++ test_case_alias ++ ", failure.Failure as " ++ test_failure_alias ++ "} from \"std\";\n";

/// One test's answer (`ran`, std's `attempt` over the lowered test) as its
/// `TestCase`, pushed onto `cases` once — outside the `case`, which a push in
/// each arm of inside the loop would need.
const test_answer_src =
    "        cases.push(" ++ test_answer_fn ++ "(e._0, e._1, e._2, ran, caseOutput));\n";

/// What the registry answered: its tests, each run by `__bp_test_cases`
/// (each inside its own capture and `attempt`), or, for a package the
/// target refuses, the `off_marker` text (`run_failed_src`); a crash while
/// the package's bodies run is `.Abort` with what they wrote.
fn testRunSrc(comptime async_: bool) []const u8 {
    const entry = if (async_) test_entry_async else test_entry_sync;
    const cases_fn = if (async_) test_cases_async_fn else test_cases_fn;
    const run_fn_name = if (async_) test_run_async_fn else test_run_fn;
    const in_fn = if (async_) test_run_async_in_fn else test_run_in_fn;
    const answer_type = "Result<" ++ test_report_alias ++ ", " ++ run_failure_alias ++ ">";
    const reg_type = "fn() -> Result<" ++ entry ++ "[], string>";
    // The call's scratch directory around its whole run, the package's
    // bodies included, as `botopink test` names one for the run.
    const outer = (if (async_) "async fn " ++ run_fn_name ++ "(reg: " ++ reg_type ++ ") -> Async<" ++ answer_type ++ "> {\n" else "fn " ++ run_fn_name ++ "(reg: " ++ reg_type ++ ") -> " ++ answer_type ++ " {\n") ++
        "    val tmp = " ++ module_alias ++ "." ++ tmp_open ++ "();\n" ++
        (if (async_) "    val answer = await " ++ in_fn ++ "(reg);\n" else "    val answer = " ++ in_fn ++ "(reg);\n") ++
        "    " ++ module_alias ++ "." ++ tmp_close ++ "(tmp);\n" ++
        "    case answer {\n" ++
        "        Ok(report) -> return report;\n" ++
        "        Error(failed) -> throw failed;\n" ++
        "    }\n" ++
        "}\n";
    const head = if (async_)
        "async fn " ++ in_fn ++ "(reg: " ++ reg_type ++ ") -> Async<" ++ answer_type ++ "> {\n"
    else
        "fn " ++ in_fn ++ "(reg: " ++ reg_type ++ ") -> " ++ answer_type ++ " {\n";
    const ran_ok = if (async_)
        "            Ok(entries) -> return await " ++ cases_fn ++ "(entries);\n"
    else
        "            Ok(entries) -> return " ++ cases_fn ++ "(entries);\n";
    const cases_head = if (async_)
        "async fn " ++ cases_fn ++ "(entries: " ++ entry ++ "[]) -> Async<" ++ test_report_alias ++ "> {\n"
    else
        "fn " ++ cases_fn ++ "(entries: " ++ entry ++ "[]) -> " ++ test_report_alias ++ " {\n";
    const run_one = if (async_)
        "        val ran = await " ++ failure_alias ++ ".attemptTask(e._3);\n"
    else
        "        val ran = " ++ attempt_alias ++ "(e._3);\n";
    return outer ++ head ++
        "    val open = " ++ module_alias ++ "." ++ capture_open ++ "();\n" ++
        "    val listed = " ++ attempt_alias ++ "(reg);\n" ++
        "    val output = " ++ module_alias ++ "." ++ capture_close ++ "(open);\n" ++
        "    case listed {\n" ++
        "        Ok(found) -> case found {\n" ++
        ran_ok ++
        "            Error(m) -> " ++ run_failed_src ++
        "        }\n" ++
        "        Error(crash) -> throw " ++ run_failure_alias ++ "(kind: .Abort, message: crash.message, output: output);\n" ++
        "    }\n" ++
        "}\n" ++
        cases_head ++
        "    var cases: " ++ test_case_alias ++ "[] = [];\n" ++
        "    for entries { e ->\n" ++
        "        val caseOpen = " ++ module_alias ++ "." ++ capture_open ++ "();\n" ++
        "        val named = " ++ module_alias ++ "." ++ name_open ++ "(e._0);\n" ++
        run_one ++
        "        " ++ module_alias ++ "." ++ name_close ++ "(named);\n" ++
        "        val caseOutput = " ++ module_alias ++ "." ++ capture_close ++ "(caseOpen);\n" ++
        test_answer_src ++
        "    }\n" ++
        "    return " ++ test_report_alias ++ "(cases: cases);\n" ++
        "}\n";
}

const test_run_src =
    testRunSrc(false) ++ testRunSrc(true) ++
    "fn " ++ test_case_fn ++ "(name: string, file: string, line: i32, ok: bool, message: string, output: string) -> " ++ test_case_alias ++ " {\n" ++
    "    val at = if (ok) \"\" else file + \":\" + line.toString();\n" ++
    "    return " ++ test_case_alias ++ "(name: name, file: file, line: line, ok: ok, output: output, message: message, at: at, durationMs: 0);\n" ++
    "}\n" ++
    "fn " ++ test_answer_fn ++ "(name: string, file: string, line: i32, ran: Result<Result<void, string>, " ++ test_failure_alias ++ ">, output: string) -> " ++ test_case_alias ++ " {\n" ++
    "    case ran {\n" ++
    "        Ok(answer) -> case answer {\n" ++
    "            Ok(_) -> return " ++ test_case_fn ++ "(name, file, line, true, \"\", output);\n" ++
    "            Error(m) -> return " ++ test_case_fn ++ "(name, file, line, false, m, output);\n" ++
    "        }\n" ++
    "        Error(crash) -> return " ++ test_case_fn ++ "(name, file, line, false, crash.message, output);\n" ++
    "    }\n" ++
    "}\n" ++
    "fn " ++ test_none_fn ++ "() -> Result<" ++ test_entry_sync ++ "[], string> {\n    return [];\n}\n" ++
    "fn " ++ test_async_none_fn ++ "() -> Result<" ++ test_entry_async ++ "[], string> {\n    return [];\n}\n";

/// The local name `withRunImports` gives the tested package `package`'s
/// `loaded_tests_fn`.
pub fn testsAlias(arena: std.mem.Allocator, package: []const u8) ![]const u8 {
    return std.mem.concat(arena, u8, &.{ tests_alias_prefix, package });
}

/// `` `test`() `` rewritten: `__bp_test_run(__bp_tests__<package>)` —
/// `test_run_async_fn` when the package's tests are `async` —, or, while the
/// package is not yet in the program, over a registry of no test.
pub fn testRewrite(arena: std.mem.Allocator, loc: ast.Loc, alias: ?[]const u8, async_: bool) error{OutOfMemory}!*ast.Expr {
    const text = try std.fmt.allocPrint(arena, "fn __bp_test_rewrite() {{ {s}({s}); }}", .{
        if (async_) test_run_async_fn else test_run_fn,
        alias orelse if (async_) test_async_none_fn else test_none_fn,
    });
    const line = rewrite_first_line + loc.line * 4096 + @min(loc.col, 4095);
    const program = parseShifted(arena, text, line, null) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("Module.test: the rewrite does not parse"),
    };
    const out = try arena.create(ast.Expr);
    out.* = program.decls[0].@"fn".body[0].expr;
    return out;
}

/// Whether an `await` stands in `v` outside every closure and `async { }`
/// block (each a scope of its own): a test body that awaits.
const AwaitFinder = struct {
    found: bool = false,

    fn walk(self: *AwaitFinder, comptime T: type, v: T) void {
        if (self.found) return;
        if (T == ast.Expr) {
            if (v == .function) return;
            if (v == .jump and v.jump.kind == .await_) {
                self.found = true;
                return;
            }
        }
        if (comptime !mayHoldExpr(T)) return;
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => if (@typeInfo(ptr.child) != .@"fn" and @typeInfo(ptr.child) != .@"opaque") self.walk(ptr.child, v.*),
                .slice => for (v) |item| self.walk(ptr.child, item),
                else => {},
            },
            .optional => |o| if (v) |x| self.walk(o.child, x),
            .@"struct" => |st| {
                // `for await (gen) { … }` awaits each item.
                if (@hasField(T, "awaitLoop")) if (v.awaitLoop) {
                    self.found = true;
                    return;
                };
                inline for (st.fields) |fl| {
                    if (!fl.is_comptime) self.walk(fl.type, @field(v, fl.name));
                }
            },
            .@"union" => |un| if (un.tag_type != null) switch (v) {
                inline else => |payload| self.walk(@TypeOf(payload), payload),
            },
            else => {},
        }
    }
};

/// Decision 993 (3) — whether the loaded package's tests are `async`: one of
/// its `test` blocks awaits. Then every test is lowered `async`, and its
/// `` `test`() `` answers an `Async` (989 (2)).
pub fn testsAsync(entry: Entry) !bool {
    if (state.tests_async.get(entry.path)) |b| return b;
    var scratch_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer scratch_state.deinit();
    const scratch = scratch_state.allocator();
    var found = false;
    const all = try std.mem.concat(scratch, Module, &.{ entry.modules, entry.test_modules });
    outer: for (all) |m| {
        var lx = Lexer.init(m.source);
        const tokens = lx.scanAll(scratch) catch continue;
        var p = Parser.init(tokens);
        const program = p.parse(scratch) catch continue;
        for (program.decls) |d| switch (d) {
            .@"test" => |t| {
                var f: AwaitFinder = .{};
                f.walk([]ast.Stmt, t.body);
                if (f.found) {
                    found = true;
                    break :outer;
                }
            },
            else => {},
        };
    }
    try state.tests_async.put(stateArena(), try stateArena().dupe(u8, entry.path), found);
    return found;
}

/// Decisions 993 (3), 513 — a module of a package a `` `test`() `` reached,
/// compiled in test mode in-process: each `test` block becomes the function
/// `__bp_case_<k>` (its body, then `return;`), answering `Result<void,
/// string>` — `Async` of it when the package's tests are `async` —, so a
/// `try` or `throw` in it is its failure; the module gains `tests_fn`, its
/// tests and its `mod`s' (each `test_entry_*`: the name — `test_<k>` for an
/// anonymous one —, the module's file, the line); the package's root gains
/// `loaded_tests_fn` over it and `loaded_tests_off_fn`. Any other module is
/// `program` itself.
pub fn withTestFns(arena: std.mem.Allocator, program: ast.Program, mod: Module) !ast.Program {
    if (!isLoadedPackage(mod.package)) return program;
    const entry = (try testedEntry(arena, mod.package)) orelse return program;
    var is_root = false;
    for (program.decls) |d| switch (d) {
        .@"fn" => |fd| {
            if (std.mem.eql(u8, fd.name, tests_fn)) return program;
            if (std.mem.eql(u8, fd.name, loaded_info_fn)) is_root = true;
        },
        else => {},
    };
    const async_ = try testsAsync(entry);
    const entry_type = if (async_) test_entry_async else test_entry_sync;
    const file = if (mod.srcPath.len > 0) mod.srcPath else try std.fmt.allocPrint(arena, "{s}.bp", .{mod.path});

    var text: std.ArrayListUnmanaged(u8) = .empty;
    var list: std.ArrayListUnmanaged(u8) = .empty;
    var n_tests: usize = 0;
    for (program.decls) |d| switch (d) {
        .@"test" => |t| {
            if (async_)
                try text.print(arena, "pub async fn {s}{d}() -> Async<Result<void, string>> {{\n    return;\n}}\n", .{ test_case_prefix, n_tests })
            else
                try text.print(arena, "pub fn {s}{d}() -> Result<void, string> {{\n    return;\n}}\n", .{ test_case_prefix, n_tests });
            const name = t.name orelse try std.fmt.allocPrint(arena, "test_{d}", .{n_tests});
            if (list.items.len > 0) try list.appendSlice(arena, ", ");
            // The function behind a lambda: a name alone in a tuple labels
            // its element.
            try list.print(arena, "#(\"{s}\", \"{s}\", {d}, {{ -> {s}{d}() }})", .{
                try blockEval.stringLexeme(arena, name),
                try blockEval.stringLexeme(arena, file),
                t.loc.line,
                test_case_prefix,
                n_tests,
            });
            const key = try std.fmt.allocPrint(stateArena(), "{s}\x00{s}{d}", .{ mod.path, test_case_prefix, n_tests });
            try state.test_names.put(stateArena(), key, try lasting(name));
            n_tests += 1;
        },
        else => {},
    };
    try text.print(arena, "pub fn " ++ tests_fn ++ "() -> {s}[] {{\n    val own: {s}[] = [{s}];\n    return own", .{ entry_type, entry_type, list.items });
    for (program.decls) |d| switch (d) {
        .mod => |m| try text.print(arena, ".append({s}." ++ tests_fn ++ "())", .{m.name}),
        else => {},
    };
    // The package's `test/` suite after its `src/` tests, in path order, as
    // `botopink test` runs it: each suite module's own registry.
    var suite_imports: std.ArrayListUnmanaged(u8) = .empty;
    if (is_root) for (entry.test_modules, 0..) |sm, s| {
        const logical = try std.mem.replaceOwned(u8, arena, sm.path, "/", ".");
        try suite_imports.print(arena, "import {{{s}." ++ tests_fn ++ " as " ++ suite_alias_prefix ++ "{d}}};\n", .{ logical, s });
        try text.print(arena, ".append(" ++ suite_alias_prefix ++ "{d}())", .{s});
    };
    try text.appendSlice(arena, ";\n}\n");
    if (is_root) try text.print(arena, "pub fn " ++ loaded_tests_fn ++ "() -> Result<{s}[], string> {{\n    return " ++ tests_fn ++ "();\n}}\n" ++
        "pub fn " ++ loaded_tests_off_fn ++ "() -> Result<{s}[], string> {{\n    throw \"\";\n}}\n", .{ entry_type, entry_type });
    // The text outlives the compile as a loaded package's source does
    // (`lasting`): an emitted literal slices it.
    const generated = parseShifted(arena, try lasting(text.items), helper_first_line + 300, null) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("Module.test: the lowered tests do not parse"),
    };

    const suite = if (suite_imports.items.len == 0) ast.Program{ .decls = &.{} } else parseShifted(arena, try lasting(suite_imports.items), helper_first_line + 200, null) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("Module.test: the test suite's imports do not parse"),
    };
    const decls = try arena.alloc(ast.DeclKind, suite.decls.len + program.decls.len + generated.decls.len - n_tests);
    @memcpy(decls[0..suite.decls.len], suite.decls);
    var k: usize = 0;
    var i: usize = suite.decls.len;
    for (program.decls) |d| {
        defer i += 1;
        decls[i] = switch (d) {
            .@"test" => |t| blk: {
                var fd = generated.decls[k].@"fn";
                k += 1;
                fd.name = try lasting(try std.fmt.allocPrint(arena, "{s}{d}", .{ test_case_prefix, k - 1 }));
                fd.nameLoc = t.loc;
                fd.startLoc = t.loc;
                fd.docComment = t.docComment;
                fd.comment = t.comment;
                fd.moduleComment = t.moduleComment;
                fd.body = try std.mem.concat(arena, ast.Stmt, &.{ t.body, fd.body });
                break :blk .{ .@"fn" = fd };
            },
            else => d,
        };
    }
    @memcpy(decls[i..], generated.decls[n_tests..]);
    var out = program;
    out.decls = decls;
    return out;
}

/// The modules a loaded package joins the program with (decision 787 (2)):
/// `entry`'s file and its `mod` tree, each named `<package>/<logical>`, the
/// root gaining `loaded_main_fn` — its `main`, or, for a `main` answering a
/// `Result`, its `Error`'s text thrown (806 (1)).
/// The strings of the loaded packages' modules (their names, paths and
/// sources) outlive the compile: a backend's output names its module and
/// renders a diagnostic over its source after the session is gone, as a
/// driver's own modules outlive it. Interned for the process, one copy per
/// text however many compiles meet it.
var lasting_mutex: std.atomic.Mutex = .unlocked;
var lasting_arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var lasting_set: std.StringHashMapUnmanaged(void) = .empty;

fn lasting(text: []const u8) ![]const u8 {
    while (!lasting_mutex.tryLock()) std.atomic.spinLoopHint();
    defer lasting_mutex.unlock();
    if (lasting_set.getKey(text)) |k| return k;
    const copy = try lasting_arena.allocator().dupe(u8, text);
    try lasting_set.put(lasting_arena.allocator(), copy, {});
    return copy;
}

pub fn packageModules(arena: std.mem.Allocator, entry: Entry, targets: ?moduleMod.Targets) ![]const Module {
    const pkg = try packageName(arena, entry.path);
    const out = try arena.alloc(Module, entry.modules.len);
    for (entry.modules, 0..) |m, i| {
        var source = try arena.dupe(u8, m.source);
        // Decision 1001 (4) — a package with no `main` gains neither
        // `loaded_main_fn` nor `loaded_main_off_fn`: its `run()` is refused
        // (`no_main`), its `` `test`() `` runs.
        if (m.root) source = try std.mem.concat(arena, u8, &.{
            source,
            if (!entry.has_main)
                ""
            else if (entry.main_async)
                // Decision 989 (2) — an `async` `main`, awaited.
                (if (entry.main_result)
                    "\n\npub async fn " ++ loaded_main_fn ++ "() -> Async<Result<void, string>> {\n    case await main() {\n        Ok(_) -> return;\n        Error(e) -> throw \"${e}\";\n    }\n}\n"
                else
                    "\n\npub async fn " ++ loaded_main_fn ++ "() -> Async<Result<void, string>> {\n    await main();\n    return;\n}\n")
            else if (entry.main_result)
                "\n\npub fn " ++ loaded_main_fn ++ "() -> Result<void, string> {\n    case main() {\n        Ok(_) -> return;\n        Error(e) -> throw \"${e}\";\n    }\n}\n"
            else
                "\n\npub fn " ++ loaded_main_fn ++ "() -> Result<void, string> {\n    main();\n    return;\n}\n",
            // Decision 989 (3) — read and rewritten at `emit`.
            if (!entry.has_main)
                ""
            else if (entry.main_async)
                "\npub async fn " ++ loaded_main_off_fn ++ "() -> Async<Result<void, string>> {\n    throw \"\";\n}\n"
            else
                "\npub fn " ++ loaded_main_off_fn ++ "() -> Result<void, string> {\n    throw \"\";\n}\n",
            "\npub fn " ++ loaded_info_fn ++ "() -> string {\n    return \"",
            try blockEval.stringLexeme(arena, entry.path),
            "|",
            try targetsText(arena, entry.targets),
            "\";\n}\n",
        });
        out[i] = .{
            .path = try lasting(try std.mem.concat(arena, u8, &.{ pkg, "/", m.path })),
            .source = try lasting(source),
            .srcPath = try lasting(m.srcPath),
            .package = try lasting(pkg),
            .targets = targets,
            .files = m.files,
        };
    }
    // Decision 993 (3) — a tested package's `test/` suite joins with it.
    const tested = for (state.tests.items) |p| {
        if (std.mem.eql(u8, p, entry.path)) break true;
    } else false;
    if (!tested or entry.test_modules.len == 0) return out;
    const suite = try arena.alloc(Module, entry.test_modules.len);
    for (entry.test_modules, suite) |m, *s| s.* = .{
        .path = try lasting(try std.mem.concat(arena, u8, &.{ pkg, "/", m.path })),
        .source = try lasting(m.source),
        .srcPath = try lasting(m.srcPath),
        .package = try lasting(pkg),
        .targets = targets,
        .files = m.files,
    };
    // Each suite module imports the package's modules and the root imports
    // each suite's registry: the suite compiles before the root.
    var ordered: std.ArrayListUnmanaged(Module) = .empty;
    for (entry.modules, out) |m, o| if (!m.root) try ordered.append(arena, o);
    try ordered.appendSlice(arena, suite);
    for (entry.modules, out) |m, o| if (m.root) try ordered.append(arena, o);
    return ordered.items;
}

/// A manifest's `targets` as `loaded_info_fn` writes them: the names
/// joined by `,`, `*` for a manifest that declares none.
fn targetsText(arena: std.mem.Allocator, targets: ?moduleMod.Targets) ![]const u8 {
    const t = targets orelse return "*";
    var out: std.ArrayListUnmanaged(u8) = .empty;
    inline for (.{ "commonJS", "typescript", "erlang", "beam", "wasm" }) |n| if (@field(t, n)) {
        if (out.items.len > 0) try out.append(arena, ',');
        try out.appendSlice(arena, n);
    };
    return out.items;
}

/// `__bp_load_module(name: …, path: …, buildOutput: …, mainAsync: …)` — decision 811 (4): std's opaque
/// `Module` made by its method without `pub` (`module_fn`'s body, the only
/// call of it).
fn writeModule(arena: std.mem.Allocator, text: *std.ArrayListUnmanaged(u8), loaded: Loaded) !void {
    try text.print(arena, module_fn ++ "(name: \"{s}\", path: \"{s}\", buildOutput: \"{s}\", mainAsync: {})", .{
        try blockEval.stringLexeme(arena, loaded.name()),
        try blockEval.stringLexeme(arena, loaded.path),
        try blockEval.stringLexeme(arena, loaded.buildOutput()),
        loaded.mainAsync(),
    });
}

fn writeDiagnostics(arena: std.mem.Allocator, text: *std.ArrayListUnmanaged(u8), ds: []const Diagnostic) !void {
    try writeDiagnosticList(arena, text, ds);
}

/// `[Bp__LoadDiagnostic(…), …]`.
fn writeDiagnosticList(arena: std.mem.Allocator, text: *std.ArrayListUnmanaged(u8), ds: []const Diagnostic) !void {
    try text.append(arena, '[');
    for (ds, 0..) |d, i| {
        if (i > 0) try text.appendSlice(arena, ", ");
        try text.print(arena, diagnostic_alias ++ "(code: \"{s}\", message: \"{s}\", file: \"{s}\", line: {d}, column: {d}, label: ", .{
            try blockEval.stringLexeme(arena, d.code),
            try blockEval.stringLexeme(arena, d.message),
            try blockEval.stringLexeme(arena, d.file),
            d.line,
            d.column,
        });
        if (d.label) |l| try text.print(arena, "\"{s}\", `from`: [", .{try blockEval.stringLexeme(arena, l)}) else try text.appendSlice(arena, "null, `from`: [");
        for (d.from, 0..) |f, k| {
            if (k > 0) try text.appendSlice(arena, ", ");
            try text.print(arena, "\"{s}\"", .{try blockEval.stringLexeme(arena, f)});
        }
        try text.appendSlice(arena, "])");
    }
    try text.append(arena, ']');
}

// ── the nested compile ───────────────────────────────────────────────────────

pub const Request = struct {
    /// The loaded package's directory, relative to the caller's
    /// `botopink.json` (decision 982 (1)); its path rules already checked
    /// (`embed.checkPath`).
    path: []const u8,
    files: PackageFiles,
    io: std.Io,
    build_root: ?[]const u8,
    /// Decision 993 (2) — the package's directory when a resolver answered it
    /// (a `compiler.load(package: …)` outside the caller's tree): read from
    /// there instead of from `path` under `files`; `path` is then only the
    /// name the load is kept under.
    at: ?[]const u8 = null,
};

pub const Answer = union(enum) {
    /// The refusals, in order; empty when the package compiles.
    diagnostics: []const Diagnostic,
    /// Decision 982 (2) — the path names no package: what it lacks.
    not_a_package: NotAPackageWhy,
    /// The file is already being loaded on this thread.
    cycle,
    /// std's one-time initialisation is running: no compile may start.
    std_initialising,
};

/// Decision 982 (2) — why a path is no package: it names a file, or a
/// directory with no `botopink.json`, or one with no entry file.
pub const NotAPackage = enum {
    file,
    no_manifest,
    no_main,
};

/// `NotAPackage` and the entry file the package lacks (decision 993 (1):
/// its manifest's `src` and `entry`, `src/main.bp` by default).
pub const NotAPackageWhy = struct {
    why: NotAPackage,
    entry: []const u8 = package_main,

    /// The refusal's text after the path, allocated with `arena`.
    pub fn text(self: NotAPackageWhy, arena: std.mem.Allocator) ![]const u8 {
        return switch (self.why) {
            .file => "names a file, not a package directory",
            .no_manifest => "names no directory holding a `botopink.json`",
            .no_main => try std.fmt.allocPrint(arena, "names a package with no `{s}`", .{self.entry}),
        };
    }
};

/// The entry a loaded package is compiled from when its manifest writes
/// neither `src` nor `entry` (decisions 982 (1), 993 (1), 512 (4)).
pub const package_main = "src/main.bp";

/// What a loaded package's own `botopink.json` says (decisions 982 (1), (3),
/// 993 (1)): its name, its targets (null when it declares none) and the
/// names of its dependencies; its entry file is `entryFileOf`'s.
const Manifest = struct {
    name: []const u8 = "",
    targets: ?moduleMod.Targets = null,
    dependencies: []const []const u8 = &.{},
};

/// Decision 993 (1) — what resolves a loaded package's own dependencies, as
/// `botopink build` in its directory would: `path` from its directory,
/// `{ "workspace": true }` from its workspace's root, `git` through decision
/// 483's tiers. The CLI hands it (`libs.installLoadResolver`); with none (the
/// language server, the browser build, a unit test) a loaded package's
/// dependency is the caller build's module of that name (decision 982 (1)).
pub const Resolver = struct {
    ctx: ?*anyopaque = null,
    /// The dependencies of the package whose `botopink.json` is in `dir` (a
    /// directory as the caller's reader roots it, joined with the loaded
    /// path). What it answers lives as long as the process.
    resolve: *const fn (ctx: ?*anyopaque, io: std.Io, dir: []const u8) anyerror!Resolution,
    /// Decision 993 (2) — the directory of the package named `name`, looked up
    /// as a `git` dependency of the package whose directory is `from` is
    /// (decision 483's tiers). Null: this resolver resolves no name.
    by_name: ?*const fn (ctx: ?*anyopaque, io: std.Io, name: []const u8, from: []const u8) anyerror!NameResolution = null,
};

/// A `Resolver.by_name` answer.
pub const NameResolution = union(enum) {
    /// The package's directory as the resolver found it (`dir`), and the same
    /// directory relative to `from` when it is under it (`rel`).
    found: struct { dir: []const u8, rel: ?[]const u8 = null },
    /// No library declares the name.
    unknown,
    /// The name resolves to no package: two libraries declare it, it names a
    /// workspace, or a manifest it reaches is refused — the text the
    /// dependency resolution gives.
    refused: []const u8,
};

/// Decision 993 (2) — `compiler.load(package: name)` resolved.
pub const Named = union(enum) {
    /// Load the package at `path`: relative to the caller's package when it
    /// is under it (`at` null), else the directory the resolver answered
    /// (`at`, and `path` the same text).
    found: struct { path: []const u8, at: ?[]const u8 },
    no_resolver,
    unknown,
    refused: []const u8,
};

/// Ask the resolver for the package `name`, from the package `files` reads.
pub fn resolveName(arena: std.mem.Allocator, files: PackageFiles, io: std.Io, name: []const u8) !Named {
    const r = resolver orelse return .no_resolver;
    const by_name = r.by_name orelse return .no_resolver;
    const from = try packageDir(arena, files);
    return switch (try by_name(r.ctx, io, name, from)) {
        .found => |f| if (f.rel) |rel|
            .{ .found = .{ .path = rel, .at = null } }
        else
            .{ .found = .{ .path = f.dir, .at = f.dir } },
        .unknown => .unknown,
        .refused => |m| .{ .refused = m },
    };
}

/// The label of `compiler.load`'s other argument form (decision 993 (2)).
pub const package_label = "package";

/// A `Resolver`'s answer for one loaded package.
pub const Resolution = union(enum) {
    ok: struct {
        /// Every module of the package's dependency closure, dependencies
        /// before dependents, each carrying its package (`Module.package`).
        modules: []const Module,
        /// Decisions 75, 512 (3), 770 — the targets the package holds when its
        /// manifest writes none (its workspace's, narrowed by its
        /// dependencies'); null when nothing narrows them.
        targets: ?[]const []const u8 = null,
    },
    /// The package's manifest or its dependencies refused, as `botopink
    /// build` there would refuse them: one `Diagnostic` at `botopink.json`.
    refused: Refusal,

    /// A refusal's text and where in `botopink.json` it points (`line` and
    /// `column` 0 when nowhere).
    pub const Refusal = struct { message: []const u8, line: usize = 0, column: usize = 0 };
};

/// The resolver of this process (set once by the CLI, before any compile).
pub var resolver: ?Resolver = null;

/// The directory of the loaded package `files` reads, as its reader roots it.
fn packageDir(arena: std.mem.Allocator, files: PackageFiles) ![]const u8 {
    if (files.dir.len == 0) return arena.dupe(u8, files.root);
    return std.fs.path.join(arena, &.{ files.root, files.dir });
}

/// The manifest's `src` as a directory of the package — `"src/"` → `"src"`,
/// `"."` or `"./"` → `""` (the CLI's `ProjectConfig.srcDir`).
fn srcDirOf(src: []const u8) []const u8 {
    var s = std.mem.trimEnd(u8, src, "/");
    while (std.mem.startsWith(u8, s, "./")) s = s[2..];
    if (std.mem.eql(u8, s, ".")) return "";
    return s;
}

/// The entry file `text`'s `src` and `entry` name (decision 993 (1)), read
/// before the manifest is checked: a manifest that does not parse keeps
/// `package_main`, and its refusal is `readManifest`'s.
fn entryFileOf(arena: std.mem.Allocator, text: []const u8) ![]const u8 {
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, arena, text, .{}) catch return package_main;
    if (parsed != .object) return package_main;
    var src: []const u8 = "src";
    var entry: []const u8 = "main.bp";
    if (parsed.object.get("src")) |v| if (v == .string) {
        src = srcDirOf(v.string);
    };
    if (parsed.object.get("entry")) |v| if (v == .string and v.string.len > 0) {
        entry = v.string;
    };
    if (src.len == 0) return arena.dupe(u8, entry);
    return std.mem.concat(arena, u8, &.{ src, "/", entry });
}

/// Why a loaded package's `botopink.json` is refused, and where it points
/// (`line` and `column` 0 when nowhere).
const ManifestRefusal = struct { message: []const u8, line: usize = 0, column: usize = 0 };

/// The targets a manifest may name (`Targets.of`).
const known_targets = [_][]const u8{ "commonJS", "typescript", "erlang", "beam", "wasm" };

/// Where `"entry"` stands after `"key"` in `text`: the entry's quotes, else
/// the key's, else nowhere.
fn entryPlace(text: []const u8, key: []const u8, entry: []const u8) struct { line: usize, col: usize } {
    var kbuf: [256]u8 = undefined;
    var ebuf: [512]u8 = undefined;
    const qkey = std.fmt.bufPrint(&kbuf, "\"{s}\"", .{key}) catch return .{ .line = 0, .col = 0 };
    const qentry = std.fmt.bufPrint(&ebuf, "\"{s}\"", .{entry}) catch return .{ .line = 0, .col = 0 };
    const k = std.mem.indexOf(u8, text, qkey) orelse return .{ .line = 0, .col = 0 };
    const at = std.mem.indexOfPos(u8, text, k, qentry) orelse k;
    const lc = lineColOf(text, at);
    return .{ .line = lc.line, .col = lc.col };
}

/// `text`, a loaded package's `botopink.json`, or why it is no manifest.
fn readManifest(arena: std.mem.Allocator, text: []const u8) union(enum) { ok: Manifest, bad: ManifestRefusal } {
    const parsed = std.json.parseFromSliceLeaky(std.json.Value, arena, text, .{}) catch
        return .{ .bad = .{ .message = "botopink.json is not valid JSON" } };
    if (parsed != .object) return .{ .bad = .{ .message = "botopink.json is not a JSON object" } };
    var m: Manifest = .{};
    if (parsed.object.get("name")) |v| if (v == .string) {
        m.name = v.string;
    };
    if (parsed.object.get("targets")) |v| {
        if (v != .array) {
            const at = entryPlace(text, "targets", "targets");
            return .{ .bad = .{ .message = "\"targets\" is not an array of target names", .line = at.line, .column = at.col } };
        }
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        for (v.array.items) |t| {
            if (t != .string) {
                const at = entryPlace(text, "targets", "targets");
                return .{ .bad = .{ .message = "\"targets\" is not an array of target names", .line = at.line, .column = at.col } };
            }
            const known = for (known_targets) |k| {
                if (std.mem.eql(u8, k, t.string)) break true;
            } else false;
            if (!known) {
                const at = entryPlace(text, "targets", t.string);
                // The CLI's wording for a target it does not know.
                const message = std.fmt.allocPrint(arena, "unknown target `{s}` (commonJS, erlang, beam, wasm)", .{t.string}) catch return .{ .bad = .{ .message = "out of memory" } };
                return .{ .bad = .{ .message = message, .line = at.line, .column = at.col } };
            }
            names.append(arena, t.string) catch return .{ .bad = .{ .message = "out of memory" } };
        }
        m.targets = moduleMod.Targets.of(names.items);
    }
    if (parsed.object.get("dependencies")) |v| if (v == .object) {
        m.dependencies = v.object.keys();
    };
    return .{ .ok = m };
}

/// Compile the package at `req.path` (decision 982) from the entry its
/// manifest names (`src/main.bp` by default, decision 993 (1)), under its own
/// manifest, and answer its refusals, allocated with `arena`.
pub fn compileFile(arena: std.mem.Allocator, req: Request) !Answer {
    const comptimeMod = @import("../comptime.zig");
    if (!comptimeMod.stdlibTemplateReady()) return .std_initialising;
    const key = try keyOf(arena, req.files, req.path);
    for (loading.items) |p| if (std.mem.eql(u8, p, key)) return .cycle;
    // One compile per file per top-level compile (decision 787): every read
    // of it, and the compile again with the packages `run` reaches, read the
    // first answer.
    if (state.entries.get(key)) |e| return .{ .diagnostics = e.diagnostics };

    var scratch_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer scratch_state.deinit();
    const scratch = scratch_state.allocator();

    // Decision 982 (2) — a package directory: its own `botopink.json` and
    // `src/main.bp`; a file, or a directory short of either, is none.
    if (req.at == null and exists(scratch, req.files, req.path)) return .{ .not_a_package = .{ .why = .file } };
    const pkg_files = if (req.at) |dir| blk: {
        var f = req.files;
        f.root = try arena.dupe(u8, dir);
        f.dir = "";
        f.log = null;
        break :blk f;
    } else try req.files.under(arena, req.path);
    const manifest_text = pkg_files.readFile(scratch, "botopink.json") catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return .{ .not_a_package = .{ .why = .no_manifest } },
    };
    // Decision 993 (1) — the entry the manifest's `src` and `entry` name.
    const entry_file = try entryFileOf(arena, manifest_text);
    if (!exists(scratch, pkg_files, entry_file)) return .{ .not_a_package = .{ .why = .no_main, .entry = entry_file } };

    var refusals: std.ArrayListUnmanaged(Diagnostic) = .empty;
    var main_of: MainOf = .{};
    const manifest = switch (readManifest(scratch, manifest_text)) {
        .ok => |m| m,
        .bad => |why| {
            try refusals.append(arena, .{ .code = "", .message = try arena.dupe(u8, why.message), .file = "botopink.json", .line = why.line, .column = why.column });
            return .{ .diagnostics = try remember(key, "", "", refusals.items, &.{}, &.{}, main_of, null) };
        },
    };
    var pkg_req = req;
    pkg_req.files = pkg_files;
    const own = gatherTree(scratch, arena, pkg_req, entry_file, &refusals, &main_of) catch |err| switch (err) {
        error.FileNotFound => return .{ .not_a_package = .{ .why = .no_main, .entry = entry_file } },
        else => |e| return e,
    };
    if (refusals.items.len > 0) return .{ .diagnostics = try remember(key, manifest.name, "", refusals.items, own, &.{}, main_of, manifest.targets) };

    // Decisions 982 (1), (3), 993 (1) — the loaded package's own manifest:
    // its targets and its dependencies. With a resolver, the dependencies are
    // the package's own, resolved from its directory, and a manifest that
    // writes no targets holds what its workspace and its dependencies leave
    // it (75, 770); without one, each is the one the build resolved under that
    // name (one the build has none of is left out, and the loaded package's
    // import of it is its own refusal). The wasm host stays the build's.
    const caller = build_modules;
    var targets = manifest.targets;
    var wasm_host: ast.WasmHost = .wasi;
    for (caller) |m| if (m.package.len == 0) {
        wasm_host = m.wasm_host;
        break;
    };
    var modules: std.ArrayListUnmanaged(Module) = .empty;
    var own_dependencies: []const Module = &.{};
    if (resolver) |r| {
        const dir = try packageDir(scratch, pkg_files);
        const resolution = r.resolve(r.ctx, req.io, dir) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => Resolution{ .refused = .{ .message = try std.fmt.allocPrint(arena, "the dependencies of `{s}` could not be resolved ({s})", .{ req.path, @errorName(err) }) } },
        };
        switch (resolution) {
            .ok => |ok| {
                try modules.appendSlice(scratch, ok.modules);
                own_dependencies = ok.modules;
                if (targets == null) targets = moduleMod.Targets.of(ok.targets);
            },
            .refused => |why| {
                try refusals.append(arena, .{ .code = codeOf(why.message), .message = try arena.dupe(u8, why.message), .file = "botopink.json", .line = why.line, .column = why.column });
                return .{ .diagnostics = try remember(key, manifest.name, "", refusals.items, own, &.{}, main_of, manifest.targets) };
            },
        }
    } else for (caller) |m| if (m.package.len > 0) {
        const named = for (manifest.dependencies) |d| {
            if (std.mem.eql(u8, d, m.package)) break true;
        } else false;
        if (named) try modules.append(scratch, m);
    };
    for (own) |m| {
        var mm = m;
        mm.targets = targets;
        mm.wasm_host = wasm_host;
        mm.files = pkg_files;
        try modules.append(scratch, mm);
    }

    try loading.append(std.heap.page_allocator, key);
    defer _ = loading.pop();
    const saved = build_modules;
    defer build_modules = saved;

    var session = try comptimeMod.compile(std.heap.page_allocator, modules.items, req.io, req.build_root);
    defer session.deinit(std.heap.page_allocator);
    for (session.outputs.items) |o| {
        // A dependency's refusal is no refusal of the loaded file: it is the
        // caller's, reported where the caller is built (781 (5)).
        const ownModule = for (own) |m| {
            if (std.mem.eql(u8, if (m.path.len > 0) m.path else "main", o.name)) break true;
        } else false;
        if (!ownModule) continue;
        if (try diagnosticOf(arena, o)) |d| try refusals.append(arena, d);
    }
    // Decisions 833, 982 (3) — the target refusals, for every target the
    // loaded package's manifest declares (all when it declares none), after
    // the analysis ones.
    const declared = targets orelse moduleMod.Targets{ .commonJS = true, .typescript = true, .erlang = true, .beam = true, .wasm = true };
    var lookups: [3][]const u8 = undefined;
    var n_lookups: usize = 0;
    if (declared.commonJS or declared.typescript) {
        lookups[n_lookups] = "node";
        n_lookups += 1;
    }
    if (declared.erlang or declared.beam) {
        lookups[n_lookups] = "erlang";
        n_lookups += 1;
    }
    if (declared.wasm) {
        lookups[n_lookups] = wasm_host.lookupName();
        n_lookups += 1;
    }
    for (lookups[0..n_lookups]) |lookup| for (session.outputs.items) |o| {
        const ownModule = for (own) |m| {
            if (std.mem.eql(u8, if (m.path.len > 0) m.path else "main", o.name)) break true;
        } else false;
        if (!ownModule) continue;
        switch (o.outcome) {
            .ok => |ok| if (try targetCheck.refusalOf(arena, ok, lookup)) |te| {
                var refused = o;
                refused.outcome = .{ .typeError = te };
                if (try diagnosticOf(arena, refused)) |d| try refusals.append(arena, d);
            },
            else => {},
        }
    };
    // Decisions 904, 989 (4) — what the package's own modules printed at
    // build, a refused module's before its refusal.
    var printed: std.ArrayListUnmanaged(u8) = .empty;
    for (session.outputs.items) |o| {
        const ownModule = for (own) |m| {
            if (std.mem.eql(u8, if (m.path.len > 0) m.path else "main", o.name)) break true;
        } else false;
        if (!ownModule) continue;
        switch (o.outcome) {
            .ok => |ok| try printed.appendSlice(scratch, ok.build_output),
            else => if (o.target_trace) |t| try printed.appendSlice(scratch, t.build_output),
        }
    }
    const ds = try remember(key, manifest.name, printed.items, refusals.items, own, own_dependencies, main_of, targets);
    if (state.entries.getPtr(key)) |e| e.test_modules = try testSuite(stateArena(), pkg_files, targets, wasm_host);
    return .{ .diagnostics = ds };
}

/// Decision 993 (3) — the `test/` suite of the package `files` reads: each
/// `.bp` file under `test/`, named by its path there without `.bp` (`a_test`,
/// `nested/b_test`), its `@src().file` the package-relative path, in path
/// order — the modules `botopink test` scans beside `src/`.
fn testSuite(arena: std.mem.Allocator, files: PackageFiles, targets: ?moduleMod.Targets, wasm_host: ast.WasmHost) ![]const Module {
    const listed = files.listFiles(arena, "test") catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return &.{},
    };
    var out: std.ArrayListUnmanaged(Module) = .empty;
    for (listed) |rel| {
        if (!std.mem.endsWith(u8, rel, ".bp") or std.mem.endsWith(u8, rel, ".d.bp")) continue;
        const file = try std.mem.concat(arena, u8, &.{ "test/", rel });
        const source = files.readFile(arena, file) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => continue,
        };
        try out.append(arena, .{
            .path = try arena.dupe(u8, rel[0 .. rel.len - 3]),
            .source = source,
            .srcPath = file,
            .targets = targets,
            .wasm_host = wasm_host,
            .files = files,
        });
    }
    return out.items;
}

const MainOf = struct { has: bool = false, result: bool = false, async_: bool = false };

/// `path`'s entry in this compile's state, copied into the state's arena;
/// its diagnostics.
fn remember(path: []const u8, name: []const u8, build_output: []const u8, ds: []const Diagnostic, own: []const Module, dependencies: []const Module, main_of: MainOf, targets: ?moduleMod.Targets) ![]const Diagnostic {
    const a = stateArena();
    const dcopy = try a.alloc(Diagnostic, ds.len);
    for (ds, 0..) |d, i| dcopy[i] = .{
        .code = try a.dupe(u8, d.code),
        .message = try a.dupe(u8, d.message),
        .file = try a.dupe(u8, d.file),
        .line = d.line,
        .column = d.column,
        .label = if (d.label) |l| try a.dupe(u8, l) else null,
        .from = blk: {
            const from = try a.alloc([]const u8, d.from.len);
            for (d.from, 0..) |f, k| from[k] = try a.dupe(u8, f);
            break :blk from;
        },
    };
    const mcopy = try a.alloc(Module, own.len);
    for (own, 0..) |m, i| mcopy[i] = .{
        .path = try a.dupe(u8, m.path),
        .source = try a.dupe(u8, m.source),
        .srcPath = try a.dupe(u8, m.srcPath),
        .root = m.root,
        // The reader's paths are the load's (`PackageFiles.under`, the
        // caller's arena): a later compile that reaches this package — the
        // build's second pass, after the arena of the first is gone — reads
        // its own `compiler.load` files through them, so they are kept here.
        .files = if (m.files) |f| blk: {
            var kept = f;
            kept.root = try a.dupe(u8, f.root);
            kept.dir = try a.dupe(u8, f.dir);
            break :blk kept;
        } else null,
    };
    const key = try a.dupe(u8, path);
    try state.entries.put(a, key, .{ .path = key, .name = try a.dupe(u8, name), .build_output = try a.dupe(u8, build_output), .diagnostics = dcopy, .modules = mcopy, .has_main = main_of.has, .main_result = main_of.result, .main_async = main_of.async_, .targets = targets, .dependencies = dependencies });
    return dcopy;
}

/// The loaded file and the `mod` tree beside it, children before their
/// parent (a module compiles after what it declares), each named by its
/// logical path as the CLI's resolver names a package's modules. A `mod`
/// naming no file, or two, is a refusal of the tree (`refusals`), as the
/// resolver's.
fn gatherTree(scratch: std.mem.Allocator, arena: std.mem.Allocator, req: Request, entry: []const u8, refusals: *std.ArrayListUnmanaged(Diagnostic), main_of: *MainOf) ![]const Module {
    const Item = struct { logical: []const u8, file: []const u8, root: bool };
    var work: std.ArrayListUnmanaged(Item) = .empty;
    const base = std.fs.path.basename(entry);
    const rootLogical = if (std.mem.endsWith(u8, base, ".bp")) base[0 .. base.len - 3] else base;
    try work.append(scratch, .{ .logical = rootLogical, .file = entry, .root = true });
    var out: std.ArrayListUnmanaged(Module) = .empty;
    var i: usize = 0;
    while (i < work.items.len) : (i += 1) {
        const item = work.items[i];
        const source = req.files.readFile(arena, item.file) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => if (item.root) return error.FileNotFound else continue,
        };
        try out.append(scratch, .{ .path = item.logical, .source = source, .srcPath = item.file, .root = item.root, .files = req.files });
        var lx = Lexer.init(source);
        const tokens = lx.scanAll(scratch) catch continue;
        var p = Parser.init(tokens);
        const program = p.parse(scratch) catch continue;
        if (item.root) for (program.decls) |d| switch (d) {
            .@"fn" => |fd| if (std.mem.eql(u8, fd.name, "main")) {
                main_of.has = true;
                // Decision 989 (2) — an `async fn main` (`-> Async<…>`):
                // `run()` awaits it; its `Result` is the one inside.
                main_of.async_ = fd.marker == .task;
                if (fd.returnType) |rt| {
                    const inner = if (main_of.async_ and rt == .generic and std.mem.eql(u8, rt.generic.name, "Async") and rt.generic.args.len == 1) rt.generic.args[0] else rt;
                    main_of.result = inner == .generic and std.mem.eql(u8, inner.generic.name, "Result");
                }
            },
            else => {},
        };
        const dir = std.fs.path.dirname(item.file) orelse "";
        for (program.decls) |d| {
            const m = switch (d) {
                .mod => |m| m,
                else => continue,
            };
            const name = ast.unquotedName(m.name);
            const sibling = try joinPath(scratch, dir, try std.mem.concat(scratch, u8, &.{ name, ".bp" }));
            const folder = try joinPath(scratch, dir, try std.mem.concat(scratch, u8, &.{ name, "/mod.bp" }));
            const hasSibling = exists(scratch, req.files, sibling);
            const hasFolder = exists(scratch, req.files, folder);
            if (hasSibling == hasFolder) {
                try refusals.append(arena, .{
                    .code = "",
                    .message = if (hasSibling) "ambiguous module: both a sibling file and a folder index exist" else "unresolved module declaration",
                    .file = "",
                    .line = 0,
                    .column = 0,
                });
                continue;
            }
            const logical = if (item.root) try scratch.dupe(u8, name) else try std.mem.concat(scratch, u8, &.{ item.logical, "/", name });
            try work.append(scratch, .{ .logical = logical, .file = if (hasSibling) sibling else folder, .root = false });
        }
    }
    std.mem.reverse(Module, out.items);
    return orderedByImports(scratch, out.items);
}

/// `mods` (children before their parent) reordered so every module follows
/// the modules of the package it imports (`import {state.ActionState};`
/// names `state`, decision 337), as the CLI's resolver orders a package's
/// modules (`orderPackageModules`): each step places the first module whose
/// imports are all placed; a cycle keeps the rest in order, the checker
/// naming what is unbound.
fn orderedByImports(scratch: std.mem.Allocator, mods: []Module) ![]Module {
    const n = mods.len;
    if (n < 2) return mods;
    const needs = try scratch.alloc(bool, n * n);
    @memset(needs, false);
    for (mods, 0..) |m, i| {
        var lx = Lexer.init(m.source);
        const tokens = lx.scanAll(scratch) catch continue;
        var p = Parser.init(tokens);
        const program = p.parse(scratch) catch continue;
        for (program.decls) |d| switch (d) {
            .use => |imp| if (imp.source == .root) for (imp.imports) |item| {
                // The longest leading run of segments that is a module.
                var k = item.segments.len;
                while (k > 0) : (k -= 1) {
                    const path = try std.mem.join(scratch, "/", item.segments[0..k]);
                    const j = for (mods, 0..) |o, jj| {
                        if (std.mem.eql(u8, o.path, path)) break jj;
                    } else continue;
                    if (j != i) needs[i * n + j] = true;
                    break;
                }
            },
            else => {},
        };
    }
    const placed = try scratch.alloc(bool, n);
    @memset(placed, false);
    const order = try scratch.alloc(Module, n);
    for (0..n) |count| {
        const pick: usize = pick: {
            for (0..n) |i| {
                if (placed[i]) continue;
                for (0..n) |j| {
                    if (needs[i * n + j] and !placed[j]) break;
                } else break :pick i;
            }
            for (0..n) |i| if (!placed[i]) break :pick i;
            unreachable;
        };
        placed[pick] = true;
        order[count] = mods[pick];
    }
    return order;
}

fn joinPath(a: std.mem.Allocator, dir: []const u8, rel: []const u8) ![]const u8 {
    if (dir.len == 0) return a.dupe(u8, rel);
    return std.mem.concat(a, u8, &.{ dir, "/", rel });
}

fn exists(scratch: std.mem.Allocator, files: PackageFiles, rel: []const u8) bool {
    _ = files.readFile(scratch, rel) catch return false;
    return true;
}

// ── a refused module as a `Diagnostic` ───────────────────────────────────────

/// The refusal `o` carries, as `botopink build` prints it, or null when the
/// module compiled.
fn diagnosticOf(arena: std.mem.Allocator, o: anytype) !?Diagnostic {
    const file = if (o.srcPath.len > 0) o.srcPath else try std.fmt.allocPrint(arena, "{s}.bp", .{o.name});
    switch (o.outcome) {
        .ok => return null,
        .typeError => |te| {
            const message = try te.message(arena);
            var d: Diagnostic = .{ .code = codeOf(message), .message = message, .file = try arena.dupe(u8, file), .line = 0, .column = 0 };
            // A raise at build located in another file (decision 532).
            if (te.origin) |org| {
                d.file = try arena.dupe(u8, org.file);
                d.line = org.loc.line;
                d.column = org.loc.col;
            } else if (te.loc) |l| {
                d.line = l.line;
                d.column = l.col;
            }
            // Decision 989 (4) — the calls the raise crossed (532), the CLI's
            // `called from` lines, innermost first.
            if (te.frames.len > 0) {
                const from = try arena.alloc([]const u8, te.frames.len);
                for (te.frames, 0..) |f, i| from[i] = try std.fmt.allocPrint(arena, "{s}:{d}:{d}", .{ f.file, f.loc.line, f.loc.col });
                d.from = from;
            }
            return d;
        },
        .validationError => |ce| return .{
            .code = "",
            .message = "comptime: expression cannot be evaluated at compile time",
            .file = try arena.dupe(u8, file),
            .line = ce.loc.line,
            .column = ce.loc.col,
        },
        .parseError => |se| switch (se) {
            .lex => |lf| {
                const start = if (lf.info) |le| le.start else lf.start;
                const name = if (lf.info) |le| @tagName(le.kind) else lf.name;
                const at = lineColOf(o.src, start);
                return .{ .code = "", .message = try humanize(arena, name), .file = try arena.dupe(u8, file), .line = at.line, .column = at.col };
            },
            .parse => |info| {
                const i = info orelse return .{ .code = "", .message = try std.fmt.allocPrint(arena, "parse error in {s}", .{file}), .file = "", .line = 0, .column = 0 };
                var aw: std.Io.Writer.Allocating = .init(arena);
                try printErrors.render(&aw.writer, i, o.src, file);
                return try fromRendered(arena, aw.written());
            },
        },
    }
}

/// A refusal's code as its message writes it first, `<code>: …` (a code is
/// lowercase words joined by `-`); `""` when the message names none.
pub fn codeOf(message: []const u8) []const u8 {
    const colon = std.mem.indexOf(u8, message, ": ") orelse return "";
    const head = message[0..colon];
    if (head.len == 0 or std.mem.indexOfScalar(u8, head, '-') == null) return "";
    for (head) |c| if (!(std.ascii.isLower(c) or std.ascii.isDigit(c) or c == '-')) return "";
    return head;
}

/// A refusal rendered as `print.zig` renders a parse error, read back: the
/// `error[<code>]: <message>` line, the `--> <file>:<line>:<col>` under it and
/// the label beside the caret.
fn fromRendered(arena: std.mem.Allocator, text: []const u8) !Diagnostic {
    var d: Diagnostic = .{ .code = "", .message = "", .file = "", .line = 0, .column = 0 };
    var lines = std.mem.splitScalar(u8, text, '\n');
    var at_read = false;
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, " \r");
        if (d.message.len == 0) {
            if (std.mem.startsWith(u8, line, "error[")) {
                const close = std.mem.indexOf(u8, line, "]: ") orelse continue;
                d.code = try arena.dupe(u8, line["error[".len..close]);
                d.message = try arena.dupe(u8, line[close + 3 ..]);
            } else if (std.mem.startsWith(u8, line, "error: ")) {
                d.message = try arena.dupe(u8, line["error: ".len..]);
                d.code = codeOf(d.message);
            }
            continue;
        }
        const t = std.mem.trimStart(u8, line, " ");
        if (!at_read) {
            if (std.mem.startsWith(u8, t, "--> ")) {
                at_read = true;
                const place = t["--> ".len..];
                const c2 = std.mem.lastIndexOfScalar(u8, place, ':') orelse continue;
                const c1 = std.mem.lastIndexOfScalar(u8, place[0..c2], ':') orelse continue;
                d.file = try arena.dupe(u8, place[0..c1]);
                d.line = std.fmt.parseInt(usize, place[c1 + 1 .. c2], 10) catch 0;
                d.column = std.fmt.parseInt(usize, place[c2 + 1 ..], 10) catch 0;
            }
            continue;
        }
        if (caretLabel(line)) |l| {
            if (l.len > 0) d.label = try arena.dupe(u8, l);
            break;
        }
    }
    return d;
}

/// The text beside the caret of a snippet line (`  |   ^^^ the label`): ""
/// when the carets stand alone, null when the line is no caret line — as
/// `botopink build --json` reads it (`refusals.zig` `caretLabel`).
fn caretLabel(line: []const u8) ?[]const u8 {
    const bar = std.mem.indexOfScalar(u8, line, '|') orelse return null;
    if (std.mem.trim(u8, line[0..bar], " 0123456789").len != 0) return null;
    const after = std.mem.trimStart(u8, line[bar + 1 ..], " ");
    if (after.len == 0 or after[0] != '^') return null;
    const rest = std.mem.trimStart(u8, after, "^");
    return std.mem.trim(u8, rest, " ");
}

fn lineColOf(source: []const u8, offset: usize) struct { line: usize, col: usize } {
    const end = @min(offset, source.len);
    var line: usize = 1;
    var line_start: usize = 0;
    for (source[0..end], 0..) |c, i| {
        if (c == '\n') {
            line += 1;
            line_start = i + 1;
        }
    }
    return .{ .line = line, .col = end - line_start + 1 };
}

/// `UnterminatedString` → `unterminated string`, as the CLI prints a lex
/// error (`diagnostics.zig` `humanize`).
fn humanize(arena: std.mem.Allocator, name: []const u8) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (name, 0..) |c, i| {
        if (std.ascii.isUpper(c)) {
            if (i > 0) try out.append(arena, ' ');
            try out.append(arena, std.ascii.toLower(c));
        } else try out.append(arena, c);
    }
    return out.items;
}

test "a refusal's code is the kebab word its message writes first" {
    try std.testing.expectEqualStrings("embed-file-missing", codeOf("embed-file-missing: `@embed(\"a\")` names no file"));
    try std.testing.expectEqualStrings("", codeOf("type mismatch: expected i32, got string"));
    try std.testing.expectEqualStrings("", codeOf("unbound variable 'x'"));
}

test "a rendered parse refusal reads back as its code, message, place and label" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const text =
        \\error[case-bare-name-arm]: a name alone is not a pattern
        \\ --> src/cases/a/main.bp:7:9
        \\  |
        \\7 |         n { "other" }
        \\  |         ^ use _ { n -> … } to bind the matched value
        \\  |
        \\  = hint: An arm names a type.
        \\
    ;
    const d = try fromRendered(arena_state.allocator(), text);
    try std.testing.expectEqualStrings("case-bare-name-arm", d.code);
    try std.testing.expectEqualStrings("a name alone is not a pattern", d.message);
    try std.testing.expectEqualStrings("src/cases/a/main.bp", d.file);
    try std.testing.expectEqual(@as(usize, 7), d.line);
    try std.testing.expectEqual(@as(usize, 9), d.column);
    try std.testing.expectEqualStrings("use _ { n -> … } to bind the matched value", d.label.?);
}
