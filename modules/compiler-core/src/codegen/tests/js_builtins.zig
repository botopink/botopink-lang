//! codegen: builtin/stdlib/assert (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const codegen = @import("../../codegen.zig");
const snap = @import(".././snapshot.zig");
const config = @import(".././config.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const Module = codegen.Module;
const ModuleOutput = @import(".././moduleOutput.zig").ModuleOutput;
const GenerateResult = @import(".././moduleOutput.zig").GenerateResult;
const comptimeMod = @import("../../comptime.zig");
const validation = @import("../../comptime/error.zig");
const h = @import("helpers.zig");

test "js: assert ---- simple assertion" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert true;
        \\}
    );
}

test "js: assert ---- with arithmetic comparison" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert 1.0 + 2.0 == 3.0;
        \\}
    );
}

test "js: assert ---- with message" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert false, "error message";
        \\}
    );
}

test "js: assert ---- array equality" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert [] == [];
        \\}
    );
}

test "js: assert pattern ---- with catch throw" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Person(name, age) = r catch throw Error("is not person");
        \\}
    );
}

test "js: assert pattern ---- with catch default value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
        \\}
    );
}

test "js: assert pattern ---- with list pattern" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [first, ..] = items catch throw Error("not a list");
        \\}
    );
}

test "js: assert pattern ---- with string literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert "hello" = greeting catch throw Error("not hello");
        \\}
    );
}

test "js: assert pattern ---- with number literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert 42 = answer catch throw Error("not 42");
        \\}
    );
}

test "js: assert pattern ---- with enum variant" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Ok(value) = result catch throw Error("not ok");
        \\}
    );
}

test "js: assert pattern ---- with empty list" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [] = list catch throw Error("not empty");
        \\}
    );
}

test "js: assert pattern ---- with multiple element list" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [1, 2, 3] = numbers catch throw Error("not matching");
        \\}
    );
}

test "js: assert pattern ---- with list and rest" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [first, second, ..rest] = items catch [];
        \\}
    );
}

test "js: builtin ---- @todo with message" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn notImplemented() {
        \\    @todo("implement this function");
        \\}
    );
}

test "js: builtin ---- @panic with message" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn fail() {
        \\    @panic("something went wrong");
        \\}
    );
}

test "js: builtin ---- @print single argument" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("Hello, World!");
        \\}
    );
}

test "js: builtin ---- @print multiple arguments" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("Hello", 42, true);
        \\}
    );
}

test "js: builtin ---- @print expression" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val x = 10;
        \\    @print(x * 2);
        \\}
    );
}

test "js: stdlib ---- Result.map transforms Ok, propagates Error intact" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val r = parseAge("42").map({ n -> n + 1 });
        \\}
    );
}

test "js: stdlib ---- Result.flatMap chains and flattens" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\*fn validate(n: i32) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val r = parseAge("42").flatMap({ n -> validate(n) });
        \\}
    );
}

test "js: stdlib ---- Result.unwrapOr returns data on Ok, default on Error" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val n = parseAge("42").unwrapOr(0);
        \\}
    );
}

test "js: stdlib ---- Result.isOk and isError predicates" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val r = parseAge("42");
        \\    val ok = r.isOk();
        \\    val bad = r.isError();
        \\}
    );
}

test "js: stdlib ---- Option map, flatMap and unwrapOr mirror Result" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Person { name: string }
        \\fn firstName(p: Person) -> ?string { @todo(); }
        \\fn shout(s: string) -> ?string { @todo(); }
        \\fn greet(p: Person) -> string {
        \\    return firstName(p)
        \\        .map({ n -> "Hello " + n })
        \\        .flatMap({ n -> shout(n) })
        \\        .unwrapOr("Hello stranger");
        \\}
    );
}

test "js: stdlib ---- chain map flatMap unwrapOr types correctly" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\*fn validate(n: i32) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val r = parseAge("42")
        \\        .map({ n -> n + 1 })
        \\        .flatMap({ n -> validate(n) })
        \\        .unwrapOr(0);
        \\}
    );
}

test "js: builtin ---- @print in if branch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn check(x: i32) {
        \\    if x > 0 {
        \\        @print("positive");
        \\    } else {
        \\        @print("non-positive");
        \\    }
        \\}
    );
}

test "js: builtin ---- @print with variable" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val name = "world";
        \\    @print("Hello, " + name);
        \\}
    );
}

test "js: builtin ---- @print in loop" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn countdown(n: i32) {
        \\    val i = n;
        \\    loop {
        \\        if i <= 0 { break; }
        \\        @print(i);
        \\        val i = i - 1;
        \\    }
        \\}
    );
}

test "js: builtin ---- @print return value void" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn log(msg: string) {
        \\    @print(msg);
        \\}
        \\fn main() {
        \\    log("started");
        \\    val x = 42;
        \\    log("done");
        \\}
    );
}

test "codegen: test runner" {
    try h.assertJsTestMode(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\
        \\test "addition works" {
        \\    val r = add(2, 3);
        \\    assert r == 5;
        \\}
        \\
        \\test {
        \\    assert true;
        \\}
    );
}

test "codegen: test runner excluded from normal build" {
    const src =
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\
        \\test "addition works" {
        \\    assert add(2, 3) == 5;
        \\}
        \\
        \\fn main() {
        \\    @print("hello");
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{"function add"});
    try h.assertJsNotContains(std.testing.allocator, src, &.{ "__bp_test", "__bp_assert", "__bp_run_tests" });
}
