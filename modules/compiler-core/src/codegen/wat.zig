/// WebAssembly Text (`.wat`) codegen backend.
///
/// Lowers botopink into the `wat/wat_ast.zig` code model; `wat/wat_emitter.zig`
/// turns that model into the `(module ...)` text `wasmtime` executes. Nothing
/// in this file writes target syntax — the same split as `codegen/erlang.zig`
/// over `codegen/beam/erl_ast.zig`.
///
/// Covers: numeric fn decls, arithmetic, comparisons, if/else, return,
/// top-level val as globals (folded comptime values included), fn main/0
/// wrapper, linear memory with a bump allocator, length-prefixed strings,
/// @print via WASI fd_write, case (numbers, strings, variant and Result tags),
/// loops and comprehensions via block/loop/br_if, tuples/arrays/records in
/// memory, primitive methods (`instance_lowerings`), function values through a
/// funcref table, boxed scalar optionals, `assert`, and imports linked
/// statically. See `codegen/AGENTS.md` §wat.
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const crossModule = @import("./crossModule.zig");
const envMod = @import("../comptime/env.zig");
const wat = @import("./wat/wat_ast.zig");
const watEmitter = @import("./wat/wat_emitter.zig");
const prelude = @import("./wat/wat_prelude.zig");

const CrossModule = crossModule.CrossModule;

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;

const Instr = wat.Instr;
const Line = wat.Line;
const Seq = wat.Seq;
const Item = wat.Item;
const ValType = wat.ValType;

/// The `ValType` a backend-internal type name (`"i32"`, `"f64"`, …) stands for.
/// Lowering recovers types as spelled strings; the model is an enum, and this
/// is the one place the two meet.
fn vt(name: []const u8) ValType {
    return ValType.parse(name);
}

/// `i32.const <text>` / `f64.const <text>` — the numeral keeps its spelling.
fn constOf(ty: []const u8, text: []const u8) Instr {
    return .{ .@"const" = .{ .ty = vt(ty), .text = text } };
}

/// `<ty>.<name>` (`i32.add`, `f64.lt`, `i32.eqz`, …).
fn opOf(ty: []const u8, name: []const u8) Instr {
    return .{ .op = .{ .ty = vt(ty), .name = name } };
}

/// `i32.const 0` — the carrier this backend uses for absence, false, a null
/// pointer and every construct it cannot lower.
const zero: Instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } };

/// `i32.const 1` — the true carrier.
const one: Instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } };

/// The bump-allocator pointer every aggregate construction advances.
const heap_ptr = "__heap_ptr";

/// Comments the Result/Option lowering repeats often enough to name.
const result_tag = "Result tag (0 = Ok, non-zero = Error)";
const ok_payload = "Ok payload";
const option_shape = "Option (0 = None, else Some payload)";

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

fn isSyntheticEntrypointVal(v: ast.ValDecl) bool {
    return std.mem.startsWith(u8, v.name, "_");
}

fn watType(t: ast.TypeRef) []const u8 {
    switch (t) {
        .named => |n| {
            if (std.mem.eql(u8, n, "i32")) return "i32";
            if (std.mem.eql(u8, n, "i64")) return "i64";
            if (std.mem.eql(u8, n, "f32")) return "f32";
            if (std.mem.eql(u8, n, "f64")) return "f64";
            if (std.mem.eql(u8, n, "bool")) return "i32";
        },
        else => {},
    }
    return "i32";
}

fn watTypeOpt(t: ?ast.TypeRef) []const u8 {
    if (t) |x| return watType(x);
    return "i32";
}

fn isNamedTypeRef(t: ast.TypeRef, name: []const u8) bool {
    return switch (t) {
        .named => |n| std.mem.eql(u8, n, name),
        .optional => |inner| isNamedTypeRef(inner.*, name),
        else => false,
    };
}

fn isStringTypeRef(t: ast.TypeRef) bool {
    return isNamedTypeRef(t, "string");
}

fn isBoolTypeRef(t: ast.TypeRef) bool {
    return isNamedTypeRef(t, "bool");
}

// ── public entry ─────────────────────────────────────────────────────────────

pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    _ = config;
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    // wasm has no module linking at run time, so a module that imports from
    // another is linked statically: the owner's declarations are emitted into
    // the consumer (`collectLinks`). The index resolves an imported name to
    // the module that defines it.
    var cross = try crossModule.build(alloc, outputs);
    defer cross.deinit();

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError, .typeError => try results.append(alloc, try ModuleOutput.failedModule(alloc, ct.*)),
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
                var linked: std.ArrayListUnmanaged(Linked) = .empty;
                defer linked.deinit(alloc);
                var visited = std.StringHashMap(void).init(alloc);
                defer visited.deinit();
                try visited.put(ct.name, {});
                try collectLinks(alloc, outputs, &cross, ok.transformed, &visited, &linked);
                const code = try emitWat(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, ok.instance_lowerings, linked.items);
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = code,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
                        .comptime_trace = try comptimeMod.trace.renderAlloc(alloc, ok.comptime_traces),
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    return results;
}

// ── static linking ───────────────────────────────────────────────────────────

/// A module whose declarations are emitted into a consumer, with the loc-keyed
/// tables its own lowering needs (locs are per source file, so the consumer's
/// tables would answer for the wrong nodes).
const Linked = struct {
    program: ast.Program,
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
};

/// Every module `program` imports from, transitively, dependencies first. An
/// import resolves through the export index (`import {double} from "math"`)
/// or names a module by its basename (`import {order} from "std"`).
fn collectLinks(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    cross: *const CrossModule,
    program: ast.Program,
    visited: *std.StringHashMap(void),
    out: *std.ArrayListUnmanaged(Linked),
) !void {
    for (program.decls) |decl| {
        const u = switch (decl) {
            .use => |u| u,
            else => continue,
        };
        for (u.imports) |imp| {
            for (outputs) |*o| {
                const owns = if (cross.exports.get(imp.name())) |info|
                    std.mem.eql(u8, info.module, o.name)
                else
                    std.mem.eql(u8, crossModule.moduleBasename(o.name), imp.segments[imp.segments.len - 1]);
                if (!owns or visited.contains(o.name)) continue;
                const ok = switch (o.outcome) {
                    .ok => |*ok| ok,
                    else => continue,
                };
                try visited.put(o.name, {});
                try collectLinks(alloc, outputs, cross, ok.transformed, visited, out);
                try out.append(alloc, .{
                    .program = ok.transformed,
                    .rewrites = ok.dispatch_rewrites,
                    .instance_lowerings = ok.instance_lowerings,
                });
            }
        }
    }
}

/// The name a top-level declaration binds, when it binds one.
fn declName(d: ast.DeclKind) ?[]const u8 {
    return switch (d) {
        .@"fn" => |f| f.name,
        .val => |v| v.name,
        .type_ => |t| t.name,
        .behavior => |i| i.name,
        .implement => |im| im.name,
        .extend => |ex| ex.name,
        else => null,
    };
}

// ── top-level emitter ────────────────────────────────────────────────────────

const DataSeg = struct { offset: u32, len: u32, content: []const u8 };

fn emitWat(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    own_program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    own_instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    linked: []const Linked,
) ![]u8 {
    var em = Emitter.init(alloc, comptime_vals, rewrites);
    defer em.deinit();
    em.module_name = module_name;
    em.instance_lowerings = own_instance_lowerings;

    // `val x = comptime { … break v; }` was folded by the comptime pass into
    // `comptime_vals["ct_<N>"]`, N counting this module's `val`s and `fn`s in
    // order — the same numbering commonJS reads it by.
    {
        var binding_idx: usize = 0;
        for (own_program.decls) |d| switch (d) {
            .val => |v| {
                if (v.value.* == .comptime_) {
                    const id = try std.fmt.allocPrint(em.arena(), "ct_{d}", .{binding_idx});
                    if (comptime_vals.get(id)) |text| try em.folded_globals.put(v.name, text);
                }
                binding_idx += 1;
            },
            .@"fn" => binding_idx += 1,
            else => {},
        };
    }

    // The linked modules' declarations come first, minus their entry point,
    // their tests and any name this module defines itself. `owner[i]` is the
    // index into `linked` a declaration came from (`linked.len` = this module).
    const ar0 = em.arena();
    var own_names = std.StringHashMap(void).init(alloc);
    defer own_names.deinit();
    for (own_program.decls) |d| if (declName(d)) |n| try own_names.put(n, {});
    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var owner: std.ArrayListUnmanaged(usize) = .empty;
    for (linked, 0..) |l, li| for (l.program.decls) |d| {
        switch (d) {
            .@"fn" => |f| if (isMain0(f)) continue,
            .@"test", .use, .mod, .comment => continue,
            else => {},
        }
        const n = declName(d) orelse continue;
        if (own_names.contains(n)) continue;
        try own_names.put(n, {});
        // A linked declaration is not this module's export.
        const copy: ast.DeclKind = switch (d) {
            .@"fn" => |f| blk: {
                var g = f;
                g.isPub = false;
                break :blk .{ .@"fn" = g };
            },
            .val => |v| blk: {
                var w = v;
                w.isPub = false;
                break :blk .{ .val = w };
            },
            else => d,
        };
        try decls.append(ar0, copy);
        try owner.append(ar0, li);
    };
    for (own_program.decls) |d| {
        try decls.append(ar0, d);
        try owner.append(ar0, linked.len);
    }
    const program: ast.Program = .{ .decls = decls.items };
    try em.registerTypes(program);
    try em.collectExtensions(program);

    var has_main_0 = false;
    var main_returns_value = false;
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| if (isMain0(f)) {
            has_main_0 = true;
            main_returns_value = Emitter.fnHasResult(f);
        },
        else => {},
    };

    // Top-level `val`s become module globals whether or not there is a `main`.
    // They used to be dropped when a `main` existed, which left every reference
    // to one as a dangling `global.get`.
    try em.registerSymbols(program, true);

    for (program.decls, owner.items) |decl, from| {
        em.rewrites = if (from < linked.len) linked[from].rewrites else rewrites;
        em.instance_lowerings = if (from < linked.len) linked[from].instance_lowerings else own_instance_lowerings;
        try em.emitDecl(decl);
    }
    em.rewrites = rewrites;
    em.instance_lowerings = own_instance_lowerings;

    // After every fn is emitted (their signatures are what the initialisers
    // call) but before the module is assembled (it may intern more strings).
    try em.emitGlobalInit();

    // Functions emitted on demand: the lambdas lifted out of the bodies above
    // (each may lift more), and the interface associated `default fn`s some
    // call reached.
    try em.emitPendingFns();

    if (has_main_0) try em.emitEntrypointWrapper(main_returns_value);

    // ── assemble the module ──────────────────────────────────────────────
    //
    // Order is this backend's, not the emitter's: imports, memory, the
    // instantiation hook, the interned data, the bump-allocator pointer, the
    // lowered forms, then the runtime helpers the lowering asked for.
    const ar = em.arena();
    var items: std.ArrayListUnmanaged(Item) = .empty;

    // The print helpers are the only thing that needs a host function, and
    // `Builder.helper` is the only way to have called one.
    if (em.b.helpers.has(.print)) try items.append(ar, .{ .import = prelude.fd_write_import });

    try items.append(ar, .{ .memory = .{ .@"export" = "memory", .min_pages = 1 } });

    // The function table a lambda value indexes into.
    if (em.lambdas.items.len > 0 or em.uses_table) {
        const names = try ar.alloc([]const u8, em.lambdas.items.len);
        for (em.lambdas.items, 0..) |l, i| names[i] = l.name;
        try items.append(ar, .{ .table = names });
    }

    // Runs at instantiation, ahead of `_start`: fills in the globals whose
    // initialiser is not a constant expression.
    if (em.deferred_globals.items.len > 0)
        try items.append(ar, .{ .start = "__init_globals" });

    for (em.data_segments.items) |seg| {
        try items.append(ar, .{ .data = .{
            .offset = seg.offset,
            .len_prefix = seg.len,
            .bytes = seg.content,
        } });
    }

    try items.append(ar, .{ .global = .{
        .name = "__heap_ptr",
        .ty = .i32,
        .mutable = true,
        .init = try std.fmt.allocPrint(ar, "{d}", .{em.next_data_offset}),
    } });

    try items.appendSlice(ar, em.items.items);

    for (prelude.order) |group| {
        if (em.b.helpers.has(group)) try items.appendSlice(ar, prelude.items(group));
    }

    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();
    try watEmitter.renderModule(&aw.writer, .{ .items = items.items });
    return aw.toOwnedSlice();
}

// ── Emitter ──────────────────────────────────────────────────────────────────

/// What the wasm operand stack looks like after an expression / statement has
/// been lowered.
///   * `.value`      — exactly one value was pushed.
///   * `.none`       — nothing was pushed (void call, comment, binding).
///   * `.terminated` — control left the block (`return` / `unreachable`), so
///                     the stack is polymorphic and needs no fix-up.
/// Every emission site normalises to what its context needs (push a zero when a
/// value is required, `drop` when one is not), which is what keeps the module
/// valid: wasm rejects both leftovers at the end of a block and underflows.
const Tail = enum { value, none, terminated };

/// A hoisted local declaration. Locals live in the `wat_ast.Func` node, so
/// there is no way to write one into a body at all: lowering registers them
/// here and `funcNode` hands the list to the model.
const LocalDecl = struct { name: []const u8, ty: []const u8 };

/// A detached instruction sink. Lowering a nested body (a function body, an
/// `if` arm, a `loop` body) redirects `Emitter.cur` into one of these and
/// `seal`s it into a `wat_ast.Seq` with the stack effect the context expects —
/// the same buffer-and-swap the writer-based emitter used, minus the text.
const Capture = struct {
    lines: std.ArrayListUnmanaged(Line) = .empty,
    /// The sink to restore on `seal` — null when this capture is the outermost
    /// one (a function body).
    saved: ?*std.ArrayListUnmanaged(Line) = null,
};

/// Signature of an emitted function, keyed by its WAT symbol (already mangled
/// for extension/record methods). `result` is null for a void function. Call
/// sites consult this to know whether a `call` pushes a value, and to coerce
/// arguments to the declared parameter types.
const FnSig = struct { params: []const []const u8, result: ?[]const u8 };

const Emitter = struct {
    alloc: std.mem.Allocator,
    /// Node factory: owns the arena every built node borrows from and the set
    /// of runtime helpers the lowering has asked for. Set up in `init` once
    /// `reg_arena` exists.
    b: wat.Builder = .{ .arena = undefined },
    /// Where lowered instructions go. Null outside a function body — emitting
    /// an instruction there is a bug, not a silently dropped line.
    cur: ?*std.ArrayListUnmanaged(Line) = null,
    /// Top-level forms produced so far, in order: the lowered functions, the
    /// module globals and the comments between them.
    items: std.ArrayListUnmanaged(Item) = .empty,
    cv: std.StringHashMap([]const u8),

    cur_result: []const u8 = "i32",
    /// Whether the function being emitted has a `(result …)`. Drives the
    /// value/void normalisation of the body's tail and of `return <expr>`.
    fn_has_result: bool = false,
    /// Names a `case` arm rebinds with a different wasm type than the local
    /// already declared under that name (a pattern `Square(s)` inside
    /// `fn area(s: Shape)`): the arm's uses read `s__<n>` instead.
    aliases: std.StringHashMap([]const u8),
    /// Locals first declared by a `case` pattern (their type is the pattern's).
    pattern_locals: std.StringHashMap(void),
    alias_seq: u32 = 0,
    /// The function being emitted returns a `@Result` (`#[@result]`, or a
    /// declared `-> @Result<…>`).
    fn_returns_result: bool = false,
    locals: std.StringHashMap([]const u8),
    /// Locals to flush into the current function's header, in insertion order.
    pending_locals: std.ArrayListUnmanaged(LocalDecl) = .empty,
    /// Locals known to hold a length-prefixed string pointer (params typed
    /// `string`, `val`s bound to a literal/concat/slice). Drives string `==`,
    /// `+` and `@print` on non-literal operands.
    str_locals: std.StringHashMap(void),
    /// Locals known to hold the 0/1 boolean carrier, so `@print` can render
    /// them as `true`/`false` like the other backends.
    bool_locals: std.StringHashMap(void),
    /// Emitted functions declared `-> string` / `-> bool`.
    str_fns: std.StringHashMap(void),
    /// Functions declared `-> @Result<string, …>`: `try f()` is a string.
    result_str_fns: std.StringHashMap(void),
    /// Payload shapes of the `@Result` a fn returns / a local holds / a `case`
    /// subject local holds — so `Ok(v) -> "OK:" + v` knows `v` is a string.
    result_shape_fns: std.StringHashMap(ResultShape),
    result_shape_locals: std.StringHashMap(ResultShape),
    result_subjects: std.StringHashMap(ResultShape),
    /// Locals bound to an optional no declaration names (an else-less `if`).
    opt_locals: std.StringHashMap(OptInfo),
    /// Declared types the optional carrier needs to see: a fn's return type and
    /// parameter types, a local's / global's annotation (or the declared type
    /// of the call it was bound from), and every record field's type.
    fn_ret_typerefs: std.StringHashMap(ast.TypeRef),
    fn_param_typerefs: std.StringHashMap([]const ast.TypeRef),
    local_typerefs: std.StringHashMap(ast.TypeRef),
    global_typerefs: std.StringHashMap(ast.TypeRef),
    record_field_typerefs: std.StringHashMap([]const ast.TypeRef),
    /// The declared return type of the fn being emitted.
    cur_ret_typeref: ?ast.TypeRef = null,
    /// Top-level `val` → the text the comptime pass folded its initialiser to.
    folded_globals: std.StringHashMap([]const u8),
    /// Top-level `val` → record type name, when recovered (`val cfg = record
    /// { … }`), so `cfg.port` reads the right slot.
    global_rec_types: std.StringHashMap([]const u8),
    bool_fns: std.StringHashMap(void),
    /// Module globals: wat value type, plus the string/bool shapes.
    global_types: std.StringHashMap([]const u8),
    str_globals: std.StringHashMap(void),
    /// Names known to hold an `[len][e0][e1]…` array blob. `loop (xs) {…}`
    /// only walks the layout for these; anything else keeps the honest
    /// `;; loop over unknown iterable` no-op rather than reading garbage.
    arr_locals: std.StringHashMap(void),
    /// Local name → the `$__print_shaped_raw` shape of its value, when it is
    /// an array or a tuple (`printShapeOf`).
    print_shape_locals: std.StringHashMap([]const u8),
    arr_globals: std.StringHashMap(void),
    bool_globals: std.StringHashMap(void),
    /// Every emitted WAT function symbol → its signature.
    fn_sigs: std.StringHashMap(FnSig),
    /// Every emitted WAT global symbol. An identifier that is neither a local
    /// nor a known global lowers to a zero placeholder instead of a dangling
    /// `global.get`.
    globals: std.StringHashMap(void),
    case_depth: u32 = 0,
    try_seq: u32 = 0,
    /// Sequence counter for the `$__assert_{n}` local a `val assert` stages
    /// its subject in.
    assert_seq: u32 = 0,
    /// Sequence counter for the `$_res{n}` scratch pointers a Result/Option
    /// method op uses to hold its receiver (and, for `map`, the rewrapped
    /// result) while the tag/payload are read out.
    res_seq: u32 = 0,
    loop_seq: u32 = 0,
    /// The module path, for the `file:line` an `assert` failure names.
    module_name: []const u8 = "",
    /// The array local a comprehension's `yield`/`break <v>` appends to.
    yield_target: ?[]const u8 = null,
    /// Decision 8 §10 — the local a **search** loop's `break <v>` writes. A
    /// condition or infinite `loop` used as a value whose body has no `yield`
    /// has exactly one value to give, the one its `break` carries, so there is
    /// no accumulator: `break <v>` stores `v` here and ends the loop, and the
    /// loop answers this local (`0` when it never broke).
    search_target: ?[]const u8 = null,
    /// How many loops enclose the code being lowered: `break`/`continue`
    /// branch only inside one.
    loop_depth: u32 = 0,
    /// The `loop_depth` of the innermost condition loop (decision 8 §10) used
    /// as a value: there a `break <v>` contributes `v` and also ends the loop.
    cond_break_depth: ?u32 = null,
    /// Sequence counter for the `$__mem{n}` scratch pointers used when building
    /// or destructuring aggregates (tuples, arrays, records, enum payloads).
    mem_seq: u32 = 0,

    // ── type registry (codegen is untyped, so we recover record/enum layout
    //    from the declarations to lower construction/access by memory offset) ──
    /// record/struct name → ordered field names (slots are 4 bytes each).
    records: std.StringHashMap([]const []const u8),
    /// record/struct name → ordered field type-names (parallel to `records`).
    /// Used to chain-infer the type of `recv.a.b` (`a`'s declared type drives
    /// the lookup for `.b`). Empty/unknown types stay as `""`.
    record_field_types: std.StringHashMap([]const []const u8),
    /// enum name → variants (tag = declaration index; payload fields follow).
    enums: std.StringHashMap([]const ast.EnumVariant),
    /// Arena backing the slices stored in `records` (field-name strings alias
    /// the AST and are not copied).
    reg_arena: std.heap.ArenaAllocator,

    /// Local-variable name → record type when known (from `let x = Rec(...)`,
    /// a record-typed param, a destructuring pattern's field type, or a call to
    /// a fn whose return type is a record). Codegen is untyped so this map is a
    /// best-effort recovery, just enough to drive named-field access by offset.
    local_types: std.StringHashMap([]const u8),
    /// Record/struct name whose method body is currently being emitted. Drives
    /// `self.field` lookup. Null at top level.
    self_type: ?[]const u8 = null,
    /// Top-level fn name → declared return-type record name (`mk` → "E" given
    /// `fn mk() -> E {...}`). Powers `mk().n` field access.
    fn_return_types: std.StringHashMap([]const u8),

    data_segments: std.ArrayListUnmanaged(DataSeg) = .empty,
    next_data_offset: u32 = 256,
    /// Top-level `val`s whose initialiser is not a wasm constant expression
    /// (an array/tuple/record literal, a call, a concatenation…). A wasm
    /// `(global …)` may only be initialised by a constant, so these are
    /// declared as zeroed mutable globals and filled in by `$__init_globals`,
    /// which the module's `(start …)` runs before anything else. They used to
    /// stay at the `(i32.const 0)` placeholder, so every read saw 0.
    deferred_globals: std.ArrayListUnmanaged(ast.ValDecl) = .empty,

    /// Static extension dispatch (F6): call-site loc → activated extension symbol.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Value-receiver method calls (and `.length` reads), keyed by call /
    /// access loc: the receiver's primitive family or record type, recorded by
    /// inference. The one piece of type information this untyped backend is
    /// handed; `lowerPrimMethod` and `lowerRecordMethod` lower from it.
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering) = undefined,
    /// Element shape of names bound to an array blob (locals; cleared per fn)
    /// and of top-level `val`s. Drives `join`/`indexOf`/`contains` and the
    /// type of a HOF's element parameter.
    arr_elem_locals: std.StringHashMap(ElemKind),
    arr_elem_globals: std.StringHashMap(ElemKind),
    /// Element shape of the arrays top-level fns are declared to return.
    fn_arr_elem: std.StringHashMap(ElemKind),
    /// Lambdas lifted into functions, in table order — see `lowerLambdaValue`.
    lambdas: std.ArrayListUnmanaged(Lifted) = .empty,
    /// Local name → the lifted lambda a `val f = { … }` bound it to (cleared
    /// per fn). A call through the name threads the captures the lambda
    /// assigns (`lowerValueCall`) and recovers its parameters' shapes.
    closure_locals: std.StringHashMap(u32),
    /// Inside a lifted lambda: a captured name the body assigns → its slot in
    /// the environment cell, written back after every assignment (cleared per
    /// fn).
    env_slots: std.StringHashMap(u32),
    /// While `isStringExpr` judges a lifted lambda's body for one call: the
    /// lambda's parameters and whether that call's argument is a string.
    param_shape: ?ParamShape = null,
    /// Some `call_indirect` was emitted: the module needs a table even when it
    /// lifted no lambda of its own (a function value that came in as a
    /// parameter).
    uses_table: bool = false,
    /// Top-level fn name → the table slot of its trampoline, for a fn used as
    /// a value.
    fn_refs: std.StringHashMap(u32),
    /// Interface associated `default fn`s (`Pair.of`), by WAT symbol
    /// (`Pair_of`), and the ones some call reached (emitted by
    /// `emitPendingFns`).
    iface_assoc: std.StringHashMap(ast.BehaviorMethod),
    /// Bodyless `declare fn`s — host-backed (`#[@External.<Target>(…)]`). wasm
    /// has no host to bind them to; a call traps (see `lowerPlainCall`).
    host_fns: std.StringHashMap(void),
    assoc_needed: std.ArrayListUnmanaged([]const u8) = .empty,
    assoc_emitted: std.StringHashMap(void),
    /// Extension block name → target type + methods (for resolving the mangled
    /// `$<target>_<method>` callee at activated and qualified dispatch sites).
    ext_by_name: std.StringHashMap(ExtInfo),
    /// Scratch space for the mangled callee symbol of a dispatch site. Only
    /// ever used for an immediate `fn_sigs` lookup.
    sym_buf: [256]u8 = undefined,

    const ExtInfo = struct { target: []const u8, methods: []const ast.ImplementMethod };

    fn init(alloc: std.mem.Allocator, cv: std.StringHashMap([]const u8), rewrites: std.AutoHashMap(ast.Loc, []const u8)) Emitter {
        const em: Emitter = .{
            .alloc = alloc,
            .cv = cv,
            .locals = std.StringHashMap([]const u8).init(alloc),
            .str_locals = std.StringHashMap(void).init(alloc),
            .bool_locals = std.StringHashMap(void).init(alloc),
            .str_fns = std.StringHashMap(void).init(alloc),
            .result_str_fns = std.StringHashMap(void).init(alloc),
            .result_shape_fns = std.StringHashMap(ResultShape).init(alloc),
            .result_shape_locals = std.StringHashMap(ResultShape).init(alloc),
            .result_subjects = std.StringHashMap(ResultShape).init(alloc),
            .global_rec_types = std.StringHashMap([]const u8).init(alloc),
            .folded_globals = std.StringHashMap([]const u8).init(alloc),
            .fn_ret_typerefs = std.StringHashMap(ast.TypeRef).init(alloc),
            .opt_locals = std.StringHashMap(OptInfo).init(alloc),
            .fn_param_typerefs = std.StringHashMap([]const ast.TypeRef).init(alloc),
            .local_typerefs = std.StringHashMap(ast.TypeRef).init(alloc),
            .global_typerefs = std.StringHashMap(ast.TypeRef).init(alloc),
            .record_field_typerefs = std.StringHashMap([]const ast.TypeRef).init(alloc),
            .bool_fns = std.StringHashMap(void).init(alloc),
            .global_types = std.StringHashMap([]const u8).init(alloc),
            .str_globals = std.StringHashMap(void).init(alloc),
            .arr_locals = std.StringHashMap(void).init(alloc),
            .print_shape_locals = std.StringHashMap([]const u8).init(alloc),
            .arr_globals = std.StringHashMap(void).init(alloc),
            .bool_globals = std.StringHashMap(void).init(alloc),
            .fn_sigs = std.StringHashMap(FnSig).init(alloc),
            .globals = std.StringHashMap(void).init(alloc),
            .records = std.StringHashMap([]const []const u8).init(alloc),
            .record_field_types = std.StringHashMap([]const []const u8).init(alloc),
            .enums = std.StringHashMap([]const ast.EnumVariant).init(alloc),
            .reg_arena = std.heap.ArenaAllocator.init(alloc),
            .local_types = std.StringHashMap([]const u8).init(alloc),
            .fn_return_types = std.StringHashMap([]const u8).init(alloc),
            .rewrites = rewrites,
            .ext_by_name = std.StringHashMap(ExtInfo).init(alloc),
            .arr_elem_locals = std.StringHashMap(ElemKind).init(alloc),
            .arr_elem_globals = std.StringHashMap(ElemKind).init(alloc),
            .fn_arr_elem = std.StringHashMap(ElemKind).init(alloc),
            .fn_refs = std.StringHashMap(u32).init(alloc),
            .iface_assoc = std.StringHashMap(ast.BehaviorMethod).init(alloc),
            .host_fns = std.StringHashMap(void).init(alloc),
            .aliases = std.StringHashMap([]const u8).init(alloc),
            .pattern_locals = std.StringHashMap(void).init(alloc),
            .assoc_emitted = std.StringHashMap(void).init(alloc),
            .closure_locals = std.StringHashMap(u32).init(alloc),
            .env_slots = std.StringHashMap(u32).init(alloc),
        };
        return em;
    }

    /// The arena every built node (and every string a node borrows) comes from.
    /// It outlives the frames that build the tree and dies with the emitter,
    /// after the module has been rendered.
    fn arena(self: *Emitter) std.mem.Allocator {
        return self.reg_arena.allocator();
    }

    /// The node factory. The arena is re-bound on every use because
    /// `std.heap.ArenaAllocator.allocator()` closes over the arena's *address*,
    /// which is only final once the emitter has stopped moving.
    fn builder(self: *Emitter) *wat.Builder {
        self.b.arena = self.reg_arena.allocator();
        return &self.b;
    }

    fn deinit(self: *Emitter) void {
        self.locals.deinit();
        self.pending_locals.deinit(self.alloc);
        self.str_locals.deinit();
        self.bool_locals.deinit();
        self.str_fns.deinit();
        self.result_str_fns.deinit();
        self.result_shape_fns.deinit();
        self.result_shape_locals.deinit();
        self.result_subjects.deinit();
        self.global_rec_types.deinit();
        self.folded_globals.deinit();
        self.fn_ret_typerefs.deinit();
        self.opt_locals.deinit();
        self.fn_param_typerefs.deinit();
        self.local_typerefs.deinit();
        self.global_typerefs.deinit();
        self.record_field_typerefs.deinit();
        self.bool_fns.deinit();
        self.global_types.deinit();
        self.str_globals.deinit();
        self.arr_locals.deinit();
        self.print_shape_locals.deinit();
        self.arr_globals.deinit();
        self.bool_globals.deinit();
        self.fn_sigs.deinit();
        self.globals.deinit();
        self.records.deinit();
        self.record_field_types.deinit();
        self.enums.deinit();
        self.local_types.deinit();
        self.fn_return_types.deinit();
        self.reg_arena.deinit();
        self.data_segments.deinit(self.alloc);
        self.deferred_globals.deinit(self.alloc);
        self.ext_by_name.deinit();
        self.arr_elem_locals.deinit();
        self.arr_elem_globals.deinit();
        self.fn_arr_elem.deinit();
        self.lambdas.deinit(self.alloc);
        self.fn_refs.deinit();
        self.iface_assoc.deinit();
        self.host_fns.deinit();
        self.aliases.deinit();
        self.pattern_locals.deinit();
        self.assoc_needed.deinit(self.alloc);
        self.assoc_emitted.deinit();
        self.closure_locals.deinit();
        self.env_slots.deinit();
    }

    /// Lower one top-level declaration into module items.
    fn emitDecl(self: *Emitter, decl: ast.DeclKind) !void {
        switch (decl) {
            .@"fn" => |f| if (!f.isHost()) try self.emitFn(f),
            .val => |v| {
                if (!isSyntheticEntrypointVal(v)) try self.emitGlobalVal(v);
            },
            .comment => |c| try self.itemComment(c.text),
            // Extension methods lower to linear-memory functions named
            // `$<target>_<method>` so activated/qualified dispatch can `call` them.
            .implement => |im| try self.emitExtensionMethods(im.target, im.methods),
            .extend => |ex| try self.emitExtensionMethods(ex.target, ex.methods),
            // Record / struct methods piggy-back on the same emission machinery as
            // extension methods (same `$<target>_<method>` mangling); `self` is the
            // record pointer + a method body's `self.field` walks the declared
            // layout via `self_type`.
            .type_ => |r| if (r.isRecord()) try self.emitInterfaceMethods(r.name, r.methods),
            // An import is linked statically: `emitWat` has already put the
            // owner's declarations in front of this module's.
            .use, .behavior, .delegate, .mod, .@"test" => {},
        }
    }

    /// Pre-pass: record every symbol this module will define — function
    /// signatures (already mangled for extension/record methods) and globals.
    /// Lowering consults these so a `call`/`global.get` is never emitted for a
    /// name the module does not define (wasmtime rejects the whole module on
    /// the first such reference) and so arguments can be coerced to the
    /// declared parameter types.
    fn registerSymbols(self: *Emitter, program: ast.Program, emit_globals: bool) !void {
        const ra = self.reg_arena.allocator();
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (f.isHost() or f.isDeclare or f.body.len == 0) {
                    try self.host_fns.put(f.name, {});
                    continue;
                }
                const has_result = fnHasResult(f);
                var params: std.ArrayListUnmanaged([]const u8) = .empty;
                var ptrefs: std.ArrayListUnmanaged(ast.TypeRef) = .empty;
                for (f.params) |p| {
                    if (std.mem.eql(u8, p.name, "self")) continue;
                    try params.append(ra, watType(p.typeRef));
                    try ptrefs.append(ra, p.typeRef);
                }
                try self.fn_param_typerefs.put(f.name, ptrefs.items);
                try self.fn_sigs.put(f.name, .{
                    .params = try params.toOwnedSlice(ra),
                    .result = if (has_result) watTypeOpt(f.returnType) else null,
                });
                if (f.returnType != null and f.typeGuardParam == null) {
                    const rt = f.returnType.?;
                    if (isStringTypeRef(rt)) try self.str_fns.put(f.name, {});
                    if (isBoolTypeRef(rt)) try self.bool_fns.put(f.name, {});
                    if (arrayElemOfTypeRef(rt)) |ek| try self.fn_arr_elem.put(f.name, ek);
                    if (resultOfString(rt)) try self.result_str_fns.put(f.name, {});
                    if (resultShapeOfTypeRef(rt)) |shape| try self.result_shape_fns.put(f.name, shape);
                    try self.fn_ret_typerefs.put(f.name, rt);
                } else if (f.returnType == null and self.bodyReturnsString(f.body)) {
                    // The specialisation pass clears the return type of the
                    // fns it injects; a body that returns a string still does.
                    try self.str_fns.put(f.name, {});
                }
                // `fn isPositive(n: i32) -> n is i32` answers a bool.
                if (f.typeGuardParam != null) try self.bool_fns.put(f.name, {});
            },
            .val => |v| if (emit_globals and !isSyntheticEntrypointVal(v)) {
                try self.globals.put(v.name, {});
                try self.global_types.put(v.name, self.globalValType(v));
                if (v.typeAnnotation) |ta| {
                    if (isStringTypeRef(ta)) try self.str_globals.put(v.name, {});
                    if (isBoolTypeRef(ta)) try self.bool_globals.put(v.name, {});
                } else if (self.folded_globals.get(v.name)) |text| {
                    if (quotedString(text) != null) try self.str_globals.put(v.name, {});
                    if (std.mem.eql(u8, text, "true") or std.mem.eql(u8, text, "false")) try self.bool_globals.put(v.name, {});
                } else {
                    // A template expansion or a concatenation is a string as
                    // much as a literal is.
                    if (self.isStringExpr(v.value.*)) try self.str_globals.put(v.name, {});
                    if (self.isBoolExpr(v.value.*)) try self.bool_globals.put(v.name, {});
                }
                if (self.recordTypeOfExpr(v.value.*)) |rty| try self.global_rec_types.put(v.name, rty);
                if (v.typeAnnotation orelse self.typeRefOf(v.value.*)) |tr| try self.global_typerefs.put(v.name, tr);
                if (self.isArrayExpr(v.value.*)) {
                    try self.arr_globals.put(v.name, {});
                    try self.arr_elem_globals.put(v.name, self.elemKindOf(v.value.*));
                }
                if (v.typeAnnotation) |ta| if (arrayElemOfTypeRef(ta)) |ek| {
                    try self.arr_globals.put(v.name, {});
                    try self.arr_elem_globals.put(v.name, ek);
                };
            },
            .implement => |im| try self.registerMethodSigs(im.target, im.methods),
            .extend => |ex| try self.registerMethodSigs(ex.target, ex.methods),
            .type_ => |r| if (r.isRecord()) try self.registerInterfaceSigs(r.name, r.methods),
            .behavior => |i| for (i.methods) |m| {
                const body = m.body orelse continue;
                if (!m.is_default or m.is_declare or m.isExternal() or m.isHost()) continue;
                if (m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self")) continue;
                const sym = try std.fmt.allocPrint(ra, "{s}_{s}", .{ i.name, m.name });
                if (self.fn_sigs.contains(sym)) continue;
                const params = try ra.alloc([]const u8, m.params.len);
                for (m.params, 0..) |p, k| params[k] = watType(p.typeRef);
                try self.fn_sigs.put(sym, .{
                    .params = params,
                    .result = if (m.returnType != null or methodHasResult(body)) watTypeOpt(m.returnType) else null,
                });
                if (m.returnType) |rt| {
                    if (isStringTypeRef(rt)) try self.str_fns.put(sym, {});
                    if (isBoolTypeRef(rt)) try self.bool_fns.put(sym, {});
                }
                try self.iface_assoc.put(sym, m);
            },
            else => {},
        };
    }

    fn registerMethodSigs(self: *Emitter, target: []const u8, methods: []const ast.ImplementMethod) !void {
        const ra = self.reg_arena.allocator();
        for (methods) |m| {
            const qualifier = m.qualifier orelse target;
            const sym = try std.fmt.allocPrint(ra, "{s}_{s}", .{ qualifier, m.name });
            const params = try ra.alloc([]const u8, m.params.len);
            for (params) |*t| t.* = "i32";
            try self.fn_sigs.put(sym, .{
                .params = params,
                .result = if (methodHasResult(m.body)) "i32" else null,
            });
        }
    }

    fn registerInterfaceSigs(self: *Emitter, owner: []const u8, methods: []const ast.BehaviorMethod) !void {
        const ra = self.reg_arena.allocator();
        for (methods) |m| {
            const body = m.body orelse continue;
            if (m.is_declare or m.isExternal() or m.isHost()) continue;
            const sym = try std.fmt.allocPrint(ra, "{s}_{s}", .{ owner, m.name });
            var has_self_param = false;
            for (m.params) |p| {
                if (std.mem.eql(u8, p.name, "self")) has_self_param = true;
            }
            const needs_self = !has_self_param and bodyReferencesSelf(body);
            const n = m.params.len + @as(usize, if (needs_self) 1 else 0);
            const params = try ra.alloc([]const u8, n);
            for (params) |*t| t.* = "i32";
            try self.fn_sigs.put(sym, .{
                .params = params,
                .result = if (m.returnType != null or methodHasResult(body)) "i32" else null,
            });
            // A method's declared return type, under the symbol the call
            // emits. `typeRefOf` asks for it so the *reader* of a `?T` agrees
            // with the writer: `Dict.lookup` answers `?V`, which is unboxed
            // here (a type parameter is not a known scalar), and without this
            // the reader assumed a box and loaded through the payload as if it
            // were an address — `d.lookup("a").unwrapOr(0)` answered `0` for a
            // key that is present, exit 0, no diagnostic.
            // The same registration the top-level `fn` arm makes, for the same
            // reason: `@print` picks its printer from the recovered shape, and a
            // method's shape was never recorded — so a method returning a
            // `string`, a `bool` or an array was printed through
            // `$__print_i32`, which writes a **pointer** (`276` for `"doc:hi"`,
            // `444` for `["a", "b"]`) or `0`/`1` for a bool.
            if (m.returnType) |rt| {
                try self.fn_ret_typerefs.put(sym, rt);
                if (isStringTypeRef(rt)) try self.str_fns.put(sym, {});
                if (isBoolTypeRef(rt)) try self.bool_fns.put(sym, {});
                if (arrayElemOfTypeRef(rt)) |ek| try self.fn_arr_elem.put(sym, ek);
            }
        }
    }

    fn collectExtensions(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .implement => |im| try self.ext_by_name.put(im.name, .{ .target = im.target, .methods = im.methods }),
            .extend => |ex| try self.ext_by_name.put(ex.name, .{ .target = ex.target, .methods = ex.methods }),
            else => {},
        };
    }

    /// Mangled `$<target>_<method>` name for a dispatch site (without the `$`),
    /// written into `buf`. `sym` is the extension block name; the qualifier
    /// defaults to the target type (matching `emitExtensionMethods`).
    fn extMangledName(self: *Emitter, buf: []u8, sym: []const u8, method: []const u8) ?[]const u8 {
        const info = self.ext_by_name.get(sym) orelse return null;
        var qualifier = info.target;
        for (info.methods) |m| {
            if (std.mem.eql(u8, m.name, method)) {
                qualifier = m.qualifier orelse info.target;
                break;
            }
        }
        return std.fmt.bufPrint(buf, "{s}_{s}", .{ qualifier, method }) catch null;
    }

    /// Populate `records`/`enums` from the program's type declarations so that
    /// construction calls can be distinguished from ordinary function calls.
    fn registerTypes(self: *Emitter, program: ast.Program) !void {
        const ra = self.reg_arena.allocator();
        for (program.decls) |decl| switch (decl) {
            .type_ => |tdecl| switch (tdecl.shape) {
                .record => {
                    for (tdecl.methods) |m| if (m.returnType) |rt| {
                        const tn = typeRefName(rt);
                        if (tn.len > 0) try self.fn_return_types.put(try std.fmt.allocPrint(ra, "{s}_{s}", .{ tdecl.name, m.name }), if (std.mem.eql(u8, tn, "Self")) tdecl.name else tn);
                    };
                    const names = try ra.alloc([]const u8, tdecl.recordFields().len);
                    const types = try ra.alloc([]const u8, tdecl.recordFields().len);
                    const trefs = try ra.alloc(ast.TypeRef, tdecl.recordFields().len);
                    for (tdecl.recordFields(), 0..) |f, i| {
                        names[i] = f.name;
                        types[i] = typeRefName(f.typeRef);
                        trefs[i] = f.typeRef;
                    }
                    try self.record_field_typerefs.put(tdecl.name, trefs);
                    try self.records.put(tdecl.name, names);
                    try self.record_field_types.put(tdecl.name, types);
                },
                .enum_ => try self.enums.put(tdecl.name, tdecl.variants()),
            },
            .@"fn" => |f| {
                if (f.returnType) |rt| {
                    const tn = typeRefName(rt);
                    if (tn.len > 0) try self.fn_return_types.put(f.name, tn);
                }
            },
            else => {},
        };
    }

    /// Bare type-name behind a `TypeRef`, stripping `?T` and generic args.
    /// Returns `""` for shapes we can't reduce (fn types, tuples, etc.).
    fn typeRefName(t: ast.TypeRef) []const u8 {
        return switch (t) {
            .named => |n| n,
            .optional => |inner| typeRefName(inner.*),
            .generic => |g| g.name,
            else => "",
        };
    }

    /// Resolves `Self` to the current `self_type` and rejects empty names.
    fn resolveRecordName(self: *Emitter, tn: []const u8) ?[]const u8 {
        if (tn.len == 0) return null;
        const name = if (std.mem.eql(u8, tn, "Self")) (self.self_type orelse return null) else tn;
        if (self.records.contains(name)) return name;
        return null;
    }

    /// Field offset in bytes (4 bytes per slot, declaration order). Null when
    /// `record` or `field` is unknown.
    fn fieldOffsetIn(self: *Emitter, record: []const u8, field: []const u8) ?u32 {
        const fields = self.records.get(record) orelse return null;
        for (fields, 0..) |fn_, i| {
            if (std.mem.eql(u8, fn_, field)) return @intCast(i * 4);
        }
        return null;
    }

    /// Declared type-name of `field` inside `record`, when both are known.
    fn fieldTypeIn(self: *Emitter, record: []const u8, field: []const u8) ?[]const u8 {
        const fields = self.records.get(record) orelse return null;
        const types = self.record_field_types.get(record) orelse return null;
        for (fields, 0..) |fn_, i| {
            if (std.mem.eql(u8, fn_, field)) {
                if (i >= types.len) return null;
                const tn = types[i];
                return if (tn.len == 0) null else tn;
            }
        }
        return null;
    }

    /// Best-effort record-type name for an expression — drives `recv.field`
    /// offset lookup. Recovers from common shapes: `self`, locals bound to a
    /// record_ctor or a known-record-returning fn call, chained `recv.a.b`
    /// where `a`'s declared field type is itself a record, **and anonymous
    /// `record { ... }` literals via lazy synthetic registration** (F1 tail —
    /// every anon literal in source maps to a unique `__anon_L{line}_C{col}`
    /// entry in `records`/`record_field_types`, registered on first sight).
    fn recordTypeOfExpr(self: *Emitter, e: ast.Expr) ?[]const u8 {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |name0| blk: {
                    const name = self.resolveName(name0);
                    if (std.mem.eql(u8, name, "self")) {
                        const st = self.self_type orelse break :blk null;
                        break :blk self.resolveRecordName(st);
                    }
                    const tn = self.local_types.get(name) orelse
                        (if (self.locals.contains(name)) null else self.global_rec_types.get(name)) orelse break :blk null;
                    break :blk self.resolveRecordName(tn);
                },
                .identAccess => |ia| blk: {
                    const recv_ty = self.recordTypeOfExpr(ia.receiver.*) orelse break :blk null;
                    const field_ty = self.fieldTypeIn(recv_ty, ia.member) orelse break :blk null;
                    break :blk self.resolveRecordName(field_ty);
                },
                else => null,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    switch (self.callKind(cc)) {
                        .record_ctor => break :blk self.resolveRecordName(cc.callee),
                        .plain => {
                            const key = self.assocSym(cc) orelse cc.callee;
                            const tn = self.fn_return_types.get(key) orelse break :blk null;
                            break :blk self.resolveRecordName(tn);
                        },
                        else => break :blk null,
                    }
                },
                else => null,
            },
            .collection => |c| switch (c.kind) {
                .behaviorLit => |il| self.ensureAnonRecord(c.loc, .{ .fields = il.fields }) catch null,
                .grouped => |inner| self.recordTypeOfExpr(inner.*),
                else => null,
            },
            else => null,
        };
    }

    /// Decision 8 §7's two rows this front cannot close: a value whose printed
    /// text is its **type's name** — `Point(x: 1, y: 2)` (F2) and
    /// `Shape.Square(side: 4)` (F3). Both need a value that knows which named
    /// type it is at run time, which is `13-module-identity`'s subject; until
    /// then `@print` has no text to write for one.
    const NamedShape = enum { record, variant };

    /// Which of the two `e` is, or null. An array or a tuple **literal** whose
    /// elements are ones counts: `@print([Point(x: 1, y: 2)])` printed
    /// `[256,264]`, addresses inside a container, the same wrong answer one
    /// bracket deeper. Not covered, and recorded in `wat/AGENTS.md`: a local
    /// bound to such a container (the element shapes tracked for a local are
    /// `i32`/`f32`/`str`, and a record is an `i32` slot like any pointer), and a
    /// record read out of one.
    fn namedShapeOf(self: *Emitter, e: ast.Expr) ?NamedShape {
        if (self.recordTypeOfExpr(e)) |_| return .record;
        switch (e) {
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.namedShapeOf(inner.*),
                .arrayLit => |al| {
                    for (al.elems) |el| if (self.namedShapeOf(el)) |ns| return ns;
                    return null;
                },
                .tupleLit => |tl| {
                    for (tl.elems) |el| if (self.namedShapeOf(el)) |ns| return ns;
                    return null;
                },
                else => return null,
            },
            // `Shape.Square(side: 4)`, and the bare `Square(side: 4)` whose
            // name uniquely finds a payload-bearing variant.
            .call => |c| switch (c.kind) {
                .call => |cc| return if (self.callKind(cc) == .enum_ctor) .variant else null,
                else => return null,
            },
            // `Shape.Nothing` — a unit variant, read as a qualified member.
            .identifier => |id| switch (id.kind) {
                .identAccess => |ia| {
                    const ename = switch (ia.receiver.*) {
                        .identifier => |rid| switch (rid.kind) {
                            .ident => |n| n,
                            else => return null,
                        },
                        else => return null,
                    };
                    const variants = self.enums.get(ename) orelse return null;
                    for (variants) |v| if (std.mem.eql(u8, v.name, ia.member)) return .variant;
                    return null;
                },
                else => return null,
            },
            else => return null,
        }
    }

    /// Register a behavior literal's fields under a synthetic name
    /// `__anon_L{line}_C{col}` so `recordTypeOfExpr` + `fieldOffsetIn` can
    /// resolve field reads against it. Idempotent: subsequent encounters of
    /// the same literal return the existing entry. Field-type recovery for
    /// nested anon records currently bottoms out (`record { span: record {…} }`
    /// — the outer field's type-name slot stays empty); chained `recv.a.b`
    /// against a nested anon stops at the first hop, matching the plain
    /// `i32.const 0` stub the historic path already produced.
    fn ensureAnonRecord(self: *Emitter, loc: ast.Loc, rl: anytype) ![]const u8 {
        const ra = self.reg_arena.allocator();
        const name = try std.fmt.allocPrint(ra, "__anon_L{d}_C{d}", .{ loc.line, loc.col });
        if (self.records.contains(name)) return name;
        const names = try ra.alloc([]const u8, rl.fields.len);
        const types = try ra.alloc([]const u8, rl.fields.len);
        for (rl.fields, 0..) |f, i| {
            names[i] = f.name;
            // Field type recovery from the value's shape; empty when unknown —
            // the chained-recovery handles those via `recordTypeOfExpr`.
            types[i] = blk: {
                if (self.isStringExpr(f.value.*)) break :blk "string";
                if (self.isBoolExpr(f.value.*)) break :blk "bool";
                if (self.wasmTypeOf(f.value.*)[0] == 'f') break :blk "f64";
                break :blk "";
            };
        }
        try self.records.put(name, names);
        try self.record_field_types.put(name, types);
        return name;
    }

    // ── node emission ────────────────────────────────────────────────────
    //
    // Lowering appends `Line`s to the open sequence; `wat_emitter.zig` is the
    // only thing that turns one into text. The default column is the function
    // body's; `emitAt` is for the few constructs whose arms the historical
    // layout indents further.

    fn emit(self: *Emitter, instr: Instr) !void {
        try self.cur.?.append(self.arena(), .{ .instr = instr });
    }

    /// An instruction with a trailing `;; comment`.
    fn emitC(self: *Emitter, instr: Instr, comment: []const u8) !void {
        try self.cur.?.append(self.arena(), .{ .instr = instr, .comment = comment });
    }

    fn emitCf(self: *Emitter, instr: Instr, comptime f: []const u8, args: anytype) !void {
        try self.emitC(instr, try std.fmt.allocPrint(self.arena(), f, args));
    }

    fn emitAt(self: *Emitter, indent: u8, instr: Instr) !void {
        try self.cur.?.append(self.arena(), .{ .instr = instr, .indent = indent });
    }

    fn emitAtC(self: *Emitter, indent: u8, instr: Instr, comment: []const u8) !void {
        try self.cur.?.append(self.arena(), .{
            .instr = instr,
            .indent = indent,
            .comment = comment,
        });
    }

    fn emitAtCf(self: *Emitter, indent: u8, instr: Instr, comptime f: []const u8, args: anytype) !void {
        try self.emitAtC(indent, instr, try std.fmt.allocPrint(self.arena(), f, args));
    }

    /// A `;; text` line of its own, inside a body — a construct with no wasm
    /// lowering, recorded rather than silently dropped.
    fn note(self: *Emitter, text: []const u8) !void {
        try self.emit(.{ .comment = text });
    }

    fn noteF(self: *Emitter, comptime f: []const u8, args: anytype) !void {
        try self.note(try std.fmt.allocPrint(self.arena(), f, args));
    }

    /// Append a top-level form.
    fn item(self: *Emitter, it: Item) !void {
        try self.items.append(self.arena(), it);
    }

    /// A `;; text` line between top-level forms.
    fn itemComment(self: *Emitter, text: []const u8) !void {
        try self.item(.{ .comment = text });
    }

    fn itemCommentF(self: *Emitter, comptime f: []const u8, args: anytype) !void {
        try self.itemComment(try std.fmt.allocPrint(self.arena(), f, args));
    }

    /// Redirect lowering into `c` until `seal`.
    fn open(self: *Emitter, c: *Capture) void {
        c.saved = self.cur;
        self.cur = &c.lines;
    }

    /// Close `c` and hand back the sequence, tagged with what it leaves on the
    /// operand stack. Every consumer of a `Seq` checks that tag against what it
    /// can accept, which is what makes "a value left behind by a void function"
    /// unrepresentable rather than merely unlikely.
    fn seal(self: *Emitter, c: *Capture, stack: wat.Stack) Seq {
        self.cur = c.saved;
        return .{ .lines = c.lines.items, .stack = stack };
    }

    /// The `wat_ast.Stack` a lowered `Tail` stands for. `.value` carries the
    /// type the context coerced the expression to.
    fn stackOf(tail: Tail, ty: []const u8) wat.Stack {
        return switch (tail) {
            .value => .{ .value = vt(ty) },
            .none => .none,
            .terminated => .terminated,
        };
    }

    fn resetFnState(self: *Emitter, result_type: ?[]const u8) void {
        self.locals.clearRetainingCapacity();
        self.local_types.clearRetainingCapacity();
        self.str_locals.clearRetainingCapacity();
        self.arr_locals.clearRetainingCapacity();
        self.print_shape_locals.clearRetainingCapacity();
        self.arr_elem_locals.clearRetainingCapacity();
        self.result_shape_locals.clearRetainingCapacity();
        self.result_subjects.clearRetainingCapacity();
        self.aliases.clearRetainingCapacity();
        self.pattern_locals.clearRetainingCapacity();
        self.local_typerefs.clearRetainingCapacity();
        self.opt_locals.clearRetainingCapacity();
        self.cur_ret_typeref = null;
        self.bool_locals.clearRetainingCapacity();
        self.closure_locals.clearRetainingCapacity();
        self.env_slots.clearRetainingCapacity();
        self.pending_locals.clearRetainingCapacity();
        self.cur_result = result_type orelse "i32";
        self.fn_has_result = result_type != null;
        self.fn_returns_result = false;
        self.case_depth = 0;
        self.try_seq = 0;
        self.assert_seq = 0;
        self.mem_seq = 0;
        self.res_seq = 0;
        self.loop_seq = 0;
        self.yield_target = null;
        self.loop_depth = 0;
    }

    /// Register a local for the current function. Idempotent, and the *only*
    /// way a `(local …)` reaches the output: the declaration goes into the
    /// function node, which is the one place WAT accepts it.
    fn declareLocal(self: *Emitter, name: []const u8, ty: []const u8) !void {
        if (self.locals.contains(name)) return;
        try self.locals.put(name, ty);
        try self.pending_locals.append(self.alloc, .{ .name = name, .ty = ty });
    }

    /// The `(local …)` lines of the function being emitted: one declaration per
    /// line, in registration order.
    fn localLines(self: *Emitter) ![]const []const wat.Local {
        const ar = self.arena();
        const lines = try ar.alloc([]const wat.Local, self.pending_locals.items.len);
        for (self.pending_locals.items, 0..) |l, i| {
            const slot = try ar.alloc(wat.Local, 1);
            slot[0] = .{ .name = l.name, .ty = vt(l.ty) };
            lines[i] = slot;
        }
        return lines;
    }

    /// `$__mem{k}` — the scratch pointer an aggregate construction or a
    /// destructuring binding holds its base in.
    fn memName(self: *Emitter, k: u32) ![]const u8 {
        return std.fmt.allocPrint(self.arena(), "__mem{d}", .{k});
    }

    /// `$_res{k}` — the scratch pointer a Result/Option op holds its receiver in.
    fn resName(self: *Emitter, k: u32) ![]const u8 {
        return std.fmt.allocPrint(self.arena(), "_res{d}", .{k});
    }

    /// `$_try{k}` — the scratch pointer a `try`/`try…catch` holds its Result in.
    fn tryName(self: *Emitter, k: u32) ![]const u8 {
        return std.fmt.allocPrint(self.arena(), "_try{d}", .{k});
    }

    /// Push `{cur_result}.const 0` — the neutral value used whenever a context
    /// demands a value the lowered expression did not produce.
    fn pushZero(self: *Emitter) !void {
        try self.emit(constOf(self.cur_result, "0"));
    }

    /// `i32.const <n>` for a computed number: a data-segment offset, a variant
    /// tag, a byte count.
    fn constInt(self: *Emitter, value: anytype) !Instr {
        return .{ .@"const" = .{
            .ty = .i32,
            .text = try std.fmt.allocPrint(self.arena(), "{d}", .{value}),
        } };
    }

    /// The bytes a string literal stands for. The lexer keeps a literal's
    /// escape sequences verbatim (`q\"t`); a data segment holds the value
    /// (`q"t`), so `@print` writes the same bytes as commonJS and erlang.
    /// `\n \r \t \0 \\ \"` map to their byte, `\$` to `$`, `\u{hex}` to UTF-8.
    fn literalBytes(self: *Emitter, lexeme: []const u8) ![]const u8 {
        if (std.mem.indexOfScalar(u8, lexeme, '\\') == null) return lexeme;
        var out: std.ArrayListUnmanaged(u8) = .empty;
        var i: usize = 0;
        while (i < lexeme.len) : (i += 1) {
            const ch = lexeme[i];
            if (ch != '\\' or i + 1 >= lexeme.len) {
                try out.append(self.arena(), ch);
                continue;
            }
            i += 1;
            switch (lexeme[i]) {
                'n' => try out.append(self.arena(), '\n'),
                'r' => try out.append(self.arena(), '\r'),
                't' => try out.append(self.arena(), '\t'),
                '0' => try out.append(self.arena(), 0),
                'u' => if (i + 1 < lexeme.len and lexeme[i + 1] == '{') {
                    const close = std.mem.indexOfScalarPos(u8, lexeme, i + 2, '}') orelse {
                        try out.appendSlice(self.arena(), "\\u");
                        continue;
                    };
                    const cp = std.fmt.parseInt(u21, lexeme[i + 2 .. close], 16) catch {
                        try out.appendSlice(self.arena(), "\\u");
                        continue;
                    };
                    var buf: [4]u8 = undefined;
                    const n = std.unicode.utf8Encode(cp, &buf) catch {
                        try out.appendSlice(self.arena(), "\\u");
                        continue;
                    };
                    try out.appendSlice(self.arena(), buf[0..n]);
                    i = close;
                } else try out.appendSlice(self.arena(), "\\u"),
                else => |esc| try out.append(self.arena(), esc),
            }
        }
        return out.items;
    }

    fn internString(self: *Emitter, s: []const u8) !DataSeg {
        for (self.data_segments.items) |seg| {
            if (seg.len == s.len and std.mem.eql(u8, seg.content, s)) return seg;
        }
        // Strings are length-prefixed: the value is a pointer to a 4-byte i32
        // length word, immediately followed by the raw bytes (at `offset + 4`).
        // This lets `.len`/`.slice` and concat operate on runtime strings without
        // carrying the length in a separate register.
        const seg = DataSeg{
            .offset = self.next_data_offset,
            .len = @intCast(s.len),
            .content = s,
        };
        self.next_data_offset += 4 + @as(u32, @intCast(s.len));
        if (self.next_data_offset % 4 != 0)
            self.next_data_offset += 4 - (self.next_data_offset % 4);
        try self.data_segments.append(self.alloc, seg);
        return seg;
    }

    // ── fn ───────────────────────────────────────────────────────────────────

    /// Synthetic name for a parameter the source did not name (a destructuring
    /// param such as `fn greet({ name, .. }: Person)`). Emitting `(param $ i32)`
    /// is a WAT parse error ("empty identifier").
    fn paramSymbol(self: *Emitter, p: ast.Param, idx: usize) ![]const u8 {
        if (p.name.len > 0) return p.name;
        return std.fmt.allocPrint(self.reg_arena.allocator(), "__p{d}", .{idx});
    }

    /// Bind a destructuring parameter's field names to locals at function
    /// entry: the parameter holds a pointer to a run of 4-byte slots, so each
    /// bound name is an `i32.load` at the field's declared offset.
    fn bindParamDestructure(self: *Emitter, p: ast.Param, symbol: []const u8) !void {
        const d = p.destruct orelse return;
        const rty = self.resolveRecordName(typeRefName(p.typeRef));
        switch (d) {
            .names => |n| for (n.fields, 0..) |fld, i| {
                try self.declareLocal(fld.bind_name, "i32");
                const off: u32 = if (rty) |r|
                    (self.fieldOffsetIn(r, fld.field_name) orelse @as(u32, @intCast(i * 4)))
                else
                    @as(u32, @intCast(i * 4));
                if (rty) |r| {
                    if (self.fieldTypeIn(r, fld.field_name)) |ft| {
                        if (self.resolveRecordName(ft)) |sub| try self.local_types.put(fld.bind_name, sub);
                        if (std.mem.eql(u8, ft, "string")) try self.str_locals.put(fld.bind_name, {});
                    }
                }
                try self.emit(.{ .local_get = symbol });
                try self.emitLoadOffset(off);
                try self.emit(.{ .local_set = fld.bind_name });
            },
            .tuple_ => |names| for (names, 0..) |name, i| {
                try self.declareLocal(name, "i32");
                try self.emit(.{ .local_get = symbol });
                try self.emitLoadOffset(@intCast(i * 4));
                try self.emit(.{ .local_set = name });
            },
            else => try self.note("unsupported param destructure pattern"),
        }
    }

    /// Declare the pre-counted `$_try{n}` / `$__mem{n}` scratch pointers.
    fn declareScratch(self: *Emitter, prefix: []const u8, n: u32) !void {
        const ra = self.reg_arena.allocator();
        for (0..n) |i| {
            const name = try std.fmt.allocPrint(ra, "{s}{d}", .{ prefix, i });
            try self.declareLocal(name, "i32");
        }
    }

    /// Lower a function body into a detached sequence, tagged with what it
    /// leaves on the operand stack. Locals registered while lowering land in
    /// `pending_locals`, which the caller hands to the function node.
    ///
    /// The tag is what makes a void function with a leftover value — and a
    /// value-returning one with no `(result …)` — impossible to build: the
    /// stack here is checked against the signature by `wat_ast.Builder.func`.
    fn renderBody(self: *Emitter, body: []const ast.Stmt, prologue: ?ast.FnDecl) !Seq {
        var c: Capture = .{};
        self.open(&c);
        if (prologue) |f| {
            for (f.params, 0..) |p, i| {
                if (p.destruct == null) continue;
                try self.bindParamDestructure(p, try self.paramSymbol(p, i));
            }
        }
        const tail_type: ?[]const u8 = if (self.fn_has_result and body.len > 0)
            self.wasmTypeOf(body[body.len - 1].expr)
        else
            null;
        const tail = try self.emitBody(body, self.fn_has_result);
        if (self.fn_has_result and tail == .none) try self.pushZero();
        // An implicit tail value has to meet the declared `(result …)` too.
        if (self.fn_has_result and tail == .value) {
            if (tail_type) |t| try self.emitConvert(t, self.cur_result);
        }
        // `emitBody` normalises: with a result the tail is a value (or the
        // body terminated), without one it is nothing (or terminated).
        const stack: wat.Stack = if (tail == .terminated)
            .terminated
        else if (self.fn_has_result)
            .{ .value = vt(self.cur_result) }
        else
            .none;
        return self.seal(&c, stack);
    }

    fn renderAccumulatingBody(self: *Emitter, body: []const ast.Stmt) !Seq {
        var c: Capture = .{};
        self.open(&c);
        const tgt = "__yield_fn";
        try self.declareLocal(tgt, "i32");
        try self.emit(zero);
        try self.emit(self.builder().helper(.arr_new));
        try self.emit(.{ .local_set = tgt });
        self.yield_target = tgt;
        defer self.yield_target = null;
        const tail = try self.emitBody(body, false);
        if (tail != .terminated) {
            try self.emitC(.{ .local_get = tgt }, "everything the body yielded");
            try self.emitConvert("i32", self.cur_result);
        }
        return self.seal(&c, if (tail == .terminated) .terminated else .{ .value = vt(self.cur_result) });
    }

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        // A bodyless `declare fn` (host-backed FFI, `#[@External.…]`) has no
        // wasm implementation. Emitting `(func $f (result f64))` with an empty
        // body is invalid, so skip it entirely — call sites fall back to the
        // unresolved-call stub, which is at least honest and loadable.
        if (f.isDeclare or f.body.len == 0) {
            try self.itemCommentF("declare fn {s} — no wasm implementation (host-backed)", .{f.name});
            return;
        }
        const has_result = fnHasResult(f);
        self.resetFnState(if (has_result) watTypeOpt(f.returnType) else null);
        self.fn_returns_result = (f.effect != null and f.effect.? == .result) or
            (if (f.returnType) |rt| resultShapeOfTypeRef(rt) != null else false);

        // An effect fn is async/generator — except `#[@result]` (checked-Result
        // effect), which is a plain function. WASM is single-threaded and eager
        // here: `@Future<T>` resolves to `T` (`await` is identity); full
        // generator state-machine lowering is not yet implemented.
        if (f.effect != null and f.effect.? != .result) {
            try self.itemComment("#[@future] / #[@asyncGenerator] — eager lowering");
        }
        // Params, and the locals the body needs, are registered *before* the
        // body is rendered so identifier lowering can tell a local from a global.
        for (f.params, 0..) |p, i| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            const sym = try self.paramSymbol(p, i);
            const t = watType(p.typeRef);
            try self.locals.put(sym, t);
            const tn = typeRefName(p.typeRef);
            if (self.resolveRecordName(tn)) |rty|
                try self.local_types.put(sym, rty);
            try self.noteParamShape(sym, p.typeRef);
            try self.local_typerefs.put(sym, p.typeRef);
        }
        self.cur_ret_typeref = f.returnType;
        try self.declareScratch("_try", countTrys(f.body));
        try self.declareScratch("__mem", self.countMems(f.body));
        try self.emitLocalDecls(f.body);

        // An `#[@iterator]` / `#[@generator]` body runs eagerly: every `yield`
        // is appended to one array, which is what the fn returns.
        const accumulates = if (f.effect) |e|
            (e == .iterator or e == .generator or e == .asyncGenerator) and has_result and bodyYieldsDeep(f.body)
        else
            false;
        const body = if (accumulates) try self.renderAccumulatingBody(f.body) else try self.renderBody(f.body, f);

        const ar = self.arena();
        var params: std.ArrayListUnmanaged(wat.Param) = .empty;
        for (f.params, 0..) |p, i| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            try params.append(ar, wat.Builder.param(try self.paramSymbol(p, i), vt(watType(p.typeRef))));
        }
        try self.item(.{ .func = try self.builder().func(.{
            .name = f.name,
            .exports = if (f.isPub) try ar.dupe([]const u8, &.{f.name}) else &.{},
            .params = params.items,
            .result = if (has_result) vt(self.cur_result) else null,
            .locals = try self.localLines(),
            .body = body,
        }) });
    }

    /// Emit each `implement`/`extend` method as a linear-memory function
    /// `$<target>_<method>`. Unlike `emitFn`, the receiver `self` is kept as a
    /// real `i32` param (records/structs are heap pointers) so an activated
    /// `recv.m(args)` dispatch can pass it. Codegen is untyped and method
    /// bodies carry no return type, so params/result default to `i32`; a method
    /// whose body yields no value is emitted without a result.
    fn emitExtensionMethods(self: *Emitter, target: []const u8, methods: []const ast.ImplementMethod) !void {
        for (methods) |m| {
            const has_result = methodHasResult(m.body);
            self.resetFnState(if (has_result) "i32" else null);
            // `self.field` inside an extension method walks the target record's
            // declared field layout.
            self.self_type = if (self.records.contains(target)) target else null;
            defer self.self_type = null;
            const qualifier = m.qualifier orelse target;
            for (m.params, 0..) |p, i| {
                const sym = try self.paramSymbol(p, i);
                try self.locals.put(sym, "i32");
                if (std.mem.eql(u8, p.name, "self")) {
                    if (self.self_type) |st| try self.local_types.put("self", st);
                } else {
                    const tn = typeRefName(p.typeRef);
                    if (self.resolveRecordName(tn)) |rty|
                        try self.local_types.put(sym, rty);
                    try self.noteParamShape(sym, p.typeRef);
                }
            }
            try self.declareScratch("_try", countTrys(m.body));
            try self.declareScratch("__mem", self.countMems(m.body));
            try self.emitLocalDecls(m.body);

            const body = try self.renderBody(m.body, null);

            const ar = self.arena();
            var params: std.ArrayListUnmanaged(wat.Param) = .empty;
            for (m.params, 0..) |p, i| {
                try params.append(ar, wat.Builder.param(try self.paramSymbol(p, i), .i32));
            }
            try self.item(.{ .func = try self.builder().func(.{
                .name = try std.fmt.allocPrint(ar, "{s}_{s}", .{ qualifier, m.name }),
                .params = params.items,
                .result = if (has_result) .i32 else null,
                .locals = try self.localLines(),
                .body = body,
            }) });
        }
    }

    /// Record / struct member methods emitted as `$<owner>_<method>` linear-
    /// memory fns. `self` becomes an i32 record-pointer param, so `self.field`
    /// in the body reads the slot at the declared offset. Skipped: bodyless
    /// declarations (`declare fn`) and `#[@External.<targert>(...)]` host-backed methods.
    fn emitInterfaceMethods(self: *Emitter, owner: []const u8, methods: []const ast.BehaviorMethod) !void {
        for (methods) |m| {
            if (m.is_declare or m.body == null or m.isExternal() or m.isHost()) continue;
            try self.emitMemberFn(owner, m);
        }
    }

    fn emitStructMethods(self: *Emitter, s: ast.StructDecl) !void {
        for (s.members) |mem| switch (mem) {
            .method => |m| {
                if (m.is_declare or m.body == null or m.isExternal() or m.isHost()) continue;
                try self.emitMemberFn(s.name, m);
            },
            else => {},
        };
    }

    fn emitMemberFn(self: *Emitter, owner: []const u8, m: ast.BehaviorMethod) !void {
        const body = m.body orelse return;
        const has_result = m.returnType != null or methodHasResult(body);
        self.resetFnState(if (has_result) "i32" else null);
        self.fn_returns_result = if (m.returnType) |rt| resultShapeOfTypeRef(rt) != null else false;
        self.self_type = if (self.records.contains(owner)) owner else null;
        defer self.self_type = null;
        // Methods declared inside a record/struct body that reference `self`
        // without listing it as a param need an implicit `(param $self i32)`,
        // otherwise the bare `self.field` would emit a `global.get $self`
        // that wasmtime --validate rejects.
        var has_self_param = false;
        for (m.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) {
                has_self_param = true;
                break;
            }
        }
        const needs_self = !has_self_param and bodyReferencesSelf(body);
        if (needs_self) {
            try self.locals.put("self", "i32");
            if (self.self_type) |st| try self.local_types.put("self", st);
        }
        for (m.params, 0..) |p, i| {
            const sym = try self.paramSymbol(p, i);
            try self.locals.put(sym, "i32");
            if (std.mem.eql(u8, p.name, "self")) {
                if (self.self_type) |st| try self.local_types.put("self", st);
            } else {
                const tn = typeRefName(p.typeRef);
                if (self.resolveRecordName(tn)) |rty|
                    try self.local_types.put(sym, rty);
                try self.noteParamShape(sym, p.typeRef);
            }
        }
        try self.declareScratch("_try", countTrys(body));
        try self.declareScratch("__mem", self.countMems(body));
        try self.emitLocalDecls(body);

        const seq = try self.renderBody(body, null);

        const ar = self.arena();
        var params: std.ArrayListUnmanaged(wat.Param) = .empty;
        if (needs_self) try params.append(ar, wat.Builder.param("self", .i32));
        for (m.params, 0..) |p, i| {
            try params.append(ar, wat.Builder.param(try self.paramSymbol(p, i), .i32));
        }
        try self.item(.{ .func = try self.builder().func(.{
            .name = try std.fmt.allocPrint(ar, "{s}_{s}", .{ owner, m.name }),
            .params = params.items,
            .result = if (has_result) .i32 else null,
            .locals = try self.localLines(),
            .body = seq,
        }) });
    }

    /// True when any `self` identifier appears anywhere in `body` (used to
    /// decide whether a self-less member fn needs an implicit `$self` param).
    fn bodyReferencesSelf(body: []const ast.Stmt) bool {
        for (body) |s| if (exprReferencesSelf(s.expr)) return true;
        return false;
    }

    fn exprReferencesSelf(e: ast.Expr) bool {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| std.mem.eql(u8, n, "self"),
                .identAccess => |ia| exprReferencesSelf(ia.receiver.*),
                .dotIdent => false,
            },
            .binaryOp => |bin| exprReferencesSelf(bin.lhs.*) or exprReferencesSelf(bin.rhs.*),
            .unaryOp => |un| exprReferencesSelf(un.expr.*),
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (cc.receiver) |r| if (exprReferencesSelf(r.*)) break :blk true;
                    for (cc.args) |a| if (exprReferencesSelf(a.value.*)) break :blk true;
                    for (cc.trailing) |t| if (bodyReferencesSelf(t.body)) break :blk true;
                    break :blk false;
                },
                .pipeline => |pl| exprReferencesSelf(pl.lhs.*) or exprReferencesSelf(pl.rhs.*),
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| blk: {
                    if (exprReferencesSelf(i.cond.*)) break :blk true;
                    if (bodyReferencesSelf(i.then_)) break :blk true;
                    if (i.else_) |els| if (bodyReferencesSelf(els)) break :blk true;
                    break :blk false;
                },
                .tryCatch => |tc| exprReferencesSelf(tc.expr.*) or exprReferencesSelf(tc.handler.*),
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| exprReferencesSelf(lb.value.*),
                .localBindDestruct => |lb| exprReferencesSelf(lb.value.*),
                .assign => |a| blk: {
                    if (exprReferencesSelf(a.value.*)) break :blk true;
                    switch (a.target) {
                        .fieldAccess => |fa| if (exprReferencesSelf(fa.receiver.*)) break :blk true,
                        .name => |n| if (std.mem.eql(u8, n, "self")) break :blk true,
                    }
                    break :blk false;
                },
            },
            .jump => |j| switch (j.kind) {
                .@"return", .throw_, .try_ => |v| if (v) |i| exprReferencesSelf(i.*) else false,
                inline .@"break", .yield => |jl| if (jl.value) |i| exprReferencesSelf(i.*) else false,
                .await_ => |a| exprReferencesSelf(a.*),
                else => false,
            },
            .loop => |lp| exprReferencesSelf(lp.iter.*) or bodyReferencesSelf(lp.body),
            else => false,
        };
    }

    /// True when a method body's final statement produces a value (so the WAT
    /// function needs a `(result i32)`). Void-tailed bodies (a bare `@print`,
    /// a valueless `return`, or an empty body) yield nothing.
    fn bodyYieldsValue(body: []const ast.Stmt) bool {
        if (body.len == 0) return false;
        const last = body[body.len - 1].expr;
        return switch (last) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| r != null,
                .yield => |y| y.value != null,
                .await_ => true,
                else => false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| !(cc.is_builtin and
                    (std.mem.eql(u8, cc.callee, "print") or
                        std.mem.eql(u8, cc.callee, "todo") or
                        std.mem.eql(u8, cc.callee, "panic"))),
                .pipeline => true,
            },
            .binding => false,
            .comptime_ => |ct| ct.kind != .assert,
            // Same statement-form test as `exprTail`/`lowerIfExpr`: a trailing
            // `if` with two void arms leaves the function empty-handed, so it
            // must not be given a `(result …)`.
            .branch => |b| switch (b.kind) {
                .if_ => |i| !ifIsStatementForm(i),
                .tryCatch => true,
            },
            else => true,
        };
    }

    /// Whether a function needs a `(result …)`. A declared return type settles
    /// it; otherwise the body decides. The comptime specialisation pass clears
    /// `returnType` on the functions it injects (`transform.zig` `.returnType =
    /// null`) even though their bodies still `return` a value, so relying on
    /// the annotation alone emits a void function whose `return <v>` leaves a
    /// value on the stack — and the call site then underflows.
    fn fnHasResult(f: ast.FnDecl) bool {
        if (f.returnType != null) return true;
        return methodHasResult(f.body);
    }

    /// Same question for a body with no signature to consult: a value-producing
    /// tail, or any `return <expr>` anywhere inside.
    fn methodHasResult(body: []const ast.Stmt) bool {
        return bodyYieldsValue(body) or bodyHasValueReturn(body);
    }

    fn bodyHasValueReturn(body: []const ast.Stmt) bool {
        for (body) |s| if (exprHasValueReturn(s.expr)) return true;
        return false;
    }

    fn exprHasValueReturn(e: ast.Expr) bool {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| r != null,
                else => false,
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| bodyHasValueReturn(i.then_) or
                    (if (i.else_) |els| bodyHasValueReturn(els) else false),
                else => false,
            },
            .loop => |lp| bodyHasValueReturn(lp.body),
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    for (cc.trailing) |t| if (bodyHasValueReturn(t.body)) break :blk true;
                    break :blk false;
                },
                else => false,
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| exprHasValueReturn(lb.value.*),
                else => false,
            },
            else => false,
        };
    }

    /// Count `try`/`try…catch` nodes so a scratch pointer local can be declared
    /// for each (WAT locals must be declared up-front, before the body).
    fn countTrys(body: []const ast.Stmt) u32 {
        var n: u32 = 0;
        for (body) |stmt| n += countTrysExpr(stmt.expr);
        return n;
    }

    fn countTrysExpr(e: ast.Expr) u32 {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                .try_ => |t| 1 + (if (t) |i| countTrysExpr(i.*) else 0),
                .@"return", .throw_ => |v| if (v) |i| countTrysExpr(i.*) else 0,
                inline .@"break", .yield => |jl| if (jl.value) |i| countTrysExpr(i.*) else 0,
                .await_ => |a| countTrysExpr(a.*),
                else => 0,
            },
            .branch => |b| switch (b.kind) {
                .tryCatch => |tc| 1 + countTrysExpr(tc.expr.*) + countTrysExpr(tc.handler.*),
                .if_ => |i| blk: {
                    var n = countTrysExpr(i.cond.*) + countTrys(i.then_);
                    if (i.else_) |els| n += countTrys(els);
                    break :blk n;
                },
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| countTrysExpr(lb.value.*),
                .localBindDestruct => |lb| countTrysExpr(lb.value.*),
                .assign => |a| countTrysExpr(a.value.*),
            },
            else => 0,
        };
    }

    /// What a `.call` lowers to. Construction calls need a `$__mem` scratch
    /// pointer; plain calls and builtins do not. Used identically by
    /// `countMems` (to size the scratch pool) and `lowerExpr` (to consume it),
    /// so the count and usage stay in lock-step.
    const CallKind = enum { builtin, record_ctor, enum_ctor, plain };

    fn callKind(self: *Emitter, cc: anytype) CallKind {
        if (cc.is_builtin) return .builtin;
        if (self.records.contains(cc.callee)) return .record_ctor;
        if (receiverName(cc)) |rcv| {
            if (self.enums.contains(rcv)) return .enum_ctor;
        } else if (cc.callee.len > 0 and std.ascii.isUpper(cc.callee[0])) {
            // `Variant(...)` with no receiver: an enum payload constructor when
            // the (capitalised) name uniquely names a payload-bearing variant.
            if (self.findVariant(cc.callee)) |fv| {
                if (fv.variant.fields.len > 0) return .enum_ctor;
            }
        }
        return .plain;
    }

    /// The receiver of a qualified call, when it is a plain identifier
    /// (`Color.Rgb(…)` → `"Color"`). The call `receiver` is an expression
    /// pointer, so anything more complex yields null.
    fn receiverName(cc: anytype) ?[]const u8 {
        const recv = cc.receiver orelse return null;
        return switch (recv.*) {
            .identifier => |rid| switch (rid.kind) {
                .ident => |n| n,
                else => null,
            },
            else => null,
        };
    }

    const FoundVariant = struct { variants: []const ast.EnumVariant, tag: u32, variant: ast.EnumVariant };

    /// Decision 8 §5.1 P8: a pattern's variant name reaches the backend with
    /// the path it was **written** with — `Shape.Circle`, `.Circle` — while the
    /// constructor stores the bare `Circle`. The last `.`-separated segment is
    /// the variant; what precedes it, when it is not empty, is the enum.
    fn bareVariantName(name: []const u8) []const u8 {
        const i = std.mem.lastIndexOfScalar(u8, name, '.') orelse return name;
        return name[i + 1 ..];
    }

    /// The enum a written path names, or `""` for a bare name and for the
    /// dot shorthand `.Circle` (whose enum comes from the matched value).
    fn variantPathEnum(name: []const u8) []const u8 {
        const i = std.mem.lastIndexOfScalar(u8, name, '.') orelse return "";
        return name[0..i];
    }

    /// True when `name` was written as a path (`Shape.Circle`, `.None`). Such a
    /// name is a variant, never a binding, however it resolves (§5.1 P8).
    fn isVariantPath(name: []const u8) bool {
        return std.mem.indexOfScalar(u8, name, '.') != null;
    }

    /// Search for a variant the pattern named. A written path (`Shape.Circle`)
    /// is looked up in the enum it names first; a bare or dot-shorthand name
    /// searches every enum, first match wins.
    fn findVariant(self: *Emitter, name: []const u8) ?FoundVariant {
        const bare = bareVariantName(name);
        const ename = variantPathEnum(name);
        if (ename.len > 0) {
            if (self.enums.get(ename)) |variants| {
                for (variants, 0..) |v, i| {
                    if (std.mem.eql(u8, v.name, bare))
                        return .{ .variants = variants, .tag = @intCast(i), .variant = v };
                }
            }
        }
        var it = self.enums.iterator();
        while (it.next()) |entry| {
            for (entry.value_ptr.*, 0..) |v, i| {
                if (std.mem.eql(u8, v.name, bare))
                    return .{ .variants = entry.value_ptr.*, .tag = @intCast(i), .variant = v };
            }
        }
        return null;
    }

    /// Count the `$__mem` scratch pointers a function body needs: one per
    /// aggregate construction (tuple/array/record/enum-payload) and one per
    /// destructuring binding.
    fn countMems(self: *Emitter, body: []const ast.Stmt) u32 {
        var n: u32 = 0;
        for (body) |stmt| {
            switch (stmt.expr) {
                .binding => |b| switch (b.kind) {
                    .localBind => |lb| n += self.countMemsExpr(lb.value.*),
                    .assign => |a| {
                        n += self.countMemsExpr(a.value.*);
                        switch (a.target) {
                            .fieldAccess => |fa| {
                                n += self.countMemsExpr(fa.receiver.*);
                                // `recv.field += rhs` stashes the receiver in
                                // a scratch local for the load-add-store cycle.
                                if (a.op == .plusAssign) n += 1;
                            },
                            else => {},
                        }
                    },
                    .localBindDestruct => |lb| n += 1 + self.countMemsExpr(lb.value.*),
                },
                else => n += self.countMemsExpr(stmt.expr),
            }
        }
        return n;
    }

    fn countMemsExpr(self: *Emitter, e: ast.Expr) u32 {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .identAccess => |ia| blk: {
                    var n = self.countMemsExpr(ia.receiver.*);
                    // `?.field` lowers to a `local.tee` guard which needs a
                    // scratch i32 to hold the receiver pointer while testing
                    // for null. Over-counting is safe (unused locals are fine).
                    if (ia.optional) n += 1;
                    break :blk n;
                },
                else => 0,
            },
            .binaryOp => |bin| self.countMemsExpr(bin.lhs.*) + self.countMemsExpr(bin.rhs.*),
            .unaryOp => |un| self.countMemsExpr(un.expr.*),
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    var n: u32 = switch (self.callKind(cc)) {
                        .record_ctor, .enum_ctor => 1,
                        else => 0,
                    };
                    // A method call's receiver is an expression too: `[1,2].at(0)`
                    // materialises the array into a scratch local before the
                    // call, and skipping it here left that `local.set $__memN`
                    // against a name no `(local …)` declared.
                    if (cc.receiver) |recv| n += self.countMemsExpr(recv.*);
                    for (cc.args) |arg| n += self.countMemsExpr(arg.value.*);
                    for (cc.trailing) |t| n += self.countMems(t.body);
                    break :blk n;
                },
                .pipeline => |pl| self.countMemsExpr(pl.lhs.*) + self.countMemsExpr(pl.rhs.*),
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| blk: {
                    var n = self.countMemsExpr(i.cond.*) + self.countMems(i.then_);
                    if (i.else_) |els| n += self.countMems(els);
                    break :blk n;
                },
                .tryCatch => |tc| self.countMemsExpr(tc.expr.*) + self.countMemsExpr(tc.handler.*),
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.countMemsExpr(inner.*),
                .case => |c| blk: {
                    var n: u32 = 0;
                    for (c.subjects) |s| n += self.countMemsExpr(s);
                    for (c.arms) |arm| n += self.countMemsExpr(arm.body);
                    break :blk n;
                },
                .tupleLit => |tl| blk: {
                    var n: u32 = 1;
                    for (tl.elems) |el| n += self.countMemsExpr(el);
                    break :blk n;
                },
                .arrayLit => |al| blk: {
                    var n: u32 = 1;
                    for (al.elems) |el| n += self.countMemsExpr(el);
                    break :blk n;
                },
                .range => |r| blk: {
                    var n = self.countMemsExpr(r.start.*);
                    if (r.end) |end| n += self.countMemsExpr(end.*);
                    break :blk n;
                },
                .behaviorLit => |il| blk: {
                    var n: u32 = 1;
                    for (il.fields) |f| n += self.countMemsExpr(f.value.*);
                    break :blk n;
                },
            },
            .jump => |j| switch (j.kind) {
                .@"return", .throw_, .try_ => |v| if (v) |i| self.countMemsExpr(i.*) else 0,
                inline .@"break", .yield => |jl| if (jl.value) |i| self.countMemsExpr(i.*) else 0,
                .await_ => |a| self.countMemsExpr(a.*),
                else => 0,
            },
            .loop => |lp| self.countMemsExpr(lp.iter.*) + self.countMems(lp.body),
            else => 0,
        };
    }

    /// Walk a body and *register* every local it binds (no output — see
    /// `declareLocal`). Recurses through every nested statement list — if/else
    /// branches, loop bodies, `@block { … }` trailing bodies — because a `val`
    /// bound inside one of those is still a function-level WAT local, and
    /// missing it used to produce a `local.set` against an undeclared name.
    fn emitLocalDecls(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        for (body) |stmt| {
            switch (stmt.expr) {
                .binding => |b| switch (b.kind) {
                    .localBind => |lb| {
                        const t = self.inferExprType(lb.value.*);
                        if (self.recordTypeOfExpr(lb.value.*)) |rty| {
                            try self.local_types.put(lb.name, rty);
                        }
                        if (self.isStringExpr(lb.value.*)) try self.str_locals.put(lb.name, {});
                        if (self.isBoolExpr(lb.value.*)) try self.bool_locals.put(lb.name, {});
                        try self.noteArrayLocal(lb.name, lb.value.*);
                        if (self.resultShapeOf(lb.value.*)) |shape| try self.result_shape_locals.put(lb.name, shape);
                        try self.declareLocal(lb.name, t);
                        try self.declareNestedLocals(lb.value.*);
                    },
                    .localBindDestruct => |lb| {
                        switch (lb.pattern) {
                            .names => |n| {
                                const recv_rty = self.recordTypeOfExpr(lb.value.*);
                                for (n.fields) |fld| {
                                    if (recv_rty) |rty| {
                                        if (self.fieldTypeIn(rty, fld.field_name)) |ft| {
                                            if (self.resolveRecordName(ft)) |sub|
                                                try self.local_types.put(fld.bind_name, sub);
                                        }
                                    }
                                    try self.declareLocal(fld.bind_name, "i32");
                                }
                            },
                            .tuple_ => |bindings| {
                                for (bindings, 0..) |name, i| {
                                    try self.declareLocal(name, "i32");
                                    try self.noteTupleElemShape(name, lb.value.*, i);
                                }
                            },
                            else => {},
                        }
                        try self.declareNestedLocals(lb.value.*);
                    },
                    .assign => |a| try self.declareNestedLocals(a.value.*),
                },
                else => try self.declareNestedLocals(stmt.expr),
            }
        }
    }

    /// Register locals bound inside an expression's nested statement lists.
    fn declareNestedLocals(self: *Emitter, e: ast.Expr) anyerror!void {
        switch (e) {
            .branch => |b| switch (b.kind) {
                .if_ => |i| {
                    // `if (opt) { v -> … }` binds the narrowed value to `v`.
                    if (i.binding) |name| try self.declareLocal(name, "i32");
                    try self.emitLocalDecls(i.then_);
                    if (i.else_) |els| try self.emitLocalDecls(els);
                },
                .tryCatch => |tc| {
                    try self.declareNestedLocals(tc.expr.*);
                    try self.declareNestedLocals(tc.handler.*);
                },
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    for (cc.args) |a| try self.declareNestedLocals(a.value.*);
                    for (cc.trailing) |t| try self.emitLocalDecls(t.body);
                },
                .pipeline => |pl| {
                    try self.declareNestedLocals(pl.lhs.*);
                    try self.declareNestedLocals(pl.rhs.*);
                },
            },
            .loop => |lp| {
                // A walk over a float array binds its element as an f32
                // (`lowerCollectionLoop`); a range or an index is an i32.
                const is_range = lp.iter.* == .collection and lp.iter.collection.kind == .range;
                for (lp.params, 0..) |p, i| {
                    const float_elem = i == 0 and !is_range and self.isArrayExpr(lp.iter.*) and self.elemKindOf(lp.iter.*) == .f32;
                    try self.declareLocal(p, if (float_elem) "f32" else "i32");
                }
                try self.emitLocalDecls(lp.body);
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| try self.declareNestedLocals(inner.*),
                .case => |cse| for (cse.arms) |arm| {
                    try self.declarePatternLocals(arm.pattern);
                    try self.declareNestedLocals(arm.body);
                },
                else => {},
            },
            .binaryOp => |bin| {
                try self.declareNestedLocals(bin.lhs.*);
                try self.declareNestedLocals(bin.rhs.*);
            },
            .unaryOp => |un| try self.declareNestedLocals(un.expr.*),
            .jump => |j| switch (j.kind) {
                .@"return", .throw_, .try_ => |v| if (v) |i| try self.declareNestedLocals(i.*),
                inline .@"break", .yield => |jl| if (jl.value) |i| try self.declareNestedLocals(i.*),
                .await_ => |a| try self.declareNestedLocals(a.*),
                else => {},
            },
            .useHook => |uh| try self.declareNestedLocals(uh.kind.inner.*),
            else => {},
        }
    }

    /// Locals a case pattern binds (variant payload fields, `ident` binders,
    /// list-pattern element and rest names).
    fn declarePatternLocals(self: *Emitter, p: ast.Pattern) anyerror!void {
        switch (p) {
            .ident => |n| if (self.findVariant(n) == null) try self.declareLocal(n, "i32"),
            .variant => |v| switch (v.payload) {
                .binding => |b| try self.declareLocal(b, "i32"),
                .fields => |fs| for (fs, 0..) |f, i| {
                    const ty = if (self.findVariant(v.name)) |fv|
                        (if (i < fv.variant.fields.len) watType(fv.variant.fields[i].typeRef) else "i32")
                    else
                        "i32";
                    // A name already declared (a parameter) keeps its slot and
                    // the arm binds an alias instead — see `bindName`.
                    if (!self.locals.contains(f)) {
                        try self.declareLocal(f, ty);
                        try self.pattern_locals.put(f, {});
                    }
                },
                .literals => |pats| for (pats) |sub| try self.declarePatternLocals(sub),
            },
            .list => |l| {
                for (l.elems) |el| try self.declareListElemLocals(el);
                if (l.spread) |rest| if (rest.len > 0) try self.declareLocal(rest, "i32");
            },
            .@"or", .multi => |pats| for (pats) |sub| try self.declarePatternLocals(sub),
            else => {},
        }
    }

    fn declareListElemLocals(self: *Emitter, el: ast.ListPatternElem) anyerror!void {
        switch (el) {
            .bind => |n| try self.declareLocal(n, "i32"),
            else => {},
        }
    }

    /// The wasm type to declare a local with. Must be the *same* classifier the
    /// lowering uses, or the value pushed and the slot it is stored into
    /// disagree: `val taxa = valor * 0.15` lowered to an `f32.mul` but declared
    /// `(local $taxa i32)`.
    fn inferExprType(self: *Emitter, e: ast.Expr) []const u8 {
        return self.wasmTypeOf(e);
    }

    fn emitGlobalVal(self: *Emitter, v: ast.ValDecl) !void {
        const t = self.globalValType(v);
        if (self.boxesInto(v.typeAnnotation, v.value.*)) {
            try self.item(.{ .global = .{ .name = v.name, .ty = .i32, .mutable = true, .init = "0" } });
            try self.deferred_globals.append(self.alloc, v);
            return;
        }
        if (self.folded_globals.get(v.name)) |text| {
            if (isNumericLiteral(text)) {
                try self.item(.{ .global = .{ .name = v.name, .ty = vt(t), .init = text } });
                return;
            }
            if (quotedString(text)) |str| {
                const seg = try self.internString(str);
                try self.item(.{ .global = .{
                    .name = v.name,
                    .ty = .i32,
                    .init = try std.fmt.allocPrint(self.arena(), "{d}", .{seg.offset}),
                } });
                return;
            }
        }
        switch (v.value.*) {
            .literal => |lit| switch (lit.kind) {
                // The comptime folder rewrites a folded `val` into a `numberLit`
                // node carrying the *rendered* value, which is not always a
                // number: `val COMMANDS = comptime ["calc", …]` arrived here as
                // the text `["calc", "noop", "help"]` and was emitted as
                // `(f32.const ["calc", …])` — a parse error that killed the
                // whole module. Only take the constant path for real numerals.
                .numberLit => |n| if (isNumericLiteral(n)) {
                    try self.item(.{ .global = .{
                        .name = v.name,
                        .exports = if (v.isPub) try self.arena().dupe([]const u8, &.{v.name}) else &.{},
                        .ty = vt(t),
                        .init = n,
                    } });
                    return;
                },
                .stringLit => |s| {
                    const seg = try self.internString(try self.literalBytes(s));
                    try self.item(.{ .global = .{
                        .name = v.name,
                        .ty = .i32,
                        .mutable = true,
                        .init = try std.fmt.allocPrint(self.arena(), "{d}", .{seg.offset}),
                    } });
                    return;
                },
                else => {},
            },
            else => {},
        }
        // Not a constant expression: declare it zeroed and mutable, and fill it
        // in from `$__init_globals` (see `emitGlobalInit`).
        try self.item(.{ .global = .{
            .name = v.name,
            .ty = vt(t),
            .mutable = true,
            .init = "0",
        } });
        try self.deferred_globals.append(self.alloc, v);
    }

    /// Emit `$__init_globals`, the body of the module's `(start …)`: every
    /// top-level `val` whose initialiser is not a wasm constant expression is
    /// evaluated here, in source order, before `main` runs.
    fn emitGlobalInit(self: *Emitter) !void {
        if (self.deferred_globals.items.len == 0) return;
        self.resetFnState(null);

        var total_mems: u32 = 0;
        var total_trys: u32 = 0;
        for (self.deferred_globals.items) |v| {
            total_mems += self.countMemsExpr(v.value.*);
            total_trys += countTrysExpr(v.value.*);
        }
        try self.declareScratch("_try", total_trys);
        try self.declareScratch("__mem", total_mems);

        var c: Capture = .{};
        self.open(&c);
        for (self.deferred_globals.items) |v| {
            if (self.boxesInto(v.typeAnnotation, v.value.*))
                try self.lowerBoxed(v.value.*)
            else
                try self.lowerCoerced(v.value.*, self.globalValType(v));
            try self.emit(.{ .global_set = v.name });
        }
        const body = self.seal(&c, .none);

        try self.item(.{ .func = try self.builder().func(.{
            .name = "__init_globals",
            .locals = try self.localLines(),
            .body = body,
        }) });
    }

    /// Syntactically an array literal (through parentheses).
    fn isArrayLit(e: ast.Expr) bool {
        return switch (e) {
            .collection => |col| switch (col.kind) {
                .arrayLit => true,
                .grouped => |inner| isArrayLit(inner.*),
                else => false,
            },
            else => false,
        };
    }

    /// The contents of a folded `"…"` value, when the text is one (no escapes
    /// inside).
    fn quotedString(text: []const u8) ?[]const u8 {
        if (text.len < 2 or text[0] != '"' or text[text.len - 1] != '"') return null;
        const inner = text[1 .. text.len - 1];
        if (std.mem.indexOfAny(u8, inner, "\\\"") != null) return null;
        return inner;
    }

    /// Whether a `numberLit`'s text really is a wasm numeral. Guards against the
    /// comptime folder's rendered non-numeric values (arrays, records, strings).
    fn isNumericLiteral(n: []const u8) bool {
        if (n.len == 0) return false;
        var i: usize = 0;
        if (n[0] == '-' or n[0] == '+') i = 1;
        if (i >= n.len) return false;
        var seen_digit = false;
        while (i < n.len) : (i += 1) switch (n[i]) {
            '0'...'9' => seen_digit = true,
            '.', 'e', 'E', '+', '-', '_' => {},
            else => return false,
        };
        return seen_digit;
    }

    /// The wat value type of a top-level `val`. Without an annotation the
    /// literal's own spelling decides, so `val PI = 3.14` is an `f64` global
    /// rather than an `(global $PI i32 (i32.const 3.14))` parse error.
    fn globalValType(self: *Emitter, v: ast.ValDecl) []const u8 {
        if (v.typeAnnotation) |ta| return watType(ta);
        // A folded float is an f64 — the value the comptime pass computed.
        if (self.folded_globals.get(v.name)) |text| {
            if (isNumericLiteral(text)) return if (std.mem.indexOfAny(u8, text, ".eE") != null) "f64" else "i32";
        }
        return switch (v.value.*) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| if (isNumericLiteral(n)) numLitType(n) else "i32",
                else => "i32",
            },
            // Anything the init function computes is a pointer or an i32 unless
            // the expression is plainly a float.
            else => self.wasmTypeOf(v.value.*),
        };
    }

    fn emitEntrypointWrapper(self: *Emitter, main_returns_value: bool) !void {
        var c: Capture = .{};
        self.open(&c);
        // The one folded instruction the backend emits, kept for byte-identity
        // with the historical wrapper.
        try self.cur.?.append(self.arena(), .{ .instr = .{ .call = "main" }, .folded = true });
        // The wrapper itself returns nothing, so a value-returning `main` would
        // leave its result on the stack — invalid wasm. Discard it.
        if (main_returns_value) try self.emit(.drop);
        const body = self.seal(&c, .none);

        try self.item(.{ .func = try self.builder().func(.{
            .name = "_botopink_main",
            .exports = &.{ "_botopink_main", "_start" },
            .body = body,
        }) });
    }

    // ── body ─────────────────────────────────────────────────────────────────

    /// Lower a statement list. `keep_value` says whether the last statement's
    /// value must survive on the operand stack (a function with a `(result …)`,
    /// or an `(if (result …))` branch). The returned `Tail` reports what the
    /// stack actually looks like afterwards, so nested contexts can normalise.
    fn emitBody(self: *Emitter, body: []const ast.Stmt, keep_value: bool) anyerror!Tail {
        if (body.len == 0) {
            if (keep_value) {
                try self.pushZero();
                return .value;
            }
            return .none;
        }
        for (body[0 .. body.len - 1]) |stmt| _ = try self.emitStmt(stmt, false);
        return self.emitStmt(body[body.len - 1], keep_value);
    }

    fn emitStmt(self: *Emitter, stmt: ast.Stmt, keep_value: bool) anyerror!Tail {
        const tail = try self.emitStmtRaw(stmt, keep_value);
        // Normalise to what the context asked for: a value where one is
        // required, nothing where one is not. `.terminated` needs neither.
        if (keep_value and tail == .none) {
            try self.pushZero();
            return .value;
        }
        if (!keep_value and tail == .value) {
            try self.emit(.drop);
            return .none;
        }
        return tail;
    }

    fn emitStmtRaw(self: *Emitter, stmt: ast.Stmt, keep_value: bool) anyerror!Tail {
        switch (stmt.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| {
                        // Coerce to the *declared* result: `fn area(…) -> f64`
                        // whose body multiplies f32 literals produced an f32
                        // and the `(result f64)` rejected the whole module.
                        if (self.fn_has_result and self.boxesInto(self.cur_ret_typeref, val.*))
                            try self.lowerBoxed(val.*)
                        else if (self.fn_has_result)
                            try self.lowerCoerced(val.*, self.cur_result)
                        else {
                            // A `return <expr>` inside a void function must not
                            // carry a value out of it.
                            try self.lowerValue(val.*);
                            try self.emit(.drop);
                        }
                    }
                    try self.emit(.@"return");
                    return .terminated;
                },
                .throw_ => |val| {
                    try self.lowerThrow(val);
                    return .terminated;
                },
                .try_ => |val| {
                    if (val) |v| {
                        try self.lowerTryPropagate(v.*);
                        return .value;
                    }
                    return .none;
                },
                .await_ => |av| {
                    try self.lowerExpr(av.*);
                    return self.exprTail(av.*);
                },
                .@"break" => |br| {
                    if (br.value) |v| {
                        // §10: in a search the break's value IS the loop's.
                        if (self.search_target) |tgt| {
                            try self.lowerCoerced(v.*, "i32");
                            try self.emit(.{ .local_set = tgt });
                            try self.emit(.{ .br = break_label });
                            return .terminated;
                        }
                        if (self.yield_target != null) {
                            try self.emitYield(v.*);
                            if (self.cond_break_depth != null and self.cond_break_depth.? == self.loop_depth) {
                                try self.emit(.{ .br = break_label });
                                return .terminated;
                            }
                            return .none;
                        }
                        try self.lowerValue(v.*);
                        return .value;
                    }
                    if (self.loop_depth > 0) {
                        try self.emit(.{ .br = break_label });
                        return .terminated;
                    }
                    return .none;
                },
                .yield => |y| {
                    if (y.value) |v| {
                        if (self.yield_target != null) {
                            try self.emitYield(v.*);
                            return .none;
                        }
                        try self.lowerValue(v.*);
                        return .value;
                    }
                    return .none;
                },
                .@"continue" => {
                    if (self.loop_depth > 0) {
                        try self.emit(.{ .br = next_label });
                        return .terminated;
                    }
                    return .none;
                },
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    try self.declareLocal(lb.name, self.inferExprType(lb.value.*));
                    if (lb.typeAnnotation orelse self.typeRefOf(lb.value.*)) |tr| try self.local_typerefs.put(lb.name, tr);
                    if (lb.typeAnnotation == null) if (self.optInfoOf(lb.value.*)) |oi| try self.opt_locals.put(lb.name, oi);
                    if (self.isStringExpr(lb.value.*)) try self.str_locals.put(lb.name, {});
                    if (self.isBoolExpr(lb.value.*)) try self.bool_locals.put(lb.name, {});
                    try self.noteArrayLocal(lb.name, lb.value.*);
                    if (self.resultShapeOf(lb.value.*)) |shape| try self.result_shape_locals.put(lb.name, shape);
                    if (self.recordTypeOfExpr(lb.value.*)) |rty| try self.local_types.put(lb.name, rty);
                    // Coerce to the type the local was *actually* declared with:
                    // `emitLocalDecls` runs before the body, so its guess can
                    // differ from what lowering ends up pushing.
                    const lambda_idx: u32 = @intCast(self.lambdas.items.len);
                    if (self.boxesInto(lb.typeAnnotation, lb.value.*))
                        try self.lowerBoxed(lb.value.*)
                    else
                        try self.lowerCoerced(lb.value.*, self.locals.get(lb.name) orelse "i32");
                    try self.emit(.{ .local_set = lb.name });
                    if (lb.value.* == .function and self.lambdas.items.len > lambda_idx)
                        try self.closure_locals.put(lb.name, lambda_idx)
                    else
                        _ = self.closure_locals.remove(lb.name);
                },
                .assign => |a| switch (a.target) {
                    .name => |name| switch (a.op) {
                        .assign => {
                            // A scalar flowing into a declared `?T` goes in a
                            // box, exactly as it does at the binding that
                            // declared the slot. Without this, `var h: ?i32 =
                            // null; h = 5;` stored the bare `5` and the reader
                            // took it for a box *address*: `@print(h)` answered
                            // whatever lives at offset 5 — `16777216` — with
                            // exit 0 and no diagnostic.
                            const tr: ?ast.TypeRef = blk: {
                                const n = self.resolveName(name);
                                if (self.local_typerefs.get(n)) |t| break :blk t;
                                if (self.locals.contains(n)) break :blk null;
                                break :blk self.global_typerefs.get(n);
                            };
                            if (self.boxesInto(tr, a.value.*))
                                try self.lowerBoxed(a.value.*)
                            else
                                // The slot's declared type wins over the value's.
                                try self.lowerCoerced(a.value.*, self.locals.get(name) orelse
                                    self.global_types.get(name) orelse "i32");
                            try self.emit(if (self.locals.contains(name))
                                .{ .local_set = name }
                            else
                                .{ .global_set = name });
                            try self.writeBackCapture(name);
                        },
                        .plusAssign => {
                            try self.emit(if (self.locals.contains(name))
                                .{ .local_get = name }
                            else
                                .{ .global_get = name });
                            const t = self.locals.get(name) orelse
                                self.global_types.get(name) orelse "i32";
                            try self.lowerCoerced(a.value.*, t);
                            try self.emit(opOf(t, "add"));
                            try self.emit(if (self.locals.contains(name))
                                .{ .local_set = name }
                            else
                                .{ .global_set = name });
                            try self.writeBackCapture(name);
                        },
                    },
                    .fieldAccess => |fa| {
                        // `recv.field [+]= value` → store at the record's
                        // declared field offset. `+=` reads the current slot,
                        // adds, then writes back. Falls back to a comment when
                        // the receiver's record type can't be recovered.
                        const rty_opt = self.recordTypeOfExpr(fa.receiver.*);
                        const off_opt = if (rty_opt) |rty| self.fieldOffsetIn(rty, fa.field) else null;
                        if (off_opt) |off| switch (a.op) {
                            .assign => {
                                try self.lowerValue(fa.receiver.*);
                                try self.lowerValue(a.value.*);
                                try self.emitCf(.{ .store = .{ .offset = off } }, ".{s} =", .{fa.field});
                            },
                            .plusAssign => {
                                const mem = try self.memName(self.nextMem());
                                try self.lowerValue(fa.receiver.*);
                                try self.emit(.{ .local_set = mem });
                                try self.emit(.{ .local_get = mem });
                                try self.emit(.{ .local_get = mem });
                                try self.emit(.{ .load = .{ .offset = off } });
                                try self.lowerValue(a.value.*);
                                try self.emit(opOf("i32", "add"));
                                try self.emitCf(.{ .store = .{ .offset = off } }, ".{s} +=", .{fa.field});
                            },
                        } else try self.note("field assign (unknown receiver type)");
                    },
                },
                .localBindDestruct => |lb| {
                    // The value is a pointer to a contiguous run of 4-byte slots
                    // (tuple or record). Load each slot at its offset; named
                    // patterns walk the record's declared field order so
                    // out-of-order destructuring (`{ b, a } = R(7, 11)`) reads
                    // the right slot.
                    const mem = try self.memName(self.nextMem());
                    try self.lowerValue(lb.value.*);
                    try self.emit(.{ .local_set = mem });
                    switch (lb.pattern) {
                        .names => |n| {
                            const recv_rty = self.recordTypeOfExpr(lb.value.*);
                            for (n.fields, 0..) |fld, i| {
                                try self.emit(.{ .local_get = mem });
                                const off: u32 = if (recv_rty) |rty|
                                    (self.fieldOffsetIn(rty, fld.field_name) orelse @as(u32, @intCast(i * 4)))
                                else
                                    @as(u32, @intCast(i * 4));
                                try self.emitLoadOffset(off);
                                try self.emit(.{ .local_set = fld.bind_name });
                            }
                        },
                        .tuple_ => |bindings| {
                            for (bindings, 0..) |name, i| {
                                try self.noteTupleElemShape(name, lb.value.*, i);
                                try self.emit(.{ .local_get = mem });
                                try self.emitLoadOffset(@intCast(i * 4));
                                try self.emit(.{ .local_set = name });
                            }
                        },
                        else => try self.note("unsupported destructure pattern"),
                    }
                },
            },
            // `@block { … }` is transparent: its trailing body is inlined, so
            // the enclosing statement's value requirement passes straight in.
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (cc.is_builtin and std.mem.eql(u8, cc.callee, "block")) {
                        if (cc.trailing.len == 0) return .none;
                        return self.emitBody(cc.trailing[0].body, keep_value);
                    }
                    try self.lowerExpr(stmt.expr);
                    return self.exprTail(stmt.expr);
                },
                else => {
                    try self.lowerExpr(stmt.expr);
                    return self.exprTail(stmt.expr);
                },
            },
            else => {
                try self.lowerExpr(stmt.expr);
                return self.exprTail(stmt.expr);
            },
        }
        return .none;
    }

    /// What `lowerExpr(e)` leaves on the operand stack. This is the single
    /// classifier the statement loop, the argument loop and the branch
    /// normaliser all consult; every arm of `lowerExpr` must agree with it,
    /// which is what keeps the emitted module free of stack leftovers and
    /// underflows.
    fn exprTail(self: *Emitter, e: ast.Expr) Tail {
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .comment => .none,
                else => .value,
            },
            .useHook => |uh| self.exprTail(uh.kind.inner.*),
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (cc.is_builtin) {
                        if (isVoidBuiltinCall(cc)) break :blk .none;
                        if (std.mem.eql(u8, cc.callee, "block")) {
                            if (cc.trailing.len == 0) break :blk .none;
                            break :blk self.bodyTail(cc.trailing[0].body);
                        }
                        break :blk .value;
                    }
                    if (self.primKindAt(cc, c.loc)) |k| {
                        const res = primCallRes(k, cc) orelse break :blk .value;
                        break :blk if (res == .none) Tail.none else Tail.value;
                    }
                    if (self.recordMethodSym(cc, c.loc)) |sym| {
                        if (self.fn_sigs.get(sym)) |sig| break :blk if (sig.result != null) Tail.value else Tail.none;
                    }
                    if (self.calleeSymbol(cc, c.loc)) |sym| {
                        if (self.fn_sigs.get(sym)) |sig| {
                            break :blk if (sig.result != null) Tail.value else Tail.none;
                        }
                    }
                    // Constructors, string/array ops and the unresolved-call
                    // stub all leave exactly one value.
                    break :blk .value;
                },
                .pipeline => .value,
            },
            .jump => |j| switch (j.kind) {
                .@"return", .throw_ => .terminated,
                .@"continue" => if (self.loop_depth > 0) Tail.terminated else Tail.none,
                .try_ => |v| if (v != null) Tail.value else Tail.none,
                .@"break" => |jl| if (jl.value != null)
                    (if (self.yield_target != null) Tail.none else Tail.value)
                else if (self.loop_depth > 0) Tail.terminated else Tail.none,
                .yield => |jl| if (jl.value != null and self.yield_target == null) Tail.value else Tail.none,
                .await_ => |a| self.exprTail(a.*),
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.exprTail(inner.*),
                else => .value,
            },
            .comptime_ => |ct| switch (ct.kind) {
                .assert, .assertPattern => .none,
                else => .value,
            },
            // Mirror `lowerIfExpr`: an `if` whose branches all end in a void
            // call is emitted in statement form and pushes nothing. Reporting
            // `.value` here made the statement loop `drop` an empty stack and
            // gave the enclosing `fn` a `(result i32)` it never fills.
            .branch => |b| switch (b.kind) {
                .if_ => |i| if (ifIsStatementForm(i)) Tail.none else Tail.value,
                .tryCatch => .value,
            },
            else => .value,
        };
    }

    /// The one predicate `lowerIfExpr`, `exprTail` and `fnHasResult` share:
    /// both arms void ⇒ no `(result …)` on the `(if …)`, no value pushed.
    fn ifIsStatementForm(i: anytype) bool {
        if (!branchIsVoid(i.then_)) return false;
        const els = i.else_ orelse return false;
        return branchIsVoid(els);
    }

    fn bodyTail(self: *Emitter, body: []const ast.Stmt) Tail {
        if (body.len == 0) return .none;
        return self.exprTail(body[body.len - 1].expr);
    }

    /// Lower `e` guaranteeing exactly one value on the stack. Used wherever an
    /// operand is required (call arguments, stores, bindings): a void-tailed
    /// expression gets a zero, a terminating one gets nothing (the stack is
    /// polymorphic after `return`/`unreachable`).
    fn lowerValue(self: *Emitter, e: ast.Expr) anyerror!void {
        const t = self.exprTail(e);
        try self.lowerExpr(e);
        if (t == .none) try self.pushZero();
    }

    /// Builtin calls that emit *no* operand-stack push (void on the wasm
    /// side). Matches the void arms of `lowerBuiltin` 1:1. New builtins
    /// added here must update this list or be wired through a producing
    /// arm in `lowerBuiltin`.
    fn isVoidBuiltinCall(cc: anytype) bool {
        if (!cc.is_builtin) return false;
        const eq = std.mem.eql;
        return eq(u8, cc.callee, "print") or
            eq(u8, cc.callee, "panic") or
            eq(u8, cc.callee, "todo");
    }

    // ── expressions ──────────────────────────────────────────────────────────

    fn lowerExpr(self: *Emitter, e: ast.Expr) anyerror!void {
        switch (e) {
            // `use` is a transparent prefix: lower the wrapped hook call. The
            // enclosing `val` stores the result into its local slot.
            .useHook => |uh| try self.lowerExpr(uh.kind.inner.*),
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| {
                    // The comptime folder parks *rendered* values (arrays,
                    // records, …) in a `numberLit` node, so the text is not
                    // always a numeral. `f32.const ["calc", …]` is a parse
                    // error that rejects the module — intern such a value as a
                    // string constant instead, which at least loads.
                    if (!isNumericLiteral(n)) {
                        const seg = try self.internString(n);
                        try self.emitC(try self.constInt(seg.offset), "folded non-numeric literal");
                    } else {
                        try self.emit(constOf(numLitType(n), n));
                    }
                },
                .null_ => try self.emit(zero),
                .stringLit => |s| {
                    const seg = try self.internString(try self.literalBytes(s));
                    try self.emit(try self.constInt(seg.offset));
                },
                // Desugared to a `+` chain by the transform pass; never reaches codegen.
                .stringTemplate => unreachable,
                .comment => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n0| {
                    const n = self.resolveName(n0);
                    // `true`/`false` are bound as identifiers (bool builtins),
                    // not literals. wasm has no boolean type — they lower to
                    // the same `i32` 0/1 a comparison yields. Without this they
                    // would emit `global.get $true`, referencing a global that
                    // is never defined.
                    if (std.mem.eql(u8, n, "true")) {
                        try self.emit(one);
                    } else if (std.mem.eql(u8, n, "false")) {
                        try self.emit(zero);
                    } else if (self.locals.contains(n)) {
                        try self.emit(.{ .local_get = n });
                    } else if (self.globals.contains(n)) {
                        try self.emit(.{ .global_get = n });
                    } else if (self.fn_sigs.contains(n)) {
                        try self.lowerFnRef(n);
                    } else if (self.findVariant(n)) |fv| {
                        // a bare unit variant (`Lt`)
                        try self.emitUnitVariant(fv.variants, fv.tag, "", n);
                    } else {
                        // Neither a local nor a module global: a `global.get`
                        // here would make the whole module unloadable
                        // ("unknown global"). Emit the zero carrier instead and
                        // record the gap.
                        try self.emitCf(zero, "unbound identifier {s}", .{n});
                    }
                },
                .dotIdent => |name| {
                    // `.Variant` — type inferred from context. Emit the variant
                    // tag if the name uniquely identifies a unit variant.
                    if (self.findVariant(name)) |fv| {
                        try self.emitUnitVariant(fv.variants, fv.tag, "", name);
                    } else {
                        try self.emitCf(zero, ".{s}", .{name});
                    }
                },
                .identAccess => |ia| try self.lowerIdentAccess(ia, id.loc),
            },
            .binaryOp => |bin| try self.lowerBinOp(bin.op, bin.lhs.*, bin.rhs.*),
            .unaryOp => |un| switch (un.op) {
                .neg => try self.lowerNeg(un.expr.*),
                .not => {
                    try self.lowerExpr(un.expr.*);
                    try self.emit(opOf("i32", "eqz"));
                },
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    // Static extension dispatch (F6) — resolve to the mangled
                    // linear-memory function `$<target>_<method>` before the
                    // ordinary call-kind handling.
                    if (try self.lowerDispatchCall(cc, c.loc)) return;
                    if (self.primKindAt(cc, c.loc)) |k| {
                        try self.lowerPrimMethod(k, cc);
                        return;
                    }
                    if (try self.lowerRecordMethod(cc, c.loc)) return;
                    if (self.assocSym(cc)) |sym_tmp| {
                        const sym = try self.arena().dupe(u8, sym_tmp);
                        try self.lowerCallArgs(cc.args, self.fn_sigs.get(sym).?, 0);
                        try self.emit(.{ .call = sym });
                        if (self.iface_assoc.contains(sym) and !self.assoc_emitted.contains(sym))
                            try self.assoc_needed.append(self.alloc, sym);
                        return;
                    }
                    // String slice method (`s.slice(a, b)`) — handled before the
                    // ctor/plain classification (codegen is untyped).
                    if (isStrSlice(cc)) {
                        try self.lowerStrSlice(cc);
                        return;
                    }
                    switch (self.callKind(cc)) {
                        .builtin => try self.lowerBuiltin(cc),
                        .record_ctor => try self.lowerRecordCtor(cc, self.records.get(cc.callee).?),
                        .enum_ctor => {
                            if (receiverName(cc)) |rcv| {
                                const variants = self.enums.get(rcv).?;
                                for (variants, 0..) |v, i| {
                                    if (std.mem.eql(u8, v.name, cc.callee)) {
                                        try self.lowerEnumCtor(cc, @intCast(i), v);
                                        return;
                                    }
                                }
                                try self.emitC(zero, "unknown variant");
                            } else if (self.findVariant(cc.callee)) |fv| {
                                try self.lowerEnumCtor(cc, fv.tag, fv.variant);
                            }
                        },
                        .plain => try self.lowerPlainCall(cc),
                    }
                },
                .pipeline => |pl| {
                    switch (pl.rhs.*) {
                        .identifier => |pid| switch (pid.kind) {
                            .ident => |name| {
                                if (self.fn_sigs.get(name)) |sig| {
                                    try self.lowerValue(pl.lhs.*);
                                    try self.emit(.{ .call = name });
                                    if (sig.result == null) try self.pushZero();
                                } else {
                                    try self.emitCf(zero, "unresolved pipeline target {s}", .{name});
                                }
                            },
                            else => try self.emitC(zero, "unsupported pipeline rhs"),
                        },
                        else => try self.lowerValue(pl.rhs.*),
                    }
                },
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| try self.lowerIfExpr(i),
                .tryCatch => |tc| try self.lowerTryCatch(tc),
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| try self.lowerExpr(inner.*),
                .case => |c| try self.lowerCase(c),
                .tupleLit => |tl| try self.lowerTupleLit(tl),
                .arrayLit => |al| try self.lowerArrayLit(al),
                .behaviorLit => |il| try self.lowerRecordLit(.{ .fields = il.fields }),
                .range => try self.emitC(zero, "range"),
            },
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| try self.lowerExpr(val.*);
                    try self.emit(.@"return");
                },
                .throw_ => |val| try self.lowerThrow(val),
                .try_ => |val| {
                    if (val) |v| try self.lowerTryPropagate(v.*);
                },
                .await_ => |av| try self.lowerExpr(av.*),
                .@"break" => |br| {
                    if (br.value) |v| {
                        if (self.yield_target != null) {
                            try self.emitYield(v.*);
                            if (self.cond_break_depth != null and self.cond_break_depth.? == self.loop_depth) try self.emit(.{ .br = break_label });
                        } else try self.lowerExpr(v.*);
                    } else if (self.loop_depth > 0) try self.emit(.{ .br = break_label });
                },
                .yield => |y| {
                    if (y.value) |v| {
                        if (self.yield_target != null) try self.emitYield(v.*) else try self.lowerExpr(v.*);
                    }
                },
                .@"continue" => if (self.loop_depth > 0)
                    try self.emit(.{ .br = next_label })
                else
                    try self.note("continue outside a loop"),
            },
            .comptime_ => |ct| switch (ct.kind) {
                .assert => |a| try self.lowerAssert(a, ct.loc),
                .assertPattern => |ap| try self.lowerAssertPattern(ap),
                else => try self.emit(zero),
            },
            .function => |f| try self.lowerLambdaValue(f.kind.params, f.kind.body),
            .loop => |lp| try self.lowerLoop(lp),
            else => try self.noteF("unsupported expr: {s}", .{@tagName(e)}),
        }
    }

    // A `@Result` lives in linear memory as a pointer: the tag is the `i32` at
    // `[ptr]` (0 = Ok, non-zero = Error) and the payload is the `i32` at `[ptr+4]`.
    // `try`/`catch` branch on that tag with `if`/`else` — never host exceptions.

    /// `try expr catch handler` → load the tag; Ok yields `[ptr+4]`, Error runs
    /// the handler. Leaves the resulting value on the stack.
    /// `assert cond[, msg]` — always fatal (decision 4 of the 1.0.2-beta
    /// semantics decisions): when `cond` is false the module writes
    /// `<module>.bp:<line>: assertion failed[: <msg>]` to stderr and traps.
    fn lowerAssert(self: *Emitter, a: anytype, loc: ast.Loc) anyerror!void {
        try self.lowerCoerced(a.condition.*, "i32");
        try self.emit(opOf("i32", "eqz"));
        var then_c: Capture = .{};
        self.open(&then_c);
        const file = if (self.module_name.len > 0) self.module_name else "main";
        const where = try self.internString(try std.fmt.allocPrint(self.arena(), "{s}.bp:{d}", .{ file, loc.line }));
        try self.emit(try self.constInt(where.offset));
        if (a.message) |m| try self.lowerCoerced(m.*, "i32") else try self.emit(zero);
        try self.emit(self.builder().helper(.assert_fail));
        try self.emit(.@"unreachable");
        const then_seq = self.seal(&then_c, .terminated);
        try self.emit(.{ .@"if" = .{ .then = .{ .seq = then_seq } } });
    }

    /// `val assert P = e [catch h];` (decision 8 § 9). The subject is staged in
    /// a local, the pattern's own test decides, and the pattern's names are
    /// bound in the function's locals — where the statements after it read
    /// them. A mismatch runs the handler: the `@panic(…)` the parser desugars
    /// the handler-less form to traps, a written `catch <value>` replaces the
    /// staged subject so the bindings come from it.
    ///
    /// `bindPattern` covers identifier and variant patterns. A list pattern
    /// binds nothing here, exactly as a `case` arm's does not — wasm has no
    /// array test yet (`patternIsIrrefutable`).
    /// True when `emitPatternTest` produces a real test for `p`. A variant
    /// pattern naming neither an enum variant nor a `@Result` arm — a record
    /// constructor, say — falls back to a constant `0`, which as a `val
    /// assert` test would mean "never matches" and make every such assert
    /// fatal. There the assert is lowered as a plain binding instead, which is
    /// what the construct did before it was lowered at all.
    fn patternTestIsReal(self: *Emitter, p: ast.Pattern) bool {
        return switch (p) {
            .variant => |v| self.variantRef(v.name) != null,
            .@"or" => |pats| blk: {
                for (pats) |sub| {
                    if (!self.patternTestIsReal(sub)) break :blk false;
                }
                break :blk true;
            },
            else => true,
        };
    }

    fn lowerAssertPattern(self: *Emitter, ap: anytype) anyerror!void {
        const slot = try std.fmt.allocPrint(self.arena(), "__assert_{d}", .{self.assert_seq});
        self.assert_seq += 1;
        try self.declareLocal(slot, "i32");
        try self.lowerCoerced(ap.expr.*, "i32");
        try self.emit(.{ .local_set = slot });
        if (self.isStringExpr(ap.expr.*)) try self.str_locals.put(slot, {});
        if (self.resultShapeOf(ap.expr.*)) |shape| try self.result_subjects.put(slot, shape);

        if (!self.patternIsIrrefutable(ap.pattern) and self.patternTestIsReal(ap.pattern)) {
            try self.emitPatternTest(ap.pattern, slot);
            try self.emit(opOf("i32", "eqz"));
            var then_c: Capture = .{};
            self.open(&then_c);
            const handler_tail = self.exprTail(ap.handler.*);
            try self.lowerExpr(ap.handler.*);
            if (handler_tail == .value) try self.emit(.{ .local_set = slot });
            const then_seq = self.seal(&then_c, if (handler_tail == .terminated) .terminated else .none);
            try self.emit(.{ .@"if" = .{ .then = .{ .seq = then_seq } } });
        }
        try self.bindPattern(ap.pattern, slot);
    }

    /// `throw e`. Inside a fn that returns a `@Result` the transform rewrites
    /// the common forms into `return __bp_error(e)`; one it left behind (inside
    /// a `case` arm, say) still returns the Error rather than trapping. Anywhere
    /// else there is nothing to unwind to, so it traps.
    fn lowerThrow(self: *Emitter, val: ?*ast.Expr) anyerror!void {
        if (self.fn_returns_result and self.fn_has_result) {
            const slot = try self.declRes();
            try self.allocResultPair(slot);
            try self.emit(.{ .local_get = slot });
            try self.emit(one);
            try self.emitC(.{ .store = .{} }, "Result tag (Error)");
            try self.emit(.{ .local_get = slot });
            if (val) |v| try self.lowerCoerced(v.*, "i32") else try self.emit(zero);
            try self.emitC(.{ .store = .{ .offset = 4 } }, "payload");
            try self.emit(.{ .local_get = slot });
            try self.emit(.@"return");
            return;
        }
        if (val) |v| {
            try self.lowerValue(v.*);
            try self.emit(.drop);
        }
        try self.emit(.@"unreachable");
    }

    fn lowerTryCatch(self: *Emitter, tc: anytype) anyerror!void {
        const slot = try self.tryName(self.try_seq);
        self.try_seq += 1;
        try self.declareLocal(slot, "i32");
        try self.lowerValue(tc.expr.*);
        try self.emit(.{ .local_set = slot });
        try self.emit(.{ .local_get = slot });
        try self.emitC(.{ .load = .{} }, result_tag);

        const ty = vt(self.cur_result);
        var then_c: Capture = .{};
        self.open(&then_c);
        try self.lowerExpr(tc.handler.*);
        const then_seq = self.seal(&then_c, .{ .value = ty });

        var else_c: Capture = .{};
        self.open(&else_c);
        try self.emit(.{ .local_get = slot });
        try self.emitC(.{ .load = .{ .offset = 4 } }, ok_payload);
        const else_seq = self.seal(&else_c, .{ .value = ty });

        try self.emit(.{ .@"if" = .{
            .result = ty,
            .then = .{ .seq = then_seq },
            .@"else" = .{ .seq = else_seq },
        } });
    }

    /// `try expr` (no catch) → unwrap the Ok payload, or `return` the Result
    /// pointer unchanged to propagate the Error variant up. Leaves the unwrapped
    /// Ok payload on the stack.
    fn lowerTryPropagate(self: *Emitter, inner: ast.Expr) anyerror!void {
        const slot = try self.tryName(self.try_seq);
        self.try_seq += 1;
        try self.declareLocal(slot, "i32");
        try self.lowerValue(inner);
        try self.emit(.{ .local_set = slot });
        try self.emit(.{ .local_get = slot });
        try self.emitC(.{ .load = .{} }, result_tag);

        var then_c: Capture = .{};
        self.open(&then_c);
        try self.emit(.{ .local_get = slot });
        try self.emitC(.@"return", "propagate Error");
        const then_seq = self.seal(&then_c, .terminated);

        try self.emit(.{ .@"if" = .{ .then = .{ .seq = then_seq } } });
        try self.emit(.{ .local_get = slot });
        try self.emitC(.{ .load = .{ .offset = 4 } }, ok_payload);
    }

    /// One `@print` argument. `last` decides whether the trailing newline is
    /// emitted here (the `_raw` helpers write the value only). The printer is
    /// picked from the argument's recovered shape — everything used to go
    /// through `$__print_i32`, so a string printed as its *address* and a bool
    /// as `0`/`1`.
    fn lowerPrintArg(self: *Emitter, arg: ast.Expr, last: bool) anyerror!void {
        // §7 F2/F3 are not this front's — a value has to know which named type
        // it is at run time, which is `13-module-identity`. Until then a record
        // or a variant reaching `@print` has **no text**, and the numeric
        // printer answered its heap address: `328`, `336`, `344` with exit 0 and
        // no diagnostic. That is the one thing this backend must not do, and it
        // already has the mechanism for a shape it cannot write — the trap 24
        // fixtures record. So it traps, and the wrong number is gone.
        if (self.namedShapeOf(arg)) |ns| {
            try self.emitCf(.@"unreachable", "§7 F{d}: no printed form for a {s} yet (13-module-identity)", .{
                @as(u8, if (ns == .record) 2 else 3),
                @tagName(ns),
            });
            return;
        }
        if (self.optInfoOf(arg)) |oi| {
            try self.lowerValue(arg);
            const b = self.builder();
            try self.emit(if (oi.boxed)
                b.helper(if (oi.bool_)
                    (if (last) .print_opt_bool else .print_opt_bool_raw)
                else if (oi.float_)
                    (if (last) .print_opt_f32 else .print_opt_f32_raw)
                else if (last) .print_opt_i32 else .print_opt_i32_raw)
            else if (oi.str)
                b.helper(if (last) .print_opt_str else .print_opt_str_raw)
            else
                b.helper(if (last) .print_i32 else .print_i32_raw));
            return;
        }
        if (self.isStringExpr(arg)) {
            try self.lowerValue(arg);
            try self.emit(self.builder().helper(if (last) .print_str else .print_str_raw));
            return;
        }
        if (self.isBoolExpr(arg)) {
            try self.lowerCoerced(arg, "i32");
            try self.emit(self.builder().helper(if (last) .print_bool else .print_bool_raw));
            return;
        }
        // An array of strings, a tuple, an array of tuples: the shape-driven
        // printer (semantics decision 1a). A flat i32/f32 array keeps its own.
        if (try self.printShapeOf(arg)) |shape| if (!std.mem.eql(u8, shape, "[i") and !std.mem.eql(u8, shape, "[f")) {
            try self.lowerCoerced(arg, "i32");
            const seg = try self.internString(shape);
            try self.emit(try self.constInt(seg.offset + 4));
            try self.emit(try self.constInt(1));
            try self.emit(self.builder().helper(.print_shaped_raw));
            try self.emit(.drop);
            if (last) try self.emit(self.builder().helper(.print_nl));
            return;
        };
        if (self.isArrayExpr(arg)) switch (self.elemKindOf(arg)) {
            .i32 => {
                try self.lowerCoerced(arg, "i32");
                try self.emit(self.builder().helper(if (last) .print_arr_i32 else .print_arr_i32_raw));
                return;
            },
            .f32 => {
                try self.lowerCoerced(arg, "i32");
                try self.emit(self.builder().helper(if (last) .print_arr_f32 else .print_arr_f32_raw));
                return;
            },
            .str => {},
        };
        const t = self.wasmTypeOf(arg);
        if (t[0] == 'f') {
            try self.lowerCoerced(arg, "f64");
            try self.emit(self.builder().helper(if (last) .print_f64 else .print_f64_raw));
            return;
        }
        try self.lowerCoerced(arg, "i32");
        try self.emit(self.builder().helper(if (last) .print_i32 else .print_i32_raw));
    }

    fn lowerBuiltin(self: *Emitter, cc: anytype) anyerror!void {
        if (std.mem.eql(u8, cc.callee, "todo") or std.mem.eql(u8, cc.callee, "panic")) {
            try self.emit(.@"unreachable");
            return;
        }
        if (std.mem.eql(u8, cc.callee, "block")) {
            if (cc.trailing.len > 0) _ = try self.emitBody(cc.trailing[0].body, true);
            return;
        }
        if (std.mem.eql(u8, cc.callee, "print")) {
            // Marks the print helper group even for `@print()` with no
            // arguments, matching the historical `uses_print` flag.
            _ = self.builder().helper(.print_nl);
            if (cc.args.len == 0) return;
            // `@print(a, b, c)` is one line with the parts space-separated, the
            // shape node and erlang print. Only the first argument used to be
            // emitted at all.
            for (cc.args, 0..) |a, i| {
                if (i > 0) try self.emit(self.builder().helper(.print_sp));
                try self.lowerPrintArg(a.value.*, i + 1 == cc.args.len);
            }
            return;
        }
        if (std.mem.eql(u8, cc.callee, ast.index_builtin_name)) {
            try self.lowerIndex(cc);
            return;
        }
        if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
            try self.lowerResultOptionOp(cc.callee, cc.args);
            return;
        }
        // Decorator / template builtins (`@emit`, `@compilerError`,
        // `Binding.ref`) only exist inside comptime bodies, which never reach
        // this backend: the comptime pass runs them on `erl`. There is nothing
        // in a program module to call, so a program that reaches one traps —
        // the same honest shape as an unresolved call.
        if (std.mem.eql(u8, cc.callee, "emit") or
            std.mem.eql(u8, cc.callee, "compilerError") or
            std.mem.eql(u8, cc.callee, "ref"))
        {
            try self.emitCf(.@"unreachable", "comptime-only builtin: {s}", .{cc.callee});
            return;
        }
        try self.note("builtin stub");
    }

    /// Decision 30's index expression, which the parser lands as the reserved
    /// builtin call `ast.index_builtin_name` over `(receiver, index)`. One node
    /// serves four readings, told apart by the receiver and by whether the
    /// index is a range (`decision-8:447` — `..` is iteration **and** slicing):
    ///
    /// | Written | Lowering |
    /// |---|---|
    /// | `xs[i]` | `$__arr_at` — the element itself, `0` out of range |
    /// | `xs[a..b]` | `$__arr_slice` — a fresh array, bounds clamped |
    /// | `s[i]` | `$__str_slice(s, i, i+1)` — the one-byte string |
    /// | `s[a..b]` | `$__str_slice` |
    ///
    /// **`xs[i]` answers `T`, not `?T`** — the reading every other language
    /// gives it, and the one `$__arr_at` already implements for the `.at()`
    /// method on a string array. Which of the two decision 30 means is
    /// `01-checker`'s to settle (`ast.zig:1734`); if it settles on `?T` this is
    /// one helper swap (`.arr_at` → `.arr_at_box`) and the fixtures move with it.
    ///
    /// A receiver that is neither an array nor a string — a `Dict`, above all —
    /// has no lowering here: `d["k"]` is `Dict.lookup` through a std record, and
    /// this backend inlines std rather than linking it. It traps rather than
    /// answering a number nothing put there.
    /// The `(receiver, index)` of an index call, and whether the index is a
    /// range — `null` for every other call. The one question the type
    /// predicates (`isStringExpr`, `isArrayExpr`, `elemKindOf`) ask about it.
    const IndexArgs = struct { recv: ast.Expr, idx: ast.Expr, is_slice: bool };

    fn indexArgs(self: *Emitter, cc: anytype) ?IndexArgs {
        _ = self;
        if (!cc.is_builtin or !std.mem.eql(u8, cc.callee, ast.index_builtin_name)) return null;
        if (cc.args.len != 2) return null;
        const idx = cc.args[1].value.*;
        const is_slice = switch (idx) {
            .collection => |col| col.kind == .range,
            else => false,
        };
        return .{ .recv = cc.args[0].value.*, .idx = idx, .is_slice = is_slice };
    }

    /// The print shape of `xs[i]` — one `[` stripped off the receiver's shape —
    /// when that element is itself a blob (`[[i` → `[i`, `[(is)` → `(is)`).
    /// Null for a slice, for a scalar element and for a receiver whose shape is
    /// unknown. This is what tells `rows[1]` from `xs[1]`: without it a nested
    /// index had no lowering and trapped (`index on an unknown receiver`).
    ///
    /// It must not call `isArrayExpr` on the index node itself: `isArrayExpr`
    /// asks *this* question, and `printShapeOf` ends by asking `isArrayExpr`.
    /// Only the receiver — structurally smaller — is walked.
    fn indexElemShape(self: *Emitter, cc: anytype) anyerror!?[]const u8 {
        const ix = self.indexArgs(cc) orelse return null;
        if (ix.is_slice) return null;
        const outer = try self.printShapeOf(ix.recv) orelse return null;
        if (outer.len < 2 or outer[0] != '[') return null;
        const inner = outer[1..];
        return if (inner[0] == '[' or inner[0] == '(') inner else null;
    }

    fn lowerIndex(self: *Emitter, cc: anytype) anyerror!void {
        const b = self.builder();
        const recv = cc.args[0].value.*;
        const idx = cc.args[1].value.*;
        const is_str = self.isStringExpr(recv);
        const is_arr = self.isArrayExpr(recv);

        // `xs[a..b]` — the same node, with a range where the index goes.
        const range = switch (idx) {
            .collection => |col| switch (col.kind) {
                .range => |r| r,
                else => null,
            },
            else => null,
        };
        if (range) |r| {
            if (!is_str and !is_arr) {
                try self.emitCf(.@"unreachable", "index slice on an unknown receiver", .{});
                return;
            }
            try self.lowerCoerced(recv, "i32");
            try self.lowerCoerced(r.start.*, "i32");
            if (r.end) |e| {
                try self.lowerCoerced(e.*, "i32");
            } else if (is_str) {
                // to the end: the source's length prefix
                try self.lowerCoerced(recv, "i32");
                try self.emitC(.{ .load = .{} }, "source length");
            } else {
                // `$__arr_slice` clamps, so "to the end" is the largest i32
                try self.emit(try self.constInt(std.math.maxInt(i32)));
            }
            try self.emit(b.helper(if (is_str) .str_slice else .arr_slice));
            return;
        }

        if (is_str) {
            // `s[i]` is the one-byte string at `i`, the `char` §7 prints.
            const at = try self.declRes();
            try self.lowerCoerced(idx, "i32");
            try self.emit(.{ .local_set = at });
            try self.lowerCoerced(recv, "i32");
            try self.emit(.{ .local_get = at });
            try self.emit(.{ .local_get = at });
            try self.emit(one);
            try self.emit(opOf("i32", "add"));
            try self.emit(b.helper(.str_slice));
            return;
        }
        if (is_arr) {
            try self.lowerCoerced(recv, "i32");
            try self.lowerCoerced(idx, "i32");
            try self.emit(b.helper(.arr_at));
            // A float array's slots are `f32`: `$__arr_at` answers the four
            // bytes, which are the float's *bits*. `fs.at(0)` still prints
            // them as an integer (`1069547520` for `1.5`) — the same gap, in
            // the primitive-method path this front's step 6 audits.
            if (self.elemKindOf(recv) == .f32) try self.emit(.{ .convert = "f32.reinterpret_i32" });
            return;
        }
        try self.emitCf(.@"unreachable", "index on an unknown receiver", .{});
    }

    /// Reserve and declare the next `$_res{n}` scratch pointer local. Declared
    /// inline (like the `$__case` locals) since the count isn't known up front.
    /// Bump the heap by the two `i32` slots a `@Result` occupies, leaving the
    /// base pointer in the scratch local `slot`.
    fn allocResultPair(self: *Emitter, slot: []const u8) !void {
        try self.emit(.{ .global_get = heap_ptr });
        try self.emit(.{ .local_set = slot });
        try self.emit(.{ .global_get = heap_ptr });
        try self.emit(try self.constInt(8));
        try self.emit(opOf("i32", "add"));
        try self.emit(.{ .global_set = heap_ptr });
    }

    fn declRes(self: *Emitter) ![]const u8 {
        const name = try self.resName(self.res_seq);
        self.res_seq += 1;
        try self.declareLocal(name, "i32");
        return name;
    }

    /// True when `arg` is a literal lambda (`{ x -> ... }`), the only fn form a
    /// higher-order Result/Option op can inline on WASM (there is no first-class
    /// closure value in this backend — `.function` otherwise lowers to `0`).
    fn lambdaArg(arg: ?*ast.Expr) ?*ast.Expr {
        const a = arg orelse return null;
        if (a.* != .function) return null;
        if (a.function.kind.syntax != .lambda) return null;
        return a;
    }

    /// Bind a single-param lambda's parameter to a value held in `src` (a local
    /// name), declaring the parameter local on first use. A zero-param lambda
    /// ignores the value.
    fn bindLambdaParam(self: *Emitter, lam: anytype, src: []const u8) !void {
        if (lam.params.len == 0) return;
        const p = lam.params[0];
        try self.declareLocal(p, "i32");
        try self.emit(.{ .local_get = src });
        try self.emit(.{ .local_set = p });
    }

    /// Inline a lambda body, leaving its tail value on the stack. An explicit
    /// `return` tail is unwrapped to its value (a bare `return` opcode would
    /// exit the *enclosing* function, not the inlined closure).
    fn inlineLambdaBody(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        if (body.len == 0) {
            try self.emit(zero);
            return;
        }
        for (body[0 .. body.len - 1]) |s| _ = try self.emitStmt(s, false);
        const last = body[body.len - 1];
        switch (last.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |v| try self.lowerValue(v.*) else try self.emit(zero);
                    return;
                },
                else => {},
            },
            else => {},
        }
        _ = try self.emitStmt(last, true);
    }

    /// Lower a `__bp_<domain>_<op>(receiver, arg?)` Result/Option method op.
    /// A `@Result` is a pointer to two `i32` slots — `[ptr]` is the tag (0 = Ok,
    /// non-zero = Error), `[ptr+4]` the payload — matching `try`/`catch`. A
    /// `@Option` is the bare value, with `0` standing for absence. `map`/`flatMap`
    /// inline the closure body (there are no first-class funs here); the other
    /// ops are pure tag tests / payload loads.
    fn lowerResultOptionOp(self: *Emitter, callee: []const u8, args: anytype) anyerror!void {
        const recv = args[0].value;
        const arg1: ?*ast.Expr = if (args.len > 1) args[1].value else null;

        // §1F F4F-T2 — `#[@future]` post-transform markers. wat's #[@future]
        // lowering is eager (Frente A §C2 is what wires `botopink test --target
        // wasm`); strip the resolved marker back to the inner value. The
        // rejected marker is a trap (wat has no `throw` op; future runtime is
        // gated on Frente A §D-D4).
        if (std.mem.eql(u8, callee, "__bp_future_resolved")) {
            try self.lowerExpr(recv.*);
            return;
        }
        if (std.mem.eql(u8, callee, "__bp_future_rejected")) {
            try self.emitC(.@"unreachable", "@future rejection (wat runtime: Frente A §D-D4)");
            return;
        }
        if (std.mem.eql(u8, callee, "__bp_ok") or std.mem.eql(u8, callee, "__bp_error")) {
            // Result constructor (`return v` / `throw e` in a `-> @Result<…>`
            // fn): allocate a fresh `{ tag, payload }` pair (tag 0 = Ok, 1 = Error).
            const tag: u8 = if (std.mem.eql(u8, callee, "__bp_ok")) 0 else 1;
            const slot = try self.declRes();
            try self.allocResultPair(slot);
            try self.emit(.{ .local_get = slot });
            try self.emit(try self.constInt(tag));
            try self.emitCf(.{ .store = .{} }, "Result tag ({s})", .{if (tag == 0) "Ok" else "Error"});
            try self.emit(.{ .local_get = slot });
            try self.lowerExpr(recv.*);
            try self.emitC(.{ .store = .{ .offset = 4 } }, "payload");
            try self.emit(.{ .local_get = slot });
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_map") or std.mem.eql(u8, callee, "__bp_result_flatMap")) {
            const is_map = std.mem.eql(u8, callee, "__bp_result_map");
            const le = lambdaArg(arg1) orelse {
                try self.note("map/flatMap needs a literal closure on WASM — receiver passed through");
                try self.lowerExpr(recv.*);
                return;
            };
            const lam = le.function.kind;
            const slot = try self.declRes();
            try self.lowerExpr(recv.*);
            try self.emit(.{ .local_set = slot });
            try self.emit(.{ .local_get = slot });
            try self.emitC(.{ .load = .{} }, result_tag);

            var then_c: Capture = .{};
            self.open(&then_c);
            try self.emitC(.{ .local_get = slot }, "Error — propagate unchanged");
            const then_seq = self.seal(&then_c, .{ .value = .i32 });

            var else_c: Capture = .{};
            self.open(&else_c);
            // Ok: bind the closure param to the payload, then apply it.
            try self.emit(.{ .local_get = slot });
            try self.emitC(.{ .load = .{ .offset = 4 } }, ok_payload);
            try self.emit(.{ .local_set = slot });
            try self.bindLambdaParam(lam, slot);
            if (is_map) {
                // Rewrap the mapped value as a fresh `{ tag: 0, payload }` Result.
                const out = try self.declRes();
                try self.allocResultPair(out);
                try self.emit(.{ .local_get = out });
                try self.emit(zero);
                try self.emitC(.{ .store = .{} }, "Ok tag");
                try self.emit(.{ .local_get = out });
                try self.inlineLambdaBody(lam.body);
                try self.emitC(.{ .store = .{ .offset = 4 } }, "mapped payload");
                try self.emit(.{ .local_get = out });
            } else {
                // flatMap: the closure already yields a `@Result` pointer.
                try self.inlineLambdaBody(lam.body);
            }
            const else_seq = self.seal(&else_c, .{ .value = .i32 });

            try self.emit(.{ .@"if" = .{
                .result = .i32,
                .then = .{ .seq = then_seq },
                .@"else" = .{ .seq = else_seq },
            } });
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_unwrapOr")) {
            const slot = try self.declRes();
            try self.lowerExpr(recv.*);
            try self.emit(.{ .local_set = slot });
            try self.emit(.{ .local_get = slot });
            try self.emitC(.{ .load = .{} }, result_tag);

            var then_c: Capture = .{};
            self.open(&then_c);
            if (arg1) |d| try self.lowerExpr(d.*) else try self.emit(zero);
            const then_seq = self.seal(&then_c, .{ .value = .i32 });

            var else_c: Capture = .{};
            self.open(&else_c);
            try self.emit(.{ .local_get = slot });
            try self.emitC(.{ .load = .{ .offset = 4 } }, ok_payload);
            const else_seq = self.seal(&else_c, .{ .value = .i32 });

            try self.emit(.{ .@"if" = .{
                .result = .i32,
                .then = .{ .seq = then_seq },
                .@"else" = .{ .seq = else_seq },
            } });
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_isOk")) {
            try self.lowerExpr(recv.*);
            try self.emitC(.{ .load = .{} }, "Result tag");
            try self.emitC(opOf("i32", "eqz"), "isOk = (tag == 0)");
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_isError")) {
            try self.lowerExpr(recv.*);
            try self.emitC(.{ .load = .{} }, "Result tag");
            try self.emit(zero);
            try self.emitC(opOf("i32", "ne"), "isError = (tag != 0)");
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_option_map") or std.mem.eql(u8, callee, "__bp_option_flatMap")) {
            const le = lambdaArg(arg1) orelse {
                try self.note("map/flatMap needs a literal closure on WASM — receiver passed through");
                try self.lowerExpr(recv.*);
                return;
            };
            const lam = le.function.kind;
            const boxed = self.optionIsBoxed(recv.*, null);
            const is_map = std.mem.eql(u8, callee, "__bp_option_map");
            const slot = try self.declRes();
            try self.lowerExpr(recv.*);
            try self.emit(.{ .local_set = slot });
            try self.emitC(.{ .local_get = slot }, option_shape);

            var then_c: Capture = .{};
            self.open(&then_c);
            // Some: apply the closure to the payload.
            if (lam.params.len > 0) {
                try self.declareLocal(lam.params[0], "i32");
                try self.emit(.{ .local_get = slot });
                if (boxed) try self.emitC(.{ .load = .{} }, "optional payload");
                try self.emit(.{ .local_set = lam.params[0] });
            }
            const tail_boxes = is_map and !self.lambdaTailIsPointer(lam.body);
            try self.inlineLambdaBody(lam.body);
            // `map`'s result is an optional again: a scalar goes back in a box.
            if (tail_boxes) try self.emit(self.builder().helper(.box_i32));
            const then_seq = self.seal(&then_c, .{ .value = .i32 });

            var else_c: Capture = .{};
            self.open(&else_c);
            try self.emitC(zero, "None — propagate absence");
            const else_seq = self.seal(&else_c, .{ .value = .i32 });

            try self.emit(.{ .@"if" = .{
                .result = .i32,
                .then = .{ .seq = then_seq },
                .@"else" = .{ .seq = else_seq },
            } });
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_option_unwrapOr")) {
            const slot = try self.declRes();
            try self.lowerExpr(recv.*);
            try self.emit(.{ .local_set = slot });
            try self.emitC(.{ .local_get = slot }, option_shape);

            var then_c: Capture = .{};
            self.open(&then_c);
            try self.emitC(.{ .local_get = slot }, "Some — present value");
            if (self.optionIsBoxed(recv.*, arg1)) try self.emitC(.{ .load = .{} }, "optional payload");
            const then_seq = self.seal(&then_c, .{ .value = .i32 });

            var else_c: Capture = .{};
            self.open(&else_c);
            if (arg1) |d| try self.lowerExpr(d.*) else try self.emit(zero);
            const else_seq = self.seal(&else_c, .{ .value = .i32 });

            try self.emit(.{ .@"if" = .{
                .result = .i32,
                .then = .{ .seq = then_seq },
                .@"else" = .{ .seq = else_seq },
            } });
            return;
        }

        try self.noteF("unsupported Result/Option op: {s}", .{callee});
    }

    /// True when `e` evaluates to the 0/1 boolean carrier: the `true`/`false`
    /// identifiers, a comparison, `!x`, `&&`/`||`, or a call to a fn declared
    /// `-> bool`.
    fn isBoolExpr(self: *Emitter, e: ast.Expr) bool {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| std.mem.eql(u8, n, "true") or std.mem.eql(u8, n, "false") or
                    self.bool_locals.contains(self.resolveName(n)) or self.bool_globals.contains(n),
                else => false,
            },
            .unaryOp => |un| un.op == .not,
            .binaryOp => |bin| switch (bin.op) {
                .eq, .ne, .lt, .gt, .lte, .gte => true,
                .@"and", .@"or" => self.isBoolExpr(bin.lhs.*) or self.isBoolExpr(bin.rhs.*),
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.isBoolExpr(inner.*),
                else => false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (cc.is_builtin) break :blk std.mem.eql(u8, cc.callee, "__bp_result_isOk") or
                        std.mem.eql(u8, cc.callee, "__bp_result_isError");
                    if (self.primKindAt(cc, c.loc)) |k| break :blk primCallRes(k, cc) == .bool_;
                    if (self.resolvedCallSym(cc, c.loc)) |sym| break :blk self.bool_fns.contains(sym);
                    break :blk false;
                },
                else => false,
            },
            .useHook => |uh| self.isBoolExpr(uh.kind.inner.*),
            else => false,
        };
    }

    fn lowerCase(self: *Emitter, c: anytype) anyerror!void {
        if (c.subjects.len == 0 or c.arms.len == 0) {
            try self.emit(zero);
            return;
        }
        const subj_local = try std.fmt.allocPrint(self.arena(), "__case_{d}", .{self.case_depth});
        self.case_depth += 1;
        try self.declareLocal(subj_local, "i32");
        try self.lowerCoerced(c.subjects[0], "i32");
        try self.emit(.{ .local_set = subj_local });
        const subj_is_str = self.isStringExpr(c.subjects[0]);
        if (subj_is_str) try self.str_locals.put(subj_local, {});
        if (self.resultShapeOf(c.subjects[0])) |shape| try self.result_subjects.put(subj_local, shape);

        try self.emitCaseArms(c.arms, subj_local, 0);
    }

    fn emitCaseArms(self: *Emitter, arms: anytype, subj: []const u8, idx: usize) anyerror!void {
        if (idx >= arms.len) {
            try self.emit(constOf(self.cur_result, "0"));
            return;
        }
        const arm = arms[idx];
        if (self.patternIsIrrefutable(arm.pattern)) {
            try self.bindPattern(arm.pattern, subj);
            // A guard makes even `_` refutable: a failing guard falls through
            // to the next arm (§5.3), so there is still a chain to emit.
            if (arm.guard) |g| {
                try self.emitGuardChain(arms, subj, idx, g);
            } else {
                try self.lowerArmBody(arm.body, subj);
            }
            self.aliases.clearRetainingCapacity();
            return;
        }
        try self.emitPatternTest(arm.pattern, subj);
        try self.emitArmChain(arms, subj, idx, arm.body);
    }

    /// `(if <guard> (then <arm body>) (else <rest of the chain>))`, the
    /// pattern's names already bound. Decision 8 §5.3: the guard is read after
    /// the binding, and a failing one falls through. Dropping it — which is
    /// what this backend did until now — made every guarded arm match
    /// unconditionally (`case_guard_bound_identifier_numeric_guard` answered
    /// `"positive"` for every `n`).
    fn emitGuardChain(self: *Emitter, arms: anytype, subj: []const u8, idx: usize, guard: ast.Expr) anyerror!void {
        const ty = vt(self.cur_result);
        try self.lowerCoerced(guard, "i32");

        var ok_c: Capture = .{};
        self.open(&ok_c);
        try self.lowerArmBody(arms[idx].body, subj);
        const ok_seq = self.seal(&ok_c, .{ .value = ty });

        var no_c: Capture = .{};
        self.open(&no_c);
        try self.emitCaseArms(arms, subj, idx + 1);
        const no_seq = self.seal(&no_c, .{ .value = ty });

        try self.emit(.{ .@"if" = .{
            .result = ty,
            .then = .{ .seq = ok_seq },
            .@"else" = .{ .seq = no_seq },
        } });
    }

    /// Decision 8 §5.1 P1/P3: an arm written `Pattern { … }` — and the
    /// pre-decision-8 `-> { … }` block arm — arrives as a **lambda**: a leading
    /// `name ->` binds the whole matched value and the last expression is the
    /// arm's value. It is not a function value, so it is inlined here. Lowering
    /// it as a value lifted the body into the function table and left the arm
    /// answering a closure-cell address (`case_or_patterns_with_block_arm_body`
    /// recorded that as `$__lambda0` plus a 4-byte cell).
    const ArmLambda = struct { params: []const []const u8, body: []const ast.Stmt };

    fn armLambda(body: ast.Expr) ?ArmLambda {
        if (body != .function) return null;
        const k = body.function.kind;
        if (k.syntax != .lambda or k.params.len > 1) return null;
        return .{ .params = k.params, .body = k.body };
    }

    /// The arm's value, coerced to the case's result type.
    fn lowerArmBody(self: *Emitter, body: ast.Expr, subj: []const u8) anyerror!void {
        const lam = armLambda(body) orelse {
            try self.lowerCoerced(body, self.cur_result);
            return;
        };
        // P1: the single parameter binds the whole matched value.
        if (lam.params.len == 1) {
            const p = lam.params[0];
            try self.declareLocal(p, "i32");
            if (self.str_locals.contains(subj)) try self.str_locals.put(p, {});
            if (self.local_types.get(subj)) |t| try self.local_types.put(p, t);
            try self.emit(.{ .local_get = subj });
            try self.emit(.{ .local_set = p });
        }
        if (lam.body.len == 0) {
            try self.emit(constOf(self.cur_result, "0"));
            return;
        }
        for (lam.body[0 .. lam.body.len - 1]) |s| _ = try self.emitStmt(s, false);
        const last = lam.body[lam.body.len - 1];
        // P3: the last expression is the value; an explicit `break v` carries
        // it instead — the shape the pre-decision-8 block arm is written with.
        switch (last.expr) {
            .jump => |j| switch (j.kind) {
                .@"break" => |br| if (br.value) |v| {
                    if (self.yield_target == null) {
                        try self.lowerCoerced(v.*, self.cur_result);
                        return;
                    }
                },
                else => {},
            },
            .binding => {
                // `val x = …` in tail position is not a value
                _ = try self.emitStmt(last, false);
                try self.emit(constOf(self.cur_result, "0"));
                return;
            },
            else => {},
        }
        const from = self.wasmTypeOf(last.expr);
        const tail = try self.emitStmt(last, true);
        if (tail == .value) try self.emitConvert(from, self.cur_result);
    }

    // ── case patterns ────────────────────────────────────────────────────────
    //
    // A pattern is a test (`emitPatternTest`, leaves an i32) plus the bindings
    // its arm sees (`bindPattern`, run at the top of the arm). What a variant
    // test reads depends on how the subject is laid out:
    //   * a variant of a user enum whose variants are all units is its tag, an
    //     i32 (`Color.Red` = 0);
    //   * a variant of an enum with any payload is a pointer to `[tag, …fields]`
    //     — unit variants of such an enum are allocated too, so every value of
    //     the enum has the same shape;
    //   * `Ok(v)` / `Err(e)` on a `@Result` read the `[tag, payload]` pair
    //     (tag 0 = Ok).
    // A bare name that is a variant of some enum is a tag test, not a binding.

    const VariantRef = union(enum) {
        user: FoundVariant,
        result_ok,
        result_err,
    };

    fn variantRef(self: *Emitter, name: []const u8) ?VariantRef {
        if (self.findVariant(name)) |fv| return .{ .user = fv };
        const bare = bareVariantName(name);
        if (std.mem.eql(u8, bare, "Ok")) return .result_ok;
        if (std.mem.eql(u8, bare, "Err") or std.mem.eql(u8, bare, "Error")) return .result_err;
        return null;
    }

    fn enumHasPayload(variants: []const ast.EnumVariant) bool {
        for (variants) |v| if (v.fields.len > 0) return true;
        return false;
    }

    fn patternIsIrrefutable(self: *Emitter, p: ast.Pattern) bool {
        return switch (p) {
            .wildcard => true,
            // a written path is a variant, never a binding (§5.1 P8)
            .ident => |n| !isVariantPath(n) and self.findVariant(n) == null,
            // no wasm test for these yet: the arm runs as before
            .list, .multi => true,
            else => false,
        };
    }

    fn emitPatternTest(self: *Emitter, p: ast.Pattern, subj: []const u8) anyerror!void {
        switch (p) {
            .wildcard, .list, .multi => try self.emit(one),
            .ident => |n| {
                // A written path is a variant, never a binding (§5.1 P8), so
                // `.Ok` and `Shape.Circle` test a tag; a path no enum here
                // declares is an arm that can never match, not a catch-all.
                if (isVariantPath(n)) {
                    if (self.variantRef(n)) |ref|
                        try self.emitTagTest(ref, subj)
                    else
                        try self.emitCf(zero, "unknown variant pattern: {s}", .{n});
                } else if (self.findVariant(n)) |fv| {
                    try self.emitTagTest(.{ .user = fv }, subj);
                } else try self.emit(one);
            },
            .numberLit => |n| {
                try self.emit(.{ .local_get = subj });
                const t = numLitType(n);
                // the subject local is i32; a float literal is compared as one
                if (t[0] == 'f') {
                    try self.emit(constOf("f64", n));
                    try self.emit(.{ .convert = "i32.trunc_f64_s" });
                } else try self.emit(constOf(t, n));
                try self.emit(opOf("i32", "eq"));
            },
            .stringLit => |lit| {
                const seg = try self.internString(try self.literalBytes(lit));
                try self.emit(.{ .local_get = subj });
                try self.emit(try self.constInt(seg.offset));
                try self.emit(self.builder().helper(.str_eq));
            },
            .@"or" => |pats| {
                try self.emit(zero);
                for (pats) |sub| {
                    try self.emitPatternTest(sub, subj);
                    try self.emit(opOf("i32", "or"));
                }
            },
            .variant => |v| {
                const ref = self.variantRef(v.name) orelse {
                    try self.emitC(zero, "unknown variant pattern");
                    return;
                };
                try self.emitTagTest(ref, subj);
                switch (v.payload) {
                    .literals => |lits| for (lits, 0..) |sub, i| {
                        // test the payload field against a nested pattern
                        const field = try std.fmt.allocPrint(self.arena(), "__case_{d}", .{self.case_depth});
                        self.case_depth += 1;
                        try self.declareLocal(field, "i32");
                        var then_c: Capture = .{};
                        self.open(&then_c);
                        try self.emit(.{ .local_get = subj });
                        try self.emit(.{ .load = .{ .offset = @intCast((i + 1) * 4) } });
                        try self.emit(.{ .local_set = field });
                        try self.emitPatternTest(sub, field);
                        const then_seq = self.seal(&then_c, .{ .value = .i32 });
                        var else_c: Capture = .{};
                        self.open(&else_c);
                        try self.emit(zero);
                        const else_seq = self.seal(&else_c, .{ .value = .i32 });
                        try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
                    },
                    else => {},
                }
            },
        }
    }

    fn emitTagTest(self: *Emitter, ref: VariantRef, subj: []const u8) anyerror!void {
        switch (ref) {
            .user => |fv| {
                try self.emit(.{ .local_get = subj });
                if (enumHasPayload(fv.variants)) try self.emitC(.{ .load = .{} }, "variant tag");
                try self.emitCf(try self.constInt(fv.tag), "{s}", .{fv.variant.name});
                try self.emit(opOf("i32", "eq"));
            },
            .result_ok, .result_err => {
                try self.emit(.{ .local_get = subj });
                try self.emitC(.{ .load = .{} }, result_tag);
                if (ref == .result_ok) try self.emit(opOf("i32", "eqz"));
            },
        }
    }

    fn resolveName(self: *Emitter, n: []const u8) []const u8 {
        return self.aliases.get(n) orelse n;
    }

    /// The local a pattern binding `n` of wasm type `ty` is stored in: `n`
    /// itself, or — when `n` is already a local of another type — a fresh
    /// alias the arm's uses resolve to (until `emitCaseArms` drops it).
    fn bindName(self: *Emitter, n: []const u8, ty: []const u8) ![]const u8 {
        if (self.locals.get(n)) |existing| {
            if (!std.mem.eql(u8, existing, ty) and !self.pattern_locals.contains(n)) {
                const alias = try std.fmt.allocPrint(self.arena(), "{s}__{d}", .{ n, self.alias_seq });
                self.alias_seq += 1;
                try self.declareLocal(alias, ty);
                try self.aliases.put(n, alias);
                return alias;
            }
        }
        _ = self.aliases.remove(n);
        try self.declareLocal(n, ty);
        return n;
    }

    /// Bind the names a pattern introduces, from the subject held in `subj`.
    fn bindPattern(self: *Emitter, p: ast.Pattern, subj: []const u8) anyerror!void {
        switch (p) {
            .ident => |n| if (!isVariantPath(n) and self.findVariant(n) == null) {
                try self.declareLocal(n, "i32");
                if (self.str_locals.contains(subj)) try self.str_locals.put(n, {});
                try self.emit(.{ .local_get = subj });
                try self.emit(.{ .local_set = n });
            },
            .variant => |v| {
                const ref = self.variantRef(v.name) orelse return;
                const names: []const []const u8 = switch (v.payload) {
                    .binding => |b| &.{b},
                    .fields => |fs| fs,
                    .literals => return,
                };
                for (names, 0..) |n0, i| {
                    const field_ty: ?ast.TypeRef = switch (ref) {
                        .user => |fv| if (i < fv.variant.fields.len) fv.variant.fields[i].typeRef else null,
                        else => null,
                    };
                    const ty = if (field_ty) |t| watType(t) else "i32";
                    const n = try self.bindName(n0, ty);
                    const local_ty = self.locals.get(n) orelse ty;
                    if (field_ty) |t| {
                        if (isStringTypeRef(t)) try self.str_locals.put(n, {});
                        if (isBoolTypeRef(t)) try self.bool_locals.put(n, {});
                    }
                    switch (ref) {
                        .result_ok, .result_err => {
                            const shape = self.result_subjects.get(subj) orelse ResultShape{};
                            if ((ref == .result_ok and shape.ok_str) or (ref == .result_err and shape.err_str))
                                try self.str_locals.put(n, {});
                        },
                        else => {},
                    }
                    // payload slots are 4 bytes: a float field is an f32
                    const slot_float = local_ty[0] == 'f';
                    try self.emit(.{ .local_get = subj });
                    try self.emit(.{ .load = .{ .ty = if (slot_float) .f32 else .i32, .offset = @intCast((i + 1) * 4) } });
                    try self.emitConvert(if (slot_float) "f32" else "i32", local_ty);
                    try self.emit(.{ .local_set = n });
                }
            },
            else => {},
        }
    }

    /// A unit variant value: its tag, or — when the enum has payload variants,
    /// whose values are `[tag, …fields]` pointers — a one-slot `[tag]` cell, so
    /// every value of the enum has the same shape.
    fn emitUnitVariant(self: *Emitter, variants: []const ast.EnumVariant, tag: u32, ename: []const u8, vname: []const u8) anyerror!void {
        if (!enumHasPayload(variants)) {
            if (ename.len > 0)
                try self.emitCf(try self.constInt(tag), "{s}.{s}", .{ ename, vname })
            else
                try self.emitCf(try self.constInt(tag), ".{s}", .{vname});
            return;
        }
        const base = try self.allocSlots(4);
        try self.storeSlotConst(base, 0, tag);
        try self.loadBase(base);
    }

    /// The `(if (result …) (then <arm body>) (else <rest of the chain>))` a
    /// tested case arm expands to. The arm's test is already on the stack.
    fn emitArmChain(self: *Emitter, arms: anytype, subj: []const u8, idx: usize, body: ast.Expr) anyerror!void {
        const ty = vt(self.cur_result);

        var then_c: Capture = .{};
        self.open(&then_c);
        try self.bindPattern(arms[idx].pattern, subj);
        if (arms[idx].guard) |g| {
            try self.emitGuardChain(arms, subj, idx, g);
        } else {
            try self.lowerArmBody(body, subj);
        }
        self.aliases.clearRetainingCapacity();
        const then_seq = self.seal(&then_c, .{ .value = ty });

        var else_c: Capture = .{};
        self.open(&else_c);
        try self.emitCaseArms(arms, subj, idx + 1);
        const else_seq = self.seal(&else_c, .{ .value = ty });

        try self.emit(.{ .@"if" = .{
            .result = ty,
            .then = .{ .seq = then_seq },
            .@"else" = .{ .seq = else_seq },
        } });
    }

    // ── aggregates in linear memory ───────────────────────────────────────────
    //
    // Tuples, arrays, records and enum payloads are laid out as a contiguous run
    // of 4-byte slots in the bump-allocated heap. Construction leaves a pointer
    // to the first slot on the stack; element/field access loads from a fixed
    // offset. `$__mem{n}` scratch locals hold the base pointer while the slots
    // are filled (WAT has no `dup`, so the base must be reloaded per slot).

    /// Reserve the next `$__mem` scratch index without emitting anything.
    fn nextMem(self: *Emitter) u32 {
        const k = self.mem_seq;
        self.mem_seq += 1;
        // `countMems` sizes the pool up front; a construct it does not walk
        // (an inlined lambda body, say) still gets a declared slot. Idempotent,
        // so a pre-counted slot keeps its place in the local list.
        const name = self.memName(k) catch return k;
        self.declareLocal(name, "i32") catch {};
        return k;
    }

    /// Bump the heap by `nbytes`, stash the base pointer in a fresh `$__mem{k}`
    /// scratch local, and return `k`.
    fn allocSlots(self: *Emitter, nbytes: u32) ![]const u8 {
        const base = try self.memName(self.nextMem());
        try self.emit(.{ .global_get = heap_ptr });
        try self.emit(.{ .local_set = base });
        if (nbytes > 0) {
            try self.emit(.{ .global_get = heap_ptr });
            try self.emit(try self.constInt(nbytes));
            try self.emit(opOf("i32", "add"));
            try self.emit(.{ .global_set = heap_ptr });
        }
        return base;
    }

    /// Store one 4-byte slot. A float operand is kept a float — narrowed to
    /// `f32` so it still fits the slot — and stored with `f32.store`; feeding a
    /// float to `i32.store` is a validation error that rejected the module.
    /// KNOWN LIMIT: an `f64` field therefore round-trips at `f32` precision.
    fn storeSlotExpr(self: *Emitter, base: []const u8, offset: u32, value: ast.Expr) !void {
        try self.emit(.{ .local_get = base });
        const value_ty = self.wasmTypeOf(value);
        const is_float = std.mem.eql(u8, value_ty, "f32") or std.mem.eql(u8, value_ty, "f64");
        if (is_float) try self.lowerCoerced(value, "f32") else try self.lowerCoerced(value, "i32");
        try self.emit(.{ .store = .{
            .ty = if (is_float) .f32 else .i32,
            .offset = offset,
        } });
    }

    fn storeSlotConst(self: *Emitter, base: []const u8, offset: u32, value: i64) !void {
        try self.emit(.{ .local_get = base });
        try self.emit(try self.constInt(value));
        try self.emit(.{ .store = .{ .offset = offset } });
    }

    fn loadBase(self: *Emitter, base: []const u8) !void {
        try self.emit(.{ .local_get = base });
    }

    /// `i32.load` at `offset` — the emitter drops a zero `offset=`. Expects the
    /// base pointer on the stack.
    fn emitLoadOffset(self: *Emitter, offset: u32) !void {
        try self.emit(.{ .load = .{ .offset = offset } });
    }

    fn lowerTupleLit(self: *Emitter, tl: anytype) anyerror!void {
        const base = try self.allocSlots(@intCast(tl.elems.len * 4));
        for (tl.elems, 0..) |el, i| try self.storeSlotExpr(base, @intCast(i * 4), el);
        try self.loadBase(base);
    }

    /// F4 — list literals over linear memory with an explicit i32 length
    /// prefix. Layout: `[len i32][elem0 i32][elem1 i32]...`. `.len` reads
    /// the prefix (`i32.load` at offset 0); element access via `arr[N]`
    /// is `i32.load offset=(N+1)*4`. Matches the string layout convention
    /// so `.len` is uniform across both. Spread is still deferred.
    fn lowerArrayLit(self: *Emitter, al: anytype) anyerror!void {
        if (al.spread != null) try self.note("note: array spread not lowered");
        const total: u32 = @intCast((al.elems.len + 1) * 4);
        const base = try self.allocSlots(total);
        try self.storeSlotConst(base, 0, @intCast(al.elems.len));
        for (al.elems, 0..) |el, i| {
            const off: u32 = @intCast((i + 1) * 4);
            try self.storeSlotExpr(base, off, el);
        }
        try self.loadBase(base);
    }

    /// `record { a: 1, b: "x" }` → contiguous 4-byte slots in source-text order.
    /// Mirrors `lowerRecordCtor` but for anonymous records: the field list is
    /// taken from the literal itself.
    /// F1 tail: also registers the literal under its synthetic name
    /// (`__anon_L{line}_C{col}`) so subsequent `recv.field` reads against
    /// `val r = record { ... }` resolve to a real `i32.load offset=N`.
    fn lowerRecordLit(self: *Emitter, rl: anytype) anyerror!void {
        // Drop the returned name — registration is the side-effect we want.
        // `lowerExpr` callers feed `Expr.loc` into us; the surrounding
        // `lowerExpr` arm already has the loc, but the recordLit path inside
        // `recordTypeOfExpr` is the one that needs the synthetic name. We
        // pre-register here so the registry is non-empty by the time a later
        // `recv.field` access fires.
        _ = self.ensureAnonRecordFromLit(rl) catch {};
        const base = try self.allocSlots(@intCast(rl.fields.len * 4));
        for (rl.fields, 0..) |f, i| {
            try self.storeSlotExpr(base, @intCast(i * 4), f.value.*);
        }
        try self.loadBase(base);
    }

    /// `lowerRecordLit` has no `Loc` in hand (`lowerExpr` calls the arm with
    /// just the kind payload). We synthesise a loc from the first field's
    /// loc as a stable identity — a literal with N fields will produce the
    /// same name on every encounter.
    fn ensureAnonRecordFromLit(self: *Emitter, rl: anytype) ![]const u8 {
        const loc: ast.Loc = if (rl.fields.len > 0) rl.fields[0].value.getLoc() else .{ .line = 0, .col = 0 };
        return self.ensureAnonRecord(loc, rl);
    }

    /// `Rec(a: 1, b: 2)` → contiguous slots in declaration order. Named args are
    /// matched to fields by label; otherwise positional order is used.
    /// Static extension dispatch (F6). Returns true when `cc` is an activated
    /// or qualified extension call and was lowered to `call $<target>_<method>`.
    fn lowerDispatchCall(self: *Emitter, cc: anytype, loc: ast.Loc) anyerror!bool {
        var nbuf: [256]u8 = undefined;
        // Activated: `recv.m(args)` carries a rewrite entry → push the receiver
        // as the first argument, then the explicit args.
        if (self.rewrites.get(loc)) |sym| {
            const mangled = self.extMangledName(&nbuf, sym, cc.callee) orelse return false;
            const sig = self.fn_sigs.get(mangled) orelse {
                try self.emitCf(zero, "unresolved dispatch: {s}", .{mangled});
                return true;
            };
            var base: usize = 0;
            if (cc.receiver) |recv| if (sig.params.len > 0) {
                try self.lowerCoerced(recv.*, sig.params[0]);
                base = 1;
            };
            try self.lowerCallArgs(cc.args, sig, base);
            // `mangled` lives in a stack buffer; the node outlives this frame.
            try self.emit(.{ .call = try self.arena().dupe(u8, mangled) });
            return true;
        }
        // Qualified: `Sym.m(obj, args)` where `Sym` names an extension block —
        // the object is already arg 0, so only the args are pushed.
        if (receiverName(cc)) |rn| {
            if (self.ext_by_name.contains(rn)) {
                const mangled = self.extMangledName(&nbuf, rn, cc.callee) orelse return false;
                const sig = self.fn_sigs.get(mangled) orelse {
                    try self.emitCf(zero, "unresolved dispatch: {s}", .{mangled});
                    return true;
                };
                try self.lowerCallArgs(cc.args, sig, 0);
                try self.emit(.{ .call = try self.arena().dupe(u8, mangled) });
                return true;
            }
        }
        return false;
    }

    /// Push the explicit arguments of a call, coerced to the callee's declared
    /// parameter types, padding a short call with zeros.
    fn lowerCallArgs(self: *Emitter, args: anytype, sig: FnSig, base: usize) anyerror!void {
        for (args, 0..) |arg, i| {
            if (base + i >= sig.params.len) break;
            try self.lowerCoerced(arg.value.*, sig.params[base + i]);
        }
        var k = base + args.len;
        while (k < sig.params.len) : (k += 1) {
            try self.emitC(constOf(sig.params[k], "0"), "missing argument");
        }
    }

    /// The WAT symbol a non-builtin call resolves to, or null when this module
    /// defines nothing by that name. Mirrors `lowerDispatchCall` + `lowerPlainCall`
    /// so `exprTail` and the emitter agree on whether a `call` pushes a value.
    /// The symbol a call emits, method calls included: `recordMethodSym` reads
    /// the receiver's type off inference's per-loc note (`d.hasKey(…)` →
    /// `Dict_hasKey`), which is the path `lowerRecordMethod` itself takes, and
    /// `calleeSymbol` covers the rest. The shape predicates ask *this*, not
    /// `calleeSymbol` alone: without the first half a method's declared return
    /// type was invisible to them, so a method answering a `bool` or an array was
    /// printed through `$__print_i32` — `0`/`1` for a bool, and a **pointer**
    /// (`444` for `["a", "b"]`) for an array.
    fn resolvedCallSym(self: *Emitter, cc: anytype, loc: ast.Loc) ?[]const u8 {
        if (self.recordMethodSym(cc, loc)) |sym| return sym;
        return self.calleeSymbol(cc, loc);
    }

    fn calleeSymbol(self: *Emitter, cc: anytype, loc: ast.Loc) ?[]const u8 {
        if (self.rewrites.get(loc)) |sym| {
            if (self.extMangledName(&self.sym_buf, sym, cc.callee)) |m| return m;
        }
        if (receiverName(cc)) |rn| {
            if (self.ext_by_name.contains(rn)) {
                if (self.extMangledName(&self.sym_buf, rn, cc.callee)) |m| return m;
            }
            if (self.assocSym(cc)) |m| return m;
        }
        if (self.fn_sigs.contains(cc.callee)) return cc.callee;
        return null;
    }

    /// A call to an ordinary (non-constructor, non-builtin) function. Arguments
    /// are coerced to the callee's declared parameter types and a short call is
    /// padded with zeros, so the emitted `call` always type-checks.
    ///
    /// Two callees lower to `unreachable` instead — a trap, never a folded
    /// value, so a program that needs them fails loudly and the module still
    /// loads (`call $undefined` would reject the whole module):
    ///   * a host-backed `declare fn` (`#[@External.<Target>(…)]`): wasm has no
    ///     host, so there is nothing to call (`;; host-backed declare fn …`);
    ///   * a name nothing in the module, its linked imports, the primitive
    ///     method table or a function value resolves (`;; unresolved call: …`).
    fn lowerPlainCall(self: *Emitter, cc: anytype) anyerror!void {
        if (self.fn_sigs.get(cc.callee)) |sig| {
            var base: usize = 0;
            // `recv.m(a)` against a top-level `fn m(self, a)`: the receiver is
            // argument 0.
            if (cc.receiver != null and sig.params.len == cc.args.len + 1) {
                try self.lowerCoerced(cc.receiver.?.*, sig.params[0]);
                base = 1;
            }
            const ptrefs = self.fn_param_typerefs.get(cc.callee);
            for (cc.args, 0..) |arg, i| {
                if (base + i >= sig.params.len) {
                    try self.noteF("extra argument {d} ignored ({s}/{d})", .{ i, cc.callee, sig.params.len });
                    break;
                }
                const ptref: ?ast.TypeRef = if (ptrefs) |ps| (if (base + i < ps.len) ps[base + i] else null) else null;
                if (self.boxesInto(ptref, arg.value.*))
                    try self.lowerBoxed(arg.value.*)
                else
                    try self.lowerCoerced(arg.value.*, sig.params[base + i]);
            }
            var k = base + cc.args.len;
            while (k < sig.params.len) : (k += 1) {
                try self.emitC(constOf(sig.params[k], "0"), "missing argument");
            }
            try self.emit(.{ .call = cc.callee });
            return;
        }
        if (try self.lowerCollectionMethod(cc)) return;
        if (try self.lowerValueCall(cc)) return;
        if (cc.receiver == null and self.host_fns.contains(cc.callee)) {
            try self.emitCf(.@"unreachable", "host-backed declare fn {s}/{d}: no wasm host", .{ cc.callee, cc.args.len });
            return;
        }
        // `Ok(v)` / `Err(e)` / `new Error(msg)` outside the `#[@result]`
        // transform build the same `[tag, payload]` pair as `__bp_ok` /
        // `__bp_error` — the lowering beam and erlang give them (`{error, Msg}`).
        // A user enum variant of the same name was matched before this.
        if (cc.receiver == null and cc.args.len == 1 and cc.trailing.len == 0 and self.findVariant(cc.callee) == null) {
            if (self.variantRef(cc.callee)) |ref| switch (ref) {
                .result_ok => return self.lowerResultOptionOp("__bp_ok", cc.args),
                .result_err => return self.lowerResultOptionOp("__bp_error", cc.args),
                .user => {},
            };
        }
        try self.emitCf(.@"unreachable", "unresolved call: {s}/{d}", .{ cc.callee, cc.args.len });
    }

    // ── primitive instance methods ───────────────────────────────────────────
    //
    // `xs.join(",")`, `s.toUpper()`, `n.abs()`: inference records the
    // receiver's primitive family at the call loc (`instance_lowerings`), and
    // the method lowers to an opcode, a runtime helper from
    // `wat/wat_prelude.zig`, or — for a higher-order method whose argument is a
    // literal lambda — a loop over the array blob with the lambda body inlined
    // (there are no function values to pass). A method with no wasm lowering
    // traps with `;; prim method not lowered on wasm: …`.

    /// The primitive family of `recv.method(…)`'s receiver, when inference
    /// recorded one.
    fn primKindAt(self: *Emitter, cc: anytype, loc: ast.Loc) ?envMod.PrimKind {
        if (cc.receiver == null or cc.is_builtin) return null;
        const il = self.instance_lowerings.get(loc) orelse return null;
        return switch (il) {
            .prim => |k| k,
            .type_ => null,
        };
    }

    /// What a primitive method leaves on the stack. Null: no wasm lowering.
    const PrimRes = enum { i32, f64, bool_, str, arr, none };

    fn primCallRes(k: envMod.PrimKind, cc: anytype) ?PrimRes {
        const name: []const u8 = cc.callee;
        const argc = cc.args.len + cc.trailing.len;
        const Row = struct { []const u8, usize, PrimRes };
        const rows: []const Row = switch (k) {
            .array => &.{
                .{ "length", 0, .i32 },    .{ "at", 1, .i32 },      .{ "first", 0, .i32 },
                .{ "join", 1, .str },      .{ "indexOf", 1, .i32 }, .{ "contains", 1, .bool_ },
                .{ "isEmpty", 0, .bool_ }, .{ "reverse", 0, .arr }, .{ "prepend", 1, .arr },
                .{ "append", 1, .arr },    .{ "push", 1, .none },   .{ "zip", 1, .arr },
                .{ "slice", 1, .arr },     .{ "slice", 2, .arr },   .{ "rest", 0, .arr },
                .{ "take", 1, .arr },      .{ "drop", 1, .arr },    .{ "toList", 0, .arr },
                .{ "map", 1, .arr },       .{ "filter", 1, .arr },  .{ "forEach", 1, .none },
                .{ "all", 1, .bool_ },     .{ "every", 1, .bool_ }, .{ "any", 1, .bool_ },
                .{ "some", 1, .bool_ },    .{ "count", 1, .i32 },   .{ "findIndex", 1, .i32 },
                .{ "fold", 2, .i32 },
            },
            .string => &.{
                .{ "length", 0, .i32 },      .{ "toUpper", 0, .str },      .{ "toLower", 0, .str },
                .{ "contains", 1, .bool_ },  .{ "startsWith", 1, .bool_ }, .{ "endsWith", 1, .bool_ },
                .{ "indexOf", 1, .i32 },     .{ "trim", 0, .str },         .{ "trimStart", 0, .str },
                .{ "trimEnd", 0, .str },     .{ "split", 1, .arr },        .{ "slice", 1, .str },
                .{ "slice", 2, .str },       .{ "repeat", 1, .str },       .{ "toString", 0, .str },
                // The host spellings `primitives.bp` gives `toUpper`/`toLower`
                // through `#[@External.Node(…)]`. Source writes them
                // (`tests/language/test/string_case_conversion.bp`), commonJS
                // answers them because they are JavaScript's own, and this
                // backend used to trap on an unlowered primitive method.
                .{ "toUpperCase", 0, .str }, .{ "toLowerCase", 0, .str },
            },
            .bool => &.{
                .{ "negate", 0, .bool_ },      .{ "nor", 1, .bool_ },          .{ "nand", 1, .bool_ },
                .{ "exclusiveOr", 1, .bool_ }, .{ "exclusiveNor", 1, .bool_ }, .{ "toString", 0, .str },
            },
            .int => &.{
                .{ "abs", 0, .i32 },      .{ "min", 1, .i32 },      .{ "max", 1, .i32 },
                .{ "clamp", 2, .i32 },    .{ "isEven", 0, .bool_ }, .{ "isOdd", 0, .bool_ },
                .{ "toString", 0, .str },
            },
            .float => &.{
                .{ "abs", 0, .f64 },   .{ "min", 1, .f64 },        .{ "max", 1, .f64 },
                .{ "clamp", 2, .f64 }, .{ "floor", 0, .f64 },      .{ "ceil", 0, .f64 },
                .{ "round", 0, .f64 }, .{ "squareRoot", 0, .f64 },
            },
        };
        for (rows) |r| {
            if (r[1] == argc and std.mem.eql(u8, r[0], name)) return r[2];
        }
        return null;
    }

    /// The `i`-th argument of a call, counting trailing lambdas after the
    /// parenthesised ones.
    fn callArg(cc: anytype, i: usize) ?ast.Expr {
        if (i < cc.args.len) return cc.args[i].value.*;
        return null;
    }

    /// A lambda written at argument `i` — `xs.map({ x -> … })` or the trailing
    /// form `xs.map { x -> … }`.
    const LambdaView = struct { params: []const []const u8, body: []const ast.Stmt };

    fn lambdaAt(cc: anytype, i: usize) ?LambdaView {
        if (i < cc.args.len) {
            const a = cc.args[i].value;
            if (a.* != .function) return null;
            return .{ .params = a.function.kind.params, .body = a.function.kind.body };
        }
        const t = i - cc.args.len;
        if (t < cc.trailing.len) return .{ .params = cc.trailing[t].params, .body = cc.trailing[t].body };
        return null;
    }

    fn primNotLowered(self: *Emitter, k: envMod.PrimKind, cc: anytype) !void {
        try self.emitCf(.@"unreachable", "prim method not lowered on wasm: {s}.{s}/{d}", .{
            @tagName(k), cc.callee, cc.args.len + cc.trailing.len,
        });
    }

    fn lowerPrimMethod(self: *Emitter, k: envMod.PrimKind, cc: anytype) anyerror!void {
        if (primCallRes(k, cc) == null) return self.primNotLowered(k, cc);
        const recv = cc.receiver.?.*;
        const name: []const u8 = cc.callee;
        const eq = std.mem.eql;
        const b = self.builder();
        switch (k) {
            .bool => {
                try self.lowerCoerced(recv, "i32");
                if (eq(u8, name, "negate")) {
                    try self.emit(opOf("i32", "eqz"));
                } else if (eq(u8, name, "toString")) {
                    const t = try self.internString("true");
                    const f = try self.internString("false");
                    var then_c: Capture = .{};
                    self.open(&then_c);
                    try self.emit(try self.constInt(t.offset));
                    const then_seq = self.seal(&then_c, .{ .value = .i32 });
                    var else_c: Capture = .{};
                    self.open(&else_c);
                    try self.emit(try self.constInt(f.offset));
                    const else_seq = self.seal(&else_c, .{ .value = .i32 });
                    try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
                } else {
                    try self.lowerCoerced(callArg(cc, 0).?, "i32");
                    if (eq(u8, name, "nor")) {
                        try self.emit(opOf("i32", "or"));
                        try self.emit(opOf("i32", "eqz"));
                    } else if (eq(u8, name, "nand")) {
                        try self.emit(opOf("i32", "and"));
                        try self.emit(opOf("i32", "eqz"));
                    } else if (eq(u8, name, "exclusiveOr")) {
                        try self.emit(opOf("i32", "ne"));
                    } else {
                        try self.emit(opOf("i32", "eq"));
                    }
                }
            },
            .int => {
                try self.lowerCoerced(recv, "i32");
                if (eq(u8, name, "abs")) {
                    try self.emit(b.helper(.i32_abs));
                } else if (eq(u8, name, "min") or eq(u8, name, "max")) {
                    try self.lowerCoerced(callArg(cc, 0).?, "i32");
                    try self.emit(b.helper(if (eq(u8, name, "min")) .i32_min else .i32_max));
                } else if (eq(u8, name, "clamp")) {
                    try self.lowerCoerced(callArg(cc, 0).?, "i32");
                    try self.emit(b.helper(.i32_max));
                    try self.lowerCoerced(callArg(cc, 1).?, "i32");
                    try self.emit(b.helper(.i32_min));
                } else if (eq(u8, name, "isEven") or eq(u8, name, "isOdd")) {
                    try self.emit(try self.constInt(2));
                    try self.emit(opOf("i32", "rem_s"));
                    try self.emit(opOf("i32", "eqz"));
                    if (eq(u8, name, "isOdd")) try self.emit(opOf("i32", "eqz"));
                } else {
                    try self.emit(b.helper(.i32_to_str));
                }
            },
            .float => {
                try self.lowerCoerced(recv, "f64");
                if (eq(u8, name, "min") or eq(u8, name, "max")) {
                    try self.lowerCoerced(callArg(cc, 0).?, "f64");
                    try self.emit(opOf("f64", name));
                } else if (eq(u8, name, "clamp")) {
                    try self.lowerCoerced(callArg(cc, 0).?, "f64");
                    try self.emit(opOf("f64", "max"));
                    try self.lowerCoerced(callArg(cc, 1).?, "f64");
                    try self.emit(opOf("f64", "min"));
                } else if (eq(u8, name, "round")) {
                    // `Math.round`: ties round up — `floor(x + 0.5)`.
                    try self.emit(constOf("f64", "0.5"));
                    try self.emit(opOf("f64", "add"));
                    try self.emit(opOf("f64", "floor"));
                } else if (eq(u8, name, "squareRoot")) {
                    try self.emit(opOf("f64", "sqrt"));
                } else {
                    // abs / floor / ceil are opcodes of the same name.
                    try self.emit(opOf("f64", name));
                }
            },
            .string => try self.lowerStringMethod(cc),
            .array => try self.lowerArrayMethod(cc),
        }
    }

    fn lowerStringMethod(self: *Emitter, cc: anytype) anyerror!void {
        const recv = cc.receiver.?.*;
        const name: []const u8 = cc.callee;
        const eq = std.mem.eql;
        const b = self.builder();
        if (eq(u8, name, "slice")) return self.lowerStrSlice(cc);
        try self.lowerCoerced(recv, "i32");
        if (eq(u8, name, "length")) {
            try self.emitC(.{ .load = .{} }, "string length");
        } else if (eq(u8, name, "toUpper") or eq(u8, name, "toLower") or
            eq(u8, name, "toUpperCase") or eq(u8, name, "toLowerCase"))
        {
            const upper = eq(u8, name, "toUpper") or eq(u8, name, "toUpperCase");
            try self.emit(try self.constInt(if (upper) @as(i32, 'a') else 'A'));
            try self.emit(try self.constInt(if (upper) @as(i32, 'z') else 'Z'));
            try self.emit(try self.constInt(if (upper) @as(i32, -32) else 32));
            try self.emit(b.helper(.str_case));
        } else if (eq(u8, name, "trim") or eq(u8, name, "trimStart") or eq(u8, name, "trimEnd")) {
            const mode: i32 = if (eq(u8, name, "trimStart")) 1 else if (eq(u8, name, "trimEnd")) 2 else 3;
            try self.emit(try self.constInt(mode));
            try self.emit(b.helper(.str_trim));
        } else if (eq(u8, name, "toString")) {
            // already the string
        } else {
            try self.lowerCoerced(callArg(cc, 0).?, "i32");
            if (eq(u8, name, "contains")) {
                try self.emit(b.helper(.str_index_of));
                try self.emit(try self.constInt(-1));
                try self.emit(opOf("i32", "ne"));
            } else if (eq(u8, name, "indexOf")) {
                try self.emit(b.helper(.str_index_of));
            } else if (eq(u8, name, "startsWith")) {
                try self.emit(b.helper(.str_starts_with));
            } else if (eq(u8, name, "endsWith")) {
                try self.emit(b.helper(.str_ends_with));
            } else if (eq(u8, name, "split")) {
                try self.emit(b.helper(.str_split));
            } else {
                try self.emit(b.helper(.str_repeat));
            }
        }
    }

    fn lowerArrayMethod(self: *Emitter, cc: anytype) anyerror!void {
        const recv = cc.receiver.?.*;
        const name: []const u8 = cc.callee;
        const eq = std.mem.eql;
        const b = self.builder();

        const Hof = enum { map, filter, for_each, all, any, count, find_index, fold };
        const hof: ?Hof = if (eq(u8, name, "map")) .map else if (eq(u8, name, "filter")) .filter else if (eq(u8, name, "forEach")) .for_each else if (eq(u8, name, "all") or eq(u8, name, "every")) .all else if (eq(u8, name, "any") or eq(u8, name, "some")) .any else if (eq(u8, name, "count")) .count else if (eq(u8, name, "findIndex")) .find_index else if (eq(u8, name, "fold")) .fold else null;
        if (hof) |h| {
            const lam = lambdaAt(cc, if (h == .fold) 1 else 0) orelse {
                try self.emitCf(.@"unreachable", "{s} needs a literal lambda on wasm (no function values)", .{name});
                return;
            };
            return self.lowerArrayHof(@intFromEnum(h), recv, lam, if (h == .fold) callArg(cc, 0) else null);
        }
        if (eq(u8, name, "push")) return self.lowerArrayPush(cc);

        try self.lowerCoerced(recv, "i32");
        const elem = self.elemKindOf(recv);
        if (eq(u8, name, "length")) {
            try self.emitC(.{ .load = .{} }, "element count");
        } else if (eq(u8, name, "isEmpty")) {
            try self.emitC(.{ .load = .{} }, "element count");
            try self.emit(opOf("i32", "eqz"));
        } else if (eq(u8, name, "at") or eq(u8, name, "first")) {
            // `?T`: a string element is its own offset; anything else is boxed.
            if (eq(u8, name, "first")) try self.emit(zero) else try self.lowerCoerced(callArg(cc, 0).?, "i32");
            try self.emit(b.helper(if (elem == .str) .arr_at else .arr_at_box));
        } else if (eq(u8, name, "toList")) {
            // the array itself
        } else if (eq(u8, name, "reverse")) {
            try self.emit(b.helper(.arr_reverse));
        } else if (eq(u8, name, "rest") or eq(u8, name, "take") or eq(u8, name, "drop") or eq(u8, name, "slice")) {
            // `arr_slice` clamps its bounds, so "to the end" is the largest i32.
            const whole = try self.constInt(std.math.maxInt(i32));
            if (eq(u8, name, "rest")) {
                try self.emit(one);
                try self.emit(whole);
            } else if (eq(u8, name, "take")) {
                try self.emit(zero);
                try self.lowerCoerced(callArg(cc, 0).?, "i32");
            } else {
                try self.lowerCoerced(callArg(cc, 0).?, "i32");
                if (callArg(cc, 1)) |end| try self.lowerCoerced(end, "i32") else try self.emit(whole);
            }
            try self.emit(b.helper(.arr_slice));
        } else {
            const arg = callArg(cc, 0).?;
            if (eq(u8, name, "join")) {
                try self.lowerCoerced(arg, "i32");
                try self.emit(b.helper(if (elem == .str) .arr_join_str else .arr_join_i32));
            } else if (eq(u8, name, "indexOf") or eq(u8, name, "contains")) {
                try self.lowerCoerced(arg, "i32");
                try self.emit(b.helper(if (elem == .str or self.isStringExpr(arg)) .arr_index_of_str else .arr_index_of_i32));
                if (eq(u8, name, "contains")) {
                    try self.emit(try self.constInt(-1));
                    try self.emit(opOf("i32", "ne"));
                }
            } else {
                try self.lowerCoerced(arg, "i32");
                try self.emit(b.helper(if (eq(u8, name, "prepend")) .arr_prepend else if (eq(u8, name, "append")) .arr_concat else .arr_zip));
            }
        }
    }

    /// `xs.push(v)` — the blob has a fixed size, so the receiver is rebound to
    /// a copy with `v` appended (the erlang backend threads the same way). A
    /// receiver that is not a name or a record field cannot be rebound.
    fn lowerArrayPush(self: *Emitter, cc: anytype) anyerror!void {
        const recv = cc.receiver.?.*;
        const arg = callArg(cc, 0) orelse {
            try self.emitC(.@"unreachable", "push without a value");
            return;
        };
        switch (recv) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| if (self.locals.contains(n) or self.globals.contains(n)) {
                    try self.lowerCoerced(recv, "i32");
                    try self.lowerCoerced(arg, "i32");
                    try self.emit(self.builder().helper(.arr_push));
                    try self.emit(if (self.locals.contains(n)) .{ .local_set = n } else .{ .global_set = n });
                    return;
                },
                .identAccess => |ia| if (self.recordTypeOfExpr(ia.receiver.*)) |rty| if (self.fieldOffsetIn(rty, ia.member)) |off| {
                    const mem = try self.memName(self.nextMem());
                    try self.lowerValue(ia.receiver.*);
                    try self.emit(.{ .local_tee = mem });
                    try self.emit(.{ .local_get = mem });
                    try self.emit(.{ .load = .{ .offset = off } });
                    try self.lowerCoerced(arg, "i32");
                    try self.emit(self.builder().helper(.arr_push));
                    try self.emitCf(.{ .store = .{ .offset = off } }, ".{s} = push", .{ia.member});
                    return;
                },
                else => {},
            },
            else => {},
        }
        try self.emitC(.@"unreachable", "push on a receiver that cannot be rebound");
    }

    /// A higher-order array method over a literal lambda: a counted walk of the
    /// `[len][e0][e1]…` blob with the lambda's parameters bound to locals and
    /// its body inlined per element. `hof` is `lowerArrayMethod`'s `Hof`.
    fn lowerArrayHof(self: *Emitter, hof: u8, recv: ast.Expr, lam: LambdaView, init_expr: ?ast.Expr) anyerror!void {
        const map = 0;
        const filter = 1;
        const for_each = 2;
        const all = 3;
        const any = 4;
        const count = 5;
        const find_index = 6;
        const fold = 7;

        const ra = self.reg_arena.allocator();
        const n = self.loop_seq;
        self.loop_seq += 1;
        const base = try std.fmt.allocPrint(ra, "__iter{d}", .{n});
        const cur = try std.fmt.allocPrint(ra, "__idx{d}", .{n});
        const len = try std.fmt.allocPrint(ra, "__len{d}", .{n});
        const acc = try std.fmt.allocPrint(ra, "__acc{d}", .{n});
        const out = try std.fmt.allocPrint(ra, "__out{d}", .{n});
        try self.declareLocal(base, "i32");
        try self.declareLocal(cur, "i32");
        try self.declareLocal(len, "i32");

        const elem_kind = self.elemKindOf(recv);
        const elem_ty: []const u8 = if (elem_kind == .f32) "f32" else "i32";
        // fold binds (acc, item); the others bind (item).
        const acc_param: ?[]const u8 = if (hof == fold and lam.params.len > 0) lam.params[0] else null;
        const elem_param: ?[]const u8 = if (hof == fold)
            (if (lam.params.len > 1) lam.params[1] else null)
        else if (lam.params.len > 0) lam.params[0] else null;
        const acc_ty: []const u8 = if (hof == fold) (if (init_expr) |i| self.wasmTypeOf(i) else "i32") else "i32";
        try self.declareLocal(acc, acc_ty);
        if (hof == map or hof == filter) try self.declareLocal(out, "i32");
        if (elem_param) |p| {
            try self.declareLocal(p, elem_ty);
            if (elem_kind == .str) try self.str_locals.put(p, {});
        }
        if (acc_param) |p| {
            try self.declareLocal(p, acc_ty);
            if (init_expr) |i| if (self.isStringExpr(i)) try self.str_locals.put(p, {});
        }

        try self.lowerCoerced(recv, "i32");
        try self.emit(.{ .local_set = base });
        try self.emit(.{ .local_get = base });
        try self.emitC(.{ .load = .{} }, "element count");
        try self.emit(.{ .local_set = len });
        try self.emit(zero);
        try self.emit(.{ .local_set = cur });
        switch (hof) {
            map, filter => {
                try self.emit(.{ .local_get = len });
                try self.emit(self.builder().helper(.arr_new));
                try self.emit(.{ .local_set = out });
                try self.emit(zero);
                try self.emit(.{ .local_set = acc });
            },
            fold => {
                try self.lowerCoerced(init_expr.?, acc_ty);
                try self.emit(.{ .local_set = acc });
            },
            all => {
                try self.emit(one);
                try self.emit(.{ .local_set = acc });
            },
            find_index => {
                try self.emit(try self.constInt(-1));
                try self.emit(.{ .local_set = acc });
            },
            else => {
                try self.emit(zero);
                try self.emit(.{ .local_set = acc });
            },
        }

        var loop_c: Capture = .{};
        self.open(&loop_c);
        try self.emitAt(8, .{ .local_get = cur });
        try self.emitAt(8, .{ .local_get = len });
        try self.emitAt(8, opOf("i32", "ge_s"));
        try self.emitAt(8, .{ .br_if = break_label });
        if (hof == find_index) {
            try self.emitAt(8, .{ .local_get = acc });
            try self.emitAt(8, try self.constInt(-1));
            try self.emitAt(8, opOf("i32", "ne"));
            try self.emitAt(8, .{ .br_if = break_label });
        }
        if (elem_param) |p| {
            try self.emitAt(8, .{ .local_get = base });
            try self.emitAt(8, .{ .local_get = cur });
            try self.emitAt(8, try self.constInt(4));
            try self.emitAt(8, opOf("i32", "mul"));
            try self.emitAt(8, opOf("i32", "add"));
            try self.emitAt(8, .{ .load = .{ .ty = vt(elem_ty), .offset = 4 } });
            try self.emitAt(8, .{ .local_set = p });
        }
        if (acc_param) |p| {
            try self.emitAt(8, .{ .local_get = acc });
            try self.emitAt(8, .{ .local_set = p });
        }
        switch (hof) {
            for_each => for (lam.body) |stmt| {
                _ = try self.emitStmt(stmt, false);
            },
            map => {
                const tail_ty = self.lambdaTailType(lam.body);
                const is_float = tail_ty[0] == 'f';
                // the slot address first, then the value
                try self.emit(.{ .local_get = out });
                try self.emit(.{ .local_get = cur });
                try self.emit(try self.constInt(4));
                try self.emit(opOf("i32", "mul"));
                try self.emit(opOf("i32", "add"));
                try self.inlineLambdaBody(lam.body);
                try self.emitConvert(tail_ty, if (is_float) "f32" else "i32");
                try self.emit(.{ .store = .{ .ty = if (is_float) .f32 else .i32, .offset = 4 } });
            },
            fold => {
                const tail_ty = self.lambdaTailType(lam.body);
                try self.inlineLambdaBody(lam.body);
                try self.emitConvert(tail_ty, acc_ty);
                try self.emit(.{ .local_set = acc });
            },
            else => {
                try self.inlineLambdaBody(lam.body);
                var then_c: Capture = .{};
                self.open(&then_c);
                switch (hof) {
                    filter => {
                        try self.emit(.{ .local_get = out });
                        try self.emit(.{ .local_get = acc });
                        try self.emit(try self.constInt(4));
                        try self.emit(opOf("i32", "mul"));
                        try self.emit(opOf("i32", "add"));
                        try self.emit(.{ .local_get = base });
                        try self.emit(.{ .local_get = cur });
                        try self.emit(try self.constInt(4));
                        try self.emit(opOf("i32", "mul"));
                        try self.emit(opOf("i32", "add"));
                        try self.emit(.{ .load = .{ .offset = 4 } });
                        try self.emit(.{ .store = .{ .offset = 4 } });
                        try self.emit(.{ .local_get = acc });
                        try self.emit(one);
                        try self.emit(opOf("i32", "add"));
                        try self.emit(.{ .local_set = acc });
                    },
                    all => {
                        try self.emit(zero);
                        try self.emit(.{ .local_set = acc });
                    },
                    any => {
                        try self.emit(one);
                        try self.emit(.{ .local_set = acc });
                    },
                    count => {
                        try self.emit(.{ .local_get = acc });
                        try self.emit(one);
                        try self.emit(opOf("i32", "add"));
                        try self.emit(.{ .local_set = acc });
                    },
                    else => {
                        try self.emit(.{ .local_get = cur });
                        try self.emit(.{ .local_set = acc });
                    },
                }
                const then_seq = self.seal(&then_c, .none);
                if (hof == all) try self.emit(opOf("i32", "eqz"));
                try self.emit(.{ .@"if" = .{ .then = .{ .seq = then_seq } } });
            },
        }
        try self.emitAt(8, .{ .local_get = cur });
        try self.emitAt(8, one);
        try self.emitAt(8, opOf("i32", "add"));
        try self.emitAt(8, .{ .local_set = cur });
        try self.emitAt(8, .{ .br = continue_label });
        const loop_seq = self.seal(&loop_c, .terminated);
        try self.emitLoopBlock(loop_seq);

        switch (hof) {
            for_each => {},
            map => try self.emit(.{ .local_get = out }),
            filter => {
                try self.emit(.{ .local_get = out });
                try self.emit(.{ .local_get = acc });
                try self.emitC(.{ .store = .{} }, "kept count");
                try self.emit(.{ .local_get = out });
            },
            else => try self.emit(.{ .local_get = acc }),
        }
    }

    /// The wasm type an inlined lambda body leaves (its tail, or the value of a
    /// trailing `return`).
    fn lambdaTailType(self: *Emitter, body: []const ast.Stmt) []const u8 {
        if (body.len == 0) return "i32";
        const last = body[body.len - 1].expr;
        return switch (last) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |v| self.wasmTypeOf(v.*) else "i32",
                else => "i32",
            },
            else => self.wasmTypeOf(last),
        };
    }

    // ── array element shapes ─────────────────────────────────────────────────

    const ElemKind = enum { i32, f32, str };

    /// The element shape a `T[]` / `Array<T>` type spells, when it is an array.
    fn arrayElemOfTypeRef(t: ast.TypeRef) ?ElemKind {
        const elem: ast.TypeRef = switch (t) {
            .array => |inner| inner.*,
            // An iterator runs eagerly here: it is the array of what it yields.
            .generic => |g| if (g.args.len == 1 and (std.mem.eql(u8, g.name, "Array") or
                std.mem.eql(u8, g.name, "Iterator") or std.mem.eql(u8, g.name, "AsyncIterator")))
                g.args[0]
            else
                return null,
            .optional => |inner| return arrayElemOfTypeRef(inner.*),
            else => return null,
        };
        return elemKindOfTypeRef(elem);
    }

    fn elemKindOfTypeRef(t: ast.TypeRef) ElemKind {
        return switch (t) {
            .named => |n| if (std.mem.eql(u8, n, "string"))
                .str
            else if (std.mem.eql(u8, n, "f32") or std.mem.eql(u8, n, "f64"))
                .f32
            else
                .i32,
            else => .i32,
        };
    }

    /// Record what a parameter's declared type says about its value.
    fn noteParamShape(self: *Emitter, sym: []const u8, t: ast.TypeRef) !void {
        if (isStringTypeRef(t)) try self.str_locals.put(sym, {});
        if (isBoolTypeRef(t)) try self.bool_locals.put(sym, {});
        if (arrayElemOfTypeRef(t)) |ek| {
            try self.arr_locals.put(sym, {});
            try self.arr_elem_locals.put(sym, ek);
        }
    }

    /// A local bound to something `isArrayExpr` recognises is an array too,
    /// with the element shape of its initialiser.
    fn noteArrayLocal(self: *Emitter, name: []const u8, value: ast.Expr) !void {
        if (try self.printShapeOf(value)) |shape| try self.print_shape_locals.put(name, shape);
        if (!self.isArrayExpr(value)) return;
        try self.arr_locals.put(name, {});
        try self.arr_elem_locals.put(name, self.elemKindOf(value));
    }

    /// The shape `$__print_shaped_raw` walks for `e` (semantics decision 1a):
    /// `i` an i32, `f` an f32 slot, `b` a bool, `s` a string, `[X` an array of
    /// `X`, `(XY…)` a tuple. Null when `e` is not known to be an array or a
    /// tuple.
    fn printShapeOf(self: *Emitter, e: ast.Expr) anyerror!?[]const u8 {
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| if (self.print_shape_locals.get(self.resolveName(n))) |shape| return shape,
                else => {},
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.printShapeOf(inner.*),
                .tupleLit => |tl| {
                    var out: std.ArrayListUnmanaged(u8) = .empty;
                    try out.append(self.arena(), '(');
                    for (tl.elems) |el| try out.appendSlice(self.arena(), try self.valueShapeOf(el));
                    try out.append(self.arena(), ')');
                    return out.items;
                },
                .arrayLit => |al| if (al.elems.len > 0) {
                    if (try self.printShapeOf(al.elems[0])) |inner| return try std.fmt.allocPrint(self.arena(), "[{s}", .{inner});
                },
                else => {},
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (std.mem.eql(u8, cc.callee, "zip") and cc.args.len == 1 and cc.receiver != null) {
                        if (self.primKindAt(cc, c.loc) == .array) return try std.fmt.allocPrint(self.arena(), "[({c}{c})", .{
                            elemCode(self.elemKindOf(cc.receiver.?.*)),
                            elemCode(self.elemKindOf(cc.args[0].value.*)),
                        });
                    }
                    // `rows[1]` keeps the shape of one element of `rows`.
                    if (try self.indexElemShape(cc)) |inner| return inner;
                },
                else => {},
            },
            else => {},
        }
        // A parameter, a fn result or a local whose declared type spells a tuple.
        if (self.typeRefOf(e)) |tr| if (try self.typeRefShape(tr)) |shape| return shape;
        if (!self.isArrayExpr(e)) return null;
        return switch (self.elemKindOf(e)) {
            .i32 => "[i",
            .f32 => "[f",
            .str => "[s",
        };
    }

    /// The print shape a declared type spells, when it holds a tuple or a
    /// string somewhere inside an array or a tuple; null for anything the
    /// shape codes cannot describe (a record, an enum, a map).
    fn typeRefShape(self: *Emitter, t: ast.TypeRef) anyerror!?[]const u8 {
        switch (t) {
            .tuple_, .labeledTuple => {
                const elems = t.tupleElems().?;
                var out: std.ArrayListUnmanaged(u8) = .empty;
                try out.append(self.arena(), '(');
                for (elems) |el| {
                    if (try self.typeRefShape(el)) |inner| {
                        try out.appendSlice(self.arena(), inner);
                        continue;
                    }
                    try out.append(self.arena(), scalarCode(el) orelse return null);
                }
                try out.append(self.arena(), ')');
                return out.items;
            },
            .array => |inner| return self.arrayTypeShape(inner.*),
            .generic => |g| if (g.args.len == 1 and std.mem.eql(u8, g.name, "Array")) return self.arrayTypeShape(g.args[0]),
            else => {},
        }
        return null;
    }

    fn arrayTypeShape(self: *Emitter, elem: ast.TypeRef) anyerror!?[]const u8 {
        if (try self.typeRefShape(elem)) |inner| return try std.fmt.allocPrint(self.arena(), "[{s}", .{inner});
        return switch (scalarCode(elem) orelse return null) {
            's' => "[s",
            else => null,
        };
    }

    /// The shape code of a scalar named type: `i` an integer, `f` a float, `b`
    /// a bool, `s` a string.
    fn scalarCode(t: ast.TypeRef) ?u8 {
        const n = switch (t) {
            .named => |n| n,
            else => return null,
        };
        if (std.mem.eql(u8, n, "string")) return 's';
        if (std.mem.eql(u8, n, "bool")) return 'b';
        if (std.mem.eql(u8, n, "i32") or std.mem.eql(u8, n, "int") or std.mem.eql(u8, n, "Int")) return 'i';
        if (std.mem.eql(u8, n, "f32") or std.mem.eql(u8, n, "f64") or std.mem.eql(u8, n, "float")) return 'f';
        return null;
    }

    /// The shape of one element of a tuple.
    fn valueShapeOf(self: *Emitter, e: ast.Expr) anyerror![]const u8 {
        if (try self.printShapeOf(e)) |shape| return shape;
        if (self.isStringExpr(e)) return "s";
        if (self.isBoolExpr(e)) return "b";
        if (self.wasmTypeOf(e)[0] == 'f') return "f";
        return "i";
    }

    fn elemCode(k: ElemKind) u8 {
        return switch (k) {
            .i32 => 'i',
            .f32 => 'f',
            .str => 's',
        };
    }

    /// Best-effort element shape of an array-valued expression. `i32` covers
    /// integers, bools and pointers alike.
    fn elemKindOf(self: *Emitter, e: ast.Expr) ElemKind {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.arr_elem_locals.get(self.resolveName(n)) orelse self.arr_elem_globals.get(n) orelse .i32,
                .identAccess => |ia| blk: {
                    const rty = self.recordTypeOfExpr(ia.receiver.*) orelse break :blk .i32;
                    const fields = self.records.get(rty) orelse break :blk .i32;
                    _ = fields;
                    break :blk .i32;
                },
                else => .i32,
            },
            .loop => |lp| self.yieldElemKind(lp.body),
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.elemKindOf(inner.*),
                .arrayLit => |al| blk: {
                    if (al.elems.len == 0) break :blk .i32;
                    const first = al.elems[0];
                    if (self.isStringExpr(first)) break :blk .str;
                    if (self.wasmTypeOf(first)[0] == 'f') break :blk .f32;
                    break :blk .i32;
                },
                else => .i32,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (self.primKindAt(cc, c.loc)) |k| switch (k) {
                        .string => break :blk .str, // split
                        .array => {
                            const recv = cc.receiver.?.*;
                            if (std.mem.eql(u8, cc.callee, "map")) {
                                const lam = lambdaAt(cc, 0) orelse break :blk .i32;
                                if (lam.body.len == 0) break :blk .i32;
                                const last = lam.body[lam.body.len - 1].expr;
                                const v = switch (last) {
                                    .jump => |j| switch (j.kind) {
                                        .@"return" => |r| if (r) |x| x.* else break :blk .i32,
                                        else => break :blk .i32,
                                    },
                                    else => last,
                                };
                                if (self.isStringExpr(v)) break :blk .str;
                                if (self.wasmTypeOf(v)[0] == 'f') break :blk .f32;
                                break :blk .i32;
                            }
                            break :blk self.elemKindOf(recv);
                        },
                        else => break :blk .i32,
                    };
                    // `xs[a..b]` keeps the elements of `xs`
                    if (self.indexArgs(cc)) |ix| break :blk if (ix.is_slice) self.elemKindOf(ix.recv) else .i32;
                    if (cc.is_builtin) break :blk .i32;
                    if (self.resolvedCallSym(cc, c.loc)) |sym| break :blk self.fn_arr_elem.get(sym) orelse .i32;
                    break :blk self.fn_arr_elem.get(cc.callee) orelse .i32;
                },
                else => .i32,
            },
            else => .i32,
        };
    }

    // ── function values ──────────────────────────────────────────────────────
    //
    // A lambda used as a value is lifted into a function of its own,
    // `$__lambda{n}(env, a0, …) -> i32`, and listed in the module's function
    // table. The value is a pointer to an environment cell: `[table index]`
    // then one 4-byte slot per captured local, copied at creation (a capture is
    // a snapshot — a lambda that assigns an outer local does not change it).
    // Calling a value is `call_indirect` with the cell as the first argument.
    // Every parameter and the result are `i32` (the carrier every value here
    // fits, a float excepted).
    //
    // A lambda passed straight to an array method is not lifted: it is inlined
    // (`lowerArrayHof`), which is what lets `forEach` mutate outer locals.

    const Captured = struct {
        name: []const u8,
        ty: []const u8,
        str: bool,
        record: ?[]const u8,
        arr_elem: ?ElemKind,
        /// The lambda body assigns it: the environment slot is the variable
        /// while the lambda runs, and a call through a known closure local
        /// copies it in before the call and back out after.
        threaded: bool = false,
    };

    const ParamShape = struct { names: []const []const u8, str: []const bool };

    const Lifted = struct {
        name: []const u8,
        params: []const []const u8,
        body: []const ast.Stmt,
        captures: []const Captured,
        /// Per parameter: some call through a closure local passed a string
        /// (`lowerValueCall`). The program type-checked, so one proven string
        /// argument makes the parameter a string.
        param_str: []bool = &.{},
        /// Set for a trampoline standing for a top-level fn used as a value.
        fn_ref: ?[]const u8 = null,
    };

    fn lowerLambdaValue(self: *Emitter, params: []const []const u8, body: []const ast.Stmt) anyerror!void {
        const ra = self.reg_arena.allocator();
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        for (body) |st| try self.collectIdents(st.expr, &names);
        var caps: std.ArrayListUnmanaged(Captured) = .empty;
        outer: for (names.items) |n| {
            for (params) |p| if (std.mem.eql(u8, p, n)) continue :outer;
            for (caps.items) |cp| if (std.mem.eql(u8, cp.name, n)) continue :outer;
            const ty = self.locals.get(n) orelse continue;
            try caps.append(ra, .{
                .name = n,
                .ty = ty,
                .str = self.str_locals.contains(n),
                .record = self.local_types.get(n),
                .arr_elem = self.arr_elem_locals.get(n),
                .threaded = bodyAssigns(body, n),
            });
        }
        const idx: u32 = @intCast(self.lambdas.items.len);
        const param_str = try ra.alloc(bool, params.len);
        @memset(param_str, false);
        try self.lambdas.append(self.alloc, .{
            .name = try std.fmt.allocPrint(ra, "__lambda{d}", .{idx}),
            .params = params,
            .body = body,
            .captures = caps.items,
            .param_str = param_str,
        });
        try self.emitClosureCell(idx, caps.items);
    }

    /// Allocate the environment cell of table slot `idx` and leave its pointer.
    fn emitClosureCell(self: *Emitter, idx: u32, caps: []const Captured) anyerror!void {
        const base = try self.allocSlots(@intCast((1 + caps.len) * 4));
        try self.storeSlotConst(base, 0, idx);
        for (caps, 0..) |cp, i| {
            const is_float = cp.ty[0] == 'f';
            try self.emit(.{ .local_get = base });
            try self.emit(.{ .local_get = cp.name });
            try self.emitConvert(cp.ty, if (is_float) "f32" else "i32");
            try self.emitCf(.{ .store = .{ .ty = if (is_float) .f32 else .i32, .offset = @intCast((i + 1) * 4) } }, "capture {s}", .{cp.name});
        }
        try self.loadBase(base);
    }

    /// A top-level fn used as a value: a closure over a trampoline that
    /// forwards its arguments.
    fn lowerFnRef(self: *Emitter, name: []const u8) anyerror!void {
        const idx = self.fn_refs.get(name) orelse blk: {
            const i: u32 = @intCast(self.lambdas.items.len);
            try self.lambdas.append(self.alloc, .{
                .name = try std.fmt.allocPrint(self.reg_arena.allocator(), "__fnref_{s}", .{name}),
                .params = &.{},
                .body = &.{},
                .captures = &.{},
                .fn_ref = name,
            });
            try self.fn_refs.put(name, i);
            break :blk i;
        };
        try self.emitClosureCell(idx, &.{});
    }

    /// `f(a, b)` where `f` is a local or global holding a function value,
    /// `r.field(a)` where the field holds one, or `t._1(a)` — a **tuple slot**
    /// holding one, which is also what a labelled element arrives as: the checker
    /// resolves `c.set(9)` on `#(value: i32, set: fn(n: i32) -> i32)` to the
    /// position, so the callee here is `_1`. Without that last case the call fell
    /// into the unresolved path and trapped (`;; unresolved call: _1/1`), which is
    /// the whole of what "wasm has no function values" ever meant.
    fn lowerValueCall(self: *Emitter, cc: anytype) anyerror!bool {
        // The slot the function value sits in, for a call through a receiver.
        const slotOffset = struct {
            fn f(em: *Emitter, recv: ast.Expr, member: []const u8) ?u32 {
                if (em.recordTypeOfExpr(recv)) |rty| {
                    if (em.fieldOffsetIn(rty, member)) |off| return off;
                }
                if (tupleIndex(member)) |idx| return idx * 4;
                return null;
            }
        }.f;
        const is_value = blk: {
            if (cc.receiver) |recv| break :blk slotOffset(self, recv.*, cc.callee) != null;
            break :blk self.locals.contains(cc.callee) or self.globals.contains(cc.callee);
        };
        if (!is_value) return false;
        const ra = self.reg_arena.allocator();
        const tmp = try std.fmt.allocPrint(ra, "__fnv{d}", .{self.loop_seq});
        self.loop_seq += 1;
        try self.declareLocal(tmp, "i32");
        if (cc.receiver) |recv| {
            const off = slotOffset(self, recv.*, cc.callee).?;
            try self.lowerValue(recv.*);
            try self.emitCf(.{ .load = .{ .offset = off } }, ".{s}", .{cc.callee});
        } else if (self.locals.contains(cc.callee)) {
            try self.emit(.{ .local_get = cc.callee });
        } else {
            try self.emit(.{ .global_get = cc.callee });
        }
        try self.emit(.{ .local_set = tmp });
        const closure: ?Lifted = if (cc.receiver == null and self.locals.contains(cc.callee))
            if (self.closure_locals.get(cc.callee)) |li| self.lambdas.items[li] else null
        else
            null;
        if (closure) |l| {
            for (cc.args, 0..) |a, i| {
                if (i < l.param_str.len and self.isStringExpr(a.value.*)) l.param_str[i] = true;
            }
            try self.syncCaptures(tmp, l.captures, .into_env);
        }
        try self.emit(.{ .local_get = tmp });
        for (cc.args) |a| try self.lowerCoerced(a.value.*, "i32");
        for (cc.trailing) |t| try self.lowerLambdaValue(t.params, t.body);
        try self.emitIndirect(tmp, cc.args.len + cc.trailing.len);
        if (closure) |l| try self.syncCaptures(tmp, l.captures, .out_of_env);
        return true;
    }

    /// Around a call through a closure local, copy each capture the lambda
    /// assigns into its environment slot (the caller may have changed it since
    /// the closure was made) or back out of it (the lambda may have changed
    /// it). The call's result stays on the stack underneath.
    fn syncCaptures(self: *Emitter, env: []const u8, caps: []const Captured, dir: enum { into_env, out_of_env }) anyerror!void {
        for (caps, 0..) |cp, i| {
            if (!cp.threaded) continue;
            const ty = self.locals.get(cp.name) orelse continue;
            const is_float = cp.ty[0] == 'f';
            const slot: wat.MemArg = .{ .ty = if (is_float) .f32 else .i32, .offset = @intCast((i + 1) * 4) };
            switch (dir) {
                .into_env => {
                    try self.emit(.{ .local_get = env });
                    try self.emit(.{ .local_get = cp.name });
                    try self.emitConvert(ty, if (is_float) "f32" else "i32");
                    try self.emitCf(.{ .store = slot }, "sync {s} into env", .{cp.name});
                },
                .out_of_env => {
                    try self.emit(.{ .local_get = env });
                    try self.emitCf(.{ .load = slot }, "sync {s} from env", .{cp.name});
                    try self.emitConvert(if (is_float) "f32" else "i32", ty);
                    try self.emit(.{ .local_set = cp.name });
                },
            }
        }
    }

    /// Inside a lifted lambda, after `name` was assigned: when it is a
    /// threaded capture, store it back into the environment cell.
    fn writeBackCapture(self: *Emitter, name: []const u8) anyerror!void {
        const off = self.env_slots.get(name) orelse return;
        const ty = self.locals.get(name) orelse return;
        const is_float = ty[0] == 'f';
        try self.emit(.{ .local_get = "__env" });
        try self.emit(.{ .local_get = name });
        try self.emitConvert(ty, if (is_float) "f32" else "i32");
        try self.emitCf(.{ .store = .{ .ty = if (is_float) .f32 else .i32, .offset = off } }, "write {s} back to env", .{name});
    }

    /// Whether a statement list assigns the plain name `n` (`n = …`, `n += …`),
    /// in nested branches, loops, arms and lambdas included.
    fn bodyAssigns(body: []const ast.Stmt, n: []const u8) bool {
        for (body) |st| if (exprAssigns(st.expr, n)) return true;
        return false;
    }

    fn exprAssigns(e: ast.Expr, n: []const u8) bool {
        return switch (e) {
            .binding => |b| switch (b.kind) {
                .assign => |a| switch (a.target) {
                    .name => |t| std.mem.eql(u8, t, n) or exprAssigns(a.value.*, n),
                    .fieldAccess => exprAssigns(a.value.*, n),
                },
                .localBind => |lb| exprAssigns(lb.value.*, n),
                .localBindDestruct => |lb| exprAssigns(lb.value.*, n),
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| bodyAssigns(i.then_, n) or (if (i.else_) |els| bodyAssigns(els, n) else false),
                .tryCatch => |tc| exprAssigns(tc.expr.*, n) or exprAssigns(tc.handler.*, n),
            },
            .loop => |lp| bodyAssigns(lp.body, n),
            .function => |f| bodyAssigns(f.kind.body, n),
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    for (cc.args) |a| if (exprAssigns(a.value.*, n)) break :blk true;
                    for (cc.trailing) |t| if (bodyAssigns(t.body, n)) break :blk true;
                    break :blk false;
                },
                .pipeline => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| exprAssigns(inner.*, n),
                .case => |cs| blk: {
                    for (cs.arms) |arm| if (exprAssigns(arm.body, n)) break :blk true;
                    break :blk false;
                },
                else => false,
            },
            else => false,
        };
    }

    /// Whether a call through the closure local bound to lifted lambda `li`
    /// yields a string: its body is judged with each parameter taking the
    /// shape of this call's argument (`{ x, y -> x + y }` over two strings).
    fn closureCallIsString(self: *Emitter, li: u32, cc: anytype) bool {
        const l = self.lambdas.items[li];
        if (l.fn_ref != null) return false;
        const flags = self.arena().alloc(bool, l.params.len) catch return false;
        for (flags, 0..) |*f, i| f.* = (i < l.param_str.len and l.param_str[i]) or
            (i < cc.args.len and self.isStringExpr(cc.args[i].value.*));
        const saved = self.param_shape;
        defer self.param_shape = saved;
        self.param_shape = .{ .names = l.params, .str = flags };
        return self.bodyIsString(l.body);
    }

    /// With the environment and `argc` arguments on the stack, call the
    /// function value held in `fnv`.
    fn emitIndirect(self: *Emitter, fnv: []const u8, argc: usize) anyerror!void {
        self.uses_table = true;
        try self.emit(.{ .local_get = fnv });
        try self.emitC(.{ .load = .{} }, "table index");
        const params = try self.arena().alloc(ValType, argc + 1);
        for (params) |*p| p.* = .i32;
        try self.emit(.{ .call_indirect = .{ .params = params, .result = .i32 } });
    }

    /// Emit every function queued while lowering: lifted lambdas (which may
    /// lift more) and reached interface associated fns.
    fn emitPendingFns(self: *Emitter) anyerror!void {
        var li: usize = 0;
        var ai: usize = 0;
        while (li < self.lambdas.items.len or ai < self.assoc_needed.items.len) {
            while (li < self.lambdas.items.len) : (li += 1) try self.emitLifted(self.lambdas.items[li]);
            while (ai < self.assoc_needed.items.len) : (ai += 1) {
                const sym = self.assoc_needed.items[ai];
                if (self.assoc_emitted.contains(sym)) continue;
                try self.assoc_emitted.put(sym, {});
                const m = self.iface_assoc.get(sym).?;
                try self.emitFn(.{
                    .isPub = false,
                    .name = sym,
                    .genericParams = m.genericParams,
                    .params = m.params,
                    .returnType = m.returnType,
                    .body = m.body.?,
                });
            }
        }
    }

    fn emitLifted(self: *Emitter, l: Lifted) anyerror!void {
        self.resetFnState("i32");
        const ar = self.arena();
        var params: std.ArrayListUnmanaged(wat.Param) = .empty;
        try params.append(ar, wat.Builder.param("__env", .i32));
        try self.locals.put("__env", "i32");

        var c: Capture = .{};
        self.open(&c);
        if (l.fn_ref) |target| {
            const sig = self.fn_sigs.get(target).?;
            for (sig.params, 0..) |pt, i| {
                const pn = try std.fmt.allocPrint(ar, "__a{d}", .{i});
                try params.append(ar, wat.Builder.param(pn, .i32));
                try self.emit(.{ .local_get = pn });
                try self.emitConvert("i32", pt);
            }
            try self.emit(.{ .call = target });
            if (sig.result) |r| try self.emitConvert(r, "i32") else try self.emit(zero);
        } else {
            for (l.params, 0..) |p, i| {
                try params.append(ar, wat.Builder.param(p, .i32));
                try self.locals.put(p, "i32");
                if (i < l.param_str.len and l.param_str[i]) try self.str_locals.put(p, {});
            }
            for (l.captures, 0..) |cp, i| {
                try self.declareLocal(cp.name, cp.ty);
                if (cp.threaded) try self.env_slots.put(cp.name, @intCast((i + 1) * 4));
                if (cp.str) try self.str_locals.put(cp.name, {});
                if (cp.record) |r| try self.local_types.put(cp.name, r);
                if (cp.arr_elem) |ek| {
                    try self.arr_locals.put(cp.name, {});
                    try self.arr_elem_locals.put(cp.name, ek);
                }
                const is_float = cp.ty[0] == 'f';
                try self.emit(.{ .local_get = "__env" });
                try self.emit(.{ .load = .{ .ty = if (is_float) .f32 else .i32, .offset = @intCast((i + 1) * 4) } });
                try self.emitConvert(if (is_float) "f32" else "i32", cp.ty);
                try self.emit(.{ .local_set = cp.name });
            }
            try self.declareScratch("_try", countTrys(l.body));
            try self.declareScratch("__mem", self.countMems(l.body));
            try self.emitLocalDecls(l.body);
            const tail_type: ?[]const u8 = if (l.body.len > 0) self.wasmTypeOf(l.body[l.body.len - 1].expr) else null;
            const tail = try self.emitBody(l.body, true);
            if (tail == .value) if (tail_type) |t| try self.emitConvert(t, "i32");
        }
        const body = self.seal(&c, .{ .value = .i32 });
        try self.item(.{ .func = try self.builder().func(.{
            .name = l.name,
            .params = params.items,
            .result = .i32,
            .locals = try self.localLines(),
            .body = body,
        }) });
    }

    /// `Iface_method` when `cc` is `Iface.method(…)` naming an interface
    /// associated `default fn`.
    fn assocSym(self: *Emitter, cc: anytype) ?[]const u8 {
        const rn = receiverName(cc) orelse return null;
        if (self.locals.contains(rn) or self.globals.contains(rn)) return null;
        const sym = std.fmt.bufPrint(&self.sym_buf, "{s}_{s}", .{ rn, cc.callee }) catch return null;
        // An interface associated `default fn`, or a record's own fn called on
        // the type (`Response.ok(…)`).
        if (self.iface_assoc.contains(sym)) return sym;
        if (self.records.contains(rn) and self.fn_sigs.contains(sym)) return sym;
        return null;
    }

    /// Every plain identifier `e` mentions (reads and assignment targets),
    /// nested lambdas included — the candidates a lifted lambda captures.
    fn collectIdents(self: *Emitter, e: ast.Expr, out: *std.ArrayListUnmanaged([]const u8)) anyerror!void {
        const ra = self.reg_arena.allocator();
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| try out.append(ra, n),
                .identAccess => |ia| try self.collectIdents(ia.receiver.*, out),
                .dotIdent => {},
            },
            .binaryOp => |b| {
                try self.collectIdents(b.lhs.*, out);
                try self.collectIdents(b.rhs.*, out);
            },
            .unaryOp => |u| try self.collectIdents(u.expr.*, out),
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (cc.receiver) |r| try self.collectIdents(r.*, out);
                    if (!cc.is_builtin and cc.receiver == null) try out.append(ra, cc.callee);
                    for (cc.args) |a| try self.collectIdents(a.value.*, out);
                    for (cc.trailing) |t| for (t.body) |st| try self.collectIdents(st.expr, out);
                },
                .pipeline => |pl| {
                    try self.collectIdents(pl.lhs.*, out);
                    try self.collectIdents(pl.rhs.*, out);
                },
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| {
                    try self.collectIdents(i.cond.*, out);
                    for (i.then_) |st| try self.collectIdents(st.expr, out);
                    if (i.else_) |els| for (els) |st| try self.collectIdents(st.expr, out);
                },
                .tryCatch => |tc| {
                    try self.collectIdents(tc.expr.*, out);
                    try self.collectIdents(tc.handler.*, out);
                },
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| try self.collectIdents(lb.value.*, out),
                .localBindDestruct => |lb| try self.collectIdents(lb.value.*, out),
                .assign => |a| {
                    try self.collectIdents(a.value.*, out);
                    switch (a.target) {
                        .name => |n| try out.append(ra, n),
                        .fieldAccess => |fa| try self.collectIdents(fa.receiver.*, out),
                    }
                },
            },
            .jump => |j| switch (j.kind) {
                .@"return", .throw_, .try_ => |v| if (v) |x| try self.collectIdents(x.*, out),
                inline .@"break", .yield => |jl| if (jl.value) |x| try self.collectIdents(x.*, out),
                .await_ => |a| try self.collectIdents(a.*, out),
                else => {},
            },
            .loop => |lp| {
                try self.collectIdents(lp.iter.*, out);
                for (lp.body) |st| try self.collectIdents(st.expr, out);
            },
            .function => |f| for (f.kind.body) |st| try self.collectIdents(st.expr, out),
            .collection => |col| switch (col.kind) {
                .grouped => |inner| try self.collectIdents(inner.*, out),
                .case => |cs| {
                    for (cs.subjects) |sj| try self.collectIdents(sj, out);
                    for (cs.arms) |arm| try self.collectIdents(arm.body, out);
                },
                .tupleLit => |tl| for (tl.elems) |el| try self.collectIdents(el, out),
                .arrayLit => |al| for (al.elems) |el| try self.collectIdents(el, out),
                .behaviorLit => |il| for (il.fields) |f| try self.collectIdents(f.value.*, out),
                .range => |r| {
                    try self.collectIdents(r.start.*, out);
                    if (r.end) |x| try self.collectIdents(x.*, out);
                },
            },
            .useHook => |uh| try self.collectIdents(uh.kind.inner.*, out),
            else => {},
        }
    }

    /// Element shape of what a comprehension body yields: the first
    /// `yield`/`break` value found. Loop parameters are not bound yet, so a
    /// float is recognised by its literal or arithmetic, a string by a literal.
    fn yieldElemKind(self: *Emitter, body: []const ast.Stmt) ElemKind {
        // `val taxa = valor * 0.15; break valor + taxa;` — the body's own float
        // locals make the yielded value a float.
        var floats: std.ArrayListUnmanaged([]const u8) = .empty;
        for (body) |st| {
            switch (st.expr) {
                .binding => |b| switch (b.kind) {
                    .localBind => |lb| if (self.wasmTypeOf(lb.value.*)[0] == 'f' or self.mentionsAny(lb.value.*, floats.items))
                        floats.append(self.reg_arena.allocator(), lb.name) catch {},
                    else => {},
                },
                else => {},
            }
            if (self.yieldValue(st.expr)) |v| {
                if (self.isStringExpr(v)) return .str;
                if (self.wasmTypeOf(v)[0] == 'f' or self.mentionsAny(v, floats.items)) return .f32;
                return .i32;
            }
        }
        return .i32;
    }

    fn mentionsAny(self: *Emitter, e: ast.Expr, names: []const []const u8) bool {
        if (names.len == 0) return false;
        var seen: std.ArrayListUnmanaged([]const u8) = .empty;
        self.collectIdents(e, &seen) catch return false;
        for (seen.items) |n| for (names) |m| if (std.mem.eql(u8, n, m)) return true;
        return false;
    }

    fn yieldValue(self: *Emitter, e: ast.Expr) ?ast.Expr {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                inline .@"break", .yield => |jl| if (jl.value) |v| v.* else null,
                else => null,
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| blk: {
                    for (i.then_) |st| if (self.yieldValue(st.expr)) |v| break :blk v;
                    if (i.else_) |els| for (els) |st| if (self.yieldValue(st.expr)) |v| break :blk v;
                    break :blk null;
                },
                else => null,
            },
            else => null,
        };
    }

    // ── optionals ────────────────────────────────────────────────────────────
    //
    // `?T` is an i32 offset into linear memory, `0` = null (decision 3 of the
    // 1.0.2-beta semantics decisions). A `T` that is already a pointer (a
    // string, a record, an array) is its own offset. A scalar `T` (an integer,
    // a bool, a float) is boxed: a 4-byte cell holding the payload
    // (`$__box_i32`), so a present `0` is distinguishable from none. The box is
    // made where a `T` flows into a declared `?T` (a return, an annotated
    // binding, an argument, a record field) and read where the program uses
    // the payload (`if (x) { v -> … }`, `@print`, a comparison with a value, a
    // string `+`, `unwrapOr`/`map`).

    const OptInfo = struct {
        /// The payload is a scalar in a box (else the value is the payload).
        boxed: bool,
        str: bool = false,
        bool_: bool = false,
        /// The boxed payload is an `f32` slot, not an integer — a float array's
        /// `at`/`first`. Read as an `i32` it prints the float's bits.
        float_: bool = false,
        inner: ?ast.TypeRef = null,
    };

    fn optInfoOfTypeRef(t: ast.TypeRef) ?OptInfo {
        const inner = switch (t) {
            .optional => |i| i.*,
            else => return null,
        };
        return switch (inner) {
            .named => |n| if (std.mem.eql(u8, n, "string"))
                .{ .boxed = false, .str = true, .inner = inner }
            else if (std.mem.eql(u8, n, "bool"))
                .{ .boxed = true, .bool_ = true, .inner = inner }
            else if (isScalarName(n))
                .{ .boxed = true, .inner = inner }
            else
                .{ .boxed = false, .inner = inner },
            else => .{ .boxed = false, .inner = inner },
        };
    }

    fn isScalarName(n: []const u8) bool {
        for ([_][]const u8{ "i32", "i64", "u32", "u64", "f32", "f64", "int", "float" }) |s| {
            if (std.mem.eql(u8, n, s)) return true;
        }
        return false;
    }

    /// The declared type an expression carries, when a declaration names it.
    fn typeRefOf(self: *Emitter, e: ast.Expr) ?ast.TypeRef {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n0| blk: {
                    const n = self.resolveName(n0);
                    if (self.local_typerefs.get(n)) |t| break :blk t;
                    if (self.locals.contains(n)) break :blk null;
                    break :blk self.global_typerefs.get(n);
                },
                .identAccess => |ia| blk: {
                    if (tupleIndex(ia.member)) |idx| {
                        const rt = self.typeRefOf(ia.receiver.*) orelse break :blk null;
                        const elems = rt.tupleElems() orelse break :blk null;
                        break :blk if (idx < elems.len) elems[idx] else null;
                    }
                    const rty = self.recordTypeOfExpr(ia.receiver.*) orelse break :blk null;
                    const fields = self.records.get(rty) orelse break :blk null;
                    const trefs = self.record_field_typerefs.get(rty) orelse break :blk null;
                    for (fields, 0..) |f, i| if (std.mem.eql(u8, f, ia.member) and i < trefs.len) break :blk trefs[i];
                    break :blk null;
                },
                else => null,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (cc.is_builtin) break :blk null;
                    // A method on a record value: its declared return type is
                    // registered under the emitted symbol (`Dict_lookup`), and
                    // asking for it is what keeps the *reader* of a `?T` in step
                    // with the writer. `d.lookup("a")` returns a `?V` — a type
                    // parameter, so unboxed here — while the reader guessed
                    // "boxed" and loaded through the payload as an address.
                    if (cc.receiver != null) {
                        if (self.recordMethodSym(cc, c.loc)) |sym| {
                            if (self.fn_ret_typerefs.get(sym)) |t| break :blk t;
                        }
                        // The same question one step lower: the symbol the call
                        // actually emits — a `rewrites` entry the comptime pass
                        // left, an interface `default fn`, or a method already
                        // flattened to `Dict_lookup` by the specialisation pass.
                        const sym = self.calleeSymbol(cc, c.loc) orelse break :blk null;
                        break :blk self.fn_ret_typerefs.get(sym);
                    }
                    break :blk self.fn_ret_typerefs.get(cc.callee);
                },
                else => null,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.typeRefOf(inner.*),
                else => null,
            },
            else => null,
        };
    }

    /// The optional an expression evaluates to, when it is one.
    fn optInfoOf(self: *Emitter, e: ast.Expr) ?OptInfo {
        switch (e) {
            // An `if` with no `else` in value position: absent when the
            // condition is false (its value when false is the language
            // question decision 2 answers; the `0` here is none).
            .branch => |b| switch (b.kind) {
                .if_ => |i| if (i.else_ == null and !ifIsStatementForm(i) and !branchIsVoid(i.then_)) {
                    if (self.bodyIsString(i.then_)) return .{ .boxed = false, .str = true };
                },
                else => {},
            },

            .call => |c| switch (c.kind) {
                .call => |cc| if (self.primKindAt(cc, c.loc)) |k| if (k == .array and
                    (std.mem.eql(u8, cc.callee, "at") or std.mem.eql(u8, cc.callee, "first")))
                {
                    return switch (self.elemKindOf(cc.receiver.?.*)) {
                        .str => .{ .boxed = false, .str = true },
                        .f32 => .{ .boxed = true, .float_ = true },
                        .i32 => .{ .boxed = true },
                    };
                },
                else => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| if (self.opt_locals.get(self.resolveName(n))) |oi| return oi,
                // `recv?.field` of a scalar field is a boxed optional
                .identAccess => |ia| if (ia.optional) {
                    const rty = self.recordTypeOfExpr(ia.receiver.*) orelse return null;
                    const ft = self.fieldTypeIn(rty, ia.member);
                    if (ft == null or self.resolveRecordName(ft.?) != null) return .{ .boxed = false };
                    if (std.mem.eql(u8, ft.?, "string")) return .{ .boxed = false, .str = true };
                    return .{ .boxed = true, .bool_ = std.mem.eql(u8, ft.?, "bool") };
                },
                else => {},
            },
            else => {},
        }
        const t = self.typeRefOf(e) orelse return null;
        return optInfoOfTypeRef(t);
    }

    fn isNullLit(e: ast.Expr) bool {
        return switch (e) {
            .literal => |lit| lit.kind == .null_,
            .collection => |col| switch (col.kind) {
                .grouped => |inner| isNullLit(inner.*),
                else => false,
            },
            else => false,
        };
    }

    /// Whether `value` flowing into a slot declared `target` must be boxed:
    /// the slot is a scalar optional and the value is neither `null` nor
    /// already an optional.
    fn boxesInto(self: *Emitter, target: ?ast.TypeRef, value: ast.Expr) bool {
        const t = target orelse return false;
        const oi = optInfoOfTypeRef(t) orelse return false;
        if (!oi.boxed) return false;
        if (isNullLit(value)) return false;
        return self.optInfoOf(value) == null;
    }

    /// Whether the `@Option` an `__bp_option_*` op receives holds its payload in
    /// a box. Known from the receiver's declared type; otherwise the default
    /// value's shape decides (a string or record default means a pointer
    /// payload), and a scalar is assumed.
    fn optionIsBoxed(self: *Emitter, recv: ast.Expr, default: ?*ast.Expr) bool {
        if (self.optInfoOf(recv)) |oi| return oi.boxed;
        if (default) |d| {
            if (self.isStringExpr(d.*) or self.recordTypeOfExpr(d.*) != null or self.isArrayExpr(d.*)) return false;
        }
        return true;
    }

    fn lambdaTailIsPointer(self: *Emitter, body: []const ast.Stmt) bool {
        if (body.len == 0) return false;
        const last = body[body.len - 1].expr;
        const v = switch (last) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |x| x.* else return false,
                else => last,
            },
            else => last,
        };
        return self.isStringExpr(v) or self.recordTypeOfExpr(v) != null or self.isArrayExpr(v) or self.optInfoOf(v) != null;
    }

    fn lowerBoxed(self: *Emitter, value: ast.Expr) anyerror!void {
        try self.lowerCoerced(value, "i32");
        try self.emit(self.builder().helper(.box_i32));
    }

    // ── record inherent methods ──────────────────────────────────────────────

    /// `$<Record>_<method>` for `recv.method(…)` when inference tagged the
    /// receiver as a record value and the module emitted that method.
    fn recordMethodSym(self: *Emitter, cc: anytype, loc: ast.Loc) ?[]const u8 {
        if (cc.receiver == null or cc.is_builtin) return null;
        const il = self.instance_lowerings.get(loc) orelse return null;
        const rec = switch (il) {
            .type_ => |r| r,
            .prim => return null,
        };
        const sym = std.fmt.bufPrint(&self.sym_buf, "{s}_{s}", .{ rec, cc.callee }) catch return null;
        if (!self.fn_sigs.contains(sym)) return null;
        return sym;
    }

    /// `c.atual()` on a record value → `call $Contador_atual` with the receiver
    /// as the `self` argument.
    fn lowerRecordMethod(self: *Emitter, cc: anytype, loc: ast.Loc) anyerror!bool {
        const sym_tmp = self.recordMethodSym(cc, loc) orelse return false;
        const sym = try self.arena().dupe(u8, sym_tmp);
        const sig = self.fn_sigs.get(sym).?;
        var base: usize = 0;
        if (sig.params.len == cc.args.len + 1) {
            try self.lowerCoerced(cc.receiver.?.*, sig.params[0]);
            base = 1;
        }
        try self.lowerCallArgs(cc.args, sig, base);
        try self.emit(.{ .call = sym });
        return true;
    }

    /// Instance methods on the built-in array layout (`[len][e0][e1]…`) that
    /// the wasm memory model can serve directly. Returns false when the method
    /// isn't one of them, so the caller can fall back to the stub.
    fn lowerCollectionMethod(self: *Emitter, cc: anytype) anyerror!bool {
        const recv = cc.receiver orelse return false;
        if (std.mem.eql(u8, cc.callee, "at") and cc.args.len == 1) {
            // `xs.at(i)` → `xs[i]`, or 0 when out of range.
            try self.lowerValue(recv.*);
            try self.lowerCoerced(cc.args[0].value.*, "i32");
            try self.emit(self.builder().helper(.arr_at));
            return true;
        }
        if (std.mem.eql(u8, cc.callee, "length") and cc.args.len == 0) {
            try self.lowerValue(recv.*);
            try self.emitC(.{ .load = .{} }, ".length (array/string prefix)");
            return true;
        }
        return false;
    }

    fn lowerRecordCtor(self: *Emitter, cc: anytype, fields: []const []const u8) anyerror!void {
        const base = try self.allocSlots(@intCast(fields.len * 4));
        for (fields, 0..) |fname, i| {
            const off: u32 = @intCast(i * 4);
            if (self.argForField(cc.args, fname, i)) |arg| {
                const ftref: ?ast.TypeRef = if (self.record_field_typerefs.get(cc.callee)) |ts| (if (i < ts.len) ts[i] else null) else null;
                if (self.boxesInto(ftref, arg.value.*)) {
                    try self.emit(.{ .local_get = base });
                    try self.lowerBoxed(arg.value.*);
                    try self.emit(.{ .store = .{ .offset = off } });
                } else try self.storeSlotExpr(base, off, arg.value.*);
            } else {
                try self.storeSlotConst(base, off, 0);
            }
        }
        try self.loadBase(base);
    }

    /// Pick the call argument that fills field `fname` (declaration index `idx`):
    /// the labelled arg whose label matches, else the positional arg at `idx`.
    fn argForField(self: *Emitter, args: anytype, fname: []const u8, idx: usize) ?@TypeOf(args[0]) {
        _ = self;
        for (args) |arg| {
            if (arg.label) |lbl| {
                if (std.mem.eql(u8, lbl, fname)) return arg;
            }
        }
        // No matching label — fall back to positional (skipping `..spread`).
        if (idx < args.len and args[idx].label == null) return args[idx];
        return null;
    }

    /// `Color.Rgb(r: 1, g: 2, b: 3)` → `[tag, r, g, b]`. The tag (variant index)
    /// lives at offset 0; payload fields follow at 4, 8, ...
    fn lowerEnumCtor(self: *Emitter, cc: anytype, tag: u32, variant: ast.EnumVariant) anyerror!void {
        const nslots = 1 + variant.fields.len;
        const base = try self.allocSlots(@intCast(nslots * 4));
        try self.storeSlotConst(base, 0, tag);
        for (variant.fields, 0..) |vf, i| {
            const off: u32 = @intCast((i + 1) * 4);
            if (self.argForField(cc.args, vf.name, i)) |arg| {
                try self.storeSlotExpr(base, off, arg.value.*);
            } else {
                try self.storeSlotConst(base, off, 0);
            }
        }
        try self.loadBase(base);
    }

    /// `recv.member` — tuple element (`t._0`), qualified enum unit variant
    /// (`Color.Red`), or a named record field (`r.b` / `self.x`).
    fn lowerIdentAccess(self: *Emitter, ia: anytype, loc: ast.Loc) anyerror!void {
        // `xs.length` / `s.length` on a primitive: inference recorded the
        // receiver's family at this loc, and both layouts keep the count in the
        // first word.
        if (std.mem.eql(u8, ia.member, "length")) {
            if (self.instance_lowerings.get(loc)) |il| if (il == .prim) {
                try self.lowerValue(ia.receiver.*);
                try self.emitC(.{ .load = .{} }, ".length");
                return;
            };
            // Inference records `.prim` only where it typed the receiver. It
            // does not type decision 30's index node yet, so `xs[0..2].length`
            // and a local bound to a slice arrived here unrecorded and fell
            // through to the field-access stub — `i32.const 0`, a wrong length
            // with exit 0. This backend's own predicates know the receiver is a
            // blob; neither is ever true of a record, so a field actually named
            // `length` still resolves below.
            if (self.isArrayExpr(ia.receiver.*) or self.isStringExpr(ia.receiver.*)) {
                try self.lowerValue(ia.receiver.*);
                try self.emitC(.{ .load = .{} }, ".length");
                return;
            }
        }
        // `.len` on a string → load the length prefix. Strings are
        // length-prefixed buffers, so the value points at the i32 length word.
        // Codegen is untyped; `.len` is assumed to mean string length here.
        if (std.mem.eql(u8, ia.member, "len")) {
            try self.lowerExpr(ia.receiver.*);
            try self.emitC(.{ .load = .{} }, "string length");
            return;
        }
        // Tuple element access: `_0`, `_1`, ... → load at `index * 4`.
        if (tupleIndex(ia.member)) |idx| {
            try self.lowerExpr(ia.receiver.*);
            try self.emitLoadOffset(idx * 4);
            return;
        }
        // Qualified enum unit variant: `Color.Red` → variant tag.
        switch (ia.receiver.*) {
            .identifier => |rid| switch (rid.kind) {
                .ident => |ename| {
                    if (self.enums.get(ename)) |variants| {
                        for (variants, 0..) |v, i| {
                            if (std.mem.eql(u8, v.name, ia.member)) {
                                try self.emitUnitVariant(variants, @intCast(i), ename, ia.member);
                                return;
                            }
                        }
                    }
                },
                else => {},
            },
            else => {},
        }
        // Named record-field access — two-level resolution:
        //   1. **Type recovery** (`recordTypeOfExpr`): walk the receiver's
        //      recovered record type (`self_type` in methods, `local_types`
        //      for let-bindings, fn return-type for direct calls, chained
        //      field types for `a.b.c`) and load at the field's declared
        //      4-byte offset. `?.` guards via `local.tee` + `i32.eqz` +
        //      `(if (result i32) ...)`. Carrier shape: none = `i32.const 0`.
        //   2. **Unique-field heuristic** (`uniqueFieldOffset`): when type
        //      recovery fails (anon record literals bound to a local,
        //      cross-template captures, …), fall back to scanning the
        //      record registry for an unambiguous slot owner of the bare
        //      field name. Templates catalogued in the F0 audit use a
        //      disjoint field vocabulary (`Span.start/end/line`,
        //      `CustomNode.kind/span/ref/children`, …) so the heuristic
        //      terminates uniquely in practice.
        //   3. **Stub** (`i32.const 0`) — recorded backend limit; the
        //      surrounding fn still runs under wasmtime.
        if (self.recordTypeOfExpr(ia.receiver.*)) |rty| {
            if (self.fieldOffsetIn(rty, ia.member)) |off| {
                if (ia.optional) {
                    try self.lowerOptionalField(ia, off, "");
                    return;
                }
                try self.lowerExpr(ia.receiver.*);
                try self.emitCf(.{ .load = .{ .offset = off } }, ".{s}", .{ia.member});
                return;
            }
        }
        // Type recovery failed — try the name-unique fallback. `?.` on this
        // path still has to short-circuit on a null pointer, so use the same
        // `local.tee` + `i32.eqz` guard as the typed branch above.
        if (self.uniqueFieldOffset(ia.member)) |off| {
            if (ia.optional) {
                try self.lowerOptionalField(ia, off, " (unique)");
                return;
            }
            try self.lowerExpr(ia.receiver.*);
            try self.emitLoadOffset(off);
            return;
        }
        // Both heuristics failed — keep the historical `i32.const 0` placeholder
        // so wasmtime still executes the surrounding fn. `0` matches the
        // BEAM/erlang null-guard on missing fields.
        if (ia.optional) {
            try self.emitCf(zero, "optional field access .{s} (unknown receiver type)", .{ia.member});
            return;
        }
        try self.emitCf(zero, "field access .{s} (unknown receiver type)", .{ia.member});
    }

    /// `recv?.field` → stash the receiver, test it for null, and load the slot
    /// only on the present branch. `suffix` marks which resolution found the
    /// offset, matching the historical comments.
    fn lowerOptionalField(self: *Emitter, ia: anytype, off: u32, suffix: []const u8) anyerror!void {
        const mem = try self.memName(self.nextMem());
        try self.lowerExpr(ia.receiver.*);
        try self.emit(.{ .local_tee = mem });
        try self.emit(opOf("i32", "eqz"));

        var then_c: Capture = .{};
        self.open(&then_c);
        try self.emitAtCf(8, zero, "?.{s} on null", .{ia.member});
        const then_seq = self.seal(&then_c, .{ .value = .i32 });

        var else_c: Capture = .{};
        self.open(&else_c);
        try self.emitAt(8, .{ .local_get = mem });
        try self.emitAtCf(8, .{ .load = .{ .offset = off } }, "?.{s}{s}", .{ ia.member, suffix });
        // `?.` makes the result a `?T`: a scalar field goes in a box.
        if (self.optInfoOf(.{ .identifier = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .identAccess = ia } } })) |oi| {
            if (oi.boxed) try self.emitAt(8, self.builder().helper(.box_i32));
        }
        const else_seq = self.seal(&else_c, .{ .value = .i32 });

        try self.emit(.{ .@"if" = .{
            .result = .i32,
            .then = .{ .seq = then_seq },
            .@"else" = .{ .seq = else_seq },
        } });
    }

    /// Single-field heuristic for untyped wat codegen: returns the slot offset
    /// when every registered record-type with a field named `name` places it at
    /// the same index (i.e., the name maps to one unambiguous offset across the
    /// program's type registry). Returns null when two record types disagree on
    /// the slot — caller falls back to the unresolved-member stub.
    fn uniqueFieldOffset(self: *Emitter, name: []const u8) ?u32 {
        var found: ?u32 = null;
        var it = self.records.iterator();
        while (it.next()) |entry| {
            for (entry.value_ptr.*, 0..) |fname, idx| {
                if (!std.mem.eql(u8, fname, name)) continue;
                const off: u32 = @intCast(idx * 4);
                if (found) |existing| {
                    if (existing != off) return null;
                } else {
                    found = off;
                }
                break;
            }
        }
        return found;
    }

    /// Returns N for a tuple-accessor member of the form `_N` (e.g. `_0`).
    fn tupleIndex(member: []const u8) ?u32 {
        // `t._N` and the bare `t.N` both read element N.
        const digits = if (member.len > 0 and member[0] == '_') member[1..] else member;
        if (digits.len == 0) return null;
        var n: u32 = 0;
        for (digits) |c| {
            if (!std.ascii.isDigit(c)) return null;
            n = n * 10 + (c - '0');
        }
        return n;
    }

    // ── strings in linear memory ──────────────────────────────────────────────
    //
    // Strings are length-prefixed buffers: a value is a pointer to a 4-byte i32
    // length word immediately followed by the raw bytes. Literals are interned in
    // the data section with this layout; `.len` loads the prefix and `.slice`
    // copies a sub-range into a fresh prefixed buffer, so length travels with the
    // string at runtime (it no longer has to be a compile-time constant).
    // Concatenation and comparison of literals lower to helper calls (offsets +
    // compile-time lengths), demonstrating `memory.copy` and a byte-compare loop;
    // the concat result is itself a valid prefixed string, so `.len`/`.slice`
    // compose on it. Concat/compare of non-literal operands is not detected here
    // (codegen is untyped, so `a + b` on string variables lowers as numeric add).

    fn isStrLit(e: ast.Expr) ?[]const u8 {
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .stringLit => |s| s,
                else => null,
            },
            else => null,
        };
    }

    /// True when `e` is known to evaluate to a length-prefixed string pointer:
    /// a literal, a local/param declared or inferred as `string`, a `.slice`
    /// result, or a `+` chain over such operands. Drives string `==`, `+` and
    /// `@print`, none of which may go through the numeric path.
    fn isStringExpr(self: *Emitter, e: ast.Expr) bool {
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .stringLit => true,
                else => false,
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| blk: {
                    if (self.param_shape) |ps| for (ps.names, 0..) |pn, i| {
                        if (std.mem.eql(u8, pn, n)) break :blk ps.str[i];
                    };
                    break :blk self.str_locals.contains(self.resolveName(n)) or self.str_globals.contains(n);
                },
                .identAccess => |ia| blk: {
                    // A record field declared `string`.
                    const rty = self.recordTypeOfExpr(ia.receiver.*) orelse break :blk false;
                    const ft = self.fieldTypeIn(rty, ia.member) orelse break :blk false;
                    break :blk std.mem.eql(u8, ft, "string");
                },
                else => false,
            },
            .binaryOp => |bin| switch (bin.op) {
                .add => self.isStringExpr(bin.lhs.*) or self.isStringExpr(bin.rhs.*),
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.isStringExpr(inner.*),
                // A `case`/`if` yielding strings is itself a string. Without
                // this, `@print(case x { 0 -> "zero"; … })` went through
                // `$__print_i32` and printed the *pointer* (`256`).
                .case => |c| blk: {
                    var any = false;
                    for (c.arms) |arm| {
                        if (self.exprTail(arm.body) == .terminated) continue;
                        if (!self.isStringExpr(arm.body)) break :blk false;
                        any = true;
                    }
                    break :blk any;
                },
                else => false,
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| blk: {
                    const els = i.else_ orelse break :blk false;
                    break :blk self.bodyIsString(i.then_) and self.bodyIsString(els);
                },
                // Both sides have the payload's type; either one proves it.
                .tryCatch => |tc| self.isStringExpr(tc.handler.*) or self.resultOfStringCall(tc.expr.*),
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (self.primKindAt(cc, c.loc)) |k| break :blk primCallRes(k, cc) == .str;
                    if (isStrSlice(cc)) break :blk true;
                    // `s[i]` / `s[a..b]` (decision 30) answer a string; an
                    // array index answers a string when its elements are ones.
                    if (self.indexArgs(cc)) |ix| break :blk if (self.isStringExpr(ix.recv))
                        true
                    else
                        self.isArrayExpr(ix.recv) and !ix.is_slice and self.elemKindOf(ix.recv) == .str;
                    if (cc.is_builtin) break :blk false;
                    if (cc.receiver == null and self.locals.contains(cc.callee)) {
                        if (self.closure_locals.get(cc.callee)) |li| break :blk self.closureCallIsString(li, cc);
                    }
                    if (self.resolvedCallSym(cc, c.loc)) |sym| {
                        if (self.str_fns.contains(sym)) break :blk true;
                    }
                    break :blk false;
                },
                else => false,
            },
            .useHook => |uh| self.isStringExpr(uh.kind.inner.*),
            .jump => |j| switch (j.kind) {
                .try_ => |v| if (v) |x| self.resultOfStringCall(x.*) else false,
                else => false,
            },
            else => false,
        };
    }

    /// `f()` where `f` is declared `-> @Result<string, …>`.
    fn resultOfStringCall(self: *Emitter, e: ast.Expr) bool {
        return switch (e) {
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    const sym = self.calleeSymbol(cc, c.loc) orelse break :blk false;
                    break :blk self.result_str_fns.contains(sym);
                },
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.resultOfStringCall(inner.*),
                else => false,
            },
            else => false,
        };
    }

    const ResultShape = struct { ok_str: bool = false, err_str: bool = false };

    fn resultShapeOfTypeRef(t: ast.TypeRef) ?ResultShape {
        return switch (t) {
            .generic => |g| if (std.mem.endsWith(u8, g.name, "Result") and g.args.len == 2) .{
                .ok_str = isStringTypeRef(g.args[0]),
                .err_str = isStringTypeRef(g.args[1]),
            } else null,
            else => null,
        };
    }

    fn resultShapeOf(self: *Emitter, e: ast.Expr) ?ResultShape {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.result_shape_locals.get(self.resolveName(n)),
                else => null,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    const sym = self.calleeSymbol(cc, c.loc) orelse break :blk null;
                    break :blk self.result_shape_fns.get(sym);
                },
                else => null,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.resultShapeOf(inner.*),
                else => null,
            },
            else => null,
        };
    }

    /// `@Result<string, E>`.
    fn resultOfString(t: ast.TypeRef) bool {
        return switch (t) {
            .generic => |g| std.mem.endsWith(u8, g.name, "Result") and g.args.len > 0 and isStringTypeRef(g.args[0]),
            else => false,
        };
    }

    /// Whether a body with no declared return type returns a string: some
    /// `return <e>` or its tail is one, judged on literals and fn results
    /// (locals are not known yet).
    fn bodyReturnsString(self: *Emitter, body: []const ast.Stmt) bool {
        if (body.len == 0) return false;
        for (body) |st| switch (st.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |v| if (self.isStringExpr(v.*)) return true,
                else => {},
            },
            else => {},
        };
        return self.isStringExpr(body[body.len - 1].expr);
    }

    /// `val #(a, b) = #(12, "hello")`: an element of a tuple literal lends its
    /// shape to the name bound to it.
    fn noteTupleElemShape(self: *Emitter, name: []const u8, value: ast.Expr, i: usize) !void {
        const elems = switch (value) {
            .collection => |col| switch (col.kind) {
                .tupleLit => |tl| tl.elems,
                else => return,
            },
            else => return,
        };
        if (i >= elems.len) return;
        if (self.isStringExpr(elems[i])) try self.str_locals.put(name, {});
        if (self.isBoolExpr(elems[i])) try self.bool_locals.put(name, {});
    }

    /// Whether a statement list yields a string (its last statement does).
    fn bodyIsString(self: *Emitter, body: []const ast.Stmt) bool {
        if (body.len == 0) return false;
        return self.isStringExpr(body[body.len - 1].expr);
    }

    /// `a + b` on strings → a fresh length-prefixed buffer. Both operands are
    /// plain pointers, so this works for runtime values as well as literals.
    fn lowerStrConcat(self: *Emitter, a: ast.Expr, b: ast.Expr) anyerror!void {
        try self.lowerConcatOperand(a);
        try self.lowerConcatOperand(b);
        try self.emit(self.builder().helper(.str_concat));
    }

    /// One operand of a string `+`. A non-string operand is rendered as text
    /// first — its decimal digits, or `true`/`false` — the rule the erlang
    /// backend's E2 fix follows (`integer_to_binary/1`). It used to be added as
    /// if it were a string pointer.
    fn lowerConcatOperand(self: *Emitter, e: ast.Expr) anyerror!void {
        if (self.optInfoOf(e)) |oi| {
            // none renders as `undefined`, the text the other targets print
            const tmp = try std.fmt.allocPrint(self.arena(), "__opt{d}", .{self.loop_seq});
            self.loop_seq += 1;
            try self.declareLocal(tmp, "i32");
            try self.lowerCoerced(e, "i32");
            try self.emit(.{ .local_tee = tmp });
            try self.emit(opOf("i32", "eqz"));
            const undef = try self.internString("undefined");
            var then_c: Capture = .{};
            self.open(&then_c);
            try self.emit(try self.constInt(undef.offset));
            const then_seq = self.seal(&then_c, .{ .value = .i32 });
            var else_c: Capture = .{};
            self.open(&else_c);
            try self.emit(.{ .local_get = tmp });
            if (oi.boxed) {
                try self.emit(.{ .load = .{} });
                try self.emit(self.builder().helper(.i32_to_str));
            }
            const else_seq = self.seal(&else_c, .{ .value = .i32 });
            try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
            return;
        }
        if (self.isStringExpr(e)) return self.lowerValue(e);
        if (self.isBoolExpr(e)) {
            try self.lowerCoerced(e, "i32");
            const t = try self.internString("true");
            const f = try self.internString("false");
            var then_c: Capture = .{};
            self.open(&then_c);
            try self.emit(try self.constInt(t.offset));
            const then_seq = self.seal(&then_c, .{ .value = .i32 });
            var else_c: Capture = .{};
            self.open(&else_c);
            try self.emit(try self.constInt(f.offset));
            const else_seq = self.seal(&else_c, .{ .value = .i32 });
            try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
            return;
        }
        if (self.wasmTypeOf(e)[0] == 'f') {
            try self.lowerCoerced(e, "f64");
            try self.emit(self.builder().helper(.f64_to_str));
            return;
        }
        try self.lowerCoerced(e, "i32");
        try self.emit(self.builder().helper(.i32_to_str));
    }

    /// A `recv.slice(...)` method call. Codegen is untyped, so a `slice` with a
    /// receiver (and not a builtin) is treated as a string slice.
    fn isStrSlice(cc: anytype) bool {
        return cc.receiver != null and !cc.is_builtin and std.mem.eql(u8, cc.callee, "slice");
    }

    /// `s.slice(start, end)` → a fresh length-prefixed buffer holding the bytes
    /// `[start, end)` of the receiver. A missing `end` slices to the source's
    /// length. Leaves a pointer to the new string on the stack.
    fn lowerStrSlice(self: *Emitter, cc: anytype) anyerror!void {
        try self.lowerExpr(cc.receiver.?.*);
        if (cc.args.len > 0)
            try self.lowerExpr(cc.args[0].value.*)
        else
            try self.emit(zero);
        if (cc.args.len > 1) {
            try self.lowerExpr(cc.args[1].value.*);
        } else {
            // No end argument: slice to the end (load the source length prefix).
            try self.lowerExpr(cc.receiver.?.*);
            try self.emitC(.{ .load = .{} }, "source length");
        }
        try self.emit(self.builder().helper(.str_slice));
    }

    /// `a == b` / `a != b` on strings → byte comparison via `$__str_eq`. The
    /// old lowering compared the two *pointers* with `i32.eq`, which only ever
    /// agreed with the other backends because identical literals are interned
    /// at the same address.
    fn lowerStrEq(self: *Emitter, a: ast.Expr, b: ast.Expr, negate: bool) anyerror!void {
        try self.lowerValue(a);
        try self.lowerValue(b);
        try self.emit(self.builder().helper(.str_eq));
        if (negate) try self.emit(opOf("i32", "eqz"));
    }

    fn lowerLoop(self: *Emitter, lp: anytype) anyerror!void {
        // A loop whose body `yield`s (or `break`s with a value) is a
        // comprehension: every such value is appended to a fresh array, which
        // is the loop's value. Inside an `#[@iterator]`/`#[@generator]` fn the
        // fn's own accumulator (`emitFn`) collects them instead.
        const saved_target = self.yield_target;
        const saved_search = self.search_target;
        defer {
            self.yield_target = saved_target;
            self.search_target = saved_search;
        }
        var result: ?[]const u8 = null;
        if (self.yield_target == null and bodyYields(lp.body)) {
            // Decision 8 §10: the fork is the body. A `yield` anywhere means
            // the loop **collects**; without one, a condition or infinite loop
            // used as a value is a **search** and `break <v>` IS its value, not
            // one element of an array. An iteration loop (`loop (xs) { x -> … }`)
            // always collects — `fn find(xs) -> i32[]` relies on it.
            if (loopIsSearch(lp)) {
                const tgt = try std.fmt.allocPrint(self.reg_arena.allocator(), "__found{d}", .{self.loop_seq});
                try self.declareLocal(tgt, "i32");
                try self.emitC(zero, "§10: a search that never breaks has no value");
                try self.emit(.{ .local_set = tgt });
                self.search_target = tgt;
                result = tgt;
            } else {
                const tgt = try std.fmt.allocPrint(self.reg_arena.allocator(), "__yield{d}", .{self.loop_seq});
                try self.declareLocal(tgt, "i32");
                try self.emit(zero);
                try self.emit(self.builder().helper(.arr_new));
                try self.emit(.{ .local_set = tgt });
                self.yield_target = tgt;
                result = tgt;
            }
        }
        if (lp.condition) return self.lowerConditionLoop(lp, result);
        switch (lp.iter.*) {
            .collection => |col| switch (col.kind) {
                .range => |r| {
                    try self.lowerRangeLoop(lp.params, lp.body, r, result);
                    return;
                },
                else => {},
            },
            else => {},
        }
        if (self.isArrayExpr(lp.iter.*)) return self.lowerCollectionLoop(lp, result);
        // Iterating a lambda-backed iterator or an opaque value has no wasm
        // lowering yet; a no-op is at least loadable.
        try self.emitC(zero, "loop over unknown iterable");
    }

    /// Whether a loop body `yield`s or `break`s with a value — directly or in a
    /// nested `if`/`case` arm, but not inside a nested loop or lambda, whose
    /// values are their own.
    fn bodyYields(body: []const ast.Stmt) bool {
        for (body) |st| if (exprYields(st.expr)) return true;
        return false;
    }

    /// A `yield` anywhere in the body, `if` branches and `case` arms included —
    /// what tells a comprehension (which collects) from a search (whose value
    /// is the one its `break` carries). A nested loop is not descended into:
    /// its `yield`s are its own.
    /// Decision 8 §10 — a condition or infinite `loop` used as a value whose
    /// body holds no `yield`: its value is the one its `break` carries, not a
    /// collection. An iteration loop always collects.
    fn loopIsSearch(lp: anytype) bool {
        return lp.condition and !bodyHasYield(lp.body);
    }

    fn bodyHasYield(body: []const ast.Stmt) bool {
        for (body) |st| if (exprHasYield(st.expr)) return true;
        return false;
    }

    fn exprHasYield(e: ast.Expr) bool {
        return switch (e) {
            .jump => |j| j.kind == .yield,
            .branch => |b| switch (b.kind) {
                .if_ => |i| bodyHasYield(i.then_) or (if (i.else_) |els| bodyHasYield(els) else false),
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| exprHasYield(inner.*),
                .case => |c| blk: {
                    for (c.arms) |arm| if (exprHasYield(arm.body)) break :blk true;
                    break :blk false;
                },
                else => false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| cc.is_builtin and std.mem.eql(u8, cc.callee, "block") and
                    cc.trailing.len > 0 and bodyHasYield(cc.trailing[0].body),
                else => false,
            },
            else => false,
        };
    }

    fn exprYields(e: ast.Expr) bool {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                inline .@"break", .yield => |jl| jl.value != null,
                else => false,
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| bodyYields(i.then_) or (if (i.else_) |els| bodyYields(els) else false),
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| exprYields(inner.*),
                .case => |c| blk: {
                    for (c.arms) |arm| if (exprYields(arm.body)) break :blk true;
                    break :blk false;
                },
                else => false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| cc.is_builtin and std.mem.eql(u8, cc.callee, "block") and cc.trailing.len > 0 and bodyYields(cc.trailing[0].body),
                else => false,
            },
            else => false,
        };
    }

    /// Any `yield` with a value anywhere in a fn body, loops included (not
    /// lambdas) — what makes an `#[@iterator]` body an accumulator.
    fn bodyYieldsDeep(body: []const ast.Stmt) bool {
        for (body) |st| {
            if (exprYields(st.expr)) return true;
            switch (st.expr) {
                .loop => |lp| if (bodyYieldsDeep(lp.body)) return true,
                .jump => |j| switch (j.kind) {
                    .@"return" => |r| if (r) |v| switch (v.*) {
                        .loop => |lp| if (bodyYieldsDeep(lp.body)) return true,
                        else => {},
                    },
                    else => {},
                },
                else => {},
            }
        }
        return false;
    }

    /// `yield v` / `break v` inside a comprehension: append `v` to the
    /// accumulator. A float is appended as its f32 bits.
    fn emitYield(self: *Emitter, v: ast.Expr) anyerror!void {
        const tgt = self.yield_target.?;
        try self.emit(.{ .local_get = tgt });
        if (self.wasmTypeOf(v)[0] == 'f') {
            try self.lowerCoerced(v, "f32");
            try self.emit(.{ .convert = "i32.reinterpret_f32" });
        } else try self.lowerCoerced(v, "i32");
        try self.emit(self.builder().helper(.arr_push));
        try self.emit(.{ .local_set = tgt });
    }

    /// `x` names an `[len][e0][e1]…` blob: an array literal, or a name bound to
    /// one. Deliberately narrow — walking the layout of something else would
    /// read its first word as an element count and trap.
    fn isArrayExpr(self: *Emitter, e: ast.Expr) bool {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.arr_locals.contains(self.resolveName(n)) or self.arr_globals.contains(n),
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.isArrayExpr(inner.*),
                .arrayLit => true,
                else => false,
            },
            // a search answers the value its `break` carries, not an array
            .loop => |lp| bodyYields(lp.body) and !loopIsSearch(lp),
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (self.primKindAt(cc, c.loc)) |k| break :blk primCallRes(k, cc) == .arr;
                    // A slice of an array is an array; `xs[i]` is an element,
                    // which is itself an array when `xs` holds arrays.
                    if (self.indexArgs(cc)) |ix| break :blk if (ix.is_slice)
                        self.isArrayExpr(ix.recv)
                    else if ((self.indexElemShape(cc) catch null)) |s| s[0] == '[' else false;
                    if (cc.is_builtin) break :blk false;
                    if (self.resolvedCallSym(cc, c.loc)) |sym| break :blk self.fn_arr_elem.contains(sym);
                    break :blk self.fn_arr_elem.contains(cc.callee);
                },
                else => false,
            },
            else => false,
        };
    }

    /// `loop (xs) { item -> … }` / `loop (xs, 0..) { item, i -> … }` over the
    /// `[len][e0][e1]…` layout: a counted walk binding each element to the loop
    /// parameter. The loop itself yields 0 — a `yield`/`break`-accumulating
    /// comprehension still collects nothing (see codegen/AGENTS.md).
    fn lowerCollectionLoop(self: *Emitter, lp: anytype, result: ?[]const u8) anyerror!void {
        const ra = self.reg_arena.allocator();
        const n = self.loop_seq;
        self.loop_seq += 1;
        const base = try std.fmt.allocPrint(ra, "__iter{d}", .{n});
        const cur = try std.fmt.allocPrint(ra, "__idx{d}", .{n});
        const len = try std.fmt.allocPrint(ra, "__len{d}", .{n});
        try self.declareLocal(base, "i32");
        try self.declareLocal(cur, "i32");
        try self.declareLocal(len, "i32");

        const elem = if (lp.params.len > 0) lp.params[0] else "__it";
        const elem_kind = self.elemKindOf(lp.iter.*);
        // A float element is an f32 slot: loading it as an i32 read its bits
        // as an integer (`[2.0, 4.0, 9.0]` averaged to `1082480000`).
        const elem_ty = if (elem_kind == .f32) "f32" else "i32";
        try self.declareLocal(elem, elem_ty);
        if (elem_kind == .str) try self.str_locals.put(elem, {});
        const idx_param: ?[]const u8 = if (lp.params.len > 1) lp.params[1] else null;
        if (idx_param) |ip| try self.declareLocal(ip, "i32");
        // `loop (xs, 1..) { x, i -> … }` counts `i` from the range's start.
        const start = try self.indexRangeStart(lp.indexRange, n);

        try self.lowerCoerced(lp.iter.*, "i32");
        try self.emit(.{ .local_set = base });
        try self.emit(.{ .local_get = base });
        try self.emitC(.{ .load = .{} }, "element count");
        try self.emit(.{ .local_set = len });
        try self.emit(zero);
        try self.emit(.{ .local_set = cur });

        var loop_c: Capture = .{};
        self.open(&loop_c);
        try self.emitAt(8, .{ .local_get = cur });
        try self.emitAt(8, .{ .local_get = len });
        try self.emitAt(8, opOf("i32", "ge_s"));
        try self.emitAt(8, .{ .br_if = break_label });
        try self.emitAt(8, .{ .local_get = base });
        try self.emitAt(8, .{ .local_get = cur });
        try self.emitAt(8, try self.constInt(4));
        try self.emitAt(8, opOf("i32", "mul"));
        try self.emitAt(8, opOf("i32", "add"));
        try self.emitAt(8, .{ .load = .{ .ty = vt(elem_ty), .offset = 4 } });
        try self.emitAt(8, .{ .local_set = elem });
        if (idx_param) |ip| {
            try self.emitAt(8, .{ .local_get = cur });
            switch (start) {
                .zero => {},
                .constant => |k| {
                    try self.emitAt(8, k);
                    try self.emitAt(8, opOf("i32", "add"));
                },
                .local => |l| {
                    try self.emitAt(8, .{ .local_get = l });
                    try self.emitAt(8, opOf("i32", "add"));
                },
            }
            try self.emitAt(8, .{ .local_set = ip });
        }
        try self.emitIterationBody(lp.body);
        try self.emitAt(8, .{ .local_get = cur });
        try self.emitAt(8, one);
        try self.emitAt(8, opOf("i32", "add"));
        try self.emitAt(8, .{ .local_set = cur });
        try self.emitAt(8, .{ .br = continue_label });
        const loop_seq = self.seal(&loop_c, .terminated);

        try self.emitLoopBlock(loop_seq);
        if (result) |r| try self.emit(.{ .local_get = r }) else try self.emit(zero);
    }

    const IndexStart = union(enum) { zero, constant: Instr, local: []const u8 };

    /// The first index of `loop (xs, <range>)`: the range's lower bound (`0`
    /// without one, as erlang's `lists:enumerate(Start, Xs)`). An integer
    /// literal is added as a constant; anything else is evaluated once, before
    /// the walk, into `__start<n>`.
    fn indexRangeStart(self: *Emitter, range: anytype, n: u32) anyerror!IndexStart {
        const r = range orelse return .zero;
        const start_expr = switch (r.*) {
            .collection => |col| switch (col.kind) {
                .range => |rg| rg.start.*,
                else => return .zero,
            },
            else => return .zero,
        };
        switch (start_expr) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |text| if (isNumericLiteral(text) and numLitType(text)[0] == 'i') {
                    const k = std.fmt.parseInt(i64, text, 10) catch return .zero;
                    if (k == 0) return .zero;
                    return .{ .constant = try self.constInt(k) };
                },
                else => {},
            },
            else => {},
        }
        const name = try std.fmt.allocPrint(self.reg_arena.allocator(), "__start{d}", .{n});
        try self.declareLocal(name, "i32");
        try self.lowerCoerced(start_expr, "i32");
        try self.emit(.{ .local_set = name });
        return .{ .local = name };
    }

    /// One iteration's statements. A body that `continue`s is wrapped in
    /// `(block $__next …)` so the jump lands on the step; `loop_depth` lets
    /// `break`/`continue` branch at all.
    fn emitIterationBody(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        self.loop_depth += 1;
        defer self.loop_depth -= 1;
        if (!bodyContinues(body)) {
            for (body) |stmt| _ = try self.emitStmt(stmt, false);
            return;
        }
        var c: Capture = .{};
        self.open(&c);
        for (body) |stmt| _ = try self.emitStmt(stmt, false);
        const seq = self.seal(&c, .none);
        try self.emitAt(8, .{ .block = .{ .kind = .block, .label = next_label, .body = seq } });
    }

    fn bodyContinues(body: []const ast.Stmt) bool {
        for (body) |st| if (exprContinues(st.expr)) return true;
        return false;
    }

    fn exprContinues(e: ast.Expr) bool {
        return switch (e) {
            .jump => |j| j.kind == .@"continue",
            .branch => |b| switch (b.kind) {
                .if_ => |i| bodyContinues(i.then_) or (if (i.else_) |els| bodyContinues(els) else false),
                else => false,
            },
            else => false,
        };
    }

    /// `(block $__break (loop $__continue …))` around a lowered loop body, and
    /// the labels both jumps use.
    const break_label = "__break";
    const continue_label = "__continue";
    /// The block around one iteration's body; `continue` branches out of it
    /// to the step.
    const next_label = "__next";

    fn emitLoopBlock(self: *Emitter, body: Seq) !void {
        var block_c: Capture = .{};
        self.open(&block_c);
        try self.emitAt(6, .{ .block = .{
            .kind = .loop,
            .label = continue_label,
            .body = body,
        } });
        const block_seq = self.seal(&block_c, .none);
        try self.emit(.{ .block = .{
            .kind = .block,
            .label = break_label,
            .body = block_seq,
        } });
    }

    /// `loop (condition) { … }` / `loop { … }` (decision 8 §10): test the
    /// condition at the top of every iteration, leave when it is false.
    fn lowerConditionLoop(self: *Emitter, lp: anytype, result: ?[]const u8) anyerror!void {
        const saved_depth = self.cond_break_depth;
        self.cond_break_depth = if (result != null) self.loop_depth + 1 else null;
        defer self.cond_break_depth = saved_depth;

        var loop_c: Capture = .{};
        self.open(&loop_c);
        try self.lowerCoerced(lp.iter.*, "i32");
        try self.emitAt(8, opOf("i32", "eqz"));
        try self.emitAt(8, .{ .br_if = break_label });
        try self.emitIterationBody(lp.body);
        try self.emitAt(8, .{ .br = continue_label });
        const loop_seq = self.seal(&loop_c, .terminated);

        try self.emitLoopBlock(loop_seq);
        if (result) |res| try self.emit(.{ .local_get = res }) else try self.emit(zero);
    }

    fn lowerRangeLoop(self: *Emitter, params: []const []const u8, body: []const ast.Stmt, r: anytype, result: ?[]const u8) anyerror!void {
        const param = if (params.len > 0) params[0] else "__i";
        try self.declareLocal(param, "i32");

        try self.lowerCoerced(r.start.*, "i32");
        try self.emit(.{ .local_set = param });

        var loop_c: Capture = .{};
        self.open(&loop_c);
        if (r.end) |end| {
            try self.emitAt(8, .{ .local_get = param });
            try self.lowerExpr(end.*);
            try self.emitAt(8, opOf("i32", "ge_s"));
            try self.emitAt(8, .{ .br_if = break_label });
        }

        try self.emitIterationBody(body);

        try self.emitAt(8, .{ .local_get = param });
        try self.emitAt(8, one);
        try self.emitAt(8, opOf("i32", "add"));
        try self.emitAt(8, .{ .local_set = param });
        try self.emitAt(8, .{ .br = continue_label });
        const loop_seq = self.seal(&loop_c, .terminated);

        try self.emitLoopBlock(loop_seq);
        if (result) |res| try self.emit(.{ .local_get = res }) else try self.emit(zero);
    }

    // ── numeric types ─────────────────────────────────────────────────────────
    //
    // Codegen is untyped, so the wasm value type of an expression is recovered
    // here: from the literal spelling, the declared type of a local/param, or
    // the callee's registered result. Every operand site then *coerces* to the
    // type the context wants. Without this a `f64` parameter fed an `f32.const`,
    // or an `i32` local assigned a float, fails validation and the whole module
    // is rejected.

    /// Best-effort wasm value type of `e`.
    fn wasmTypeOf(self: *Emitter, e: ast.Expr) []const u8 {
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| if (isNumericLiteral(n)) numLitType(n) else "i32",
                else => "i32",
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.locals.get(self.resolveName(n)) orelse self.global_types.get(n) orelse "i32",
                else => "i32",
            },
            .unaryOp => |un| switch (un.op) {
                .neg => self.wasmTypeOf(un.expr.*),
                .not => "i32",
            },
            .binaryOp => |bin| switch (bin.op) {
                .eq, .ne, .lt, .gt, .lte, .gte, .@"and", .@"or" => "i32",
                else => self.unifyNum(self.wasmTypeOf(bin.lhs.*), self.wasmTypeOf(bin.rhs.*)),
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.wasmTypeOf(inner.*),
                // `emitCaseArms` emits `(if (result {cur_result}))` and coerces
                // every arm to it, so that — not `i32` — is what a `case` leaves
                // on the stack. Saying `i32` made `return case …` in an `f64` fn
                // append a second, bogus `f64.convert_i32_s`.
                .case => self.cur_result,
                else => "i32",
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| if (ifIsStatementForm(i)) "i32" else self.cur_result,
                .tryCatch => self.cur_result,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    // `xs[i]` over a float array reads an `f32` slot
                    if (self.indexArgs(cc)) |ix|
                        break :blk if (!ix.is_slice and self.isArrayExpr(ix.recv) and
                            self.elemKindOf(ix.recv) == .f32) "f32" else "i32";
                    if (cc.is_builtin) break :blk "i32";
                    if (self.primKindAt(cc, c.loc)) |k| break :blk if (primCallRes(k, cc) == .f64) "f64" else "i32";
                    if (self.recordMethodSym(cc, c.loc)) |sym| {
                        if (self.fn_sigs.get(sym)) |sig| break :blk sig.result orelse "i32";
                    }
                    if (self.calleeSymbol(cc, c.loc)) |sym| {
                        if (self.fn_sigs.get(sym)) |sig| break :blk sig.result orelse "i32";
                    }
                    break :blk "i32";
                },
                else => "i32",
            },
            .useHook => |uh| self.wasmTypeOf(uh.kind.inner.*),
            else => "i32",
        };
    }

    /// The type two numeric operands meet in: the wider / floatier of the two.
    fn unifyNum(self: *Emitter, a: []const u8, b: []const u8) []const u8 {
        _ = self;
        if (std.mem.eql(u8, a, b)) return a;
        if (std.mem.eql(u8, a, "f64") or std.mem.eql(u8, b, "f64")) return "f64";
        if (std.mem.eql(u8, a, "f32") or std.mem.eql(u8, b, "f32")) return "f32";
        if (std.mem.eql(u8, a, "i64") or std.mem.eql(u8, b, "i64")) return "i64";
        return "i32";
    }

    /// Emit the conversion opcode that turns a value of type `from` into `to`.
    fn emitConvert(self: *Emitter, from: []const u8, to: []const u8) !void {
        if (std.mem.eql(u8, from, to)) return;
        const eq = std.mem.eql;
        const opcode: ?[]const u8 =
            if (eq(u8, to, "f64"))
                (if (eq(u8, from, "f32")) "f64.promote_f32" else if (eq(u8, from, "i64")) "f64.convert_i64_s" else "f64.convert_i32_s")
            else if (eq(u8, to, "f32"))
                (if (eq(u8, from, "f64")) "f32.demote_f64" else if (eq(u8, from, "i64")) "f32.convert_i64_s" else "f32.convert_i32_s")
            else if (eq(u8, to, "i64"))
                (if (eq(u8, from, "f64")) "i64.trunc_f64_s" else if (eq(u8, from, "f32")) "i64.trunc_f32_s" else "i64.extend_i32_s")
            else if (eq(u8, to, "i32"))
                (if (eq(u8, from, "f64")) "i32.trunc_f64_s" else if (eq(u8, from, "f32")) "i32.trunc_f32_s" else "i32.wrap_i64")
            else
                null;
        if (opcode) |o| try self.emit(.{ .convert = o });
    }

    /// Lower `e` and convert the result to `want`.
    fn lowerCoerced(self: *Emitter, e: ast.Expr, want: []const u8) anyerror!void {
        const from = self.wasmTypeOf(e);
        try self.lowerValue(e);
        try self.emitConvert(from, want);
    }

    /// The print shape both sides of an `==` share when both are tuples of the
    /// same shape — the one case this backend can compare element by element
    /// without a run-time walk, because the shape is static (`(is)` for
    /// `#(1, "a")`). `null` when either side has no shape, when they differ, or
    /// when the shape holds an array (`[X` has no closing code, and an array's
    /// length is only known at run time).
    fn tupleEqShape(self: *Emitter, lhs: ast.Expr, rhs: ast.Expr) anyerror!?[]const u8 {
        const ls = try self.printShapeOf(lhs) orelse return null;
        const rs = try self.printShapeOf(rhs) orelse return null;
        if (ls.len == 0 or ls[0] != '(') return null;
        if (!std.mem.eql(u8, ls, rs)) return null;
        if (std.mem.indexOfScalar(u8, ls, '[') != null) return null;
        return ls;
    }

    /// Leave `1`/`0` for "the tuples at `a` and `b` are equal", by the shape
    /// starting at `shape[start]` (a `(`). Answers the index past its `)`.
    /// Each element is compared by its own code: `i`/`b` as an `i32`, `f` as
    /// the `f32` the 4-byte slot holds, `s` through `$__str_eq` — a string
    /// element is a pointer, so comparing the words would compare addresses —
    /// and `(` by recursing through the pointer the slot holds.
    fn emitTupleEq(self: *Emitter, a: []const u8, b: []const u8, shape: []const u8, start: usize) anyerror!usize {
        var i = start + 1;
        var slot: u32 = 0;
        var first = true;
        while (i < shape.len and shape[i] != ')') {
            const off: u32 = slot * 4;
            switch (shape[i]) {
                '(' => {
                    const na = try self.declRes();
                    const nb = try self.declRes();
                    try self.emit(.{ .local_get = a });
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emit(.{ .local_set = na });
                    try self.emit(.{ .local_get = b });
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emit(.{ .local_set = nb });
                    i = try self.emitTupleEq(na, nb, shape, i);
                },
                'f' => {
                    try self.emit(.{ .local_get = a });
                    try self.emit(.{ .load = .{ .ty = .f32, .offset = @intCast(off) } });
                    try self.emit(.{ .local_get = b });
                    try self.emit(.{ .load = .{ .ty = .f32, .offset = @intCast(off) } });
                    try self.emit(opOf("f32", "eq"));
                    i += 1;
                },
                's' => {
                    try self.emit(.{ .local_get = a });
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emit(.{ .local_get = b });
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emit(self.builder().helper(.str_eq));
                    i += 1;
                },
                else => {
                    try self.emit(.{ .local_get = a });
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emit(.{ .local_get = b });
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emit(opOf("i32", "eq"));
                    i += 1;
                },
            }
            if (!first) try self.emit(opOf("i32", "and"));
            first = false;
            slot += 1;
        }
        if (first) try self.emitC(one, "an empty tuple equals an empty tuple");
        return if (i < shape.len) i + 1 else i;
    }

    fn lowerBinOp(self: *Emitter, op: anytype, lhs: ast.Expr, rhs: ast.Expr) anyerror!void {
        const Op = @TypeOf(op);
        // `x == null` compares the carrier with 0, whatever `x` holds — a
        // string `==` would read the length word at address 0.
        if ((op == Op.eq or op == Op.ne) and (isNullLit(lhs) or isNullLit(rhs))) {
            try self.lowerCoerced(lhs, "i32");
            try self.lowerCoerced(rhs, "i32");
            try self.emit(opOf("i32", if (op == Op.eq) "eq" else "ne"));
            return;
        }
        // A boxed optional against a value: equal only when present and its
        // payload is equal (`null == 0` is false, as on the other targets).
        const lopt = self.optInfoOf(lhs);
        const ropt = self.optInfoOf(rhs);
        if ((op == Op.eq or op == Op.ne) and ((lopt != null and lopt.?.boxed) != (ropt != null and ropt.?.boxed))) {
            const opt_side = if (lopt != null and lopt.?.boxed) lhs else rhs;
            const val_side = if (lopt != null and lopt.?.boxed) rhs else lhs;
            const tmp = try std.fmt.allocPrint(self.arena(), "__opt{d}", .{self.loop_seq});
            self.loop_seq += 1;
            try self.declareLocal(tmp, "i32");
            try self.lowerCoerced(opt_side, "i32");
            try self.emit(.{ .local_tee = tmp });
            var then_c: Capture = .{};
            self.open(&then_c);
            try self.emit(.{ .local_get = tmp });
            try self.emitC(.{ .load = .{} }, "optional payload");
            try self.lowerCoerced(val_side, "i32");
            try self.emit(opOf("i32", "eq"));
            const then_seq = self.seal(&then_c, .{ .value = .i32 });
            var else_c: Capture = .{};
            self.open(&else_c);
            try self.emitC(zero, "none equals no value");
            const else_seq = self.seal(&else_c, .{ .value = .i32 });
            try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
            if (op == Op.ne) try self.emit(opOf("i32", "eqz"));
            return;
        }
        // String operands: concatenation and comparison run through
        // linear-memory helpers rather than the numeric ALU. This used to fire
        // only for literal==literal, so `s == "yes"` compared *pointers* and
        // `a + b` added them.
        if (self.isStringExpr(lhs) or self.isStringExpr(rhs)) switch (op) {
            Op.add => return self.lowerStrConcat(lhs, rhs),
            Op.eq => return self.lowerStrEq(lhs, rhs, false),
            Op.ne => return self.lowerStrEq(lhs, rhs, true),
            else => {},
        };
        // Decision 8 §6 T6 — a tuple is positional at run time and `==`
        // compares its **elements**; T5 — labels take no part. Both sides are
        // pointers into the bump heap, so `i32.eq` on them answered `false` for
        // `#(1, "a") == #(1, "a")`.
        if (op == Op.eq or op == Op.ne) {
            if (try self.tupleEqShape(lhs, rhs)) |shape| {
                const a = try self.declRes();
                const b = try self.declRes();
                try self.lowerCoerced(lhs, "i32");
                try self.emit(.{ .local_set = a });
                try self.lowerCoerced(rhs, "i32");
                try self.emit(.{ .local_set = b });
                _ = try self.emitTupleEq(a, b, shape, 0);
                if (op == Op.ne) try self.emit(opOf("i32", "eqz"));
                return;
            }
        }
        const t = self.unifyNum(self.wasmTypeOf(lhs), self.wasmTypeOf(rhs));
        try self.lowerCoerced(lhs, t);
        try self.lowerCoerced(rhs, t);
        const is_float = t[0] == 'f';
        const opname: ?[]const u8 = switch (op) {
            Op.add => "add",
            Op.sub => "sub",
            Op.mul => "mul",
            Op.div => if (is_float) "div" else "div_s",
            Op.mod => if (is_float) null else "rem_s",
            Op.lt => if (is_float) "lt" else "lt_s",
            Op.gt => if (is_float) "gt" else "gt_s",
            Op.lte => if (is_float) "le" else "le_s",
            Op.gte => if (is_float) "ge" else "ge_s",
            Op.eq => "eq",
            Op.ne => "ne",
            // wasm has no short-circuit form; `and`/`or` are bitwise on the
            // 0/1 carrier, which is the same answer for booleans.
            Op.@"and" => if (is_float) null else "and",
            Op.@"or" => if (is_float) null else "or",
        };
        if (opname) |on| {
            try self.emit(opOf(t, on));
        } else {
            // No opcode for this pair (float `%`, float `&&`): discard the rhs
            // and keep the lhs so the stack stays balanced.
            try self.emitCf(.drop, "unsupported binary op for {s}", .{t});
        }
    }

    fn lowerNeg(self: *Emitter, inner: ast.Expr) anyerror!void {
        const t = self.wasmTypeOf(inner);
        if (t[0] == 'f') {
            try self.lowerValue(inner);
            try self.emit(opOf(t, "neg"));
        } else {
            try self.emit(constOf(t, "0"));
            try self.lowerCoerced(inner, t);
            try self.emit(opOf(t, "sub"));
        }
    }

    fn lowerIfExpr(self: *Emitter, i: anytype) !void {
        // F2 (Optionals tail) — distinguish statement-form `if` (both
        // branches end in void calls / valueless returns) from value-form
        // `if` (the expression yields an i32). Statement-form must NOT
        // carry `(result i32)`; otherwise wasmtime --validate rejects the
        // module because the void-tailed branches don't push a value.
        const then_void = branchIsVoid(i.then_);
        const else_void = if (i.else_) |els| branchIsVoid(els) else false;
        const as_stmt = then_void and else_void;

        // `if (opt) { v -> … }`: the condition is the optional (0 = none), and
        // the arm binds `v` to its payload.
        const bind_tmp: ?[]const u8 = if (i.binding != null) blk: {
            const t = try std.fmt.allocPrint(self.arena(), "__opt{d}", .{self.loop_seq});
            self.loop_seq += 1;
            try self.declareLocal(t, "i32");
            break :blk t;
        } else null;
        if (bind_tmp) |t| {
            try self.lowerCoerced(i.cond.*, "i32");
            try self.emit(.{ .local_tee = t });
        } else try self.lowerExpr(i.cond.*);
        const result: ?ValType = if (as_stmt) null else vt(self.cur_result);

        var then_c: Capture = .{};
        self.open(&then_c);
        if (i.binding) |name| {
            const oi = self.optInfoOf(i.cond.*);
            try self.declareLocal(name, "i32");
            try self.emit(.{ .local_get = bind_tmp.? });
            if (oi) |o| {
                if (o.boxed) try self.emitC(.{ .load = .{} }, "optional payload");
                if (o.str) try self.str_locals.put(name, {});
                if (o.bool_) try self.bool_locals.put(name, {});
                if (o.inner) |tr| try self.local_typerefs.put(name, tr);
            }
            try self.emit(.{ .local_set = name });
        }
        const then_tail = try self.emitBody(i.then_, !as_stmt);
        const then_seq = self.seal(&then_c, stackOf(then_tail, self.cur_result));

        var else_seq: ?Seq = null;
        if (i.else_) |els| {
            var else_c: Capture = .{};
            self.open(&else_c);
            const else_tail = try self.emitBody(els, !as_stmt);
            else_seq = self.seal(&else_c, stackOf(else_tail, self.cur_result));
        } else if (!as_stmt) {
            // A value-form `if` must fill its `(result …)` on both paths.
            var else_c: Capture = .{};
            self.open(&else_c);
            try self.emitAt(8, constOf(self.cur_result, "0"));
            else_seq = self.seal(&else_c, .{ .value = vt(self.cur_result) });
        }

        try self.emit(.{ .@"if" = .{
            .result = result,
            .then = .{ .seq = then_seq },
            .@"else" = if (else_seq) |s| .{ .seq = s } else null,
        } });
    }

    /// True when an if-branch body ends in a void expression (a void
    /// builtin call like `@print`/`@panic`/`@todo`, or a valueless
    /// `return`). Drives the statement-form `(if ...)` emission above.
    fn branchIsVoid(body: []const ast.Stmt) bool {
        if (body.len == 0) return true;
        const last = body[body.len - 1].expr;
        return switch (last) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| r == null,
                .throw_, .@"continue" => true,
                else => false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| isVoidBuiltinCall(cc),
                else => false,
            },
            .binding => true,
            else => false,
        };
    }
};

// ── small helpers ────────────────────────────────────────────────────────────

fn numLitType(n: []const u8) []const u8 {
    for (n) |c| if (c == '.' or c == 'e' or c == 'E') return "f32";
    return "i32";
}

fn exprNumType(e: ast.Expr) []const u8 {
    return switch (e) {
        .literal => |lit| switch (lit.kind) {
            .numberLit => |n| numLitType(n),
            else => "i32",
        },
        .unaryOp => |un| switch (un.op) {
            .neg => exprNumType(un.expr.*),
            else => "i32",
        },
        .binaryOp => |bin| exprNumType(bin.lhs.*),
        .collection => |col| switch (col.kind) {
            .grouped => |inner| exprNumType(inner.*),
            else => "i32",
        },
        else => "i32",
    };
}
