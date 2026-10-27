//! codegen: WAT backend codegen (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const codegen = @import("../../codegen.zig");
const bpAst = @import("../../ast.zig");
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
const watCodegen = @import("../wat.zig");

test {
    _ = @import("../wat/host_binding.zig");
    _ = @import("../wat/wat_reader.zig");
    _ = @import("../wat/std_leaves.zig");
    _ = @import("../wat/reach.zig");
    _ = @import("../wat/comptime_units.zig");
}

// Front 164 s3 — `String.length` and `String.charCodeAt` are `.wat` leaves
// (`modules/std-wasm/wat/text.wat`): a WasmGC module calls each over its
// `$str`, with no marshal into linear memory, and answers what std-wasm's
// export answered. Decision 1026 — the leaves are `std@string`'s: the module
// imports them, typed over its prelude group.
test "wat: front 164 s3 ---- a std: cell naming a .wat leaf is the leaf, imported from its std unit" {
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    var outputs = try h.generate(alloc, &.{.{ .path = "", .source =
        \\fn main() -> void {
        \\    val s = "héllo, 日本";
        \\    print(s.length());
        \\    print("".length());
        \\    print(s.charCodeAt(1));
        \\    print(s.charCodeAt(8));
        \\    print(s.charCodeAt(9));
        \\    print(s.charCodeAt(-1));
        \\    print("\u{1F600}".charCodeAt(0));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    }}, io, h.configs[3]);
    defer {
        for (outputs.items) |*o| o.result.deinit(alloc);
        outputs.deinit(alloc);
    }
    const o = for (outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "") or std.mem.eql(u8, o.name, "main")) break o;
    } else return error.ModuleDidNotCompile;
    const wat_text = o.result.js;
    // Decision 1037 — imported through the unit's abstract signature, called
    // through a thunk of the module's concrete one.
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "(import \"std@string\" \"wat:text.length\" (func $__abi___std_text_length (param arrayref) (result i32)))") != null);
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "(import \"std@string\" \"wat:text.charCodeAt\" (func $__abi___std_text_charCodeAt (param arrayref i32) (result i32)))") != null);
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "\n  (func $__std_text_length (param $p0 (ref null $str)) (result i32)\n    local.get $p0\n    call $__abi___std_text_length\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "__gc_to_lin_str") == null);
    try std.testing.expectEqualStrings("9\n0\n233\n26412\n-1\n-1\n128512\n", o.result.run_output orelse "");
}

// Front 164 s2 P4 — a task is a `$task` in a WasmGC module: an asynchronous
// function's frame a typed struct, the value boxed when it settles, an
// `async { }` block a lifted state machine, and `await` outside a machine the
// scheduler run in place.
test "wat: front 164 s2 P4 ---- tasks and their frames are GC structs" {
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    var outputs = try h.generate(alloc, &.{.{ .path = "", .source =
        \\async fn twice(n: i32) -> Async<i32> {
        \\    return n * 2;
        \\}
        \\async fn greet(name: string) -> Async<string> {
        \\    val n = await twice(21);
        \\    return name + " " + n.toString();
        \\}
        \\async fn run() -> Async<void> {
        \\    val b = async {
        \\        val g = await greet("hi");
        \\        return g;
        \\    };
        \\    print(await b);
        \\}
        \\fn main() -> void {
        \\    run();
        \\}
        \\
        \\import {io.terminal.print} from "std";
    }}, io, h.configs[3]);
    defer {
        for (outputs.items) |*o| o.result.deinit(alloc);
        outputs.deinit(alloc);
    }
    const o = for (outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "") or std.mem.eql(u8, o.name, "main")) break o;
    } else return error.ModuleDidNotCompile;
    const wat_text = o.result.js;
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "(type $task (struct") != null);
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "(func $__task_settle (param $t (ref null $task)) (param $v anyref)") != null);
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "struct.new_default $frame") != null);
    try std.testing.expectEqualStrings("hi 42\n", o.result.run_output orelse "");
}

// Front 164 s2, decisions 568 and 569 — a tuple is `$tuple`, a subtype of
// `$arr_any` of its own, so a type parameter's slot holding one prints
// `#(…)` (`$__print_tuple`), never `[…]`; and `==` over a generic record whose
// type arguments are not written compares its erased slots through the
// structural `$__unk_eq` (`$__unk_eq_ref`: a record, an array, a tuple by
// their parts). Both kept the module in linear memory before.
test "wat: front 164 s2 ---- a tuple in a type parameter's slot, and a structural unknown equality" {
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    var outputs = try h.generate(alloc, &.{.{ .path = "", .source =
        \\type Box<T>(value: T)
        \\type Pair<A, B>(left: A, right: B)
        \\fn id<T>(x: T) -> T {
        \\    return x;
        \\}
        \\fn main() -> void {
        \\    print(Box(value: #(1, 2)));
        \\    print(id(#(3, "x")));
        \\    print(Pair(left: #(1, "a"), right: [1, 2]) == Pair(left: #(1, "a"), right: [1, 2]));
        \\    print(Pair(left: #(1, "a"), right: [1, 2]) == Pair(left: #(1, "b"), right: [1, 2]));
        \\    print(Pair(left: [1.5, 2.5], right: Box(value: "x")) == Pair(left: [1.5, 2.5], right: Box(value: "x")));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    }}, io, h.configs[3]);
    defer {
        for (outputs.items) |*o| o.result.deinit(alloc);
        outputs.deinit(alloc);
    }
    const o = for (outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "") or std.mem.eql(u8, o.name, "main")) break o;
    } else return error.ModuleDidNotCompile;
    const wat_text = o.result.js;
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "(type $tuple (sub final $arr_any (array (mut anyref))))") != null);
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "(func $__unk_eq_ref (param $a anyref) (param $b anyref) (result i32)") != null);
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "(func $__unk_eq_arr_f64") != null);
    try std.testing.expectEqualStrings(
        \\Box(value: #(1, 2))
        \\#(3, "x")
        \\true
        \\false
        \\true
        \\
    , o.result.run_output orelse "");
}

// Front 164 s3 P1-a — `text.byteLength`, `text.byteAt`, `text.byteSlice` and
// `text.fromCodepoint` are `.wat` leaves too. No String method is bound to
// them yet and a `std:` cell is std's alone (decision 445), so the program is
// a module of std's own declaring them.
test "wat: front 164 s3 ---- the byte leaves and fromCodepoint answer in a GC module" {
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    var outputs = try h.generate(alloc, &.{.{ .path = "", .std_member = true, .source =
        \\#[compiler.external(.Wasm(std: "text.byteLength"))]
        \\declare fn byteLength(s: string) -> i32;
        \\#[compiler.external(.Wasm(std: "text.byteAt"))]
        \\declare fn byteAt(s: string, i: i32) -> i32;
        \\#[compiler.external(.Wasm(std: "text.byteSlice"))]
        \\declare fn byteSlice(s: string, a: i32, b: i32) -> string;
        \\#[compiler.external(.Wasm(std: "text.fromCodepoint"))]
        \\declare fn fromCodepoint(cp: i32) -> string;
        \\fn main() -> void {
        \\    val s = "aé日😀";
        \\    print(byteLength(s));
        \\    print(byteLength(""));
        \\    print(byteAt(s, 1));
        \\    print(byteAt(s, 2));
        \\    print(byteAt(s, 10));
        \\    print(byteAt(s, 11));
        \\    print(byteAt(s, -1));
        \\    print(byteSlice(s, 1, 3));
        \\    print(byteSlice(s, 3, 6));
        \\    print(byteSlice(s, -4, 1));
        \\    print(byteSlice(s, 3, 1).length());
        \\    print(byteSlice(s, 6, 99));
        \\    print(byteSlice(s, 50, 99).length());
        \\    print(fromCodepoint(97));
        \\    print(fromCodepoint(233));
        \\    print(fromCodepoint(26085));
        \\    print(fromCodepoint(128512));
        \\    print(byteLength(fromCodepoint(128512)));
        \\    print(byteLength(fromCodepoint(127)));
        \\    print(byteLength(fromCodepoint(128)));
        \\    print(byteLength(fromCodepoint(2047)));
        \\    print(byteLength(fromCodepoint(2048)));
        \\    print(byteLength(fromCodepoint(65535)));
        \\    print(byteLength(fromCodepoint(65536)));
        \\    print(byteLength(fromCodepoint(1114111)));
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    }}, io, h.configs[3]);
    defer {
        for (outputs.items) |*o| o.result.deinit(alloc);
        outputs.deinit(alloc);
    }
    const o = for (outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "") or std.mem.eql(u8, o.name, "main")) break o;
    } else return error.ModuleDidNotCompile;
    if (o.result.diagnostic) |d| switch (d) {
        .type => |t| std.debug.print("\n=== refused: {s}\n", .{t.message}),
        .syntax => {},
    };
    const wat_text = o.result.js;
    for ([_][]const u8{ "byteLength", "byteAt", "byteSlice", "fromCodepoint" }) |leaf| {
        var buf: [64]u8 = undefined;
        try std.testing.expect(std.mem.indexOf(u8, wat_text, try std.fmt.bufPrint(&buf, "(func $__std_text_{s} ", .{leaf})) != null);
    }
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "__gc_to_lin_str") == null);
    try std.testing.expectEqualStrings(
        "10\n0\n195\n169\n-1\n-1\n-1\né\n日\na\n0\n😀\n0\na\né\n日\n😀\n4\n1\n2\n2\n3\n3\n4\n4\n",
        o.result.run_output orelse "",
    );
}

// Front 164 s3 P2-a — an integer's text is the `.wat` leaves'
// (`number.i32ToString`, `number.i64ToString`, `number.u64ToString`) in a GC
// module: `@print` of an `i64` / `u64` writes the leaf's `$str`, a `toString`
// calls it, and no digit goes through linear memory.
test "wat: front 164 s3 ---- an integer's text is the number leaves in a GC module" {
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    var outputs = try h.generate(alloc, &.{.{ .path = "", .source =
        \\fn main() -> void {
        \\    val lo: i64 = -9223372036854775807 - 1;
        \\    val hi: i64 = 9223372036854775807;
        \\    val big: u64 = 18446744073709551615;
        \\    val mid: u64 = 9223372036854775808;
        \\    val z: i64 = 0;
        \\    val one: i64 = -1;
        \\    print(lo);
        \\    print(hi);
        \\    print(big);
        \\    print(mid);
        \\    print(z);
        \\    print(one);
        \\    print(lo.toString());
        \\    print(big.toString());
        \\    val n: i32 = -2147483648;
        \\    print(n.toString());
        \\    print(n);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    }}, io, h.configs[3]);
    defer {
        for (outputs.items) |*o| o.result.deinit(alloc);
        outputs.deinit(alloc);
    }
    const o = for (outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "") or std.mem.eql(u8, o.name, "main")) break o;
    } else return error.ModuleDidNotCompile;
    if (o.result.diagnostic) |d| switch (d) {
        .type => |t| std.debug.print("\n=== refused: {s}\n", .{t.message}),
        .syntax => {},
    };
    const wat_text = o.result.js;
    for ([_][]const u8{ "i64ToString", "u64ToString", "i32ToString" }) |leaf| {
        var buf: [64]u8 = undefined;
        try std.testing.expect(std.mem.indexOf(u8, wat_text, try std.fmt.bufPrint(&buf, "(func $__std_number_{s} ", .{leaf})) != null);
    }
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "i64Text") == null);
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "__gc_to_lin_str") == null);
    try std.testing.expectEqualStrings(
        "-9223372036854775808\n9223372036854775807\n18446744073709551615\n9223372036854775808\n0\n-1\n-9223372036854775808\n18446744073709551615\n-2147483648\n-2147483648\n",
        o.result.run_output orelse "",
    );
}

// Front 164 s3 P2-d — `bytes.length`, `bytes.at` and `bytes.ofWords`, the three
// leaves `encoding`'s byte codecs are written over (decision 585 (k)). Their
// `std:` cells wait for the `.bp` half in `libs/std`, so the program is a
// module of std's own declaring them.
test "wat: front 164 s3 ---- the bytes leaves answer in a GC module" {
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    const decls =
        \\#[compiler.external(.Wasm(std: "bytes.length"))]
        \\declare fn bytesLength(b: bytes) -> i32;
        \\#[compiler.external(.Wasm(std: "bytes.at"))]
        \\declare fn bytesAt(b: bytes, i: i32) -> i32;
        \\#[compiler.external(.Wasm(std: "bytes.ofWords"))]
        \\declare fn bytesOfWords(w: array<i32>) -> bytes;
        \\import {io.terminal.print, compiler} from "std";
    ;
    // In its domain a leaf answers; outside it (decision 880) it traps: `at`
    // past the end or negative, `ofWords` at the first word beyond `0..255`.
    const bodies = [_]struct { body: []const u8, expect: ?[]const u8 }{
        .{ .body = "val b = bytesOfWords([104, 105, 255]);\n print(bytesLength(b));\n print(bytesAt(b, 0));\n print(bytesAt(b, 2));\n print(bytesLength(bytesOfWords([])));", .expect = "3\n104\n255\n0\n" },
        .{ .body = "val b = bytesOfWords([104, 105, 33]);\n print(bytesAt(b, 3));", .expect = null },
        .{ .body = "val b = bytesOfWords([104, 105, 33]);\n print(bytesAt(b, -1));", .expect = null },
        .{ .body = "val b = bytesOfWords([104, 105, 289]);\n print(bytesLength(b));", .expect = null },
    };
    for (bodies) |c| {
        const src = try std.fmt.allocPrint(alloc, "{s}\nfn main() -> void {{\n {s}\n}}\n", .{ decls, c.body });
        defer alloc.free(src);
        var outputs = try h.generate(alloc, &.{.{ .path = "", .std_member = true, .source = src }}, io, h.configs[3]);
        defer {
            for (outputs.items) |*o| o.result.deinit(alloc);
            outputs.deinit(alloc);
        }
        const o = for (outputs.items) |o| {
            if (std.mem.eql(u8, o.name, "") or std.mem.eql(u8, o.name, "main")) break o;
        } else return error.ModuleDidNotCompile;
        try std.testing.expect(std.mem.indexOf(u8, o.result.js, "(func $__std_bytes_ofWords ") != null);
        const got = o.result.run_output orelse "";
        if (c.expect) |e| {
            try std.testing.expectEqualStrings(e, got);
        } else {
            try std.testing.expect(std.mem.indexOf(u8, got, "RUNTIME TRAP (wasmtime)") != null);
        }
    }
}

// Front 164 s3 P2-e — `random.*` as leaves: the stream's word is the prelude's
// `$__random_state` global, the host's entropy the prelude's
// `$__wasi_random_f64`, both named by the leaf (decision 585 (i), (j)) and,
// since decision 1026, declared by the leaves' unit `std@io@random` (the
// state) and the runtime core (the entropy), never by the module. The draws are the commonJS sidecar's Mulberry32,
// bit for bit (`std-wasm/src/random.zig`'s test).
test "wat: front 164 s3 ---- random.* leaves name the prelude's state and entropy" {
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    var outputs = try h.generate(alloc, &.{.{ .path = "", .std_member = true, .source =
        \\#[compiler.external(.Wasm(std: "random.float"))]
        \\declare fn randomFloat() -> f64;
        \\#[compiler.external(.Wasm(std: "random.seed"))]
        \\declare fn randomSeed(s: i32) -> void;
        \\#[compiler.external(.Wasm(std: "random.seededFloat"))]
        \\declare fn randomSeededFloat() -> f64;
        \\fn main() -> void {
        \\    val f = randomFloat();
        \\    print(f >= 0.0 && f < 1.0);
        \\    val u = randomSeededFloat();
        \\    print(u >= 0.0 && u < 1.0);
        \\    randomSeed(42);
        \\    print(randomSeededFloat());
        \\    print(randomSeededFloat());
        \\    print(randomSeededFloat());
        \\    randomSeed(-7);
        \\    print(randomSeededFloat());
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    }}, io, h.configs[3]);
    defer {
        for (outputs.items) |*o| o.result.deinit(alloc);
        outputs.deinit(alloc);
    }
    const o = for (outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "") or std.mem.eql(u8, o.name, "main")) break o;
    } else return error.ModuleDidNotCompile;
    if (o.result.diagnostic) |d| switch (d) {
        .type => |t| std.debug.print("\n=== refused: {s}\n", .{t.message}),
        .syntax => {},
    };
    const wat_text = o.result.js;
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "(import \"std@io@random\" \"wat:random.seededFloat\" (func $__std_random_seededFloat ") != null);
    try std.testing.expect(std.mem.indexOf(u8, wat_text, "$__random_state") == null);
    const rt = try @import("../wat/runtime_unit.zig").get();
    const unit = rt.unit("std@io@random").?;
    try std.testing.expect(std.mem.indexOf(u8, unit.text, "(global $__random_state (mut i64)") != null);
    try std.testing.expect(std.mem.indexOf(u8, unit.text, "(import \"std@__rt\" \"__wasi_random_f64\" (func $__wasi_random_f64 ") != null);
    try std.testing.expectEqualStrings(
        "true\ntrue\n0.6011037519201636\n0.44829055899754167\n0.8524657934904099\n0.43306733411736786\n",
        o.result.run_output orelse "",
    );
}

test "wat: record construct two fields" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32)
        \\fn make() -> Point {
        \\    return Point(x: 3, y: 4);
        \\}
    );
}

test "wat: tuple construct then destructure" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val t = #(10, 20);
        \\    val #(a, b) = t;
        \\    print(a + b);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: enum payload construct as tagged struct" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(r: i32),
        \\    Square(side: i32),
        \\}
        \\fn makeCircle() -> Shape {
        \\    return Shape.Circle(r: 5);
        \\}
    );
}

test "wat: string concat via linear memory" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn greeting() -> string {
        \\    return "Hello, " + "World";
        \\}
    );
}

test "wat: string compare via byte loop" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sameWord() -> bool {
        \\    return "foo" == "bar";
        \\}
    );
}

test "wat: string len reads length prefix" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn n() -> i32 {
        \\    val s = "hello";
        \\    return s.len;
        \\}
    );
}

test "wat: string slice copies bytes into a new buffer" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn first3() -> string {
        \\    val s = "hello";
        \\    return s.slice(0, 3);
        \\}
    );
}

// C-04 (01 step 7, N1) closed the documented skip this test used to pin.
// `libs/std/src/primitives.bp` declares `default fn slice(self, start: i32,
// end: ?i32 = null)`, so the one-argument call is legal — and now the checker
// fills the declared default in, so all four snapshots hold the same lowering
// as the two-argument call and a RUN LOG of `3`. The argument reaches the
// backends written out — `end` is the `null` the declaration gives it — and wasm
// read that `null` as `0` and trapped until `00 · 05-wasm` made it the end.
test "wat: string slice without end arg slices to source length" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val s = "hello";
        \\    val tail = s.slice(2);
        \\    print(tail.len);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: string len participates in arithmetic" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val s = "hello";
        \\    print(s.len + 1);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: string slice result length is readable" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val s = "abcdef";
        \\    val mid = s.slice(1, 5);
        \\    print(mid.len);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F1 — anonymous record literal lowering. The literal allocates `fields.len * 4`
// bytes in the bump heap, stores each value at offset `i * 4` in source-text
// order, then leaves the base pointer on the stack. Field-by-name read across
// untyped receivers is the separate uniqueFieldOffset heuristic (below).
test "wat: anon record literal two fields" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn make() -> #(i32, i32) {
        \\    val r = #(7, 11);
        \\    return r;
        \\}
    );
}

test "wat: anon record literal nested" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn make() -> #(#(i32, i32), i32) {
        \\    val outer = #(#(1, 2), 3);
        \\    return outer;
        \\}
    );
}

// F1 — field-by-name read via the unique-field-offset heuristic. wat.zig is
// untyped; this fixture pins that an unambiguous field name on the receiver
// lowers to an `i32.load offset=N` against the standalone record's slot
// layout. A second record sharing no field names doesn't perturb the lookup.
test "wat: record field access via unique name" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32)
        \\fn first(p: Point) -> i32 {
        \\    return p.x;
        \\}
        \\fn second(p: Point) -> i32 {
        \\    return p.y;
        \\}
    );
}

test "wat: record returned then field read on call result" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Span(start: i32, end: i32, line: i32)
        \\fn span() -> Span {
        \\    return Span(start: 4, end: 9, line: 2);
        \\}
        \\fn lineNo() -> i32 {
        \\    return span().line;
        \\}
    );
}

// wat-refactor F2 — type-recovered field access by name (`local_types` +
// `recordTypeOfExpr`). Same spec scenario, runs under wasmtime + prints `11`.
test "wat: record field access by name loads at declared offset" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(a: i32, b: i32)
        \\fn main() -> void {
        \\    val r = R(a: 7, b: 11);
        \\    print(r.b);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// wat-refactor F3 — `?.field` on a null receiver short-circuits to
// `i32.const 0`; on a non-null pointer it loads the named slot via the
// `local.tee` + `i32.eqz` + `(if (result i32) ...)` guard.
test "wat: optional chaining on record null returns zero" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(a: i32, b: i32)
        \\fn pick(maybe: ?R) -> ?i32 {
        \\    return maybe?.b;
        \\}
    );
}

// F1 tail — anon record let-bound to a local then field-read by name. The
// synthetic `__anon_L*_C*` registration in `ensureAnonRecord` lets
// `recordTypeOfExpr` resolve the receiver back to its anon layout so
// `r.kind` lowers to `i32.load offset=4` (slot 1, not the legacy stub).
test "wat: anon record let-bound then field read by name" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val code = 7;
        \\    val kind = 11;
        \\    val r = #(code, kind);
        \\    print(r.kind);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F1 tail — nested anon record reads through the chained type slot. The
// outer literal records its `span` field's type as the inner anon's
// synthetic name; `outer.span.start` therefore lowers to a real
// `i32.load` chain instead of the legacy `i32.const 0` stub.
test "wat: nested anon record chained field read" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val start = 5;
        \\    val end = 9;
        \\    val span = #(start, end);
        \\    val kind = 3;
        \\    val outer = #(span, kind);
        \\    print(outer.span.start);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F2 — Optionals `?T`. Carrier shape on WAT: a reference-typed value is
// non-zero when present, `i32.const 0` when absent. The four fixtures
// below pin the four common shapes the F0 audit identified in template
// bodies:
//
//   1. local `?T = null` round-trips through equality check.
//   2. `?T` from a fn return — null path.
//   3. `?T` from a fn return — value path with `?.`.
//   4. `if x == null` branch + non-null deref via `?.`.

// F2.1 — Optional local initialised to null, equality test against null.
test "wat: optional local equals null" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val x: ?i32 = null;
        \\    if (x == null) {
        \\        print(1);
        \\    } else {
        \\        print(0);
        \\    }
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F2.2 — Optional fn return — null arm.
test "wat: optional fn return null path" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(kind: i32)
        \\fn choose(present: bool) -> ?R {
        \\    if (present) {
        \\        return R(kind: 7);
        \\    } else {
        \\        return null;
        \\    }
        \\}
        \\fn main() -> void {
        \\    print(choose(false)?.kind);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F2.3 — Optional fn return — value path with `?.`.
test "wat: optional fn return present path with optional chaining" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(kind: i32)
        \\fn choose(present: bool) -> ?R {
        \\    if (present) {
        \\        return R(kind: 7);
        \\    } else {
        \\        return null;
        \\    }
        \\}
        \\fn main() -> void {
        \\    print(choose(true)?.kind);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F2.4 — Branch on `x == null`, deref through `?.` on the present arm.
test "wat: optional branch on equality and chained deref" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type R(kind: i32)
        \\fn main() -> void {
        \\    val r = R(kind: 11);
        \\    val maybe: ?R = r;
        \\    if (maybe == null) {
        \\        print(0);
        \\    } else {
        \\        print(maybe.kind);
        \\    }
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F3 — String operations. WAT strings are length-prefixed buffers in
// linear memory (4-byte little-endian length, then raw bytes). The
// existing `__str_concat` / `__str_eq` / `__str_slice` runtime helpers
// already cover concat/equality/slice; `.len` reads the prefix word.
// The 5 fixtures below pin the full surface the F0 audit identified.

// F3.1 — concat of two literals via `+`.
test "wat: string concat of two literals" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val s = "hi " + "there";
        \\    print(s.len);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F3.2 — equality compares content, not identity. `left` is built at runtime,
// so it is not the interned "foo" pointer; `diff` is the false case. Expected
// RUN LOG `1` then `0`, on all four backends.
test "wat: string equality compares content not identity" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val left = "fo" + "o";
        \\    val same = left == "foo";
        \\    val diff = "foo" == "bar";
        \\    if (same) {
        \\        print(1);
        \\    } else {
        \\        print(0);
        \\    };
        \\    if (diff) {
        \\        print(1);
        \\    } else {
        \\        print(0);
        \\    }
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F3.3 — slice with both bounds.
test "wat: string slice both bounds" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val s = "hello";
        \\    val mid = s.slice(1, 4);
        \\    print(mid.len);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F3.4 — length of a runtime concat (composes with `+`).
test "wat: string length after concat" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val s = "ab" + "cdef";
        \\    print(s.len);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F3.5 — `if (s == lit)` branch lights up the equality path inside an if. `s`
// is built at runtime so a pointer-identity compare could not pass. Expected
// RUN LOG `42`; beam's is empty while string `+` is arithmetic (04-beam B3).
test "wat: string equality drives if branch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val s = "ye" + "s";
        \\    if (s == "yes") {
        \\        print(42);
        \\    } else {
        \\        print(0);
        \\    }
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F4 — List literals over linear memory. Layout: `[len i32][elem0]...`
// (same prefix convention as strings, so `.len` is uniform). The four
// fixtures below pin the F0 audit's list-literal shapes.

// F4.1 — `[1, 2, 3].len` → 3.
test "wat: list literal len reads length prefix" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val xs = [1, 2, 3];
        \\    print(xs.len);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F4.2 — `[].len` → 0.
test "wat: empty list literal len is zero" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val xs: i32[] = [];
        \\    print(xs.len);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F4.3 — list literal of strings (each element is a heap pointer).
test "wat: list literal of strings len" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val labels = ["a", "bb", "ccc"];
        \\    print(labels.len);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F4.4 — list literal of records (each element is a base pointer).
test "wat: list literal of records len" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type P(x: i32, y: i32)
        \\fn main() -> void {
        \\    val pts = [P(x: 1, y: 2), P(x: 3, y: 4)];
        \\    print(pts.len);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F5 — Structured throw/catch surface. WAT models `@Result`-style
// try/catch over a `[tag, payload]` linear-memory pair (tag 0 = Ok,
// non-zero = Error). `@panic`/`@todo`/`throw` collapse to `unreachable`
// — the backend does not use the exceptions proposal. The 3 fixtures
// below pin the `@Result`-based shape.

// F5.1 — try a `#[@result]` fn, catch the error and yield a default.
test "wat: try catch on result with default fallback" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn maybeFail(should_fail: bool) -> Result<i32, string> {
        \\    if (should_fail) {
        \\        throw "boom";
        \\    } else {
        \\        return 42;
        \\    }
        \\}
        \\fn main() -> void {
        \\    val v = try maybeFail(false) catch -1;
        \\    print(v);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F5.2 — try expression with catch handler — the error path runs.
test "wat: try catch returns handler value on error" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn maybeFail(should_fail: bool) -> Result<i32, string> {
        \\    if (should_fail) {
        \\        throw "boom";
        \\    } else {
        \\        return 42;
        \\    }
        \\}
        \\fn main() -> void {
        \\    val v = try maybeFail(true) catch -1;
        \\    print(v);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// F5.3 — `try` propagation: the inner Error variant propagates up.
test "wat: try propagation in result fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn inner(should_fail: bool) -> Result<i32, string> {
        \\    if (should_fail) {
        \\        throw "inner-fail";
        \\    } else {
        \\        return 7;
        \\    }
        \\}
        \\fn outer(should_fail: bool) -> Result<i32, string> {
        \\    val v = try inner(should_fail);
        \\    return v + 1;
        \\}
        \\fn main() -> void {
        \\    val r = try outer(false) catch -1;
        \\    print(r);
        \\    val r2 = try outer(true) catch -1;
        \\    print(r2);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// ── decision 8 §5: the three defects `01-checker` handed to the backends ─────
//
// Each of the fixtures below answered wrongly on wasm before front 05's case
// row; every backend has taken its half since, and the four logs agree.

// §5.1 P8 — a pattern's variant name reaches the backend with the path it was
// **written** with (`Shape.Circle`), while the constructor stores the bare
// `Circle`, so a dotted arm never matched: wasm answered `0` for a `Circle`.
// Every backend has since taken its half — `04-js` at `f1757f41`, `02-erlang`
// and `03-beam` in the `f8d97f95` window — so all four now print `7` then `0`:
// the dotted arm matches a `Circle`, and a `Rect` is not one. erlang answered `0`
// twice; beam left an empty RUN LOG, lifting each arm body into a
// `-main/0-fun-N-` closure it never applied.
test "wat: case ---- a variant pattern written as a dotted path" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(width: i32, height: i32),
        \\}
        \\fn main() -> void {
        \\    val c = Shape.Circle(radius: 7);
        \\    case c {
        \\        Shape.Circle(r) { print(r); }
        \\        _ { print(0); }
        \\    };
        \\    val q = Shape.Rect(width: 2, height: 5);
        \\    case q {
        \\        Shape.Circle(r) { print(r); }
        \\        _ { print(0); }
        \\    };
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// §5.1 P8 — the dot shorthand `.Circle(r)`, whose enum comes from the matched
// value. The leading `.` is what tells a variant path from a binding, so it
// stays in the name. All four print `7`; erlang answered `0` and beam printed
// nothing, both since fixed.
test "wat: case ---- the dot-shorthand variant pattern" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(width: i32, height: i32),
        \\}
        \\fn main() -> void {
        \\    val c = Shape.Circle(radius: 7);
        \\    case c {
        \\        .Circle(r) { print(r); }
        \\        _ { print(0); }
        \\    };
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// §5.1 P3 — an arm written `Pattern { … }` arrives as a lambda whose last
// expression is the arm's value. wasm lifted it into the function table and
// left the arm answering a closure-cell address, so the body never ran: this
// program printed nothing at all. All four now print `circle`; beam's log was
// empty until `03-beam` landed, the lifted-closure shape above.
test "wat: case ---- an arm body's statements run and its last expression is its value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(width: i32, height: i32),
        \\}
        \\fn main() -> void {
        \\    val s = Shape.Circle(radius: 3);
        \\    case s {
        \\        Circle(r) { print("circle"); }
        \\        Rect(w, h) { print("rect"); }
        \\    };
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// §5.1 P1 — a one-parameter arm binder binds the whole matched value. All four
// print `7`. erlang did not assemble at all (`main.erl:10:27: variable 'N' is
// unbound`) and beam's log was empty, until 02 and 03 took their halves.
test "wat: case ---- a one-parameter arm binder binds the matched value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val v = 7;
        \\    case v {
        \\        0 { print("zero"); }
        \\        _ { n -> print(n); }
        \\    };
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// §5.3 — a failing guard falls through to the next arm. wasm dropped the guard
// entirely, so a guarded arm matched unconditionally: `classify` answered
// `"positive"` for every `n` (`case_guard_bound_identifier_numeric_guard`
// recorded exactly that).
test "wat: case ---- a failing guard falls through to the next arm" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn classify(n: i32) -> string {
        \\    return case n {
        \\        x if x > 0 -> "positive";
        \\        0 -> "zero";
        \\        _ -> "negative";
        \\    };
        \\}
        \\fn main() -> void {
        \\    print(classify(5));
        \\    print(classify(0));
        \\    print(classify(-3));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// ── C-02: an index IS a method call (decision 63, amended 2026-09-19) ───────
//
// `15-language-surface` landed `xs[0]` in the parser as the reserved builtin
// call `ast.index_builtin_name` over `(receiver, index)`, and `xs[0..2]` is the
// same node with a `range` where the index goes. Each backend then grew its own
// lowering for that node — and the checker still had no type for it, so `xs[0]`
// was `void` and every front wrote `.at(i)` by hand.
//
// C-02 removed the node instead. The checker rewrites it: `xs[k]` IS `xs.at(k)`,
// `xs[a..b]` is `xs.slice(a, b)`, `xs[1..]` is `xs.slice(1, null)`, and a tuple's
// `t[0]` is `t._0`. The four fixtures below are unchanged on purpose — the same
// programs, re-recorded — because what they now measure is different: not four
// lowerings of an index, but whether `Array.at`, `Array.slice` and `String.slice`
// answer on each target. Two of them do not, and BOTH are reproducible with the
// method written by hand and no index anywhere in the program:
//
//   wasm   `rows.at(1)` on an array OF arrays answers a raw heap address (`308`),
//          and `.at(0)` / `.length` of that is `0`; `s.slice(3, null)` — an open
//          end — trapped with `out of bounds memory access` until `00 · 05-wasm`
//          read a `null` end as the end (`a null end, written or at run time,
//          is the end`); it answers `lo` / `[20, 30]` now.
//   beam   `xs.slice(1, null)` and `s.slice(1, 3)` do not assemble:
//          `beam_asm` folds `Array.slice`'s `default fn` body to its
//          `end != null` arm with no test emitted (the `.S` calls
//          `lists:sublist/3` on `{atom, undefined}`), and it emits a
//          `String_slice/3` whose labels do not resolve. `codegen/beam_asm.zig`
//          is `fix/identity-half3`'s file right now; reported, not reached into.
//
// The gain is on the same two targets, and it is why the trade is worth taking:
// beam used to RUN these programs at exit 0 and answer the receiver or `ok`
// where an element belongs, and wasm answered `0` for an index past the end. An
// index that fails is a defect that can be found; an index that quietly answers
// the wrong thing is what sent two fronts to `.length()`.
//
// One divergence among the four is nobody's row here: a slice prints `[20, 30]`
// on commonJS and beam against `[20,30]` on wasm and erlang (decision 8 §7's
// separator).
test "wat: index ---- an array element, a string character and a slice" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val xs = [10, 20, 30];
        \\    val i = 1;
        \\    print(xs[0]);
        \\    print(xs[i + 1]);
        \\    val names = ["ana", "bo"];
        \\    print(names[1]);
        \\    val s = "hello";
        \\    print(s[1]);
        \\    print(s[1..3]);
        \\    print(s[3..]);
        \\    print(xs[1..]);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// An index past the end is `xs.at(9)`, whose type is `?i32`, and decision 47
// spells absent `null`. commonJS (`__bp_array_at`) and wasm (`$__print_null`)
// print it so since 1.0.10-beta `00 · 04-js` / `05-wasm`; erlang and beam still
// print the atom `undefined` — C-18's row, theirs.
test "wat: index ---- an index past the end answers zero" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val xs = [10, 20, 30];
        \\    print(xs[9]);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// A float array's slots are `f32`. `fs[0]` and `fs.at(0)` are now the SAME
// expression — that is the whole of decision 63's amendment in one line — so
// the two prints are one lowering and answer `1.5` on all four targets. The
// fixture used to pin them as two different paths, one of which (`$__print_opt_i32`
// over a `?f32` box) printed `1069547520` for `1.5`.
test "wat: index ---- a float array element is reinterpreted, not read as bits" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val fs = [1.5, 2.5];
        \\    print(fs[0]);
        \\    print(fs.at(0));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// The shapes `conformance/modules/decisions-taken/record_field_assignment_refused-37/run/src/cases/index_expression` asks for that the three
// fixtures above do not reach: an index whose element is itself an array
// (`rows[1][0]`, which is `rows.at(1).at(0)` — a method call on a `?T`
// receiver, which the checker lets flow), a slice's length, and a tuple
// element.
//
// commonJS and erlang answer everything, modulo §7's separator (commonJS
// prints `ps[1]` as `[2, "b"]`, `04-js`'s row). wasm answers erlang's text:
// `rows[1]` and `ps[1]` print by the element's shape (`OptInfo.shape`) — they
// printed the row's and the tuple's heap address at exit 0 until
// `01-compiler/05-wasm` step 1. On beam the module does not assemble, because
// `String_slice/3` comes out with unresolved labels.
test "wat: index ---- a nested index, a slice's length and a tuple element" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val rows = [[1, 2], [3, 4]];
        \\    print(rows);
        \\    print(rows[1]);
        \\    val r1: i32[] = rows[1] ?? [];
        \\    print(r1[0]);
        \\    print(rows[0]?.length);
        \\    val xs = [10, 20, 30];
        \\    print(xs[0..2].length);
        \\    val sl = xs[0..2];
        \\    print(sl.length);
        \\    val ps = [#(1, "a"), #(2, "b")];
        \\    print(ps[1]);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// A string slice's length, which belonged in the fixture above and is its own
// because of a beam defect that would otherwise hide all seven of that one's
// claims: with a CHAINED primitive method anywhere in the same module
// (`rows.at(1).at(0)`), `beam_asm` emits `String_slice/3` **twice**, with the
// same two labels, and `erlc +from_asm` refuses the module — so
// `scripts/beam_export_audit.sh` refuses the snapshot. Measured by hand, with
// no index expression in the program at all:
//
//     val rows = [[1, 2], [3, 4]];
//     @print(rows.at(1).at(0));
//     val s = "hello";
//     @print(s.slice(1, 3));     // → two `{function, 'String_slice', 3, …}` forms
//
// Drop either half and one copy is emitted and the module assembles. It is a
// duplicate-emission bug in the `default fn` helper, `codegen/beam_asm.zig`'s
// file — `fix/identity-half3`'s right now — and it is reported rather than
// reached into.
test "wat: index ---- a string slice's length" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val s = "hello";
        \\    print(s[1..3].length);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// ── decision 8 §10 and §6 T6, the two twins of `04-js` steps 3 and 4 ─────────

// Decision 105 — a `while` / `loop` is a statement: the answer a search finds
// lives in a `var` the body reassigns before a bare `break`, and a loop that
// ends without finding one leaves it as it was. A RUN LOG, not a snapshot: the
// other backends' baselines of this program are their own fixtures'.
test "wat: loop ---- a search leaves its answer in a var and ends at break" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    var k = 0;
        \\    var r = 0;
        \\    loop { k = k + 1; if (k > 2) { r = k; break; }; };
        \\    print(r);
        \\    var i = 0;
        \\    var found = 0;
        \\    while (i < 10) { if (i == 4) { found = i * 2; break; }; i = i + 1; };
        \\    print(found);
        \\    var m = 0;
        \\    while (m < 3) { m = m + 1; };
        \\    print(m);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "3\n8\n3\n");
}

// §6 T6 — a tuple is positional at run time and `==` compares its elements;
// T5 — labels take no part. Both sides are pointers into the bump heap, so the
// `i32.eq` this backend emitted answered `false` for two equal tuples. Since
// decision 210 each tuple type compares through its generated
// `$__eq_Tuple<n>_…`: a string element through `$__str_eq` (comparing the
// words would compare addresses), a float as the `f32` its slot holds, a nested
// tuple through its own equality.
test "wat: tuple ---- equality compares elements, and labels take no part" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val a = #(1, "a");
        \\    val b = #(1, "a");
        \\    print(a == b);
        \\    print(a != b);
        \\    val c = #(1, "b");
        \\    print(a == c);
        \\    val name = "SP";
        \\    val pop = 12;
        \\    val labeled = #(name, pop);
        \\    val plain = #("SP", 12);
        \\    print(labeled == plain);
        \\    val n1 = #(#(1, 2), "x");
        \\    val n2 = #(#(1, 2), "x");
        \\    val n3 = #(#(1, 3), "x");
        \\    print(n1 == n2);
        \\    print(n1 == n3);
        \\    val f1 = #(1.5, true);
        \\    val f2 = #(1.5, true);
        \\    val f3 = #(1.5, false);
        \\    print(f1 == f2);
        \\    print(f1 == f3);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// §6 T4 / §7 — a tuple element is printed by its own shape, not by its address.
// `@print(t.1)` answered `256` where it means `x`, and `@print(row.name)` — a
// label the checker resolves to `row._0` — answered `256` where it means `SP`:
// the tuple's shape was known to `printShapeOf` and to nothing else, so a
// **single** element fell through to the numeric printer with exit 0 and no
// diagnostic. `tupleElemShapeOf` slices element N out of the receiver's shape
// and both readers ask it, which also makes an element that is itself a
// container print as one (`t.0` → `#(1, 2)`, `u.0` → `["a", "b"]`).
//
// A RUN LOG and not a snapshot, the shape a single backend's row uses: the last
// two prints are where commonJS and wasm still disagree, and an all-backend
// fixture would pin commonJS's answer in a directory this front does not own.
// commonJS prints `[1, 2]` for `t.0` — it drops the tuple marker when the shape
// hint is absent, which is `04-js`'s to answer, not this front's. Every other
// line here was run on both and matches.
test "wat: tuple ---- an element prints by its shape, positional and labelled" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn load() -> #(name: string, pop: i32) {
        \\    val name = "SP";
        \\    val pop = 12;
        \\    return #(name, pop);
        \\}
        \\fn main() -> void {
        \\    val t = #(#(1, 2), "x");
        \\    print(t.1);
        \\    print(t.0.1);
        \\    val row = load();
        \\    print(row.name);
        \\    print(row.pop + 1);
        \\    val a = "RJ";
        \\    val b = 7;
        \\    val local = #(a, b);
        \\    print(local.a);
        \\    val s = t.1;
        \\    print(s + "!");
        \\    print(t.1 == "x");
        \\    val u = #(["a", "b"], 3);
        \\    print(t.0);
        \\    print(u.0);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "x\n2\nSP\n13\nRJ\nx!\ntrue\n#(1, 2)\n[\"a\", \"b\"]\n");
}

// ── step 6: the string case primitives ──────────────────────────────────────

// `"aB".toUpper()` reaches std-wasm's `text.toUpper` on wasm (decision 443:
// over all of Unicode). The host spellings
// (`toUpperCase`, JavaScript's own, which `primitives.bp` gives `toUpper`
// through `#[@External.Node("toUpperCase")]`) used to be lowered here too; the
// checker refuses them now (pending 0203-a, answered (b):
// `conformance/modules/primitive/refused/src/cases/primitive_method_undeclared`).
test "wat: string ---- toUpper and toLower answer" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    print("aB".toUpper());
        \\    print("aB".toLower());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// ── step 1: a record and a variant reaching `@print` ──────────────────────────
//
// §7's F2 (`Point(x: 1, y: 2)`) and F3 (`Shape.Square(side: 4)`) need a value
// that knows which named type it is at run time. Before it did, the wasm
// numeric printer answered the value's **heap address** with exit 0 and no
// diagnostic: `modules/print/run/src/cases/print_formatter` printed `328`, `336`, `344` where §7
// wants three names, and `@print([Point(x: 1, y: 2)])` wrote `[256]`; the
// interim was a trap.
//
// All four backends print §7's text now — `Point(x: 1, y: 2)`,
// `Shape.Square(side: 4)`, `Shape.Nothing`, `[Point(x: 1, y: 2)]` — after the
// three prints of values that never needed an identity.
test "wat: print ---- a record and a variant print their names and fields" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32)
        \\type Shape { Square(side: i32), Nothing }
        \\fn main() -> void {
        \\    print("hi");
        \\    print([1, 2]);
        \\    print(#(1, "a"));
        \\    print(Point(x: 1, y: 2));
        \\    print(Shape.Square(side: 4));
        \\    print(Shape.Nothing);
        \\    print([Point(x: 1, y: 2)]);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// ── step 3: the two halves of `Dict.at` answering the fallback ───────────
//
// `modules/std/run/src/cases/std_import` printed `0` where `1` is stored, exit 0, no diagnostic.
// The suspect named in the step was the closure — a `forEach` writing an outer
// local — and it is innocent: the first two prints below worked before the fix.
// The two that did not, each a `?T` whose writer and reader disagreed about the
// box:
//
//   `var h: ?i32 = null; h = 5;`   the assignment stored the bare `5`; the
//                                  binding that declares the slot boxes, the
//                                  assignment did not. `@print(h)` then read
//                                  offset 5 as a box: `16777216`.
//   `d.at("a").unwrapOr(0)`    `-> ?V` is unboxed (a type parameter is not a
//                                  known scalar) and the reader assumed a box.
//                                  A method's declared return type was not
//                                  registered under the symbol its call emits,
//                                  so the reader had nothing to ask.
//
// Registering it fixes three more readers at once — `hasKey` answered `0`/`1`
// for a `bool` and `values()` answered a **pointer** for an array — and the two
// that remain are the generic-parameter limit, written into `wat/AGENTS.md`:
// `keys()` is `Array<K>` with `K = string`, and `?V` with `V = string`, and
// nothing here monomorphises, so both print an address.
//
// The four backends' logs are byte-identical: §7's separator (`[6, 8]`) and
// decision 47's spelling of absence (`null`) on every one.
//
// The `Dict` cells this row was found through live in `std_package.zig`, where
// erlang's and beam's own cross-module rows are pinned.
test "wat: option ---- a value assigned into a declared `?T` is boxed like one" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Box(items: array<i32>) {
        \\    fn total(self: Self) -> i32 {
        \\        var sum = 0;
        \\        self.items.forEach({ n -> sum = sum + n });
        \\        return sum;
        \\    }
        \\    fn isBig(self: Self) -> bool { return self.items.length > 1; }
        \\    fn doubled(self: Self) -> array<i32> { return self.items.map({ n -> n * 2 }); }
        \\    fn label(self: Self) -> string { return "box"; }
        \\}
        \\fn main() -> void {
        \\    var seen = 0;
        \\    [1, 2].forEach({ n -> seen = n });
        \\    print(seen);
        \\    val b = Box(items: [3, 4]);
        \\    print(b.total());
        \\    var h: ?i32 = null;
        \\    print(h);
        \\    h = 5;
        \\    print(h);
        \\    var acc: ?i32 = null;
        \\    [7, 8].forEach({ n -> acc = n });
        \\    print(acc);
        \\    print(b.isBig());
        \\    print(b.doubled());
        \\    print(b.label());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// A top-level `-> void` function used as a value and called through a record
// field typed `fn(…)`: the call site unboxes the unit word a void function value
// answers, so the trampoline boxes one. Once `-> void` answered nothing (decision
// 622, `ast.answersNothing`) the trampoline pushed `ref.null` and the unbox
// trapped `null reference` (decision 354's `context_sheet_registers`).
test "wat: function value ---- a -> void function in a fn field is called through its trampoline" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type Writer(add: fn(s: string))
        \\
        \\fn shout(s: string) -> void {
        \\    print(s + "!");
        \\}
        \\
        \\fn main() -> void {
        \\    val w = Writer(add: shout);
        \\    w.add("a");
        \\    w.add("b");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "a!\nb!\n");
}

// ── step 7: function values ─────────────────────────────────────────────────
//
// The step asked whether to build them or defer, on the reading that "wasm has no
// function values". Measured first, and the reading was wrong: `wat.zig` lifts a
// lambda into `$__lambda{n}(env, …)`, lists it in the module's function table and
// applies it with `call_indirect`, and four of the five ways a function reaches a
// value already worked — a lambda in a local, a lambda passed as a `fn(…)`
// parameter, a top-level fn used as a value, and one bound to a local.
//
// The fifth did not: a function value read out of an **aggregate slot**.
// `lowerValueCall` recognised a record field and nothing else, and a labelled
// tuple element is resolved by the checker to its *position* — `c.set` arrives as
// `_1`, which is not a field name — so the call fell through to the unresolved
// path: `unreachable ;; unresolved call: _1/1`. One helper (`slotOffset`, a record
// field offset or `tupleIndex * 4`) closes it, so there is nothing to defer.
//
// All four prints match commonJS exactly. The three fixtures the step listed as
// this shape's traps were re-read with it: only
// `tuple_a_labeled_element_of_function_type_is_called_like_a_method` was one, and
// it now answers `18` on all four backends. `call_trailing_lambda_block` and
// `call_trailing_lambda_with_multiple_params` trap on the **`@todo()` in the
// function they call** — the program's own trap, not a missing mechanism — and
// neither ever carried a `KNOWN` note saying otherwise.
test "wat: function value ---- a lambda in a tuple slot or a record field is applied" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Ops(step: fn(n: i32) -> i32)
        \\fn mk() -> #(value: i32, set: fn(n: i32) -> i32) {
        \\    val value = 1;
        \\    val set: fn(i32) -> i32 = { n -> return n * 2; };
        \\    return #(value, set);
        \\}
        \\fn main() -> void {
        \\    val c = mk();
        \\    print(c.value);
        \\    print(c.set(9));
        \\    val t = #(1, { n -> return n + 100; });
        \\    print(t._1(2));
        \\    val o = Ops(step: { n -> return n - 1; });
        \\    print(o.step(10));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// `String.at` — the reader decision 63's amendment gave every indexable type,
// and what `s[i]` rewrites to. It had no wasm lowering at all: the call fell
// through `primCallRes` and emitted
// `unreachable ;; prim method not lowered on wasm: string.at/1`, so
// `conformance/modules/decisions-taken/negative_index_counts_from_end-139/run/src/cases/index_at_optional` died at exit 134 on this backend
// while commonJS, erlang and beam all answered. std-wasm's `text.at` is
// `$__str_slice(s, i, i + 1)` behind one `i32.ge_u` bounds test, after a
// negative index has been counted from the end (`i + len`, decision 139) — one
// still negative wraps past any length and is rejected by the same compare.
//
// The absent probes are the half that makes the lowering safe rather than merely
// present: `at` answers a `?string` whose absence is the pointer `0`, and
// `optInfoOf` routes it through `$__print_opt_str`. Printed as a plain string it
// would read a length out of the WASI iovec at address 0 and answer garbage with
// exit 0 — the silent-wrong-answer class this backend refuses to add to.
//
// A RUN LOG and not a snapshot: `String.at` already answers on the other three
// backends, so an all-backend fixture would move
// `snapshots/codegen/{commonJS,erlang,beam}/`, which this front does not own.
// `conformance/modules/decisions-taken/negative_index_counts_from_end-139/run/src/cases/string_at` is the cross-backend half.
test "wat: prim method ---- string.at answers a one-character string, and null out of range" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    val s = "abc";
        \\    print(s.at(0));
        \\    print(s.at(2));
        \\    print(s.at(3));
        \\    print(s.at(0 - 1));
        \\    print(s.at(0 - 4));
        \\    print("hello world".at(6));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "a\nc\nnull\nc\nnull\nw\n");
}

// A self-call in `return` position is a branch to the function's own loop head
// (`00 · 05-wasm` step 9). wasm has no tail calls unless the proposal is
// enabled, and wasmtime's default does not enable it: `count(10000, 0)` answered
// and `count(100000, 0)` trapped `call stack exhausted` at exit 134, where the
// other three backends answer. `return f(args)` inside `fn f` now evaluates
// every argument, re-binds the parameters in reverse and `br $__tail`s; the
// body is wrapped in `(loop $__tail (result …))` only when such a call exists,
// so no other function's text moves. `sumTo` pins that the accumulator reads the
// OLD `n` — the arguments are on the stack before any parameter is re-bound.
//
// A RUN LOG and not a snapshot: the depth is the point, and the other three
// backends already answer it. `conformance/modules/tail/run/src/cases/tail_self_call` is the
// cross-backend half.
test "wat: tail call ---- a self-call in return position runs in one frame" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn count(n: i32, acc: i32) -> i32 {
        \\    if (n == 0) { return acc; } else { return count(n - 1, acc + 1); }
        \\}
        \\fn sumTo(n: i32, acc: i32) -> i32 {
        \\    if (n == 0) { return acc; };
        \\    return sumTo(n - 1, acc + n);
        \\}
        \\fn main() -> void {
        \\    print(count(1000000, 0));
        \\    print(sumTo(1000, 0));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "1000000\n500500\n");
}

// `00 · 05-wasm` step 6's audit of `primitives.bp` against `primCallRes`: the
// `String` and `Float` members with a byte-level answer are lowered, each
// answering what commonJS answers for the same program (measured side by
// side) — but a float's text, which is std-wasm's (decision 441):
// `5.0.toString()` is `5.0`, as on erlang (node answers `5`); `charCodeAt` out of range is
// `-1`, the answer both host templates give; the pad cycles as JavaScript's
// does; an empty pattern matches before every byte.
test "wat: prim method ---- the String and Float members step 6's audit lowered" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    val f = 2.5;
        \\    print(f.toString());
        \\    val g = 5.0;
        \\    print(g.toString());
        \\    print("abc".charCodeAt(1));
        \\    print("abc".charCodeAt(7));
        \\    print("a-b-c".lastIndexOf("-"));
        \\    print("a-b-c".lastIndexOf("z"));
        \\    print("ab".padStart(5, "*-"));
        \\    print("ab".padEnd(5, "*-"));
        \\    print("abcdef".padStart(3, "*"));
        \\    print("a-b-c".replace("-", "+"));
        \\    print("a-b-c".replaceAll("-", "+="));
        \\    print("ab".replaceAll("", "-"));
        \\    print("xy".chars());
        \\    print([1, 2, 3].find({ x -> x > 1 }));
        \\    print([1, 2, 3].find({ x -> x > 5 }));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\2.5
        \\5.0
        \\98
        \\-1
        \\3
        \\-1
        \\*-*ab
        \\ab*-*
        \\abcdef
        \\a+b-c
        \\a+=b+=c
        \\-a-b-
        \\["x", "y"]
        \\2
        \\null
        \\
    );
}

// `01-compiler/05-wasm` step 1: the primitive methods step 6's audit left
// trapping each have a lowering — std-wasm's `text.lines` / `text.words`, and the
// array helpers std-wasm's `array.unique`, `array.flatten` (`flatMap` is `map` then
// it, as `primitives.bp`'s body is), `array.chunked`, `array.sliding`,
// `array.fill`. The answers are commonJS's, erlang's and beam's for the same
// program (`conformance/modules/string/run/src/cases/string_lines_words`, `array_unique.bp`,
// `array_flat_forms.bp`, `array_windows.bp`, `array_fill.bp`).
test "wat: prim method ---- the methods that trapped lower: lines, words, unique, the flat forms, the windows, fill" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    print("a b\tc\n d".words());
        \\    print("a\nb\r\nc\r".lines());
        \\    print([3, 1, 1, 3].unique());
        \\    print(["a", "a", "b"].unique());
        \\    print([true, true, false].unique());
        \\    print([[1], [2, 3]].flatten());
        \\    print([["a"], ["b"]].flat());
        \\    print([1, 2].flatMap({ x -> [x, x] }));
        \\    print([1, 2, 3].chunked(2));
        \\    print([1, 2, 3].sliding(2));
        \\    print([1, 2].fill(0));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\["a", "b", "c", "d"]
        \\["a", "b", "c\r"]
        \\[3, 1]
        \\["a", "b"]
        \\[true, false]
        \\[1, 2, 3]
        \\["a", "b"]
        \\[1, 1, 2, 2]
        \\[[1, 2], [3]]
        \\[[1, 2], [2, 3]]
        \\[0, 0]
        \\
    );
}

// What is left of the class is refused by name rather than answered:
// `unique` over records (std-wasm's `array.unique` compares words and strings; decision
// 210's structural answer has no wasm lowering yet), `flatMap` whose function
// answers a scalar (node keeps it, erlang fails), and `flatten` over elements
// no shape says are arrays. Each was a run-time trap; each is a located build
// refusal at the call now (`00 · 110-gate-wasm`).
test "wat: prim method ---- unique over records, flatMap over a scalar and flatten over scalars are refused at the call" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\type P(x: i32)
        \\fn main() -> void {
        \\    print([P(x: 1), P(x: 1)].unique().length);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "`unique` on the wasm backend compares", 3, 30);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\fn main() -> void {
        \\    print([1, 2].flatMap({ x -> x + 1 }));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "`flatMap` on the wasm backend: nothing shows that its function answers an array", 2, 18);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\fn main() -> void {
        \\    print([1, 2].flatten());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "`flatten` on the wasm backend: nothing shows", 2, 18);
}

// A prelude `default fn` (`primitives.bp`'s `parseInt`, `parseFloat`) is
// copied into the program, and the free host helpers its body calls
// (`stringSlice0`, `stringToFloat`, …) are adopted with their
// `#[@External.Wasm(std: "…")]` cells (`adoptPreludeHostFn`). Unbound, the
// copy was refused — located at the program's call that reaches it
// (`ast.BehaviorMethod.from_prelude`, `foreign_origin`); bound, it answers,
// an `f64` / `i64` `Ok` held in its cell.
test "wat: prim method ---- a prelude default's host helpers are std-wasm's, its @Result read whole" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    print("12".parseInt().unwrapOr(0l));
        \\    print("-2.5e-1".parseFloat().unwrapOr(0.0));
        \\    print("1.".parseFloat().isError());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\12
        \\-0.25
        \\true
        \\
    );
}

// `Array.pop` and `Array.lastIndexOf` left the trap list: `pop` answers the
// `?T` `at(-1)` does and rebinds the local to a copy one shorter, as `push`
// rebinds it to a grown one; `lastIndexOf` walks `indexOf`'s equality from
// the last slot down.
test "wat: prim method ---- pop shrinks a local array and lastIndexOf searches from the end" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    var xs = [1, 2, 3];
        \\    val p = xs.pop();
        \\    print(p);
        \\    print(xs);
        \\    print([1, 2, 1].lastIndexOf(1));
        \\    print(["a", "b"].lastIndexOf("z"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\3
        \\[1, 2]
        \\2
        \\-1
        \\
    );
}

// Decision 8 §11's box on wasm (`00 · 05-wasm` step 2): a value entering an
// `unknown` slot carries a header naming what it holds, and `is`, a type arm,
// `==` and `@print` read it — `conformance/modules/unknown/run/src/cases/unknown_by_value` pins the
// answers on four targets. A payload declared as a type parameter (`value: T`)
// is not typed by this backend, which does not monomorphise: a constructor
// written where its value is an `unknown` boxes that payload by its static
// type, and a `case` over an `unknown` binds it as the `unknown` it is
// (decision 8 §5.1 P5), so `v is string` answers `true` for `"abc"` and
// `false` for the `1` of a `Maybe` it reads in the second arm.
test "wat: unknown ---- a type parameter's slot matched out of an unknown is an unknown" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type Maybe<T> {
        \\    Some(value: T),
        \\    None,
        \\}
        \\fn innerLength(b: unknown) -> i32 {
        \\    return case b {
        \\        Maybe.Some(value: v) when (v is string) { 1 }
        \\        Maybe.Some(value: v) { -1 }
        \\        _ { -2 }
        \\    };
        \\}
        \\fn main() -> void {
        \\    val x: unknown = 1;
        \\    print(innerLength(x));
        \\    val s: unknown = Maybe.Some(value: "abc");
        \\    print(innerLength(s));
        \\    val n: unknown = Maybe.Some(value: 5);
        \\    print(innerLength(n));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\-2
        \\1
        \\-1
        \\
    );
}

// The guard's `is` narrows `v` in the arm body as an `if (v is string)` does
// in its block: `v.length` reads the string the box holds.
test "wat: unknown ---- a field read on a guard-narrowed type parameter's slot" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Maybe<T> {
        \\    Some(value: T),
        \\    None,
        \\}
        \\fn innerLength(b: unknown) -> i32 {
        \\    return case b {
        \\        Maybe.Some(value: v) when (v is string) { v.length }
        \\        Maybe.Some(value: v) { -1 }
        \\        _ { -2 }
        \\    };
        \\}
        \\fn main() -> void {
        \\    val s: unknown = Maybe.Some(value: "abc");
        \\    print(innerLength(s));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// A slice's `end: ?i32` written out as `null` — or an optional that is absent
// at run time — means "to the end". Lowered as the `0` a `null` is, the end
// fell before the start and `$__str_slice` read out of bounds (a trap), where
// commonJS and erlang answer `cdef`; an optional `end` was read as its box's
// ADDRESS. (status.md's `slice(2, null)` row.)
test "wat: slice ---- a null end, written or at run time, is the end" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn cut(s: string, end: ?i32) -> string {
        \\    return s.slice(1, end);
        \\}
        \\fn main() -> void {
        \\    print("abcdef".slice(2, null));
        \\    print([1, 2, 3, 4].slice(1, null));
        \\    print(cut("abcdef", 3));
        \\    print(cut("abcdef", null));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\cdef
        \\[2, 3, 4]
        \\bc
        \\bcdef
        \\
    );
}

// `01-compiler/05-wasm` step 3 — C-07's wasm twins, one fixture per pattern
// shape of decision 8 §5, each RUN LOG the value erlang and beam answer for
// the same program (and commonJS, where it answers; the rows it does not are
// named at the fixture). Before this step a tuple pattern in a `case` was
// refused (`` `` names no variant``), every list pattern matched every array
// (`[x]` took a `[]` arm), and `true` / `false` inside a tuple pattern were
// binders, so every arm matched — the last two a wrong value at exit 0.

// §5.1 P6: a tuple pattern is positional; a literal inside it is tested, a
// name binds the element by its own shape (a string prints as text), and a
// labelled tuple type is still matched by position.
test "wat: case ---- a tuple pattern tests its literals and binds its elements" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn classify(p: #(i32, string)) -> string {
        \\    return case p {
        \\        #(0, s) { "zero " + s }
        \\        #(n, "x") { "x " + n.toString() }
        \\        #(_, s) { s }
        \\    };
        \\}
        \\fn capital(r: #(name: string, pop: i32)) -> string {
        \\    return case r {
        \\        #("SP", p) { "capital " + p.toString() }
        \\        #(n, _) { n }
        \\    };
        \\}
        \\fn nested(t: #(#(i32, i32), string)) -> string {
        \\    return case t {
        \\        #(#(0, b), s) { s + b.toString() }
        \\        #(#(a, _), s) { s + "!" + a.toString() }
        \\    };
        \\}
        \\fn main() -> void {
        \\    print(classify(#(0, "a")));
        \\    print(classify(#(7, "x")));
        \\    print(classify(#(7, "y")));
        \\    print(capital(#("SP", 12)));
        \\    print(capital(#("Rio", 6)));
        \\    print(nested(#(#(0, 7), "z")));
        \\    print(nested(#(#(5, 7), "z")));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\zero a
        \\x 7
        \\y
        \\capital 12
        \\Rio
        \\z7
        \\z!5
        \\
    );
}

// §5.1 P7: `..` ignores the rest — of a tuple, a variant's fields and a
// record's — and `true` / `false` in a pattern are the bool literals. commonJS
// emits `const true = _s[2]` for the last (a SyntaxError, `04-js`'s row), and
// erlang binds it (`names(#("a", "b", false))` answers `ba`, `02-erlang`'s).
test "wat: case ---- `..` skips the rest and a bool literal in a tuple pattern is tested" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(w: i32, h: i32),
        \\    Dot,
        \\}
        \\type Point(x: i32, y: i32)
        \\fn first(t: #(i32, i32, i32)) -> i32 {
        \\    return case t {
        \\        #(a, ..) { a }
        \\    };
        \\}
        \\fn width(s: Shape) -> i32 {
        \\    return case s {
        \\        Shape.Rect(w: w, ..) { w }
        \\        Shape.Circle(..) { -1 }
        \\        _ { 0 }
        \\    };
        \\}
        \\fn px(p: Point) -> i32 {
        \\    return case p {
        \\        Point(x: 0, ..) { 0 }
        \\        Point(x: x, ..) { x }
        \\    };
        \\}
        \\fn names(t: #(string, string, bool)) -> string {
        \\    return case t {
        \\        #(a, b, true) { b + a }
        \\        #(a, ..) { a }
        \\    };
        \\}
        \\fn main() -> void {
        \\    print(first(#(4, 5, 6)));
        \\    print(width(Shape.Rect(w: 4, h: 5)));
        \\    print(width(Shape.Circle(radius: 1)));
        \\    print(width(Shape.Dot));
        \\    print(px(Point(x: 0, y: 1)));
        \\    print(px(Point(x: 3, y: 1)));
        \\    print(names(#("a", "b", true)));
        \\    print(names(#("a", "b", false)));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\4
        \\4
        \\-1
        \\0
        \\0
        \\3
        \\ba
        \\a
        \\
    );
}

// §5.2: an arm naming a type is chosen by the value — a primitive over an
// `unknown` subject by its box (binding the unboxed payload), a record and an
// enum by the value's header. commonJS answers `other` for `Shape { … }` over
// a variant, where erlang and beam answer `shape` (`04-js`'s row).
test "wat: case ---- a type pattern is chosen by the value" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type Shape {
        \\    Rect(w: i32, h: i32),
        \\    Dot,
        \\}
        \\type Point(x: i32, y: i32)
        \\fn kind(v: unknown) -> string {
        \\    return case v {
        \\        i32 { n -> "int " + n.toString() }
        \\        string { s -> "string " + s }
        \\        bool { "bool" }
        \\        Point { "point" }
        \\        Shape { "shape" }
        \\        _ { "other" }
        \\    };
        \\}
        \\fn main() -> void {
        \\    print(kind(1));
        \\    print(kind("a"));
        \\    print(kind(true));
        \\    print(kind(Point(x: 1, y: 2)));
        \\    print(kind(Shape.Rect(w: 1, h: 1)));
        \\    print(kind(2.5));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\int 1
        \\string a
        \\bool
        \\point
        \\shape
        \\other
        \\
    );
}

// §5.1 list patterns: the length — exactly the elements written, or at least
// them with a spread — then each literal; a binder by the element's shape and
// a named spread bound to the rest. erlang answers the same; commonJS tests no
// literal (`pick([2, 9])` answers `9`) and a brace arm answers a function
// (`04-js`'s rows); beam leaves the binders unresolved (`03-beam`'s).
test "wat: case ---- a list pattern tests its length and literals and binds the rest" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn head(xs: string[]) -> string {
        \\    return case xs {
        \\        [] -> "none";
        \\        [a, ..rest] -> a + "+" + rest.length.toString();
        \\    };
        \\}
        \\fn pick(xs: i32[]) -> i32 {
        \\    return case xs {
        \\        [1, b] -> b;
        \\        [_, _, c, ..] -> c;
        \\        [..] -> -1;
        \\    };
        \\}
        \\fn main() -> void {
        \\    print(head([]));
        \\    print(head(["x"]));
        \\    print(head(["x", "y", "z"]));
        \\    print(pick([1, 9]));
        \\    print(pick([2, 9]));
        \\    print(pick([5, 6, 7, 8]));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\none
        \\x+0
        \\x+2
        \\9
        \\-1
        \\7
        \\
    );
}

// Decision 152 refuses a second binding of one name in one body, and decision
// 205 makes the body the whole function: an inner block's `val`, a loop's
// binder and a `case` arm's binder over a name visible there are refused by the
// checker (`modules/decisions-taken/shadowing_in_inner_blocks_refused-205/refused/src/cases/binding_shadows_in_inner_block`,
// `modules/decisions-taken/shadowing_in_inner_blocks_refused-205/refused/src/cases/case_arm_binder_reuses_name`). What stays legal is a lambda — a
// function of its own — binding a name its enclosing function holds, as a
// parameter or a `val` of its body, and two sibling blocks each binding one
// name. One wasm function is one local namespace and a HOF's lambda is inlined
// into it, so the lambda's `val k = "lambda"` wrote the outer `$k` and every
// read after it answered the inner value (`lambda` where node answers `5`; the
// pre-pass also marked the outer `k` a string). A re-binding is a local of its
// own (`bindTarget`, `<name>__sh<n>`), aliased until its statement list ends
// (`scopeRestore`). The RUN LOG is commonJS's.
test "wat: scope ---- a lambda's binding shadows the outer one only inside it" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    val k = 5;
        \\    [1].forEach({ e ->
        \\        val k = "lambda";
        \\        print(k);
        \\    });
        \\    print(k);
        \\    val e = 5;
        \\    [1, 2].forEach({ e -> print(e) });
        \\    print(e);
        \\    if (true) { val t = 1; print(t); }
        \\    if (true) { val t = "two"; print(t); }
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\lambda
        \\5
        \\1
        \\2
        \\5
        \\1
        \\two
        \\
    );
}

// Decision 214 — the NaN half of `f64`'s total-order `==`, which the
// four-target cell `modules/decisions-taken/f64_equality_total_order-214/run/src/cases/f64_equality_total_order` cannot carry (erlang and
// beam never produce a NaN): `NaN == NaN` is `true` bare and inside a record,
// a tuple, an array and a variant, `NaN != NaN` is `false`, and NaN against a
// number is unequal. `<` stays IEEE (`NaN < 1.0` is `false`).
test "wat: f64 ---- NaN equals NaN under ==, bare and inside composites" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type F(x: f64)
        \\type V {
        \\    W(x: f64),
        \\    Z,
        \\}
        \\fn zero() -> f64 {
        \\    return 0.0;
        \\}
        \\fn main() -> void {
        \\    val z = zero();
        \\    val nan = z / z;
        \\    print(nan == nan);
        \\    print(nan != nan);
        \\    print(nan == 1.0);
        \\    print(nan < 1.0);
        \\    print(F(x: nan) == F(x: z / z));
        \\    val ta = #(nan, 1);
        \\    val tb = #(z / z, 1);
        \\    print(ta == tb);
        \\    val xs = [nan];
        \\    val ys = [z / z];
        \\    print(xs == ys);
        \\    print(V.W(x: nan) == V.W(x: z / z));
        \\    print(F(x: nan) == F(x: 1.0));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "true\nfalse\nfalse\nfalse\ntrue\ntrue\ntrue\ntrue\nfalse\n");
}

// A behavior `default fn` adopted by two types, one of which calls a primitive
// method on another default's result (`self.twice().toString()`): inference
// typed the body against `Self`, so the receiver had no recorded lowering and
// `Sq_label` trapped (`unresolved call: toString/0`). The callee's declared
// return answers it. The RUN LOG is commonJS's and erlang's for the program.
test "wat: behavior ---- a primitive method on a default's result inside an adopted default" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\behavior Shape {
        \\    fn area(self: Self) -> i32;
        \\    default fn twice(self: Self) -> i32 {
        \\        return self.area() * 2;
        \\    }
        \\    default fn label(self: Self) -> string {
        \\        return "area " + self.twice().toString();
        \\    }
        \\}
        \\type Sq(s: i32) implement Shape {
        \\    fn area(self: Self) -> i32 {
        \\        return self.s * self.s;
        \\    }
        \\}
        \\fn main() -> void {
        \\    print(Sq(s: 3).label());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "area 18\n");
}

// A program's own `default fn` on a primitive, a contract implemented for it
// (decision 799): a copy with `Self` written as the receiver's primitive,
// called with the receiver as `self` (`lowerPrimDefault`). It trapped (`prim
// method not lowered on wasm`). The RUN LOG is commonJS's and erlang's for the
// program.
test "wat: behavior ---- a program's default fn on a primitive behavior is called" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\behavior Shout {
        \\    default fn shout(self: Self) -> string {
        \\        return self + "!";
        \\    }
        \\}
        \\StringShout implement Shout for string {};
        \\behavior Number {
        \\    default fn twice(self: Self) -> Self {
        \\        return self + self;
        \\    }
        \\}
        \\fn main() -> void {
        \\    print("hi".shout());
        \\    val n: i32 = 21;
        \\    print(n.twice());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "hi!\n42\n");
}

// A program's own `default fn` on `array<T>`, a contract implemented for it
// (decision 799): the copy writes `Self<T>` as the receiver's array type and
// `T` as its element (`ensurePrimDefault`). It trapped (`prim method not
// lowered on wasm`). The RUN LOG is commonJS's and erlang's for the program.
test "wat: behavior ---- a program's default fn on array<T> is called with its element type" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\behavior Tagged<T> {
        \\    default fn tag(self: Self<T>) -> string {
        \\        return "arr";
        \\    }
        \\    default fn pairUp(self: Self<T>, x: T) -> T[] {
        \\        return [x, x];
        \\    }
        \\}
        \\ArrTagged<T> implement Tagged<T> for array<T> {};
        \\fn main() -> void {
        \\    print([1, 2].tag());
        \\    print([1].pairUp(7));
        \\    print(["a"].pairUp("b"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "arr\n[7, 7]\n[\"b\", \"b\"]\n");
}

// A lambda stored in a generic record's field (`Box<T>(value: T)`) whose
// parameter nothing types: the record goes through a generic fn and the
// field is called on the result, so no call through the constructor's own
// local and no written type reach the lambda. Its parameter's word may be a
// string or an integer; the lambda is REFUSED where it is written
// (`lambda parameter `s`: nothing gives it a type the wasm backend can see`)
// instead of guessing — it printed `300?` for `"d" + "?"` at exit 0, then
// trapped at the lambda's entry until `00 · 110-gate-wasm`. commonJS answers
// `x%`.
test "wat: function value ---- a lambda in a generic field that nothing types is refused, never guessed" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\type Box<T>(value: T)
        \\fn keep<T>(b: Box<T>) -> Box<T> {
        \\    return b;
        \\}
        \\fn main() -> void {
        \\    val esc = keep(Box(value: { s -> s + "%" }));
        \\    val ef = esc.value;
        \\    print(ef("x"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "lambda parameter `s`: nothing gives it a type the wasm backend can see", 6, 31);
}

// ── `00 · 110-gate-wasm`: every lowering that cannot proceed is a located refusal ──
//
// Each program below compiled on wasm and died at run time on an
// `unreachable` the lowering wrote "so the module still loads" — a program the
// other backends run, refused only once it executed. The rule of
// `codegen/wat/AGENTS.md` § Where this backend refuses to answer is that a
// lowering that cannot proceed stops the build where the source is written;
// what keeps an `unreachable` is the program's own semantics (`assert`,
// `@panic`, `@todo`, an uncaught `throw`, a rejected `#[@future]`) and the
// structural end of a dispatch nothing else reaches.

// `is` over an all-unit enum: its values are bare ordinals with no header, so
// there is no run-time test. commonJS answers `false`.
test "wat: refusal ---- is over a type with no descriptor is refused at the test" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\type Color { Red, Green }
        \\pub fn main() -> void {
        \\    val c: unknown = 1;
        \\    print(c is Color);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "`is Color`: the wasm backend has no run-time test for this type", 4, 13);
}

// A decorator / template builtin written in a program body: nothing on wasm
// runs it. (commonJS emits `__emit("x")` and dies at run time — `04-js`'s row.)
test "wat: refusal ---- a comptime-only builtin in a program body is refused" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\pub fn main() -> void {
        \\    @emit("x");
        \\}
    , "`@emit` is a comptime-only builtin", 2, 5);
}

// `pop` shrinks its receiver in place on the other backends. A local, a module
// `var` and — now — a record's field are rebound to the shorter copy; a call's
// result may be an array another name holds, which a copy would leave whole,
// so it is refused rather than answered.
test "wat: refusal ---- pop on a call's result is refused, pop on a record field shrinks it" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\fn xs() -> array<i32> {
        \\    return [1, 2];
        \\}
        \\pub fn main() -> void {
        \\    print(xs().pop());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "`pop` on the wasm backend rebinds its receiver", 5, 16);
    try h.assertWasmRunLog(std.testing.allocator,
        \\type Stack(items: array<i32>)
        \\pub fn main() -> void {
        \\    val s = Stack(items: [1, 2, 3]);
        \\    print(s.items.pop());
        \\    print(s.items);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\3
        \\[1, 2]
        \\
    );
}

// Dispatch by value tells implementers apart by the header behind the value;
// an all-unit enum's variant is its ordinal and has none, so `show(Color.Red)`
// reached the dispatcher's end and trapped after printing `p`. commonJS prints
// `p` then `c`.
test "wat: refusal ---- dispatch by value over an all-unit enum implementer is refused at the call" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\behavior Named {
        \\    fn name(self: Self) -> string;
        \\}
        \\type Color implement Named {
        \\    Red,
        \\    Green,
        \\
        \\    fn name(self: Self) -> string {
        \\        return "c";
        \\    }
        \\}
        \\type P(x: i32) implement Named {
        \\    fn name(self: Self) -> string {
        \\        return "p";
        \\    }
        \\}
        \\fn show(n: Named) -> string {
        \\    return n.name();
        \\}
        \\pub fn main() -> void {
        \\    print(show(P(x: 1)));
        \\    print(show(Color.Red));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "`Color` is an all-unit enum", 18, 14);
}

// A behavior method declared with no return, called on a behavior-typed value
// as a function's last statement: the dispatcher answers nothing, and the
// function took a `(result i32)` it never filled — wasmtime refused the module
// (`expected i32 but nothing on stack`) where commonJS, erlang and beam printed.
test "wat: behavior ---- a method with no return dispatched by value as a body's tail" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\behavior Shuttable {
        \\    fn shut(self: Self) -> void;
        \\}
        \\type Door(name: string) implement Shuttable {
        \\    fn shut(self: Self) -> void {
        \\        print("shut " + self.name);
        \\    }
        \\}
        \\fn doShut(c: Shuttable) -> void {
        \\    c.shut();
        \\}
        \\pub fn main() -> void {
        \\    doShut(Door(name: "front"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\shut front
        \\
    );
}

// A generic body is the one a call reaches when no specialisation bound its
// type parameters. `x is string` over a `T` now asks for a copy per bound type
// (`callsMethodOn`), so `shown(1)` / `shown("s")` / `shown(true)` answer from
// copies; the generic body keeps an `unreachable` no execution meets.
test "wat: refusal ---- is over a type parameter specialises the generic fn per bound type" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn shown<T>(x: T) -> string {
        \\    if (x is string) return "q";
        \\    return "n";
        \\}
        \\pub fn main() -> void {
        \\    print(shown(1));
        \\    print(shown("s"));
        \\    print(shown(true));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\n
        \\q
        \\n
        \\
    );
}

// ...and a concrete call that reaches the generic body unspecialised — here
// `$__display_of` printing a `Box<i32>` through the ONE `Box.display`, whose
// `shown(self.value)` binds nothing — is refused where it is written
// (`refuseUnboundTemplateCalls`). It trapped inside `shown`. commonJS prints
// `Box(n)`.
test "wat: refusal ---- a generic body reached with nothing bound is refused at the concrete call" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\fn shown<T>(x: T) -> string {
        \\    if (x is string) return "s";
        \\    return "n";
        \\}
        \\type Box<T>(value: T) implement Display {
        \\    pub fn display(self: Self<T>) -> string {
        \\        return "Box(" + shown(self.value) + ")";
        \\    }
        \\}
        \\pub fn main() -> void {
        \\    print(Box(value: 1));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "cannot call the generic `Box.display` here", 11, 11);
}

// Decision 238 — what a `#[@External.Wasm("…")]` binding names: `op:` one
// numeric instruction over the declared parameters, `fn:` a private bodied fn
// of the same module with the same signature, `wasi:` an adapter of
// `wat/host_binding.zig`'s list (conformance/docs.md § Host bindings). Each lowers to a
// function of the declared name and signature, so a call is an ordinary call.
test "wat: host binding ---- op:, fn: and wasi: bind a declare fn" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\#[compiler.external(.Wasm(op: "f64.floor"))]
        \\declare fn down(x: f64) -> f64;
        \\#[compiler.external(.Wasm(op: "i32.add"))]
        \\declare fn plus(a: i32, b: i32) -> i32;
        \\#[compiler.external(.Wasm(op: "f64.lt"))]
        \\declare fn below(a: f64, b: f64) -> bool;
        \\#[compiler.external(.JavaScript("(\"hi \" + $0)"), .Wasm(body: greetBody))]
        \\declare fn greet(name: string) -> string;
        \\fn greetBody(name: string) -> string {
        \\    return "hi " + name;
        \\}
        \\#[compiler.external(.Wasm(wasi: .RandomF64))]
        \\declare fn draw() -> f64;
        \\fn main() -> void {
        \\    print(down(2.75) == 2.0);
        \\    print(plus(40, 2));
        \\    print(below(1.0, 2.0));
        \\    print(greet("wasm"));
        \\    val r = draw();
        \\    print(r >= 0.0 && r < 1.0);
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    ,
        \\true
        \\42
        \\true
        \\hi wasm
        \\true
        \\
    );
}

// Decision 451 — `std/io/random`'s seeded stream is std-wasm's, bound by the
// `std:` cells on `seed` / `seededFloat`: Mulberry32 as the commonJS sidecar
// draws it — 39393, 29379 after `seed(42)` and 28381 after `seed(-7)` are
// `Math.floor(draw * 65536)` of `sidecars/random.mjs`'s draws. A draw before
// any seed is the host's entropy (`env.bp_random_f64`, linked to
// `$__wasi_random_f64`), and `seed`'s `-> void` answers the 0 its caller drops.
test "wat: std-wasm ---- seed and seededFloat draw the sidecar's Mulberry32 stream" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\import {io.random} from "std";
        \\fn main() -> void {
        \\    val before = random.seededFloat();
        \\    print(before >= 0.0 && before < 1.0);
        \\    random.seed(42);
        \\    print((random.seededFloat() * 65536.0).floor());
        \\    print((random.seededFloat() * 65536.0).floor());
        \\    random.seed(0 - 7);
        \\    print((random.seededFloat() * 65536.0).floor());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\true
        \\39393.0
        \\29379.0
        \\28381.0
        \\
    );
}

// An `if` whose arms answer integers types as an integer in a function that
// answers a float: `(if (result f64)` around two `i32`s was invalid code.
test "wat: an integer if-expression inside a float function" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn digitOf(c: i32) -> f64 {
        \\    val d = if (c < 58) c - 48 else c - 87;
        \\    val big = if (d > 9) d >= 10 else false;
        \\    return if (big) d * 1.0 else 0.0 - d;
        \\}
        \\fn main() -> void {
        \\    print(digitOf(55) == 0.0 - 7.0);
        \\    print(digitOf(102) == 15.0);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\true
        \\true
        \\
    );
}

// Anything outside the vocabulary is refused at the annotation — never read
// as text, never lowered to a guess; a `body:` naming no private fn of the
// declaration's types at the argument (`external-body-not-a-fn`, decision 610).
test "wat: host binding ---- an unknown form, opcode, signature, fn or adapter is refused at the annotation" {
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[compiler.external(.Wasm(op: "f64.flor"))]
        \\declare fn down(x: f64) -> f64;
        \\fn main() -> void { print(down(1.5)); }
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "`f64.flor` is not a wasm numeric instruction", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[compiler.external(.Wasm(op: "f64.min"))]
        \\declare fn least(x: f64) -> f64;
        \\fn main() -> void { print(least(1.5)); }
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "`f64.min` is `(f64, f64) -> f64`", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[compiler.external(.Wasm(op: "f64.lt"))]
        \\declare fn below(a: f64, b: f64) -> f64;
        \\fn main() -> void { print(below(1.0, 2.0)); }
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "`f64.lt` is `(f64, f64) -> bool`", 1, 3);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[compiler.external(.Wasm(body: greetBdy))]
        \\declare fn greet(name: string) -> string;
        \\fn greetBody(name: string) -> string { return name; }
        \\fn main() -> void { print(greet("x")); }
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "unbound variable 'greetBdy'", 1, 33);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[compiler.external(.Wasm(body: greetBody))]
        \\declare fn greet(name: string) -> string;
        \\pub fn greetBody(name: string) -> string { return name; }
        \\fn main() -> void { print(greet("x")); }
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "`greetBody` is `pub`", 1, 27);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[compiler.external(.Wasm(body: greetBody))]
        \\declare fn greet(name: string) -> string;
        \\fn greetBody(name: string, n: i32) -> string { return name; }
        \\fn main() -> void { print(greet("x")); }
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "must take the same parameter types in the same order", 1, 27);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[compiler.external(.Wasm(wasi: .ClockTimeGet))]
        \\declare fn now() -> f64;
        \\fn main() -> void { print(now()); }
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "unbound variable 'ClockTimeGet'", 1, 33);
    try h.assertWasmRefusedAt(std.testing.allocator,
        \\#[compiler.external(.Wasm("""(f64.floor $0)"""))]
        \\declare fn down(x: f64) -> f64;
        \\fn main() -> void { print(down(1.5)); }
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "is none of the four cells", 1, 3);
}

// `wat/host_binding.zig`'s `adapters` is the list `conformance/docs.md` § Host bindings
// documents; the test reads the table and fails in both directions — an
// adapter the backend binds that the reference does not list, and a row the
// backend does not bind.
test "wat: host binding ---- the adapter list agrees with conformance/docs.md" {
    const hb = @import("../wat/host_binding.zig");
    const io = std.testing.io;
    const alloc = std.testing.allocator;
    const docs = try std.Io.Dir.cwd().readFileAlloc(io, "../../conformance/docs.md", alloc, .limited(1 << 22));
    defer alloc.free(docs);
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const head = "| Adapter | Signature | Answers |";
    const at = std.mem.indexOf(u8, docs, head) orelse return error.AdapterTableMissing;
    var rows: usize = 0;
    var lines = std.mem.splitScalar(u8, docs[at + head.len ..], '\n');
    _ = lines.next(); // the rest of the header line
    _ = lines.next(); // the separator
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "| `")) break;
        const end = std.mem.indexOfScalarPos(u8, line, 3, '`') orelse return error.AdapterRowUnreadable;
        // Decision 481 — a row names the adapter as a `wasi:` cell writes
        // it, `.RandomF64` for `random_f64`.
        var snake: std.ArrayList(u8) = .empty;
        defer snake.deinit(alloc);
        if (line[3] != '.') return error.AdapterRowUnreadable;
        for (line[4..end], 0..) |c, k| {
            if (std.ascii.isUpper(c) and k > 0) try snake.append(alloc, '_');
            try snake.append(alloc, std.ascii.toLower(c));
        }
        const name = snake.items;
        if (hb.findAdapter(name) == null) {
            std.debug.print("conformance/docs.md lists the adapter `{s}` and host_binding.zig binds none\n", .{name});
            return error.AdapterNotBound;
        }
        rows += 1;
    }
    for (hb.adapters) |a| {
        const cell = try bpAst.wasmCellDisplay(alloc, try std.fmt.allocPrint(arena.allocator(), "wasi:{s}", .{a.name}));
        defer alloc.free(cell);
        const needle = try std.fmt.allocPrint(alloc, "| `{s}` |", .{cell["wasi: ".len..]});
        defer alloc.free(needle);
        if (std.mem.indexOf(u8, docs[at..], needle) == null) {
            std.debug.print("host_binding.zig binds `{s}` and conformance/docs.md does not list it\n", .{a.name});
            return error.AdapterNotDocumented;
        }
    }
    try std.testing.expectEqual(hb.adapters.len, rows);
}

// Decision 440 (2) — std-wasm's program face, decoded: every function it
// implements turns into the model, links into a module beside a stand-in
// `$__alloc`, validates and encodes. Anything the face must not use (here, a
// module that is no side module at all) is refused by name.
test "wat: std-wasm ---- every function std-wasm implements decodes, validates and encodes" {
    const link = @import("../wat/std_wasm_link.zig");
    const ast = @import("../wat/wat_ast.zig");
    const binary = @import("../wat/wasm_binary_emitter.zig");
    const stdWasm = @import("std_wasm");
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ar = arena.allocator();
    var names: [stdWasm.exports.len + stdWasm.program.len][]const u8 = undefined;
    for (stdWasm.exports, 0..) |e, i| names[i] = e.name;
    for (stdWasm.program, stdWasm.exports.len..) |e, i| names[i] = e.name;
    var diag: link.Diag = .{};
    const l = link.link(ar, &names, 301, &diag) catch |err| {
        std.debug.print("std-wasm: {s}\n", .{diag.message});
        return err;
    };
    var items: std.ArrayListUnmanaged(ast.Item) = .empty;
    try items.append(ar, .{ .memory = .{ .min_pages = 1 } });
    try items.append(ar, .{ .func = .{
        .name = "__alloc",
        .params = &.{.{ .name = "n", .ty = .i32 }},
        .result = .i32,
        .body = .{ .lines = &.{.{ .instr = .{ .local_get = "n" } }}, .stack = .{ .value = .i32 } },
    } });
    // The host's entropy, which `random.seededFloat` draws before any seed
    // (decision 451 (2)).
    try std.testing.expect(l.random);
    try items.append(ar, .{ .func = .{
        .name = link.random_import,
        .result = .f64,
        .body = .{ .lines = &.{.{ .instr = .{ .@"const" = .{ .ty = .f64, .text = "0.5" } } }}, .stack = .{ .value = .f64 } },
    } });
    try items.appendSlice(ar, l.items);
    const m: ast.Module = .{ .items = items.items };
    try ast.validateModule(m);
    _ = try binary.encodeModule(ar, m);
    for (names) |name| try std.testing.expect(ast.declaresCall(m, try link.entryName(ar, name)));
    // The data starts on its alignment at or past the floor; the heap after the stack.
    var data_at: ?u32 = null;
    for (l.items) |it| if (it == .data) {
        data_at = data_at orelse it.data.offset;
        try std.testing.expect(it.data.len_prefix == null);
    };
    try std.testing.expect(data_at.? >= 301 and data_at.? % 8 == 0);
    try std.testing.expect(l.end > data_at.? and l.end % 16 == 0);
    // A print helper calls std-wasm by the symbol the link gives it.
    for (std.enums.values(ast.HelperGroup)) |g| for (g.stdCalls()) |name| {
        try std.testing.expect(stdWasm.find(name) != null or for (stdWasm.program) |p| {
            if (std.mem.eql(u8, p.name, name)) break true;
        } else false);
    };
    try std.testing.expectEqualStrings(comptime @import("../wat/wat_prelude.zig").stdSymbol("number.floatToString"), try link.entryName(ar, watCodegen.stdMethodExport("Float", "toString").?));

    diag = .{};
    try std.testing.expectError(error.Unsupported, link.linkModule(ar, &.{ 0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00 }, &.{}, 0, &diag));
    try std.testing.expect(std.mem.indexOf(u8, diag.message, "dylink.0") != null);
}

// Decision 447 (3) — `$__std_sp` is std-wasm's one stack, and a frame that
// would reach below its floor traps instead of writing over the data beneath
// it. The stack is sized for the deepest frame path the program links, so no
// program reaches its end; the test drives one past it by starting the stack
// pointer eight bytes above the floor (a 16-byte frame then needs eight more)
// and expects the trap, then the same module from its real top to run clean.
// Every prologue the decoder reads goes through `$__std_sp_check`.
test "wat: std-wasm ---- a frame past the stack's end traps, never writes below it" {
    const link = @import("../wat/std_wasm_link.zig");
    const ast = @import("../wat/wat_ast.zig");
    const binary = @import("../wat/wasm_binary_emitter.zig");
    const runtime = @import("../runtime.zig");
    const a = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    var diag: link.Diag = .{};
    const l = try link.link(ar, &.{"text.indexOf"}, 256, &diag);
    // The stack's floor, as the check reads it, and the frame-taking prologue.
    // The prologue opens `text.indexOf`'s frame or a frame of a function it
    // calls — where the optimizer puts it is its choice.
    var floor: ?[]const u8 = null;
    var top: ?usize = null;
    var frames: usize = 0;
    for (l.items, 0..) |it, i| switch (it) {
        .global => |g| if (std.mem.eql(u8, g.name, link.stack_global)) {
            top = i;
        },
        .func => |f| if (std.mem.eql(u8, f.name, link.stack_check)) {
            floor = f.body.lines[1].instr.@"const".text;
        } else if (f.body.lines.len > 3 and f.body.lines[0].instr == .global_get and f.body.lines[3].instr == .call) {
            if (std.mem.eql(u8, f.body.lines[0].instr.global_get, link.stack_global) and std.mem.eql(u8, f.body.lines[3].instr.call, link.stack_check)) frames += 1;
        },
        else => {},
    };
    try std.testing.expect(frames > 0);
    const floor_at = try std.fmt.parseInt(u32, floor.?, 10);
    try std.testing.expect(floor_at >= 256);

    for ([_]bool{ true, false }) |past_end| {
        var items: std.ArrayListUnmanaged(ast.Item) = .empty;
        try items.append(ar, .{ .memory = .{ .@"export" = "memory", .min_pages = 1 } });
        try items.append(ar, .{ .func = .{
            .name = "__alloc",
            .params = &.{.{ .name = "n", .ty = .i32 }},
            .result = .i32,
            .body = .{ .lines = &.{.{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "4096" } } }}, .stack = .{ .value = .i32 } },
        } });
        const linked = try ar.dupe(ast.Item, l.items);
        if (past_end) linked[top.?].global.init = try std.fmt.allocPrint(ar, "{d}", .{floor_at + 8});
        try items.appendSlice(ar, linked);
        // `"".indexOf("")`: the empty string at address 0.
        try items.append(ar, .{ .func = .{
            .name = "_start",
            .exports = &.{"_start"},
            .body = .{ .lines = &.{
                .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
                .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "0" } } },
                .{ .instr = .{ .call = "__std_text_indexOf" } },
                .{ .instr = .drop },
            } },
        } });
        const bytes = try binary.encodeModule(ar, .{ .items = items.items });
        const out = try runtime.executeWat(a, "", bytes, "main", std.testing.io);
        defer a.free(out);
        if (past_end) {
            try std.testing.expect(std.mem.indexOf(u8, out, "unreachable") != null);
        } else {
            try std.testing.expectEqualStrings("", out);
        }
    }
}

// Decision 440 (3) — the `std:` cells `primitives.bp` writes are the ones the
// wasm codegen lowers by (`wat.zig` `std_method_exports`), in both
// directions: a method the table binds carries its cell, and every `std:`
// cell of the prelude is a row of the table.
test "wat: std-wasm ---- primitives.bp's std: cells agree with the codegen's table" {
    const stdWasm = @import("std_wasm");
    const src = @import("std_prelude").primitives;
    for (watCodegen.std_method_exports) |row| {
        // A primitive type's own member (`pub type string { … }`, decision
        // 641), or — a contract carries no host code (decision 617 (3)) — the
        // member of the first type implementing it (`Float.toString` is
        // written on `f32` and `f64`).
        var head_buf: [64]u8 = undefined;
        const head = try std.fmt.bufPrint(&head_buf, "pub type {s} ", .{row.behavior});
        var type_buf: [64]u8 = undefined;
        const type_head = try std.fmt.bufPrint(&type_buf, " implement {s} {{", .{row.behavior});
        const at = std.mem.indexOf(u8, src, type_head) orelse std.mem.indexOf(u8, src, head) orelse return error.BehaviorMissing;
        var fn_buf: [64]u8 = undefined;
        const decl = try std.fmt.bufPrint(&fn_buf, "fn {s}(", .{row.method});
        const f = std.mem.indexOfPos(u8, src, at, decl) orelse return error.MethodMissing;
        var cell_buf: [96]u8 = undefined;
        const cell = try std.fmt.bufPrint(&cell_buf, ".Wasm(std: \"{s}\")", .{row.export_name});
        // The cell sits in the annotation block right above the declaration.
        const block_start = std.mem.lastIndexOf(u8, src[0..f], ";") orelse at;
        if (std.mem.indexOf(u8, src[block_start..f], cell) == null) {
            std.debug.print("primitives.bp: `{s}.{s}` carries no {s}\n", .{ row.behavior, row.method, cell });
            return error.CellMissing;
        }
    }
    var n: usize = 0;
    var seen: std.ArrayListUnmanaged(u8) = .empty;
    defer seen.deinit(std.testing.allocator);
    var it = std.mem.splitSequence(u8, src, ".Wasm(std: \"");
    _ = it.next();
    while (it.next()) |rest| {
        const end = std.mem.indexOfScalar(u8, rest, '"') orelse return error.CellUnreadable;
        // A free host helper of a `default fn`'s body (`stringSlice0`): a
        // `declare fn` at the top level, adopted by the call that reaches it
        // (`adoptPreludeHostFn`), not a method row — std-wasm exports it.
        const after = rest[end..];
        // The declaration follows the annotation's closing `)]`.
        const close = std.mem.indexOf(u8, after, ")]") orelse return error.CellUnreadable;
        const line_end = std.mem.indexOfScalarPos(u8, after, close, '\n') orelse return error.CellUnreadable;
        if (std.mem.startsWith(u8, after[line_end + 1 ..], "declare fn ")) {
            if (stdWasm.find(rest[0..end]) == null) {
                std.debug.print("primitives.bp binds `std:{s}` and std-wasm exports no such function\n", .{rest[0..end]});
                return error.CellNotLowered;
            }
            continue;
        }
        var found = false;
        for (watCodegen.std_method_exports) |row| {
            if (std.mem.eql(u8, row.export_name, rest[0..end])) found = true;
        }
        // Each width writes its own cell (`f32` and `f64`'s `toString`): one
        // row per function.
        var key_buf: [96]u8 = undefined;
        const key = try std.fmt.bufPrint(&key_buf, "|{s}|", .{rest[0..end]});
        if (std.mem.indexOf(u8, seen.items, key) == null) {
            n += 1;
            try seen.appendSlice(std.testing.allocator, key);
        }
        if (!found) {
            std.debug.print("primitives.bp binds `std:{s}` and wat.zig's std_method_exports has no row for it\n", .{rest[0..end]});
            return error.CellNotLowered;
        }
    }
    try std.testing.expectEqual(watCodegen.std_method_exports.len, n);
}

// Decisions 440, 441 — std's `hash.contentHash` (a `std:` binding of std's),
// `trim` (space, tab, LF, CR, VT, FF; a no-break space stays) and a float's
// text in a string answer std-wasm's, transpiled into the module.
test "wat: std-wasm ---- a std: binding, trim and a float's text answer std-wasm's" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\import {hash} from "std";
        \\fn main() -> void {
        \\    print(hash.contentHash("Point"));
        \\    print("[" + " \t\na b\r ".trim() + "]");
        \\    print("[" + " a ".trimStart() + "]");
        \\    print("[" + " a ".trimEnd() + "]");
        \\    print("${2.5} ${100.0} ${1e22}");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\de553cf
        \\[a b]
        \\[a ]
        \\[ a]
        \\2.5 100.0 1.0e22
        \\
    );
}

// An empty body is a function that does nothing, not a bodyless `declare fn`:
// `main` written `{}` is emitted for `_start` to call (it was not — the module
// failed validation, `UndefinedCall`), and an empty `fn` is called.
test "wat: fn ---- an empty body is emitted and called, never taken for a declare fn" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {}
    , "");
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn nothing() -> void {}
        \\fn main() -> void {
        \\    nothing();
        \\    print("after");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\after
        \\
    );
}

// std's `testing.mocks` links no other std module: its test scaffolding is a
// private cell of its own, never an import of `testing.asserts`, whose
// host-only `canonical` the import linked into it — its wasm refusal then named
// `canonical` at `asserts.bp` instead of its own host cell, and every cell
// pinning that refusal went red (`conformance/modules/std/{run,refused}/src/cases/std_decorator_*` and `modules/std/cells/std_decorator_*`). The
// module is refused on wasm for one of ITS host cells, never a linked one's.
// Decision 531 — a dependency's function the program never reaches is not
// lowered on wasm and stops nothing: `testing.mocks`' host cells have no wasm
// binding, and neither the module nor the program importing it is refused.
test "wat: std ---- testing.mocks imports on wasm, its unbound host cells unlowered (decision 531)" {
    var outputs = try codegen.generateWith(std.testing.allocator, &.{.{ .path = "", .source =
        \\import {testing.mocks} from "std";
        \\fn main() -> void {
        \\    print(0);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    }}, std.testing.io, h.configs[3], .{ .execute = false });
    defer {
        for (outputs.items) |*o| o.result.deinit(std.testing.allocator);
        outputs.deinit(std.testing.allocator);
    }
    var seen = false;
    for (outputs.items) |o| {
        if (o.result.diagnostic) |d| {
            std.debug.print("{s}: {s}\n", .{ o.name, d.type.message });
            return error.UnexpectedRefusal;
        }
        if (std.mem.eql(u8, o.name, "std/testing/mocks")) seen = true;
    }
    if (!seen) return error.ModuleNotEmitted;
}

// Decision 443 — case mapping over all of Unicode, std-wasm's: OTP's answer
// where a JS engine's differs. No final sigma (`ΟΔΟΣ` lowers to `οδοσ`; node
// answers `οδος`), the unconditional full mappings (`ß` → `SS`).
test "wat: std-wasm ---- toUpper and toLower answer OTP's over all of Unicode" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    print("straße é ǆ ﬁ".toUpper());
        \\    print("ΟΔΟΣ ÉCOLE".toLower());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\STRASSE É Ǆ FI
        \\οδοσ école
        \\
    );
}

// Decision 445 — a `std:` cell is std's alone: outside std it is refused at
// the annotation, naming the std function to call instead (also
// `conformance/modules/decisions-taken/std_cell_is_std_only-445/cells/external_wasm_std_outside_std`); inside std, a name
// std-wasm lacks and a declaration of other types are refused there (decision
// 440 (3)) — what only std can now write.
test "wat: std-wasm ---- a std: cell is std's alone, and inside std it names an export of its types" {
    const a = std.testing.allocator;
    try h.assertJsRefusedAt(a,
        \\#[compiler.external(.JavaScript("String"), .Wasm(std: "hash.contentHash"))]
        \\declare fn digest(x: string) -> string;
        \\fn main() -> void {
        \\    print(digest("Point"));
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "a `std:` binding is std's alone (decision 445) — call std's `hash.contentHash` instead", 1, 3);
    try h.assertStdModuleRefusedAt(a,
        \\#[compiler.external(.JavaScript("Math.floor($0)"), .Wasm(std: "math.floorOf"))]
        \\declare fn floorOf(x: f64) -> f64;
        \\fn main() -> void {
        \\    print(floorOf(2.5));
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "std-wasm implements no `math.floorOf`", 1, 3);
    try h.assertStdModuleRefusedAt(a,
        \\#[compiler.external(.JavaScript("String"), .Wasm(std: "hash.contentHash"))]
        \\declare fn digestOf(x: i32) -> string;
        \\fn main() -> void {
        \\    print(digestOf(7));
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "std-wasm's `hash.contentHash` is `(string) -> string`, and `digestOf` is declared `(i32) -> string`", 1, 3);
}

// Decision 445 — each std-wasm export names the std function that binds it,
// what the refusal outside std tells a program to call: a primitive method's
// row of `std_method_exports` is its `Behavior.method`.
test "wat: std-wasm ---- every export names the std function a program calls instead" {
    const stdWasm = @import("std_wasm");
    for (watCodegen.std_method_exports) |row| {
        const e = stdWasm.find(row.export_name) orelse return error.ExportMissing;
        var buf: [96]u8 = undefined;
        try std.testing.expectEqualStrings(try std.fmt.bufPrint(&buf, "{s}.{s}", .{ row.behavior, row.method }), e.api);
    }
    try std.testing.expectEqualStrings("hash.contentHash", stdWasm.find("hash.contentHash").?.api);
}

// Decision 441: a wasm program prints std-wasm's text — the text of erlang,
// beam and the comptime, OTP's `float_to_binary(F, [short])`: the shortest
// round-trip digits, in fixed notation or as `D.DDDeE`, whichever is shorter
// (`1.0e21`, `5.0e-324`, `1.0e-6`; `100000000000000000000.0` is `1.0e20`, and
// `2^60` is `1.152921504606847e18`, its 16 shortest digits — OTP's own
// answers). The values erlang cannot make
// (`Infinity`, `NaN`) are written as those words. commonJS keeps the JS
// engine's text (`1e+21`, `5`).
test "wat: print ---- a float prints std-wasm's text, as erlang does (decision 441)" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn id(x: f64) -> f64 {
        \\    return x;
        \\}
        \\fn main() -> void {
        \\    print(1e21);
        \\    print(1.7976931348623157e308);
        \\    print(5e-324);
        \\    print(1e-7);
        \\    print(0.000001);
        \\    print(1152921504606846976.0);
        \\    print(100000000000000000000.0);
        \\    print(id(1.0) / 0.0);
        \\    print(id(-1.0) / 0.0);
        \\    print(id(0.0) / 0.0);
        \\    print(5.0.toString());
        \\    print("x" + 0.000001);
        \\    print("x" + 1e300);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\1.0e21
        \\1.7976931348623157e308
        \\5.0e-324
        \\1.0e-7
        \\1.0e-6
        \\1.152921504606847e18
        \\1.0e20
        \\Infinity
        \\-Infinity
        \\NaN
        \\5.0
        \\x1.0e-6
        \\x1.0e300
        \\
    );
}

// `00 · gate-wasm-wrong-answers`: an integer `+`, `-`, `*` whose result leaves
// its type traps rather than wrapping. commonJS and erlang never wrap
// (`2147483647 + 1` is `2147483648` on both); `i32.add` answered
// `-2147483648` at exit 0. Up to the edge the answer is the number.
test "wat: arithmetic ---- an integer that leaves its width traps instead of wrapping" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    val big: i32 = 2147483647;
        \\    print(big - 1);
        \\    print(-big);
        \\    val wide: i64 = 9223372036854775807;
        \\    print(wide);
        \\    print(big + 1);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\2147483646
        \\-2147483647
        \\9223372036854775807
        \\panic: integer overflow: + on i32 at main.bp:7:15
        \\RUNTIME TRAP (wasmtime):
        \\wasm trap: wasm `unreachable` instruction executed
        \\
    );
}

// `01-compiler/05-wasm` step 5: a `?T` in a tuple's slot is the optional's
// carrier — `0` absence, a scalar's box, a string's or a record's own
// pointer, a float's cell — and prints `null` or its payload (`?X` / `!X` in
// `$__print_shaped_raw`). Read through the payload's code it printed the
// box's address (`#(1, 328)`) at exit 0, and a generic method's
// `#(Q<T>, ?T)` read the box as the payload.
test "wat: tuple ---- a `?T` element prints and reads as its payload or null" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type P(n: i32)
        \\type Q<T>(items: array<T>) {
        \\    fn pop(self: Self<T>) -> #(Q<T>, ?T) {
        \\        return #(Q(items: self.items), self.items.at(0));
        \\    }
        \\}
        \\fn mixed() -> #(?i32, ?string, ?bool, ?f64, ?P) {
        \\    return #([7].at(0), ["s"].at(3), [true].at(0), [1.5].at(0), [P(n: 2)].at(0));
        \\}
        \\fn main() -> void {
        \\    val t = #(1, [7].at(5));
        \\    print(t);
        \\    print(t._1 ?? 4);
        \\    print(mixed());
        \\    val m = mixed();
        \\    print(m._0);
        \\    print(m._1);
        \\    print(m._3);
        \\    val q: Q<i32> = Q(items: [5, 6]);
        \\    print(q.pop()._1 ?? -1);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\#(1, null)
        \\4
        \\#(7, null, true, 1.5, P(n: 2))
        \\7
        \\null
        \\1.5
        \\5
        \\
    );
}

// `o.unwrapOr(d)` keeps the payload's print shape: the `@Result`'s declared
// payload, else a container default (`[]` says nothing). Both read a tuple's
// string element as an integer at exit 0.
test "wat: the nullish default ---- the answer keeps the payload's tuple shape" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn rows() -> Result<array<#(string, string)>, string> {
        \\    val xs = [#("a", "b"), #("c", "d")];
        \\    if (xs.length > 5) throw "too many";
        \\    return xs;
        \\}
        \\fn main() -> void {
        \\    val rs = rows().unwrapOr([]);
        \\    print(rs);
        \\    print((rs.at(1) ?? #("", ""))._1);
        \\    print(rs.map({ r -> r._0 }).join(","));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\[#("a", "b"), #("c", "d")]
        \\d
        \\a,c
        \\
    );
}

// `01-compiler/05-wasm`'s rows: a `_` in a variant's payload pattern bound
// nothing for the names beside it (`Rect(w, _)` answered `w = 0`: the
// pattern's binder pass returned on a payload holding anything but names), and
// a nested variant pattern left one test per payload element on the stack,
// unread — `Two(Rect(w, _), _)` answered whatever the last one said.
test "wat: case ---- a `_` and a nested variant in a payload pattern" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(width: i32, height: i32),
        \\    Dot,
        \\}
        \\type Pair {
        \\    Two(left: Shape, right: Shape),
        \\}
        \\fn widthOf(s: Shape) -> i32 {
        \\    return case s {
        \\        Rect(w, _) -> w;
        \\        Circle(_) -> -1;
        \\        Dot -> 0;
        \\    };
        \\}
        \\fn leftWidth(p: Pair) -> i32 {
        \\    return case p {
        \\        Two(Rect(w, _), _) -> w;
        \\        Two(Circle(r), Rect(_, h)) -> r * 1000 + h;
        \\        Two(_, Circle(r)) -> -r;
        \\        Two(_, _) -> 0;
        \\    };
        \\}
        \\fn main() -> void {
        \\    print(widthOf(Shape.Rect(4, 5)));
        \\    print(widthOf(Shape.Circle(3)));
        \\    print(leftWidth(Pair.Two(Shape.Rect(9, 1), Shape.Dot)));
        \\    print(leftWidth(Pair.Two(Shape.Circle(2), Shape.Rect(6, 7))));
        \\    print(leftWidth(Pair.Two(Shape.Dot, Shape.Circle(8))));
        \\    print(leftWidth(Pair.Two(Shape.Dot, Shape.Dot)));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\4
        \\-1
        \\9
        \\2007
        \\-8
        \\0
        \\
    );
}

// Decision 319 on wasm: a `u64` holds `0 … 2^64 − 1` in its `i64` carrier.
// Read signed, `10^19` printed `-8446744073709551616`, compared below `3`,
// divided to a negative quotient and trapped in `$__i64_sub_chk` on
// `10^19 - 3·10^18` — all at exit 0 but the last. Its digits, `/ % < >` and
// checked `+ - *` now read the bits unsigned; past either end still traps.
test "wat: arithmetic ---- a `u64` past 2^63 is unsigned in its `i64` carrier" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    val w: u64 = 10000000000000000000;
        \\    val v: u64 = 3000000000000000000;
        \\    val m: u64 = 18446744073709551615;
        \\    print(w);
        \\    print(w > v);
        \\    print(v >= w);
        \\    print(w / v);
        \\    print(w % v);
        \\    print(w - v);
        \\    print(v + v + v);
        \\    print(m.toString());
        \\    print("${m / 2}");
        \\    print(v - w);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\10000000000000000000
        \\true
        \\false
        \\3
        \\1000000000000000000
        \\7000000000000000000
        \\9000000000000000000
        \\18446744073709551615
        \\9223372036854775807
        \\panic: integer overflow: - on u64 at main.bp:14:13
        \\RUNTIME TRAP (wasmtime):
        \\wasm trap: wasm `unreachable` instruction executed
        \\
    );
}

// Decision 319 on wasm: a `val` with no annotation over a `u64` keeps its
// type — bound to a `ul` literal past `i64`'s top (decimal or radix) or to a
// `u64` sum. `val top = 18446744073709551615ul; @print(top)` printed `-1`
// and `0xFFFF_FFFF_FFFF_FFFFul` folded to a `256` placeholder.
test "wat: arithmetic ---- an unannotated `val` over a `u64` literal or sum prints unsigned" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    val top = 18446744073709551615ul;
        \\    val hex = 0xFFFF_FFFF_FFFF_FFFFul;
        \\    val sum = 18446744073709551614ul + 1ul;
        \\    print(top);
        \\    print(hex);
        \\    print(sum);
        \\    print(top == hex);
        \\    print(top + 1ul);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\18446744073709551615
        \\18446744073709551615
        \\18446744073709551615
        \\true
        \\panic: integer overflow: + on u64 at main.bp:9:15
        \\RUNTIME TRAP (wasmtime):
        \\wasm trap: wasm `unreachable` instruction executed
        \\
    );
}

test "wat: print ---- @println lowers as @print does, with its newline" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    print("a", 1);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// B-31: a template is a `string` whatever its parts. The desugared
// `"" + 5.5` met an `i32` address with an `f64` and typed the whole as `f64`,
// so `s + "!"` was invalid wasm and an array element was refused.
test "wat: template ---- a lone float hole is a string, as a val, an element and an operand" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    val s = "${5.5}";
        \\    print(s + "!");
        \\    val xs: string[] = ["${2.5}", "a"];
        \\    print(xs.length);
        \\    print("${1.5}" + "${2.25}");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\5.5!
        \\2
        \\1.52.25
        \\
    );
}

// A module-level tuple's `bool` element read inside a function. `print_shape_locals` is cleared
// per function and held only locals, so `t.flag` (a labelled tuple, the shape a template's
// `@expr(#(server, debug))` lifts) had no shape for a global `t` and printed `1`, where every
// other target prints `true`. `conformance/modules/global/cells/global_tuple_bool_field` is the cross-backend
// half.
test "wat: print ---- a bool element of a module-level tuple prints true / false" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\val flag = true;
        \\val off = false;
        \\val a = 3;
        \\val t = #(a, flag, off);
        \\fn main() -> void {
        \\    print(t.flag);
        \\    print(t.2);
        \\    print(t.0);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "true\nfalse\n3\n");
}

test "wat: a package template's answer is its library's record, its field read and its method resolved" {
    // 144 B-68 — `shelf @`built`` answers `Label`, a type this module does not
    // import. The call's value carries `Label`'s fields (the slot of `text`
    // is a string, `size` an `i32` with `toString`), and the built code's
    // call to the library's `makeLabel` — under the template's alias —
    // answers the record `Label` too.
    try h.assertWasmRunLogModules(std.testing.allocator, &.{
        .{ .path = "shelf/shelf", .source =
        \\pub type Label(text: string, size: i32)
        \\
        \\pub fn makeLabel(text: string) -> Label {
        \\    return Label(text: text, size: text.length);
        \\}
        \\
        \\pub default fn label(syntax t: string) -> Label {
        \\    return compiler.build("makeLabel(\"" + compiler.text(t) + "\")");
        \\}
        \\
        \\import {compiler} from "std";
        },
        .{ .path = "shelf/root", .source =
        \\pub default mod shelf;
        },
        .{ .path = "", .source =
        \\import shelf from "shelf";
        \\
        \\pub fn main() -> void {
        \\    val built = shelf @`built`;
        \\    print(built.text);
        \\    print(built.size.toString());
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    }, "built\n5\n");
}

// Decision 346 — `Bytes` on this backend: in and out of text, length, slice,
// concat, `==`, and the `Error` of bytes that are not UTF-8.
const bytes_src =
    \\pub fn main() -> void {
    \\    val b = bytes.fromUtf8("héllo");
    \\    print(b.length());
    \\    print(b.slice(1, 3).toUtf8().unwrapOr("?"));
    \\    print(b.slice(1, 2).toUtf8().isError());
    \\    val j = bytes.fromUtf8("ab").concat(bytes.fromUtf8("cd"));
    \\    print(j[2..].toUtf8().unwrapOr("?"));
    \\    print(j == bytes.fromUtf8("abcd"));
    \\}
    \\
    \\import {io.terminal.print} from "std";
;
const bytes_log = "6\né\ntrue\ncd\ntrue\n";

test "wat: decision 346 ---- bytes is a string's buffer, toUtf8 std-wasm's bytes.isUtf8" {
    try h.assertWasmRunLog(std.testing.allocator, bytes_src, bytes_log);
}

// 144 B-20 Conformance — `recv?.m()` over a record's and an all-unit enum's
// method: the method runs only on a present receiver and its answer is a
// `?R` (a present `0` stays present). The enum's dispatcher trapped on an
// absent one, a record's method read address 0.
test "wat: decision 330 ---- recv?.m() over a record's or an all-unit enum's method is guarded and boxed" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\type P(x: i32) {
        \\    fn twice(self: Self) -> i32 {
        \\        return self.x * 2;
        \\    }
        \\}
        \\type C {
        \\    Red,
        \\    Green,
        \\
        \\    fn n(self: Self) -> i32 {
        \\        return case self {
        \\            Red -> 0;
        \\            Green -> 1;
        \\        };
        \\    }
        \\}
        \\fn p(c: bool) -> ?P {
        \\    return if (c) P(x: 0) else null;
        \\}
        \\fn col(c: i32) -> ?C {
        \\    if (c == 0) return null;
        \\    return C.Red;
        \\}
        \\fn main() -> void {
        \\    print(p(true)?.twice() ?? -1);
        \\    print(p(false)?.twice() ?? -1);
        \\    print(col(1)?.n() ?? -1);
        \\    print(col(0)?.n() ?? -1);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "0\n-1\n0\n-1\n");
}

/// The wasm binary of `src` (the module with the empty path), owned by the caller.
fn wasmBinaryOfSource(allocator: Allocator, src: []const u8) ![]u8 {
    var outputs = try h.generate(allocator, &.{.{ .path = "", .source = src }}, std.testing.io, h.configs[3]);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        return allocator.dupe(u8, o.result.wasm orelse return error.ModuleDidNotCompile);
    }
    return error.ModuleDidNotCompile;
}

/// The bytes of each `rec` group of a wasm binary's type section, in order.
fn recGroupsOf(allocator: Allocator, wasm: []const u8) ![]const []const u8 {
    const R = struct {
        b: []const u8,
        at: usize,
        fn byte(r: *@This()) u8 {
            r.at += 1;
            return r.b[r.at - 1];
        }
        fn leb(r: *@This()) u32 {
            var v: u32 = 0;
            var shift: u5 = 0;
            while (true) {
                const x = r.byte();
                v |= @as(u32, x & 0x7f) << shift;
                if (x & 0x80 == 0) return v;
                shift +%= 7;
            }
        }
        fn field(r: *@This()) void {
            const t = r.byte();
            if (t == 0x63 or t == 0x64) _ = r.leb();
            _ = r.byte(); // mutability
        }
    };
    var r: R = .{ .b = wasm, .at = 8 };
    var groups: std.ArrayListUnmanaged([]const u8) = .empty;
    errdefer groups.deinit(allocator);
    while (r.at < wasm.len) {
        const id = r.byte();
        const size = r.leb();
        if (id != 1) {
            r.at += size;
            continue;
        }
        var n = r.leb();
        while (n > 0) : (n -= 1) {
            const start = r.at;
            if (r.byte() != 0x4E) break;
            var members = r.leb();
            while (members > 0) : (members -= 1) {
                var k = r.byte();
                if (k == 0x50 or k == 0x4F) {
                    var supers = r.leb();
                    while (supers > 0) : (supers -= 1) _ = r.leb();
                    k = r.byte();
                }
                if (k == 0x5F) {
                    var fields = r.leb();
                    while (fields > 0) : (fields -= 1) r.field();
                } else if (k == 0x60) {
                    // A function type of the prelude (decision 1055 (1)):
                    // its parameters, then its results.
                    for (0..2) |_| {
                        var vals = r.leb();
                        while (vals > 0) : (vals -= 1) {
                            const t = r.byte();
                            if (t == 0x63 or t == 0x64) _ = r.leb();
                        }
                    }
                } else r.field();
            }
            try groups.append(allocator, wasm[start..r.at]);
        }
        break;
    }
    return groups.toOwnedSlice(allocator);
}

// Decision 1021 (9) — a type's group and its place depend only on the
// declarations: two modules naming one record, each lowering its types in an
// order of its own (one asks for an array of floats and another record
// first), carry the same prelude group and the same group for the record,
// byte for byte; the second module's own record, which names it, comes after.
test "wat: decision 1021 (9) ---- two modules naming one record carry byte-identical shared type groups" {
    const alloc = std.testing.allocator;
    const a = try wasmBinaryOfSource(alloc,
        \\type Point(x: i32, label: string)
        \\fn main() -> void {
        \\    val p = Point(x: 1, label: "a");
        \\    print(p.label);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
    defer alloc.free(a);
    const b = try wasmBinaryOfSource(alloc,
        \\type Zed(p: Point, n: i32)
        \\type Point(x: i32, label: string)
        \\fn main() -> void {
        \\    val xs = [1.5, 2.5];
        \\    print(xs[1]);
        \\    val z = Zed(p: Point(x: 3, label: "b"), n: 4);
        \\    print(z.p.label);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
    defer alloc.free(b);
    const ga = try recGroupsOf(alloc, a);
    defer alloc.free(ga);
    const gb = try recGroupsOf(alloc, b);
    defer alloc.free(gb);
    // The prelude, `Point`'s group; and in the second, `Zed`'s.
    try std.testing.expectEqual(@as(usize, 2), ga.len);
    try std.testing.expectEqual(@as(usize, 3), gb.len);
    try std.testing.expectEqualSlices(u8, ga[0], gb[0]);
    try std.testing.expectEqualSlices(u8, ga[1], gb[1]);
}

/// The host features the wasm build of `src` (the module with the empty path)
/// asks for — its binary's `botopink.needs` section (decision 518).
fn wasmNeedsOfSource(allocator: Allocator, src: []const u8) !bpAst.WasmNeeds {
    var outputs = try h.generate(allocator, &.{.{ .path = "", .source = src }}, std.testing.io, h.configs[3]);
    defer {
        for (outputs.items) |*o| o.result.deinit(allocator);
        outputs.deinit(allocator);
    }
    for (outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "") and !std.mem.eql(u8, o.name, "main")) continue;
        return codegen.wasmNeeds.needsOf(o.result.wasm orelse return error.ModuleDidNotCompile);
    }
    return error.ModuleDidNotCompile;
}

// Decision 518 (2) — the compiler gathers the `needs` of what the program
// REACHES: `std/failure` linked and `attempt` never called asks for no
// exception handling. The module is a WasmGC one (front 164 s2), so `gc` is
// the one need its section names.
test "wat: needs ---- std/failure linked and attempt never called asks for nothing" {
    const needs = try wasmNeedsOfSource(std.testing.allocator,
        \\import {failure} from "std";
        \\fn main() -> void {
        \\    print("no attempt");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
    try std.testing.expect(!needs.contains(.exceptions));
    try std.testing.expect(needs.contains(.gc));
    try std.testing.expectEqual(@as(usize, 1), needs.count());
}

// Decision 771 — a module binding std's memo cells (`wasi: .CellNew` …, `use
// memo`) keeps the WasmGC lowering: the cell is a `$cell` struct, not a
// linear-memory word.
test "wat: needs ---- a use memo module stays WasmGC" {
    const needs = try wasmNeedsOfSource(std.testing.allocator,
        \\import {context.RenderScope, hooks.memo, io.terminal.print} from "std";
        \\
        \\type Element(text: string) implement Renderable
        \\
        \\component fn Page(name: string) -> Component<Element> {
        \\    val label = use memo({ ->
        \\        print("label " + name);
        \\        "page " + name
        \\    });
        \\    val count = use memo({ ->
        \\        print("count " + name);
        \\        name.length + 1
        \\    });
        \\    return Element(text: label + " " + count.toString());
        \\}
        \\
        \\pub async fn main() -> Async<void> {
        \\    val a = Page("a");
        \\    val b = Page("bb");
        \\    val first = (await a.run(RenderScope.root())).value;
        \\    print(first.text);
        \\    val again = (await a.run(RenderScope.root())).value;
        \\    print(again.text);
        \\    val other = (await b.run(RenderScope.root())).value;
        \\    print(other.text);
        \\    val last = (await a.run(RenderScope.root())).value;
        \\    print(last.text);
        \\}
    );
    try std.testing.expect(needs.contains(.gc));
}

// ... and a call of `attempt` asks for `Exceptions`.
test "wat: needs ---- a call of attempt asks for Exceptions" {
    const needs = try wasmNeedsOfSource(std.testing.allocator,
        \\import {failure} from "std";
        \\fn main() -> void {
        \\    val r = failure.attempt({ -> 6 * 7 });
        \\    print("done");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
    try std.testing.expect(needs.contains(.exceptions));
}

// Decisions 449 (3), 450 (4) — the Erlang terms translated BEAM code computes
// over, allocated on a process's heap (std-wasm's `heap.zig`) with the layout
// each cell kind has (`term.cellLayout`), survive its collections: a module
// links the term library with `env.bp_term_alloc` bound to `heap.alloc` and
// `env.bp_term_static` (an atom) to `heap.static`, as a host running
// translated code does; it decodes a nested term (a tuple, lists, a map,
// binaries, atoms, an integer past 32 bits, a float) many times over as
// garbage, keeps one in a root, one list of them growing and dropped, one
// binary whose bytes a builder made on the heap and one in the process
// dictionary (`heap.termRoots`), collects minor and major, then compares each
// kept term with a fresh decode (`rt_eqx`): a word a layout mislabels moves
// under it or is rewritten, and the comparison traps. The kept term must have
// moved: a collection that copied nothing would prove nothing.
const heap_etf = [_]u8{
    131, 104, 8,   97,  1,   109, 0,   0,   0,   2,   97,  98,  108, 0,   0,   0,   3,   119, 3,   102,
    111, 111, 70,  64,  4,   0,   0,   0,   0,   0,   0,   104, 3,   119, 6,   110, 101, 115, 116, 101,
    100, 107, 0,   3,   1,   2,   3,   116, 0,   0,   0,   2,   97,  7,   108, 0,   0,   0,   1,   119,
    3,   98,  97,  114, 106, 119, 1,   107, 109, 0,   0,   0,   1,   118, 106, 98,  255, 254, 238, 144,
    110, 6,   0,   0,   0,   0,   0,   0,   1,   109, 0,   0,   0,   20,  98,  121, 116, 101, 115, 32,
    97,  110, 100, 32,  109, 111, 114, 101, 32,  98,  121, 116, 101, 115, 108, 0,   0,   0,   12,  109,
    0,   0,   0,   1,   120, 109, 0,   0,   0,   1,   120, 109, 0,   0,   0,   1,   120, 109, 0,   0,
    0,   1,   120, 109, 0,   0,   0,   1,   120, 109, 0,   0,   0,   1,   120, 109, 0,   0,   0,   1,
    120, 109, 0,   0,   0,   1,   120, 109, 0,   0,   0,   1,   120, 109, 0,   0,   0,   1,   120, 109,
    0,   0,   0,   1,   120, 109, 0,   0,   0,   1,   120, 106, 107, 0,   5,   99,  104, 97,  114, 115,
};

const HeapRun = enum { kept, exhaust };

/// The module `HeapRun` names, encoded: the term library and the heap linked
/// from `std_wasm.wasm`, a `_start` driving them.
fn termHeapModule(ar: Allocator, run: HeapRun) ![]u8 {
    const link = @import("../wat/std_wasm_link.zig");
    const ast = @import("../wat/wat_ast.zig");
    const binary = @import("../wat/wasm_binary_emitter.zig");
    const wanted = [_][]const u8{
        "heap.init",     "heap.alloc",    "heap.static", "heap.collect", "heap.termRoots",
        "rt_reset",      "rt_etf_decode", "rt_eqx",      "rt_atom",      "rt_erlang_put",
        "rt_erlang_get", "rt_cons",       "rt_nil",      "rt_hd",        "rt_bin",
        "rt_bb_new",     "rt_bb_bin",     "rt_bb_end",
    };
    const bindings = [_]link.Binding{
        .{ .import = "bp_alloc", .to = "" },
        .{ .import = "bp_term_alloc", .to = "__std_heap_alloc" },
        .{ .import = "bp_term_static", .to = "__std_heap_static" },
        .{ .import = "bp_random_f64", .to = "" },
        .{ .import = "bp_call0", .to = "" },
        .{ .import = "bp_call1", .to = "" },
        .{ .import = "bp_call2", .to = "" },
        .{ .import = "bp_call3", .to = "" },
        .{ .import = "bp_call4", .to = "" },
    };
    var diag: link.Diag = .{};
    const l = link.linkWith(ar, link.module_bytes, &wanted, 1024, .{ .bindings = &bindings, .fixed_stack = 64 * 1024, .export_wanted = true }, &diag) catch |err| {
        std.debug.print("std-wasm: {s}\n", .{diag.message});
        return err;
    };
    // A runtime function whose body another's equals is folded into it and
    // named by the first: `rt_hd` is the function its export names.
    var rt_hd: []const u8 = "rt_hd";
    for (l.items) |it| if (it == .func) for (it.func.exports) |e| {
        if (std.mem.eql(u8, e, "rt_hd")) rt_hd = it.func.name;
    };
    // Scratch below the data: the roots, the term's bytes, an atom's name, a binary's.
    const roots: u32 = 128;
    const etf_at: u32 = 256;
    const key_at: u32 = 512;
    const hello_at: u32 = 520;
    const pages: u32 = @intCast((l.end + 65535) / 65536);

    const L = struct {
        ar: Allocator,
        fn c(s: @This(), v: i64) ast.Instr {
            return .{ .@"const" = .{ .ty = .i32, .text = std.fmt.allocPrint(s.ar, "{d}", .{v}) catch unreachable } };
        }
        fn op(_: @This(), name: []const u8) ast.Instr {
            return .{ .op = .{ .ty = .i32, .name = name } };
        }
        fn seq(s: @This(), instrs: []const ast.Instr) ast.Seq {
            const lines = s.ar.alloc(ast.Line, instrs.len) catch unreachable;
            for (lines, instrs) |*ln, i| ln.* = .{ .instr = i };
            return .{ .lines = lines, .stack = .none };
        }
        fn when(s: @This(), then: []const ast.Instr) ast.Instr {
            return .{ .@"if" = .{ .then = .{ .seq = s.seq(then) } } };
        }
    };
    const b: L = .{ .ar = ar };
    var fresh_buf: [3]ast.Instr = .{ b.c(etf_at), b.c(heap_etf.len), .{ .call = "rt_etf_decode" } };
    const fresh: []const ast.Instr = &fresh_buf;
    // A binary whose bytes a builder made on the heap: "hello heap" twice.
    const built: []const ast.Instr = &.{
        .{ .call = "rt_bb_new" }, .{ .local_set = "bb" },
        .{ .local_get = "bb" },   b.c(hello_at),
        b.c(10),                  .{ .call = "rt_bin" },
        .{ .call = "rt_bb_bin" }, .drop,
        .{ .local_get = "bb" },   b.c(hello_at),
        b.c(10),                  .{ .call = "rt_bin" },
        .{ .call = "rt_bb_bin" }, .drop,
        .{ .local_get = "bb" },   .{ .call = "rt_bb_end" },
    };
    // A damaged value is told from memory exhausted by its trap.
    const damaged: []const ast.Instr = &.{ b.c(1), b.c(0), b.op("div_s"), .drop };

    var start: std.ArrayListUnmanaged(ast.Instr) = .empty;
    try start.appendSlice(ar, &.{ b.c(l.end), .{ .call = "__std_heap_init" }, .drop, .{ .call = "rt_reset" }, .{ .call = "__std_heap_termRoots" } });
    // The process dictionary holds one: `put(key, T)`.
    try start.appendSlice(ar, &.{ b.c(key_at), b.c(3), .{ .call = "rt_atom" }, .{ .local_set = "key" }, .{ .local_get = "key" } });
    try start.appendSlice(ar, fresh);
    try start.appendSlice(ar, &.{ .{ .call = "rt_erlang_put" }, .drop });
    // Root 0: one decode, kept throughout; root 1: a list of them; root 2: a built binary.
    try start.append(ar, b.c(roots));
    try start.appendSlice(ar, fresh);
    try start.appendSlice(ar, &.{ .{ .store = .{} }, b.c(roots + 4), .{ .call = "rt_nil" }, .{ .store = .{} }, b.c(roots + 8) });
    try start.appendSlice(ar, built);
    try start.append(ar, .{ .store = .{} });
    // Root 0's address before any collection.
    try start.appendSlice(ar, &.{ b.c(roots + 12), b.c(roots), .{ .load = .{} }, .{ .store = .{} } });

    var body: std.ArrayListUnmanaged(ast.Instr) = .empty;
    try body.appendSlice(ar, fresh);
    try body.appendSlice(ar, &.{ .drop, b.c(roots + 4) });
    try body.appendSlice(ar, fresh);
    try body.appendSlice(ar, &.{ b.c(roots + 4), .{ .load = .{} }, .{ .call = "rt_cons" }, .{ .store = .{} } });
    if (run == .exhaust) {
        // Every list kept, until the memory runs out; its newest element
        // checked every twentieth turn.
        var check: std.ArrayListUnmanaged(ast.Instr) = .empty;
        try check.appendSlice(ar, &.{ b.c(roots + 4), .{ .load = .{} }, .{ .call = rt_hd } });
        try check.appendSlice(ar, fresh);
        try check.appendSlice(ar, &.{ .{ .call = "rt_eqx" }, b.op("eqz"), b.when(damaged) });
        try body.appendSlice(ar, &.{ .{ .local_get = "i" }, b.c(20), b.op("rem_u"), b.op("eqz"), b.when(check.items) });
    } else {
        try body.appendSlice(ar, &.{ .{ .local_get = "i" }, b.c(10), b.op("rem_u"), b.op("eqz"), b.when(&.{ b.c(roots + 4), .{ .call = "rt_nil" }, .{ .store = .{} } }) });
    }
    // A minor collection every 50 turns, a major one every 300.
    try body.appendSlice(ar, &.{
        .{ .local_get = "i" },                                                                                                            b.c(50),                                       b.op("rem_u"), b.op("eqz"),
        b.when(&.{ b.c(roots), b.c(3), .{ .local_get = "i" }, b.c(300), b.op("rem_u"), b.op("eqz"), .{ .call = "__std_heap_collect" } }), .{ .local_get = "i" },                         b.c(1),        b.op("add"),
        .{ .local_tee = "i" },                                                                                                            b.c(if (run == .exhaust) 1_000_000 else 2003), b.op("lt_u"),  .{ .br_if = "turn" },
    });
    try start.append(ar, .{ .block = .{ .kind = .loop, .label = "turn", .body = b.seq(body.items) } });
    // Memory never ran out: the exhaustion run says so by a damaged answer's trap.
    if (run == .exhaust) try start.appendSlice(ar, damaged);
    // Root 0 moved, and each kept term equals a fresh decode.
    try start.appendSlice(ar, &.{ b.c(roots), .{ .load = .{} }, b.c(roots + 12), .{ .load = .{} }, b.op("eq"), b.when(&.{.@"unreachable"}) });
    try start.appendSlice(ar, &.{ b.c(roots), .{ .load = .{} } });
    try start.appendSlice(ar, fresh);
    try start.appendSlice(ar, &.{ .{ .call = "rt_eqx" }, b.op("eqz"), b.when(&.{.@"unreachable"}) });
    try start.appendSlice(ar, &.{ .{ .local_get = "key" }, .{ .call = "rt_erlang_get" } });
    try start.appendSlice(ar, fresh);
    try start.appendSlice(ar, &.{ .{ .call = "rt_eqx" }, b.op("eqz"), b.when(&.{.@"unreachable"}) });
    try start.appendSlice(ar, &.{ b.c(roots + 4), .{ .load = .{} }, .{ .call = rt_hd } });
    try start.appendSlice(ar, fresh);
    try start.appendSlice(ar, &.{ .{ .call = "rt_eqx" }, b.op("eqz"), b.when(&.{.@"unreachable"}) });
    try start.appendSlice(ar, &.{ b.c(roots + 8), .{ .load = .{} } });
    try start.appendSlice(ar, built);
    try start.appendSlice(ar, &.{ .{ .call = "rt_eqx" }, b.op("eqz"), b.when(&.{.@"unreachable"}) });

    var items: std.ArrayListUnmanaged(ast.Item) = .empty;
    try items.append(ar, .{ .memory = .{ .@"export" = "memory", .min_pages = pages, .max_pages = if (run == .exhaust) pages + 16 else null } });
    try items.appendSlice(ar, l.items);
    try items.append(ar, .{ .data = .{ .offset = etf_at, .len_prefix = null, .bytes = &heap_etf } });
    try items.append(ar, .{ .data = .{ .offset = key_at, .len_prefix = null, .bytes = "key" } });
    try items.append(ar, .{ .data = .{ .offset = hello_at, .len_prefix = null, .bytes = "hello heap" } });
    try items.append(ar, .{ .func = .{
        .name = "_start",
        .exports = &.{"_start"},
        .locals = &.{&.{ .{ .name = "i", .ty = .i32 }, .{ .name = "key", .ty = .i32 }, .{ .name = "bb", .ty = .i32 } }},
        .body = b.seq(start.items),
    } });
    const m: ast.Module = .{ .items = items.items };
    try ast.validateModule(m);
    return binary.encodeModule(ar, m);
}

test "wat: std-wasm ---- translated code's terms on a process heap survive its collections" {
    const runtime = @import("../runtime.zig");
    const a = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const kept = try runtime.executeWat(a, "", try termHeapModule(arena.allocator(), .kept), "main", std.testing.io);
    defer a.free(kept);
    try std.testing.expectEqualStrings("", kept);
}

// Decision 448 (4), 144 B-30 box 5 — a run that exhausts memory traps, never
// answers with damaged data: the same terms kept on a heap whose memory may
// grow 16 pages, collected as they grow, their newest checked as it goes,
// until `memory.grow` is refused — `unreachable` (the heap's face), never the
// damaged-value trap (`integer divide by zero`).
test "wat: std-wasm ---- a heap that exhausts its memory traps, never answers with damaged data" {
    const runtime = @import("../runtime.zig");
    const a = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const out = try runtime.executeWat(a, "", try termHeapModule(arena.allocator(), .exhaust), "main", std.testing.io);
    defer a.free(out);
    try std.testing.expect(std.mem.indexOf(u8, out, "unreachable") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "divide by zero") == null);
}

// ── front 164 s2 P2: the shapes a WasmGC module holds as references ──────────────
//
// Each program is lowered with records, variants, arrays, tuples, optionals and
// `@Result`s as GC types (`(rec`), and its RUN LOG is the language's own answer.

test "wat: gc ---- a record, its fields, a nested record and its structural equality" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32)
        \\type Person(name: string, age: i32, tall: bool, h: f64, home: Point)
        \\
        \\fn sum(p: Point) -> i32 {
        \\    return p.x + p.y;
        \\}
        \\
        \\fn greet(p: Person) -> string {
        \\    return "hi " + p.name;
        \\}
        \\
        \\pub fn main() -> void {
        \\    val p = Point(x: 1, y: 2);
        \\    print(sum(p));
        \\    print(p);
        \\    val q = Person(name: "Ana", age: 30, tall: true, h: 1.75, home: p);
        \\    print(greet(q));
        \\    print(q);
        \\    print(q.home.y);
        \\    print(q.h);
        \\    print(q.tall);
        \\    print(p == Point(x: 1, y: 2));
        \\    print(p == Point(x: 1, y: 3));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- a record's methods answering a number, a string and a record" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Counter(n: i32, label: string) {
        \\    pub fn bump(self: Self) -> i32 {
        \\        return self.n + 1;
        \\    }
        \\    pub fn name(self: Self) -> string {
        \\        return self.label + "!";
        \\    }
        \\    pub fn scaled(self: Self, k: i32) -> i32 {
        \\        return self.n * k;
        \\    }
        \\    pub fn twice(self: Self) -> Counter {
        \\        return Counter(n: self.n * 2, label: self.label);
        \\    }
        \\}
        \\
        \\pub fn main() -> void {
        \\    val c = Counter(n: 4, label: "ctr");
        \\    print(c.bump());
        \\    print(c.name());
        \\    print(c.scaled(3));
        \\    print(c.twice());
        \\    print(c.twice().twice().n);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- an enum with payloads, a case over its variants, its printed text and its equality" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(r: i32),
        \\    Rect(w: i32, h: i32),
        \\    Dot,
        \\}
        \\
        \\fn area(s: Shape) -> i32 {
        \\    return case s {
        \\        Circle(r) -> r * r * 3;
        \\        Rect(w, h) -> w * h;
        \\        Dot -> 0;
        \\    };
        \\}
        \\
        \\fn name(s: Shape) -> string {
        \\    return case s {
        \\        Circle -> "circle";
        \\        Rect -> "rect";
        \\        Dot -> "dot";
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    val a = Shape.Circle(r: 2);
        \\    val b = Shape.Rect(w: 3, h: 4);
        \\    print(area(a));
        \\    print(area(b));
        \\    print(area(Shape.Dot));
        \\    print(name(b));
        \\    print(a);
        \\    print(b);
        \\    print(Shape.Dot);
        \\    print(a == Shape.Circle(r: 2));
        \\    print(a == b);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- an enum with float payloads inside a record, an all-unit enum field" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\}
        \\
        \\type Color { Red, Green, Blue }
        \\
        \\type Item(shape: Shape, color: Color, label: string)
        \\
        \\fn area(shape: Shape) -> f64 {
        \\    return case shape {
        \\        Circle(radius) -> radius * radius * 3.14;
        \\        Square(side) -> side * side;
        \\    };
        \\}
        \\
        \\fn warm(c: Color) -> bool {
        \\    return case c {
        \\        Red -> true;
        \\        Green -> false;
        \\        Blue -> false;
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(area(Shape.Square(side: 2.0)));
        \\    print(area(Shape.Circle(radius: 1.0)));
        \\    val it = Item(shape: Shape.Square(side: 3.0), color: Color.Green, label: "x");
        \\    print(it);
        \\    print(warm(it.color));
        \\    print(it.color);
        \\    print(area(it.shape));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- arrays: a literal, an index, a loop, push, length and equality" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn total(xs: i32[]) -> i32 {
        \\    var sum = 0;
        \\    for (xs) { x -> sum = sum + x; }
        \\    return sum;
        \\}
        \\
        \\fn longest(names: string[]) -> i32 {
        \\    var best = 0;
        \\    for (names) { n -> if (n.length() > best) { best = n.length(); } }
        \\    return best;
        \\}
        \\
        \\pub fn main() -> void {
        \\    val xs = [3, 1, 2];
        \\    print(xs);
        \\    print(total(xs));
        \\    print(xs[1]);
        \\    print(xs.length);
        \\    print(xs.length());
        \\    var ys = [10, 20];
        \\    ys.push(30);
        \\    print(ys);
        \\    val names = ["ann", "bobby"];
        \\    print(names);
        \\    print(longest(names));
        \\    print(names[1]);
        \\    val fs = [1.5, 2.5];
        \\    print(fs);
        \\    print(xs == [3, 1, 2]);
        \\    print(xs == ys);
        \\    val e: i32[] = [];
        \\    print(e.length());
        \\    print(e);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- arrays: the operations that were std-wasm's, now the module's" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn main() -> void {
        \\    val xs = [3, 1, 2];
        \\    print(xs.reverse());
        \\    print(xs.slice(1));
        \\    print(xs.slice(0, 2));
        \\    print(xs.take(2));
        \\    print(xs.drop(1));
        \\    print(xs.rest());
        \\    print(xs.append([9, 8]));
        \\    print(xs.prepend(7));
        \\    print(xs.indexOf(2));
        \\    print(xs.indexOf(5));
        \\    print(xs.lastIndexOf(1));
        \\    print(xs.contains(1));
        \\    print(xs.contains(8));
        \\    print(xs.join("-"));
        \\    val ws = ["a", "b", "c"];
        \\    print(ws.reverse());
        \\    print(ws.join(", "));
        \\    print(ws.indexOf("c"));
        \\    print(ws.contains("z"));
        \\    val ns = [-5, 0, 123];
        \\    print(ns.join("|"));
        \\    val fs = [1.5, 2.5];
        \\    print(fs.reverse());
        \\    print(fs.indexOf(2.5));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- tuples: their elements, their printed text, an array of them and of records" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Pair(a: i32, b: string)
        \\
        \\pub fn main() -> void {
        \\    val t = #(1, "x", 2.5, true);
        \\    print(t);
        \\    print(t.0);
        \\    print(t.1);
        \\    print(t._2);
        \\    print(t._3);
        \\    val u = #(1, "x", 2.5, true);
        \\    print(t == u);
        \\    val rs = [Pair(a: 1, b: "p"), Pair(a: 2, b: "q")];
        \\    print(rs);
        \\    for (rs) { r -> print(r.b); }
        \\    val ts = [#(1, "a"), #(2, "b")];
        \\    print(ts);
        \\    print(ts[0]);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- optionals: at, null, a boxed scalar, ??, a narrowing binding and null compares" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Box(n: ?i32, s: ?string)
        \\
        \\fn first(xs: i32[]) -> ?i32 {
        \\    return xs.at(0);
        \\}
        \\
        \\fn pick(flag: bool) -> ?i32 {
        \\    if (flag) {
        \\        return 5;
        \\    }
        \\    return null;
        \\}
        \\
        \\fn show(o: ?i32) -> i32 {
        \\    return o ?? -1;
        \\}
        \\
        \\pub fn main() -> void {
        \\    val xs = [7, 8];
        \\    print(xs.at(1));
        \\    print(xs.at(5));
        \\    print(first(xs));
        \\    print(pick(true));
        \\    print(pick(false));
        \\    print(show(pick(true)));
        \\    print(show(pick(false)));
        \\    val b = Box(n: 3, s: "x");
        \\    print(b);
        \\    val c = Box(n: null, s: null);
        \\    print(c);
        \\    if (b.n) { v -> print(v + 1); }
        \\    val words = ["a", "b"];
        \\    print(words.at(0));
        \\    print(words.at(9));
        \\    print(words[1] ?? "z");
        \\    print(xs[0]);
        \\    print(b.n == null);
        \\    print(c.n == null);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- optionals: a field read through ?. and an optional record field" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type User(name: string, age: i32, next: ?User)
        \\
        \\fn nameOf(u: ?User) -> ?string {
        \\    return u?.name;
        \\}
        \\
        \\fn ageOf(u: ?User) -> ?i32 {
        \\    return u?.age;
        \\}
        \\
        \\pub fn main() -> void {
        \\    val a = User(name: "ann", age: 3, next: null);
        \\    val b = User(name: "bob", age: 4, next: a);
        \\    print(nameOf(a));
        \\    print(nameOf(null));
        \\    print(ageOf(b));
        \\    print(b.next?.name);
        \\    print(a.next?.name);
        \\    print(b.next?.age ?? 0);
        \\    print(a == b);
        \\    print(b.next == a);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- a @Result: its constructors, a case over it, try and unwrapOr" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn half(n: i32) -> Result<i32, string> {
        \\    if (n % 2 == 0) {
        \\        return n / 2;
        \\    }
        \\    throw "odd";
        \\}
        \\
        \\fn twice(n: i32) -> Result<i32, string> {
        \\    val h = try half(n);
        \\    return try half(h);
        \\}
        \\
        \\fn show(r: Result<i32, string>) -> string {
        \\    return case r {
        \\        Ok(v) -> "ok " + v;
        \\        Error(e) -> "err " + e;
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(half(4));
        \\    print(half(3));
        \\    print(twice(8));
        \\    print(twice(6));
        \\    print(show(half(10)));
        \\    print(show(half(7)));
        \\    print(half(6).unwrapOr(0));
        \\    print(half(5).unwrapOr(0));
        \\    print(half(6).isOk());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- bytes, and the string arrays and optional strings std-wasm answers" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn main() -> void {
        \\    val b = bytes.fromUtf8("hello");
        \\    print(b.length());
        \\    print(b.slice(1, 3).length());
        \\    val c = b.concat(bytes.fromUtf8("!"));
        \\    print(c.length());
        \\    print(b == bytes.fromUtf8("hello"));
        \\    val r = b.toUtf8();
        \\    print(r);
        \\    val parts = "a,b,c".split(",");
        \\    print(parts);
        \\    print("hello".at(1));
        \\    print("hello".at(9));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- assert and panic messages, a folded comptime string val" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val GREETING = comptime "hi";
        \\
        \\fn check(n: i32) -> i32 {
        \\    assert n > 0, "n must be positive";
        \\    return n;
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(GREETING);
        \\    print(check(3));
        \\    if (check(1) < 0) {
        \\        panic("negative");
        \\    }
        \\    print("done");
        \\}
        \\
        \\import {io.terminal.print, failure.panic} from "std";
    );
}

test "wat: gc ---- a linked module no function of the program names does not keep it in linear memory" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import {collections} from "std";
        \\
        \\pub fn main() -> void {
        \\    print("x");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// Shapes that sent a module to linear memory, each now in GC form: an `if`
// with an empty array arm, a `case` answering apart from its function, `try`
// over a `Result` of a tuple, a string method named like a free function of
// the module, `fill` with a value of another class, `?.` over an enum's method.
test "wat: gc ---- an empty array arm, a case of its own type, try over a tuple, fill and ?. over an enum method" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Val {
        \\    Num(n: i32),
        \\    Text(s: string),
        \\
        \\    fn str(self: Self) -> string {
        \\        return case self {
        \\            Text(s: t) -> t;
        \\            _ -> "";
        \\        };
        \\    }
        \\}
        \\
        \\fn find(kind: i32) -> ?Val {
        \\    if (kind == 1) return Val.Text(s: "a");
        \\    if (kind == 2) return Val.Num(n: 40);
        \\    return null;
        \\}
        \\
        \\fn contains(xs: string[], x: string) -> Result<void, string> {
        \\    if (xs.indexOf(x) < 0) throw "missing";
        \\    return;
        \\}
        \\
        \\fn pair(s: string) -> Result<#(string, string), string> {
        \\    if (s == "") throw "empty";
        \\    return #(s, s.toUpper());
        \\}
        \\
        \\fn label(s: string, loud: bool) -> string {
        \\    val mark = case loud {
        \\        true -> 1;
        \\        false -> 0;
        \\    };
        \\    val parts = if (s == "") [] else [s, s];
        \\    return parts.join("-") + mark.toString();
        \\}
        \\
        \\fn verdict(r: Result<void, string>) -> string {
        \\    return case r {
        \\        Ok(_) -> "ok";
        \\        Error(e) -> e;
        \\    };
        \\}
        \\
        \\fn both(s: string) -> Result<string, string> {
        \\    val p = try pair(s);
        \\    return p._0 + p._1;
        \\}
        \\
        \\fn text(r: Result<string, string>) -> string {
        \\    return case r {
        \\        Ok(v) -> v;
        \\        Error(e) -> e;
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(label("ab", true));
        \\    print(label("", false));
        \\    print("abc".contains("b"));
        \\    print(verdict(contains(["a"], "b")));
        \\    print(text(both("a")));
        \\    print(text(both("")));
        \\    print([1, 2, 3].fill("z"));
        \\    print(find(1)?.str() ?? "none");
        \\    print(find(3)?.str() ?? "none");
        \\    print(Val.Num(n: 2).str().length);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// `indexOf`, `lastIndexOf` and `contains` over an array in a type-parameter
// slot (std's `asserts.includes`): a number, a string or a bool by value.
test "wat: gc ---- indexOf, lastIndexOf and contains over a generic array" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn at<T>(xs: T[], x: T) -> i32 {
        \\    return xs.indexOf(x);
        \\}
        \\
        \\fn lastAt<T>(xs: T[], x: T) -> i32 {
        \\    return xs.lastIndexOf(x);
        \\}
        \\
        \\fn holds<T>(xs: T[], x: T) -> bool {
        \\    return xs.contains(x);
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(asserts.includes([1, 2], 2).isOk());
        \\    print(asserts.includes([1, 2], 3).isOk());
        \\    print(at([2.5, 3.5], 3.5));
        \\    print(at(["a", "b"], "b"));
        \\    print(lastAt([1, 2, 1], 1));
        \\    print(lastAt([true, false], true));
        \\    print(holds(["x"], "y"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
        \\import {testing.asserts} from "std";
    );
}

// `r.unwrapOr(d)` answering an array (std's `querystring` tests), a lambda
// written in a generic function (std's `functions`), and a call through the
// function value a generic function answers, each in GC form.
test "wat: gc ---- unwrapOr's array, a lambda in a generic fn and a call through what compose answers" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn parse(s: string) -> Result<array<#(string, string)>, string> {
        \\    if (s == "") throw "empty";
        \\    return [#(s, s.toUpper())];
        \\}
        \\
        \\fn pairsOf(r: Result<array<#(string, string)>, string>) -> string {
        \\    val none: array<#(string, string)> = [];
        \\    return r.unwrapOr(none).map({ p -> [p._0, "=>", p._1].join("") }).join("|");
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(pairsOf(parse("a")));
        \\    print(pairsOf(parse("")).length);
        \\    val double: fn(i32) -> i32 = { n -> n * 2 };
        \\    val addOne: fn(i32) -> i32 = { n -> n + 1 };
        \\    print(functions.compose(double, addOne)(3));
        \\    val shout: fn(string) -> string = { s -> s + "!" };
        \\    print(functions.compose(shout, shout)("hi"));
        \\    val sub: fn(i32, i32) -> i32 = { a, b -> a - b };
        \\    print(functions.flip(sub)(3, 10));
        \\    print(functions.constant(42)("x"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
        \\import {functions} from "std";
    );
}

// ── front 164 s2 P2b: unknown, generic declarations, the array operations, generators ──
//
// Each program is lowered as a WasmGC module (`(rec`), its RUN LOG the language's own answer.

test "wat: gc ---- an unknown boxed by its value, its is tests, narrowing, equality, printing and a union array" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn describe(x: unknown) -> string {
        \\    return case x {
        \\        i32 { n ->
        \\            "number " + n.toString()
        \\        }
        \\        string { s ->
        \\            "text " + s
        \\        }
        \\        _ {
        \\            "other"
        \\        }
        \\    };
        \\}
        \\
        \\fn show(x: unknown) -> string {
        \\    if (x is i32) return "i32";
        \\    if (x is f64) return "f64";
        \\    if (x is string) return "string";
        \\    if (x is bool) return "bool";
        \\    return "other";
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(describe(3));
        \\    print(describe("a"));
        \\    print(describe(true));
        \\    print(show(1), show(2.5), show("s"), show(false));
        \\    val two: unknown = 2.0;
        \\    print(two == 2, two == 3);
        \\    val t: unknown = "hi";
        \\    print(t == "hi", t);
        \\    val b: unknown = true;
        \\    print(b);
        \\    print(300 is i8, 100 is i8, 2 is f64);
        \\    val xs = [1, "a", true];
        \\    print(xs);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- a generic record and enum as one struct per declaration, boxed at construction and unboxed at the read" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Box<T>(value: T) {
        \\    pub fn get(self: Self<T>) -> T {
        \\        return self.value;
        \\    }
        \\}
        \\
        \\type Maybe<T> {
        \\    Some(value: T),
        \\    None,
        \\}
        \\
        \\fn orZero(m: Maybe<i32>) -> i32 {
        \\    return case m {
        \\        Maybe.Some(value: v) -> v;
        \\        Maybe.None -> 0;
        \\    };
        \\}
        \\
        \\fn ident<T>(x: T) -> T {
        \\    return x;
        \\}
        \\
        \\pub fn main() -> void {
        \\    val b = Box(value: 41);
        \\    print(b.value + 1);
        \\    print(b.get());
        \\    print(Box(value: "s"));
        \\    print(Box(value: true));
        \\    print(orZero(Maybe.Some(value: 7)), orZero(Maybe.None));
        \\    print(Maybe.Some(value: "x"));
        \\    print(ident(3) + 1);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- unique, flatten, chunked, sliding, zip and the array walks with a closure written at the call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn main() -> void {
        \\    val xs = [3, 1, 3, 2, 1];
        \\    print(xs.unique());
        \\    print(["a", "b", "a"].unique());
        \\    print([[1, 2], [3]].flatten());
        \\    print(xs.chunked(2));
        \\    print(xs.sliding(3));
        \\    print(xs.map({ x -> x * 2 }));
        \\    print(xs.filter({ x -> x > 1 }));
        \\    print(xs.fold(0, { acc, x -> acc + x }));
        \\    print(xs.any({ x -> x == 2 }), xs.all({ x -> x > 0 }), xs.count({ x -> x == 3 }));
        \\    print(["a", "bb"].map({ s -> s.length() }));
        \\    print(xs.zip(["a", "b"]));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "wat: gc ---- an iterator fn collecting its yields, and a Result's map and flatMap" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\iter fn evens(n: i32) -> Iter<i32> {
        \\    var i = 0;
        \\    while (i < n) {
        \\        if (i % 2 == 0) yield i;
        \\        i = i + 1;
        \\    }
        \\}
        \\
        \\fn parse(s: string) -> Result<i32, string> {
        \\    if (s == "") throw "empty";
        \\    return s.length();
        \\}
        \\
        \\pub fn main() -> void {
        \\    for (evens(7)) { v -> print(v); }
        \\    print(parse("abc").map({ n -> n * 10 }).unwrapOr(-1));
        \\    print(parse("").map({ n -> n * 10 }).unwrapOr(-1));
        \\    print(parse("ab").flatMap({ n -> parse("xyz") }).unwrapOr(-1));
        \\    print(parse("ab").flatMap({ n -> parse("") }).isError());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// Decision 1008 (5), 1034 (8) — the harness's in-process run keeps its
// compiled code under the cache directory it is given, as
// `<sha256>.cwasm`, never in `~/.cache/wasmtime`.
test "wat: executeWatIn ---- the compiled module sits under the given directory" {
    const runtime = @import("../runtime.zig");
    const test_scratch = @import("test_scratch");
    const a = std.testing.allocator;
    const io = std.testing.io;
    var rand: [8]u8 = undefined;
    io.random(&rand);
    var name_buf: [32]u8 = undefined;
    const name = try std.fmt.bufPrint(&name_buf, "cachedir{x}", .{std.mem.readInt(u64, &rand, .little)});
    test_scratch.remove(io, "wasmtime-cache-dir");
    defer test_scratch.remove(io, "wasmtime-cache-dir");
    const dir = test_scratch.path(io, "wasmtime-cache-dir/.botopinkbuild/cache/wasmtime");
    // The name in the text: bytes no other test loaded in this process.
    const text = try std.fmt.allocPrint(a, "(module (func (export \"_start\")) (func ${s}))", .{name});
    defer a.free(text);
    const out = try runtime.executeWatIn(a, text, null, name, dir, io);
    defer a.free(out);
    try std.testing.expectEqualStrings("", out);
    var d = try std.Io.Dir.cwd().openDir(io, dir, .{ .iterate = true });
    defer d.close(io);
    var n: usize = 0;
    var it = d.iterate();
    while (try it.next(io)) |e| if (std.mem.endsWith(u8, e.name, ".cwasm")) {
        n += 1;
    };
    try std.testing.expectEqual(@as(usize, 1), n);
}

// 1034 (1) — the check `backend_exec.sh` made with `wasmtime --invoke main`:
// a wasm build's core module runs on its own and its `main` export answers
// what `main` returns — 55 for `sumTo(10, 0)` — now through the runner.
test "wat: runner ---- a core module's main export invoked answers 55" {
    const runner = @import("../wat/runner.zig");
    const a = std.testing.allocator;
    var outputs = try h.generate(a, &.{.{ .path = "", .source =
        \\fn sumTo(n: i32, acc: i32) -> i32 {
        \\    if (n == 0) return acc;
        \\    return sumTo(n - 1, acc + n);
        \\}
        \\
        \\pub fn main() -> i32 {
        \\    return sumTo(10, 0);
        \\}
    }}, std.testing.io, h.configs[3]);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    const bytes = for (outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "") or std.mem.eql(u8, o.name, "main")) break o.result.wasm orelse return error.ModuleDidNotCompile;
    } else return error.ModuleDidNotCompile;
    var failure: ?[]u8 = null;
    const m = (try runner.load(a, std.testing.io, null, bytes, .module, false, &failure)) orelse {
        std.debug.print("\n{s}\n", .{failure.?});
        a.free(failure.?);
        return error.ModuleDidNotCompile;
    };
    defer m.deinit();
    // The runtime core and the std units it imports, defined first.
    var ar = std.heap.ArenaAllocator.init(a);
    defer ar.deinit();
    const pre = try @import("../runtime.zig").wasmPreloads(ar.allocator(), bytes);
    var units: std.ArrayListUnmanaged(runner.Unit) = .empty;
    defer units.deinit(a);
    defer for (units.items) |u| @import("../wat/engine.zig").c.wasmtime_module_delete(u.module);
    for (pre) |u| {
        const um = (try runner.load(a, std.testing.io, null, u.code, .module, false, &failure)) orelse return error.ModuleDidNotCompile;
        try units.append(a, .{ .name = u.name, .module = um.module });
    }
    const got = try runner.invokeCore(a, m.module, units.items, "main", .{ .stdout = .capture, .stderr = .capture });
    defer got.outcome.deinit(a);
    if (got.outcome.trap) |t| std.debug.print("\ntrap: {s}\n", .{t});
    try std.testing.expectEqual(@as(?i64, 55), got.value);
}

// Decision 1021 (10) — the GC lowering's gaps fixed in the lowering itself:
// each program here built to a WasmGC module (no linear fallback) answers as
// on erlang (its cell under `conformance/modules/decisions-taken/
// wasm_unit_per_module_linked-1021/cases/`).

test "wat: decision 1021 (10) ---- a catch binder is the Result's error payload in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\pub type Fault(code: i32, why: string)
        \\
        \\fn parse(n: i32) -> Result<i32, string> {
        \\    if (n < 0) throw "negative";
        \\    return n * 10;
        \\}
        \\
        \\fn check(n: i32) -> Result<string, Fault> {
        \\    if (n > 5) throw Fault(code: n, why: "too big");
        \\    return "fine";
        \\}
        \\
        \\pub fn main() -> void {
        \\    val a = try parse(3) catch { e ->
        \\        print("never " + e);
        \\        0
        \\    };
        \\    val b = try parse(-1) catch { e ->
        \\        print("caught " + e);
        \\        7
        \\    };
        \\    print(a);
        \\    print(b);
        \\    print(try check(2) catch { f -> f.why });
        \\    print(try check(9) catch { f -> f.why + " " + f.code.toString() });
        \\}
    , "caught negative\n30\n7\nfine\ntoo big 9\n");
}

test "wat: decision 1021 (10) ---- `try f() catch null` into a declared optional is absent on failure in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\fn parse(n: i32) -> Result<i32, string> {
        \\    if (n < 0) throw "negative";
        \\    return n * 10;
        \\}
        \\
        \\fn word(n: i32) -> Result<string, string> {
        \\    if (n < 0) throw "negative";
        \\    return "w" + n.toString();
        \\}
        \\
        \\pub fn main() -> void {
        \\    val a: ?i32 = try parse(3) catch null;
        \\    val b: ?i32 = try parse(-3) catch null;
        \\    val c: ?string = try word(2) catch null;
        \\    val d: ?string = try word(-2) catch null;
        \\    print(a ?? -1);
        \\    print(b ?? -1);
        \\    print(c ?? "none");
        \\    print(d ?? "none");
        \\}
    , "30\n-1\nw2\nnone\n");
}

test "wat: decision 1021 (10) ---- an if answering null or a value is the optional in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\pub type Point(x: i32, y: i32)
        \\
        \\fn pick(c: bool) -> ?i32 {
        \\    return if (c) 0 else null;
        \\}
        \\
        \\fn grade(n: i32) -> ?i32 {
        \\    return if (n > 10) 2 else if (n > 5) 1 else null;
        \\}
        \\
        \\fn half(c: bool) -> ?f64 {
        \\    return if (c) 0.5 else null;
        \\}
        \\
        \\fn flag(n: i32) -> ?bool {
        \\    return if (n == 0) null else n > 0;
        \\}
        \\
        \\fn at(c: bool) -> ?Point {
        \\    return if (c) Point(x: 1, y: 2) else null;
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(pick(true) ?? -1);
        \\    print(pick(false) ?? -1);
        \\    print(grade(20) ?? -1);
        \\    print(grade(7) ?? -1);
        \\    print(grade(1) ?? -1);
        \\    print(half(true) ?? -1.0);
        \\    print(half(false) ?? -1.0);
        \\    print(flag(3) ?? false);
        \\    print(flag(-3) ?? true);
        \\    print(flag(0) ?? true);
        \\    val n: ?i32 = if (pick(true) != null) {
        \\        print("arm");
        \\        5;
        \\    } else null;
        \\    print(n ?? -1);
        \\    print(at(true)?.x ?? -1);
        \\    print(at(false)?.y ?? -1);
        \\}
    , "0\n-1\n2\n1\n-1\n0.5\n-1.0\ntrue\nfalse\ntrue\narm\n5\n1\n-1\n");
}

test "wat: decision 1021 (10) ---- a bigint is a byte array in the GC lowering, marshalled to std-wasm" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\type Account(owner: string, balance: bigint)
        \\
        \\fn grow(n: i64) -> bigint {
        \\    var acc = 1n;
        \\    var i = 2l;
        \\    while (i <= n) {
        \\        acc = acc * bigint.of(i);
        \\        i += 1l;
        \\    }
        \\    return acc;
        \\}
        \\
        \\fn sign(x: bigint) -> string {
        \\    return case x {
        \\        0n -> "zero";
        \\        _ -> if (x < 0n) "negative" else "positive";
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    val big = 123456789012345678901234567890n;
        \\    print(big + 1n);
        \\    print(big - big - 7n);
        \\    print(-big * 3n);
        \\    print(big / 1000n);
        \\    print(big % 1000n);
        \\    print(grow(25));
        \\    print(bigint.parse("-99999999999999999999").unwrapOr(0n));
        \\    print(bigint.parse("x1").unwrapOr(-1n));
        \\    print(sign(0n));
        \\    print(sign(-5n));
        \\    print(big > 1n);
        \\    print(big == 123456789012345678901234567890n);
        \\    val xs: bigint[] = [1n, big];
        \\    print(xs);
        \\    print(xs[1] == big);
        \\    val maybe: ?bigint = if (big > 0n) big else null;
        \\    print(maybe);
        \\    print(maybe == big);
        \\    val a0 = Account(owner: "Ana", balance: 10n);
        \\    val a = Account(..a0, balance: a0.balance + 90000000000000000000n);
        \\    print(a.balance);
        \\    print(a);
        \\    print("total " + big.toString());
        \\    print(bigint.of(42l).toI64() + 1l);
        \\}
    , "123456789012345678901234567891\n-7\n-370370367037037036703703703670\n123456789012345678901234567\n890\n15511210043330985984000000\n-99999999999999999999\n-1\nzero\nnegative\ntrue\ntrue\n[1, 123456789012345678901234567890]\ntrue\n123456789012345678901234567890\ntrue\n90000000000000000010\nAccount(owner: \"Ana\", balance: 90000000000000000010)\ntotal 123456789012345678901234567890\n43\n");
}

test "wat: decision 1031 (2) ---- a bigint in an unknown slot is boxed in $box_big, printed and compared by value" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\type Box<T>(value: T)
        \\
        \\fn show(a: i32 | bigint) -> void {
        \\    print(a);
        \\}
        \\
        \\fn same(a: i32 | bigint, b: i32 | bigint) -> bool {
        \\    return a == b;
        \\}
        \\
        \\pub fn main() -> void {
        \\    val big = 123456789012345678901234567890n;
        \\    show(5);
        \\    show(big * 2n);
        \\    print(same(big, 123456789012345678901234567890n));
        \\    print(same(big, 5));
        \\    print(same(5, 5));
        \\    val b = Box(value: big + 1n);
        \\    print(b);
        \\    print(b.value + 1n);
        \\    print(b == Box(value: 123456789012345678901234567891n));
        \\    print(b == Box(value: 1n));
        \\}
    , "5\n246913578024691357802469135780\ntrue\nfalse\ntrue\nBox(value: 123456789012345678901234567891)\n123456789012345678901234567892\ntrue\nfalse\n");
}

test "wat: decision 1021 (10) ---- string ordering by bytes in the GC lowering ($__str_cmp)" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\fn first(a: string, b: string) -> string {
        \\    return if (a < b) a else b;
        \\}
        \\
        \\pub fn main() -> void {
        \\    print("apple" < "banana");
        \\    print("b" > "a");
        \\    print("abc" <= "abd");
        \\    print("abc" >= "abcd");
        \\    print(first("pear", "fig"));
        \\    print(first("ab", "abc"));
        \\    print("é" > "z");
        \\    val w = "kiwi";
        \\    if (w > "date") print("after");
        \\}
    , "true\ntrue\ntrue\nfalse\nfig\nab\ntrue\nafter\n");
}

test "wat: decision 1021 (10) ---- a case arm that assigns runs as a statement in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\fn parse(n: i32) -> Result<string, string> {
        \\    if (n < 0) throw "negative";
        \\    return "n" + n.toString();
        \\}
        \\
        \\pub fn main() -> void {
        \\    var kept = "none";
        \\    case parse(4) {
        \\        Ok(s) -> kept = s;
        \\        Error(e) -> kept = e;
        \\    }
        \\    print(kept);
        \\    case parse(-4) {
        \\        Ok(s) -> kept = s;
        \\        Error(e) -> kept = e;
        \\    }
        \\    print(kept);
        \\}
    , "n4\nnegative\n");
}

// Decision 1027 — the same-package half of the cell `wasm_same_shape_types_distinct` (its
// package-qualified half needs a dependency, its conformance case's): each declared group's
// brand keeps two declarations of one shape two types.
test "wat: decision 1027 ---- declarations of one shape stay distinct types (the brand)" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\type Person(name: string, age: i32)
        \\
        \\type Vec(name: string, age: i32)
        \\
        \\type Box<T>(value: T)
        \\
        \\type Maybe<T> {
        \\    None,
        \\    Some(value: T),
        \\}
        \\
        \\fn kind(v: unknown) -> string {
        \\    val p = if (v is Person) "person" else "-";
        \\    val q = if (v is Vec) "vec" else "-";
        \\    val b = if (v is Box<unknown>) "box" else "-";
        \\    val s = if (v is Maybe<unknown>) "maybe" else "-";
        \\    return p + " " + q + " " + b + " " + s;
        \\}
        \\
        \\fn label(v: unknown) -> string {
        \\    return case v {
        \\        Person { x ->
        \\            "a person"
        \\        }
        \\        Vec { x ->
        \\            "a vec"
        \\        }
        \\        Box<unknown> { x ->
        \\            "a box"
        \\        }
        \\        _ {
        \\            "other"
        \\        }
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    val mine: unknown = Person(name: "Ana", age: 30);
        \\    val vec: unknown = Vec(name: "Ana", age: 30);
        \\    print(kind(mine));
        \\    print(kind(vec));
        \\    print(kind(Box(value: 1)));
        \\    print(kind(Maybe.Some(value: 1)));
        \\    print(label(mine));
        \\    print(label(vec));
        \\    print(label(Box(value: 1)));
        \\    print(label(Maybe.Some(value: 1)));
        \\    print(mine == vec);
        \\    print(mine == Person(name: "Ana", age: 30));
        \\    print(mine);
        \\    print(vec);
        \\}
    , "person - - -\n- vec - -\n- - box -\n- - - maybe\na person\na vec\na box\nother\nfalse\ntrue\nPerson(name: \"Ana\", age: 30)\nVec(name: \"Ana\", age: 30)\n");
}

test "wat: decision 1021 (10) ---- a ?. read of an array, a tuple or an optional array field takes its payload from the field's type, and the absent arm of ?.[k] is null in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\type Field(name: string)
        \\
        \\type Form(fields: ?Field[], tags: string[], range: #(i32, i32))
        \\
        \\fn make(k: i32) -> ?Form {
        \\    if (k == 0) return null;
        \\    return Form(fields: [Field(name: "email")], tags: ["a", "b"], range: #(1, 2));
        \\}
        \\
        \\pub fn main() -> void {
        \\    val f = make(1);
        \\    val tags: string[] = f?.tags ?? [];
        \\    print(tags.join(","));
        \\    val none: string[] = make(0)?.tags ?? [];
        \\    print(none.length);
        \\    val r = f?.range ?? #(0, 0);
        \\    print(r);
        \\    print(f?.fields?.[0]?.name ?? "none");
        \\    print(make(0)?.fields?.[0]?.name ?? "none");
        \\    val empty: ?Form = Form(fields: null, tags: [], range: #(3, 4));
        \\    print(empty?.fields?.[0]?.name ?? "none");
        \\}
    , "a,b\n0\n#(1, 2)\nemail\nnone\nnone\n");
}

test "wat: decision 1021 (10) ---- a behavior-typed value is its implementer's reference, dispatched by its own type in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\behavior Greeter {
        \\    fn greet(self: Self, punct: string) -> string;
        \\}
        \\
        \\type Bob(name: string) implement Greeter {
        \\    fn greet(self: Self, punct: string) -> string {
        \\        return "hi " + self.name + punct;
        \\    }
        \\}
        \\
        \\type Ann(age: i32) implement Greeter {
        \\    fn greet(self: Self, punct: string) -> string {
        \\        return "ann " + self.age.toString() + punct;
        \\    }
        \\}
        \\
        \\type Pet implement Greeter {
        \\    Dog(name: string),
        \\    Cat(lives: i32),
        \\
        \\    fn greet(self: Self, punct: string) -> string {
        \\        return case self {
        \\            Dog(name) -> "woof " + name + punct;
        \\            Cat(lives) -> "meow " + lives.toString() + punct;
        \\        };
        \\    }
        \\}
        \\
        \\type Door(name: string) implement Closeable {
        \\    fn close(self: Self) -> void {
        \\        print("closed " + self.name);
        \\    }
        \\}
        \\
        \\type Registry(names: string[]) implement Index<string, i32> {
        \\    pub fn at(self: Self, key: string) -> ?i32 {
        \\        val found = self.names.indexOf(key);
        \\        if (found < 0) return null;
        \\        return found;
        \\    }
        \\}
        \\
        \\fn welcome(g: Greeter) -> string {
        \\    return g.greet("!");
        \\}
        \\
        \\fn make(old: bool) -> Greeter {
        \\    if (old) return Ann(age: 70);
        \\    return Bob(name: "b");
        \\}
        \\
        \\fn shut(c: Closeable) -> void {
        \\    c.close();
        \\}
        \\
        \\fn lookup(m: Index<string, i32>, key: string) -> i32 {
        \\    return m.at(key) ?? -1;
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(welcome(Bob(name: "bob")));
        \\    print(welcome(make(true)));
        \\    print(welcome(make(false)));
        \\    print(welcome(Pet.Dog(name: "rex")));
        \\    print(welcome(Pet.Cat(lives: 9)));
        \\    val all: Greeter[] = [Bob(name: "x"), Ann(age: 3), Pet.Cat(lives: 1)];
        \\    for (all) { g ->
        \\        print(g.greet("?"));
        \\    }
        \\    shut(Door(name: "front"));
        \\    val r = Registry(names: ["ana", "bo"]);
        \\    print(lookup(r, "bo"));
        \\    print(lookup(r, "zz"));
        \\}
    , "hi bob!\nann 70!\nhi b!\nwoof rex!\nmeow 9!\nhi x?\nann 3?\nmeow 1?\nclosed front\n1\n-1\n");
}

test "wat: decision 1021 (10) ---- f?.(x) over an optional function field answers the optional of a string, a word or a float in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\type Cfg(scoper: ?fn(string) -> string = null, count: ?fn(i32) -> i32 = null, half: ?fn(f64) -> f64 = null)
        \\
        \\fn shout(s: string) -> string {
        \\    return s + "!";
        \\}
        \\
        \\fn triple(n: i32) -> i32 {
        \\    return n * 3;
        \\}
        \\
        \\fn halve(x: f64) -> f64 {
        \\    return x / 2.0;
        \\}
        \\
        \\pub fn main() -> void {
        \\    val a = Cfg(scoper: shout);
        \\    print(a.scoper?.("x") ?? "none");
        \\    print(a.count?.(2) ?? -1);
        \\    print(a.half?.(3.0) ?? 0.5);
        \\    val b = Cfg(count: triple, half: halve);
        \\    print(b.scoper?.("y") ?? "none");
        \\    print(b.count?.(0) ?? -1);
        \\    print(b.count?.(2) ?? -1);
        \\    print(b.half?.(3.0) ?? 0.5);
        \\}
    , "x!\n-1\n0.5\nnone\n0\n6\n1.5\n");
}

test "wat: decision 1021 (10) ---- val assert over a variant, a record and a Result keeps its subject, its catch taken, in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\type Shape { Circle(r: i32), Square(side: i32) }
        \\
        \\type Person(name: string, age: i32)
        \\
        \\fn parse(s: string) -> Result<i32, string> {
        \\    if (s == "") throw "empty input";
        \\    return s.length;
        \\}
        \\
        \\fn radius(s: Shape) -> i32 {
        \\    val assert Circle(r) = s catch Shape.Circle(r: 0 - 1);
        \\    return r;
        \\}
        \\
        \\fn describe(p: Person) -> string {
        \\    val assert Person(n, a) = p;
        \\    return n + "/" + a.toString();
        \\}
        \\
        \\fn size(s: string) -> i32 {
        \\    val assert Ok(n) = parse(s);
        \\    return n;
        \\}
        \\
        \\fn reason(s: string) -> string {
        \\    val assert Error(message) = parse(s);
        \\    return message;
        \\}
        \\
        \\fn older(p: Person) -> i32 {
        \\    val assert Person(n, a) = p catch Person(name: "none", age: 0);
        \\    return a + n.length;
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(radius(Shape.Circle(r: 3)));
        \\    print(radius(Shape.Square(side: 2)));
        \\    print(describe(Person(name: "ana", age: 30)));
        \\    print(size("four"));
        \\    print(reason(""));
        \\    print(older(Person(name: "bo", age: 41)));
        \\}
    , "3\n-1\nana/30\n4\nempty input\n43\n");
}

test "wat: decision 1021 (10) ---- a return written through an alias of a Result is the Result it names in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\type ParseError { Empty }
        \\
        \\pub type Parser<T> = Result<T, ParseError>;
        \\
        \\pub type Checked<T> = Result<T, string>;
        \\
        \\fn parsePort(s: string) -> Result<i32, ParseError> {
        \\    if (s == "") throw ParseError.Empty;
        \\    return 8080;
        \\}
        \\
        \\fn port(s: string) -> Parser<i32> {
        \\    return parsePort(s);
        \\}
        \\
        \\fn check(n: i32) -> Result<i32, string> {
        \\    if (n < 0) throw "negative";
        \\    return n;
        \\}
        \\
        \\fn pass(r: Checked<i32>) -> Checked<i32> {
        \\    return r;
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(try port("x") catch 0);
        \\    print(try port("") catch 7);
        \\    print(pass(check(4)).unwrapOr(0));
        \\    print(pass(check(-4)).unwrapOr(0));
        \\    print(pass(check(-1)).isError());
        \\}
    , "8080\n7\n4\n0\ntrue\n");
}

test "wat: decision 1021 (10) ---- a tuple parameter's destructuring binds each element at its type in the GC lowering" {
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\fn second(#(_, s): #(i32, string)) -> string {
        \\    return s;
        \\}
        \\
        \\fn sum(#(a, b): #(i32, i32)) -> i32 {
        \\    return a + b;
        \\}
        \\
        \\fn label(#(name, score): #(string, f64)) -> string {
        \\    return name + "=" + score.toString();
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(second(#(1, "x")));
        \\    print(sum(#(2, 40)));
        \\    print(label(#("ana", 2.5)));
        \\}
    , "x\n42\nana=2.5\n");
}

test "wat: decision 1021 (10) ---- an aliased import of a function two modules declare, passed as a value, is the one it names in the GC lowering" {
    // The second `label` is mangled per module; a name read as a value is no
    // call `renameLinkedCalls` rewrites, so the GC pass's reach followed the
    // alias to nothing and refused it (`… is not bound here`).
    try h.assertWasmGcRunLogModules(std.testing.allocator, &.{
        .{ .path = "one", .source =
        \\pub fn label() -> string {
        \\    return "one";
        \\}
        },
        .{ .path = "two", .source =
        \\pub fn label() -> string {
        \\    return "two";
        \\}
        },
        .{ .path = "main", .source =
        \\import {io.terminal.print} from "std";
        \\import {one.label as first, two.label as second};
        \\
        \\fn call(f: fn() -> string) -> string {
        \\    return f();
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(call(first));
        \\    print(call(second));
        \\}
        },
    }, "one\ntwo\n");
}

test "wat: decision 1021 (10) ---- a record's constructor pattern names the module's own record when two modules declare it, in the GC lowering" {
    const person =
        \\pub type Person(name: string, age: i32)
        \\
        \\pub fn make(n: string, a: i32) -> Person {
        \\    return Person(name: n, age: a);
        \\}
        \\
        \\pub fn describe(p: Person) -> string {
        \\    val assert Person(n, a) = p;
        \\    return n + "/" + a.toString();
        \\}
    ;
    try h.assertWasmGcRunLogModules(std.testing.allocator, &.{
        .{ .path = "one", .source = person },
        .{ .path = "two", .source = person },
        .{ .path = "main", .source =
        \\import {io.terminal.print} from "std";
        \\import {one.make as makeOne, one.describe as describeOne, two.make as makeTwo, two.describe as describeTwo};
        \\
        \\pub fn main() -> void {
        \\    print(describeOne(makeOne("ana", 30)));
        \\    print(describeTwo(makeTwo("bia", 40)));
        \\}
        },
    }, "ana/30\nbia/40\n");
}

test "wat: decision 1058 (4) ---- a bare variant pattern two modules' same-named enums declare never tests the other enum's variant" {
    // Each module's `Shape` is linked mangled; `Circle(r)` in a `val assert`
    // searched every enum and the first `Circle` answered, so the GC lowering
    // tested the other module's struct type and `radiusOf` answered `-1` for a
    // circle. Guarded into a named gap until the subject's enum resolves it.
    const shape =
        \\pub type Shape { Circle(radius: i32), Rect(width: i32, height: i32) }
        \\
        \\pub fn circle(r: i32) -> Shape {
        \\    return Shape.Circle(r);
        \\}
        \\
        \\pub fn rect() -> Shape {
        \\    return Shape.Rect(1, 1);
        \\}
        \\
        \\pub fn radiusOf(s: Shape) -> i32 {
        \\    val assert Circle(r) = s catch return -1;
        \\    return r;
        \\}
    ;
    try h.assertWasmRunLogModules(std.testing.allocator, &.{
        .{ .path = "one", .source = shape },
        .{ .path = "two", .source = shape },
        .{ .path = "main", .source =
        \\import {io.terminal.print} from "std";
        \\import {one.circle as circleOne, one.rect as rectOne, one.radiusOf as radiusOne, two.circle as circleTwo, two.rect as rectTwo, two.radiusOf as radiusTwo};
        \\
        \\pub fn main() -> void {
        \\    print(radiusOne(circleOne(4)));
        \\    print(radiusOne(rectOne()));
        \\    print(radiusTwo(circleTwo(5)));
        \\    print(radiusTwo(rectTwo()));
        \\}
        },
    }, "4\n-1\n5\n-1\n");
}

test "wat: decision 1058 (4) ---- an imported enum's variant two modules declare alike answers `is` for the module that built it (B-202)" {
    try h.assertWasmRunLogModules(std.testing.allocator, &.{
        .{ .path = "one", .source =
        \\pub type Shape { Circle(r: i32), Square(side: i32) }
        \\
        \\pub fn square() -> Shape {
        \\    return Shape.Square(side: 2);
        \\}
        },
        .{ .path = "shapes", .source =
        \\pub type Shape { Circle(r: i32), Square(side: i32) }
        \\
        \\pub fn unitCircle() -> Shape {
        \\    return Shape.Circle(r: 1);
        \\}
        },
        .{ .path = "main", .source =
        \\import {io.terminal.print} from "std";
        \\import {one.square, shapes.Shape, shapes.unitCircle};
        \\
        \\pub fn main() -> void {
        \\    val s = unitCircle();
        \\    print(s is Shape.Circle);
        \\    print(s == Shape.Circle(r: 1));
        \\    print(s);
        \\    print(square());
        \\}
        },
    }, "true\ntrue\nShape.Circle(r: 1)\nShape.Square(side: 2)\n");
}

test "wat: decision 1021 (10) ---- a method call on a value is never the module's free function of its name in the GC lowering" {
    // `xs?.[0]` is written `n.at(0)`, and `m.at(key)` on an `Index` dispatches
    // by value: both were typed by `fn at(c: bool) -> ?Point`, and the module
    // fell back to linear memory.
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\pub type Point(x: i32, y: i32)
        \\
        \\type Field(name: string)
        \\
        \\type Form(fields: ?Field[])
        \\
        \\type Registry(names: string[]) implement Index<string, i32> {
        \\    pub fn at(self: Self, key: string) -> ?i32 {
        \\        val found = self.names.indexOf(key);
        \\        if (found < 0) return null;
        \\        return found;
        \\    }
        \\}
        \\
        \\fn at(c: bool) -> ?Point {
        \\    return if (c) Point(x: 1, y: 2) else null;
        \\}
        \\
        \\fn lookup(m: Index<string, i32>, key: string) -> i32 {
        \\    return m.at(key) ?? -1;
        \\}
        \\
        \\pub fn main() -> void {
        \\    val f: ?Form = Form(fields: [Field(name: "email")]);
        \\    print(f?.fields?.[0]?.name ?? "none");
        \\    print(at(true)?.x ?? -1);
        \\    print(lookup(Registry(names: ["a", "b"]), "b"));
        \\    print(lookup(Registry(names: ["a"]), "z"));
        \\}
    , "email\n1\n1\n-1\n");
}

// Decision 1032 (piece P3/P4 step B) — with `Config.wasm_units` on, a `wasi`
// build's entry is a core module holding only its own code: no unit's text,
// `botopink.units` naming the core, the std units it reaches in dependency
// order and the entry itself; every import it makes is an export of the unit
// it names, with the same type (the units' index); and the frame compiled
// from those units through the embedded engine runs it (decision 1034's
// runner, R0) — the bytes the units' files hold.
test "wat: units ---- a wasi entry with the units on imports them, names them in botopink.units, and the frame runs it" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    const ru = @import("../wat/runtime_unit.zig");
    const engine = @import("../wat/engine.zig");
    const runner = @import("../wat/runner.zig");
    const watEmitter = @import("../wat/wat_emitter.zig");
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    var outputs = try h.generate(a, &.{.{ .path = "main", .source =
        \\import {io.terminal.print} from "std";
        \\
        \\fn main() -> void {
        \\    print("hello, world");
        \\    print("a,b".split(","));
        \\}
    }}, io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    const o = for (outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "main")) break o;
    } else return error.ModuleDidNotCompile;
    const bin = o.result.wasm orelse return error.ModuleDidNotCompile;
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    const rt = try ru.get();

    // The entry is a core module, its text the module's (no component, no
    // unit's text).
    try std.testing.expect(std.mem.startsWith(u8, o.result.js, "(module"));
    try std.testing.expect(std.mem.indexOf(u8, o.result.js, "(component") == null);
    const stems = try ru.unitsOf(ar, bin);
    try std.testing.expect(stems.len >= 3);
    try std.testing.expectEqualStrings(ru.name, stems[0]);
    try std.testing.expectEqualStrings("test@main", stems[stems.len - 1]);
    for (stems[1 .. stems.len - 1]) |s| try std.testing.expect(rt.unit(s) != null);

    // Every import of the entry is an export of the unit it names, typed alike.
    const face = try ru.faceOfBytes(ar, bin);
    var lines = std.mem.tokenizeScalar(u8, face.text, '\n');
    while (lines.next()) |l| {
        const head = "    (import \"";
        if (!std.mem.startsWith(u8, l, head)) continue;
        const rest = l[head.len..];
        const q = std.mem.indexOfScalar(u8, rest, '"').?;
        const module = rest[0..q];
        const unit_face = if (std.mem.eql(u8, module, ru.name)) rt.core_face else (rt.unit(module) orelse return error.TestUnexpectedResult).face;
        const want = try std.fmt.allocPrint(ar, "    (export {s}", .{rest[q + 2 ..]});
        try std.testing.expect(std.mem.indexOf(u8, unit_face.text, want[0 .. want.len - 1]) != null);
    }

    // The frame over the units' bytes, run through the runner.
    var fw: std.Io.Writer.Allocating = .init(ar);
    try watEmitter.frameOf(ar, &fw.writer, bin, &.{});
    var failure: ?[]u8 = null;
    const comp = (try engine.precompiled(a, io, null, fw.written(), .component, false, &failure)) orelse {
        std.debug.print("\n=== frame refused: {s}\n", .{failure.?});
        a.free(failure.?);
        return error.TestUnexpectedResult;
    };
    defer comp.code.deinit();
    var held: std.ArrayListUnmanaged(engine.Precompiled) = .empty;
    defer {
        for (held.items) |p| p.code.deinit();
        held.deinit(a);
    }
    const units = try ar.alloc(runner.Unit, stems.len);
    for (stems, units, 0..) |s, *u, k| {
        const bytes = if (k == stems.len - 1) bin else if (std.mem.eql(u8, s, ru.name)) rt.core_bytes else rt.unit(s).?.bytes;
        const pc = (try engine.precompiled(a, io, null, bytes, .module, false, &failure)) orelse {
            std.debug.print("\n=== unit {s} refused: {s}\n", .{ s, failure.? });
            a.free(failure.?);
            return error.TestUnexpectedResult;
        };
        try held.append(a, pc);
        u.* = .{ .name = try std.fmt.allocPrint(ar, "unit-{d}", .{k}), .module = pc.code.module };
    }
    const out = try runner.run(a, comp.code.component, units, .{ .stdout = .capture });
    defer out.deinit(a);
    if (out.trap) |t| std.debug.print("\n=== trap: {s}\n", .{t});
    try std.testing.expectEqual(@as(i32, 0), out.status);
    try std.testing.expectEqualStrings("hello, world\n[\"a\", \"b\"]\n", out.stdout orelse "");
}

test "wat: decision 1021 (10) ---- a variant's i64 field prints by its own code in the GC lowering" {
    // The variant printer read every `i64` field through the `i32` printer
    // (`FsError.InvalidUtf8(offset: i64)`), a type error that sent every
    // module printing a `Display` value through std's `io.fs` to linear memory.
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\type Failure {
        \\    Bad(path: string, offset: i64),
        \\    Other(code: i32),
        \\}
        \\
        \\pub fn main() -> void {
        \\    val all: Failure[] = [Failure.Bad(path: "a.txt", offset: 4294967296), Failure.Other(code: 7)];
        \\    for (all) { f -> print(f); }
        \\    print(Failure.Bad(path: "b", offset: -3));
        \\}
    , "Failure.Bad(path: \"a.txt\", offset: 4294967296)\nFailure.Other(code: 7)\nFailure.Bad(path: \"b\", offset: -3)\n");
}

test "wat: decision 1021 (10) ---- flatMap, pop, an empty inner array and a spread alone stay in the GC lowering" {
    // Each sent `conformance/modules/array` to linear memory: `flatMap` and
    // `pop` through std-wasm's linear `array.flatten` / `array.slice`, an
    // empty array beside arrays and `[..xs]` with no type of their own.
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\pub fn main() -> void {
        \\    print([[1, 2], [], [3]].flatten());
        \\    print([1, 2].flatMap({ x -> [x, x * 10] }));
        \\    print(["ab", "c"].flatMap({ s -> s.chars() }));
        \\    val none: i32[][] = [];
        \\    print(none.flatten());
        \\    val empty: i32[] = [];
        \\    val onlySpread = [..empty];
        \\    print(onlySpread.length);
        \\    var xs = [1, 2, 3];
        \\    print(xs.pop());
        \\    print(xs);
        \\    var names = ["a", "b"];
        \\    print(names.pop() ?? "none");
        \\    print(names.pop() ?? "none");
        \\    print(names.pop() ?? "none");
        \\    print(names);
        \\}
    , "[1, 2, 3]\n[1, 10, 2, 20]\n[\"a\", \"b\", \"c\"]\n[]\n0\n3\n[1, 2]\nb\na\nnone\n[]\n");
}

// Decision 1032 (6) P4 — with `Config.wasm_units` on, each module of a
// program is a unit of its own: `lib` exports its `pub` functions (through
// decision 1037's wrappers where a type definition crosses), the entry
// imports them from `test@lib` instead of linking their bodies and names the
// unit in its `botopink.units` before itself; every import of every unit is
// an export of the unit it names, typed alike (the index oracle, extended to
// program units); and the frame over the units runs through `runner.run`.
test "wat: units ---- each module of a program is a unit, importing what the units it reaches export" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    const ru = @import("../wat/runtime_unit.zig");
    const engine = @import("../wat/engine.zig");
    const runner = @import("../wat/runner.zig");
    const watEmitter = @import("../wat/wat_emitter.zig");
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    var outputs = try h.generate(a, &.{
        .{ .path = "lib", .source =
        \\pub type Point(x: i32, y: i32)
        \\
        \\pub fn greet(name: string) -> string {
        \\    return "hi, " + name;
        \\}
        \\
        \\pub fn shift(p: Point, d: i32) -> Point {
        \\    return Point(x: p.x + d, y: p.y);
        \\}
        },
        .{ .path = "main", .source =
        \\import {io.terminal.print} from "std";
        \\import {greet, shift, Point} from "lib";
        \\
        \\fn main() -> void {
        \\    print(greet("bo"));
        \\    val p = shift(Point(x: 1, y: 2), 3);
        \\    print(p.x);
        \\}
        },
    }, io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    const rt = try ru.get();
    var program: std.ArrayListUnmanaged(watEmitter.UnitBytes) = .empty;
    var entry: ?[]const u8 = null;
    for (outputs.items) |o| {
        const bin = o.result.wasm orelse continue;
        const stems = try ru.unitsOf(ar, bin);
        if (stems.len == 0) continue;
        try program.append(ar, .{ .name = stems[stems.len - 1], .bytes = bin });
        if (std.mem.eql(u8, o.name, "main")) entry = bin;
    }
    const bin = entry orelse return error.ModuleDidNotCompile;
    const stems = try ru.unitsOf(ar, bin);
    try std.testing.expectEqualStrings("test@lib", stems[stems.len - 2]);
    try std.testing.expectEqualStrings("test@main", stems[stems.len - 1]);
    const main_text = (try ru.faceOfBytes(ar, bin)).text;
    try std.testing.expect(std.mem.indexOf(u8, main_text, "(import \"test@lib\" \"greet\" ") != null);
    try std.testing.expect(std.mem.indexOf(u8, main_text, "(import \"test@lib\" \"shift\" ") != null);

    // The index oracle over every unit of the program.
    for (program.items) |p| {
        const face = try ru.faceOfBytes(ar, p.bytes);
        var lines = std.mem.tokenizeScalar(u8, face.text, '\n');
        while (lines.next()) |l| {
            const head = "    (import \"";
            if (!std.mem.startsWith(u8, l, head)) continue;
            const rest = l[head.len..];
            const q = std.mem.indexOfScalar(u8, rest, '"').?;
            const module = rest[0..q];
            const unit_face = if (std.mem.eql(u8, module, ru.name)) rt.core_face else if (rt.unit(module)) |u| u.face else for (program.items) |o| {
                if (std.mem.eql(u8, o.name, module)) break try ru.faceOfBytes(ar, o.bytes);
            } else return error.TestUnexpectedResult;
            const want = try std.fmt.allocPrint(ar, "    (export {s}", .{rest[q + 2 ..]});
            if (std.mem.indexOf(u8, unit_face.text, want[0 .. want.len - 1]) == null) {
                std.debug.print("\n=== {s}: no export for {s}\n", .{ p.name, l });
                return error.TestUnexpectedResult;
            }
        }
    }

    var fw: std.Io.Writer.Allocating = .init(ar);
    try watEmitter.frameOf(ar, &fw.writer, bin, program.items);
    var failure: ?[]u8 = null;
    const comp = (try engine.precompiled(a, io, null, fw.written(), .component, false, &failure)) orelse {
        std.debug.print("\n=== frame refused: {s}\n", .{failure.?});
        a.free(failure.?);
        return error.TestUnexpectedResult;
    };
    defer comp.code.deinit();
    var held: std.ArrayListUnmanaged(engine.Precompiled) = .empty;
    defer {
        for (held.items) |p| p.code.deinit();
        held.deinit(a);
    }
    const units = try ar.alloc(runner.Unit, stems.len);
    for (stems, units, 0..) |s, *u, k| {
        const bytes = if (std.mem.eql(u8, s, ru.name)) rt.core_bytes else if (rt.unit(s)) |su| su.bytes else for (program.items) |p| {
            if (std.mem.eql(u8, p.name, s)) break p.bytes;
        } else return error.TestUnexpectedResult;
        const pc = (try engine.precompiled(a, io, null, bytes, .module, false, &failure)) orelse {
            std.debug.print("\n=== unit {s} refused: {s}\n", .{ s, failure.? });
            a.free(failure.?);
            return error.TestUnexpectedResult;
        };
        try held.append(a, pc);
        u.* = .{ .name = try std.fmt.allocPrint(ar, "unit-{d}", .{k}), .module = pc.code.module };
    }
    const out = try runner.run(a, comp.code.component, units, .{ .stdout = .capture });
    defer out.deinit(a);
    if (out.trap) |t| std.debug.print("\n=== trap: {s}\n", .{t});
    try std.testing.expectEqual(@as(i32, 0), out.status);
    try std.testing.expectEqualStrings("hi, bo\n4\n", out.stdout orelse "");
}

/// The stdout of the frame over `entry`'s units (the core, std's, and the
/// program units `program` holds by stem), run through `runner.run`.
fn runUnitsFrame(a: std.mem.Allocator, ar: std.mem.Allocator, entry: []const u8, program: []const @import("../wat/wat_emitter.zig").UnitBytes) ![]const u8 {
    const io = std.testing.io;
    const ru = @import("../wat/runtime_unit.zig");
    const engine = @import("../wat/engine.zig");
    const runner = @import("../wat/runner.zig");
    const watEmitter = @import("../wat/wat_emitter.zig");
    const rt = try ru.get();
    const stems = try ru.unitsOf(ar, entry);
    var fw: std.Io.Writer.Allocating = .init(ar);
    try watEmitter.frameOf(ar, &fw.writer, entry, program);
    var failure: ?[]u8 = null;
    const comp = (try engine.precompiled(a, io, null, fw.written(), .component, false, &failure)) orelse {
        std.debug.print("\n=== frame refused: {s}\n", .{failure.?});
        a.free(failure.?);
        return error.TestUnexpectedResult;
    };
    defer comp.code.deinit();
    var held: std.ArrayListUnmanaged(engine.Precompiled) = .empty;
    defer {
        for (held.items) |p| p.code.deinit();
        held.deinit(a);
    }
    const units = try ar.alloc(runner.Unit, stems.len);
    for (stems, units, 0..) |s, *u, k| {
        const bytes = if (k == stems.len - 1) entry else if (std.mem.eql(u8, s, ru.name)) rt.core_bytes else if (rt.unit(s)) |su| su.bytes else for (program) |p| {
            if (std.mem.eql(u8, p.name, s)) break p.bytes;
        } else return error.TestUnexpectedResult;
        const pc = (try engine.precompiled(a, io, null, bytes, .module, false, &failure)) orelse {
            std.debug.print("\n=== unit {s} refused: {s}\n", .{ s, failure.? });
            a.free(failure.?);
            return error.TestUnexpectedResult;
        };
        try held.append(a, pc);
        u.* = .{ .name = try std.fmt.allocPrint(ar, "unit-{d}", .{k}), .module = pc.code.module };
    }
    const out = try runner.run(a, comp.code.component, units, .{ .stdout = .capture });
    defer out.deinit(a);
    if (out.trap) |t| std.debug.print("\n=== trap: {s}\n", .{t});
    try std.testing.expectEqual(@as(i32, 0), out.status);
    return ar.dupe(u8, out.stdout orelse "");
}

/// The index oracle over a program's units (decision 1037): each unit's face
/// reads — no import or exported function names a type definition — and
/// every import of every unit is an export of the unit it names, typed alike.
fn expectUnitsLink(ar: std.mem.Allocator, program: []const @import("../wat/wat_emitter.zig").UnitBytes) !void {
    const ru = @import("../wat/runtime_unit.zig");
    const rt = try ru.get();
    for (program) |p| {
        const face = ru.faceOfBytes(ar, p.bytes) catch |err| {
            std.debug.print("\n=== {s}: the face does not read: {s}\n", .{ p.name, @errorName(err) });
            return err;
        };
        var lines = std.mem.tokenizeScalar(u8, face.text, '\n');
        while (lines.next()) |l| {
            const head = "    (import \"";
            if (!std.mem.startsWith(u8, l, head)) continue;
            const rest = l[head.len..];
            const q = std.mem.indexOfScalar(u8, rest, '"').?;
            const module = rest[0..q];
            const unit_face = if (std.mem.eql(u8, module, ru.name)) rt.core_face else if (rt.unit(module)) |u| u.face else for (program) |o| {
                if (std.mem.eql(u8, o.name, module)) break try ru.faceOfBytes(ar, o.bytes);
            } else {
                std.debug.print("\n=== {s}: imports the unknown unit {s}\n", .{ p.name, module });
                return error.TestUnexpectedResult;
            };
            const want = try std.fmt.allocPrint(ar, "    (export {s}", .{rest[q + 2 ..]});
            if (std.mem.indexOf(u8, unit_face.text, want[0 .. want.len - 1]) == null) {
                std.debug.print("\n=== {s}: no export for {s}\n", .{ p.name, l });
                return error.TestUnexpectedResult;
            }
        }
    }
}

/// Each program unit `outputs` holds, by its stem (its `botopink.units`'
/// last line), and the bytes of the module `entry_name`.
fn programUnitsOf(ar: std.mem.Allocator, outputs: []const ModuleOutput, entry_name: []const u8, program: *std.ArrayListUnmanaged(@import("../wat/wat_emitter.zig").UnitBytes)) !?[]const u8 {
    const ru = @import("../wat/runtime_unit.zig");
    var entry: ?[]const u8 = null;
    for (outputs) |o| {
        const bin = o.result.wasm orelse continue;
        const stems = try ru.unitsOf(ar, bin);
        if (stems.len == 0) continue;
        try program.append(ar, .{ .name = stems[stems.len - 1], .bytes = bin });
        if (std.mem.eql(u8, o.name, entry_name)) entry = bin;
    }
    return entry;
}

// Decisions 1032 (6) P4, 1037 — a `pub` function answering `Result` (a
// prelude GC type, its error payload a declared record) crosses the unit
// boundary through its 1037 wrapper: `test@lib` exports `half` with abstract
// types only, `test@main` imports it and calls it through a thunk; the index
// oracle reads every unit and the frame runs through `runner.run`.
test "wat: units ---- a pub fn answering Result crosses the boundary through its wrapper" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    const ru = @import("../wat/runtime_unit.zig");
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    var outputs = try h.generate(a, &.{
        .{ .path = "lib", .source =
        \\pub type Odd(n: i32)
        \\
        \\pub fn half(n: i32) -> Result<i32, Odd> {
        \\    if (n % 2 != 0) throw Odd(n: n);
        \\    return n / 2;
        \\}
        },
        .{ .path = "main", .source =
        \\import {io.terminal.print} from "std";
        \\import {half} from "lib";
        \\
        \\fn main() -> void {
        \\    print("${half(4)}");
        \\    print("${half(3)}");
        \\}
        },
    }, io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    var program: std.ArrayListUnmanaged(@import("../wat/wat_emitter.zig").UnitBytes) = .empty;
    const bin = (try programUnitsOf(ar, outputs.items, "main", &program)) orelse return error.ModuleDidNotCompile;
    try expectUnitsLink(ar, program.items);
    for (program.items) |p| if (std.mem.eql(u8, p.name, "test@lib")) {
        const face = (try ru.faceOfBytes(ar, p.bytes)).text;
        try std.testing.expect(std.mem.indexOf(u8, face, "(export \"half\" (func (param i32) (result structref)))") != null);
    };
    const main_face = (try ru.faceOfBytes(ar, bin)).text;
    try std.testing.expect(std.mem.indexOf(u8, main_face, "(import \"test@lib\" \"half\" ") != null);
    try std.testing.expectEqualStrings("Ok(2)\nError(Odd(n: 3))\n", try runUnitsFrame(a, ar, bin, program.items));
}

// Decisions 1026, 1028, 1032 (6) P4 — a program reaching std's `.bp` modules
// (`io.fs`, which reaches `path`): no std module is a unit of its own (its
// bodies are linked into the importer; the one `std@<path>` unit is
// std-wasm's), so no program unit is named `std@…`, the entry's
// `botopink.units` lists every unit its units import, each before its
// importer, and the frame builds and compiles.
test "wat: units ---- an io.fs program's entry lists every unit its frame needs" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    const ru = @import("../wat/runtime_unit.zig");
    const engine = @import("../wat/engine.zig");
    const watEmitter = @import("../wat/wat_emitter.zig");
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    var outputs = try h.generate(a, &.{
        .{ .path = "main", .source =
        \\import {io.fs, io.terminal.print} from "std";
        \\
        \\fn main() -> void {
        \\    print("${fs.readText("missing.txt")}");
        \\}
        },
    }, io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    const rt = try ru.get();
    var program: std.ArrayListUnmanaged(watEmitter.UnitBytes) = .empty;
    const bin = (try programUnitsOf(ar, outputs.items, "main", &program)) orelse return error.ModuleDidNotCompile;
    for (program.items) |p| if (std.mem.startsWith(u8, p.name, "std@")) {
        std.debug.print("\n=== a std module emitted as the unit {s}\n", .{p.name});
        return error.TestUnexpectedResult;
    };
    try expectUnitsLink(ar, program.items);
    // Each unit the list names imports only units listed before it.
    const stems = try ru.unitsOf(ar, bin);
    for (stems, 0..) |s, k| {
        const face = if (k == stems.len - 1) try ru.faceOfBytes(ar, bin) else if (std.mem.eql(u8, s, ru.name)) rt.core_face else if (rt.unit(s)) |u| u.face else for (program.items) |p| {
            if (std.mem.eql(u8, p.name, s)) break try ru.faceOfBytes(ar, p.bytes);
        } else return error.TestUnexpectedResult;
        for (face.modules) |m| {
            if (std.mem.eql(u8, m, "wasi_snapshot_preview1") or std.mem.eql(u8, m, "bp_fs") or std.mem.eql(u8, m, "bp_host")) continue;
            for (stems[0..k]) |d| {
                if (std.mem.eql(u8, d, m)) break;
            } else {
                std.debug.print("\n=== {s} imports {s}, not listed before it\n", .{ s, m });
                return error.TestUnexpectedResult;
            }
        }
    }
    var listed_fs = false;
    for (stems) |s| listed_fs = listed_fs or std.mem.eql(u8, s, "std@io@fs");
    try std.testing.expect(listed_fs);
    var fw: std.Io.Writer.Allocating = .init(ar);
    try watEmitter.frameOf(ar, &fw.writer, bin, program.items);
    var failure: ?[]u8 = null;
    const comp = (try engine.precompiled(a, io, null, fw.written(), .component, false, &failure)) orelse {
        std.debug.print("\n=== frame refused: {s}\n", .{failure.?});
        a.free(failure.?);
        return error.TestUnexpectedResult;
    };
    comp.code.deinit();
}

// Decision 1032 (6) P4 — under `botopink test` with the units on, a module's
// test entry is the unit `<pkg>@<module>.test` (its `botopink.units`' last
// line), importing the program units its tests reach as the module does;
// its frame runs the tests.
test "wat: units ---- a module's test entry is the unit <pkg>@<module>.test" {
    const a = std.testing.allocator;
    const ru = @import("../wat/runtime_unit.zig");
    const watEmitter = @import("../wat/wat_emitter.zig");
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    cfg.test_mode = true;
    var outputs = try h.generate(a, &.{
        .{ .path = "util", .source =
        \\pub fn twice(n: i32) -> i32 {
        \\    return n * 2;
        \\}
        },
        .{ .path = "calc", .source =
        \\import {twice} from "util";
        \\
        \\pub fn quad(n: i32) -> i32 {
        \\    return twice(twice(n));
        \\}
        \\
        \\test "quad" {
        \\    assert quad(3) == 12;
        \\}
        },
    }, std.testing.io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    var program: std.ArrayListUnmanaged(watEmitter.UnitBytes) = .empty;
    var entry: ?[]const u8 = null;
    for (outputs.items) |o| {
        if (o.result.wasm) |bin| {
            const stems = try ru.unitsOf(ar, bin);
            if (stems.len > 0) try program.append(ar, .{ .name = stems[stems.len - 1], .bytes = bin });
        }
        if (std.mem.eql(u8, o.name, "calc")) entry = (o.result.test_unit orelse return error.NoTestUnit).wasm;
    }
    const bin = entry orelse return error.NoTestUnit;
    const stems = try ru.unitsOf(ar, bin);
    try std.testing.expectEqualStrings("test@calc.test", stems[stems.len - 1]);
    try std.testing.expectEqualStrings("test@util", stems[stems.len - 2]);
    try std.testing.expect(std.mem.indexOf(u8, (try ru.faceOfBytes(ar, bin)).text, "(import \"test@util\" \"twice\" ") != null);
    const out = try runUnitsFrame(a, ar, bin, program.items);
    try std.testing.expect(std.mem.indexOf(u8, out, "1 passed, 0 failed") != null);
}

test "wat: decision 1021 (10) ---- a method on a type imported under an alias is its declaration's beside a free function of its name, in the GC lowering" {
    // Inference names the type `APolicy`, which declares no method here: the
    // call fell to `k`'s private `describe(e: Fault)` by its arity, a
    // conversion refused (`Policy -> Fault`), and the module left GC.
    try h.assertWasmGcRunLogModules(std.testing.allocator, &.{
        .{ .path = "a/p", .source =
        \\pub type Policy(ms: i32) {
        \\    pub fn describe(self: Self) -> string {
        \\        return "a:" + self.ms.toString();
        \\    }
        \\}
        },
        .{ .path = "b/p", .source =
        \\pub type Policy(name: string) {
        \\    pub fn describe(self: Self) -> string {
        \\        return "b:" + self.name;
        \\    }
        \\}
        },
        .{ .path = "k", .source =
        \\pub type Fault(code: i32)
        \\
        \\pub fn other() -> string {
        \\    return describe(Fault(code: 4));
        \\}
        \\
        \\fn describe(e: Fault) -> string {
        \\    return "fault " + e.code.toString();
        \\}
        },
        .{ .path = "main", .source =
        \\import {io.terminal.print} from "std";
        \\import {a.p.Policy as APolicy, b.p.Policy as BPolicy, k.other};
        \\
        \\pub fn main() -> void {
        \\    val x = APolicy(ms: 5);
        \\    val y: BPolicy = BPolicy(name: "n");
        \\    print(x.describe());
        \\    print(y.describe());
        \\    print(other());
        \\}
        },
    }, "a:5\nb:n\nfault 4\n");
}

// Decisions 1033, 1035 (1), (3), 1038 (4) — piece C1, the `.comptime` stage:
// a module declaring a decorator has its comptime unit `<pkg>@<path>`, emitted
// by the program's generator whatever the build's target (erlang here), with
// the program unit it imports and nothing else; every unit passes the face
// oracle (its index read from its bytes, every import an export of the unit
// it names, typed alike) and compiles; the folder's core and std units are
// the bytes a `wasi` build with the units writes into `out/wasm/`; a second
// stage over the same analysis takes every unit from the cache (1058 (2));
// and the stage changes nothing of the program's own emit.
test "wat: comptime units ---- a module declaring a decorator has its comptime unit, whatever the target" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    const ru = @import("../wat/runtime_unit.zig");
    const cu = @import("../wat/comptime_units.zig");
    const engine = @import("../wat/engine.zig");
    const modules = [_]codegen.Module{
        .{ .path = "lib", .source =
        \\pub fn twice(n: i32) -> i32 {
        \\    return n * 2;
        \\}
        },
        .{ .path = "plain", .source =
        \\pub fn unused(n: i32) -> i32 {
        \\    return n + 1;
        \\}
        },
        .{ .path = "main", .source =
        \\import {compiler, io.terminal.print} from "std";
        \\import {twice} from "lib";
        \\
        \\fn label(syntax decl: unknown) -> void {
        \\    compiler.addMember("pub fn label() -> string { return \"the " + compiler.name(decl)! + "\"; }");
        \\}
        \\
        \\#[label]
        \\type City(name: string)
        \\
        \\pub fn main() -> void {
        \\    print(City.label());
        \\    print(twice(21));
        \\    print("a,b".split(","));
        \\}
        },
    };
    const cfg = h.configs[1];
    var without = try codegen.generateWith(a, &modules, io, cfg, .{ .execute = false });
    defer {
        for (without.items) |*o| o.result.deinit(a);
        without.deinit(a);
    }
    var session = try codegen.analyse(a, &modules, io, cfg);
    defer session.deinit(a);
    // A store in memory: the first stage fills it, the second takes every
    // unit from it and emits nothing.
    const Store = struct {
        map: std.AutoHashMapUnmanaged(cu.Key, []u8) = .empty,
        gets: usize = 0,
        hits: usize = 0,
        fn get(ctx: *anyopaque, key: cu.Key) ?[]const u8 {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            self.gets += 1;
            const v = self.map.get(key) orelse return null;
            self.hits += 1;
            return v;
        }
        fn put(ctx: *anyopaque, key: cu.Key, bytes: []const u8) void {
            const self: *@This() = @ptrCast(@alignCast(ctx));
            const copy = std.testing.allocator.dupe(u8, bytes) catch return;
            self.map.put(std.testing.allocator, key, copy) catch std.testing.allocator.free(copy);
        }
    };
    var store: Store = .{};
    defer {
        var it = store.map.valueIterator();
        while (it.next()) |v| a.free(v.*);
        store.map.deinit(a);
    }
    const iface: cu.Cache = .{ .ctx = &store, .get = Store.get, .put = Store.put };
    var units = try codegen.comptimeUnits(a, session.outputs.items, cfg, iface);
    defer {
        for (units.items) |*o| o.result.deinit(a);
        units.deinit(a);
    }
    try std.testing.expectEqual(@as(usize, 0), store.hits);
    try std.testing.expectEqual(units.items.len, store.map.count());
    var again = try codegen.comptimeUnits(a, session.outputs.items, cfg, iface);
    defer {
        for (again.items) |*o| o.result.deinit(a);
        again.deinit(a);
    }
    try std.testing.expectEqual(units.items.len, store.hits);
    try std.testing.expectEqual(units.items.len, again.items.len);
    for (units.items, again.items) |x, y| try std.testing.expectEqualSlices(u8, x.result.wasm.?, y.result.wasm.?);
    // The stage changes nothing of the program's own emit.
    var with = try codegen.emit(a, session.outputs.items, cfg);
    defer {
        for (with.items) |*o| o.result.deinit(a);
        with.deinit(a);
    }
    try std.testing.expectEqual(without.items.len, with.items.len);
    for (with.items, without.items) |x, y| try std.testing.expectEqualStrings(y.result.js, x.result.js);

    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    const rt = try ru.get();
    var program: std.ArrayListUnmanaged(cu.Unit) = .empty;
    for (units.items) |o| {
        if (o.result.failed()) {
            std.debug.print("\n=== comptime unit of {s} refused\n", .{o.name});
            return error.TestUnexpectedResult;
        }
        const bin = o.result.wasm orelse return error.TestUnexpectedResult;
        const stems = try ru.unitsOf(ar, bin);
        try program.append(ar, .{ .stem = stems[stems.len - 1], .bytes = bin });
    }
    // `main` declares the decorator; `lib` is the program unit it imports;
    // `plain`, which no comptime module reaches, is not in the folder.
    try std.testing.expectEqual(@as(usize, 2), program.items.len);
    try std.testing.expectEqualStrings("test@lib", program.items[0].stem);
    try std.testing.expectEqualStrings("test@main", program.items[1].stem);

    // The face oracle over every comptime unit.
    for (program.items) |p| {
        const face = try ru.faceOfBytes(ar, p.bytes);
        var lines = std.mem.tokenizeScalar(u8, face.text, '\n');
        while (lines.next()) |l| {
            const head = "    (import \"";
            if (!std.mem.startsWith(u8, l, head)) continue;
            const rest = l[head.len..];
            const q = std.mem.indexOfScalar(u8, rest, '"').?;
            const module = rest[0..q];
            const unit_face = if (std.mem.eql(u8, module, ru.name)) rt.core_face else if (rt.unit(module)) |u| u.face else for (program.items) |o| {
                if (std.mem.eql(u8, o.stem, module)) break try ru.faceOfBytes(ar, o.bytes);
            } else {
                std.debug.print("\n=== {s} imports {s}, no unit of the folder\n", .{ p.stem, module });
                return error.TestUnexpectedResult;
            };
            const want = try std.fmt.allocPrint(ar, "    (export {s}", .{rest[q + 2 ..]});
            if (std.mem.indexOf(u8, unit_face.text, want[0 .. want.len - 1]) == null) {
                std.debug.print("\n=== {s}: no export for {s}\n", .{ p.stem, l });
                return error.TestUnexpectedResult;
            }
        }
    }

    // The folder's files: the core first, std's units, then the modules';
    // each compiles.
    const files = try cu.files(ar, program.items);
    try std.testing.expectEqualStrings(ru.file_name, files[0].name);
    try std.testing.expectEqualStrings("test@main.wasm", files[files.len - 1].name);
    for (files) |f| {
        var failure: ?[]u8 = null;
        const pc = (try engine.precompiled(a, io, null, f.bytes, .module, false, &failure)) orelse {
            std.debug.print("\n=== {s} refused: {s}\n", .{ f.name, failure.? });
            a.free(failure.?);
            return error.TestUnexpectedResult;
        };
        pc.code.deinit();
    }

    // The core and std units are `out/wasm/`'s bytes: what a `wasi` build
    // with the units writes beside its entry (`build.zig` `writeRuntimeUnits`).
    var wcfg = h.configs[3];
    wcfg.wasm_artifact = true;
    wcfg.wasm_units = true;
    var wasm = try codegen.generateWith(a, &modules, io, wcfg, .{ .execute = false });
    defer {
        for (wasm.items) |*o| o.result.deinit(a);
        wasm.deinit(a);
    }
    var out_wasm: std.StringHashMapUnmanaged([]const u8) = .empty;
    try out_wasm.put(ar, ru.file_name, rt.core_bytes);
    for (wasm.items) |o| {
        const bin = o.result.wasm orelse continue;
        if (!ru.importsRuntime(bin)) continue;
        for (try rt.closure(ar, (try ru.importsOf(ar, bin)).units)) |u| try out_wasm.put(ar, u.file_name, u.bytes);
    }
    var shared: usize = 0;
    for (files) |f| {
        if (!std.mem.startsWith(u8, f.name, "std@")) continue;
        const theirs = out_wasm.get(f.name) orelse {
            std.debug.print("\n=== {s} is in out/wasm-comptime/ and not in out/wasm/\n", .{f.name});
            return error.TestUnexpectedResult;
        };
        try std.testing.expectEqualSlices(u8, theirs, f.bytes);
        shared += 1;
    }
    try std.testing.expect(shared >= 2);
}

// Decision 1032 (2), (3), 1034 (5), (8) — piece R2: `runner.runEntry` composes
// a program from its unit files (the entry's `botopink.units`: the core,
// std's units, the program's own `test@lib`, the entry), each loaded through
// the `.cwasm` cache by its bytes, the frame precompiled beside them; it
// answers what the program prints, a missing unit is named, and a program
// needing `http` is given `wasi:http`.
test "wat: units ---- runner.runEntry composes a two-module program from its unit files through the .cwasm cache" {
    const a = std.testing.allocator;
    const io = std.testing.io;
    const ru = @import("../wat/runtime_unit.zig");
    const runner = @import("../wat/runner.zig");
    const test_scratch = @import("test_scratch");
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    var outputs = try h.generate(a, &.{
        .{ .path = "lib", .source =
        \\pub type Point(x: i32, y: i32)
        \\
        \\pub fn greet(name: string) -> string {
        \\    return "hi, " + name;
        \\}
        \\
        \\pub fn shift(p: Point, d: i32) -> Point {
        \\    return Point(x: p.x + d, y: p.y);
        \\}
        },
        .{ .path = "main", .source =
        \\import {io.terminal.print} from "std";
        \\import {greet, shift, Point} from "lib";
        \\
        \\fn main() -> void {
        \\    print(greet("bo"));
        \\    val p = shift(Point(x: 1, y: 2), 3);
        \\    print(p.x);
        \\}
        },
    }, io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    const dir = test_scratch.path(io, "codegen/run_entry/out");
    const cache = test_scratch.path(io, "codegen/run_entry/cache");
    const cwd = std.Io.Dir.cwd();
    cwd.deleteTree(io, dir) catch {};
    cwd.deleteTree(io, cache) catch {};
    try cwd.createDirPath(io, dir);
    // The files a build writes: each program unit, the core and std's units.
    var entry: ?[]const u8 = null;
    for (outputs.items) |o| {
        const bin = o.result.wasm orelse continue;
        const stems = try ru.unitsOf(ar, bin);
        if (stems.len == 0) continue;
        try cwd.writeFile(io, .{ .sub_path = try std.fmt.allocPrint(ar, "{s}/{s}.wasm", .{ dir, stems[stems.len - 1] }), .data = bin });
        if (std.mem.eql(u8, o.name, "main")) entry = bin;
    }
    const bin = entry orelse return error.ModuleDidNotCompile;
    const rt = try ru.get();
    try cwd.writeFile(io, .{ .sub_path = try std.fmt.allocPrint(ar, "{s}/{s}", .{ dir, ru.file_name }), .data = rt.core_bytes });
    for (try rt.closure(ar, try ru.unitsOf(ar, bin))) |u|
        try cwd.writeFile(io, .{ .sub_path = try std.fmt.allocPrint(ar, "{s}/{s}", .{ dir, u.file_name }), .data = u.bytes });

    const out = try runner.runEntry(a, io, cache, false, bin, .{ .dir = dir }, .{ .stdout = .capture });
    defer out.deinit(a);
    if (out.trap) |t| std.debug.print("\n=== runEntry: {s}\n", .{t});
    try std.testing.expectEqual(@as(i32, 0), out.status);
    try std.testing.expectEqualStrings("hi, bo\n4\n", out.stdout orelse "");

    var n: usize = 0;
    var d = try cwd.openDir(io, cache, .{ .iterate = true });
    defer d.close(io);
    var it = d.iterate();
    while (try it.next(io)) |e| if (std.mem.endsWith(u8, e.name, ".cwasm")) {
        n += 1;
    };
    // What this process loaded before (`load`'s LRU) is not written again:
    // at most one file per unit and one for the frame (`tests/wasm_runner.sh`
    // counts them exactly, a process per program).
    try std.testing.expect(n >= 1 and n <= (try ru.unitsOf(ar, bin)).len + 1);

    // Decision 1034 (6), (7) — a program needing `http` is given `wasi:http`
    // beside WASI p2: the composed program links and answers the same.
    var http_needs: bpAst.WasmNeeds = .initEmpty();
    http_needs.insert(.http);
    const with_http = try runner.runEntry(a, io, cache, false, bin, .{ .dir = dir }, .{ .stdout = .capture, .needs = http_needs });
    defer with_http.deinit(a);
    if (with_http.trap) |t| std.debug.print("\n=== runEntry (http): {s}\n", .{t});
    try std.testing.expectEqual(@as(i32, 0), with_http.status);
    try std.testing.expectEqualStrings("hi, bo\n4\n", with_http.stdout orelse "");

    // A unit missing beside the entry is named, never run.
    const missing = try runner.runEntry(a, io, cache, false, bin, .{ .dir = cache }, .{ .stdout = .capture });
    defer missing.deinit(a);
    try std.testing.expectEqual(@as(i32, 1), missing.status);
    try std.testing.expect(std.mem.startsWith(u8, missing.trap orelse "", "no unit std@__rt.wasm beside the entry"));
}

/// The sources of a conformance case's modules, read from its `src/`
/// (tests run with `modules/compiler-core` as their directory).
fn caseSources(ar: std.mem.Allocator, case: []const u8, names: []const []const u8) ![]codegen.Module {
    const io = std.testing.io;
    const out = try ar.alloc(codegen.Module, names.len);
    for (names, out) |n, *o| {
        const path = try std.fmt.allocPrint(ar, "../../conformance/modules/{s}/src/{s}.bp", .{ case, n });
        o.* = .{ .path = n, .source = try std.Io.Dir.cwd().readFileAlloc(io, path, ar, .limited(1 << 20)) };
    }
    return out;
}

/// Each program unit's bytes (by its stem) and the entry `entry_name`'s.
fn programUnits(ar: std.mem.Allocator, outputs: anytype, entry_name: []const u8) !struct { program: []const @import("../wat/wat_emitter.zig").UnitBytes, entry: []const u8 } {
    const ru = @import("../wat/runtime_unit.zig");
    var program: std.ArrayListUnmanaged(@import("../wat/wat_emitter.zig").UnitBytes) = .empty;
    var entry: ?[]const u8 = null;
    for (outputs.items) |o| {
        const bin = o.result.wasm orelse continue;
        const stems = try ru.unitsOf(ar, bin);
        if (stems.len == 0) continue;
        try program.append(ar, .{ .name = stems[stems.len - 1], .bytes = bin });
        if (std.mem.eql(u8, o.name, entry_name)) entry = bin;
    }
    return .{ .program = program.items, .entry = entry orelse return error.ModuleDidNotCompile };
}

// Decision 1055 (4) — cell `wasm_closure_crosses_units`, run through the
// units' frame (`Config.wasm_units`): `maker` exports `adder` (answering a
// closure) and `apply` (taking one), which `main` imports instead of linking;
// a closure made in `maker` is called in `main`, one made in `main` in `maker`,
// one goes to `std@array`'s `map`, a type's method is taken as a value, one
// captures `maker`'s module `val` and closures of eleven parameters cross
// both ways (decision 1076 (2)) — the cell's own answers.
test "wat: units ---- decision 1055 (4): a closure crosses units (cell wasm_closure_crosses_units)" {
    const a = std.testing.allocator;
    const ru = @import("../wat/runtime_unit.zig");
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    const srcs = try caseSources(ar, "decisions-taken/wasm_unit_per_module_linked-1021/cases/wasm_closure_crosses_units", &.{ "maker", "main" });
    var outputs = try h.generate(a, srcs, std.testing.io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    const pu = try programUnits(ar, &outputs, "main");
    const main_text = (try ru.faceOfBytes(ar, pu.entry)).text;
    try std.testing.expect(std.mem.indexOf(u8, main_text, "(import \"test@maker\" \"adder\" ") != null);
    try std.testing.expect(std.mem.indexOf(u8, main_text, "(import \"test@maker\" \"apply\" ") != null);
    // Decision 1076 (2) — a closure of eleven parameters crosses too: no
    // arity is capped.
    try std.testing.expect(std.mem.indexOf(u8, main_text, "(import \"test@maker\" \"apply11\" ") != null);
    try std.testing.expect(std.mem.indexOf(u8, main_text, "(import \"test@maker\" \"sum11\" ") != null);
    const out = try runUnitsFrame(a, ar, pu.entry, pu.program);
    const want = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "../../conformance/modules/decisions-taken/wasm_unit_per_module_linked-1021/snapshot/main.snap", ar, .limited(1 << 20));
    try std.testing.expectEqualStrings(try snapSection(ar, want, "wasm_closure_crosses_units"), out);
}

/// A case's section of a self-checking module's `main.snap` as the program's
/// stdout: each `out <line>` of `== <case>`.
fn snapSection(ar: std.mem.Allocator, text: []const u8, case: []const u8) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var in = false;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |l| {
        if (std.mem.startsWith(u8, l, "== ")) {
            in = std.mem.eql(u8, l[3..], case);
            continue;
        }
        if (!in) continue;
        if (std.mem.startsWith(u8, l, "out ")) {
            try out.appendSlice(ar, l[4..]);
            try out.append(ar, '\n');
        } else if (std.mem.eql(u8, l, "out")) try out.append(ar, '\n');
    }
    return out.items;
}

test "wat: decision 1021 (10) ---- a Result of a type-token-bound parameter, a record's function field, an i64[] argument, a dispatched Result and a tuple compared against a literal in the GC lowering" {
    // Each was a value the GC lowering typed a word: `failed(string, …)`'s
    // `Result<T, string>` read through `unwrapOr("fallback")`; `m.make()`
    // through a field of a function type; `[3, 9, 4]` against `xs: i64[]`;
    // `store.get(key)` dispatched to implementers answering a `Result`;
    // `pair(5) == #(5, true)` against a `#(u64, bool)`.
    try h.assertWasmGcRunLog(std.testing.allocator,
        \\import {io.terminal.print} from "std";
        \\
        \\fn failed<T>(comptime t: type<T>, message: string) -> Result<T, string> {
        \\    throw message;
        \\}
        \\
        \\type Maker(make: fn() -> fn() -> string)
        \\
        \\fn sizeOf(xs: i64[], extra: u32) -> i32 {
        \\    return xs.length;
        \\}
        \\
        \\behavior Store {
        \\    fn get(self: Self, key: string) -> Result<string, string>;
        \\}
        \\
        \\type Memory(prefix: string) implement Store {
        \\    fn get(self: Self, key: string) -> Result<string, string> {
        \\        if (key == "") throw "empty key";
        \\        return self.prefix + key;
        \\    }
        \\}
        \\
        \\fn read(store: Store, key: string) -> string {
        \\    return store.get(key).unwrapOr("none");
        \\}
        \\
        \\fn pair(n: u64) -> #(u64, bool) {
        \\    return #(n, true);
        \\}
        \\
        \\pub fn main() -> void {
        \\    val s = failed(string, "gone");
        \\    print(s.unwrapOr("fallback").length);
        \\    val m = Maker(make: { -> { -> "made" } });
        \\    val f: fn() -> string = m.make();
        \\    print(f());
        \\    print(sizeOf([3, 9, 4], 1));
        \\    print(read(Memory(prefix: "m:"), "a"));
        \\    print(read(Memory(prefix: "m:"), ""));
        \\    print(pair(5) == #(5, true));
        \\    print(pair(5) != #(6, true));
        \\}
    , "8\nmade\n3\nm:a\nnone\ntrue\ntrue\n");
}

// Decision 1055 (2), (3) — cell `wasm_foreign_type_prints`, run through the
// units' frame: `shapes` builds a record, a variant and a `Display` type and
// exports the functions that answer them, which `main` imports; `main` prints,
// compares, tests and displays them — alone, in an array, a tuple and an
// `unknown` — each declared type's `$__tinfo` reaching its printer and its
// equality through the core.
test "wat: units ---- decision 1055 (2), (3): a foreign type prints, compares and displays (cell wasm_foreign_type_prints)" {
    const a = std.testing.allocator;
    const ru = @import("../wat/runtime_unit.zig");
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    const case = "decisions-taken/wasm_unit_per_module_linked-1021/cases/wasm_foreign_type_prints";
    const srcs = try caseSources(ar, case, &.{ "shapes", "main" });
    var outputs = try h.generate(a, srcs, std.testing.io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    const pu = try programUnits(ar, &outputs, "main");
    const main_text = (try ru.faceOfBytes(ar, pu.entry)).text;
    try std.testing.expect(std.mem.indexOf(u8, main_text, "(import \"test@shapes\" \"origin\" ") != null);
    try std.testing.expect(std.mem.indexOf(u8, main_text, "(import \"test@shapes\" \"anything\" ") != null);
    const out = try runUnitsFrame(a, ar, pu.entry, pu.program);
    const want = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "../../conformance/modules/decisions-taken/wasm_unit_per_module_linked-1021/snapshot/main.snap", ar, .limited(1 << 20));
    try std.testing.expectEqualStrings(try snapSection(ar, want, "wasm_foreign_type_prints"), out);
}

// Decision 1055 (6), (8) — cell `wasm_val_methods_cross_units`, run through
// the units' frame: `config` declares a module `val` whose initialiser
// prints, a type's own method and the method of a behavior it implements;
// `reader` and `main` both read the `val` — through `config`'s accessor,
// never re-running its initialiser — and call the methods `config` exports,
// never linking their bodies.
test "wat: units ---- decision 1055 (6): a module val initialised once, methods called across units (cell wasm_val_methods_cross_units)" {
    const a = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const ar = arena.allocator();
    var cfg = h.configs[3];
    cfg.wasm_artifact = true;
    cfg.wasm_units = true;
    const case = "decisions-taken/wasm_unit_per_module_linked-1021/cases/wasm_val_methods_cross_units";
    const srcs = try caseSources(ar, case, &.{ "config", "reader", "main" });
    var outputs = try h.generate(a, srcs, std.testing.io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(a);
        outputs.deinit(a);
    }
    const pu = try programUnits(ar, &outputs, "main");
    try expectUnitsLink(ar, pu.program);
    // The `val` is `config`'s alone: `reader` and `main` read it through its
    // accessor and call its methods, never linking their bodies.
    const ru = @import("../wat/runtime_unit.zig");
    for ([_][]const u8{ "reader", "main" }) |name| {
        const bin = for (outputs.items) |o| {
            if (std.mem.eql(u8, o.name, name)) break o.result.wasm.?;
        } else return error.ModuleDidNotCompile;
        const face = (try ru.faceOfBytes(ar, bin)).text;
        for ([_][]const u8{ "\"get_seed\"", "\"Box_doubled\"", "\"Box_name\"" }) |x| {
            const want = try std.fmt.allocPrint(ar, "(import \"test@config\" {s} ", .{x});
            if (std.mem.indexOf(u8, face, want) == null) {
                std.debug.print("\n=== {s}: no {s}\n", .{ name, want });
                return error.TestUnexpectedResult;
            }
        }
    }
    const out = try runUnitsFrame(a, ar, pu.entry, pu.program);
    const want = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "../../conformance/modules/decisions-taken/wasm_unit_per_module_linked-1021/snapshot/main.snap", ar, .limited(1 << 20));
    try std.testing.expectEqualStrings(try snapSection(ar, want, "wasm_val_methods_cross_units"), out);
}
