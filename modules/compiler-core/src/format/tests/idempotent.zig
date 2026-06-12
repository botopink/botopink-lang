//! format: idempotent round-trips (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");
const h = @import("helpers.zig");

test "format: idempotent ---- full Account struct" {
    try h.assertIdempotent(std.testing.allocator,
        \\val Account = struct {
        \\    _balance: number = 0,
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value;
        \\    }
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\};
    );
}

test "format: idempotent ---- full Drawable interface" {
    try h.assertIdempotent(std.testing.allocator,
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\};
    );
}

test "format: idempotent ---- enum with payload" {
    try h.assertIdempotent(std.testing.allocator,
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\};
    );
}

test "format: idempotent ---- pub fn with comptime params" {
    try h.assertIdempotent(std.testing.allocator,
        \\pub fn repeat(s comptime: string, n comptime: int) -> string {
        \\    todo;
        \\}
    );
}

test "format: idempotent ---- case with empty lines" {
    try h.assertIdempotent(std.testing.allocator,
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

test "format: idempotent ---- pipeline with comments" {
    try h.assertIdempotent(std.testing.allocator,
        \\fn main() {
        \\    1
        \\    // 1
        \\    |> func1
        \\    // 2
        \\    |> func2;
        \\}
    );
}

test "format: idempotent ---- nested case expressions" {
    try h.assertIdempotent(std.testing.allocator,
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

test "format: idempotent ---- struct with methods" {
    try h.assertIdempotent(std.testing.allocator,
        \\val Account = struct {
        \\    _balance: number = 0,
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value;
        \\    }
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\};
    );
}

test "format: idempotent ---- interface with default method" {
    try h.assertIdempotent(std.testing.allocator,
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\};
    );
}

test "format: idempotent ---- enum with payload variants" {
    try h.assertIdempotent(std.testing.allocator,
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\};
    );
}

test "format: idempotent ---- complex case with OR patterns" {
    try h.assertIdempotent(std.testing.allocator,
        \\fn main() {
        \\    case n {
        \\        0 | 2 | 4 | 6 | 8 -> "even digit";
        \\        1 | 3 | 5 | 7 | 9 -> "odd digit";
        \\        _ -> "not a digit";
        \\    };
        \\}
    );
}

test "format: idempotent ---- lambda with multiple trailing blocks" {
    try h.assertIdempotent(std.testing.allocator,
        \\fn main() {
        \\    executar {
        \\        ok;
        \\    } erro: {
        \\        fail;
        \\    };
        \\}
    );
}

test "format: idempotent ---- array prepend" {
    try h.assertIdempotent(std.testing.allocator,
        \\val list1 = [1, ..[]];
        \\val list2 = [1, 2, ..[3]];
        \\val list3 = [1, 2, ..[3, 4]];
    );
}
