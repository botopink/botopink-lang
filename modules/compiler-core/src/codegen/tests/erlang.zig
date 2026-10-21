//! codegen: the erlang backend's own rows (1.0.11-beta `01-compiler/02-erlang`)
//! — fixtures that run the emitted module (`assertErlangRunLog`) and check its
//! text, for shapes no snapshot of a green program shows. One file per backend
//! (the README's rule), so the beam and wasm twins of a row live in their own.

const std = @import("std");
const h = @import("helpers.zig");
const prelude = @import("std_prelude");

test "erlang: a prelude default fn body ignores what inference recorded at the program's line and column" {
    // Inference keys a method call's lowering by line and column, with no
    // file. `Array.unique`'s body (`primitives.bp`) calls `out.append([x])`
    // on a local (inside an `if` since decision 217, so it lowers through
    // `'__bp_prim_append'/2`); a program whose own `s.trim()` sits at the same line and
    // column made the body's call `append(Out, [X])` — undefined, `erlc`
    // refused the module (the std-dedupe front's `exponent.startsWith("+")`
    // was the same lookup). The program is built so its call lands exactly
    // there, wherever `primitives.bp` keeps that line.
    const alloc = std.testing.allocator;
    const marker = "out = out.append([x])";
    const at = std.mem.indexOf(u8, prelude.primitives, marker) orelse return error.PreludeMarkerMoved;
    const line_start = if (std.mem.lastIndexOfScalar(u8, prelude.primitives[0..at], '\n')) |nl| nl + 1 else 0;
    const line = std.mem.count(u8, prelude.primitives[0..at], "\n") + 1;
    // The call's column is its `.`; `print(s.trim())`'s `.` is 7 past the pad.
    const dot = at + "out = out".len - line_start;
    try std.testing.expect(dot >= 7 and line > 4);

    var src: std.ArrayListUnmanaged(u8) = .empty;
    defer src.deinit(alloc);
    try src.appendSlice(alloc,
        \\pub fn main() -> void {
        \\    val s = " ab ";
        \\    print([1, 1, 2].unique());
        \\
    );
    for (4..line) |_| try src.appendSlice(alloc, "    //\n");
    try src.appendNTimes(alloc, ' ', dot - 7);
    try src.appendSlice(alloc,
        \\print(s.trim());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
    try h.assertErlangRunLog(alloc, src.items, "[1, 2]\nab\n", &.{"'__bp_prim_append'(Out, [X])"});
}

test "erlang: a prelude static's body ignores what inference recorded at the program's line and column" {
    // The associated twin of the test above. `array.repeat`'s erlang cell is
    // `body: arrayRepeatBody`, emitted into the consuming module as
    // `array_repeat/2`; a program whose own `s.trim()` sat at the line and
    // column of the body's inner `half.append(half)` made that call
    // `append(Half, Half)` — undefined, `erlc` refused the module (validation's
    // `decorators` met it with a `t.indexOf("<")`).
    const alloc = std.testing.allocator;
    const marker = "half.append(half).append([value])";
    const at = std.mem.indexOf(u8, prelude.primitives, marker) orelse return error.PreludeMarkerMoved;
    const line_start = if (std.mem.lastIndexOfScalar(u8, prelude.primitives[0..at], '\n')) |nl| nl + 1 else 0;
    const line = std.mem.count(u8, prelude.primitives[0..at], "\n") + 1;
    // The inner call's column is its `.`; `print(s.trim())`'s `.` is 7 past the pad.
    const dot = at + "half".len - line_start;
    try std.testing.expect(dot >= 7 and line > 4);

    var src: std.ArrayListUnmanaged(u8) = .empty;
    defer src.deinit(alloc);
    try src.appendSlice(alloc,
        \\pub fn main() -> void {
        \\    val s = " ab ";
        \\    print(array.repeat("a", 3).join(","));
        \\
    );
    for (4..line) |_| try src.appendSlice(alloc, "    //\n");
    try src.appendNTimes(alloc, ' ', dot - 7);
    try src.appendSlice(alloc,
        \\print(s.trim());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
    try h.assertErlangRunLog(alloc, src.items, "a,a,a\nab\n", &.{"'__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])"});
}

test "erlang: a default fn body lowers a local's method by the kind its declared types give it" {
    // Inference records no lowering inside an interface `default fn` body, so a
    // method on one of its locals was the bare local call — `unwrapOr(F, D)`,
    // undefined — or a run-time dispatch shim. The body's declared types give
    // each local its kind: `stringSlice0`'s `-> string`, `Array.at`'s `-> ?T`.
    // The program's own contracts are implemented for `string` and `array<T>`
    // (decision 799), so their bodies reach std's `startsWith` and `at`, and
    // `self` is the primitive.
    try h.assertErlangRunLog(std.testing.allocator,
        \\behavior Shout {
        \\    fn slice(self: Self, start: i32, end: ?i32 = null) -> string;
        \\
        \\    default fn tailShout(self: Self) -> string {
        \\        val tail = self.slice(1);
        \\        return if (tail.startsWith("+")) tail.toUpper() else tail;
        \\    }
        \\}
        \\
        \\StringShout implement Shout for string {};
        \\
        \\behavior FirstOr<T> {
        \\    fn at(self: Self<T>, index: i32) -> ?T;
        \\
        \\    default fn firstOr(self: Self<T>, d: T) -> T {
        \\        val f = self.at(0);
        \\        return f ?? d;
        \\    }
        \\}
        \\
        \\ArrFirstOr<T> implement FirstOr<T> for array<T> {};
        \\
        \\pub fn main() -> void {
        \\    print("a+b".tailShout());
        \\    print("ab".tailShout());
        \\    print([1, 2].firstOr(9));
        \\    val none: i32[] = [];
        \\    print(none.firstOr(9));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "+B\nb\n1\n9\n", &.{ "(string:prefix(Tail, <<\"+\">>) =/= nomatch)", "string:uppercase(Tail)" });
}

test "erlang: array.unique keeps each value's first occurrence" {
    // C-35: the prelude body is lowered with the kinds its declared types give
    // its locals (`var out: T[]`). Decision 217: every duplicate goes, not only
    // a consecutive one.
    try h.assertErlangRunLog(std.testing.allocator,
        \\pub fn main() -> void {
        \\    print([1, 2, 1, 3, 2].unique());
        \\    print([4].unique());
        \\    val none: i32[] = [];
        \\    print(none.unique());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "[1, 2, 3]\n[4]\n[]\n", &.{});
}

test "erlang: an entry point sets standard_io to unicode before anything prints" {
    // `erl` opens `standard_io` in the host locale's encoding: under `LANG=C`
    // `@print("é")` wrote the latin1 byte `0xE9` and `"\u{1F600}"` the text
    // `\x{1F600}`. The program sets it itself, first, so its output is the
    // same bytes under any locale (`modules/string/run/src/cases/string_literal_unicode_escape` run
    // with `LANG=C` is the measurement; this harness has the host's locale).
    try h.assertErlangRunLog(std.testing.allocator,
        \\pub fn main() -> void {
        \\    print("é", "\u{1F600}");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "é 😀\n", &.{"'_botopink_main'() ->\n    io:setopts(standard_io, [{encoding, unicode}]),\n    main()."});
}

test "erlang: true and false inside a tuple pattern are matched, not bound" {
    // `#(true, n)` was `{True, N}`: `true` became a variable, the first arm
    // matched every tuple, and `tag(#(false, 1))` answered `yes 1`.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn tag(t: #(bool, i32)) -> string {
        \\    return case t {
        \\        #(true, n) { "yes " + n.toString() }
        \\        #(false, n) { "no " + n.toString() }
        \\    };
        \\}
        \\
        \\fn first(t: #(bool, i32, i32)) -> i32 {
        \\    return case t {
        \\        #(false, ..) { 0 }
        \\        #(true, n, ..) { n }
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(tag(#(false, 1)));
        \\    print(tag(#(true, 2)));
        \\    print(first(#(false, 7, 8)));
        \\    print(first(#(true, 7, 8)));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "no 1\nyes 2\n0\n7\n", &.{ "{true, N} ->", "{false, N@1} ->", "=:= false" });
}

test "erlang: a record's constructor pattern carries the record's own tag" {
    // `Point(x: 0, ..)` and `Point(x: 0, y: y)` were `{'Point', 0, _}`: the
    // record is built as `{'test@main@@Point', …}` (decision 109), so no arm
    // matched and the `case` died with `case_clause` — or fell to `_`.
    try h.assertErlangRunLog(std.testing.allocator,
        \\type Point(x: i32, y: i32)
        \\
        \\fn f(p: Point) -> i32 {
        \\    return case p {
        \\        Point(x: 0, y: y) { y }
        \\        Point(x: x, y: _) { x }
        \\    };
        \\}
        \\
        \\fn onAxis(p: Point) -> string {
        \\    return case p {
        \\        Point(x: 0, ..) { "on y" }
        \\        Point(y: 0, ..) { "on x" }
        \\        _ { "off" }
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(f(Point(x: 0, y: 5)));
        \\    print(f(Point(x: 3, y: 0)));
        \\    print(onAxis(Point(x: 0, y: 5)));
        \\    print(onAxis(Point(x: 3, y: 0)));
        \\    print(onAxis(Point(x: 3, y: 4)));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "5\n3\non y\non x\noff\n", &.{"{test@main@@Point, 0, _} ->"});
}

test "erlang: a throw in a case arm of a Result fn is that fn's error" {
    // `return case n { 0 -> throw "zero", 1 { throw "one"; } _ -> n * 2 }`
    // wrapped the whole `case` in `{ok, …}`: the arrow arm's `{error, <<"zero">>}`
    // came back as `{ok, {error, …}}` and the block arm's throw escaped as an
    // uncaught erlang `throw`. The arms that do not leave carry the `{ok, …}`.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn parse(n: i32) -> Result<i32, string> {
        \\    return case n {
        \\        0 -> throw "zero",
        \\        1 { throw "one"; }
        \\        _ -> n * 2,
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(parse(0).unwrapOr(-1));
        \\    print(parse(1).unwrapOr(-2));
        \\    print(parse(2).unwrapOr(-3));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "-1\n-2\n4\n", &.{ "{error, <<\"one\">>};", "{ok, '__bp_int'((N * 2), -2147483648, 2147483647, <<\"integer overflow: * on i32 at main.bp:5:16\">>)}" });
}

test "erlang: a fn in a generic record's field is applied when called through the field" {
    // `type Box<T>(value: T)`: the field is written `T`, so inference records
    // no lowering for `h.value("b")` and the call fell through to a bare
    // `value(H, <<"b">>)` — undefined, `erlc` refused the module. A field typed
    // by one of the record's type parameters is applied like a `fn(…)` one.
    try h.assertErlangRunLog(std.testing.allocator,
        \\type Box<T>(value: T)
        \\
        \\fn shout(s: string) -> string {
        \\    return s + "!";
        \\}
        \\
        \\pub fn main() -> void {
        \\    val h = Box(value: shout);
        \\    print(h.value("b"));
        \\    val lam = Box(value: { s -> s + "?" });
        \\    print(lam.value("e"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "b!\ne?\n", &.{ "(erlang:element(2, H))(<<\"b\">>)", "(erlang:element(2, Lam))(<<\"e\">>)" });
}

test "erlang: a list pattern that is a spread alone binds the whole list" {
    // `[..all]` matches every list. It was emitted `[All]`, a one-element list:
    // the `case` arm fell through to `case_clause` on `[1, 2, 3]` and on `[]`,
    // and `val assert [..all] = xs` panicked "assert pattern did not match".
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn describe(xs: i32[]) -> string {
        \\    return case xs {
        \\        [..all] -> "all ${all.length()}";
        \\    };
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(describe([1, 2, 3]));
        \\    print(describe([]));
        \\    val assert [..every] = [4, 5];
        \\    print(every);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "all 3\nall 0\n[4, 5]\n", &.{"Every = case"});
}

test "erlang: a block reassigning an enclosing `var` answers it beside its value" {
    // Decision 525 — a block is a scope of the function, its value its tail.
    // On erlang it is a `case` used as a value, whose clauses cannot rebind
    // what the function bound: every arm answers `{V, Group}` and the match
    // rebinds the group (`mutatingCaseExprAs`), also from an `if` / `else` at
    // the block's end (`ifValueGroupExpr`).
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn firstOver(xs: i32[], limit: i32) -> i32 {
        \\    var seen = 0;
        \\    var hit = -1;
        \\    val found = {
        \\        for x in xs {
        \\            seen = seen + 1;
        \\            if (hit < 0 && x > limit) {
        \\                hit = x;
        \\            }
        \\        }
        \\        if (hit < 0) {
        \\            seen = seen * 10;
        \\            hit
        \\        } else {
        \\            hit
        \\        }
        \\    };
        \\    return found * 100 + seen;
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(firstOver([1, 7, 3], 5));
        \\    print(firstOver([1, 2], 5));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "703\n-80\n", &.{"erlang:element(1, {_, "});
}

test "erlang: a library's field read is its closure's alone, whatever its consumer declares" {
    // Decision 509 (2), 144 B-65: `q.label` in `shelf` is `erlang:element(2,
    // Q)` — `shelf`'s closure declares one `Queue`. The consumer's own
    // `Queue` and `rival`'s, with other field orders, are not in it; the read
    // used to vote over the whole program and became `'__bp_field'(Q, label)`
    // under `crowded` alone.
    try h.assertLibrarySameUnder(std.testing.allocator, .erlang, &.{ "shelf", "rival" }, "shelf", &h.closure_plain, &h.closure_crowded);
}

test "erlang: a record imported by name beside a std module declaring the same name is the imported one" {
    // 144 B-67: `import {collections} from "std"` registered `std/collections`'
    // `Queue` before `import {items.Queue}` named `items`' own, so `Queue(…)`
    // built `{std@collections@@Queue, …}` and `describe`'s head refused it
    // with `function_clause`. The construction names the imported type's
    // owner, whichever import is written first.
    const items =
        \\pub type Queue(label: string, size: i32)
        \\
        \\pub fn describe(q: Queue) -> string {
        \\    return q.label + ":" + q.size.toString();
        \\}
    ;
    try h.assertErlangRunLogModules(std.testing.allocator, &.{
        .{ .path = "items", .source = items },
        .{ .path = "main", .source =
        \\import {collections} from "std";
        \\import {items.Queue, items.describe};
        \\
        \\pub fn main() -> void {
        \\    print(describe(Queue(label: "crowded", size: 2)));
        \\    print(collections.toInt(collections.lt()));
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    }, "main", "crowded:2\n-1\n", &.{"{test@items@@Queue, <<\"crowded\">>, 2}"});
    try h.assertErlangRunLogModules(std.testing.allocator, &.{
        .{ .path = "items", .source = items },
        .{ .path = "main", .source =
        \\import {items.Queue, items.describe};
        \\import {collections} from "std";
        \\
        \\pub fn main() -> void {
        \\    print(describe(Queue(label: "after", size: 3)));
        \\    print(collections.toInt(collections.gt()));
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    }, "main", "after:3\n1\n", &.{"{test@items@@Queue, <<\"after\">>, 3}"});
}

test "erlang: a `_`-prefixed module-level val is a binding its readers see, not a discarded statement" {
    // Only `_`, `_loop` and `_main…` are statements. `val _c = …` was inlined
    // into `'_botopink_init'/0` with no 0-arity function, so `_d`'s initialiser
    // and `main` referred to an unbound variable and `erlc` refused the module.
    try h.assertErlangRunLog(std.testing.allocator,
        \\type Box(n: i32) {
        \\    fn get(self: Self) -> i32 {
        \\        return self.n;
        \\    }
        \\}
        \\
        \\fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
        \\
        \\val _c = Box(n: 5);
        \\val _d = double(_c.get());
        \\
        \\pub fn main() -> void {
        \\    print(_d);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "10\n", &.{"'_c'() ->"});
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

test "erlang: decision 346 ---- bytes is a binary, its methods std's templates" {
    try h.assertErlangRunLog(std.testing.allocator, bytes_src, bytes_log, &.{"byte_size("});
}

test "erlang: a defer reads a var a value case's arm reassigns before it panics" {
    // Decision 539 (amended): the `val r = case …` statement is no
    // `collectMutations` site, so the `defer` watched nothing and the `after`
    // read the old value (`close a`). The arm writes it where it happens.
    try h.assertErlangRunLog(std.testing.allocator,
        \\import {failure, failure.Failure} from "std";
        \\
        \\fn boom() -> i32 {
        \\    panic("boom");
        \\}
        \\
        \\fn work(n: i32) -> i32 {
        \\    var f = "a";
        \\    defer print("close " + f);
        \\    val r = case n {
        \\        0 { f = "e"; boom() }
        \\        _ { f = "g"; 3 }
        \\    };
        \\    return r;
        \\}
        \\
        \\pub fn main() -> void {
        \\    val r = failure.attempt({ -> work(0) });
        \\    print("done");
        \\}
        \\
        \\import {io.terminal.print, failure.panic} from "std";
    , "close e\ndone\n", &.{"erlang:put(__BpDeferRef1, {F@"});
}

test "erlang: a defer body that rebinds a var leaves its group unbound" {
    // The `after` runs for its effects: the group of the rebinding is not
    // bound to a variable nothing reads (erlc: "variable 'N@2' is unused").
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn f() -> i32 {
        \\    var n = 1;
        \\    defer {
        \\        n = 100;
        \\    }
        \\    return n;
        \\}
        \\
        \\pub fn main() -> void {
        \\    print(f());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "1\n", &.{"    after\n        case true of"});
}

test "erlang: a bare return in a yielding case arm ends the generator" {
    try h.assertErlangRunLog(std.testing.allocator,
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
        \\pub fn main() -> void {
        \\    for v in items(0) { print(v); }
        \\    for v in items(1) { print(v); }
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "0\n1\n0\n2\n9\n", &.{"'__bp_gen_stop'"});
}

test "erlang: a labelled break leaves the outer loop from an inner one" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn sumBeforeTwo(xs: i32[], ys: i32[]) -> i32 {
        \\    var s = 0;
        \\    for :outer x in xs {
        \\        for y in ys {
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
        \\pub fn main() -> void {
        \\    print(sumBeforeTwo([1, 2], [1, 2, 3]));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "1\n", &.{"'__bp_label_break'"});
}

test "erlang: a labelled continue starts the outer loop's next round from a case arm of an inner one" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn run(xs: i32[], ys: i32[]) -> i32 {
        \\    var s = 0;
        \\    for :outer x in xs {
        \\        for y in ys {
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
        \\pub fn main() -> void {
        \\    print(run([1, 2], [1, 2, 3]));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "113\n", &.{"__bp_label_continue"});
}
