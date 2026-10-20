//! Decisions 780–783, 786 — `comptime compiler.load(path)`: a file of the
//! package compiled at build as the entry of a package of its own, answered
//! as its `Module` and its refusals.
//!
//! - `parser/compiler_surface.zig` reads `compiler.load(p)` onto the builtin
//!   `surface.load_builtin`; the checker (`infer.zig` `inferLoadBuiltin`, beside
//!   `@embed`'s) reads the path by `@embed`'s rules and calls `compileFile`.
//! - `compileFile` gathers the file's own `mod` tree beside it through the
//!   package's reader (`Module.files`), adds the caller build's dependency
//!   modules (the caller's manifest), and runs `comptime.compile` on them —
//!   no target, which comptime never reads (decision 798 (4)): a refusal
//!   that depends on the target is the emit's — captured: nothing is printed, and the caller's
//!   program never sees the modules. Each refused module is one `Diagnostic`,
//!   in the order `botopink build` prints them, with the text and the place it
//!   prints (decision 780 (2), 781).
//! - The answer is code (`rewrite`): `__bp_loaded(Bp_LoadModule(…),
//!   [Bp_LoadDiagnostic(…), …])`, a call of the function `withLoadHelper`
//!   declares in the module that loads (`Ok(m)` for `[]`, `Error(Refused(m,
//!   ds))` otherwise, decisions 782, 786), std's `compiler.Module`,
//!   `compiler.Refused` and `compiler.Diagnostic` imported under names no
//!   source writes. The `Module` is the loaded file's (`Loaded`): `name` its
//!   directory's, `path` the file — no target (decision 805 (4)).
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

/// The function `withLoadHelper` declares: `Ok(m)` for no refusal,
/// `Error(Refused(m, ds))` otherwise.
pub const helper_fn = "__bp_loaded";
/// The local name of std's `compiler.Diagnostic` in a module that loads.
pub const diagnostic_alias = "Bp_LoadDiagnostic";
/// The local name of std's `compiler.Module` in a module that loads.
pub const module_alias = "Bp_LoadModule";
/// The local name of std's `compiler.Refused` in a module that loads.
pub const refused_alias = "Bp_LoadRefused";

/// The fields of the records the answer builds, in the order `rewrite`
/// writes them — std's `compiler.Module`, `compiler.Refused` and
/// `compiler.Diagnostic`, record for record (`tests/compiler_members.zig`).
pub const records = [_]struct { name: []const u8, fields: []const []const u8 }{
    .{ .name = "Module", .fields = &.{ "name", "path" } },
    .{ .name = "Refused", .fields = &.{ "module", "diagnostics" } },
    .{ .name = "Diagnostic", .fields = &.{ "code", "message", "file", "line", "column", "label" } },
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

/// The package a loaded file is compiled into when a `run` reaches it.
pub fn packageName(arena: std.mem.Allocator, path: []const u8) ![]const u8 {
    const stem = if (std.mem.endsWith(u8, path, ".bp")) path[0 .. path.len - 3] else path;
    const out = try std.mem.replaceOwned(u8, arena, stem, "/", "__");
    return std.mem.concat(arena, u8, &.{ package_prefix, out });
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
    /// The refusals, empty when the file compiled.
    diagnostics: []const Diagnostic,
    /// The file and its `mod` tree (`gatherTree`), children first, each
    /// named by its logical path in the package.
    modules: []const Module,
    /// Whether the file declares a `main`, and whether that `main` answers a
    /// `Result`.
    has_main: bool,
    main_result: bool,
};

/// The state of one top-level compile (`comptime.compileWith` enters and
/// leaves it): the loaded files' entries and the files a `run` reaches.
pub const State = struct {
    arena: ?*std.heap.ArenaAllocator = null,
    entries: std.StringHashMapUnmanaged(Entry) = .empty,
    /// The paths a `run` reached, in the order first reached.
    runs: std.ArrayListUnmanaged([]const u8) = .empty,
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

/// The entry of `path`, when this compile loaded it.
pub fn entryOf(path: []const u8) ?Entry {
    return state.entries.get(path);
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
};

// ── finding the reads ────────────────────────────────────────────────────────

fn isLoadCall(e: ast.Expr) bool {
    return e == .call and e.call.kind == .call and e.call.kind.call.is_builtin and std.mem.eql(u8, e.call.kind.call.callee, surface.load_builtin);
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
            if (args.len == 1) if (try foldedPath(self.arena, args[0].value)) |p| try self.paths.append(self.arena, p);
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
        "fn " ++ helper_fn ++ "(m: " ++ module_alias ++ ", ds: " ++ diagnostic_alias ++ "[]) -> Result<" ++ module_alias ++ ", " ++ refused_alias ++ "> { if (ds.length > 0) throw " ++ refused_alias ++ "(module: m, diagnostics: ds); return m; }\n";
    // A module that writes a `run()` also gets what the call is rewritten to
    // (`runRewrite`): std's `compiler.RunFailure` and `run_fn` (decision 806).
    var runs_found: RunFinder = .{ .arena = arena, .collect_all = true };
    for (program.decls) |d| try runs_found.walk(ast.DeclKind, d);
    const src: []const u8 = if (runs_found.calls.items.len > 0)
        base ++ "import {compiler.RunFailure as " ++ run_failure_alias ++ "} from \"std\";\n" ++ run_fn_src
    else
        base;
    const helper = try parseShifted(arena, src, helper_first_line, null);
    // Both first: an alias of an imported type names it in a signature only
    // of a function declared after the import and before its callers.
    const decls = try arena.alloc(ast.DeclKind, program.decls.len + helper.decls.len);
    @memcpy(decls[0..helper.decls.len], helper.decls);
    @memcpy(decls[helper.decls.len..], program.decls);
    var out = program;
    out.decls = decls;
    return out;
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

/// The loaded file's `Module` (decisions 786 (1), 805 (4)).
pub const Loaded = struct {
    /// The file, relative to the package's `botopink.json`.
    path: []const u8,

    /// `name`: the directory the file sits in, by its last segment
    /// (`src/cases/<case>/mod.bp` → `<case>`); `""` for a file at the
    /// package's root.
    pub fn name(self: Loaded) []const u8 {
        const dir = std.fs.path.dirnamePosix(self.path) orelse return "";
        return std.fs.path.basenamePosix(dir);
    }
};

/// The call a read at `loc` is rewritten to: `__bp_loaded(Bp_LoadModule(…),
/// […])`, one `Bp_LoadDiagnostic(…)` per refusal, on a line of its own.
pub fn rewrite(arena: std.mem.Allocator, loc: ast.Loc, loaded: Loaded, ds: []const Diagnostic) error{OutOfMemory}!*ast.Expr {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.appendSlice(arena, "fn __bp_load_rewrite() { " ++ helper_fn ++ "(");
    try writeModule(arena, &text, loaded);
    try text.appendSlice(arena, ", [");
    for (ds, 0..) |d, i| {
        if (i > 0) try text.appendSlice(arena, ", ");
        try text.print(arena, diagnostic_alias ++ "(code: \"{s}\", message: \"{s}\", file: \"{s}\", line: {d}, column: {d}, label: ", .{
            try blockEval.stringLexeme(arena, d.code),
            try blockEval.stringLexeme(arena, d.message),
            try blockEval.stringLexeme(arena, d.file),
            d.line,
            d.column,
        });
        if (d.label) |l| try text.print(arena, "\"{s}\")", .{try blockEval.stringLexeme(arena, l)}) else try text.appendSlice(arena, "null)");
    }
    try text.appendSlice(arena, "]); }");
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
/// runtime builds: `Ok(Bp_LoadModule(…))`, or `Error(Bp_LoadRefused(module:
/// …, diagnostics: […]))` — the records are the runtime's maps
/// (`decorator_eval`'s host records), no target (decision 805 (4)).
pub fn runtimeAnswer(arena: std.mem.Allocator, loc: ast.Loc, loaded: Loaded, ds: []const Diagnostic) error{OutOfMemory}!ast.Expr {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.appendSlice(arena, "fn __bp_load_rewrite() { ");
    try text.appendSlice(arena, if (ds.len == 0) "Ok(" else "Error(" ++ refused_alias ++ "(module: ");
    try writeModule(arena, &text, loaded);
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
                };
                var one: std.ArrayListUnmanaged(u8) = .empty;
                try writeDiagnostics(arena, &one, &.{d});
                // `[…]` around the one written: the record alone.
                try text.appendSlice(arena, one.items[1 .. one.items.len - 1]);
                return true;
            }
            const path = jsonString(o, "path") orelse return false;
            const name = jsonString(o, "name") orelse return false;
            try text.print(arena, module_alias ++ "(name: \"{s}\", path: \"{s}\")", .{
                try blockEval.stringLexeme(arena, name),
                try blockEval.stringLexeme(arena, path),
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
pub const run_failure_alias = "Bp_RunFailure";
/// The function a `run()` is rewritten to call (decision 806): std's
/// `attempt` over the loaded package's `loaded_main_fn`, its answer read as
/// a `RunFailure` — `.Failed` with the text of the `Error` the loaded `main`
/// returned, `.Abort` with the crash's text for anything the package's body,
/// executors or `main` raised. Nothing propagates out of it.
pub const run_fn = "__bp_run";
const run_fn_src =
    "fn " ++ run_fn ++ "(f: fn() -> Result<void, string>) -> Result<void, " ++ run_failure_alias ++ "> {\n" ++
    "    case " ++ attempt_alias ++ "(f) {\n" ++
    "        Ok(answer) -> case answer {\n" ++
    "            Ok(_) -> return;\n" ++
    "            Error(m) -> throw " ++ run_failure_alias ++ "(kind: .Failed, message: m);\n" ++
    "        }\n" ++
    "        Error(crash) -> throw " ++ run_failure_alias ++ "(kind: .Abort, message: crash.message);\n" ++
    "    }\n" ++
    "}\n";
/// The prefix of the local name a loaded package's `loaded_main_fn` is
/// imported under: `__bp_run__<package>`.
pub const run_alias_prefix = "__bp_run__";

/// The path of the `Module` a `run()` is called on, read off the receiver as
/// an executor holds it (`recordSource`): `Bp_LoadModule(…, path: "…", …)`,
/// or `Bp_LoadRefused(module: …, …).module`. Null for any other receiver.
pub fn receiverPath(arena: std.mem.Allocator, written: *const ast.Expr) !?[]const u8 {
    // A splice stands parenthesised: `(Bp_LoadModule(…)).run()`.
    var e = written;
    while (e.* == .collection and e.collection.kind == .grouped) e = e.collection.kind.grouped;
    switch (e.*) {
        .call => |c| if (c.kind == .call) {
            const cc = c.kind.call;
            if (cc.receiver != null or cc.is_builtin) return null;
            if (!std.mem.eql(u8, cc.callee, module_alias)) return null;
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
/// loaded package's `loaded_main_fn` —, or, while the package is not yet in
/// the program (the compile that finds the `run`, compiled again with it,
/// `comptime.compileWith`), over a function that does nothing.
pub fn runRewrite(arena: std.mem.Allocator, loc: ast.Loc, alias: ?[]const u8) error{OutOfMemory}!*ast.Expr {
    const text = if (alias) |a|
        try std.fmt.allocPrint(arena, "fn __bp_run_rewrite() {{ " ++ run_fn ++ "({s}); }}", .{a})
    else
        "fn __bp_run_rewrite() { " ++ run_fn ++ "(fn() -> Result<void, string> { return; }); }";
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

/// A `run()` call as written: where, and on what.
pub const RunCall = struct { loc: ast.Loc, receiver: *const ast.Expr };

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
                if (std.mem.eql(u8, cc.callee, "run") and cc.args.len == 0 and !cc.is_builtin) if (cc.receiver) |r| {
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
    collect_all: bool = false,
    calls: std.ArrayListUnmanaged(RunCall) = .empty,

    fn walk(self: *RunFinder, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.Expr) if (v == .call and v.call.kind == .call) {
            const cc = v.call.kind.call;
            if (std.mem.eql(u8, cc.callee, "run") and cc.args.len == 0 and !cc.is_builtin) if (cc.receiver) |r| {
                if (self.collect_all) try self.calls.append(self.arena, .{ .loc = v.call.loc, .receiver = r });
                if (try receiverPath(self.arena, r)) |p| try self.paths.append(self.arena, p);
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
pub fn withRunImports(arena: std.mem.Allocator, program: ast.Program) !ast.Program {
    var t: AliasTracer = .{ .arena = arena };
    for (program.decls) |d| try t.walk(ast.DeclKind, d);
    var f: RunFinder = .{ .arena = arena };
    for (program.decls) |d| try f.walk(ast.DeclKind, d);
    if (f.paths.items.len == 0) return program;
    var src: std.ArrayListUnmanaged(u8) = .empty;
    var has_attempt = false;
    var has_failure = false;
    var has_run_fn = false;
    for (program.decls) |d| switch (d) {
        .use => |u| for (u.imports) |imp| {
            if (imp.alias) |a| {
                if (std.mem.eql(u8, a, attempt_alias)) has_attempt = true;
                if (std.mem.eql(u8, a, run_failure_alias)) has_failure = true;
            }
        },
        .@"fn" => |fd| if (std.mem.eql(u8, fd.name, run_fn)) {
            has_run_fn = true;
        },
        else => {},
    };
    if (!has_attempt) try src.appendSlice(arena, "import {failure.attempt as " ++ attempt_alias ++ "} from \"std\";\n");
    if (!has_failure) try src.appendSlice(arena, "import {compiler.RunFailure as " ++ run_failure_alias ++ "} from \"std\";\n");
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    for (f.paths.items) |p| {
        const pkg = try packageName(arena, p);
        if (seen.contains(pkg)) continue;
        try seen.put(arena, pkg, {});
        const present = for (build_modules) |m| {
            if (std.mem.eql(u8, m.package, pkg)) break true;
        } else false;
        if (!present) continue;
        try src.print(arena, "import {{" ++ loaded_main_fn ++ " as {s}}} from \"{s}\";\n", .{ try runAlias(arena, pkg), pkg });
    }
    if (!has_run_fn) try src.appendSlice(arena, run_fn_src);
    if (src.items.len == 0) return program;
    const imports = try parseShifted(arena, src.items, helper_first_line + 100, null);
    const decls = try arena.alloc(ast.DeclKind, program.decls.len + imports.decls.len);
    @memcpy(decls[0..imports.decls.len], imports.decls);
    @memcpy(decls[imports.decls.len..], program.decls);
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
        if (m.root) source = try std.mem.concat(arena, u8, &.{
            source,
            if (entry.main_result)
                "\n\npub fn " ++ loaded_main_fn ++ "() -> Result<void, string> {\n    case main() {\n        Ok(_) -> return;\n        Error(e) -> throw \"${e}\";\n    }\n}\n"
            else
                "\n\npub fn " ++ loaded_main_fn ++ "() -> Result<void, string> {\n    main();\n    return;\n}\n",
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
    return out;
}

/// `Bp_LoadModule(name: …, path: …)`.
fn writeModule(arena: std.mem.Allocator, text: *std.ArrayListUnmanaged(u8), loaded: Loaded) !void {
    try text.print(arena, module_alias ++ "(name: \"{s}\", path: \"{s}\")", .{
        try blockEval.stringLexeme(arena, loaded.name()),
        try blockEval.stringLexeme(arena, loaded.path),
    });
}

fn writeDiagnostics(arena: std.mem.Allocator, text: *std.ArrayListUnmanaged(u8), ds: []const Diagnostic) !void {
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
        if (d.label) |l| try text.print(arena, "\"{s}\")", .{try blockEval.stringLexeme(arena, l)}) else try text.appendSlice(arena, "null)");
    }
    try text.append(arena, ']');
}

// ── the nested compile ───────────────────────────────────────────────────────

pub const Request = struct {
    /// The file, relative to the package's `botopink.json`; its path rules
    /// already checked (`embed.checkPath`).
    path: []const u8,
    files: PackageFiles,
    io: std.Io,
    build_root: ?[]const u8,
};

pub const Answer = union(enum) {
    /// The refusals, in order; empty when the file compiles.
    diagnostics: []const Diagnostic,
    /// The file is not one of the package.
    missing,
    /// The file is already being loaded on this thread.
    cycle,
    /// std's one-time initialisation is running: no compile may start.
    std_initialising,
};

/// Compile `req.path` as the entry of a package of its own and answer its
/// refusals, allocated with `arena`.
pub fn compileFile(arena: std.mem.Allocator, req: Request) !Answer {
    const comptimeMod = @import("../comptime.zig");
    if (!comptimeMod.stdlibTemplateReady()) return .std_initialising;
    for (loading.items) |p| if (std.mem.eql(u8, p, req.path)) return .cycle;
    // One compile per file per top-level compile (decision 787): every read
    // of it, and the compile again with the packages `run` reaches, read the
    // first answer.
    if (state.entries.get(req.path)) |e| return .{ .diagnostics = e.diagnostics };

    var scratch_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer scratch_state.deinit();
    const scratch = scratch_state.allocator();

    var refusals: std.ArrayListUnmanaged(Diagnostic) = .empty;
    var main_of: MainOf = .{};
    const own = gatherTree(scratch, arena, req, &refusals, &main_of) catch |err| switch (err) {
        error.FileNotFound => return .missing,
        else => |e| return e,
    };
    if (refusals.items.len > 0) return .{ .diagnostics = try remember(req.path, refusals.items, own, main_of) };

    // The caller's manifest: its targets, its reader and its dependencies.
    const caller = build_modules;
    var targets: ?moduleMod.Targets = null;
    for (caller) |m| if (m.package.len == 0) {
        targets = m.targets;
        break;
    };
    var modules: std.ArrayListUnmanaged(Module) = .empty;
    for (caller) |m| if (m.package.len > 0) try modules.append(scratch, m);
    for (own) |m| {
        var mm = m;
        mm.targets = targets;
        mm.files = req.files;
        try modules.append(scratch, mm);
    }

    try loading.append(std.heap.page_allocator, req.path);
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
    return .{ .diagnostics = try remember(req.path, refusals.items, own, main_of) };
}

const MainOf = struct { has: bool = false, result: bool = false };

/// `path`'s entry in this compile's state, copied into the state's arena;
/// its diagnostics.
fn remember(path: []const u8, ds: []const Diagnostic, own: []const Module, main_of: MainOf) ![]const Diagnostic {
    const a = stateArena();
    const dcopy = try a.alloc(Diagnostic, ds.len);
    for (ds, 0..) |d, i| dcopy[i] = .{
        .code = try a.dupe(u8, d.code),
        .message = try a.dupe(u8, d.message),
        .file = try a.dupe(u8, d.file),
        .line = d.line,
        .column = d.column,
        .label = if (d.label) |l| try a.dupe(u8, l) else null,
    };
    const mcopy = try a.alloc(Module, own.len);
    for (own, 0..) |m, i| mcopy[i] = .{
        .path = try a.dupe(u8, m.path),
        .source = try a.dupe(u8, m.source),
        .srcPath = try a.dupe(u8, m.srcPath),
        .root = m.root,
        .files = m.files,
    };
    const key = try a.dupe(u8, path);
    try state.entries.put(a, key, .{ .path = key, .diagnostics = dcopy, .modules = mcopy, .has_main = main_of.has, .main_result = main_of.result });
    return dcopy;
}

/// The loaded file and the `mod` tree beside it, children before their
/// parent (a module compiles after what it declares), each named by its
/// logical path as the CLI's resolver names a package's modules. A `mod`
/// naming no file, or two, is a refusal of the tree (`refusals`), as the
/// resolver's.
fn gatherTree(scratch: std.mem.Allocator, arena: std.mem.Allocator, req: Request, refusals: *std.ArrayListUnmanaged(Diagnostic), main_of: *MainOf) ![]const Module {
    const Item = struct { logical: []const u8, file: []const u8, root: bool };
    var work: std.ArrayListUnmanaged(Item) = .empty;
    const base = std.fs.path.basename(req.path);
    const rootLogical = if (std.mem.endsWith(u8, base, ".bp")) base[0 .. base.len - 3] else base;
    try work.append(scratch, .{ .logical = rootLogical, .file = req.path, .root = true });
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
                if (fd.returnType) |rt| main_of.result = rt == .generic and std.mem.eql(u8, rt.generic.name, "Result");
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
    return out.items;
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
/// `botopink cell check` reads it (`cell.zig` `caretLabel`).
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
