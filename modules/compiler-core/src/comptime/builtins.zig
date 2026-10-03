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
    /// one declaration; `@TypeInfo.all`: the catalogue's labelled arguments;
    /// `@getContext`: one type name inside a component; `@comptimeError`:
    /// the message it raises).
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
    .{ .name = "TypeInfo.all", .signature = "TypeInfo.all(with: unknown, member: ?string = null) -> Declared<unknown>[]", .held = .own_rule, .comptime_only = true },
    .{ .name = "TypeOf", .signature = "TypeOf<T>(value: T) -> T", .held = .declaration, .comptime_only = true },
    .{ .name = "makeRecord", .signature = "makeRecord<R>(fields: RecordField[]) -> R", .held = .declaration, .comptime_only = true },
    .{ .name = "RecordKeys", .signature = "RecordKeys(comptime _: type) -> string[]", .held = .declaration, .comptime_only = true },
    .{ .name = "comptimeError", .signature = "comptimeError(comptime message: string) -> noreturn", .held = .own_rule, .comptime_only = true },
    .{ .name = "emit", .signature = "emit(source: string)", .held = .declaration, .comptime_only = true },
    .{ .name = "compilerError", .signature = "compilerError(message: string) -> noreturn", .held = .declaration, .comptime_only = true },
    .{ .name = "expr", .signature = "expr<T>(comptime value: T) -> Expr<T>", .held = .declaration, .comptime_only = true },
    .{ .name = "code", .signature = "code<T>(text: string) -> Expr<T>", .held = .declaration, .comptime_only = true },
};

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
