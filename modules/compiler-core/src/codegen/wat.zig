/// WebAssembly Text (`.wat`) codegen backend.
///
/// Lowers botopink into the `wat/wat_ast.zig` code model; `wat/wat_emitter.zig`
/// turns that model into the `(module ...)` text `wasmtime` executes. Nothing
/// in this file writes target syntax — the same split as `codegen/erlang.zig`
/// over `codegen/beam/erl_ast.zig`.
///
/// Covers: numeric fn decls, arithmetic, comparisons, if/else, return,
/// top-level val as globals, fn main/0 wrapper, linear memory with bump
/// allocator, length-prefixed strings (`.len`/`.slice`/concat/compare),
/// @print via WASI fd_write, case via if-chain, loops via block/loop/br_if,
/// tuples/arrays in memory, lambdas as i32 indices.
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const crossModule = @import("./crossModule.zig");
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

/// Emit a single function declaration as WAT inside a fresh `(module ...)`
/// wrapper, with no program context (no comptime vals, no dispatch rewrites,
/// no cross-module link table). Wat-side analogue of `commonJS.emitFnJs`.
///
/// The comptime template evaluator (`comptime/template_eval.zig` F8 path)
/// calls into here when assembling the per-template wasm module: the
/// `wat_runtime` prelude supplies the comptime surface (`__expr`/`__code`
/// / `__capture` and friends), and this fn emits the template body as a
/// pub callable. The combined source then runs through `wasm3_host.runWat`.
pub fn emitFnWat(alloc: std.mem.Allocator, out: *std.Io.Writer, f: ast.FnDecl) !void {
    const cv = std.StringHashMap([]const u8).init(alloc);
    const rewrites = std.AutoHashMap(ast.Loc, []const u8).init(alloc);
    var em = Emitter.init(alloc, cv, rewrites);
    em.uses_str_concat_rt = true; // template bodies use runtime string concat
    defer em.deinit();
    try em.emitFn(f);
    // Forms only, no `(module …)` wrapper: the caller concatenates them with
    // the `wat_runtime` prelude, which is where this fn's `$__str_concat_rt` /
    // `$__capture` callees are defined.
    for (em.items.items) |it| try watEmitter.renderItem(out, it);
}

pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    _ = config;
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    // Built only to detect (and flag) cross-module imports — wasm stays
    // single-module today, so it links nothing; the index lets `emitWat`
    // record the explicit limitation instead of silently emitting a `call`
    // to a function that lives in another module.
    var cross = try crossModule.build(alloc, outputs);
    defer cross.deinit();

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError => continue,
            .typeError => continue,
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
                const code = try emitWat(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, &cross);
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

// ── top-level emitter ────────────────────────────────────────────────────────

const DataSeg = struct { offset: u32, len: u32, content: []const u8 };

fn emitWat(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    cross: ?*const CrossModule,
) ![]u8 {
    _ = module_name;

    var em = Emitter.init(alloc, comptime_vals, rewrites);
    defer em.deinit();
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

    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| if (!f.isHost()) try em.emitFn(f),
        .val => |v| {
            if (!isSyntheticEntrypointVal(v)) try em.emitGlobalVal(v);
        },
        .comment => |c| try em.itemComment(c.text),
        // Extension methods lower to linear-memory functions named
        // `$<target>_<method>` so activated/qualified dispatch can `call` them.
        .implement => |im| try em.emitExtensionMethods(im.target, im.methods),
        .extend => |ex| try em.emitExtensionMethods(ex.target, ex.methods),
        // Record / struct methods piggy-back on the same emission machinery as
        // extension methods (same `$<target>_<method>` mangling); `self` is the
        // record pointer + a method body's `self.field` walks the declared
        // layout via `self_type`.
        .record => |r| try em.emitInterfaceMethods(r.name, r.methods),
        // KNOWN GAP: wasm is single-module. A `from "<pkg>"` import that
        // resolves to a concrete emitted symbol in another module can't be
        // linked here (no wasm module-linking story yet) — flag it explicitly
        // so the broken `call $sym` below isn't silently mistaken for working
        // code. erlang/beam handle this via remote calls (see crossModule.zig).
        .use => |u| if (cross) |xc| {
            for (u.imports) |imp| {
                if (xc.exports.get(imp.name())) |info| {
                    try em.itemCommentF(
                        "cross-module import not linked (wasm single-module): {s} from {s}",
                        .{ imp.name(), info.module },
                    );
                }
            }
        },
        .@"enum", .interface, .delegate, .mod, .@"test" => {},
    };

    // After every fn is emitted (their signatures are what the initialisers
    // call) but before the module is assembled (it may intern more strings).
    try em.emitGlobalInit();

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
    if (em.b.helpers.print) try items.append(ar, .{ .import = prelude.fd_write_import });

    try items.append(ar, .{ .memory = .{ .@"export" = "memory", .min_pages = 1 } });

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
    try watEmitter.renderModule(&aw.writer, .{
        .items = items.items,
        .externs = em.b.externs.items,
    });
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
    /// Node factory: owns the arena every built node borrows from, the set of
    /// runtime helpers the lowering has asked for, and the extern symbols it
    /// called. Set up in `init` once `reg_arena` exists.
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
    bool_fns: std.StringHashMap(void),
    /// Module globals: wat value type, plus the string/bool shapes.
    global_types: std.StringHashMap([]const u8),
    str_globals: std.StringHashMap(void),
    /// Names known to hold an `[len][e0][e1]…` array blob. `loop (xs) {…}`
    /// only walks the layout for these; anything else keeps the honest
    /// `;; loop over unknown iterable` no-op rather than reading garbage.
    arr_locals: std.StringHashMap(void),
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
    /// Sequence counter for the `$_res{n}` scratch pointers a Result/Option
    /// method op uses to hold its receiver (and, for `map`, the rewrapped
    /// result) while the tag/payload are read out.
    res_seq: u32 = 0,
    loop_seq: u32 = 0,
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
    /// Template-body mode: `a + b` on two non-literals is string concatenation
    /// through the `wat_runtime` prelude rather than a numeric add. Not a
    /// helper flag — `$__str_concat_rt` lives outside the module.
    uses_str_concat_rt: bool = false,

    /// Static extension dispatch (F6): call-site loc → activated extension symbol.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
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
            .bool_fns = std.StringHashMap(void).init(alloc),
            .global_types = std.StringHashMap([]const u8).init(alloc),
            .str_globals = std.StringHashMap(void).init(alloc),
            .arr_locals = std.StringHashMap(void).init(alloc),
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
        self.bool_fns.deinit();
        self.global_types.deinit();
        self.str_globals.deinit();
        self.arr_locals.deinit();
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
                if (f.isHost() or f.isDeclare or f.body.len == 0) continue;
                const has_result = fnHasResult(f);
                var params: std.ArrayListUnmanaged([]const u8) = .empty;
                for (f.params) |p| {
                    if (std.mem.eql(u8, p.name, "self")) continue;
                    try params.append(ra, watType(p.typeRef));
                }
                try self.fn_sigs.put(f.name, .{
                    .params = try params.toOwnedSlice(ra),
                    .result = if (has_result) watTypeOpt(f.returnType) else null,
                });
                if (f.returnType) |rt| {
                    if (isStringTypeRef(rt)) try self.str_fns.put(f.name, {});
                    if (isBoolTypeRef(rt)) try self.bool_fns.put(f.name, {});
                }
            },
            .val => |v| if (emit_globals and !isSyntheticEntrypointVal(v)) {
                try self.globals.put(v.name, {});
                try self.global_types.put(v.name, self.globalValType(v));
                if (v.typeAnnotation) |ta| {
                    if (isStringTypeRef(ta)) try self.str_globals.put(v.name, {});
                    if (isBoolTypeRef(ta)) try self.bool_globals.put(v.name, {});
                } else switch (v.value.*) {
                    .literal => |lit| switch (lit.kind) {
                        .stringLit => try self.str_globals.put(v.name, {}),
                        else => {},
                    },
                    else => {},
                }
                if (isArrayLit(v.value.*)) try self.arr_globals.put(v.name, {});
            },
            .implement => |im| try self.registerMethodSigs(im.target, im.methods),
            .extend => |ex| try self.registerMethodSigs(ex.target, ex.methods),
            .record => |r| try self.registerInterfaceSigs(r.name, r.methods),
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

    fn registerInterfaceSigs(self: *Emitter, owner: []const u8, methods: []const ast.InterfaceMethod) !void {
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
                .result = if (methodHasResult(body)) "i32" else null,
            });
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
            .record => |r| {
                const names = try ra.alloc([]const u8, r.fields.len);
                const types = try ra.alloc([]const u8, r.fields.len);
                for (r.fields, 0..) |f, i| {
                    names[i] = f.name;
                    types[i] = typeRefName(f.typeRef);
                }
                try self.records.put(r.name, names);
                try self.record_field_types.put(r.name, types);
            },
            .@"enum" => |e| try self.enums.put(e.name, e.variants),
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
                .ident => |name| blk: {
                    if (std.mem.eql(u8, name, "self")) {
                        const st = self.self_type orelse break :blk null;
                        break :blk self.resolveRecordName(st);
                    }
                    const tn = self.local_types.get(name) orelse break :blk null;
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
                            const tn = self.fn_return_types.get(cc.callee) orelse break :blk null;
                            break :blk self.resolveRecordName(tn);
                        },
                        else => break :blk null,
                    }
                },
                else => null,
            },
            .collection => |c| switch (c.kind) {
                .recordLit => |rl| self.ensureAnonRecord(c.loc, rl) catch null,
                .interfaceLit => |il| self.ensureAnonRecord(c.loc, .{ .fields = il.fields }) catch null,
                .grouped => |inner| self.recordTypeOfExpr(inner.*),
                else => null,
            },
            else => null,
        };
    }

    /// Register an anonymous `record { ... }` literal under a synthetic name
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
            // Anon-record field type recovery for nested literals (`{ inner:
            // record { ... } }`): drill in so chained `outer.inner.field`
            // resolves. For non-anon values (literals, calls), leave empty —
            // the existing chained-recovery already handles those via
            // `recordTypeOfExpr` on the receiver.
            types[i] = blk: {
                switch (f.value.*) {
                    .collection => |c2| switch (c2.kind) {
                        .recordLit => |rl2| {
                            const inner = try self.ensureAnonRecord(f.value.getLoc(), rl2);
                            break :blk inner;
                        },
                        else => {},
                    },
                    else => {},
                }
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
        self.bool_locals.clearRetainingCapacity();
        self.pending_locals.clearRetainingCapacity();
        self.cur_result = result_type orelse "i32";
        self.fn_has_result = result_type != null;
        self.case_depth = 0;
        self.try_seq = 0;
        self.mem_seq = 0;
        self.res_seq = 0;
        self.loop_seq = 0;
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

    // ── public single-fn surface ─────────────────────────────────────────
    // `emitFnWat` is the wat-side analogue of `commonJS.emitFnJs`. The
    // comptime template evaluator (`comptime/template_eval.zig` F8 path)
    // calls into here when building the per-template wasm module — the
    // wat_runtime prelude supplies the comptime surface (`__expr`/`__code`
    // / `__capture` etc.), and this fn emits the template body itself.

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
            if (isStringTypeRef(p.typeRef)) try self.str_locals.put(sym, {});
        }
        try self.declareScratch("_try", countTrys(f.body));
        try self.declareScratch("__mem", self.countMems(f.body));
        try self.emitLocalDecls(f.body);

        const body = try self.renderBody(f.body, f);

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
                    if (isStringTypeRef(p.typeRef)) try self.str_locals.put(sym, {});
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
    fn emitInterfaceMethods(self: *Emitter, owner: []const u8, methods: []const ast.InterfaceMethod) !void {
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

    fn emitMemberFn(self: *Emitter, owner: []const u8, m: ast.InterfaceMethod) !void {
        const body = m.body orelse return;
        const has_result = methodHasResult(body);
        self.resetFnState(if (has_result) "i32" else null);
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
                if (isStringTypeRef(p.typeRef)) try self.str_locals.put(sym, {});
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

    /// Search every enum for a variant named `name`. First match wins.
    fn findVariant(self: *Emitter, name: []const u8) ?FoundVariant {
        var it = self.enums.iterator();
        while (it.next()) |entry| {
            for (entry.value_ptr.*, 0..) |v, i| {
                if (std.mem.eql(u8, v.name, name))
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
                .recordLit => |rl| blk: {
                    var n: u32 = 1;
                    for (rl.fields) |f| n += self.countMemsExpr(f.value.*);
                    break :blk n;
                },
                .interfaceLit => |il| blk: {
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
                    if (isArrayLit(lb.value.*)) try self.arr_locals.put(lb.name, {});
                        if (isArrayLit(lb.value.*)) try self.arr_locals.put(lb.name, {});
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
                                for (bindings) |name| try self.declareLocal(name, "i32");
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
                for (lp.params) |p| try self.declareLocal(p, "i32");
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
            .ident => |n| try self.declareLocal(n, "i32"),
            .variant => |v| switch (v.payload) {
                .binding => |b| try self.declareLocal(b, "i32"),
                .fields => |fs| for (fs) |f| try self.declareLocal(f, "i32"),
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
                    const seg = try self.internString(s);
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
                        if (self.fn_has_result)
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
                    if (val) |v| {
                        try self.lowerValue(v.*);
                        try self.emit(.drop);
                    }
                    try self.emit(.@"unreachable");
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
                        try self.lowerValue(v.*);
                        return .value;
                    }
                    return .none;
                },
                .yield => |y| {
                    if (y.value) |v| {
                        try self.lowerValue(v.*);
                        return .value;
                    }
                    return .none;
                },
                .@"continue" => return .none,
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    try self.declareLocal(lb.name, self.inferExprType(lb.value.*));
                    if (self.isStringExpr(lb.value.*)) try self.str_locals.put(lb.name, {});
                    if (isArrayLit(lb.value.*)) try self.arr_locals.put(lb.name, {});
                    if (self.recordTypeOfExpr(lb.value.*)) |rty| try self.local_types.put(lb.name, rty);
                    // Coerce to the type the local was *actually* declared with:
                    // `emitLocalDecls` runs before the body, so its guess can
                    // differ from what lowering ends up pushing.
                    try self.lowerCoerced(lb.value.*, self.locals.get(lb.name) orelse "i32");
                    try self.emit(.{ .local_set = lb.name });
                },
                .assign => |a| switch (a.target) {
                    .name => |name| switch (a.op) {
                        .assign => {
                            // The slot's declared type wins over the value's.
                            try self.lowerCoerced(a.value.*, self.locals.get(name) orelse
                                self.global_types.get(name) orelse "i32");
                            try self.emit(if (self.locals.contains(name))
                                .{ .local_set = name }
                            else
                                .{ .global_set = name });
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
                .@"continue" => .none,
                .try_ => |v| if (v != null) Tail.value else Tail.none,
                inline .@"break", .yield => |jl| if (jl.value != null) Tail.value else Tail.none,
                .await_ => |a| self.exprTail(a.*),
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.exprTail(inner.*),
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
                    const seg = try self.internString(s);
                    try self.emit(try self.constInt(seg.offset));
                },
                // Desugared to a `+` chain by the transform pass; never reaches codegen.
                .stringTemplate => unreachable,
                .comment => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
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
                        try self.emitCf(try self.constInt(fv.tag), ".{s}", .{name});
                    } else {
                        try self.emitCf(zero, ".{s}", .{name});
                    }
                },
                .identAccess => |ia| try self.lowerIdentAccess(ia),
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
                .recordLit => |rl| try self.lowerRecordLit(rl),
                .interfaceLit => |il| try self.lowerRecordLit(.{ .fields = il.fields }),
                .range => try self.emitC(zero, "range"),
            },
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| try self.lowerExpr(val.*);
                    try self.emit(.@"return");
                },
                .throw_ => |val| {
                    if (val) |v| try self.lowerExpr(v.*);
                    try self.emit(.@"unreachable");
                },
                .try_ => |val| {
                    if (val) |v| try self.lowerTryPropagate(v.*);
                },
                .await_ => |av| try self.lowerExpr(av.*),
                .@"break" => |br| {
                    if (br.value) |v| try self.lowerExpr(v.*);
                },
                .yield => |y| {
                    if (y.value) |v| try self.lowerExpr(v.*);
                },
                else => try self.noteF("unsupported jump: {s}", .{@tagName(j.kind)}),
            },
            .comptime_ => try self.emit(zero),
            .function => try self.emitC(zero, "lambda"),
            .loop => |lp| try self.lowerLoop(lp),
            else => try self.noteF("unsupported expr: {s}", .{@tagName(e)}),
        }
    }

    // A `@Result` lives in linear memory as a pointer: the tag is the `i32` at
    // `[ptr]` (0 = Ok, non-zero = Error) and the payload is the `i32` at `[ptr+4]`.
    // `try`/`catch` branch on that tag with `if`/`else` — never host exceptions.

    /// `try expr catch handler` → load the tag; Ok yields `[ptr+4]`, Error runs
    /// the handler. Leaves the resulting value on the stack.
    fn lowerTryCatch(self: *Emitter, tc: anytype) anyerror!void {
        const slot = try self.tryName(self.try_seq);
        self.try_seq += 1;
        try self.lowerExpr(tc.expr.*);
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
        try self.lowerExpr(inner);
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
        if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
            try self.lowerResultOptionOp(cc.callee, cc.args);
            return;
        }
        // Decorator builtins — lowered to rawInfra exports.
        //
        // KNOWN GAP: `$__emit` / `$__compilerError` / `$__binding_ref` (and
        // `$__str_concat_rt` in `lowerBinOp`) are defined by the `wat_runtime`
        // prelude a comptime template module is concatenated with. In the
        // whole-program path nothing defines them, so a program that reached
        // one of these arms would emit a `call` to a function the module does
        // not have. `Builder.externCall` records them in `Module.externs`,
        // which is honest about the dependency but does not supply it; no
        // fixture exercises the arms today. Closing it means either lowering
        // them to a stub outside template mode or shipping the definitions.
        if (std.mem.eql(u8, cc.callee, "emit")) {
            if (cc.args.len > 0) {
                try self.lowerExpr(cc.args[0].value.*);
                try self.emit(try self.builder().externCall("__emit"));
            }
            return;
        }
        if (std.mem.eql(u8, cc.callee, "compilerError")) {
            if (cc.args.len > 0) {
                try self.lowerExpr(cc.args[0].value.*);
                try self.emit(try self.builder().externCall("__compilerError"));
            }
            return;
        }
        // Template builtins: Binding.ref(entry) → __binding_ref.
        if (std.mem.eql(u8, cc.callee, "ref")) {
            if (cc.receiver) |recv| {
                try self.lowerExpr(recv.*);
                try self.emit(try self.builder().externCall("__binding_ref"));
            }
            return;
        }
        try self.note("builtin stub");
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
            const slot = try self.declRes();
            try self.lowerExpr(recv.*);
            try self.emit(.{ .local_set = slot });
            try self.emitC(.{ .local_get = slot }, option_shape);

            var then_c: Capture = .{};
            self.open(&then_c);
            // Some: apply the closure to the present value.
            try self.bindLambdaParam(lam, slot);
            try self.inlineLambdaBody(lam.body);
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
                    self.bool_locals.contains(n) or self.bool_globals.contains(n),
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
                    if (cc.is_builtin) break :blk false;
                    if (self.calleeSymbol(cc, c.loc)) |sym| break :blk self.bool_fns.contains(sym);
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

        try self.emitCaseArms(c.arms, subj_local, 0);
    }

    fn emitCaseArms(self: *Emitter, arms: anytype, subj: []const u8, idx: usize) anyerror!void {
        if (idx >= arms.len) {
            try self.emit(zero);
            return;
        }
        const arm = arms[idx];
        switch (arm.pattern) {
            .wildcard, .ident => {
                try self.lowerCoerced(arm.body, self.cur_result);
            },
            .numberLit => |n| {
                try self.emit(.{ .local_get = subj });
                const t = numLitType(n);
                try self.emit(constOf(t, n));
                try self.emit(opOf(t, "eq"));
                try self.emitArmChain(arms, subj, idx, arm.body);
            },
            .stringLit => |s| {
                _ = s;
                try self.emit(.{ .local_get = subj });
                try self.emit(.drop);
                try self.lowerCoerced(arm.body, self.cur_result);
            },
            .@"or" => |pats| {
                try self.emit(zero);
                for (pats) |p| {
                    switch (p) {
                        .numberLit => |n| {
                            try self.emit(.{ .local_get = subj });
                            const t = numLitType(n);
                            try self.emit(constOf(t, n));
                            try self.emit(opOf(t, "eq"));
                            try self.emit(opOf("i32", "or"));
                        },
                        else => {},
                    }
                }
                try self.emitArmChain(arms, subj, idx, arm.body);
            },
            else => {
                try self.lowerCoerced(arm.body, self.cur_result);
            },
        }
    }

    /// The `(if (result …) (then <arm body>) (else <rest of the chain>))` a
    /// tested case arm expands to. The arm's test is already on the stack.
    fn emitArmChain(self: *Emitter, arms: anytype, subj: []const u8, idx: usize, body: ast.Expr) anyerror!void {
        const ty = vt(self.cur_result);

        var then_c: Capture = .{};
        self.open(&then_c);
        try self.lowerCoerced(body, self.cur_result);
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
    fn calleeSymbol(self: *Emitter, cc: anytype, loc: ast.Loc) ?[]const u8 {
        if (self.rewrites.get(loc)) |sym| {
            if (self.extMangledName(&self.sym_buf, sym, cc.callee)) |m| return m;
        }
        if (receiverName(cc)) |rn| {
            if (self.ext_by_name.contains(rn)) {
                if (self.extMangledName(&self.sym_buf, rn, cc.callee)) |m| return m;
            }
        }
        if (self.fn_sigs.contains(cc.callee)) return cc.callee;
        return null;
    }

    /// A call to an ordinary (non-constructor, non-builtin) function. Arguments
    /// are coerced to the callee's declared parameter types and a short call is
    /// padded with zeros, so the emitted `call` always type-checks. A callee
    /// this module never defines lowers to a zero placeholder plus a comment —
    /// `call $undefined` makes the *whole module* unloadable, which used to
    /// take out every fixture that touched an unimplemented stdlib method.
    fn lowerPlainCall(self: *Emitter, cc: anytype) anyerror!void {
        if (self.fn_sigs.get(cc.callee)) |sig| {
            var base: usize = 0;
            // `recv.m(a)` against a top-level `fn m(self, a)`: the receiver is
            // argument 0.
            if (cc.receiver != null and sig.params.len == cc.args.len + 1) {
                try self.lowerCoerced(cc.receiver.?.*, sig.params[0]);
                base = 1;
            }
            for (cc.args, 0..) |arg, i| {
                if (base + i >= sig.params.len) {
                    try self.noteF("extra argument {d} ignored ({s}/{d})", .{ i, cc.callee, sig.params.len });
                    break;
                }
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
        try self.emitCf(zero, "unresolved call: {s}/{d}", .{ cc.callee, cc.args.len });
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
                try self.storeSlotExpr(base, off, arg.value.*);
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
    fn lowerIdentAccess(self: *Emitter, ia: anytype) anyerror!void {
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
                                try self.emitCf(try self.constInt(i), "{s}.{s}", .{ ename, ia.member });
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
        if (member.len < 2 or member[0] != '_') return null;
        var n: u32 = 0;
        for (member[1..]) |c| {
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
                .ident => |n| self.str_locals.contains(n) or self.str_globals.contains(n),
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
                    if (c.arms.len == 0) break :blk false;
                    for (c.arms) |arm| if (!self.isStringExpr(arm.body)) break :blk false;
                    break :blk true;
                },
                else => false,
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| blk: {
                    const els = i.else_ orelse break :blk false;
                    break :blk self.bodyIsString(i.then_) and self.bodyIsString(els);
                },
                .tryCatch => |tc| self.isStringExpr(tc.expr.*) and self.isStringExpr(tc.handler.*),
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (isStrSlice(cc)) break :blk true;
                    if (cc.is_builtin) break :blk false;
                    if (self.calleeSymbol(cc, c.loc)) |sym| {
                        if (self.str_fns.contains(sym)) break :blk true;
                    }
                    break :blk false;
                },
                else => false,
            },
            .useHook => |uh| self.isStringExpr(uh.kind.inner.*),
            else => false,
        };
    }

    /// Whether a statement list yields a string (its last statement does).
    fn bodyIsString(self: *Emitter, body: []const ast.Stmt) bool {
        if (body.len == 0) return false;
        return self.isStringExpr(body[body.len - 1].expr);
    }

    /// `a + b` on strings → a fresh length-prefixed buffer. Both operands are
    /// plain pointers, so this works for runtime values as well as literals.
    fn lowerStrConcat(self: *Emitter, a: ast.Expr, b: ast.Expr) anyerror!void {
        try self.lowerValue(a);
        try self.lowerValue(b);
        try self.emit(self.builder().helper(.str_concat));
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
        switch (lp.iter.*) {
            .collection => |col| switch (col.kind) {
                .range => |r| {
                    try self.lowerRangeLoop(lp.params, lp.body, r);
                    return;
                },
                else => {},
            },
            else => {},
        }
        if (self.isArrayExpr(lp.iter.*)) return self.lowerCollectionLoop(lp);
        // Iterating a lambda-backed iterator or an opaque value has no wasm
        // lowering yet; a no-op is at least loadable.
        try self.emitC(zero, "loop over unknown iterable");
    }

    /// `x` names an `[len][e0][e1]…` blob: an array literal, or a name bound to
    /// one. Deliberately narrow — walking the layout of something else would
    /// read its first word as an element count and trap.
    fn isArrayExpr(self: *Emitter, e: ast.Expr) bool {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.arr_locals.contains(n) or self.arr_globals.contains(n),
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.isArrayExpr(inner.*),
                .arrayLit => true,
                else => false,
            },
            else => false,
        };
    }

    /// `loop (xs) { item -> … }` / `loop (xs, 0..) { item, i -> … }` over the
    /// `[len][e0][e1]…` layout: a counted walk binding each element to the loop
    /// parameter. The loop itself yields 0 — a `yield`/`break`-accumulating
    /// comprehension still collects nothing (see codegen/AGENTS.md).
    fn lowerCollectionLoop(self: *Emitter, lp: anytype) anyerror!void {
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
        try self.declareLocal(elem, "i32");
        const idx_param: ?[]const u8 = if (lp.params.len > 1) lp.params[1] else null;
        if (idx_param) |ip| try self.declareLocal(ip, "i32");

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
        try self.emitAt(8, .{ .load = .{ .offset = 4 } });
        try self.emitAt(8, .{ .local_set = elem });
        if (idx_param) |ip| {
            try self.emitAt(8, .{ .local_get = cur });
            try self.emitAt(8, .{ .local_set = ip });
        }
        for (lp.body) |stmt| _ = try self.emitStmt(stmt, false);
        try self.emitAt(8, .{ .local_get = cur });
        try self.emitAt(8, one);
        try self.emitAt(8, opOf("i32", "add"));
        try self.emitAt(8, .{ .local_set = cur });
        try self.emitAt(8, .{ .br = continue_label });
        const loop_seq = self.seal(&loop_c, .terminated);

        try self.emitLoopBlock(loop_seq);
        try self.emit(zero);
    }

    /// `(block $__break (loop $__continue …))` around a lowered loop body, and
    /// the labels both jumps use.
    const break_label = "__break";
    const continue_label = "__continue";

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

    fn lowerRangeLoop(self: *Emitter, params: []const []const u8, body: []const ast.Stmt, r: anytype) anyerror!void {
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

        for (body) |stmt| {
            _ = try self.emitStmt(stmt, false);
        }

        try self.emitAt(8, .{ .local_get = param });
        try self.emitAt(8, one);
        try self.emitAt(8, opOf("i32", "add"));
        try self.emitAt(8, .{ .local_set = param });
        try self.emitAt(8, .{ .br = continue_label });
        const loop_seq = self.seal(&loop_c, .terminated);

        try self.emitLoopBlock(loop_seq);
        try self.emit(zero);
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
                .ident => |n| self.locals.get(n) orelse self.global_types.get(n) orelse "i32",
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
                    if (cc.is_builtin) break :blk "i32";
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

    fn lowerBinOp(self: *Emitter, op: anytype, lhs: ast.Expr, rhs: ast.Expr) anyerror!void {
        const Op = @TypeOf(op);
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
        // Runtime string concatenation: for template bodies, assume + on
        // non-literal operands is string concat.
        if (self.uses_str_concat_rt and op == Op.add and isStrLit(lhs) == null and isStrLit(rhs) == null) {
            try self.lowerValue(lhs);
            try self.lowerValue(rhs);
            try self.emit(try self.builder().externCall("__str_concat_rt"));
            return;
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

        try self.lowerExpr(i.cond.*);
        const result: ?ValType = if (as_stmt) null else vt(self.cur_result);

        var then_c: Capture = .{};
        self.open(&then_c);
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
