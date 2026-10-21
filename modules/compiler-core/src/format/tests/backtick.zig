//! format: decision 561's backtick identifiers are printed back as written.

const std = @import("std");
const h = @import("helpers.zig");

test "format: backtick names in every name position" {
    try h.assertFormat(std.testing.allocator,
        \\pub mod `my-utils`;
        \\import {`my-utils`.`helper fn` as helper, shapes.perimeter as `around it`};
        \\
        \\type `my point`(`x pos`: i32, `type`: string) {
        \\    fn `sum of`(self: Self) -> i32 {
        \\        return self.`x pos`;
        \\    }
        \\}
        \\
        \\type `Shape kind` {
        \\    `Round one`(radius: i32),
        \\    Square,
        \\}
        \\
        \\fn `add one`(`the value`: i32) -> i32 {
        \\    val `not-found` = `the value` + 1;
        \\    return `not-found`;
        \\}
    );
}

test "format: a backtick name that is an identifier is written plain" {
    try h.assertFormatAs(std.testing.allocator,
        \\fn `double`(`n`: i32) -> i32 {
        \\    return `n` * 2;
        \\}
    ,
        \\fn double(n: i32) -> i32 {
        \\    return n * 2;
        \\}
    );
}
