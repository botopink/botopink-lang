//! Decision 216 (4) — `@TypeInfo.all(with: d)`: the declarations of the
//! program that carry the decorator `d`, answered at compile time so an entry
//! point builds its catalogue explicitly (no module registers itself at load).
//!
//! The answer is an array literal of the prelude record `Declared<T>`
//! (`comptime.zig` `decl_reflection_src`):
//!
//!     Declared<unknown>(name: "about", module: "app/about",
//!              meta: [DeclaredMeta(key: "path", value: "/about")],
//!              returnTypeName: "string", value: about)
//!
//! `meta` is what `d` set on the declaration (`decl.setMeta`), in set order.
//! `returnTypeName` is a function's declared return type as the source spells
//! it, `""` for a type (decision 256), so a catalogue can be keyed by the type
//! a provider answers.
//! `value` is the function itself for a function, and for a `type` or a
//! `behavior` a thunk `{ -> T.<member>() }` calling the associated fn the
//! query names (`member: "register"`): a type is no value. Every entry is
//! built as `Declared<unknown>(…)`, so the answer is `Declared<unknown>[]`
//! whatever the program declares (decision 254) and a use narrows `value`
//! with `is`.
//!
//! **What it sees.** Every module of the build — the root package, its
//! dependencies and std — that does not itself read `@TypeInfo.all`, plus the
//! reading module's own declarations. A module that reads it is analysed after
//! every other one (`comptime.zig` `orderReaders`), and no module may import
//! it: the reader answers for the whole program, so nothing it reports can
//! depend on it (`typeinfo-all-imported`, at the import). A declaration of
//! another module is reached through an import the answer adds, so it is
//! `pub` (`typeinfo-all-private`).
//!
//! **Order.** By module path (byte order), then by declaration order inside a
//! module — the order decorators ran in, which is source order.
//!
//! **A list** (decision 235). `with: [a, b]` answers every declaration carrying
//! any of them, in that one order, a declaration carrying two of them once
//! (at its first recording); its `meta` is what the listed decorators set, in
//! set order. A name listed twice is `typeinfo-all-arguments`.
//!
//! The pass works in two halves. `collect` finds the queries of a parsed
//! module, which makes its first analysis stop before bodies (like a module
//! whose decorators contributed code). After the first analysis has run the
//! module's own decorators, `plan` resolves each query against the session's
//! reflection into the array expression (keyed by the call's loc, which
//! inference splices through `Env.srcRewrites`) and the import declarations
//! the expression needs, both handed to the re-analysis.
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const reflectionMod = @import("reflection.zig");
const diagnostics = @import("diagnostics.zig");
const TypeError = @import("error.zig").TypeError;
const Lexer = @import("../lexer.zig").Lexer;
const Token = @import("../lexer.zig").Token;
const Parser = @import("../parser.zig").Parser;

const Error = error{OutOfMemory};

/// The builtin's callee as the parser records it (`@TypeInfo.all(…)`).
pub const callee = "TypeInfo.all";

/// One `@TypeInfo.all(…)` call of a module.
pub const Query = struct {
    loc: ast.Loc,
    args: []const ast.CallArg,
};

const Collector = struct {
    arena: std.mem.Allocator,
    found: std.ArrayListUnmanaged(Query) = .empty,

    fn walk(self: *Collector, comptime T: type, ptr: *const T) Error!void {
        if (T == ast.Expr) {
            if (ptr.* == .call and ptr.call.kind == .call) {
                const c = ptr.call.kind.call;
                if (c.is_builtin and std.mem.eql(u8, c.callee, callee)) try self.found.append(self.arena, .{ .loc = ptr.call.loc, .args = c.args });
            }
        }
        if (T == ast.ImportDecl) return;
        switch (@typeInfo(T)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldExpr(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                        try self.walk(@TypeOf(payload.*), payload);
                    },
                }
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) try self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, e);
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*e| try self.walk(arr.child, e);
            },
            else => {},
        }
    }
};

fn mayHoldExpr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque" => false,
        .pointer => |p| if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else if (p.size == .slice) mayHoldExpr(p.child) else true,
        else => true,
    };
}

/// Every `@TypeInfo.all(…)` of `program`, in source order.
pub fn collect(arena: std.mem.Allocator, program: ast.Program) Error![]const Query {
    var c = Collector{ .arena = arena };
    for (program.decls) |*d| try c.walk(ast.DeclKind, d);
    return c.found.items;
}

/// True when `program` calls `@TypeInfo.all` — the test `comptime.zig`
/// orders the build's modules by. It reads the parse, never the text: a
/// comment or a string literal spelling `@TypeInfo.all` reads nothing.
pub fn reads(arena: std.mem.Allocator, program: ast.Program) Error!bool {
    return (try collect(arena, program)).len > 0;
}

/// What the re-analysis of a reading module receives.
pub const Plan = struct {
    /// The import declarations the answers reach other modules through.
    imports: []const ast.DeclKind = &.{},
    /// Call loc → the array expression answering it.
    rewrites: std.AutoHashMapUnmanaged(ast.Loc, *const ast.Expr) = .empty,
};

pub const Outcome = union(enum) {
    ok: Plan,
    refused: TypeError,
};

/// The decorator a query's `with:` names.
const Decorator = struct { owner: []const u8, name: []const u8 };

/// A string as the text of a string literal (the escapes a backend emits).
fn quoted(out: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, text: []const u8) Error!void {
    try out.append(arena, '"');
    for (text) |ch| switch (ch) {
        '\\' => try out.appendSlice(arena, "\\\\"),
        '"' => try out.appendSlice(arena, "\\\""),
        '\n' => try out.appendSlice(arena, "\\n"),
        '\t' => try out.appendSlice(arena, "\\t"),
        '\r' => try out.appendSlice(arena, "\\r"),
        else => try out.append(arena, ch),
    };
    try out.append(arena, '"');
}

fn refuse(arena: std.mem.Allocator, loc: ast.Loc, comptime fmt: []const u8, args: anytype, hint: []const u8) Error!Outcome {
    return .{ .refused = TypeError.custom(try std.fmt.allocPrint(arena, fmt, args), hint).withLoc(loc) };
}

/// Resolve every query of a reading module. `env` is the module's first
/// analysis (its imports bound, its decorators run); `program` its parse;
/// `first_line` where the generated code's tokens start (after everything the
/// module's other contributions occupy — no two lowerings share a location).
pub fn plan(
    arena: std.mem.Allocator,
    env: *const envMod.Env,
    program: ast.Program,
    module_path: []const u8,
    reflection: *const reflectionMod.Reflection,
    queries: []const Query,
    first_line: usize,
) Error!Outcome {
    var out: Plan = .{};
    var imports: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var line = first_line;
    var alias_seq: usize = 0;
    const arguments_hint = "Write `@TypeInfo.all(with: <decorator>)` for functions, `@TypeInfo.all(with: <decorator>, member: \"<associated fn>\")` for types.";

    for (queries) |q| {
        // ── the arguments ─────────────────────────────────────────────────
        var with: ?*const ast.Expr = null;
        var member: ?[]const u8 = null;
        for (q.args) |a| {
            const label = a.label orelse return refuse(arena, q.loc, "{s}: `@TypeInfo.all` takes labelled arguments, and this one has none", .{diagnostics.typeinfo_all_arguments}, arguments_hint);
            if (std.mem.eql(u8, label, "with") and with == null) {
                with = a.value;
            } else if (std.mem.eql(u8, label, "member") and member == null) {
                if (a.value.* != .literal or a.value.literal.kind != .stringLit)
                    return refuse(arena, q.loc, "{s}: `member:` names an associated fn with a string literal", .{diagnostics.typeinfo_all_arguments}, arguments_hint);
                member = a.value.literal.kind.stringLit;
            } else return refuse(arena, q.loc, "{s}: `@TypeInfo.all` has no argument `{s}:` (or it is written twice)", .{ diagnostics.typeinfo_all_arguments, label }, arguments_hint);
        }
        const with_expr = with orelse return refuse(arena, q.loc, "{s}: `@TypeInfo.all` needs `with:`, the decorator its declarations carry", .{diagnostics.typeinfo_all_arguments}, arguments_hint);

        // ── the decorators ───────────────────────────────────────────────
        // Decision 235 — `with:` names one decorator or a list of them
        // (`with: [component, service]`): one answer, in the one order, a
        // declaration carrying two of them once.
        const with_items: []const ast.Expr = switch (with_expr.*) {
            .collection => |c| switch (c.kind) {
                .arrayLit => |al| if (al.spread == null and al.spreadExpr == null and al.elems.len > 0)
                    al.elems
                else
                    return refuse(arena, q.loc, "{s}: `with:` lists one or more decorators by name, with no spread", .{diagnostics.typeinfo_all_arguments}, arguments_hint),
                else => @as(*const [1]ast.Expr, with_expr)[0..1],
            },
            else => @as(*const [1]ast.Expr, with_expr)[0..1],
        };
        var decorators: std.ArrayListUnmanaged(Decorator) = .empty;
        // Decision 268 — an item that names no decorator leaves the query
        // unanswered: inference holds `with:` to its declared type
        // (`Decorator | Decorator[]`) and refuses it as the ordinary mismatch
        // at the argument (`infer.zig` `checkCatalogueArguments`).
        const answered = for (with_items) |*item| {
            const spelled: []const u8 = switch (item.*) {
                .identifier => |id| switch (id.kind) {
                    .ident => |n| n,
                    .identAccess => |ia| if (ia.receiver.* == .identifier and ia.receiver.identifier.kind == .ident)
                        try std.fmt.allocPrint(arena, "{s}.{s}", .{ ia.receiver.identifier.kind.ident, ia.member })
                    else
                        "",
                    else => "",
                },
                else => "",
            };
            const decorator: Decorator = found: {
                for (program.decls) |d| switch (d) {
                    .@"fn" => |f| if (std.mem.eql(u8, f.name, spelled) and f.params.len > 0 and f.params[0].typeRef.isDeclType() and f.body.len > 0)
                        break :found .{ .owner = module_path, .name = f.name },
                    else => {},
                };
                if (env.decorators.get(spelled)) |sig| if (sig.fn_decl) |dfn| if (dfn.body.len > 0)
                    break :found .{ .owner = env.comptimeOwnerOf(dfn), .name = dfn.name };
                break false;
            };
            for (decorators.items) |seen| if (std.mem.eql(u8, seen.owner, decorator.owner) and std.mem.eql(u8, seen.name, decorator.name))
                return refuse(arena, q.loc, "{s}: `with:` lists `{s}` twice", .{ diagnostics.typeinfo_all_arguments, spelled }, arguments_hint);
            try decorators.append(arena, decorator);
        } else true;
        if (!answered) continue;
        // How the refusals name the query's decorators: `#[a]`, `#[a]/#[b]`.
        var label_buf: std.ArrayListUnmanaged(u8) = .empty;
        for (decorators.items, 0..) |d, i| {
            if (i > 0) try label_buf.append(arena, '/');
            try label_buf.print(arena, "#[{s}]", .{d.name});
        }
        const label = label_buf.items;

        // ── the declarations ─────────────────────────────────────────────
        var entries: std.ArrayListUnmanaged(reflectionMod.DeclaredEntry) = .empty;
        for (reflection.declared.items) |e| {
            const listed = for (decorators.items) |d| {
                if (std.mem.eql(u8, e.decorator_owner, d.owner) and std.mem.eql(u8, e.decorator_name, d.name)) break true;
            } else false;
            if (!listed) continue;
            const own = std.mem.eql(u8, e.module, module_path);
            if (!own and reflection.readers.contains(e.module)) continue;
            const again = for (entries.items) |prev| {
                if (std.mem.eql(u8, prev.module, e.module) and std.mem.eql(u8, prev.name, e.name)) break true;
            } else false;
            if (again) continue;
            try entries.append(arena, e);
        }
        std.mem.sort(reflectionMod.DeclaredEntry, entries.items, {}, struct {
            fn lessThan(_: void, a: reflectionMod.DeclaredEntry, b: reflectionMod.DeclaredEntry) bool {
                return switch (std.mem.order(u8, a.module, b.module)) {
                    .lt => true,
                    .gt => false,
                    .eq => a.seq < b.seq,
                };
            }
        }.lessThan);

        var fns: usize = 0;
        for (entries.items) |e| {
            if (e.kind == .function) fns += 1;
        }
        if (fns > 0 and fns < entries.items.len) {
            const first_fn, const first_type = blk: {
                var f: []const u8 = "";
                var t: []const u8 = "";
                for (entries.items) |e| {
                    if (e.kind == .function and f.len == 0) f = e.name;
                    if (e.kind != .function and t.len == 0) t = e.name;
                }
                break :blk .{ f, t };
            };
            return refuse(arena, q.loc, "{s}: `{s}` is carried by the function `{s}` and by the type `{s}`, and one query answers one kind of value", .{ diagnostics.typeinfo_all_mixed, label, first_fn, first_type }, "Catalogue functions and types with two decorators, or two queries.");
        }
        const of_types = entries.items.len > fns;
        if (of_types and member == null) {
            return refuse(arena, q.loc, "{s}: `{s}` is carried by the type `{s}`, and a type is no value: name the associated fn each entry calls", .{ diagnostics.typeinfo_all_needs_member, label, entries.items[0].name }, "Write `@TypeInfo.all(with: <decorator>, member: \"<associated fn>\")`; each `value` is then `{ -> T.<associated fn>() }`.");
        }
        if (!of_types and member != null and entries.items.len > 0) {
            return refuse(arena, q.loc, "{s}: `{s}` is carried by functions, and `member:` names an associated fn of a type", .{ diagnostics.typeinfo_all_arguments, label }, "A function's entry is the function itself; leave `member:` out.");
        }
        for (entries.items) |e| {
            if (!std.mem.eql(u8, e.module, module_path) and !e.isPub)
                return refuse(arena, q.loc, "{s}: `{s}` of `{s}` carries `{s}` and is not `pub`, so the catalogue cannot reach it", .{ diagnostics.typeinfo_all_private, e.name, e.module, label }, "Make the declaration `pub`: the entry point reaches every declaration it catalogues through an import.");
        }

        // ── the answer ───────────────────────────────────────────────────
        var text: std.ArrayListUnmanaged(u8) = .empty;
        try text.append(arena, '[');
        for (entries.items, 0..) |e, i| {
            if (i > 0) try text.appendSlice(arena, ", ");
            const ref: []const u8 = if (std.mem.eql(u8, e.module, module_path)) e.name else ref: {
                const alias = try std.fmt.allocPrint(arena, "__bp_ti_{d}", .{alias_seq});
                alias_seq += 1;
                var imp: std.ArrayListUnmanaged(u8) = .empty;
                try imp.print(arena, "import {{{s} as {s}}} from ", .{ e.name, alias });
                try quoted(&imp, arena, e.module);
                try imp.append(arena, ';');
                var lx = Lexer.init(imp.items);
                const toks = lx.scanAll(arena) catch return error.OutOfMemory;
                var p = Parser.init(toks);
                const parsed = p.parse(arena) catch return error.OutOfMemory;
                try imports.appendSlice(arena, parsed.decls);
                break :ref alias;
            };
            try text.appendSlice(arena, "Declared<unknown>(name: ");
            try quoted(&text, arena, e.name);
            try text.appendSlice(arena, ", module: ");
            try quoted(&text, arena, e.module);
            try text.appendSlice(arena, ", meta: [");
            var first = true;
            for (try reflection.metaOf(arena, e.module, e.name)) |m| {
                const listed = for (decorators.items) |d| {
                    if (std.mem.eql(u8, m.decorator, d.name)) break true;
                } else false;
                if (!listed) continue;
                if (!first) try text.appendSlice(arena, ", ");
                first = false;
                try text.appendSlice(arena, "DeclaredMeta(key: ");
                try quoted(&text, arena, m.key);
                try text.appendSlice(arena, ", value: ");
                try quoted(&text, arena, m.value);
                try text.append(arena, ')');
            }
            try text.appendSlice(arena, "], returnTypeName: ");
            try quoted(&text, arena, e.returnTypeName);
            try text.appendSlice(arena, ", value: ");
            if (of_types) {
                try text.print(arena, "{{ -> {s}.{s}() }}", .{ ref, member.? });
            } else try text.appendSlice(arena, ref);
            try text.append(arena, ')');
        }
        try text.append(arena, ']');

        // `val __bp_ti = <answer>;`, its tokens on lines of their own.
        const prefix = "val __bp_ti = ";
        const src = try std.fmt.allocPrint(arena, "{s}{s};", .{ prefix, text.items });
        var lx = Lexer.init(src);
        const tokens = try arena.dupe(Token, lx.scanAll(arena) catch return error.OutOfMemory);
        for (tokens) |*t| t.line += line;
        line += 1;
        var p = Parser.init(tokens);
        const parsed = p.parse(arena) catch return error.OutOfMemory;
        if (parsed.decls.len != 1 or parsed.decls[0] != .val) return error.OutOfMemory;
        try out.rewrites.put(arena, q.loc, parsed.decls[0].val.value);
    }
    out.imports = imports.items;
    return .{ .ok = out };
}

fn readsSource(arena: std.mem.Allocator, source: []const u8) !bool {
    var lx = Lexer.init(source);
    const toks = try lx.scanAll(arena);
    var p = Parser.init(toks);
    return reads(arena, try p.parse(arena));
}

test "typeinfo.all: a reader is a module that calls it" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    try std.testing.expect(try readsSource(arena, "val x = @TypeInfo.all(with: d);"));
    try std.testing.expect(try readsSource(arena, "fn f() -> i32 { return @TypeInfo.all(with: d).length; }"));
    try std.testing.expect(!try readsSource(arena, "// @TypeInfo.all(with: d)\nval x = 1;"));
    try std.testing.expect(!try readsSource(arena, "val x = @typeInfo(City).name;"));
}

test "typeinfo.all: a string literal spelling it reads nothing" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    try std.testing.expect(!try readsSource(arena,
        \\pub fn hint() -> string {
        \\    return "write @TypeInfo.all(with: d) in the entry point";
        \\}
    ));
}
