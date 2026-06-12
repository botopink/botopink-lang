const std = @import("std");
const parser = @import("modules/core/src/parser.zig");

pub fn main() !void {
    const alloc = std.testing.allocator;
    
    const src = "pub val One = struct {};";
    var tokens = try parser.tokenize(alloc, src);
    defer tokens.deinit(alloc);
    
    var p = try parser.Parser.init(alloc, tokens.items);
    defer p.deinit(alloc);
    
    const prog = try p.parse(alloc);
    defer prog.deinit(alloc);
    
    std.debug.print("isPub: {}\n", .{prog.decls[0].val.isPub});
}
