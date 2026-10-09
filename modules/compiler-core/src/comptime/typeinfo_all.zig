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

/// Decision 353 — a template function: one whose return type is `@Expr<…>`
/// or `@ExprCustom<…>` (what `infer.zig` registers in `Env.templateFns`).
pub fn isTemplateFn(f: ast.FnDecl) bool {
    const rt = f.returnType orelse return false;
    return rt.isTemplateReturnType();
}

/// Every `@TypeInfo.all(…)` of `program` outside a template function's body,
/// in source order: the queries that make the module a reader. A template
/// body's query is answered where the template is expanded
/// (`collectTemplates`, decision 353).
pub fn collect(arena: std.mem.Allocator, program: ast.Program) Error![]const Query {
    var c = Collector{ .arena = arena };
    for (program.decls) |*d| {
        if (d.* == .@"fn" and isTemplateFn(d.@"fn")) continue;
        try c.walk(ast.DeclKind, d);
    }
    return c.found.items;
}

/// The queries of one template function's body (decision 353).
pub const TemplateQueries = struct { name: []const u8, queries: []const Query };

/// Every template function of `program` whose body calls `@TypeInfo.all`,
/// with its queries in source order.
pub fn collectTemplates(arena: std.mem.Allocator, program: ast.Program) Error![]const TemplateQueries {
    var out: std.ArrayListUnmanaged(TemplateQueries) = .empty;
    for (program.decls) |*d| {
        if (d.* != .@"fn" or !isTemplateFn(d.@"fn")) continue;
        var c = Collector{ .arena = arena };
        try c.walk(ast.DeclKind, d);
        if (c.found.items.len > 0) try out.append(arena, .{ .name = d.@"fn".name, .queries = c.found.items });
    }
    return out.items;
}

/// True when `program` calls `@TypeInfo.all` outside a template function's
/// body — the test `comptime.zig` orders the build's modules by. It reads the
/// parse, never the text: a comment or a string literal spelling
/// `@TypeInfo.all` reads nothing, and a template body's query makes no reader
/// (decision 353: it answers for the program that expands the template).
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
const Decorator = reflectionMod.DecoratorId;
const Resolved = reflectionMod.TemplateQuery;

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

fn refusal(arena: std.mem.Allocator, loc: ast.Loc, comptime fmt: []const u8, args: anytype, hint: []const u8) Error!TypeError {
    return TypeError.custom(try std.fmt.allocPrint(arena, fmt, args), hint).withLoc(loc);
}

const arguments_hint = "Write `@TypeInfo.all(with: <decorator>)` for functions, `@TypeInfo.all(with: <decorator>, member: \"<associated fn>\")` for types.";

pub const Resolution = union(enum) {
    ok: Resolved,
    /// `with:` names no decorator: inference holds the call to its
    /// declaration (decision 268) and refuses the argument.
    unanswered,
    refused: TypeError,
};

/// One query's arguments, its decorators identified in the module that writes
/// it: `program` and `env` are that module's (its imports bound), `module_path`
/// its path.
pub fn resolve(
    arena: std.mem.Allocator,
    env: *const envMod.Env,
    program: ast.Program,
    module_path: []const u8,
    q: Query,
) Error!Resolution {
    var with: ?*const ast.Expr = null;
    var member: ?[]const u8 = null;
    for (q.args) |a| {
        const label = a.label orelse return .{ .refused = try refusal(arena, q.loc, "{s}: `@TypeInfo.all` takes labelled arguments, and this one has none", .{diagnostics.typeinfo_all_arguments}, arguments_hint) };
        if (std.mem.eql(u8, label, "with") and with == null) {
            with = a.value;
        } else if (std.mem.eql(u8, label, "member") and member == null) {
            if (a.value.* != .literal or a.value.literal.kind != .stringLit)
                return .{ .refused = try refusal(arena, q.loc, "{s}: `member:` names an associated fn with a string literal", .{diagnostics.typeinfo_all_arguments}, arguments_hint) };
            member = a.value.literal.kind.stringLit;
        } else return .{ .refused = try refusal(arena, q.loc, "{s}: `@TypeInfo.all` has no argument `{s}:` (or it is written twice)", .{ diagnostics.typeinfo_all_arguments, label }, arguments_hint) };
    }
    const with_expr = with orelse return .{ .refused = try refusal(arena, q.loc, "{s}: `@TypeInfo.all` needs `with:`, the decorator its declarations carry", .{diagnostics.typeinfo_all_arguments}, arguments_hint) };

    // Decision 235 — `with:` names one decorator or a list of them
    // (`with: [component, service]`): one answer, in the one order, a
    // declaration carrying two of them once.
    const with_items: []const ast.Expr = switch (with_expr.*) {
        .collection => |c| switch (c.kind) {
            .arrayLit => |al| if (al.spread == null and al.spreadExpr == null and al.elems.len > 0)
                al.elems
            else
                return .{ .refused = try refusal(arena, q.loc, "{s}: `with:` lists one or more decorators by name, with no spread", .{diagnostics.typeinfo_all_arguments}, arguments_hint) },
            else => @as(*const [1]ast.Expr, with_expr)[0..1],
        },
        else => @as(*const [1]ast.Expr, with_expr)[0..1],
    };
    var decorators: std.ArrayListUnmanaged(Decorator) = .empty;
    // Decision 268 — an item that names no decorator leaves the query
    // unanswered: inference holds `with:` to its declared type
    // (`Decorator | Decorator[]`) and refuses it as the ordinary mismatch
    // at the argument (`infer.zig` `checkCatalogueArguments`).
    for (with_items) |*item| {
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
            return .unanswered;
        };
        for (decorators.items) |seen| if (std.mem.eql(u8, seen.owner, decorator.owner) and std.mem.eql(u8, seen.name, decorator.name))
            return .{ .refused = try refusal(arena, q.loc, "{s}: `with:` lists `{s}` twice", .{ diagnostics.typeinfo_all_arguments, spelled }, arguments_hint) };
        try decorators.append(arena, decorator);
    }
    // How the refusals name the query's decorators: `#[a]`, `#[a]/#[b]`.
    var label_buf: std.ArrayListUnmanaged(u8) = .empty;
    for (decorators.items, 0..) |d, i| {
        if (i > 0) try label_buf.append(arena, '/');
        try label_buf.print(arena, "#[{s}]", .{d.name});
    }
    return .{ .ok = .{ .loc = q.loc, .decorators = decorators.items, .member = member, .label = label_buf.items } };
}

/// The declarations a resolved query answers, by module path then recording
/// order. `reader` is an entry point's own module: another reader's entries are
/// left out (it is analysed after this one). Null for a template body's query
/// (decision 353), which answers for every module of the program.
fn entriesFor(arena: std.mem.Allocator, reflection: *const reflectionMod.Reflection, q: Resolved, reader: ?[]const u8) Error![]reflectionMod.DeclaredEntry {
    var entries: std.ArrayListUnmanaged(reflectionMod.DeclaredEntry) = .empty;
    for (reflection.declared.items) |e| {
        const listed = for (q.decorators) |d| {
            if (std.mem.eql(u8, e.decorator_owner, d.owner) and std.mem.eql(u8, e.decorator_name, d.name)) break true;
        } else false;
        if (!listed) continue;
        if (reader) |own| if (!std.mem.eql(u8, e.module, own) and reflection.readers.contains(e.module)) continue;
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
    return entries.items;
}

/// The catalogue's own rules over an answer (one kind per query, `member:`
/// for types and only for them, every entry of another module `pub`), refused
/// at `at`. `own` is the reading module, whose private declarations it reaches
/// directly; null for a template body's query.
fn checkEntries(arena: std.mem.Allocator, q: Resolved, entries: []const reflectionMod.DeclaredEntry, own: ?[]const u8, at: ast.Loc) Error!?TypeError {
    var fns: usize = 0;
    for (entries) |e| {
        if (e.kind == .function) fns += 1;
    }
    if (fns > 0 and fns < entries.len) {
        var first_fn: []const u8 = "";
        var first_type: []const u8 = "";
        for (entries) |e| {
            if (e.kind == .function and first_fn.len == 0) first_fn = e.name;
            if (e.kind != .function and first_type.len == 0) first_type = e.name;
        }
        return try refusal(arena, at, "{s}: `{s}` is carried by the function `{s}` and by the type `{s}`, and one query answers one kind of value", .{ diagnostics.typeinfo_all_mixed, q.label, first_fn, first_type }, "Catalogue functions and types with two decorators, or two queries.");
    }
    const of_types = entries.len > fns;
    if (of_types and q.member == null) {
        return try refusal(arena, at, "{s}: `{s}` is carried by the type `{s}`, and a type is no value: name the associated fn each entry calls", .{ diagnostics.typeinfo_all_needs_member, q.label, entries[0].name }, "Write `@TypeInfo.all(with: <decorator>, member: \"<associated fn>\")`; each `value` is then `{ -> T.<associated fn>() }`.");
    }
    if (!of_types and q.member != null and entries.len > 0) {
        return try refusal(arena, at, "{s}: `{s}` is carried by functions, and `member:` names an associated fn of a type", .{ diagnostics.typeinfo_all_arguments, q.label }, "A function's entry is the function itself; leave `member:` out.");
    }
    for (entries) |e| {
        const mine = if (own) |o| std.mem.eql(u8, e.module, o) else false;
        if (!mine and !e.isPub)
            return try refusal(arena, at, "{s}: `{s}` of `{s}` carries `{s}` and is not `pub`, so the catalogue cannot reach it", .{ diagnostics.typeinfo_all_private, e.name, e.module, q.label }, "Make the declaration `pub`: the entry point reaches every declaration it catalogues through an import.");
    }
    return null;
}

/// One entry as `<ctor>(name: …, module: …, meta: […], returnTypeName: …, value: <value>)`.
fn writeEntry(text: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, reflection: *const reflectionMod.Reflection, q: Resolved, e: reflectionMod.DeclaredEntry, ctor: []const u8, value: []const u8) Error!void {
    try text.print(arena, "{s}(name: ", .{ctor});
    try quoted(text, arena, e.name);
    try text.appendSlice(arena, ", module: ");
    try quoted(text, arena, e.module);
    try text.appendSlice(arena, ", meta: [");
    var first = true;
    for (try reflection.metaOf(arena, e.module, e.name)) |m| {
        const listed = for (q.decorators) |d| {
            if (std.mem.eql(u8, m.decorator, d.name)) break true;
        } else false;
        if (!listed) continue;
        if (!first) try text.appendSlice(arena, ", ");
        first = false;
        try text.appendSlice(arena, "DeclaredMeta(key: ");
        try quoted(text, arena, m.key);
        try text.appendSlice(arena, ", value: ");
        try quoted(text, arena, m.value);
        try text.append(arena, ')');
    }
    try text.appendSlice(arena, "], returnTypeName: ");
    try quoted(text, arena, e.returnTypeName);
    try text.appendSlice(arena, ", value: ");
    try text.appendSlice(arena, value);
    try text.append(arena, ')');
}

/// `val __bp_ti = <text>;` parsed, its tokens on line `line`: the answer's
/// expression.
fn parseAnswer(arena: std.mem.Allocator, text: []const u8, line: usize) Error!*const ast.Expr {
    const prefix = "val __bp_ti = ";
    const src = try std.fmt.allocPrint(arena, "{s}{s};", .{ prefix, text });
    var lx = Lexer.init(src);
    const tokens = try arena.dupe(Token, lx.scanAll(arena) catch return error.OutOfMemory);
    for (tokens) |*t| t.line += line;
    var p = Parser.init(tokens);
    const parsed = p.parse(arena) catch return error.OutOfMemory;
    if (parsed.decls.len != 1 or parsed.decls[0] != .val) return error.OutOfMemory;
    return parsed.decls[0].val.value;
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

    for (queries) |q| {
        const rq = switch (try resolve(arena, env, program, module_path, q)) {
            .ok => |r| r,
            .unanswered => continue,
            .refused => |te| return .{ .refused = te },
        };
        const entries = try entriesFor(arena, reflection, rq, module_path);
        if (try checkEntries(arena, rq, entries, module_path, q.loc)) |te| return .{ .refused = te };
        const of_types = for (entries) |e| {
            if (e.kind != .function) break true;
        } else false;

        // ── the answer ───────────────────────────────────────────────────
        var text: std.ArrayListUnmanaged(u8) = .empty;
        try text.append(arena, '[');
        for (entries, 0..) |e, i| {
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
            const value = if (of_types) try std.fmt.allocPrint(arena, "{{ -> {s}.{s}() }}", .{ ref, rq.member.? }) else ref;
            try writeEntry(&text, arena, reflection, rq, e, "Declared<unknown>", value);
        }
        try text.append(arena, ']');

        // `val __bp_ti = <answer>;`, its tokens on lines of their own.
        try out.rewrites.put(arena, q.loc, try parseAnswer(arena, text.items, line));
        line += 1;
    }
    out.imports = imports.items;
    return .{ .ok = out };
}

/// What a template body's query is answered with (decision 353).
pub const TemplateAnswer = union(enum) {
    /// The array the template's comptime module builds, and its text (what
    /// `comptime.zig` compares with the session's final catalogue).
    ok: struct { expr: *const ast.Expr, text: []const u8 },
    refused: TypeError,
};

/// Decision 353 — the answer to a template body's query `q` for the program
/// the expansion at `at` is compiled in: every module's declarations carrying
/// the query's decorators, from `reflection`'s oracle when the session has
/// one (a complete earlier session), else from `reflection` itself. Each entry
/// is `Declared(name:, module:, meta:, returnTypeName:, value: null)`: the
/// template's comptime module builds it as data, and a declaration of the
/// program is no value at build — a template body's read of `value` is
/// refused (`typeinfo-all-template-value`, `infer.zig`). The catalogue's rules
/// (one kind, `member:` for types, `pub`) hold as for an entry point, refused
/// at the expansion.
pub fn answerForTemplate(arena: std.mem.Allocator, reflection: *const reflectionMod.Reflection, q: Resolved, at: ast.Loc) Error!TemplateAnswer {
    const source = reflection.oracle orelse reflection;
    const text = switch (try templateAnswerText(arena, source, q, at)) {
        .ok => |t| t,
        .refused => |te| return .{ .refused = te },
    };
    return .{ .ok = .{ .expr = try parseAnswer(arena, text, q.loc.line), .text = text } };
}

pub const AnswerText = union(enum) { ok: []const u8, refused: TypeError };

/// The text of a template body's answer from `source` — also how
/// `comptime.zig` re-reads an answer against the final catalogue.
pub fn templateAnswerText(arena: std.mem.Allocator, source: *const reflectionMod.Reflection, q: Resolved, at: ast.Loc) Error!AnswerText {
    const entries = try entriesFor(arena, source, q, null);
    if (try checkEntries(arena, q, entries, null, at)) |te| return .{ .refused = te };
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.append(arena, '[');
    for (entries, 0..) |e, i| {
        if (i > 0) try text.appendSlice(arena, ", ");
        try writeEntry(&text, arena, source, q, e, "Declared", "null");
    }
    try text.append(arena, ']');
    return .{ .ok = text.items };
}

/// Decision 353 — `f` with each of `answers`' calls (by location) replaced
/// by its answer: a copy, so the declaration the registries hold keeps its
/// queries for the next expansion.
pub fn substitute(arena: std.mem.Allocator, f: ast.FnDecl, answers: *const std.AutoHashMapUnmanaged(ast.Loc, *const ast.Expr)) Error!ast.FnDecl {
    const s = Substituter{ .arena = arena, .answers = answers };
    return s.copy(ast.FnDecl, &f);
}

const Substituter = struct {
    arena: std.mem.Allocator,
    answers: *const std.AutoHashMapUnmanaged(ast.Loc, *const ast.Expr),

    fn copy(self: Substituter, comptime T: type, ptr: *const T) Error!T {
        if (T == ast.Expr) {
            if (ptr.* == .call and ptr.call.kind == .call) {
                const c = ptr.call.kind.call;
                if (c.is_builtin and std.mem.eql(u8, c.callee, callee)) {
                    if (self.answers.get(ptr.call.loc)) |answer| return answer.*;
                }
            }
        }
        if (comptime !mayHoldExpr(T)) return ptr.*;
        switch (@typeInfo(T)) {
            .@"struct" => |s| {
                var out = ptr.*;
                inline for (s.fields) |f| {
                    if (f.is_comptime) continue;
                    if (comptime mayHoldExpr(f.type)) @field(out, f.name) = try self.copy(f.type, &@field(ptr.*, f.name));
                }
                return out;
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload, tag| {
                        const P = @TypeOf(payload.*);
                        if (comptime mayHoldExpr(P)) return @unionInit(T, @tagName(tag), try self.copy(P, payload));
                        return ptr.*;
                    },
                }
            } else return ptr.*,
            .optional => |o| return if (ptr.*) |*inner| try self.copy(o.child, inner) else null,
            .pointer => |p| switch (p.size) {
                .one => {
                    const node = try self.arena.create(p.child);
                    node.* = try self.copy(p.child, ptr.*);
                    return node;
                },
                .slice => {
                    const items = try self.arena.alloc(p.child, ptr.*.len);
                    for (ptr.*, 0..) |*e, i| items[i] = try self.copy(p.child, e);
                    return items;
                },
                else => return ptr.*,
            },
            .array => |arr| {
                var out: T = undefined;
                for (ptr, 0..) |*e, i| out[i] = try self.copy(arr.child, e);
                return out;
            },
            else => return ptr.*,
        }
    }
};

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

test "typeinfo.all: a template body's query makes no reader (decision 353)" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const src =
        \\pub fn tpl(comptime e: @Expr<string>) -> @Expr<string> {
        \\    val n = @TypeInfo.all(with: d).length;
        \\    return @expr(e.text() + n.toString());
        \\}
    ;
    try std.testing.expect(!try readsSource(arena, src));
    var lx = Lexer.init(src);
    var p = Parser.init(try lx.scanAll(arena));
    const found = try collectTemplates(arena, try p.parse(arena));
    try std.testing.expectEqual(@as(usize, 1), found.len);
    try std.testing.expectEqualStrings("tpl", found[0].name);
    try std.testing.expectEqual(@as(usize, 1), found[0].queries.len);
}
