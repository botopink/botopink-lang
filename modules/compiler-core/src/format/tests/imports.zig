//! format: import formatting (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");
const h = @import("helpers.zig");

test "format: import ---- empty imports from root" {
    try h.assertFormat(std.testing.allocator,
        \\import {};
    );
}

test "format: import ---- named imports" {
    try h.assertFormat(std.testing.allocator,
        \\import {foo, bar, baz};
    );
}

test "format: import ---- from module source" {
    try h.assertFormat(std.testing.allocator,
        \\import {x, y} from "mod";
    );
}

test "format: import ---- multiple declarations" {
    try h.assertFormat(std.testing.allocator,
        \\import {a};
        \\import {b, c} from "dep";
    );
}

test "format: import ---- dotted path" {
    try h.assertFormat(std.testing.allocator,
        \\import {X.x1.x2};
    );
}

test "format: import ---- activation suffix and alias" {
    try h.assertFormat(std.testing.allocator,
        \\import {Pato, PatoNada*, std.List as L} from "ducks";
    );
}

test "format: import ---- activation fallback statement" {
    try h.assertFormat(std.testing.allocator,
        \\X*;
    );
}

test "format: import ---- empty" {
    try h.assertFormat(std.testing.allocator,
        \\import {};
    );
}

test "format: import ---- single import" {
    try h.assertFormat(std.testing.allocator,
        \\import {one};
    );
}

test "format: import ---- multiple imports" {
    try h.assertFormat(std.testing.allocator,
        \\import {one};
        \\import {two} from "dep";
    );
}

test "format: import ---- ordered imports" {
    try h.assertFormat(std.testing.allocator,
        \\import {four, five};
        \\import {one, two, three} from "dep";
    );
}

test "format: import ---- selective imports" {
    try h.assertFormat(std.testing.allocator,
        \\import {fun, fun2, fun3};
    );
}

test "format: import ---- mixed type and function imports" {
    try h.assertFormat(std.testing.allocator,
        \\import {One, Two, fun1, fun2};
    );
}

test "format: multiple statements with import and types" {
    try h.assertFormat(std.testing.allocator,
        \\import {one};
        \\import {three};
        \\import {two};
        \\
        \\pub val One = struct {};
        \\
        \\pub val Two = struct {};
        \\
        \\pub val Three = struct {};
        \\
        \\pub val Four = struct {};
    );
}
