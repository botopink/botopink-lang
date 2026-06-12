//! .d.ts emitter: template fns (`@Expr<…>` / `@ExprCustom<…>`) are skipped.
//! The runtime contract is that template fns expand at their call site and
//! never reach codegen; the `.d.ts` surface mirrors that drop. This test
//! asserts no `Expr<` substring leaks into the typedef output.

const std = @import("std");
const codegen = @import("../../codegen.zig");
const Module = codegen.Module;
const helpers = @import("./helpers.zig");

fn assertNoExprInDts(src: []const u8) !void {
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
    const dts = outputs.items[0].result.typedef orelse "";
    if (std.mem.indexOf(u8, dts, "Expr<")) |off| {
        std.debug.print("\nUNEXPECTED `Expr<` in .d.ts at offset {d}:\n{s}\n", .{ off, dts });
        return error.TemplateLeakedIntoDts;
    }
    if (std.mem.indexOf(u8, dts, "ExprCustom<")) |off| {
        std.debug.print("\nUNEXPECTED `ExprCustom<` in .d.ts at offset {d}:\n{s}\n", .{ off, dts });
        return error.CustomTemplateLeakedIntoDts;
    }
}

test ".d.ts: free fn returning @Expr<T> is skipped" {
    try assertNoExprInDts(
        \\pub fn html(template: string) -> @Expr<string> {
        \\    return @expr("hello");
        \\}
        \\pub fn plain(x: i32) -> i32 { return x + 1; }
    );
}

test ".d.ts: interface method returning @Expr<T> is skipped" {
    try assertNoExprInDts(
        \\pub interface Tpl {
        \\    fn render(self: Self) -> @Expr<string>
        \\    fn name(self: Self) -> string
        \\}
    );
}
