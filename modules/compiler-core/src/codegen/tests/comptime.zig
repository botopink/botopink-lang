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
        \\fn main() -> void {
        \\    print(v1);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: comptime folding ---- block with a tail value inlines result" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val t = comptime { 2 + 22 };
        \\fn main() -> void {
        \\    print(t);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: comptime folding ---- float multiplication folds to literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val pi2 = comptime { 3.14 * 2.0 };
        \\fn main() -> void {
        \\    print(pi2);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: comptime folding ---- multiplication binds tighter than addition" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val n = comptime { 2 + 3 * 4 };
        \\fn main() -> void {
        \\    print(n);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// `greeting` is a declared module-level runtime `val`, so the error is the
// comptime scope rule (a comptime block may not read a runtime binding), not
// an undeclared name.
test "js: comptime validation ---- runtime identifier inside comptime raises error" {
    try h.assertJsError(std.testing.allocator, @src(),
        \\val greeting = "hi";
        \\val msg = comptime { greeting };
        \\fn main() -> void {
        \\    print(msg);
        \\}
        \\
        \\import {io.terminal.print} from "std";
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
        \\fn main() -> void {
        \\    print(result);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: comptime specialization ---- distinct string args generate specialized functions" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn build(prefix comptime: string, name: string) -> string {
        \\    return prefix + ": " + name;
        \\}
        \\
        \\fn main() -> void {
        \\    val r1 = build("INFO", "Sistema iniciado");
        \\    val r2 = build("WARN", "Memória alta");
        \\    val r3 = build("INFO", "Log replicado");
        \\    print(r1);
        \\    print(r2);
        \\    print(r3);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: comptime specialization ---- distinct integer args generate specialized functions" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn multiply(comptime factor: i32, x: i32) -> i32 {
        \\    return x * factor;
        \\}
        \\
        \\fn main() -> void {
        \\    val double = multiply(2, 21);
        \\    val triple = multiply(3, 21);
        \\    val doubleAgain = multiply(2, 10);
        \\    print(double);
        \\    print(triple);
        \\    print(doubleAgain);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// Every call passes the same comptime `prefix`, so only one specialisation
// (`build_$0`) may be emitted. (It used to repeat the distinct-args fixture
// above with the modifier spelled before the name.)
test "js: comptime specialization ---- same string arg reuses specialized function" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn build(comptime prefix: string, name: string) -> string {
        \\    return prefix + ": " + name;
        \\}
        \\
        \\fn main() -> void {
        \\    val r1 = build("INFO", "Sistema iniciado");
        \\    val r2 = build("INFO", "Log replicado");
        \\    print(r1);
        \\    print(r2);
        \\}
        \\
        \\import {io.terminal.print} from "std";
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
        \\fn main() -> void {
        \\    val doubled = scale(2, base);
        \\    val tripled = scale(3, base);
        \\    val doubledAgain = scale(2, 100);
        \\}
    );
}

test "js: comptime specialization ---- constrained type meta-kind specializes per value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn coerce(comptime v: type<string | int | bool>, x: i32) -> i32 {
        \\    return x;
        \\}
        \\
        \\fn main() -> void {
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
        \\fn main() -> void {
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
        \\    for cmd in COMMANDS {
        \\        if (cmd == slug) {
        \\            output = input * 2;
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() -> void {
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
        \\    for cmd in COMMANDS {
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
        \\fn main() -> void {
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
        \\    for cmd in COMMANDS {
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
        \\fn main() -> void {
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
        \\    for cmd in COMMANDS {
        \\        if (cmd == slug) {
        \\            output = input * 2;
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() -> void {
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
        \\fn main() -> void {
        \\    val r = double(21);
        \\}
    );
}

// A `comptime { … }` block has its own scope: a local `val` is declared,
// folded, and visible to the block's tail (decision 525; `comptime/error.zig`
// `validateBody` + `comptime/eval.zig` `Scope`), as `conformance/docs.md` ("Compile-time
// evaluation") shows. Folds to `20`.
test "js: comptime ---- block with a tail" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val result = comptime {
        \\    val x = 10;
        \\    x * 2
        \\};
        \\fn main() -> void {
        \\    print(result);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: template end to end ---- bounded html expansion" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn html(syntax template: string) -> string {
        \\    return template;
        \\}
        \\val page = html @`
        \\<p>world</p>
        \\`;
        \\fn main() -> void {
        \\    print(page);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: template end to end ---- an anyvalue answer built from text" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn port(syntax q: string) -> anyvalue {
        \\    return compiler.build("8080");
        \\}
        \\fn main() -> void {
        \\    val p = port @`x` + 1;
        \\    print(p);
        \\}
        \\import {compiler} from "std";
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: template end to end ---- cross-module html mirrors the canonical example" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{
            .path = "view",
            .source =
            \\pub fn html(syntax q: string) -> string {
            \\    return q;
            \\}
            ,
        },
        .{
            .path = "",
            .source =
            \\import {view.html};
            \\
            \\val page = html @`<div>
            \\  <p>world</p>
            \\  <Page1/>
            \\</div>`;
            \\fn main() -> void {
            \\    print(page);
            \\}
            \\
            \\import {io.terminal.print} from "std";
            ,
        },
    });
}

// Decision 415 (2) — `q.lookup(name)` answers the caller-scope declaration,
// and the template splices a bare reference to it by its `name`: the build
// expands to the identifier `greeting` — not to its value — and the module
// prints `ola mundo`. (The user fn is named `refer`; a user `pick` would also
// win over the `pick` type-manipulation builtin since std-surface 6a.) The
// miss path is an `else` arm, not a statement after the `if`: in a template
// body lowered by `codegen/erlang.zig` `emitComptimeModule`, a `return` inside
// an if-arm does not leave the function — the `case` value is discarded and the
// next statement runs anyway (visible in the `COMPTIME ERLANG` section of
// `runtime_template_body_lookup_miss_drives_control_flow`, where the miss hides
// it). That lowering gap is owned by the codegen/erlang side, not by comptime.
test "js: template end to end ---- lookup() names a caller-scope declaration the build splices" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val greeting = "ola mundo";
        \\pub fn refer(syntax q: string) -> string {
        \\    val hit = compiler.lookup(q, "greeting");
        \\    if (hit) { b ->
        \\        return compiler.build(b.name);
        \\    } else {
        \\        return compiler.fail("greeting not found in caller scope", at: q);
        \\    };
        \\}
        \\val s = refer @`greeting`;
        \\fn main() -> void {
        \\    print(s);
        \\}
        \\import {compiler} from "std";
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: template end to end ---- yaml model computes a labeled tuple" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn conf(syntax q: string) -> anyvalue {
        \\    val t = compiler.text(q);
        \\    val port = 8000 + t.length;
        \\    val debug = true;
        \\    return #(port, debug);
        \\}
        \\val cfg = conf @`yaml`;
        \\fn main() -> void {
        \\    print(cfg.port + 1);
        \\}
        \\import {compiler} from "std";
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: comptime ---- a constant division by zero is a located comptime error (C4b)" {
    try h.assertJsError(std.testing.allocator, @src(),
        \\val q = comptime 1 / 0;
    );
}

test "js: comptime ---- negating a string is a located comptime error (C4b)" {
    try h.assertJsError(std.testing.allocator, @src(),
        \\val q = comptime -"s";
    );
}

// Decisions 266, 331 (01-checker step 21) — a `comptime` with a call and a
// loop runs on the comptime runtime (wasm, decision 434), never on the
// target: every backend emits `2` and `6` where the source wrote the two
// `comptime`s.
test "js: comptime runtime ---- a block with a call and a loop is evaluated at build" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\
        \\fn two() -> i32 {
        \\    return 2;
        \\}
        \\
        \\fn main() -> void {
        \\    val a = comptime two();
        \\    print(a);
        \\    val d = comptime {
        \\        var d = 0;
        \\        for b in [1, 2, 3] { d = add(d, b); }
        \\        d
        \\    };
        \\    print(d);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// Decision 331 — a record and a declared function lifted: the record the
// block built is written as its constructor, the function as its name, and a
// lambda reading nothing the block declares as the lambda.
test "js: comptime runtime ---- a record holding a function reference is lifted" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Op(name: string, run: fn() -> i32, twice: fn() -> i32)
        \\
        \\fn two() -> i32 {
        \\    return 2;
        \\}
        \\
        \\fn main() -> void {
        \\    val op = comptime Op(name: "two" + "!", run: two, twice: { -> two() * 2 });
        \\    print(op.name);
        \\    print(op.run());
        \\    print(op.twice());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}
