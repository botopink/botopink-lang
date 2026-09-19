//! .d.ts emitter: template fns (`@Expr<…>` / `@ExprCustom<…>`) are skipped.
//! The runtime contract is that template fns expand at their call site and
//! never reach codegen; the `.d.ts` surface mirrors that drop. This test
//! asserts no `Expr<` substring leaks into the typedef output.

const std = @import("std");
const codegen = @import("../../codegen.zig");
const Module = codegen.Module;
const helpers = @import("./helpers.zig");

/// Asserts the typedef of `src` carries no `Expr<`/`ExprCustom<`, contains every
/// `present` needle (so a typedef that dropped everything cannot pass) and none
/// of the `absent` ones (the template members themselves).
fn assertNoExprInDts(src: []const u8, present: []const []const u8, absent: []const []const u8) !void {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var outputs = try codegen.generate(
        alloc,
        &.{.{ .path = "", .source = src }},
        io,
        helpers.configs[0],
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(alloc);
        outputs.deinit(alloc);
    }
    try std.testing.expect(outputs.items.len >= 1);
    const dts = outputs.items[0].result.typedef orelse return error.MissingTypedef;
    if (std.mem.indexOf(u8, dts, "Expr<")) |off| {
        std.debug.print("\nUNEXPECTED `Expr<` in .d.ts at offset {d}:\n{s}\n", .{ off, dts });
        return error.TemplateLeakedIntoDts;
    }
    if (std.mem.indexOf(u8, dts, "ExprCustom<")) |off| {
        std.debug.print("\nUNEXPECTED `ExprCustom<` in .d.ts at offset {d}:\n{s}\n", .{ off, dts });
        return error.CustomTemplateLeakedIntoDts;
    }
    for (present) |needle| {
        if (std.mem.indexOf(u8, dts, needle) == null) {
            std.debug.print("\nmissing `{s}` in .d.ts:\n{s}\n", .{ needle, dts });
            return error.NeedleNotFound;
        }
    }
    for (absent) |needle| {
        if (std.mem.indexOf(u8, dts, needle) != null) {
            std.debug.print("\nunexpected `{s}` in .d.ts:\n{s}\n", .{ needle, dts });
            return error.UnexpectedNeedle;
        }
    }
}

test ".d.ts: free fn returning @Expr<T> is skipped" {
    try assertNoExprInDts(
        \\pub fn html(template: string) -> @Expr<string> {
        \\    return @expr("hello");
        \\}
        \\pub fn plain(x: i32) -> i32 { return x + 1; }
    , &.{"export declare function plain("}, &.{"function html("});
}

test ".d.ts: interface method returning @Expr<T> is skipped" {
    try assertNoExprInDts(
        \\pub behavior Tpl {
        \\    fn render(self: Self) -> @Expr<string>;
        \\    fn name(self: Self) -> string;
        \\}
    , &.{ "export declare interface Tpl {", "name(): string;" }, &.{"render("});
}

// Decision 8 §3's union `A | B` reaches the `.d.ts` as TypeScript's own union.
// It rides on `TypeRef.generic` under the reserved name `ast.union_type_name`
// (`"|"`), and the generic path wrote it out as `|<A, B>` — a declaration file
// that is not TypeScript, the defect step 6's T2 named for the primitive names.
// No snapshot: the typedef is the only output that moves, and a snapshot would
// carry this program's JavaScript through all four backends.
test ".d.ts: a union is `A | B`, not `|<A, B>` (step 6 T3)" {
    try helpers.assertDtsContains(
        std.testing.allocator,
        \\pub type A(x: i32)
        \\pub type B(y: string)
        \\pub fn pick(v: A | B) -> A | B { return v; }
        \\pub fn u(x: unknown) -> unknown { return x; }
        \\pub fn opt(x: ?i32) -> ?i32 { return x; }
    ,
        &.{
            "export declare function pick(v: A | B): A | B;",
            "export declare function u(x: unknown): unknown;",
            "export declare function opt(x: number | null): number | null;",
        },
        &.{"|<"},
    );
}
