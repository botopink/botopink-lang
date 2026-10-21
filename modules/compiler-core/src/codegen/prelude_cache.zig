//! The embedded prelude, `primitives.bp` and its compiler section (the latter with std's
//! `print` and `panic`), parsed once for
//! the life of the process — what the emitters read a `default fn`'s helpers
//! from (`stringSlice0`'s declared return, its `.Wasm(…)` cell) and the
//! prelude's declarations' implementations (`ast.Implementation`, decision
//! 575 (6)): no emitter parses the prelude itself.
//!
//! `emitErlangModule` re-lexed and re-parsed it (`collectPrimErlangDispatch`)
//! on EVERY emission, and the source is a comptime-embedded string — the same
//! bytes, the same parse, every time. On a
//! comptime-heavy build that is one whole parse per evaluated declaration
//! (handed over by `14-comptime-on-beam`, whose step 2 left this as the other
//! half of the per-evaluation cost).
//!
//! The memo is safe because nothing writes to what it holds: the AST borrows
//! only comptime source, and every caller deep-copies what it keeps into its
//! own allocator. It has its own arena over the page allocator rather than a
//! caller's, so a test allocator never sees it and the lifetime is the
//! process's, not one module's. The lock is a spin over `std.atomic.Mutex`'s
//! `tryLock` — zig 0.16 has no blocking mutex outside `std.Io`, and there is
//! nothing to contend for after the first parse — because the test runner
//! compiles on several threads and an arena is not thread-safe.
const std = @import("std");
const ast = @import("../ast.zig");
const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");
const prelude = @import("std_prelude");
const envMod = @import("../comptime/env.zig");

var mutex: std.atomic.Mutex = .unlocked;
var arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var primitives_tried: bool = false;
var primitives_program: ?ast.Program = null;
var builtins_tried: bool = false;
var builtins_program: ?ast.Program = null;

fn lock() void {
    while (!mutex.tryLock()) std.atomic.spinLoopHint();
}

/// The parsed `primitives.bp`, or null when it does not parse — the callers
/// have always swallowed a prelude parse failure, and `primErlangDispatchCount`
/// pins what that would cost.
pub fn primitives() ?ast.Program {
    lock();
    defer mutex.unlock();
    if (primitives_tried) return primitives_program;
    primitives_tried = true;
    const a = arena.allocator();
    var lx = lexerMod.Lexer.init(prelude.primitives);
    const tokens = lx.scanAll(a) catch return null;
    var p = parserMod.Parser.init(tokens);
    const parsed = p.parse(a) catch return null;
    primitives_program = withWidthMembers(a, parsed) catch null;
    return primitives_program;
}

/// The parsed `primitives.bp`'s compiler section, with std's `print` and `panic` as their modules
/// write them (`io/terminal.bp`, `failure.bp`, decision 606 (2)) — the
/// implementations the backends dispatch those calls by —, or null when it
/// does not parse.
pub fn builtins() ?ast.Program {
    lock();
    defer mutex.unlock();
    if (builtins_tried) return builtins_program;
    builtins_tried = true;
    const a = arena.allocator();
    const fns = (@import("../comptime/std_calls.zig").declarationsText(a) catch return null) orelse return null;
    const text = std.mem.concat(a, u8, &.{ prelude.builtins, "\n", fns }) catch return null;
    var lx = lexerMod.Lexer.init(text);
    const tokens = lx.scanAll(a) catch return null;
    var p = parserMod.Parser.init(tokens);
    const parsed = p.parse(a) catch return null;
    // `panic` keeps the backends' own per-arity dispatch (its default).
    var kept: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (parsed.decls) |d| {
        if (d == .@"fn" and std.mem.eql(u8, d.@"fn".name, "panic")) continue;
        kept.append(a, d) catch return null;
    }
    builtins_program = .{ .decls = kept.items };
    return builtins_program;
}

/// The prelude's free `fn` named `name` (`stringSlice0`), or null.
pub fn freeFn(name: []const u8) ?ast.FnDecl {
    const prog = primitives() orelse return null;
    for (prog.decls) |d| if (d == .@"fn" and std.mem.eql(u8, d.@"fn".name, name)) return d.@"fn";
    return null;
}

/// Decision 617 (1) — the contract the primitive type `type_name` (`i32`)
/// implements: the first name of the `implement` clause of its
/// `pub type i32 implement Signed { … }` in `primitives.bp` (`Signed`). Null
/// for a type the prelude does not declare so, or one that implements
/// nothing. The one resolution of a primitive's methods: the checker and every
/// backend start their walk here, then follow the contracts' `extends`.
pub fn primitiveContract(type_name: []const u8) ?[]const u8 {
    const t = primitiveType(type_name) orelse return null;
    if (t.implement.len == 0) return null;
    return switch (t.implement[0]) {
        .named => |n| n,
        .generic => |g| g.name,
        else => null,
    };
}

/// The prelude's primitive type declaration named `type_name`
/// (`TypeDecl.isPrimitive`), or null.
pub fn primitiveType(type_name: []const u8) ?ast.TypeDecl {
    const prog = primitives() orelse return null;
    for (prog.decls) |d| if (d == .type_ and d.type_.isPrimitive and std.mem.eql(u8, d.type_.name, type_name)) return d.type_;
    return null;
}

/// The first `extends` of the prelude behavior `name` (`Signed` → `Integer`),
/// or null.
pub fn behaviorParent(name: []const u8) ?[]const u8 {
    const prog = primitives() orelse return null;
    for (prog.decls) |d| if (d == .behavior and std.mem.eql(u8, d.behavior.name, name)) {
        return if (d.behavior.extends.len > 0) d.behavior.extends[0] else null;
    };
    return null;
}

/// True when the contract chain of the primitive type `type_name` — its
/// `implement`, then each `extends` — names `behavior`.
pub fn primitiveReaches(type_name: []const u8, behavior: []const u8) bool {
    var cur = primitiveContract(type_name);
    var guard: usize = 0;
    while (cur) |c| : (guard += 1) {
        if (guard >= 16) return false;
        if (std.mem.eql(u8, c, behavior)) return true;
        cur = behaviorParent(c);
    }
    return false;
}

/// The behaviors of `primitives.bp` a receiver of kind `k` answers methods
/// from, most specific first: the union, in declaration order, of the
/// contract chain of every primitive type of that kind (`.int`: `i32`, `i64`,
/// `u32`, `u64` → `Signed`, `Integer`, `Number`). Empty for a kind the prelude
/// declares no primitive type of. Read once, from the text.
pub fn contractChainOfKind(k: envMod.PrimKind) []const []const u8 {
    lock();
    const memo = &chain_memo[@intFromEnum(k)];
    if (memo.*) |m| {
        mutex.unlock();
        return m;
    }
    mutex.unlock();
    var buf: [16][]const u8 = undefined;
    var n: usize = 0;
    if (primitives()) |prog| for (prog.decls) |d| {
        if (d != .type_ or !d.type_.isPrimitive) continue;
        if (envMod.primKindOfName(d.type_.name) != k) continue;
        var cur = primitiveContract(d.type_.name);
        var guard: usize = 0;
        while (cur) |c| : (guard += 1) {
            if (guard >= 16) break;
            const seen = for (buf[0..n]) |x| {
                if (std.mem.eql(u8, x, c)) break true;
            } else false;
            if (!seen and n < buf.len) {
                buf[n] = c;
                n += 1;
            }
            cur = behaviorParent(c);
        }
    };
    // A contract a later width reaches more directly (`u32` → `Integer`) is
    // still placed after the ones that extend it: order by depth, deepest
    // first, so `Signed` precedes `Integer` precedes `Number`.
    std.mem.sort([]const u8, buf[0..n], {}, struct {
        fn lt(_: void, a: []const u8, b: []const u8) bool {
            return depth(a) > depth(b);
        }
    }.lt);
    lock();
    defer mutex.unlock();
    if (chain_memo[@intFromEnum(k)]) |m| return m;
    const out = arena.allocator().dupe([]const u8, buf[0..n]) catch return &.{};
    chain_memo[@intFromEnum(k)] = out;
    return out;
}

var chain_memo: [@typeInfo(envMod.PrimKind).@"enum".fields.len]?[]const []const u8 = @splat(null);

/// How many `extends` the prelude behavior `name` stands above its root.
fn depth(name: []const u8) usize {
    var d: usize = 0;
    var cur = behaviorParent(name);
    while (cur) |c| : (d += 1) {
        if (d >= 16) break;
        cur = behaviorParent(c);
    }
    return d;
}

/// The kinds of the primitive types whose contract chain names the prelude
/// behavior `name` (`Number` → `.int`, `.float`; `Signed` → `.int`), in the
/// order of `envMod.PrimKind`. Empty for a behavior no primitive type
/// implements.
pub fn kindsReaching(name: []const u8) []const envMod.PrimKind {
    const all = comptime std.enums.values(envMod.PrimKind);
    lock();
    const idx = blk: {
        for (reach_names[0..reach_len], 0..) |rn, i| if (std.mem.eql(u8, rn, name)) break :blk i;
        break :blk null;
    };
    if (idx) |i| {
        defer mutex.unlock();
        return reach_kinds[i];
    }
    mutex.unlock();
    var buf: [all.len]envMod.PrimKind = undefined;
    var n: usize = 0;
    for (all) |k| for (contractChainOfKind(k)) |c| if (std.mem.eql(u8, c, name)) {
        buf[n] = k;
        n += 1;
        break;
    };
    lock();
    defer mutex.unlock();
    const out = arena.allocator().dupe(envMod.PrimKind, buf[0..n]) catch return &.{};
    if (reach_len < reach_names.len) {
        reach_names[reach_len] = arena.allocator().dupe(u8, name) catch return out;
        reach_kinds[reach_len] = out;
        reach_len += 1;
    }
    return out;
}

var reach_names: [64][]const u8 = undefined;
var reach_kinds: [64][]const envMod.PrimKind = undefined;
var reach_len: usize = 0;

/// Decision 617 (3), 496 — the free function a member a primitive type
/// declares itself is lowered as: `__i32_abs` for `i32`'s `abs`. A call
/// `n.abs()` on an `i32` is rewritten to `__i32_abs(n)` (`MethodLowering`'s
/// `.width` domain), and the function carries the member's host cells, so
/// every backend lowers it as any prelude `declare fn`. The width's own
/// member is the one that knows the width: `abs` of the lowest `i32` and of
/// the lowest `i64` abort with their own bound.
pub fn widthMemberName(alloc: std.mem.Allocator, width: []const u8, method: []const u8) ![]const u8 {
    return std.fmt.allocPrint(alloc, "__{s}_{s}", .{ width, method });
}

/// The width and the member a `widthMemberName` names (`__i32_abs` →
/// `i32`, `abs`) when the prelude's primitive type declares that member, else
/// null.
pub fn widthMemberOf(callee: []const u8) ?struct { width: []const u8, method: []const u8 } {
    if (!std.mem.startsWith(u8, callee, "__")) return null;
    const rest = callee[2..];
    const us = std.mem.indexOfScalar(u8, rest, '_') orelse return null;
    const width = rest[0..us];
    const method = rest[us + 1 ..];
    const m = widthMember(width, method) orelse return null;
    return .{ .width = width, .method = m.name };
}

/// The member `method` the prelude's primitive type `width` declares itself
/// (`i32`'s `abs`), or null — a member its contracts declare is not one.
pub fn widthMember(width: []const u8, method: []const u8) ?ast.BehaviorMethod {
    const t = primitiveType(width) orelse return null;
    for (t.methods) |m| if (std.mem.eql(u8, m.name, method)) return m;
    return null;
}

/// `program` folded (`foldWidthMembers`) and with, after its declarations, one
/// free `declare fn` per member a primitive type still declares itself
/// (`widthMemberName`): `self` named `value`, `Self`
/// written as the type, the member's annotations and host cells kept. The
/// checker and every backend read the prelude through this.
pub fn withWidthMembers(alloc: std.mem.Allocator, written: ast.Program) !ast.Program {
    const program = try foldWidthMembers(alloc, try dissolvedTypesAsMemberTables(alloc, written));
    var extra: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (program.decls) |d| {
        if (d != .type_ or !d.type_.isPrimitive) continue;
        const t = d.type_;
        for (t.methods) |m| {
            if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
            const params = try alloc.dupe(ast.Param, m.params);
            params[0].name = "value";
            for (params) |*pp| pp.typeRef = selfAs(pp.typeRef, t.name);
            // The parser wrote a method's `$0` as the receiver marker and its
            // `$N` as `$(N-1)` (`parser/template_markers.zig`); the free
            // function takes the receiver as its `$0`.
            const impls = try alloc.dupe(ast.Implementation, m.implementations);
            for (impls) |*im| {
                const same = im.template != null and std.mem.eql(u8, im.template.?, im.text);
                if (im.template) |tp| im.template = try unshift(alloc, tp);
                if (same) im.text = im.template.? else if (im.cell == null) im.text = try unshift(alloc, im.text);
            }
            try extra.append(alloc, .{ .@"fn" = .{
                .isPub = false,
                .isDeclare = true,
                .name = try widthMemberName(alloc, t.name, m.name),
                .nameLoc = m.nameLoc,
                .annotations = m.annotations,
                .implementations = impls,
                .genericParams = m.genericParams,
                .params = params,
                .returnType = if (m.returnType) |r| selfAs(r, t.name) else null,
                .returnTypeLoc = m.returnTypeLoc,
                .body = &.{},
            } });
        }
    }
    if (extra.items.len == 0) return program;
    var out = program;
    out.decls = try std.mem.concat(alloc, ast.DeclKind, &.{ program.decls, extra.items });
    return out;
}

/// Decision 641 — each primitive type of `program` that implements no
/// contract (`pub type string { … }`, `bool`, `bigint`, `bytes`,
/// `array<T>`) held as its member table: the `BehaviorDecl` of the type's own
/// name (`string`) the checker and every backend find a primitive's methods
/// and statics in (`BehaviorDecl.primitiveType`), its properties
/// (`val length: i32;`) the table's fields. A `declare fn` with its cells is
/// a member with those implementations; a `fn` with a body is a member with
/// that body. A member one target runs in botopink (`.Wasm(body: f)`,
/// decision 610) is the member whose body is `f`'s and whose cells are the
/// others — `f`'s first parameter is the receiver (read as the member's
/// `self`), and its other parameters the member's. A program never names the table: it names
/// the type.
pub fn dissolvedTypesAsMemberTables(alloc: std.mem.Allocator, program: ast.Program) !ast.Program {
    var any = false;
    for (program.decls) |d| if (d == .type_ and d.type_.isPrimitive and d.type_.implement.len == 0) {
        any = true;
        break;
    };
    if (!any) return program;
    const out_decls = try alloc.dupe(ast.DeclKind, program.decls);
    for (out_decls) |*d| {
        if (d.* != .type_ or !d.type_.isPrimitive or d.type_.implement.len != 0) continue;
        const t = d.type_;
        const methods = try alloc.alloc(ast.BehaviorMethod, t.methods.len);
        for (t.methods, methods) |m, *out| {
            out.* = m;
            out.is_declare = false;
            out.is_default = m.body != null;
            var bodies: usize = 0;
            for (m.implementations) |im| {
                if (im.cell != null and im.cell.?.kind == .body) bodies += 1;
            }
            if (bodies == 0) continue;
            var kept: std.ArrayListUnmanaged(ast.Implementation) = .empty;
            var body_fn: ?[]const u8 = null;
            for (m.implementations) |im| {
                if (im.cell) |c| if (c.kind == .body) {
                    body_fn = c.value;
                    continue;
                };
                try kept.append(alloc, im);
            }
            out.implementations = kept.items;
            out.annotations = try withoutBodyCells(alloc, m.annotations);
            const f = for (program.decls) |fd| {
                if (fd == .@"fn" and std.mem.eql(u8, fd.@"fn".name, body_fn.?)) break fd.@"fn";
            } else return error.PreludeBodyMissing;
            // The function's receiver is its first parameter (`value`); the
            // member's is `self`.
            const takes_self = m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self");
            out.body = if (takes_self and f.params.len > 0 and !std.mem.eql(u8, f.params[0].name, "self"))
                try @import("../comptime/template_eval.zig").renameIdentifier(alloc, f.body, f.params[0].name, "self")
            else
                f.body;
            out.is_default = true;
        }
        d.* = .{ .behavior = .{
            .name = t.name,
            .docComment = t.docComment,
            .comment = t.comment,
            .moduleComment = t.moduleComment,
            .annotations = t.annotations,
            .genericParams = t.genericParams,
            .fields = t.properties,
            .methods = methods,
            .bodyComments = t.bodyComments,
            .nameLoc = t.loc,
            .primitiveType = true,
        } };
    }
    var out = program;
    out.decls = out_decls;
    return out;
}

/// Decision 641 — the primitive types that hold their own members, each table
/// under the type's own name (`dissolvedTypesAsMemberTables`). A static is
/// called through that name, lowercase like the type: `string.fromCodepoint(65)`,
/// `array.range(0, 3)`, `bytes.fromUtf8(s)`, `bigint.of(n)`.
pub const member_table_names = [_][]const u8{ "string", "bool", "bigint", "bytes", "array" };

/// True when `name` is one of `member_table_names`.
pub fn isMemberTable(name: []const u8) bool {
    for (member_table_names) |n| if (std.mem.eql(u8, n, name)) return true;
    return false;
}

/// True when `name` is a primitive type holding its own members and its
/// table declares the static `method` (no `self`): `array.range`.
pub fn isMemberTableStatic(name: []const u8, method: []const u8) bool {
    if (!isMemberTable(name)) return false;
    const prog = primitives() orelse return false;
    for (prog.decls) |d| if (d == .behavior and d.behavior.primitiveType and std.mem.eql(u8, d.behavior.name, name)) {
        for (d.behavior.methods) |m| if (std.mem.eql(u8, m.name, method)) {
            return m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self");
        };
    };
    return false;
}

/// `annotations` with each `.T(body: f)` source left out of an
/// `#[compiler.external(…)]` (`dissolvedTypesAsMemberTables`: the body is the
/// member's own).
fn withoutBodyCells(alloc: std.mem.Allocator, annotations: []ast.Annotation) ![]ast.Annotation {
    const out = try alloc.dupe(ast.Annotation, annotations);
    for (out) |*a| {
        var args: std.ArrayListUnmanaged([]const u8) = .empty;
        var src: std.ArrayListUnmanaged([]const u8) = .empty;
        var labels: std.ArrayListUnmanaged([]const u8) = .empty;
        var locs: std.ArrayListUnmanaged(ast.Loc) = .empty;
        var dropped = false;
        for (a.args, 0..) |arg, i| {
            if (isBodySource(arg)) {
                dropped = true;
                continue;
            }
            try args.append(alloc, arg);
            if (a.source_args) |sa| if (i < sa.len) try src.append(alloc, sa[i]);
            if (i < a.labels.len) try labels.append(alloc, a.labels[i]);
            if (i < a.argLocs.len) try locs.append(alloc, a.argLocs[i]);
        }
        if (!dropped) continue;
        a.args = args.items;
        if (a.source_args != null) a.source_args = src.items;
        if (a.labels.len > 0) a.labels = labels.items;
        if (a.argLocs.len > 0) a.argLocs = locs.items;
    }
    return out;
}

/// True for a source argument written `.T(body: f)`.
fn isBodySource(arg: []const u8) bool {
    const open = std.mem.indexOfScalar(u8, arg, '(') orelse return false;
    const inner = std.mem.trimStart(u8, arg[open + 1 ..], " \t\n");
    return std.mem.startsWith(u8, inner, "body") and std.mem.indexOfScalar(u8, inner, ':') != null and
        std.mem.indexOfScalar(u8, inner, '"') == null;
}

fn selfAs(r: ast.TypeRef, name: []const u8) ast.TypeRef {
    if (r == .named and std.mem.eql(u8, r.named, "Self")) return .{ .named = name };
    return r;
}

/// A method's template written for a free function: the receiver marker is
/// `$0`, and each `$N` is `$(N+1)`.
fn unshift(alloc: std.mem.Allocator, text: []const u8) ![]const u8 {
    const receiver_marker = @import("../comptime/primOpTemplate.zig").receiver_marker;
    var out: std.ArrayList(u8) = .empty;
    var i: usize = 0;
    while (i < text.len) {
        if (std.mem.startsWith(u8, text[i..], receiver_marker)) {
            try out.appendSlice(alloc, "$0");
            i += receiver_marker.len;
            continue;
        }
        if (text[i] == '$' and i + 1 < text.len and std.ascii.isDigit(text[i + 1])) {
            var j = i + 1;
            while (j < text.len and std.ascii.isDigit(text[j])) j += 1;
            const n = std.fmt.parseInt(usize, text[i + 1 .. j], 10) catch 0;
            try out.print(alloc, "${d}", .{n + 1});
            i = j;
            continue;
        }
        try out.append(alloc, text[i]);
        i += 1;
    }
    return out.items;
}

/// Decision 617 (3) — a contract's member that EVERY primitive type
/// implementing the contract declares with the same host code (`Number.min`
/// on the six widths, `Float.floor` on `f32` and `f64`) has one answer
/// whatever the width: the program the checker and the backends read holds
/// that code on the contract's member (`BehaviorMethod.folded`) and the
/// member no longer on the types, so a call keeps the contract's dispatch.
/// A member the types declare differently (`abs` on `i32` and on `i64`,
/// each with its bound), or one only some of them declare, stays on each
/// type (`withWidthMembers`). The text writes host code on the types alone.
pub fn foldWidthMembers(alloc: std.mem.Allocator, program: ast.Program) !ast.Program {
    var out_decls = try alloc.dupe(ast.DeclKind, program.decls);
    var folded_any = false;
    for (out_decls, 0..) |d, bi| {
        if (d != .behavior or d.behavior.primitiveType) continue;
        const b = d.behavior;
        var methods: ?[]ast.BehaviorMethod = null;
        for (b.methods, 0..) |m, mi| {
            if (m.implementations.len > 0) continue;
            if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
            var first: ?ast.BehaviorMethod = null;
            var implementors: usize = 0;
            const same = for (program.decls) |td| {
                if (td != .type_ or !td.type_.isPrimitive) continue;
                if (!reachesIn(program, td.type_, b.name)) continue;
                implementors += 1;
                const own = for (td.type_.methods) |tm| {
                    if (std.mem.eql(u8, tm.name, m.name)) break tm;
                } else break false;
                if (own.implementations.len == 0) break false;
                if (first) |f| {
                    if (!sameImplementations(f.implementations, own.implementations)) break false;
                } else first = own;
            } else true;
            if (!same or implementors == 0) continue;
            const ms = methods orelse try alloc.dupe(ast.BehaviorMethod, b.methods);
            methods = ms;
            ms[mi].implementations = first.?.implementations;
            ms[mi].annotations = first.?.annotations;
            ms[mi].folded = true;
        }
        const ms = methods orelse continue;
        folded_any = true;
        var nb = b;
        nb.methods = ms;
        out_decls[bi] = .{ .behavior = nb };
    }
    if (!folded_any) return program;
    // The folded members leave the types.
    for (out_decls, 0..) |d, ti| {
        if (d != .type_ or !d.type_.isPrimitive) continue;
        var kept: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
        for (d.type_.methods) |tm| {
            if (foldedFor(out_decls, d.type_, tm.name)) continue;
            try kept.append(alloc, tm);
        }
        var nt = d.type_;
        nt.methods = kept.items;
        out_decls[ti] = .{ .type_ = nt };
    }
    var out = program;
    out.decls = out_decls;
    return out;
}

/// True when a contract `t` reaches in `decls` holds `name` folded.
fn foldedFor(decls: []const ast.DeclKind, t: ast.TypeDecl, name: []const u8) bool {
    for (decls) |d| {
        if (d != .behavior) continue;
        if (!reachesIn(.{ .decls = @constCast(decls) }, t, d.behavior.name)) continue;
        for (d.behavior.methods) |m| if (m.folded and std.mem.eql(u8, m.name, name)) return true;
    }
    return false;
}

/// True when the primitive type `t`'s `implement` clause, or a contract its
/// chain `extends` in `program`, is `behavior`.
fn reachesIn(program: ast.Program, t: ast.TypeDecl, behavior: []const u8) bool {
    if (t.implement.len == 0) return false;
    var cur: ?[]const u8 = switch (t.implement[0]) {
        .named => |n| n,
        .generic => |g| g.name,
        else => null,
    };
    var guard: usize = 0;
    while (cur) |c| : (guard += 1) {
        if (guard >= 16) return false;
        if (std.mem.eql(u8, c, behavior)) return true;
        cur = null;
        for (program.decls) |d| if (d == .behavior and std.mem.eql(u8, d.behavior.name, c)) {
            if (d.behavior.extends.len > 0) cur = d.behavior.extends[0];
            break;
        };
    }
    return false;
}

fn sameImplementations(a: []const ast.Implementation, b: []const ast.Implementation) bool {
    if (a.len != b.len) return false;
    for (a, b) |x, y| {
        if (x.target != y.target or x.inline_ != y.inline_ or x.result != y.result or x.needs_mask != y.needs_mask) return false;
        if (!std.mem.eql(u8, x.text, y.text)) return false;
        if ((x.template == null) != (y.template == null)) return false;
        if (x.template) |t| if (!std.mem.eql(u8, t, y.template.?)) return false;
        if ((x.cell == null) != (y.cell == null)) return false;
        if (x.cell) |c| if (c.kind != y.cell.?.kind or !std.mem.eql(u8, c.value, y.cell.?.value)) return false;
        if ((x.host == null) != (y.host == null)) return false;
        if (x.host) |h| if (h != y.host.?) return false;
    }
    return true;
}
