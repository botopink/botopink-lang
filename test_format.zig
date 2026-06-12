const std = @import("std");
const lexerMod = @import("./modules/compiler-core/src/lexer.zig");
const parserMod = @import("./modules/compiler-core/src/parser.zig");
const formatMod = @import("./modules/compiler-core/src/format.zig");

pub fn main() !void {
    const src =
        \\fn main() {
        \\    case list {
        \\        [] -> acc;
        \\        [_, ..rest] -> rest |> do_len(acc + 1);
        \\    };
        \\}
    ;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(allocator);
    defer l.deinit(allocator);

    var p = parserMod.Parser.init(tokens);
    var program = try p.parse(allocator);
    defer program.deinit(allocator);

    const formatted = try formatMod.format(allocator, program);
    defer allocator.free(formatted);

    std.debug.print("Original:\n{s}\n\n", .{src});
    std.debug.print("Formatted:\n{s}\n", .{formatted});
}
