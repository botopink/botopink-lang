//! Decisions 575 (3), (4) and 576 — the surface a build-time body talks to the
//! compiler through, read onto the machinery the checker, the decorator and
//! template evaluators and the comptime runtime already know. Run once by
//! `Parser.parse`, after `syntax_params.zig` (the formatter parses with
//! `Parser.keep_surface` and sees the program as written).
//!
//! - `compiler.<member>(…)` — the `Compiler` of the point (`libs/std/src/
//!   compiler.bp`): in a decorator the annotated declaration, read through the
//!   declaration handle the parser gave the decorator's first `expr`
//!   (`ast.decl_type_name`); in a template the call site, read through the
//!   template's literal; elsewhere the builtins of the point. `members` is
//!   the table a unit test holds to `compiler.bp`.
//! - `comptime x: T` (`Param.arrival == .value`) — a bare read of `x` is the
//!   value (`x.value` to the machinery; `comptime/syntax_param.zig` erases it for
//!   the code that runs). Inside a tree — a member or a wrapper a decorator
//!   writes — `x` stays the parameter, spliced where it was written.
//! - `-> expr T` — a template's `return e` hands the expression `e` to the call
//!   site: a parameter's tree as it is, anything else lifted (`@expr(e)` to
//!   the template machinery).
//! - The refusals — `compiler-at-run-time`, `compiler-output-outside-decorator`,
//!   `compiler-member-unknown` — are written as the
//!   reserved builtin `refusal_builtin` at the place, which the checker
//!   reports there (`infer.zig`).

const std = @import("std");
const ast = @import("../ast.zig");
const diagnostics = @import("../comptime/diagnostics.zig");
const memberFn = @import("../comptime/member_fn.zig");

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

/// One member: its name, what it is, and how each of its parameters after
/// `self` arrives (decision 616) — `syntax`, the code as written; `value`
/// (`comptime`), a value known at build; `written`, a plain value. A
/// property has none.
pub const Member = struct { name: []const u8, kind: Kind, params: []const ast.Arrival = &.{} };

const S: ast.Arrival = .syntax;
const V: ast.Arrival = .value;
const W: ast.Arrival = .written;

/// The `Compiler` members built so far — 575 (3) and 576 (2), (3), less
/// B-139 and B-140's (`setBuiltin`, `embed`, `record`, `fields`
/// over a type, `optional`, `required`). `comptime/tests/compiler_
/// members.zig` holds it to `libs/std/src/compiler.bp`, member for member and
/// arrival for arrival (decision 616).
pub const members = [_]Member{
    .{ .name = "src", .kind = .property },
    .{ .name = "module", .kind = .property },
    .{ .name = "package", .kind = .property },
    .{ .name = "isStd", .kind = .property },
    .{ .name = "fail", .kind = .read, .params = &.{ W, S, W } },
    .{ .name = "setMeta", .kind = .output, .params = &.{S} },
    .{ .name = "addMeta", .kind = .output, .params = &.{S} },
    .{ .name = "addMember", .kind = .output, .params = &.{ W, S } },
    .{ .name = "addType", .kind = .output, .params = &.{ W, V } },
    .{ .name = "wrapWith", .kind = .output, .params = &.{S} },
    .{ .name = "init", .kind = .output, .params = &.{S} },
    .{ .name = "implement", .kind = .output, .params = &.{V} },
    .{ .name = "find", .kind = .site, .params = &.{ W, W } },
    .{ .name = "typeInfo", .kind = .site, .params = &.{V} },
    .{ .name = "text", .kind = .read, .params = &.{S} },
    .{ .name = "name", .kind = .read, .params = &.{S} },
    .{ .name = "source", .kind = .read, .params = &.{S} },
    .{ .name = "context", .kind = .read, .params = &.{S} },
    .{ .name = "lookup", .kind = .read, .params = &.{ S, W } },
    .{ .name = "bindings", .kind = .read, .params = &.{S} },
    .{ .name = "build", .kind = .site, .params = &.{V} },
    .{ .name = "buildType", .kind = .site, .params = &.{V} },
    .{ .name = "note", .kind = .site, .params = &.{W} },
    .{ .name = "tagDecl", .kind = .site, .params = &.{ W, W, S } },
    .{ .name = "annotate", .kind = .site, .params = &.{ S, W } },
    .{ .name = "custom", .kind = .site, .params = &.{W} },
    .{ .name = "kind", .kind = .read, .params = &.{S} },
    .{ .name = "moduleOf", .kind = .read, .params = &.{S} },
    .{ .name = "meta", .kind = .read, .params = &.{S} },
    .{ .name = "metaAll", .kind = .read, .params = &.{S} },
    .{ .name = "attr", .kind = .read, .params = &.{ S, W } },
    .{ .name = "component", .kind = .read, .params = &.{S} },
    .{ .name = "hooks", .kind = .read, .params = &.{S} },
    .{ .name = "fields", .kind = .read, .params = &.{S} },
    .{ .name = "methods", .kind = .read, .params = &.{S} },
    .{ .name = "params", .kind = .read, .params = &.{S} },
    .{ .name = "returnType", .kind = .read, .params = &.{S} },
    .{ .name = "owner", .kind = .read, .params = &.{S} },
    .{ .name = "annotations", .kind = .read, .params = &.{S} },
    .{ .name = "variants", .kind = .read, .params = &.{S} },
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
    /// Parameters whose argument is a tree (`syntax x: T`, a template's).
    trees: []const []const u8 = &.{},
    /// `syntax x: T` parameters (not the handle): opaque in the body.
    exprs: []const []const u8 = &.{},
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
    /// Decision 614 — the `val`s an executor's `compiler.*` reads became,
    /// waiting for `walkStmts` to put them before the statement.
    hoisted: std.ArrayListUnmanaged(ast.Stmt) = .empty,
    /// How many such `val`s the body holds (their names, `__bp_build_<k>`).
    hoistCount: usize = 0,
    /// How many `compiler.*` reads the pass mapped so far.
    mapped: usize = 0,
};

/// Read the program's new surface onto the machinery (see the file comment).
/// A program that writes none of it is left untouched.
pub fn expandProgram(alloc: std.mem.Allocator, program: *ast.Program) error{OutOfMemory}!void {
    // Decision 579 — `compiler` is std's value, bound by its import:
    // `import {compiler} from "std";` (`import {compiler};` in std), an alias
    // included. A module that does not import it has no `compiler`.
    const saved_name = compiler_name;
    defer compiler_name = saved_name;
    compiler_name = boundCompilerName(program.*);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const P = Pass{ .alloc = alloc, .scratch = arena.allocator() };
    for (program.decls) |*d| switch (d.*) {
        .@"fn" => |*f| try expandFn(P, f.name, f.params, &f.returnType, &f.genericParams, &f.body),
        .type_ => |*t| try expandType(P, t),
        .behavior => |*b| for (b.methods) |*m| if (m.body) |*body| try expandFn(P, m.name, m.params, &m.returnType, &m.genericParams, body),
        .implement => |*i| for (i.methods) |*m| try expandFn(P, m.name, m.params, &none, null, &m.body),
        .extend => |*e| for (e.methods) |*m| try expandFn(P, m.name, m.params, &none, null, &m.body),
        .@"test" => |*t| {
            var ctx: Ctx = .{ .alloc = alloc, .scratch = P.scratch, .runTime = true };
            try walkStmts(&ctx, &t.body);
        },
        .val => |*v| {
            var ctx: Ctx = .{ .alloc = alloc, .scratch = P.scratch };
            try walkExpr(&ctx, v.value);
        },
        else => {},
    };
}

const Pass = struct { alloc: std.mem.Allocator, scratch: std.mem.Allocator };

/// The name the module binds std's `compiler` value to (decision 579), while
/// `expandProgram` runs.
threadlocal var compiler_name: ?[]const u8 = null;

/// The local name of `import {compiler} from "std";` / `import {compiler};`
/// (a std module's), or null when the module does not import it.
fn boundCompilerName(program: ast.Program) ?[]const u8 {
    for (program.decls) |d| if (d == .use) {
        const u = d.use;
        const fromStd = switch (u.source) {
            .module => |m| std.mem.eql(u8, m, "std"),
            .root => true,
            .key => false,
        };
        if (!fromStd) continue;
        for (u.imports) |imp| {
            if (imp.segments.len == 1 and std.mem.eql(u8, imp.segments[0], ast.compiler_keyword)) return imp.name();
        }
    };
    return null;
}

/// Whether `e` is the name the module binds `compiler` to.
fn isCompiler(e: ast.Expr) bool {
    const n = compiler_name orelse return false;
    return isIdent(e, n);
}

/// The return of a function that writes none (an `implement` method's).
var none: ?ast.TypeRef = null;

/// The local a `-> expr T` template's `compiler.custom(tree)` keeps its tree
/// in (decision 576 (4)); no source can spell it.
const custom_tree_name = "__bp_customTree";

fn expandType(P: Pass, t: *ast.TypeDecl) error{OutOfMemory}!void {
    for (t.methods) |*m| if (m.body) |*body| try expandFn(P, m.name, m.params, &m.returnType, &m.genericParams, body);
    for (t.assocTypes) |*inner| try expandType(P, inner);
}

fn expandFn(P: Pass, name: []const u8, params: []ast.Param, returnRef: *?ast.TypeRef, gps: ?*[]ast.GenericParam, bodyRef: *[]ast.Stmt) error{OutOfMemory}!void {
    const body = bodyRef.*;
    // Decision 578 (1) — a template by its text parameter answers its return
    // (`T`, or `anyvalue`: the type the built code has at each call) as the
    // tree the machinery knows; its returns are lifted as `-> expr T`'s were.
    var byText = false;
    if (ast.templateTextIndex(params) != null) {
        const already = if (returnRef.*) |rt| rt.isTemplateReturnType() else false;
        if (!already) {
            byText = true;
            const written: ast.TypeRef = returnRef.* orelse .{ .named = ast.anyvalue_type_name };
            var inner = written;
            if (written == .named and std.mem.eql(u8, written.named, ast.anyvalue_type_name)) {
                inner = .{ .named = ast.anyvalue_param_name };
                if (gps) |g| {
                    const grown = try P.alloc.alloc(ast.GenericParam, g.len + 1);
                    @memcpy(grown[0..g.len], g.*);
                    grown[g.len] = .{ .name = ast.anyvalue_param_name };
                    g.* = grown;
                }
            }
            const args = try P.alloc.alloc(ast.TypeRef, 1);
            args[0] = inner;
            returnRef.* = .{ .generic = .{ .name = ast.expr_type_name, .args = args, .is_builtin = true } };
        }
    }
    const returnType = returnRef.*;
    const alloc = P.scratch;
    var ctx: Ctx = .{ .alloc = P.alloc, .scratch = P.scratch };
    // Decision 577 (4) — a template takes its text (a `syntax self` receiver
    // before it for a method, the annotated declaration after it for an
    // annotation) and nothing else: refused at the parameter.
    if (ast.templateTextIndex(params)) |q| for (params, 0..) |p, i| {
        if (i <= q) continue;
        if (i == q + 1 and p.typeRef.isDeclType()) continue;
        if (body.len == 0) break;
        body[0].expr = try refusal(&ctx, if (p.loc.line != 0) p.loc else p.typeLoc, diagnostics.template_signature, try std.fmt.allocPrint(P.alloc, "the template `{s}` takes its text and nothing else, and declares `{s}`", .{ name, p.name }), "A template's parameters are its text `syntax q: string` (after a `syntax self: R` receiver for a method), and for an annotation the declaration `syntax decl: unknown` (decision 577 (4)); make it an ordinary function, or read the input from the text.");
        return;
    };
    ctx.runTime = std.mem.eql(u8, name, "main");
    if (params.len > 0 and params[0].typeRef.isDeclType()) ctx.decl = params[0].name;
    // A template annotation's handle is its second parameter (decision 311).
    if (params.len > 1 and params[1].typeRef.isDeclType()) ctx.decl = params[1].name;
    const template = if (returnType) |rt| rt.isTemplateReturnType() else false;
    ctx.template = template;
    var values: std.ArrayListUnmanaged([]const u8) = .empty;
    var trees: std.ArrayListUnmanaged([]const u8) = .empty;
    var exprs: std.ArrayListUnmanaged([]const u8) = .empty;
    for (params, 0..) |p, i| {
        if (p.arrival == .value) try values.append(alloc, p.name);
        if (p.arrival == .syntax and !p.typeRef.isDeclType()) try exprs.append(alloc, p.name);
        const tree = p.exprWrapped or p.typeRef.isExprType() or p.typeRef.isExprCustomType();
        if (p.arrival != .value and tree) try trees.append(alloc, p.name);
        if (template and ctx.site == null and p.typeRef.isExprType()) {
            // A template method's literal is its second parameter (311 (3)).
            if (!(i == 0 and (ast.isTemplateMethodSignature(params, returnType) or ast.templateTextIndex(params) == 1))) ctx.site = p.name;
        }
    }
    ctx.values = values.items;
    ctx.trees = trees.items;
    ctx.exprs = exprs.items;
    // Decision 576 (4) — `compiler.custom(tree)` in a `-> expr T` template:
    // the tree is kept (`val <custom_tree_name> = tree`), the template is the
    // custom carrier the machinery knows (`@ExprCustom<T>`), and each return
    // hands the tree with its expression (`q.custom(tree, e)`).
    const keyword = byText or (if (returnType) |rt| ast.isExprKeywordReturn(rt) else false);
    if (keyword) for (body) |*st| if (compilerCall(st.expr)) |c| if (std.mem.eql(u8, c.callee, "custom") and c.args.len == 1) {
        st.expr = .{ .binding = .{ .loc = st.expr.getLoc(), .kind = .{ .localBind = .{ .name = custom_tree_name, .value = c.args[0].value, .mutable = false } } } };
        ctx.custom = true;
    };
    try walkStmts(&ctx, bodyRef);
    if (keyword) try liftReturns(&ctx, bodyRef.*);
    if (ctx.custom) returnRef.*.?.generic.name = ast.expr_custom_type_name;
}

/// Each statement walked in place; the `val`s a statement's executor hoists
/// (decision 614, `hoistBuildReads`) are put right before it.
fn walkStmts(ctx: *Ctx, body: *[]ast.Stmt) error{OutOfMemory}!void {
    var i: usize = 0;
    while (i < body.len) : (i += 1) {
        const mark = ctx.hoisted.items.len;
        try walkExpr(ctx, &body.*[i].expr);
        const added = ctx.hoisted.items.len - mark;
        if (added == 0) continue;
        const grown = try ctx.alloc.alloc(ast.Stmt, body.len + added);
        @memcpy(grown[0..i], body.*[0..i]);
        @memcpy(grown[i .. i + added], ctx.hoisted.items[mark..]);
        @memcpy(grown[i + added ..], body.*[i..]);
        body.* = grown;
        i += added;
        ctx.hoisted.shrinkRetainingCapacity(mark);
    }
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
    if (c.is_builtin or !isCompiler(r.*)) return null;
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
        const d = ctx.decl orelse return refusal(ctx, loc, diagnostics.compiler_output_outside_decorator, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}` writes to the annotated declaration, and only a decorator has one", .{name}), "A decorator is a function whose first parameter is `syntax` — `fn mark(syntax decl: unknown) { compiler.setMeta(…); }` (decision 575 (3)).");
        // Decision 615 — `compiler.init(f)` is the handle's executor output,
        // `decl.compile(f)` to the machinery (`member_fn.compile_name`).
        const handleName = if (std.mem.eql(u8, name, "init")) "compile" else name;
        return methodCall(ctx, loc, try ident(ctx, d, loc), handleName, args, c.trailing, c.typeArgs);
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
    if (std.mem.eql(u8, name, "find")) return builtinCall(loc, "TypeInfo.all", args, c.trailing);
    if (member.kind == .site) {
        const s = ctx.site orelse return refusal(ctx, loc, diagnostics.compiler_member_unknown, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}` reads a template's call site, and this body is no template", .{name}), "A template answers `-> expr T`; its body reads the call site through `compiler` (decision 576 (2)).");
        if (std.mem.eql(u8, name, "buildType"))
            return refusal(ctx, loc, diagnostics.compiler_member_unknown, "`compiler.buildType(source)` builds a type only as `compiler.addType`'s source yet", "Write `compiler.addType(name, compiler.buildType(\"(…)\"))`; a derived type built from its text joins with step B-140 (decision 578 (3)).");
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
    if (args.len == 0) return refusal(ctx, loc, diagnostics.compiler_member_unknown, try std.fmt.allocPrint(ctx.alloc, "`compiler.{s}` takes the expression it reads first", .{name}), "Hand it the `syntax` parameter or the declaration: `compiler.text(e)` (decision 576 (2)).");
    const first = args[0].value;
    const rest = args[1..];
    if (handleField(name)) |field| {
        if (std.mem.eql(u8, name, "name")) {
            // Decision 612 — an expression written right there that has no
            // name is refused at it.
            if (namelessKind(first.*)) |kind| return refusal(ctx, first.getLoc(), diagnostics.syntax_has_no_name, try std.fmt.allocPrint(ctx.alloc, "this argument is {s}: it has no name", .{kind}), "`compiler.name(e)` answers the name a declaration, a named function or a type is written as (decision 612); read the text with `compiler.text(e)`.");
            // The name a `syntax` argument is written as: in a decorator,
            // refused at the annotation's argument when it has none.
            if (!isHandle(ctx, first.*)) return methodCall(ctx, loc, first, if (ctx.decl != null) "name" else "text", rest, c.trailing, null);
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

/// Decision 612 — what `e`, written as `compiler.name`'s argument, is when
/// it has no name; null for a name or a path.
fn namelessKind(e: ast.Expr) ?[]const u8 {
    return switch (e) {
        .function => "a lambda",
        .literal => "a literal",
        .collection => "an array",
        .call => "a call",
        .binaryOp, .unaryOp => "an operator expression",
        else => null,
    };
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

/// `{ -> e() }` — the executor `e` names, called (decision 575 (3)); the call
/// is the lambda's tail (decision 409), so an `e` that answers a value is
/// refused at it like any executor.
fn executorOf(ctx: *Ctx, e: *ast.Expr) error{OutOfMemory}!*ast.Expr {
    const loc = e.getLoc();
    const named = e.* == .identifier and e.identifier.kind == .ident;
    const call: ast.Expr = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = if (named) e.identifier.kind.ident else "",
        .calleeExpr = if (named) null else e,
        .is_builtin = false,
        .args = &.{},
        .trailing = &.{},
    } } } };
    const body = try ctx.alloc.alloc(ast.Stmt, 1);
    body[0] = .{ .expr = call, .tail = .value };
    return box(ctx, .{ .function = .{ .loc = loc, .kind = .{ .syntax = .lambda, .params = &.{}, .body = body } } });
}

/// `compiler.<p>` read without a call.
/// `compiler.src` is located where `compiler` is written: the place it reads.
fn mapProperty(ctx: *Ctx, loc: ast.Loc, name: []const u8) error{OutOfMemory}!ast.Expr {
    ctx.changed = true;
    ctx.mapped += 1;
    if (std.mem.eql(u8, name, "src")) return builtinCall(loc, "src", &.{}, &[_]ast.TrailingLambda{});
    if (std.mem.eql(u8, name, "module")) if (ctx.decl) |d| return fieldRead(ctx, loc, try ident(ctx, d, loc), "module");
    if (std.mem.eql(u8, name, "package")) if (ctx.decl) |d| return fieldRead(ctx, loc, try ident(ctx, d, loc), "package");
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

/// Decision 614 — every `compiler.*` read the executor `f` writes is
/// evaluated at build: replaced by the name of a `val` that holds it
/// (`__bp_build_<k>`, queued on `ctx.hoisted` for `walkStmts` to put before
/// the `compiler.init` statement), so the executor reads it as the literal
/// of its value, exactly as a `val` the body wrote before it. A read whose
/// argument names a value of the tree — a parameter of a lambda in it, a
/// value it binds — is refused at that argument (`compiler-arg-at-run-time`)
/// only at a `comptime` position; a `syntax` position takes the name as written
/// and the read folds to a literal (decision 642). Every tree a decorator
/// hands the compiler — executor, member, wrapper — is hoisted so.
fn hoistBuildReads(ctx: *Ctx, f: *ast.Expr) error{OutOfMemory}!void {
    const set = memberFn.boundNames(ctx.scratch, &.{}, &[_]ast.Stmt{.{ .expr = f.* }}) catch return error.OutOfMemory;
    var bound: std.ArrayListUnmanaged([]const u8) = .empty;
    var it = set.keyIterator();
    while (it.next()) |k| try bound.append(ctx.scratch, k.*);
    try hoistIn(ctx, f, bound.items);
}

fn hoistIn(ctx: *Ctx, p: *ast.Expr, bound: []const []const u8) error{OutOfMemory}!void {
    const e = p.*;
    // A `comptime e` in a tree is the build's own (the tree rule splices its
    // answer): `walkExpr` reads the compiler there, nothing is hoisted.
    if (e == .comptime_ and e.comptime_.kind == .comptimeExpr) return;
    // `compiler.name(d)` is hoisted whole: the `!` reads the build's answer.
    var read = false;
    if (e == .call and e.call.kind == .call and e.call.kind.call.is_builtin and std.mem.eql(u8, e.call.kind.call.callee, ast.non_null_builtin_name) and e.call.kind.call.args.len == 1) {
        if (compilerCall(e.call.kind.call.args[0].value.*) != null) read = true;
    }
    if (!read and compilerCall(e) != null) read = true;
    if (!read and e == .identifier and e.identifier.kind == .identAccess and isCompiler(e.identifier.kind.identAccess.receiver.*)) read = true;
    if (read) {
        if (try runTimeArgument(ctx, e, bound)) |at| {
            p.* = try refusal(ctx, at.loc, diagnostics.compiler_arg_at_run_time, try std.fmt.allocPrint(ctx.alloc, "`{s}` is a value of the tree, which exists only when the program runs, and the `comptime` parameter `{s}` of `compiler.{s}` takes only what the build knows", .{ at.name, at.param, at.callee }), "A `comptime` argument of a `compiler.*` read inside a tree is evaluated at build: hand it a parameter of the decorator or a `val` of its body, never a value the tree computes (decisions 614, 642).");
            return;
        }
        // A `syntax` argument that is a name of the tree: the name as written.
        if (try foldSyntax(ctx, e, bound)) |lit| {
            p.* = lit;
            return;
        }
        // A read over a name the tree binds is never hoisted: the decorator's
        // body does not bind it (a nameless expression keeps its refusal).
        if (readCall(e)) |rc| if (rc.args.len == 1 and try readsTreeName(ctx, rc.args[0].value.*, bound)) return;
        const name = try std.fmt.allocPrint(ctx.alloc, "{s}{d}", .{ memberFn.build_read_prefix, ctx.hoistCount });
        ctx.hoistCount += 1;
        const loc = e.getLoc();
        const value = try box(ctx, e);
        // The read itself, mapped as any read of the body is.
        try walkExpr(ctx, value);
        try ctx.hoisted.append(ctx.scratch, .{ .expr = .{ .binding = .{ .loc = loc, .kind = .{ .localBind = .{ .name = name, .value = value, .mutable = false } } } } });
        p.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = name } } };
        return;
    }
    switch (p.*) {
        inline else => |*inner| try hoistAny(ctx, inner, bound),
    }
}

fn hoistAny(ctx: *Ctx, v: anytype, bound: []const []const u8) error{OutOfMemory}!void {
    const T = @TypeOf(v.*);
    if (T == ast.Expr) return hoistIn(ctx, v, bound);
    if (T == ast.TypeRef or T == ast.Pattern) return;
    switch (@typeInfo(T)) {
        .pointer => |ptr| switch (ptr.size) {
            .one => return hoistAny(ctx, @constCast(v.*), bound),
            .slice => {
                if (ptr.child == u8 or ptr.child == []const u8) return;
                for (@constCast(v.*)) |*item| try hoistAny(ctx, item, bound);
            },
            else => {},
        },
        .optional => if (v.*) |_| try hoistAny(ctx, &(v.*.?), bound),
        .@"struct" => |st| inline for (st.fields) |fl| {
            if (fl.is_comptime) continue;
            try hoistAny(ctx, &@field(v.*, fl.name), bound);
        },
        .@"union" => |u| if (u.tag_type != null) switch (v.*) {
            inline else => |*inner| try hoistAny(ctx, inner, bound),
        },
        else => {},
    }
}

const RunTimeArg = struct { name: []const u8, loc: ast.Loc, param: []const u8, callee: []const u8 };

/// The `compiler.*` call of a hoisted read, `!`-wrapped or not.
fn readCall(read: ast.Expr) ?CallData {
    if (compilerCall(read)) |c| return c;
    if (read == .call and read.call.kind == .call and read.call.kind.call.args.len == 1) return compilerCall(read.call.kind.call.args[0].value.*);
    return null;
}

/// The name of the `comptime` parameter of a `Compiler` member (`compiler.bp`).
fn valueParamName(callee: []const u8) []const u8 {
    return if (std.mem.eql(u8, callee, "typeInfo")) "t" else "source";
}

/// The first name a read's `comptime` arguments write that the tree binds
/// (decision 642): a `syntax` position takes its argument as written, so it
/// is never at run time.
fn runTimeArgument(ctx: *Ctx, read: ast.Expr, bound: []const []const u8) error{OutOfMemory}!?RunTimeArg {
    if (bound.len == 0) return null;
    const c = readCall(read) orelse return null;
    const m = memberOf(c.callee) orelse return null;
    for (c.args, 0..) |a, i| {
        if (i >= m.params.len or m.params[i] != .value) continue;
        const body = try ctx.scratch.alloc(ast.Stmt, 1);
        body[0] = .{ .expr = a.value.* };
        const lambda: ast.FunctionExpr = .{ .loc = a.value.getLoc(), .kind = .{ .syntax = .lambda, .params = &.{}, .body = body } };
        for (memberFn.freeNames(ctx.scratch, lambda) catch return error.OutOfMemory) |n| {
            if (contains(bound, n.name)) return .{ .name = n.name, .loc = n.loc, .param = valueParamName(c.callee), .callee = c.callee };
        }
    }
    return null;
}

/// Decision 642 — a `syntax` parameter of `Compiler` receives its argument as
/// written. `compiler.text(e)` where `e` reads a name the tree binds (a
/// parameter of a lambda in it, a value it binds; not the declaration handle,
/// and whatever a decorator parameter is called) is the literal of `e`'s
/// source; `compiler.name(e)` is the literal of the name of an identifier or
/// of a member path (its last segment). Null when the read names nothing of
/// the tree.
fn foldSyntax(ctx: *Ctx, read: ast.Expr, bound: []const []const u8) error{OutOfMemory}!?ast.Expr {
    const c = readCall(read) orelse return null;
    if (c.args.len != 1 or c.args[0].label != null) return null;
    const isName = std.mem.eql(u8, c.callee, "name");
    if (!isName and !std.mem.eql(u8, c.callee, "text")) return null;
    const a = c.args[0].value.*;
    if (!try readsTreeName(ctx, a, bound)) return null;
    if (isName) {
        const n = nameOf(a) orelse return null;
        ctx.changed = true;
        return (try stringLit(ctx, n, read.getLoc())).*;
    }
    const format = @import("../format.zig");
    var f = format.Formatter.init(ctx.scratch);
    const doc = f.fmtExpr(a) catch return error.OutOfMemory;
    const text = format.render(ctx.alloc, doc, 100000) catch return error.OutOfMemory;
    ctx.changed = true;
    return (try stringLit(ctx, std.mem.trim(u8, text, " \n"), read.getLoc())).*;
}

/// Whether `e` reads a name the tree binds that is not the declaration handle.
fn readsTreeName(ctx: *Ctx, e: ast.Expr, bound: []const []const u8) error{OutOfMemory}!bool {
    if (bound.len == 0) return false;
    const body = try ctx.scratch.alloc(ast.Stmt, 1);
    body[0] = .{ .expr = e };
    const lambda: ast.FunctionExpr = .{ .loc = e.getLoc(), .kind = .{ .syntax = .lambda, .params = &.{}, .body = body } };
    for (memberFn.freeNames(ctx.scratch, lambda) catch return error.OutOfMemory) |n| {
        if (!contains(bound, n.name)) continue;
        if (ctx.decl) |d| if (std.mem.eql(u8, d, n.name)) continue;
        return true;
    }
    return false;
}

/// The name an identifier or a member path is written with: its last segment.
fn nameOf(e: ast.Expr) ?[]const u8 {
    if (e != .identifier) return null;
    return switch (e.identifier.kind) {
        .ident => |n| n,
        .identAccess => |ia| ia.member,
        else => null,
    };
}

fn walkExpr(ctx: *Ctx, p: *ast.Expr) error{OutOfMemory}!void {
    const e = p.*;
    const loc = e.getLoc();
    // `compiler.name(d)` — the handle's name is a `string` to the machinery.
    if (e == .call and e.call.kind == .call and e.call.kind.call.is_builtin and std.mem.eql(u8, e.call.kind.call.callee, ast.non_null_builtin_name) and e.call.kind.call.args.len == 1) {
        if (compilerCall(e.call.kind.call.args[0].value.*)) |inner| if (std.mem.eql(u8, inner.callee, "name") and inner.args.len == 1 and isHandle(ctx, inner.args[0].value.*)) {
            p.* = e.call.kind.call.args[0].value.*;
            return walkExpr(ctx, p);
        };
    }
    if (e == .call and e.call.kind == .call) {
        const c = e.call.kind.call;
        // Decision 575 (4) — `@expr` is the compiler's own: a `-> expr T`
        // template returns the expression.
        if (c.is_builtin and std.mem.eql(u8, c.callee, "expr")) {
            p.* = try refusal(ctx, loc, diagnostics.unknown_builtin, "`@expr` is gone: a `-> syntax T` template returns the expression itself", "Write `return e;` — a `comptime` value is spliced as a literal, a `syntax` as written (decision 575 (4)).");
            return;
        }
        // Decision 576 (2) — an `expr` is opaque: read only through
        // `compiler.*`.
        if (c.receiver) |r| if (r.* == .identifier and r.identifier.kind == .ident and contains(ctx.exprs, r.identifier.kind.ident) and !contains(ctx.shadow.items, r.identifier.kind.ident)) {
            p.* = try refusal(ctx, loc, diagnostics.expr_param_method, try std.fmt.allocPrint(ctx.alloc, "`{s}` is a `syntax` — the expression written — and has no method `.{s}(…)`", .{ r.identifier.kind.ident, c.callee }), "Read it through the compiler — `compiler.text(e)`, `compiler.lookup(e, name)`, … — or hand it to a tree (decision 576 (2)).");
            return;
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
        // Decision 578 (3) — `compiler.addType(name, compiler.buildType(s))`:
        // the type built from its text (the text the machinery takes).
        if (std.mem.eql(u8, c.callee, "addType") and c.args.len == 2) if (compilerCall(c.args[1].value.*)) |bt| if (std.mem.eql(u8, bt.callee, "buildType") and bt.args.len == 1) {
            c.args[1].value = bt.args[0].value;
        };
        // Decision 575 (3) — `compiler.init(e)` with an executor that is
        // no function written at the call (a function's name, an `expr`
        // parameter): the executor is `{ -> e() }`, a tree like any other.
        if (std.mem.eql(u8, c.callee, "init") and c.args.len == 1 and c.args[0].value.* != .function)
            c.args[0].value = try executorOf(ctx, c.args[0].value);
        // Decision 614 — a `compiler.*` read inside the executor is
        // evaluated at build: hoisted into a `val` of the body before the
        // call, the executor reading it as a literal (575 (4)'s tree rule).
        // The arguments first: a member, a wrapper and an executor are trees,
        // each hoisted alike (decision 642).
        const tree = std.mem.eql(u8, c.callee, "addMember") or std.mem.eql(u8, c.callee, "wrapWith") or std.mem.eql(u8, c.callee, "init");
        if (tree) for (c.args) |a| if (a.value.* == .function) try hoistBuildReads(ctx, a.value);
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
        ctx.mapped += 1;
        p.* = try mapCall(ctx, loc, c);
        return;
    }
    if (e == .identifier) switch (e.identifier.kind) {
        .ident => |n| {
            if (compiler_name != null and std.mem.eql(u8, n, compiler_name.?)) {
                p.* = if (ctx.runTime) try runTimeRefusal(ctx, loc) else try refusal(ctx, loc, diagnostics.compiler_escapes, "`compiler` is the compiler at this point, read through its members: it is never passed nor stored", "Write `compiler.<member>` — `compiler.src`, `compiler.fail(…)` (decision 579 (3)).");
                return;
            }
            if (!ctx.inTree and contains(ctx.values, n) and !contains(ctx.shadow.items, n)) {
                ctx.changed = true;
                p.* = fieldRead(ctx, loc, try ident(ctx, n, loc), "value");
            }
            return;
        },
        .identAccess => |ia| {
            if (ia.receiver.* == .identifier and ia.receiver.identifier.kind == .ident and contains(ctx.exprs, ia.receiver.identifier.kind.ident) and !contains(ctx.shadow.items, ia.receiver.identifier.kind.ident)) {
                p.* = try refusal(ctx, loc, diagnostics.expr_param_method, try std.fmt.allocPrint(ctx.alloc, "`{s}` is a `syntax` — the expression written — and has no field `.{s}`", .{ ia.receiver.identifier.kind.ident, ia.member }), "Read it through the compiler — `compiler.text(e)`, … — or hand it to a tree (decision 576 (2)).");
                return;
            }
            if (isCompiler(ia.receiver.*)) {
                const at = ia.receiver.getLoc();
                p.* = if (ctx.runTime) try runTimeRefusal(ctx, at) else try mapProperty(ctx, if (std.mem.eql(u8, ia.member, "src")) at else loc, ia.member);
                // The read replaced the node: its `compiler` is no one's.
                ctx.alloc.destroy(ia.receiver);
                return;
            }
            return walkExpr(ctx, ia.receiver);
        },
        .dotIdent => return,
    };
    // Decision 606 (3) — `comptime compiler.typeInfo(T)` in a run-time body:
    // what `comptime` holds runs at build, where `compiler` is the call site.
    // The compiler's answer is computed where the program is checked (the
    // reads `@typeInfo` made), so `comptime compiler.typeInfo(T).name` is
    // that read, the `comptime` it is written under done.
    if (e == .comptime_) switch (e.comptime_.kind) {
        .comptimeExpr => |inner| {
            const was = ctx.runTime;
            const was_tree = ctx.inTree;
            ctx.runTime = false;
            // Inside a tree a `comptime` is the build's own (the tree rule
            // splices its answer): the compiler is read there, and the
            // `comptime` stays.
            ctx.inTree = false;
            defer ctx.runTime = was;
            defer ctx.inTree = was_tree;
            const before = ctx.mapped;
            try walkExpr(ctx, inner);
            if (ctx.mapped != before and !was_tree) {
                p.* = inner.*;
                ctx.alloc.destroy(inner);
            }
            return;
        },
        .comptimeBlock => if (ctx.runTime) {
            ctx.runTime = false;
            defer ctx.runTime = true;
            return walkAny(ctx, &p.comptime_);
        },
        else => {},
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
    if (T == []ast.Stmt) return walkStmts(ctx, v);
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
    // A local bound to a tree (`val code = compiler.build(…)`) is one too.
    var trees: std.ArrayListUnmanaged([]const u8) = .empty;
    try trees.appendSlice(ctx.scratch, ctx.trees);
    for (body) |st| if (st.expr == .binding and st.expr.binding.kind == .localBind) {
        const lb = st.expr.binding.kind.localBind;
        if (answersTree(ctx, lb.value.*)) {
            try trees.append(ctx.scratch, lb.name);
            ctx.trees = trees.items;
        }
    };
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

test "a template's value return is lifted (decision 578)" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    var lx = lexer.Lexer.init(
        \\fn shout(syntax q: string) -> string {
        \\    return compiler.text(q).toUpper();
        \\}
        \\import {compiler} from "std";
    );
    var p = parser.Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const f = program.decls[0].@"fn";
    const r = f.body[0].expr.jump.kind.@"return".?.*;
    try std.testing.expect(r == .call);
    try std.testing.expect(r.call.kind.call.is_builtin);
    try std.testing.expectEqualStrings("expr", r.call.kind.call.callee);
}
