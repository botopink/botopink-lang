//! Decisions 575 (3), (4) and 576 — the surface a build-time body talks to the
//! compiler through, read onto the machinery the checker, the decorator and
//! template evaluators and the comptime runtime already know. Run once by
//! `Parser.parse`, after `expr_params.zig` (the formatter parses with
//! `Parser.keep_surface` and sees the program as written).
//!
//! - `compiler.<member>(…)` — the `Compiler` of the point (`libs/std/src/
//!   compiler.bp`): in a decorator the annotated declaration, read through the
//!   declaration handle the parser gave the decorator's first `expr`
//!   (`ast.decl_type_name`); in a template the call site, read through the
//!   template's literal; elsewhere the builtins of the point. `members` is
//!   the table a unit test holds to `compiler.bp`.
//! - `comptime x: T` (`Param.arrival == .value`) — a bare read of `x` is the
//!   value (`x.value` to the machinery; `comptime/expr_param.zig` erases it for
//!   the code that runs). Inside a tree — a member or a wrapper a decorator
//!   writes — `x` stays the parameter, spliced where it was written.
//! - `-> expr T` — a template's `return e` hands the expression `e` to the call
//!   site: a parameter's tree as it is, anything else lifted (`@expr(e)` to
//!   the template machinery).
//! - The refusals — `compiler-at-run-time`, `compiler-output-outside-decorator`,
//!   `expr-captures-build`, `compiler-member-unknown` — are written as the
//!   reserved builtin `refusal_builtin` at the place, which the checker
//!   reports there (`infer.zig`).

const std = @import("std");
const ast = @import("../ast.zig");
const diagnostics = @import("../comptime/diagnostics.zig");

/// The builtin a refusal of this pass is written as: `@<name>("<code>",
/// "<message>", "<hint>")`. No source can spell it (`@` takes a name).
pub const refusal_builtin = "__compilerRefusal";

/// What a member is, for the table test and the mapping below.
pub const Kind = enum {
    /// A read of the point: `compiler.src`.
    property,
    /// An output of a decorator: `compiler.setMeta(v)`.
    output,
    /// A read taking an `expr` (or a declaration handle) first.
    read,
    /// A read of the template's call site: `compiler.build<R>(source)`.
    site,
};

pub const Member = struct { name: []const u8, kind: Kind };

/// The `Compiler` members this step builds — 575 (3) and 576 (2), (3), less
/// B-137 … B-140's (`compile`, `implement`, `setBuiltin`, `embed`, `record`,
/// `fields` over a type, `optional`, `required`). `comptime/tests/compiler_
/// members.zig` holds it to `libs/std/src/compiler.bp`.
pub const members = [_]Member{
    .{ .name = "src", .kind = .property },
    .{ .name = "module", .kind = .property },
    .{ .name = "package", .kind = .property },
    .{ .name = "isStd", .kind = .property },
    .{ .name = "fail", .kind = .read },
    .{ .name = "setMeta", .kind = .output },
    .{ .name = "addMeta", .kind = .output },
    .{ .name = "addMember", .kind = .output },
    .{ .name = "addType", .kind = .output },
    .{ .name = "wrapWith", .kind = .output },
    .{ .name = "catalogue", .kind = .site },
    .{ .name = "typeInfo", .kind = .site },
    .{ .name = "text", .kind = .read },
    .{ .name = "name", .kind = .read },
    .{ .name = "parts", .kind = .read },
    .{ .name = "source", .kind = .read },
    .{ .name = "context", .kind = .read },
    .{ .name = "lookup", .kind = .read },
    .{ .name = "bindings", .kind = .read },
    .{ .name = "build", .kind = .site },
    .{ .name = "note", .kind = .site },
    .{ .name = "tagDecl", .kind = .site },
    .{ .name = "annotate", .kind = .site },
    .{ .name = "custom", .kind = .site },
    .{ .name = "kind", .kind = .read },
    .{ .name = "moduleOf", .kind = .read },
    .{ .name = "meta", .kind = .read },
    .{ .name = "metaAll", .kind = .read },
    .{ .name = "attr", .kind = .read },
    .{ .name = "component", .kind = .read },
    .{ .name = "hooks", .kind = .read },
    .{ .name = "fields", .kind = .read },
    .{ .name = "methods", .kind = .read },
    .{ .name = "params", .kind = .read },
    .{ .name = "returnType", .kind = .read },
    .{ .name = "owner", .kind = .read },
    .{ .name = "annotations", .kind = .read },
    .{ .name = "variants", .kind = .read },
};

fn memberOf(name: []const u8) ?Member {
    for (members) |m| if (std.mem.eql(u8, m.name, name)) return m;
    return null;
}

/// A declaration handle's field each read maps to (`compiler.kind(d)` →
/// `d.kind`); `moduleOf` reads `module`.
fn handleField(name: []const u8) ?[]const u8 {
    const fields = [_][]const u8{ "name", "kind", "component", "hooks", "fields", "methods", "params", "returnType", "owner", "annotations", "variants" };
    for (fields) |f| if (std.mem.eql(u8, f, name)) return f;
    if (std.mem.eql(u8, name, "moduleOf")) return "module";
    return null;
}

const Ctx = struct {
    /// The program's allocator: every node the pass writes.
    alloc: std.mem.Allocator,
    /// The pass's own lists, freed when it ends.
    scratch: std.mem.Allocator,
    /// The decorator's declaration handle (its first parameter), if any.
    decl: ?[]const u8 = null,
    /// The template's literal (its call site), if any.
    site: ?[]const u8 = null,
    template: bool = false,
    /// `comptime x: T` parameters: a bare read is the value.
    values: []const []const u8 = &.{},
    /// Parameters whose argument is a tree (`expr x: T`, a template's).
    trees: []const []const u8 = &.{},
    /// `main` / a `test` body: no build-time body.
    runTime: bool = false,
    /// Inside a tree a decorator writes (a member, a wrapper).
    inTree: bool = false,
    /// Names a lambda inside the body binds over a value parameter.
    shadow: std.ArrayListUnmanaged([]const u8) = .empty,
    /// Whether the pass wrote anything.
    changed: bool = false,
    /// A `-> expr T` template that attaches a reference tree.
    custom: bool = false,
};

/// Read the program's new surface onto the machinery (see the file comment).
/// A program that writes none of it is left untouched.
pub fn expandProgram(alloc: std.mem.Allocator, program: *ast.Program) error{OutOfMemory}!void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const P = Pass{ .alloc = alloc, .scratch = arena.allocator() };
    for (program.decls) |*d| switch (d.*) {
        .@"fn" => |*f| try expandFn(P, f.name, f.params, &f.returnType, f.body),
        .type_ => |*t| try expandType(P, t),
        .behavior => |*b| for (b.methods) |*m| if (m.body) |body| try expandFn(P, m.name, m.params, &m.returnType, body),
        .implement => |*i| for (i.methods) |*m| try expandFn(P, m.name, m.params, &none, m.body),
        .extend => |*e| for (e.methods) |*m| try expandFn(P, m.name, m.params, &none, m.body),
        .@"test" => |*t| {
            var ctx: Ctx = .{ .alloc = alloc, .scratch = P.scratch, .runTime = true };
            try walkStmts(&ctx, t.body);
        },
        .val => |*v| {
            var ctx: Ctx = .{ .alloc = alloc, .scratch = P.scratch };
            try walkExpr(&ctx, v.value);
        },
        else => {},
    };
}

const Pass = struct { alloc: std.mem.Allocator, scratch: std.mem.Allocator };

/// The return of a function that writes none (an `implement` method's).
var none: ?ast.TypeRef = null;

/// The local a `-> expr T` template's `compiler.custom(tree)` keeps its tree
/// in (decision 576 (4)); no source can spell it.
const custom_tree_name = "__bp_customTree";

fn expandType(P: Pass, t: *ast.TypeDecl) error{OutOfMemory}!void {
    for (t.methods) |*m| if (m.body) |body| try expandFn(P, m.name, m.params, &m.returnType, body);
    for (t.assocTypes) |*inner| try expandType(P, inner);
}

fn expandFn(P: Pass, name: []const u8, params: []ast.Param, returnRef: *?ast.TypeRef, body: []ast.Stmt) error{OutOfMemory}!void {
    const returnType = returnRef.*;
    const alloc = P.scratch;
    var ctx: Ctx = .{ .alloc = P.alloc, .scratch = P.scratch };
    ctx.runTime = std.mem.eql(u8, name, "main");
    if (params.len > 0 and params[0].typeRef.isDeclType()) ctx.decl = params[0].name;
    // A template annotation's handle is its second parameter (decision 311).
    if (params.len > 1 and params[1].typeRef.isDeclType()) ctx.decl = params[1].name;
    const template = if (returnType) |rt| rt.isTemplateReturnType() else false;
    ctx.template = template;
    var values: std.ArrayListUnmanaged([]const u8) = .empty;
    var trees: std.ArrayListUnmanaged([]const u8) = .empty;
    for (params, 0..) |p, i| {
        if (p.arrival == .value) try values.append(alloc, p.name);
        const tree = p.exprWrapped or p.typeRef.isExprType() or p.typeRef.isExprCustomType();
        if (p.arrival != .value and tree) try trees.append(alloc, p.name);
        if (template and ctx.site == null and p.typeRef.isExprType()) {
            // A template method's literal is its second parameter (311 (3)).
            if (!(i == 0 and ast.isTemplateMethodSignature(params, returnType))) ctx.site = p.name;
        }
    }
    ctx.values = values.items;
    ctx.trees = trees.items;
    // Decision 576 (4) — `compiler.custom(tree)` in a `-> expr T` template:
    // the tree is kept (`val <custom_tree_name> = tree`), the template is the
    // custom carrier the machinery knows (`@ExprCustom<T>`), and each return
    // hands the tree with its expression (`q.custom(tree, e)`).
    const keyword = if (returnType) |rt| ast.isExprKeywordReturn(rt) else false;
    if (keyword) for (body) |*st| if (compilerCall(st.expr)) |c| if (std.mem.eql(u8, c.callee, "custom") and c.args.len == 1) {
        st.expr = .{ .binding = .{ .loc = st.expr.getLoc(), .kind = .{ .localBind = .{ .name = custom_tree_name, .value = c.args[0].value, .mutable = false } } } };
        ctx.custom = true;
    };
    try walkStmts(&ctx, body);
    if (keyword) try liftReturns(&ctx, body);
    if (ctx.custom) returnRef.*.?.generic.name = "ExprCustom";
}

fn walkStmts(ctx: *Ctx, body: []ast.Stmt) error{OutOfMemory}!void {
    for (body) |*s| try walkExpr(ctx, &s.expr);
}

fn isIdent(e: ast.Expr, name: []const u8) bool {
    return e == .identifier and e.identifier.kind == .ident and std.mem.eql(u8, e.identifier.kind.ident, name);
}

fn contains(names: []const []const u8, n: []const u8) bool {
    for (names) |x| if (std.mem.eql(u8, x, n)) return true;
    return false;
}

const CallData = @FieldType(@FieldType(ast.CallExprOf(.untyped), "kind"), "call");

/// `compiler.<m>(…)`, if `e` is one.
fn compilerCall(e: ast.Expr) ?CallData {
    if (e != .call or e.call.kind != .call) return null;
    const c = e.call.kind.call;
    const r = c.receiver orelse return null;
    if (c.is_builtin or !isIdent(r.*, ast.compiler_keyword)) return null;
    return c;
}

fn box(ctx: *Ctx, e: ast.Expr) error{OutOfMemory}!*ast.Expr {
    const p = try ctx.alloc.create(ast.Expr);
    p.* = e;
    return p;
}

fn ident(ctx: *Ctx, name: []const u8, loc: ast.Loc) error{OutOfMemory}!*ast.Expr {
    return box(ctx, .{ .identifier = .{ .loc = loc, .kind = .{ .ident = name } } });
}

fn stringLit(ctx: *Ctx, text: []const u8, loc: ast.Loc) error{OutOfMemory}!*ast.Expr {
    return box(ctx, .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = text } } });
}

fn refusal(ctx: *Ctx, loc: ast.Loc, code: []const u8, message: []const u8, hint: []const u8) error{OutOfMemory}!ast.Expr {
    ctx.changed = true;
    const args = try ctx.alloc.alloc(ast.CallArg, 3);
    args[0] = .{ .label = null, .value = try stringLit(ctx, code, loc) };
    args[1] = .{ .label = null, .value = try stringLit(ctx, message, loc) };
    args[2] = .{ .label = null, .value = try stringLit(ctx, hint, loc) };
    return .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = refusal_builtin,
        .is_builtin = true,
        .args = args,
        .trailing = &.{},
    } } } };
}

fn methodCall(ctx: *Ctx, loc: ast.Loc, receiver: *ast.Expr, callee: []const u8, args: []ast.CallArg, trailing: anytype, typeArgs: ?[]ast.TypeRef) ast.Expr {
    _ = ctx;
    return .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = receiver,
        .callee = callee,
        .is_builtin = false,
        .args = args,
        .trailing = trailing,
        .typeArgs = typeArgs,
    } } } };
}

fn builtinCall(loc: ast.Loc, callee: []const u8, args: []ast.CallArg, trailing: anytype) ast.Expr {
    return .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = callee,
        .is_builtin = true,
        .args = args,
        .trailing = trailing,
    } } } };
}

fn fieldRead(ctx: *Ctx, loc: ast.Loc, receiver: *ast.Expr, member: []const u8) ast.Expr {
    _ = ctx;
    return .{ .identifier = .{ .loc = loc, .kind = .{ .identAccess = .{ .receiver = receiver, .member = member } } } };
}

fn labelled(args: []ast.CallArg, label: []const u8) ?ast.CallArg {
    for (args) |a| if (a.label) |l| if (std.mem.eql(u8, l, label)) return a;
    return null;
}

fn positional(ctx: *Ctx, args: []ast.CallArg) error{OutOfMemory}![]ast.CallArg {
    var n: usize = 0;
    for (args) |a| if (a.label == null) {
        n += 1;
    };
    const out = try ctx.alloc.alloc(ast.CallArg, n);
    var i: usize = 0;
    for (args) |a| if (a.label == null) {
        out[i] = a;
        i += 1;
    };
    return out;
}

/// The member `m` written on `compiler` at `loc`, read onto the machinery.
fn mapCall(ctx: *Ctx, loc: ast.Loc, c: anytype) error{OutOfMemory}!ast.Expr {
    const name = c.callee;
    const member = memberOf(name) orelse return refusal(ctx, loc, diagnostics.compiler_member_unknown, try std.fmt.allocPrint(ctx.alloc, "`Compiler` has no member `{s}`", .{name}), "The members of `compiler` are declared by the behavior `Compiler` in std's `compiler.bp` (decision 575 (3)).");
    if (member.kind == .property) return refusal(ctx, loc, diagnostics.compiler_member_unknown, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}` is read, not called", .{name}), "Write `compiler.src`, without parentheses (decision 575 (3)).");
    ctx.changed = true;
    const args = c.args;
    if (member.kind == .output) {
        const d = ctx.decl orelse return refusal(ctx, loc, diagnostics.compiler_output_outside_decorator, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}` writes to the annotated declaration, and only a decorator has one", .{name}), "A decorator is a function whose first parameter is `expr` — `fn mark(expr decl: unknown) { compiler.setMeta(…); }` (decision 575 (3)).");
        return methodCall(ctx, loc, try ident(ctx, d, loc), name, args, c.trailing, c.typeArgs);
    }
    if (std.mem.eql(u8, name, "fail")) {
        const pos = try positional(ctx, args);
        const at = labelled(args, "at");
        const span = labelled(args, "span");
        const target: *ast.Expr = if (at) |a| a.value else if (ctx.decl) |d| try ident(ctx, d, loc) else if (ctx.site) |s| try ident(ctx, s, loc) else {
            return builtinCall(loc, "comptimeError", pos, c.trailing);
        };
        if (span) |s| {
            const two = try ctx.alloc.alloc(ast.CallArg, 1 + pos.len);
            two[0] = .{ .label = null, .value = s.value };
            @memcpy(two[1..], pos);
            return methodCall(ctx, loc, target, "failAt", two, c.trailing, null);
        }
        return methodCall(ctx, loc, target, "fail", pos, c.trailing, null);
    }
    if (std.mem.eql(u8, name, "typeInfo")) return builtinCall(loc, "typeInfo", args, c.trailing);
    if (std.mem.eql(u8, name, "catalogue")) return builtinCall(loc, "TypeInfo.all", args, c.trailing);
    if (member.kind == .site) {
        const s = ctx.site orelse return refusal(ctx, loc, diagnostics.compiler_member_unknown, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}` reads a template's call site, and this body is no template", .{name}), "A template answers `-> expr T`; its body reads the call site through `compiler` (decision 576 (2)).");
        if (std.mem.eql(u8, name, "annotate")) {
            // `compiler.annotate(d, at: span)` → `q.annotate(d, span)`.
            const pos = try positional(ctx, args);
            const at = labelled(args, "at");
            const out = try ctx.alloc.alloc(ast.CallArg, pos.len + @intFromBool(at != null));
            @memcpy(out[0..pos.len], pos);
            if (at) |a| out[pos.len] = .{ .label = null, .value = a.value };
            return methodCall(ctx, loc, try ident(ctx, s, loc), name, out, c.trailing, c.typeArgs);
        }
        return methodCall(ctx, loc, try ident(ctx, s, loc), name, args, c.trailing, c.typeArgs);
    }
    // A read taking the `expr` / the handle first.
    if (args.len == 0) return refusal(ctx, loc, diagnostics.compiler_member_unknown, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}` takes the expression it reads first", .{name}), "Hand it the `expr` parameter or the declaration: `compiler.text(e)` (decision 576 (2)).");
    const first = args[0].value;
    const rest = args[1..];
    if (handleField(name)) |field| {
        if (std.mem.eql(u8, name, "name") and !isHandle(ctx, first.*)) {
            // The name an `expr` argument is written as.
            return methodCall(ctx, loc, first, "text", rest, c.trailing, null);
        }
        return fieldRead(ctx, loc, first, field);
    }
    // `compiler.meta<M>(d)` → `d.meta(M)` (298).
    if (std.mem.eql(u8, name, "meta") or std.mem.eql(u8, name, "metaAll")) {
        const ta = c.typeArgs orelse return refusal(ctx, loc, diagnostics.compiler_member_unknown, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}<M>(d)` names the meta type `M`", .{name}), "Write the record type the decorator set: `compiler.meta<Entity>(d)` (decision 298).");
        if (ta.len != 1 or ta[0] != .named) return refusal(ctx, loc, diagnostics.compiler_member_unknown, "the meta type is one named record type", "Write the record type the decorator set: `compiler.meta<Entity>(d)` (decision 298).");
        const one = try ctx.alloc.alloc(ast.CallArg, 1);
        one[0] = .{ .label = null, .value = try ident(ctx, ta[0].named, loc) };
        return methodCall(ctx, loc, first, name, one, c.trailing, null);
    }
    return methodCall(ctx, loc, first, name, rest, c.trailing, c.typeArgs);
}

/// Whether `e` names a declaration handle rather than an `expr` parameter:
/// the decorator's own, or any name that is no tree parameter (a `val` that
/// `compiler.lookup` / `compiler.tagDecl` answered).
fn isHandle(ctx: *Ctx, e: ast.Expr) bool {
    if (e != .identifier or e.identifier.kind != .ident) return true;
    const n = e.identifier.kind.ident;
    if (ctx.decl) |d| if (std.mem.eql(u8, d, n)) return true;
    return !contains(ctx.trees, n) and !contains(ctx.values, n);
}

/// `compiler.<p>` read without a call.
fn mapProperty(ctx: *Ctx, loc: ast.Loc, name: []const u8) error{OutOfMemory}!ast.Expr {
    ctx.changed = true;
    if (std.mem.eql(u8, name, "src")) return builtinCall(loc, "src", &.{}, &[_]ast.TrailingLambda{});
    if (std.mem.eql(u8, name, "module")) if (ctx.decl) |d| return fieldRead(ctx, loc, try ident(ctx, d, loc), "module");
    // Whether the annotated declaration is std's: its module is `std/…`.
    if (std.mem.eql(u8, name, "isStd")) if (ctx.decl) |d| {
        const args = try ctx.alloc.alloc(ast.CallArg, 1);
        args[0] = .{ .label = null, .value = try stringLit(ctx, "std/", loc) };
        const module = try box(ctx, fieldRead(ctx, loc, try ident(ctx, d, loc), "module"));
        return methodCall(ctx, loc, module, "startsWith", args, &[_]ast.TrailingLambda{}, null);
    };
    if (memberOf(name)) |m| if (m.kind == .property)
        return refusal(ctx, loc, diagnostics.compiler_member_unknown, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}` is read only in a decorator's body yet", .{name}), "The annotated declaration answers it (decision 575 (3)).");
    return refusal(ctx, loc, diagnostics.compiler_member_unknown, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}` is a call, or no member of `Compiler`", .{name}), "The members of `compiler` are declared by the behavior `Compiler` in std's `compiler.bp` (decision 575 (3)).");
}

fn runTimeRefusal(ctx: *Ctx, loc: ast.Loc) error{OutOfMemory}!ast.Expr {
    return refusal(ctx, loc, diagnostics.compiler_at_run_time, "`compiler` is the compiler of a body that runs at build, and this body runs when the program runs", "Read the compiler in a decorator, a template, a function called at build or a `comptime { … }` block (decision 575 (3)).");
}

fn treeRefusal(ctx: *Ctx, loc: ast.Loc) error{OutOfMemory}!ast.Expr {
    return refusal(ctx, loc, diagnostics.expr_captures_build, "a tree holds the code the program runs, and `compiler` exists only while it compiles", "Read the compiler in the decorator's body and hand the tree a `comptime` value or an `expr` (decision 575 (4), the tree rule).");
}

fn walkExpr(ctx: *Ctx, p: *ast.Expr) error{OutOfMemory}!void {
    const e = p.*;
    const loc = e.getLoc();
    // `compiler.name(d)!` — the handle's name is a `string` to the machinery.
    if (e == .call and e.call.kind == .call and e.call.kind.call.is_builtin and std.mem.eql(u8, e.call.kind.call.callee, ast.non_null_builtin_name) and e.call.kind.call.args.len == 1) {
        if (compilerCall(e.call.kind.call.args[0].value.*)) |inner| if (std.mem.eql(u8, inner.callee, "name") and inner.args.len == 1 and isHandle(ctx, inner.args[0].value.*)) {
            p.* = e.call.kind.call.args[0].value.*;
            return walkExpr(ctx, p);
        };
    }
    // `x is type` tests a value-or-type parameter itself (decision 297).
    if (e == .call and e.call.kind == .call and e.call.kind.call.is_builtin and std.mem.eql(u8, e.call.kind.call.callee, ast.is_builtin_name) and e.call.kind.call.args.len == 1) {
        const a = e.call.kind.call.args[0].value.*;
        if (a == .identifier and a.identifier.kind == .ident and contains(ctx.values, a.identifier.kind.ident)) return;
    }
    // A call of a `comptime` parameter, `rule(x)`: its value called
    // (`rule.value(x)` to the machinery, which refuses a function's value at
    // build — decision 364 (3)).
    if (e == .call and e.call.kind == .call) {
        const c = e.call.kind.call;
        if (!ctx.inTree and c.receiver == null and c.calleeExpr == null and !c.is_builtin and contains(ctx.values, c.callee) and !contains(ctx.shadow.items, c.callee)) {
            ctx.changed = true;
            p.call.kind.call.receiver = try ident(ctx, c.callee, loc);
            p.call.kind.call.callee = "value";
            for (p.call.kind.call.args) |*a| try walkExpr(ctx, a.value);
            return;
        }
    }
    if (compilerCall(e)) |c| {
        // Refused at the keyword itself.
        const at = c.receiver.?.getLoc();
        if (ctx.runTime) {
            p.* = try runTimeRefusal(ctx, at);
            return;
        }
        if (ctx.inTree) {
            p.* = try treeRefusal(ctx, at);
            return;
        }
        // The arguments first: a member and a wrapper are trees.
        const tree = std.mem.eql(u8, c.callee, "addMember") or std.mem.eql(u8, c.callee, "wrapWith");
        const reads = if (memberOf(c.callee)) |m| m.kind == .read else false;
        for (c.args, 0..) |*a, i| {
            // The expression a read is about — `at:` of `fail`, the first
            // argument of any other read — is the parameter itself, even a
            // `comptime` one (its argument is where `fail` points).
            const about = reads and if (std.mem.eql(u8, c.callee, "fail"))
                (if (a.label) |l| std.mem.eql(u8, l, "at") else false)
            else
                (i == 0 and a.label == null);
            if (about and a.value.* == .identifier and a.value.identifier.kind == .ident) continue;
            const fnArg = a.value.* == .function;
            const saved = ctx.inTree;
            if (tree and fnArg) ctx.inTree = true;
            defer ctx.inTree = saved;
            if (tree and fnArg) try walkTree(ctx, a.value) else try walkExpr(ctx, a.value);
        }
        for (c.trailing) |*t| try walkAny(ctx, t);
        p.* = try mapCall(ctx, loc, c);
        return;
    }
    if (e == .identifier) switch (e.identifier.kind) {
        .ident => |n| {
            if (std.mem.eql(u8, n, ast.compiler_keyword)) {
                p.* = if (ctx.runTime) try runTimeRefusal(ctx, loc) else if (ctx.inTree) try treeRefusal(ctx, loc) else try refusal(ctx, loc, diagnostics.compiler_member_unknown, "`compiler` is read through its members", "Write `compiler.<member>` — `compiler.src`, `compiler.fail(…)` (decision 575 (3)).");
                return;
            }
            if (!ctx.inTree and contains(ctx.values, n) and !contains(ctx.shadow.items, n)) {
                ctx.changed = true;
                p.* = fieldRead(ctx, loc, try ident(ctx, n, loc), "value");
            }
            return;
        },
        .identAccess => |ia| {
            if (isIdent(ia.receiver.*, ast.compiler_keyword)) {
                const at = ia.receiver.getLoc();
                p.* = if (ctx.runTime) try runTimeRefusal(ctx, at) else if (ctx.inTree) try treeRefusal(ctx, at) else try mapProperty(ctx, loc, ia.member);
                return;
            }
            return walkExpr(ctx, ia.receiver);
        },
        .dotIdent => return,
    };
    if (e == .function) {
        // A lambda's parameters shadow the value parameters they name.
        const mark = ctx.shadow.items.len;
        for (e.function.kind.params) |n| if (contains(ctx.values, n)) try ctx.shadow.append(ctx.scratch, n);
        defer ctx.shadow.shrinkRetainingCapacity(mark);
        return walkAny(ctx, &p.function);
    }
    switch (p.*) {
        inline else => |*inner| try walkAny(ctx, inner),
    }
}

/// A tree: a value parameter is the parameter itself, spliced (no `.value`).
fn walkTree(ctx: *Ctx, p: *ast.Expr) error{OutOfMemory}!void {
    const savedValues = ctx.values;
    ctx.values = &.{};
    defer ctx.values = savedValues;
    try walkExpr(ctx, p);
}

/// Every `Expr` reachable from `v`, walked in place.
fn walkAny(ctx: *Ctx, v: anytype) error{OutOfMemory}!void {
    const T = @TypeOf(v.*);
    if (T == ast.Expr) return walkExpr(ctx, v);
    if (T == ast.TypeRef or T == ast.Pattern) return;
    switch (@typeInfo(T)) {
        .pointer => |ptr| switch (ptr.size) {
            .one => return walkAny(ctx, @constCast(v.*)),
            .slice => {
                if (ptr.child == u8 or ptr.child == []const u8) return;
                for (@constCast(v.*)) |*item| try walkAny(ctx, item);
            },
            else => {},
        },
        .optional => if (v.*) |_| try walkAny(ctx, &(v.*.?)),
        .@"struct" => |s| inline for (s.fields) |f| {
            if (f.is_comptime) continue;
            try walkAny(ctx, &@field(v.*, f.name));
        },
        .@"union" => |u| if (u.tag_type != null) switch (v.*) {
            inline else => |*inner| try walkAny(ctx, inner),
        },
        else => {},
    }
}

/// Decision 575 (4) — `-> expr T`: each `return e` of the template's own
/// body hands `e` to the call site. A tree parameter and a call that already
/// answers a tree (the site's `build`, `custom`, `@expr`, `@code`) stay; any
/// other expression is lifted (`@expr(e)`).
fn liftReturns(ctx: *Ctx, body: []ast.Stmt) error{OutOfMemory}!void {
    for (body) |*s| try liftIn(ctx, &s.expr);
}

fn liftIn(ctx: *Ctx, p: *ast.Expr) error{OutOfMemory}!void {
    switch (p.*) {
        .function => return,
        .jump => |*j| if (j.kind == .@"return") {
            if (j.kind.@"return") |r| {
                if (!answersTree(ctx, r.*)) {
                    const args = try ctx.alloc.alloc(ast.CallArg, 1);
                    args[0] = .{ .label = null, .value = try box(ctx, r.*) };
                    r.* = builtinCall(r.getLoc(), "expr", args, &[_]ast.TrailingLambda{});
                }
                if (ctx.custom) if (ctx.site) |site| {
                    const args = try ctx.alloc.alloc(ast.CallArg, 2);
                    args[0] = .{ .label = null, .value = try ident(ctx, custom_tree_name, r.getLoc()) };
                    args[1] = .{ .label = null, .value = try box(ctx, r.*) };
                    r.* = methodCall(ctx, r.getLoc(), try ident(ctx, site, r.getLoc()), "custom", args, &[_]ast.TrailingLambda{}, null);
                };
            }
            return;
        },
        else => {},
    }
    switch (p.*) {
        inline else => |*inner| try liftAny(ctx, inner),
    }
}

fn liftAny(ctx: *Ctx, v: anytype) error{OutOfMemory}!void {
    const T = @TypeOf(v.*);
    if (T == ast.Expr) return liftIn(ctx, v);
    if (T == ast.TypeRef or T == ast.Pattern) return;
    switch (@typeInfo(T)) {
        .pointer => |ptr| switch (ptr.size) {
            .one => return liftAny(ctx, @constCast(v.*)),
            .slice => {
                if (ptr.child == u8 or ptr.child == []const u8) return;
                for (@constCast(v.*)) |*item| try liftAny(ctx, item);
            },
            else => {},
        },
        .optional => if (v.*) |_| try liftAny(ctx, &(v.*.?)),
        .@"struct" => |s| inline for (s.fields) |f| {
            if (f.is_comptime) continue;
            try liftAny(ctx, &@field(v.*, f.name));
        },
        .@"union" => |u| if (u.tag_type != null) switch (v.*) {
            inline else => |*inner| try liftAny(ctx, inner),
        },
        else => {},
    }
}

fn answersTree(ctx: *Ctx, e: ast.Expr) bool {
    if (e == .identifier and e.identifier.kind == .ident) return contains(ctx.trees, e.identifier.kind.ident);
    if (e == .call and e.call.kind == .call) {
        const c = e.call.kind.call;
        if (c.is_builtin) return std.mem.eql(u8, c.callee, "expr") or std.mem.eql(u8, c.callee, "code");
        if (c.receiver) |r| if (ctx.site) |s| if (isIdent(r.*, s))
            return std.mem.eql(u8, c.callee, "build") or std.mem.eql(u8, c.callee, "custom");
        if (c.receiver) |r| if (r.* == .identifier and r.identifier.kind == .ident and contains(ctx.trees, r.identifier.kind.ident))
            return std.mem.eql(u8, c.callee, "build") or std.mem.eql(u8, c.callee, "custom");
    }
    return false;
}
