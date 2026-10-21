//! Decision 804 (1) — 593 (2) with its method renamed: a type implementing
//! the prelude's `Component<R>` is a component. Its fields are the props and
//! its `fn compose(self: Self) -> Component<R>` is the body, so
//!
//!     type Card(title: string, body: string = "none") implement Component<View> {
//!         fn compose(self: Self) -> Component<View> { … self.title … self.label() … }
//!         fn label(self: Self) -> string { … }
//!     }
//!
//! is the `fn` component it reads as, and `Card(…)` answers the component,
//! never a record. This pass, run on the parsed program before the checker
//! and the backends see it (`analyzeSource`), rewrites the declaration into
//!
//!     type Card__Self(title: string, body: string = "none") { fn label(self: Self) -> string { … } }
//!     component fn Card(title: string, body: string = "none") -> Component<View> {
//!         val compose__self = Card__Self(title: title, body: body);
//!         … compose's body, `self` read as `compose__self`, `Self` as `Card__Self` …
//!     }
//!
//! — the record `self` reads (shown `Card`, the helpers and the type's other
//! `implement`s kept on it) and the `fn` component it is sugar for, which
//! takes the type's annotations, so `#[page] type` and `#[page] fn` are one.
//! No checker rule and no backend learns a new node.
//!
//! Refused here, located: `implement Component<R>` with no `compose`
//! (`component-compose-missing`); a `compose` of another signature (800's
//! `implement-signature-differs`, the contract `fn compose(self: Self) ->
//! Component<R>`); a `RenderScope` field (`component-scope-field`, 388 (5)).
//! The checker refuses the other two with the names this pass records
//! (`Composed`): a `use` in a helper (`component-use-outside-compose`) and
//! `Card.compose()` (`component-compose-called`).
//!
//! The pass is idempotent: the rewritten program implements no `Component`.
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const member_fn = @import("member_fn.zig");
const diagnostics = @import("diagnostics.zig");
const TypeError = @import("error.zig").TypeError;
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;

const Error = error{OutOfMemory};

/// The name of a type component's body.
pub const compose_name = "compose";

/// The local a component's body reads its `self` under.
const self_local = "compose__self";

/// One rewritten type component: the record its `self` reads and the
/// component's name.
pub const Composed = struct {
    record: []const u8,
    component: []const u8,
};

pub const Result = union(enum) {
    ok: struct { program: ast.Program, composed: []const Composed },
    refused: TypeError,
};

/// The record a type component's `self` reads: `Card__Self`.
pub fn recordName(arena: std.mem.Allocator, component: []const u8) Error![]const u8 {
    return envMod.assocTypeName(arena, component, "Self");
}

/// The clause naming the prelude's `Component<R>`, or null.
fn componentClause(td: ast.TypeDecl) ?usize {
    for (td.implement, 0..) |im, i| switch (im) {
        .generic => |g| if (g.is_builtin and g.args.len == 1 and std.mem.eql(u8, g.name, "Component")) return i,
        else => {},
    };
    return null;
}

pub fn expand(arena: std.mem.Allocator, program: ast.Program) Error!Result {
    var any = false;
    for (program.decls) |d| if (d == .type_ and d.type_.isRecord() and componentClause(d.type_) != null) {
        any = true;
    };
    if (!any) return .{ .ok = .{ .program = program, .composed = &.{} } };

    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var blanks: std.ArrayListUnmanaged(bool) = .empty;
    const keep_blanks = program.blankLineBefore.len == program.decls.len;
    var composed: std.ArrayListUnmanaged(Composed) = .empty;
    for (program.decls, 0..) |d, i| {
        const clause = if (d == .type_ and d.type_.isRecord()) componentClause(d.type_) else null;
        if (clause == null) {
            try out.append(arena, d);
            if (keep_blanks) try blanks.append(arena, program.blankLineBefore[i]);
            continue;
        }
        const td = d.type_;
        const rewritten = switch (try rewrite(arena, td, clause.?)) {
            .ok => |r| r,
            .refused => |te| return .{ .refused = te },
        };
        try out.append(arena, .{ .type_ = rewritten.record });
        try out.append(arena, .{ .@"fn" = rewritten.component });
        if (keep_blanks) {
            try blanks.append(arena, program.blankLineBefore[i]);
            try blanks.append(arena, false);
        }
        try composed.append(arena, .{ .record = rewritten.record.name, .component = td.name });
    }
    var p = program;
    p.decls = try out.toOwnedSlice(arena);
    p.blankLineBefore = if (keep_blanks) try blanks.toOwnedSlice(arena) else &.{};
    return .{ .ok = .{ .program = p, .composed = try composed.toOwnedSlice(arena) } };
}

const Rewritten = union(enum) {
    ok: struct { record: ast.TypeDecl, component: ast.FnDecl },
    refused: TypeError,
};

fn refuse(msg: []const u8, hint: []const u8, loc: ast.Loc) Rewritten {
    return .{ .refused = TypeError.custom(msg, hint).withLoc(loc) };
}

fn rewrite(arena: std.mem.Allocator, td: ast.TypeDecl, clause: usize) Error!Rewritten {
    const iface = td.implement[clause];
    const renders = iface.generic.args[0];
    const fields = td.recordFields();

    // 388 (5) — the scope is never a field: the renderer hands it at each run.
    for (fields) |f| if (isRenderScope(f.typeRef)) {
        return refuse(
            try std.fmt.allocPrint(arena, "{s}: `{s}.{s}` is a `RenderScope` — a component holds no scope: the renderer hands it to `compose` at each run (decision 388 (5))", .{ diagnostics.component_scope_field, td.name, f.name }),
            "Drop the field; what the body reads from above it is a context, `use context(ctx)` in `compose`.",
            if (f.typeLoc.line != 0) f.typeLoc else td.loc,
        );
    };

    var compose: ?ast.BehaviorMethod = null;
    for (td.methods) |m| if (std.mem.eql(u8, m.name, compose_name) and m.body != null) {
        compose = m;
    };
    const c = compose orelse return refuse(
        try std.fmt.allocPrint(arena, "{s}: `{s}` implements `{f}` and declares no `compose` — a type component's body is its `fn compose(self: Self) -> {f}` (decision 804 (1))", .{ diagnostics.component_compose_missing, td.name, iface, iface }),
        try std.fmt.allocPrint(arena, "Write the body as `fn compose(self: Self) -> {f} {{ … }}`; the fields are the props, read on `self`.", .{iface}),
        td.loc,
    );

    // Decision 800 — the contract's one member, `Self` read as the type.
    if (!composeMatches(c, iface)) {
        return refuse(
            try std.fmt.allocPrint(arena, "{s}: `{s}.compose` does not match the contract `{f}` — contract: fn compose(self: {s}) -> {f} · written: {s}", .{
                diagnostics.implement_signature_differs,
                td.name,
                iface,
                td.name,
                iface,
                try writtenSig(arena, c, td.name),
            }),
            "Write the member with the contract's parameter types and return type, `Self` the implementing type — labels, parameter names and defaults are free.",
            if (c.nameLoc.line != 0) c.nameLoc else td.loc,
        );
    }

    const rec_name = try recordName(arena, td.name);

    // The record: the fields, the helpers, the other contracts.
    var record = td;
    record.name = rec_name;
    record.displayName = td.printedName();
    record.annotations = &.{};
    record.docComment = null;
    record.comment = null;
    record.moduleComment = null;
    var impls: std.ArrayListUnmanaged(ast.TypeRef) = .empty;
    for (td.implement, 0..) |im, i| if (i != clause) try impls.append(arena, im);
    record.implement = try impls.toOwnedSlice(arena);
    // The record keeps the helpers; `compose` becomes the component's body.
    var helpers: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
    for (td.methods) |m| if (!std.mem.eql(u8, m.name, compose_name)) try helpers.append(arena, m);
    record.methods = try helpers.toOwnedSlice(arena);

    // The component: the fields as its parameters, the record `self` reads
    // made from them first. The receiver is read under `self_local` — a
    // backend lowers a `self` it does not receive as a method's `this` — and
    // `Self` as the record.
    const params = try arena.alloc(ast.Param, fields.len);
    for (fields, 0..) |f, i| params[i] = .{
        .name = f.name,
        .typeRef = f.typeRef,
        .default = f.default,
        .typeLoc = f.typeLoc,
        .exprWrapped = f.exprWrapped,
    };
    const at = if (c.nameLoc.line != 0) c.nameLoc else td.loc;
    var unbound = c;
    unbound.params = &.{};
    const renamed = try member_fn.renameMethod(arena, unbound, &.{
        .{ .from = c.params[0].name, .to = self_local },
        .{ .from = "Self", .to = rec_name },
    });
    const written = renamed.body.?;
    const body = try arena.alloc(ast.Stmt, written.len + 1);
    body[0] = try selfBinding(arena, rec_name, fields, at);
    @memcpy(body[1..], written);

    const component: ast.FnDecl = .{
        .isPub = td.isPub,
        .effect = .component,
        .marker = .component,
        .markerLoc = at,
        .name = td.name,
        .nameLoc = td.loc,
        .startLoc = td.startLoc,
        .docComment = td.docComment,
        .comment = td.comment,
        .moduleComment = td.moduleComment,
        .annotations = td.annotations,
        .genericParams = td.genericParams,
        .params = params,
        .returnType = renders: {
            const args = try arena.alloc(ast.TypeRef, 1);
            args[0] = renders;
            break :renders .{ .generic = .{ .name = "Component", .args = args, .is_builtin = true, .bare = true } };
        },
        .returnTypeLoc = c.returnTypeLoc,
        .body = body,
    };
    return .{ .ok = .{ .record = record, .component = component } };
}

fn isRenderScope(t: ast.TypeRef) bool {
    return switch (t) {
        .named => |n| std.mem.eql(u8, n, "RenderScope") or std.mem.endsWith(u8, n, ".RenderScope"),
        .optional => |inner| isRenderScope(inner.*),
        else => false,
    };
}

/// `fn compose(self: Self) -> Component<R>`, `R` the clause's: one parameter,
/// `Self`, no type parameter, the clause's wrapper as the return.
fn composeMatches(c: ast.BehaviorMethod, iface: ast.TypeRef) bool {
    if (c.params.len != 1 or c.genericParams.len != 0) return false;
    if (!c.params[0].typeRef.isSelf()) return false;
    const r = c.returnType orelse return false;
    return typeRefEql(r, iface);
}

fn typeRefEql(a: ast.TypeRef, b: ast.TypeRef) bool {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;
    return switch (a) {
        .named => |n| std.mem.eql(u8, n, b.named),
        .array => |e| typeRefEql(e.*, b.array.*),
        .optional => |e| typeRefEql(e.*, b.optional.*),
        .tuple_ => |es| es.len == b.tuple_.len and for (es, b.tuple_) |x, y| {
            if (!typeRefEql(x, y)) break false;
        } else true,
        .labeledTuple => |lt| lt.elems.len == b.labeledTuple.elems.len and for (lt.elems, b.labeledTuple.elems) |x, y| {
            if (!typeRefEql(x, y)) break false;
        } else true,
        .function => |f| f.params.len == b.function.params.len and typeRefEql(f.returnType.*, b.function.returnType.*) and for (f.params, b.function.params) |x, y| {
            if (!typeRefEql(x, y)) break false;
        } else true,
        .generic => |g| std.mem.eql(u8, g.name, b.generic.name) and g.args.len == b.generic.args.len and for (g.args, b.generic.args) |x, y| {
            if (!typeRefEql(x, y)) break false;
        } else true,
        .typeparam => |cs| cs.len == b.typeparam.len and for (cs, b.typeparam) |x, y| {
            if (!typeRefEql(x, y)) break false;
        } else true,
    };
}

/// `fn compose(self: Card, n: i32) -> View` — the member as written, `Self`
/// read as the type.
fn writtenSig(arena: std.mem.Allocator, c: ast.BehaviorMethod, self_name: []const u8) Error![]const u8 {
    var out: std.Io.Writer.Allocating = .init(arena);
    const w = &out.writer;
    w.writeAll("fn compose(") catch return error.OutOfMemory;
    for (c.params, 0..) |p, i| {
        if (i > 0) w.writeAll(", ") catch return error.OutOfMemory;
        if (p.typeRef.isSelf())
            w.print("{s}: {s}", .{ p.name, self_name }) catch return error.OutOfMemory
        else
            w.print("{s}: {f}", .{ p.name, p.typeRef }) catch return error.OutOfMemory;
    }
    w.writeAll(") -> ") catch return error.OutOfMemory;
    if (c.returnType) |r| {
        if (r.isSelf()) w.writeAll(self_name) catch return error.OutOfMemory else w.print("{f}", .{r}) catch return error.OutOfMemory;
    } else w.writeAll("void") catch return error.OutOfMemory;
    return out.toOwnedSlice() catch return error.OutOfMemory;
}

/// `val compose__self = Card__Self(title: title, …);`, parsed at `at`'s line.
fn selfBinding(arena: std.mem.Allocator, rec_name: []const u8, fields: []const ast.Field, at: ast.Loc) Error!ast.Stmt {
    var out: std.Io.Writer.Allocating = .init(arena);
    const w = &out.writer;
    w.print("fn __compose() -> void {{ val {s} = {s}(", .{ self_local, rec_name }) catch return error.OutOfMemory;
    for (fields, 0..) |f, i| w.print("{s}{s}: {s}", .{ if (i > 0) ", " else "", f.name, f.name }) catch return error.OutOfMemory;
    w.writeAll("); }") catch return error.OutOfMemory;
    const src = out.toOwnedSlice() catch return error.OutOfMemory;
    var lx = Lexer.init(src);
    const tokens = arena.dupe(@import("../lexer.zig").Token, lx.scanAll(arena) catch return error.OutOfMemory) catch return error.OutOfMemory;
    for (tokens) |*t| {
        t.line += at.line - 1;
        t.col = at.col;
    }
    var p = Parser.init(tokens);
    const parsed = p.parse(arena) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => @panic("component_types: the `self` binding does not parse"),
    };
    return parsed.decls[0].@"fn".body[0];
}
