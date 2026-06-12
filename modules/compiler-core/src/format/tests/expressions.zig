//! format: binary/call/access/lambda/precedence/pipeline/negation (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");
const h = @import("helpers.zig");

test "format: lambda ---- trailing no params" {
    try h.assertFormat(std.testing.allocator,
        \\val Test = interface {
        \\    default fn run() {
        \\        executar {
        \\            ok;
        \\        };
        \\    }
        \\};
    );
}

test "format: lambda ---- named arg + trailing with params" {
    try h.assertFormat(std.testing.allocator,
        \\val Test = interface {
        \\    default fn run() {
        \\        calcular(fator: 2) { a, b ->
        \\            a + b;
        \\        };
        \\    }
        \\};
    );
}

test "format: lambda ---- two trailing blocks second labeled" {
    try h.assertFormat(std.testing.allocator,
        \\val Test = interface {
        \\    default fn run() {
        \\        executar {
        \\            ok;
        \\        } erro: {
        \\            fail;
        \\        };
        \\    }
        \\};
    );
}

test "format: lambda ---- simple no params" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn() {
        \\        x;
        \\    };
        \\}
    );
}

test "format: lambda ---- with param" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn(x) {
        \\        x;
        \\    };
        \\}
    );
}

test "format: lambda ---- multi-statement body" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn() {
        \\        1;
        \\        2;
        \\    };
        \\}
    );
}

test "format: lambda ---- case expression in body" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn(x) {
        \\        case x {
        \\            1 -> 1;
        \\            _ -> 0;
        \\        };
        \\    };
        \\}
    );
}

test "format: call ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    run();
        \\}
    );
}

test "format: call ---- single argument" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    run(1);
        \\}
    );
}

test "format: call ---- labeled argument" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    run(with: 1);
        \\}
    );
}

test "format: call ---- constructor with labeled args" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    Person(name: "Al", is_cool: VeryTrue);
        \\}
    );
}

test "format: binary ---- logical and" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    True && False;
        \\}
    );
}

test "format: binary ---- logical or" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    True || False;
        \\}
    );
}

test "format: binary ---- comparison less than" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 < 1;
        \\}
    );
}

test "format: binary ---- comparison less than or equal" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 <= 1;
        \\}
    );
}

test "format: binary ---- equality" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 == 1;
        \\}
    );
}

test "format: binary ---- inequality" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 != 1;
        \\}
    );
}

test "format: binary ---- addition" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 + 1;
        \\}
    );
}

test "format: binary ---- subtraction" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 - 1;
        \\}
    );
}

test "format: binary ---- multiplication" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 * 1;
        \\}
    );
}

test "format: binary ---- division" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 / 1;
        \\}
    );
}

test "format: binary ---- modulo" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 % 1;
        \\}
    );
}

test "format: seq ---- multiple expressions" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1;
        \\    2;
        \\    3;
        \\}
    );
}

test "format: seq ---- call then literal" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    first(1);
        \\    1;
        \\}
    );
}

test "format: access ---- simple field access" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    one.two;
        \\}
    );
}

test "format: access ---- chained field access" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    one.two.three.four;
        \\}
    );
}

test "format: access ---- tuple access" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    tup.0;
        \\}
    );
}

test "format: access ---- chained tuple access" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    tup.1.2;
        \\}
    );
}

test "format: panic ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @panic();
        \\}
    );
}

test "format: panic ---- with message" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @panic("panicking");
        \\}
    );
}

test "format: precedence ---- parentheses around addition" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    (1 + 2) * 3;
        \\}
    );
}

test "format: precedence ---- multiplication on right" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    3 * (1 + 2);
        \\}
    );
}

test "format: precedence ---- logical or in parentheses" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    True != (a == b);
        \\}
    );
}

test "format: negation ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    !x;
        \\}
    );
}

test "format: negation ---- block" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    !@block{
        \\        123;
        \\        x;
        \\    };
        \\}
    );
}

test "format: pipeline ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1
        \\    |> really_long_variable_name
        \\    |> really_long_variable_name
        \\    |> really_long_variable_name;
        \\}
    );
}

test "format: pipeline ---- in list" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        1
        \\        |> succ
        \\        |> succ,
        \\        2,
        \\        3,
        \\    ];
        \\}
    );
}

test "format: pipeline ---- with comments" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1
        \\    // 1
        \\    |> func1
        \\    // 2
        \\    |> func2;
        \\}
    );
}

test "format: labeled args ---- with comments" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    Emulator(
        \\        // one
        \\        one: 1,
        \\        // two
        \\        two: 1,
        \\    );
        \\}
    );
}

test "format: panic ---- with message and comment" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @panic("wibble");
        \\}
    );
}

test "format: multiline string ---- as function argument" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    wibble(
        \\        wobble,
        \\        """
        \\        This is a multiline string.
        \\        It can span several lines.
        \\        """,
        \\        wibble,
        \\        wibble,
        \\    );
        \\}
    );
}

test "format: await ---- prefix expression" {
    try h.assertFormat(std.testing.allocator,
        \\*fn run() -> @Future<Int> {
        \\    val x = await load(url);
        \\    return x;
        \\}
    );
}

test "format: tagged call ---- round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\val q = sql "SELECT 1";
    );
}

test "format: tagged call ---- interpolated multiline round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\val component = html """
        \\<Button label=${title}></Button>
        \\""";
    );
}
