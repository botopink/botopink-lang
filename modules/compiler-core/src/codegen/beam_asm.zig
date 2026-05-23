/// BEAM Assembly (`.S`) codegen backend.
///
/// Emits the textual format produced by `erlc +to_asm <file>.erl`, which
/// `erlc +from_asm <file>.S` can re-assemble back to a `.beam`.
///
/// **Fase 2 scope** (this file): everything from Fase 1 (numeric `fn` decls,
/// arithmetic via `gc_bif`, comparisons via `{test, is_*, ...}`, `if/else`,
/// `return`, top-level `val`, `fn main/0` wrapper) plus:
///   - local bindings (`val name = expr`) via y-registers with
///     `{allocate, N, Arity}` / `{deallocate, N}` framing;
///   - local calls (`fn1(args)`) via `{call, Arity, {f, EntryLabel}}` for
///     non-tail position; `{call_last, ...}` / `{call_only, ...}` when the
///     call is the tail of a `return`;
///   - `@todo()` builtin lowered to `erlang:error(undef)`.
///
/// Anything else emits `%% unsupported: <kind>` and is skipped — upcoming
/// fases (see `/TODO.md`) lower strings, records, closures, pattern matching,
/// loops, and error handling.
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;

// ── helpers ──────────────────────────────────────────────────────────────────

fn fnArityNoSelf(f: ast.FnDecl) usize {
    var n: usize = 0;
    for (f.params) |p| {
        if (!std.mem.eql(u8, p.name, "self")) n += 1;
    }
    return n;
}

fn isMain0(f: ast.FnDecl) bool {
    return std.mem.eql(u8, f.name, "main") and fnArityNoSelf(f) == 0;
}

/// True if `stmt` is a `return` expression. Used to suppress dead jumps after
/// an `if` branch that already exits.
fn stmtIsReturn(stmt: ast.Stmt) bool {
    return switch (stmt.expr) {
        .jump => |j| switch (j.kind) {
            .@"return" => true,
            else => false,
        },
        else => false,
    };
}

/// True if every control-flow path in `body` terminates explicitly (via
/// `return` or an `if` whose both branches return). Used to decide whether an
/// implicit `return.` is needed at the end of a fn body.
fn bodyExits(body: []const ast.Stmt) bool {
    if (body.len == 0) return false;
    const last = body[body.len - 1];
    return switch (last.expr) {
        .jump => |j| switch (j.kind) {
            .@"return", .throw_, .yield, .@"continue" => true,
            else => false,
        },
        .branch => |b| switch (b.kind) {
            .if_ => |i| {
                if (i.else_) |els| return bodyExits(i.then_) and bodyExits(els);
                return false;
            },
            else => false,
        },
        else => false,
    };
}

/// True for the synthetic top-level vals the comptime transform injects to
/// model script-level entrypoint calls (names starting with `_`).
fn isSyntheticEntrypointVal(v: ast.ValDecl) bool {
    return std.mem.startsWith(u8, v.name, "_");
}

/// Arity for an `InterfaceMethod` (`self` is always present in member methods
/// and gets x0; we count it just like a regular fn param).
fn methodArity(m: ast.InterfaceMethod) usize {
    return m.params.len;
}

/// Arity for an `ImplementMethod` (same convention).
fn implementMethodArity(m: ast.ImplementMethod) usize {
    return m.params.len;
}

/// Append `'Owner_methodName'/arity` for every `pub` method in `methods` to
/// the exports list. Caller is responsible for the `owned` tracker — every
/// allocated string is pushed there so it gets freed after the header.
fn collectMethodExports(
    alloc: std.mem.Allocator,
    exports: *std.ArrayListUnmanaged(ExportEntry),
    owned: *std.ArrayListUnmanaged([]u8),
    owner: []const u8,
    methods: []const ast.InterfaceMethod,
) !void {
    for (methods) |m| {
        if (m.body == null or m.is_declare) continue;
        if (!m.isPub) continue;
        const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ owner, m.name });
        try owned.append(alloc, mangled);
        try exports.append(alloc, .{ .name = mangled, .arity = methodArity(m) });
    }
}

fn collectStructExports(
    alloc: std.mem.Allocator,
    exports: *std.ArrayListUnmanaged(ExportEntry),
    owned: *std.ArrayListUnmanaged([]u8),
    s: ast.StructDecl,
) !void {
    for (s.members) |mem| switch (mem) {
        .field => {},
        // Getters/setters don't carry an `isPub` bit — struct accessors are
        // always considered part of the struct's public surface.
        .getter => |g| {
            const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ s.name, g.name });
            try owned.append(alloc, mangled);
            try exports.append(alloc, .{ .name = mangled, .arity = 1 });
        },
        .setter => |st| {
            const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ s.name, st.name });
            try owned.append(alloc, mangled);
            try exports.append(alloc, .{ .name = mangled, .arity = st.params.len });
        },
        .method => |m| {
            if (m.body == null or m.is_declare) continue;
            if (!m.isPub) continue;
            const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ s.name, m.name });
            try owned.append(alloc, mangled);
            try exports.append(alloc, .{ .name = mangled, .arity = methodArity(m) });
        },
    };
}

fn collectImplementExports(
    alloc: std.mem.Allocator,
    exports: *std.ArrayListUnmanaged(ExportEntry),
    owned: *std.ArrayListUnmanaged([]u8),
    im: ast.ImplementDecl,
) !void {
    for (im.methods) |m| {
        const qualifier = m.qualifier orelse im.target;
        const mangled = try std.fmt.allocPrint(alloc, "'{s}_{s}'", .{ qualifier, m.name });
        try owned.append(alloc, mangled);
        try exports.append(alloc, .{ .name = mangled, .arity = implementMethodArity(m) });
    }
}

/// Walk a body counting `localBind`s (`val name = ...`) recursively into
/// nested blocks (if/then/else) so we can pre-allocate y-slots before any
/// instruction is emitted.
fn countLocalsRec(body: []const ast.Stmt, count: *u32) void {
    for (body) |stmt| switch (stmt.expr) {
        .binding => |b| switch (b.kind) {
            .localBind => count.* += 1,
            .localBindDestruct => count.* += 1, // future: each field
            else => {},
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                countLocalsRec(i.then_, count);
                if (i.else_) |els| countLocalsRec(els, count);
            },
            else => {},
        },
        else => {},
    };
}

// ── public entry ─────────────────────────────────────────────────────────────

pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    _ = config;
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError => continue,
            .validationError => |verr| {
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = try alloc.dupe(u8, ""),
                        .comptime_script = null,
                        .comptime_err = verr,
                    },
                });
            },
            .ok => |*ok| {
                const code = try emitBeamAsm(alloc, ct.name, ok.transformed, ok.comptime_vals);
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = code,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    return results;
}

// ── top-level emitter ────────────────────────────────────────────────────────

const ExportEntry = struct { name: []const u8, arity: usize };

fn emitBeamAsm(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
) ![]u8 {
    // Three passes:
    //   1. assign entry labels to every fn/top-val so wrappers can refer to
    //      them by `{f, N}`;
    //   2. emit each body into a buffer;
    //   3. emit the header (module + exports + attributes + labels) followed
    //      by the buffered bodies.
    //
    // The header needs the final label count, which is only known after
    // emitting; that's why bodies are buffered.

    var body_buf: std.Io.Writer.Allocating = .init(alloc);
    defer body_buf.deinit();

    var em = Emitter.init(alloc, module_name, &body_buf.writer, comptime_vals);
    defer em.deinit();

    // Detect main/0 entrypoint (drives wrapper emission).
    var has_main_0 = false;
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| if (isMain0(f)) {
                has_main_0 = true;
            },
            else => {},
        }
    }

    // Pass 1: pre-assign labels (func_info, entry) for every emitted function
    // so wrappers and (eventually) local calls can resolve targets by name.
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| try em.reserveFn(f.name, fnArityNoSelf(f)),
            .val => |v| if (!has_main_0 and !isSyntheticEntrypointVal(v)) {
                try em.reserveFn(v.name, 0);
            },
            .record => |r| try em.reserveRecordMethods(r),
            .@"struct" => |s| try em.reserveStructMembers(s),
            .@"enum" => |e| try em.reserveEnumMethods(e),
            .implement => |im| try em.reserveImplementMethods(im),
            else => {},
        }
    }
    if (has_main_0) {
        try em.reserveFn("'_botopink_main'", 0);
        try em.reserveFn("main", 1);
    }

    // Collect exports: pub fns + entrypoint wrappers when main/0 exists.
    var exports: std.ArrayListUnmanaged(ExportEntry) = .empty;
    defer exports.deinit(alloc);
    // Mangled method names live in heap-allocated strings; track them so we
    // can free after the header is written.
    var owned_export_names: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (owned_export_names.items) |s| alloc.free(s);
        owned_export_names.deinit(alloc);
    }
    if (has_main_0) {
        try exports.append(alloc, .{ .name = "'_botopink_main'", .arity = 0 });
        try exports.append(alloc, .{ .name = "main", .arity = 1 });
    }
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| if (f.isPub) {
                try exports.append(alloc, .{ .name = f.name, .arity = fnArityNoSelf(f) });
            },
            .record => |r| try collectMethodExports(alloc, &exports, &owned_export_names, r.name, r.methods),
            .@"struct" => |s| try collectStructExports(alloc, &exports, &owned_export_names, s),
            .@"enum" => |e| try collectMethodExports(alloc, &exports, &owned_export_names, e.name, e.methods),
            .implement => |im| try collectImplementExports(alloc, &exports, &owned_export_names, im),
            else => {},
        }
    }

    // Pass 2: emit each fn body into body_buf.
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| try em.emitFn(f),
            .val => |v| {
                if (!has_main_0 and !isSyntheticEntrypointVal(v)) {
                    try em.emitTopVal(v);
                }
            },
            .comment => |c| {
                const prefix = if (c.is_doc) "%%" else if (c.is_module) "%%%" else "%";
                try em.bodyPrint("{s} {s}\n", .{ prefix, c.text });
            },
            .record => |r| try em.emitRecord(r),
            .@"struct" => |s| try em.emitStruct(s),
            .@"enum" => |e| try em.emitEnum(e),
            .implement => |im| try em.emitImplement(im),
            // Purely abstract decls (interface/delegate) and module-graph
            // metadata (use) don't lower to runtime code — silently skip.
            .interface, .delegate, .use => {},
        }
    }

    if (has_main_0) {
        try em.emitEntrypointWrappers();
    }

    // Now build the final output: header + exports + attributes + labels + body.
    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();

    try aw.writer.print("{{module, {s}}}.\n", .{module_name});

    try aw.writer.writeAll("{exports, [");
    for (exports.items, 0..) |e, i| {
        if (i > 0) try aw.writer.writeAll(", ");
        try aw.writer.print("{{{s}, {d}}}", .{ e.name, e.arity });
    }
    try aw.writer.writeAll("]}.\n");
    try aw.writer.writeAll("{attributes, []}.\n");
    try aw.writer.print("{{labels, {d}}}.\n", .{em.next_label});

    try aw.writer.writeAll(body_buf.written());
    for (em.deferred_lambdas.items) |lambda_code| {
        try aw.writer.writeAll(lambda_code);
    }

    return aw.toOwnedSlice();
}

// ── Emitter ──────────────────────────────────────────────────────────────────

const FnLabels = struct {
    func_info: u32,
    entry: u32,
};

/// A BEAM register reference: x-registers (caller-saved, clobbered by calls)
/// or y-registers (stack-frame locals, preserved across calls).
const Reg = union(enum) {
    x: u32,
    y: u32,

    fn format(self: Reg, buf: []u8) ![]const u8 {
        return switch (self) {
            .x => |n| std.fmt.bufPrint(buf, "{{x, {d}}}", .{n}),
            .y => |n| std.fmt.bufPrint(buf, "{{y, {d}}}", .{n}),
        };
    }
};

fn fnKey(alloc: std.mem.Allocator, name: []const u8, arity: usize) ![]u8 {
    return std.fmt.allocPrint(alloc, "{s}/{d}", .{ name, arity });
}

const Emitter = struct {
    alloc: std.mem.Allocator,
    module_name: []const u8,
    out: *std.Io.Writer,
    cv: std.StringHashMap([]const u8),

    /// Next available label index. Label 1 is reserved (BEAM convention).
    next_label: u32 = 2,

    /// `"name/arity"` → reserved label pair. Populated by `reserveFn` in pass 1.
    fn_labels: std.StringHashMap(FnLabels),

    /// Per-function: name → register (x for params, y for locals).
    reg_map: std.StringHashMap(Reg),
    /// Per-function: next y-slot available for a new local.
    next_y: u32 = 0,
    /// Per-function: total y-slots reserved (set by `precountLocals`).
    num_y: u32 = 0,
    /// Per-function: arity in x-registers (live registers floor for gc_bif).
    cur_arity: u32 = 0,
    /// Per-function: bumps the source-location placeholder.
    cur_line: u32 = 1,
    /// Module-wide lambda counter for generating unique fun names.
    lambda_count: u32 = 0,
    /// Current function name — used for lambda naming (`-fn/N-fun-K-`).
    cur_fn_name: []const u8 = "",
    /// Deferred lambda bodies — emitted after main pass 2.
    deferred_lambdas: std.ArrayListUnmanaged([]u8) = .empty,
    /// True when emitting a loop body lambda — makes break emit return.
    in_loop_lambda: bool = false,

    fn init(alloc: std.mem.Allocator, module_name: []const u8, out: *std.Io.Writer, cv: std.StringHashMap([]const u8)) Emitter {
        return .{
            .alloc = alloc,
            .module_name = module_name,
            .out = out,
            .cv = cv,
            .fn_labels = std.StringHashMap(FnLabels).init(alloc),
            .reg_map = std.StringHashMap(Reg).init(alloc),
        };
    }

    fn deinit(self: *Emitter) void {
        var it = self.fn_labels.iterator();
        while (it.next()) |kv| self.alloc.free(kv.key_ptr.*);
        self.fn_labels.deinit();
        self.reg_map.deinit();
        for (self.deferred_lambdas.items) |s| self.alloc.free(s);
        self.deferred_lambdas.deinit(self.alloc);
    }

    fn allocLabel(self: *Emitter) u32 {
        const l = self.next_label;
        self.next_label += 1;
        return l;
    }

    fn reserveFn(self: *Emitter, name: []const u8, arity: usize) !void {
        const key = try fnKey(self.alloc, name, arity);
        try self.fn_labels.put(key, .{
            .func_info = self.allocLabel(),
            .entry = self.allocLabel(),
        });
    }

    fn fnLabelsFor(self: *Emitter, name: []const u8, arity: usize) !FnLabels {
        var buf: [256]u8 = undefined;
        const key = try std.fmt.bufPrint(&buf, "{s}/{d}", .{ name, arity });
        return self.fn_labels.get(key) orelse error.UnknownFunction;
    }

    fn bodyPrint(self: *Emitter, comptime fmt: []const u8, args: anytype) !void {
        try self.out.print(fmt, args);
    }

    fn bodyWrite(self: *Emitter, s: []const u8) !void {
        try self.out.writeAll(s);
    }

    // ── per-fn state ─────────────────────────────────────────────────────────

    fn resetFnState(self: *Emitter, arity: u32) void {
        self.reg_map.clearRetainingCapacity();
        self.next_y = 0;
        self.num_y = 0;
        self.cur_arity = arity;
    }

    /// Count the y-slots needed for a function body: one slot per `localBind`.
    /// Conservative: every `val` gets a slot even when its lifetime ends
    /// before a call. Refining this is Fase 9 (polish).
    fn precountLocals(_: *Emitter, body: []const ast.Stmt) u32 {
        var n: u32 = 0;
        countLocalsRec(body, &n);
        return n;
    }

    // ── fn ───────────────────────────────────────────────────────────────────

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        const arity = fnArityNoSelf(f);
        const labels = try self.fnLabelsFor(f.name, arity);
        const func_info_label = labels.func_info;
        const entry_label = labels.entry;

        self.resetFnState(@intCast(arity));
        self.cur_fn_name = f.name;
        self.num_y = self.precountLocals(f.body);

        // Bind params to x0..x{arity-1}.
        var x: u32 = 0;
        for (f.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            try self.reg_map.put(p.name, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ f.name, arity, entry_label });
        try self.bodyPrint("  {{label, {d}}}.\n", .{func_info_label});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, f.name, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{entry_label});

        try self.bodyPrint("    {{allocate, {d}, {d}}}.\n", .{ self.num_y, arity });

        self.cur_line += 1;
        try self.emitBody(f.body);
    }

    // ── record / struct / enum / implement ───────────────────────────────────
    //
    // The declaration itself never emits standalone runtime code — the
    // constructor / field-access lowering belongs in Fase 4. What we do here
    // is reify every method (`fn`, `get`, `set`) with a body as a
    // module-level function named `'Owner_methodName'/arity`. Methods that
    // have no body (`declare fn ...`) are silently skipped.

    fn reserveMethod(self: *Emitter, owner: []const u8, suffix: []const u8, arity: usize) !void {
        var buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&buf, "'{s}_{s}'", .{ owner, suffix });
        try self.reserveFn(mangled, arity);
    }

    fn reserveRecordMethods(self: *Emitter, r: ast.RecordDecl) !void {
        for (r.methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.reserveMethod(r.name, m.name, methodArity(m));
        }
    }

    fn reserveStructMembers(self: *Emitter, s: ast.StructDecl) !void {
        for (s.members) |mem| switch (mem) {
            .field => {},
            .getter => |g| try self.reserveMethod(s.name, g.name, 1),
            .setter => |st| {
                // Setters have explicit params; arity == params.len.
                try self.reserveMethod(s.name, st.name, st.params.len);
            },
            .method => |m| {
                if (m.body == null or m.is_declare) continue;
                try self.reserveMethod(s.name, m.name, methodArity(m));
            },
        };
    }

    fn reserveEnumMethods(self: *Emitter, e: ast.EnumDecl) !void {
        for (e.methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.reserveMethod(e.name, m.name, methodArity(m));
        }
    }

    fn reserveImplementMethods(self: *Emitter, im: ast.ImplementDecl) !void {
        for (im.methods) |m| {
            const qualifier = m.qualifier orelse im.target;
            var buf: [256]u8 = undefined;
            const mangled = try std.fmt.bufPrint(&buf, "'{s}_{s}'", .{ qualifier, m.name });
            try self.reserveFn(mangled, implementMethodArity(m));
        }
    }

    fn emitRecord(self: *Emitter, r: ast.RecordDecl) !void {
        for (r.methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.emitMethodAsFn(r.name, m);
        }
    }

    fn emitStruct(self: *Emitter, s: ast.StructDecl) !void {
        for (s.members) |mem| switch (mem) {
            .field => {},
            .getter => |g| try self.emitGetter(s.name, g),
            .setter => |st| try self.emitSetter(s.name, st),
            .method => |m| {
                if (m.body == null or m.is_declare) continue;
                try self.emitMethodAsFn(s.name, m);
            },
        };
    }

    fn emitEnum(self: *Emitter, e: ast.EnumDecl) !void {
        for (e.methods) |m| {
            if (m.body == null or m.is_declare) continue;
            try self.emitMethodAsFn(e.name, m);
        }
    }

    fn emitImplement(self: *Emitter, im: ast.ImplementDecl) !void {
        for (im.methods) |m| {
            const qualifier = m.qualifier orelse im.target;
            try self.emitImplementMethod(qualifier, m);
        }
    }

    fn emitMethodAsFn(self: *Emitter, owner: []const u8, m: ast.InterfaceMethod) !void {
        const arity = methodArity(m);
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ owner, m.name });
        const labels = try self.fnLabelsFor(mangled, arity);

        self.resetFnState(@intCast(arity));
        self.num_y = self.precountLocals(m.body.?);

        var x: u32 = 0;
        for (m.params) |p| {
            try self.reg_map.put(p.name, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ mangled, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, mangled, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});

        try self.bodyPrint("    {{allocate, {d}, {d}}}.\n", .{ self.num_y, arity });

        self.cur_line += 1;
        try self.emitBody(m.body.?);
    }

    fn emitImplementMethod(self: *Emitter, qualifier: []const u8, m: ast.ImplementMethod) !void {
        const arity = implementMethodArity(m);
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ qualifier, m.name });
        const labels = try self.fnLabelsFor(mangled, arity);

        self.resetFnState(@intCast(arity));
        self.num_y = self.precountLocals(m.body);

        var x: u32 = 0;
        for (m.params) |p| {
            try self.reg_map.put(p.name, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ mangled, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, mangled, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});

        try self.bodyPrint("    {{allocate, {d}, {d}}}.\n", .{ self.num_y, arity });

        self.cur_line += 1;
        try self.emitBody(m.body);
    }

    /// `get fieldName(self: Self) -> T { ... }` — lowered as `'Owner_fieldName'/1`.
    /// Implementations vary (custom body vs. plain field read); we emit the
    /// method body as written. Plain field-access semantics arrive in Fase 4.
    fn emitGetter(self: *Emitter, owner: []const u8, g: anytype) !void {
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ owner, g.name });
        const labels = try self.fnLabelsFor(mangled, 1);

        self.resetFnState(1);
        self.num_y = self.precountLocals(g.body);
        try self.reg_map.put(g.selfParam.name, .{ .x = 0 });

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, 1, {d}}}.\n", .{ mangled, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, 1}}.\n", .{ self.module_name, mangled });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});
        try self.bodyPrint("    {{allocate, {d}, 1}}.\n", .{self.num_y});
        self.cur_line += 1;
        try self.emitBody(g.body);
    }

    fn emitSetter(self: *Emitter, owner: []const u8, s: anytype) !void {
        const arity = s.params.len;
        var name_buf: [256]u8 = undefined;
        const mangled = try std.fmt.bufPrint(&name_buf, "'{s}_{s}'", .{ owner, s.name });
        const labels = try self.fnLabelsFor(mangled, arity);

        self.resetFnState(@intCast(arity));
        self.num_y = self.precountLocals(s.body);
        var x: u32 = 0;
        for (s.params) |p| {
            try self.reg_map.put(p.name, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ mangled, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, mangled, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});
        try self.bodyPrint("    {{allocate, {d}, {d}}}.\n", .{ self.num_y, arity });
        self.cur_line += 1;
        try self.emitBody(s.body);
    }

    // ── top-level val (only when there's no fn main/0) ───────────────────────
    //
    // Erlang backend emits these as 0-arity functions. We mirror that — `val
    // pi = 3.14` becomes `pi/0` returning the literal. Only literal/numeric
    // expressions are supported in Fase 1; richer values fall to Fase 2+.

    fn emitTopVal(self: *Emitter, v: ast.ValDecl) !void {
        const labels = try self.fnLabelsFor(v.name, 0);
        const func_info_label = labels.func_info;
        const entry_label = labels.entry;

        self.resetFnState(0);

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, 0, {d}}}.\n", .{ v.name, entry_label });
        try self.bodyPrint("  {{label, {d}}}.\n", .{func_info_label});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, 0}}.\n", .{ self.module_name, v.name });
        try self.bodyPrint("  {{label, {d}}}.\n", .{entry_label});
        self.cur_line += 1;

        try self.lowerExprIntoX0(v.value.*);
        try self.emitReturn();
    }

    /// Emit `return.`, preceded by `{deallocate, N}.` when the current function
    /// owns a y-stack frame.
    fn emitReturn(self: *Emitter) !void {
        try self.bodyPrint("    {{deallocate, {d}}}.\n", .{self.num_y});
        try self.bodyWrite("    return.\n");
    }

    // ── entrypoint wrappers when main/0 exists ───────────────────────────────

    fn emitEntrypointWrappers(self: *Emitter) !void {
        const wrapper = try self.fnLabelsFor("'_botopink_main'", 0);
        const main1 = try self.fnLabelsFor("main", 1);
        const main0 = try self.fnLabelsFor("main", 0);

        // '_botopink_main'/0 → tail-calls main/0.
        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, '_botopink_main', 0, {d}}}.\n", .{wrapper.entry});
        try self.bodyPrint("  {{label, {d}}}.\n", .{wrapper.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, '_botopink_main'}}, 0}}.\n", .{self.module_name});
        try self.bodyPrint("  {{label, {d}}}.\n", .{wrapper.entry});
        try self.bodyPrint("    {{call_only, 0, {{f, {d}}}}}.\n", .{main0.entry});
        self.cur_line += 1;

        // main/1 → discards argv and tail-calls _botopink_main/0.
        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, main, 1, {d}}}.\n", .{main1.entry});
        try self.bodyPrint("  {{label, {d}}}.\n", .{main1.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, main}}, 1}}.\n", .{self.module_name});
        try self.bodyPrint("  {{label, {d}}}.\n", .{main1.entry});
        try self.bodyPrint("    {{call_only, 0, {{f, {d}}}}}.\n", .{wrapper.entry});
        self.cur_line += 1;
    }

    // ── body ─────────────────────────────────────────────────────────────────

    fn emitBody(self: *Emitter, body: []const ast.Stmt) !void {
        for (body) |stmt| {
            try self.emitStmt(stmt);
        }
        // BEAM functions must end with an exit instruction. When the source
        // didn't write an explicit `return`, fall back to returning the atom
        // `ok` so the frame is balanced (deallocate + return).
        if (!bodyExits(body)) {
            try self.bodyWrite("    {move, {atom, ok}, {x, 0}}.\n");
            try self.emitReturn();
        }
    }

    fn emitStmt(self: *Emitter, stmt: ast.Stmt) anyerror!void {
        switch (stmt.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| {
                        // Tail-call detection: `return call(...)` becomes
                        // `{call_last, ...}` / `{call_only, ...}`, which encode
                        // deallocate + return atomically.
                        switch (val.*) {
                            .call => |c| switch (c.kind) {
                                .call => |cc| {
                                    try self.lowerCall(cc, .tail, 0);
                                    return;
                                },
                                else => {},
                            },
                            else => {},
                        }
                        try self.lowerExprIntoX0(val.*);
                    }
                    try self.emitReturn();
                },
                .throw_ => |val| {
                    if (val) |v| {
                        try self.lowerExprIntoX0(v.*);
                    } else {
                        try self.bodyWrite("    {move, {atom, undef}, {x, 0}}.\n");
                    }
                    try self.bodyWrite("    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.\n");
                },
                .@"break" => |val| {
                    if (val) |v| {
                        try self.lowerExprIntoX0(v.*);
                    }
                    if (self.in_loop_lambda) try self.emitReturn();
                },
                .yield => |val| {
                    if (val) |v| {
                        try self.lowerExprIntoX0(v.*);
                    }
                    try self.emitReturn();
                },
                .@"continue" => {
                    try self.bodyWrite("    {move, {atom, ok}, {x, 0}}.\n");
                    try self.emitReturn();
                },
                else => |k| try self.bodyPrint("    %% unsupported jump: {s}\n", .{@tagName(k)}),
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| try self.emitIf(i),
                .tryCatch => try self.bodyWrite("    %% unsupported: try/catch (Fase 8)\n"),
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| try self.emitLocalBind(lb.name, lb.value.*),
                .assign => |a| try self.emitAssign(a),
                .localBindDestruct => |lb| {
                    try self.lowerExprIntoX0(lb.value.*);
                    switch (lb.pattern) {
                        .names => |n| {
                            for (n.fields) |fld| {
                                const scratch = self.cur_arity;
                                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                                const fail = self.allocLabel();
                                try self.bodyPrint(
                                    "    {{get_map_elements, {{f, {d}}}, {{x, {d}}}, {{list, [{{atom, {s}}}, {{x, 0}}]}}}}.\n",
                                    .{ fail, scratch, fld.field_name },
                                );
                                try self.bodyPrint("  {{label, {d}}}.\n", .{fail});
                                const y_idx = self.next_y;
                                self.next_y += 1;
                                try self.reg_map.put(fld.bind_name, .{ .y = y_idx });
                                try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                                try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{scratch});
                            }
                        },
                        .tuple_ => |bindings| {
                            for (bindings, 0..) |name, i| {
                                try self.bodyPrint(
                                    "    {{get_tuple_element, {{x, 0}}, {d}, {{x, 1}}}}.\n",
                                    .{i},
                                );
                                const y_idx = self.next_y;
                                self.next_y += 1;
                                try self.reg_map.put(name, .{ .y = y_idx });
                                try self.bodyPrint("    {{move, {{x, 1}}, {{y, {d}}}}}.\n", .{y_idx});
                            }
                        },
                        else => try self.bodyWrite("    %% unsupported destructure pattern\n"),
                    }
                },
            },
            else => {
                try self.lowerExprIntoX0(stmt.expr);
            },
        }
    }

    /// Lower `val name = value`: evaluate `value` into `{x, 0}`, then move it
    /// to a freshly-allocated y-slot. The y-slot count was pre-reserved by
    /// `precountLocals` so the `{allocate, NumY, _}` at the top of the
    /// function already covers it.
    fn emitLocalBind(self: *Emitter, name: []const u8, value: ast.Expr) !void {
        try self.lowerExprIntoX0(value);
        const y_idx = self.next_y;
        self.next_y += 1;
        try self.reg_map.put(name, .{ .y = y_idx });
        try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
    }

    /// `name = expr` or `name += expr`: evaluate the new value and store
    /// back into the variable's y-slot.
    fn emitAssign(self: *Emitter, a: anytype) anyerror!void {
        switch (a.target) {
            .name => |name| {
                const reg = self.reg_map.get(name) orelse {
                    try self.bodyPrint("    %% assign to unknown variable: {s}\n", .{name});
                    return;
                };
                switch (a.op) {
                    .assign => {
                        try self.lowerExprIntoX0(a.value.*);
                        var buf: [64]u8 = undefined;
                        const term = try reg.format(&buf);
                        try self.bodyPrint("    {{move, {{x, 0}}, {s}}}.\n", .{term});
                    },
                    .plusAssign => {
                        var reg_buf: [64]u8 = undefined;
                        const reg_term = try reg.format(&reg_buf);
                        try self.lowerExprIntoX0(a.value.*);
                        const scratch = self.cur_arity;
                        try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                        try self.bodyPrint(
                            "    {{gc_bif, '+', {{f, 0}}, {d}, [{s}, {{x, {d}}}], {{x, 0}}}}.\n",
                            .{ scratch + 1, reg_term, scratch },
                        );
                        try self.bodyPrint("    {{move, {{x, 0}}, {s}}}.\n", .{reg_term});
                    },
                }
            },
            .fieldAccess => |*fa| {
                try self.lowerExprIntoX0(a.value.*);
                const scratch = self.cur_arity;
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                try self.lowerExprIntoX0(fa.receiver.*);
                try self.bodyPrint(
                    "    {{put_map_exact, {{f, 0}}, {{x, 0}}, {{x, 0}}, {d}, {{list, [{{atom, {s}}}, {{x, {d}}}]}}}}.\n",
                    .{ scratch + 1, fa.field, scratch },
                );
                if (self.reg_map.get("self")) |reg| {
                    var buf: [64]u8 = undefined;
                    const term = try reg.format(&buf);
                    try self.bodyPrint("    {{move, {{x, 0}}, {s}}}.\n", .{term});
                }
            },
        }
    }

    // ── if (cmp) { then } else { else } ──────────────────────────────────────
    //
    // Only handles cond = binaryOp comparison between two simple operands
    // (literal/identifier). Anything else → `%% unsupported`.

    fn emitIf(self: *Emitter, i: anytype) anyerror!void {
        const else_label = self.allocLabel();

        const lowered = try self.lowerComparisonAsTest(i.cond.*, else_label);
        if (!lowered) {
            try self.lowerExprIntoX0(i.cond.*);
            try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, true}}]}}.\n", .{else_label});
        }

        // then branch (cond true).
        for (i.then_) |s| try self.emitStmt(s);
        const then_returns = i.then_.len > 0 and stmtIsReturn(i.then_[i.then_.len - 1]);

        // Skip the unconditional jump-to-end when the then branch already
        // exits via `return.` — otherwise BEAM will see unreachable code.
        const end_label: ?u32 = if (!then_returns) self.allocLabel() else null;
        if (end_label) |el| try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{el});

        // else branch.
        try self.bodyPrint("  {{label, {d}}}.\n", .{else_label});
        if (i.else_) |els| {
            for (els) |s| try self.emitStmt(s);
        } else {
            try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
            try self.emitReturn();
        }

        if (end_label) |el| try self.bodyPrint("  {{label, {d}}}.\n", .{el});
    }

    /// Lower `lhs <op> rhs` (a comparison) as a `{test, is_<op>, {f, F}, [A, B]}.`
    /// instruction whose failure target is `fail_label`. Returns false if the
    /// expression is not a recognised comparison.
    fn lowerComparisonAsTest(self: *Emitter, cond: ast.Expr, fail_label: u32) anyerror!bool {
        switch (cond) {
            .binaryOp => |bin| {
                const opcode: ?[]const u8 = switch (bin.kind.op) {
                    .lt => "is_lt",
                    .gt => "is_gt",
                    .lte => "is_le",
                    .gte => "is_ge",
                    .eq => "is_eq",
                    .ne => "is_ne_exact",
                    else => null,
                };
                if (opcode == null) return false;

                var lhs_buf: [64]u8 = undefined;
                var rhs_buf: [64]u8 = undefined;
                const lhs_simple = try self.simpleTerm(bin.kind.lhs.*, &lhs_buf);
                const rhs_simple = try self.simpleTerm(bin.kind.rhs.*, &rhs_buf);

                var lhs_final: []const u8 = undefined;
                var rhs_final: []const u8 = undefined;
                var lhs_final_buf: [64]u8 = undefined;
                var rhs_final_buf: [64]u8 = undefined;

                if (lhs_simple != null and rhs_simple != null) {
                    lhs_final = lhs_simple.?;
                    rhs_final = rhs_simple.?;
                } else {
                    const scratch = self.cur_arity;
                    if (lhs_simple) |ls| {
                        try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ ls, scratch });
                    } else {
                        try self.lowerExprIntoX0(bin.kind.lhs.*);
                        if (scratch != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                    }
                    lhs_final = try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});
                    if (rhs_simple) |rs| {
                        rhs_final = rs;
                    } else {
                        try self.lowerExprIntoX0(bin.kind.rhs.*);
                        rhs_final = try std.fmt.bufPrint(&rhs_final_buf, "{{x, 0}}", .{});
                    }
                }

                try self.bodyPrint(
                    "    {{test, {s}, {{f, {d}}}, [{s}, {s}]}}.\n",
                    .{ opcode.?, fail_label, lhs_final, rhs_final },
                );
                return true;
            },
            else => return false,
        }
    }

    // ── lowering helpers ─────────────────────────────────────────────────────

    /// Lower `e` so its value lives in `{x, 0}`, ready for `return.`.
    fn lowerExprIntoX0(self: *Emitter, e: ast.Expr) anyerror!void {
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    if (self.reg_map.get(n)) |reg| {
                        switch (reg) {
                            .x => |xn| {
                                if (xn == 0) return;
                                try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{xn});
                            },
                            .y => |yn| {
                                try self.bodyPrint("    {{move, {{y, {d}}}, {{x, 0}}}}.\n", .{yn});
                            },
                        }
                        return;
                    }
                    if (self.cv.get(n)) |val| {
                        try self.bodyPrint("    {{move, {{atom, '{s}'}}, {{x, 0}}}}.\n", .{val});
                        return;
                    }
                    try self.bodyPrint("    {{move, {{atom, {s}}}, {{x, 0}}}}.\n", .{n});
                    return;
                },
                .dotIdent => |d| {
                    try self.bodyPrint("    {{move, {{atom, {s}}}, {{x, 0}}}}.\n", .{d});
                    return;
                },
                .identAccess => |ia| {
                    try self.lowerIdentAccess(ia, 0);
                    return;
                },
            },
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| {
                    var buf: [64]u8 = undefined;
                    const term = try formatNumberInto(&buf, n);
                    try self.bodyPrint("    {{move, {s}, {{x, 0}}}}.\n", .{term});
                    return;
                },
                .null_ => {
                    try self.bodyWrite("    {move, {atom, nil}, {x, 0}}.\n");
                    return;
                },
                .stringLit => |s| {
                    try self.emitStringLiteral(s, 0);
                    return;
                },
                .comment => return,
            },
            .binaryOp => {
                try self.lowerArith(e, 0);
                return;
            },
            .unaryOp => |un| switch (un.kind.op) {
                .neg => {
                    try self.lowerNeg(un.kind.expr.*, 0);
                    return;
                },
                .not => {
                    try self.lowerNot(un.kind.expr.*, 0);
                    return;
                },
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    try self.lowerCall(cc, .non_tail, 0);
                    return;
                },
                .pipeline => |pl| {
                    try self.lowerPipeline(pl);
                    return;
                },
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| {
                    try self.emitTailIf(i);
                    return;
                },
                .tryCatch => |tc| {
                    try self.lowerTryCatch(tc);
                    return;
                },
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| {
                    try self.lowerExprIntoX0(inner.*);
                    return;
                },
                .arrayLit => |al| {
                    try self.lowerArrayLit(al);
                    return;
                },
                .tupleLit => |tl| {
                    try self.lowerTupleLit(tl);
                    return;
                },
                .case => |c| {
                    try self.lowerCase(c.subjects, c.arms);
                    return;
                },
                .range => {
                    try self.bodyWrite("    %% unsupported: range (Fase 7)\n");
                    try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
                    return;
                },
            },
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| try self.lowerExprIntoX0(val.*);
                    try self.emitReturn();
                    return;
                },
                .throw_ => |val| {
                    if (val) |v| try self.lowerExprIntoX0(v.*);
                    try self.bodyWrite("    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.\n");
                    return;
                },
                .try_ => |val| {
                    if (val) |v| try self.lowerExprIntoX0(v.*);
                    return;
                },
                else => {},
            },
            .comptime_ => {
                try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
                return;
            },
            .function => |f| switch (f.kind) {
                .lambda => |lam| {
                    try self.lowerLambda(lam);
                    return;
                },
                else => {
                    try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
                    return;
                },
            },
            .loop => |lp| {
                try self.lowerLoop(lp);
                return;
            },
            else => {},
        }

        try self.bodyPrint("    %% unsupported expr in tail position: {s}\n", .{@tagName(e)});
        try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
    }

    /// Lower `-e` into `{x, dest}`. Constant-folds literal numerics.
    fn lowerNeg(self: *Emitter, inner: ast.Expr, dest: u32) !void {
        switch (inner) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| {
                    var buf: [64]u8 = undefined;
                    const term = try formatNegNumberInto(&buf, n);
                    try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ term, dest });
                    return;
                },
                else => {},
            },
            else => {},
        }
        var ibuf: [64]u8 = undefined;
        const inner_term = try self.simpleTerm(inner, &ibuf);
        if (inner_term) |it| {
            try self.bodyPrint(
                "    {{gc_bif, '-', {{f, 0}}, {d}, [{{integer, 0}}, {s}], {{x, {d}}}}}.\n",
                .{ self.cur_arity, it, dest },
            );
        } else {
            try self.lowerExprIntoX0(inner);
            const scratch = self.cur_arity;
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            var scratch_buf: [64]u8 = undefined;
            const scratch_term = try std.fmt.bufPrint(&scratch_buf, "{{x, {d}}}", .{scratch});
            try self.bodyPrint(
                "    {{gc_bif, '-', {{f, 0}}, {d}, [{{integer, 0}}, {s}], {{x, {d}}}}}.\n",
                .{ scratch + 1, scratch_term, dest },
            );
        }
    }

    /// Emit an `if (cmp) then else else` whose value should land in `{x, 0}`
    /// and immediately return. Each branch ends in `return.` directly.
    fn emitTailIf(self: *Emitter, i: anytype) anyerror!void {
        const else_label = self.allocLabel();
        const lowered = try self.lowerComparisonAsTest(i.cond.*, else_label);
        if (!lowered) {
            try self.lowerExprIntoX0(i.cond.*);
            try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, true}}]}}.\n", .{else_label});
        }

        try self.emitTailBody(i.then_);

        try self.bodyPrint("  {{label, {d}}}.\n", .{else_label});
        if (i.else_) |els| {
            try self.emitTailBody(els);
        } else {
            try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
            try self.emitReturn();
        }
    }

    /// Emit a body whose last statement is the tail value. The last stmt's
    /// expression is lowered into `{x, 0}` and followed by `return.`.
    fn emitTailBody(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        if (body.len == 0) {
            try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
            try self.emitReturn();
            return;
        }
        for (body[0 .. body.len - 1]) |stmt| try self.emitStmt(stmt);
        const last = body[body.len - 1];
        switch (last.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| try self.lowerExprIntoX0(val.*);
                    try self.emitReturn();
                    return;
                },
                else => {},
            },
            else => {},
        }
        try self.lowerExprIntoX0(last.expr);
        try self.emitReturn();
    }

    /// Lower a binaryOp (arithmetic, comparison, or logical) so its value
    /// lands in `{x, dest}`.
    fn lowerArith(self: *Emitter, e: ast.Expr, dest: u32) anyerror!void {
        switch (e) {
            .binaryOp => |bin| switch (bin.kind.op) {
                .add, .sub, .mul, .div, .mod => try self.lowerArithGcBif(bin, dest),
                .lt, .gt, .lte, .gte, .eq, .ne => try self.lowerCmpAsValue(bin, dest),
                .@"and" => try self.lowerAndAsValue(bin, dest),
                .@"or" => try self.lowerOrAsValue(bin, dest),
            },
            else => try self.bodyPrint("    %% unsupported in arith position: {s}\n", .{@tagName(e)}),
        }
    }

    /// Arithmetic via `gc_bif`. Handles non-simple operands by materializing
    /// them into scratch x-registers above `cur_arity`.
    fn lowerArithGcBif(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        const bif: []const u8 = switch (bin.kind.op) {
            .add => "'+'",
            .sub => "'-'",
            .mul => "'*'",
            .div => "'div'",
            .mod => "'rem'",
            else => unreachable,
        };
        var lhs_buf: [64]u8 = undefined;
        var rhs_buf: [64]u8 = undefined;
        const lhs_simple = try self.simpleTerm(bin.kind.lhs.*, &lhs_buf);
        const rhs_simple = try self.simpleTerm(bin.kind.rhs.*, &rhs_buf);

        if (lhs_simple != null and rhs_simple != null) {
            try self.bodyPrint(
                "    {{gc_bif, {s}, {{f, 0}}, {d}, [{s}, {s}], {{x, {d}}}}}.\n",
                .{ bif, self.cur_arity, lhs_simple.?, rhs_simple.?, dest },
            );
            return;
        }

        const scratch = self.cur_arity;
        if (lhs_simple) |ls| {
            try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ ls, scratch });
        } else {
            try self.lowerExprIntoX0(bin.kind.lhs.*);
            if (scratch != 0)
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
        }

        var rhs_final_buf: [64]u8 = undefined;
        const rhs_final: []const u8 = if (rhs_simple) |rs| rs else blk: {
            try self.lowerExprIntoX0(bin.kind.rhs.*);
            break :blk try std.fmt.bufPrint(&rhs_final_buf, "{{x, 0}}", .{});
        };

        var lhs_final_buf: [64]u8 = undefined;
        const lhs_final = try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});

        try self.bodyPrint(
            "    {{gc_bif, {s}, {{f, 0}}, {d}, [{s}, {s}], {{x, {d}}}}}.\n",
            .{ bif, scratch + 1, lhs_final, rhs_final, dest },
        );
    }

    /// Lower a comparison (`<`, `>`, `==`, …) as a value: emits a `{test, …}`
    /// then branches to produce `{atom, true}` or `{atom, false}` in `{x, dest}`.
    fn lowerCmpAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        const opcode: []const u8 = switch (bin.kind.op) {
            .lt => "is_lt",
            .gt => "is_gt",
            .lte => "is_le",
            .gte => "is_ge",
            .eq => "is_eq",
            .ne => "is_ne_exact",
            else => unreachable,
        };

        var lhs_buf: [64]u8 = undefined;
        var rhs_buf: [64]u8 = undefined;
        const lhs_simple = try self.simpleTerm(bin.kind.lhs.*, &lhs_buf);
        const rhs_simple = try self.simpleTerm(bin.kind.rhs.*, &rhs_buf);

        var lhs_final_buf: [64]u8 = undefined;
        var rhs_final_buf: [64]u8 = undefined;
        var lhs_final: []const u8 = undefined;
        var rhs_final: []const u8 = undefined;

        if (lhs_simple != null and rhs_simple != null) {
            lhs_final = lhs_simple.?;
            rhs_final = rhs_simple.?;
        } else {
            const scratch = self.cur_arity;
            if (lhs_simple) |ls| {
                try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ ls, scratch });
            } else {
                try self.lowerExprIntoX0(bin.kind.lhs.*);
                if (scratch != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            }
            lhs_final = try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});

            if (rhs_simple) |rs| {
                rhs_final = rs;
            } else {
                try self.lowerExprIntoX0(bin.kind.rhs.*);
                rhs_final = try std.fmt.bufPrint(&rhs_final_buf, "{{x, 0}}", .{});
            }
        }

        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        try self.bodyPrint("    {{test, {s}, {{f, {d}}}, [{s}, {s}]}}.\n", .{ opcode, false_label, lhs_final, rhs_final });
        try self.bodyPrint("    {{move, {{atom, true}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
        try self.bodyPrint("  {{label, {d}}}.\n", .{false_label});
        try self.bodyPrint("    {{move, {{atom, false}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// `a && b` → short-circuit: test `a`, if false → false, else evaluate `b`.
    fn lowerAndAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        var lhs_buf: [64]u8 = undefined;
        const lhs_simple = try self.simpleTerm(bin.kind.lhs.*, &lhs_buf);
        var lhs_final_buf: [64]u8 = undefined;
        const lhs_final: []const u8 = if (lhs_simple) |ls| ls else blk: {
            const scratch = self.cur_arity;
            try self.lowerExprIntoX0(bin.kind.lhs.*);
            if (scratch != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            break :blk try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});
        };
        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{s}, {{atom, true}}]}}.\n", .{ false_label, lhs_final });
        try self.lowerExprIntoX0(bin.kind.rhs.*);
        if (dest != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
        try self.bodyPrint("  {{label, {d}}}.\n", .{false_label});
        try self.bodyPrint("    {{move, {{atom, false}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// `a || b` → short-circuit: test `a`, if true → true, else evaluate `b`.
    fn lowerOrAsValue(self: *Emitter, bin: anytype, dest: u32) anyerror!void {
        var lhs_buf: [64]u8 = undefined;
        const lhs_simple = try self.simpleTerm(bin.kind.lhs.*, &lhs_buf);
        var lhs_final_buf: [64]u8 = undefined;
        const lhs_final: []const u8 = if (lhs_simple) |ls| ls else blk: {
            const scratch = self.cur_arity;
            try self.lowerExprIntoX0(bin.kind.lhs.*);
            if (scratch != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            break :blk try std.fmt.bufPrint(&lhs_final_buf, "{{x, {d}}}", .{scratch});
        };
        const true_label = self.allocLabel();
        const end_label = self.allocLabel();
        try self.bodyPrint("    {{test, is_ne_exact, {{f, {d}}}, [{s}, {{atom, true}}]}}.\n", .{ true_label, lhs_final });
        try self.lowerExprIntoX0(bin.kind.rhs.*);
        if (dest != 0) try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
        try self.bodyPrint("  {{label, {d}}}.\n", .{true_label});
        try self.bodyPrint("    {{move, {{atom, true}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// `!x` → test x against true, produce the opposite atom.
    fn lowerNot(self: *Emitter, inner: ast.Expr, dest: u32) anyerror!void {
        try self.lowerExprIntoX0(inner);
        const false_label = self.allocLabel();
        const end_label = self.allocLabel();
        try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {{atom, true}}]}}.\n", .{false_label});
        try self.bodyPrint("    {{move, {{atom, false}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
        try self.bodyPrint("  {{label, {d}}}.\n", .{false_label});
        try self.bodyPrint("    {{move, {{atom, true}}, {{x, {d}}}}}.\n", .{dest});
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    // ── calls ────────────────────────────────────────────────────────────────

    /// `non_tail`: result lives in `{x, 0}` after the call; caller proceeds.
    /// `tail`: emit `call_last`/`call_only` (deallocate + return baked in).
    const CallMode = enum { non_tail, tail };

    /// Lower a `call.call` form into BEAM assembly. Evaluates each arg into
    /// `{x, i}`, then emits the appropriate call opcode.
    fn lowerCall(self: *Emitter, cc: anytype, mode: CallMode, _: u32) anyerror!void {
        if (cc.is_builtin) {
            try self.lowerBuiltinCall(cc, mode);
            return;
        }
        if (cc.receiver) |recv_name| {
            if (self.reg_map.get(recv_name)) |reg| {
                var rbuf: [64]u8 = undefined;
                const recv_term = try reg.format(&rbuf);
                try self.bodyPrint("    {{move, {s}, {{x, 0}}}}.\n", .{recv_term});
            } else {
                try self.bodyPrint("    {{move, {{atom, {s}}}, {{x, 0}}}}.\n", .{recv_name});
            }
            const scratch = self.cur_arity;
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            for (cc.args, 0..) |arg, i| {
                try self.lowerExprIntoX0(arg.value.*);
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch + 1 + i});
            }
            try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{scratch});
            for (0..cc.args.len) |i| {
                try self.bodyPrint("    {{move, {{x, {d}}}, {{x, {d}}}}}.\n", .{ scratch + 1 + i, 1 + i });
            }
            const total_arity = 1 + cc.args.len;
            const labels = self.fnLabelsFor(cc.callee, total_arity) catch {
                try self.bodyPrint("    %% unresolved method call: {s}/{d}\n", .{ cc.callee, total_arity });
                if (mode == .tail) try self.emitReturn();
                return;
            };
            switch (mode) {
                .non_tail => try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ total_arity, labels.entry }),
                .tail => try self.bodyPrint("    {{call_last, {d}, {{f, {d}}}, {d}}}.\n", .{ total_arity, labels.entry, self.num_y }),
            }
            return;
        }
        if (cc.trailing.len > 0) {
            for (cc.trailing) |trail| {
                try self.lowerLambda(trail);
                const scratch = self.cur_arity;
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
            }
        }

        const arity = cc.args.len;
        try self.materializeCallArgs(cc.args);

        const labels = self.fnLabelsFor(cc.callee, arity) catch {
            try self.bodyPrint("    %% unresolved local call: {s}/{d}\n", .{ cc.callee, arity });
            if (mode == .tail) try self.emitReturn();
            return;
        };
        switch (mode) {
            .non_tail => {
                try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ arity, labels.entry });
            },
            .tail => {
                try self.bodyPrint("    {{call_last, {d}, {{f, {d}}}, {d}}}.\n", .{ arity, labels.entry, self.num_y });
            },
        }
    }

    /// Builtins (`@print`, `@todo`, …) map to specific BEAM call_ext targets.
    /// Fase 2 only handles `@todo` cleanly (errors out at runtime); printing
    /// and the rest of the builtins require strings/binaries (Fase 3+).
    fn lowerBuiltinCall(self: *Emitter, cc: anytype, mode: CallMode) anyerror!void {
        if (std.mem.eql(u8, cc.callee, "todo") or std.mem.eql(u8, cc.callee, "panic")) {
            const atom: []const u8 = if (std.mem.eql(u8, cc.callee, "todo")) "undef" else "panic";
            try self.bodyPrint("    {{move, {{atom, {s}}}, {{x, 0}}}}.\n", .{atom});
            const tag: []const u8 = if (mode == .tail) "call_ext_only" else "call_ext";
            try self.bodyPrint("    {{{s}, 1, {{extfunc, erlang, error, 1}}}}.\n", .{tag});
            return;
        }
        if (std.mem.eql(u8, cc.callee, "print")) {
            if (cc.args.len > 0) {
                try self.lowerExprIntoX0(cc.args[0].value.*);
            }
            try self.bodyWrite("    {move, {x, 0}, {x, 1}}.\n");
            try self.emitStringLiteral("~p~n", 0);
            try self.bodyWrite("    {test_heap, 2, 2}.\n");
            try self.bodyWrite("    {put_list, {x, 1}, nil, {x, 1}}.\n");
            const tag: []const u8 = if (mode == .tail) "call_ext_only" else "call_ext";
            try self.bodyPrint("    {{{s}, 2, {{extfunc, io, format, 2}}}}.\n", .{tag});
            return;
        }
        if (std.mem.eql(u8, cc.callee, "block")) {
            if (cc.trailing.len > 0) {
                const body = cc.trailing[0];
                for (body.body) |stmt| try self.emitStmt(stmt);
            }
            return;
        }
        try self.bodyPrint("    %% unsupported builtin: @{s} (Fase 3+)\n", .{cc.callee});
    }

    /// Lay out call arguments into `{x, 0}..{x, arity-1}`. Currently expects
    /// each arg to be a `simpleTerm` (literal/identifier). Composite args go
    /// to Fase 9 (proper allocation).
    fn materializeCallArgs(self: *Emitter, args: anytype) anyerror!void {
        if (args.len > 16) {
            try self.bodyWrite("    %% unsupported: call with > 16 args\n");
            return;
        }
        var bufs: [16][64]u8 = undefined;
        var terms: [16]?[]const u8 = undefined;
        var has_complex = false;
        for (args, 0..) |arg, i| {
            terms[i] = try self.simpleTerm(arg.value.*, &bufs[i]);
            if (terms[i] == null) has_complex = true;
        }

        if (!has_complex) {
            for (args, 0..) |_, i| {
                try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ terms[i].?, i });
            }
            return;
        }

        const scratch_base = self.cur_arity;
        for (args, 0..) |arg, i| {
            if (terms[i]) |t| {
                try self.bodyPrint("    {{move, {s}, {{x, {d}}}}}.\n", .{ t, scratch_base + i });
            } else {
                try self.lowerExprIntoX0(arg.value.*);
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch_base + i});
            }
        }
        for (args, 0..) |_, i| {
            try self.bodyPrint("    {{move, {{x, {d}}}, {{x, {d}}}}}.\n", .{ scratch_base + i, i });
        }
    }

    /// Build an Erlang list from an array literal. Elements are consed
    /// right-to-left via `{put_list, Elem, Tail, {x, 0}}`.
    fn lowerArrayLit(self: *Emitter, al: anytype) anyerror!void {
        if (al.spreadExpr) |se| {
            try self.lowerExprIntoX0(se.*);
        } else {
            try self.bodyWrite("    {move, nil, {x, 0}}.\n");
        }
        if (al.elems.len > 0) {
            try self.bodyPrint("    {{test_heap, {d}, {d}}}.\n", .{ al.elems.len * 2, self.cur_arity + 1 });
            var i: usize = al.elems.len;
            while (i > 0) {
                i -= 1;
                const scratch = self.cur_arity;
                try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                try self.lowerExprIntoX0(al.elems[i]);
                try self.bodyPrint(
                    "    {{put_list, {{x, 0}}, {{x, {d}}}, {{x, 0}}}}.\n",
                    .{scratch},
                );
            }
        }
    }

    /// Build an Erlang tuple from a tuple literal via `{put_tuple2, ...}`.
    fn lowerTupleLit(self: *Emitter, tl: anytype) anyerror!void {
        const n = tl.elems.len;
        const scratch_base = self.cur_arity;
        for (tl.elems, 0..) |elem, i| {
            try self.lowerExprIntoX0(elem);
            try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch_base + i});
        }
        try self.bodyPrint("    {{test_heap, {d}, {d}}}.\n", .{ n + 1, scratch_base + n });
        try self.bodyPrint("    {{put_tuple2, {{x, 0}}, {{list, [", .{});
        for (0..n) |i| {
            if (i > 0) try self.bodyWrite(", ");
            try self.bodyPrint("{{x, {d}}}", .{scratch_base + i});
        }
        try self.bodyWrite("]}}.\n");
    }

    /// Lower a `case expr { pat -> body; ... }` into a chain of BEAM test
    /// instructions with fall-through labels.
    fn lowerCase(self: *Emitter, subjects: anytype, arms: anytype) anyerror!void {
        if (subjects.len == 0) {
            try self.bodyWrite("    {move, {atom, undefined}, {x, 0}}.\n");
            return;
        }
        try self.lowerExprIntoX0(subjects[0]);

        const end_label = self.allocLabel();
        for (arms) |arm| {
            switch (arm.pattern) {
                .numberLit => |n| {
                    var buf: [64]u8 = undefined;
                    const term = try formatNumberInto(&buf, n);
                    const next = self.allocLabel();
                    try self.bodyPrint(
                        "    {{test, is_eq, {{f, {d}}}, [{{x, 0}}, {s}]}}.\n",
                        .{ next, term },
                    );
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .stringLit => |s| {
                    const next = self.allocLabel();
                    try self.bodyPrint("    {{move, {{x, 0}}, {{x, 1}}}}.\n", .{});
                    try self.emitStringLiteral(s, 0);
                    try self.bodyPrint(
                        "    {{test, is_eq, {{f, {d}}}, [{{x, 1}}, {{x, 0}}]}}.\n",
                        .{next},
                    );
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .ident => |name| {
                    if (std.mem.eql(u8, name, "_")) {
                        try self.lowerExprIntoX0(arm.body);
                        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    } else {
                        const y_idx = self.next_y;
                        self.next_y += 1;
                        try self.reg_map.put(name, .{ .y = y_idx });
                        try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                        try self.lowerExprIntoX0(arm.body);
                        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    }
                },
                .wildcard => {
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                },
                .@"or" => |pats| {
                    const arm_label = self.allocLabel();
                    for (pats) |p| {
                        switch (p) {
                            .numberLit => |n| {
                                var buf: [64]u8 = undefined;
                                const term = try formatNumberInto(&buf, n);
                                try self.bodyPrint(
                                    "    {{test, is_ne_exact, {{f, {d}}}, [{{x, 0}}, {s}]}}.\n",
                                    .{ arm_label, term },
                                );
                            },
                            else => {},
                        }
                    }
                    const next = self.allocLabel();
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{next});
                    try self.bodyPrint("  {{label, {d}}}.\n", .{arm_label});
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .variantFields => |vf| {
                    const next = self.allocLabel();
                    try self.bodyPrint("    {{test, is_tagged_tuple, {{f, {d}}}, {{x, 0}}, {d}, {{atom, {s}}}}}.\n", .{ next, vf.bindings.len + 1, vf.name });
                    for (vf.bindings, 0..) |bname, i| {
                        try self.bodyPrint("    {{get_tuple_element, {{x, 0}}, {d}, {{x, 1}}}}.\n", .{i + 1});
                        const y_idx = self.next_y;
                        self.next_y += 1;
                        try self.reg_map.put(bname, .{ .y = y_idx });
                        try self.bodyPrint("    {{move, {{x, 1}}, {{y, {d}}}}}.\n", .{y_idx});
                    }
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .variantBinding => |vb| {
                    const next = self.allocLabel();
                    try self.bodyPrint("    {{test, is_tuple, {{f, {d}}}, [{{x, 0}}]}}.\n", .{next});
                    try self.bodyPrint("    {{get_tuple_element, {{x, 0}}, 0, {{x, 1}}}}.\n", .{});
                    try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{{x, 1}}, {{atom, {s}}}]}}.\n", .{ next, vb.name });
                    const y_idx = self.next_y;
                    self.next_y += 1;
                    try self.reg_map.put(vb.binding, .{ .y = y_idx });
                    try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .list => |lst| {
                    const next = self.allocLabel();
                    if (lst.elems.len == 0 and lst.spread == null) {
                        try self.bodyPrint("    {{test, is_nil, {{f, {d}}}, [{{x, 0}}]}}.\n", .{next});
                    } else {
                        for (lst.elems) |_| {
                            try self.bodyPrint("    {{test, is_nonempty_list, {{f, {d}}}, [{{x, 0}}]}}.\n", .{next});
                            try self.bodyWrite("    {get_list, {x, 0}, {x, 1}, {x, 0}}.\n");
                        }
                        if (lst.spread) |spread_name| {
                            if (spread_name.len > 0) {
                                const y_idx = self.next_y;
                                self.next_y += 1;
                                try self.reg_map.put(spread_name, .{ .y = y_idx });
                                try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                            }
                        }
                    }
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                .multi => |pats| {
                    const next = self.allocLabel();
                    for (pats, 0..) |p, i| {
                        if (i < subjects.len) {
                            switch (p) {
                                .numberLit => |n| {
                                    var buf: [64]u8 = undefined;
                                    const term = try formatNumberInto(&buf, n);
                                    var subj_buf: [64]u8 = undefined;
                                    const subj_term = try self.simpleTerm(subjects[i], &subj_buf) orelse blk: {
                                        try self.lowerExprIntoX0(subjects[i]);
                                        break :blk try std.fmt.bufPrint(&subj_buf, "{{x, 0}}", .{});
                                    };
                                    try self.bodyPrint("    {{test, is_eq, {{f, {d}}}, [{s}, {s}]}}.\n", .{ next, subj_term, term });
                                },
                                .wildcard => {},
                                .ident => |name| {
                                    if (!std.mem.eql(u8, name, "_")) {
                                        try self.lowerExprIntoX0(subjects[i]);
                                        const y_idx = self.next_y;
                                        self.next_y += 1;
                                        try self.reg_map.put(name, .{ .y = y_idx });
                                        try self.bodyPrint("    {{move, {{x, 0}}, {{y, {d}}}}}.\n", .{y_idx});
                                    }
                                },
                                else => {},
                            }
                        }
                    }
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                    try self.bodyPrint("  {{label, {d}}}.\n", .{next});
                },
                else => {
                    try self.lowerExprIntoX0(arm.body);
                    try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});
                },
            }
        }
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// Lower a lambda `{ params -> body }` into a deferred BEAM function and
    /// emit `{make_fun2, ...}` at the call site. Result in `{x, 0}`.
    fn lowerLambda(self: *Emitter, lam: anytype) anyerror!void {
        const idx = self.lambda_count;
        self.lambda_count += 1;
        const arity: u32 = @intCast(lam.params.len);

        var name_buf: [256]u8 = undefined;
        const fun_name = try std.fmt.bufPrint(&name_buf, "'-{s}/{d}-fun-{d}-'", .{ self.cur_fn_name, self.cur_arity, idx });

        try self.reserveFn(fun_name, arity);
        const labels = try self.fnLabelsFor(fun_name, arity);

        var lam_buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &lam_buf.writer;

        const saved_reg_map = self.reg_map;
        self.reg_map = std.StringHashMap(Reg).init(self.alloc);
        const saved_y = self.next_y;
        const saved_num_y = self.num_y;
        const saved_arity = self.cur_arity;

        self.next_y = 0;
        self.cur_arity = arity;
        self.num_y = self.precountLocals(lam.body);

        var x: u32 = 0;
        for (lam.params) |p| {
            try self.reg_map.put(p, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ fun_name, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, fun_name, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});
        try self.bodyPrint("    {{allocate, {d}, {d}}}.\n", .{ self.num_y, arity });
        try self.emitBody(lam.body);

        self.reg_map.deinit();
        self.reg_map = saved_reg_map;
        self.next_y = saved_y;
        self.num_y = saved_num_y;
        self.cur_arity = saved_arity;
        self.out = saved_out;

        try self.deferred_lambdas.append(self.alloc, try lam_buf.toOwnedSlice());
        lam_buf.deinit();

        try self.bodyPrint("    {{make_fun2, {{f, {d}}}, {d}, 0, 0}}.\n", .{ labels.entry, idx });
    }

    /// Lower `try expr catch handler` → BEAM try/catch block.
    fn lowerTryCatch(self: *Emitter, tc: anytype) anyerror!void {
        const y_idx = self.next_y;
        self.next_y += 1;
        const catch_label = self.allocLabel();
        const end_label = self.allocLabel();

        try self.bodyPrint("    {{try, {{y, {d}}}, {{f, {d}}}}}.\n", .{ y_idx, catch_label });
        try self.lowerExprIntoX0(tc.expr.*);
        try self.bodyPrint("    {{try_end, {{y, {d}}}}}.\n", .{y_idx});
        try self.bodyPrint("    {{jump, {{f, {d}}}}}.\n", .{end_label});

        try self.bodyPrint("  {{label, {d}}}.\n", .{catch_label});
        try self.bodyPrint("    {{try_case, {{y, {d}}}}}.\n", .{y_idx});
        try self.lowerExprIntoX0(tc.handler.*);
        try self.bodyPrint("  {{label, {d}}}.\n", .{end_label});
    }

    /// Lower `lhs |> rhs`: evaluate lhs, then call rhs as function with result.
    fn lowerPipeline(self: *Emitter, pl: anytype) anyerror!void {
        try self.lowerExprIntoX0(pl.lhs.*);
        switch (pl.rhs.*) {
            .identifier => |id| switch (id.kind) {
                .ident => |name| {
                    const labels = self.fnLabelsFor(name, 1) catch {
                        try self.bodyPrint("    %% unresolved pipeline fn: {s}/1\n", .{name});
                        return;
                    };
                    try self.bodyPrint("    {{call, 1, {{f, {d}}}}}.\n", .{labels.entry});
                },
                else => try self.bodyWrite("    %% unsupported pipeline rhs\n"),
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    const scratch = self.cur_arity;
                    try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
                    try self.materializeCallArgs(cc.args);
                    const total = cc.args.len + 1;
                    var i: usize = cc.args.len;
                    while (i > 0) : (i -= 1) {
                        try self.bodyPrint("    {{move, {{x, {d}}}, {{x, {d}}}}}.\n", .{ i - 1, i });
                    }
                    try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{scratch});
                    const labels = self.fnLabelsFor(cc.callee, total) catch {
                        try self.bodyPrint("    %% unresolved pipeline fn: {s}/{d}\n", .{ cc.callee, total });
                        return;
                    };
                    try self.bodyPrint("    {{call, {d}, {{f, {d}}}}}.\n", .{ total, labels.entry });
                },
                .pipeline => |inner_pl| {
                    try self.lowerPipeline(inner_pl);
                },
            },
            else => try self.bodyWrite("    %% unsupported pipeline rhs\n"),
        }
    }

    fn hasYieldOrBreakValue(body: []const ast.Stmt) bool {
        for (body) |stmt| {
            switch (stmt.expr) {
                .jump => |j| switch (j.kind) {
                    .yield => return true,
                    .@"break" => |v| if (v != null) return true,
                    else => {},
                },
                .branch => |b| switch (b.kind) {
                    .if_ => |i| {
                        if (hasYieldOrBreakValue(i.then_)) return true;
                        if (i.else_) |els| if (hasYieldOrBreakValue(els)) return true;
                    },
                    else => {},
                },
                else => {},
            }
        }
        return false;
    }

    fn lowerLoop(self: *Emitter, lp: anytype) anyerror!void {
        const has_map = hasYieldOrBreakValue(lp.kind.body);

        const idx = self.lambda_count;
        self.lambda_count += 1;
        const arity: u32 = @intCast(lp.kind.params.len);

        var name_buf: [256]u8 = undefined;
        const fun_name = try std.fmt.bufPrint(&name_buf, "'-{s}/{d}-fun-{d}-'", .{ self.cur_fn_name, self.cur_arity, idx });

        try self.reserveFn(fun_name, arity);
        const labels = try self.fnLabelsFor(fun_name, arity);

        var lam_buf: std.Io.Writer.Allocating = .init(self.alloc);
        const saved_out = self.out;
        self.out = &lam_buf.writer;

        const saved_reg_map = self.reg_map;
        self.reg_map = std.StringHashMap(Reg).init(self.alloc);
        const saved_y = self.next_y;
        const saved_num_y = self.num_y;
        const saved_arity = self.cur_arity;
        const saved_loop_flag = self.in_loop_lambda;

        self.next_y = 0;
        self.cur_arity = arity;
        self.num_y = self.precountLocals(lp.kind.body);
        self.in_loop_lambda = true;

        var x: u32 = 0;
        for (lp.kind.params) |p| {
            try self.reg_map.put(p, .{ .x = x });
            x += 1;
        }

        try self.bodyWrite("\n");
        try self.bodyPrint("{{function, {s}, {d}, {d}}}.\n", .{ fun_name, arity, labels.entry });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.func_info});
        try self.bodyPrint("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ self.module_name, self.cur_line });
        try self.bodyPrint("    {{func_info, {{atom, {s}}}, {{atom, {s}}}, {d}}}.\n", .{ self.module_name, fun_name, arity });
        try self.bodyPrint("  {{label, {d}}}.\n", .{labels.entry});
        try self.bodyPrint("    {{allocate, {d}, {d}}}.\n", .{ self.num_y, arity });

        try self.emitBody(lp.kind.body);

        self.reg_map.deinit();
        self.reg_map = saved_reg_map;
        self.next_y = saved_y;
        self.num_y = saved_num_y;
        self.cur_arity = saved_arity;
        self.in_loop_lambda = saved_loop_flag;
        self.out = saved_out;

        try self.deferred_lambdas.append(self.alloc, try lam_buf.toOwnedSlice());
        lam_buf.deinit();

        try self.bodyPrint("    {{make_fun2, {{f, {d}}}, {d}, 0, 0}}.\n", .{ labels.entry, idx });

        const scratch = self.cur_arity;
        try self.bodyPrint("    {{move, {{x, 0}}, {{x, {d}}}}}.\n", .{scratch});
        try self.lowerExprIntoX0(lp.kind.iter.*);
        try self.bodyPrint("    {{move, {{x, 0}}, {{x, 1}}}}.\n", .{});
        try self.bodyPrint("    {{move, {{x, {d}}}, {{x, 0}}}}.\n", .{scratch});

        const func = if (has_map) "map" else "foreach";
        try self.bodyPrint("    {{call_ext, 2, {{extfunc, lists, {s}, 2}}}}.\n", .{func});
    }

    /// Emit a string literal as a BEAM binary into `{x, dest}`.
    /// For OTP 24+ the simplest approach is `{move, {literal, <<"str">>}, {x, D}}`.
    fn emitStringLiteral(self: *Emitter, s: []const u8, dest: u32) !void {
        try self.bodyPrint("    {{move, {{literal, <<\"", .{});
        for (s) |c| switch (c) {
            '"' => try self.bodyWrite("\\\""),
            '\\' => try self.bodyWrite("\\\\"),
            '\n' => try self.bodyWrite("\\n"),
            '\r' => try self.bodyWrite("\\r"),
            '\t' => try self.bodyWrite("\\t"),
            else => try self.out.writeByte(c),
        };
        try self.bodyPrint("\">>}}, {{x, {d}}}}}.\n", .{dest});
    }

    /// Lower `receiver.member` into `{x, dest}` via `{get_map_elements, ...}`.
    /// The receiver is evaluated into x0, then the field is extracted.
    fn lowerIdentAccess(self: *Emitter, ia: anytype, dest: u32) anyerror!void {
        try self.lowerExprIntoX0(ia.receiver.*);
        const fail_label = self.allocLabel();
        try self.bodyPrint(
            "    {{get_map_elements, {{f, {d}}}, {{x, 0}}, {{list, [{{atom, {s}}}, {{x, {d}}}]}}}}.\n",
            .{ fail_label, ia.member, dest },
        );
        try self.bodyPrint("  {{label, {d}}}.\n", .{fail_label});
    }

    /// Render a "simple" expression (literal number or identifier already
    /// mapped to a register) as a BEAM term in `buf`. Returns the rendered
    /// slice or null if the expression is too complex.
    fn simpleTerm(self: *Emitter, e: ast.Expr, buf: []u8) !?[]const u8 {
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    if (self.reg_map.get(n)) |reg| {
                        return try reg.format(buf);
                    }
                    return null;
                },
                else => return null,
            },
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| {
                    return try formatNumberInto(buf, n);
                },
                .null_ => return try std.fmt.bufPrint(buf, "{{atom, nil}}", .{}),
                else => return null,
            },
            .unaryOp => |un| switch (un.kind.op) {
                .neg => switch (un.kind.expr.*) {
                    .literal => |lit| switch (lit.kind) {
                        .numberLit => |n| return try formatNegNumberInto(buf, n),
                        else => return null,
                    },
                    else => return null,
                },
                else => return null,
            },
            else => return null,
        }
    }
};

/// Render a numeric literal into `buf`. Returns the populated slice.
fn formatNumberInto(buf: []u8, n: []const u8) ![]const u8 {
    var has_dot = false;
    for (n) |c| if (c == '.' or c == 'e' or c == 'E') {
        has_dot = true;
        break;
    };
    if (has_dot) {
        return std.fmt.bufPrint(buf, "{{float, {s}}}", .{n});
    }
    return std.fmt.bufPrint(buf, "{{integer, {s}}}", .{n});
}

/// Render the negation of a numeric literal as `{integer, -N}` / `{float, -F}`.
fn formatNegNumberInto(buf: []u8, n: []const u8) ![]const u8 {
    var has_dot = false;
    for (n) |c| if (c == '.' or c == 'e' or c == 'E') {
        has_dot = true;
        break;
    };
    if (has_dot) {
        return std.fmt.bufPrint(buf, "{{float, -{s}}}", .{n});
    }
    return std.fmt.bufPrint(buf, "{{integer, -{s}}}", .{n});
}
