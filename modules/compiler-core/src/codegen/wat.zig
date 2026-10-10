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
const context_lower = @import("../comptime/context_lower.zig");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const crossModule = @import("./crossModule.zig");
const hostMethods = @import("./hostMethods.zig");
const envMod = @import("../comptime/env.zig");
const wat = @import("./wat/wat_ast.zig");
const watEmitter = @import("./wat/wat_emitter.zig");
const wasmBinary = @import("./wat/wasm_binary_emitter.zig");
const prelude = @import("./wat/wat_prelude.zig");
const hostBinding = @import("./wat/host_binding.zig");
const hostFnBinding = @import("./hostFnBinding.zig");

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

/// The payload name a caller reads for a `?V` over a type parameter
/// (`Emitter.eraseOptTypeParam`): a name no program can declare.
const tparam_marker = "__tparam";

/// `i32.const 1` — the true carrier.
const one: Instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } };

/// The bump-allocator pointer every aggregate construction advances.
const heap_ptr = "__heap_ptr";

/// The header a value that knows its own declaration carries
/// (13-module-identity half 3, decision 22): one i32 holding the address of
/// the type descriptor, written BEHIND the pointer the value is, so every
/// field offset is what it was before the header existed.
const tag_header_bytes: u32 = 4;

/// The lowest address the bump allocator ever answers. A value below it is not
/// a pointer, so `x is T` must not read a header behind it.
const heap_floor: i64 = 256;

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

/// A synthetic statement that only calls `main()` — the entrypoint wrapper
/// already does, so it is not run a second time (`beam_asm.zig`'s
/// `isSyntheticMainCall`, erlang's `isSyntheticMainEntrypointCall`).
fn isSyntheticMainCall(v: ast.ValDecl) bool {
    if (std.mem.startsWith(u8, v.name, "_main")) return true;
    return isSyntheticEntrypointVal(v) and isZeroArgMainCall(v.value.*);
}

fn isZeroArgMainCall(e: ast.Expr) bool {
    return switch (e) {
        .call => |c| switch (c.kind) {
            .call => |cc| !cc.is_builtin and cc.receiver == null and cc.args.len == 0 and
                cc.trailing.len == 0 and std.mem.eql(u8, cc.callee, "main"),
            else => false,
        },
        .jump => |j| switch (j.kind) {
            .@"return" => |r| if (r) |rp| isZeroArgMainCall(rp.*) else false,
            .try_ => |t| if (t) |tp| isZeroArgMainCall(tp.*) else false,
            else => false,
        },
        .collection => |col| switch (col.kind) {
            .grouped => |g| isZeroArgMainCall(g.*),
            else => false,
        },
        else => false,
    };
}

/// The value an eager effect wrapper carries. wasm runs a `@Task<T>` and a
/// `@Component<T>` in place (`await` and `use` are identity), so a value of
/// either type IS its `T`: every question about its representation — a string,
/// a `@Result` with a string payload, an array, a record — is asked of `T`.
/// Nested wrappers peel all the way (`@Task<@Task<string>>` is a string).
fn eagerTypeRef(t: ast.TypeRef) ast.TypeRef {
    return switch (t) {
        .generic => |g| if (g.is_builtin and g.args.len == 1 and std.mem.eql(u8, g.name, "Task"))
            eagerTypeRef(g.args[0])
        else if (g.is_builtin and g.args.len == 1 and std.mem.eql(u8, g.name, "Component"))
            eagerTypeRef(g.args[0])
        else
            t,
        else => t,
    };
}

fn watType(t0: ast.TypeRef) []const u8 {
    const t = eagerTypeRef(t0);
    switch (t) {
        .named => |n| {
            if (std.mem.eql(u8, n, "i32")) return "i32";
            // `u32` and `u64` past `2^31` do not fit the signed `i32` word:
            // `4294967295` printed `-1`. Both are held as an `i64`.
            if (std.mem.eql(u8, n, "i64") or std.mem.eql(u8, n, "u64") or std.mem.eql(u8, n, "u32")) return "i64";
            // An `f32` is held as the `f64` it is on commonJS (a JS number):
            // narrowed, `val x: f32 = 0.1` printed `0.10000000149011612`.
            if (std.mem.eql(u8, n, "f32")) return "f64";
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
    return switch (eagerTypeRef(t)) {
        .named => |n| std.mem.eql(u8, n, name),
        .optional => |inner| isNamedTypeRef(inner.*, name),
        else => false,
    };
}

/// The wasm type of a method's parameter or result: a declared float is the
/// float it names, everything else the `i32` word a method has always passed.
/// A method declared `-> f64` had an `(result i32)` and truncated its answer
/// (`self.x / 2.0` returned `0`).
fn memberValType(t: ast.TypeRef) []const u8 {
    const w = watType(t);
    return if (w[0] == 'f' or std.mem.eql(u8, w, "i64")) w else "i32";
}

/// The 8-byte cell a field or an optional of the named type holds its value
/// in (`Emitter.Cell`): a float or a 64-bit integer; `.none` for a word.
fn fieldCellOf(n: []const u8) Emitter.Cell {
    if (isFloatTypeName(n)) return .f64;
    if (std.mem.eql(u8, n, "i64") or std.mem.eql(u8, n, "u64") or std.mem.eql(u8, n, "u32")) return .i64;
    return .none;
}

/// The shape code of a value held in an `i64` cell, by its type's name: `u`
/// for a `u64` (unsigned digits, decision 319), `l` for an `i64` or a `u32`;
/// null for a type held in a word or an `f64` cell.
fn i64CellCode(n: []const u8) ?u8 {
    if (fieldCellOf(n) != .i64) return null;
    return if (std.mem.eql(u8, n, "u64")) 'u' else 'l';
}

/// `i` / `f` for an array of integers / floats (`i32[]`, `Array<f64>`), the
/// two flat element kinds with a printer of their own; null otherwise.
fn arrayScalarCode(t: ast.TypeRef) ?u8 {
    const elem: ast.TypeRef = switch (t) {
        .array => |ie| ie.*,
        .generic => |g| if (g.args.len == 1 and std.mem.eql(u8, g.name, "Array")) g.args[0] else return null,
        else => return null,
    };
    const n = switch (elem) {
        .named => |x| x,
        else => return null,
    };
    if (std.mem.eql(u8, n, "i32") or std.mem.eql(u8, n, "int")) return 'i';
    if (isFloatTypeName(n)) return 'f';
    return null;
}

/// A declared float type name — `f64`, `f32` or `float`.
fn isFloatTypeName(n: []const u8) bool {
    return std.mem.eql(u8, n, "f64") or std.mem.eql(u8, n, "f32") or std.mem.eql(u8, n, "float");
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
    // Decision 334: which `#[@External.Wasm(…, host: …)]` a `declare fn`
    // lowers to (`wasm` is the `wasi` host's lookup, `wasm.browser` the
    // browser's).
    const external_lookup = config.wasm_host.lookupName();
    // What the text is: the module, or the build's artifact for its host.
    const artifact: Artifact = if (config.wasm_artifact) switch (config.wasm_host) {
        .wasi => .component,
        .browser => .browser,
    } else .module;
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    // wasm has no module linking at run time, so a module that imports from
    // another is linked statically: the owner's declarations are emitted into
    // the consumer (`collectLinks`). The index resolves an imported name to
    // the module that defines it.
    var cross = try crossModule.build(alloc, outputs);
    defer cross.deinit();

    // What `relocateLinkedRefusals` reads once every module is emitted: the
    // message each refused module carries, and the modules each one links.
    var notes_arena = std.heap.ArenaAllocator.init(alloc);
    defer notes_arena.deinit();
    const na = notes_arena.allocator();
    var refusals: std.StringHashMapUnmanaged([]const u8) = .empty;
    var refused_links: std.ArrayListUnmanaged(RefusedLinks) = .empty;

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
                try collectLinks(alloc, outputs, &cross, ok.transformed, &visited, &linked, null);
                // 06 C13 — a host-backed fn with no `wasm` target reaches the
                // driver as a located diagnostic naming the function, not as
                // the bare error name that would abort the whole build.
                var missing: ?moduleOutput.MissingExternal = null;
                var refused: ?Emitter.Refusal = null;
                const emitted = emitWat(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, ok.instance_lowerings, linked.items, &cross, external_lookup, artifact, &missing, &refused) catch |err| {
                    // A construct this backend cannot lower reaches the
                    // driver the same way: located, naming the construct,
                    // failing only this module.
                    const diagnostic: moduleOutput.Diagnostic = if (missing) |me|
                        try me.diagnostic(alloc)
                    else if (refused) |r|
                        .{ .type = .{ .message = r.message, .loc = r.loc } }
                    else
                        return err;
                    try refusals.put(na, ct.name, try na.dupe(u8, diagnostic.type.message));
                    const links = try na.alloc(LinkVia, linked.items.len);
                    for (linked.items, links) |l, *lv| lv.* = .{ .name = l.name, .via = l.via };
                    try refused_links.append(na, .{ .result = results.items.len, .links = links });
                    try results.append(alloc, .{
                        .name = ct.name,
                        .src = ct.src,
                        .result = .{
                            .js = try alloc.dupe(u8, ""),
                            .comptime_script = null,
                            .diagnostic = diagnostic,
                        },
                    });
                    continue;
                };
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = emitted.text,
                        .wasm = emitted.binary,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
                        .comptime_trace = try comptimeMod.trace.renderAlloc(alloc, ok.comptime_traces),
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    try relocateLinkedRefusals(alloc, results.items, &refusals, refused_links.items);
    return results;
}

/// A module one refused module links, and the import item of that module
/// that reaches it (`Linked.via`).
const LinkVia = struct { name: []const u8, via: ast.Loc };

/// A refused module's entry in the results, and what it links.
const RefusedLinks = struct { result: usize, links: []const LinkVia };

/// A module this backend refuses takes every module that links it down with
/// it: the linked declarations are emitted INTO the consumer, so the consumer
/// meets the same refusal — at a location of the linked module's file, which
/// the driver would print against the consumer's (`src/main.bp:101:9` for a
/// call at `std/testing/asserts.bp:101:9`). The refused module reports its
/// own diagnostic, in its own file; each consumer reports the same message at
/// its import that links the module, naming it.
fn relocateLinkedRefusals(
    alloc: std.mem.Allocator,
    results: []ModuleOutput,
    refusals: *const std.StringHashMapUnmanaged([]const u8),
    refused_links: []const RefusedLinks,
) !void {
    for (refused_links) |rl| for (rl.links) |l| {
        const why = refusals.get(l.name) orelse continue;
        const d = &(results[rl.result].result.diagnostic orelse break);
        const message = try std.fmt.allocPrint(alloc, "{s} — in `{s}`, which this import links", .{ why, l.name });
        alloc.free(d.type.message);
        d.* = .{ .type = .{ .message = message, .loc = l.via } };
        break;
    };
}

// ── static linking ───────────────────────────────────────────────────────────

/// A module whose declarations are emitted into a consumer, with the loc-keyed
/// tables its own lowering needs (locs are per source file, so the consumer's
/// tables would answer for the wrong nodes).
const Linked = struct {
    /// The module's path (`sec/jwt`) — what a mangled name starts with.
    name: []const u8,
    program: ast.Program,
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    /// The import item of the CONSUMER that reaches this module — its own
    /// import, or the one whose module imports this one in turn. Where the
    /// consumer reports a refusal of this module (`relocateLinkedRefusals`).
    via: ast.Loc,
};

/// Every module `program` imports from, transitively, dependencies first. An
/// import resolves through the export index (`import {double} from "math"`)
/// or names a module by its basename (`import {order} from "std"`). `via` is
/// null for the consumer's own program and, below it, the consumer's import
/// item the walk came through.
fn collectLinks(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    cross: *const CrossModule,
    program: ast.Program,
    visited: *std.StringHashMap(void),
    out: *std.ArrayListUnmanaged(Linked),
    via: ?ast.Loc,
) !void {
    // The import sources synthesised below are scratch: they answer one
    // ownership question each and are not kept.
    var scratch = std.heap.ArenaAllocator.init(alloc);
    defer scratch.deinit();
    const sa = scratch.allocator();
    for (program.decls) |decl| {
        const u = switch (decl) {
            .use => |u| u,
            else => continue,
        };
        for (u.imports) |imp| {
            for (outputs) |*o| {
                // Which module actually defines this name, asked of the
                // import's own `from "<mod>"`. `exports.get` is keyed by the
                // bare name, so two modules exporting one name linked whichever
                // the index's walk reached last INTO the consumer: measured,
                // `import {parse} from "one"` linked `two`'s body and the
                // program printed the other module's answer at exit 0.
                // A qualified item (decision 107) asks for its LEAF in the
                // module its prefix names; the whole path names a module
                // outright (`import {io.fs} from "std"` → `std/io/fs`).
                const leaf_src = try u.leafSource(imp, sa, false);
                const whole = try u.leafSource(imp, sa, true);
                const owns = if (cross.picked(imp.leaf(), leaf_src, null)) |info|
                    std.mem.eql(u8, info.module, o.name)
                else
                    whole.namesModule(o.name) or (whole != .key and std.mem.eql(u8, crossModule.moduleBasename(o.name), imp.leaf()));
                if (!owns or visited.contains(o.name)) continue;
                const ok = switch (o.outcome) {
                    .ok => |*ok| ok,
                    else => continue,
                };
                try visited.put(o.name, {});
                const reached = via orelse imp.loc;
                try collectLinks(alloc, outputs, cross, ok.transformed, visited, out, reached);
                try out.append(alloc, .{
                    .name = o.name,
                    .program = ok.transformed,
                    .rewrites = ok.dispatch_rewrites,
                    .instance_lowerings = ok.instance_lowerings,
                    .via = reached,
                });
            }
        }
    }
}

/// The name a value of a linked type prints under: a mangled `<module>/<Name>`
/// (or `<module>/<Enum>.<Variant>`) is its declaration's `Name` again — the
/// mangling is this backend's namespace, not the program's.
fn displayTypeName(name: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, name, '/')) |i| return name[i + 1 ..];
    return name;
}

/// Whether `b` is a primitive behavior of the std prelude (`String`, `Array`,
/// the numeric tower, `Bool`, `Function`, `Pair`) whose declaration already
/// sits in `own` or `linked` with the same members, name for name — the
/// prelude materialised twice.
fn samePreludeBehavior(b: ast.BehaviorDecl, own: []const ast.DeclKind, linked: []const ast.DeclKind) bool {
    const prelude_names = [_][]const u8{ "String", "Array", "Bool", "Number", "Integer", "Signed", "Float", "I32", "I64", "U32", "U64", "F32", "F64", "Function", "Pair" };
    const is_prelude = for (prelude_names) |pn| {
        if (std.mem.eql(u8, pn, b.name)) break true;
    } else false;
    if (!is_prelude) return false;
    for ([_][]const ast.DeclKind{ own, linked }) |list| for (list) |d| {
        if (d != .behavior or !std.mem.eql(u8, d.behavior.name, b.name)) continue;
        const other = d.behavior;
        if (other.methods.len != b.methods.len) return false;
        for (other.methods, b.methods) |x, y| if (!std.mem.eql(u8, x.name, y.name)) return false;
        return true;
    };
    return false;
}

/// `link_mangled`'s key: the module that declares `name`, then the name.
fn linkKey(arena: std.mem.Allocator, module: []const u8, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00{s}", .{ module, name });
}

/// The calls module `module_name` (whose declarations are `program`) writes
/// that mean a MANGLED function: its own function of that name, and every
/// import — an alias, a namespace call's synthesised alias
/// (`__bp_ns_jwt__sign`) — whose owner's function was mangled. Local name →
/// mangled name.
fn linkRenames(
    arena: std.mem.Allocator,
    mangled: *const std.StringHashMapUnmanaged([]const u8),
    cross: ?*const CrossModule,
    module_name: []const u8,
    program: ast.Program,
    out: *std.StringHashMapUnmanaged([]const u8),
) !void {
    for (program.decls) |d| switch (d) {
        .@"fn" => |f| if (mangled.get(try linkKey(arena, module_name, f.name))) |m| try out.put(arena, f.name, m),
        .use => |u| for (u.imports) |imp| {
            // A namespace item (`import {url} from "std"`): every mangled
            // function of the module it names is reached as `url.parse(…)`,
            // a call with the namespace as its receiver. Keyed
            // `<namespace>.<fn>` — no function name holds a dot — and
            // rewritten to the plain mangled call by `renameLinkedCalls`.
            // Without it the receiver was dropped and `url.parse(…)` called
            // whichever `parse` kept the bare name (`querystring`'s), at
            // exit 0.
            const whole_module: ?[]const u8 = switch (try u.leafSource(imp, arena, true)) {
                .module, .key => |m| m,
                .root => null,
            };
            if (whole_module) |wm| {
                const ns = imp.alias orelse imp.leaf();
                var it = mangled.iterator();
                while (it.next()) |e| {
                    const sep = std.mem.indexOfScalar(u8, e.key_ptr.*, 0) orelse continue;
                    if (!std.mem.eql(u8, e.key_ptr.*[0..sep], wm)) continue;
                    const key = try std.fmt.allocPrint(arena, "{s}.{s}", .{ ns, e.key_ptr.*[sep + 1 ..] });
                    try out.put(arena, key, e.value_ptr.*);
                }
            }
            const c = cross orelse continue;
            const src = try u.leafSource(imp, arena, false);
            const info = c.picked(imp.leaf(), src, null) orelse continue;
            const m = mangled.get(try linkKey(arena, info.module, imp.leaf())) orelse continue;
            try out.put(arena, imp.alias orelse imp.leaf(), m);
        },
        else => {},
    };
}

/// `linkRenames` for the module-level `val`s: the module's own `val` whose
/// declaration was mangled, and every import of one. Local name → mangled.
fn linkValRenames(
    arena: std.mem.Allocator,
    mangled: *const std.StringHashMapUnmanaged([]const u8),
    cross: ?*const CrossModule,
    module_name: []const u8,
    program: ast.Program,
    out: *std.StringHashMapUnmanaged([]const u8),
) !void {
    for (program.decls) |d| switch (d) {
        .val => |v| if (mangled.get(try linkKey(arena, module_name, v.name))) |m| try out.put(arena, v.name, m),
        .use => |u| for (u.imports) |imp| {
            const c = cross orelse continue;
            const src = try u.leafSource(imp, arena, false);
            const info = c.picked(imp.leaf(), src, null) orelse continue;
            const m = mangled.get(try linkKey(arena, info.module, imp.leaf())) orelse continue;
            try out.put(arena, imp.alias orelse imp.leaf(), m);
        },
        else => {},
    };
}

/// `linkRenames` for the named types: the module's own `type`, `behavior`,
/// `implement` or `extend` whose declaration was mangled, and every import of
/// a record or an enum whose owner's was. Local name → mangled.
fn linkTypeRenames(
    arena: std.mem.Allocator,
    mangled: *const std.StringHashMapUnmanaged([]const u8),
    cross: ?*const CrossModule,
    module_name: []const u8,
    program: ast.Program,
    out: *std.StringHashMapUnmanaged([]const u8),
) !void {
    for (program.decls) |d| switch (d) {
        .type_ => |t| if (mangled.get(try linkKey(arena, module_name, t.name))) |m| try out.put(arena, t.name, m),
        .behavior => |b| if (mangled.get(try linkKey(arena, module_name, b.name))) |m| try out.put(arena, b.name, m),
        .implement => |im| if (mangled.get(try linkKey(arena, module_name, im.name))) |m| try out.put(arena, im.name, m),
        .extend => |ex| if (mangled.get(try linkKey(arena, module_name, ex.name))) |m| try out.put(arena, ex.name, m),
        .use => |u| for (u.imports) |imp| {
            const c = cross orelse continue;
            const src = try u.leafSource(imp, arena, false);
            const info = c.picked(imp.leaf(), src, null) orelse continue;
            if (info.kind != .record and info.kind != .@"enum") continue;
            const m = mangled.get(try linkKey(arena, info.module, imp.leaf())) orelse continue;
            try out.put(arena, imp.alias orelse imp.leaf(), m);
        },
        else => {},
    };
}

/// The `Enum` half of a written variant path (`Shape.Circle` → `Shape`),
/// renamed when `renames` holds it: `<module>/Shape.Circle`.
fn renameVariantPath(arena: std.mem.Allocator, name: []const u8, renames: *const std.StringHashMapUnmanaged([]const u8)) error{OutOfMemory}![]const u8 {
    const dot = std.mem.lastIndexOfScalar(u8, name, '.') orelse return name;
    const m = renames.get(name[0..dot]) orelse return name;
    return std.fmt.allocPrint(arena, "{s}{s}", .{ m, name[dot..] });
}

/// A copy of `value` in which every reference to a type `renames` holds names
/// the mangled type instead: a type written in a signature, an annotation or
/// a type argument (`Response`, `Response<T>`), a constructor call
/// (`Response(html: …)`), the type of an `Enum.Variant` access or call, a
/// `case` arm's path (`Shape.Circle`), an `extend`/`implement` target. The
/// walk `renameLinkedCalls` takes: the strings and the nodes no rename reaches
/// are shared, never mutated.
fn renameLinkedTypes(comptime T: type, arena: std.mem.Allocator, value: T, renames: *const std.StringHashMapUnmanaged([]const u8)) error{OutOfMemory}!T {
    if (T == ast.TypeRef) switch (value) {
        .named => |n| return if (renames.get(n)) |m| .{ .named = m } else value,
        .generic => |g| {
            var out = g;
            if (renames.get(g.name)) |m| out.name = m;
            out.args = try renameLinkedTypes(@TypeOf(g.args), arena, g.args, renames);
            return .{ .generic = out };
        },
        else => {},
    };
    if (T == ast.Pattern) switch (value) {
        .ident => |n| return .{ .ident = try renameVariantPath(arena, n, renames) },
        .variant => |v| {
            var out = v;
            out.name = try renameVariantPath(arena, v.name, renames);
            out.payload = try renameLinkedTypes(@TypeOf(v.payload), arena, v.payload, renames);
            return .{ .variant = out };
        },
        else => {},
    };
    switch (@typeInfo(T)) {
        .@"struct" => |st| {
            var out: T = value;
            inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                @field(out, f.name) = try renameLinkedTypes(f.type, arena, @field(value, f.name), renames);
            }
            // A plain call names a record constructor; `Enum.Variant(…)` is
            // reached through its receiver, an identifier renamed below.
            if (comptime @hasField(T, "callee") and @hasField(T, "receiver") and @hasField(T, "calleeExpr") and @hasField(T, "is_builtin")) {
                if (out.receiver == null and out.calleeExpr == null and !out.is_builtin) {
                    if (renames.get(out.callee)) |m| out.callee = m;
                }
            }
            // An `extend` / `implement` block's target type.
            if (comptime @hasField(T, "target") and @hasField(T, "methods") and @hasField(T, "shorthand") and @FieldType(T, "target") == []const u8) {
                if (renames.get(out.target)) |m| out.target = m;
            }
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return value;
            // `Enum.Variant` reads and calls, and a type named as a value.
            if (comptime @hasField(T, "ident") and @hasField(T, "dotIdent") and @hasField(T, "identAccess")) {
                if (value == .ident) if (renames.get(value.ident)) |m| return .{ .ident = m };
            }
            switch (value) {
                inline else => |payload, tag| return @unionInit(T, @tagName(tag), try renameLinkedTypes(@TypeOf(payload), arena, payload, renames)),
            }
        },
        .optional => |o| return if (value) |v| try renameLinkedTypes(o.child, arena, v, renames) else null,
        .pointer => |p| switch (p.size) {
            .one => {
                if (comptime !isAstNodeType(p.child)) return value;
                const n = try arena.create(p.child);
                n.* = try renameLinkedTypes(p.child, arena, value.*, renames);
                return n;
            },
            .slice => {
                if (comptime !isAstNodeType(p.child)) return value;
                const n = try arena.alloc(p.child, value.len);
                for (value, 0..) |e, i| n[i] = try renameLinkedTypes(p.child, arena, e, renames);
                return n;
            },
            else => return value,
        },
        else => return value,
    }
}

/// A copy of `value` in which every plain call (`name(…)` — no receiver, no
/// callee expression, not a builtin) whose name `renames` holds calls the
/// mangled name instead. Reflective over the AST, like `alias_erase`; the
/// strings and the nodes no rename reaches are shared, never mutated.
fn renameLinkedCalls(comptime T: type, arena: std.mem.Allocator, value: T, renames: *const std.StringHashMapUnmanaged([]const u8)) error{OutOfMemory}!T {
    switch (@typeInfo(T)) {
        .@"struct" => |st| {
            var out: T = value;
            inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                @field(out, f.name) = try renameLinkedCalls(f.type, arena, @field(value, f.name), renames);
            }
            if (comptime @hasField(T, "callee") and @hasField(T, "receiver") and @hasField(T, "calleeExpr") and @hasField(T, "is_builtin")) {
                if (out.receiver == null and out.calleeExpr == null and !out.is_builtin) {
                    if (renames.get(out.callee)) |m| out.callee = m;
                } else if (out.calleeExpr == null and !out.is_builtin) {
                    // `url.parse(…)` through a namespace item (`linkRenames`).
                    const r = out.receiver.?;
                    if (r.* == .identifier and r.identifier.kind == .ident) {
                        const key = try std.fmt.allocPrint(arena, "{s}.{s}", .{ r.identifier.kind.ident, out.callee });
                        if (renames.get(key)) |m| {
                            out.callee = m;
                            out.receiver = null;
                        }
                    }
                }
            }
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return value;
            switch (value) {
                inline else => |payload, tag| return @unionInit(T, @tagName(tag), try renameLinkedCalls(@TypeOf(payload), arena, payload, renames)),
            }
        },
        .optional => |o| return if (value) |v| try renameLinkedCalls(o.child, arena, v, renames) else null,
        .pointer => |p| switch (p.size) {
            .one => {
                if (comptime !isAstNodeType(p.child)) return value;
                const n = try arena.create(p.child);
                n.* = try renameLinkedCalls(p.child, arena, value.*, renames);
                return n;
            },
            .slice => {
                if (comptime !isAstNodeType(p.child)) return value;
                const n = try arena.alloc(p.child, value.len);
                for (value, 0..) |e, i| n[i] = try renameLinkedCalls(p.child, arena, e, renames);
                return n;
            },
            else => return value,
        },
        else => return value,
    }
}

/// A generic `fn` and the per-module maps its body is lowered under.
const GenericFn = struct {
    decl: ast.FnDecl,
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    renames: ?*const std.StringHashMapUnmanaged([]const u8),
    /// Set for a declaration of a LINKED module: its locations are that
    /// module's file, not the consumer's (`Emitter.foreign_origin`).
    linked: bool = false,
    /// A queued copy's: the consumer location a refusal inside it is
    /// reported at (`Emitter.foreign_origin`).
    origin: ?ast.Loc = null,
};

/// A method of a generic `type`, its owner and the owner's type parameters,
/// and the per-module maps its body is lowered under.
/// A program-declared `default fn` of a primitive behavior: the behavior that
/// declares it and the method.
const PrimDefault = struct { behavior: []const u8, method: ast.BehaviorMethod, tparams: []const ast.GenericParam = &.{} };

/// A name a block re-bound, and the alias it had before (`Emitter.shadow_log`).
/// What a statement list did to a name, undone at its end: bound it first
/// (`prev` unused — the name leaves `bound_names`), or aliased it over an
/// enclosing binding (`prev` the alias it had before).
const Shadow = struct { name: []const u8, prev: ?[]const u8, aliased: bool };

const GenericMethod = struct {
    owner: []const u8,
    tparams: []const ast.GenericParam,
    method: ast.BehaviorMethod,
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    renames: ?*const std.StringHashMapUnmanaged([]const u8),
    /// The owner's type parameters this copy substituted (`A` → `string`),
    /// so a field the owner declares `left: A` reads as `string` in it.
    subs: []const TypeSub = &.{},
    /// As `GenericFn.linked` / `.origin`.
    linked: bool = false,
    origin: ?ast.Loc = null,
};

/// A type parameter's name and the type a specialisation writes for it.
const TypeSub = struct { name: []const u8, to: ast.TypeRef };

/// A copy of `value` in which every written type naming one of `subs`'s
/// type parameters names its type instead — `x: T`, `-> ?T`, `Array<T>`, a
/// `val` annotation in the body. The nodes no substitution reaches and every
/// string are shared, never mutated (the walk `renameLinkedCalls` takes).
fn substTypeParams(comptime T: type, arena: std.mem.Allocator, value: T, subs: []const TypeSub) error{OutOfMemory}!T {
    if (T == ast.TypeRef) switch (value) {
        .named => |n| {
            for (subs) |sub| if (std.mem.eql(u8, sub.name, n)) return sub.to;
            return value;
        },
        // `Self<T>` in a primitive `Array<T>` default's copy: the whole
        // written array type (`lowerPrimDefault`), its arguments included.
        .generic => |g| for (subs) |sub| {
            if (std.mem.eql(u8, sub.name, g.name) and sub.to == .array) return sub.to;
        },
        else => {},
    };
    switch (@typeInfo(T)) {
        .@"struct" => |st| {
            var out: T = value;
            inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                @field(out, f.name) = try substTypeParams(f.type, arena, @field(value, f.name), subs);
            }
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return value;
            switch (value) {
                inline else => |payload, tag| return @unionInit(T, @tagName(tag), try substTypeParams(@TypeOf(payload), arena, payload, subs)),
            }
        },
        .optional => |o| return if (value) |v| try substTypeParams(o.child, arena, v, subs) else null,
        .pointer => |p| switch (p.size) {
            .one => {
                if (comptime !isAstNodeType(p.child)) return value;
                const n = try arena.create(p.child);
                n.* = try substTypeParams(p.child, arena, value.*, subs);
                return n;
            },
            .slice => {
                if (comptime !isAstNodeType(p.child)) return value;
                const n = try arena.alloc(p.child, value.len);
                for (value, 0..) |e, i| n[i] = try substTypeParams(p.child, arena, e, subs);
                return n;
            },
            else => return value,
        },
        else => return value,
    }
}

/// Whether `value` holds a method call whose receiver is one of `names`
/// (`x.toString()` with `x: T`).
fn callsMethodOn(comptime T: type, value: T, names: []const []const u8) bool {
    if (names.len == 0) return false;
    switch (@typeInfo(T)) {
        .@"struct" => |st| {
            if (comptime @hasField(T, "callee") and @hasField(T, "receiver") and @hasField(T, "is_builtin")) {
                if (value.receiver) |r| if (r.* == .identifier and r.identifier.kind == .ident) {
                    for (names) |n| if (std.mem.eql(u8, n, r.identifier.kind.ident)) return true;
                };
            }
            // `x is T` over a parameter tests what the parameter IS: the one
            // generic body cannot box its slot (`lowerAsUnknown`), a copy
            // with the type bound can.
            if (comptime @hasField(T, "isType") and @hasField(T, "args")) {
                if (value.isType != null and value.args.len == 1) {
                    const a = value.args[0].value.*;
                    if (a == .identifier and a.identifier.kind == .ident) {
                        for (names) |n| if (std.mem.eql(u8, n, a.identifier.kind.ident)) return true;
                    }
                }
            }
            inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                if (callsMethodOn(f.type, @field(value, f.name), names)) return true;
            }
            return false;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return false;
            switch (value) {
                inline else => |payload| return callsMethodOn(@TypeOf(payload), payload, names),
            }
        },
        .optional => |o| return if (value) |v| callsMethodOn(o.child, v, names) else false,
        .pointer => |p| switch (p.size) {
            .one => {
                if (comptime !isAstNodeType(p.child)) return false;
                return callsMethodOn(p.child, value.*, names);
            },
            .slice => {
                if (comptime !isAstNodeType(p.child)) return false;
                for (value) |e| if (callsMethodOn(p.child, e, names)) return true;
                return false;
            },
            else => return false,
        },
        else => return false,
    }
}

/// Whether `value` holds a `==` or `!=` (decision 210: a generic body that
/// compares values is specialised for a composite bound to its parameter).
fn comparesValues(comptime T: type, value: T) bool {
    switch (@typeInfo(T)) {
        .@"struct" => |st| {
            if (comptime @hasField(T, "op") and @hasField(T, "lhs") and @hasField(T, "rhs")) {
                if (comptime @typeInfo(@FieldType(T, "op")) == .@"enum" and @hasField(@FieldType(T, "op"), "eq")) {
                    if (value.op == .eq or value.op == .ne) return true;
                }
            }
            inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                if (comparesValues(f.type, @field(value, f.name))) return true;
            }
            return false;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return false;
            switch (value) {
                inline else => |payload| return comparesValues(@TypeOf(payload), payload),
            }
        },
        .optional => |o| return if (value) |v| comparesValues(o.child, v) else false,
        .pointer => |p| switch (p.size) {
            .one => {
                if (comptime !isAstNodeType(p.child)) return false;
                return comparesValues(p.child, value.*);
            },
            .slice => {
                if (comptime !isAstNodeType(p.child)) return false;
                for (value) |e| if (comparesValues(p.child, e)) return true;
                return false;
            },
            else => return false,
        },
        else => return false,
    }
}

/// Whether the rename walk descends into `T`: a struct, union or optional —
/// an AST node — and not a byte string or a pointer to anything else.
fn isAstNodeType(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct" => T != std.mem.Allocator,
        .@"union", .optional => true,
        .pointer => |p| p.size == .slice and isAstNodeType(p.child),
        else => false,
    };
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
    cross: ?*const CrossModule,
    /// The build's `#[@External.Wasm]` lookup (decision 334's host).
    external_lookup: []const u8,
    artifact: Artifact,
    /// 06 C13 — set when the emit fails with `error.MissingExternalTarget`.
    missing: ?*?moduleOutput.MissingExternal,
    /// Set when the emit fails with `error.WasmLoweringRefused`: the slot
    /// takes the message's ownership.
    refused: ?*?Emitter.Refusal,
) !Emitted {
    var em = Emitter.init(alloc, comptime_vals, rewrites);
    defer em.deinit();
    em.cross = cross;
    errdefer if (missing) |slot| {
        slot.* = em.missing_external;
    };
    errdefer if (refused) |slot| {
        slot.* = em.refusal;
        em.refusal = null;
    };
    em.module_name = module_name;
    em.external_lookup = external_lookup;
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
        if (own_names.contains(n)) {
            // The std prelude's primitive behaviors (`String`, `Array`, …) are
            // materialised into every module that uses one of their default
            // methods, so two linked modules each carry the SAME declaration.
            // It is one behavior, not two: the later copy is dropped instead
            // of mangled — mangled, every `Array<i32>` and `String.…` its
            // module wrote was renamed to `<module>/Array`, a type no shape
            // predicate knows (`flatten` over `Array<Array<i32>>` refused,
            // `String.fromCodepoint` unresolved in `std/querystring`).
            if (d == .behavior and samePreludeBehavior(d.behavior, own_program.decls, decls.items)) continue;
            // Two modules of the program declare `n`, and this backend links
            // them into ONE namespace. A FUNCTION is mangled per module: the
            // first declaration keeps `n`, this one is `<module>/<n>`, and
            // every call that means it — its own module's, an importer's
            // alias, a namespace call — is rewritten to that name
            // (`renameLinkedCalls`). Before, the first declaration won and a
            // call to the other answered it (`import {parse as parse2} from
            // "two"` printed `one`'s `parse` at exit 0), and then trapped.
            // A module-level `val` is mangled the same way; its reads are
            // resolved while its module is emitted (`global_renames`), where
            // a parameter or a local of the same name still shadows it.
            // A `type` (record or enum), a `behavior`, an `implement` and an
            // `extend` block are mangled the same way, and every reference
            // their module and its importers write — a constructor call, a
            // type annotation, a `case` arm's path, `Enum.Variant`, an `is`
            // test — is renamed with them (`renameLinkedTypes`). Before, such
            // a declaration was DROPPED: two packages each declaring `type
            // Response` linked the first one's layout into both, and
            // `ok().html` printed `0` at exit 0.
            const mangled = try std.fmt.allocPrint(ar0, "{s}/{s}", .{ l.name, n });
            const key = try linkKey(ar0, l.name, n);
            const renamed: ast.DeclKind = switch (d) {
                .@"fn" => |f| blk: {
                    try em.link_mangled.put(em.alloc, key, mangled);
                    var g = f;
                    g.isPub = false;
                    g.name = mangled;
                    break :blk .{ .@"fn" = g };
                },
                .val => |v| blk: {
                    try em.link_mangled_vals.put(em.alloc, key, mangled);
                    var w = v;
                    w.isPub = false;
                    w.name = mangled;
                    break :blk .{ .val = w };
                },
                .type_ => |t| blk: {
                    try em.link_mangled_types.put(em.alloc, key, mangled);
                    var u = t;
                    u.isPub = false;
                    u.name = mangled;
                    break :blk .{ .type_ = u };
                },
                .behavior => |b| blk: {
                    try em.link_mangled_types.put(em.alloc, key, mangled);
                    var c = b;
                    c.isPub = false;
                    c.name = mangled;
                    break :blk .{ .behavior = c };
                },
                .implement => |im| blk: {
                    try em.link_mangled_types.put(em.alloc, key, mangled);
                    var c = im;
                    c.isPub = false;
                    c.name = mangled;
                    break :blk .{ .implement = c };
                },
                .extend => |ex| blk: {
                    try em.link_mangled_types.put(em.alloc, key, mangled);
                    var c = ex;
                    c.isPub = false;
                    c.name = mangled;
                    break :blk .{ .extend = c };
                },
                // `declName` answers null for these, and they were skipped above.
                .use, .mod, .comment, .@"test", .typeAlias, .delegate => unreachable,
            };
            try decls.append(ar0, renamed);
            try owner.append(ar0, li);
            continue;
        }
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
    // Every module whose calls reach a mangled function gets those calls
    // rewritten to the mangled name, in a copy of its declarations (the
    // module's own program is shared with its own emission).
    if (em.link_mangled.count() > 0) {
        var maps = try ar0.alloc(std.StringHashMapUnmanaged([]const u8), linked.len + 1);
        for (maps, 0..) |*m, i| {
            m.* = .empty;
            const mod_name = if (i < linked.len) linked[i].name else module_name;
            const prog = if (i < linked.len) linked[i].program else own_program;
            try linkRenames(ar0, &em.link_mangled, cross, mod_name, prog, m);
        }
        for (decls.items, owner.items) |*d, from| {
            if (maps[from].count() == 0) continue;
            d.* = try renameLinkedCalls(ast.DeclKind, ar0, d.*, &maps[from]);
        }
    }
    // The named types the same way: every module that declares or imports a
    // mangled `type`, `behavior`, `implement` or `extend` has its references
    // renamed in a copy of its declarations.
    if (em.link_mangled_types.count() > 0) {
        var maps = try ar0.alloc(std.StringHashMapUnmanaged([]const u8), linked.len + 1);
        for (maps, 0..) |*m, i| {
            m.* = .empty;
            const mod_name = if (i < linked.len) linked[i].name else module_name;
            const prog = if (i < linked.len) linked[i].program else own_program;
            try linkTypeRenames(ar0, &em.link_mangled_types, cross, mod_name, prog, m);
        }
        for (decls.items, owner.items) |*d, from| {
            if (maps[from].count() == 0) continue;
            d.* = try renameLinkedTypes(ast.DeclKind, ar0, d.*, &maps[from]);
        }
    }
    // The module-level `val`s the same way, read by the emitter per module.
    var val_maps: []std.StringHashMapUnmanaged([]const u8) = &.{};
    if (em.link_mangled_vals.count() > 0) {
        val_maps = try ar0.alloc(std.StringHashMapUnmanaged([]const u8), linked.len + 1);
        for (val_maps, 0..) |*m, i| {
            m.* = .empty;
            const mod_name = if (i < linked.len) linked[i].name else module_name;
            const prog = if (i < linked.len) linked[i].program else own_program;
            try linkValRenames(ar0, &em.link_mangled_vals, cross, mod_name, prog, m);
        }
    }
    try em.checkHostBindings(decls.items, owner.items, linked, own_program, module_name);
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
    try em.typeFnValueGlobals(program);
    for (program.decls, owner.items) |decl, from| switch (decl) {
        .@"fn" => |f| if (f.genericParams.len > 0 and f.body.len > 0 and !f.isDeclare) {
            try em.generic_fns.put(em.alloc, f.name, .{
                .decl = f,
                .rewrites = if (from < linked.len) linked[from].rewrites else rewrites,
                .lowerings = if (from < linked.len) linked[from].instance_lowerings else own_instance_lowerings,
                .renames = if (val_maps.len > 0) &val_maps[from] else null,
                .linked = from < linked.len,
            });
        },
        // A method of a generic `type` (`Dict<K, V>.at`), by the symbol its
        // calls emit.
        .type_ => |t| if (t.genericParams.len > 0) for (try em.methodsWithDefaults(t)) |m| {
            if (m.body == null or m.is_declare or m.isExternal() or m.isHost()) continue;
            const sym = try std.fmt.allocPrint(ar0, "{s}_{s}", .{ t.name, m.name });
            try em.generic_methods.put(em.alloc, sym, .{
                .owner = t.name,
                .tparams = t.genericParams,
                .method = m,
                .rewrites = if (from < linked.len) linked[from].rewrites else rewrites,
                .lowerings = if (from < linked.len) linked[from].instance_lowerings else own_instance_lowerings,
                .renames = if (val_maps.len > 0) &val_maps[from] else null,
                .linked = from < linked.len,
            });
        },
        // A behavior's generic associated `default fn` (`Seq<A>.firstOr`),
        // by the symbol its calls emit.
        .behavior => |b| for (b.methods) |m| {
            const body = m.body orelse continue;
            if (!m.is_default or m.is_declare or m.isExternal() or m.isHost()) continue;
            if (m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self")) continue;
            if (b.genericParams.len + m.genericParams.len == 0) continue;
            const gps = try ar0.alloc(ast.GenericParam, b.genericParams.len + m.genericParams.len);
            @memcpy(gps[0..b.genericParams.len], b.genericParams);
            @memcpy(gps[b.genericParams.len..], m.genericParams);
            const sym = try std.fmt.allocPrint(ar0, "{s}_{s}", .{ b.name, m.name });
            try em.generic_fns.put(em.alloc, sym, .{
                .decl = .{ .isPub = false, .name = sym, .genericParams = gps, .params = m.params, .returnType = m.returnType, .body = body },
                .rewrites = if (from < linked.len) linked[from].rewrites else rewrites,
                .lowerings = if (from < linked.len) linked[from].instance_lowerings else own_instance_lowerings,
                .renames = if (val_maps.len > 0) &val_maps[from] else null,
                .linked = from < linked.len,
            });
        },
        else => {},
    };

    for (program.decls, owner.items) |decl, from| {
        em.rewrites = if (from < linked.len) linked[from].rewrites else rewrites;
        em.instance_lowerings = if (from < linked.len) linked[from].instance_lowerings else own_instance_lowerings;
        em.global_renames = if (val_maps.len > 0) &val_maps[from] else null;
        em.foreign_origin = if (from < linked.len) linked[from].via else null;
        try em.emitDecl(decl);
    }
    em.foreign_origin = null;
    em.global_renames = null;
    em.rewrites = rewrites;
    em.instance_lowerings = own_instance_lowerings;

    // After every fn is emitted (their signatures are what the initialisers
    // call) but before the module is assembled (it may intern more strings).
    try em.emitGlobalInit();

    // Functions emitted on demand: the lambdas lifted out of the bodies above
    // (each may lift more), and the interface associated `default fn`s some
    // call reached.
    try em.emitPendingFns();
    try em.refuseUnboundTemplateCalls();

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
    // Decision 238's `wasi:` adapters each bring the WASI call they make.
    if (em.b.helpers.has(.wasi_random_f64)) try items.append(ar, .{ .import = prelude.random_get_import });

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
    for (em.behavior_dispatch.values()) |bd| try items.append(ar, .{ .func = try em.behaviorDispatchFunc(bd) });
    // Decision 210 — each equality may ask for the equality of a part.
    var eq_i: usize = 0;
    while (eq_i < em.eq_requests.count()) : (eq_i += 1) {
        try items.append(ar, .{ .func = try em.eqFunc(em.eq_requests.keys()[eq_i], em.eq_requests.values()[eq_i]) });
    }
    if (em.float_eq_used) try items.append(ar, .{ .func = try em.floatEqFunc() });

    for (prelude.order) |group| {
        if (!em.b.helpers.has(group)) continue;
        // `$__print_tagged_raw` asks the module which of its types answers its
        // own text (decision 8 §7's `Display`); the answer is this module's.
        if (group == .display_of) if (try em.displayDispatch()) |f| {
            try items.append(ar, .{ .func = f });
            continue;
        };
        try items.appendSlice(ar, prelude.items(group));
    }

    // One model, two renderings: the text the snapshot records and the binary
    // an engine instantiates (`wasm_binary_emitter.zig`).
    const lowered: wat.Module = .{ .items = items.items };
    // The `browser` host's module: the start a host calls once the instance
    // exists (`wat_ast.startAsExport`, decision 334) — text and binary alike.
    const module: wat.Module = if (artifact == .browser) try wat.startAsExport(em.arena(), lowered) else lowered;
    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();
    switch (artifact) {
        .module, .browser => try watEmitter.renderModule(&aw.writer, module),
        .component => watEmitter.renderComponent(alloc, &aw.writer, module) catch |err| switch (err) {
            // Every preview 1 import the prelude emits is adapted
            // (`wat_emitter.preview1_adapted`); one that is not is a
            // backend defect, never a module left unsatisfied.
            error.UnadaptedPreview1Import => return em.refuse(null, "the module imports a WASI preview 1 function the `wasi` host's component does not adapt (it adapts {s} and {s})", .{ watEmitter.preview1_adapted[0], watEmitter.preview1_adapted[1] }),
            else => |e| return e,
        },
    }
    const binary = try wasmBinary.encodeModule(alloc, module);
    errdefer alloc.free(binary);
    return .{ .text = try aw.toOwnedSlice(), .binary = binary };
}

/// What `emitWat` renders a module to: the `.wat` text and the binary module.
const Emitted = struct { text: []u8, binary: []u8 };

/// The text `emitWat` writes: the module the backend lowers (the snapshot's,
/// the comptime runtime's), the WASI preview 2 component a `wasi` build runs,
/// or the module a `browser` build's loader instantiates — its start exported
/// for the loader to call — beside its binary (decision 334).
const Artifact = enum { module, component, browser };

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

/// An `@block` being lowered whose body returns (`Emitter.block_ret`): the
/// local its value lands in, of type `ty`, and the label of the wasm block a
/// `return` branches out of.
const BlockRet = struct { local: []const u8, label: []const u8, ty: []const u8 };

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

/// True when an `@block`'s body holds a `return` of its own scope — the
/// block's value, never the enclosing function's (`ast.exprReturns`).
fn blockBodyReturns(body: []const ast.Stmt) bool {
    for (body) |stmt| if (ast.exprReturns(stmt.expr)) return true;
    return false;
}

/// The first value an `@block`'s body returns in its own scope (the borders of
/// `ast.exprReturns`: a closure and a nested `@block` return for themselves, a
/// braced `case` arm does not) — what the block answers, for the classifiers
/// that read a value's shape off its expression (`genericResultOf`). A
/// `return` written directly in `body` comes first: its operands are read in
/// the block's own scope, while one inside a loop reads the loop's binder,
/// which no classifier knows outside the loop — `return s` from a `for` over
/// strings made the block's `"[" + hit + "]"` print an address
/// (`run/block_for_return_is_block_value`).
fn blockReturnValue(body: []const ast.Stmt) ?ast.Expr {
    for (body) |st| if (st.expr == .jump and st.expr.jump.kind == .@"return") if (st.expr.jump.kind.@"return") |v| return v.*;
    for (body) |st| if (blockReturnValueOf(st.expr)) |v| return v;
    return null;
}

/// `e`'s returned value when `e` is an `@block` whose body returns.
fn blockResultOf(e: ast.Expr) ?ast.Expr {
    if (e != .call or e.call.kind != .call) return null;
    const cc = e.call.kind.call;
    if (!cc.is_builtin or !std.mem.eql(u8, cc.callee, "block") or cc.trailing.len == 0) return null;
    return blockReturnValue(cc.trailing[0].body);
}

fn blockReturnValueOf(e: ast.Expr) ?ast.Expr {
    return switch (e) {
        .jump => |j| switch (j.kind) {
            .@"return" => |r| if (r) |v| v.* else null,
            else => null,
        },
        .branch => |b| switch (b.kind) {
            .if_ => |i| blockReturnValue(i.then_) orelse (if (i.else_) |els| blockReturnValue(els) else null),
            .tryCatch => null,
        },
        .loop => |lp| if (lp.generator == null) blockReturnValue(lp.body) else null,
        .collection => |col| switch (col.kind) {
            .case => |c| blk: {
                for (c.arms) |arm| {
                    const v = if (arm.body == .function and arm.body.function.kind.syntax == .lambda)
                        blockReturnValue(arm.body.function.kind.body)
                    else
                        blockReturnValueOf(arm.body);
                    if (v) |x| break :blk x;
                }
                break :blk null;
            },
            else => null,
        },
        else => null,
    };
}

/// Signature of an emitted function, keyed by its WAT symbol (already mangled
/// for extension/record methods). `result` is null for a void function. Call
/// sites consult this to know whether a `call` pushes a value, and to coerce
/// arguments to the declared parameter types.
const FnSig = struct { params: []const []const u8, result: ?[]const u8 };

/// A dispatcher `$__bdispatch_<method>_<n>` a behavior-typed call asked for
/// (`Emitter.lowerBehaviorDispatch`), written once the module is lowered.
const BehaviorDispatch = struct { method: []const u8, argc: usize, sig: FnSig };

const Emitter = struct {
    alloc: std.mem.Allocator,
    /// The behavior dispatchers the module's calls named, by symbol.
    behavior_dispatch: std.StringArrayHashMapUnmanaged(BehaviorDispatch) = .empty,
    /// Decision 210 — the per-type equalities `$__eq_<T>` the module's `==`
    /// asked for, by symbol, written once the module is lowered.
    eq_requests: std.StringArrayHashMapUnmanaged(ast.TypeRef) = .empty,
    /// Decision 210 — a `val`'s composite type when nothing else recovers it
    /// (`eqTypeOf` over its initialiser), by the local's symbol.
    eq_local_types: std.StringHashMapUnmanaged(ast.TypeRef) = .empty,
    /// Decision 214 — whether `$__f64_eq` was called.
    float_eq_used: bool = false,
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
    /// The type parameters in scope while a body is emitted: the owner type's
    /// (`Dict<K, V>`) and the function's or method's own (`first<T>`). A `?V`
    /// over one of them is boxed (`optInfoOfTypeRef`).
    owner_tparams: []const ast.GenericParam = &.{},
    fn_tparams: []const ast.GenericParam = &.{},
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
    /// Names a `!= null` test has narrowed for the branch being emitted, with
    /// the optional they were before it. Inside the branch the name is its
    /// PAYLOAD and not an optional at all: `optInfoOf` answers nothing for it,
    /// and a boxed payload is loaded at every read. Without this a narrowed
    /// `?i32` was read as its box — `n + 1` answered a heap address at exit 0 —
    /// while the optional-binding form `if (ns.at(0)) { n -> … }` unboxed and
    /// answered the sum.
    narrowed_opts: std.StringHashMap(OptInfo),
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
    /// The declared function type a lambda about to be lifted is written
    /// against — the enclosing fn's `-> fn(x: string) -> string` at a
    /// `return { x -> … }`, or a `val f: fn(…) -> … = { … }` annotation. Read
    /// (and cleared) by `lowerLambdaValue`, which types the parameters from it.
    expected_fn: ?ast.TypeRef = null,
    /// Top-level `val` → the text the comptime pass folded its initialiser to.
    folded_globals: std.StringHashMap([]const u8),
    /// Top-level `val` → record type name, when recovered (`val cfg = record
    /// { … }`), so `cfg.port` reads the right slot.
    global_rec_types: std.StringHashMap([]const u8),
    bool_fns: std.StringHashMap(void),
    /// Module globals: wat value type, plus the string/bool shapes.
    global_types: std.StringHashMap([]const u8),
    str_globals: std.StringHashMap(void),
    /// Names known to hold an `[len][e0][e1]…` array blob. `for (xs) {…}`
    /// only walks the layout for these; anything else is refused
    /// (`lowerLoop`) rather than reading garbage or running the body zero
    /// times.
    arr_locals: std.StringHashMap(void),
    /// Local name → the `$__print_shaped_raw` shape of its value, when it is
    /// an array or a tuple (`printShapeOf`).
    print_shape_locals: std.StringHashMap([]const u8),
    arr_globals: std.StringHashMap(void),
    bool_globals: std.StringHashMap(void),
    /// Every emitted WAT function symbol → its signature.
    fn_sigs: std.StringHashMap(FnSig),
    /// Decision 107 — an imported fn bound under an alias (`import {a.twice as
    /// double}`): the local name → the declared name. The module is linked
    /// statically, so the function exists under its declared name only; the
    /// alias is registered beside it in every name-keyed table and mapped
    /// back at the `call`.
    import_aliases: std.StringHashMap([]const u8),
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
    /// Decision 334 — the `#[@External.<Member>]` lookup of this build:
    /// `wasm` (the `wasi` host, the default) or `wasm.browser`. A
    /// `declare fn` lowers to the binding serving the host; one with none
    /// for it is `external_missing`.
    external_lookup: []const u8 = "wasm",
    /// The array local a comprehension's `yield`/`break <v>` appends to.
    yield_target: ?[]const u8 = null,
    /// The block label of the annotated `loop` being lowered (decision 105):
    /// a `break <v>` inside it pushes `v` and branches here, out of every
    /// loop between. Null outside one.
    gen_end: ?[]const u8 = null,
    /// The innermost `@block { … }` with a `return` of its own being lowered
    /// in this function (`lowerBlockWithReturn`): its `return` stores into
    /// `local` and branches to `label`, never leaving the function.
    block_ret: ?BlockRet = null,
    /// How many loops enclose the code being lowered: `break`/`continue`
    /// branch only inside one.
    loop_depth: u32 = 0,
    /// The function being emitted, when its body returns a call to itself in
    /// tail position (00 · 05-wasm step 9): `return f(args)` re-binds the
    /// parameters and branches to `$__tail`, the loop the body is wrapped in,
    /// instead of pushing a frame. Null inside a lifted lambda, a method and
    /// an accumulating (generator) body.
    tail_self: ?TailSelf = null,
    /// Set by `lowerSelfTailCall` — only then does `emitFn` wrap the body.
    tail_self_used: bool = false,
    /// Sequence counter for the `$__mem{n}` scratch pointers used when building
    /// or destructuring aggregates (tuples, arrays, records, enum payloads).
    mem_seq: u32 = 0,

    // ── type registry (codegen is untyped, so we recover record/enum layout
    //    from the declarations to lower construction/access by memory offset) ──
    /// record/struct name → ordered field names (slots are 4 bytes each).
    records: std.StringHashMap([]const []const u8),
    /// The type parameters a record declares (`type Pair<A>(…)`), for the
    /// type arguments a constructor call binds (`ctorTypeRef`). In `reg_arena`.
    record_generics: std.StringHashMapUnmanaged([]const ast.GenericParam) = .empty,
    /// record/struct name → ordered field type-names (parallel to `records`).
    /// Used to chain-infer the type of `recv.a.b` (`a`'s declared type drives
    /// the lookup for `.b`). Empty/unknown types stay as `""`.
    record_field_types: std.StringHashMap([]const []const u8),
    /// enum name → variants (tag = declaration index; payload fields follow).
    enums: std.StringHashMap([]const ast.EnumVariant),
    /// Declaration name → the name a printed value spells, for a type whose
    /// two differ (an associated type, `City__Columns` → `City.Columns`,
    /// decision 216). Every other type prints as `displayTypeName(name)`.
    printed_names: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// Declaration name → the address of the descriptor a value of it carries
    /// in its header (13-module-identity half 3). Keyed by the record's name
    /// and by `"<Enum>.<Variant>"`, because a variant IS a declaration for the
    /// purpose of identity: `Shape.Dot` and `Shape.Circle` are two of them.
    type_descs: std.StringHashMap(u32),
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
    /// A `case` subject local → the enum its subject is a value of
    /// (`enumOfSubject`), which a bare or dot-shorthand arm name is read in.
    subject_enums: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// The enum the pattern being tested or bound is read in: set from
    /// `subject_enums` for the WHOLE subject only, so a payload's own
    /// pattern keeps the program-wide lookup.
    case_enum_hint: ?[]const u8 = null,
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
    /// The entries of `deferred_globals` that are `_`-named top-level
    /// statements: run for their effect in `$__init_globals`, stored nowhere.
    deferred_stmts: std.StringHashMapUnmanaged(void) = .empty,
    /// `<module>\x00<name>` → `<module>/<name>`: a linked module-level `val`
    /// whose name an earlier declaration of the program already took
    /// (`emitWat`).
    link_mangled_vals: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// `linkKey(module, name)` → `<module>/<name>` for every linked `type`,
    /// `behavior`, `implement` and `extend` block whose name an earlier
    /// declaration of the program already took (`emitWat`); the references
    /// are renamed by `renameLinkedTypes` before anything is registered.
    link_mangled_types: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// While a declaration is emitted, its module's reads of a mangled `val`:
    /// local name → mangled global (`resolveName`).
    global_renames: ?*const std.StringHashMapUnmanaged([]const u8) = null,
    /// The `global_renames` each `deferred_globals` entry was declared under,
    /// so `$__init_globals` reads its initialiser in its own module.
    deferred_renames: std.ArrayListUnmanaged(?*const std.StringHashMapUnmanaged([]const u8)) = .empty,
    /// `<module>\x00<name>` → `<module>/<name>`: a linked FUNCTION whose name
    /// an earlier declaration of the program already took (`emitWat`).
    link_mangled: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// `<anon record>.<field>` for each behavior-literal field whose lambda
    /// takes `self` first (`ensureAnonRecord`).
    self_method_fields: std.StringHashMapUnmanaged(void) = .empty,
    /// A generic function whose return type is one of its own type
    /// parameters, bare (`fn ident<T>(x: T) -> T`) → the index of the first
    /// argument declared with that parameter. There is one body for every
    /// instance, so what such a call answers has the shape of that argument
    /// (`genericResultArg`): the shape predicates read the argument, where
    /// the declared `T` said nothing and a string printed as its address.
    generic_result_arg: std.StringHashMapUnmanaged(usize) = .empty,
    /// A generic `fn` with a body → its declaration and the per-module maps
    /// it is lowered under (`specializedCallee`).
    generic_fns: std.StringHashMapUnmanaged(GenericFn) = .empty,
    /// Specialisations created by a call, emitted after the declarations
    /// (`emitPendingFns`), and the names already created.
    spec_pending: std.ArrayListUnmanaged(GenericFn) = .empty,
    spec_names: std.StringHashMapUnmanaged(void) = .empty,
    /// A method of a generic `type` → the method, its owner and the owner's
    /// type parameters (`specializeMethod`); the specialised copies to emit.
    generic_methods: std.StringHashMapUnmanaged(GenericMethod) = .empty,
    mspec_pending: std.ArrayListUnmanaged(GenericMethod) = .empty,
    /// While a method specialisation is emitted: its owner and the owner's
    /// type parameters it substituted. `fieldTypeIn` / `fieldTypeRefIn`
    /// answer a field of the owner declared as one of them by its
    /// substitution — `self.left == self.right` over `Pair<string>`
    /// compared WORDS while the fields read as `A` (`run/generic_string_equality`).
    field_subs_owner: []const u8 = "",
    /// The names a `val` / `var` of the function being emitted has bound so
    /// far (`bindTarget`), and the aliases a re-binding of one installed,
    /// undone at the end of the statement list it stands in (`scopeRestore`).
    /// Both in `reg_arena`, cleared per function.
    bound_names: std.StringHashMapUnmanaged(void) = .empty,
    shadow_log: std.ArrayListUnmanaged(Shadow) = .empty,
    shadow_seq: u32 = 0,
    /// The names a tuple pattern bound (`bindTuplePattern`), whose element
    /// type `primKindAt` reads when inference recorded no lowering. In `reg_arena`.
    tuple_binders: std.StringHashMapUnmanaged(void) = .empty,
    field_subs: []const TypeSub = &.{},
    /// Set while a specialisation's body is emitted: a method on a value
    /// whose declared type the substitution made a primitive takes that
    /// primitive's lowering (`primKindAt`) — inference saw a type variable
    /// there and recorded none.
    in_spec: bool = false,
    /// The generic body being emitted — a `fn` with type parameters, a
    /// method of a generic `type`, or a lambda lifted out of either — by its
    /// symbol; null in a concrete body (a specialised copy is concrete). Such
    /// a body is the one a call reaches when no specialisation bound its type
    /// parameters (`specializeFor` / `specializeMethod`).
    cur_template: ?[]const u8 = null,
    /// Non-null while emitting code another module wrote — a linked
    /// declaration (its consumer's import item, `Linked.via`) or a copy a
    /// call specialised from one (that call, in the consumer): its locations
    /// are that module's file, so a refusal there is reported here, in the
    /// consumer (`refuse`).
    foreign_origin: ?ast.Loc = null,
    /// The generic bodies that hold a construct only a bound type parameter
    /// can lower (`lowerAsUnknown` over a type parameter's slot): each such
    /// site is an `unreachable` in the generic body, and every call that
    /// reaches the body unspecialised from a concrete one is refused at the
    /// call (`refuseUnboundTemplateCalls`).
    template_traps: std.StringHashMapUnmanaged(void) = .empty,
    /// Every call of a generic body no specialisation reached: from which
    /// body (`cur_template`, null for a concrete one), to which, and where.
    template_calls: std.ArrayListUnmanaged(TemplateCall) = .empty,
    /// `<anon record>.<field>` → the lambda a record literal's field holds, so
    /// a call through the field can be judged by the lambda's body
    /// (`fieldLambdaCallIsString`).
    field_lambdas: std.StringHashMapUnmanaged(FieldLambda) = .empty,
    /// The `case` subject locals holding an `unknown` / union value, whose
    /// arms may name a primitive type (`i32 { n -> … }`, §5.2).
    unknown_subjects: std.StringHashMapUnmanaged(void) = .empty,
    /// Set for the one arm body a primitive-type arm opens: its binder is the
    /// payload the test proved, unboxed (`lowerArmBody` reads and clears it).
    arm_unbox: ?PrimTest = null,
    /// Set while a tested arm naming a RECORD (`DogB { d -> … }`, decision 8
    /// §3.3) lowers its body: the binder is that record, whatever the union
    /// subject is (`emitArmChain` sets it, `lowerArmBody` reads and clears it).
    arm_record: ?[]const u8 = null,
    /// `<Behavior>.<method>` → its declaration: what a behavior literal's
    /// field lambda is written against.
    behavior_methods: std.StringHashMapUnmanaged(ast.BehaviorMethod) = .empty,
    /// A program's own `default fn` with a `self` on a primitive behavior
    /// (`behavior String { default fn tailShout(self: Self) … }`), keyed
    /// `<kind>.<method>` for every primitive kind the behavior covers
    /// (`primBehaviorKinds`). In `reg_arena`.
    prim_defaults: std.StringHashMapUnmanaged(PrimDefault) = .empty,
    /// Every behavior the program declares, by name (`registerTypes`): where a
    /// type that implements one finds the `default fn`s it adopts.
    behavior_decls: std.StringHashMapUnmanaged(ast.BehaviorDecl) = .empty,
    /// The parameters a lambda about to be lifted is written against when
    /// they come from a declaration rather than a function type — a behavior
    /// literal's method (`expected_fn`'s twin).
    expected_params: ?[]const ast.Param = null,

    /// Static extension dispatch (F6): call-site loc → activated extension symbol.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Value-receiver method calls (and `.length` reads), keyed by call /
    /// access loc: the receiver's primitive family or record type, recorded by
    /// inference. The one piece of type information this untyped backend is
    /// handed; `lowerPrimMethod` and `lowerRecordMethod` lower from it.
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering) = undefined,
    /// The program's link index — read for its `host_methods`, so a call to a
    /// host-backed method is refused (`hostMethods.missingAt`).
    cross: ?*const CrossModule = null,
    /// Element shape of names bound to an array blob (locals; cleared per fn)
    /// and of top-level `val`s. Drives `join`/`indexOf`/`contains` and the
    /// type of a HOF's element parameter.
    arr_elem_locals: std.StringHashMap(ElemKind),
    arr_elem_globals: std.StringHashMap(ElemKind),
    /// The record type the elements of an array-valued name hold, when they
    /// hold one. `ElemKind` cannot carry it — a record shares the `i32` slot
    /// with an integer — and the `?T` a `.at()` answers needs the NAME, both
    /// to find a field's offset and to know the value is its own pointer.
    arr_elem_recs: std.StringHashMap([]const u8),
    arr_elem_rec_globals: std.StringHashMap([]const u8),
    /// Element shape of the arrays top-level fns are declared to return.
    fn_arr_elem: std.StringHashMap(ElemKind),
    /// Lambdas lifted into functions, in table order — see `lowerLambdaValue`.
    lambdas: std.ArrayListUnmanaged(Lifted) = .empty,
    /// Local name → the lifted lambda a `val f = { … }` bound it to (cleared
    /// per fn). A call through the name threads the captures the lambda
    /// assigns (`lowerValueCall`) and recovers its parameters' shapes.
    closure_locals: std.StringHashMap(u32),
    /// `<local>.<field>` → the lifted lambda a record constructor bound to
    /// that local stored in that field (`Box(value: { s -> … })`), so a call
    /// through the field or through a local read from it types the lambda's
    /// parameters by its arguments as a closure local's call does. Filled from
    /// `ctor_lambdas`, which `lowerRecordCtor` leaves for the binding. In
    /// `reg_arena`, cleared per function.
    field_closures: std.StringHashMapUnmanaged(u32) = .empty,
    ctor_lambdas: std.ArrayListUnmanaged(struct { field: []const u8, idx: u32 }) = .empty,
    /// The type a generic record's constructor is written against where it
    /// stands — a parameter's (`run(b: Box<fn(s: string) -> string>)`), a
    /// `val`'s annotation, the function's return —, consumed by
    /// `lowerRecordCtor`: a lambda in a field written `T` takes its type
    /// from the type argument at `T`.
    expected_ctor: ?ast.TypeRef = null,
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
    /// has no host to bind them to; a call is refused (see `lowerPlainCall`).
    host_fns: std.StringHashMap(void),
    /// The subset of `host_fns` that carries `#[@External.<Target>(…)]` for
    /// some target and **none** for wasm: there is no host symbol to call and
    /// none was ever promised. Decision 67 — calling one is refused where it is
    /// written, not lowered to a trap (see `lowerPlainCall`).
    external_missing: std.StringHashMap(void),
    /// Decision 238 — the `declare fn`s whose `#[@External.Wasm("…")]` reads
    /// as one of the three forms (`checkHostBindings`), by the name the
    /// module emits them under. Each is registered and emitted like a bodied
    /// `fn` (`registerFn`, `emitHostBinding`).
    host_bindings: std.StringHashMapUnmanaged(HostBound) = .empty,
    /// 06 C13 — set when the emit fails with `error.MissingExternalTarget`, so
    /// the driver gets a located diagnostic naming the fn and this backend
    /// instead of the bare error name.
    missing_external: ?moduleOutput.MissingExternal = null,
    /// Set when the emit fails with `error.WasmLoweringRefused` (`refuse`):
    /// a construct this backend cannot lower, reported to the driver as a
    /// located diagnostic. Before, such a site wrote `i32.const 0` and a
    /// `;; note` and went on, so the program ran and printed a wrong value at
    /// exit 0 — the one outcome decision 67 rules out. Every site that used
    /// to do that refuses now; a `;; note` documents only a correct lowering.
    refusal: ?Refusal = null,
    /// The location of the call expression being lowered (`lowerExpr`'s
    /// `.call` arm sets it, restoring the caller's on the way out), so a
    /// method lowering that receives only the call's parts — `lowerIndex`,
    /// `lowerPrimMethod`, `lowerArrayMethod`, `lowerIsCall` — refuses at the
    /// call it cannot lower.
    call_loc: ?ast.Loc = null,
    /// The statement being lowered — where a conversion with no expression
    /// of its own (a body's tail into the declared result, a function value's
    /// answer into the indirect-call word) is refused.
    stmt_loc: ?ast.Loc = null,
    assoc_needed: std.ArrayListUnmanaged([]const u8) = .empty,
    assoc_emitted: std.StringHashMap(void),
    /// Extension block name → target type + methods (for resolving the mangled
    /// `$<target>_<method>` callee at activated and qualified dispatch sites).
    ext_by_name: std.StringHashMap(ExtInfo),
    /// Scratch space for the mangled callee symbol of a dispatch site. Only
    /// ever used for an immediate `fn_sigs` lookup.
    sym_buf: [256]u8 = undefined,

    const ExtInfo = struct { target: []const u8, methods: []const ast.ImplementMethod };

    const TemplateCall = struct { from: ?[]const u8, to: []const u8, loc: ?ast.Loc, foreign: bool };

    /// Where a refusal inside a copy queued now is reported: the current
    /// foreign origin, or — for a copy of a linked module's generic asked for
    /// by the consumer's own code — the call asking for it.
    fn specOrigin(self: *Emitter, linked: bool) ?ast.Loc {
        if (self.foreign_origin) |o| return o;
        return if (linked) self.call_loc else null;
    }

    /// Record a call to the generic body `to` that no specialisation reached.
    fn noteTemplateCall(self: *Emitter, to: []const u8, loc: ?ast.Loc) !void {
        const ra = self.reg_arena.allocator();
        try self.template_calls.append(ra, .{ .from = self.cur_template, .to = try ra.dupe(u8, to), .loc = self.foreign_origin orelse loc, .foreign = self.foreign_origin != null });
    }

    /// After every body is emitted: a generic body that traps over an
    /// unbound type parameter (`template_traps`) — or calls, unspecialised,
    /// one that does — is reached at run time only by a call from a
    /// concrete body that bound nothing. That call is refused where it is
    /// written; a generic body nothing concrete reaches that way keeps its
    /// `unreachable`, which no execution meets.
    fn refuseUnboundTemplateCalls(self: *Emitter) !void {
        const ra = self.reg_arena.allocator();
        var grew = true;
        while (grew) {
            grew = false;
            for (self.template_calls.items) |tc| {
                const from = tc.from orelse continue;
                if (self.template_traps.contains(from) or !self.template_traps.contains(tc.to)) continue;
                try self.template_traps.put(ra, from, {});
                grew = true;
            }
        }
        for (self.template_calls.items) |tc| {
            if (tc.from != null or !self.template_traps.contains(tc.to)) continue;
            self.foreign_origin = if (tc.foreign) tc.loc else null;
            const gm = self.generic_methods.get(tc.to);
            return self.refuse(tc.loc, "the wasm backend cannot call the generic `{s}{s}{s}` here: nothing at this call binds the type parameters its body needs bound (a type parameter's slot is not monomorphised)", .{
                if (gm) |m| m.owner else tc.to,
                if (gm != null) "." else "",
                if (gm) |m| m.method.name else "",
            });
        }
    }

    /// A lowering this backend refused: the located message the driver reports
    /// in place of the module. `message` is owned by the emitter's `alloc` and
    /// handed to the diagnostic (`codegenEmit`).
    pub const Refusal = struct { message: []u8, loc: ?ast.Loc };

    /// Stop the emit at a construct this backend cannot lower: records the
    /// located message and answers the error every lowering path propagates.
    /// Written `return self.refuse(loc, "…", .{…})`.
    fn refuse(self: *Emitter, loc: ?ast.Loc, comptime f: []const u8, args: anytype) anyerror {
        const message = if (self.foreign_origin != null)
            std.fmt.allocPrint(self.alloc, f ++ " — in another module's code this line reaches", args) catch |err| return err
        else
            std.fmt.allocPrint(self.alloc, f, args) catch |err| return err;
        if (self.refusal) |old| self.alloc.free(old.message);
        self.refusal = .{ .message = message, .loc = self.foreign_origin orelse loc };
        return error.WasmLoweringRefused;
    }

    /// `refuse` for a construct a bound type parameter could make lowerable
    /// — a method on a value of `T`, `T`'s slot boxed or tested, a `T`
    /// iterated. In a concrete body it is a refusal. In a generic body
    /// (`cur_template`) the body is the one a call reaches only when no
    /// specialisation bound its type parameters: the site is an
    /// `unreachable` naming the shape, the body is marked
    /// (`template_traps`), and every concrete call that reaches it
    /// unspecialised is refused where it is written
    /// (`refuseUnboundTemplateCalls`) — so no execution meets the trap.
    fn refuseUnlessTemplate(self: *Emitter, loc: ?ast.Loc, comptime f: []const u8, args: anytype) anyerror!void {
        if (self.cur_template) |t| {
            try self.template_traps.put(self.reg_arena.allocator(), t, {});
            try self.emitCf(.@"unreachable", f, args);
            return;
        }
        return self.refuse(loc, f, args);
    }

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
            .narrowed_opts = std.StringHashMap(OptInfo).init(alloc),
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
            .import_aliases = std.StringHashMap([]const u8).init(alloc),
            .globals = std.StringHashMap(void).init(alloc),
            .records = std.StringHashMap([]const []const u8).init(alloc),
            .record_field_types = std.StringHashMap([]const []const u8).init(alloc),
            .enums = std.StringHashMap([]const ast.EnumVariant).init(alloc),
            .type_descs = std.StringHashMap(u32).init(alloc),
            .reg_arena = std.heap.ArenaAllocator.init(alloc),
            .local_types = std.StringHashMap([]const u8).init(alloc),
            .fn_return_types = std.StringHashMap([]const u8).init(alloc),
            .rewrites = rewrites,
            .ext_by_name = std.StringHashMap(ExtInfo).init(alloc),
            .arr_elem_locals = std.StringHashMap(ElemKind).init(alloc),
            .arr_elem_globals = std.StringHashMap(ElemKind).init(alloc),
            .arr_elem_recs = std.StringHashMap([]const u8).init(alloc),
            .arr_elem_rec_globals = std.StringHashMap([]const u8).init(alloc),
            .fn_arr_elem = std.StringHashMap(ElemKind).init(alloc),
            .fn_refs = std.StringHashMap(u32).init(alloc),
            .iface_assoc = std.StringHashMap(ast.BehaviorMethod).init(alloc),
            .host_fns = std.StringHashMap(void).init(alloc),
            .external_missing = std.StringHashMap(void).init(alloc),
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
        self.narrowed_opts.deinit();
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
        self.import_aliases.deinit();
        self.globals.deinit();
        self.records.deinit();
        self.record_field_types.deinit();
        self.enums.deinit();
        self.type_descs.deinit();
        self.local_types.deinit();
        self.fn_return_types.deinit();
        self.reg_arena.deinit();
        self.data_segments.deinit(self.alloc);
        self.deferred_globals.deinit(self.alloc);
        self.deferred_stmts.deinit(self.alloc);
        self.link_mangled_vals.deinit(self.alloc);
        self.link_mangled_types.deinit(self.alloc);
        self.deferred_renames.deinit(self.alloc);
        self.link_mangled.deinit(self.alloc);
        self.self_method_fields.deinit(self.alloc);
        self.generic_result_arg.deinit(self.alloc);
        self.generic_fns.deinit(self.alloc);
        self.spec_pending.deinit(self.alloc);
        self.spec_names.deinit(self.alloc);
        self.generic_methods.deinit(self.alloc);
        self.mspec_pending.deinit(self.alloc);
        self.field_lambdas.deinit(self.alloc);
        self.unknown_subjects.deinit(self.alloc);
        self.subject_enums.deinit(self.alloc);
        self.behavior_methods.deinit(self.alloc);
        self.behavior_decls.deinit(self.alloc);
        self.ext_by_name.deinit();
        self.arr_elem_locals.deinit();
        self.arr_elem_globals.deinit();
        self.arr_elem_recs.deinit();
        self.arr_elem_rec_globals.deinit();
        self.fn_arr_elem.deinit();
        self.lambdas.deinit(self.alloc);
        self.fn_refs.deinit();
        self.iface_assoc.deinit();
        self.host_fns.deinit();
        self.external_missing.deinit();
        self.host_bindings.deinit(self.alloc);
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
            // Every bodied function is emitted, called or not — so a body
            // that calls a host function with no wasm binding is refused at
            // that call (`lowerPlainCall`), in the root package and in a
            // linked dependency alike. Decision 146: the rule commonJS,
            // erlang and beam hold by emitting every function.
            .@"fn" => |f| if (!f.isHost()) try self.emitFn(f),
            .val => |v| {
                if (!isSyntheticEntrypointVal(v)) {
                    try self.emitGlobalVal(v);
                } else if (!isSyntheticMainCall(v)) {
                    // A `_`-named top-level statement runs at module load, in
                    // source order with the named `val`s around it — what
                    // commonJS, erlang and beam do. It used to be dropped.
                    try self.deferred_stmts.put(self.alloc, v.name, {});
                    try self.deferred_globals.append(self.alloc, v);
                    try self.deferred_renames.append(self.alloc, self.global_renames);
                }
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
            .type_ => |r| {
                self.owner_tparams = r.genericParams;
                defer self.owner_tparams = &.{};
                try self.emitInterfaceMethods(r.name, try self.methodsWithDefaults(r));
            },
            // An import is linked statically: `emitWat` has already put the
            // owner's declarations in front of this module's.
            // A type alias is erased: the checker substituted its target.
            .use, .behavior, .delegate, .mod, .@"test", .typeAlias => {},
        }
    }

    /// Pre-pass: record every symbol this module will define — function
    /// signatures (already mangled for extension/record methods) and globals.
    /// Lowering consults these so a `call`/`global.get` is never emitted for a
    /// name the module does not define (wasmtime rejects the whole module on
    /// the first such reference) and so arguments can be coerced to the
    /// declared parameter types.
    /// A function's signature and the shapes its return spells — every
    /// declared `fn`, and each specialisation of a generic one
    /// (`specializedCallee`).
    fn registerFn(self: *Emitter, f: ast.FnDecl) !void {
        const ra = self.reg_arena.allocator();
        if ((f.isHost() or f.isDeclare or f.body.len == 0) and !self.host_bindings.contains(f.name)) {
            try self.host_fns.put(f.name, {});
            // Decision 67 — a host-backed `declare fn` that names some
            // other target and no `wasm` one has no symbol here and
            // never claimed to: `lowerPlainCall` refuses the call
            // rather than lowering it to a trap.
            if (f.isExternal() and f.externalFor(self.external_lookup) == null)
                try self.external_missing.put(f.name, {});
            return;
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
            try self.fn_ret_typerefs.put(f.name, try self.eraseOptTypeParam(&.{}, f.genericParams, rt));
            if (genericResultIndex(f.genericParams, ptrefs.items, rt)) |ix|
                try self.generic_result_arg.put(self.alloc, f.name, ix);
        } else if (f.returnType == null and self.bodyReturnsString(f.body)) {
            // The specialisation pass clears the return type of the
            // fns it injects; a body that returns a string still does.
            try self.str_fns.put(f.name, {});
        }
        // `fn isPositive(n: i32) -> n is i32` answers a bool.
        if (f.typeGuardParam != null) try self.bool_fns.put(f.name, {});
    }

    /// A module-level `val g = greet` whose function is declared after it:
    /// `registerSymbols` met the `val` before `greet`'s signature, so it is
    /// typed here, once every signature is registered.
    fn typeFnValueGlobals(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .val => |v| if (v.typeAnnotation == null and !self.global_typerefs.contains(v.name) and self.globals.contains(v.name)) {
                if (try self.fnRefTypeRef(v.value.*)) |tr| try self.global_typerefs.put(v.name, tr);
            },
            else => {},
        };
    }

    fn registerSymbols(self: *Emitter, program: ast.Program, emit_globals: bool) !void {
        const ra = self.reg_arena.allocator();
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| try self.registerFn(f),
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
                // `val g = greet` types `g` by `greet`'s declaration (the
                // local's rule, `.localBind`); a fn declared further down is
                // typed by `typeFnValueGlobals` once every signature is known.
                const bound_tr: ?ast.TypeRef = v.typeAnnotation orelse self.typeRefOf(v.value.*) orelse try self.fnRefTypeRef(v.value.*);
                if (bound_tr) |tr| try self.global_typerefs.put(v.name, tr);
                if (self.isArrayExpr(v.value.*)) {
                    try self.arr_globals.put(v.name, {});
                    try self.arr_elem_globals.put(v.name, self.elemKindOf(v.value.*));
                    if (self.elemRecordOf(v.value.*)) |rec| try self.arr_elem_rec_globals.put(v.name, rec);
                }
                if (v.typeAnnotation) |ta| {
                    if (arrayElemOfTypeRef(ta)) |ek| {
                        try self.arr_globals.put(v.name, {});
                        try self.arr_elem_globals.put(v.name, ek);
                    }
                    if (self.elemRecordOfTypeRef(ta)) |rec| try self.arr_elem_rec_globals.put(v.name, rec);
                }
            },
            .implement => |im| try self.registerMethodSigs(im.target, im.methods),
            .extend => |ex| try self.registerMethodSigs(ex.target, ex.methods),
            // An enum's methods too: `Shape.Rect(…).counts(3)` is
            // `$Shape_counts(self, 3)` exactly as a record's is — it used to
            // be an `unresolved call` trap.
            .type_ => |r| try self.registerInterfaceSigs(r.name, r.genericParams, try self.methodsWithDefaults(r)),
            .behavior => |i| for (i.methods) |m| {
                try self.behavior_methods.put(self.alloc, try std.fmt.allocPrint(ra, "{s}.{s}", .{ i.name, m.name }), m);
                const body = m.body orelse continue;
                if (!m.is_default or m.is_declare or m.isExternal() or m.isHost()) continue;
                if (m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self")) {
                    // A primitive behavior's default with a `self`: a call on
                    // a primitive receiver reaches it (`lowerPrimDefault`).
                    for (primBehaviorKinds(i.name)) |k| {
                        const key = try std.fmt.allocPrint(ra, "{s}.{s}", .{ @tagName(k), m.name });
                        if (!self.prim_defaults.contains(key)) try self.prim_defaults.put(ra, key, .{ .behavior = i.name, .method = m, .tparams = i.genericParams });
                    }
                    continue;
                }
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
                // One with no type parameter is emitted whether or not a call
                // reaches it, like every other bodied function (`emitDecl`):
                // a body that calls a host function with no wasm binding is
                // refused called or not (decision 146). One with a type
                // parameter — its own or its behavior's — is still emitted
                // only when a call reaches it: emitting each of the primitive
                // behaviors' (`Array.range`, `Pair.of`, …) into every module
                // that carries the behavior is `05-wasm`'s to weigh.
                if (i.genericParams.len + m.genericParams.len == 0) try self.assoc_needed.append(self.alloc, sym);
            },
            else => {},
        };
        // Decision 107 — an import bound under an alias: the callee a body
        // spells is the alias, the function the linked owner defines is the
        // declared name. Register the alias beside the declared name in every
        // table a call consults, and map it back where the `call` is written.
        for (program.decls) |decl| switch (decl) {
            .use => |u| for (u.imports) |imp| {
                const alias = imp.alias orelse continue;
                const leaf = imp.leaf();
                if (std.mem.eql(u8, alias, leaf)) continue;
                // An imported module-level `pub val` under an alias: the global
                // the linked owner defines is the declared name; every table a
                // read consults answers the alias as it answers the leaf, and
                // `global.get` is written with the leaf (`globalName`).
                if (self.globals.contains(leaf)) {
                    try self.aliasGlobal(alias, leaf);
                    continue;
                }
                const sig = self.fn_sigs.get(leaf) orelse continue;
                try self.import_aliases.put(alias, leaf);
                try self.fn_sigs.put(alias, sig);
                if (self.fn_param_typerefs.get(leaf)) |v| try self.fn_param_typerefs.put(alias, v);
                if (self.fn_ret_typerefs.get(leaf)) |v| try self.fn_ret_typerefs.put(alias, v);
                if (self.generic_result_arg.get(leaf)) |v| try self.generic_result_arg.put(self.alloc, alias, v);
                if (self.fn_arr_elem.get(leaf)) |v| try self.fn_arr_elem.put(alias, v);
                if (self.result_shape_fns.get(leaf)) |v| try self.result_shape_fns.put(alias, v);
                if (self.str_fns.contains(leaf)) try self.str_fns.put(alias, {});
                if (self.bool_fns.contains(leaf)) try self.bool_fns.put(alias, {});
                if (self.result_str_fns.contains(leaf)) try self.result_str_fns.put(alias, {});
            },
            else => {},
        };
    }

    /// Register `alias` for the linked global `leaf` in every per-global table.
    fn aliasGlobal(self: *Emitter, alias: []const u8, leaf: []const u8) !void {
        try self.import_aliases.put(alias, leaf);
        try self.globals.put(alias, {});
        if (self.global_types.get(leaf)) |v| try self.global_types.put(alias, v);
        if (self.global_typerefs.get(leaf)) |v| try self.global_typerefs.put(alias, v);
        if (self.global_rec_types.get(leaf)) |v| try self.global_rec_types.put(alias, v);
        if (self.folded_globals.get(leaf)) |v| try self.folded_globals.put(alias, v);
        if (self.str_globals.contains(leaf)) try self.str_globals.put(alias, {});
        if (self.bool_globals.contains(leaf)) try self.bool_globals.put(alias, {});
        if (self.arr_globals.contains(leaf)) try self.arr_globals.put(alias, {});
        if (self.arr_elem_globals.get(leaf)) |v| try self.arr_elem_globals.put(alias, v);
        if (self.arr_elem_rec_globals.get(leaf)) |v| try self.arr_elem_rec_globals.put(alias, v);
    }

    /// The wasm global a read of `name` reaches: the declared name of an
    /// imported `pub val` bound under an alias, else the name itself.
    fn globalName(self: *const Emitter, name: []const u8) []const u8 {
        return self.import_aliases.get(name) orelse name;
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

    fn registerInterfaceSigs(self: *Emitter, owner: []const u8, owner_tparams: []const ast.GenericParam, methods: []const ast.BehaviorMethod) !void {
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
            const first: usize = if (needs_self) 1 else 0;
            for (m.params, 0..) |p, i| params[first + i] = memberValType(p.typeRef);
            try self.fn_sigs.put(sym, .{
                .params = params,
                .result = if (m.returnType) |rt| memberValType(rt) else if (methodHasResult(body)) "i32" else null,
            });
            // A method's declared return type, under the symbol the call
            // emits. `typeRefOf` asks for it so the *reader* of a `?T` agrees
            // with the writer: `Dict.at` answers `?V`, which is unboxed
            // here (a type parameter is not a known scalar), and without this
            // the reader assumed a box and loaded through the payload as if it
            // were an address — `d.at("a").unwrapOr(0)` answered `0` for a
            // key that is present, exit 0, no diagnostic.
            // The same registration the top-level `fn` arm makes, for the same
            // reason: `@print` picks its printer from the recovered shape, and a
            // method's shape was never recorded — so a method returning a
            // `string`, a `bool` or an array was printed through
            // `$__print_i32`, which writes a **pointer** (`276` for `"doc:hi"`,
            // `444` for `["a", "b"]`) or `0`/`1` for a bool.
            if (m.returnType) |rt| {
                try self.fn_ret_typerefs.put(sym, try self.eraseOptTypeParam(owner_tparams, m.genericParams, rt));
                if (isStringTypeRef(rt)) try self.str_fns.put(sym, {});
                if (isBoolTypeRef(rt)) try self.bool_fns.put(sym, {});
                if (arrayElemOfTypeRef(rt)) |ek| try self.fn_arr_elem.put(sym, ek);
                // A method answering `@Result<string, …>`: what a `try` of it
                // binds is a string (`val once = try self.read(b)`).
                if (resultOfString(rt)) try self.result_str_fns.put(sym, {});
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
                    if (tdecl.genericParams.len > 0) try self.record_generics.put(ra, tdecl.name, tdecl.genericParams);
                    if (tdecl.displayName) |shown| try self.printed_names.put(self.reg_arena.allocator(), tdecl.name, shown);
                },
                .enum_ => {
                    try self.enums.put(tdecl.name, tdecl.variants());
                    if (tdecl.displayName) |shown| try self.printed_names.put(self.reg_arena.allocator(), tdecl.name, shown);
                },
            },
            .@"fn" => |f| {
                if (f.returnType) |rt| {
                    const tn = typeRefName(rt);
                    if (tn.len > 0) try self.fn_return_types.put(f.name, tn);
                }
            },
            .behavior => |b| try self.behavior_decls.put(self.alloc, b.name, b),
            else => {},
        };
        // A `default fn` a record adopts returns `Self` as the record.
        for (program.decls) |decl| switch (decl) {
            .type_ => |tdecl| if (tdecl.isRecord()) {
                for (try self.adoptedDefaults(tdecl)) |m| if (m.returnType) |rt| {
                    const tn = typeRefName(rt);
                    if (tn.len > 0) try self.fn_return_types.put(try std.fmt.allocPrint(ra, "{s}_{s}", .{ tdecl.name, m.name }), if (std.mem.eql(u8, tn, "Self")) tdecl.name else tn);
                };
            },
            else => {},
        };
    }

    /// The `default fn`s a type adopts from the behaviors it implements (and
    /// the ones those extend) and does not write itself. They are emitted as
    /// its own `$<Type>_<method>` — `Money(…).clamp(lo, hi)` over `Bounded`'s
    /// default was an `unresolved call` trap.
    fn adoptedDefaults(self: *Emitter, t: ast.TypeDecl) ![]const ast.BehaviorMethod {
        var out: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
        var seen: std.ArrayListUnmanaged([]const u8) = .empty;
        for (t.implement) |tr| try self.collectDefaults(typeRefName(tr), t, &out, &seen);
        return out.items;
    }

    fn collectDefaults(
        self: *Emitter,
        name: []const u8,
        t: ast.TypeDecl,
        out: *std.ArrayListUnmanaged(ast.BehaviorMethod),
        seen: *std.ArrayListUnmanaged([]const u8),
    ) !void {
        for (seen.items) |n| if (std.mem.eql(u8, n, name)) return;
        try seen.append(self.arena(), name);
        const b = self.behavior_decls.get(name) orelse return;
        outer: for (b.methods) |m| {
            if (!m.is_default or m.body == null) continue;
            if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
            for (t.methods) |own| if (std.mem.eql(u8, own.name, m.name)) continue :outer;
            for (out.items) |got| if (std.mem.eql(u8, got.name, m.name)) continue :outer;
            try out.append(self.arena(), m);
        }
        for (b.extends) |e| try self.collectDefaults(e, t, out, seen);
    }

    /// A type's own methods followed by the defaults it adopts.
    fn methodsWithDefaults(self: *Emitter, t: ast.TypeDecl) ![]const ast.BehaviorMethod {
        const adopted = try self.adoptedDefaults(t);
        if (adopted.len == 0) return t.methods;
        const all = try self.arena().alloc(ast.BehaviorMethod, t.methods.len + adopted.len);
        @memcpy(all[0..t.methods.len], t.methods);
        @memcpy(all[t.methods.len..], adopted);
        return all;
    }

    /// Bare type-name behind a `TypeRef`, stripping `?T` and generic args.
    /// Returns `""` for shapes we can't reduce (fn types, tuples, etc.).
    fn typeRefName(t: ast.TypeRef) []const u8 {
        return switch (eagerTypeRef(t)) {
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

    /// Declared type of `field` inside `record`, when both are known.
    fn fieldTypeRefIn(self: *Emitter, record: []const u8, field: []const u8) ?ast.TypeRef {
        const fields = self.records.get(record) orelse return null;
        const trefs = self.record_field_typerefs.get(record) orelse return null;
        for (fields, 0..) |f, i| if (std.mem.eql(u8, f, field) and i < trefs.len) return self.fieldSub(record, trefs[i]);
        return null;
    }

    /// A field type `ft` of the generic record `rty` that names one of its
    /// type parameters, read through `recv` whose type spells the arguments
    /// (`p: Pair<string>` in a copy, a `Pair(left: s, …)` local): that
    /// argument. `ft` itself otherwise.
    /// `recvTypeArg` for any type argument, a function type included.
    fn recvTypeArgRef(self: *Emitter, recv: ast.Expr, rty: []const u8, ft: ast.TypeRef) ast.TypeRef {
        if (ft != .named) return ft;
        const gps = self.record_generics.get(rty) orelse return ft;
        const idx = for (gps, 0..) |gp, i| {
            if (std.mem.eql(u8, gp.name, ft.named)) break i;
        } else return ft;
        const tr = self.typeRefOf(recv) orelse return ft;
        if (tr != .generic or !std.mem.eql(u8, tr.generic.name, rty) or tr.generic.args.len != gps.len) return ft;
        return tr.generic.args[idx];
    }

    fn recvTypeArg(self: *Emitter, recv: ast.Expr, rty: []const u8, ft: []const u8) []const u8 {
        const gps = self.record_generics.get(rty) orelse return ft;
        const idx = for (gps, 0..) |gp, i| {
            if (std.mem.eql(u8, gp.name, ft)) break i;
        } else return ft;
        const tr = self.typeRefOf(recv) orelse return ft;
        if (tr != .generic or !std.mem.eql(u8, tr.generic.name, rty) or tr.generic.args.len != gps.len) return ft;
        return switch (tr.generic.args[idx]) {
            .named => |n| n,
            else => ft,
        };
    }

    /// A field type written as one of the owner's type parameters, read in a
    /// specialisation of one of the owner's methods: the substituted type.
    fn fieldSub(self: *Emitter, record: []const u8, t: ast.TypeRef) ast.TypeRef {
        if (self.field_subs.len == 0 or !std.mem.eql(u8, record, self.field_subs_owner)) return t;
        const n = switch (t) {
            .named => |n| n,
            else => return t,
        };
        for (self.field_subs) |sub| if (std.mem.eql(u8, sub.name, n)) return sub.to;
        return t;
    }

    /// Declared type-name of `field` inside `record`, when both are known.
    fn fieldTypeIn(self: *Emitter, record: []const u8, field: []const u8) ?[]const u8 {
        const fields = self.records.get(record) orelse return null;
        const types = self.record_field_types.get(record) orelse return null;
        for (fields, 0..) |fn_, i| {
            if (std.mem.eql(u8, fn_, field)) {
                if (i >= types.len) return null;
                const tn = types[i];
                if (tn.len == 0) return null;
                return switch (self.fieldSub(record, .{ .named = tn })) {
                    .named => |n| n,
                    else => tn,
                };
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
        if (self.genericResultOf(e)) |a| return self.recordTypeOfExpr(a);
        // `x!` (decision 330): the payload's record.
        if (optOperatorParts(e)) |op| if (op.bang) if (self.optInfoOf(op.cond.*)) |oi| {
            if (oi.rec) |r| return r;
            if (oi.inner) |tr| switch (tr) {
                .named => |n| return self.resolveRecordName(n),
                .generic => |g| return self.resolveRecordName(g.name),
                else => {},
            };
        };
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
                    // A field declared as one of a generic record's type
                    // parameters (`data: D` of `Route<P, D>`) is the record
                    // the receiver's type argument names: `route.data.title`
                    // reads `Post`'s slot, never an untyped one.
                    break :blk self.resolveRecordName(self.recvTypeArg(ia.receiver.*, recv_ty, field_ty));
                },
                else => null,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    // `xs.at(i)` / `xs.first()` over an array of records: the
                    // `?Entry` it answers is an `Entry` pointer, and its record
                    // type is what a `?.field` read (and the narrowed name a
                    // `!= null` test rebinds) needs to find a slot. Without it
                    // the reader fell back to the unique-field guess and, when
                    // the value was a box, read one indirection short.
                    if (self.primKindAt(cc, c.loc)) |k| {
                        if (k == .array and (std.mem.eql(u8, cc.callee, "at") or std.mem.eql(u8, cc.callee, "first") or std.mem.eql(u8, cc.callee, "find") or std.mem.eql(u8, cc.callee, "pop"))) {
                            if (cc.receiver) |r| if (self.elemRecordOf(r.*)) |rec| break :blk rec;
                        }
                    }
                    switch (self.callKind(cc)) {
                        .record_ctor => break :blk self.resolveRecordName(cc.callee),
                        .plain => {
                            // A method on a record value answers its declared
                            // return — `self.max(lo)` is a `Money` when
                            // `Money_max` returns `Self` — so a chained
                            // `.min(hi)` finds its owner.
                            if (cc.receiver != null) if (self.recordMethodSym(cc, c.loc)) |sym| {
                                const tn = self.fn_return_types.get(sym) orelse break :blk null;
                                break :blk self.resolveRecordName(tn);
                            };
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
            // `try f(…)` answers the ok payload of the `@Result` `f` declares:
            // `val v = try readValue(doc, i); v.next` (`std/json`'s reader)
            // reads a field of a `Parsed`, which nothing typed before.
            .jump => |j| switch (j.kind) {
                .try_ => |t| blk: {
                    const inner = t orelse break :blk null;
                    switch (inner.*) {
                        .call => |c| switch (c.kind) {
                            .call => |cc| {
                                const sym = self.assocSym(cc) orelse cc.callee;
                                const rt = self.fn_ret_typerefs.get(sym) orelse break :blk null;
                                if (rt != .generic) break :blk null;
                                const g = rt.generic;
                                if (!std.mem.endsWith(u8, g.name, "Result") or g.args.len != 2) break :blk null;
                                break :blk self.resolveRecordName(typeRefName(g.args[0]));
                            },
                            else => break :blk null,
                        },
                        else => break :blk null,
                    }
                },
                else => null,
            },
            // `a ?? b` — the transform pass writes it as `if (a) { <this> ->
            // <this> } else { b }`, so the binder is what tells it apart from
            // an ordinary `if`. Both arms carry the same type by construction
            // and the default is the one that names it: the payload arm reads
            // a bound name whose type nothing recovered. Without this,
            // `(es.at(9) ?? Entry(key: "zz")).key` found its slot by the
            // unique-field guess and then printed the string as a number,
            // because nothing knew the field was declared `string`.
            .branch => |b| switch (b.kind) {
                .if_ => |i| blk: {
                    if (i.binding == null) break :blk null;
                    const els = i.else_ orelse break :blk null;
                    if (els.len == 0) break :blk null;
                    break :blk self.recordTypeOfExpr(els[els.len - 1].expr);
                },
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
    /// `i32`/`f64`/`str`, and a record is an `i32` slot like any pointer), and a
    /// record read out of one.
    /// The enum a plain call (`stop()`, an import's alias included) is declared
    /// to answer, when its callee's return type names one this program holds.
    /// A `?Enum` is not one: an optional prints by its own path.
    fn enumReturnedBy(self: *Emitter, cc: anytype) ?[]const u8 {
        if (cc.receiver != null or cc.calleeExpr != null or cc.is_builtin) return null;
        const callee = self.import_aliases.get(cc.callee) orelse cc.callee;
        const rt = switch (self.fn_ret_typerefs.get(callee) orelse return null) {
            .named => |n| n,
            else => return null,
        };
        return if (self.enums.contains(rt)) rt else null;
    }

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
                .call => |cc| {
                    if (self.callKind(cc) == .enum_ctor) return .variant;
                    // `stop()` — a function declared to answer an enum. Its
                    // value is a variant like the constructor's; the numeric
                    // printer answered its address.
                    if (self.enumReturnedBy(cc) != null) return .variant;
                    return null;
                },
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

    /// Whether `name` is a declaration this module can test a value against
    /// (a record, or an enum with at least one allocated variant).
    fn namesATestableType(self: *Emitter, name: []const u8) bool {
        const descs = self.typeDescriptors(.{ .named = name }) catch return false;
        return descs.len > 0;
    }

    /// The header test for a named `type`, over the subject already in a
    /// local: `subj >= <heap floor> && load(subj - 4) == <descriptor>`, an
    /// enum's variants joined by `or`. False when the name is not a type this
    /// module can place, and the caller keeps what it wrote before.
    fn emitNamedTypeTest(self: *Emitter, name: []const u8, subj: []const u8) anyerror!bool {
        const descs = try self.typeDescriptors(.{ .named = name });
        if (descs.len == 0) return false;
        try self.emit(.{ .local_get = subj });
        try self.emit(try self.constInt(heap_floor));
        try self.emit(opOf("i32", "ge_u"));
        for (descs, 0..) |d, i| {
            try self.emitHeaderLoad(subj);
            try self.emit(try self.constInt(d));
            try self.emit(opOf("i32", "eq"));
            if (i > 0) try self.emit(opOf("i32", "or"));
        }
        try self.emit(opOf("i32", "and"));
        return true;
    }

    /// The descriptor word behind the value in `subj`, read where a caller
    /// has already pushed the heap-floor guard it `and`s the answer with.
    /// wasm's `and` does not short-circuit, so an ordinal below the floor (an
    /// all-unit variant, `0`) would still be loaded from `subj - 4` — below
    /// address 0 for the first few, an out-of-bounds trap. The address is
    /// `(subj - 4) * (subj >= floor)`: a value below the floor reads word 0,
    /// whose answer the guard discards.
    fn emitHeaderLoad(self: *Emitter, subj: []const u8) anyerror!void {
        try self.emit(.{ .local_get = subj });
        try self.emit(try self.constInt(tag_header_bytes));
        try self.emit(opOf("i32", "sub"));
        try self.emit(.{ .local_get = subj });
        try self.emit(try self.constInt(heap_floor));
        try self.emit(opOf("i32", "ge_u"));
        try self.emit(opOf("i32", "mul"));
        try self.emit(.{ .load = .{} });
    }

    /// Decision 8 §4.2 — `x is T` on wasm. The identity is the descriptor
    /// address in the value's header, so the test is one `i32.load` behind the
    /// pointer compared against the constant the declaration interned, under a
    /// bounds guard: an `i32` that is not a pointer would otherwise read four
    /// bytes of whatever sits below it. An enum is every variant's descriptor,
    /// joined by `or`.
    ///
    /// A type with no descriptor has no test here — an all-unit enum's value
    /// is its bare ordinal, an `i32` like every other — so the test is
    /// refused where it is written (`refuseUnlessTemplate`), never answered.
    fn lowerIsCall(self: *Emitter, cc: anytype) anyerror!void {
        const t = cc.isType orelse return error.InvalidArgs;
        if (cc.args.len != 1) return error.InvalidArgs;
        // §4.1 / §4.2 over a primitive — by VALUE: the operand goes in the
        // box an `unknown` slot holds (a no-op when it already is one), and
        // the box's header answers. `300 is i8` is `false`, `3.0 is i32` is
        // `true`, `2 is f64` is `true`.
        if (primTestOf(t)) |pt| {
            try self.lowerAsUnknown(cc.args[0].value.*);
            try self.emitPrimTest(pt);
            return;
        }
        // Decision 254 — `x is fn(<params>) -> T`: a function value in an
        // `unknown` slot is boxed under the descriptor of its arity
        // (`lowerAsUnknown`), so the test is that descriptor in the header.
        if (t == .function) {
            const desc = try self.fnDescriptorAddr(t.function.params.len);
            const mem = try self.memName(self.nextMem());
            try self.lowerAsUnknown(cc.args[0].value.*);
            try self.emit(.{ .local_tee = mem });
            try self.emit(try self.constInt(heap_floor));
            try self.emit(opOf("i32", "ge_u"));
            try self.emitHeaderLoad(mem);
            try self.emit(try self.constInt(desc));
            try self.emit(opOf("i32", "eq"));
            try self.emit(opOf("i32", "and"));
            return;
        }
        if (t.tupleElems()) |elems| return self.lowerIsTuple(cc.args[0].value.*, elems);
        const descs = try self.typeDescriptors(t);
        if (descs.len == 0) {
            return self.refuseUnlessTemplate(self.call_loc, "`is {f}`: the wasm backend has no run-time test for this type (no value of it carries a descriptor)", .{t});
        }
        const mem = try self.memName(self.nextMem());
        try self.lowerCoerced(cc.args[0].value.*, "i32");
        try self.emit(.{ .local_tee = mem });
        try self.emit(try self.constInt(heap_floor));
        try self.emit(opOf("i32", "ge_u"));
        for (descs, 0..) |d, i| {
            try self.emitHeaderLoad(mem);
            try self.emit(try self.constInt(d));
            try self.emit(opOf("i32", "eq"));
            if (i > 0) try self.emit(opOf("i32", "or"));
        }
        try self.emit(opOf("i32", "and"));
    }

    // ── decision 8 §11's box (`00 · 05-wasm` step 2 D1–D3) ─────────────────
    //
    // A value entering an `unknown` or union slot carries a header behind its
    // pointer — the header C-01 gave every value a declaration builds. A record
    // or a variant already has one and goes in as it is; a primitive is boxed
    // (`[descriptor][payload]`, descriptor `'P' <n> name`), so the readers in
    // `wat_prelude.zig`'s `unknown` group can ask the value what it holds.

    const PrimTest = union(enum) {
        /// An integer type: a whole number in `lo..=hi`.
        int: struct { lo: i32, hi: i32 },
        /// A float type: any number.
        float,
        bool_,
        string,
    };

    fn primTestOf(t: ast.TypeRef) ?PrimTest {
        const n = switch (t) {
            .named => |n| n,
            else => return null,
        };
        const eq = std.mem.eql;
        if (eq(u8, n, "i8")) return .{ .int = .{ .lo = -128, .hi = 127 } };
        if (eq(u8, n, "i16")) return .{ .int = .{ .lo = -32768, .hi = 32767 } };
        if (eq(u8, n, "u8")) return .{ .int = .{ .lo = 0, .hi = 255 } };
        if (eq(u8, n, "u16")) return .{ .int = .{ .lo = 0, .hi = 65535 } };
        // An `i32` slot is this backend's integer: `i64`/`u32`/`u64` values
        // it holds fit the `i32` range (`u32`/`u64` from 0).
        if (eq(u8, n, "i32") or eq(u8, n, "i64") or eq(u8, n, "int") or eq(u8, n, "isize"))
            return .{ .int = .{ .lo = std.math.minInt(i32), .hi = std.math.maxInt(i32) } };
        if (eq(u8, n, "u32") or eq(u8, n, "u64") or eq(u8, n, "uint") or eq(u8, n, "usize"))
            return .{ .int = .{ .lo = 0, .hi = std.math.maxInt(i32) } };
        if (eq(u8, n, "f32") or eq(u8, n, "f64") or eq(u8, n, "float")) return .float;
        if (eq(u8, n, "bool")) return .bool_;
        if (eq(u8, n, "string")) return .string;
        return null;
    }

    /// With an `unknown` value on the stack, leave whether it holds `pt`.
    fn emitPrimTest(self: *Emitter, pt: PrimTest) anyerror!void {
        const b = self.builder();
        switch (pt) {
            .int => |r| {
                try self.emit(try self.constInt(r.lo));
                try self.emit(try self.constInt(r.hi));
                try self.emit(b.helper(.unknown_int_in));
            },
            .float => {
                const k = try self.memName(self.nextMem());
                try self.emit(b.helper(.unknown_kind));
                try self.emit(.{ .local_tee = k });
                try self.emit(try self.constInt(@as(i32, 'i')));
                try self.emit(opOf("i32", "eq"));
                try self.emit(.{ .local_get = k });
                try self.emit(try self.constInt(@as(i32, 'f')));
                try self.emit(opOf("i32", "eq"));
                try self.emit(opOf("i32", "or"));
            },
            .bool_, .string => {
                try self.emit(b.helper(.unknown_kind));
                try self.emit(try self.constInt(@as(i32, if (pt == .bool_) 'b' else 's')));
                try self.emit(opOf("i32", "eq"));
            },
        }
    }

    fn isUnknownTypeRef(t: ast.TypeRef) bool {
        return switch (t) {
            .named => |n| std.mem.eql(u8, n, ast.unknown_type_name),
            .generic => |g| std.mem.eql(u8, g.name, ast.union_type_name),
            else => false,
        };
    }

    /// Whether `e` already is an `unknown` / union value — a box or a tagged
    /// value by construction.
    fn isUnknownExpr(self: *Emitter, e: ast.Expr) bool {
        const t = self.typeRefOf(e) orelse return false;
        return isUnknownTypeRef(t);
    }

    /// The descriptor a boxed primitive carries: `'P' <n> name`, interned once.
    fn primDescriptorAddr(self: *Emitter, name: []const u8) anyerror!u32 {
        const key = try std.fmt.allocPrint(self.reg_arena.allocator(), "#{s}", .{name});
        if (self.type_descs.get(key)) |addr| return addr;
        var out: std.ArrayListUnmanaged(u8) = .empty;
        try out.append(self.arena(), 'P');
        try out.append(self.arena(), @intCast(name.len));
        try out.appendSlice(self.arena(), name);
        const seg = try self.internString(out.items);
        const addr = seg.offset + 4;
        try self.type_descs.put(key, addr);
        return addr;
    }

    /// Decision 254 — the descriptor a function value boxed into an `unknown`
    /// slot carries: `'P' <n> "fn/<arity>"`. The arity is the one thing a
    /// run-time test can read back; the parameter and return types leave no
    /// trace in a closure cell.
    fn fnDescriptorAddr(self: *Emitter, arity: usize) anyerror!u32 {
        return self.primDescriptorAddr(try std.fmt.allocPrint(self.reg_arena.allocator(), "fn/{d}", .{arity}));
    }

    /// The arity of `e` when it is a function value: a lambda, a top-level fn
    /// named as a value, or a name or slot declared with a function type.
    fn fnValueArity(self: *Emitter, e: ast.Expr) ?usize {
        switch (e) {
            .function => |f| if (f.kind.syntax == .lambda) return f.kind.params.len,
            .identifier => |id| if (id.kind == .ident) {
                const n = self.resolveName(id.kind.ident);
                if (!self.locals.contains(n) and !self.globals.contains(n)) {
                    if (self.fn_sigs.get(id.kind.ident)) |sig| return sig.params.len;
                }
            },
            else => {},
        }
        const t = self.typeRefOf(e) orelse return null;
        return switch (t) {
            .function => |f| f.params.len,
            else => null,
        };
    }

    /// Decision 354 (8) — the hidden context map a `@Component` function
    /// receives (`context_lower.zig`) is already an `unknown` value: passed
    /// on, it is not boxed again.
    fn isContextMapIdent(value: ast.Expr) bool {
        if (value != .identifier or value.identifier.kind != .ident) return false;
        return std.mem.eql(u8, value.identifier.kind.ident, context_lower.map_param);
    }

    /// Lower `value` as the `unknown` value it becomes in such a slot: as it
    /// is when it already is one or carries its own header, `0` for `null`,
    /// else boxed by its static shape — a function value under its arity's
    /// descriptor (decision 254), its payload the closure cell.
    fn lowerAsUnknown(self: *Emitter, value: ast.Expr) anyerror!void {
        if (isNullLit(value) or self.isUnknownExpr(value) or self.isTaggedValue(value) or isContextMapIdent(value)) {
            try self.lowerCoerced(value, "i32");
            return;
        }
        if (self.fnValueArity(value)) |arity| {
            const fbase = try self.allocTagged(try self.fnDescriptorAddr(arity), 4);
            try self.emit(.{ .local_get = fbase });
            try self.lowerCoerced(value, "i32");
            try self.emitC(.{ .store = .{ .offset = tag_header_bytes } }, "unknown: box a function value");
            try self.loadTaggedBase(fbase);
            return;
        }
        const Kind = enum { i32_, f64_, bool_, str, arr, tuple };
        const kind: Kind = if (self.isStringExpr(value))
            .str
        else if (self.isBoolExpr(value))
            .bool_
        else if (self.wasmTypeOf(value)[0] == 'f')
            .f64_
        else if (self.isArrayExpr(value))
            .arr
        else if (isTupleLit(value) or self.typeRefIsTuple(value))
            .tuple
        else if (self.isKnownInteger(value))
            .i32_
        else {
            // Nothing proves what the value is — a type parameter's slot
            // (`Maybe.Some(value: v)` over a `T`), a result nothing typed —
            // and every value here is an `i32`: a guess would answer `is`
            // and `==` wrongly at exit 0 (decision 67).
            // In a generic body the slot is a type parameter's, and the body
            // runs only for a call no specialisation bound: that call is
            // refused (`refuseUnboundTemplateCalls`), and the generic body
            // keeps an `unreachable` no execution meets.
            if (self.cur_template != null)
                return self.refuseUnlessTemplate(value.getLoc(), "unknown: no static type to box this value by (a type parameter's slot?)", .{});
            // A call of a host cell with no wasm binding answers nothing
            // here at all: lowering it raises that refusal, which names the
            // real cause.
            if (value == .call and value.call.kind == .call and self.external_missing.contains(value.call.kind.call.callee))
                return self.lowerCoerced(value, "i32");
            return self.refuse(value.getLoc(), "the wasm backend cannot box this value as `unknown`: nothing gives it a static type here", .{});
        };
        if (kind == .tuple) return self.boxTupleAsUnknown(value);
        const name = switch (kind) {
            .i32_ => "i32",
            .f64_ => "f64",
            .bool_ => "bool",
            .str => "string",
            .arr => "array",
            .tuple => "tuple",
        };
        const desc = try self.primDescriptorAddr(name);
        const base = try self.allocTagged(desc, if (kind == .f64_) 8 else 4);
        try self.emit(.{ .local_get = base });
        if (kind == .f64_) {
            try self.lowerCoerced(value, "f64");
            try self.emitC(.{ .store = .{ .ty = .f64, .offset = tag_header_bytes } }, "unknown: box an f64");
        } else {
            try self.lowerCoerced(value, "i32");
            try self.emitCf(.{ .store = .{ .offset = tag_header_bytes } }, "unknown: box a{s} {s}", .{ if (kind == .arr) "n" else "", name });
        }
        try self.loadTaggedBase(base);
    }

    /// How a tuple element's word goes into an `unknown` slot of its own:
    /// boxed as the primitive it is, as it is when it carries a header (a
    /// record, a variant, an `unknown`), or `unresolved` when nothing says
    /// what the word holds (a nested tuple, a function, an `i64` cell, a type
    /// parameter's slot).
    const ElemBox = enum { i32_, f64_, bool_, str, arr, as_is, unresolved };

    fn elemBoxOfExpr(self: *Emitter, e: ast.Expr) ElemBox {
        if (isNullLit(e) or self.isUnknownExpr(e) or self.isTaggedValue(e)) return .as_is;
        if (self.fnValueArity(e) != null) return .unresolved;
        if (self.isStringExpr(e)) return .str;
        if (self.isBoolExpr(e)) return .bool_;
        const wt = self.wasmTypeOf(e);
        if (std.mem.eql(u8, wt, "f64")) return .f64_;
        if (wt[0] != 'i' or wt.len != 3 or wt[1] != '3') return .unresolved;
        if (self.isArrayExpr(e)) return .arr;
        if (isTupleLit(e) or self.typeRefIsTuple(e)) return .unresolved;
        if (self.isKnownInteger(e)) return .i32_;
        return .unresolved;
    }

    fn elemBoxOfTypeRef(self: *Emitter, t: ast.TypeRef) ElemBox {
        if (isUnknownTypeRef(t)) return .as_is;
        if (t == .array) return .arr;
        if (t == .generic and std.mem.eql(u8, t.generic.name, "Array")) return .arr;
        if (primTestOf(t)) |pt| {
            const n = t.named;
            if (fieldCellOf(n) == .i64) return .unresolved;
            return switch (pt) {
                .int => .i32_,
                .float => .f64_,
                .bool_ => .bool_,
                .string => .str,
            };
        }
        const descs = self.typeDescriptors(t) catch return .unresolved;
        if (descs.len > 0) {
            // An enum whose values may be bare ordinals (a unit variant
            // beside allocated ones) has no header to read on every value.
            const n = typeRefName(t);
            if (self.enums.get(n)) |variants| {
                if (variants.len != descs.len) return .unresolved;
            }
            return .as_is;
        }
        if (t == .named and self.enums.contains(t.named)) return .i32_;
        return .unresolved;
    }

    /// Decision 8 §4.2 — a tuple in an `unknown` slot: `[desc "tuple"][the
    /// tuple][arity][box 0]…[box n-1]`, each element in an `unknown` box of its
    /// own, so `v is #(i32, string)` asks every element by value as a
    /// primitive `is` does. The tuple stays the payload's first word, which is
    /// what every other reader of a boxed tuple loads. An element nothing
    /// types writes arity `-1`: `is` over such a box traps rather than answer.
    fn boxTupleAsUnknown(self: *Emitter, value: ast.Expr) anyerror!void {
        const lit_elems: ?[]const ast.Expr = switch (value) {
            .collection => |col| switch (col.kind) {
                .tupleLit => |tl| tl.elems,
                else => null,
            },
            else => null,
        };
        const tr_elems: ?[]ast.TypeRef = if (self.typeRefOf(value)) |t| t.tupleElems() else null;
        const n: usize = if (lit_elems) |es| es.len else if (tr_elems) |ts| ts.len else 0;
        const ra = self.reg_arena.allocator();
        const kinds = try ra.alloc(ElemBox, n);
        var resolved = lit_elems != null or tr_elems != null;
        for (kinds, 0..) |*k, i| {
            k.* = if (lit_elems) |es| self.elemBoxOfExpr(es[i]) else self.elemBoxOfTypeRef(tr_elems.?[i]);
            if (k.* == .unresolved) resolved = false;
        }
        const tup = try self.memName(self.nextMem());
        try self.lowerCoerced(value, "i32");
        try self.emit(.{ .local_set = tup });
        const desc = try self.primDescriptorAddr("tuple");
        const base = try self.allocTagged(desc, @intCast(8 + 4 * (if (resolved) n else 0)));
        try self.emit(.{ .local_get = base });
        try self.emit(.{ .local_get = tup });
        try self.emitC(.{ .store = .{ .offset = tag_header_bytes } }, "unknown: box a tuple");
        try self.emit(.{ .local_get = base });
        try self.emit(try self.constInt(if (resolved) @as(i32, @intCast(n)) else -1));
        try self.emitC(.{ .store = .{ .offset = tag_header_bytes + 4 } }, "unknown: the tuple's arity (-1: an element nothing types)");
        if (!resolved) {
            try self.loadTaggedBase(base);
            return;
        }
        const word = try self.memName(self.nextMem());
        const boxed = try self.memName(self.nextMem());
        for (kinds, 0..) |k, i| {
            try self.emit(.{ .local_get = tup });
            try self.emitLoadOffset(@intCast(i * 4));
            try self.emit(.{ .local_set = word });
            switch (k) {
                .as_is => try self.emit(.{ .local_get = word }),
                .f64_ => {
                    const eb = try self.allocTagged(try self.primDescriptorAddr("f64"), 8);
                    try self.emit(.{ .local_get = eb });
                    try self.emit(.{ .local_get = word });
                    try self.emit(.{ .load = .{ .ty = .f64 } });
                    try self.emitC(.{ .store = .{ .ty = .f64, .offset = tag_header_bytes } }, "unknown: box a tuple's f64 element");
                    try self.loadTaggedBase(eb);
                },
                .i32_, .bool_, .str, .arr => {
                    const name: []const u8 = switch (k) {
                        .i32_ => "i32",
                        .bool_ => "bool",
                        .str => "string",
                        else => "array",
                    };
                    const eb = try self.allocTagged(try self.primDescriptorAddr(name), 4);
                    try self.emit(.{ .local_get = eb });
                    try self.emit(.{ .local_get = word });
                    try self.emitCf(.{ .store = .{ .offset = tag_header_bytes } }, "unknown: box a tuple's {s} element", .{name});
                    try self.loadTaggedBase(eb);
                },
                .unresolved => unreachable,
            }
            try self.emit(.{ .local_set = boxed });
            try self.emit(.{ .local_get = base });
            try self.emit(.{ .local_get = boxed });
            try self.emit(.{ .store = .{ .offset = @intCast(tag_header_bytes + 8 + 4 * i) } });
        }
        try self.loadTaggedBase(base);
    }

    /// `x is #(T0, …, Tn-1)`: the subject in its `unknown` box is a boxed
    /// tuple of arity `n` whose every element box answers `is Ti`. A box whose
    /// elements nothing typed (arity `-1`) traps.
    fn lowerIsTuple(self: *Emitter, subject: ast.Expr, elems: []const ast.TypeRef) anyerror!void {
        const b = self.builder();
        const m = try self.memName(self.nextMem());
        const r = try self.memName(self.nextMem());
        const e = try self.memName(self.nextMem());
        try self.lowerAsUnknown(subject);
        try self.emit(.{ .local_set = m });
        try self.emit(try self.constInt(0));
        try self.emit(.{ .local_set = r });

        // Innermost first: element i's test runs only when every earlier one held.
        var inner: ?Seq = null;
        var i = elems.len;
        while (i > 0) {
            i -= 1;
            var c: Capture = .{};
            self.open(&c);
            try self.emit(.{ .local_get = m });
            try self.emitLoadOffset(@intCast(8 + 4 * i));
            try self.emit(.{ .local_set = e });
            try self.emitElemIsTest(elems[i], e);
            try self.emit(.{ .local_set = r });
            if (inner) |sq| {
                try self.emit(.{ .local_get = r });
                try self.emit(.{ .@"if" = .{ .then = .{ .seq = sq } } });
            }
            inner = self.seal(&c, .none);
        }

        var arity_c: Capture = .{};
        self.open(&arity_c);
        try self.emit(.{ .local_get = m });
        try self.emitLoadOffset(4);
        try self.emit(try self.constInt(-1));
        try self.emit(opOf("i32", "eq"));
        var trap_c: Capture = .{};
        self.open(&trap_c);
        try self.emitC(.@"unreachable", "`is` over a tuple whose elements nothing typed");
        const trap_seq = self.seal(&trap_c, .none);
        try self.emit(.{ .@"if" = .{ .then = .{ .seq = trap_seq } } });
        try self.emit(.{ .local_get = m });
        try self.emitLoadOffset(4);
        try self.emit(try self.constInt(@as(i32, @intCast(elems.len))));
        try self.emit(opOf("i32", "eq"));
        var hit_c: Capture = .{};
        self.open(&hit_c);
        if (inner) |sq| {
            for (sq.lines) |ln| try self.cur.?.append(self.arena(), ln);
        } else {
            try self.emit(try self.constInt(1));
            try self.emit(.{ .local_set = r });
        }
        const hit_seq = self.seal(&hit_c, .none);
        try self.emit(.{ .@"if" = .{ .then = .{ .seq = hit_seq } } });
        const arity_seq = self.seal(&arity_c, .none);

        try self.emit(.{ .local_get = m });
        try self.emit(b.helper(.unknown_kind));
        try self.emit(try self.constInt(@as(i32, 't')));
        try self.emit(opOf("i32", "eq"));
        try self.emit(.{ .@"if" = .{ .then = .{ .seq = arity_seq } } });
        try self.emit(.{ .local_get = r });
    }

    /// With element box `e` in a local, leave whether it holds `t`.
    fn emitElemIsTest(self: *Emitter, t: ast.TypeRef, e: []const u8) anyerror!void {
        if (isUnknownTypeRef(t)) {
            try self.emit(try self.constInt(1));
            return;
        }
        if (primTestOf(t)) |pt| {
            try self.emit(.{ .local_get = e });
            try self.emitPrimTest(pt);
            return;
        }
        const descs = try self.typeDescriptors(t);
        if (descs.len == 0 or t.tupleElems() != null) {
            return self.refuseUnlessTemplate(self.call_loc, "`is` over a tuple: the wasm backend has no run-time test for an element of type `{f}`", .{t});
        }
        try self.emit(.{ .local_get = e });
        try self.emit(try self.constInt(heap_floor));
        try self.emit(opOf("i32", "ge_u"));
        for (descs, 0..) |d, k| {
            try self.emitHeaderLoad(e);
            try self.emit(try self.constInt(d));
            try self.emit(opOf("i32", "eq"));
            if (k > 0) try self.emit(opOf("i32", "or"));
        }
        try self.emit(opOf("i32", "and"));
    }

    /// Whether `e` is known to be an integer: a numeral, an integer-typed
    /// declaration, an arithmetic result, an enum ordinal.
    fn isKnownInteger(self: *Emitter, e: ast.Expr) bool {
        switch (e) {
            .literal => |lit| return lit.kind == .numberLit,
            .binaryOp, .unaryOp => return true,
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.isKnownInteger(inner.*),
                else => {},
            },
            else => {},
        }
        const t = self.typeRefOf(e) orelse return false;
        return switch (t) {
            .named => |n| (primTestOf(t) != null and primTestOf(t).? == .int) or self.enums.contains(n),
            else => false,
        };
    }

    fn isTupleLit(e: ast.Expr) bool {
        return switch (e) {
            .collection => |col| switch (col.kind) {
                .tupleLit => true,
                .grouped => |inner| isTupleLit(inner.*),
                else => false,
            },
            else => false,
        };
    }

    fn typeRefIsTuple(self: *Emitter, e: ast.Expr) bool {
        const t = self.typeRefOf(e) orelse return false;
        return t.tupleElems() != null;
    }

    /// Every descriptor a value of `t` may carry: one for a record, one per
    /// variant for an enum, none for anything wasm cannot place.
    fn typeDescriptors(self: *Emitter, t: ast.TypeRef) anyerror![]const u32 {
        const name = switch (t) {
            .named => |n| n,
            .generic => |g| g.name,
            else => return &.{},
        };
        if (try self.typeDescriptorAddr(name, null)) |d| {
            const only = try self.arena().alloc(u32, 1);
            only[0] = d;
            return only;
        }
        // `x is Token.Num` / `x is .Num` — ONE variant, the descriptor its
        // values carry (the enum's other variants carry their own).
        if (std.mem.lastIndexOfScalar(u8, name, '.')) |dot| {
            const vname = name[dot + 1 ..];
            const ename = name[0..dot];
            const en: []const u8 = if (ename.len > 0 and self.enums.contains(ename)) ename else blk: {
                // A leading dot names the variant alone: the one enum that
                // declares it, or no test at all when two do — never a guess.
                var found: ?[]const u8 = null;
                var it = self.enums.iterator();
                while (it.next()) |entry| for (entry.value_ptr.*) |v| {
                    if (!std.mem.eql(u8, v.name, vname)) continue;
                    if (found != null) return &.{};
                    found = entry.key_ptr.*;
                };
                break :blk found orelse return &.{};
            };
            const vs = self.enums.get(en) orelse return &.{};
            if (!enumHasPayload(vs)) return &.{};
            for (vs) |v| if (std.mem.eql(u8, v.name, vname)) {
                const d = try self.variantDescriptorAddr(en, v) orelse return &.{};
                const only = try self.arena().alloc(u32, 1);
                only[0] = d;
                return only;
            };
            return &.{};
        }
        const variants = self.enums.get(name) orelse return &.{};
        if (!enumHasPayload(variants)) return &.{};
        var out: std.ArrayListUnmanaged(u32) = .empty;
        for (variants) |v| {
            if (try self.variantDescriptorAddr(name, v)) |d| try out.append(self.arena(), d);
        }
        return out.items;
    }

    /// Whether `e`'s value carries a descriptor header — every record a
    /// declaration builds, and every variant of an enum that has at least one
    /// payload variant (those are allocated; an all-unit enum's member is the
    /// bare ordinal). An array or a tuple HOLDING one does not: the container
    /// is printed by its shape, and the shape codes have no record arm yet.
    /// The enum with a payload variant a name or a field read is declared
    /// as (`val p: Place`, `a.place`) — the declaration says so, not the
    /// value's spelling.
    fn payloadEnumOfName(self: *Emitter, e: ast.Expr) ?[]const u8 {
        if (e != .identifier) return null;
        const t = self.typeRefOf(e) orelse return null;
        if (t != .named) return null;
        const variants = self.enums.get(t.named) orelse return null;
        return if (enumHasPayload(variants)) t.named else null;
    }

    fn isTaggedValue(self: *Emitter, e: ast.Expr) bool {
        if (self.recordTypeOfExpr(e)) |rt| return self.records.contains(rt);
        switch (e) {
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.isTaggedValue(inner.*),
                else => return false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (self.callKind(cc) != .enum_ctor) {
                        // A call of a function declared to answer an enum
                        // with payloads: the value carries its variant's
                        // descriptor exactly as the constructor's does.
                        // `@print(stop())` printed the pointer.
                        if (self.enumReturnedBy(cc)) |en| if (self.enums.get(en)) |variants| return enumHasPayload(variants);
                        return false;
                    }
                    if (receiverName(cc)) |rcv| {
                        if (self.enums.get(rcv)) |variants| return enumHasPayload(variants);
                    }
                    if (self.enumOfVariant(cc.callee)) |en| {
                        if (self.enums.get(en)) |variants| return enumHasPayload(variants);
                    }
                    return false;
                },
                else => return false,
            },
            .identifier => |id| switch (id.kind) {
                .identAccess => |ia| {
                    const ename = switch (ia.receiver.*) {
                        .identifier => |rid| switch (rid.kind) {
                            .ident => |n| n,
                            else => return false,
                        },
                        else => return false,
                    };
                    const variants = self.enums.get(ename) orelse return false;
                    for (variants) |v| if (std.mem.eql(u8, v.name, ia.member)) return enumHasPayload(variants);
                    return false;
                },
                else => return false,
            },
            else => return false,
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
        // A behavior literal's method — a field whose lambda takes `self`
        // first — is called on the literal (`g.greet(who)`), so the call
        // passes the receiver as that parameter (`lowerValueCall`).
        for (rl.fields) |f| {
            const v = f.value.*;
            if (v != .function or v.function.kind.syntax != .lambda) continue;
            const key = try std.fmt.allocPrint(ra, "{s}.{s}", .{ name, f.name });
            try self.field_lambdas.put(self.alloc, key, .{ .params = v.function.kind.params, .body = v.function.kind.body });
            if (v.function.kind.params.len > 0 and std.mem.eql(u8, v.function.kind.params[0], "self"))
                try self.self_method_fields.put(self.alloc, key, {});
        }
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
        self.eq_local_types.clearRetainingCapacity();
        self.bound_names.clearRetainingCapacity();
        self.field_closures.clearRetainingCapacity();
        self.ctor_lambdas.clearRetainingCapacity();
        self.shadow_log.clearRetainingCapacity();
        self.local_types.clearRetainingCapacity();
        self.str_locals.clearRetainingCapacity();
        self.arr_locals.clearRetainingCapacity();
        self.print_shape_locals.clearRetainingCapacity();
        self.arr_elem_locals.clearRetainingCapacity();
        self.arr_elem_recs.clearRetainingCapacity();
        self.result_shape_locals.clearRetainingCapacity();
        self.result_subjects.clearRetainingCapacity();
        self.aliases.clearRetainingCapacity();
        self.pattern_locals.clearRetainingCapacity();
        self.local_typerefs.clearRetainingCapacity();
        self.opt_locals.clearRetainingCapacity();
        self.narrowed_opts.clearRetainingCapacity();
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
        self.gen_end = null;
        self.block_ret = null;
        self.loop_depth = 0;
        self.tail_self = null;
        self.tail_self_used = false;
    }

    /// Register a local for the current function. Idempotent, and the *only*
    /// way a `(local …)` reaches the output: the declaration goes into the
    /// function node, which is the one place WAT accepts it.
    /// The local a `val` / `var` (or a loop's, a HOF's binder) named `name`
    /// binds: `name` itself, or a fresh `<name>__sh<n>` when a parameter or a
    /// binding of an enclosing, still open statement list holds it — a
    /// sibling block's binding has ended and its local is reused, as before. One function is one wasm local
    /// namespace, so an inner block's `val x = 2` wrote the outer `$x`, and
    /// `x` after the block read `2` at exit 0 where node answers the outer
    /// value (decision 152: a block is a new scope).
    fn bindTarget(self: *Emitter, name: []const u8) ![]const u8 {
        const ra = self.reg_arena.allocator();
        if (!self.bound_names.contains(name) and !self.isParamLocal(name)) {
            try self.bound_names.put(ra, name, {});
            try self.shadow_log.append(ra, .{ .name = name, .prev = null, .aliased = false });
            return name;
        }
        const alias = try std.fmt.allocPrint(ra, "{s}__sh{d}", .{ name, self.shadow_seq });
        self.shadow_seq += 1;
        return alias;
    }

    /// `bindTarget` for a binder of wasm type `ty`: a name the function
    /// already declared with another type (`xs.map({ x -> x * 3.0 })` then
    /// `[1, 2].map({ x -> x + 1 })`) is a local of its own — one wasm local
    /// has one type, and the second walk stored an `i32` into the `f64`.
    fn bindTargetAs(self: *Emitter, name: []const u8, ty: []const u8) ![]const u8 {
        const t = try self.bindTarget(name);
        const have = self.locals.get(t) orelse return t;
        if (std.mem.eql(u8, have, ty)) return t;
        const ra = self.reg_arena.allocator();
        const alias = try std.fmt.allocPrint(ra, "{s}__sh{d}", .{ name, self.shadow_seq });
        self.shadow_seq += 1;
        return alias;
    }

    /// After the binding's value is lowered — `val x = x + 1` reads the outer
    /// `x` — the name means the alias until its statement list ends.
    fn installShadow(self: *Emitter, name: []const u8, target: []const u8) void {
        if (std.mem.eql(u8, name, target)) return;
        self.shadow_log.append(self.reg_arena.allocator(), .{ .name = name, .prev = self.aliases.get(name), .aliased = true }) catch return;
        self.aliases.put(name, target) catch {};
    }

    /// A parameter is in `locals` without a `pending_locals` declaration.
    fn isParamLocal(self: *Emitter, name: []const u8) bool {
        if (!self.locals.contains(name)) return false;
        for (self.pending_locals.items) |l| if (std.mem.eql(u8, l.name, name)) return false;
        return true;
    }

    /// An arm's pattern binders alias names only for the arm: the aliases are
    /// put back as they were before it — a block's re-binding around the
    /// `case` stays (clearing them all lost it).
    fn restoreAliases(self: *Emitter, saved: std.StringHashMap([]const u8)) void {
        self.aliases.deinit();
        self.aliases = saved;
    }

    fn scopeMark(self: *Emitter) usize {
        return self.shadow_log.items.len;
    }

    /// The end of a statement list: every name it re-bound means what it
    /// meant before the list again.
    fn scopeRestore(self: *Emitter, mark: usize) void {
        while (self.shadow_log.items.len > mark) {
            const sh = self.shadow_log.pop().?;
            if (!sh.aliased) {
                _ = self.bound_names.remove(sh.name);
            } else if (sh.prev) |p| self.aliases.put(sh.name, p) catch {} else _ = self.aliases.remove(sh.name);
        }
    }

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
    fn bindParamDestructure(self: *Emitter, p: ast.Param, symbol: []const u8, loc: ast.Loc) !void {
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
            .list, .ctor => return self.refuse(loc, "the wasm backend has no lowering for a list or a constructor pattern in the parameter `{s}`", .{p.name}),
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
                // A parameter carries no location of its own: the body's first
                // statement stands for the signature.
                const loc: ast.Loc = if (body.len > 0) body[0].expr.getLoc() else f.returnTypeLoc;
                try self.bindParamDestructure(p, try self.paramSymbol(p, i), loc);
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

    /// A `declare fn` decision 238's vocabulary binds: the form, and for
    /// `fn:` the name the private fn is emitted under (a linked module's
    /// function may be mangled, `<module>/<name>`).
    const HostBound = struct { binding: hostBinding.Binding, target: []const u8 = "" };

    /// Decision 238 — every `#[@External.Wasm("…")]` of the program and its
    /// linked modules is read before anything is registered: `op:` against
    /// the opcode table and the signature, `fn:` against the declaring
    /// module's own functions (a private bodied `fn` with the same
    /// parameter and return types), `wasi:` against the adapter list. A
    /// binding outside the vocabulary is refused at its annotation, in a
    /// linked module at the consumer's import (`foreign_origin`). A
    /// `declare fn` with no wasm binding is left to `external_missing`.
    fn checkHostBindings(
        self: *Emitter,
        decls: []const ast.DeclKind,
        owner: []const usize,
        linked: []const Linked,
        own_program: ast.Program,
        module_name: []const u8,
    ) !void {
        defer self.foreign_origin = null;
        for (decls, owner) |d, from| {
            const f = switch (d) {
                .@"fn" => |f| f,
                else => continue,
            };
            if (!f.isDeclare or f.body.len > 0) continue;
            // Decision 334: every wasm binding is read and checked, whichever
            // host it serves — a misspelt `.Browser` binding is refused on a
            // `wasi` build too —, and the one serving this build's host is
            // the one recorded.
            const build_host = ast.ExternalLookup.of(self.external_lookup).host orelse .wasi;
            for (f.annotations) |a| {
                if (!std.mem.startsWith(u8, a.name, "External.") or !std.ascii.eqlIgnoreCase(a.name["External.".len..], "Wasm")) continue;
                const host: ?ast.WasmHost = if (ast.hostArgIndex(a)) |at| ast.WasmHost.ofArg(a.args[at]) else null;
                const ext = ast.externalRefOf(a, (host orelse build_host).lookupName()) orelse continue;
                const bound = try self.checkHostBinding(f, from, ext, a.loc, linked, own_program, module_name);
                if (host == null or host.? == build_host) try self.host_bindings.put(self.alloc, f.name, bound);
            }
        }
    }

    /// One `#[@External.Wasm(…)]` of `f`, read and checked (decision 238's
    /// three forms); `from` indexes `linked` for a linked module's `fn`.
    fn checkHostBinding(
        self: *Emitter,
        f: ast.FnDecl,
        from: usize,
        ext: ast.ExternalRef,
        ann_loc: ?ast.Loc,
        linked: []const Linked,
        own_program: ast.Program,
        module_name: []const u8,
    ) !HostBound {
        const ar = self.arena();
        self.foreign_origin = if (from < linked.len) linked[from].via else null;
        if (ext.module.len > 0)
            return self.refuse(ann_loc, "`#[@External.Wasm(…)]` on `{s}` takes one string — `op:<opcode>`, `fn:<private fn of this module>` or `wasi:<adapter>`", .{f.name});
        var slots: std.ArrayListUnmanaged(?hostBinding.Slot) = .empty;
        for (f.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            try slots.append(ar, slotOf(p.typeRef));
        }
        const rslot: ?hostBinding.Slot = if (f.returnType) |rt| slotOf(rt) else null;
        const result_other = if (f.returnType) |rt| rslot == null and !isNamedTypeRef(rt, "void") else false;
        const parsed = try hostBinding.parse(ar, ext.symbol, .{ .params = slots.items, .result = rslot, .result_other = result_other });
        const binding = switch (parsed) {
            .refused => |r| return self.refuse(ann_loc, "{s} (on `{s}`)", .{ r.message, f.name }),
            .ok => |b| b,
        };
        var bound: HostBound = .{ .binding = binding };
        if (binding == .fn_) {
            const name = binding.fn_;
            const prog = if (from < linked.len) linked[from].program else own_program;
            const mod_name = if (from < linked.len) linked[from].name else module_name;
            switch (try hostFnBinding.resolve(ar, f, name, prog, if (from < linked.len) mod_name else "", "Wasm")) {
                .refused => |message| return self.refuse(ann_loc, "{s}", .{message}),
                .ok => {},
            }
            bound.target = if (from < linked.len)
                (self.link_mangled.get(try linkKey(ar, mod_name, name)) orelse name)
            else
                name;
        }
        return bound;
    }

    /// The numeric slot a written type spells for decision 238's checks;
    /// null for any other type.
    fn slotOf(t: ast.TypeRef) ?hostBinding.Slot {
        return switch (eagerTypeRef(t)) {
            .named => |n| inline for (.{ "i32", "i64", "f32", "f64", "bool" }) |k| {
                if (std.mem.eql(u8, n, k)) break @field(hostBinding.Slot, k);
            } else null,
            else => null,
        };
    }

    /// The function a bound `declare fn` lowers to — its declared name and
    /// signature (`registerFn` registered both), the parameters passed in
    /// order: `op:` applies the instruction to them, `fn:` calls the private
    /// fn, `wasi:` calls the adapter's prelude helper.
    fn emitHostBinding(self: *Emitter, f: ast.FnDecl, hb: HostBound) !void {
        const ar = self.arena();
        const sig = self.fn_sigs.get(f.name).?;
        var params: std.ArrayListUnmanaged(wat.Param) = .empty;
        var lines: std.ArrayListUnmanaged(wat.Line) = .empty;
        var i: usize = 0;
        for (f.params, 0..) |p, k| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            const sym = try self.paramSymbol(p, k);
            try params.append(ar, wat.Builder.param(sym, vt(sig.params[i])));
            try lines.append(ar, .{ .indent = 4, .instr = .{ .local_get = sym } });
            i += 1;
        }
        const call: wat.Instr = switch (hb.binding) {
            .op => |op| hostBinding.instrOf(op),
            .fn_ => .{ .call = hb.target },
            .wasi => |ad| blk: {
                if (std.mem.eql(u8, ad.name, "random_f64")) break :blk self.builder().helper(.wasi_random_f64);
                if (std.mem.eql(u8, ad.name, "seed_u32")) break :blk self.builder().helper(.wasi_seed_u32);
                if (std.mem.eql(u8, ad.name, "seeded_f64")) break :blk self.builder().helper(.wasi_seeded_f64);
                unreachable; // every listed adapter has its helper (`host_binding.zig` `adapters`)
            },
        };
        try lines.append(ar, .{ .indent = 4, .instr = call });
        const result: ?ValType = if (sig.result) |r| vt(r) else null;
        // A written `-> void` registers an `i32` result like every function
        // declaring one (`fnHasResult`); an adapter answering nothing
        // (`seed_u32`) leaves the stack empty, so the wrapper answers the 0
        // the caller drops.
        const yields = switch (hb.binding) {
            .wasi => |ad| ad.result != null,
            else => true,
        };
        if (result != null and !yields) try lines.append(ar, .{ .indent = 4, .instr = constOf(@tagName(result.?), "0") });
        try self.itemCommentF("{s} — #[@External.Wasm(\"{s}\")]", .{ f.name, f.externalFor(self.external_lookup).?.symbol });
        try self.item(.{ .func = try self.builder().func(.{
            .name = f.name,
            .exports = if (f.isPub) try ar.dupe([]const u8, &.{f.name}) else &.{},
            .params = params.items,
            .result = result,
            .locals = &.{},
            .body = .{ .stack = if (result) |r| .{ .value = r } else .none, .lines = lines.items },
        }) });
    }

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        // A bodyless `declare fn` (host-backed FFI, `#[@External.…]`) has no
        // wasm implementation. Emitting `(func $f (result f64))` with an empty
        // body is invalid, so skip it entirely — a call of it is refused
        // (`lowerPlainCall`).
        if (self.host_bindings.get(f.name)) |hb| return self.emitHostBinding(f, hb);
        if (f.isDeclare or f.body.len == 0) {
            try self.itemCommentF("declare fn {s} — no wasm implementation (host-backed)", .{f.name});
            return;
        }
        const has_result = fnHasResult(f);
        self.resetFnState(if (has_result) watTypeOpt(f.returnType) else null);
        self.fn_tparams = f.genericParams;
        defer self.fn_tparams = &.{};
        const outer_template = self.cur_template;
        self.cur_template = if (!self.in_spec and f.genericParams.len > 0) f.name else null;
        defer self.cur_template = outer_template;
        self.fn_returns_result = (f.effect != null and f.effect.? == .result) or
            (if (f.returnType) |rt| resultShapeOfTypeRef(rt) != null else false);

        // An effect fn is async/generator — except `-> @Result` (the
        // checked-Result value), which is a plain function. WASM is
        // single-threaded and eager here: a `@Task<T>` is `T` (`await` is
        // identity, decision 120); full generator state-machine lowering is
        // not yet implemented. `-> @Component` is a plain function too
        // (decision 88: it gates `use`).
        if (f.effect != null and f.effect.? != .result and f.effect.? != .component) {
            try self.itemComment(switch (f.effect.?) {
                .task => "@Task — eager lowering",
                .iterator => "@Iterator — eager lowering",
                else => "@Stream — eager lowering",
            });
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

        // An `@Iterator` / `@Stream` body runs eagerly: every `yield` is
        // appended to one array, which is what the fn returns.
        const accumulates = if (f.effect) |e|
            (e == .iterator or e == .stream) and has_result and bodyYieldsDeep(f.body)
        else
            false;
        if (!accumulates) try self.noteSelfTailCalls(f);
        const rendered = if (accumulates) try self.renderAccumulatingBody(f.body) else try self.renderBody(f.body, f);
        const body = if (self.tail_self_used) try self.wrapTailLoop(rendered) else rendered;

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
        self.fn_tparams = m.genericParams;
        defer self.fn_tparams = &.{};
        const outer_template = self.cur_template;
        self.cur_template = if (!self.in_spec and (m.genericParams.len > 0 or self.owner_tparams.len > 0))
            try std.fmt.allocPrint(self.reg_arena.allocator(), "{s}_{s}", .{ owner, m.name })
        else
            null;
        defer self.cur_template = outer_template;
        const has_result = m.returnType != null or methodHasResult(body);
        const result_ty: []const u8 = if (m.returnType) |rt| memberValType(rt) else "i32";
        self.resetFnState(if (has_result) result_ty else null);
        // What `return v` coerces to — a `-> ?i32` method boxes its scalar,
        // as a fn does (`emitFn`). Unset here, `Registry.at` returned the bare
        // index and its reader loaded through it as a box (`16777216` for `1`).
        self.cur_ret_typeref = m.returnType;
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
            try self.locals.put(sym, memberValType(p.typeRef));
            if (std.mem.eql(u8, p.name, "self")) {
                if (self.self_type) |st| try self.local_types.put("self", st);
                // A primitive default's copy (`lowerPrimDefault`) writes
                // `self: string`: the receiver's shape.
                if ((p.typeRef == .named and primKindOfName(p.typeRef.named) != null) or (p.typeRef == .array and self.self_type == null)) {
                    try self.noteParamShape("self", p.typeRef);
                    try self.local_typerefs.put("self", p.typeRef);
                }
            } else {
                const tn = typeRefName(p.typeRef);
                if (self.resolveRecordName(tn)) |rty|
                    try self.local_types.put(sym, rty);
                try self.noteParamShape(sym, p.typeRef);
                // In a copy the written type is concrete (`ys: i32[]` for
                // `Self<T>`): `primKindAt` reads it for a method on the param.
                if (self.in_spec) try self.local_typerefs.put(sym, p.typeRef);
            }
        }
        try self.declareScratch("_try", countTrys(body));
        try self.declareScratch("__mem", self.countMems(body));
        try self.emitLocalDecls(body);

        // A method declared `-> @Iterator<T>` / `-> @Stream<T>` runs eagerly
        // like a fn does (`emitFn`): every `yield` is appended to one array,
        // which is what it returns. Rendered as a plain body, each `yield` was
        // dropped and the method answered `0` — or whatever its last
        // statement left.
        const seq = if (has_result and methodYieldsEagerly(m) and bodyYieldsDeep(body))
            try self.renderAccumulatingBody(body)
        else
            try self.renderBody(body, null);

        const ar = self.arena();
        var params: std.ArrayListUnmanaged(wat.Param) = .empty;
        if (needs_self) try params.append(ar, wat.Builder.param("self", .i32));
        for (m.params, 0..) |p, i| {
            try params.append(ar, wat.Builder.param(try self.paramSymbol(p, i), vt(memberValType(p.typeRef))));
        }
        try self.item(.{ .func = try self.builder().func(.{
            .name = try std.fmt.allocPrint(ar, "{s}_{s}", .{ owner, m.name }),
            .params = params.items,
            .result = if (has_result) vt(result_ty) else null,
            .locals = try self.localLines(),
            .body = seq,
        }) });
    }

    /// A method whose declared return is an `@Iterator<T>` / `@Stream<T>` —
    /// what `FnDecl.effect` says for a fn (a method carries no effect field).
    fn methodYieldsEagerly(m: ast.BehaviorMethod) bool {
        const rt = m.returnType orelse return false;
        return switch (rt) {
            .generic => |g| g.is_builtin and (std.mem.eql(u8, g.name, "Iterator") or std.mem.eql(u8, g.name, "Stream")),
            else => false,
        };
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
            // `case (self) { … }` in an enum's method — the subject and every
            // arm. Missed, the method got no `$self` and read `0` for it.
            .collection => |col| switch (col.kind) {
                .case => |cs| blk: {
                    for (cs.subjects) |sub| if (exprReferencesSelf(sub)) break :blk true;
                    for (cs.arms) |arm| {
                        if (exprReferencesSelf(arm.body)) break :blk true;
                        if (arm.guard) |g| if (exprReferencesSelf(g)) break :blk true;
                    }
                    break :blk false;
                },
                .grouped => |inner| exprReferencesSelf(inner.*),
                else => false,
            },
            .function => |f| bodyReferencesSelf(f.kind.body),
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
        // A variant reached through its enum (`__Token__Layout.Size(…)`, what a
        // section path desugars to) is that enum's, even when a record of the
        // same name is in scope (`type Size(px: i32)`): it used to build the
        // record, and `.Layout.Size.Large` answered the section's first arm.
        if (receiverName(cc)) |rcv| if (self.enums.get(rcv)) |vs| {
            for (vs) |v| if (std.mem.eql(u8, v.name, cc.callee)) return .enum_ctor;
        };
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
        // A bare or dot-shorthand arm (`Red`, `.After`) over a subject whose
        // enum is known is that enum's variant (§5.1 P8). Searched through one
        // flat table, the first enum declaring the name answered: `case c {
        // Red -> … }` over a `Cool` tested `Warm.Red`'s tag, and a section
        // leaf `Layout.Break.After` was taken for `Token.After(inner)`.
        if (ename.len == 0) if (self.case_enum_hint) |hint| if (self.enums.get(hint)) |variants| {
            for (variants, 0..) |v, i| {
                if (std.mem.eql(u8, v.name, bare))
                    return .{ .variants = variants, .tag = @intCast(i), .variant = v };
            }
        };
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
                        // A re-binding of a name already declared here is a
                        // local of its own (`bindTarget`), registered when it
                        // is lowered: registering its shape under the shared
                        // name here marked the OUTER `x` a string too.
                        if (self.locals.contains(lb.name)) {
                            try self.declareNestedLocals(lb.value.*);
                            continue;
                        }
                        // An `unknown` / union slot holds the box's pointer,
                        // whatever the value's own shape.
                        if (lb.typeAnnotation) |ta| if (isUnknownTypeRef(ta)) {
                            try self.local_typerefs.put(lb.name, ta);
                            try self.declareLocal(lb.name, "i32");
                            try self.declareNestedLocals(lb.value.*);
                            continue;
                        };
                        const t = self.bindingLocalType(lb.typeAnnotation, lb.value.*);
                        // A cell optional (`?f64`, `?i64`) is known before the
                        // body is lowered, so a binder over it is declared
                        // the cell's width.
                        if (lb.typeAnnotation) |ta| if (self.optInfoOfTypeRef(ta)) |oi| if (oi.cell != .none) try self.opt_locals.put(lb.name, oi);
                        if (lb.typeAnnotation == null) if (self.optInfoOf(lb.value.*)) |oi| if (oi.cell != .none) try self.opt_locals.put(lb.name, oi);
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
                                    var cell: Cell = .none;
                                    if (recv_rty) |rty| {
                                        if (self.fieldTypeIn(rty, fld.field_name)) |ft| {
                                            if (self.resolveRecordName(ft)) |sub|
                                                try self.local_types.put(fld.bind_name, sub);
                                            cell = fieldCellOf(ft);
                                        }
                                    }
                                    try self.declareLocal(fld.bind_name, cell.ty());
                                }
                            },
                            .tuple_ => |bindings| {
                                for (bindings, 0..) |name, i| {
                                    try self.declareLocal(name, (try self.tupleElemCell(lb.value.*, i)).ty());
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
                    // `if (opt) { v -> … }` binds the narrowed value to `v`:
                    // a `?f64`'s / `?i64`'s is what its cell holds.
                    if (i.binding) |name| {
                        const cell: Cell = if (self.optInfoOf(i.cond.*)) |o| o.cell else .none;
                        try self.declareLocal(name, cell.ty());
                    }
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
                // A walk over a float array binds its element as the `f64`
                // its slot's cell holds (`lowerCollectionLoop`); a range or an
                // index is an i32.
                const is_range = lp.iter.* == .collection and lp.iter.collection.kind == .range;
                for (lp.params, 0..) |p, i| {
                    const float_elem = i == 0 and !is_range and self.isArrayExpr(lp.iter.*) and self.elemKindOf(lp.iter.*) == .f64;
                    try self.declareLocal(p, if (float_elem) "f64" else "i32");
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

    /// The wasm type of a `val`/`var`'s local: what a written type says, when
    /// it says one — a `?T` is the `i32` of its box or pointer, a number the
    /// width it names (`val a: i64 = 4294967295` is an `i64`, `val o: ?f64 =
    /// 1.1` the address of a cell) — and the value's own type otherwise.
    fn bindingLocalType(self: *Emitter, ann: ?ast.TypeRef, value: ast.Expr) []const u8 {
        if (ann) |ta| switch (ta) {
            .optional => return "i32",
            .named => |n| if (isScalarName(n)) return watType(ta),
            else => {},
        };
        return self.inferExprType(value);
    }

    fn emitGlobalVal(self: *Emitter, v: ast.ValDecl) !void {
        const t = self.globalValType(v);
        if (self.boxesInto(v.typeAnnotation, v.value.*)) {
            try self.item(.{ .global = .{ .name = v.name, .ty = .i32, .mutable = true, .init = "0" } });
            try self.deferred_globals.append(self.alloc, v);
            try self.deferred_renames.append(self.alloc, self.global_renames);
            return;
        }
        // A `var` (front 17 step 2) is a mutable global on every path: the two
        // constant paths below declared an immutable one, which `global.set`
        // does not validate against.
        if (self.folded_globals.get(v.name)) |text| {
            if (isNumericLiteral(text)) {
                try self.item(.{ .global = .{ .name = v.name, .ty = vt(t), .mutable = v.mutable, .init = try numeralText(self.arena(), text) } });
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
                        .mutable = v.mutable,
                        .init = try numeralText(self.arena(), n),
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
        try self.deferred_renames.append(self.alloc, self.global_renames);
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
        for (self.deferred_globals.items, self.deferred_renames.items) |v, renames| {
            self.global_renames = renames;
            defer self.global_renames = null;
            if (self.deferred_stmts.contains(v.name)) {
                _ = try self.emitStmt(.{ .expr = v.value.* }, false);
                continue;
            }
            if (self.boxesInto(v.typeAnnotation, v.value.*))
                try self.lowerBoxedInto(v.typeAnnotation, v.value.*)
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
        if (radixOf(n)) |r| return radixValue(n, r) != null;
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
            if (isNumericLiteral(text)) return numLitType(text);
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

    /// `$__display_of(v) -> i32`: the string a record's own `display(self)
    /// -> string` answers for `v`, or `0` when `v`'s type declares none — the
    /// hook `$__print_tagged_raw` calls first. Null when no record qualifies:
    /// the prelude's `display_of` group (`0`) is then the module's answer. One compare per record type that
    /// has both a descriptor (some value of it was built) and a `display`
    /// method: `v` is a pointer past the data floor and the header four bytes
    /// behind it is that type's descriptor. A dispatch written after lowering,
    /// not a table index interned into the descriptor, because table indices
    /// are handed out as lambdas are lifted and would shift under it.
    fn displayDispatch(self: *Emitter) !?wat.Func {
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = self.records.keyIterator();
        while (it.next()) |k| try names.append(self.arena(), k.*);
        std.mem.sort([]const u8, names.items, {}, struct {
            fn lt(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.lessThan(u8, a, b);
            }
        }.lt);
        var c: Capture = .{};
        self.open(&c);
        var any = false;
        for (names.items) |rec| {
            const desc = self.type_descs.get(rec) orelse continue;
            const sym = try std.fmt.allocPrint(self.arena(), "{s}_display", .{rec});
            const sig = self.fn_sigs.get(sym) orelse continue;
            if (sig.params.len != 1 or sig.result == null) continue;
            any = true;
            var hit: Capture = .{};
            self.open(&hit);
            try self.emit(.{ .local_get = "v" });
            try self.emit(.{ .call = sym });
            try self.emit(.@"return");
            const hit_seq = self.seal(&hit, .terminated);
            var guard: Capture = .{};
            self.open(&guard);
            try self.emit(.{ .local_get = "v" });
            try self.emit(.{ .@"const" = .{ .ty = .i32, .text = "4" } });
            try self.emit(opOf("i32", "sub"));
            try self.emit(.{ .load = .{} });
            try self.emit(try self.constInt(desc));
            try self.emit(opOf("i32", "eq"));
            try self.emitC(.{ .@"if" = .{ .then = .{ .seq = hit_seq } } }, rec);
            const guard_seq = self.seal(&guard, .none);
            try self.emit(.{ .local_get = "v" });
            try self.emit(.{ .@"const" = .{ .ty = .i32, .text = "256" } });
            try self.emit(opOf("i32", "ge_u"));
            try self.emit(.{ .@"if" = .{ .then = .{ .seq = guard_seq } } });
        }
        try self.emit(.{ .@"const" = .{ .ty = .i32, .text = "0" } });
        const body = self.seal(&c, .{ .value = .i32 });
        // No type declares `display`: the prelude's form (`0`) is the answer.
        if (!any) return null;
        return try self.builder().func(.{
            .name = "__display_of",
            .params = &.{wat.Builder.param("v", .i32)},
            .result = .i32,
            .body = body,
        });
    }

    /// The types that may answer `method` with `argc` arguments: every record
    /// and enum of the (linked) module declaring `<Type>_<method>` taking the
    /// receiver and `argc` more, sorted so two runs emit the same module.
    fn behaviorImplementers(self: *Emitter, method: []const u8, argc: usize) ![]const []const u8 {
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var rit = self.records.keyIterator();
        while (rit.next()) |k| try names.append(self.arena(), k.*);
        var eit = self.enums.keyIterator();
        while (eit.next()) |k| try names.append(self.arena(), k.*);
        std.mem.sort([]const u8, names.items, {}, struct {
            fn lt(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.lessThan(u8, a, b);
            }
        }.lt);
        var out: std.ArrayListUnmanaged([]const u8) = .empty;
        for (names.items) |t| {
            const sym = try std.fmt.allocPrint(self.arena(), "{s}_{s}", .{ t, method });
            const sig = self.fn_sigs.get(sym) orelse continue;
            if (sig.params.len != argc + 1) continue;
            try out.append(self.arena(), t);
        }
        return out.items;
    }

    /// `recv.method(…)` where `recv` is typed by a `behavior`: no declaration
    /// is known at the call, so the VALUE answers — its header names its type,
    /// and `$__bdispatch_<method>_<n>` calls that type's `<Type>_<method>`.
    /// It trapped (`unresolved call`) where commonJS, erlang and beam
    /// dispatched. False when no type of the module declares the method.
    fn lowerBehaviorDispatch(self: *Emitter, cc: anytype) anyerror!bool {
        const impls = try self.behaviorImplementers(cc.callee, cc.args.len);
        if (impls.len == 0) return false;
        const first = try std.fmt.allocPrint(self.arena(), "{s}_{s}", .{ impls[0], cc.callee });
        const sig = self.fn_sigs.get(first).?;
        // The dispatcher tells implementers apart by the descriptor in the
        // value's header and calls each through one signature. A variant of
        // an all-unit enum is its bare ordinal (no header), and an
        // implementer whose method takes or answers something else cannot
        // be called from the dispatcher: a value of either would reach the
        // dispatcher's end at run time, so the call is refused here.
        for (impls) |t| {
            const gsym = try std.fmt.allocPrint(self.arena(), "{s}_{s}", .{ t, cc.callee });
            if (self.generic_methods.contains(gsym)) try self.noteTemplateCall(gsym, self.call_loc);
            if (self.enums.get(t)) |variants| if (!enumHasPayload(variants))
                return self.refuse(self.call_loc, "the wasm backend cannot dispatch `.{s}` by value: `{s}` is an all-unit enum, whose values carry no header naming their type", .{ cc.callee, t });
            const isym = try std.fmt.allocPrint(self.arena(), "{s}_{s}", .{ t, cc.callee });
            if (!sameSig(self.fn_sigs.get(isym).?, sig))
                return self.refuse(self.call_loc, "the wasm backend cannot dispatch `.{s}` by value: `{s}` and `{s}` declare it with different wasm signatures", .{ cc.callee, impls[0], t });
        }
        const sym = try std.fmt.allocPrint(self.reg_arena.allocator(), "__bdispatch_{s}_{d}", .{ cc.callee, cc.args.len });
        if (!self.behavior_dispatch.contains(sym)) try self.behavior_dispatch.put(self.reg_arena.allocator(), sym, .{
            .method = try self.reg_arena.allocator().dupe(u8, cc.callee),
            .argc = cc.args.len,
            .sig = sig,
        });
        try self.lowerCoerced(cc.receiver.?.*, "i32");
        try self.lowerCallArgs(cc.args, sig, 1);
        try self.emit(.{ .call = sym });
        return true;
    }

    /// `$__bdispatch_<method>_<n>(self, a0, …)`: one header compare per
    /// descriptor of each implementer (a record's, or each variant's of a
    /// payload enum) that some value of the module was built with, calling
    /// that type's method. The chain ends in `unreachable`, which no value
    /// reaches: `lowerBehaviorDispatch` refused the call when an implementer
    /// has no header (an all-unit enum) or another signature. Written after
    /// lowering, as `$__display_of` is, because a descriptor exists only once
    /// a value of its type was built.
    fn behaviorDispatchFunc(self: *Emitter, bd: BehaviorDispatch) !wat.Func {
        const impls = try self.behaviorImplementers(bd.method, bd.argc);
        var params: std.ArrayListUnmanaged(wat.Param) = .empty;
        try params.append(self.arena(), wat.Builder.param("self", .i32));
        var arg_names: std.ArrayListUnmanaged([]const u8) = .empty;
        for (0..bd.argc) |i| {
            const n = try std.fmt.allocPrint(self.arena(), "a{d}", .{i});
            try arg_names.append(self.arena(), n);
            try params.append(self.arena(), wat.Builder.param(n, vt(bd.sig.params[i + 1])));
        }
        var c: Capture = .{};
        self.open(&c);
        for (impls) |t| {
            const sym = try std.fmt.allocPrint(self.arena(), "{s}_{s}", .{ t, bd.method });
            const sig = self.fn_sigs.get(sym).?;
            // An implementer whose method does not take and answer what the
            // dispatcher does cannot be called from it.
            if (!sameSig(sig, bd.sig)) continue;
            var descs: std.ArrayListUnmanaged(u32) = .empty;
            if (self.records.contains(t)) {
                if (self.type_descs.get(t)) |d| try descs.append(self.arena(), d);
            } else if (self.enums.get(t)) |variants| {
                for (variants) |v| {
                    const key = try std.fmt.allocPrint(self.arena(), "{s}.{s}", .{ t, v.name });
                    if (self.type_descs.get(key)) |d| try descs.append(self.arena(), d);
                }
            }
            for (descs.items) |d| {
                var hit: Capture = .{};
                self.open(&hit);
                try self.emit(.{ .local_get = "self" });
                for (arg_names.items) |n| try self.emit(.{ .local_get = n });
                try self.emit(.{ .call = sym });
                try self.emit(.@"return");
                const hit_seq = self.seal(&hit, .terminated);
                var guard: Capture = .{};
                self.open(&guard);
                try self.emit(.{ .local_get = "self" });
                try self.emit(try self.constInt(tag_header_bytes));
                try self.emit(opOf("i32", "sub"));
                try self.emit(.{ .load = .{} });
                try self.emit(try self.constInt(d));
                try self.emit(opOf("i32", "eq"));
                try self.emitC(.{ .@"if" = .{ .then = .{ .seq = hit_seq } } }, t);
                const guard_seq = self.seal(&guard, .none);
                try self.emit(.{ .local_get = "self" });
                try self.emit(try self.constInt(heap_floor));
                try self.emit(opOf("i32", "ge_u"));
                try self.emit(.{ .@"if" = .{ .then = .{ .seq = guard_seq } } });
            }
        }
        try self.emitC(.@"unreachable", "no implementer of this behavior method built the value");
        const body = self.seal(&c, .terminated);
        return try self.builder().func(.{
            .name = try std.fmt.allocPrint(self.arena(), "__bdispatch_{s}_{d}", .{ bd.method, bd.argc }),
            .params = params.items,
            .result = if (bd.sig.result) |r| vt(r) else null,
            .body = body,
        });
    }

    /// Whether a method call at `loc` is answered by its receiver's own type
    /// at run time: inference placed it on a behavior-typed value, named a
    /// type this module declares no record or enum of (the behavior itself),
    /// or placed it nowhere.
    fn dispatchesByValue(self: *Emitter, loc: ast.Loc) bool {
        const il = self.instance_lowerings.get(loc) orelse return true;
        return switch (il) {
            .by_value => true,
            .type_, .unplaced_type => |tn| !self.records.contains(tn) and !self.enums.contains(tn),
            else => false,
        };
    }

    fn sameSig(a: FnSig, b: FnSig) bool {
        if (a.params.len != b.params.len) return false;
        for (a.params, b.params) |x, y| if (!std.mem.eql(u8, x, y)) return false;
        if (a.result == null or b.result == null) return a.result == null and b.result == null;
        return std.mem.eql(u8, a.result.?, b.result.?);
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
        const scope_mark = self.scopeMark();
        defer self.scopeRestore(scope_mark);
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
        const outer_loc = self.stmt_loc;
        self.stmt_loc = stmt.expr.getLoc();
        defer self.stmt_loc = outer_loc;
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
                    if (self.block_ret) |br| {
                        try self.emitBlockReturn(br, if (r) |val| val.* else null);
                        return .terminated;
                    }
                    if (r) |val| if (try self.lowerSelfTailCall(val.*)) return .terminated;
                    if (r) |val| {
                        // Coerce to the *declared* result: `fn area(…) -> f64`
                        // whose body multiplies f32 literals produced an f32
                        // and the `(result f64)` rejected the whole module.
                        if (val.* == .function) self.expected_fn = self.cur_ret_typeref;
                        if (self.cur_ret_typeref) |rt| if (rt == .generic and self.record_generics.contains(rt.generic.name)) {
                            self.expected_ctor = rt;
                        };
                        defer self.expected_ctor = null;
                        defer self.expected_fn = null;
                        if (self.fn_has_result and self.boxesInto(self.cur_ret_typeref, val.*))
                            try self.lowerBoxedInto(self.cur_ret_typeref, val.*)
                        else if (self.fn_has_result)
                            try self.lowerCoerced(val.*, self.cur_result)
                        else {
                            // A `return <expr>` inside a void function must not
                            // carry a value out of it.
                            try self.lowerValue(val.*);
                            try self.emit(.drop);
                        }
                    } else if (self.fn_has_result) {
                        // A bare `return;` in a function that still has a
                        // `(result …)` — a `@Task<void>` carries a word —
                        // leaves with the neutral value, or the module fails
                        // validation ("expected i32 but nothing on stack").
                        try self.pushZero();
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
                        // Decision 105: `break <v>` in a generator scope
                        // pushes `v` and ends the scope from any loop depth.
                        if (self.yield_target != null) {
                            try self.emitGenBreak(v.*);
                            return .terminated;
                        }
                        try self.lowerValue(v.*);
                        return .value;
                    }
                    if (self.loop_depth > 0) {
                        try self.emit(.{ .br = break_label });
                        return .terminated;
                    }
                    // Decision 103: a bare `break` at a generator body's own
                    // level ends it — nothing after it is emitted.
                    if (self.yield_target != null) {
                        try self.emitGenEnd();
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
                .localBind => |lb0| {
                    // A second binding of a name — a block's `val x` over an
                    // outer `x` (decision 152 keeps that legal: a new scope)
                    // — is a fresh local, aliased until the block ends.
                    var lb = lb0;
                    lb.name = try self.bindTargetAs(lb0.name, self.bindingLocalType(lb0.typeAnnotation, lb0.value.*));
                    defer self.installShadow(lb0.name, lb.name);
                    if (lb.typeAnnotation) |ta| if (isUnknownTypeRef(ta)) {
                        try self.declareLocal(lb.name, "i32");
                        try self.local_typerefs.put(lb.name, ta);
                        if (self.boxesInto(ta, lb.value.*))
                            try self.lowerAsUnknown(lb.value.*)
                        else
                            try self.lowerCoerced(lb.value.*, "i32");
                        try self.emit(.{ .local_set = lb.name });
                        return .none;
                    };
                    try self.declareLocal(lb.name, self.bindingLocalType(lb.typeAnnotation, lb.value.*));
                    // A function NAMED as the value (`val g = greet`) types the
                    // local by its declaration, as a written `fn(…) -> T` does:
                    // `g()` then answers `greet`'s declared return. Without it the
                    // call of a string-returning function printed the string's
                    // address at exit 0.
                    const bound_tr: ?ast.TypeRef = lb.typeAnnotation orelse self.typeRefOf(lb.value.*) orelse try self.fnRefTypeRef(lb.value.*);
                    if (bound_tr) |tr| try self.local_typerefs.put(lb.name, tr);
                    // Decision 210 — the composite a `val` holds, for `==`
                    // over the name (`val t = #(P(x: 1), 2)`).
                    _ = self.eq_local_types.remove(lb.name);
                    if (lb.typeAnnotation == null) if (try self.eqTypeOf(lb.value.*)) |et| if (self.eqComposite(et)) {
                        try self.eq_local_types.put(self.arena(), lb.name, et);
                    };
                    // A written `?T` says the local is optional; how the value
                    // carries its absence (boxed or not) is the VALUE's, so it
                    // is asked too: `val c: ?Color = cs[1]` holds a box around
                    // an all-unit enum's ordinal, and read as the bare ordinal
                    // it compared unequal to `Color.Green` and printed the
                    // box's address.
                    const ann_optional = if (lb.typeAnnotation) |ta| ta == .optional else true;
                    if (ann_optional) if (self.optInfoOf(lb.value.*)) |oi| try self.opt_locals.put(lb.name, oi);
                    // A `?f64` written as such is a cell whatever the value is.
                    if (lb.typeAnnotation) |ta| if (self.optInfoOfTypeRef(ta)) |oi| if (oi.cell != .none) try self.opt_locals.put(lb.name, oi);
                    if (self.isStringExpr(lb.value.*)) try self.str_locals.put(lb.name, {});
                    if (self.isBoolExpr(lb.value.*)) try self.bool_locals.put(lb.name, {});
                    // The written type says it too, where the value cannot: a
                    // generic call (`val s: string = first<string>(…)`) answers
                    // a `T`, whose word printed as an address (`276`).
                    if (lb.typeAnnotation) |ta| if (ta == .named) {
                        if (std.mem.eql(u8, ta.named, "string")) try self.str_locals.put(lb.name, {});
                        if (std.mem.eql(u8, ta.named, "bool")) try self.bool_locals.put(lb.name, {});
                    };
                    try self.noteArrayLocal(lb.name, lb.value.*);
                    // A written array type says what an empty literal cannot:
                    // `var names: string[] = []` holds strings, and read off
                    // `[]` its shape was `[i` — `names.push("a")` printed
                    // `[256]`, the string's address, at exit 0.
                    if (lb.typeAnnotation) |ta| try self.noteAnnotatedArray(lb.name, ta);
                    if (self.resultShapeOf(lb.value.*)) |shape| try self.result_shape_locals.put(lb.name, shape);
                    if (self.recordTypeOfExpr(lb.value.*)) |rty| try self.local_types.put(lb.name, rty);
                    // Coerce to the type the local was *actually* declared with:
                    // `emitLocalDecls` runs before the body, so its guess can
                    // differ from what lowering ends up pushing.
                    const lambda_idx: u32 = @intCast(self.lambdas.items.len);
                    self.ctor_lambdas.clearRetainingCapacity();
                    if (lb.typeAnnotation) |ta| if (ta == .generic and self.record_generics.contains(ta.generic.name)) {
                        self.expected_ctor = ta;
                    };
                    defer self.expected_ctor = null;
                    if (lb.value.* == .function) self.expected_fn = lb.typeAnnotation;
                    defer self.expected_fn = null;
                    // `val f: fn(a: string, b: string) -> bool = same` over a
                    // generic `same`: the copy the written type binds, as an
                    // argument against such a parameter is (`specializeByFnType`).
                    if (lb.typeAnnotation) |ta| if (plainIdentName(lb.value.*)) |vn| if (!self.locals.contains(vn)) {
                        if (try self.specializeByFnType(self.import_aliases.get(vn) orelse vn, ta)) |sym| {
                            try self.lowerFnRef(sym, null);
                            try self.emit(.{ .local_set = lb.name });
                            _ = self.closure_locals.remove(lb.name);
                            return .none;
                        }
                    };
                    if (self.boxesInto(lb.typeAnnotation, lb.value.*))
                        try self.lowerBoxedInto(lb.typeAnnotation, lb.value.*)
                    else
                        try self.lowerCoerced(lb.value.*, self.locals.get(lb.name) orelse "i32");
                    try self.emit(.{ .local_set = lb.name });
                    if (lb.value.* == .function and self.lambdas.items.len > lambda_idx)
                        try self.closure_locals.put(lb.name, lambda_idx)
                    else if (self.fieldClosureOfExpr(lb.value.*)) |li|
                        // `val lf = lam.value` over a constructor-stored lambda.
                        try self.closure_locals.put(lb.name, li)
                    else
                        _ = self.closure_locals.remove(lb.name);
                    // A constructor that stored lambdas: each one by its field —
                    // only when the value IS the constructor call.
                    if (lb.value.* == .call and lb.value.call.kind == .call and lb.value.call.kind.call.receiver == null and self.records.contains(lb.value.call.kind.call.callee)) for (self.ctor_lambdas.items) |cl| {
                        const key = try std.fmt.allocPrint(self.reg_arena.allocator(), "{s}.{s}", .{ lb.name, cl.field });
                        try self.field_closures.put(self.reg_arena.allocator(), key, cl.idx);
                    };
                    self.ctor_lambdas.clearRetainingCapacity();
                },
                .assign => |a| switch (a.target) {
                    // A `var` two linked modules declare is written in the
                    // module the statement is in (`resolveName`).
                    .name => |name0| switch (a.op) {
                        .assign => {
                            const name = self.resolveName(name0);
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
                                try self.lowerBoxedInto(tr, a.value.*)
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
                            const name = self.resolveName(name0);
                            try self.emit(if (self.locals.contains(name))
                                .{ .local_get = name }
                            else
                                .{ .global_get = name });
                            const t = self.locals.get(name) orelse
                                self.global_types.get(name) orelse "i32";
                            try self.lowerCoerced(a.value.*, t);
                            try self.emitArith(t, "add", b.loc);
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
                            // A float field's slot holds its `f64` cell: the
                            // new value is a new cell (`lowerSlotWord`), never
                            // a write into the old one, which another value
                            // may share.
                            .assign => {
                                const cell = fieldCellOf(self.fieldTypeIn(rty_opt.?, fa.field) orelse "");
                                try self.lowerValue(fa.receiver.*);
                                if (cell != .none) try self.lowerCellWord(a.value.*, cell) else try self.lowerValue(a.value.*);
                                try self.emitCf(.{ .store = .{ .offset = off } }, ".{s} =", .{fa.field});
                            },
                            .plusAssign => {
                                const cell = fieldCellOf(self.fieldTypeIn(rty_opt.?, fa.field) orelse "");
                                const mem = try self.memName(self.nextMem());
                                try self.lowerValue(fa.receiver.*);
                                try self.emit(.{ .local_set = mem });
                                try self.emit(.{ .local_get = mem });
                                try self.emit(.{ .local_get = mem });
                                try self.emit(.{ .load = .{ .offset = off } });
                                if (cell != .none) {
                                    try self.emitFromCell(cell);
                                    try self.lowerCoerced(a.value.*, cell.ty());
                                    try self.emitArith(cell.ty(), "add", b.loc);
                                    try self.emit(self.builder().helper(if (cell == .f64) .box_f64 else .box_i64));
                                } else {
                                    try self.lowerCoerced(a.value.*, "i32");
                                    try self.emitArith("i32", "add", b.loc);
                                }
                                try self.emitCf(.{ .store = .{ .offset = off } }, ".{s} +=", .{fa.field});
                            },
                        } else return self.refuse(stmt.expr.getLoc(), "the wasm backend cannot place `.{s} =`: the receiver's type is not known here", .{fa.field});
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
                                // A float or `i64` field holds its cell.
                                if (recv_rty) |rty| try self.emitFromCell(fieldCellOf(self.fieldTypeIn(rty, fld.field_name) orelse ""));
                                // The binder is the field's type, as `.ctor`'s
                                // below: a string field concatenates as text.
                                if (recv_rty) |rty| if (self.fieldTypeIn(rty, fld.field_name)) |ft| {
                                    if (std.mem.eql(u8, ft, "string")) try self.str_locals.put(fld.bind_name, {});
                                    if (std.mem.eql(u8, ft, "bool")) try self.bool_locals.put(fld.bind_name, {});
                                    if (self.resolveRecordName(ft)) |sub| try self.local_types.put(fld.bind_name, sub);
                                };
                                try self.emit(.{ .local_set = fld.bind_name });
                            }
                        },
                        .tuple_ => |bindings| {
                            for (bindings, 0..) |name, i| {
                                try self.noteTupleElemShape(name, lb.value.*, i);
                                try self.emit(.{ .local_get = mem });
                                try self.emitLoadOffset(@intCast(i * 4));
                                const cell = try self.tupleElemCell(lb.value.*, i);
                                if (cell != .none) {
                                    try self.emitFromCell(cell);
                                    if (!std.mem.eql(u8, self.locals.get(name) orelse "", cell.ty()))
                                        return self.refuse(stmt.expr.getLoc(), "the wasm backend binds `{s}` to values of two widths in one function", .{name});
                                }
                                try self.emit(.{ .local_set = name });
                            }
                        },
                        // `val Circle(r) = s;` — decision 67's R5: the checker
                        // accepts it only where it cannot fail, so there is no
                        // test, only the reads. A record reads each binding off
                        // the declared field at its position; a variant takes
                        // the `case` arm's binder (`bindPattern`), payload
                        // slots from offset 4.
                        .ctor => |pat| {
                            if (self.ctorRecordFields(pat)) |r| {
                                for (r.binds, 0..) |bind, i| {
                                    if (bind.len == 0) continue;
                                    const cell = fieldCellOf(self.fieldTypeIn(r.record, r.fields[i]) orelse "");
                                    try self.declareLocal(bind, cell.ty());
                                    if (self.fieldTypeIn(r.record, r.fields[i])) |ft| {
                                        if (std.mem.eql(u8, ft, "string")) try self.str_locals.put(bind, {});
                                        if (std.mem.eql(u8, ft, "bool")) try self.bool_locals.put(bind, {});
                                        if (self.resolveRecordName(ft)) |sub| try self.local_types.put(bind, sub);
                                    }
                                    try self.emit(.{ .local_get = mem });
                                    try self.emitLoadOffset(@intCast(i * 4));
                                    // A float or `i64` field holds its cell.
                                    try self.emitFromCell(cell);
                                    try self.emit(.{ .local_set = bind });
                                }
                            } else if (try self.ctorAsFieldsPattern(pat)) |fp| {
                                try self.bindPattern(fp, mem);
                            } else return self.refuse(stmt.expr.getLoc(), "the wasm backend has no lowering for this constructor pattern in a binding", .{});
                        },
                        // A spread-only list is the one list the checker lets
                        // through: `[..rest]` is the whole value.
                        .list => |pat| if (pat == .list and pat.list.elems.len == 0) {
                            if (pat.list.spread) |sp| if (sp.len > 0) {
                                try self.declareLocal(sp, "i32");
                                try self.noteArrayLocal(sp, lb.value.*);
                                try self.emit(.{ .local_get = mem });
                                try self.emit(.{ .local_set = sp });
                            };
                        } else return self.refuse(stmt.expr.getLoc(), "the wasm backend has no lowering for a list pattern with elements in a binding", .{}),
                    }
                },
            },
            // `@block { … }` is transparent: its trailing body is inlined, so
            // the enclosing statement's value requirement passes straight in.
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (cc.is_builtin and std.mem.eql(u8, cc.callee, "block")) {
                        if (cc.trailing.len == 0) return .none;
                        if (blockBodyReturns(cc.trailing[0].body)) return self.lowerBlockWithReturn(cc.trailing[0].body, keep_value);
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
                            if (blockBodyReturns(cc.trailing[0].body)) break :blk .value;
                            break :blk self.bodyTail(cc.trailing[0].body);
                        }
                        break :blk .value;
                    }
                    if (self.primKindAt(cc, c.loc)) |k| {
                        const res = self.primRes(k, cc) orelse break :blk .value;
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
                    (if (self.yield_target != null) Tail.terminated else Tail.value)
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
                        try self.emit(try numLitConst(self.arena(), n));
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
                        // Narrowed by a `!= null` test: the name is its payload
                        // inside the branch, and a boxed payload lives one
                        // indirection away.
                        if (self.narrowed_opts.get(n)) |o| {
                            if (o.boxed) try self.emitUnboxPayload(o, "narrowed optional payload");
                        }
                    } else if (self.globals.contains(n)) {
                        try self.emit(.{ .global_get = self.globalName(n) });
                    } else if (self.fn_sigs.contains(n)) {
                        try self.lowerFnRef(self.import_aliases.get(n) orelse n, id.loc);
                    } else if (self.findVariant(n)) |fv| {
                        // a bare unit variant (`Lt`)
                        try self.emitUnitVariant(fv.variants, fv.tag, "", n);
                    } else {
                        // Neither a local nor a module global: a `global.get`
                        // here would make the whole module unloadable
                        // ("unknown global"), and a `0` in its place printed
                        // a wrong value at exit 0.
                        return self.refuse(id.loc, "`{s}` is not bound here: the wasm backend found no local, global, function or variant of that name", .{n});
                    }
                },
                .dotIdent => |name| {
                    // `.Variant` — type inferred from context. Emit the variant
                    // tag if the name uniquely identifies a unit variant.
                    if (self.findVariant(name)) |fv| {
                        try self.emitUnitVariant(fv.variants, fv.tag, "", name);
                    } else {
                        return self.refuse(id.loc, "`.{s}` names no variant of an enum this program declares", .{name});
                    }
                },
                .identAccess => |ia| try self.lowerIdentAccess(ia, id.loc),
            },
            .binaryOp => |bin| try self.lowerBinOp(bin.op, bin.lhs.*, bin.rhs.*, bin.loc),
            .unaryOp => |un| switch (un.op) {
                .neg => try self.lowerNeg(un.expr.*, un.loc),
                .not => {
                    try self.lowerExpr(un.expr.*);
                    try self.emit(opOf("i32", "eqz"));
                },
            },
            .call => |c| {
                const outer_call = self.call_loc;
                self.call_loc = c.loc;
                defer self.call_loc = outer_call;
                switch (c.kind) {
                    .call => |cc| {
                        // Decision 354 (8) — a `use provide` / `use context`
                        // lowered to std's `context.push` / `context.find`
                        // carries a value through an `unknown` slot the lowering
                        // wrote after inference, and this backend boxes and
                        // unboxes a value only by a static type it reads from
                        // inference: refused, located at the `use`, until the
                        // wasm lowering of the hidden map lands
                        // (`language-gaps.md` row 354-wasm).
                        if (cc.receiver == null and (std.mem.eql(u8, cc.callee, context_lower.push_fn) or std.mem.eql(u8, cc.callee, context_lower.find_fn)))
                            return self.refuse(c.loc, "the wasm backend does not lower a context yet: `use provide` / `use context` (decision 354 (8)) runs on erlang, beam and commonJS", .{});
                        // Static extension dispatch (F6) — resolve to the mangled
                        // linear-memory function `$<target>_<method>` before the
                        // ordinary call-kind handling.
                        if (try self.lowerDispatchCall(cc, c.loc)) return;
                        if (self.instance_lowerings.get(c.loc)) |il| if (il == .sequence_next) {
                            try self.lowerSequenceNext(cc);
                            return;
                        };
                        if (try self.lowerChainedCall(cc, c.loc)) return;
                        if (self.primKindAt(cc, c.loc)) |k| {
                            try self.lowerPrimMethod(k, cc);
                            return;
                        }
                        // A host-backed method (`hostMethods`): wasm has no host,
                        // so the call is refused where it is written, as a
                        // module-level host function's is (`lowerPlainCall`).
                        if (hostMethods.missingAt(self.cross, &self.instance_lowerings, c.loc, cc.callee, .wasm)) |me| {
                            self.missing_external = me;
                            return error.MissingExternalTarget;
                        }
                        if (try self.lowerRecordMethod(cc, c.loc)) return;
                        if (self.primAssocHelper(cc)) |h| {
                            try self.lowerCoerced(callArg(cc, 0).?, "i32");
                            try self.emit(self.builder().helper(h));
                            return;
                        }
                        if (self.assocSym(cc)) |sym_tmp| {
                            const generic = try self.arena().dupe(u8, sym_tmp);
                            const spec = try self.specializeFor(generic, cc.args);
                            const sym = spec orelse generic;
                            try self.lowerCallArgs(cc.args, self.fn_sigs.get(sym).?, 0);
                            if (spec == null and self.generic_fns.contains(sym)) try self.noteTemplateCall(sym, c.loc);
                            try self.emit(.{ .call = sym });
                            if (spec == null and self.iface_assoc.contains(sym) and !self.assoc_emitted.contains(sym))
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
                            .builtin => try self.lowerBuiltin(cc, c.loc),
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
                                    return self.refuse(c.loc, "`{s}.{s}` names no variant of `{s}`", .{ rcv, cc.callee, rcv });
                                } else if (self.findVariant(cc.callee)) |fv| {
                                    try self.lowerEnumCtor(cc, fv.tag, fv.variant);
                                }
                            },
                            .plain => try self.lowerPlainCall(cc, c.loc),
                        }
                    },
                    .pipeline => |pl| {
                        switch (pl.rhs.*) {
                            .identifier => |pid| switch (pid.kind) {
                                .ident => |name| {
                                    if (self.fn_sigs.get(name)) |sig| {
                                        try self.lowerValue(pl.lhs.*);
                                        try self.emit(.{ .call = self.import_aliases.get(name) orelse name });
                                        if (sig.result == null) try self.pushZero();
                                    } else {
                                        return self.refuse(c.loc, "`{s}` is not a function the wasm backend can pipe into", .{name});
                                    }
                                },
                                else => return self.refuse(c.loc, "the wasm backend pipes only into a named function", .{}),
                            },
                            else => try self.lowerValue(pl.rhs.*),
                        }
                    },
                }
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| try self.lowerIfExpr(i),
                .tryCatch => |tc| try self.lowerTryCatch(tc),
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| try self.lowerExpr(inner.*),
                .case => |c| try self.lowerCase(c),
                .tupleLit => |tl| try self.lowerTupleLit(tl),
                .arrayLit => |al| try self.lowerArrayLit(al, e.getLoc()),
                .behaviorLit => |il| try self.lowerBehaviorLit(il),
                .range => return self.refuse(e.getLoc(), "the wasm backend has no lowering for a range outside an index or a pattern", .{}),
            },
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (self.block_ret) |br| {
                        try self.emitBlockReturn(br, if (r) |val| val.* else null);
                        return;
                    }
                    if (r) |val| if (try self.lowerSelfTailCall(val.*)) return;
                    if (r) |val| try self.lowerExpr(val.*) else if (self.fn_has_result) try self.pushZero();
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
                            // Decision 105 — see the statement-position arm above.
                            try self.emitGenBreak(v.*);
                        } else try self.lowerExpr(v.*);
                    } else if (self.loop_depth > 0) {
                        try self.emit(.{ .br = break_label });
                    } else if (self.yield_target != null) {
                        // Decision 103 — see the statement-position arm above.
                        try self.emitGenEnd();
                    }
                },
                .yield => |y| {
                    if (y.value) |v| {
                        if (self.yield_target != null) try self.emitYield(v.*) else try self.lowerExpr(v.*);
                    }
                },
                .@"continue" => if (self.loop_depth > 0)
                    try self.emit(.{ .br = next_label })
                else
                    return self.refuse(e.getLoc(), "`continue` outside a loop", .{}),
            },
            .comptime_ => |ct| switch (ct.kind) {
                .assert => |a| try self.lowerAssert(a, ct.loc),
                .assertPattern => |ap| try self.lowerAssertPattern(ap, ct.loc),
                else => return self.refuse(ct.loc, "the wasm backend has no lowering for the comptime construct `{s}`", .{@tagName(ct.kind)}),
            },
            .function => |f| if (f.kind.syntax == .asyncBlock)
                try self.lowerAsyncBlock(f.kind.body)
            else
                try self.lowerLambdaValue(f.kind.params, f.kind.body, e.getLoc()),
            .loop => |lp| try self.lowerLoop(lp),
            else => return self.refuse(e.getLoc(), "the wasm backend has no lowering for a `{s}` expression", .{@tagName(e)}),
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
    /// The local a pattern is matched against, given what its subject is: a
    /// tuple's shape (what a tuple pattern reads its elements by), an array's
    /// shape and element kind (what a list pattern reads).
    fn noteSubjectShape(self: *Emitter, local: []const u8, subject: ast.Expr) !void {
        if (try self.printShapeOf(subject)) |sh| if (sh[0] == '(' or sh[0] == '[') try self.print_shape_locals.put(local, sh);
        if (self.isArrayExpr(subject)) {
            try self.arr_locals.put(local, {});
            try self.arr_elem_locals.put(local, self.elemKindOf(subject));
        }
    }

    /// True when `emitPatternTest` produces a real test for `p`. A variant
    /// pattern naming neither an enum variant nor a `@Result` arm — a record
    /// constructor, say — falls back to a constant `0`, which as a `val
    /// assert` test would mean "never matches" and make every such assert
    /// fatal. There the assert is lowered as a plain binding instead, which is
    /// what the construct did before it was lowered at all.
    fn patternTestIsReal(self: *Emitter, p: ast.Pattern) bool {
        return switch (p) {
            .variant => |v| self.variantRef(v.name) != null or self.recordPatternType(v) != null,
            .@"or" => |pats| blk: {
                for (pats) |sub| {
                    if (!self.patternTestIsReal(sub)) break :blk false;
                }
                break :blk true;
            },
            else => true,
        };
    }

    fn lowerAssertPattern(self: *Emitter, ap: anytype, loc: ast.Loc) anyerror!void {
        const slot = try std.fmt.allocPrint(self.arena(), "__assert_{d}", .{self.assert_seq});
        self.assert_seq += 1;
        try self.declareLocal(slot, "i32");
        try self.lowerCoerced(ap.expr.*, "i32");
        try self.emit(.{ .local_set = slot });
        if (self.isStringExpr(ap.expr.*)) try self.str_locals.put(slot, {});
        if (self.resultShapeOf(ap.expr.*)) |shape| try self.result_subjects.put(slot, shape);
        try self.noteSubjectShape(slot, ap.expr.*);

        if (!self.patternIsIrrefutable(ap.pattern) and self.patternTestIsReal(ap.pattern)) {
            try self.emitPatternTest(ap.pattern, slot, loc);
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
        if (self.yield_target) |tgt| {
            // Decision 122 — in a sequence whose item is a `@Result`, a
            // failing `try` emits the Error as the last item and ends (the
            // scope's `break <v>`).
            try self.emit(.{ .local_get = tgt });
            try self.emit(.{ .local_get = slot });
            try self.emit(self.builder().helper(.arr_push));
            try self.emit(.{ .local_set = tgt });
            if (self.gen_end) |label| {
                try self.emit(.{ .br = label });
            } else {
                try self.emitC(.{ .local_get = tgt }, "everything the body yielded");
                try self.emitConvert("i32", self.cur_result);
                try self.emit(.@"return");
            }
        } else {
            try self.emit(.{ .local_get = slot });
            try self.emitC(.@"return", "propagate Error");
        }
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
        // A value of a generic `type` that declares `display` prints through
        // `$__display_of`, which calls the ONE generic body of that method:
        // a call no specialisation reached (`refuseUnboundTemplateCalls`).
        if (self.recordTypeOfExpr(arg)) |rec| {
            const dsym = try std.fmt.allocPrint(self.arena(), "{s}_display", .{rec});
            if (self.generic_methods.contains(dsym)) try self.noteTemplateCall(dsym, arg.getLoc());
        }
        // §7 F2/F3 are not this front's — a value has to know which named type
        // it is at run time, which is `13-module-identity`. Until then a record
        // or a variant reaching `@print` has **no text**, and the numeric
        // printer answered its heap address: `328`, `336`, `344` with exit 0 and
        // no diagnostic. That is the one thing this backend must not do.
        // §7 F2/F3 — a value that carries its own declaration prints as the
        // source writes it, read from the VALUE's header and not from this
        // site. A variant of an ALL-UNIT enum is the ordinal itself, with no
        // allocation and so no header, and still has no printed form: it is
        // refused rather than reading four bytes behind an integer.
        // A field or a name declared as an enum with a payload variant
        // (`a.place`, `val p: Place`): every value of it — a unit variant too
        // — is a tagged cell carrying its variant's descriptor. Neither
        // `namedShapeOf` nor `isTaggedValue` reads a declared type, and the
        // numeric printer answered the cell's address.
        if (self.payloadEnumOfName(arg) != null) {
            try self.lowerCoerced(arg, "i32");
            try self.emit(self.builder().helper(if (last) .print_tagged else .print_tagged_raw));
            return;
        }
        if (self.namedShapeOf(arg)) |ns| {
            // A record that may be ABSENT — `es.at(0)`, or a name bound to one.
            // The tagged printer reads a header four bytes behind the value, so
            // a `0` would read out of bounds; `$__print_opt_tagged` answers
            // `undefined` for it and the header for anything else.
            if (self.optInfoOf(arg)) |oi| if (oi.rec != null) {
                try self.lowerCoerced(arg, "i32");
                try self.emit(self.builder().helper(if (last) .print_opt_tagged else .print_opt_tagged_raw));
                return;
            };
            if (self.isTaggedValue(arg)) {
                try self.lowerCoerced(arg, "i32");
                try self.emit(self.builder().helper(if (last) .print_tagged else .print_tagged_raw));
                return;
            }
            // A CONTAINER of such values is printed by its shape, whose `T`
            // arm reads each element's own header.
            if (try self.printShapeOf(arg)) |_| {} else {
                return self.refuse(arg.getLoc(), "the wasm backend has no printed form for this {s}: a variant of an all-unit enum is its ordinal, with no header naming its type", .{@tagName(ns)});
            }
        }
        // An `unknown` / union value prints by what its box says it holds.
        if (self.isUnknownExpr(arg)) {
            try self.lowerCoerced(arg, "i32");
            try self.emit(self.builder().helper(if (last) .print_unknown else .print_unknown_raw));
            return;
        }
        if (self.optInfoOf(arg)) |oi| {
            // A `?Color` of an all-unit enum: a box around the ordinal, which
            // prints `null` or the variant's name. Through `$__print_opt_i32`
            // it printed the ordinal.
            if (oi.boxed and !oi.bool_ and oi.cell == .none) if (try self.optUnitEnumShape(arg, oi)) |shape| {
                const tmp = try self.declRes();
                try self.lowerValue(arg);
                try self.emit(.{ .local_tee = tmp });
                try self.emit(opOf("i32", "eqz"));
                var then_c: Capture = .{};
                self.open(&then_c);
                try self.emit(self.builder().helper(.print_null));
                const then_seq = self.seal(&then_c, .none);
                var else_c: Capture = .{};
                self.open(&else_c);
                try self.emit(.{ .local_get = tmp });
                try self.emitC(.{ .load = .{} }, "optional payload");
                const seg = try self.internString(shape);
                try self.emit(try self.constInt(seg.offset + 4));
                try self.emit(try self.constInt(1));
                try self.emit(self.builder().helper(.print_shaped_raw));
                try self.emit(.drop);
                const else_seq = self.seal(&else_c, .none);
                try self.emit(.{ .@"if" = .{ .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
                if (last) try self.emit(self.builder().helper(.print_nl));
                return;
            };
            // A `?T[]` of a scalar `T` — `m.at(1)` on a `Matrix` whose `at`
            // answers `?i32[]`: the value is the array's own pointer and `0`
            // its absence, so it prints `null` or the array. Through the
            // integer printer it answered the row's address (`384`).
            if (!oi.boxed and !oi.str) if (oi.inner) |inner| if (arrayScalarCode(inner)) |code| {
                const tmp = try self.declRes();
                try self.lowerValue(arg);
                try self.emit(.{ .local_tee = tmp });
                try self.emit(opOf("i32", "eqz"));
                var then_c: Capture = .{};
                self.open(&then_c);
                try self.emit(self.builder().helper(.print_null));
                if (last) try self.emit(self.builder().helper(.print_nl));
                const then_seq = self.seal(&then_c, .none);
                var else_c: Capture = .{};
                self.open(&else_c);
                try self.emit(.{ .local_get = tmp });
                try self.emit(self.builder().helper(if (code == 'f')
                    (if (last) .print_arr_f64 else .print_arr_f64_raw)
                else if (last) .print_arr_i32 else .print_arr_i32_raw));
                const else_seq = self.seal(&else_c, .none);
                try self.emit(.{ .@"if" = .{ .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
                return;
            };
            if (!oi.boxed and !oi.str) if (oi.shape) |shape| {
                const tmp = try self.declRes();
                try self.lowerValue(arg);
                try self.emit(.{ .local_tee = tmp });
                try self.emit(opOf("i32", "eqz"));
                var then_c: Capture = .{};
                self.open(&then_c);
                try self.emit(self.builder().helper(.print_null));
                const then_seq = self.seal(&then_c, .none);
                var else_c: Capture = .{};
                self.open(&else_c);
                try self.emit(.{ .local_get = tmp });
                const seg = try self.internString(shape);
                try self.emit(try self.constInt(seg.offset + 4));
                try self.emit(try self.constInt(1));
                try self.emit(self.builder().helper(.print_shaped_raw));
                try self.emit(.drop);
                const else_seq = self.seal(&else_c, .none);
                try self.emit(.{ .@"if" = .{ .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
                if (last) try self.emit(self.builder().helper(.print_nl));
                return;
            };
            try self.lowerValue(arg);
            const b = self.builder();
            try self.emit(if (oi.boxed)
                b.helper(if (oi.bool_)
                    (if (last) .print_opt_bool else .print_opt_bool_raw)
                else if (oi.cell == .f64)
                    (if (last) .print_opt_f64 else .print_opt_f64_raw)
                else if (oi.cell == .i64 and optIsU64(oi))
                    (if (last) .print_opt_u64 else .print_opt_u64_raw)
                else if (oi.cell == .i64)
                    (if (last) .print_opt_i64 else .print_opt_i64_raw)
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
        // printer (semantics decision 1a). A flat integer or float array keeps its own.
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
            .f64 => {
                try self.lowerCoerced(arg, "i32");
                try self.emit(self.builder().helper(if (last) .print_arr_f64 else .print_arr_f64_raw));
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
        if (std.mem.eql(u8, t, "i64")) {
            try self.lowerValue(arg);
            if (self.isU64Expr(arg)) {
                try self.emit(self.builder().helper(if (last) .print_u64 else .print_u64_raw));
                return;
            }
            try self.emit(self.builder().helper(if (last) .print_i64 else .print_i64_raw));
            return;
        }
        // A tuple whose elements have no print shape here (a `?T` over a type
        // parameter, an all-unit enum) is a pointer: through the integer
        // printer it answered its address (`300`) at exit 0.
        if (self.typeRefOf(arg)) |tr| if (tr.tupleElems() != null)
            return self.refuse(arg.getLoc(), "the wasm backend has no printed form for this tuple: one of its elements has no print shape here", .{});
        try self.lowerCoerced(arg, "i32");
        try self.emit(self.builder().helper(if (last) .print_i32 else .print_i32_raw));
    }

    fn lowerBuiltin(self: *Emitter, cc: anytype, loc: ast.Loc) anyerror!void {
        if (std.mem.eql(u8, cc.callee, "todo") or std.mem.eql(u8, cc.callee, "panic")) {
            try self.emit(.@"unreachable");
            return;
        }
        if (std.mem.eql(u8, cc.callee, ast.is_builtin_name) and cc.isType != null) {
            try self.lowerIsCall(cc);
            return;
        }
        if (std.mem.eql(u8, cc.callee, "block")) {
            if (cc.trailing.len > 0) {
                const body = cc.trailing[0].body;
                if (blockBodyReturns(body)) {
                    _ = try self.lowerBlockWithReturn(body, true);
                } else _ = try self.emitBody(body, true);
            }
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
            try self.lowerResultOptionOp(cc.callee, cc.args, loc);
            return;
        }
        // Decorator / template builtins (`@emit`, `@compilerError`,
        // `Binding.ref`) only exist inside comptime bodies, which never reach
        // this backend: the comptime pass runs them on `erl`. There is nothing
        // in a program module to call, so a program that writes one is
        // refused there.
        if (std.mem.eql(u8, cc.callee, "emit") or
            std.mem.eql(u8, cc.callee, "compilerError") or
            std.mem.eql(u8, cc.callee, "ref"))
        {
            return self.refuse(loc, "`@{s}` is a comptime-only builtin: it runs in a decorator or template body, never in a program the wasm backend emits", .{cc.callee});
        }
        return self.refuse(loc, "the wasm backend has no lowering for the builtin `@{s}`", .{cc.callee});
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
    /// has no lowering here: `d["k"]` is `Dict.at` through a std record, and
    /// this backend inlines std rather than linking it. It is refused rather
    /// than answering a number nothing put there.
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
                return self.refuseUnlessTemplate(self.call_loc, "the wasm backend cannot slice this receiver: nothing types it as a string or an array here", .{});
            }
            try self.lowerCoerced(recv, "i32");
            try self.lowerCoerced(r.start.*, "i32");
            if (r.end) |e| {
                try self.lowerCoerced(e.*, "i32");
            } else {
                // `$__str_cp_slice` and `$__arr_slice` clamp, so "to the end"
                // is the largest i32
                try self.emit(try self.constInt(std.math.maxInt(i32)));
            }
            // Decision 240: a string's bounds are codepoints.
            try self.emit(b.helper(if (is_str) .str_cp_slice else .arr_slice));
            return;
        }

        if (is_str) {
            // `s[i]` is the one-codepoint string at codepoint `i` (decision
            // 240), the `char` §7 prints.
            const at = try self.declRes();
            try self.lowerCoerced(idx, "i32");
            try self.emit(.{ .local_set = at });
            try self.lowerCoerced(recv, "i32");
            try self.emit(.{ .local_get = at });
            try self.emit(.{ .local_get = at });
            try self.emit(one);
            try self.emit(opOf("i32", "add"));
            try self.emit(b.helper(.str_cp_slice));
            return;
        }
        if (is_arr) {
            try self.lowerCoerced(recv, "i32");
            try self.lowerCoerced(idx, "i32");
            try self.emit(b.helper(.arr_at));
            // A float array's slot holds the address of the element's `f64`
            // cell (`$__box_f64`): the value is one load away.
            if (self.elemKindOf(recv) == .f64) try self.emitFromFloatSlot();
            return;
        }
        return self.refuseUnlessTemplate(self.call_loc, "the wasm backend cannot index this receiver: nothing types it as a string or an array here", .{});
    }

    /// Reserve and declare the next `$_res{n}` scratch pointer local. Declared
    /// inline (like the `$__case` locals) since the count isn't known up front.
    /// Bump the heap by the two `i32` slots a `@Result` occupies, leaving the
    /// base pointer in the scratch local `slot`.
    fn allocResultPair(self: *Emitter, slot: []const u8) !void {
        try self.emit(try self.constInt(8));
        try self.emit(self.builder().helper(.alloc));
        try self.emit(.{ .local_set = slot });
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
        const scope_mark = self.scopeMark();
        defer self.scopeRestore(scope_mark);
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
    fn lowerResultOptionOp(self: *Emitter, callee: []const u8, args: anytype, loc: ast.Loc) anyerror!void {
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
            // A float or an `i64` does not fit the payload's word, and the
            // readers (`try`, `unwrapOr`, a `case` arm) take a word.
            if (Cell.of(self.wasmTypeOf(recv.*)) != .none)
                return self.refuse(recv.getLoc(), "the wasm backend has no `@Result` holding an `{s}`", .{self.wasmTypeOf(recv.*)});
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
            const le = lambdaArg(arg1) orelse return self.refuse(loc, "`Result.{s}` on the wasm backend takes a closure written at the call; a function value is not lowered", .{if (is_map) "map" else "flatMap"});
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
                if (Cell.of(self.lambdaTailType(lam.body)) != .none)
                    return self.refuse(loc, "the wasm backend has no `@Result` holding an `{s}`", .{self.lambdaTailType(lam.body)});
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
            const is_map = std.mem.eql(u8, callee, "__bp_option_map");
            const le = lambdaArg(arg1) orelse return self.refuse(loc, "`Option.{s}` on the wasm backend takes a closure written at the call; a function value is not lowered", .{if (is_map) "map" else "flatMap"});
            const lam = le.function.kind;
            const boxed = self.optionIsBoxed(recv.*, null);
            if (self.optInfoOf(recv.*)) |oi| if (oi.cell != .none) {
                return self.refuse(loc, "`Option.{s}` over a `?{s}` has no lowering on the wasm backend", .{ if (is_map) "map" else "flatMap", oi.cell.ty() });
            };
            if (is_map and Cell.of(self.lambdaTailType(lam.body)) != .none) {
                return self.refuse(loc, "`Option.map` to an `{s}` has no lowering on the wasm backend", .{self.lambdaTailType(lam.body)});
            }
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
            // A `?f64` / `?i64` answers what its cell holds, the default
            // that type.
            const cell: Cell = if (self.optInfoOf(recv.*)) |oi| oi.cell else .none;
            const res_ty: ValType = vt(cell.ty());
            try self.lowerExpr(recv.*);
            try self.emit(.{ .local_set = slot });
            try self.emitC(.{ .local_get = slot }, option_shape);

            var then_c: Capture = .{};
            self.open(&then_c);
            try self.emitC(.{ .local_get = slot }, "Some — present value");
            if (cell != .none)
                try self.emitC(.{ .load = .{ .ty = res_ty } }, "optional payload")
            else if (self.optionIsBoxed(recv.*, arg1)) try self.emitC(.{ .load = .{} }, "optional payload");
            const then_seq = self.seal(&then_c, .{ .value = res_ty });

            var else_c: Capture = .{};
            self.open(&else_c);
            if (cell != .none) {
                if (arg1) |d| try self.lowerCoerced(d.*, cell.ty()) else try self.emit(constOf(cell.ty(), "0"));
            } else if (arg1) |d| try self.lowerExpr(d.*) else try self.emit(zero);
            const else_seq = self.seal(&else_c, .{ .value = res_ty });

            try self.emit(.{ .@"if" = .{
                .result = res_ty,
                .then = .{ .seq = then_seq },
                .@"else" = .{ .seq = else_seq },
            } });
            return;
        }

        return self.refuse(loc, "the wasm backend has no lowering for `{s}`", .{callee});
    }

    /// True when `e` evaluates to the 0/1 boolean carrier: the `true`/`false`
    /// identifiers, a comparison, `!x`, `&&`/`||`, or a call to a fn declared
    /// `-> bool`.
    fn isBoolExpr(self: *Emitter, e: ast.Expr) bool {
        if (blockResultOf(e)) |a| return self.isBoolExpr(a);
        // `o ?? d` reads as `o.unwrapOr(d)`; `x!` answers its payload.
        if (nullishParts(e)) |nu| return self.isBoolExpr(nu.dflt);
        if (optOperatorParts(e)) |op| if (op.bang) return if (self.optInfoOf(op.cond.*)) |oi| oi.bool_ else false;
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| std.mem.eql(u8, n, "true") or std.mem.eql(u8, n, "false") or
                    self.bool_locals.contains(self.resolveName(n)) or self.bool_globals.contains(self.resolveName(n)),
                // `r.flag` of a field declared `bool`, `t.1` of a `bool`
                // element: the word is `1`/`0`, and only the declared type
                // says it prints `true`/`false` — `@print(r.flag)` wrote `1`
                // at exit 0. An optional read (`r?.flag`) is a `?bool`.
                .identAccess => |ia| !ia.optional and if (self.typeRefOf(e)) |t| isBoolTypeRef(t) else if (self.tupleElemShapeOf(e) catch null) |el| std.mem.eql(u8, el, "b") else false,
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
                    if (isUnwrapOr(cc)) break :blk self.isBoolExpr(cc.args[1].value.*);
                    if (cc.is_builtin) break :blk std.mem.eql(u8, cc.callee, "__bp_result_isOk") or
                        std.mem.eql(u8, cc.callee, "__bp_result_isError") or
                        (std.mem.eql(u8, cc.callee, ast.is_builtin_name) and cc.isType != null);
                    if (self.primKindAt(cc, c.loc)) |k| break :blk self.primRes(k, cc) == .bool_;
                    if (self.genericResultArg(cc)) |a| break :blk self.isBoolExpr(a);
                    // `f(a, b)` over a value declared `fn(…) -> bool`.
                    if (self.valueCallTypeRef(cc)) |t| if (isBoolTypeRef(t)) break :blk true;
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
        // A multi-subject `case` lowers each subject once, into its own
        // local below; the first one's is copied into `subj_local` there.
        if (c.subjects.len == 1) {
            try self.lowerCoerced(c.subjects[0], "i32");
            try self.emit(.{ .local_set = subj_local });
        }
        if (self.isUnknownExpr(c.subjects[0])) try self.unknown_subjects.put(self.alloc, subj_local, {});
        const subj_is_str = self.isStringExpr(c.subjects[0]);
        if (subj_is_str) try self.str_locals.put(subj_local, {});
        if (self.resultShapeOf(c.subjects[0])) |shape| try self.result_subjects.put(subj_local, shape);
        if (self.enumOfSubject(c.subjects[0])) |en| try self.subject_enums.put(self.alloc, subj_local, en) else _ = self.subject_enums.remove(subj_local);
        try self.noteSubjectShape(subj_local, c.subjects[0]);
        // `case a, n { 0, "x" -> … }`: every subject in its own local,
        // `<subject local>_<i>`, which the `.multi` pattern's i-th pattern is
        // tested against and binds from. Only the first was lowered, and the
        // `.multi` pattern tested nothing — the first arm answered every call.
        if (c.subjects.len > 1) for (c.subjects, 0..) |subj, i| {
            const sub = try multiSubjectLocal(self.arena(), subj_local, i);
            try self.declareLocal(sub, "i32");
            try self.lowerCoerced(subj, "i32");
            try self.emit(.{ .local_set = sub });
            if (self.isUnknownExpr(subj)) try self.unknown_subjects.put(self.alloc, sub, {});
            if (self.isStringExpr(subj)) try self.str_locals.put(sub, {});
            if (self.resultShapeOf(subj)) |shape| try self.result_subjects.put(sub, shape);
            if (self.recordTypeOfExpr(subj)) |rty| try self.local_types.put(sub, rty);
            if (self.enumOfSubject(subj)) |en| try self.subject_enums.put(self.alloc, sub, en) else _ = self.subject_enums.remove(sub);
            if (i == 0) {
                try self.emit(.{ .local_get = sub });
                try self.emit(.{ .local_set = subj_local });
            }
        };

        try self.emitCaseArms(c.arms, subj_local, 0);
    }

    fn emitCaseArms(self: *Emitter, arms: anytype, subj: []const u8, idx: usize) anyerror!void {
        if (idx >= arms.len) {
            try self.emit(constOf(self.cur_result, "0"));
            return;
        }
        const arm = arms[idx];
        // §5.2 — an arm naming a primitive type over an `unknown` subject
        // tests the value's box (by value: `3.0` takes an `i32` arm), and its
        // binder is the unboxed payload. As a plain identifier it was a
        // binding that matched everything: `number 364`, a heap address.
        if (self.unknown_subjects.contains(subj) and arm.pattern == .ident) if (primTestOf(.{ .named = arm.pattern.ident })) |pt| {
            try self.emit(.{ .local_get = subj });
            try self.emitPrimTest(pt);
            const ty = vt(self.cur_result);
            var then_c: Capture = .{};
            self.open(&then_c);
            self.arm_unbox = pt;
            if (arm.guard) |g| {
                try self.emitGuardChain(arms, subj, idx, g);
            } else {
                try self.lowerArmBody(arm.body, subj);
            }
            self.arm_unbox = null;
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
            return;
        };
        const irrefutable = blk: {
            const prev_hint = self.case_enum_hint;
            self.case_enum_hint = self.subject_enums.get(subj);
            defer self.case_enum_hint = prev_hint;
            break :blk self.patternIsIrrefutable(arm.pattern);
        };
        if (irrefutable) {
            const arm_aliases = try self.aliases.clone();
            try self.bindPattern(arm.pattern, subj);
            // A guard makes even `_` refutable: a failing guard falls through
            // to the next arm (§5.3), so there is still a chain to emit.
            if (arm.guard) |g| {
                try self.emitGuardChain(arms, subj, idx, g);
            } else {
                try self.lowerArmBody(arm.body, subj);
            }
            self.restoreAliases(arm_aliases);
            return;
        }
        try self.emitPatternTest(arm.pattern, subj, arm.patternLoc);
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
        const scope_mark = self.scopeMark();
        defer self.scopeRestore(scope_mark);
        const unbox = self.arm_unbox;
        self.arm_unbox = null;
        // Read once: a `case` nested in the body binds its own arms.
        const record = self.arm_record;
        self.arm_record = null;
        const lam = armLambda(body) orelse {
            try self.lowerCoerced(body, self.cur_result);
            return;
        };
        // P1: the single parameter binds the whole matched value — for a
        // primitive-type arm over an `unknown` subject, the payload its test
        // proved.
        if (unbox) |pt| if (lam.params.len == 1) {
            const p = lam.params[0];
            const b = self.builder();
            try self.declareLocal(p, if (pt == .float) "f64" else "i32");
            try self.emit(.{ .local_get = subj });
            switch (pt) {
                .int => try self.emit(b.helper(.unknown_as_i32)),
                .float => try self.emit(b.helper(.unknown_as_f64)),
                .bool_, .string => try self.emitC(.{ .load = .{} }, "unknown: the proven payload"),
            }
            try self.emit(.{ .local_set = p });
            if (pt == .string) try self.str_locals.put(p, {});
            if (pt == .bool_) try self.bool_locals.put(p, {});
        };
        if (unbox == null and lam.params.len == 1) {
            const p = lam.params[0];
            try self.declareLocal(p, "i32");
            if (self.str_locals.contains(subj)) try self.str_locals.put(p, {});
            if (record orelse self.local_types.get(subj)) |t| try self.local_types.put(p, t);
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
        if (!isResultPath(name)) if (self.findVariant(name)) |fv| return .{ .user = fv };
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
            // a written path is a variant, never a binding (§5.1 P8); a name
            // that is a `type` this module declares is decision 8 §3.3's arm,
            // tested by the value's own header, not a binding either
            .ident => |n| !isLitPatternName(n) and !isVariantPath(n) and self.findVariant(n) == null and !self.namesATestableType(n),
            .multi => |pats| for (pats) |sub| {
                if (!self.patternIsIrrefutable(sub)) break false;
            } else true,
            // `[..]` / `[..rest]` matches every array; any other list pattern
            // is tested (`emitListPatternTest`). Every one of them used to be
            // irrefutable here, so `[x]` took a `[]` arm before it.
            .list => |l| l.elems.len == 0 and l.spread != null,
            else => false,
        };
    }

    fn emitPatternTest(self: *Emitter, p: ast.Pattern, subj: []const u8, loc: ast.Loc) anyerror!void {
        const prev_hint = self.case_enum_hint;
        self.case_enum_hint = self.subject_enums.get(subj);
        defer self.case_enum_hint = prev_hint;
        switch (p) {
            .wildcard => try self.emit(one),
            .list => |l| try self.emitListPatternTest(l, subj, loc),
            // Every pattern against its own subject (`lowerCase`), all of them
            // holding. A primitive type over an `unknown` / union subject
            // tests the value's box, as a whole-subject arm does.
            .multi => |pats| {
                try self.emit(one);
                for (pats, 0..) |sub, i| {
                    const local = try multiSubjectLocal(self.arena(), subj, i);
                    if (sub == .ident and self.unknown_subjects.contains(local)) if (primTestOf(.{ .named = sub.ident })) |pt| {
                        try self.emit(.{ .local_get = local });
                        try self.emitPrimTest(pt);
                        try self.emit(opOf("i32", "and"));
                        continue;
                    };
                    try self.emitPatternTest(sub, local, loc);
                    try self.emit(opOf("i32", "and"));
                }
            },
            // `true` / `false` in a pattern are the bool literals, never a
            // binder: inside a tuple pattern (`#(a, b, true)`) the element was
            // bound to a local named `true` and every arm matched.
            .ident => |n| if (isBoolLitName(n)) {
                try self.emit(.{ .local_get = subj });
                try self.emit(if (n[0] == 't') one else zero);
                try self.emit(opOf("i32", "eq"));
            } else if (std.mem.eql(u8, n, "null")) {
                // `Box(label: null, n: k)`: an optional field is absent when
                // its word is `0`. Bound as a local named `null`, the arm
                // took every value.
                try self.emit(.{ .local_get = subj });
                try self.emit(opOf("i32", "eqz"));
            } else {
                // A written path is a variant, never a binding (§5.1 P8), so
                // `.Ok` and `Shape.Circle` test a tag; a path no enum here
                // declares is an arm that can never match, not a catch-all.
                if (isVariantPath(n)) {
                    if (self.variantRef(n)) |ref|
                        try self.emitTagTest(ref, subj)
                    else
                        return self.refuse(loc, "`{s}` names no variant of an enum this program declares", .{n});
                } else if (self.findVariant(n)) |fv| {
                    // One spelling can be BOTH a `type` this module places and
                    // a variant some enum declares (`type Block(…)` beside
                    // `Token.Layout { Block, … }`). §5.3b: the SUBJECT's type
                    // says which one the arm means, and this emitter has no
                    // subject type, so the arm tests both, each by a test that
                    // is false for the other's values: the record's header,
                    // `or` the variant's own identity. Tested by the tag alone,
                    // a `case` over `Block | Vec` never matched a `Block`
                    // record, and a payload enum's tag load read a record's
                    // first field as a tag.
                    if (self.records.contains(n) and try self.emitNamedTypeTest(n, subj)) {
                        try self.emitVariantIdentityTest(fv, subj, loc);
                        try self.emit(opOf("i32", "or"));
                    } else try self.emitTagTest(.{ .user = fv }, subj);
                } else if (try self.emitNamedTypeTest(n, subj)) {
                    // Decision 8 §3.3 — an arm naming a `type` is chosen by the
                    // VALUE's own declaration, which half 3 put in its header.
                    // Emitted as the catch-all `1` below, the first arm of a
                    // `case` over `Person | Vec` answered for every subject.
                } else try self.emit(one);
            },
            .numberLit => |n| {
                try self.emit(.{ .local_get = subj });
                const t = numLitType(n);
                // the subject local is i32; a float literal is compared as one
                if (t[0] == 'f') {
                    try self.emit(constOf("f64", n));
                    try self.emit(.{ .convert = "i32.trunc_f64_s" });
                } else try self.emit(try numLitConst(self.arena(), n));
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
                    try self.emitPatternTest(sub, subj, loc);
                    try self.emit(opOf("i32", "or"));
                }
            },
            .variant => |v| {
                if (v.shape == .tuple) return self.emitTuplePatternTest(v, subj, loc);
                if (v.shape == .range) {
                    // `A...B` (decision 53): both ends included. The bounds are
                    // `payload.literals[0..2]`, low then high; the subject local
                    // is an i32, so a float bound is compared as one. Before
                    // this arm the shape fell into the variant path below, found
                    // no variant named `""` and answered `0` for every value.
                    const bounds = v.payload.literals;
                    try self.emitRangeBound(bounds[0], subj, "ge_s", loc);
                    try self.emitRangeBound(bounds[1], subj, "le_s", loc);
                    try self.emit(opOf("i32", "and"));
                    return;
                }
                // A RECORD's constructor pattern (`val assert Person(n, a) =
                // p catch …`): the value's header names the record, and a
                // nested pattern tests the field it stands at. Read as a
                // variant, no enum declared the name and the pattern tested
                // nothing and bound nothing (`unbound identifier n`).
                if (self.recordPatternType(v)) |rty| {
                    if (!try self.emitNamedTypeTest(rty, subj)) return self.refuse(loc, "the wasm backend has no descriptor for `{s}`, so its constructor pattern cannot be tested", .{rty});
                    if (v.payload == .literals) for (v.payload.literals, 0..) |sub, i| {
                        const fname = self.recordPatternField(rty, v, i) orelse
                            return self.refuse(loc, "the constructor pattern names a field `{s}` does not declare", .{rty});
                        const field = try std.fmt.allocPrint(self.arena(), "__case_{d}", .{self.case_depth});
                        self.case_depth += 1;
                        var then_c: Capture = .{};
                        self.open(&then_c);
                        const acc = try self.recordFieldAccess(subj, rty, fname);
                        try self.declareLocal(field, self.wasmTypeOf(acc));
                        try self.lowerValue(acc);
                        try self.emit(.{ .local_set = field });
                        try self.noteFieldBinder(field, rty, fname);
                        try self.emitPatternTest(sub, field, loc);
                        const then_seq = self.seal(&then_c, .{ .value = .i32 });
                        var else_c: Capture = .{};
                        self.open(&else_c);
                        try self.emit(zero);
                        const else_seq = self.seal(&else_c, .{ .value = .i32 });
                        try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
                    };
                    return;
                }
                const ref = self.variantRef(v.name) orelse
                    return self.refuse(loc, "`{s}` names no variant of an enum this program declares", .{v.name});
                try self.emitTagTest(ref, subj);
                // The payload's nested patterns, read only once the tag held
                // (a unit variant's cell has no payload slots) and `and`ed
                // into the tag test. Each test was left on the stack beside
                // the tag's, unread: the arm answered whatever the last
                // one said, and a `_` or a plain name tested a slot of a
                // value the tag had already refused.
                const lits: []const ast.Pattern = if (v.payload == .literals) v.payload.literals else &.{};
                var tested = false;
                for (lits) |sub| {
                    if (!self.patternOnlyBinds(sub)) tested = true;
                }
                if (tested) {
                    var then_c: Capture = .{};
                    self.open(&then_c);
                    try self.emit(one);
                    for (lits, 0..) |sub, i| {
                        if (self.patternOnlyBinds(sub)) continue;
                        const slot = payloadSlot(ref, v, i) orelse
                            return self.refuse(loc, "a label of the `{s}` pattern names no field its variant declares", .{v.name});
                        const field = try self.payloadFieldLocal(ref, subj, slot);
                        try self.emitPatternTest(sub, field, loc);
                        try self.emit(opOf("i32", "and"));
                    }
                    const then_seq = self.seal(&then_c, .{ .value = .i32 });
                    var else_c: Capture = .{};
                    self.open(&else_c);
                    try self.emit(zero);
                    const else_seq = self.seal(&else_c, .{ .value = .i32 });
                    try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
                }
            },
        }
    }

    /// The element patterns of a tuple pattern (`#(0, s)`, `#(a, ..)`).
    fn tupleElems(v: anytype) []const ast.Pattern {
        return switch (v.payload) {
            .literals => |l| l,
            else => &.{},
        };
    }

    /// Whether a pattern only binds (or ignores) — it tests nothing.
    fn patternOnlyBinds(self: *Emitter, p: ast.Pattern) bool {
        return switch (p) {
            .wildcard => true,
            .ident => |n| !isLitPatternName(n) and !isVariantPath(n) and self.findVariant(n) == null and !self.records.contains(n),
            else => false,
        };
    }

    fn isBoolLitName(n: []const u8) bool {
        return std.mem.eql(u8, n, "true") or std.mem.eql(u8, n, "false");
    }

    /// `true`, `false` and `null` ride on `Pattern.ident`
    /// (`parser/patterns.zig` `parseSimplePattern`): literals a pattern
    /// tests, never names it binds.
    fn isLitPatternName(n: []const u8) bool {
        return isBoolLitName(n) or std.mem.eql(u8, n, "null");
    }

    /// Element `i` of the tuple `subj` holds — its shape code (`s`, `i`, `(…)`),
    /// read off the subject's tuple shape. A tuple pattern needs it: the slot
    /// is a word whatever it holds, and a string bound as an integer printed
    /// its address.
    fn tuplePatternElemShape(self: *Emitter, subj: []const u8, i: usize, loc: ast.Loc) anyerror![]const u8 {
        const sh = self.print_shape_locals.get(subj) orelse
            return self.refuse(loc, "the wasm backend does not know the element types of this tuple pattern's subject", .{});
        return tupleShapeElem(sh, @intCast(i)) orelse
            self.refuse(loc, "the tuple pattern has more elements than its subject's type", .{});
    }

    /// Decision 8 §5.1 P6/P7 — `#(0, s)`: each element that tests something
    /// is read from its slot (`i * 4`, no header) and tested in a chain, as a
    /// variant's payload literals are; a binder, `_` and the elements `..`
    /// skips test nothing. A float element is a cell (`emitToFloatSlot`), which the `i32`
    /// tests here cannot compare — refused, never compared as bits.
    fn emitTuplePatternTest(self: *Emitter, v: anytype, subj: []const u8, loc: ast.Loc) anyerror!void {
        try self.emit(one);
        for (tupleElems(v), 0..) |sub, i| {
            if (self.patternOnlyBinds(sub)) continue;
            const code = try self.tuplePatternElemShape(subj, i, loc);
            if (code[0] == 'f') return self.refuse(loc, "the wasm backend cannot test a float tuple element against a pattern", .{});
            if (shapeCell(code) == .i64) return self.refuse(loc, "the wasm backend cannot test a 64-bit integer tuple element against a pattern", .{});
            const field = try std.fmt.allocPrint(self.arena(), "__case_{d}", .{self.case_depth});
            self.case_depth += 1;
            try self.declareLocal(field, "i32");
            try self.noteTupleElemLocal(field, code);
            var then_c: Capture = .{};
            self.open(&then_c);
            try self.emit(.{ .local_get = subj });
            try self.emit(.{ .load = .{ .offset = @intCast(i * 4) } });
            try self.emit(.{ .local_set = field });
            try self.emitPatternTest(sub, field, loc);
            const then_seq = self.seal(&then_c, .{ .value = .i32 });
            var else_c: Capture = .{};
            self.open(&else_c);
            try self.emit(zero);
            const else_seq = self.seal(&else_c, .{ .value = .i32 });
            try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
        }
    }

    /// What a local holding one tuple element is, by the element's shape code.
    fn noteTupleElemLocal(self: *Emitter, n: []const u8, code: []const u8) !void {
        const scalar: ?[]const u8 = switch (code[0]) {
            'i' => "i32",
            's' => "string",
            'b' => "bool",
            'f' => "f64",
            'l' => "i64",
            'u' => "u64",
            else => null,
        };
        if (scalar) |t| try self.local_typerefs.put(n, .{ .named = t });
        switch (code[0]) {
            's' => try self.str_locals.put(n, {}),
            'b' => try self.bool_locals.put(n, {}),
            '(' => try self.print_shape_locals.put(n, code),
            '[' => {
                try self.print_shape_locals.put(n, code);
                try self.arr_locals.put(n, {});
                try self.arr_elem_locals.put(n, if (code.len > 1 and code[1] == 's') .str else if (code.len > 1 and code[1] == 'f') .f64 else .i32);
            },
            else => {},
        }
    }

    /// `[]`, `[x]`, `[4, ..]`, `[first, ..rest]`: the length — exactly the
    /// elements written, or at least them with a spread — then each number
    /// literal against its slot, in a chain. It matched every array (the
    /// pattern answered `1`), so `[x]` took `[]`'s arm at exit 0.
    fn emitListPatternTest(self: *Emitter, l: anytype, subj: []const u8, loc: ast.Loc) anyerror!void {
        if (!self.arr_locals.contains(subj)) return self.refuse(loc, "the wasm backend tests a list pattern against an array subject only", .{});
        try self.emit(.{ .local_get = subj });
        try self.emitC(.{ .load = .{} }, "element count");
        try self.emit(try self.constInt(@as(i32, @intCast(l.elems.len))));
        try self.emit(opOf("i32", if (l.spread == null) "eq" else "ge_u"));
        for (l.elems, 0..) |el, i| {
            const n = switch (el) {
                .numberLit => |n| n,
                else => continue,
            };
            if (self.arr_elem_locals.get(subj) == .f64 or numLitType(n)[0] == 'f')
                return self.refuse(loc, "the wasm backend cannot test a float list element against a pattern", .{});
            var then_c: Capture = .{};
            self.open(&then_c);
            try self.emit(.{ .local_get = subj });
            try self.emit(.{ .load = .{ .offset = @intCast((i + 1) * 4) } });
            try self.emit(try numLitConst(self.arena(), n));
            try self.emit(opOf("i32", "eq"));
            const then_seq = self.seal(&then_c, .{ .value = .i32 });
            var else_c: Capture = .{};
            self.open(&else_c);
            try self.emit(zero);
            const else_seq = self.seal(&else_c, .{ .value = .i32 });
            try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
        }
    }

    /// Bind a list pattern's names: each `bind` from its slot, a named spread
    /// to the rest of the array (`$__arr_slice`).
    fn bindListPattern(self: *Emitter, l: anytype, subj: []const u8) anyerror!void {
        const ek = self.arr_elem_locals.get(subj) orelse .i32;
        const sh = self.print_shape_locals.get(subj);
        for (l.elems, 0..) |el, i| {
            const name = switch (el) {
                .bind => |b| b,
                else => continue,
            };
            const float = ek == .f64;
            const n = try self.bindName(name, if (float) "f64" else "i32");
            try self.emit(.{ .local_get = subj });
            try self.emit(.{ .load = .{ .offset = @intCast((i + 1) * 4) } });
            if (float) try self.emitFromFloatSlot();
            try self.emitConvert(if (float) "f64" else "i32", self.locals.get(n) orelse "i32");
            try self.emit(.{ .local_set = n });
            if (sh) |shape| if (shape.len > 1) try self.noteTupleElemLocal(n, shape[1..]);
            if (ek == .str) try self.str_locals.put(n, {});
            if (ek != .f64) try self.tuple_binders.put(self.reg_arena.allocator(), n, {});
        }
        const rest = l.spread orelse return;
        if (rest.len == 0) return;
        const n = try self.bindName(rest, "i32");
        try self.emit(.{ .local_get = subj });
        try self.emit(try self.constInt(@as(i32, @intCast(l.elems.len))));
        try self.emit(try self.constInt(std.math.maxInt(i32)));
        try self.emit(self.builder().helper(.arr_slice));
        try self.emit(.{ .local_set = n });
        try self.arr_locals.put(n, {});
        try self.arr_elem_locals.put(n, ek);
        if (sh) |shape| try self.print_shape_locals.put(n, shape);
    }

    /// Bind the names a tuple pattern introduces, each from its slot.
    fn bindTuplePattern(self: *Emitter, v: anytype, subj: []const u8) anyerror!void {
        for (tupleElems(v), 0..) |sub, i| {
            if (sub == .wildcard) continue;
            const code = try self.tuplePatternElemShape(subj, i, .{ .line = 0, .col = 0 });
            const cell = shapeCell(code);
            const float = cell != .none;
            if (sub == .ident and self.patternOnlyBinds(sub)) {
                const n = try self.bindName(sub.ident, cell.ty());
                try self.emit(.{ .local_get = subj });
                try self.emit(.{ .load = .{ .offset = @intCast(i * 4) } });
                try self.emitFromCell(cell);
                try self.emitConvert(cell.ty(), self.locals.get(n) orelse "i32");
                try self.emit(.{ .local_set = n });
                try self.noteTupleElemLocal(n, code);
                try self.tuple_binders.put(self.reg_arena.allocator(), n, {});
                continue;
            }
            if (float or sub == .numberLit or sub == .stringLit) continue;
            const field = try std.fmt.allocPrint(self.arena(), "__case_{d}", .{self.case_depth});
            self.case_depth += 1;
            try self.declareLocal(field, "i32");
            try self.noteTupleElemLocal(field, code);
            try self.emit(.{ .local_get = subj });
            try self.emit(.{ .load = .{ .offset = @intCast(i * 4) } });
            try self.emit(.{ .local_set = field });
            try self.bindPattern(sub, field);
        }
    }

    /// One end of a range pattern: `subj <op> bound`, the bound a number
    /// literal (a string bound has no wasm ordering yet and answers `0`).
    fn emitRangeBound(self: *Emitter, bound: ast.Pattern, subj: []const u8, cmp: []const u8, loc: ast.Loc) anyerror!void {
        switch (bound) {
            .numberLit => |n| {
                try self.emit(.{ .local_get = subj });
                const t = numLitType(n);
                if (t[0] == 'f') {
                    try self.emit(constOf("f64", n));
                    try self.emit(.{ .convert = "i32.trunc_f64_s" });
                } else try self.emit(try numLitConst(self.arena(), n));
                try self.emit(opOf("i32", cmp));
            },
            else => return self.refuse(loc, "the wasm backend tests a range pattern against a number literal bound only", .{}),
        }
    }

    /// A user variant's identity over a subject that may not be a value of its
    /// enum at all: an all-unit enum's member is its ordinal, which no pointer
    /// equals (a pointer is at least the heap floor); a payload enum's member
    /// is allocated and carries its variant's descriptor, so the test is the
    /// header one, never a load of what would be a record's first field.
    fn emitVariantIdentityTest(self: *Emitter, fv: FoundVariant, subj: []const u8, loc: ast.Loc) anyerror!void {
        if (enumHasPayload(fv.variants)) {
            var it = self.enums.iterator();
            while (it.next()) |entry| {
                if (entry.value_ptr.*.ptr != fv.variants.ptr) continue;
                const d = try self.variantDescriptorAddr(entry.key_ptr.*, fv.variant) orelse break;
                try self.emit(.{ .local_get = subj });
                try self.emit(try self.constInt(heap_floor));
                try self.emit(opOf("i32", "ge_u"));
                try self.emitHeaderLoad(subj);
                try self.emit(try self.constInt(d));
                try self.emit(opOf("i32", "eq"));
                try self.emit(opOf("i32", "and"));
                return;
            }
            return self.refuse(loc, "the wasm backend has no descriptor for the variant `{s}`, so the arm cannot be tested", .{fv.variant.name});
        }
        try self.emitTagTest(.{ .user = fv }, subj);
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
        if (self.aliases.get(n)) |a| return a;
        // A module-level `val` two linked modules declare: this module's
        // read means its own (mangled) one, unless a local shadows it.
        if (self.global_renames) |m| if (m.get(n)) |g| if (!self.locals.contains(n)) return g;
        return n;
    }

    /// The local a pattern binding `n` of wasm type `ty` is stored in: `n`
    /// itself, or — when `n` is already a local of another type — a fresh
    /// alias the arm's uses resolve to (until `emitCaseArms` drops it).
    fn bindName(self: *Emitter, n: []const u8, ty: []const u8) ![]const u8 {
        if (self.locals.get(n)) |existing| {
            // A binder over a name an enclosing statement list (or a
            // parameter) binds is a local of its own too: `case 5 { n -> … }`
            // under a `val n` wrote the outer `$n`.
            const shadows = self.bound_names.contains(n) or self.isParamLocal(n);
            if (shadows or (!std.mem.eql(u8, existing, ty) and !self.pattern_locals.contains(n))) {
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
    /// A record constructor in binding position (`val Circle(r) = s;`): the
    /// record's declared field names and, per position, the name each binds
    /// (`""` for `_`). Null when the pattern names no record of this module or
    /// nests a pattern (the checker refuses a nested one as refutable).
    fn ctorRecordFields(self: *Emitter, pat: ast.Pattern) ?struct { record: []const u8, fields: []const []const u8, binds: []const []const u8 } {
        if (pat != .variant) return null;
        const v = pat.variant;
        const name = bareVariantName(v.name);
        const fields = self.records.get(name) orelse return null;
        if (v.payload != .literals) return null;
        const lits = v.payload.literals;
        if (lits.len > fields.len) return null;
        const binds = self.arena().alloc([]const u8, lits.len) catch return null;
        for (lits, 0..) |l, i| binds[i] = switch (l) {
            .wildcard => "",
            .ident => |n| n,
            else => return null,
        };
        return .{ .record = name, .fields = fields, .binds = binds };
    }

    /// A variant constructor in binding position (`val Sq(side) = q;`) as the
    /// `case` arm pattern `bindPattern` already reads — its positional names
    /// as `.fields`. Null for a nested pattern or an unknown variant.
    fn ctorAsFieldsPattern(self: *Emitter, pat: ast.Pattern) !?ast.Pattern {
        if (pat != .variant) return null;
        const v = pat.variant;
        if (self.variantRef(v.name) == null) return null;
        if (v.payload != .literals) return pat;
        const lits = v.payload.literals;
        const names = try self.arena().alloc([]const u8, lits.len);
        for (lits, 0..) |l, i| names[i] = switch (l) {
            .wildcard => "_",
            .ident => |n| n,
            else => return null,
        };
        var out = v;
        out.payload = .{ .fields = names };
        return .{ .variant = out };
    }

    /// The enum `subject` is a value of, when its declared type names one:
    /// a parameter, a local, a field or a call typed by the enum, `self`
    /// inside the enum's own method, and a section written as a path
    /// (`Token.Layout.Break`), declared under the F1 mangling
    /// (`__Token__Layout__Break`).
    fn enumOfSubject(self: *Emitter, subject: ast.Expr) ?[]const u8 {
        const written: []const u8 = blk: {
            if (subject == .identifier and subject.identifier.kind == .ident and
                std.mem.eql(u8, subject.identifier.kind.ident, "self"))
            {
                if (self.self_type) |st| break :blk st;
            }
            const tr = self.typeRefOf(subject) orelse return null;
            break :blk switch (tr) {
                .named => |n| n,
                .generic => |g| g.name,
                else => return null,
            };
        };
        if (self.enums.contains(written)) return written;
        if (std.mem.indexOfScalar(u8, written, '.') == null) return null;
        var buf: std.ArrayListUnmanaged(u8) = .empty;
        var it = std.mem.splitScalar(u8, written, '.');
        while (it.next()) |seg| {
            buf.appendSlice(self.arena(), "__") catch return null;
            buf.appendSlice(self.arena(), seg) catch return null;
        }
        if (self.enums.getKey(buf.items)) |declared| return declared;
        return null;
    }

    /// The record a constructor pattern names (`Person(n, a)`), when no enum
    /// declares a variant of that name: the pattern is then the record's.
    fn recordPatternType(self: *Emitter, v: anytype) ?[]const u8 {
        if (v.shape != .variant or isResultPath(v.name)) return null;
        if (isVariantPath(v.name)) return null;
        if (self.findVariant(v.name) != null) return null;
        return self.resolveRecordName(v.name);
    }

    /// The field the i-th element of a record pattern stands at: its label,
    /// else the declared field at that position.
    fn recordPatternField(self: *Emitter, rty: []const u8, v: anytype, i: usize) ?[]const u8 {
        const fields = self.records.get(rty) orelse return null;
        if (v.labels.len > i and v.labels[i].len > 0) {
            for (fields) |f| if (std.mem.eql(u8, f, v.labels[i])) return f;
            return null;
        }
        return if (i < fields.len) fields[i] else null;
    }

    /// `subj.field` over the record `rty` in `subj`, as the source would
    /// write it — lowered by the field read every other access takes, a boxed
    /// float field included.
    fn recordFieldAccess(self: *Emitter, subj: []const u8, rty: []const u8, fname: []const u8) !ast.Expr {
        try self.local_types.put(subj, rty);
        const recv = try self.arena().create(ast.Expr);
        recv.* = .{ .identifier = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .ident = subj } } };
        return .{ .identifier = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .identAccess = .{ .receiver = recv, .member = fname } } } };
    }

    /// A local bound from a record field carries the field's declared shape.
    fn noteFieldBinder(self: *Emitter, n: []const u8, rty: []const u8, fname: []const u8) !void {
        const ft = self.fieldTypeIn(rty, fname) orelse return;
        if (std.mem.eql(u8, ft, "string")) try self.str_locals.put(n, {});
        if (std.mem.eql(u8, ft, "bool")) try self.bool_locals.put(n, {});
        if (self.resolveRecordName(ft)) |r| try self.local_types.put(n, r);
        // The binder carries the field's whole declared type, as a parameter
        // does: `Dog(age: a)` over `age: ?i32` is a `?i32`, so `a ?? 0`
        // unboxes it — read as a plain word, `"${a ?? 0}"` printed the box's
        // address.
        if (self.fieldTypeRefIn(rty, fname)) |t| try self.noteTypedBinder(n, t);
    }

    /// The local a multi-subject `case` holds its i-th subject in.
    fn multiSubjectLocal(a: std.mem.Allocator, subj: []const u8, i: usize) ![]const u8 {
        return std.fmt.allocPrint(a, "{s}_{d}", .{ subj, i });
    }

    fn bindPattern(self: *Emitter, p: ast.Pattern, subj: []const u8) anyerror!void {
        const prev_hint = self.case_enum_hint;
        self.case_enum_hint = self.subject_enums.get(subj);
        defer self.case_enum_hint = prev_hint;
        switch (p) {
            .multi => |pats| for (pats, 0..) |sub, i| {
                const local = try multiSubjectLocal(self.arena(), subj, i);
                // A primitive type names no binder.
                if (sub == .ident and self.unknown_subjects.contains(local) and primTestOf(.{ .named = sub.ident }) != null) continue;
                try self.bindPattern(sub, local);
            },
            .ident => |n0| if (!isLitPatternName(n0) and !isVariantPath(n0) and self.findVariant(n0) == null) {
                const n = try self.bindName(n0, "i32");
                if (self.str_locals.contains(subj)) try self.str_locals.put(n, {});
                try self.emit(.{ .local_get = subj });
                try self.emit(.{ .local_set = n });
            },
            .list => |l| try self.bindListPattern(l, subj),
            .variant => |v| {
                if (v.shape == .tuple) return self.bindTuplePattern(v, subj);
                // A record's constructor pattern binds each name from the
                // field it stands at — by label when the pattern wrote one.
                if (self.recordPatternType(v)) |rty| {
                    switch (v.payload) {
                        .binding => |bn| try self.bindPattern(.{ .ident = bn }, subj),
                        .fields => |fs| for (fs, 0..) |n0, i| {
                            if (std.mem.eql(u8, n0, "_")) continue;
                            const fname = self.recordPatternField(rty, v, i) orelse continue;
                            const acc = try self.recordFieldAccess(subj, rty, fname);
                            const ty = self.wasmTypeOf(acc);
                            const n = try self.bindName(n0, ty);
                            try self.lowerValue(acc);
                            try self.emitConvert(ty, self.locals.get(n) orelse ty);
                            try self.emit(.{ .local_set = n });
                            try self.noteFieldBinder(n, rty, fname);
                        },
                        .literals => |lits| for (lits, 0..) |sub, i| {
                            const fname = self.recordPatternField(rty, v, i) orelse continue;
                            const field = try std.fmt.allocPrint(self.arena(), "__case_{d}", .{self.case_depth});
                            self.case_depth += 1;
                            const acc = try self.recordFieldAccess(subj, rty, fname);
                            try self.declareLocal(field, self.wasmTypeOf(acc));
                            try self.lowerValue(acc);
                            try self.emit(.{ .local_set = field });
                            try self.noteFieldBinder(field, rty, fname);
                            try self.bindPattern(sub, field);
                        },
                    }
                    return;
                }
                const ref = self.variantRef(v.name) orelse return;
                switch (v.payload) {
                    .binding => |b| try self.bindPayloadName(ref, subj, 0, b),
                    .fields => |fs| for (fs, 0..) |n0, i| {
                        if (std.mem.eql(u8, n0, "_")) continue;
                        const slot = payloadSlot(ref, v, i) orelse continue;
                        try self.bindPayloadName(ref, subj, slot, n0);
                    },
                    // `Rect(w, _)`, `Two(Rect(w, _), r)`: a `_` binds nothing,
                    // a plain name binds its slot as `.fields` does, and a
                    // nested pattern binds from its slot's own local. This
                    // returned without binding anything, so every name of the
                    // payload read the 0 its local was declared with.
                    .literals => |lits| for (lits, 0..) |sub, i| {
                        if (sub == .wildcard) continue;
                        const slot = payloadSlot(ref, v, i) orelse continue;
                        if (sub == .ident and self.patternOnlyBinds(sub)) {
                            if (std.mem.eql(u8, sub.ident, "_")) continue;
                            try self.bindPayloadName(ref, subj, slot, sub.ident);
                            continue;
                        }
                        const field = try self.payloadFieldLocal(ref, subj, slot);
                        try self.bindPattern(sub, field);
                    },
                }
            },
            else => {},
        }
    }

    /// The payload slot (0-based, after the tag) the i-th element of a
    /// variant pattern stands at: the declared position of the label it wrote
    /// (§5.1 P4), else `i`. Null when the label names no declared field.
    fn payloadSlot(ref: VariantRef, v: anytype, i: usize) ?usize {
        if (v.labels.len > i and v.labels[i].len > 0) switch (ref) {
            .user => |fv| {
                for (fv.variant.fields, 0..) |f, at| if (std.mem.eql(u8, f.name, v.labels[i])) return at;
                return null;
            },
            else => {},
        };
        return i;
    }

    /// The declared type of payload slot `slot` of the variant `ref` names;
    /// null for `@Result`'s and an undeclared slot.
    fn payloadFieldType(ref: VariantRef, slot: usize) ?ast.TypeRef {
        return switch (ref) {
            .user => |fv| if (slot < fv.variant.fields.len) fv.variant.fields[slot].typeRef else null,
            else => null,
        };
    }

    /// Payload slot `slot` of the variant in `subj`, in a fresh i32 local a
    /// nested pattern is tested against and binds from — carrying the field's
    /// declared shape: a string, a record, and the enum a nested variant
    /// pattern resolves its bare name against (`subject_enums`).
    fn payloadFieldLocal(self: *Emitter, ref: VariantRef, subj: []const u8, slot: usize) ![]const u8 {
        const field = try std.fmt.allocPrint(self.arena(), "__case_{d}", .{self.case_depth});
        self.case_depth += 1;
        try self.declareLocal(field, "i32");
        try self.emit(.{ .local_get = subj });
        try self.emit(.{ .load = .{ .offset = @intCast((slot + 1) * 4) } });
        try self.emit(.{ .local_set = field });
        _ = self.subject_enums.remove(field);
        if (payloadFieldType(ref, slot)) |t| {
            if (isStringTypeRef(t)) try self.str_locals.put(field, {});
            if (isBoolTypeRef(t)) try self.bool_locals.put(field, {});
            try self.noteTypedBinder(field, t);
            const tn = typeRefName(t);
            if (self.enums.contains(tn)) try self.subject_enums.put(self.alloc, field, tn);
        }
        return field;
    }

    /// Bind `n0` to payload slot `slot` of the variant in `subj`, typed by the
    /// slot's declaration.
    fn bindPayloadName(self: *Emitter, ref: VariantRef, subj: []const u8, slot: usize, n0: []const u8) !void {
        const field_ty = payloadFieldType(ref, slot);
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
                if (if (ref == .result_ok) shape.ok else shape.err) |pt| try self.noteTypedBinder(n, pt);
            },
            else => {},
        }
        // payload slots are 4 bytes: a float field's holds its cell
        const slot_float = local_ty[0] == 'f';
        try self.emit(.{ .local_get = subj });
        try self.emit(.{ .load = .{ .offset = @intCast((slot + 1) * 4) } });
        if (slot_float) try self.emitFromFloatSlot();
        try self.emitConvert(if (slot_float) "f64" else "i32", local_ty);
        try self.emit(.{ .local_set = n });
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
        const desc = blk: {
            for (variants) |v| {
                if (std.mem.eql(u8, v.name, vname)) break :blk try self.variantDescriptorAddr(ename, v);
            }
            break :blk null;
        };
        const base = try self.allocTagged(desc orelse 0, 4);
        try self.storeSlotConst(base, tag_header_bytes, tag);
        try self.loadTaggedBase(base);
    }

    /// The `(if (result …) (then <arm body>) (else <rest of the chain>))` a
    /// tested case arm expands to. The arm's test is already on the stack.
    fn emitArmChain(self: *Emitter, arms: anytype, subj: []const u8, idx: usize, body: ast.Expr) anyerror!void {
        const ty = vt(self.cur_result);

        var then_c: Capture = .{};
        self.open(&then_c);
        const arm_aliases = try self.aliases.clone();
        try self.bindPattern(arms[idx].pattern, subj);
        // An arm naming a record over a union subject (`DogB { d -> … }`):
        // the binder is the record the test proved. It took the subject's
        // type, which a union has none of, so `d.name` printed an address.
        const prev_record = self.arm_record;
        defer self.arm_record = prev_record;
        self.arm_record = switch (arms[idx].pattern) {
            .ident => |n| if (!isVariantPath(n) and self.findVariant(n) == null and self.records.contains(n)) n else null,
            else => null,
        };
        if (arms[idx].guard) |g| {
            try self.emitGuardChain(arms, subj, idx, g);
        } else {
            try self.lowerArmBody(body, subj);
        }
        self.arm_record = prev_record;
        self.restoreAliases(arm_aliases);
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
        // Every allocation goes through `$__alloc`, the one bump that grows
        // the memory (decision 261); a zero-byte one only reads the pointer.
        if (nbytes > 0) {
            try self.emit(try self.constInt(nbytes));
            try self.emit(self.builder().helper(.alloc));
        } else {
            try self.emit(.{ .global_get = heap_ptr });
        }
        try self.emit(.{ .local_set = base });
        return base;
    }

    /// Store one 4-byte slot. A float operand goes in as the address of its
    /// own `f64` cell (`emitToFloatSlot`); narrowed to an `f32` in the slot,
    /// `1.1` read back as `1.100000023841858` at exit 0.
    fn storeSlotExpr(self: *Emitter, base: []const u8, offset: u32, value: ast.Expr) !void {
        try self.emit(.{ .local_get = base });
        try self.lowerSlotWord(value);
        try self.emit(.{ .store = .{ .offset = offset } });
    }

    /// Leave the word a 4-byte slot holds for `value`: a float's `f64` cell
    /// (`$__box_f64`), anything else the `i32` word itself.
    fn lowerSlotWord(self: *Emitter, value: ast.Expr) anyerror!void {
        if (self.wasmTypeOf(value)[0] == 'f') {
            try self.lowerCoerced(value, "f64");
            try self.emitToFloatSlot();
        } else try self.lowerCoerced(value, "i32");
    }

    /// Leave the address of `value`'s 8-byte `cell` — an `f64` or an `i64`
    /// — the word a declared field or optional of that type holds.
    fn lowerCellWord(self: *Emitter, value: ast.Expr, cell: Cell) anyerror!void {
        try self.lowerCoerced(value, cell.ty());
        try self.emit(self.builder().helper(switch (cell) {
            .f64 => .box_f64,
            .i64 => .box_i64,
            .none => unreachable,
        }));
    }

    /// The value a cell's address on the stack stands for.
    fn emitFromCell(self: *Emitter, cell: Cell) !void {
        if (cell != .none) try self.emit(.{ .load = .{ .ty = vt(cell.ty()) } });
    }

    /// The word an element of an array of `kind` holds for `value`: a float
    /// array's every element is an `f64` cell (an integer one too —
    /// `[1, 2.5]`), and a float never enters an array whose readers take
    /// words: `var xs = []; xs.push(0.15)` has no element type the backend
    /// can see, and its pointer printed as an integer at exit 0.
    fn lowerElemWord(self: *Emitter, kind: ElemKind, value: ast.Expr) anyerror!void {
        if (kind == .f64) {
            try self.lowerCoerced(value, "f64");
            return self.emitToFloatSlot();
        }
        if (self.wasmTypeOf(value)[0] == 'f')
            return self.refuse(value.getLoc(), "the wasm backend cannot place a float in this array: nothing types its elements as floats (write the array's type, `Array<f64>`)", .{});
        try self.lowerCoerced(value, "i32");
    }

    /// A float in a 4-byte word slot — an array or tuple element, a variant's
    /// payload, a `?f64`, a closure's capture — is the address of an 8-byte
    /// `f64` cell, as a record's float field is (`storeBoxedF64`): the `f64`
    /// on the stack becomes that address.
    fn emitToFloatSlot(self: *Emitter) !void {
        try self.emit(self.builder().helper(.box_f64));
    }

    /// The `f64` a float slot's word (the address of its cell) stands for.
    fn emitFromFloatSlot(self: *Emitter) !void {
        try self.emit(.{ .load = .{ .ty = .f64 } });
    }

    /// Store a float field of a named record: the 4-byte slot holds the
    /// address of an 8-byte `f64` cell, so the field keeps the precision its
    /// declared `f64` promises. Narrowed into the slot as an `f32`, `5e-324`
    /// was `0`, and a read that loaded the slot as an `i32` answered the float's
    /// bits (`1069547520` for `1.5`). `lowerIdentAccess` reads it back
    /// (`i32.load`, then `f64.load`).
    fn storeBoxedF64(self: *Emitter, base: []const u8, offset: u32, value: ast.Expr) !void {
        try self.emit(.{ .local_get = base });
        const cell = try self.allocSlots(8);
        try self.emit(.{ .local_get = cell });
        try self.lowerCoerced(value, "f64");
        try self.emit(.{ .store = .{ .ty = .f64 } });
        try self.emitC(.{ .local_get = cell }, "boxed f64 field");
        try self.emit(.{ .store = .{ .offset = offset } });
    }

    fn storeSlotConst(self: *Emitter, base: []const u8, offset: u32, value: i64) !void {
        try self.emit(.{ .local_get = base });
        try self.emit(try self.constInt(value));
        try self.emit(.{ .store = .{ .offset = offset } });
    }

    fn loadBase(self: *Emitter, base: []const u8) !void {
        try self.emit(.{ .local_get = base });
    }

    /// The VALUE of a tagged allocation: the pointer one header word past the
    /// base (13-module-identity half 3). The header sits BEHIND the pointer on
    /// purpose — every field offset stays what it was, so no read moved.
    fn loadTaggedBase(self: *Emitter, base: []const u8) !void {
        try self.emit(.{ .local_get = base });
        try self.emit(try self.constInt(tag_header_bytes));
        try self.emit(opOf("i32", "add"));
    }

    /// Allocate `nbytes` of payload behind a header holding `desc` — the
    /// address of the declaration's descriptor. Returns the BASE local; the
    /// payload starts at `tag_header_bytes`.
    fn allocTagged(self: *Emitter, desc: u32, nbytes: u32) ![]const u8 {
        const base = try self.allocSlots(tag_header_bytes + nbytes);
        try self.storeSlotConst(base, 0, desc);
        return base;
    }

    /// `i32.load` at `offset` — the emitter drops a zero `offset=`. Expects the
    /// base pointer on the stack.
    fn emitLoadOffset(self: *Emitter, offset: u32) !void {
        try self.emit(.{ .load = .{ .offset = offset } });
    }

    /// A tuple's slots are words: a float element holds its `f64` cell and a
    /// 64-bit integer (`i64`, `u32`, `u64`) its `i64` cell (`$__box_i64`),
    /// the codes `f` / `l` / `u` of its print shape (`valueShapeOf`), which
    /// every reader of an element goes by. The checker types each element by
    /// itself (`#(1, true)` is no `#(i64, bool)`), so the element's own type
    /// is the slot's. An `i64` element was refused as a narrowing.
    fn lowerTupleLit(self: *Emitter, tl: anytype) anyerror!void {
        return self.lowerTupleLitAs(tl, null);
    }

    /// The same, each element widened to the type `as` gives its slot when
    /// one is given: `pair(5) == #(5, true)` over a `#(u64, bool)`, where the
    /// checker typed the literal by the other operand and the `5` is a `u64`.
    fn lowerTupleLitAs(self: *Emitter, tl: anytype, as: ?[]const ast.TypeRef) anyerror!void {
        const base = try self.allocSlots(@intCast(tl.elems.len * 4));
        for (tl.elems, 0..) |el, i| {
            const want: ?ast.TypeRef = if (as) |ts| (if (i < ts.len) ts[i] else null) else null;
            const wide = if (want) |w| (w == .named and fieldCellOf(w.named) == .i64) else std.mem.eql(u8, self.wasmTypeOf(el), "i64");
            if (wide) {
                try self.emit(.{ .local_get = base });
                try self.lowerCellWord(el, .i64);
                try self.emit(.{ .store = .{ .offset = @intCast(i * 4) } });
            } else try self.storeSlotExpr(base, @intCast(i * 4), el);
        }
        try self.loadBase(base);
    }

    /// The cell a tuple element's shape code says its slot holds.
    fn shapeCell(code: []const u8) Cell {
        if (code.len == 0) return .none;
        return switch (code[0]) {
            'f' => .f64,
            'l', 'u' => .i64,
            else => .none,
        };
    }

    /// F4 — list literals over linear memory with an explicit i32 length
    /// prefix. Layout: `[len i32][elem0 i32][elem1 i32]...`. `.len` reads
    /// the prefix (`i32.load` at offset 0); element access via `arr[N]`
    /// is `i32.load offset=(N+1)*4`. Matches the string layout convention
    /// so `.len` is uniform across both. A trailing spread (`[1, 2, ..rest]`
    /// — the parser admits no other position) is the literal's elements
    /// followed by the spread value's, through `$__arr_concat`; before, the
    /// spread was dropped with a `;; note` and the array was two short.
    fn lowerArrayLit(self: *Emitter, al: anytype, loc: ast.Loc) anyerror!void {
        const total: u32 = @intCast((al.elems.len + 1) * 4);
        // One element kind for the whole literal (`elemKindOf`: a float
        // anywhere makes every slot a cell), which is the kind its readers ask.
        const kind = self.elemKindOf(.{ .collection = .{ .loc = loc, .kind = .{ .arrayLit = al } } });
        const base = try self.allocSlots(total);
        try self.storeSlotConst(base, 0, @intCast(al.elems.len));
        for (al.elems, 0..) |el, i| {
            const off: u32 = @intCast((i + 1) * 4);
            try self.emit(.{ .local_get = base });
            try self.lowerElemWord(kind, el);
            try self.emit(.{ .store = .{ .offset = off } });
        }
        try self.loadBase(base);
        if (al.spreadExpr) |se| {
            try self.lowerCoerced(se.*, "i32");
            try self.emit(self.builder().helper(.arr_concat));
        } else if (al.spread) |name| {
            if (name.len == 0) return self.refuse(loc, "a bare `..` in an array literal spreads nothing", .{});
            const rest = try self.arena().create(ast.Expr);
            rest.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = name } } };
            try self.lowerCoerced(rest.*, "i32");
            try self.emit(self.builder().helper(.arr_concat));
        }
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

    /// `@Greeter(greet: { self, who -> … })` — a record literal whose lambda
    /// fields take their parameter types from the behavior's declaration of
    /// the method, so `who` is a string inside the lifted lambda.
    fn lowerBehaviorLit(self: *Emitter, il: anytype) anyerror!void {
        _ = self.ensureAnonRecordFromLit(.{ .fields = il.fields }) catch {};
        const base = try self.allocSlots(@intCast(il.fields.len * 4));
        for (il.fields, 0..) |f, i| {
            var buf: [256]u8 = undefined;
            const key = std.fmt.bufPrint(&buf, "{s}.{s}", .{ il.name, f.name }) catch "";
            if (self.behavior_methods.get(key)) |m| {
                if (f.value.* == .function) self.expected_params = m.params;
            }
            defer self.expected_params = null;
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
            const sig = self.fn_sigs.get(mangled) orelse
                return self.refuse(loc, "`{s}` resolves to a method the wasm backend emitted no function for", .{mangled});
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
                const sig = self.fn_sigs.get(mangled) orelse
                    return self.refuse(loc, "`{s}` resolves to a method the wasm backend emitted no function for", .{mangled});
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
        if (self.calleeSymbol(cc, loc)) |sym| return sym;
        // A behavior-typed receiver dispatches (`lowerBehaviorDispatch`) to
        // implementers that all answer the method's one declared type, so
        // the first one says what the call answers — a string, a bool, an
        // array's elements.
        if (cc.receiver != null and !cc.is_builtin and self.dispatchesByValue(loc)) {
            const impls = self.behaviorImplementers(cc.callee, cc.args.len) catch return null;
            if (impls.len == 0) return null;
            return std.fmt.bufPrint(&self.sym_buf, "{s}_{s}", .{ impls[0], cc.callee }) catch null;
        }
        return null;
    }

    fn calleeSymbol(self: *Emitter, cc: anytype, loc: ast.Loc) ?[]const u8 {
        if (self.rewrites.get(loc)) |sym| {
            if (self.extMangledName(&self.sym_buf, sym, cc.callee)) |m| return m;
        }
        if (receiverName(cc)) |rn| {
            if (self.ext_by_name.contains(rn)) {
                if (self.extMangledName(&self.sym_buf, rn, cc.callee)) |m| return m;
            }
            if (self.assocSym(cc)) |m| {
                const generic = self.arena().dupe(u8, m) catch return m;
                return (self.specializeFor(generic, cc.args) catch null) orelse generic;
            }
        }
        if (self.specializedCallee(cc) catch null) |sym| return sym;
        if (self.fn_sigs.contains(cc.callee)) return cc.callee;
        return null;
    }

    /// A call to an ordinary (non-constructor, non-builtin) function. Arguments
    /// are coerced to the callee's declared parameter types and a short call is
    /// padded with zeros, so the emitted `call` always type-checks.
    ///
    /// A **host-backed `declare fn` that names another target and no `wasm`
    /// one is refused here**, at the call site, with the diagnostic commonJS,
    /// erlang and beam already print (06 C13's `MissingExternal`). It used to
    /// lower to `unreachable` "so the module still loads", which made wasm the
    /// only backend where such a program compiled and then trapped at run time
    /// — a silent divergence decision 67 rules out, and no flag turns it back
    /// on.
    ///
    /// A name nothing in the module, its linked imports, the primitive method
    /// table or a function value resolves is refused where it is written
    /// (`refuseUnlessTemplate`: in a generic body, an `unreachable` the
    /// concrete call that reaches it is refused for), and so is a call of a
    /// bodyless `declare fn` with no `#[@External.<Target>(…)]` at all. Both
    /// used to lower to `unreachable` "so the module still loads".
    fn lowerPlainCall(self: *Emitter, cc: anytype, loc: ast.Loc) anyerror!void {
        if (try self.specializedCallee(cc)) |sym| {
            var spec = cc;
            spec.callee = sym;
            return self.lowerPlainCall(spec, loc);
        }
        // The ONE body of a generic `fn` holds every type parameter as a word.
        // A float or an `i64` reaching it inside a parameter typed by one
        // (`first(#(1.1, 2))` over `#(A, B)`, `headOf([1.1])` over
        // `Array<T>`) is a cell that body reads as a word: `264` printed for
        // `1.1` at exit 0. No specialisation took it, so it is refused.
        if (self.generic_fns.get(self.import_aliases.get(cc.callee) orelse cc.callee)) |g| {
            var pi: usize = 0;
            for (g.decl.params) |p| {
                if (std.mem.eql(u8, p.name, "self")) continue;
                defer pi += 1;
                if (pi >= cc.args.len) break;
                // A bare `T` passes its argument through untouched (a float
                // one takes a specialised copy); a container OF one is read
                // inside by the body.
                if (p.typeRef == .named or !typeMentionsParam(p.typeRef, g.decl.genericParams)) continue;
                const arg = cc.args[pi].value.*;
                const sh = (try self.printShapeOf(arg)) orelse "";
                if (Cell.of(self.wasmTypeOf(arg)) != .none or std.mem.indexOfAny(u8, sh, "flu") != null)
                    return self.refuse(arg.getLoc(), "the wasm backend has one body for generic `{s}`, where `{s}`'s type parameter is a word: a float or an `i64` in it has no lowering", .{ cc.callee, p.name });
            }
        }
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
                if (ptref) |pt| if (plainIdentName(arg.value.*)) |an| if (!self.locals.contains(an)) {
                    if (try self.specializeByFnType(self.import_aliases.get(an) orelse an, pt)) |sym| {
                        try self.lowerFnRef(sym, null);
                        continue;
                    }
                };
                if (ptref) |pt| if (pt == .generic and self.record_generics.contains(pt.generic.name)) {
                    self.expected_ctor = pt;
                };
                defer self.expected_ctor = null;
                if (self.boxesInto(ptref, arg.value.*))
                    try self.lowerBoxedInto(ptref, arg.value.*)
                else
                    try self.lowerCoerced(arg.value.*, sig.params[base + i]);
            }
            var k = base + cc.args.len;
            while (k < sig.params.len) : (k += 1) {
                try self.emitC(constOf(sig.params[k], "0"), "missing argument");
            }
            const callee = self.import_aliases.get(cc.callee) orelse cc.callee;
            if (self.generic_fns.contains(callee)) try self.noteTemplateCall(callee, loc);
            try self.emit(.{ .call = callee });
            return;
        }
        // A method on a behavior-typed value — or on a receiver inference
        // placed nowhere (a lambda parameter typed by an alias naming the
        // behavior) — is answered by the value's own type at run time.
        if (cc.receiver != null and !cc.is_builtin and self.dispatchesByValue(loc)) {
            if (try self.lowerBehaviorDispatch(cc)) return;
        }
        if (try self.lowerCollectionMethod(cc)) return;
        if (try self.lowerValueCall(cc)) return;
        if (cc.receiver == null and self.external_missing.contains(cc.callee)) {
            self.missing_external = .{ .name = cc.callee, .target = "wasm", .loc = loc };
            return error.MissingExternalTarget;
        }
        if (cc.receiver == null and self.host_fns.contains(cc.callee)) {
            return self.refuse(loc, "`{s}` is a bodyless `declare fn` with no `#[@External.<Target>(…)]`: the wasm backend has nothing to call", .{cc.callee});
        }
        // `Ok(v)` / `Err(e)` / `new Error(msg)` outside the `#[@result]`
        // transform build the same `[tag, payload]` pair as `__bp_ok` /
        // `__bp_error` — the lowering beam and erlang give them (`{error, Msg}`).
        // A user enum variant of the same name was matched before this.
        if (cc.receiver == null and cc.args.len == 1 and cc.trailing.len == 0 and self.findVariant(cc.callee) == null) {
            if (self.variantRef(cc.callee)) |ref| switch (ref) {
                .result_ok => return self.lowerResultOptionOp("__bp_ok", cc.args, loc),
                .result_err => return self.lowerResultOptionOp("__bp_error", cc.args, loc),
                .user => {},
            };
        }
        return self.refuseUnlessTemplate(loc, "the wasm backend cannot resolve the call `{s}/{d}`: no function, method, variant or function value of the module or its imports answers it", .{ cc.callee, cc.args.len });
    }

    // ── primitive instance methods ───────────────────────────────────────────
    //
    // `xs.join(",")`, `s.toUpper()`, `n.abs()`: inference records the
    // receiver's primitive family at the call loc (`instance_lowerings`), and
    // the method lowers to an opcode, a runtime helper from
    // `wat/wat_prelude.zig`, or — for a higher-order method whose argument is a
    // literal lambda — a loop over the array blob with the lambda body inlined
    // (there are no function values to pass). A method with no wasm lowering
    // is refused at the call (`primNotLowered`).

    /// The primitive family of `recv.method(…)`'s receiver, when inference
    /// recorded one.
    fn primKindAt(self: *Emitter, cc: anytype, loc: ast.Loc) ?envMod.PrimKind {
        if (cc.receiver == null or cc.is_builtin) return null;
        // In a specialisation the substituted type is the answer: inference
        // saw a type variable (`x: T`, `xs: Array<A>`) and recorded nothing,
        // or a dispatch by value where the type is now a primitive.
        if (self.in_spec) if (self.typeRefOf(cc.receiver.?.*)) |tr| {
            const k: ?envMod.PrimKind = switch (tr) {
                .named => |n| primKindOfName(n),
                .array => .array,
                .generic => |g| if (std.mem.eql(u8, g.name, "Array")) .array else null,
                else => null,
            };
            if (k) |kk| return kk;
        };
        const il = self.instance_lowerings.get(loc) orelse {
            // A tuple pattern's binder (`#(n, "x") { n.toString() }`):
            // inference recorded no lowering at its loc, and the binder's
            // declared type — the element's, `noteTupleElemLocal` — says
            // which primitive it is. It was an `unresolved call` trap.
            //
            // A method call answering a primitive inside an adopted
            // behavior `default fn` (`self.twice().toString()` in `Sq`'s
            // copy of `Shape.label`): inference typed the body against
            // `Self`, so the call's result was a type variable and no
            // lowering was recorded. The callee's declared return —
            // `Sq_twice -> i32` — is the primitive, when it has the method.
            // It trapped in `Sq_label` (`unresolved call: toString/0`).
            const recv = cc.receiver.?.*;
            if (recv == .call) {
                const tr = self.typeRefOf(recv) orelse return null;
                const k = switch (tr) {
                    .named => |tn| primKindOfName(tn) orelse return null,
                    else => return null,
                };
                return if (primCallRes(k, cc) != null) k else null;
            }
            const n = plainIdentName(recv) orelse return null;
            if (!self.tuple_binders.contains(n)) return null;
            const tr = self.local_typerefs.get(n) orelse return null;
            return switch (tr) {
                .named => |tn| primKindOfName(tn),
                else => null,
            };
        };
        return switch (il) {
            .prim => |k| k,
            .type_, .field_of, .sequence_next, .division, .by_value, .unplaced_type => null,
        };
    }

    // ── a method on the rest of a `?.` chain ─────────────────────────────────
    //
    // `es.at(1)?.key.length().toString()`: the `?.` makes EVERYTHING after it
    // conditional — absent short-circuits the whole chain — but only the link
    // written with `?.` carried the guard. The next method started from a
    // carrier that may be `0` and read it as a string (`length` loaded a
    // length from address 0, the WASI iovec, at exit 0) or found no receiver
    // type at all (`unresolved call: toString/0`, a trap). A primitive method
    // whose receiver is such a chain is lowered under the same guard: absent
    // stays `0`, present unboxes the receiver, runs the method on it, and
    // boxes a scalar result — so the whole expression is the `?T` the checker
    // typed it as, and prints `null` or its value.

    /// Whether `e` is, or continues, a `?.` chain.
    fn isOptionalChain(e: ast.Expr) bool {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .identAccess => |ia| ia.optional or isOptionalChain(ia.receiver.*),
                else => false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| cc.optional or (if (cc.receiver) |r| isOptionalChain(r.*) else false),
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| isOptionalChain(inner.*),
                else => false,
            },
            else => false,
        };
    }

    /// The primitive family of the PAYLOAD of an optional-chain receiver:
    /// what inference recorded for it, what the previous guarded link answers,
    /// or a string field read through `?.`.
    fn chainPayloadKind(self: *Emitter, recv: ast.Expr) ?envMod.PrimKind {
        switch (recv) {
            .call => |c| switch (c.kind) {
                .call => |inner| if (self.chainedCallKind(inner, c.loc)) |k| {
                    return switch (primCallRes(k, inner) orelse return null) {
                        .i32 => .int,
                        .bool_ => .bool,
                        .str => .string,
                        .arr => .array,
                        .f64, .none => null,
                    };
                },
                else => {},
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.chainPayloadKind(inner.*),
                else => {},
            },
            // `x?.n` — a field read through the chain: its declared type. A
            // float field has no chained lowering here, so it is left to the
            // unguarded path.
            .identifier => |id| switch (id.kind) {
                .identAccess => |ia| if (self.recordTypeOfExpr(ia.receiver.*)) |rty| {
                    if (self.fieldTypeIn(rty, ia.member)) |ft| {
                        if (std.mem.eql(u8, ft, "string")) return .string;
                        if (std.mem.eql(u8, ft, "bool")) return .bool;
                        for ([_][]const u8{ "i32", "i64", "u32", "u64", "int" }) |n| {
                            if (std.mem.eql(u8, ft, n)) return .int;
                        }
                        return null;
                    }
                },
                else => {},
            },
            else => {},
        }
        if (self.isStringExpr(recv)) return .string;
        return null;
    }

    /// The family `cc`'s receiver has once the chain is present — only for a
    /// call that continues a `?.` chain and is not itself the `?.` link.
    fn chainedCallKind(self: *Emitter, cc: anytype, loc: ast.Loc) ?envMod.PrimKind {
        if (cc.optional or cc.is_builtin) return null;
        const recv = cc.receiver orelse return null;
        if (!isOptionalChain(recv.*)) return null;
        if (self.primKindAt(cc, loc)) |k| return k;
        return self.chainPayloadKind(recv.*);
    }

    /// What a guarded chain link leaves: a boxed scalar or a pointer (`0` is
    /// absence either way). Null when the link is not one this lowers — a
    /// float result has no box here.
    fn chainedCallOpt(self: *Emitter, cc: anytype, loc: ast.Loc) ?OptInfo {
        const k = self.chainedCallKind(cc, loc) orelse return null;
        return switch (primCallRes(k, cc) orelse return null) {
            .i32 => .{ .boxed = true },
            .bool_ => .{ .boxed = true, .bool_ = true },
            .str => .{ .boxed = false, .str = true },
            .arr => .{ .boxed = false },
            .f64, .none => null,
        };
    }

    fn lowerChainedCall(self: *Emitter, cc: anytype, loc: ast.Loc) anyerror!bool {
        const res = self.chainedCallOpt(cc, loc) orelse return false;
        const k = self.chainedCallKind(cc, loc).?;
        const recv = cc.receiver.?.*;
        const recv_boxed = if (self.optInfoOf(recv)) |oi| oi.boxed else false;
        const mem = try self.memName(self.nextMem());
        try self.lowerValue(recv);
        try self.emit(.{ .local_tee = mem });
        try self.emit(opOf("i32", "eqz"));

        var then_c: Capture = .{};
        self.open(&then_c);
        try self.emitC(zero, "?. chain: absent");
        const then_seq = self.seal(&then_c, .{ .value = .i32 });

        var else_c: Capture = .{};
        self.open(&else_c);
        if (recv_boxed) {
            try self.emit(.{ .local_get = mem });
            try self.emitC(.{ .load = .{} }, "?. chain: unbox");
            try self.emit(.{ .local_set = mem });
        }
        if (k == .string) try self.str_locals.put(mem, {});
        const payload = try self.arena().create(ast.Expr);
        payload.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = mem } } };
        var link = cc;
        link.receiver = payload;
        try self.lowerPrimMethod(k, link);
        if (res.boxed) try self.emit(self.builder().helper(.box_i32));
        const else_seq = self.seal(&else_c, .{ .value = .i32 });

        try self.emit(.{ .@"if" = .{
            .result = .i32,
            .then = .{ .seq = then_seq },
            .@"else" = .{ .seq = else_seq },
        } });
        return true;
    }

    /// What a primitive method leaves on the stack. Null: no wasm lowering.
    const PrimRes = enum { i32, f64, bool_, str, arr, none };

    /// The primitive kinds a behavior of `primitives.bp` covers — the ones a
    /// program's own `behavior <Name>` extends (01-checker). Arrays are not
    /// here as `.array`: its defaults' `Self<T>` is the receiver's written
    /// array type in the copy (`primDefaultSelf`).
    fn primBehaviorKinds(name: []const u8) []const envMod.PrimKind {
        const eq = std.mem.eql;
        if (eq(u8, name, "String")) return &.{.string};
        if (eq(u8, name, "Bool")) return &.{.bool};
        if (eq(u8, name, "Number")) return &.{ .int, .float };
        for ([_][]const u8{ "Integer", "Signed", "I32", "I64", "U32", "U64" }) |n| if (eq(u8, name, n)) return &.{.int};
        for ([_][]const u8{ "Float", "F32", "F64" }) |n| if (eq(u8, name, n)) return &.{.float};
        if (eq(u8, name, "Array")) return &.{.array};
        return &.{};
    }

    fn primDefaultOf(self: *Emitter, k: envMod.PrimKind, name: []const u8) ?PrimDefault {
        var buf: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&buf, "{s}.{s}", .{ @tagName(k), name }) catch return null;
        return self.prim_defaults.get(key);
    }

    /// The type `Self` is in a primitive default's copy for kind `k`.
    fn primSelfType(k: envMod.PrimKind) []const u8 {
        return switch (k) {
            .string => "string",
            .bool => "bool",
            .int => "i32",
            .float => "f64",
            .array => "i32",
        };
    }

    /// `primCallRes`, and what a program's own primitive `default fn`
    /// answers by its declared return (`Self` the receiver's kind).
    fn primRes(self: *Emitter, k: envMod.PrimKind, cc: anytype) ?PrimRes {
        if (primCallRes(k, cc)) |r| return r;
        const pd = self.primDefaultOf(k, cc.callee) orelse return null;
        if (pd.method.params.len != cc.args.len + 1) return null;
        if (k == .array) {
            // The copy's declared return, `Self<T>` and `T` written in.
            const sym = (self.ensurePrimDefault(k, pd, cc.receiver.?.*) catch return null);
            const rt = self.fn_ret_typerefs.get(sym) orelse return .none;
            return switch (rt) {
                .array, .generic => .arr,
                .named => |n| if (std.mem.eql(u8, n, "string")) .str else if (std.mem.eql(u8, n, "bool")) .bool_ else if (isFloatTypeName(n)) .f64 else .i32,
                else => .i32,
            };
        }
        const rt = pd.method.returnType orelse return .none;
        const n = switch (rt) {
            .named => |n| n,
            .array, .generic => return .arr,
            else => return .i32,
        };
        const t = if (std.mem.eql(u8, n, "Self")) primSelfType(k) else n;
        if (std.mem.eql(u8, t, "string")) return .str;
        if (std.mem.eql(u8, t, "bool")) return .bool_;
        if (isFloatTypeName(t)) return .f64;
        return .i32;
    }

    /// `"a+b".tailShout()` over a program's `behavior String { default fn
    /// tailShout(self: Self) … }`: a copy of the default with `Self` written
    /// as the receiver's primitive (`String_tailShout__string`), emitted once
    /// like a specialisation, called with the receiver as `self`. It trapped
    /// (`prim method not lowered on wasm`) — every program-declared default
    /// of a primitive did.
    fn lowerPrimDefault(self: *Emitter, k: envMod.PrimKind, pd: PrimDefault, cc: anytype) anyerror!void {
        const sym = try self.ensurePrimDefault(k, pd, cc.receiver.?.*);
        const sig = self.fn_sigs.get(sym).?;
        try self.lowerCoerced(cc.receiver.?.*, sig.params[0]);
        try self.lowerCallArgs(cc.args, sig, 1);
        try self.emit(.{ .call = sym });
    }

    /// The element type an `Array<T>` default's copy writes for `T`: the
    /// receiver's record, a bool by its shape, else its element kind.
    fn primArrayElemName(self: *Emitter, recv: ast.Expr) []const u8 {
        if (self.elemRecordOf(recv)) |r| return r;
        if (self.elemIsBool(recv) catch false) return "bool";
        return switch (self.elemKindOf(recv)) {
            .str => "string",
            .f64 => "f64",
            .i32 => "i32",
        };
    }

    /// The copy of a program's primitive default for a receiver of kind `k`,
    /// registered (its signature, its declared return) and queued once;
    /// its symbol.
    fn ensurePrimDefault(self: *Emitter, k: envMod.PrimKind, pd: PrimDefault, recv: ast.Expr) ![]const u8 {
        const ar = self.reg_arena.allocator();
        const elem: []const u8 = if (k == .array) self.primArrayElemName(recv) else "";
        const st = if (k == .array) try std.fmt.allocPrint(ar, "arr_{s}", .{elem}) else primSelfType(k);
        const mname = try std.fmt.allocPrint(ar, "{s}__{s}", .{ pd.method.name, st });
        const sym = try std.fmt.allocPrint(ar, "{s}_{s}", .{ pd.behavior, mname });
        if (!self.spec_names.contains(sym)) {
            try self.spec_names.put(self.alloc, sym, {});
            var subs_l: std.ArrayListUnmanaged(TypeSub) = .empty;
            if (k == .array) {
                const inner = try ar.create(ast.TypeRef);
                inner.* = .{ .named = elem };
                try subs_l.append(ar, .{ .name = "Self", .to = .{ .array = inner } });
                for (pd.tparams) |gp| try subs_l.append(ar, .{ .name = gp.name, .to = .{ .named = elem } });
            } else try subs_l.append(ar, .{ .name = "Self", .to = .{ .named = st } });
            const subs = subs_l.items;
            var m = try substTypeParams(ast.BehaviorMethod, ar, pd.method, subs);
            m.name = mname;
            // A method of the behavior, `self` its first parameter — the
            // member emission path (`emitMemberFn`) keeps it.
            try self.registerInterfaceSigs(pd.behavior, &.{}, &.{m});
            try self.mspec_pending.append(self.alloc, .{
                .owner = pd.behavior,
                .tparams = &.{},
                .method = m,
                .rewrites = self.rewrites,
                .lowerings = self.instance_lowerings,
                .renames = self.global_renames,
                .origin = self.foreign_origin,
            });
        }
        return sym;
    }

    fn primCallRes(k: envMod.PrimKind, cc: anytype) ?PrimRes {
        const name: []const u8 = cc.callee;
        const argc = cc.args.len + cc.trailing.len;
        const Row = struct { []const u8, usize, PrimRes };
        const rows: []const Row = switch (k) {
            .array => &.{
                .{ "length", 0, .i32 },     .{ "at", 1, .i32 },        .{ "first", 0, .i32 },
                .{ "find", 1, .i32 },       .{ "join", 1, .str },      .{ "indexOf", 1, .i32 },
                .{ "contains", 1, .bool_ }, .{ "isEmpty", 0, .bool_ }, .{ "reverse", 0, .arr },
                .{ "prepend", 1, .arr },    .{ "append", 1, .arr },    .{ "push", 1, .none },
                .{ "zip", 1, .arr },        .{ "slice", 1, .arr },     .{ "slice", 2, .arr },
                .{ "rest", 0, .arr },       .{ "take", 1, .arr },      .{ "drop", 1, .arr },
                .{ "toList", 0, .arr },     .{ "map", 1, .arr },       .{ "filter", 1, .arr },
                .{ "forEach", 1, .none },   .{ "all", 1, .bool_ },     .{ "every", 1, .bool_ },
                .{ "any", 1, .bool_ },      .{ "some", 1, .bool_ },    .{ "count", 1, .i32 },
                .{ "findIndex", 1, .i32 },  .{ "fold", 2, .i32 },      .{ "lastIndexOf", 1, .i32 },
                .{ "pop", 0, .i32 },        .{ "unique", 0, .arr },    .{ "flatten", 0, .arr },
                .{ "flat", 0, .arr },       .{ "flatMap", 1, .arr },   .{ "chunked", 1, .arr },
                .{ "sliding", 1, .arr },    .{ "fill", 1, .arr },
            },
            .string => &.{
                .{ "length", 0, .i32 },     .{ "toUpper", 0, .str },      .{ "toLower", 0, .str },
                .{ "contains", 1, .bool_ }, .{ "startsWith", 1, .bool_ }, .{ "endsWith", 1, .bool_ },
                .{ "indexOf", 1, .i32 },    .{ "trim", 0, .str },         .{ "trimStart", 0, .str },
                .{ "trimEnd", 0, .str },    .{ "split", 1, .arr },        .{ "slice", 1, .str },
                .{ "slice", 2, .str },      .{ "repeat", 1, .str },       .{ "toString", 0, .str },
                // `Index<i32, string>.at` (decision 63's amendment) — a
                // `?string`, absent as the pointer 0. `.str` is its stack
                // shape; `optInfoOf` is what routes the print through
                // `$__print_opt_str`, and `$__str_at` is the lowering.
                .{ "at", 1, .str },
                // `00 · 05-wasm` step 6's audit: the rest of `primitives.bp`'s
                // `String` that has a byte-level answer.
                        .{ "charCodeAt", 1, .i32 },   .{ "lastIndexOf", 1, .i32 },
                .{ "padStart", 2, .str },   .{ "padEnd", 2, .str },       .{ "replace", 2, .str },
                .{ "replaceAll", 2, .str }, .{ "chars", 0, .arr },        .{ "lines", 0, .arr },
                .{ "words", 0, .arr },
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
                .{ "round", 0, .f64 }, .{ "squareRoot", 0, .f64 }, .{ "toString", 0, .str },
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

    /// `lambdaAt`, and a FUNCTION NAMED as the argument (`xs.map(inc)`, a
    /// local or an imported fn, or a local holding a function value): the
    /// lambda `{ p0, … -> name(p0, …) }` with the `arity` parameters the
    /// method hands it, inlined like any other. It trapped — `map needs a
    /// literal lambda`.
    fn hofLambdaAt(self: *Emitter, cc: anytype, i: usize, arity: usize) !?LambdaView {
        if (lambdaAt(cc, i)) |l| return l;
        if (i >= cc.args.len) return null;
        const a = cc.args[i].value.*;
        const name = switch (a) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| n,
                else => return null,
            },
            else => return null,
        };
        const ar = self.arena();
        const params = try ar.alloc([]const u8, arity);
        const args = try ar.alloc(ast.CallArg, arity);
        for (params, args, 0..) |*p, *arg, k| {
            p.* = try std.fmt.allocPrint(ar, "__hof{d}_{d}", .{ self.loop_seq, k });
            const v = try ar.create(ast.Expr);
            v.* = .{ .identifier = .{ .loc = a.identifier.loc, .kind = .{ .ident = p.* } } };
            arg.* = .{ .label = null, .value = v };
        }
        self.loop_seq += 1;
        const body = try ar.alloc(ast.Stmt, 1);
        body[0] = .{ .expr = .{ .call = .{ .loc = a.identifier.loc, .kind = .{ .call = .{
            .receiver = null,
            .callee = name,
            .is_builtin = false,
            .args = args,
            .trailing = &.{},
        } } } } };
        return .{ .params = params, .body = body };
    }

    /// `$__arr_unique`'s equality for the elements of `recv`: `0` the slot's
    /// word (an integer, a bool, an all-unit enum's ordinal), `1` its cell's `f64`,
    /// `2` a string's content. Null for an element whose `!=` this backend
    /// has no lowering for — a record, an array, a tuple —, which is refused.
    fn uniqueMode(self: *Emitter, recv: ast.Expr) anyerror!?i32 {
        if (self.elemRecordOf(recv) != null) return null;
        if (try self.printShapeOf(recv)) |sh| {
            if (sh.len < 2 or sh[0] != '[') return null;
            return switch (sh[1]) {
                'i', 'b', 'E' => 0,
                'f' => 1,
                's' => 2,
                else => null,
            };
        }
        return switch (self.elemKindOf(recv)) {
            .i32 => 0,
            .f64 => 1,
            .str => 2,
        };
    }

    /// The print shape of what a HOF lambda's body answers, asked with its
    /// element parameter bound (as `elemKindOf`'s `map` arm asks).
    fn lambdaTailShape(self: *Emitter, lam: LambdaView, recv: ast.Expr) anyerror!?[]const u8 {
        if (lam.body.len == 0) return null;
        const last = lam.body[lam.body.len - 1].expr;
        const v = switch (last) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |x| x.* else return null,
                else => return null,
            },
            else => last,
        };
        const held = self.holdElemParam(lam, recv);
        defer self.releaseElemParam(held);
        return self.printShapeOf(v);
    }

    fn lambdaTailIsBool(self: *Emitter, lam: LambdaView, recv: ast.Expr) bool {
        if (lam.body.len == 0) return false;
        const last = lam.body[lam.body.len - 1].expr;
        const v = switch (last) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |x| x.* else return false,
                else => return false,
            },
            else => last,
        };
        const held = self.holdElemParam(lam, recv);
        defer self.releaseElemParam(held);
        return self.isBoolExpr(v);
    }

    /// The print shape of the arrays `05-wasm` step 1's methods build, read
    /// off their receiver: `unique` keeps it, `flatten`/`flat` drop one `[`,
    /// `flatMap` is its function's array, `chunked`/`sliding` add one, `fill`
    /// is an array of its value. Null for any other call.
    fn newArrShape(self: *Emitter, cc: anytype, loc: ast.Loc) anyerror!?[]const u8 {
        const k = self.primKindAt(cc, loc) orelse return null;
        if (k != .array or cc.receiver == null) return null;
        const recv = cc.receiver.?.*;
        const eq = std.mem.eql;
        const name: []const u8 = cc.callee;
        if (primCallRes(k, cc) == null) return null;
        // `xs.map(f)` answering a bool or a container: an array of it. A bool
        // printed `1`, a nested array its rows' addresses.
        if (eq(u8, name, "map")) {
            const lam = lambdaAt(cc, 0) orelse return null;
            if (try self.lambdaTailShape(lam, recv)) |sh| return try std.fmt.allocPrint(self.arena(), "[{s}", .{sh});
            if (self.lambdaTailIsBool(lam, recv)) return "[b";
            return null;
        }
        if (eq(u8, name, "unique")) return self.printShapeOf(recv);
        if (eq(u8, name, "flatten") or eq(u8, name, "flat")) {
            const sh = (try self.printShapeOf(recv)) orelse return null;
            return if (sh.len >= 2 and sh[0] == '[' and sh[1] == '[') sh[1..] else null;
        }
        if (eq(u8, name, "flatMap")) {
            const lam = lambdaAt(cc, 0) orelse return null;
            const sh = (try self.lambdaTailShape(lam, recv)) orelse return null;
            return if (sh[0] == '[') sh else null;
        }
        if (eq(u8, name, "chunked") or eq(u8, name, "sliding")) {
            const inner = (try self.printShapeOf(recv)) orelse
                try std.fmt.allocPrint(self.arena(), "[{c}", .{elemCode(self.elemKindOf(recv))});
            return try std.fmt.allocPrint(self.arena(), "[{s}", .{inner});
        }
        if (eq(u8, name, "fill")) {
            const v = callArg(cc, 0) orelse return null;
            return try std.fmt.allocPrint(self.arena(), "[{s}", .{try self.valueShapeOf(v)});
        }
        return null;
    }

    fn primNotLowered(self: *Emitter, k: envMod.PrimKind, cc: anytype) anyerror!void {
        return self.refuseUnlessTemplate(self.call_loc, "the wasm backend has no lowering for the {s} method `{s}/{d}`", .{
            @tagName(k), cc.callee, cc.args.len + cc.trailing.len,
        });
    }

    fn lowerPrimMethod(self: *Emitter, k: envMod.PrimKind, cc: anytype) anyerror!void {
        if (primCallRes(k, cc) == null) {
            if (self.primDefaultOf(k, cc.callee)) |pd| if (pd.method.params.len == cc.args.len + 1)
                return self.lowerPrimDefault(k, pd, cc);
            return self.primNotLowered(k, cc);
        }
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
                // An `i64` answers its text in all its digits; its other
                // methods have no `i64` lowering here, and the narrowing
                // below refuses them.
                if (std.mem.eql(u8, self.wasmTypeOf(recv), "i64") and eq(u8, name, "toString")) {
                    try self.lowerValue(recv);
                    try self.emit(b.helper(if (self.isU64Expr(recv)) .u64_to_str else .i64_to_str));
                    return;
                }
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
                } else if (eq(u8, name, "toString")) {
                    try self.emit(b.helper(.f64_to_str));
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
            // Decision 240: a string's length counts codepoints.
            try self.emit(b.helper(.str_cp_len));
        } else if (eq(u8, name, "toUpper") or eq(u8, name, "toLower")) {
            const upper = eq(u8, name, "toUpper");
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
        } else if (eq(u8, name, "lines")) {
            try self.emit(b.helper(.str_lines));
        } else if (eq(u8, name, "words")) {
            try self.emit(b.helper(.str_words));
        } else if (eq(u8, name, "chars")) {
            // One fresh string per UTF-8 codepoint: `$__str_split` with an
            // empty separator cuts before every codepoint.
            const empty = try self.internString("");
            try self.emit(try self.constInt(empty.offset));
            try self.emit(b.helper(.str_split));
        } else if (eq(u8, name, "padStart") or eq(u8, name, "padEnd")) {
            try self.lowerCoerced(callArg(cc, 0).?, "i32");
            try self.lowerCoerced(callArg(cc, 1).?, "i32");
            try self.emit(try self.constInt(@as(i32, if (eq(u8, name, "padStart")) 1 else 0)));
            try self.emit(b.helper(.str_pad));
        } else if (eq(u8, name, "replace") or eq(u8, name, "replaceAll")) {
            try self.lowerCoerced(callArg(cc, 0).?, "i32");
            try self.lowerCoerced(callArg(cc, 1).?, "i32");
            try self.emit(try self.constInt(@as(i32, if (eq(u8, name, "replaceAll")) 1 else 0)));
            try self.emit(b.helper(.str_replace));
        } else {
            try self.lowerCoerced(callArg(cc, 0).?, "i32");
            if (eq(u8, name, "at")) {
                try self.emit(b.helper(.str_cp_at));
            } else if (eq(u8, name, "contains")) {
                try self.emit(b.helper(.str_index_of));
                try self.emit(try self.constInt(-1));
                try self.emit(opOf("i32", "ne"));
            } else if (eq(u8, name, "indexOf")) {
                try self.emit(b.helper(.str_cp_index_of));
            } else if (eq(u8, name, "startsWith")) {
                try self.emit(b.helper(.str_starts_with));
            } else if (eq(u8, name, "endsWith")) {
                try self.emit(b.helper(.str_ends_with));
            } else if (eq(u8, name, "split")) {
                try self.emit(b.helper(.str_split));
            } else if (eq(u8, name, "charCodeAt")) {
                try self.emit(b.helper(.str_char_code));
            } else if (eq(u8, name, "lastIndexOf")) {
                try self.emit(b.helper(.str_cp_last_index_of));
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
            const lam = (try self.hofLambdaAt(cc, if (h == .fold) 1 else 0, if (h == .fold) 2 else 1)) orelse {
                return self.refuseUnlessTemplate(self.call_loc, "`{s}` on the wasm backend takes a closure written at the call; a function value is not lowered", .{name});
            };
            return self.lowerArrayHof(@intFromEnum(h), recv, lam, if (h == .fold) callArg(cc, 0) else null);
        }
        if (eq(u8, name, "push")) return self.lowerArrayPush(cc);
        if (eq(u8, name, "pop")) return self.lowerArrayPop(cc);
        // `xs.find(pred)` is `xs.filter(pred).at(0)` — `primitives.bp`'s own
        // body — as the `?T` `at` answers (`arrayElemOpt`: a scalar boxed, a
        // pointer as itself).
        if (eq(u8, name, "find")) {
            const lam = (try self.hofLambdaAt(cc, 0, 1)) orelse {
                return self.refuseUnlessTemplate(self.call_loc, "`{s}` on the wasm backend takes a closure written at the call; a function value is not lowered", .{name});
            };
            try self.lowerArrayHof(@intFromEnum(Hof.filter), recv, lam, null);
            try self.emit(zero);
            try self.emit(b.helper(self.arrAtHelper(recv)));
            return;
        }
        // `xs.flatMap(f)` is `primitives.bp`'s own body, `xs.map(f).flatten()`
        // — when what `f` answers is known to be an array. Anything else has
        // no flattening this backend can answer by: a refusal, never a guess.
        if (eq(u8, name, "flatMap")) {
            const lam = (try self.hofLambdaAt(cc, 0, 1)) orelse {
                return self.refuseUnlessTemplate(self.call_loc, "`{s}` on the wasm backend takes a closure written at the call; a function value is not lowered", .{name});
            };
            const tail = (try self.lambdaTailShape(lam, recv)) orelse
                return self.refuseUnlessTemplate(self.call_loc, "`flatMap` on the wasm backend: nothing shows that its function answers an array", .{});
            if (tail[0] != '[')
                return self.refuseUnlessTemplate(self.call_loc, "`flatMap` on the wasm backend: its function answers no array, so there is nothing to flatten", .{});
            try self.lowerArrayHof(@intFromEnum(Hof.map), recv, lam, null);
            try self.emit(b.helper(.arr_flatten));
            return;
        }
        if (eq(u8, name, "flatten") or eq(u8, name, "flat")) {
            const sh = (try self.printShapeOf(recv)) orelse "";
            if (!(sh.len >= 2 and sh[0] == '[' and sh[1] == '[')) {
                return self.refuseUnlessTemplate(self.call_loc, "`{s}` on the wasm backend: nothing shows that the receiver's elements are arrays", .{name});
            }
            try self.lowerCoerced(recv, "i32");
            try self.emit(b.helper(.arr_flatten));
            return;
        }
        if (eq(u8, name, "unique")) {
            const mode = (try self.uniqueMode(recv)) orelse {
                return self.refuseUnlessTemplate(self.call_loc, "`unique` on the wasm backend compares integers, floats, bools and strings; these elements (a record, an array, a tuple) have no equality here", .{});
            };
            try self.lowerCoerced(recv, "i32");
            try self.emit(try self.constInt(mode));
            try self.emit(b.helper(.arr_unique));
            return;
        }
        if (eq(u8, name, "fill")) {
            const v = callArg(cc, 0).?;
            try self.lowerCoerced(recv, "i32");
            try self.emitC(.{ .load = .{} }, "element count");
            // The result holds `v`s whatever the receiver held (its shape is
            // `v`'s, `newArrShape`): a float fills every slot with the one
            // cell — a cell is never written again, so sharing it is sharing
            // a value.
            try self.lowerSlotWord(v);
            try self.emit(b.helper(.arr_fill));
            return;
        }
        if (eq(u8, name, "chunked") or eq(u8, name, "sliding")) {
            try self.lowerCoerced(recv, "i32");
            try self.lowerCoerced(callArg(cc, 0).?, "i32");
            try self.emit(b.helper(if (eq(u8, name, "chunked")) .arr_chunked else .arr_sliding));
            return;
        }

        try self.lowerCoerced(recv, "i32");
        const elem = self.elemKindOf(recv);
        if (eq(u8, name, "length")) {
            try self.emitC(.{ .load = .{} }, "element count");
        } else if (eq(u8, name, "isEmpty")) {
            try self.emitC(.{ .load = .{} }, "element count");
            try self.emit(opOf("i32", "eqz"));
        } else if (eq(u8, name, "at") or eq(u8, name, "first")) {
            // `?T`: a pointer element (a string, a record) is its own offset; a
            // scalar is boxed. `arrayElemOpt` is the ONE place that decides,
            // and `optInfoOf` reads the same answer — see its doc comment.
            if (eq(u8, name, "first")) try self.emit(zero) else try self.lowerCoerced(callArg(cc, 0).?, "i32");
            try self.emit(b.helper(self.arrAtHelper(recv)));
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
                if (callArg(cc, 1)) |end| {
                    if (isNullLit(end)) try self.emit(whole) else try self.lowerSliceEnd(end);
                } else try self.emit(whole);
            }
            try self.emit(b.helper(.arr_slice));
        } else {
            const arg = callArg(cc, 0).?;
            if (eq(u8, name, "join")) {
                try self.lowerCoerced(arg, "i32");
                try self.emit(b.helper(if (elem == .str) .arr_join_str else if (elem == .f64) .arr_join_f64 else .arr_join_i32));
            } else if (eq(u8, name, "lastIndexOf")) {
                if (elem == .f64) {
                    try self.lowerCoerced(arg, "f64");
                    try self.emit(b.helper(.arr_last_index_of_f64));
                } else {
                    try self.lowerCoerced(arg, "i32");
                    try self.emit(b.helper(if (elem == .str or self.isStringExpr(arg)) .arr_last_index_of_str else .arr_last_index_of_i32));
                }
            } else if (eq(u8, name, "indexOf") or eq(u8, name, "contains")) {
                if (elem == .f64) {
                    try self.lowerCoerced(arg, "f64");
                    try self.emit(b.helper(.arr_index_of_f64));
                } else {
                    try self.lowerCoerced(arg, "i32");
                    try self.emit(b.helper(if (elem == .str or self.isStringExpr(arg)) .arr_index_of_str else .arr_index_of_i32));
                }
                if (eq(u8, name, "contains")) {
                    try self.emit(try self.constInt(-1));
                    try self.emit(opOf("i32", "ne"));
                }
            } else {
                // `prepend` takes an element (a float as its cell), `append`
                // and `zip` an array.
                if (eq(u8, name, "prepend")) try self.lowerElemWord(elem, arg) else try self.lowerCoerced(arg, "i32");
                try self.emit(b.helper(if (eq(u8, name, "prepend")) .arr_prepend else if (eq(u8, name, "append")) .arr_concat else .arr_zip));
            }
        }
    }

    /// Decision 122 — `seq.next()` by hand. The eager sequence is an array blob
    /// (`[len][e0][e1]…`), so the step is its head: the prelude `YieldStep`'s
    /// `Yield(e0)` when `len > 0`, `Done` otherwise. A local receiver is then
    /// rebound to the rest (`$__arr_slice(seq, 1, len)`, a copy — an alias of
    /// the same sequence keeps its items), as `push` rebinds it, so the next
    /// `.next()` reads on. The item is copied as one 4-byte slot, which is
    /// what every element layout of the blob is.
    fn lowerSequenceNext(self: *Emitter, cc: anytype) anyerror!void {
        const recv = cc.receiver.?.*;
        const variants = self.enums.get("YieldStep") orelse {
            return self.refuse(self.call_loc, "`.next()` on a sequence: `YieldStep` is not declared in this module", .{});
        };
        var yield_tag: ?u32 = null;
        var done_tag: ?u32 = null;
        for (variants, 0..) |v, i| {
            if (std.mem.eql(u8, v.name, "Yield")) yield_tag = @intCast(i);
            if (std.mem.eql(u8, v.name, "Done")) done_tag = @intCast(i);
        }
        const yi = yield_tag orelse return self.refuse(self.call_loc, "`.next()` on a sequence: `YieldStep` declares no `Yield`", .{});
        const di = done_tag orelse return self.refuse(self.call_loc, "`.next()` on a sequence: `YieldStep` declares no `Done`", .{});
        const local: ?[]const u8 = switch (recv) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| if (self.locals.contains(n)) n else null,
                else => null,
            },
            else => null,
        };

        const seq = try self.memName(self.nextMem());
        try self.lowerCoerced(recv, "i32");
        try self.emit(.{ .local_tee = seq });
        try self.emitC(.{ .load = .{} }, "items left");

        var then_c: Capture = .{};
        self.open(&then_c);
        const desc = try self.variantDescriptorAddr("YieldStep", variants[yi]);
        const base = try self.allocTagged(desc orelse 0, 8);
        try self.storeSlotConst(base, tag_header_bytes, yi);
        try self.emit(.{ .local_get = base });
        try self.emit(.{ .local_get = seq });
        try self.emitC(.{ .load = .{ .offset = 4 } }, "the head");
        try self.emit(.{ .store = .{ .offset = tag_header_bytes + 4 } });
        if (local) |n| {
            try self.emit(.{ .local_get = seq });
            try self.emit(try self.constInt(1));
            try self.emit(.{ .local_get = seq });
            try self.emit(.{ .load = .{} });
            try self.emit(self.builder().helper(.arr_slice));
            try self.emitCf(.{ .local_set = n }, "{s} = the rest", .{n});
        }
        try self.loadTaggedBase(base);
        const then_seq = self.seal(&then_c, .{ .value = .i32 });

        var else_c: Capture = .{};
        self.open(&else_c);
        try self.emitUnitVariant(variants, di, "YieldStep", "Done");
        const else_seq = self.seal(&else_c, .{ .value = .i32 });

        try self.emit(.{ .@"if" = .{
            .result = .i32,
            .then = .{ .seq = then_seq },
            .@"else" = .{ .seq = else_seq },
        } });
    }

    /// `xs.push(v)` — the blob has a fixed size, so the receiver is rebound to
    /// a copy with `v` appended (the erlang backend threads the same way). A
    /// receiver that is not a name or a record field cannot be rebound.
    /// `xs.pop()` on a local: the last element as the `?T` `xs.at(-1)`
    /// answers (`arrayElemOpt` decides the box, as for `at`), then the local
    /// rebound to `xs.slice(0, len - 1)` — `pop` SHRINKS the array, and a
    /// blob is a value here, as `push` rebinds it to a grown copy. An empty
    /// array answers absent and stays empty (`arr_slice` clamps `-1` to 0).
    fn lowerArrayPop(self: *Emitter, cc: anytype) anyerror!void {
        const recv = cc.receiver.?.*;
        const n = switch (recv) {
            .identifier => |id| switch (id.kind) {
                .ident => |n0| blk: {
                    const n = self.resolveName(n0);
                    break :blk if (self.locals.contains(n) or self.globals.contains(n)) n else null;
                },
                else => null,
            },
            else => null,
        } orelse {
            // A field of a record whose type is known here — `push`'s field
            // path: the last element, then the field rewritten one shorter.
            if (recv == .identifier and recv.identifier.kind == .identAccess) {
                const ia = recv.identifier.kind.identAccess;
                if (self.recordTypeOfExpr(ia.receiver.*)) |rty| if (self.fieldOffsetIn(rty, ia.member)) |off| {
                    const b = self.builder();
                    const owner = try self.memName(self.nextMem());
                    const arr = try self.memName(self.nextMem());
                    try self.lowerValue(ia.receiver.*);
                    try self.emit(.{ .local_tee = owner });
                    try self.emit(.{ .load = .{ .offset = off } });
                    try self.emit(.{ .local_tee = arr });
                    try self.emit(try self.constInt(-1));
                    try self.emit(b.helper(self.arrAtHelper(recv)));
                    try self.emit(.{ .local_get = owner });
                    try self.emit(.{ .local_get = arr });
                    try self.emit(zero);
                    try self.emit(.{ .local_get = arr });
                    try self.emitC(.{ .load = .{} }, "element count");
                    try self.emit(one);
                    try self.emit(opOf("i32", "sub"));
                    try self.emit(b.helper(.arr_slice));
                    try self.emitCf(.{ .store = .{ .offset = off } }, ".{s} = pop", .{ia.member});
                    return;
                };
            }
            // Any other receiver — a call's result, an element — may be an
            // array some other name still holds, which `pop` shrinks in
            // place on the other backends; a copy here would leave it whole.
            return self.refuse(self.call_loc, "`pop` on the wasm backend rebinds its receiver, which must be a local, a module `var` or a field of a record whose type is known here", .{});
        };
        const b = self.builder();
        const get: Instr = if (self.locals.contains(n)) .{ .local_get = n } else .{ .global_get = n };
        try self.emit(get);
        try self.emit(try self.constInt(-1));
        try self.emit(b.helper(self.arrAtHelper(recv)));
        try self.emit(get);
        try self.emit(zero);
        try self.emit(get);
        try self.emitC(.{ .load = .{} }, "element count");
        try self.emit(one);
        try self.emit(opOf("i32", "sub"));
        try self.emit(b.helper(.arr_slice));
        try self.emit(if (self.locals.contains(n)) .{ .local_set = n } else .{ .global_set = n });
    }

    fn lowerArrayPush(self: *Emitter, cc: anytype) anyerror!void {
        const recv = cc.receiver.?.*;
        const arg = callArg(cc, 0) orelse {
            return self.refuse(self.call_loc, "`push` with no value to push", .{});
        };
        switch (recv) {
            .identifier => |id| switch (id.kind) {
                .ident => |n0| if (self.locals.contains(self.resolveName(n0)) or self.globals.contains(self.resolveName(n0))) {
                    const n = self.resolveName(n0);
                    try self.lowerCoerced(recv, "i32");
                    try self.lowerElemWord(self.elemKindOf(recv), arg);
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
                    try self.lowerElemWord(self.elemKindOf(recv), arg);
                    try self.emit(self.builder().helper(.arr_push));
                    try self.emitCf(.{ .store = .{ .offset = off } }, ".{s} = push", .{ia.member});
                    return;
                },
                else => {},
            },
            else => {},
        }
        return self.refuse(self.call_loc, "`push` on the wasm backend rebinds its receiver, which must be a local, a module `var` or a field of a record whose type is known here", .{});
    }

    /// A higher-order array method over a literal lambda: a counted walk of the
    /// `[len][e0][e1]…` blob with the lambda's parameters bound to locals and
    /// its body inlined per element. `hof` is `lowerArrayMethod`'s `Hof`.
    fn lowerArrayHof(self: *Emitter, hof: u8, recv: ast.Expr, lam: LambdaView, init_expr: ?ast.Expr) anyerror!void {
        const scope_mark = self.scopeMark();
        defer self.scopeRestore(scope_mark);
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
        const elem_ty: []const u8 = if (elem_kind == .f64) "f64" else "i32";
        // fold binds (acc, item); the others bind (item).
        const acc_param0: ?[]const u8 = if (hof == fold and lam.params.len > 0) lam.params[0] else null;
        const elem_param0: ?[]const u8 = if (hof == fold)
            (if (lam.params.len > 1) lam.params[1] else null)
        else if (lam.params.len > 0) lam.params[0] else null;
        // A binder over a name the function already binds (`val e = 5;
        // xs.forEach({ e -> … })`) is a local of its own — read `e` after the
        // walk and it answered the last element.
        const acc_ty: []const u8 = if (hof == fold) (if (init_expr) |i| self.wasmTypeOf(i) else "i32") else "i32";
        const acc_param: ?[]const u8 = if (acc_param0) |p| try self.bindTargetAs(p, acc_ty) else null;
        const elem_param: ?[]const u8 = if (elem_param0) |p| try self.bindTargetAs(p, elem_ty) else null;
        try self.declareLocal(acc, acc_ty);
        if (hof == map or hof == filter) try self.declareLocal(out, "i32");
        if (elem_param) |p| {
            try self.declareLocal(p, elem_ty);
            try self.noteElemShape(p, recv);
            if (elem_kind == .str) try self.str_locals.put(p, {});
            if (try self.elemIsBool(recv)) try self.bool_locals.put(p, {});
            // An element of a generic record whose type arguments are known
            // (`ctorTypeRef`) keeps them, so `p.matched()` specialises.
            if (self.elemTypeRefOf(recv)) |et| if (et == .generic and self.record_generics.contains(et.generic.name)) try self.local_typerefs.put(p, et);
            // An element of an `unknown[]` is an `unknown` (its own header):
            // `v is i32` reads the box, not a guess at a static type
            // (`run/is_truth_table`).
            if (self.elemTypeRefOf(recv)) |et| if (isUnknownTypeRef(et)) try self.local_typerefs.put(p, et);
            // The parameter is one ELEMENT, so it has the element's record
            // type. Without it a field read off it had no receiver type and
            // fell to the unique-field guess, or to the `0` stub.
            if (self.elemRecordOf(recv)) |r| try self.local_types.put(p, r);
        }
        if (acc_param) |p| {
            try self.declareLocal(p, acc_ty);
            if (init_expr) |i| if (self.isStringExpr(i)) try self.str_locals.put(p, {});
        }

        try self.lowerCoerced(recv, "i32");
        try self.emit(.{ .local_set = base });
        if (elem_param0) |p| self.installShadow(p, elem_param.?);
        if (acc_param0) |p| self.installShadow(p, acc_param.?);
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
            try self.emitAt(8, .{ .load = .{ .offset = 4 } });
            if (elem_kind == .f64) try self.emitAt(8, .{ .load = .{ .ty = .f64 } });
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
                try self.emitConvert(tail_ty, if (is_float) "f64" else "i32");
                if (is_float) try self.emitToFloatSlot();
                try self.emit(.{ .store = .{ .offset = 4 } });
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

    /// `f64`: each slot holds the address of the element's `f64` cell
    /// (`emitToFloatSlot`).
    const ElemKind = enum { i32, f64, str };

    /// The element shape a `T[]` / `Array<T>` type spells, when it is an array.
    fn arrayElemOfTypeRef(t: ast.TypeRef) ?ElemKind {
        const elem: ast.TypeRef = switch (eagerTypeRef(t)) {
            .array => |inner| inner.*,
            // An iterator runs eagerly here: it is the array of what it yields.
            .generic => |g| if (g.args.len == 1 and (std.mem.eql(u8, g.name, "Array") or
                std.mem.eql(u8, g.name, "Iterator") or std.mem.eql(u8, g.name, "Stream")))
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
                .f64
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
        if (self.elemRecordOfTypeRef(t)) |rec| try self.arr_elem_recs.put(sym, rec);
        if (resultShapeOfTypeRef(t)) |shape| try self.result_shape_locals.put(sym, shape);
    }

    /// A binder the source did not annotate but whose type is known from
    /// where it is bound — a `case` arm's `Ok(v)` / `Error(e)` over a declared
    /// `@Result`, a `for` element over a declared array or iterator: it gets
    /// everything a parameter of that type gets, so a string payload prints as
    /// text, a record payload's fields are found, a nested `@Result` can be
    /// matched again.
    fn noteTypedBinder(self: *Emitter, sym: []const u8, t: ast.TypeRef) !void {
        if (self.resolveRecordName(typeRefName(t))) |rty| try self.local_types.put(sym, rty);
        try self.noteParamShape(sym, t);
        try self.local_typerefs.put(sym, t);
    }

    /// The declared element type of what a `for` walks — an array, an
    /// `Array<T>`, an eager `@Iterator<T>` / `@Stream<T>` — when its type is
    /// known.
    fn elemTypeRefOf(self: *Emitter, e: ast.Expr) ?ast.TypeRef {
        const t = eagerTypeRef(self.typeRefOf(e) orelse return null);
        return switch (t) {
            .array => |inner| inner.*,
            .generic => |g| if (g.args.len == 1 and (std.mem.eql(u8, g.name, "Array") or
                std.mem.eql(u8, g.name, "Iterator") or std.mem.eql(u8, g.name, "Stream")))
                g.args[0]
            else
                null,
            else => null,
        };
    }

    /// A local bound to something `isArrayExpr` recognises is an array too,
    /// with the element shape of its initialiser.
    fn noteArrayLocal(self: *Emitter, name: []const u8, value: ast.Expr) !void {
        if (try self.printShapeOf(value)) |shape| try self.print_shape_locals.put(name, shape);
        if (!self.isArrayExpr(value)) return;
        try self.arr_locals.put(name, {});
        try self.arr_elem_locals.put(name, self.elemKindOf(value));
        if (self.elemRecordOf(value)) |rec| try self.arr_elem_recs.put(name, rec) else _ = self.arr_elem_recs.remove(name);
    }

    /// A local whose written type is an array: the element shape, kind and
    /// record the TYPE names, over whatever its initialiser suggested.
    fn noteAnnotatedArray(self: *Emitter, name: []const u8, ta: ast.TypeRef) !void {
        if (ta == .optional) return;
        const ek = arrayElemOfTypeRef(ta) orelse return;
        try self.arr_locals.put(name, {});
        try self.arr_elem_locals.put(name, ek);
        if (try self.typeRefShape(ta)) |sh| try self.print_shape_locals.put(name, sh);
        if (self.elemRecordOfTypeRef(ta)) |rec| try self.arr_elem_recs.put(name, rec);
    }

    /// The shape `$__print_shaped_raw` walks for `e` (semantics decision 1a):
    /// `i` an i32, `f` a float's cell, `b` a bool, `s` a string, `[X` an array of
    /// `X`, `(XY…)` a tuple. Null when `e` is not known to be an array or a
    /// tuple.
    fn printShapeOf(self: *Emitter, e: ast.Expr) anyerror!?[]const u8 {
        if (self.genericResultOf(e)) |a| return self.printShapeOf(a);
        if (self.unitEnumOf(e)) |en| return try self.unitEnumShape(en);
        // `o ?? d` (decision 330: `?T`'s `unwrapOr` is `??`) answers the
        // payload or `d`, one type — read as `o.unwrapOr(d)` is below.
        if (nullishParts(e)) |nu| {
            if (self.optInfoOf(nu.opt.*)) |oi| if (oi.shape) |sh| return sh;
            if (!isEmptyArrayLit(nu.dflt)) if (try self.printShapeOf(nu.dflt)) |sh| return sh;
        }
        if (optOperatorParts(e)) |op| if (op.bang) if (self.optInfoOf(op.cond.*)) |oi| if (oi.shape) |sh| return sh;
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| if (self.print_shape_locals.get(self.resolveName(n))) |shape| return shape,
                // A tuple element that is itself a container — `t._0` of
                // `#(#(1, 2), "x")`. The same slice `isStringExpr` takes, kept
                // only when it is an array or a tuple, which is this
                // function's contract.
                .identAccess => if (try self.tupleElemShapeOf(e)) |el| {
                    if (el[0] == '[' or el[0] == '(') return el;
                },
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
                    if (self.isTaggedValue(al.elems[0])) return "[T";
                    // A bool is an `i32` slot like an integer; only the shape
                    // tells the printer to write `true` (`[1, 0]` at exit 0).
                    if (self.isBoolExpr(al.elems[0])) return "[b";
                },
                else => {},
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    // `o.unwrapOr(d)` answers the payload or `d`, one type:
                    // the payload's declared shape (`r.unwrapOr([])` over an
                    // `@Result<Array<#(string, string)>, …>`), the optional's
                    // own, or a container default's (`pairs.at(1).unwrapOr(
                    // #("", ""))._1`) — an empty `[]` says nothing. Each
                    // printed a string's address at exit 0.
                    if (isUnwrapOr(cc)) {
                        if (self.typeRefOf(cc.args[0].value.*)) |tr| if (tr == .generic and tr.generic.args.len == 2 and
                            std.mem.endsWith(u8, tr.generic.name, "Result"))
                        {
                            if (try self.typeRefShape(tr.generic.args[0])) |sh| return sh;
                        };
                        if (self.optInfoOf(cc.args[0].value.*)) |oi| if (oi.shape) |sh| return sh;
                        if (!isEmptyArrayLit(cc.args[1].value.*)) if (try self.printShapeOf(cc.args[1].value.*)) |sh| return sh;
                    }
                    if (std.mem.eql(u8, cc.callee, "zip") and cc.args.len == 1 and cc.receiver != null) {
                        if (self.primKindAt(cc, c.loc) == .array) return try std.fmt.allocPrint(self.arena(), "[({c}{c})", .{
                            elemCode(self.elemKindOf(cc.receiver.?.*)),
                            elemCode(self.elemKindOf(cc.args[0].value.*)),
                        });
                    }
                    // `rows[1]` keeps the shape of one element of `rows`.
                    if (try self.indexElemShape(cc)) |inner| return inner;
                    if (try self.newArrShape(cc, c.loc)) |sh| return sh;
                    // `rows.reverse()`, `bs.filter(…)`: the receiver's elements,
                    // so the receiver's shape — a nested array printed its
                    // rows' addresses, a bool array `[1, 0]`.
                    if (cc.receiver != null and keepsElements(cc.callee)) if (self.primKindAt(cc, c.loc)) |k| if (k == .array) {
                        if (try self.printShapeOf(cc.receiver.?.*)) |sh| return sh;
                    };
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
            .f64 => "[f",
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
                    if (el == .optional) {
                        const oi = self.optInfoOfTypeRef(el) orelse return null;
                        try out.appendSlice(self.arena(), (try self.optElemShape(oi, null)) orelse return null);
                        continue;
                    }
                    if (try self.typeRefShape(el)) |inner| {
                        try out.appendSlice(self.arena(), inner);
                        continue;
                    }
                    // A 64-bit integer element's slot holds its cell.
                    if (el == .named) if (i64CellCode(el.named)) |c| {
                        try out.append(self.arena(), c);
                        continue;
                    };
                    try out.append(self.arena(), scalarCode(el) orelse return null);
                }
                try out.append(self.arena(), ')');
                return out.items;
            },
            .array => |inner| return self.arrayTypeShape(inner.*),
            .generic => |g| {
                if (g.args.len == 1 and std.mem.eql(u8, g.name, "Array")) return self.arrayTypeShape(g.args[0]);
                // A generic record (`Queue<i32>`) carries its declaration too.
                if (self.records.contains(g.name)) return "T";
            },
            // A written record type: the element carries its own declaration.
            .named => |n| {
                if (self.records.contains(n)) return "T";
                if (self.isAllUnitEnum(n)) return try self.unitEnumShape(n);
            },
            else => {},
        }
        return null;
    }

    fn arrayTypeShape(self: *Emitter, elem: ast.TypeRef) anyerror!?[]const u8 {
        if (try self.typeRefShape(elem)) |inner| return try std.fmt.allocPrint(self.arena(), "[{s}", .{inner});
        // An array OF arrays of a scalar — `i32[][]` — is a container whose
        // elements are pointers (`elemIsPointer`), whatever its innermost
        // code: without the shape, `rows.at(1)` boxed the row's address and
        // printed it as a number.
        const nested: ?ast.TypeRef = switch (elem) {
            .array => |ie| ie.*,
            .generic => |g| if (g.args.len == 1 and std.mem.eql(u8, g.name, "Array")) g.args[0] else null,
            else => null,
        };
        if (nested) |ie| if (scalarCode(ie)) |c| return try std.fmt.allocPrint(self.arena(), "[[{c}", .{c});
        return switch (scalarCode(elem) orelse return null) {
            's' => "[s",
            'b' => "[b",
            else => null,
        };
    }

    /// The shape of a record written as a FIELD's type is `T` — its own
    /// header names it, and `$__print_shaped_raw`'s `T` arm reads that.
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

    /// The shape of the element `t._N` reads — **scalar codes included**, which
    /// is what tells it apart from `printShapeOf`. `printShapeOf(t)` already
    /// builds the whole tuple's shape (`((ii)s)` for `#(#(1, 2), "x")`, `(si)`
    /// for a `#(name: string, pop: i32)`), so element `N` only has to be sliced
    /// out of it; nothing else in this backend knew an element's type.
    ///
    /// Both readers of an element need it and neither could ask the other:
    /// `printShapeOf`'s contract is to answer only containers, while
    /// `isStringExpr` is the question `@print` asks about a **single** value.
    /// While only the container half existed, `@print(t.1)` and `@print(row.name)`
    /// printed the element's heap address — `256` where they mean `x` and `SP` —
    /// with exit 0 and no diagnostic.
    ///
    /// A label is not a case here: the checker resolves `row.name` to `row._0`
    /// before this backend sees it (decision 8 §6 T4), so the member is always
    /// `_N` or a bare `N`.
    fn tupleElemShapeOf(self: *Emitter, e: ast.Expr) anyerror!?[]const u8 {
        const ia = switch (e) {
            .identifier => |id| switch (id.kind) {
                .identAccess => |a| a,
                else => return null,
            },
            else => return null,
        };
        if (ia.optional) return null;
        const idx = tupleIndex(ia.member) orelse return null;
        const sh = (try self.printShapeOf(ia.receiver.*)) orelse return null;
        return tupleShapeElem(sh, idx);
    }

    /// The length of the element shape starting at `sh[0]`: `i`/`f`/`b`/`s` are
    /// one byte, `[X` is one plus its element's, `(XY…)` runs to its `)`. The
    /// Zig twin of `$__print_shaped_raw`'s `go = 0` measuring mode, and it has
    /// to agree with it — the two walk the same strings.
    fn shapeSpan(sh: []const u8) usize {
        if (sh.len == 0) return 0;
        switch (sh[0]) {
            '[', '?', '!' => return 1 + shapeSpan(sh[1..]),
            '(' => {
                var i: usize = 1;
                while (i < sh.len and sh[i] != ')') {
                    const n = shapeSpan(sh[i..]);
                    if (n == 0) return i;
                    i += n;
                }
                return if (i < sh.len) i + 1 else i;
            },
            else => return 1,
        }
    }

    /// Element `idx` of the tuple shape `sh` (`(XY…)`), or null when `sh` is
    /// not a tuple shape or has no such element.
    fn tupleShapeElem(sh: []const u8, idx: u32) ?[]const u8 {
        if (sh.len == 0 or sh[0] != '(') return null;
        var i: usize = 1;
        var k: u32 = 0;
        while (i < sh.len and sh[i] != ')') {
            const n = shapeSpan(sh[i..]);
            if (n == 0) return null;
            if (k == idx) return sh[i .. i + n];
            i += n;
            k += 1;
        }
        return null;
    }

    /// The shape of one element of a tuple.
    fn valueShapeOf(self: *Emitter, e: ast.Expr) anyerror![]const u8 {
        // A `?T` element: its slot is the optional's carrier, `0` absence.
        // Read through its payload's code it printed the box's address
        // (`#(1, 328)` for `#(1, [7].at(0))`) at exit 0.
        // One whose payload is not known here is refused — in a generic
        // body, the body is marked instead (`template_traps`): a concrete
        // call that reaches it unspecialised is refused at the call.
        if (self.optInfoOf(e)) |oi| {
            if (try self.optElemShape(oi, e)) |sh| return sh;
            if (self.cur_template) |t| {
                try self.template_traps.put(self.reg_arena.allocator(), t, {});
                return "!i";
            }
            return self.refuse(e.getLoc(), "the wasm backend has no printed form for this optional inside a tuple or an array: its payload's type is not known here", .{});
        }
        if (try self.printShapeOf(e)) |shape| return shape;
        // A value that carries its own declaration reads its text from the
        // header (13-module-identity half 3), so a tuple or an array holding
        // one names its type too.
        if (self.isTaggedValue(e)) return "T";
        if (self.isStringExpr(e)) return "s";
        if (self.isBoolExpr(e)) return "b";
        if (self.wasmTypeOf(e)[0] == 'f') return "f";
        if (std.mem.eql(u8, self.wasmTypeOf(e), "i64")) return if (self.isU64Expr(e)) "u" else "l";
        return "i";
    }

    /// The print shape of a `?T` held in a tuple's or an array's slot:
    /// `?X` when the slot is the payload's own pointer (a string, a record, a
    /// container) or its 8-byte cell (`?f64`, `?i64`), `!X` when the payload
    /// is a scalar in a `$__box_i32` cell — `0` is absence in both, printed
    /// `null`. Null when the payload's code is not known here (a `?T` over a
    /// type parameter, an all-unit enum): the caller refuses.
    fn optElemShape(self: *Emitter, oi: OptInfo, e: ?ast.Expr) anyerror!?[]const u8 {
        _ = e;
        const inner_name: ?[]const u8 = if (oi.inner) |inner| switch (inner) {
            .named => |n| n,
            else => null,
        } else null;
        if (oi.boxed) {
            if (oi.cell == .f64) return "?f";
            if (oi.cell == .i64) return if (optIsU64(oi)) "?u" else "?l";
            if (oi.bool_) return "!b";
            const n = inner_name orelse return if (oi.inner == null) "!i" else null;
            if (std.mem.eql(u8, n, "bool")) return "!b";
            return if (scalarCode(.{ .named = n }) == @as(?u8, 'i')) "!i" else null;
        }
        if (oi.str) return "?s";
        if (oi.rec != null) return "?T";
        if (oi.shape) |sh| return try std.fmt.allocPrint(self.arena(), "?{s}", .{sh});
        if (oi.inner) |inner| {
            if (try self.typeRefShape(inner)) |sh| return try std.fmt.allocPrint(self.arena(), "?{s}", .{sh});
            if (scalarCode(inner) == @as(?u8, 's')) return "?s";
        }
        return null;
    }

    fn elemCode(k: ElemKind) u8 {
        return switch (k) {
            .i32 => 'i',
            .f64 => 'f',
            .str => 's',
        };
    }

    /// Best-effort element shape of an array-valued expression. `i32` covers
    /// integers, bools and pointers alike.
    fn elemKindOf(self: *Emitter, e: ast.Expr) ElemKind {
        if (self.genericResultOf(e)) |a| return self.elemKindOf(a);
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.arr_elem_locals.get(self.resolveName(n)) orelse self.arr_elem_globals.get(self.resolveName(n)) orelse .i32,
                // A record FIELD declared as an array: its element shape is in
                // the field's declared type, and reading it is what tells
                // `self.cells.at(0)` it is a `?string` and not a boxed `?i32`.
                // While this arm answered `.i32` unconditionally, `(self.cells
                // .at(0) ?? "").length()` and its narrowed twin read the box
                // as a string pointer and printed a heap address at exit 0.
                .identAccess => blk: {
                    const tr = self.typeRefOf(e) orelse break :blk .i32;
                    break :blk arrayElemOfTypeRef(tr) orelse .i32;
                },
                else => .i32,
            },
            .loop => |lp| self.yieldElemKind(lp.body),
            .jump => if (self.tryPayloadTypeRef(e)) |t| arrayElemOfTypeRef(t) orelse .i32 else .i32,
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.elemKindOf(inner.*),
                .arrayLit => |al| blk: {
                    if (al.elems.len == 0) break :blk .i32;
                    const first = al.elems[0];
                    if (self.isStringExpr(first)) break :blk .str;
                    // A float anywhere makes it a float array: `[1, 2.5]`.
                    for (al.elems) |el| if (self.wasmTypeOf(el)[0] == 'f') break :blk .f64;
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
                                const lam = lambdaAt(cc, 0) orelse {
                                    // `xs.map(inc)`: the named function's
                                    // declared return.
                                    const fname = if (cc.args.len == 1) switch (cc.args[0].value.*) {
                                        .identifier => |id| switch (id.kind) {
                                            .ident => |n| n,
                                            else => break :blk .i32,
                                        },
                                        else => break :blk .i32,
                                    } else break :blk .i32;
                                    const rt = self.fn_ret_typerefs.get(self.import_aliases.get(fname) orelse fname) orelse break :blk .i32;
                                    break :blk elemKindOfTypeRef(rt);
                                };
                                if (lam.body.len == 0) break :blk .i32;
                                const last = lam.body[lam.body.len - 1].expr;
                                const v = switch (last) {
                                    .jump => |j| switch (j.kind) {
                                        .@"return" => |r| if (r) |x| x.* else break :blk .i32,
                                        else => break :blk .i32,
                                    },
                                    else => last,
                                };
                                // The tail reads the ELEMENT parameter, whose
                                // record type `lowerArrayHof` binds only while
                                // it lowers the body — so it is bound here for
                                // the duration of the question (`00 · 05-wasm`
                                // step 9). Unbound, `es.map({ e -> e.key })`
                                // answered `.i32` and `ks.at(0)` was read as a
                                // boxed `?i32`: a heap address at exit 0.
                                const held = self.holdElemParam(lam, recv);
                                defer self.releaseElemParam(held);
                                if (self.isStringExpr(v)) break :blk .str;
                                if (self.wasmTypeOf(v)[0] == 'f') break :blk .f64;
                                break :blk .i32;
                            }
                            // `05-wasm` step 1's arrays: their element is
                            // read off the shape they build.
                            if ((self.newArrShape(cc, c.loc) catch null)) |sh| {
                                if (sh.len >= 2) break :blk switch (sh[1]) {
                                    's' => .str,
                                    'f' => .f64,
                                    else => .i32,
                                };
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

    /// What `holdElemParam` displaced, so `releaseElemParam` can put it back.
    const HeldElemParam = struct {
        name: ?[]const u8 = null,
        prev_type: ?[]const u8 = null,
        prev_str: bool = false,
        /// The name's wasm type and alias before the question: the element
        /// parameter is the element's width while it is asked about, whatever
        /// another local of that name holds (`xs.map({ x -> x * 3.0 })`, then
        /// `[1, 2].map({ x -> x + 1 })` printed its integers as floats).
        prev_local: ?[]const u8 = null,
        prev_alias: ?[]const u8 = null,
    };

    /// Bind a HOF lambda's element parameter the way `lowerArrayHof` does —
    /// its record type and its string-ness — so a shape question asked about
    /// the body before it is lowered sees the element and not an unknown name.
    fn holdElemParam(self: *Emitter, lam: LambdaView, recv: ast.Expr) HeldElemParam {
        if (lam.params.len == 0) return .{};
        const p = lam.params[0];
        const held: HeldElemParam = .{
            .name = p,
            .prev_type = self.local_types.get(p),
            .prev_str = self.str_locals.contains(p),
            .prev_local = self.locals.get(p),
            .prev_alias = self.aliases.get(p),
        };
        if (self.elemRecordOf(recv)) |r| self.local_types.put(p, r) catch {};
        if (self.elemKindOf(recv) == .str) self.str_locals.put(p, {}) catch {};
        _ = self.aliases.remove(p);
        self.locals.put(p, if (self.elemKindOf(recv) == .f64) "f64" else "i32") catch {};
        return held;
    }

    fn releaseElemParam(self: *Emitter, held: HeldElemParam) void {
        const p = held.name orelse return;
        if (held.prev_type) |t| self.local_types.put(p, t) catch {} else _ = self.local_types.remove(p);
        if (!held.prev_str) _ = self.str_locals.remove(p);
        if (held.prev_local) |t| self.locals.put(p, t) catch {} else _ = self.locals.remove(p);
        if (held.prev_alias) |a| self.aliases.put(p, a) catch {};
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

    const FieldLambda = struct { params: []const []const u8, body: []const ast.Stmt };

    const Lifted = struct {
        name: []const u8,
        params: []const []const u8,
        body: []const ast.Stmt,
        captures: []const Captured,
        /// Per parameter: some call through a closure local passed a string
        /// (`lowerValueCall`). The program type-checked, so one proven string
        /// argument makes the parameter a string.
        param_str: []bool = &.{},
        /// Per parameter: the record type the declared function type the
        /// lambda is written against gives it, so `out.tag` reads the slot
        /// `Out` declares rather than guessing one by the field's name.
        param_rec: []const ?[]const u8 = &.{},
        /// Per parameter: something gave it a type — the declared function
        /// type the lambda is written against, a behavior's declaration, or
        /// a call through a closure local passing an argument. A parameter
        /// the body reads that nothing typed is refused where the lambda is
        /// written (`emitLifted`): its word could be a string or an integer,
        /// and guessing printed `300?` for `"d" + "?"` at exit 0.
        param_known: []bool = &.{},
        /// Where the lambda is written: a parameter nothing types is refused
        /// here (`emitLifted`).
        loc: ?ast.Loc = null,
        /// The generic body the lambda is written in (`cur_template`).
        template_of: ?[]const u8 = null,
        /// `Emitter.foreign_origin` where the lambda is written.
        origin: ?ast.Loc = null,
        /// Set for a trampoline standing for a top-level fn used as a value.
        fn_ref: ?[]const u8 = null,
    };

    /// `async { … }` (decision 124): the Task is eager here — the block is
    /// lifted like a lambda and its closure called in place, so a `return`
    /// inside it leaves the block, not the enclosing function.
    fn lowerAsyncBlock(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        const slot = try std.fmt.allocPrint(self.reg_arena.allocator(), "__async{d}", .{self.lambdas.items.len});
        try self.declareLocal(slot, "i32");
        try self.lowerLambdaValue(&.{}, body, null);
        try self.emit(.{ .local_set = slot });
        try self.emitC(.{ .local_get = slot }, "the block's environment");
        try self.emitIndirect(slot, 0);
    }

    fn lowerLambdaValue(self: *Emitter, params: []const []const u8, body: []const ast.Stmt, loc: ?ast.Loc) anyerror!void {
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
        // A declared function type the lambda is written against types its
        // parameters: `fn greeter(p: string) -> fn(x: string) -> string {
        // return { x -> p + x }; }` concatenates, where an untyped `x` was an
        // `i32` and `p + x` wrote the number (`a264`, exit 0).
        const expected = self.expected_fn;
        self.expected_fn = null;
        const param_rec = try ra.alloc(?[]const u8, params.len);
        @memset(param_rec, null);
        // Known unless the slot the lambda goes into says nothing about it
        // (`lowerRecordCtor` clears it for a field written as a type
        // parameter); a call through the slot sets it again.
        const param_known = try ra.alloc(bool, params.len);
        @memset(param_known, true);
        if (expected) |et| if (et == .function) {
            const pts = et.function.params;
            for (param_str, 0..) |*ps, i| {
                if (i < pts.len and isStringTypeRef(pts[i])) ps.* = true;
            }
            for (param_rec, 0..) |*pr, i| {
                if (i < pts.len and pts[i] == .named) pr.* = self.resolveRecordName(pts[i].named);
            }
        };
        const expected_params = self.expected_params;
        self.expected_params = null;
        if (expected_params) |eps| for (param_str, 0..) |*ps, i| {
            if (i < eps.len and isStringTypeRef(eps[i].typeRef)) ps.* = true;
        };
        try self.lambdas.append(self.alloc, .{
            .name = try std.fmt.allocPrint(ra, "__lambda{d}", .{idx}),
            .params = params,
            .body = body,
            .captures = caps.items,
            .param_str = param_str,
            .param_rec = param_rec,
            .param_known = param_known,
            .loc = loc,
            .template_of = self.cur_template,
            .origin = self.foreign_origin,
        });
        try self.emitClosureCell(idx, caps.items);
    }

    fn fieldClosureOf(self: *Emitter, recv: ast.Expr, field: []const u8) ?u32 {
        const n = plainIdentName(recv) orelse return null;
        var buf: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&buf, "{s}.{s}", .{ self.resolveName(n), field }) catch return null;
        return self.field_closures.get(key);
    }

    fn fieldClosureOfExpr(self: *Emitter, e: ast.Expr) ?u32 {
        if (e != .identifier or e.identifier.kind != .identAccess) return null;
        const ia = e.identifier.kind.identAccess;
        return self.fieldClosureOf(ia.receiver.*, ia.member);
    }

    /// Allocate the environment cell of table slot `idx` and leave its pointer.
    fn emitClosureCell(self: *Emitter, idx: u32, caps: []const Captured) anyerror!void {
        const base = try self.allocSlots(@intCast((1 + caps.len) * 4));
        try self.storeSlotConst(base, 0, idx);
        for (caps, 0..) |cp, i| {
            // A float or `i64` capture is a cell of its own (`lowerCellWord`),
            // which the lambda and the syncs write in place.
            const cell = Cell.of(cp.ty);
            try self.emit(.{ .local_get = base });
            try self.emit(.{ .local_get = cp.name });
            try self.emitConvert(cp.ty, cell.ty());
            if (cell != .none) try self.emit(self.builder().helper(if (cell == .f64) .box_f64 else .box_i64));
            try self.emitCf(.{ .store = .{ .offset = @intCast((i + 1) * 4) } }, "capture {s}", .{cp.name});
        }
        try self.loadBase(base);
    }

    /// A top-level fn used as a value: a closure over a trampoline that
    /// forwards its arguments.
    fn lowerFnRef(self: *Emitter, name: []const u8, loc: ?ast.Loc) anyerror!void {
        // A generic fn as a value: its trampoline calls the one generic body.
        if (self.generic_fns.contains(name)) try self.noteTemplateCall(name, loc);
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
            if (cc.calleeExpr != null) break :blk true;
            if (cc.receiver) |recv| break :blk slotOffset(self, recv.*, cc.callee) != null;
            break :blk self.locals.contains(cc.callee) or self.globals.contains(cc.callee);
        };
        if (!is_value) return false;
        const ra = self.reg_arena.allocator();
        const tmp = try std.fmt.allocPrint(ra, "__fnv{d}", .{self.loop_seq});
        self.loop_seq += 1;
        try self.declareLocal(tmp, "i32");
        // A behavior literal's `self` method: the receiver is its first
        // argument, held here between the slot load and the call.
        const self_recv: ?[]const u8 = if (cc.calleeExpr == null) if (cc.receiver) |recv| blk: {
            const rty = self.recordTypeOfExpr(recv.*) orelse break :blk null;
            const key = try std.fmt.allocPrint(ra, "{s}.{s}", .{ rty, cc.callee });
            if (!self.self_method_fields.contains(key)) break :blk null;
            const rt = try std.fmt.allocPrint(ra, "__self{d}", .{self.loop_seq});
            self.loop_seq += 1;
            try self.declareLocal(rt, "i32");
            break :blk rt;
        } else null else null;
        if (cc.calleeExpr) |ce| {
            // `adder(3)(4)` — the callee is the VALUE of an expression (01
            // handover 15), the function value the inner call answered.
            try self.lowerValue(ce.*);
        } else if (cc.receiver) |recv| {
            const off = slotOffset(self, recv.*, cc.callee).?;
            try self.lowerValue(recv.*);
            if (self_recv) |rt| try self.emit(.{ .local_tee = rt });
            try self.emitCf(.{ .load = .{ .offset = off } }, ".{s}", .{cc.callee});
        } else if (self.locals.contains(cc.callee)) {
            // Through `resolveName`: a name narrowed by `is fn(…) -> T`
            // (decision 254) is the closure its box held.
            try self.emit(.{ .local_get = self.resolveName(cc.callee) });
        } else {
            try self.emit(.{ .global_get = self.globalName(cc.callee) });
        }
        try self.emit(.{ .local_set = tmp });
        const closure: ?Lifted = if (cc.calleeExpr == null and cc.receiver == null and self.locals.contains(cc.callee))
            if (self.closure_locals.get(cc.callee)) |li| self.lambdas.items[li] else null
        else if (cc.calleeExpr == null and cc.receiver != null)
            // `lam.value("d")`: the lambda a constructor stored in that field
            // of that local (`field_closures`).
            (if (self.fieldClosureOf(cc.receiver.?.*, cc.callee)) |li| self.lambdas.items[li] else null)
        else
            null;
        if (closure) |l| {
            for (cc.args, 0..) |a, i| {
                if (i < l.param_str.len and self.isStringExpr(a.value.*)) l.param_str[i] = true;
                if (i < l.param_known.len) l.param_known[i] = true;
            }
            try self.syncCaptures(tmp, l.captures, .into_env);
        }
        try self.emit(.{ .local_get = tmp });
        if (self_recv) |rt| try self.emit(.{ .local_get = rt });
        for (cc.args) |a| try self.lowerCoerced(a.value.*, "i32");
        for (cc.trailing) |t| try self.lowerLambdaValue(t.params, t.body, self.call_loc);
        try self.emitIndirect(tmp, cc.args.len + cc.trailing.len + @as(usize, if (self_recv != null) 1 else 0));
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
            const cell = Cell.of(cp.ty);
            const slot: wat.MemArg = .{ .offset = @intCast((i + 1) * 4) };
            switch (dir) {
                .into_env => {
                    try self.emit(.{ .local_get = env });
                    if (cell != .none) try self.emit(.{ .load = slot });
                    try self.emit(.{ .local_get = cp.name });
                    try self.emitConvert(ty, cell.ty());
                    try self.emitCf(.{ .store = if (cell != .none) .{ .ty = vt(cell.ty()) } else slot }, "sync {s} into env", .{cp.name});
                },
                .out_of_env => {
                    try self.emit(.{ .local_get = env });
                    try self.emitCf(.{ .load = slot }, "sync {s} from env", .{cp.name});
                    try self.emitFromCell(cell);
                    try self.emitConvert(cell.ty(), ty);
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
        const cell = Cell.of(ty);
        try self.emit(.{ .local_get = "__env" });
        if (cell != .none) try self.emit(.{ .load = .{ .offset = off } });
        try self.emit(.{ .local_get = name });
        try self.emitConvert(ty, cell.ty());
        try self.emitCf(.{ .store = if (cell != .none) .{ .ty = vt(cell.ty()) } else .{ .offset = off } }, "write {s} back to env", .{name});
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

    fn fieldLambdaCallIsString(self: *Emitter, cc: anytype) bool {
        const recv = cc.receiver orelse return false;
        const rty = self.recordTypeOfExpr(recv.*) orelse return false;
        var buf: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&buf, "{s}.{s}", .{ rty, cc.callee }) catch return false;
        const fl = self.field_lambdas.get(key) orelse return false;
        const skip: usize = if (self.self_method_fields.contains(key)) 1 else 0;
        const flags = self.arena().alloc(bool, fl.params.len) catch return false;
        for (flags, 0..) |*f, i| f.* = i >= skip and i - skip < cc.args.len and self.isStringExpr(cc.args[i - skip].value.*);
        const saved = self.param_shape;
        defer self.param_shape = saved;
        self.param_shape = .{ .names = fl.params, .str = flags };
        return self.bodyIsString(fl.body);
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
        var si: usize = 0;
        var mi: usize = 0;
        while (li < self.lambdas.items.len or ai < self.assoc_needed.items.len or si < self.spec_pending.items.len or mi < self.mspec_pending.items.len) {
            while (mi < self.mspec_pending.items.len) : (mi += 1) {
                const sp = self.mspec_pending.items[mi];
                const saved = .{ self.rewrites, self.instance_lowerings, self.global_renames, self.owner_tparams, self.field_subs_owner, self.field_subs, self.foreign_origin };
                self.foreign_origin = sp.origin;
                self.rewrites = sp.rewrites;
                self.instance_lowerings = sp.lowerings;
                self.global_renames = sp.renames;
                self.owner_tparams = sp.tparams;
                self.field_subs_owner = sp.owner;
                self.field_subs = sp.subs;
                self.in_spec = true;
                defer {
                    self.rewrites = saved[0];
                    self.instance_lowerings = saved[1];
                    self.global_renames = saved[2];
                    self.owner_tparams = saved[3];
                    self.field_subs_owner = saved[4];
                    self.field_subs = saved[5];
                    self.foreign_origin = saved[6];
                    self.in_spec = false;
                }
                try self.emitMemberFn(sp.owner, sp.method);
            }
            while (si < self.spec_pending.items.len) : (si += 1) {
                const sp = self.spec_pending.items[si];
                const saved = .{ self.rewrites, self.instance_lowerings, self.global_renames, self.foreign_origin };
                self.foreign_origin = sp.origin;
                self.rewrites = sp.rewrites;
                self.instance_lowerings = sp.lowerings;
                self.global_renames = sp.renames;
                self.in_spec = true;
                defer {
                    self.rewrites = saved[0];
                    self.instance_lowerings = saved[1];
                    self.global_renames = saved[2];
                    self.foreign_origin = saved[3];
                    self.in_spec = false;
                }
                try self.emitFn(sp.decl);
            }
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
        const outer_template = self.cur_template;
        self.cur_template = l.template_of;
        defer self.cur_template = outer_template;
        const outer_origin = self.foreign_origin;
        self.foreign_origin = l.origin;
        defer self.foreign_origin = outer_origin;
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
            const outer_loc = self.stmt_loc;
            self.stmt_loc = l.loc;
            if (sig.result) |r| try self.emitConvert(r, "i32") else try self.emit(zero);
            self.stmt_loc = outer_loc;
        } else {
            for (l.params, 0..) |p, i| {
                try params.append(ar, wat.Builder.param(p, .i32));
                try self.locals.put(p, "i32");
                if (i < l.param_str.len and l.param_str[i]) try self.str_locals.put(p, {});
                if (i < l.param_rec.len) if (l.param_rec[i]) |r| try self.local_types.put(p, r);
            }
            // A parameter the body reads that nothing typed: the word it
            // holds may be a string or an integer, and the body's `+`, `==`
            // and `@print` would pick one by guess. Refused where the lambda
            // is written.
            var read: std.ArrayListUnmanaged([]const u8) = .empty;
            for (l.body) |st| try self.collectIdents(st.expr, &read);
            for (l.params, 0..) |p, i| {
                if (i < l.param_known.len and !l.param_known[i]) for (read.items) |n| {
                    if (!std.mem.eql(u8, n, p)) continue;
                    try self.refuseUnlessTemplate(l.loc, "lambda parameter `{s}`: nothing gives it a type the wasm backend can see", .{p});
                    break;
                };
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
                const cell = Cell.of(cp.ty);
                try self.emit(.{ .local_get = "__env" });
                try self.emit(.{ .load = .{ .offset = @intCast((i + 1) * 4) } });
                try self.emitFromCell(cell);
                try self.emitConvert(cell.ty(), cp.ty);
                try self.emit(.{ .local_set = cp.name });
            }
            try self.declareScratch("_try", countTrys(l.body));
            try self.declareScratch("__mem", self.countMems(l.body));
            try self.emitLocalDecls(l.body);
            const tail_type: ?[]const u8 = if (l.body.len > 0) self.wasmTypeOf(l.body[l.body.len - 1].expr) else null;
            const tail = try self.emitBody(l.body, true);
            // A closure answers through the indirect call's `i32` word: a
            // float or an `i64` answer is refused at the lambda.
            const outer_loc = self.stmt_loc;
            self.stmt_loc = l.loc;
            if (tail == .value) if (tail_type) |t| try self.emitConvert(t, "i32");
            self.stmt_loc = outer_loc;
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

    /// Decision 262 — an associated host primitive of a prelude behavior,
    /// lowered to its prelude helper: `String.fromCodepoint(cp)` is
    /// `$__str_from_cp`, which writes the code point's UTF-8 bytes and traps on
    /// a value that is no Unicode scalar value (as erlang's `/utf8` raises and
    /// the Node cell throws). Null for any other call, and when `String` names
    /// something of the program's own.
    fn primAssocHelper(self: *Emitter, cc: anytype) ?wat.Helper {
        const rn = receiverName(cc) orelse return null;
        if (self.locals.contains(rn) or self.globals.contains(rn) or self.records.contains(rn) or self.enums.contains(rn)) return null;
        if (std.mem.eql(u8, rn, "String") and std.mem.eql(u8, cc.callee, "fromCodepoint") and cc.args.len == 1 and cc.trailing.len == 0) return .str_from_cp;
        return null;
    }

    /// `Iface_method` when `cc` is `Iface.method(…)` naming an interface
    /// associated `default fn`.
    fn assocSym(self: *Emitter, cc: anytype) ?[]const u8 {
        const rn = receiverName(cc) orelse return null;
        if (self.locals.contains(rn) or self.globals.contains(rn)) return null;
        const sym = std.fmt.bufPrint(&self.sym_buf, "{s}_{s}", .{ rn, cc.callee }) catch return null;
        // An interface associated `default fn`, or a record's or an enum's own
        // fn called on the type (`Response.ok(…)`, `Shape.unit()` — which took
        // the variant path and answered `0 ;; unknown variant`).
        if (self.iface_assoc.contains(sym)) return sym;
        if ((self.records.contains(rn) or self.enums.contains(rn)) and self.fn_sigs.contains(sym)) return sym;
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
                if (self.wasmTypeOf(v)[0] == 'f' or self.mentionsAny(v, floats.items)) return .f64;
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

    /// What an 8-byte cell holds: a float or an `i64`, each wider than the
    /// 4-byte word every slot of this backend is.
    const Cell = enum {
        none,
        f64,
        i64,

        /// The wasm type of what the cell holds — `i32` for a word.
        fn ty(c: Cell) []const u8 {
            return switch (c) {
                .none => "i32",
                .f64 => "f64",
                .i64 => "i64",
            };
        }

        /// The cell a value of wasm type `t` needs, if any.
        fn of(t: []const u8) Cell {
            if (t[0] == 'f') return .f64;
            if (std.mem.eql(u8, t, "i64")) return .i64;
            return .none;
        }
    };

    const OptInfo = struct {
        /// The payload is a scalar in a box (else the value is the payload).
        boxed: bool,
        str: bool = false,
        bool_: bool = false,
        /// The payload is an `f64` or an `i64`, and the box is its 8-byte cell
        /// (`$__box_f64` / `$__box_i64`) — a `?f64`, a `?i64`, a float array's
        /// `at`/`first` (whose slot already holds the cell), a `?.` over such
        /// a field. Read as an `i32` it printed the float's bits.
        cell: Cell = .none,
        /// The payload is a value of this record type — `es.at(0)` over an
        /// `Entry[]`. It names the field offsets a `?.` read needs and the
        /// header `$__print_opt_tagged` writes, and it is the reason a record
        /// element is NOT boxed: a record is its own pointer, so `0` is
        /// absence exactly as it is for a string.
        rec: ?[]const u8 = null,
        inner: ?ast.TypeRef = null,
        /// The payload is a CONTAINER — an array or a tuple — with this print
        /// shape (`[i`, `(is)`): `rows.at(1)` over `[[1, 2], [3]]`. Its own
        /// pointer, `0` absence; printed `null` or by the shape. Through the
        /// integer printer it answered the row's address at exit 0.
        shape: ?[]const u8 = null,
    };

    /// Whether a `?T`'s cell holds a `u64` — its bits print unsigned.
    fn optIsU64(oi: OptInfo) bool {
        const inner = oi.inner orelse return false;
        return inner == .named and std.mem.eql(u8, inner.named, "u64");
    }

    fn optInfoOfTypeRef(self: *Emitter, t: ast.TypeRef) ?OptInfo {
        const inner = switch (t) {
            .optional => |i| i.*,
            else => return null,
        };
        // A `?V` over a type parameter is ALWAYS a box: nothing here
        // monomorphises, so the payload may be a scalar, and a present `0` has
        // to differ from absence. Its writer (inside the generic body, where
        // `V` is in scope) and its reader (at the call, where the method's
        // registered return reads `?__tparam`) agree on the box; unboxed,
        // `Dict.at`'s absent key printed `0` and a present `0` was absent
        // (C-18).
        return switch (inner) {
            .named => |n| if (std.mem.eql(u8, n, "string"))
                .{ .boxed = false, .str = true, .inner = inner }
            else if (std.mem.eql(u8, n, "bool"))
                .{ .boxed = true, .bool_ = true, .inner = inner }
            else if (fieldCellOf(n) != .none)
                .{ .boxed = true, .cell = fieldCellOf(n), .inner = inner }
            else if (isScalarName(n))
                .{ .boxed = true, .inner = inner }
                // An all-unit enum's value is its ordinal — `0` for the first
                // variant — so `?Color` is a box as `?i32` is. Unboxed, a present
                // `Color.Red` was absent, and printed as its ordinal.
            else if (self.isAllUnitEnum(n))
                .{ .boxed = true, .inner = inner }
            else if (std.mem.eql(u8, n, tparam_marker) or self.isTypeParamName(n))
                .{ .boxed = true, .inner = inner }
            else
                .{ .boxed = false, .inner = inner },
            else => .{ .boxed = false, .inner = inner },
        };
    }

    fn isTypeParamName(self: *Emitter, n: []const u8) bool {
        for (self.owner_tparams) |gp| if (std.mem.eql(u8, gp.name, n)) return true;
        for (self.fn_tparams) |gp| if (std.mem.eql(u8, gp.name, n)) return true;
        return false;
    }

    /// A declared return type as a CALLER reads it: `?V` over one of `owner` /
    /// `own`'s type parameters becomes `?__tparam`, which `optInfoOfTypeRef`
    /// knows is boxed wherever it is asked — at a call site the parameter
    /// names nothing. A tuple's elements the same way (`dequeue`'s
    /// `#(Queue<T>, ?T)`): its `?T` slot holds the box the generic body wrote,
    /// and read as `?T` at the call — a name nothing in scope binds — the
    /// box's ADDRESS was the payload (`d._1.unwrapOr(-1)` printed `296`).
    fn eraseOptTypeParam(self: *Emitter, owner: []const ast.GenericParam, own: []const ast.GenericParam, rt: ast.TypeRef) !ast.TypeRef {
        const elems: ?[]ast.TypeRef = switch (rt) {
            .tuple_ => |es| es,
            .labeledTuple => |lt| lt.elems,
            else => null,
        };
        if (elems) |es| {
            const ra = self.reg_arena.allocator();
            const out = try ra.alloc(ast.TypeRef, es.len);
            for (es, out) |e, *o| o.* = try self.eraseOptTypeParam(owner, own, e);
            return switch (rt) {
                .tuple_ => .{ .tuple_ = out },
                .labeledTuple => |lt| .{ .labeledTuple = .{ .elems = out, .labels = lt.labels } },
                else => unreachable,
            };
        }
        const inner = switch (rt) {
            .optional => |i| i.*,
            else => return rt,
        };
        const n = switch (inner) {
            .named => |x| x,
            else => return rt,
        };
        const is_param = for (owner) |gp| {
            if (std.mem.eql(u8, gp.name, n)) break true;
        } else for (own) |gp| {
            if (std.mem.eql(u8, gp.name, n)) break true;
        } else false;
        if (!is_param) return rt;
        const ra = self.reg_arena.allocator();
        const boxed = try ra.create(ast.TypeRef);
        boxed.* = .{ .named = tparam_marker };
        return .{ .optional = boxed };
    }

    /// Decision 330 — an optional operator's `if` (`infer.inferOptionalOperator`,
    /// binder `__bp_opt_<line>_<col>`): its operand, the then-arm's value, and
    /// whether it is `x!` (the arm answers the binder itself).
    const OptOperator = struct { cond: *ast.Expr, tail: ast.Expr, bang: bool };

    fn optOperatorParts(e: ast.Expr) ?OptOperator {
        if (e != .branch or e.branch.kind != .if_) return null;
        const i = e.branch.kind.if_;
        const b = i.binding orelse return null;
        if (!std.mem.startsWith(u8, b, "__bp_opt_")) return null;
        if (i.then_.len != 1) return null;
        const tail = i.then_[0].expr;
        const bang = tail == .identifier and tail.identifier.kind == .ident and std.mem.eql(u8, tail.identifier.kind.ident, b);
        return .{ .cond = i.cond, .tail = tail, .bang = bang };
    }

    /// `o ?? d` — the parser's `if (o) { n -> n } else { d }` with the
    /// nullish binder (`ast.nullish_binding_name`): the optional and its
    /// default.
    fn nullishParts(e: ast.Expr) ?struct { opt: *ast.Expr, dflt: ast.Expr } {
        if (e != .branch or e.branch.kind != .if_) return null;
        const i = e.branch.kind.if_;
        const b = i.binding orelse return null;
        if (!std.mem.eql(u8, b, ast.nullish_binding_name)) return null;
        const els = i.else_ orelse return null;
        if (els.len != 1) return null;
        return .{ .opt = i.cond, .dflt = els[0].expr };
    }

    /// `o.unwrapOr(d)` over an `@Option` or a `@Result`, its default written
    /// — the builtin `__bp_*_unwrapOr(o, d)`, whose second argument is `d`.
    fn isUnwrapOr(cc: anytype) bool {
        if (!cc.is_builtin or cc.args.len != 2) return false;
        return std.mem.eql(u8, cc.callee, "__bp_option_unwrapOr") or std.mem.eql(u8, cc.callee, "__bp_result_unwrapOr");
    }

    /// `fn f<T>(…, x: T, …) -> T`: the index of the first parameter declared
    /// `T`, when the return type is that bare type parameter.
    fn genericResultIndex(gps: []const ast.GenericParam, ptrefs: []const ast.TypeRef, rt: ast.TypeRef) ?usize {
        const n = switch (rt) {
            .named => |x| x,
            else => return null,
        };
        for (gps) |gp| {
            if (!std.mem.eql(u8, gp.name, n)) continue;
            for (ptrefs, 0..) |pt, i| switch (pt) {
                .named => |pn| if (std.mem.eql(u8, pn, n)) return i,
                else => {},
            };
            return null;
        }
        return null;
    }

    /// The argument whose shape a generic call answers (`generic_result_arg`):
    /// `ident("a")` is a string, `ident(true)` a bool.
    fn genericResultArg(self: *Emitter, cc: anytype) ?ast.Expr {
        if (cc.receiver != null or cc.is_builtin or cc.calleeExpr != null) return null;
        const ix = self.generic_result_arg.get(cc.callee) orelse return null;
        for (cc.args) |a| if (a.label != null) return null;
        return if (ix < cc.args.len) cc.args[ix].value.* else null;
    }

    /// The name of a primitive type's family, when it is one.
    fn primKindOfName(n: []const u8) ?envMod.PrimKind {
        const eq = std.mem.eql;
        if (eq(u8, n, "string")) return .string;
        if (eq(u8, n, "bool")) return .bool;
        if (eq(u8, n, "f64") or eq(u8, n, "f32")) return .float;
        if (eq(u8, n, "i32") or eq(u8, n, "i64") or eq(u8, n, "u32") or eq(u8, n, "u64")) return .int;
        return null;
    }

    /// `Pair(left: s, right: "ab")` of a generic record: `Pair<string>`, the
    /// type arguments its fields' arguments bind — what a method call on it
    /// specialises by (`specializeMethod`). Null when the record has no type
    /// parameter or some argument does not say what its parameter is.
    fn ctorTypeRef(self: *Emitter, cc: anytype) !?ast.TypeRef {
        if (cc.receiver != null or cc.is_builtin) return null;
        const gps = self.record_generics.get(cc.callee) orelse return null;
        const names = self.records.get(cc.callee) orelse return null;
        const trefs = self.record_field_typerefs.get(cc.callee) orelse return null;
        const ar = self.reg_arena.allocator();
        const args = try ar.alloc(ast.TypeRef, gps.len);
        for (gps, args) |gp, *out| {
            out.* = for (trefs, 0..) |t, i| {
                if (t != .named or !std.mem.eql(u8, t.named, gp.name) or i >= names.len) continue;
                const arg = self.argForField(cc.args, names[i], i) orelse continue;
                if (self.concreteTypeOf(arg.value.*)) |c| break ast.TypeRef{ .named = c };
                // A top-level fn stored in the field (`Box(value: shout)`):
                // its function type, so a call through the field's value
                // answers its declared return.
                if (try self.fnRefTypeRef(arg.value.*)) |ft| break ft;
            } else return null;
        }
        return .{ .generic = .{ .name = cc.callee, .args = args, .is_builtin = false } };
    }

    /// `wrap(shout)` over `fn wrap<T>(v: T) -> Box<T>`: the declared return
    /// with each type parameter a FUNCTION argument binds written in — a
    /// function type has no specialisation (`bindParam` binds names), so the
    /// call keeps the one body and only its result's type is read.
    fn genericRetByFnArg(self: *Emitter, cc: anytype) !?ast.TypeRef {
        if (cc.receiver != null or cc.is_builtin or cc.calleeExpr != null) return null;
        const g = self.generic_fns.get(self.import_aliases.get(cc.callee) orelse cc.callee) orelse return null;
        const f = g.decl;
        const rt = f.returnType orelse return null;
        const ar = self.reg_arena.allocator();
        var subs: std.ArrayListUnmanaged(TypeSub) = .empty;
        var pi: usize = 0;
        for (f.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            defer pi += 1;
            if (pi >= cc.args.len) break;
            if (p.typeRef != .named or !isGenericParamName(p.typeRef.named, f.genericParams, &.{})) continue;
            const ft = (try self.fnRefTypeRef(cc.args[pi].value.*)) orelse continue;
            try subs.append(ar, .{ .name = p.typeRef.named, .to = ft });
        }
        if (subs.items.len == 0) return null;
        return try substTypeParams(ast.TypeRef, ar, rt, subs.items);
    }

    /// `shout` named as a value, a top-level fn of this program: `fn(…) -> R`
    /// from its declaration.
    fn fnRefTypeRef(self: *Emitter, e: ast.Expr) !?ast.TypeRef {
        const n0 = plainIdentName(e) orelse return null;
        if (self.locals.contains(n0)) return null;
        const n = self.import_aliases.get(n0) orelse n0;
        const ps = self.fn_param_typerefs.get(n) orelse return null;
        const rt = self.fn_ret_typerefs.get(n) orelse return null;
        const ar = self.reg_arena.allocator();
        const ret = try ar.create(ast.TypeRef);
        ret.* = rt;
        return .{ .function = .{ .params = try ar.dupe(ast.TypeRef, ps), .returnType = ret } };
    }

    /// The type an argument binds a type parameter to, when its shape says:
    /// a primitive, a record, an all-unit enum.
    fn concreteTypeOf(self: *Emitter, e: ast.Expr) ?[]const u8 {
        if (self.isStringExpr(e)) return "string";
        if (self.isBoolExpr(e)) return "bool";
        if (self.recordTypeOfExpr(e)) |r| return r;
        if (self.unitEnumOf(e)) |en| return en;
        if (self.typeRefOf(e)) |tr| switch (tr) {
            .named => |n| if (primKindOfName(n) != null) return n,
            else => {},
        };
        switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| if (isNumericLiteral(n)) return numLitType(n),
                else => {},
            },
            else => {},
        }
        if (self.wasmTypeOf(e)[0] == 'f') return "f64";
        return null;
    }

    /// The type parameter a parameter is written as — `x: T`, or the element
    /// of `xs: Array<T>` / `xs: T[]` — and the type the argument binds it to.
    const ParamBinding = struct {
        name: []const u8,
        ty: []const u8,
        /// Decision 210 — a composite the parameter is bound to that no name
        /// spells (`#(i32, string)`, `Array<i32>`), or a payload enum: set
        /// only when the body compares values with `==` (`eqBindParam`).
        tref: ?ast.TypeRef = null,
    };

    /// Decision 210 — `x: T` against an argument whose type is a composite,
    /// in a body that compares values with `==` / `!=`: one body for every
    /// type compares two words, so the copy binds `T` to the composite and
    /// its `==` calls that type's `$__eq_<T>`.
    fn eqBindParam(self: *Emitter, t: ast.TypeRef, arg: ast.Expr, f: ast.FnDecl) !?ParamBinding {
        const n = switch (t) {
            .named => |x| x,
            else => return null,
        };
        if (!isGenericParamName(n, f.genericParams, &.{})) return null;
        if (!comparesValues(ast.FnDecl, f)) return null;
        const at = (try self.eqTypeOf(arg)) orelse return null;
        if (!self.eqComposite(at)) return null;
        return .{ .name = n, .ty = try self.eqKey(at), .tref = at };
    }

    fn bindParam(self: *Emitter, t: ast.TypeRef, arg: ast.Expr, isParam: *const fn ([]const u8, []const ast.GenericParam, []const ast.GenericParam) bool, a: []const ast.GenericParam, b: []const ast.GenericParam) ?ParamBinding {
        switch (t) {
            .named => |n| {
                if (!isParam(n, a, b)) return null;
                return .{ .name = n, .ty = self.concreteTypeOf(arg) orelse return null };
            },
            .array, .generic => {
                // `p: Pair<T>` against an argument whose type says `Pair<string>`
                // (`ctorTypeRef`, a local bound to one): `T` is what the
                // argument's type argument at its place is.
                if (t == .generic and !std.mem.eql(u8, t.generic.name, "Array")) {
                    const at = self.typeRefOf(arg) orelse return null;
                    if (at != .generic or !std.mem.eql(u8, at.generic.name, t.generic.name) or at.generic.args.len != t.generic.args.len) return null;
                    for (t.generic.args, at.generic.args) |pa, aa| {
                        if (pa != .named or aa != .named) continue;
                        if (!isParam(pa.named, a, b)) continue;
                        if (primKindOfName(aa.named) == null and !self.records.contains(aa.named)) continue;
                        return .{ .name = pa.named, .ty = aa.named };
                    }
                    return null;
                }
                const elem: ast.TypeRef = switch (t) {
                    .array => |inner| inner.*,
                    .generic => |g| if (g.args.len == 1 and std.mem.eql(u8, g.name, "Array")) g.args[0] else return null,
                    else => unreachable,
                };
                const n = switch (elem) {
                    .named => |x| x,
                    else => return null,
                };
                if (!isParam(n, a, b) or !self.isArrayExpr(arg)) return null;
                if (self.elemRecordOf(arg)) |r| return .{ .name = n, .ty = r };
                return .{ .name = n, .ty = switch (self.elemKindOf(arg)) {
                    .str => "string",
                    .f64 => return null,
                    .i32 => "i32",
                } };
            },
            else => return null,
        }
    }

    /// Whether the written type `t` names one of `gps` anywhere in it.
    fn typeMentionsParam(t: ast.TypeRef, gps: []const ast.GenericParam) bool {
        return switch (t) {
            .named => |n| isGenericParamName(n, gps, &.{}),
            .optional, .array => |inner| typeMentionsParam(inner.*, gps),
            .generic => |g| for (g.args) |a| {
                if (typeMentionsParam(a, gps)) break true;
            } else false,
            .tuple_ => |es| for (es) |e| {
                if (typeMentionsParam(e, gps)) break true;
            } else false,
            else => false,
        };
    }

    fn isGenericParamName(n: []const u8, a: []const ast.GenericParam, b: []const ast.GenericParam) bool {
        for (a) |gp| if (std.mem.eql(u8, gp.name, n)) return true;
        for (b) |gp| if (std.mem.eql(u8, gp.name, n)) return true;
        return false;
    }

    /// A generic `fn` has ONE body here, where every type parameter is an
    /// `i32` word: a string, a bool or a float bound to one printed as a
    /// word, compared as a word and narrowed, and a method on a value of one
    /// found no lowering (`x.toString()` trapped). A call whose arguments say
    /// what a type parameter is — `describe("s")`, `pair(1.5, 2.5)` — calls
    /// a copy of the function with the type parameters it binds substituted
    /// in every written type (`<name>__<T>_<type>`), lowered like any other
    /// function. Only when it matters: a string, a bool or a float bound, or
    /// a method called on a value of the parameter.
    fn specializedCallee(self: *Emitter, cc: anytype) !?[]const u8 {
        if (cc.receiver != null or cc.is_builtin or cc.calleeExpr != null) return null;
        return self.specializeFor(self.import_aliases.get(cc.callee) orelse cc.callee, cc.args);
    }

    /// `specializedCallee` for the function `target` (a free `fn`, or a
    /// behavior's associated `default fn` by its symbol `Seq_firstOr`)
    /// called with `args`.
    fn specializeFor(self: *Emitter, target: []const u8, args: anytype) !?[]const u8 {
        const g = self.generic_fns.get(target) orelse return null;
        const f = g.decl;
        const cc = .{ .args = args };
        for (cc.args) |a| if (a.label != null) return null;
        const ar = self.reg_arena.allocator();
        var subs: std.ArrayListUnmanaged(TypeSub) = .empty;
        var needed = false;
        var params_of: std.ArrayListUnmanaged([]const u8) = .empty;
        var pi: usize = 0;
        for (f.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            defer pi += 1;
            if (pi >= cc.args.len) break;
            const bnd = self.bindParam(p.typeRef, cc.args[pi].value.*, &isGenericParamName, f.genericParams, &.{}) orelse
                (try self.eqBindParam(p.typeRef, cc.args[pi].value.*, f)) orelse continue;
            try params_of.append(ar, p.name);
            var bound = false;
            for (subs.items) |sub| if (std.mem.eql(u8, sub.name, bnd.name)) {
                bound = true;
            };
            if (bound) continue;
            try subs.append(ar, .{ .name = bnd.name, .to = bnd.tref orelse .{ .named = bnd.ty } });
            if (std.mem.eql(u8, bnd.ty, "string") or std.mem.eql(u8, bnd.ty, "bool") or bnd.ty[0] == 'f') needed = true;
            // Decision 210: a composite bound where the body compares with
            // `==` — the one body would compare two pointers.
            if (bnd.tref != null or (self.records.contains(bnd.ty) and comparesValues(ast.FnDecl, f))) needed = true;
        }
        if (subs.items.len == 0) return null;
        if (!needed and !callsMethodOn(ast.FnDecl, f, params_of.items)) return null;
        return try self.specCopy(target, g, subs.items);
    }

    /// A generic fn NAMED as an argument whose parameter is written as a
    /// function type — `apply(same, s, "ab")` against `f: fn(a: string, b:
    /// string) -> bool`: the copy the parameter types bind. The trampoline
    /// over the one generic body compared two strings as words.
    fn specializeByFnType(self: *Emitter, target: []const u8, ft: ast.TypeRef) !?[]const u8 {
        const g = self.generic_fns.get(target) orelse return null;
        const fty = switch (ft) {
            .function => |x| x,
            else => return null,
        };
        const ar = self.reg_arena.allocator();
        var subs: std.ArrayListUnmanaged(TypeSub) = .empty;
        var needed = false;
        var pi: usize = 0;
        for (g.decl.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            defer pi += 1;
            if (pi >= fty.params.len) break;
            const tn = switch (p.typeRef) {
                .named => |n| n,
                else => continue,
            };
            if (!isGenericParamName(tn, g.decl.genericParams, &.{})) continue;
            const to = switch (fty.params[pi]) {
                .named => |n| n,
                else => continue,
            };
            if (primKindOfName(to) == null and !self.records.contains(to)) continue;
            const bound = for (subs.items) |sub| {
                if (std.mem.eql(u8, sub.name, tn)) break true;
            } else false;
            if (bound) continue;
            try subs.append(ar, .{ .name = tn, .to = .{ .named = to } });
            if (std.mem.eql(u8, to, "string") or std.mem.eql(u8, to, "bool") or to[0] == 'f') needed = true;
        }
        if (subs.items.len == 0 or !needed) return null;
        return try self.specCopy(target, g, subs.items);
    }

    /// The copy of the generic fn `target` with `subs` written in, queued
    /// for emission once; its symbol `<target>__<T>_<type>…`.
    fn specCopy(self: *Emitter, target: []const u8, g: GenericFn, subs: []const TypeSub) ![]const u8 {
        const f = g.decl;
        const ar = self.reg_arena.allocator();
        var name: std.ArrayListUnmanaged(u8) = .empty;
        try name.appendSlice(ar, target);
        for (subs) |sub| try name.print(ar, "__{s}_{s}", .{ sub.name, if (sub.to == .named) sub.to.named else try self.eqKey(sub.to) });
        const sym = name.items;
        if (self.spec_names.contains(sym)) return sym;
        try self.spec_names.put(self.alloc, sym, {});
        var copy = try substTypeParams(ast.FnDecl, ar, f, subs);
        copy.name = sym;
        copy.isPub = false;
        var left: std.ArrayListUnmanaged(ast.GenericParam) = .empty;
        for (f.genericParams) |gp| {
            const done = for (subs) |sub| {
                if (std.mem.eql(u8, sub.name, gp.name)) break true;
            } else false;
            if (!done) try left.append(ar, gp);
        }
        copy.genericParams = left.items;
        try self.registerFn(copy);
        try self.spec_pending.append(self.alloc, .{ .decl = copy, .rewrites = g.rewrites, .lowerings = g.lowerings, .renames = g.renames, .origin = self.specOrigin(g.linked) });
        return sym;
    }

    /// `e` itself when it is a generic call answering its argument's shape
    /// (`genericResultArg`), that argument — and when it is an `@block` whose
    /// body returns, the first value it returns (`blockReturnValue`).
    fn genericResultOf(self: *Emitter, e: ast.Expr) ?ast.Expr {
        return switch (e) {
            .call => |c| switch (c.kind) {
                .call => |cc| blockResultOf(e) orelse self.genericResultArg(cc),
                else => null,
            },
            else => null,
        };
    }

    fn isScalarName(n: []const u8) bool {
        for ([_][]const u8{ "i32", "i64", "u32", "u64", "f32", "f64", "int", "float" }) |s| {
            if (std.mem.eql(u8, n, s)) return true;
        }
        return false;
    }

    /// The declared type an expression carries, when a declaration names it.
    /// The return type of a call whose callee is a function VALUE — the
    /// callee expression of `adder(3)(4)` or a local/global declared (or bound
    /// to a call declared) `fn(…) -> R` — or null.
    fn valueCallTypeRef(self: *Emitter, cc: anytype) ?ast.TypeRef {
        // `w.write("a")` where `write` is a record's FUNCTION-TYPED FIELD: the
        // call answers the field type's return. Without it a string answered
        // through the field printed as its heap address.
        if (cc.receiver) |r| {
            const rty = self.recordTypeOfExpr(r.*) orelse return null;
            if (self.fn_sigs.contains(std.fmt.bufPrint(&self.sym_buf, "{s}_{s}", .{ rty, cc.callee }) catch return null)) return null;
            const ft0 = self.fieldTypeRefIn(rty, cc.callee) orelse return null;
            // `h.value("b")` over `Box<fn(s: string) -> string>`: the field is
            // written `T`, the receiver's type argument is the function type.
            const ft = self.recvTypeArgRef(r.*, rty, ft0);
            return switch (ft) {
                .function => |f| f.returnType.*,
                else => null,
            };
        }
        const ft: ast.TypeRef = if (cc.calleeExpr) |ce|
            self.typeRefOf(ce.*) orelse return null
        else blk: {
            const n = self.resolveName(cc.callee);
            break :blk self.local_typerefs.get(n) orelse
                (if (self.locals.contains(n)) return null else self.global_typerefs.get(n) orelse return null);
        };
        return switch (ft) {
            .function => |f| f.returnType.*,
            else => null,
        };
    }

    fn typeRefOf(self: *Emitter, e: ast.Expr) ?ast.TypeRef {
        // `o ?? d` over a `?T` answers a `T`, as `o.unwrapOr(d)` did below:
        // a `?u64`'s payload stays a `u64`, which prints, compares and turns
        // into text unsigned (`-1` at exit 0 once 330 spelled it `??`).
        if (nullishParts(e)) |nu| {
            if (self.typeRefOf(nu.opt.*)) |ot| if (ot == .optional) return ot.optional.*;
            if (self.optInfoOf(nu.opt.*)) |oi| if (oi.inner) |inner| return inner;
        }
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n0| blk: {
                    const n = self.resolveName(n0);
                    if (self.local_typerefs.get(n)) |t| break :blk t;
                    if (self.locals.contains(n)) break :blk null;
                    break :blk self.global_typerefs.get(n);
                },
                .identAccess => |ia| blk: {
                    // `Color.Red` of an all-unit enum: a value of `Color`,
                    // which is what prints it by name once it is in a local.
                    if (self.unitEnumMember(ia)) |en| break :blk .{ .named = en };
                    if (tupleIndex(ia.member)) |idx| {
                        const rt = self.typeRefOf(ia.receiver.*) orelse break :blk null;
                        const elems = rt.tupleElems() orelse break :blk null;
                        break :blk if (idx < elems.len) elems[idx] else null;
                    }
                    const rty = self.recordTypeOfExpr(ia.receiver.*) orelse break :blk null;
                    const fields = self.records.get(rty) orelse break :blk null;
                    const trefs = self.record_field_typerefs.get(rty) orelse break :blk null;
                    for (fields, 0..) |f, i| if (std.mem.eql(u8, f, ia.member) and i < trefs.len) {
                        const ft = self.fieldSub(rty, trefs[i]);
                        break :blk self.recvTypeArgRef(ia.receiver.*, rty, ft);
                    };
                    break :blk null;
                },
                else => null,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    // `o.unwrapOr(d)` over a `?T` answers a `T`: a `?u64`'s
                    // payload stays a `u64`, which prints, compares and turns
                    // into text unsigned (`-1` at exit 0 before).
                    if (isUnwrapOr(cc)) {
                        if (self.typeRefOf(cc.args[0].value.*)) |ot| if (ot == .optional) break :blk ot.optional.*;
                        // A `?T` element of a tuple no type is written for
                        // names its payload by its print shape (`?u`).
                        if (self.optInfoOf(cc.args[0].value.*)) |oi| if (oi.inner) |inner| break :blk inner;
                    }
                    if (cc.is_builtin) break :blk null;
                    // Inside a specialisation a primitive method's result is
                    // typed by what it answers, so the next link of a chain
                    // (`self.max(lo).min(hi)`) and a `val` bound to one
                    // (`val tail = self.slice(1)`) find their primitive —
                    // inference recorded no lowering in a body it typed
                    // against a type variable or `Self`.
                    // A program's `Array<T>` default answers its copy's declared
                    // return (`?T` → `?string` …), which the optional and
                    // print-shape readers take.
                    if (cc.receiver != null) if (self.primKindAt(cc, c.loc)) |k| if (k == .array and primCallRes(k, cc) == null) if (self.primDefaultOf(k, cc.callee)) |pd| {
                        const sym = self.ensurePrimDefault(k, pd, cc.receiver.?.*) catch break :blk null;
                        break :blk self.fn_ret_typerefs.get(sym);
                    };
                    if (self.in_spec and cc.receiver != null) if (self.primKindAt(cc, c.loc)) |k| if (self.primRes(k, cc)) |r| {
                        const t: ?[]const u8 = switch (r) {
                            .str => "string",
                            .bool_ => "bool",
                            .f64 => "f64",
                            .i32 => if (k == .float and !std.mem.eql(u8, cc.callee, "length")) null else "i32",
                            .arr, .none => null,
                        };
                        if (t) |tn| break :blk .{ .named = tn };
                    };
                    // A method on a record value: its declared return type is
                    // registered under the emitted symbol (`Dict_at`), and
                    // asking for it is what keeps the *reader* of a `?T` in step
                    // with the writer. `d.at("a")` returns a `?V` — a type
                    // parameter, so unboxed here — while the reader guessed
                    // "boxed" and loaded through the payload as an address.
                    if (cc.receiver != null) {
                        if (self.recordMethodSym(cc, c.loc)) |sym| {
                            if (self.fn_ret_typerefs.get(sym)) |t| break :blk t;
                        }
                        // The same question one step lower: the symbol the call
                        // actually emits — a `rewrites` entry the comptime pass
                        // left, an interface `default fn`, or a method already
                        // flattened to `Dict_at` by the specialisation pass.
                        const sym = self.calleeSymbol(cc, c.loc) orelse break :blk null;
                        break :blk self.fn_ret_typerefs.get(sym);
                    }
                    // A function VALUE applied — `adder(3)(4)`, or `f(4)` over
                    // a local bound to one: the call answers the function
                    // type's return.
                    if (self.valueCallTypeRef(cc)) |t| break :blk t;
                    if (self.ctorTypeRef(cc) catch null) |t| break :blk t;
                    if (self.genericRetByFnArg(cc) catch null) |t| break :blk t;
                    if (self.specializedCallee(cc) catch null) |sym| break :blk self.fn_ret_typerefs.get(sym);
                    if (self.genericResultArg(cc)) |a| break :blk self.typeRefOf(a);
                    break :blk self.fn_ret_typerefs.get(cc.callee);
                },
                else => null,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.typeRefOf(inner.*),
                // `[Pair(left: s, right: "ab")]`: an array of the generic
                // record its first constructor binds, so a HOF's element
                // parameter specialises a method call on it like the
                // constructor itself does. Only that shape — every other
                // literal keeps answering nothing here.
                .arrayLit => |al| blk: {
                    if (al.elems.len == 0) break :blk null;
                    const first = switch (al.elems[0]) {
                        .call => |c| switch (c.kind) {
                            .call => |fc| fc,
                            else => break :blk null,
                        },
                        else => break :blk null,
                    };
                    const et = (self.ctorTypeRef(first) catch null) orelse break :blk null;
                    const inner = self.reg_arena.allocator().create(ast.TypeRef) catch break :blk null;
                    inner.* = et;
                    break :blk .{ .array = inner };
                },
                else => null,
            },
            // Decision 319 — a `u64` value, so a `val` bound to it keeps
            // printing and comparing unsigned: an integer literal past
            // `i64`'s top (inference stripped its `ul` and refuses it on any
            // other type) and an operator inference typed `u64` / `usize`.
            // `val top = 18446744073709551615ul; @print(top)` printed `-1`.
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| if (isPastI64Literal(n)) .{ .named = "u64" } else null,
                else => null,
            },
            .binaryOp => |bin| blk: {
                const il = self.instance_lowerings.get(bin.loc) orelse break :blk null;
                if (il != .division) break :blk null;
                break :blk switch (il.division) {
                    .u64 => .{ .named = "u64" },
                    .usize => .{ .named = "usize" },
                    else => null,
                };
            },
            else => null,
        };
    }

    /// The `?T` one element of `recv` is — **the one answer the writer and the
    /// reader of `xs.at(i)` / `xs.first()` both take**, so they cannot drift
    /// apart. `lowerArrayMethod` picks `$__arr_at` or `$__arr_at_box` from it
    /// and `optInfoOf` reports it; while the two decided separately, an array
    /// of RECORDS was written boxed (the element kind a record shares with an
    /// integer) and read as a bare pointer, so `es.at(0)?.key.length()` loaded
    /// the box, then the record's first slot, and printed a heap address
    /// (`276`) at exit 0 where the other three backends answer `3`.
    /// The helper `xs.at(i)` reads one element of `recv` with, by
    /// `arrayElemOpt`: a boxed scalar through `$__arr_at_box`, a pointer — and
    /// a float, whose slot already holds its `f64` cell, the box a `?f64` is —
    /// as the slot's own word.
    fn arrAtHelper(self: *Emitter, recv: ast.Expr) wat.Helper {
        const oi = self.arrayElemOpt(recv);
        return if (oi.boxed and oi.cell == .none) .arr_at_box else .arr_at;
    }

    fn arrayElemOpt(self: *Emitter, recv: ast.Expr) OptInfo {
        // A record is its own pointer: `0` is absence, as it is for a string,
        // and a box would only hide the payload from every reader.
        if (self.elemRecordOf(recv)) |rec| return .{ .boxed = false, .rec = rec };
        if (self.elemIsPointer(recv)) {
            const sh = (self.printShapeOf(recv) catch null).?;
            return .{ .boxed = false, .shape = sh[1..] };
        }
        // A bool element is boxed like an integer, and prints as a bool.
        if ((self.printShapeOf(recv) catch null)) |sh| if (std.mem.eql(u8, sh, "[b")) return .{ .boxed = true, .bool_ = true };
        return switch (self.elemKindOf(recv)) {
            .str => .{ .boxed = false, .str = true },
            .f64 => .{ .boxed = true, .cell = .f64 },
            .i32 => .{ .boxed = true },
        };
    }

    /// Whether one element of `recv` is a CONTAINER — an array or a tuple —
    /// and so a pointer of its own. Read off the print shape, which is the one
    /// place a nested container is already tracked (`[[i` an array of integer
    /// arrays, `[(is)` an array of tuples), for a local as much as for a
    /// literal. A record is the other pointer element and `elemRecordOf`
    /// answers it, because a record's NAME is wanted too.
    fn elemIsPointer(self: *Emitter, recv: ast.Expr) bool {
        const sh = (self.printShapeOf(recv) catch null) orelse return false;
        return sh.len >= 2 and sh[0] == '[' and (sh[1] == '[' or sh[1] == '(');
    }

    /// Whether one element of `recv` is a bool — its print shape is `[b`. The
    /// slot is an `i32` like an integer's, so a binder over it needs the
    /// mark to print `true` and not `1`.
    fn elemIsBool(self: *Emitter, recv: ast.Expr) anyerror!bool {
        const sh = (try self.printShapeOf(recv)) orelse return false;
        return std.mem.eql(u8, sh, "[b");
    }

    /// The record type the elements of an array-valued expression name, when
    /// they name one: an array literal of constructor calls, a local or global
    /// bound to one, a declared `Entry[]`, and the array methods that keep
    /// their receiver's elements.
    fn elemRecordOf(self: *Emitter, e: ast.Expr) ?[]const u8 {
        if (self.genericResultOf(e)) |a| return self.elemRecordOf(a);
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n0| {
                    const n = self.resolveName(n0);
                    if (self.arr_elem_recs.get(n)) |r| return r;
                    if (!self.locals.contains(n)) if (self.arr_elem_rec_globals.get(n)) |r| return r;
                },
                else => {},
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.elemRecordOf(inner.*),
                .arrayLit => |al| if (al.elems.len > 0) {
                    if (self.recordTypeOfExpr(al.elems[0])) |r| return r;
                },
                else => {},
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (self.primKindAt(cc, c.loc)) |k| if (k == .array and keepsElements(cc.callee)) {
                        if (cc.receiver) |r| return self.elemRecordOf(r.*);
                    };
                    // `xs.map({ n -> Y(…) })` holds what its lambda answers:
                    // unregistered, `built.at(1)?.id` read the field off the
                    // element as an address (`run/optional_member_default`).
                    if (std.mem.eql(u8, cc.callee, "map") and cc.receiver != null and cc.args.len == 1) {
                        if (lambdaArg(cc.args[0].value)) |lam| {
                            const body = lam.function.kind.body;
                            if (body.len > 0) if (self.recordTypeOfExpr(body[body.len - 1].expr)) |r| return r;
                        }
                    }
                },
                else => {},
            },
            else => {},
        }
        const t = self.typeRefOf(e) orelse return null;
        return self.elemRecordOfTypeRef(t);
    }

    /// The array methods whose result holds the elements of their receiver.
    fn keepsElements(name: []const u8) bool {
        for ([_][]const u8{ "slice", "rest", "take", "drop", "reverse", "toList", "filter", "sort", "sorted" }) |s| {
            if (std.mem.eql(u8, name, s)) return true;
        }
        return false;
    }

    /// The record an `Entry[]` / `Array<Entry>` / `?Entry[]` spells, when the
    /// element names a record this module declared.
    fn elemRecordOfTypeRef(self: *Emitter, t: ast.TypeRef) ?[]const u8 {
        const elem: ast.TypeRef = switch (eagerTypeRef(t)) {
            .array => |inner| inner.*,
            .generic => |g| if (g.args.len == 1 and (std.mem.eql(u8, g.name, "Array") or
                std.mem.eql(u8, g.name, "Iterator")))
                g.args[0]
            else
                return null,
            .optional => |inner| return self.elemRecordOfTypeRef(inner.*),
            else => return null,
        };
        const name = switch (elem) {
            .named => |n| n,
            else => return null,
        };
        return self.resolveRecordName(name);
    }

    /// The optional an expression evaluates to, when it is one.
    fn optInfoOf(self: *Emitter, e: ast.Expr) ?OptInfo {
        if (self.genericResultOf(e)) |a| return self.optInfoOf(a);
        // `xs?.[k]`: the link's own optional, flattened (decision 330).
        if (optOperatorParts(e)) |op| if (!op.bang) return self.optInfoOf(op.tail);
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
                .call => |cc| if (self.chainedCallOpt(cc, c.loc)) |oi| {
                    return oi;
                } else if (cc.is_builtin and std.mem.eql(u8, cc.callee, "__bp_option_map") and cc.args.len > 1 and lambdaArg(cc.args[1].value) != null) {
                    // `opt.map({ x -> … })` is an optional again, boxed when
                    // the closure answers a scalar (`lowerResultOptionOp`).
                    // Unregistered, a `return` into `-> ?i32` boxed the box
                    // (`lookup(pairs, "b")` printed its address).
                    const body = lambdaArg(cc.args[1].value).?.function.kind.body;
                    if (self.lambdaTailIsPointer(body)) return .{ .boxed = false, .str = self.bodyIsString(body) };
                    return .{ .boxed = true };
                } else if (self.primKindAt(cc, c.loc)) |k| {
                    if (k == .array and
                        (std.mem.eql(u8, cc.callee, "at") or std.mem.eql(u8, cc.callee, "first") or std.mem.eql(u8, cc.callee, "find") or std.mem.eql(u8, cc.callee, "pop")))
                    {
                        return self.arrayElemOpt(cc.receiver.?.*);
                    }
                    // `s.at(i)` → `?string`: `$__str_at` answers the pointer of
                    // a fresh one-byte string, or 0. Without this the result
                    // printed through `$__print_str`, which reads a length at
                    // address 0 — the WASI iovec — and answers whatever is
                    // there with exit 0 instead of saying it is absent.
                    if (k == .string and std.mem.eql(u8, cc.callee, "at")) {
                        return .{ .boxed = false, .str = true };
                    }
                },
                else => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    const rn = self.resolveName(n);
                    // Narrowed: inside the branch the name IS the payload.
                    if (self.narrowed_opts.contains(rn)) return null;
                    if (self.opt_locals.get(rn)) |oi| return oi;
                },
                // `t._1` of a `?T` element: the carrier its shape names.
                // A tuple with no shape here falls to its declared type below.
                .identAccess => |ia| if (!ia.optional and tupleIndex(ia.member) != null) {
                    if (self.tupleElemShapeOf(e) catch null) |el| if (el.len >= 2) switch (el[0]) {
                        '!' => return .{ .boxed = true, .bool_ = el[1] == 'b' },
                        '?' => return switch (el[1]) {
                            'f' => .{ .boxed = true, .cell = .f64 },
                            'l' => .{ .boxed = true, .cell = .i64 },
                            'u' => .{ .boxed = true, .cell = .i64, .inner = .{ .named = "u64" } },
                            's' => .{ .boxed = false, .str = true },
                            else => .{ .boxed = false, .shape = el[1..] },
                        },
                        else => {},
                    };
                } else if (ia.optional) {
                    // `recv?.field` of a scalar field is a boxed optional
                    const rty = self.recordTypeOfExpr(ia.receiver.*) orelse return null;
                    const ft = self.fieldTypeIn(rty, ia.member);
                    if (ft == null or self.resolveRecordName(ft.?) != null) return .{ .boxed = false };
                    if (std.mem.eql(u8, ft.?, "string")) return .{ .boxed = false, .str = true };
                    // A float or `i64` field's slot already holds its cell.
                    if (fieldCellOf(ft.?) != .none) return .{ .boxed = true, .cell = fieldCellOf(ft.?) };
                    return .{ .boxed = true, .bool_ = std.mem.eql(u8, ft.?, "bool") };
                },
                else => {},
            },
            else => {},
        }
        const t = self.typeRefOf(e) orelse return null;
        return self.optInfoOfTypeRef(t);
    }

    /// The bare name `e` reads, when it reads one and nothing else.
    fn plainIdentName(e: ast.Expr) ?[]const u8 {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| n,
                else => null,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| plainIdentName(inner.*),
                else => null,
            },
            else => null,
        };
    }

    fn isEmptyArrayLit(e: ast.Expr) bool {
        return switch (e) {
            .collection => |col| switch (col.kind) {
                .arrayLit => |al| al.elems.len == 0,
                .grouped => |inner| isEmptyArrayLit(inner.*),
                else => false,
            },
            else => false,
        };
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
        // An `unknown` / union slot: every value but one that already is one
        // goes in `lowerAsUnknown`'s box (`lowerBoxedInto`).
        if (isUnknownTypeRef(t)) return !isNullLit(value) and !self.isUnknownExpr(value) and !self.isTaggedValue(value);
        const oi = self.optInfoOfTypeRef(t) orelse return false;
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

    /// The box `boxesInto` asked for: `lowerAsUnknown`'s for an `unknown` /
    /// union slot, a `?T`'s `$__box_i32` cell otherwise.
    fn lowerBoxedInto(self: *Emitter, target: ?ast.TypeRef, value: ast.Expr) anyerror!void {
        if (target) |t| if (isUnknownTypeRef(t)) return self.lowerAsUnknown(value);
        // A `?f64`'s / `?i64`'s box is the value's own 8-byte cell.
        const cell: Cell = if (target) |t| (if (self.optInfoOfTypeRef(t)) |oi| oi.cell else .none) else .none;
        if (cell != .none or Cell.of(self.wasmTypeOf(value)) != .none)
            return self.lowerCellWord(value, if (cell != .none) cell else Cell.of(self.wasmTypeOf(value)));
        try self.lowerCoerced(value, "i32");
        try self.emit(self.builder().helper(.box_i32));
    }

    /// The payload of the boxed optional on the stack: the word its box holds,
    /// or — a `?f64` — the `f64` its cell holds.
    fn emitUnboxPayload(self: *Emitter, o: OptInfo, what: []const u8) !void {
        try self.emitC(.{ .load = .{ .ty = vt(o.cell.ty()) } }, what);
    }

    // ── record inherent methods ──────────────────────────────────────────────

    /// `$<Record>_<method>` for `recv.method(…)` when inference tagged the
    /// receiver as a record value and the module emitted that method.
    /// Inference names a receiver's type by its bare name. When two linked
    /// modules declare that name, the later one is registered as
    /// `<module>/<Name>` (`link_mangled_types`), and the value's own module
    /// says which of the two a method call means — recovered from the
    /// expression as a field read's receiver is. Without this,
    /// `netOutcome().describe()` called the FIRST declaration's `describe`
    /// over the second one's layout and printed the neighbouring field.
    fn ownerAmongTwins(self: *Emitter, rec: []const u8, recv: ast.Expr) []const u8 {
        if (self.link_mangled_types.count() == 0) return rec;
        const own = self.recordTypeOfExpr(recv) orelse return rec;
        if (!std.mem.eql(u8, own, rec) and std.mem.eql(u8, displayTypeName(own), rec)) return own;
        return rec;
    }

    fn recordMethodSym(self: *Emitter, cc: anytype, loc: ast.Loc) ?[]const u8 {
        if (cc.receiver == null or cc.is_builtin) return null;
        // Inference records no note for a method on a value of an IMPORTED
        // type (`queryOf(xs).toArray()` with `Query` declared in `shapes`), so
        // the receiver's record is recovered here as it is for a field read —
        // the modules are linked into this one, so its `<Type>_<method>` is
        // emitted beside the local ones. Without it the call fell through and
        // `.length` on its result answered `0` at exit 0.
        const rec0 = if (self.instance_lowerings.get(loc)) |il| switch (il) {
            // A type this module never imported is linked in all the same.
            .type_, .unplaced_type => |r| r,
            // A behavior-typed receiver is answered by the value's own type
            // (`lowerBehaviorDispatch`) whenever some type of the module
            // declares the method: a record recovered from the expression is
            // a guess — `Array<Request>`'s elements were all read as the
            // first literal's `Page`, and `Api(3).weight(2)` answered `2`.
            .by_value => blk: {
                const impls = self.behaviorImplementers(cc.callee, cc.args.len) catch return null;
                if (impls.len > 0) return null;
                break :blk self.recordTypeOfExpr(cc.receiver.?.*) orelse return null;
            },
            .prim, .field_of, .sequence_next, .division => return null,
        } else self.recordTypeOfExpr(cc.receiver.?.*) orelse return null;
        const rec = self.ownerAmongTwins(rec0, cc.receiver.?.*);
        const sym = std.fmt.bufPrint(&self.sym_buf, "{s}_{s}", .{ rec, cc.callee }) catch return null;
        if (!self.fn_sigs.contains(sym)) return null;
        if (self.generic_methods.contains(sym)) {
            const generic = self.reg_arena.allocator().dupe(u8, sym) catch return null;
            return (self.specializeMethod(generic, cc) catch null) orelse generic;
        }
        return sym;
    }

    /// `specializedCallee` for a method of a generic `type`: the receiver's
    /// written type arguments (`Dict<string, string>`) and the arguments'
    /// shapes bind the owner's and the method's type parameters, and the call
    /// goes to a copy of the method with them substituted
    /// (`Dict_at__K_string__V_string`). One body compared two `K` keys as
    /// WORDS — a key `split` built at run time never equalled the literal
    /// (C-18) — and read a `?V` as a box whatever `V` was.
    fn specializeMethod(self: *Emitter, sym: []const u8, cc: anytype) !?[]const u8 {
        const gm = self.generic_methods.get(sym) orelse return null;
        const m = gm.method;
        const ar = self.reg_arena.allocator();
        var subs: std.ArrayListUnmanaged(TypeSub) = .empty;
        var needed = false;
        const Local = struct {
            fn has(list: []const TypeSub, n: []const u8) bool {
                for (list) |sub| if (std.mem.eql(u8, sub.name, n)) return true;
                return false;
            }
        };
        // The receiver's written type arguments, in the owner's order.
        if (self.typeRefOf(cc.receiver.?.*)) |tr| switch (tr) {
            .generic => |g| if (g.args.len == gm.tparams.len) for (g.args, gm.tparams) |arg, gp| switch (arg) {
                .named => |n| if (primKindOfName(n) != null or self.records.contains(n)) {
                    try subs.append(ar, .{ .name = gp.name, .to = arg });
                    if (std.mem.eql(u8, n, "string") or std.mem.eql(u8, n, "bool") or n[0] == 'f') needed = true;
                },
                else => {},
            },
            else => {},
        };
        // The arguments, for a parameter written as a bare type parameter.
        var params_of: std.ArrayListUnmanaged([]const u8) = .empty;
        var pi: usize = 0;
        for (m.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            defer pi += 1;
            if (pi >= cc.args.len) break;
            const bnd = self.bindParam(p.typeRef, cc.args[pi].value.*, &isGenericParamName, gm.tparams, m.genericParams) orelse continue;
            try params_of.append(ar, p.name);
            if (Local.has(subs.items, bnd.name)) continue;
            try subs.append(ar, .{ .name = bnd.name, .to = .{ .named = bnd.ty } });
            if (std.mem.eql(u8, bnd.ty, "string") or std.mem.eql(u8, bnd.ty, "bool") or bnd.ty[0] == 'f') needed = true;
        }
        if (subs.items.len == 0) return null;
        if (!needed and !callsMethodOn(ast.BehaviorMethod, m, params_of.items)) return null;
        var name: std.ArrayListUnmanaged(u8) = .empty;
        try name.appendSlice(ar, m.name);
        for (subs.items) |sub| try name.print(ar, "__{s}_{s}", .{ sub.name, sub.to.named });
        const out = try std.fmt.allocPrint(ar, "{s}_{s}", .{ gm.owner, name.items });
        if (self.spec_names.contains(out)) return out;
        try self.spec_names.put(self.alloc, out, {});
        var copy = try substTypeParams(ast.BehaviorMethod, ar, m, subs.items);
        copy.name = name.items;
        var left_owner: std.ArrayListUnmanaged(ast.GenericParam) = .empty;
        for (gm.tparams) |gp| if (!Local.has(subs.items, gp.name)) try left_owner.append(ar, gp);
        var left_own: std.ArrayListUnmanaged(ast.GenericParam) = .empty;
        for (m.genericParams) |gp| if (!Local.has(subs.items, gp.name)) try left_own.append(ar, gp);
        copy.genericParams = left_own.items;
        try self.registerInterfaceSigs(gm.owner, left_owner.items, &.{copy});
        try self.mspec_pending.append(self.alloc, .{
            .owner = gm.owner,
            .tparams = left_owner.items,
            .method = copy,
            .rewrites = gm.rewrites,
            .lowerings = gm.lowerings,
            .renames = gm.renames,
            .subs = subs.items,
            .origin = self.specOrigin(gm.linked),
        });
        return out;
    }

    /// `c.atual()` on a record value → `call $Contador_atual` with the receiver
    /// as the `self` argument.
    fn lowerRecordMethod(self: *Emitter, cc: anytype, loc: ast.Loc) anyerror!bool {
        const sym_tmp = self.recordMethodSym(cc, loc) orelse return false;
        const sym = try self.arena().dupe(u8, sym_tmp);
        if (self.generic_methods.contains(sym)) try self.noteTemplateCall(sym, loc);
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
            // Decision 240: a string counts codepoints, an array its slots.
            if (self.isStringExpr(recv.*))
                try self.emit(self.builder().helper(.str_cp_len))
            else
                try self.emitC(.{ .load = .{} }, ".length (array prefix)");
            return true;
        }
        return false;
    }

    fn lowerRecordCtor(self: *Emitter, cc: anytype, fields: []const []const u8) anyerror!void {
        const expected_ctor = self.expected_ctor;
        self.expected_ctor = null;
        const desc = try self.typeDescriptorAddr(cc.callee, null);
        const base = try self.allocTagged(desc orelse 0, @intCast(fields.len * 4));
        for (fields, 0..) |fname, i| {
            const off: u32 = @intCast(tag_header_bytes + i * 4);
            if (self.argForField(cc.args, fname, i)) |arg| {
                const ftref: ?ast.TypeRef = if (self.record_field_typerefs.get(cc.callee)) |ts| (if (i < ts.len) ts[i] else null) else null;
                if (self.boxesInto(ftref, arg.value.*)) {
                    try self.emit(.{ .local_get = base });
                    try self.lowerBoxedInto(ftref, arg.value.*);
                    try self.emit(.{ .store = .{ .offset = off } });
                } else if (fieldCellOf(self.fieldTypeIn(cc.callee, fname) orelse "") != .none) {
                    // A float or `i64` field holds the address of its cell.
                    try self.emit(.{ .local_get = base });
                    try self.lowerCellWord(arg.value.*, fieldCellOf(self.fieldTypeIn(cc.callee, fname).?));
                    try self.emit(.{ .store = .{ .offset = off } });
                } else {
                    // A lambda stored in a function-typed field takes its
                    // parameter types from the field's declaration, as one
                    // bound to an annotated `val` does: `{ s -> prefix + s }`
                    // in a `fn(s: string) -> string` field concatenates.
                    // A field written `T` under an expected `Box<fn(…) -> R>`:
                    // the lambda is written against the type argument.
                    const fexp: ?ast.TypeRef = blk: {
                        const ft = ftref orelse break :blk null;
                        const et = expected_ctor orelse break :blk ftref;
                        if (ft != .named or et != .generic or !std.mem.eql(u8, et.generic.name, cc.callee)) break :blk ftref;
                        const gps = self.record_generics.get(cc.callee) orelse break :blk ftref;
                        for (gps, 0..) |gp, gi| if (std.mem.eql(u8, gp.name, ft.named) and gi < et.generic.args.len) break :blk et.generic.args[gi];
                        break :blk ftref;
                    };
                    if (arg.value.* == .function) self.expected_fn = fexp;
                    defer self.expected_fn = null;
                    // A float or an `i64` in a field its declaration does not
                    // type as one (`Box<T>(value: T)`): the slot would hold a
                    // cell that every reader of `T` takes for a word — `300`
                    // printed for `Box(value: 1.1).value` at exit 0.
                    if (Cell.of(self.wasmTypeOf(arg.value.*)) != .none)
                        return self.refuse(arg.value.getLoc(), "the wasm backend cannot hold an `{s}` in field `{s}`: its declared type is not one, and its readers take a word", .{ self.wasmTypeOf(arg.value.*), fname });
                    const lambda_at: u32 = @intCast(self.lambdas.items.len);
                    try self.storeSlotExpr(base, off, arg.value.*);
                    if (arg.value.* == .function and self.lambdas.items.len > lambda_at) {
                        try self.ctor_lambdas.append(self.reg_arena.allocator(), .{ .field = fname, .idx = lambda_at });
                        // A field written as the record's type parameter
                        // (`Box<T>(value: T)`) types nothing: the lambda's
                        // parameters are unknown until a call through the
                        // field passes them (`field_closures`).
                        const generic_slot = (fexp == null or fexp.? != .function) and if (ftref) |ft| ft == .named and (if (self.record_generics.get(cc.callee)) |gps| isGenericParamName(ft.named, gps, &.{}) else false) else false;
                        if (generic_slot) @memset(self.lambdas.items[lambda_at].param_known, false);
                    }
                }
            } else {
                try self.storeSlotConst(base, off, 0);
            }
        }
        try self.loadTaggedBase(base);
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
        const desc = try self.variantDescriptorAddr(receiverName(cc) orelse self.enumOfVariant(variant.name) orelse "", variant);
        const base = try self.allocTagged(desc orelse 0, @intCast(nslots * 4));
        try self.storeSlotConst(base, tag_header_bytes, tag);
        for (variant.fields, 0..) |vf, i| {
            const off: u32 = @intCast(tag_header_bytes + (i + 1) * 4);
            if (self.argForField(cc.args, vf.name, i)) |arg| {
                // A float's slot holds its cell, which only a payload declared
                // a float is read as: under a type parameter (`Some(v: T)`) a
                // binder and the printer took the cell's address for the value.
                const declared_float = switch (vf.typeRef) {
                    .named => |n| isFloatTypeName(n),
                    else => false,
                };
                if (self.wasmTypeOf(arg.value.*)[0] == 'f' and !declared_float)
                    return self.refuse(arg.value.getLoc(), "the wasm backend cannot hold an `f64` in payload `{s}`: its declared type is not one, and its readers take a word", .{vf.name});
                try self.storeSlotExpr(base, off, arg.value.*);
            } else {
                try self.storeSlotConst(base, off, 0);
            }
        }
        try self.loadTaggedBase(base);
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
                // Decision 240: a string counts codepoints.
                if (il.prim == .string)
                    try self.emit(self.builder().helper(.str_cp_len))
                else
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
                if (self.isStringExpr(ia.receiver.*))
                    try self.emit(self.builder().helper(.str_cp_len))
                else
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
        // Tuple element access: `_0`, `_1`, ... → load at `index * 4`; a
        // float element's slot holds its cell.
        if (tupleIndex(ia.member)) |idx| {
            try self.lowerExpr(ia.receiver.*);
            try self.emitLoadOffset(idx * 4);
            if (try self.tupleElemShapeOf(.{ .identifier = .{ .loc = loc, .kind = .{ .identAccess = ia } } })) |el| try self.emitFromCell(shapeCell(el));
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
                // A float or `i64` field holds its cell.
                try self.emitFromCell(fieldCellOf(self.fieldTypeIn(rty, ia.member) orelse ""));
                return;
            }
        }
        // Type recovery failed — try the name-unique fallback. `?.` on this
        // path still has to short-circuit on a null pointer, so use the same
        // `local.tee` + `i32.eqz` guard as the typed branch above.
        if (self.uniqueFieldOffset(ia.member)) |off| {
            // The slot of a float field holds a cell, which a read by the
            // name alone cannot tell from an integer's word.
            if (self.someFieldIsFloat(ia.member))
                return self.refuse(loc, "the wasm backend cannot read `.{s}`: the receiver's type is not known here, and a record declares it a float or an `i64`", .{ia.member});
            if (ia.optional) {
                try self.lowerOptionalField(ia, off, " (unique)");
                return;
            }
            try self.lowerExpr(ia.receiver.*);
            try self.emitLoadOffset(off);
            return;
        }
        // Both heuristics failed. This used to write `i32.const 0` "so
        // wasmtime still executes the surrounding fn" — the program then
        // printed `0` for a field it never read, at exit 0.
        return self.refuse(loc, "the wasm backend cannot place `{s}.{s}`: the receiver's type is not known here", .{ if (ia.optional) "?" else "", ia.member });
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
            if (oi.boxed and oi.cell == .none) try self.emitAt(8, self.builder().helper(.box_i32));
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
    /// Decision 22 — the descriptor a record's values carry:
    /// `'R' <n> Name <k> [ <n> field <shape…> ] * k`, interned as an ordinary
    /// data segment (so two identical descriptors are one blob) and addressed
    /// past its length word. Null when this module never declared the type.
    fn typeDescriptorAddr(self: *Emitter, name: []const u8, _: ?u8) anyerror!?u32 {
        if (self.type_descs.get(name)) |addr| return addr;
        const fields = self.records.get(name) orelse return null;
        var out: std.ArrayListUnmanaged(u8) = .empty;
        try out.append(self.arena(), 'R');
        try self.appendNameAndFields(&out, name, fields, self.record_field_typerefs.get(name), true);
        const seg = try self.internString(out.items);
        const addr = seg.offset + 4;
        try self.type_descs.put(name, addr);
        return addr;
    }

    /// An enum every variant of which is a unit variant: its value is the
    /// ordinal, with no allocation and no header.
    fn isAllUnitEnum(self: *Emitter, name: []const u8) bool {
        const variants = self.enums.get(name) orelse return false;
        return variants.len > 0 and !enumHasPayload(variants);
    }

    /// `Color.Red` written against an all-unit enum: the enum's name.
    fn unitEnumMember(self: *Emitter, ia: anytype) ?[]const u8 {
        const ename = switch (ia.receiver.*) {
            .identifier => |rid| switch (rid.kind) {
                .ident => |n| n,
                else => return null,
            },
            else => return null,
        };
        if (!self.isAllUnitEnum(ename)) return null;
        for (self.enums.get(ename).?) |v| if (std.mem.eql(u8, v.name, ia.member)) return ename;
        return null;
    }

    /// The all-unit enum `e` is a value of, when a declaration says so: a
    /// member written by its path, a name, a field or a call whose declared
    /// type is the enum. Its value is an ordinal, so it prints by the shape
    /// `unitEnumShape` spells, never through the numeric printer.
    fn unitEnumOf(self: *Emitter, e: ast.Expr) ?[]const u8 {
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .identAccess => |ia| if (self.unitEnumMember(ia)) |en| return en,
                else => {},
            },
            // `if (c) { Color.Green } else { Color.Red }`: both arms answer one
            // type, and an arm's tail says which.
            .branch => |b| switch (b.kind) {
                .if_ => |i| {
                    const els = i.else_ orelse return null;
                    if (i.then_.len > 0) if (self.unitEnumOf(i.then_[i.then_.len - 1].expr)) |en| return en;
                    if (els.len > 0) return self.unitEnumOf(els[els.len - 1].expr);
                    return null;
                },
                else => {},
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.unitEnumOf(inner.*),
                else => {},
            },
            else => {},
        }
        const tr = self.typeRefOf(e) orelse return null;
        return switch (tr) {
            .named => |n| if (self.isAllUnitEnum(n)) n else null,
            else => null,
        };
    }

    /// The print shape of the payload of a boxed `?E` over an all-unit enum:
    /// a declared `?Color`, or `cs.at(i)` / `cs.first()` over an array whose
    /// elements print by such a shape.
    fn optUnitEnumShape(self: *Emitter, e: ast.Expr, oi: OptInfo) anyerror!?[]const u8 {
        if (oi.inner) |inner| switch (inner) {
            .named => |n| if (self.isAllUnitEnum(n)) return try self.unitEnumShape(n),
            else => {},
        };
        if (self.typeRefOf(e)) |tr| switch (tr) {
            .optional => |i| switch (i.*) {
                .named => |n| if (self.isAllUnitEnum(n)) return try self.unitEnumShape(n),
                else => {},
            },
            else => {},
        };
        const cc = switch (e) {
            .call => |c| switch (c.kind) {
                .call => |cc| cc,
                else => return null,
            },
            else => return null,
        };
        const recv = cc.receiver orelse return null;
        const shape = (try self.printShapeOf(recv.*)) orelse return null;
        if (shape.len > 1 and shape[0] == '[' and shape[1] == 'E') return shape[1..];
        return null;
    }

    /// `E k [ <n> Enum.Variant ] * k` — the print shape of an all-unit enum's
    /// value (`$__print_shaped_raw`): the ordinal picks the name.
    fn unitEnumShape(self: *Emitter, ename: []const u8) anyerror![]const u8 {
        const variants = self.enums.get(ename) orelse return error.UnknownEnum;
        if (variants.len > 255) return error.NameTooLong;
        const a = self.arena();
        var out: std.ArrayListUnmanaged(u8) = .empty;
        try out.append(a, 'E');
        try out.append(a, @intCast(variants.len));
        for (variants) |v| {
            const text = try std.fmt.allocPrint(a, "{s}.{s}", .{ self.printed_names.get(ename) orelse displayTypeName(ename), v.name });
            if (text.len > 255) return error.NameTooLong;
            try out.append(a, @intCast(text.len));
            try out.appendSlice(a, text);
        }
        return out.items;
    }

    /// The same for ONE variant — its name is written `Enum.Variant`, which is
    /// the text decision 8 §7 wants, and its fields start one slot in because
    /// slot 0 holds the ordinal the `case` arms test.
    fn variantDescriptorAddr(self: *Emitter, ename: []const u8, v: ast.EnumVariant) anyerror!?u32 {
        if (ename.len == 0) return null;
        const key = try std.fmt.allocPrint(self.reg_arena.allocator(), "{s}.{s}", .{ ename, v.name });
        if (self.type_descs.get(key)) |addr| return addr;
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var refs: std.ArrayListUnmanaged(ast.TypeRef) = .empty;
        for (v.fields) |f| {
            try names.append(self.arena(), f.name);
            try refs.append(self.arena(), f.typeRef);
        }
        var out: std.ArrayListUnmanaged(u8) = .empty;
        try out.append(self.arena(), 'V');
        try self.appendNameAndFields(&out, key, names.items, refs.items, false);
        const seg = try self.internString(out.items);
        const addr = seg.offset + 4;
        try self.type_descs.put(key, addr);
        return addr;
    }

    /// `<n> name <k> [ <n> field <shape…> ] * k`. A name longer than 255 bytes
    /// has no descriptor — the format is length-prefixed by a byte, and a
    /// silently truncated name would print the wrong type.
    fn appendNameAndFields(
        self: *Emitter,
        out: *std.ArrayListUnmanaged(u8),
        name: []const u8,
        fields: []const []const u8,
        refs: ?[]const ast.TypeRef,
        /// A record's `i64` field holds a cell (`l`, `u` for a `u64`); a
        /// variant's payload holds only an `i32` word, the one an `i64` slot
        /// is ever given.
        record: bool,
    ) anyerror!void {
        const a = self.arena();
        const shown = self.printed_names.get(name) orelse displayTypeName(name);
        if (shown.len > 255 or fields.len > 255) return error.NameTooLong;
        try out.append(a, @intCast(shown.len));
        try out.appendSlice(a, shown);
        try out.append(a, @intCast(fields.len));
        for (fields, 0..) |fname, i| {
            if (fname.len > 255) return error.NameTooLong;
            try out.append(a, @intCast(fname.len));
            try out.appendSlice(a, fname);
            const tref: ?ast.TypeRef = if (refs) |rs| (if (i < rs.len) rs[i] else null) else null;
            const wide: ?u8 = if (tref) |t| switch (t) {
                .named => |n| i64CellCode(n),
                else => null,
            } else null;
            if (record) if (wide) |c| {
                try out.append(a, c);
                continue;
            };
            try out.appendSlice(a, try self.fieldShape(tref));
        }
    }

    /// The `$__print_shaped_raw` code a field's declared type takes. An
    /// unknown type is `i`, which is what the numeric printer answered for
    /// every field before this existed.
    fn fieldShape(self: *Emitter, t: ?ast.TypeRef) anyerror![]const u8 {
        const tref = t orelse return "i";
        if (try self.typeRefShape(tref)) |shape| return shape;
        // An enum with a payload variant is a pointer to a tagged `[tag, …]`
        // cell, every value of it — a unit variant too — carrying its
        // variant's descriptor, so it prints by its header like a record. An
        // optional field prints by its payload's shape behind `?` / `!`
        // (`optElemShape`). Both fell to `i`, so `place: Place.Here` and
        // `maybe: ?Target` printed the cell's address.
        switch (tref) {
            .named => |n| if (self.enums.contains(n) and !self.isAllUnitEnum(n)) return "T",
            .optional => |inner| {
                if (inner.* == .named and self.enums.contains(inner.named)) {
                    // `?Color` boxes the ordinal (`optInfoOfTypeRef`): `!`
                    // reads the box, then the enum's own names.
                    if (self.isAllUnitEnum(inner.named)) return try std.fmt.allocPrint(self.arena(), "!{s}", .{try self.unitEnumShape(inner.named)});
                    return "?T";
                }
                if (self.optInfoOfTypeRef(tref)) |oi| if (try self.optElemShape(oi, null)) |sh| return sh;
            },
            else => {},
        }
        const code = scalarCode(tref) orelse 'i';
        return switch (code) {
            's' => "s",
            'b' => "b",
            'f' => "f",
            else => "i",
        };
    }

    /// The enum that declares `vname`, when exactly one does.
    fn enumOfVariant(self: *Emitter, vname: []const u8) ?[]const u8 {
        var found: ?[]const u8 = null;
        var it = self.enums.iterator();
        while (it.next()) |e| {
            for (e.value_ptr.*) |v| {
                if (!std.mem.eql(u8, v.name, vname)) continue;
                if (found != null) return null;
                found = e.key_ptr.*;
                break;
            }
        }
        return found;
    }

    /// Whether a record this module knows declares a field `name` held in a
    /// cell — a float or an `i64`.
    fn someFieldIsFloat(self: *Emitter, name: []const u8) bool {
        var it = self.records.iterator();
        while (it.next()) |entry| {
            if (fieldCellOf(self.fieldTypeIn(entry.key_ptr.*, name) orelse "") != .none) return true;
        }
        return false;
    }

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
        if (blockResultOf(e)) |a| return self.isStringExpr(a);
        if (optOperatorParts(e)) |op| if (op.bang) return if (self.optInfoOf(op.cond.*)) |oi| oi.str else false;
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
                    break :blk self.str_locals.contains(self.resolveName(n)) or self.str_globals.contains(self.resolveName(n));
                },
                .identAccess => |ia| blk: {
                    // A **tuple element** whose type is a string: `t._1`, and a
                    // label the checker resolved to its position
                    // (`row.name` → `row._0`). The tuple's shape was known to
                    // `printShapeOf` and to nothing else, so `@print` fell
                    // through to the numeric printer and answered the element's
                    // heap address — `256` where it means `x`.
                    if (self.tupleElemShapeOf(e) catch null) |el| break :blk std.mem.eql(u8, el, "s");
                    // A record field declared `string`.
                    const rty = self.recordTypeOfExpr(ia.receiver.*) orelse break :blk false;
                    const ft = self.fieldTypeIn(rty, ia.member) orelse break :blk false;
                    break :blk std.mem.eql(u8, self.recvTypeArg(ia.receiver.*, rty, ft), "string");
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
                        if (!self.armIsString(arm.body)) break :blk false;
                        any = true;
                    }
                    break :blk any;
                },
                else => false,
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| blk: {
                    const els = i.else_ orelse break :blk false;
                    // An optional-binding `if` — what `a ?? b` is written as
                    // — has both arms of one type by construction, and the
                    // payload arm reads a binder nothing typed, so the default
                    // arm alone proves it. Requiring both made `["x", "yz"]
                    // .at(1) ?? "none"` print the string's address at exit 0.
                    if (i.binding != null) break :blk self.bodyIsString(i.then_) or self.bodyIsString(els);
                    break :blk self.bodyIsString(i.then_) and self.bodyIsString(els);
                },
                // Both sides have the payload's type; either one proves it.
                .tryCatch => |tc| self.isStringExpr(tc.handler.*) or self.resultOfStringCall(tc.expr.*),
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (self.primAssocHelper(cc) != null) break :blk true;
                    if (self.primKindAt(cc, c.loc)) |k| break :blk self.primRes(k, cc) == .str;
                    if (isStrSlice(cc)) break :blk true;
                    // `s[i]` / `s[a..b]` (decision 30) answer a string; an
                    // array index answers a string when its elements are ones.
                    if (self.indexArgs(cc)) |ix| break :blk if (self.isStringExpr(ix.recv))
                        true
                    else
                        self.isArrayExpr(ix.recv) and !ix.is_slice and self.elemKindOf(ix.recv) == .str;
                    // `o.unwrapOr(d)` / `r.unwrapOr(d)`: the payload and
                    // the default share one type, and the default says it.
                    if (isUnwrapOr(cc)) break :blk self.isStringExpr(cc.args[1].value.*);
                    if (cc.is_builtin) break :blk false;
                    if (self.genericResultArg(cc)) |a| break :blk self.isStringExpr(a);
                    if (cc.receiver == null and self.locals.contains(cc.callee)) {
                        if (self.closure_locals.get(cc.callee)) |li| break :blk self.closureCallIsString(li, cc);
                    }
                    // `lam.value("e")` over a constructor-stored lambda.
                    // Only a yes: the field's declared type may say more than
                    // the body judged alone (`v.tagOf(e)` over `fn(e: El) -> string`).
                    if (cc.receiver) |r| if (self.fieldClosureOf(r.*, cc.callee)) |li| if (self.closureCallIsString(li, cc)) break :blk true;
                    if (self.resolvedCallSym(cc, c.loc)) |sym| {
                        if (self.str_fns.contains(sym)) break :blk true;
                    }
                    // A call through a record literal's lambda field — a
                    // behavior literal's method — is a string when the
                    // lambda's body is, its parameters shaped by the call's
                    // arguments (the receiver first for a `self` method).
                    if (self.fieldLambdaCallIsString(cc)) break :blk true;
                    // A function value whose declared type returns a string:
                    // `greeter("a")("b")`, or `f("b")` after `val f =
                    // greeter("a")`. Without it the result printed as the
                    // string's heap address at exit 0.
                    if (self.valueCallTypeRef(cc)) |t| break :blk isStringTypeRef(t);
                    break :blk false;
                },
                else => false,
            },
            .useHook => |uh| self.isStringExpr(uh.kind.inner.*),
            .jump => |j| switch (j.kind) {
                .try_ => |v| if (v) |x| self.resultOfStringCall(x.*) else false,
                // `await t` is `t` here (the eager `@Task`).
                .await_ => |a| self.isStringExpr(a.*),
                else => false,
            },
            else => false,
        };
    }

    /// `f()` where `f` is declared `-> @Result<string, …>`.
    fn resultOfStringCall(self: *Emitter, e: ast.Expr) bool {
        return switch (e) {
            // A local or a record field declared `@Result<string, …>`.
            .identifier => resultOfString(self.typeRefOf(e) orelse return false),
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    const sym = self.calleeSymbol(cc, c.loc) orelse self.resolvedCallSym(cc, c.loc) orelse break :blk false;
                    break :blk self.result_str_fns.contains(sym);
                },
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.resultOfStringCall(inner.*),
                else => false,
            },
            .jump => |j| switch (j.kind) {
                .await_ => |a| self.resultOfStringCall(a.*),
                else => false,
            },
            .useHook => |uh| self.resultOfStringCall(uh.kind.inner.*),
            else => false,
        };
    }

    /// What a `@Result` value's payloads are: `ok_str` / `err_str` for the
    /// shapes recovered from an expression alone, and — when a declared type
    /// names them — the payload types themselves, so a `case` binder is typed
    /// in full (a string, an array, a record, another `@Result`).
    const ResultShape = struct {
        ok_str: bool = false,
        err_str: bool = false,
        ok: ?ast.TypeRef = null,
        err: ?ast.TypeRef = null,
    };

    fn resultShapeOfTypeRef(t: ast.TypeRef) ?ResultShape {
        return switch (eagerTypeRef(t)) {
            .generic => |g| if (std.mem.endsWith(u8, g.name, "Result") and g.args.len == 2) .{
                .ok_str = isStringTypeRef(g.args[0]),
                .err_str = isStringTypeRef(g.args[1]),
                .ok = g.args[0],
                .err = g.args[1],
            } else null,
            else => null,
        };
    }

    /// The payload type a `try <call>` binds — the `Ok` type of the call's
    /// declared `@Result` — or null for anything else.
    fn tryPayloadTypeRef(self: *Emitter, e: ast.Expr) ?ast.TypeRef {
        const inner = switch (e) {
            .jump => |j| switch (j.kind) {
                .try_ => |v| v orelse return null,
                else => return null,
            },
            else => return null,
        };
        const shape = self.resultShapeOf(inner.*) orelse return null;
        return shape.ok;
    }

    fn resultShapeOf(self: *Emitter, e: ast.Expr) ?ResultShape {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.result_shape_locals.get(self.resolveName(n)) orelse
                    resultShapeOfTypeRef(self.typeRefOf(e) orelse return null),
                // A record field declared `@Result<…>`.
                else => resultShapeOfTypeRef(self.typeRefOf(e) orelse return null),
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
            .jump => |j| switch (j.kind) {
                .await_ => |a| self.resultShapeOf(a.*),
                else => null,
            },
            .useHook => |uh| self.resultShapeOf(uh.kind.inner.*),
            else => null,
        };
    }

    /// `@Result<string, E>`.
    fn resultOfString(t: ast.TypeRef) bool {
        return switch (eagerTypeRef(t)) {
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
    /// A tuple that is not a literal — a local bound to one — says what its
    /// element `i` is by its print shape: `val #(a, b) = t` over a
    /// `#(1.1, "a")` printed `b` as the string's address (`264`) at exit 0.
    fn noteTupleElemByShape(self: *Emitter, name: []const u8, value: ast.Expr, i: usize) !void {
        const sh = (try self.printShapeOf(value)) orelse return;
        const el = tupleShapeElem(sh, @intCast(i)) orelse return;
        try self.noteTupleElemLocal(name, el);
    }

    /// The binder of one element of the array `arr`, when the element is a
    /// tuple or an array: its print shape, the one its reads go by.
    fn noteElemShape(self: *Emitter, elem: []const u8, arr: ast.Expr) !void {
        const sh = (try self.printShapeOf(arr)) orelse return;
        if (sh.len > 1 and sh[0] == '[' and (sh[1] == '(' or sh[1] == '[')) try self.noteTupleElemLocal(elem, sh[1..]);
    }

    /// The cell element `i` of the tuple `value` holds in its slot: a float's
    /// `f64`, a 64-bit integer's `i64`, `.none` for a word.
    fn tupleElemCell(self: *Emitter, value: ast.Expr, i: usize) !Cell {
        const sh = (try self.printShapeOf(value)) orelse return .none;
        const el = tupleShapeElem(sh, @intCast(i)) orelse return .none;
        return shapeCell(el);
    }

    fn noteTupleElemShape(self: *Emitter, name: []const u8, value: ast.Expr, i: usize) !void {
        const elems = switch (value) {
            .collection => |col| switch (col.kind) {
                .tupleLit => |tl| tl.elems,
                else => return self.noteTupleElemByShape(name, value, i),
            },
            else => return self.noteTupleElemByShape(name, value, i),
        };
        if (i >= elems.len) return;
        if (self.isStringExpr(elems[i])) try self.str_locals.put(name, {});
        if (self.isBoolExpr(elems[i])) try self.bool_locals.put(name, {});
    }

    /// Whether a `case` ARM answers a string. A BRACE arm — `case x { 5 {
    /// "five" } … }` — parses its body as a parameterless block, which arrives
    /// here as a `.function`, and a lambda VALUE is a closure pointer, so only
    /// this position may look through one: its value is its last statement's.
    /// Only the ARROW spelling (`5 -> "five";`) was a string before, so the
    /// same program answered `five` one way and the pointer `256` the other,
    /// at exit 0, where commonJS and erlang answer `five` for both.
    fn armIsString(self: *Emitter, body: ast.Expr) bool {
        return switch (body) {
            .function => |f| f.kind.params.len == 0 and self.bodyIsString(f.kind.body),
            else => self.isStringExpr(body),
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
            if (oi.cell == .f64) {
                try self.emit(.{ .load = .{ .ty = .f64 } });
                try self.emit(self.builder().helper(.f64_to_str));
            } else if (oi.cell == .i64) {
                try self.emit(.{ .load = .{ .ty = .i64 } });
                try self.emit(self.builder().helper(.i64_to_str));
            } else if (oi.boxed) {
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
        if (std.mem.eql(u8, self.wasmTypeOf(e), "i64")) {
            try self.lowerValue(e);
            try self.emit(self.builder().helper(if (self.isU64Expr(e)) .u64_to_str else .i64_to_str));
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
        if (cc.args.len > 1 and !isNullLit(cc.args[1].value.*)) {
            try self.lowerSliceEnd(cc.args[1].value.*);
        } else {
            // No end argument — or a written `null` (`s.slice(2, null)`, what
            // `s[2..]` passes): slice to the end. `$__str_cp_slice` clamps an
            // end past the codepoint count to it, so "to the end" is the
            // largest i32. `null` lowered as `0` once made the end fall
            // before the start and the byte cutter read out of bounds.
            try self.emit(try self.constInt(std.math.maxInt(i32)));
        }
        // Decision 240: the bounds are codepoints, normalised as `slice`
        // normalises them (negative from the end, clamped).
        try self.emit(self.builder().helper(.str_cp_slice));
    }

    /// A slice's `end: ?i32` that is not the literal `null`: a plain `i32`, or
    /// an optional whose absence means "to the end" — the largest i32, which
    /// `$__str_cp_slice` and `$__arr_slice` both clamp.
    fn lowerSliceEnd(self: *Emitter, end: ast.Expr) anyerror!void {
        const oi = self.optInfoOf(end) orelse return self.lowerCoerced(end, "i32");
        if (!oi.boxed) return self.lowerCoerced(end, "i32");
        const tmp = try self.memName(self.nextMem());
        try self.lowerCoerced(end, "i32");
        try self.emit(.{ .local_tee = tmp });
        try self.emit(opOf("i32", "eqz"));
        var then_c: Capture = .{};
        self.open(&then_c);
        try self.emit(try self.constInt(std.math.maxInt(i32)));
        const then_seq = self.seal(&then_c, .{ .value = .i32 });
        var else_c: Capture = .{};
        self.open(&else_c);
        try self.emit(.{ .local_get = tmp });
        try self.emitC(.{ .load = .{} }, "slice end");
        const else_seq = self.seal(&else_c, .{ .value = .i32 });
        try self.emit(.{ .@"if" = .{ .result = .i32, .then = .{ .seq = then_seq }, .@"else" = .{ .seq = else_seq } } });
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
        if (lp.generator != null) return self.lowerGeneratorLoop(lp);
        // Every other loop is a statement (decision 105); inside a generator
        // fn its `yield`s feed the fn's accumulator (`renderAccumulatingBody`).
        const result: ?[]const u8 = null;
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
        // An iterable this backend cannot tell is an array — a lambda-backed
        // iterator, an opaque value — has no wasm lowering, and it is REFUSED:
        // the no-op it used to be ran the body zero times at exit 0, which is
        // how `for (try items(n))` summed nothing and printed `6` for `9`.
        return self.refuseUnlessTemplate(lp.iter.*.getLoc(), "the wasm backend walks an array or a range; nothing shows this iterable is one", .{});
    }

    /// `#[@generator] loop { … }` (decision 105) — eager on wasm: the body
    /// runs as `loop { … }` does inside a block of its own, each `yield v`
    /// appends to a fresh array, and the expression is the array:
    ///
    ///     (block $__gen<n> (block $__break (loop $__continue …)))  local.get $__yield<n>
    ///
    /// `break <v>` appends and branches to `$__gen<n>` from any loop depth; a
    /// bare `break` leaves the loop, which falls out of the block too. A
    /// captured `var` is this function's local, so the loop's reassignments
    /// are read after it.
    fn lowerGeneratorLoop(self: *Emitter, lp: anytype) anyerror!void {
        const ra = self.reg_arena.allocator();
        const n = self.loop_seq;
        self.loop_seq += 1;
        const tgt = try std.fmt.allocPrint(ra, "__yield{d}", .{n});
        const label = try std.fmt.allocPrint(ra, "__gen{d}", .{n});
        try self.declareLocal(tgt, "i32");
        try self.emit(zero);
        try self.emit(self.builder().helper(.arr_new));
        try self.emit(.{ .local_set = tgt });
        const saved_target = self.yield_target;
        const saved_end = self.gen_end;
        self.yield_target = tgt;
        self.gen_end = label;
        var c: Capture = .{};
        self.open(&c);
        {
            defer {
                self.yield_target = saved_target;
                self.gen_end = saved_end;
            }
            try self.lowerConditionLoop(lp, null);
            try self.emit(.drop);
        }
        const seq = self.seal(&c, .none);
        try self.emit(.{ .block = .{ .kind = .block, .label = label, .body = seq } });
        try self.emit(.{ .local_get = tgt });
    }

    /// `@block { … }` whose body holds a `return` of its own (decision 2): the
    /// body is inlined in a wasm block, and each `return` stores its value in
    /// the block's local and branches out (`emitBlockReturn`) — a `return`
    /// opcode would leave the ENCLOSING function. The value is the local:
    ///
    ///     (block $__blkend<n> Body…)  [local.get $__blk<n>]
    ///
    /// A body that runs off its end leaves the local at its zero (a statement
    /// block's value; the checker refuses a valueless tail in value position,
    /// `block-tail-value`).
    fn lowerBlockWithReturn(self: *Emitter, body: []const ast.Stmt, keep_value: bool) anyerror!Tail {
        const ra = self.reg_arena.allocator();
        const n = self.loop_seq;
        self.loop_seq += 1;
        const ty = self.blockReturnType(body);
        const local = try std.fmt.allocPrint(ra, "__blk{d}", .{n});
        const label = try std.fmt.allocPrint(ra, "__blkend{d}", .{n});
        try self.declareLocal(local, ty);
        const saved = self.block_ret;
        self.block_ret = .{ .local = local, .label = label, .ty = ty };
        var c: Capture = .{};
        self.open(&c);
        {
            defer self.block_ret = saved;
            _ = try self.emitBody(body, false);
        }
        const seq = self.seal(&c, .none);
        try self.emit(.{ .block = .{ .kind = .block, .label = label, .body = seq } });
        if (!keep_value) return .none;
        try self.emit(.{ .local_get = local });
        return .value;
    }

    /// A `return` of an `@block`'s body: its value (zero for a bare one) into
    /// the block's local, then out of the block.
    fn emitBlockReturn(self: *Emitter, br: BlockRet, value: ?ast.Expr) anyerror!void {
        if (value) |v| try self.lowerCoerced(v, br.ty) else try self.emit(constOf(br.ty, "0"));
        try self.emit(.{ .local_set = br.local });
        try self.emit(.{ .br = br.label });
    }

    /// The wasm type an `@block`'s `return`s carry: their values' types met
    /// (`unifyNum`), `i32` when none carries one.
    fn blockReturnType(self: *Emitter, body: []const ast.Stmt) []const u8 {
        var ty: ?[]const u8 = null;
        self.blockReturnTypeIn(body, &ty);
        return ty orelse "i32";
    }

    fn blockReturnTypeIn(self: *Emitter, body: []const ast.Stmt, ty: *?[]const u8) void {
        for (body) |st| self.blockReturnTypeOf(st.expr, ty);
    }

    /// The borders of `ast.exprReturns`: a closure and a nested `@block` hold
    /// `return`s of their own, a braced `case` arm does not.
    fn blockReturnTypeOf(self: *Emitter, e: ast.Expr, ty: *?[]const u8) void {
        switch (e) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |v| {
                    const t = self.wasmTypeOf(v.*);
                    ty.* = if (ty.*) |prev| self.unifyNum(prev, t) else t;
                },
                else => {},
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| {
                    self.blockReturnTypeIn(i.then_, ty);
                    if (i.else_) |els| self.blockReturnTypeIn(els, ty);
                },
                .tryCatch => {},
            },
            .loop => |lp| if (lp.generator == null) self.blockReturnTypeIn(lp.body, ty),
            .collection => |col| switch (col.kind) {
                .case => |c| for (c.arms) |arm| {
                    if (arm.body == .function and arm.body.function.kind.syntax == .lambda)
                        self.blockReturnTypeIn(arm.body.function.kind.body, ty)
                    else
                        self.blockReturnTypeOf(arm.body, ty);
                },
                else => {},
            },
            else => {},
        }
    }

    /// `break <v>` in a generator scope: append `v`, then end the scope —
    /// branch out of the annotated loop's block, or, in a generator fn,
    /// return what the body collected.
    fn emitGenBreak(self: *Emitter, v: ast.Expr) anyerror!void {
        try self.emitYield(v);
        try self.emitGenEnd();
    }

    /// End the generator scope without emitting: branch out of the annotated
    /// loop's block, or, in a generator fn, return what the body collected —
    /// a bare `break` at the body's own level (decision 103), and the tail
    /// of `break <v>`.
    fn emitGenEnd(self: *Emitter) anyerror!void {
        if (self.gen_end) |label| {
            try self.emit(.{ .br = label });
            return;
        }
        try self.emitC(.{ .local_get = self.yield_target.? }, "everything the body yielded");
        try self.emitConvert("i32", self.cur_result);
        try self.emit(.@"return");
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
    /// lambdas) — what makes an `#[@resultGenerator]` body an accumulator.
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
    /// accumulator. A float is appended as its cell (`emitToFloatSlot`).
    fn emitYield(self: *Emitter, v: ast.Expr) anyerror!void {
        const tgt = self.yield_target.?;
        try self.emit(.{ .local_get = tgt });
        try self.lowerSlotWord(v);
        try self.emit(self.builder().helper(.arr_push));
        try self.emit(.{ .local_set = tgt });
    }

    /// `x` names an `[len][e0][e1]…` blob: an array literal, or a name bound to
    /// one. Deliberately narrow — walking the layout of something else would
    /// read its first word as an element count and trap.
    fn isArrayExpr(self: *Emitter, e: ast.Expr) bool {
        if (self.genericResultOf(e)) |a| return self.isArrayExpr(a);
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.arr_locals.contains(self.resolveName(n)) or self.arr_globals.contains(self.resolveName(n)),
                // A record field (or tuple element) declared as an array, an
                // `Array<T>` or an eager `@Iterator<T>` / `@Stream<T>` holds
                // the `[len][e0]…` blob its initialiser built — a `stream loop`
                // stored in `Ticker(s: …)` included. `for await (t.s)` fell to
                // the unknown-iterable no-op and yielded nothing. An optional
                // field (`?T[]`) is not an array until it is unwrapped.
                .identAccess => self.elemTypeRefOf(e) != null,
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.isArrayExpr(inner.*),
                .arrayLit => true,
                else => false,
            },
            // only the annotated loop has a value, and it is an array
            .loop => |lp| lp.generator != null,
            // `try items(n)` over a `-> @Result<i32[], E>`: the payload is the
            // array. Unrecognised, `for (try items(n))` was the unknown-iterable
            // no-op and a `val xs = try items(n)` printed its address.
            .jump => if (self.tryPayloadTypeRef(e)) |t| arrayElemOfTypeRef(t) != null else false,
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (self.primKindAt(cc, c.loc)) |k| break :blk self.primRes(k, cc) == .arr;
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

    /// `for (xs) { item -> … }` over the `[len][e0][e1]…` layout: a counted
    /// walk binding each element to the loop parameter. A statement (decision
    /// 105): it leaves 0, or the generator's array when `result` names one.
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

        const scope_mark = self.scopeMark();
        defer self.scopeRestore(scope_mark);
        const elem0 = if (lp.params.len > 0) lp.params[0] else "__it";
        const elem_kind = self.elemKindOf(lp.iter.*);
        // A float element is its slot's cell: loading the slot as an i32 read
        // the float as an integer (`[2.0, 4.0, 9.0]` averaged to `1082480000`).
        const elem_ty = if (elem_kind == .f64) "f64" else "i32";
        const elem = try self.bindTargetAs(elem0, elem_ty);
        try self.declareLocal(elem, elem_ty);
        if (elem_kind == .str) try self.str_locals.put(elem, {});
        if (try self.elemIsBool(lp.iter.*)) try self.bool_locals.put(elem, {});
        if (self.elemTypeRefOf(lp.iter.*)) |et| try self.noteTypedBinder(elem, et);
        // An element that is itself a tuple or an array prints — and is read
        // — by its shape: `for ([#(1.1, 2)]) { t -> t.0 }` read the float's
        // cell as an integer word (`288`).
        try self.noteElemShape(elem, lp.iter.*);
        // `for (es) { e -> … }` binds one ELEMENT: when the elements are
        // records, `e.key` needs the record type or it reads a slot by the
        // unique-field guess and prints the field's ADDRESS (`284` for
        // `"abc"`, exit 0).
        if (self.elemRecordOf(lp.iter.*)) |r| try self.local_types.put(elem, r);

        try self.lowerCoerced(lp.iter.*, "i32");
        try self.emit(.{ .local_set = base });
        self.installShadow(elem0, elem);
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
        if (elem_kind == .f64) try self.emitAt(8, .{ .load = .{ .ty = .f64 } });
        try self.emitAt(8, .{ .local_set = elem });
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

    /// One iteration's statements. A body that `continue`s is wrapped in
    /// `(block $__next …)` so the jump lands on the step; `loop_depth` lets
    /// `break`/`continue` branch at all.
    fn emitIterationBody(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        const scope_mark = self.scopeMark();
        defer self.scopeRestore(scope_mark);
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

    // ── self-recursion in tail position (00 · 05-wasm step 9) ────────────────
    //
    // wasm has no tail calls without the tail-call proposal, and wasmtime's
    // default does not enable it: `fn count(n, acc) { … return count(n - 1,
    // acc + 1); }` answered `count(10000, 0)` and trapped `call stack
    // exhausted` at `count(100000, 0)`, where the other three backends answer.
    // A call to the function being emitted, in `return` position and with one
    // argument per parameter, is not a call: every argument is evaluated onto
    // the stack, the parameters are re-bound from it in reverse, and `br
    // $__tail` restarts the body, which `emitFn` has wrapped in `(loop $__tail
    // (result …) …)` — one frame for any depth. Only the `return f(…)` spelling
    // is a tail call here; an implicit tail (`if (…) { acc } else { count(…) }`)
    // still lowers to `call`.

    const tail_label = "__tail";

    const TailSelf = struct {
        name: []const u8,
        /// The parameter symbols, their wasm types and their declared types,
        /// in declaration order — what a tail call re-binds.
        syms: []const []const u8,
        types: []const []const u8,
        typerefs: []const ?ast.TypeRef,
    };

    /// Arm `tail_self` for `f` when its body returns a call to itself.
    fn noteSelfTailCalls(self: *Emitter, f: ast.FnDecl) !void {
        for (f.params) |p| if (std.mem.eql(u8, p.name, "self") or p.destruct != null) return;
        if (!bodyHasSelfTailCall(f.body, f.name, f.params.len)) return;
        const ra = self.reg_arena.allocator();
        const syms = try ra.alloc([]const u8, f.params.len);
        const types = try ra.alloc([]const u8, f.params.len);
        const typerefs = try ra.alloc(?ast.TypeRef, f.params.len);
        for (f.params, 0..) |p, i| {
            syms[i] = try self.paramSymbol(p, i);
            types[i] = watType(p.typeRef);
            typerefs[i] = p.typeRef;
        }
        self.tail_self = .{ .name = f.name, .syms = syms, .types = types, .typerefs = typerefs };
    }

    /// `return f(a, …)` inside `fn f`: the argument list is `f`'s own.
    fn isSelfTailCall(val: ast.Expr, name: []const u8, arity: usize) bool {
        return switch (val) {
            .call => |c| switch (c.kind) {
                .call => |cc| cc.receiver == null and !cc.is_builtin and cc.trailing.len == 0 and
                    cc.args.len == arity and std.mem.eql(u8, cc.callee, name),
                else => false,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| isSelfTailCall(inner.*, name, arity),
                else => false,
            },
            else => false,
        };
    }

    /// A `return f(…)` reachable from `body` without crossing a lambda — the
    /// arms of an `if` and the body of a loop are looked into, a closure is a
    /// function of its own.
    fn bodyHasSelfTailCall(body: []const ast.Stmt, name: []const u8, arity: usize) bool {
        for (body) |st| switch (st.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |v| if (isSelfTailCall(v.*, name, arity)) return true,
                else => {},
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| {
                    if (bodyHasSelfTailCall(i.then_, name, arity)) return true;
                    if (i.else_) |els| if (bodyHasSelfTailCall(els, name, arity)) return true;
                },
                else => {},
            },
            .loop => |lp| if (bodyHasSelfTailCall(lp.body, name, arity)) return true,
            else => {},
        };
        return false;
    }

    /// Lower `return f(args)` as the re-binding and the branch when `f` is the
    /// function being emitted; false leaves the `return` to its ordinary path.
    fn lowerSelfTailCall(self: *Emitter, val: ast.Expr) anyerror!bool {
        const ts = self.tail_self orelse return false;
        if (!isSelfTailCall(val, ts.name, ts.syms.len)) return false;
        const call_expr = switch (val) {
            .collection => |col| switch (col.kind) {
                .grouped => |inner| inner.*,
                else => val,
            },
            else => val,
        };
        const cc = switch (call_expr) {
            .call => |c| switch (c.kind) {
                .call => |cc| cc,
                else => unreachable,
            },
            else => unreachable,
        };
        // Every argument is evaluated before any parameter is re-bound, so
        // `count(n - 1, acc + n)` reads the old `n` in both.
        for (cc.args, 0..) |arg, i| {
            if (self.boxesInto(ts.typerefs[i], arg.value.*))
                try self.lowerBoxedInto(ts.typerefs[i], arg.value.*)
            else
                try self.lowerCoerced(arg.value.*, ts.types[i]);
        }
        var i = cc.args.len;
        while (i > 0) {
            i -= 1;
            try self.emit(.{ .local_set = ts.syms[i] });
        }
        try self.emitC(.{ .br = tail_label }, "tail call");
        self.tail_self_used = true;
        return true;
    }

    /// `(loop $__tail (result …) <body>)` — the loop head a tail call branches to.
    fn wrapTailLoop(self: *Emitter, body: Seq) !Seq {
        var c: Capture = .{};
        self.open(&c);
        try self.emit(.{ .block = .{
            .kind = .loop,
            .label = tail_label,
            .result = if (self.fn_has_result) vt(self.cur_result) else null,
            .body = body,
        } });
        return self.seal(&c, body.stack);
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

    /// `while (condition) { … }` / `loop { … }` (decision 105): test the
    /// condition at the top of every iteration, leave when it is false.
    fn lowerConditionLoop(self: *Emitter, lp: anytype, result: ?[]const u8) anyerror!void {
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
        const scope_mark = self.scopeMark();
        defer self.scopeRestore(scope_mark);
        const param0 = if (params.len > 0) params[0] else "__i";
        const param = try self.bindTarget(param0);
        try self.declareLocal(param, "i32");

        try self.lowerCoerced(r.start.*, "i32");
        try self.emit(.{ .local_set = param });
        self.installShadow(param0, param);

        var loop_c: Capture = .{};
        self.open(&loop_c);
        if (r.end) |end| {
            // `a..b` stops at `b`; `a...b` (decision 105) runs it too.
            try self.emitAt(8, .{ .local_get = param });
            try self.lowerExpr(end.*);
            try self.emitAt(8, opOf("i32", if (r.inclusive) "gt_s" else "ge_s"));
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
        if (optOperatorParts(e)) |op| if (op.bang) if (self.optInfoOf(op.cond.*)) |oi| if (oi.cell != .none) return oi.cell.ty();
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| if (isNumericLiteral(n)) numLitType(n) else "i32",
                else => "i32",
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| blk: {
                    // A narrowed `?f64` is the `f64` its cell holds.
                    if (self.narrowed_opts.get(self.resolveName(n))) |o| if (o.cell != .none) break :blk o.cell.ty();
                    break :blk self.locals.get(self.resolveName(n)) orelse self.global_types.get(self.resolveName(n)) orelse "i32";
                },
                // A named record's float field reads as the `f64` its box holds.
                .identAccess => |ia| blk: {
                    if (ia.optional) break :blk "i32";
                    // A float / 64-bit tuple element reads as the value its
                    // cell holds.
                    if (tupleIndex(ia.member) != null) {
                        const el = (self.tupleElemShapeOf(e) catch null) orelse break :blk "i32";
                        break :blk shapeCell(el).ty();
                    }
                    const rty = self.recordTypeOfExpr(ia.receiver.*) orelse break :blk "i32";
                    if (self.fieldOffsetIn(rty, ia.member) == null) break :blk "i32";
                    break :blk fieldCellOf(self.fieldTypeIn(rty, ia.member) orelse "").ty();
                },
                else => "i32",
            },
            .unaryOp => |un| switch (un.op) {
                .neg => if (negatedMinimum(un.expr.*)) |m| m.ty else self.wasmTypeOf(un.expr.*),
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
                .if_ => |i| if (ifIsStatementForm(i)) "i32" else self.ifValueType(i),
                .tryCatch => self.cur_result,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    // `xs[i]` over a float array reads the `f64` its slot's cell holds
                    if (self.indexArgs(cc)) |ix|
                        break :blk if (!ix.is_slice and self.isArrayExpr(ix.recv) and
                            self.elemKindOf(ix.recv) == .f64) "f64" else "i32";
                    if (cc.is_builtin) {
                        // An `@block` whose body returns answers what its `return`s carry.
                        if (std.mem.eql(u8, cc.callee, "block") and cc.trailing.len > 0 and blockBodyReturns(cc.trailing[0].body))
                            break :blk self.blockReturnType(cc.trailing[0].body);
                        // `o.unwrapOr(d)` over a `?f64` answers its `f64`.
                        if (std.mem.eql(u8, cc.callee, "__bp_option_unwrapOr") and cc.args.len > 0) if (self.optInfoOf(cc.args[0].value.*)) |oi| if (oi.cell != .none) break :blk oi.cell.ty();
                        break :blk "i32";
                    }
                    if (self.primKindAt(cc, c.loc)) |k| {
                        // `xs.fold(init, f)` answers what its accumulator holds.
                        if (k == .array and std.mem.eql(u8, cc.callee, "fold") and cc.args.len > 0) break :blk self.wasmTypeOf(cc.args[0].value.*);
                        break :blk if (self.primRes(k, cc) == .f64) "f64" else "i32";
                    }
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

    /// Whether turning a `from` value into a `to` one may change the number:
    /// a float into an integer, an `i64` into an `i32`.
    fn lossyConversion(from: []const u8, to: []const u8) bool {
        if (from[0] == 'f' and to[0] == 'i') return true;
        return std.mem.eql(u8, from, "i64") and std.mem.eql(u8, to, "i32");
    }

    /// Emit the conversion opcode that turns a value of type `from` into `to`.
    fn emitConvert(self: *Emitter, from: []const u8, to: []const u8) anyerror!void {
        if (std.mem.eql(u8, from, to)) return;
        // A float or an `i64` asked for as a narrower word: `lowerCoerced`
        // refuses it at the expression; a conversion with none (a body's
        // tail, a function value's answer) is refused at its statement.
        if (lossyConversion(from, to))
            return self.refuse(self.stmt_loc, "the wasm backend would narrow an `{s}` value to an `{s}` slot it does not fit", .{ from, to });
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
        // A float or an `i64` asked for as a narrower word would be truncated
        // or wrapped (`i32.trunc_f64_s`, `i32.wrap_i64`) — a different number
        // at exit 0. The language converts by a call it names (`toInt`), never
        // by flowing a value into a slot; where this backend has no wider slot
        // for the value, it refuses.
        if (lossyConversion(from, want))
            return self.refuse(e.getLoc(), "the wasm backend would narrow this `{s}` value to an `{s}` slot it does not fit", .{ if (from[0] == 'f') "f64" else from, want });
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
    /// the `f64` the slot's cell holds, `s` through `$__str_eq` — a string
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
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emitFromFloatSlot();
                    try self.emit(.{ .local_get = b });
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emitFromFloatSlot();
                    try self.emit(.{ .call = self.floatEqSym() });
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
                // A 64-bit element: the values its two cells hold.
                'l', 'u' => {
                    try self.emit(.{ .local_get = a });
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emitFromCell(.i64);
                    try self.emit(.{ .local_get = b });
                    try self.emit(.{ .load = .{ .offset = @intCast(off) } });
                    try self.emitFromCell(.i64);
                    try self.emit(opOf("i64", "eq"));
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

    // ── structural equality (decision 210) ───────────────────────────────────

    /// A primitive whose `==` keeps the instruction it always had: a scalar,
    /// a bool, a string (`$__str_eq`), an all-unit enum (its ordinal), and an
    /// optional of one (`lowerBinOp`'s own optional and null rows).
    fn eqIsPrim(self: *Emitter, t: ast.TypeRef) bool {
        return switch (t) {
            .named => |n| primKindOfName(n) != null or isScalarName(n) or isFloatTypeName(n) or
                std.mem.eql(u8, n, "bool") or std.mem.eql(u8, n, "string") or std.mem.eql(u8, n, "unknown") or
                self.isAllUnitEnum(n),
            .optional => |inner| self.eqIsPrim(inner.*),
            else => false,
        };
    }

    fn eqResolve(self: *Emitter, t: ast.TypeRef) ast.TypeRef {
        if (t.isSelf()) if (self.self_type) |st| return .{ .named = st };
        return t;
    }

    fn eqArrayElem(t: ast.TypeRef) ?ast.TypeRef {
        return switch (t) {
            .array => |inner| inner.*,
            .generic => |g| if (g.args.len == 1 and std.mem.eql(u8, g.name, "Array")) g.args[0] else null,
            else => null,
        };
    }

    /// The record or payload enum `t` names in this program.
    fn eqNominal(self: *Emitter, t: ast.TypeRef) ?[]const u8 {
        const n = switch (t) {
            .named => |n| n,
            .generic => |g| if (g.is_builtin) return null else g.name,
            else => return null,
        };
        if (self.records.contains(n)) return n;
        if (self.enums.get(n)) |vs| if (enumHasPayload(vs)) return n;
        return null;
    }

    /// A composite this backend generates an equality for.
    fn eqComposite(self: *Emitter, t0: ast.TypeRef) bool {
        const t = self.eqResolve(t0);
        if (self.eqIsPrim(t)) return false;
        if (eqArrayElem(t)) |_| return true;
        return switch (t) {
            .tuple_, .labeledTuple => true,
            .optional => |inner| self.eqComposite(inner.*),
            else => self.eqNominal(t) != null,
        };
    }

    /// The type a print shape spells (`i`, `f`, `b`, `s`, `[X`, `(XY…)`), or
    /// null for a shape that names no one type (`T`, an enum's names).
    fn eqTypeOfShape(self: *Emitter, sh: []const u8) anyerror!?ast.TypeRef {
        if (sh.len == 0) return null;
        const ar = self.arena();
        switch (sh[0]) {
            'i' => return .{ .named = "i32" },
            'f' => return .{ .named = "f64" },
            'b' => return .{ .named = "bool" },
            's' => return .{ .named = "string" },
            'l' => return .{ .named = "i64" },
            'u' => return .{ .named = "u64" },
            '[' => {
                const inner = (try self.eqTypeOfShape(sh[1..])) orelse return null;
                const p = try ar.create(ast.TypeRef);
                p.* = inner;
                return .{ .array = p };
            },
            '(' => {
                var elems: std.ArrayListUnmanaged(ast.TypeRef) = .empty;
                var i: usize = 1;
                while (i < sh.len and sh[i] != ')') {
                    const n = shapeSpan(sh[i..]);
                    if (n == 0) return null;
                    try elems.append(ar, (try self.eqTypeOfShape(sh[i .. i + n])) orelse return null);
                    i += n;
                }
                return .{ .tuple_ = elems.items };
            },
            else => return null,
        }
    }

    /// The payload enum `e` is a value of: a variant constructor, a unit
    /// variant read off its enum, a call declared to answer one.
    fn eqEnumOf(self: *Emitter, e: ast.Expr) ?[]const u8 {
        switch (e) {
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (self.callKind(cc) == .enum_ctor) {
                        if (receiverName(cc)) |rcv| if (self.enums.contains(rcv)) return rcv;
                        return self.enumOfVariant(cc.callee);
                    }
                    return self.enumReturnedBy(cc);
                },
                else => {},
            },
            .identifier => |id| switch (id.kind) {
                .identAccess => |ia| if (ia.receiver.* == .identifier and ia.receiver.identifier.kind == .ident) {
                    const en = ia.receiver.identifier.kind.ident;
                    if (self.enums.get(en)) |vs| for (vs) |v| {
                        if (std.mem.eql(u8, v.name, ia.member)) return en;
                    };
                },
                else => {},
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.eqEnumOf(inner.*),
                else => {},
            },
            else => {},
        }
        return null;
    }

    /// The static type of `e` for `==`, read the way the rest of this backend
    /// reads it (`recordTypeOfExpr`, `typeRefOf`, the print shape). A
    /// primitive is answered too, because a tuple's or an array's element
    /// type is built from it. Null when nothing here says.
    fn eqTypeOf(self: *Emitter, e: ast.Expr) anyerror!?ast.TypeRef {
        if (self.genericResultOf(e)) |a| return self.eqTypeOf(a);
        const ar = self.arena();
        if (e == .identifier and e.identifier.kind == .ident) {
            if (self.eq_local_types.get(self.resolveName(e.identifier.kind.ident))) |t| return t;
        }
        if (self.recordTypeOfExpr(e)) |r| return .{ .named = r };
        if (self.eqEnumOf(e)) |en| return .{ .named = en };
        if (self.unitEnumOf(e)) |en| return .{ .named = en };
        if (self.typeRefOf(e)) |t0| {
            const t = self.eqResolve(t0);
            if (t.unionMembers() == null and (self.eqComposite(t) or self.eqIsPrim(t))) return t;
        }
        switch (e) {
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.eqTypeOf(inner.*),
                .tupleLit => |tl| {
                    const elems = try ar.alloc(ast.TypeRef, tl.elems.len);
                    for (tl.elems, elems) |el, *out| out.* = (try self.eqTypeOf(el)) orelse return null;
                    return .{ .tuple_ = elems };
                },
                .arrayLit => |al| if (al.elems.len > 0 and al.spread == null and al.spreadExpr == null) {
                    const p = try ar.create(ast.TypeRef);
                    p.* = (try self.eqTypeOf(al.elems[0])) orelse return null;
                    return .{ .array = p };
                },
                else => {},
            },
            else => {},
        }
        if (try self.printShapeOf(e)) |sh| if (try self.eqTypeOfShape(sh)) |t| return t;
        if (self.isArrayExpr(e)) {
            const p = try ar.create(ast.TypeRef);
            if (self.elemRecordOf(e)) |r| {
                p.* = .{ .named = r };
            } else p.* = .{ .named = switch (self.elemKindOf(e)) {
                .i32 => "i32",
                .f64 => "f64",
                .str => "string",
            } };
            return .{ .array = p };
        }
        if (self.isStringExpr(e)) return .{ .named = "string" };
        if (self.isBoolExpr(e)) return .{ .named = "bool" };
        if (self.wasmTypeOf(e)[0] == 'f') return .{ .named = "f64" };
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => .{ .named = "i32" },
                else => null,
            },
            .binaryOp => .{ .named = "i32" },
            .unaryOp => .{ .named = "i32" },
            else => null,
        };
    }

    /// The suffix of a per-type equality's symbol — prefix notation with each
    /// constructor's arity, so two types never share one: `Person`,
    /// `Array_Person`, `Tuple2_i32_string`, `Opt_Team`.
    fn eqMangle(self: *Emitter, t0: ast.TypeRef, out: *std.ArrayListUnmanaged(u8)) anyerror!void {
        const ar = self.reg_arena.allocator();
        const t = self.eqResolve(t0);
        if (eqArrayElem(t)) |elem| {
            try out.appendSlice(ar, "Array_");
            return self.eqMangle(elem, out);
        }
        switch (t) {
            .named => |n| try out.appendSlice(ar, n),
            .generic => |g| {
                try out.appendSlice(ar, g.name);
                for (g.args) |a| {
                    try out.append(ar, '_');
                    try self.eqMangle(a, out);
                }
            },
            .optional => |inner| {
                try out.appendSlice(ar, "Opt_");
                try self.eqMangle(inner.*, out);
            },
            .tuple_, .labeledTuple => {
                const elems = t.tupleElems().?;
                try out.print(ar, "Tuple{d}", .{elems.len});
                for (elems) |el| {
                    try out.append(ar, '_');
                    try self.eqMangle(el, out);
                }
            },
            else => try out.appendSlice(ar, "Any"),
        }
    }

    fn eqKey(self: *Emitter, t: ast.TypeRef) ![]const u8 {
        var out: std.ArrayListUnmanaged(u8) = .empty;
        try self.eqMangle(t, &out);
        return out.items;
    }

    /// `$__eq_<T>`, requested for emission once the module is lowered.
    fn eqFnFor(self: *Emitter, t0: ast.TypeRef) ![]const u8 {
        const t = self.eqResolve(t0);
        const sym = try std.fmt.allocPrint(self.reg_arena.allocator(), "__eq_{s}", .{try self.eqKey(t)});
        if (!self.eq_requests.contains(sym)) try self.eq_requests.put(self.reg_arena.allocator(), sym, t);
        return sym;
    }

    /// Decision 210 — `==` / `!=` over two composites of one static type
    /// calls that type's `$__eq_<T>`; two different nominal types are never
    /// equal (both operands still run). False when neither side is a
    /// composite this backend generates an equality for: the caller's rows
    /// below answer it as before.
    fn lowerStructuralEq(self: *Emitter, negate: bool, lhs: ast.Expr, rhs: ast.Expr) anyerror!bool {
        const lt = try self.eqTypeOf(lhs);
        const rt = try self.eqTypeOf(rhs);
        const l_comp = if (lt) |t| self.eqComposite(t) else false;
        const r_comp = if (rt) |t| self.eqComposite(t) else false;
        if (!l_comp and !r_comp) return false;
        // A primitive against a composite: two types, never equal.
        const t: ast.TypeRef = blk: {
            if (l_comp and r_comp) {
                if (std.mem.eql(u8, try self.eqKey(lt.?), try self.eqKey(rt.?))) break :blk lt.?;
                // A tuple literal against a tuple of the same arity: the
                // checker typed the literal by the other operand, so its
                // integers take the other side's widths (`#(5, true)` against
                // a `#(u64, bool)`). Compared by their own types the two were
                // never equal — `false` at exit 0.
                if (try self.lowerTupleEqAgainst(negate, lhs, lt.?, rhs, rt.?)) return true;
            } else if ((l_comp and rt == null) or (r_comp and lt == null)) {
                // The other side's type is not recovered here; the checker
                // accepted the comparison, so it is the recovered side's.
                break :blk if (l_comp) lt.? else rt.?;
            }
            try self.lowerCoerced(lhs, self.wasmTypeOf(lhs));
            try self.emit(.drop);
            try self.lowerCoerced(rhs, self.wasmTypeOf(rhs));
            try self.emit(.drop);
            try self.emitC(if (negate) one else zero, "two different types are never equal (decision 210)");
            return true;
        };
        const sym = try self.eqFnFor(t);
        try self.lowerCoerced(lhs, "i32");
        try self.lowerCoerced(rhs, "i32");
        try self.emit(.{ .call = sym });
        if (negate) try self.emit(opOf("i32", "eqz"));
        return true;
    }

    /// `#(…) == t` / `t == #(…)` where `t`'s tuple type has the literal's
    /// arity: the literal is built with `t`'s element types and both sides
    /// compared by `t`'s `$__eq_<T>`. False when neither side is such a pair.
    fn lowerTupleEqAgainst(self: *Emitter, negate: bool, lhs: ast.Expr, lt: ast.TypeRef, rhs: ast.Expr, rt: ast.TypeRef) anyerror!bool {
        const lit_left = tupleLitElems(lhs) != null;
        const lit = tupleLitElems(if (lit_left) lhs else rhs) orelse return false;
        const t = if (lit_left) rt else lt;
        const elems = t.tupleElems() orelse return false;
        if (elems.len != lit.len or tupleLitElems(if (lit_left) rhs else lhs) != null) return false;
        const sym = try self.eqFnFor(t);
        if (lit_left) {
            try self.lowerTupleLitAs(.{ .elems = lit }, elems);
            try self.lowerCoerced(rhs, "i32");
        } else {
            try self.lowerCoerced(lhs, "i32");
            try self.lowerTupleLitAs(.{ .elems = lit }, elems);
        }
        try self.emit(.{ .call = sym });
        if (negate) try self.emit(opOf("i32", "eqz"));
        return true;
    }

    /// The elements of a tuple literal, through parentheses.
    fn tupleLitElems(e: ast.Expr) ?[]ast.Expr {
        return switch (e) {
            .collection => |col| switch (col.kind) {
                .tupleLit => |tl| tl.elems,
                .grouped => |inner| tupleLitElems(inner.*),
                else => null,
            },
            else => null,
        };
    }

    /// Where a compared value is read from: `base` (+ `4 + idx * 4` for an
    /// array element) at `off`.
    const EqAddr = struct { base: []const u8, off: u32 = 0, idx: ?[]const u8 = null };

    /// How the address of a compared value reaches a float or an `i64`: a
    /// record `field` holds the address of either's cell; a tuple element, a
    /// variant payload and an array element are a `word` slot holding a
    /// float's cell (an `i64` there is only ever an `i32` word; a tuple's
    /// slot holds its cell and is compared as a `field`); an optional's box
    /// IS the `cell`.
    const EqSlot = enum { field, word, cell };

    fn eqPushAddr(self: *Emitter, a: EqAddr) !void {
        try self.emit(.{ .local_get = a.base });
        if (a.idx) |i| {
            try self.emit(try self.constInt(4));
            try self.emit(opOf("i32", "add"));
            try self.emit(.{ .local_get = i });
            try self.emit(try self.constInt(4));
            try self.emit(opOf("i32", "mul"));
            try self.emit(opOf("i32", "add"));
        }
    }

    /// Leave `1` / `0` for "the values at `a` and `b`, of type `t`, are
    /// equal" — a primitive by its own instruction, a composite by its
    /// `$__eq_<T>`.
    fn emitValueEq(self: *Emitter, t0: ast.TypeRef, slot: EqSlot, a: EqAddr, b: EqAddr) anyerror!void {
        const t = self.eqResolve(t0);
        const n: []const u8 = switch (t) {
            .named => |x| x,
            else => "",
        };
        if (std.mem.eql(u8, n, "string")) {
            try self.eqPushAddr(a);
            try self.emit(.{ .load = .{ .offset = a.off } });
            try self.eqPushAddr(b);
            try self.emit(.{ .load = .{ .offset = b.off } });
            try self.emit(self.builder().helper(.str_eq));
            return;
        }
        if (fieldCellOf(n) == .i64 and slot != .word) {
            for ([_]EqAddr{ a, b }) |x| {
                try self.eqPushAddr(x);
                if (slot == .field) {
                    try self.emit(.{ .load = .{ .offset = x.off } });
                    try self.emit(.{ .load = .{ .ty = .i64 } });
                } else try self.emit(.{ .load = .{ .ty = .i64, .offset = x.off } });
            }
            try self.emit(opOf("i64", "eq"));
            return;
        }
        if (isFloatTypeName(n)) {
            // The composite compare of a float is the bare float `==` —
            // decision 214's total order (`$__f64_eq`).
            for ([_]EqAddr{ a, b }) |x| {
                try self.eqPushAddr(x);
                switch (slot) {
                    .field, .word => {
                        try self.emit(.{ .load = .{ .offset = x.off } });
                        try self.emitFromFloatSlot();
                    },
                    .cell => try self.emit(.{ .load = .{ .ty = .f64, .offset = x.off } }),
                }
            }
            try self.emit(.{ .call = self.floatEqSym() });
            return;
        }
        if (self.eqComposite(t)) {
            const sym = try self.eqFnFor(t);
            try self.eqPushAddr(a);
            try self.emit(.{ .load = .{ .offset = a.off } });
            try self.eqPushAddr(b);
            try self.emit(.{ .load = .{ .offset = b.off } });
            try self.emit(.{ .call = sym });
            return;
        }
        if (t == .optional) {
            // A boxed scalar: equal when both are absent, or both present
            // with equal payload words.
            const sym = try self.eqFnFor(t);
            try self.eqPushAddr(a);
            try self.emit(.{ .load = .{ .offset = a.off } });
            try self.eqPushAddr(b);
            try self.emit(.{ .load = .{ .offset = b.off } });
            try self.emit(.{ .call = sym });
            return;
        }
        // An integer, a bool, an all-unit enum's ordinal — and a field this
        // backend has no type for (a type parameter's), compared as the word.
        try self.eqPushAddr(a);
        try self.emit(.{ .load = .{ .offset = a.off } });
        try self.eqPushAddr(b);
        try self.emit(.{ .load = .{ .offset = b.off } });
        try self.emit(opOf("i32", "eq"));
    }

    /// Decision 214 — the float `==` this module calls, marked for emission
    /// (`floatEqFunc`).
    fn floatEqSym(self: *Emitter) []const u8 {
        self.float_eq_used = true;
        return "__f64_eq";
    }

    /// `$__f64_eq(a, b)`: `==` over floats as a total order (decision 214,
    /// Java's `Double.compare` and Kotlin's data class) — both NaN (any
    /// payload: NaN is canonicalised by `x != x`), or the same bit pattern, so
    /// `0.0` and `-0.0` differ. Every float this backend holds is an `f64`.
    fn floatEqFunc(self: *Emitter) !wat.Func {
        var c: Capture = .{};
        self.open(&c);
        for ([_][]const u8{ "a", "b" }) |x| {
            try self.emit(.{ .local_get = x });
            try self.emit(.{ .local_get = x });
            try self.emit(opOf("f64", "ne"));
        }
        try self.emitC(opOf("i32", "and"), "both NaN");
        for ([_][]const u8{ "a", "b" }) |x| {
            try self.emit(.{ .local_get = x });
            try self.emit(.{ .convert = "i64.reinterpret_f64" });
        }
        try self.emitC(opOf("i64", "eq"), "the same bits");
        try self.emit(opOf("i32", "or"));
        const body = self.seal(&c, .{ .value = .i32 });
        return try self.builder().func(.{
            .name = "__f64_eq",
            .params = &.{ wat.Builder.param("a", .f64), wat.Builder.param("b", .f64) },
            .result = .i32,
            .body = body,
        });
    }

    /// `(if (then i32.const <v> return))` over the condition on the stack.
    fn eqReturnIf(self: *Emitter, v: Instr) !void {
        var hit: Capture = .{};
        self.open(&hit);
        try self.emit(v);
        try self.emit(.@"return");
        const s = self.seal(&hit, .terminated);
        try self.emit(.{ .@"if" = .{ .then = .{ .seq = s, .layout = .inline_ } } });
    }

    /// One field test: the comparison, and `return 0` at the first difference.
    fn eqFieldStep(self: *Emitter, t: ast.TypeRef, slot: EqSlot, off: u32) !void {
        try self.emitValueEq(t, slot, .{ .base = "a", .off = off }, .{ .base = "b", .off = off });
        try self.emit(opOf("i32", "eqz"));
        try self.eqReturnIf(zero);
    }

    /// A record field's declared type, its owner's type parameters written
    /// with the arguments `t` spells (`Pair<string>`), or a parameter itself
    /// when `t` spells none.
    fn eqFieldType(self: *Emitter, owner: ast.TypeRef, gps: []const ast.GenericParam, ft: ast.TypeRef) ast.TypeRef {
        _ = self;
        const args = switch (owner) {
            .generic => |g| g.args,
            else => return ft,
        };
        if (ft != .named) return ft;
        for (gps, 0..) |gp, i| if (std.mem.eql(u8, gp.name, ft.named) and i < args.len) return args[i];
        return ft;
    }

    /// `$__eq_<T>(a, b)`: `a == b` as pointers answers `1` at once; then the
    /// type's parts in order, `0` at the first difference, `1` past the last.
    fn eqFunc(self: *Emitter, sym: []const u8, t: ast.TypeRef) !wat.Func {
        // A field written `Self` is the type being compared.
        const prev_self = self.self_type;
        if (self.eqNominal(t)) |nm| self.self_type = nm;
        defer self.self_type = prev_self;
        var c: Capture = .{};
        self.open(&c);
        var locals: []const wat.Local = &.{};
        try self.emit(.{ .local_get = "a" });
        try self.emit(.{ .local_get = "b" });
        try self.emit(opOf("i32", "eq"));
        try self.eqReturnIf(one);
        if (eqArrayElem(t)) |elem| {
            // The same length, then each element by its own type.
            try self.emit(.{ .local_get = "a" });
            try self.emit(.{ .load = .{} });
            try self.emit(.{ .local_get = "b" });
            try self.emit(.{ .load = .{} });
            try self.emit(opOf("i32", "ne"));
            try self.eqReturnIf(zero);
            try self.emit(.{ .local_get = "a" });
            try self.emit(.{ .load = .{} });
            try self.emit(.{ .local_set = "n" });
            var body: Capture = .{};
            self.open(&body);
            try self.emit(.{ .local_get = "i" });
            try self.emit(.{ .local_get = "n" });
            try self.emit(opOf("i32", "ge_u"));
            try self.emit(.{ .br_if = "brk" });
            try self.emitValueEq(elem, .word, .{ .base = "a", .idx = "i" }, .{ .base = "b", .idx = "i" });
            try self.emit(opOf("i32", "eqz"));
            try self.eqReturnIf(zero);
            try self.emit(.{ .local_get = "i" });
            try self.emit(one);
            try self.emit(opOf("i32", "add"));
            try self.emit(.{ .local_set = "i" });
            try self.emit(.{ .br = "cont" });
            const loop_seq = self.seal(&body, .none);
            var outer: Capture = .{};
            self.open(&outer);
            try self.emit(.{ .block = .{ .kind = .loop, .label = "cont", .body = loop_seq } });
            const outer_seq = self.seal(&outer, .none);
            try self.emit(.{ .block = .{ .kind = .block, .label = "brk", .body = outer_seq } });
            try self.emit(one);
            locals = try self.arena().dupe(wat.Local, &.{ .{ .name = "n", .ty = .i32 }, .{ .name = "i", .ty = .i32 } });
        } else switch (t) {
            .optional => |inner| {
                // Absent on either side: equal only when both are (`a == b`
                // above answered two absences).
                try self.emit(.{ .local_get = "a" });
                try self.emit(opOf("i32", "eqz"));
                try self.emit(.{ .local_get = "b" });
                try self.emit(opOf("i32", "eqz"));
                try self.emit(opOf("i32", "or"));
                try self.eqReturnIf(zero);
                if (self.eqComposite(inner.*) or isNamedTypeRef(inner.*, "string")) {
                    // A pointer payload: the optional is the payload.
                    try self.emitValueEqDirect(inner.*);
                } else {
                    // A box: the payload at its address.
                    try self.eqFieldStep(inner.*, .cell, 0);
                    try self.emit(one);
                }
            },
            .tuple_, .labeledTuple => {
                // A tuple's slot holds a 64-bit element's cell, as a record
                // field does (`lowerTupleLit`).
                for (t.tupleElems().?, 0..) |el, i| try self.eqFieldStep(el, .field, @intCast(i * 4));
                try self.emit(one);
            },
            else => {
                const name = self.eqNominal(t).?;
                if (self.records.get(name)) |fields| {
                    const trefs = self.record_field_typerefs.get(name) orelse &.{};
                    const gps = self.record_generics.get(name) orelse &.{};
                    for (fields, 0..) |_, i| {
                        const ft: ast.TypeRef = if (i < trefs.len) self.eqFieldType(t, gps, trefs[i]) else .{ .named = "i32" };
                        try self.eqFieldStep(ft, .field, @intCast(i * 4));
                    }
                    try self.emit(one);
                } else {
                    // A payload enum: slot 0 is the ordinal; the variant's
                    // payload follows it, one 4-byte slot per field.
                    try self.emit(.{ .local_get = "a" });
                    try self.emit(.{ .load = .{} });
                    try self.emit(.{ .local_get = "b" });
                    try self.emit(.{ .load = .{} });
                    try self.emit(opOf("i32", "ne"));
                    try self.eqReturnIf(zero);
                    for (self.enums.get(name).?, 0..) |v, k| {
                        if (v.fields.len == 0) continue;
                        var arm: Capture = .{};
                        self.open(&arm);
                        for (v.fields, 0..) |f, i| try self.eqFieldStep(f.typeRef, .word, @intCast((i + 1) * 4));
                        const arm_seq = self.seal(&arm, .none);
                        try self.emit(.{ .local_get = "a" });
                        try self.emit(.{ .load = .{} });
                        try self.emit(try self.constInt(k));
                        try self.emit(opOf("i32", "eq"));
                        try self.emitC(.{ .@"if" = .{ .then = .{ .seq = arm_seq } } }, v.name);
                    }
                    try self.emit(one);
                }
            },
        }
        const body = self.seal(&c, .{ .value = .i32 });
        return try self.builder().func(.{
            .name = sym,
            .params = &.{ wat.Builder.param("a", .i32), wat.Builder.param("b", .i32) },
            .result = .i32,
            .locals = if (locals.len == 0) &.{} else try self.arena().dupe([]const wat.Local, &.{locals}),
            .body = body,
        });
    }

    /// The tail of an optional's equality over a pointer payload: `a` and `b`
    /// ARE the payloads, so the payload type's own compare answers.
    fn emitValueEqDirect(self: *Emitter, inner: ast.TypeRef) !void {
        try self.emit(.{ .local_get = "a" });
        try self.emit(.{ .local_get = "b" });
        if (isNamedTypeRef(inner, "string")) {
            try self.emit(self.builder().helper(.str_eq));
        } else try self.emit(.{ .call = try self.eqFnFor(inner) });
    }

    fn lowerBinOp(self: *Emitter, op: anytype, lhs: ast.Expr, rhs: ast.Expr, loc: ast.Loc) anyerror!void {
        const Op = @TypeOf(op);
        // `x == null` compares the carrier with 0, whatever `x` holds — a
        // string `==` would read the length word at address 0.
        if ((op == Op.eq or op == Op.ne) and (isNullLit(lhs) or isNullLit(rhs))) {
            try self.lowerCoerced(lhs, "i32");
            try self.lowerCoerced(rhs, "i32");
            try self.emit(opOf("i32", if (op == Op.eq) "eq" else "ne"));
            return;
        }
        // Decision 8 §2.3: `==` with an `unknown` operand compares by what
        // the values hold — numbers by value (`2.0 == 2`), strings by content.
        if ((op == Op.eq or op == Op.ne) and (self.isUnknownExpr(lhs) or self.isUnknownExpr(rhs))) {
            try self.lowerAsUnknown(lhs);
            try self.lowerAsUnknown(rhs);
            try self.emit(self.builder().helper(.unknown_eq));
            if (op == Op.ne) try self.emit(opOf("i32", "eqz"));
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
            const oi = (if (lopt != null and lopt.?.boxed) lopt else ropt).?;
            try self.emitUnboxPayload(oi, "optional payload");
            if (oi.cell == .f64) {
                // decision 214's total order, as for two floats
                try self.lowerCoerced(val_side, "f64");
                try self.emit(.{ .call = self.floatEqSym() });
            } else if (oi.cell == .i64) {
                try self.lowerCoerced(val_side, "i64");
                try self.emit(opOf("i64", "eq"));
            } else {
                try self.lowerCoerced(val_side, "i32");
                try self.emit(opOf("i32", "eq"));
            }
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
        // Decision 210 — a composite compares by value through its type's
        // generated `$__eq_<T>` (`lowerStructuralEq`).
        if (op == Op.eq or op == Op.ne) if (try self.lowerStructuralEq(op == Op.ne, lhs, rhs)) return;
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
        // A boxed optional — `xs[i]`, which answers `?T` — is the address of
        // its box: added to as a number it answered `269` for `[1, 2][0] + 1`
        // at exit 0. An absent one has no number either (erlang raises,
        // commonJS reads `null` as `0`), so the operation is refused.
        if (op != Op.eq and op != Op.ne and op != Op.@"and" and op != Op.@"or") for ([_]ast.Expr{ lhs, rhs }) |side| {
            if (self.optInfoOf(side)) |oi| if (oi.boxed)
                return self.refuse(side.getLoc(), "the wasm backend has no `{s}` over an optional value (`xs[i]` answers `?T`): unwrap it first", .{@tagName(op)});
        };
        const t0 = self.unifyNum(self.wasmTypeOf(lhs), self.wasmTypeOf(rhs));
        // Every float is compared as the `f64` the language gives it.
        const t = if (t0[0] == 'f') "f64" else t0;
        try self.lowerCoerced(lhs, t);
        try self.lowerCoerced(rhs, t);
        const is_float = t[0] == 'f';
        // Decision 214 — `==` over floats is a total order: NaN equals NaN
        // and `0.0` differs from `-0.0`. `<`, `>`, `<=`, `>=` stay IEEE.
        if (is_float and (op == Op.eq or op == Op.ne)) {
            try self.emit(.{ .call = self.floatEqSym() });
            if (op == Op.ne) try self.emit(opOf("i32", "eqz"));
            return;
        }
        // Decision 319 — a `u64` / `usize` holds `0 … 2^64 − 1` in its `i64`
        // carrier, so its division, remainder and order read the bits
        // unsigned: signed, `10^19 > 3` answered `false` at exit 0.
        const unsigned = std.mem.eql(u8, t, "i64") and (self.isU64At(loc) or self.isU64Expr(lhs) or self.isU64Expr(rhs));
        const opname: ?[]const u8 = switch (op) {
            Op.add => "add",
            Op.sub => "sub",
            Op.mul => "mul",
            Op.div => if (is_float) "div" else if (unsigned) "div_u" else "div_s",
            Op.mod => if (is_float) null else if (unsigned) "rem_u" else "rem_s",
            Op.lt => if (is_float) "lt" else if (unsigned) "lt_u" else "lt_s",
            Op.gt => if (is_float) "gt" else if (unsigned) "gt_u" else "gt_s",
            Op.lte => if (is_float) "le" else if (unsigned) "le_u" else "le_s",
            Op.gte => if (is_float) "ge" else if (unsigned) "ge_u" else "ge_s",
            Op.eq => "eq",
            Op.ne => "ne",
            // wasm has no short-circuit form; `and`/`or` are bitwise on the
            // 0/1 carrier, which is the same answer for booleans.
            Op.@"and" => if (is_float) null else "and",
            Op.@"or" => if (is_float) null else "or",
        };
        if (opname) |on| {
            try self.emitArith(t, on, loc);
        } else {
            // No opcode for this pair (float `%`, float `&&`). It used to drop
            // the right operand and answer the left one at exit 0.
            return self.refuse(lhs.getLoc(), "the wasm backend has no `{s}` for `{s}` operands", .{ @tagName(op), t });
        }
    }

    fn lowerNeg(self: *Emitter, inner: ast.Expr, loc: ast.Loc) anyerror!void {
        // Decision 319 — a type's minimum written as itself: `0 - 2^63` traps
        // the checked `sub` and `2^31` alone reads as an `i64`, so the
        // negated literal is the constant.
        if (negatedMinimum(inner)) |m| return self.emit(constOf(m.ty, m.text));
        const t = self.wasmTypeOf(inner);
        if (t[0] == 'f') {
            try self.lowerValue(inner);
            try self.emit(opOf(t, "neg"));
        } else {
            try self.emit(constOf(t, "0"));
            try self.lowerCoerced(inner, t);
            try self.emitArith(t, "sub", loc);
        }
    }

    /// `<t>.<op>` over the two operands on the stack — an integer `add`,
    /// `sub` or `mul` checked (`$__i32_add_chk`, …), which traps where the
    /// result does not fit `t`: wrapped, `2147483647 + 1` answered
    /// `-2147483648` at exit 0 where commonJS and erlang answer `2147483648`.
    /// The type inference recorded at `loc` (decision 264) then checks its
    /// own range when it is narrower than `t` (`emitRangeCheck`).
    fn emitArith(self: *Emitter, t: []const u8, on: []const u8, loc: ast.Loc) anyerror!void {
        const wide = std.mem.eql(u8, t, "i64");
        // A `u64` / `usize` result is checked unsigned against the carrier's
        // whole 64 bits (decision 319), which is its range: no range check
        // follows.
        if (wide and self.isU64At(loc)) {
            const h: ?wat.Helper = if (std.mem.eql(u8, on, "add"))
                .u64_add_chk
            else if (std.mem.eql(u8, on, "sub"))
                .u64_sub_chk
            else if (std.mem.eql(u8, on, "mul"))
                .u64_mul_chk
            else
                null;
            if (h) |helper| return self.emit(self.builder().helper(helper));
        }
        if (wide or std.mem.eql(u8, t, "i32")) {
            const h: ?wat.Helper = if (std.mem.eql(u8, on, "add"))
                (if (wide) .i64_add_chk else .i32_add_chk)
            else if (std.mem.eql(u8, on, "sub"))
                (if (wide) .i64_sub_chk else .i32_sub_chk)
            else if (std.mem.eql(u8, on, "mul"))
                (if (wide) .i64_mul_chk else .i32_mul_chk)
            else
                null;
            if (h) |helper| {
                try self.emit(self.builder().helper(helper));
                return self.emitRangeCheck(wide, loc);
            }
        }
        try self.emit(opOf(t, on));
    }

    /// Whether inference typed the arithmetic operator at `loc` `u64` or
    /// `usize` — the two types whose `i64` carrier holds unsigned bits.
    fn isU64At(self: *Emitter, loc: ast.Loc) bool {
        const il = self.instance_lowerings.get(loc) orelse return false;
        if (il != .division) return false;
        return il.division == .u64 or il.division == .usize;
    }

    /// Whether `e` names a `?T` local a null test narrowed to its payload.
    fn isNarrowedName(self: *Emitter, e: ast.Expr) bool {
        const n = plainIdentName(e) orelse return false;
        return self.narrowed_opts.contains(self.resolveName(n));
    }

    /// Whether `e` is a `u64` / `usize` value: its declared type, or the
    /// type inference recorded at its operator.
    fn isU64Expr(self: *Emitter, e: ast.Expr) bool {
        switch (e) {
            .binaryOp => |bin| return self.isU64At(bin.loc),
            .collection => |col| switch (col.kind) {
                .grouped => |inner| return self.isU64Expr(inner.*),
                else => {},
            },
            else => {},
        }
        // `t.0` of a `u64` element of a tuple no type is written for.
        if (self.tupleElemShapeOf(e) catch null) |el| if (el.len == 1 and el[0] == 'u') return true;
        const tr0 = self.typeRefOf(e) orelse return false;
        // A `?u64` a null test narrowed is the `u64` its cell holds:
        // `if (o != null) { o.toString() }` wrote `-1`.
        const tr = if (tr0 == .optional and self.isNarrowedName(e)) tr0.optional.* else tr0;
        if (tr != .named) return false;
        return std.mem.eql(u8, tr.named, "u64") or std.mem.eql(u8, tr.named, "usize");
    }

    /// Decision 264 — the checked result of the integer operator at `loc`,
    /// on the stack in its carrier (`i64` when `wide`, else `i32`), checked
    /// against the range of the type inference recorded there when that
    /// range is narrower than the carrier's: `i8`, `u8`, `i16`, `u16` in an
    /// `i32`; `u32`, `u64`, `usize` in an `i64`. `127 + 1` on `i8` answered
    /// `128` and `0 - 1` on `u32` answered `-1`, both at exit 0. A `u64`
    /// lives in an `i64` here, so its range ends at the carrier's. An
    /// operator whose type was never resolved (a generic `T`) is left as the
    /// carrier's check left it.
    fn emitRangeCheck(self: *Emitter, wide: bool, loc: ast.Loc) anyerror!void {
        const il = self.instance_lowerings.get(loc) orelse return;
        if (il != .division) return;
        const r = il.division.range() orelse return;
        const c_lo: i128 = if (wide) std.math.minInt(i64) else std.math.minInt(i32);
        const c_hi: i128 = if (wide) std.math.maxInt(i64) else std.math.maxInt(i32);
        const lo = @max(r.lo, c_lo);
        const hi = @min(r.hi, c_hi);
        if (lo == c_lo and hi == c_hi) return;
        const ty: []const u8 = if (wide) "i64" else "i32";
        try self.emit(constOf(ty, try std.fmt.allocPrint(self.arena(), "{d}", .{lo})));
        try self.emit(constOf(ty, try std.fmt.allocPrint(self.arena(), "{d}", .{hi})));
        try self.emit(self.builder().helper(if (wide) .i64_range_chk else .i32_range_chk));
    }

    /// The plain NAMES a null test narrows — when it HOLDS (`present`), which
    /// is the then-branch of `x != null`, and when it fails, which is the else
    /// branch of `x == null`. `&&` narrows both of its halves on the holding
    /// side and `||` both of them on the failing side; only a bare name is
    /// narrowable, which is the same limit the checker draws
    /// (`o.inner != null` rebinds nothing).
    fn collectNullTestNames(self: *Emitter, cond: ast.Expr, present: bool, out: *std.ArrayListUnmanaged([]const u8)) anyerror!void {
        switch (cond) {
            .collection => |col| switch (col.kind) {
                .grouped => |inner| try self.collectNullTestNames(inner.*, present, out),
                else => {},
            },
            .binaryOp => |bin| switch (bin.op) {
                .ne, .eq => {
                    if ((bin.op == .ne) != present) return;
                    const name = if (isNullLit(bin.rhs.*))
                        plainIdentName(bin.lhs.*)
                    else if (isNullLit(bin.lhs.*))
                        plainIdentName(bin.rhs.*)
                    else
                        null;
                    if (name) |n| try out.append(self.arena(), n);
                },
                .@"and" => if (present) {
                    try self.collectNullTestNames(bin.lhs.*, true, out);
                    try self.collectNullTestNames(bin.rhs.*, true, out);
                },
                .@"or" => if (!present) {
                    try self.collectNullTestNames(bin.lhs.*, false, out);
                    try self.collectNullTestNames(bin.rhs.*, false, out);
                },
                else => {},
            },
            else => {},
        }
    }

    /// One name a branch narrowed, and which shape notes were added for it —
    /// so `dropNarrowing` restores exactly what was there, and a narrowing does
    /// not outlive its branch.
    const Narrowing = struct {
        name: []const u8,
        added_str: bool = false,
        added_bool: bool = false,
        added_rec: bool = false,
    };

    /// Mark every narrowable name of `names` as its payload for the branch
    /// about to be emitted, and answer what was marked so `dropNarrowing` can
    /// put it back. A `?string`, a `?bool` and a `?Record` also take the shape
    /// their payload has, because inside the branch every reader asks about a
    /// plain value and no longer about an optional.
    const UnknownNarrowing = struct { name: []const u8, previous: ?[]const u8, alias: ?[]const u8 = null };

    /// `if (x is i32) { … x … }` over an `unknown` `x`: inside the branch `x`
    /// IS the payload the test proved — the checker types it so (§4.1) — so
    /// the branch reads an unboxed copy (an alias `resolveName` answers),
    /// converted when the box holds the other numeric kind (`3.0` read as
    /// `3`). Written at the top of the branch the test opens.
    fn narrowUnknown(self: *Emitter, cond: ast.Expr) anyerror!?UnknownNarrowing {
        const cc = switch (cond) {
            .call => |c| switch (c.kind) {
                .call => |cc| cc,
                else => return null,
            },
            else => return null,
        };
        if (!cc.is_builtin or !std.mem.eql(u8, cc.callee, ast.is_builtin_name) or cc.args.len != 1) return null;
        if (cc.isType) |ft| if (ft == .function) return self.narrowUnknownFn(cc.args[0].value.*, ft);
        const pt = primTestOf(cc.isType orelse return null) orelse return null;
        const n0 = plainIdentName(cc.args[0].value.*) orelse return null;
        if (!self.isUnknownExpr(cc.args[0].value.*)) return null;
        const n = self.resolveName(n0);
        const alias = try std.fmt.allocPrint(self.arena(), "{s}__is{d}", .{ n0, self.alias_seq });
        self.alias_seq += 1;
        const b = self.builder();
        try self.declareLocal(alias, if (pt == .float) "f64" else "i32");
        try self.emit(.{ .local_get = n });
        switch (pt) {
            .int => try self.emit(b.helper(.unknown_as_i32)),
            .float => try self.emit(b.helper(.unknown_as_f64)),
            .bool_, .string => try self.emitC(.{ .load = .{} }, "unknown: the proven payload"),
        }
        try self.emit(.{ .local_set = alias });
        if (pt == .string) try self.str_locals.put(alias, {});
        if (pt == .bool_) try self.bool_locals.put(alias, {});
        const previous = self.aliases.get(n0);
        try self.aliases.put(n0, alias);
        return .{ .name = n0, .previous = previous };
    }

    /// Decision 254 — `if (f is fn(…) -> T) { … f(…) … }` over an `unknown`
    /// `f`: inside the branch `f` is the closure cell the box holds, typed by
    /// the tested function type so a call through it answers `T`.
    fn narrowUnknownFn(self: *Emitter, subject: ast.Expr, ft: ast.TypeRef) anyerror!?UnknownNarrowing {
        const n0 = plainIdentName(subject) orelse return null;
        if (!self.isUnknownExpr(subject)) return null;
        const n = self.resolveName(n0);
        const alias = try std.fmt.allocPrint(self.arena(), "{s}__is{d}", .{ n0, self.alias_seq });
        self.alias_seq += 1;
        try self.declareLocal(alias, "i32");
        try self.emit(.{ .local_get = n });
        try self.emitC(.{ .load = .{} }, "unknown: the proven function value");
        try self.emit(.{ .local_set = alias });
        try self.local_typerefs.put(alias, ft);
        const previous = self.aliases.get(n0);
        try self.aliases.put(n0, alias);
        return .{ .name = n0, .previous = previous, .alias = alias };
    }

    fn dropUnknownNarrowing(self: *Emitter, un: ?UnknownNarrowing) void {
        const u = un orelse return;
        if (u.alias) |a| _ = self.local_typerefs.remove(a);
        if (u.previous) |p| {
            self.aliases.put(u.name, p) catch {};
        } else _ = self.aliases.remove(u.name);
    }

    fn applyNarrowing(self: *Emitter, names: []const []const u8) anyerror![]const Narrowing {
        var marked: std.ArrayListUnmanaged(Narrowing) = .empty;
        for (names) |n0| {
            const n = self.resolveName(n0);
            if (self.narrowed_opts.contains(n)) continue;
            const oi = self.opt_locals.get(n) orelse continue;
            try self.narrowed_opts.put(n, oi);
            var m: Narrowing = .{ .name = n };
            if (oi.str and !self.str_locals.contains(n)) {
                try self.str_locals.put(n, {});
                m.added_str = true;
            }
            if (oi.bool_ and !self.bool_locals.contains(n)) {
                try self.bool_locals.put(n, {});
                m.added_bool = true;
            }
            if (oi.rec) |r| if (!self.local_types.contains(n)) {
                try self.local_types.put(n, r);
                m.added_rec = true;
            };
            try marked.append(self.arena(), m);
        }
        return marked.items;
    }

    fn dropNarrowing(self: *Emitter, marked: []const Narrowing) void {
        for (marked) |m| {
            _ = self.narrowed_opts.remove(m.name);
            if (m.added_str) _ = self.str_locals.remove(m.name);
            if (m.added_bool) _ = self.bool_locals.remove(m.name);
            if (m.added_rec) _ = self.local_types.remove(m.name);
        }
    }

    const BinderFlags = struct { name: []const u8, str: bool, bool_: bool, rec: ?[]const u8 };

    fn restoreBinderFlags(self: *Emitter, bp: BinderFlags) !void {
        if (bp.str) try self.str_locals.put(bp.name, {}) else _ = self.str_locals.remove(bp.name);
        if (bp.bool_) try self.bool_locals.put(bp.name, {}) else _ = self.bool_locals.remove(bp.name);
        if (bp.rec) |r| try self.local_types.put(bp.name, r) else _ = self.local_types.remove(bp.name);
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

        // Decision 330 — `recv?.[i]`, `f?.(args)` and `x!` reach every backend
        // as an `if` over the optional with a `__bp_opt_<line>_<col>` binder
        // (`infer.inferOptionalOperator`). This backend does not know what
        // such an `if` answers — a boxed payload, a scalar, a string — and
        // lowered as it stands it printed addresses: refused, located at the
        // operand, until `05-wasm` types it.
        if (i.binding) |name| if (std.mem.startsWith(u8, name, "__bp_opt_")) {
            // `x!` answers the payload the binder holds, and `xs?.[k]` (or a
            // call answering an optional) the link's own optional — absence
            // is the `0` both arms agree on. A link answering a plain value
            // would have to be boxed here, and is refused.
            const supported = if (i.then_.len == 1) blk: {
                const tail = i.then_[0].expr;
                if (tail == .identifier and tail.identifier.kind == .ident and std.mem.eql(u8, tail.identifier.kind.ident, name)) break :blk true;
                break :blk self.optInfoOf(tail) != null;
            } else false;
            if (!supported) return self.refuse(i.cond.getLoc(), "the wasm backend does not lower `?.()` over a function answering a plain value yet (decision 330)", .{});
        };

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
        // The value's own type: an arm answering a float makes the whole `if`
        // one (`ifValueType`). It was the enclosing function's result type
        // whatever the arms answered, so `val m = if (d < 0.0) { 0.0 - d }
        // else { d }` in a function answering nothing was `(if (result i32)`
        // around two `f64`s — invalid code, the module refused.
        const ty: []const u8 = if (as_stmt) self.cur_result else self.ifValueType(i);
        const own_ty = !std.mem.eql(u8, ty, self.cur_result);
        const result: ?ValType = if (as_stmt) null else vt(ty);

        var then_c: Capture = .{};
        self.open(&then_c);
        // The binder is the then-arm's name only. What its payload made it (a
        // string, a bool, a record) is put back as it was when the arm ends:
        // every `a ?? b` binds the same `__bp_nullish`, and a string payload
        // left behind made the next `??` over an `i32` print as a string — a
        // trap on the integer read as a pointer.
        const binder_prev: ?BinderFlags = if (i.binding) |name| .{
            .name = name,
            .str = self.str_locals.contains(name),
            .bool_ = self.bool_locals.contains(name),
            .rec = self.local_types.get(name),
        } else null;
        if (i.binding) |name| {
            const oi = self.optInfoOf(i.cond.*);
            const cell: Cell = if (oi) |o| o.cell else .none;
            try self.declareLocal(name, cell.ty());
            if (!std.mem.eql(u8, self.locals.get(name).?, cell.ty()))
                return self.refuse(i.cond.getLoc(), "the wasm backend binds `{s}` to values of two widths in one function", .{name});
            try self.emit(.{ .local_get = bind_tmp.? });
            if (oi) |o| {
                if (o.boxed) try self.emitUnboxPayload(o, "optional payload");
                if (o.str) try self.str_locals.put(name, {});
                if (o.bool_) try self.bool_locals.put(name, {});
                if (o.inner) |tr| try self.local_typerefs.put(name, tr);
                // A record payload types the binder, so `h.rest` reads the
                // declared slot rather than guessing one by the field's name
                // (`modules/field_name_collision` answered `0` / `0`).
                const rec: ?[]const u8 = o.rec orelse if (o.inner) |tr| switch (tr) {
                    .named => |n| self.resolveRecordName(n),
                    .generic => |g| self.resolveRecordName(g.name),
                    else => null,
                } else null;
                if (rec) |r| try self.local_types.put(name, r);
            }
            try self.emit(.{ .local_set = name });
        }
        var then_names: std.ArrayListUnmanaged([]const u8) = .empty;
        try self.collectNullTestNames(i.cond.*, true, &then_names);
        const then_marked = try self.applyNarrowing(then_names.items);
        const unknown_narrowed = try self.narrowUnknown(i.cond.*);
        const then_tail = if (own_ty) try self.emitBranchValue(i.then_, ty) else try self.emitBody(i.then_, !as_stmt);
        self.dropUnknownNarrowing(unknown_narrowed);
        self.dropNarrowing(then_marked);
        if (binder_prev) |bp| try self.restoreBinderFlags(bp);
        const then_seq = self.seal(&then_c, stackOf(then_tail, ty));

        var else_seq: ?Seq = null;
        if (i.else_) |els| {
            var else_c: Capture = .{};
            self.open(&else_c);
            var else_names: std.ArrayListUnmanaged([]const u8) = .empty;
            try self.collectNullTestNames(i.cond.*, false, &else_names);
            const else_marked = try self.applyNarrowing(else_names.items);
            const else_tail = if (own_ty) try self.emitBranchValue(els, ty) else try self.emitBody(els, !as_stmt);
            self.dropNarrowing(else_marked);
            else_seq = self.seal(&else_c, stackOf(else_tail, ty));
        } else if (!as_stmt) {
            // A value-form `if` must fill its `(result …)` on both paths.
            var else_c: Capture = .{};
            self.open(&else_c);
            try self.emitAt(8, constOf(ty, "0"));
            else_seq = self.seal(&else_c, .{ .value = vt(ty) });
        }

        try self.emit(.{ .@"if" = .{
            .result = result,
            .then = .{ .seq = then_seq },
            .@"else" = if (else_seq) |s| .{ .seq = s } else null,
        } });
    }

    /// The type a value-form `if` answers: a float when an arm that yields a
    /// value yields one, else the enclosing result type every other value
    /// `if` has always taken (its arms are coerced to it by their context).
    fn ifValueType(self: *Emitter, i: anytype) []const u8 {
        var t: []const u8 = "";
        // The first arm's integer type, when no arm answers a float: an `if`
        // over two `i32`s (a bool, a digit) inside a function answering `f64`
        // was `(if (result f64)` around two `i32`s — invalid code.
        var int: []const u8 = "";
        for ([_]?[]const ast.Stmt{ i.then_, i.else_ }) |maybe| {
            const body = maybe orelse continue;
            if (body.len == 0) continue;
            const last = body[body.len - 1].expr;
            if (self.exprTail(last) != .value) continue;
            const lt = self.wasmTypeOf(last);
            if (lt[0] == 'f') {
                t = if (t.len == 0) lt else self.unifyNum(t, lt);
            } else if (int.len == 0) int = lt;
        }
        if (t.len > 0) return t;
        return if (int.len > 0) int else self.cur_result;
    }

    /// One arm of an `if` whose value type is its own (`ifValueType`): the
    /// arm's tail converted to `ty`, a zero of `ty` where it yields nothing.
    fn emitBranchValue(self: *Emitter, body: []const ast.Stmt, ty: []const u8) anyerror!Tail {
        const scope_mark = self.scopeMark();
        defer self.scopeRestore(scope_mark);
        if (body.len == 0) {
            try self.emit(constOf(ty, "0"));
            return .value;
        }
        for (body[0 .. body.len - 1]) |stmt| _ = try self.emitStmt(stmt, false);
        const last = body[body.len - 1];
        const from = self.wasmTypeOf(last.expr);
        const tail = try self.emitStmtRaw(last, true);
        switch (tail) {
            .none => {
                try self.emit(constOf(ty, "0"));
                return .value;
            },
            .value => {
                try self.emitConvert(from, ty);
                return .value;
            },
            .terminated => return .terminated,
        }
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

/// A number token's wasm type. A float literal is an `f64` — the type the
/// language gives it (`1e3`, `2.5`), and the only one that holds `5e-324` or
/// `1.7976931348623157e308`; it was an `f32.const`, where the first is `0`. A
/// radix integer (`0xFE`) is an `i32` whatever letters its digits use.
/// The operand of a unary `-` that is an integer literal of magnitude `2^31`
/// or `2^63`: the minimum of `i32` / `i64` written as itself (decision 319),
/// as the constant it is. Null for any other operand.
fn negatedMinimum(e: ast.Expr) ?struct { ty: []const u8, text: []const u8 } {
    if (e != .literal or e.literal.kind != .numberLit) return null;
    const n = e.literal.kind.numberLit;
    if (n.len == 0 or n[0] == '-' or n[0] == '+') return null;
    const v: i128 = if (radixOf(n)) |r| radixValue(n, r) orelse return null else blk: {
        var acc: i128 = 0;
        for (n) |c| switch (c) {
            '0'...'9' => acc = std.math.add(i128, std.math.mul(i128, acc, 10) catch return null, c - '0') catch return null,
            '_' => {},
            else => return null,
        };
        break :blk acc;
    };
    if (v == -@as(i128, std.math.minInt(i32))) return .{ .ty = "i32", .text = "-2147483648" };
    if (v == -@as(i128, std.math.minInt(i64))) return .{ .ty = "i64", .text = "-9223372036854775808" };
    return null;
}

fn numLitType(n: []const u8) []const u8 {
    if (radixOf(n)) |r| {
        const v = radixValue(n, r) orelse return "i32";
        return if (v > std.math.maxInt(i32) or v < std.math.minInt(i32)) "i64" else "i32";
    }
    for (n) |c| if (c == '.' or c == 'e' or c == 'E') return "f64";
    // An integer past the `i32` range is an `i64`: as `i32.const` the text
    // `4294967295` wrapped to `-1`.
    var v: u128 = 0;
    for (n) |c| if (c >= '0' and c <= '9') {
        v = (std.math.mul(u128, v, 10) catch return "i64") + (c - '0');
    };
    return if (v > std.math.maxInt(i32)) "i64" else "i32";
}

/// The base of a radix integer token — `0x` / `0b` / `0o`, after an optional
/// sign — or null for a decimal one.
fn radixOf(n: []const u8) ?u8 {
    const body = if (n.len > 0 and (n[0] == '-' or n[0] == '+')) n[1..] else n;
    if (body.len < 3 or body[0] != '0') return null;
    return switch (body[1]) {
        'x', 'X' => 16,
        'b', 'B' => 2,
        'o', 'O' => 8,
        else => null,
    };
}

/// A radix token's value (`_` separators allowed), or null when its digits
/// are not the base's.
/// Whether the integer literal `n` (digits, `_` separators, an optional
/// `0x` / `0b` / `0o` prefix) is past `i64`'s top — which only a `u64` holds.
fn isPastI64Literal(n: []const u8) bool {
    if (n.len == 0 or n[0] == '-') return false;
    var buf: [160]u8 = undefined;
    var len: usize = 0;
    for (n) |c| if (c != '_') {
        if (len == buf.len) return false;
        buf[len] = c;
        len += 1;
    };
    const v = std.fmt.parseInt(u128, buf[0..len], 0) catch return false;
    return v > std.math.maxInt(i64);
}

/// The value of a radix integer token, up to `u64`'s top (decision 319:
/// `0xFFFF_FFFF_FFFF_FFFFul` is a `u64`, and folded to a `256` placeholder
/// when its value overflowed an `i64` here).
fn radixValue(n: []const u8, base: u8) ?i128 {
    const neg = n[0] == '-';
    const body = if (n[0] == '-' or n[0] == '+') n[1..] else n;
    var v: i128 = 0;
    var any = false;
    for (body[2..]) |c| {
        if (c == '_') continue;
        const d = std.fmt.charToDigit(c, base) catch return null;
        v = v * base + d;
        if (v > std.math.maxInt(u64)) return null;
        any = true;
    }
    if (!any) return null;
    return if (neg) -v else v;
}

/// The `const` of a numeral token: its `numLitType`, and its text as wat
/// writes it — a radix integer in decimal (wat has no `0b` / `0o`), which it
/// had been interned as a string for, so `0xFF` printed the address `256`.
fn numLitConst(arena: std.mem.Allocator, n: []const u8) !Instr {
    return constOf(numLitType(n), try numeralText(arena, n));
}

fn numeralText(arena: std.mem.Allocator, n: []const u8) ![]const u8 {
    const r = radixOf(n) orelse return n;
    return std.fmt.allocPrint(arena, "{d}", .{radixValue(n, r).?});
}

fn exprNumType(e: ast.Expr) []const u8 {
    return switch (e) {
        .literal => |lit| switch (lit.kind) {
            .numberLit => |n| numLitType(n),
            else => "i32",
        },
        .unaryOp => |un| switch (un.op) {
            .neg => if (negatedMinimum(un.expr.*)) |m| m.ty else exprNumType(un.expr.*),
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

/// `Result.Ok` / `Result.Err` / `Result.Error` — how the transform writes an
/// `Ok(…)` / `Error(…)` pattern over a `@Result` subject
/// (`Env.resultPatternLocs`). Always the `@Result` variant, even where a user
/// enum declares one of those names.
fn isResultPath(name: []const u8) bool {
    if (!std.mem.startsWith(u8, name, "Result.")) return false;
    const bare = name["Result.".len..];
    return std.mem.eql(u8, bare, "Ok") or std.mem.eql(u8, bare, "Err") or std.mem.eql(u8, bare, "Error");
}
