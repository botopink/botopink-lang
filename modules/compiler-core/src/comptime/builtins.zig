//! Decision 252 — the compiler's table of every builtin a program can call as
//! `@name(…)`, held to its declaration in `libs/std/src/builtins.d.bp` (or
//! `builtins_fns.d.bp`).
//!
//! Each row is one builtin the checker or a backend implements, with the
//! signature the declaration spells (`signature`, in `renderSignature`'s
//! canonical form) and how a call is held to it (`held`). The unit tests at the
//! foot of this file parse both declaration files and fail, naming the builtin,
//! when a row has no declaration, a declaration has no row, or the two
//! signatures differ — so the table and the documented surface cannot drift.
//!
//! The checker reads the declarations themselves (`Env.builtinDecls`, filled
//! by `comptime.zig` `registerBuiltinDecls`): a call to a builtin held
//! `.declaration` is refused when its arguments are not the declaration's
//! (`builtin-arguments`, `infer.zig` `checkBuiltinArguments`).
const std = @import("std");
const ast = @import("../ast.zig");
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;

/// How a call to the builtin is held to its declaration.
pub const Held = enum {
    /// Arity, labels and argument types are checked against the declaration
    /// (`infer.zig` `checkBuiltinArguments`).
    declaration,
    /// The builtin's own rule refuses, before the declaration is consulted,
    /// every call the declaration refuses (`@src`: no argument; `@typeInfo`:
    /// one declaration; `@getContext`: one type name inside a component;
    /// `@comptimeError`: the message it raises).
    own_rule,
    /// The declaration cannot spell what the compiler accepts; the call keeps
    /// today's acceptance until the front's open question (`question`) is
    /// answered.
    open_question,
};

pub const Builtin = struct {
    /// The name after `@` — `TypeInfo.all` for the static method of a type.
    name: []const u8,
    /// The declaration's signature in `renderSignature`'s canonical form.
    signature: []const u8,
    held: Held,
    /// For `.open_question`: the question's id in the milestone's
    /// `decisions-pending.md`.
    question: ?[]const u8 = null,
    /// Never reaches run time: evaluated while the program is checked or while
    /// a decorator / template body runs.
    comptime_only: bool = false,
};

/// Every `@name` builtin call the compiler implements.
pub const table = [_]Builtin{
    // ── run time ──
    .{ .name = "print", .signature = "print(value: unknown)", .held = .open_question, .question = "134-a" },
    .{ .name = "println", .signature = "println(value: unknown)", .held = .open_question, .question = "134-a" },
    .{ .name = "debug", .signature = "debug(value: unknown)", .held = .open_question, .question = "134-a" },
    .{ .name = "panic", .signature = "panic(message: string = \"panic\") -> noreturn", .held = .declaration },
    .{ .name = "todo", .signature = "todo(message: string = \"not implemented\") -> noreturn", .held = .declaration },
    .{ .name = "trap", .signature = "trap() -> noreturn", .held = .declaration },
    .{ .name = "block", .signature = "block<T>(body: fn() -> T) -> T", .held = .declaration },
    .{ .name = "module", .signature = "module() -> module", .held = .declaration },
    .{ .name = "getContext", .signature = "getContext<T>(comptime _: type) -> T", .held = .own_rule },
    // ── comptime only ──
    .{ .name = "field", .signature = "field<T, F>(obj: T, comptime name: string) -> F", .held = .declaration, .comptime_only = true },
    .{ .name = "src", .signature = "src() -> SourceLocation", .held = .own_rule, .comptime_only = true },
    .{ .name = "typeInfo", .signature = "typeInfo<T>(comptime _: type) -> TypeInfo<T>", .held = .own_rule, .comptime_only = true },
    .{ .name = "TypeInfo.all", .signature = "TypeInfo.all(with: Decorator | Decorator[], member: ?string = null) -> Declared<unknown>[]", .held = .declaration, .comptime_only = true },
    .{ .name = "TypeOf", .signature = "TypeOf<T>(value: T) -> T", .held = .declaration, .comptime_only = true },
    .{ .name = "makeRecord", .signature = "makeRecord<R>(fields: RecordField[]) -> R", .held = .declaration, .comptime_only = true },
    .{ .name = "RecordKeys", .signature = "RecordKeys(comptime _: type) -> string[]", .held = .declaration, .comptime_only = true },
    .{ .name = "comptimeError", .signature = "comptimeError(comptime message: string) -> noreturn", .held = .own_rule, .comptime_only = true },
    .{ .name = "emit", .signature = "emit(source: string)", .held = .declaration, .comptime_only = true },
    .{ .name = "compilerError", .signature = "compilerError(message: string) -> noreturn", .held = .declaration, .comptime_only = true },
    .{ .name = "expr", .signature = "expr<T>(comptime value: T) -> Expr<T>", .held = .declaration, .comptime_only = true },
    .{ .name = "code", .signature = "code<T>(text: string) -> Expr<T>", .held = .declaration, .comptime_only = true },
};

/// One builtin method of a builtin type, resolved by inference and lowered
/// inline by every backend (no run-time dispatch table).
pub const Method = struct {
    /// The declared type the method belongs to (`Result`).
    owner: []const u8,
    name: []const u8,
    /// The declaration's signature in `renderSignature`'s canonical form.
    signature: []const u8,
};

/// Every builtin method the compiler implements on a builtin type
/// (`infer.zig` `inferResultOptionMethod`), each held to its `declare fn`
/// inside the owner's declaration in `builtins.d.bp`.
pub const methods = [_]Method{
    .{ .owner = "Result", .name = "map", .signature = "map<R2>(self: Self<R, E>, transform: fn(R) -> R2) -> Result<R2, E>" },
    .{ .owner = "Result", .name = "flatMap", .signature = "flatMap<R2>(self: Self<R, E>, transform: fn(R) -> Result<R2, E>) -> Result<R2, E>" },
    .{ .owner = "Result", .name = "unwrapOr", .signature = "unwrapOr(self: Self<R, E>, fallback: R) -> R" },
    .{ .owner = "Result", .name = "isOk", .signature = "isOk(self: Self<R, E>) -> bool" },
    .{ .owner = "Result", .name = "isError", .signature = "isError(self: Self<R, E>) -> bool" },
};

/// True when `owner` has the builtin method `name` (a row of `methods`).
pub fn hasMethod(owner: []const u8, name: []const u8) bool {
    for (methods) |m| {
        if (std.mem.eql(u8, m.owner, owner) and std.mem.eql(u8, m.name, name)) return true;
    }
    return false;
}

/// The row of the builtin `@name`, or null when the compiler implements none.
pub fn find(name: []const u8) ?Builtin {
    for (table) |b| {
        if (std.mem.eql(u8, b.name, name)) return b;
    }
    return null;
}

/// True when the builtin's declaration answers `noreturn`.
pub fn neverReturns(name: []const u8) bool {
    const b = find(name) orelse return false;
    return std.mem.endsWith(u8, b.signature, " -> noreturn");
}

/// The canonical text of one declared signature: `name<G, …>(comptime p: T =
/// <default>, …) -> R`, with `-> R` left out when the declaration names no
/// return type. `owner` prefixes a static method (`TypeInfo.all`).
pub fn renderSignature(
    alloc: std.mem.Allocator,
    owner: ?[]const u8,
    name: []const u8,
    generic_params: []const ast.GenericParam,
    params: []const ast.Param,
    return_type: ?ast.TypeRef,
) ![]const u8 {
    var out: std.Io.Writer.Allocating = .init(alloc);
    const w = &out.writer;
    if (owner) |o| try w.print("{s}.", .{o});
    try w.writeAll(name);
    if (generic_params.len > 0) {
        try w.writeAll("<");
        for (generic_params, 0..) |g, i| try w.print("{s}{s}", .{ if (i > 0) ", " else "", g.name });
        try w.writeAll(">");
    }
    try w.writeAll("(");
    for (params, 0..) |p, i| {
        if (i > 0) try w.writeAll(", ");
        if (p.modifier == .@"comptime") try w.writeAll("comptime ");
        try w.print("{s}: {f}", .{ p.name, p.typeRef });
        if (p.default) |d| try w.print(" = {s}", .{defaultText(d)});
    }
    try w.writeAll(")");
    if (return_type) |rt| try w.print(" -> {f}", .{rt});
    return out.toOwnedSlice();
}

fn defaultText(e: ast.Expr) []const u8 {
    return switch (e) {
        .literal => |l| switch (l.kind) {
            .numberLit => |n| n,
            .null_ => "null",
            // The literal's lexeme without its quotes cannot be re-quoted
            // without an allocator; the string defaults are rendered by
            // `renderStringDefault` below.
            else => "<literal>",
        },
        .identifier => |id| switch (id.kind) {
            .ident => |n| n,
            else => "<expr>",
        },
        else => "<expr>",
    };
}

/// One declaration of the builtin surface, as `collectDeclared` reads it.
pub const Declared = struct {
    name: []const u8,
    signature: []const u8,
};

/// Every builtin declaration of `sources`: each top-level `declare fn`
/// (annotated — a `FnDecl` — or not — a `DelegateDecl`), and
/// each static `declare fn` (no `self`) inside a declared `type`, named
/// `<Type>.<fn>`. A string default is rendered with its quotes.
pub fn collectDeclared(alloc: std.mem.Allocator, sources: []const []const u8) ![]Declared {
    var out: std.ArrayListUnmanaged(Declared) = .empty;
    for (sources) |src| {
        var lx = Lexer.init(src);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const program = try p.parse(alloc);
        for (program.decls) |d| switch (d) {
            .@"fn" => |f| if (f.isDeclare) try out.append(alloc, .{
                .name = f.name,
                .signature = try quoteStringDefaults(alloc, try renderSignature(alloc, null, f.name, f.genericParams, f.params, f.returnType), f.params),
            }),
            // An unannotated `declare fn` parses as a delegate declaration.
            .delegate => |f| try out.append(alloc, .{
                .name = f.name,
                .signature = try quoteStringDefaults(alloc, try renderSignature(alloc, null, f.name, f.genericParams, f.params, f.returnType), f.params),
            }),
            .type_ => |t| for (t.methods) |m| {
                if (!m.is_declare) continue;
                if (m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self")) continue;
                try out.append(alloc, .{
                    .name = try std.fmt.allocPrint(alloc, "{s}.{s}", .{ t.name, m.name }),
                    .signature = try quoteStringDefaults(alloc, try renderSignature(alloc, t.name, m.name, m.genericParams, m.params, m.returnType), m.params),
                });
            },
            else => {},
        };
    }
    return out.items;
}

/// `renderSignature` writes `<literal>` for a string default; put the quoted
/// string in its place, one per string-defaulted parameter in order.
fn quoteStringDefaults(alloc: std.mem.Allocator, rendered: []const u8, params: []const ast.Param) ![]const u8 {
    var text = rendered;
    for (params) |p| {
        const d = p.default orelse continue;
        if (d != .literal or d.literal.kind != .stringLit) continue;
        const at = std.mem.indexOf(u8, text, "<literal>") orelse continue;
        text = try std.fmt.allocPrint(alloc, "{s}\"{s}\"{s}", .{ text[0..at], d.literal.kind.stringLit, text[at + "<literal>".len ..] });
    }
    return text;
}

/// One declared type of the builtin surface, as `collectTypes` reads it: its
/// members in canonical text — `f: T` for a record field or a behavior's
/// `val`, `V(f: T, …)` / `V` for a variant, `fn <signature>` for an instance
/// method (`self` first; a static one is a builtin call, `table`'s).
pub const DeclaredType = struct {
    name: []const u8,
    members: []const []const u8,
};

/// Every `type` and `behavior` of `sources`. A type alias whose target is an
/// internal `__Decl__X` name (the compiler's mirrors, `comptime.zig`) names
/// that type: `X` is reported under the alias, and every spelling of
/// `__Decl__X` in a member is read as the alias.
pub fn collectTypes(alloc: std.mem.Allocator, sources: []const []const u8) ![]DeclaredType {
    var out: std.ArrayListUnmanaged(DeclaredType) = .empty;
    const programs = try alloc.alloc(ast.Program, sources.len);
    var aliases: std.ArrayListUnmanaged([2][]const u8) = .empty;
    for (sources, programs) |src, *program| {
        var lx = Lexer.init(src);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        program.* = try p.parse(alloc);
        for (program.decls) |d| switch (d) {
            .typeAlias => |a| if (a.target == .named and std.mem.startsWith(u8, a.target.named, "__Decl__"))
                try aliases.append(alloc, .{ a.target.named, a.name }),
            else => {},
        };
    }
    for (programs) |program| {
        for (program.decls) |d| switch (d) {
            .type_ => |t| {
                var members: std.ArrayListUnmanaged([]const u8) = .empty;
                for (t.recordFields()) |f| try members.append(alloc, try std.fmt.allocPrint(alloc, "{s}: {f}", .{ f.name, f.typeRef }));
                for (t.variants()) |v| {
                    if (v.fields.len == 0) {
                        try members.append(alloc, v.name);
                        continue;
                    }
                    var text: std.Io.Writer.Allocating = .init(alloc);
                    try text.writer.print("{s}(", .{v.name});
                    for (v.fields, 0..) |f, i| try text.writer.print("{s}{s}: {f}", .{ if (i > 0) ", " else "", f.name, f.typeRef });
                    try text.writer.writeAll(")");
                    try members.append(alloc, try text.toOwnedSlice());
                }
                for (t.methods) |m| try appendInstanceMethod(alloc, &members, m);
                try out.append(alloc, .{ .name = t.name, .members = members.items });
            },
            .behavior => |b| {
                var members: std.ArrayListUnmanaged([]const u8) = .empty;
                for (b.fields) |f| try members.append(alloc, try std.fmt.allocPrint(alloc, "{s}: {f}", .{ f.name, f.typeRef }));
                for (b.methods) |m| try appendInstanceMethod(alloc, &members, m);
                try out.append(alloc, .{ .name = b.name, .members = members.items });
            },
            else => {},
        };
    }
    for (out.items) |*t| {
        for (aliases.items) |a| {
            if (std.mem.eql(u8, t.name, a[0])) t.name = a[1];
        }
        const members = try alloc.dupe([]const u8, t.members);
        for (members) |*m| {
            for (aliases.items) |a| m.* = try std.mem.replaceOwned(u8, alloc, m.*, a[0], a[1]);
        }
        t.members = members;
    }
    return out.items;
}

fn appendInstanceMethod(alloc: std.mem.Allocator, members: *std.ArrayListUnmanaged([]const u8), m: ast.BehaviorMethod) !void {
    if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) return;
    try members.append(alloc, try std.fmt.allocPrint(alloc, "fn {s}", .{try renderSignature(alloc, null, m.name, m.genericParams, m.params, m.returnType)}));
}

/// One way a compiler mirror or a builtin method and the declarations
/// disagree, naming the type.
pub const TypeDrift = union(enum) {
    /// The compiler registers type `name` (a mirror) and no declaration names it.
    undeclared: []const u8,
    /// Both name the type, and `member` is in one and not the other —
    /// `in_mirror` tells which.
    member: struct { type_name: []const u8, member: []const u8, in_mirror: bool },
    /// A row of `methods` the owner's declaration does not declare with that
    /// signature, or an instance method of a `methods` owner with no row.
    method: struct { owner: []const u8, name: []const u8, table: ?[]const u8, declared: ?[]const u8 },
};

/// Every disagreement between the compiler's mirrors (`mirror_sources`) plus the
/// builtin `methods`, and the declarations of `sources`.
pub fn typeDrift(alloc: std.mem.Allocator, sources: []const []const u8, mirror_sources: []const []const u8) ![]TypeDrift {
    const declared = try collectTypes(alloc, sources);
    const mirrored = try collectTypes(alloc, mirror_sources);
    var out: std.ArrayListUnmanaged(TypeDrift) = .empty;
    for (mirrored) |m| {
        const d = findType(declared, m.name) orelse {
            try out.append(alloc, .{ .undeclared = m.name });
            continue;
        };
        for (m.members) |member| if (!contains(d.members, member))
            try out.append(alloc, .{ .member = .{ .type_name = m.name, .member = member, .in_mirror = true } });
        for (d.members) |member| if (!contains(m.members, member))
            try out.append(alloc, .{ .member = .{ .type_name = m.name, .member = member, .in_mirror = false } });
    }
    for (methods) |row| {
        const want = try std.fmt.allocPrint(alloc, "fn {s}", .{row.signature});
        const d = findType(declared, row.owner);
        const got: ?[]const u8 = if (d) |t| for (t.members) |member| {
            if (std.mem.startsWith(u8, member, "fn ") and std.mem.eql(u8, methodName(member), row.name)) break member["fn ".len..];
        } else null else null;
        if (got == null or !std.mem.eql(u8, want, try std.fmt.allocPrint(alloc, "fn {s}", .{got.?})))
            try out.append(alloc, .{ .method = .{ .owner = row.owner, .name = row.name, .table = row.signature, .declared = got } });
    }
    for (declared) |t| {
        const owns = for (methods) |row| {
            if (std.mem.eql(u8, row.owner, t.name)) break true;
        } else false;
        if (!owns) continue;
        for (t.members) |member| {
            if (!std.mem.startsWith(u8, member, "fn ")) continue;
            if (!hasMethod(t.name, methodName(member)))
                try out.append(alloc, .{ .method = .{ .owner = t.name, .name = methodName(member), .table = null, .declared = member["fn ".len..] } });
        }
    }
    return out.items;
}

fn findType(types: []const DeclaredType, name: []const u8) ?DeclaredType {
    for (types) |t| {
        if (std.mem.eql(u8, t.name, name)) return t;
    }
    return null;
}

fn contains(items: []const []const u8, item: []const u8) bool {
    for (items) |i| {
        if (std.mem.eql(u8, i, item)) return true;
    }
    return false;
}

/// The name of an `fn <signature>` member.
fn methodName(member: []const u8) []const u8 {
    const rest = member["fn ".len..];
    const end = std.mem.indexOfAny(u8, rest, "<(") orelse rest.len;
    return rest[0..end];
}

fn printTypeDrift(items: []const TypeDrift) void {
    for (items) |item| switch (item) {
        .undeclared => |n| std.debug.print("builtin type `{s}` is registered by the compiler (comptime.zig) and builtins.d.bp does not declare it\n", .{n}),
        .member => |m| if (m.in_mirror)
            std.debug.print("builtin type `{s}`: the compiler registers `{s}`, builtins.d.bp does not declare it\n", .{ m.type_name, m.member })
        else
            std.debug.print("builtin type `{s}`: builtins.d.bp declares `{s}`, the compiler does not register it\n", .{ m.type_name, m.member }),
        .method => |m| std.debug.print("builtin method `{s}.{s}`: the compiler implements `{s}`, builtins.d.bp declares `{s}`\n", .{ m.owner, m.name, m.table orelse "(nothing)", m.declared orelse "(nothing)" }),
    };
}

/// One way the table and the declarations disagree, naming the builtin.
pub const Drift = union(enum) {
    /// The compiler implements `@name` and no declaration names it.
    undeclared: []const u8,
    /// A declaration names `@name` and the compiler implements none.
    unimplemented: []const u8,
    /// Both name it, with different signatures.
    signature: struct { name: []const u8, table: []const u8, declared: []const u8 },
};

/// Every disagreement between `table` and the declarations of `sources`.
pub fn drift(alloc: std.mem.Allocator, sources: []const []const u8) ![]Drift {
    const declared = try collectDeclared(alloc, sources);
    var out: std.ArrayListUnmanaged(Drift) = .empty;
    for (table) |b| {
        const d = for (declared) |d| {
            if (std.mem.eql(u8, d.name, b.name)) break d;
        } else {
            try out.append(alloc, .{ .undeclared = b.name });
            continue;
        };
        if (!std.mem.eql(u8, d.signature, b.signature))
            try out.append(alloc, .{ .signature = .{ .name = b.name, .table = b.signature, .declared = d.signature } });
    }
    for (declared) |d| {
        if (find(d.name) == null) try out.append(alloc, .{ .unimplemented = d.name });
    }
    return out.items;
}

fn printDrift(items: []const Drift) void {
    for (items) |item| switch (item) {
        .undeclared => |n| std.debug.print("builtin `@{s}` is implemented (comptime/builtins.zig) and builtins.d.bp does not declare it\n", .{n}),
        .unimplemented => |n| std.debug.print("builtins.d.bp declares `@{s}` and the compiler implements no such builtin\n", .{n}),
        .signature => |s| std.debug.print("builtin `@{s}`: the compiler implements `{s}`, builtins.d.bp declares `{s}`\n", .{ s.name, s.table, s.declared }),
    };
}

const prelude = @import("std_prelude");

test "builtins: every implemented builtin is declared, every declaration implemented, signatures equal" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const items = try drift(arena.allocator(), &.{ prelude.builtins, prelude.builtin_fns });
    printDrift(items);
    try std.testing.expectEqual(@as(usize, 0), items.len);
}

test "builtins: an open question names its id, and only an open question does" {
    for (table) |b| {
        try std.testing.expectEqual(b.held == .open_question, b.question != null);
    }
}

test "builtins: a removed declaration is named as undeclared" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const removed = try std.mem.replaceOwned(u8, a, prelude.builtins, "pub declare fn trap() -> noreturn;", "");
    const items = try drift(a, &.{ removed, prelude.builtin_fns });
    try std.testing.expectEqual(@as(usize, 1), items.len);
    try std.testing.expectEqualStrings("trap", items[0].undeclared);
}

test "builtins: a changed signature is named with both spellings" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const changed = try std.mem.replaceOwned(u8, a, prelude.builtins, "pub declare fn emit(source: string);", "pub declare fn emit(source: string, again: bool);");
    const items = try drift(a, &.{ changed, prelude.builtin_fns });
    try std.testing.expectEqual(@as(usize, 1), items.len);
    try std.testing.expectEqualStrings("emit", items[0].signature.name);
    try std.testing.expectEqualStrings("emit(source: string, again: bool)", items[0].signature.declared);
}

test "builtins: a declaration the compiler does not implement is named" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const extra = try std.mem.concat(a, u8, &.{ prelude.builtins, "\npub declare fn frobnicate() -> i32;\n" });
    const items = try drift(a, &.{ extra, prelude.builtin_fns });
    try std.testing.expectEqual(@as(usize, 1), items.len);
    try std.testing.expectEqualStrings("frobnicate", items[0].unimplemented);
}

const type_mirrors = @import("../comptime.zig").builtin_type_mirrors;

test "builtins: every type the compiler mirrors is declared alike, every builtin method declared" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const items = try typeDrift(arena.allocator(), &.{ prelude.builtins, prelude.builtin_fns }, &type_mirrors);
    printTypeDrift(items);
    try std.testing.expectEqual(@as(usize, 0), items.len);
}

test "builtins: a mirrored field the declaration lacks is named" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const changed = try std.mem.replaceOwned(u8, a, prelude.builtins, "    fnName: string,\n)", "    fnName: string,\n    offset: i32,\n)");
    const items = try typeDrift(a, &.{ changed, prelude.builtin_fns }, &type_mirrors);
    try std.testing.expectEqual(@as(usize, 1), items.len);
    try std.testing.expectEqualStrings("SourceLocation", items[0].member.type_name);
    try std.testing.expectEqualStrings("offset: i32", items[0].member.member);
    try std.testing.expect(!items[0].member.in_mirror);
}

test "builtins: a mirror spelled under another name than its declaration is named" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    // The reflection record a handle's `annotations` hold was mirrored as
    // `Annotation` while `builtins.d.bp` declares `DeclAnnotation`.
    const renamed = try std.mem.replaceOwned(u8, a, prelude.builtins, "pub type DeclAnnotation(", "pub type ReflectedAnnotation(");
    const items = try typeDrift(a, &.{ renamed, prelude.builtin_fns }, &type_mirrors);
    var undeclared: usize = 0;
    for (items) |item| if (item == .undeclared) {
        try std.testing.expectEqualStrings("DeclAnnotation", item.undeclared);
        undeclared += 1;
    };
    try std.testing.expectEqual(@as(usize, 1), undeclared);
}

test "builtins: a builtin method declared with another signature, or not at all, is named" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const changed = try std.mem.replaceOwned(u8, a, prelude.builtins, "declare fn isOk(self: Self<R, E>) -> bool;", "declare fn isOk(self: Self<R, E>) -> i32;");
    const items = try typeDrift(a, &.{ changed, prelude.builtin_fns }, &type_mirrors);
    try std.testing.expectEqual(@as(usize, 1), items.len);
    try std.testing.expectEqualStrings("isOk", items[0].method.name);
    try std.testing.expectEqualStrings("isOk(self: Self<R, E>) -> i32", items[0].method.declared.?);
    const removed = try std.mem.replaceOwned(u8, a, prelude.builtins, "declare fn isError(self: Self<R, E>) -> bool;", "");
    const gone = try typeDrift(a, &.{ removed, prelude.builtin_fns }, &type_mirrors);
    try std.testing.expectEqual(@as(usize, 1), gone.len);
    try std.testing.expect(gone[0].method.declared == null);
    const extra = try std.mem.replaceOwned(u8, a, prelude.builtins, "declare fn isError(self: Self<R, E>) -> bool;", "declare fn isError(self: Self<R, E>) -> bool;\n    declare fn swap(self: Self<R, E>) -> Result<E, R>;");
    const more = try typeDrift(a, &.{ extra, prelude.builtin_fns }, &type_mirrors);
    try std.testing.expectEqual(@as(usize, 1), more.len);
    try std.testing.expectEqualStrings("swap", more[0].method.name);
    try std.testing.expect(more[0].method.table == null);
}
