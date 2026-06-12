//! format: case / pattern / assert (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");
const h = @import("helpers.zig");

test "format: case ---- wildcard and ident" {
    try h.assertFormat(std.testing.allocator,
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case status {
        \\            0 -> "zero";
        \\            _ -> "nonzero";
        \\        };
        \\    }
        \\};
    );
}

test "format: case ---- variant with field bindings" {
    try h.assertFormat(std.testing.allocator,
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case color {
        \\            Red -> "#FF0000";
        \\            Rgb(r, g, b) -> toHex(r, g, b);
        \\        };
        \\    }
        \\};
    );
}

test "format: case ---- list patterns with spread" {
    try h.assertFormat(std.testing.allocator,
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case items {
        \\            [] -> "empty";
        \\            [x] -> "one item";
        \\            [first, ..rest] -> "starts with " + first;
        \\        };
        \\    }
        \\};
    );
}

test "format: case ---- OR patterns" {
    try h.assertFormat(std.testing.allocator,
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case n {
        \\            0 | 2 | 4 | 6 | 8 -> "even digit";
        \\            1 | 3 | 5 | 7 | 9 -> "odd digit";
        \\            _ -> "not a digit";
        \\        };
        \\    }
        \\};
    );
}

test "format: case ---- guard clauses" {
    try h.assertFormat(std.testing.allocator,
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case n {
        \\            x if x > 0 -> "positive";
        \\            0 -> "zero";
        \\            _ -> "negative";
        \\        };
        \\    }
        \\};
    );
}

test "format: pattern ---- simple let" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val x = 1;
        \\    val y = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- discard" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val _ = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- list empty" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val [] = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- list with elements" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val [1, 2, 3, 4] = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- list with spread" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val [1, 2, 3, 4, ..x] = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- constructor" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val True = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- constructor with fields" {
    try h.assertFormat(std.testing.allocator,
        \\val Result = enum { Ok(value: i32), Error(message: String) };
        \\
        \\fn main() {
        \\    val result = Result.Ok(42);
        \\    val Ok(value) = case result {
        \\        Ok ok -> ok;
        \\        Error err -> Result.Ok(-1);
        \\    };
        \\    null;
        \\}
    );
}

test "format: pattern ---- constructor with labeled fields" {
    try h.assertFormat(std.testing.allocator,
        \\val Person = enum { Person(name: String, age: i32), Dog(name: String, age: i32) };
        \\
        \\fn main() {
        \\    val thing = Person.Dog("bob", 121);
        \\    val Person(name, age) = case thing {
        \\        Person person -> person;
        \\        Dog dog -> Person.Person(dog.name, dog.age);
        \\    };
        \\    null;
        \\}
    );
}

test "format: case ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 -> 1;
        \\        _ -> 0;
        \\    };
        \\}
    );
}

test "format: case ---- block body" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 -> {
        \\            1;
        \\            2;
        \\        };
        \\        _ -> 1;
        \\    };
        \\}
    );
}

test "format: case ---- multiple subjects" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1, 2, 3, 4 {
        \\        1, 2, 3, 4 -> 1;
        \\        _, _, _, _ -> 0;
        \\    };
        \\}
    );
}

test "format: case ---- alternative patterns" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 | 2 | 3 -> null;
        \\    };
        \\}
    );
}

test "format: case ---- nested case" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 -> case x {
        \\            1 -> 1;
        \\            _ -> 0;
        \\        };
        \\        _ -> 1;
        \\    };
        \\}
    );
}

test "format: case ---- fn body" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 -> fn(x) {
        \\            x;
        \\        };
        \\        _ -> 1;
        \\    };
        \\}
    );
}

test "format: case ---- with empty lines between arms" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case x {
        \\        1 -> 2;
        \\
        \\        2 -> 3;
        \\
        \\        _ -> 0;
        \\    };
        \\}
    );
}

test "format: complex ---- case with long message" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case x {
        \\        _ -> [123];
        \\    };
        \\}
    );
}

test "format: complex ---- function arguments after comment" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    wibble(
        \\        // Wobble
        \\        1 + 1,
        \\        "wibble",
        \\    );
        \\}
    );
}

test "format: complex ---- tuple items after comment" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #(
        \\        // Wobble
        \\        1 + 1,
        \\        "wibble",
        \\    );
        \\}
    );
}

test "format: complex ---- list items after comment" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        // Wobble
        \\        1 + 1,
        \\        "wibble",
        \\    ];
        \\}
    );
}

test "format: assert pattern ---- with catch throw" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert Person(name, age) = r catch throw Error("is not person");
        \\}
    );
}

test "format: assert pattern ---- with catch default value" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
        \\}
    );
}

test "format: assert pattern ---- with list pattern" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert [first, ..] = items catch throw Error("not a list");
        \\}
    );
}

test "format: assert pattern ---- with string literal" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert "hello" = greeting catch throw Error("not hello");
        \\}
    );
}

test "format: assert pattern ---- with number literal" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert 42 = answer catch throw Error("not 42");
        \\}
    );
}

test "format: assert pattern ---- with enum variant" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert Ok(value) = result catch throw Error("not ok");
        \\}
    );
}

test "format: assert pattern ---- with empty list" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert [] = list catch throw Error("not empty");
        \\}
    );
}

test "format: assert pattern ---- with multiple element list" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert [1, 2, 3] = numbers catch throw Error("not matching");
        \\}
    );
}

test "format: assert pattern ---- with list and rest" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert [first, second, ..rest] = items catch [];
        \\}
    );
}
