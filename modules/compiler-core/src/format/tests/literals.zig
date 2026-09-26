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

// A list that does not fit breaks one element per line with the trailing comma
// (decision 65: all-or-nothing, no fill); it stayed on one line of 117 columns
// while every group was pinned.
test "format: list ---- a list past the width breaks one element per line" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        100,
        \\        200,
        \\        300,
        \\        400,
        \\        500,
        \\        600,
        \\        700,
        \\        800,
        \\        900,
        \\        1000,
        \\        1100,
        \\        1200,
        \\        1300,
        \\        1400,
        \\        1500,
        \\        1600,
        \\        1700,
        \\        1800,
        \\        1900,
        \\        2000,
        \\    ];
        \\}
    );
}

test "format: list ---- a list of strings past the width breaks the same way" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        "one",
        \\        "two",
        \\        "three",
        \\        "four",
        \\        "five",
        \\        "six",
        \\        "seven",
        \\        "eight",
        \\        "nine",
        \\        "ten",
        \\        "eleven",
        \\        "twelve",
        \\    ];
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

test "format: tuple literal ---- round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val cfg = #(8080, true);
        \\}
    );
}

test "format: interface literal ---- basic" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val decl = @Decl(kind: "Record", name: "Service");
        \\}
    );
}

test "format: interface literal ---- multiple fields" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val decl = @Decl(kind: "Record", name: "Service", fields: [], methods: []);
        \\}
    );
}

test "format: interface literal ---- with array" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val decl = @Decl(
        \\        kind: "Record",
        \\        name: "Service",
        \\        fields: [Field(name: "x", typeName: "i32")],
        \\    );
        \\}
    );
}

test "format: a string holding a quote keeps its triple fences" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val r = parse("""{"a":1}""");
        \\}
    );
}

// G7 (09's handover, a sibling example's `main.bp:111-113`): a comment written on an
// array or tuple element's own line, after the element, is that element's. The
// literal loops counted it among the NEXT element's leading comments and the
// printer put it above that element — where it says something false — and the
// result was idempotent, so `format --check` passed over it.
test "format: array literal ---- an element keeps its trailing comment on its line" {
    try h.assertFormatLossless(std.testing.allocator,
        \\val xs = [
        \\    1, // one
        \\    2, // two
        \\    3,
        \\];
        \\
        \\val boxes = [
        \\    // leading stays above
        \\    Box(label: "sq", w: 4, h: 4), // w == h, h > 2
        \\    Box(label: "wide", w: 6, h: 2), // w != h
        \\];
    );
}

test "format: tuple literal ---- an element keeps its trailing comment on its line" {
    try h.assertFormatLossless(std.testing.allocator,
        \\val t = #(
        \\    1, // first
        \\    "b",
        \\);
    );
}

test "format: array literal ---- the last element's comment without a comma stays on its line" {
    try h.assertFormatAs(std.testing.allocator,
        \\val ys = [
        \\    1, 2, // both on one line
        \\    3 // last, no comma
        \\];
    ,
        \\val ys = [
        \\    1,
        \\    2, // both on one line
        \\    3, // last, no comma
        \\];
    );
}
