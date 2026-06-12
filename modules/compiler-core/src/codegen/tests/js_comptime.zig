//! codegen: comptime folding (split from tests.zig).

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

test "js: comptime folding ---- integer addition folds to literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val v1 = comptime 1 + 1;
        \\@print(v1);
    );
}

test "js: comptime folding ---- block with break value inlines result" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val t = comptime {
        \\    break 2 + 22;
        \\};
        \\@print(t);
    );
}

test "js: comptime folding ---- float multiplication folds to literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val pi2 = comptime {
        \\    break 3.14 * 2.0;
        \\};
        \\@print(pi2);
    );
}

test "js: comptime folding ---- multiplication binds tighter than addition" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val n = comptime {
        \\    break 2 + 3 * 4;
        \\};
        \\@print(n);
    );
}

test "js: comptime validation ---- runtime identifier inside comptime raises error" {
    try h.assertJsError(std.testing.allocator, @src(),
        \\val msg = comptime {
        \\    break greeting;
        \\};
        \\@print(msg);
    );
}

test "js: comptime val ---- runtime val with string literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val greeting = "Hello, World!";
    );
}

test "js: comptime val ---- comptime val folds arithmetic to literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val result = comptime 10 + 20;
        \\@print(result);
    );
}

test "js: comptime specialization ---- distinct string args generate specialized functions" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn build(prefix comptime: string, name: string) -> string {
        \\    return prefix + ": " + name;
        \\}
        \\
        \\fn main() {
        \\    val r1 = build("INFO", "Sistema iniciado");
        \\    val r2 = build("WARN", "Memória alta");
        \\    val r3 = build("INFO", "Log replicado");
        \\}
    );
}

test "js: comptime specialization ---- distinct integer args generate specialized functions" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn multiply(comptime factor: i32, x: i32) -> i32 {
        \\    return x * factor;
        \\}
        \\
        \\fn calculate() {
        \\    val double = multiply(2, 21);
        \\    val triple = multiply(3, 21);
        \\    val doubleAgain = multiply(2, 10);
        \\}
    );
}

test "js: comptime specialization ---- same string arg reuses specialized function" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn build(comptime prefix: string, name: string) -> string {
        \\    return prefix + ": " + name;
        \\}
        \\
        \\fn main() {
        \\    val r1 = build("INFO", "Sistema iniciado");
        \\    val r2 = build("WARN", "Memória alta");
        \\    val r3 = build("INFO", "Log replicado");
        \\}
    );
}

test "js: comptime specialization ---- comptime val used as specialization argument" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val base = comptime 10 + 5;
        \\
        \\fn scale(comptime factor: i32, value: i32) -> i32 {
        \\    return value * factor;
        \\}
        \\
        \\fn main() {
        \\    val doubled = scale(2, base);
        \\    val tripled = scale(3, base);
        \\    val doubledAgain = scale(2, 100);
        \\}
    );
}

test "js: comptime specialization ---- constrained type meta-kind specializes per value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
        \\    return x;
        \\}
        \\
        \\fn main() {
        \\    val a = coerce("s", 1);
        \\    val b = coerce(7, 2);
        \\    val c = coerce("s", 3);
        \\}
    );
}

test "js: comptime specialization ---- simple function body without loop" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    return input + 0;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\    val r3 = execute("calc", 5);
        \\}
    );
}

test "js: comptime loop unrolling ---- single if condition resolved per element" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val COMMANDS = comptime ["calc", "noop", "help"];
        \\
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    var output = 0;
        \\    loop (COMMANDS) { cmd ->
        \\        if (cmd == slug) {
        \\            output = input * 2;
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\}
    );
}

test "js: comptime loop unrolling ---- nested if-else chain fully folded" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val COMMANDS = comptime ["calc", "noop", "help"];
        \\
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    var output = 0;
        \\    loop (COMMANDS) { cmd ->
        \\        if (cmd == slug) {
        \\            if (cmd == "calc") {
        \\                output = input * 2;
        \\            } else if (cmd == "noop") {
        \\                output = input;
        \\            };
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\}
    );
}

test "js: comptime loop unrolling ---- case expression folded inside unrolled loop" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val COMMANDS = comptime ["calc", "noop", "help"];
        \\
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    var output = 0;
        \\    loop (COMMANDS) { cmd ->
        \\        if (cmd == slug) {
        \\            output = case cmd {
        \\                "calc" -> input * 2;
        \\                "noop" -> input;
        \\                _ -> 0;
        \\            };
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\}
    );
}

test "js: comptime partial ---- runtime array loop preserved, comptime param specialized" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val COMMANDS = ["calc", "noop", "help"];
        \\
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    var output = 0;
        \\    loop (COMMANDS) { cmd ->
        \\        if (cmd == slug) {
        \\            output = input * 2;
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\}
    );
}

test "js: comptime basic ---- comptime val and plain function coexist" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val x = comptime 1 + 2;
        \\
        \\fn double(n: i32) -> i32 {
        \\    return n * 2;
        \\}
        \\
        \\fn main() {
        \\    val r = double(21);
        \\}
    );
}

test "js: comptime ---- block with break" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val result = comptime {
        \\    val x = 10;
        \\    break x * 2;
        \\};
    );
}

test "js: template end to end ---- bounded html expansion" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val name = "world";
        \\val page = html """
        \\<p>${name}</p>
        \\""";
        \\fn main() {
        \\    @print(page);
        \\}
    );
}

test "js: template end to end ---- generic expr via code builtin" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn port<T>() -> @Expr<T> {
        \\    return @code("8080");
        \\}
        \\fn main() {
        \\    val p = port() + 1;
        \\    @print(p);
        \\}
    );
}

test "js: template end to end ---- holed html via parts() runs" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
        \\    var acc = "\"\"";
        \\    loop (q.parts()) { p ->
        \\        if (p.kind == "Text") {
        \\            acc = acc + " + \"" + p.text + "\"";
        \\        };
        \\        if (p.kind == "Interp") {
        \\            acc = acc + " + " + p.code;
        \\        };
        \\    };
        \\    return q.build(acc);
        \\}
        \\val name = "world";
        \\val page = html """<p>${name}</p>""";
        \\fn main() {
        \\    @print(page);
        \\}
    );
}

test "js: template end to end ---- line string template with hole" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
        \\    return q;
        \\}
        \\val name = "world";
        \\val page = html
        \\    \\<div>
        \\    \\  <p>${name}</p>
        \\    \\</div>
        \\;
        \\fn main() {
        \\    @print(page);
        \\}
    );
}

test "js: template end to end ---- cross-module html mirrors the canonical example" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{
            .path = "view",
            .source =
            \\pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
            \\    var acc = "\"\"";
            \\    loop (q.parts()) { p ->
            \\        if (p.kind == "Text") {
            \\            acc = acc + " + \"" + p.text + "\"";
            \\        };
            \\        if (p.kind == "Interp") {
            \\            acc = acc + " + " + p.code;
            \\        };
            \\    };
            \\    return q.build(acc);
            \\}
            ,
        },
        .{
            .path = "",
            .source =
            \\import {html} from "view";
            \\
            \\val name = "world";
            \\
            \\val page = html
            \\    \\<div>
            \\    \\  <p>${name}</p>
            \\    \\  <Page1/>
            \\    \\</div>
            \\;
            \\fn main() {
            \\    @print(page);
            \\}
            ,
        },
    });
}

test "js: template end to end ---- lookup().ref() splices a caller-scope reference" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val greeting = "ola mundo";
        \\pub fn pick(comptime q: @Expr<string>) -> @Expr<string> {
        \\    val hit = q.lookup("greeting");
        \\    if (hit) { b ->
        \\        return b.ref();
        \\    };
        \\    return q.fail("greeting not found in caller scope");
        \\}
        \\val s = pick "x";
        \\fn main() {
        \\    @print(s);
        \\}
    );
}

test "js: template end to end ---- yaml model computes a typed record" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
        \\    val t = q.text();
        \\    return @expr(record { port: 8000 + t.length, debug: true });
        \\}
        \\val cfg = conf "yaml";
        \\fn main() {
        \\    @print(cfg.port + 1);
        \\}
    );
}
