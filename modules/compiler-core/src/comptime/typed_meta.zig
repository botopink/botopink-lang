//! Decision 298 — a decorator's meta is a typed value keyed by its type:
//!
//!     decl.setMeta(Entity(table: table.value));   // one `Entity` per declaration
//!     decl.addMeta(Index(column: "name"));         // as many `Index` as written
//!
//! read `@typeInfo(City).meta(Entity)` → `?Entity`,
//! `@typeInfo(City).metaAll(Index)` → `Index[]`, and the same on a
//! `@TypeInfo.all` entry (`d.meta(Entity)`). Decision 370 (1) — a meta record
//! may hold `@Expr<T>` fields (`Field.exprWrapped`), each filled with one of the
//! decorator's `comptime x: @Expr<T>` parameters and spliced where the meta is
//! read as the annotation wrote its argument, so the reading program runs it:
//!
//!     pub type Check<T>(message: @Expr<string>, rule: @Expr<fn(v: T) -> bool>)
//!     decl.addMeta(Check(message: message, rule: rule));
//!
//! The pieces here: which calls of a decorator's body record typed meta
//! (`asCall`, `collect` — in the order `expr_param.eraseFn` numbers them), the
//! record constructor each is (`ctorOf`), and how the value the body built at
//! build — the prelude's `'__bp_typedMeta'/2` reply, JSON — is written back as
//! the constructor's arguments (`render`), checked against each field's shape
//! (`Shape`). `infer.zig` checks the calls where the decorator is declared
//! (`checkTypedMetaCalls`), types them in the body (`inferTypedMetaCall`),
//! records each value where the decorator runs (`runDeclDecorators`) and
//! answers the reads (`inferTypedMetaRead`, `inferDeclaredMetaRead`).
const std = @import("std");
const ast = @import("../ast.zig");
const memberFn = @import("member_fn.zig");

/// `decl.setMeta(v)` — one value of its type per declaration.
pub const set_meta = "setMeta";
/// `decl.addMeta(v)` — values of one type that repeat.
pub const add_meta = "addMeta";
/// The prelude function a typed meta call becomes in the code that runs
/// (`expr_param.eraseFn`): `'typedMeta'(K, Value)`.
pub const typed_meta_fn = @import("runtime/prelude.zig").typed_meta_fn;
/// The host record an `@Expr<T>` field's argument becomes in the code that
/// runs: `__bp_ExprRef(__bp_expr: J)`, `J` the parameter's index after the
/// `@Decl` one — read back here as the argument's lexeme.
pub const expr_ref_record = "__bp_ExprRef";
pub const expr_ref_field = "__bp_expr";

/// One `<decl>.setMeta(<value>)` / `<decl>.addMeta(<value>)` call.
pub const Call = struct {
    value: *ast.Expr,
    /// `addMeta`: the type's values repeat.
    repeat: bool,
    /// The call's location.
    loc: ast.Loc,
};

/// `e` as `<declName>.setMeta(<value>)` / `<declName>.addMeta(<value>)`, one
/// argument, no trailing block; null for any other node (the two-argument
/// `setMeta(key, value)` of decision 216 (2) included).
pub fn asCall(e: ast.Expr, declName: []const u8) ?Call {
    if (e != .call or e.call.kind != .call) return null;
    const c = e.call.kind.call;
    if (c.is_builtin or c.args.len != 1 or c.trailing.len != 0) return null;
    const repeat = if (std.mem.eql(u8, c.callee, add_meta)) true else if (std.mem.eql(u8, c.callee, set_meta)) false else return null;
    const r = c.receiver orelse return null;
    if (r.* != .identifier or r.identifier.kind != .ident or !std.mem.eql(u8, r.identifier.kind.ident, declName)) return null;
    return .{ .value = c.args[0].value, .repeat = repeat, .loc = e.call.loc };
}

/// Every typed meta call of `f`'s body, in the order `expr_param.eraseFn`
/// numbers them: a pre-order walk that does not enter a call's value nor a
/// member function handed to `decl.addMember(name, fn…)` (the program's code).
pub fn collect(arena: std.mem.Allocator, f: ast.FnDecl, declName: []const u8) ![]const Call {
    var out: std.ArrayListUnmanaged(Call) = .empty;
    var c: Collector = .{ .arena = arena, .declName = declName, .out = &out };
    try c.walk([]ast.Stmt, f.body);
    return out.items;
}

const Collector = struct {
    arena: std.mem.Allocator,
    declName: []const u8,
    out: *std.ArrayListUnmanaged(Call),

    fn walk(self: *Collector, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.Expr) {
            if (memberFn.asCall(v, self.declName)) |mc| {
                try self.walk(ast.Expr, mc.name.*);
                return;
            }
            if (asCall(v, self.declName)) |call| {
                try self.out.append(self.arena, call);
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

fn mayHoldExpr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union" => T != ast.Loc and T != ast.TypeRef,
        .optional => |o| mayHoldExpr(o.child),
        .pointer => |pi| pi.child != u8 and mayHoldExpr(pi.child),
        else => false,
    };
}

/// A meta value's constructor as written at the call: `Entity(…)`,
/// `orm.Entity(…)`, `Check<Signup>(…)`.
pub const Ctor = struct {
    /// The namespace import it is reached through (`orm`), null for a name in
    /// scope.
    namespace: ?[]const u8,
    name: []const u8,
    args: []const ast.CallArg,
};

/// `e` as a record constructor call written at the call — a capitalised
/// callee, through a namespace at most; null otherwise (`decorator-meta-not-record`).
pub fn ctorOf(e: ast.Expr) ?Ctor {
    if (e != .call or e.call.kind != .call) return null;
    const c = e.call.kind.call;
    if (c.is_builtin or c.trailing.len != 0 or c.calleeExpr != null or c.optional) return null;
    if (c.callee.len == 0 or !std.ascii.isUpper(c.callee[0])) return null;
    var ns: ?[]const u8 = null;
    if (c.receiver) |r| {
        if (r.* != .identifier or r.identifier.kind != .ident) return null;
        ns = r.identifier.kind.ident;
    }
    return .{ .namespace = ns, .name = c.callee, .args = c.args };
}

// ── a catalogue entry's typed meta ───────────────────────────────────────────

/// The function a `d.meta(T)` / `d.metaAll(T)` read on a `@TypeInfo.all` entry
/// calls (`infer.zig` `inferDeclaredMetaRead`) for the record type spelled
/// `spelled` (`Entity`, `orm.Entity`): every value of the type the entry
/// carries, each built by its thunk. One per type a module reads, and not
/// generic: a backend that monomorphises (wasm) loses a type parameter bound
/// only by the read's type.
pub fn metaAllFnName(arena: std.mem.Allocator, spelled: []const u8) ![]const u8 {
    const name = try std.fmt.allocPrint(arena, "declared__metaAll__{s}", .{spelled});
    for (name) |*ch| if (ch.* == '.') {
        ch.* = '_';
    };
    return name;
}

/// Where the functions `withMetaHelper` declares are parsed: lines of their
/// own past every line of the module and of a typed meta read's answer
/// (`infer.zig` `typed_meta_first_line`).
const helper_first_line: usize = 2_000_000;

/// `program` with a `declared__metaAll__<T>` function for each record type it
/// reads a catalogue entry's typed meta of — a method call `meta(T)` /
/// `metaAll(T)` of one argument, `T` a name or `ns.Name`, on anything but
/// `@typeInfo(…)` —: the function is the module's own, inferred with it, so
/// every backend lowers a typed body.
pub fn withMetaHelper(arena: std.mem.Allocator, program: ast.Program) !ast.Program {
    var finder: ReadFinder = .{ .arena = arena };
    try finder.walk([]const ast.DeclKind, program.decls);
    if (finder.types.count() == 0) return program;
    const lexer = @import("../lexer.zig");
    const Parser = @import("../parser.zig").Parser;
    var added: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var line = helper_first_line;
    for (finder.types.keys(), finder.types.values()) |spelled, at| {
        const name = try metaAllFnName(arena, spelled);
        // Declared already, or a generic record of this module: such a read is
        // refused at its argument (`infer.zig` `inferDeclaredMetaRead`,
        // question `130-s8-d`), and a function would name `T` unapplied.
        const skip = for (program.decls) |d| switch (d) {
            .@"fn" => |f| if (std.mem.eql(u8, f.name, name)) break true,
            .type_ => |t| if (std.mem.eql(u8, t.name, spelled) and t.genericParams.len > 0) break true,
            else => {},
        } else false;
        if (skip) continue;
        // Only a name that is a type here: one this module declares or an
        // import binds (`ns.T`: `ns` an import's name). Any other `x.meta(Y)`
        // is no catalogue read — a method of the program's own — and gets no
        // function whose signature would name `Y`.
        if (!namesTypeHere(program, spelled)) continue;
        // The type is written where the read writes it: a type the checker
        // refuses in the function's signature (unknown, generic) is refused
        // at the read's argument, never on a line of the function's own.
        var tl = lexer.Lexer.init(spelled);
        const typeTokens = try lexer.Lexer.scanAll(&tl, arena);
        const src = try std.fmt.allocPrint(arena, "fn {s}(slots: DeclaredTypedMeta[], key: string) -> " ++ type_slot ++ "[] {{ var out: " ++ type_slot ++ "[] = []; for (slots) {{ s -> if (s.key == key) {{ val f = s.value; if (f is fn() -> " ++ type_slot ++ ") out.push(f()); }} }} return out; }}", .{name});
        var lx = lexer.Lexer.init(src);
        var tokens: std.ArrayListUnmanaged(lexer.Token) = .empty;
        for (try lx.scanAll(arena)) |t| {
            if (std.mem.eql(u8, t.lexeme, type_slot)) {
                for (typeTokens) |tt| {
                    if (tt.kind == .endOfFile) continue;
                    var placed = tt;
                    placed.line = at.line;
                    placed.col = at.col;
                    try tokens.append(arena, placed);
                }
                continue;
            }
            var shifted = t;
            shifted.line += line;
            try tokens.append(arena, shifted);
        }
        line += 1;
        var p = Parser.init(tokens.items);
        const helper = try p.parse(arena);
        try added.appendSlice(arena, helper.decls);
    }
    const decls = try arena.alloc(ast.DeclKind, program.decls.len + added.items.len);
    @memcpy(decls[0..program.decls.len], program.decls);
    @memcpy(decls[program.decls.len..], added.items);
    var out = program;
    out.decls = decls;
    return out;
}

/// Whether `spelled` (`T`, `ns.T`) can name a type of `program`'s scope as
/// written: a type it declares, an import's bound name, or `T` of a namespace
/// an import binds.
fn namesTypeHere(program: ast.Program, spelled: []const u8) bool {
    const dot = std.mem.indexOfScalar(u8, spelled, '.');
    const head = if (dot) |i| spelled[0..i] else spelled;
    for (program.decls) |d| switch (d) {
        .type_ => |t| if (dot == null and std.mem.eql(u8, t.name, head)) return true,
        .use => |u| for (u.imports) |item| {
            if (item.segments.len > 0 and std.mem.eql(u8, item.name(), head)) return true;
        },
        else => {},
    };
    return false;
}

/// The placeholder the reader's source writes the type as, replaced by the
/// type's tokens.
const type_slot = "Bp__MetaT";

const ReadFinder = struct {
    arena: std.mem.Allocator,
    /// Each type spelled as written, with where its first read writes it.
    types: std.StringArrayHashMapUnmanaged(ast.Loc) = .empty,

    fn walk(self: *ReadFinder, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.Expr) if (v == .call and v.call.kind == .call) {
            const c = v.call.kind.call;
            if (!c.is_builtin and c.args.len == 1 and (std.mem.eql(u8, c.callee, "meta") or std.mem.eql(u8, c.callee, "metaAll"))) {
                if (c.receiver) |r| {
                    const onTypeInfo = r.* == .call and r.call.kind == .call and r.call.kind.call.is_builtin and std.mem.eql(u8, r.call.kind.call.callee, "typeInfo");
                    if (!onTypeInfo) if (spelledType(c.args[0].value.*)) |sp| {
                        const gop = try self.types.getOrPut(self.arena, try sp.text(self.arena));
                        if (!gop.found_existing) gop.value_ptr.* = c.args[0].value.getLoc();
                    };
                }
            }
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

/// A type written as a read's argument: `Entity` or `orm.Entity`, capitalised.
pub const Spelled = struct {
    namespace: ?[]const u8,
    name: []const u8,

    pub fn text(self: Spelled, arena: std.mem.Allocator) ![]const u8 {
        return if (self.namespace) |ns| std.fmt.allocPrint(arena, "{s}.{s}", .{ ns, self.name }) else self.name;
    }
};

pub fn spelledType(e: ast.Expr) ?Spelled {
    if (e != .identifier) return null;
    switch (e.identifier.kind) {
        .ident => |n| return if (n.len > 0 and std.ascii.isUpper(n[0])) .{ .namespace = null, .name = n } else null,
        .identAccess => |ia| {
            if (ia.optional or ia.receiver.* != .identifier or ia.receiver.identifier.kind != .ident) return null;
            if (ia.member.len == 0 or !std.ascii.isUpper(ia.member[0])) return null;
            return .{ .namespace = ia.receiver.identifier.kind.ident, .name = ia.member };
        },
        else => return null,
    }
}

// ── shapes and rendering ─────────────────────────────────────────────────────

/// What a meta record's field holds, as far as the value is rebuilt where the
/// meta is read.
pub const Shape = union(enum) {
    string,
    /// Any integer type: a decimal literal, range-checked where it is read.
    int,
    /// `f64` (suffix "") or `f32` (suffix "f").
    float: []const u8,
    boolean,
    /// A variant of an enum without payloads, written `.Name` (the field's
    /// type resolves it, decision 280 (3)).
    variant,
    array: *const Shape,
    optional: *const Shape,
    /// Decision 370 (1) — an `@Expr<T>` field: the argument as the annotation
    /// wrote it.
    expr,
};

/// One field of a meta record, in declaration order.
pub const FieldShape = struct { name: []const u8, shape: Shape };

/// The shape of a primitive type name; null for anything else.
pub fn primitiveShape(name: []const u8) ?Shape {
    if (std.mem.eql(u8, name, "string")) return .string;
    if (std.mem.eql(u8, name, "bool")) return .boolean;
    if (std.mem.eql(u8, name, "f64")) return .{ .float = "" };
    if (std.mem.eql(u8, name, "f32")) return .{ .float = "f" };
    const ints = [_][]const u8{ "i8", "i16", "i32", "i64", "isize", "u8", "u16", "u32", "u64", "usize" };
    for (ints) |i| if (std.mem.eql(u8, name, i)) return .int;
    return null;
}

/// Why a value could not be written back.
pub const RenderError = error{ OutOfMemory, Mismatch };

/// The constructor's arguments, `(name: value, …)`, from the value the body
/// built (`data`, the record as a JSON object — the fields the call gave, so
/// a default stays the record's own) — each field in declaration order. An
/// `@Expr<T>` field's value is the parameter it was given (`{"__bp_expr": J}`),
/// written as `lexemes[J]`. `bad` names the field that did not fit.
pub fn render(arena: std.mem.Allocator, fields: []const FieldShape, data: std.json.Value, lexemes: []const []const u8, bad: *[]const u8) RenderError![]const u8 {
    if (data != .object) return error.Mismatch;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    try out.append(arena, '(');
    var first = true;
    for (fields) |f| {
        const v = data.object.get(f.name) orelse continue;
        if (!first) try out.appendSlice(arena, ", ");
        first = false;
        try out.print(arena, "{s}: ", .{f.name});
        bad.* = f.name;
        try value(arena, &out, f.shape, v, lexemes);
    }
    try out.append(arena, ')');
    return out.items;
}

fn value(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), shape: Shape, v: std.json.Value, lexemes: []const []const u8) RenderError!void {
    switch (shape) {
        .string => {
            if (v != .string) return error.Mismatch;
            try writeBpString(arena, out, v.string);
        },
        .int => switch (v) {
            .integer => |n| try out.print(arena, "{d}", .{n}),
            .number_string => |s| try out.appendSlice(arena, s),
            else => return error.Mismatch,
        },
        .float => |suffix| {
            const x: f64 = switch (v) {
                .float => |x| x,
                .integer => |n| @floatFromInt(n),
                else => return error.Mismatch,
            };
            if (std.math.isNan(x) or std.math.isInf(x)) return error.Mismatch;
            const text = try std.fmt.allocPrint(arena, "{d}", .{x});
            try out.appendSlice(arena, text);
            if (std.mem.indexOfAny(u8, text, ".e") == null) try out.appendSlice(arena, ".0");
            try out.appendSlice(arena, suffix);
        },
        .boolean => {
            if (v != .bool) return error.Mismatch;
            try out.appendSlice(arena, if (v.bool) "true" else "false");
        },
        .variant => {
            if (v != .string or v.string.len == 0 or !std.ascii.isUpper(v.string[0])) return error.Mismatch;
            for (v.string) |ch| if (!std.ascii.isAlphanumeric(ch) and ch != '_') return error.Mismatch;
            try out.print(arena, ".{s}", .{v.string});
        },
        .array => |elem| {
            if (v != .array) return error.Mismatch;
            try out.append(arena, '[');
            for (v.array.items, 0..) |item, i| {
                if (i > 0) try out.appendSlice(arena, ", ");
                try value(arena, out, elem.*, item, lexemes);
            }
            try out.append(arena, ']');
        },
        .optional => |inner| {
            if (v == .null) return out.appendSlice(arena, "null");
            try value(arena, out, inner.*, v, lexemes);
        },
        .expr => {
            if (v != .object) return error.Mismatch;
            const j = v.object.get(expr_ref_field) orelse return error.Mismatch;
            if (j != .integer or j.integer < 0 or @as(usize, @intCast(j.integer)) >= lexemes.len) return error.Mismatch;
            const lexeme = lexemes[@intCast(j.integer)];
            if (lexeme.len == 0) return error.Mismatch;
            try out.appendSlice(arena, lexeme);
        },
    }
}

/// `s` as a botopink string literal (`$` escaped: no interpolation).
pub fn writeBpString(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), s: []const u8) !void {
    try out.append(arena, '"');
    for (s) |ch| switch (ch) {
        '"' => try out.appendSlice(arena, "\\\""),
        '\\' => try out.appendSlice(arena, "\\\\"),
        '$' => try out.appendSlice(arena, "\\$"),
        '\n' => try out.appendSlice(arena, "\\n"),
        '\r' => try out.appendSlice(arena, "\\r"),
        '\t' => try out.appendSlice(arena, "\\t"),
        else => try out.append(arena, ch),
    };
    try out.append(arena, '"');
}

// ── tests ────────────────────────────────────────────────────────────────────

test "typed meta calls, in body order; the string form and a member's body are none" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    var lx = lexer.Lexer.init(
        \\fn d(comptime decl: @Decl, comptime m: @Expr<string>) {
        \\    decl.setMeta("key", "value");
        \\    decl.setMeta(Entity(table: "a"));
        \\    if (decl.name == "") { decl.addMeta(Index(column: "x")); }
        \\    decl.addMember("v", fn(self: string) -> string { return m; });
        \\    decl.addMeta(orm.Index(column: "y"));
        \\}
    );
    var p = parser.Parser.init(try lx.scanAll(arena));
    const f = (try p.parse(arena)).decls[0].@"fn";
    const calls = try collect(arena, f, "decl");
    try std.testing.expectEqual(@as(usize, 3), calls.len);
    try std.testing.expect(!calls[0].repeat);
    try std.testing.expect(calls[1].repeat);
    try std.testing.expectEqualStrings("Entity", ctorOf(calls[0].value.*).?.name);
    const third = ctorOf(calls[2].value.*).?;
    try std.testing.expectEqualStrings("orm", third.namespace.?);
    try std.testing.expectEqualStrings("Index", third.name);
}

test "a value is written back field by field, each by its shape" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const str: Shape = .string;
    const opt: Shape = .{ .optional = &str };
    const variant: Shape = .variant;
    const fields = [_]FieldShape{
        .{ .name = "table", .shape = .string },
        .{ .name = "size", .shape = .int },
        .{ .name = "ratio", .shape = .{ .float = "" } },
        .{ .name = "on", .shape = .boolean },
        .{ .name = "level", .shape = .variant },
        .{ .name = "levels", .shape = .{ .array = &variant } },
        .{ .name = "alias", .shape = opt },
        .{ .name = "rule", .shape = .expr },
        .{ .name = "unset", .shape = .string },
    };
    const parsed = try std.json.parseFromSliceLeaky(std.json.Value, arena,
        \\{"table":"ci\"ty $x","size":3,"ratio":2.0,"on":true,"level":"High","levels":["Low","High"],"alias":null,"rule":{"__bp_expr":1}}
    , .{});
    var bad: []const u8 = "";
    const text = try render(arena, &fields, parsed, &.{ "\"m\"", "passwordsMatch" }, &bad);
    try std.testing.expectEqualStrings(
        \\(table: "ci\"ty \$x", size: 3, ratio: 2.0, on: true, level: .High, levels: [.Low, .High], alias: null, rule: passwordsMatch)
    , text);

    const wrong = try std.json.parseFromSliceLeaky(std.json.Value, arena, "{\"table\":3}", .{});
    try std.testing.expectError(error.Mismatch, render(arena, &fields, wrong, &.{}, &bad));
    try std.testing.expectEqualStrings("table", bad);
}
