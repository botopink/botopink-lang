//! codegen: extension dispatch (implement/interface/delegate) (split from tests.zig).

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

test "js: implement ---- attaches methods to prototype" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\interface Printable {
        \\    fn print(self: Self),
        \\}
        \\record Person { name: string }
        \\val PersonPrintable = implement Printable for Person {
        \\    fn print(self: Self) {
        \\        return self.name;
        \\    }
        \\}
    );
}

test "js: dispatch ---- inherent record method call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Contador {
        \\    n: i32,
        \\    fn atual(self: Self) {
        \\        return self.n;
        \\    }
        \\}
        \\fn main() {
        \\    val c = Contador(5);
        \\    @print(c.atual());
        \\}
    );
}

test "js: dispatch ---- string contains lowers to native includes" {
    // `s.contains(x)` on a `string` has no `String.prototype.contains`; inference
    // records a type-directed rename so codegen emits `s.includes(x)`. A `record`
    // method of the same name (`Set.contains`) keeps its own dispatch — see the
    // inherent-record-method case above.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val hw = "hello world";
        \\    @print(hw.contains("world"));
        \\}
    );
}

test "js: dispatch ---- auto-applied extension method call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\fn main() {
        \\    val donald = Pato(2);
        \\    @print(donald.swim());
        \\}
    );
}

test "js: dispatch ---- qualified extension method call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\fn main() {
        \\    val donald = Pato(3);
        \\    @print(PatoNada.swim(donald));
        \\}
    );
}

test "js: dispatch ---- multi-module implement on an imported record" {
    // `Pato` crosses the module boundary; the interface and `implement` are local
    // to the consumer. The extension is auto-applied — `donald.swim()` lowers to
    // the local symbol with no activation statement.
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "pond", .source =
        \\pub record Pato { id: i32 }
        },
        .{ .path = "", .source =
        \\import {Pato} from "pond";
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\fn main() {
        \\    val donald = Pato(2);
        \\    @print(donald.swim());
        \\}
        },
    });
}

test "js: dispatch ---- multi-module extension activated via star import" {
    // `pond` ships the `implement`; the consumer activates it with `PatoNada*` and
    // `donald.swim()` lowers to the imported symbol `PatoNada.swim(donald)`.
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "pond", .source =
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\pub record Pato { id: i32 }
        \\pub val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        },
        .{ .path = "", .source =
        \\import {Pato, PatoNada*} from "pond";
        \\fn main() {
        \\    val donald = Pato(2);
        \\    @print(donald.swim());
        \\}
        },
    });
}

test "js: delegate ---- emits comment" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\declare fn Callback(msg: string) -> void;
    );
}

test "js: interface ---- emits comment" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self);
        \\}
    );
}

test "js: delegate ---- declaration" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\declare fn Callback(msg: string) -> void;
    );
}
