//! commonJS-only fixtures (front `01-compiler/04-js`): behaviour this backend
//! answers alone, run under node with `assertJsRunLog` so no other backend's
//! snapshot directory moves.

const std = @import("std");
const h = @import("helpers.zig");
const stdWasm = @import("std_wasm");
const jsPrelude = @import("../js/js_prelude.zig");

// A `default fn` of a primitive behavior (`behavior String`, std's
// `primitives.bp` or a program's own) becomes a prototype patch
// (`String.prototype.m = function () { … }`), and its body is lowered with no
// per-call answer from inference: the checker does not type it. The receiver
// is still known — it is the behavior's own primitive — so a call on `self`
// lowers as the same call on a typed `string` would. `self.length()` was
// written as it stands: `TypeError: self.length is not a function`, because
// JavaScript's `length` is a property.
test "js: primitive behavior default fn ---- a call on self lowers as on the declared receiver" {
    try h.assertJsRunLog(std.testing.allocator,
        \\behavior String {
        \\    default fn twiceLength(self: Self) -> i32 {
        \\        return self.length() * 2;
        \\    }
        \\
        \\    default fn firstChar(self: Self) -> ?string {
        \\        return self.at(0);
        \\    }
        \\}
        \\
        \\pub fn main() {
        \\    print("abc".twiceLength());
        \\    print("".twiceLength());
        \\    print("xy".firstChar());
        \\    print("".firstChar());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\6
        \\0
        \\x
        \\null
        \\
    );
}

// The same body answering a `@Result`: its `return` and `throw` build the
// `{ ok }` / `{ error }` object every `@Result` is on this backend. The body
// is checked against its signature (`01-checker`), so it builds the value with
// `return` / `throw` — `Ok(v)` / `Error(e)` are never constructors in an
// expression (decision 208).
test "js: primitive behavior default fn ---- return and throw build the @Result" {
    try h.assertJsRunLog(std.testing.allocator,
        \\behavior String {
        \\    default fn nonEmpty(self: Self) -> Result<string, string> {
        \\        if (self == "") throw "empty";
        \\        return self;
        \\    }
        \\}
        \\
        \\pub fn main() {
        \\    print("ab".nonEmpty().isOk());
        \\    print("".nonEmpty().isError());
        \\    print(case "ab".nonEmpty() {
        \\        Ok(v) -> v;
        \\        Error(e) -> e;
        \\    });
        \\    print(case "".nonEmpty() {
        \\        Ok(v) -> v;
        \\        Error(e) -> e;
        \\    });
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\true
        \\true
        \\ab
        \\empty
        \\
    );
}

// Decision 214 — the NaN half of `f64`'s total-order `==`, which the
// four-target cell `modules/decisions-taken/f64_equality_total_order-214/run/src/cases/f64_equality_total_order` cannot carry (erlang and
// beam never produce a NaN): `NaN == NaN` is `true` bare and inside a record,
// a tuple, an array and a variant (`Object.is`, and the per-type equality's
// field compare), `NaN != NaN` is `false`, and NaN against a number is
// unequal. `<` stays IEEE (`NaN < 1.0` is `false`).
test "js: f64 ---- NaN equals NaN under ==, bare and inside composites" {
    try h.assertJsRunLog(std.testing.allocator,
        \\type F(x: f64)
        \\type V {
        \\    W(x: f64),
        \\    Z,
        \\}
        \\fn zero() -> f64 {
        \\    return 0.0;
        \\}
        \\fn main() {
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

test "js: a library's enum class is its closure's alone, whatever its consumer declares" {
    // Decision 509 (2), 144 B-66: `shelf`'s `Square(side)` reads `side` by
    // name — `shelf`'s closure declares one `Square`. `rival`'s
    // `Square(side, color)` is not in it; the variant table used to be the
    // whole program's, so under `crowded` alone the class gained `get $0()`
    // and the `case` destructured `{ $0: side }`.
    try h.assertLibrarySameUnder(std.testing.allocator, .commonJS, &.{ "shelf", "rival" }, "shelf", &h.closure_plain, &h.closure_crowded);
}

// 144 B-78: JavaScript has one number type, so a float written as text lost its
// decimal part (`"${5.0}"` was `5`, `1e21` was `1e+21`). A template hole, a
// `string + f64` and `toString()` on a float now go through `__bp_f64`, the
// formatter `@print` shares: erlang, beam and wasm's text.
test "js: f64 text ---- a template hole, toString and a string + keep the decimal part" {
    try h.assertJsRunLog(std.testing.allocator,
        \\pub fn main() {
        \\    val five = 5.0;
        \\    print("${5.0}");
        \\    print(5.0.toString());
        \\    print("x" + 2.0);
        \\    print("${1.0e21}");
        \\    print("${-3.0}");
        \\    print("${0.25}");
        \\    print("v=${five}");
        \\    print(five.toString());
        \\    print(1.0e-7);
        \\    print(7);
        \\    print("${7}");
        \\    print(1000.0, 1.0e20, 0.00001, 1200.0);
        \\    print("${9007199254740992.0}", 9007199254740991.0);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\5.0
        \\5.0
        \\x2.0
        \\1.0e21
        \\-3.0
        \\0.25
        \\v=5.0
        \\5.0
        \\1.0e-7
        \\7
        \\7
        \\1.0e3 1.0e20 1.0e-5 1.2e3
        \\9.007199254740992e15 9007199254740991.0
        \\
    );
}

// Decision 530: a template hole writes the text `@print` writes for every value. JavaScript's
// coercion wrote `[object Object]` for a record and `1,2,3` for an array; a record, an array, a
// tuple (a JS array, told by its static shape) and a float inside them now go through
// `__bp_text`.
test "js: template hole ---- a record, an array and a tuple are written as @print writes them" {
    try h.assertJsRunLog(std.testing.allocator,
        \\type Point(x: i32, y: i32)
        \\
        \\pub fn main() {
        \\    val p = Point(x: 1, y: 2);
        \\    val xs = [1, 2, 3];
        \\    val t = #(1, "a");
        \\    val fs = [1.5, 2.0];
        \\    print("${p} ${xs} ${t} ${fs}");
        \\    print("p=" + p);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\Point(x: 1, y: 2) [1, 2, 3] #(1, "a") [1.5, 2.0]
        \\p=Point(x: 1, y: 2)
        \\
    );
}

// Decision 521: `__bp_f64` is std-wasm's `number.shortFloat` ported, so the two
// answer one text — every float below, drawn from its bits, is printed by node
// and compared with std-wasm's own answer for it.
test "js: f64 text ---- __bp_f64 answers std-wasm's shortFloat" {
    const gpa = std.testing.allocator;
    var src: std.ArrayListUnmanaged(u8) = .empty;
    defer src.deinit(gpa);
    var want: std.ArrayListUnmanaged(u8) = .empty;
    defer want.deinit(gpa);
    try src.appendSlice(gpa, "import {io.terminal.print} from \"std\";\npub fn main() {\n");
    var prng = std.Random.DefaultPrng.init(521);
    const r = prng.random();
    var n: usize = 0;
    while (n < 400) {
        // Every exponent equally likely, then a few round values.
        const f: f64 = if (n < 360) @bitCast(r.int(u64)) else std.math.pow(f64, 10.0, @floatFromInt(@as(i32, @intCast(n)) - 380));
        if (!std.math.isFinite(f)) continue;
        var buf: [64]u8 = undefined;
        const text = stdWasm.number.shortFloat(f, &buf);
        try src.print(gpa, "    print({s});\n", .{text});
        try want.print(gpa, "{s}\n", .{text});
        n += 1;
    }
    try src.appendSlice(gpa, "}\n");
    try h.assertJsRunLog(gpa, src.items, want.items);
}

// Decision 521: `trim` removes std-wasm's whitespace (space, tab, LF, CR, VT,
// FF) and keeps a no-break space or an em space, which the engine's strips.
test "js: trim ---- std-wasm's whitespace set, a NBSP stays" {
    try h.assertJsRunLog(
        std.testing.allocator,
        \\pub fn main() {
        \\    print("[" + "\u{a0}x\u{a0} ".trim() + "]");
        \\    print("[" + " \t\n\r\u{b}\u{c}x\u{2003}\t ".trim() + "]");
        \\    print("[" + "\u{a0} x ".trimStart() + "]");
        \\    print("[" + " x \u{a0}".trimEnd() + "]");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        "[\u{a0}x\u{a0}]\n[x\u{2003}]\n[\u{a0} x ]\n[ x \u{a0}]\n",
    );
}

// Decisions 443, 521: `toUpper` / `toLower` are std-wasm's case mapping on
// this backend too — its table written into the helper. Every code point the
// table maps, mapped by node, against std-wasm's own `text.caseInto`.
test "js: case mapping ---- toUpper and toLower answer std-wasm's text" {
    const gpa = std.testing.allocator;
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var src: std.ArrayListUnmanaged(u8) = .empty;
    var want: std.ArrayListUnmanaged(u8) = .empty;
    try src.appendSlice(arena, "import {io.terminal.print} from \"std\";\npub fn main() {\n");
    for ([_]stdWasm.text.Case{ .upper, .lower }) |case| {
        // Every code point that maps under `case`, in runs of 64.
        var word: std.ArrayListUnmanaged(u8) = .empty;
        var cp: u21 = 0;
        while (cp < jsPrelude.case_limit) : (cp += 1) {
            if (cp >= 0xD800 and cp <= 0xDFFF) continue;
            var m: [3]u21 = undefined;
            const mapped = stdWasm.text.mapCodepoint(&m, cp, case);
            if (mapped.len == 1 and mapped[0] == cp) continue;
            var b: [4]u8 = undefined;
            const len = try std.unicode.utf8Encode(cp, &b);
            try word.appendSlice(arena, b[0..len]);
            if (word.items.len < 64 * 3) continue;
            try flushCase(arena, &src, &want, word.items, case);
            word = .empty;
        }
        if (word.items.len > 0) try flushCase(arena, &src, &want, word.items, case);
    }
    try src.appendSlice(arena, "    print(\"ΟΔΟΣ\".toLower());\n}\n");
    try want.appendSlice(arena, "οδοσ\n");
    try h.assertJsRunLog(gpa, src.items, want.items);
}

fn flushCase(arena: std.mem.Allocator, src: *std.ArrayListUnmanaged(u8), want: *std.ArrayListUnmanaged(u8), word: []const u8, case: stdWasm.text.Case) !void {
    try src.print(arena, "    print(\"{s}\".{s}());\n", .{ word, if (case == .upper) "toUpper" else "toLower" });
    const out = try arena.alloc(u8, stdWasm.text.caseLength(word, case, false));
    stdWasm.text.caseInto(out, word, case, false);
    try want.print(arena, "{s}\n", .{out});
}

// `jsPrelude.caseTable` reads the code points below `case_limit`: no case
// mapping of std-wasm's tables lies past it.
test "js: case mapping ---- no code point past the table's limit maps" {
    var cp: u21 = jsPrelude.case_limit;
    while (cp <= 0x10FFFF) : (cp += 1) {
        for ([_]stdWasm.text.Case{ .upper, .lower }) |case| {
            var m: [3]u21 = undefined;
            const mapped = stdWasm.text.mapCodepoint(&m, cp, case);
            try std.testing.expect(mapped.len == 1 and mapped[0] == cp);
        }
    }
}

// 144 B-78: a record's or a variant's `f64` field prints with its decimal
// part — the class carries each float field's print shape (`__bp_s`).
test "js: f64 text ---- a record's and a variant's float field" {
    try h.assertJsRunLog(std.testing.allocator,
        \\type Pt(x: f64, n: i32, ys: f64[])
        \\type Shape {
        \\    Circle(r: f64),
        \\    Dot,
        \\}
        \\
        \\pub fn main() {
        \\    print(Pt(x: 1.0, n: 3, ys: [2.0]));
        \\    print([Shape.Circle(r: 2.0), Shape.Dot]);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\Pt(x: 1.0, n: 3, ys: [2.0])
        \\[Shape.Circle(r: 2.0), Shape.Dot]
        \\
    );
}

// Decision 346 — `Bytes` on this backend: in and out of text, length, slice,
// concat, `==`, and the `Error` of bytes that are not UTF-8.
const bytes_src =
    \\pub fn main() {
    \\    val b = Bytes.fromUtf8("héllo");
    \\    print(b.length());
    \\    print(b.slice(1, 3).toUtf8().unwrapOr("?"));
    \\    print(b.slice(1, 2).toUtf8().isError());
    \\    val j = Bytes.fromUtf8("ab").concat(Bytes.fromUtf8("cd"));
    \\    print(j[2..].toUtf8().unwrapOr("?"));
    \\    print(j == Bytes.fromUtf8("abcd"));
    \\}
    \\
    \\import {io.terminal.print} from "std";
;
const bytes_log = "6\né\ntrue\ncd\ntrue\n";

test "js: decision 346 ---- Bytes is a Uint8Array, its methods patched on its prototype" {
    try h.assertJsRunLog(std.testing.allocator, bytes_src, bytes_log);
}

// 144 B-20 Conformance — a link after a guarded enum call (`optEnumCall`)
// continues its `?.` chain: `.length` was read off `undefined`.
test "js: decision 330 ---- a method after recv?.m() over an enum method stays under the guard" {
    try h.assertJsRunLog(std.testing.allocator,
        \\type Val {
        \\    Text(s: string),
        \\
        \\    fn str(self: Self) -> string {
        \\        return case self {
        \\            Text(s: t) -> t;
        \\        };
        \\    }
        \\}
        \\fn find(k: i32) -> ?Val {
        \\    return if (k == 1) Val.Text(s: "abc") else null;
        \\}
        \\pub fn main() {
        \\    print(find(1)?.str().length() ?? -1);
        \\    print(find(0)?.str().length() ?? -1);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\3
        \\-1
        \\
    );
}

// 144 B-78 Conformance (decision 521) — a string method reached through `?.`,
// or as a link continuing the chain, is std-wasm's: the engine's `trim`
// dropped the NBSP and its `toLowerCase` wrote a final sigma.
test "js: decision 521 ---- trim and toLower through ?. are std-wasm's, guarded" {
    try h.assertJsRunLog(
        std.testing.allocator,
        \\pub fn main() {
        \\    val o: ?string = "\u{a0}ΟΔΟΣ ";
        \\    val none: ?string = null;
        \\    print("[" + (o?.trim() ?? "-") + "]");
        \\    print("[" + (o?.trim().toLower() ?? "-") + "]");
        \\    print(none?.trim().toLower() ?? "absent");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        "[\u{a0}ΟΔΟΣ]\n[\u{a0}οδοσ]\nabsent\n",
    );
}

test "commonJS: a labelled break leaves the outer loop from a case arm of an inner one" {
    // `break :outer` was a bare `break` of the inner loop; the `case` arm's
    // box now names the label, and the loop is a JS labelled loop.
    try h.assertJsRunLog(std.testing.allocator,
        \\fn sumBeforeTwo(xs: i32[], ys: i32[]) -> i32 {
        \\    var s = 0;
        \\    for :outer (xs) { x ->
        \\        for (ys) { y ->
        \\            case y {
        \\                2 { break :outer; }
        \\                _ { }
        \\            }
        \\            s = s + x * y;
        \\        }
        \\    }
        \\    return s;
        \\}
        \\
        \\pub fn main() {
        \\    print(sumBeforeTwo([1, 2], [1, 2, 3]));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "1\n");
}

test "commonJS: a bare return in a yielding case arm ends the generator" {
    try h.assertJsRunLog(std.testing.allocator,
        \\iter fn items(n: i32) -> Iter<i32> {
        \\    yield 0;
        \\    case n {
        \\        0 {
        \\            yield 1;
        \\            return;
        \\        }
        \\        _ { yield 2; }
        \\    }
        \\    yield 9;
        \\}
        \\
        \\pub fn main() {
        \\    for (items(0)) { v -> print(v); }
        \\    for (items(1)) { v -> print(v); }
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "0\n1\n0\n2\n9\n");
}

test "commonJS: a labelled continue starts the outer loop's next round from a case arm of an inner one" {
    try h.assertJsRunLog(std.testing.allocator,
        \\fn run(xs: i32[], ys: i32[]) -> i32 {
        \\    var s = 0;
        \\    for :outer (xs) { x ->
        \\        for (ys) { y ->
        \\            case x * 10 + y {
        \\                12 { continue :outer; }
        \\                _ { }
        \\            }
        \\            s = s + x * y;
        \\        }
        \\        s = s + 100;
        \\    }
        \\    return s;
        \\}
        \\
        \\pub fn main() {
        \\    print(run([1, 2], [1, 2, 3]));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "113\n");
}
