//! Decision 364 — every `comptime` parameter other than `@Decl` is the user's
//! expression, `comptime x: @Expr<T>`. A template function (`-> @Expr<…>` /
//! `-> @ExprCustom<…>`) keeps its `@Expr` parameters as written: its own
//! machinery captures the argument unevaluated (`comptime/template.zig`).
//! Every other function — a decorator, an ordinary function, a method, a
//! `declare fn` — has the wrapper read off here, once, after the parse: the
//! parameter's `typeRef` is `T`, so every rule that reads a `comptime`
//! parameter's type (a decorator's argument check, `comptime/value_or_type.zig`,
//! the transform's specialisation, a backend's signature) reads `T`, and
//! `Param.exprWrapped` says the body holds an `Expr<T>` (`x.value`, the
//! checker's `infer.zig`; `comptime/expr_param.zig` erases the read for the
//! code that runs). The formatter prints `@Expr<T>` back.

const std = @import("std");
const ast = @import("../ast.zig");

/// Every function `program` declares, its non-template `comptime x: @Expr<T>`
/// parameters unwrapped in place.
pub fn unwrapProgram(alloc: std.mem.Allocator, program: *ast.Program) void {
    for (program.decls) |*d| switch (d.*) {
        .@"fn" => |*f| unwrap(alloc, f.params, f.returnType),
        .delegate => |*f| unwrap(alloc, f.params, f.returnType),
        .type_ => |*t| unwrapType(alloc, t),
        .behavior => |*b| for (b.methods) |*m| unwrap(alloc, m.params, m.returnType),
        .implement => |*i| for (i.methods) |*m| unwrap(alloc, m.params, null),
        .extend => |*e| for (e.methods) |*m| unwrap(alloc, m.params, null),
        else => {},
    };
}

fn unwrapType(alloc: std.mem.Allocator, t: *ast.TypeDecl) void {
    for (t.methods) |*m| unwrap(alloc, m.params, m.returnType);
    for (t.assocTypes) |*inner| unwrapType(alloc, inner);
}

fn unwrap(alloc: std.mem.Allocator, params: []ast.Param, returnType: ?ast.TypeRef) void {
    if (returnType) |rt| if (rt.isTemplateReturnType()) return;
    for (params) |*p| {
        if (p.modifier != .@"comptime" or !p.typeRef.isExprType()) continue;
        const g = p.typeRef.generic;
        if (g.args.len != 1) continue;
        p.typeRef = g.args[0];
        alloc.free(g.args);
        p.exprWrapped = true;
    }
}

test "a decorator's and a function's `@Expr` parameters are unwrapped, a template's kept" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    var lx = lexer.Lexer.init(
        \\fn setting(comptime decl: @Decl, comptime key: @Expr<string>) {}
        \\fn scale(comptime n: @Expr<i32>, x: i32) -> i32 { return x * n.value; }
        \\fn sql(comptime q: @Expr<string>) -> @Expr<string> { return q; }
        \\type Kit { fn pick(comptime t: @Expr<type>) -> i32 { return 1; } }
    );
    var p = parser.Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const setting = program.decls[0].@"fn";
    try std.testing.expect(setting.params[0].typeRef.isDeclType());
    try std.testing.expect(!setting.params[0].exprWrapped);
    try std.testing.expect(setting.params[1].exprWrapped);
    try std.testing.expectEqualStrings("string", setting.params[1].typeRef.named);
    const scale = program.decls[1].@"fn";
    try std.testing.expect(scale.params[0].exprWrapped);
    try std.testing.expect(!scale.params[1].exprWrapped);
    const sql = program.decls[2].@"fn";
    try std.testing.expect(sql.params[0].typeRef.isExprType());
    try std.testing.expect(!sql.params[0].exprWrapped);
    const kit = program.decls[3].type_;
    try std.testing.expect(kit.methods[0].params[0].exprWrapped);
    try std.testing.expect(kit.methods[0].params[0].typeRef == .typeparam);
}
