//! format: list/tuple/array/float/int/string literals (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");
const h = @import("helpers.zig");

test "format: tuple ---- empty" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #();
        \\}
    );
}

test "format: tuple ---- single element" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #(1);
        \\}
    );
}

test "format: tuple ---- two elements" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #(1, 2);
        \\}
    );
}

test "format: tuple ---- three elements" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #(1, 2, 3);
        \\}
    );
}

test "format: int ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn i() {
        \\    1;
        \\}
    );
}

test "format: int ---- with underscores" {
    try h.assertFormat(std.testing.allocator,
        \\fn i() {
        \\    121_234_345_989_000;
        \\}
    );
}

test "format: int ---- negative" {
    try h.assertFormat(std.testing.allocator,
        \\fn i() {
        \\    -12_928_347_925;
        \\}
    );
}

test "format: float ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    1.0;
        \\}
    );
}

test "format: float ---- negative" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    -1.0;
        \\}
    );
}

test "format: float ---- with decimals" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    9999.6666;
        \\}
    );
}

test "format: float ---- scientific notation" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    1.0e1;
        \\}
    );
}

test "format: float ---- negative exponent" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    1.0e-1;
        \\}
    );
}

test "format: string ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    "Hello";
        \\}
    );
}

test "format: string ---- escape sequences" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    "\\n\\t";
        \\}
    );
}

test "format: list ---- empty" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [];
        \\}
    );
}

test "format: list ---- single element" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [1];
        \\}
    );
}

test "format: list ---- multiple elements" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [1, 2, 3];
        \\}
    );
}

test "format: list ---- with spread" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [1, 2, 3, ..x];
        \\}
    );
}

test "format: list ---- nested lists" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        really_long_variable_name,
        \\        really_long_variable_name,
        \\        really_long_variable_name,
        \\        [1, 2, 3],
        \\        really_long_variable_name,
        \\    ];
        \\}
    );
}

test "format: list ---- comments inside" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        // First!
        \\        // First?
        \\        1,
        \\        // Spread!
        \\        // Spread?
        \\        ..[2, 3],
        \\    ];
        \\}
    );
}

test "format: list ---- trailing comments" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        1,
        \\        2,
        \\        // One and two are above me.
        \\    ];
        \\}
    );
}

test "format: list ---- compact wrapping integers" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000];
        \\}
    );
}

test "format: list ---- compact wrapping strings" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"];
        \\}
    );
}

test "format: tuple destruct ---- val binding" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val #(a, b) = #(1, 2);
        \\}
    );
}

test "format: tuple destruct ---- var binding" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    var #(x, y) = #(10, 20);
        \\}
    );
}

test "format: tuple destruct ---- function parameter" {
    try h.assertFormat(std.testing.allocator,
        \\fn process(#(x, y): #(i32, i32)) -> i32 {
        \\    return x;
        \\}
    );
}

test "format: tuple destruct ---- long variable names" {
    try h.assertFormat(std.testing.allocator,
        \\fn extract_coordinates() {
        \\    val #(longitude, latitude) = get_coordinates();
        \\}
    );
}

test "format: tuple destruct ---- with try-catch" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val #(a, b) = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

test "format: array ---- prepend with empty array" {
    try h.assertFormat(std.testing.allocator,
        \\val list1 = [1, ..[]];
    );
}

test "format: array ---- prepend with single element array" {
    try h.assertFormat(std.testing.allocator,
        \\val list2 = [1, 2, ..[3]];
    );
}

test "format: array ---- prepend with multiple elements array" {
    try h.assertFormat(std.testing.allocator,
        \\val list3 = [1, 2, ..[3, 4]];
    );
}

test "format: array ---- prepend with identifier" {
    try h.assertFormat(std.testing.allocator,
        \\val rest = [3, 4];
        \\
        \\val list = [1, 2, ..rest];
    );
}

test "format: string ---- interpolation round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\val s = "a ${x} b";
    );
}

test "format: string ---- interpolation with expression" {
    try h.assertFormat(std.testing.allocator,
        \\val s = "sum ${1 + 2}!";
    );
}

test "format: line string ---- normalizes to triple quotes" {
    const alloc = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const a = arena.allocator();

    var lx = lexerMod.Lexer.init(
        \\val page =
        \\    \\<div>
        \\    \\</div>
        \\;
    );
    const tokens = try lx.scanAll(a);
    var p = parserMod.Parser.init(tokens);
    const program = try p.parse(a);
    const out = try formatMod.format(alloc, program);
    defer alloc.free(out);
    try std.testing.expectEqualStrings(
        \\val page = """<div>
        \\</div>""";
    , out);
}

test "format: record literal ---- round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val cfg = record { port: 8080, debug: true };
        \\}
    );
}
