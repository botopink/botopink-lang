//! format: comments / doc / todo (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");
const h = @import("helpers.zig");

test "format: todo ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    todo;
        \\}
    );
}

test "format: todo ---- with message" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @todo("todo with a label");
        \\}
    );
}

test "format: comments ---- single line before fn" {
    try h.assertFormat(std.testing.allocator,
        \\// one
        \\fn main() {
        \\    null;
        \\}
    );
}

test "format: comments ---- multiple lines before fn" {
    try h.assertFormat(std.testing.allocator,
        \\// one
        \\// two
        \\fn main() {
        \\    null;
        \\}
    );
}

test "format: comments ---- inside function" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    // Hello
        \\    // world
        \\    1;
        \\}
    );
}

test "format: comments ---- between statements" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    // Hello
        \\    1;
        \\    // world
        \\    2;
        \\}
    );
}

test "format: comments ---- trailing after function" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    x;
        \\}
        \\// Hello world
        \\// ok!
    );
}

test "format: comments ---- inside list" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        // One
        \\        1,
        \\        // Two
        \\        2,
        \\    ];
        \\}
    );
}

test "format: comments ---- inside call" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    one(
        \\        // One
        \\        1,
        \\        // Two
        \\        2,
        \\    );
        \\}
    );
}

test "format: doc comment ---- before fn" {
    try h.assertFormat(std.testing.allocator,
        \\/// This is a documented function
        \\fn main() {
        \\    null;
        \\}
    );
}

test "format: doc comment ---- multiline before fn" {
    try h.assertFormat(std.testing.allocator,
        \\/// First line of documentation
        \\/// Second line of documentation
        \\fn greet(name: string) -> string {
        \\    return name;
        \\}
    );
}

test "format: doc comment ---- before struct" {
    try h.assertFormat(std.testing.allocator,
        \\/// User account structure
        \\val Account = struct {};
    );
}

test "format: doc comment ---- before enum" {
    try h.assertFormat(std.testing.allocator,
        \\/// Color enumeration
        \\val Color = enum { Red, Blue };
    );
}

test "format: doc comment ---- before interface" {
    try h.assertFormat(std.testing.allocator,
        \\/// Drawable interface
        \\val Drawable = interface {};
    );
}

test "format: doc comments ---- module level" {
    try h.assertFormat(std.testing.allocator,
        \\//// One
        \\//// Two
        \\//// Three
        \\
        \\pub fn main() {
        \\    val x = 1;
        \\
        \\    x;
        \\}
    );
}

test "format: comments ---- at end of anonymous fn" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    fn() {
        \\        1;
        \\        // a final comment
        \\
        \\        // another final comment
        \\        // at the end of the block
        \\    };
        \\}
    );
}

test "format: comments ---- multiline inside case block" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case list {
        \\        [] -> acc;
        \\        [_, ..rest] -> rest |> do_len(acc + 1);
        \\        // Even the opposite wouldn't be optimised:
        \\        // { acc + 1 } |> do_len(rest, _);
        \\    };
        \\}
    );
}

test "format: todo ---- with message and comment" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @todo("wibble");
        \\}
    );
}
