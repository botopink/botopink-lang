//! parser: operator/lambda/array/tuple/case/builtin/assert/control-flow (split from tests.zig).

const std = @import("std");
const snapMod = @import("../../utils/snap.zig");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ParseErrorType = parserMod.ParseErrorType;
const ast = @import("../../ast.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const print = @import("../../print.zig");
const h = @import("helpers.zig");

test "parser: use void hook" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn App() {
        \\    use effect({ -> cleanup() });
        \\}
    );
}

test "parser: use prefix in val binding" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn App() {
        \\    val doubled = use memo({ -> count * 2 });
        \\}
    );
}

test "parser: use multiple hooks in function" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn Dashboard() {
        \\    val {count, setCount} = use state(0);
        \\    val doubled = use memo({ -> count * 2 });
        \\    use effect({ -> cleanup() });
        \\}
    );
}

test "parser: lambda: plain positional call ---- print(\"hello\")" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        print("hello");
        \\    }
        \\}
    );
}

test "parser: lambda: named argument call ---- calcular(fator: 2)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        calcular(fator: 2);
        \\    }
        \\}
    );
}

test "parser: lambda: trailing lambda with no params ---- executar { ok }" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        executar { ok; };
        \\    }
        \\}
    );
}

test "parser: lambda: named arg + trailing lambda with two params and addition" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        calcular(fator: 2) { a, b ->
        \\            a + b;
        \\        };
        \\    }
        \\}
    );
}

test "parser: lambda: two trailing lambdas, second labeled ---- executar {} erro: {}" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        executar { ok; } erro: { fail; };
        \\    }
        \\}
    );
}

test "parser: lambda: method call with two-param trailing lambda ---- precos.forEach { fruta, valor -> fruta }" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        precos.forEach { fruta, valor -> fruta; };
        \\    }
        \\}
    );
}

test "parser: lambda: binary addition ---- a + b" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a + b;
        \\    }
        \\}
    );
}

test "parser: case ---- wildcard and ident patterns" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case x {
        \\            _ -> y;
        \\            Red -> z;
        \\        };
        \\    }
        \\}
    );
}

test "parser: case ---- variant with field bindings" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case (self.color) {
        \\            Red -> "red";
        \\            Rgb(r, g, b) -> "rgb";
        \\        };
        \\    }
        \\}
    );
}

test "parser: case ---- list patterns" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case xs {
        \\            [] -> "empty";
        \\            [1] -> "one";
        \\            [_, _] -> "two";
        \\            [first, ..rest] -> first;
        \\        };
        \\    }
        \\}
    );
}

test "parser: case ---- OR patterns" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case n {
        \\            2 | 4 | 6 -> "even";
        \\            _ -> "other";
        \\        };
        \\    }
        \\}
    );
}

test "parser: case ---- guard clauses" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case n {
        \\            x if x > 0 -> "positive";
        \\            0 -> "zero";
        \\            _ -> "negative";
        \\        };
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- mul binds tighter than add" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        1 + 2 * 3;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- left-to-right associativity for add" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        1 + 2 + 3;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- add binds tighter than compare" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a + 1 < b + 2;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- compare binds tighter than eq" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a < b == c > d;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- all arithmetic operators" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a + b - c * d / e % f;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- comparison operators" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a < b;
        \\        a > b;
        \\        a <= b;
        \\        a >= b;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- equality operators" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a == b;
        \\        a != b;
        \\    }
        \\}
    );
}

test "parser: builtin ---- zero-arg call" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        @src();
        \\    }
        \\}
    );
}

test "parser: builtin ---- single-arg call" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        @sizeOf(Int);
        \\        @typeName(Bool);
        \\        @panic("unreachable");
        \\    }
        \\}
    );
}

test "parser: builtin ---- multi-arg call" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        @min(a, b);
        \\        @max(x, y);
        \\        @as(Int, value);
        \\    }
        \\}
    );
}

test "parser: builtin ---- in expression context" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn doubled(x: Int) -> Int {
        \\    return @abs(x) + @abs(x);
        \\}
    );
}

test "parser: builtin ---- as val initializer" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val size = @sizeOf(Float);
        \\val name = @typeName(String);
        \\val src = @src();
    );
}

test "parser: array literal" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val xs = ["hello", "world"];
    );
}

test "parser: tuple literal" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val t = #("56454", "85484");
    );
}

test "parser: nested array type" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val matrix: i32[][] = [];
    );
}

test "parser: array prepend with empty array" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val list1 = [1, ..[]];
    );
}

test "parser: array prepend with single element array" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val list2 = [1, 2, ..[3]];
    );
}

test "parser: array prepend with multiple elements array" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val list3 = [1, 2, ..[3, 4]];
    );
}

test "parser: array prepend with identifier" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val rest = [3, 4];
        \\val list = [1, 2, ..rest];
    );
}

test "parser: try expression" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val x = try fetch();
        \\}
    );
}

test "parser: try-catch expression" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val x = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

test "parser: catch as tail operator without try" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val item = getPerson() catch throw Error("not found");
        \\}
    );
}

test "parser: catch as tail operator with return" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val item = getPerson() catch return null;
        \\}
    );
}

test "parser: if with null-check binding" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    var email: ?string = null;
        \\    if (email) { e ->
        \\        console.log(e);
        \\    };
        \\}
    );
}

test "parser: assert ---- simple assertion" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert true;
        \\}
    );
}

test "parser: assert ---- with equality comparison" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert 1 == 1;
        \\}
    );
}

test "parser: assert ---- with addition" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert 1.0 + 2.0 == 3.0;
        \\}
    );
}

test "parser: assert ---- with message" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert false, "should be true";
        \\}
    );
}

test "parser: assert ---- array equality" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert [] == [];
        \\}
    );
}

test "parser: assert ---- arithmetic comparison" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert 5.0 - 1.0 == 4.0;
        \\}
    );
}

test "parser: assert pattern ---- with catch throw" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Person(name, age) = r catch throw Error("is not person");
        \\}
    );
}

test "parser: assert pattern ---- with catch default value" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
        \\}
    );
}

test "parser: assert pattern ---- with list pattern" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [first, ..] = items catch throw Error("not a list");
        \\}
    );
}

test "parser: assert pattern ---- with wildcard pattern" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert _ = x catch throw Error("any value");
        \\}
    );
}

test "parser: assert pattern ---- with string literal" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert "hello" = greeting catch throw Error("not hello");
        \\}
    );
}

test "parser: assert pattern ---- with number literal" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert 42 = answer catch throw Error("not 42");
        \\}
    );
}

test "parser: assert pattern ---- with enum variant" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Ok(value) = result catch throw Error("not ok");
        \\}
    );
}

test "parser: assert pattern ---- with multiple bindings" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Point(x, y) = point catch Point(0, 0);
        \\}
    );
}

test "parser: assert pattern ---- with nested pattern" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Ok([first, ..]) = result catch throw Error("not ok");
        \\}
    );
}

test "parser: assert pattern ---- with empty list" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [] = list catch throw Error("not empty");
        \\}
    );
}

test "parser: assert pattern ---- with multiple element list" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [1, 2, 3] = numbers catch throw Error("not matching");
        \\}
    );
}

test "parser: assert pattern ---- with list and rest" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [first, second, ..rest] = items catch [];
        \\}
    );
}

test "parser: await ---- prefix expression" {
    try h.assertParser(std.testing.allocator, @src(),
        \\*fn run() -> @Future<Int> {
        \\    val x = await fetch(url);
        \\    return x;
        \\}
    );
}

test "parser: await ---- chained with try" {
    try h.assertParser(std.testing.allocator, @src(),
        \\*fn run() -> @Future<Int> {
        \\    val x = try await fetch(url);
        \\    return x;
        \\}
    );
}

test "parser: loop await ---- async iteration" {
    try h.assertParser(std.testing.allocator, @src(),
        \\*fn consume(items: Int[]) -> @Future<Int> {
        \\    loop await (items) { item ->
        \\        handle(item);
        \\    }
        \\}
    );
}

test "parser: loop ---- with label" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn collect(items: Int[]) {
        \\    loop :acc (items) { item ->
        \\        yield :acc item;
        \\    }
        \\}
    );
}

test "parser: yield ---- without label" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn collect(items: Int[]) {
        \\    loop (items) { item ->
        \\        yield item;
        \\    }
        \\}
    );
}

test "parser: call as binary operand" {
    // A call chain followed by a binary operator is an operand, not the
    // whole expression: `add(1, 2) == 3`.
    try h.assertParser(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 { return a + b; }
        \\val x = add(1, 2) == 3;
    );
}

test "parser: method chain as binary operand" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val ok = obj.value(1).count() > 0;
        \\}
    );
}

test "parser: assert on call equality" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 { return a + b; }
        \\fn main() {
        \\    assert add(1, 2) == 3, "sum";
        \\}
    );
}

test "parser: string ---- interpolation parts" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val s = "a ${x} b";
    );
}

test "parser: string ---- interpolation expression hole" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val s = "sum ${1 + 2}!";
    );
}

test "parser: string ---- interpolation escaped dollar stays literal" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val s = "price \${USD}";
    );
}

test "parser: string ---- multiline interpolation" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val s = """
        \\hello ${name}
        \\""";
    );
}

test "parser: string ---- interpolation nested string in hole" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val s = "v=${pick("a", key)}";
    );
}

test "parser: tagged call ---- single-line string" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val q = sql "SELECT 1";
    );
}

test "parser: tagged call ---- multiline string" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val component = html """
        \\<Button label=${title}></Button>
        \\""";
    );
}

test "parser: tagged call ---- method receiver" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val q = db.sql "SELECT 1";
    );
}

test "parser: expr stays a plain identifier in expressions" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val expr = 1;
        \\val y = expr + 2;
    );
}

test "parser: optional chaining member access" {
    try h.assertParser(std.testing.allocator, @src(),
        \\record User { name: string }
        \\fn main() {
        \\    val u: ?User = User(name: "ana");
        \\    val n = u?.name;
        \\}
    );
}

test "parser: optional chaining method call" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s: ?string = "abc";
        \\    val up = s?.to_upper();
        \\}
    );
}

test "parser: line string ---- backslash lines join with newlines" {
    // Materialized `\\` content is arena-owned in the production pipeline;
    // mirror that here (stringLit content has no per-node deinit).
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try h.assertParser(arena.allocator(), @src(),
        \\val page =
        \\    \\<div>
        \\    \\  <p>hello</p>
        \\    \\</div>
        \\;
    );
}

test "parser: line string ---- interpolation hole" {
    // Materialized `\\` content is arena-owned in the production pipeline;
    // mirror that here (stringLit content has no per-node deinit).
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try h.assertParser(arena.allocator(), @src(),
        \\val page =
        \\    \\<p>${name}</p>
        \\;
    );
}

test "parser: line string ---- tagged call" {
    // Materialized `\\` content is arena-owned in the production pipeline;
    // mirror that here (stringLit content has no per-node deinit).
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try h.assertParser(arena.allocator(), @src(),
        \\val page = html
        \\    \\<div>
        \\    \\  <p>${name}</p>
        \\    \\</div>
        \\;
    );
}

test "parser: echo is a plain identifier (keyword removed)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn echo(msg: string) -> string {
        \\    return msg;
        \\}
        \\val r = echo("hi");
    );
}
