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
    // on a local; a program whose own `s.trim()` sits at the same line and
    // column made the body's call `append(Out, [X])` — undefined, `erlc`
    // refused the module (the std-dedupe front's `exponent.startsWith("+")`
    // was the same lookup). The program is built so its call lands exactly
    // there, wherever `primitives.bp` keeps that line.
    const alloc = std.testing.allocator;
    const marker = "out = out.append([x]);";
    const at = std.mem.indexOf(u8, prelude.primitives, marker) orelse return error.PreludeMarkerMoved;
    const line_start = if (std.mem.lastIndexOfScalar(u8, prelude.primitives[0..at], '\n')) |nl| nl + 1 else 0;
    const line = std.mem.count(u8, prelude.primitives[0..at], "\n") + 1;
    // The call's column is its `.`; `@print(s.trim())`'s `.` is 8 past the pad.
    const dot = at + "out = out".len - line_start;
    try std.testing.expect(dot >= 8 and line > 4);

    var src: std.ArrayListUnmanaged(u8) = .empty;
    defer src.deinit(alloc);
    try src.appendSlice(alloc,
        \\pub fn main() {
        \\    val s = " ab ";
        \\    @print([1, 1, 2].unique());
        \\
    );
    for (4..line) |_| try src.appendSlice(alloc, "    //\n");
    try src.appendNTimes(alloc, ' ', dot - 8);
    try src.appendSlice(alloc,
        \\@print(s.trim());
        \\}
        \\
    );
    try h.assertErlangRunLog(alloc, src.items, "[1, 2]\nab\n", &.{"(Out@1 ++ [X])"});
}

test "erlang: a default fn body lowers a local's method by the kind its declared types give it" {
    // Inference records no lowering inside an interface `default fn` body, so a
    // method on one of its locals was the bare local call — `unwrapOr(F, D)`,
    // undefined — or a run-time dispatch shim. The body's declared types give
    // each local its kind: `stringSlice0`'s `-> string`, `Array.at`'s `-> ?T`.
    // Both members sit in the program's own `behavior Array<T>`: the checker
    // checks a default body (`01-checker`) and reads a program's own primitive
    // behavior as the whole interface of its primitive, so a `behavior String`
    // here would refuse `tail.startsWith` (std's `String` member) in the body.
    try h.assertErlangRunLog(std.testing.allocator,
        \\behavior Array<T> {
        \\    default fn tailShout(self: Self<T>, s: string) -> string {
        \\        val tail = stringSlice0(s, 1);
        \\        return if (tail.startsWith("+")) tail.toUpper() else tail;
        \\    }
        \\
        \\    default fn firstOr(self: Self<T>, d: T) -> T {
        \\        val f = self.at(0);
        \\        return f.unwrapOr(d);
        \\    }
        \\}
        \\
        \\pub fn main() {
        \\    @print([0].tailShout("a+b"));
        \\    @print([0].tailShout("ab"));
        \\    @print([1, 2].firstOr(9));
        \\    val none: i32[] = [];
        \\    @print(none.firstOr(9));
        \\}
    , "+B\nb\n1\n9\n", &.{ "(string:prefix(Tail, <<\"+\">>) =/= nomatch)", "string:uppercase(Tail)", "(fun(__BpO) -> case __BpO of undefined -> (D); __BpV0 -> __BpV0 end end)(F)" });
}

test "erlang: Array.unique drops consecutive duplicates" {
    // C-35: the prelude body is lowered with the kinds its declared types give
    // its locals (`var out: T[]`, `self.at(0)`'s `?T`).
    try h.assertErlangRunLog(std.testing.allocator,
        \\pub fn main() {
        \\    @print([1, 1, 2, 2, 3].unique());
        \\    @print([4].unique());
        \\    val none: i32[] = [];
        \\    @print(none.unique());
        \\}
    , "[1, 2, 3]\n[4]\n[]\n", &.{});
}

test "erlang: an entry point sets standard_io to unicode before anything prints" {
    // `erl` opens `standard_io` in the host locale's encoding: under `LANG=C`
    // `@print("é")` wrote the latin1 byte `0xE9` and `"\u{1F600}"` the text
    // `\x{1F600}`. The program sets it itself, first, so its output is the
    // same bytes under any locale (`run/string_literal_unicode_escape` run
    // with `LANG=C` is the measurement; this harness has the host's locale).
    try h.assertErlangRunLog(std.testing.allocator,
        \\pub fn main() {
        \\    @print("é", "\u{1F600}");
        \\}
    , "é 😀\n", &.{"'_botopink_main'() ->\n    io:setopts(standard_io, [{encoding, unicode}]),\n    main()."});
}

test "erlang: true and false inside a tuple pattern are matched, not bound" {
    // `#(true, n)` was `{True, N}`: `true` became a variable, the first arm
    // matched every tuple, and `tag(#(false, 1))` answered `yes 1`.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn tag(t: #(bool, i32)) -> string {
        \\    return case t {
        \\        #(true, n) { "yes " + n.toString(); }
        \\        #(false, n) { "no " + n.toString(); }
        \\    };
        \\}
        \\
        \\fn first(t: #(bool, i32, i32)) -> i32 {
        \\    return case t {
        \\        #(false, ..) { 0; }
        \\        #(true, n, ..) { n; }
        \\    };
        \\}
        \\
        \\pub fn main() {
        \\    @print(tag(#(false, 1)));
        \\    @print(tag(#(true, 2)));
        \\    @print(first(#(false, 7, 8)));
        \\    @print(first(#(true, 7, 8)));
        \\}
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
        \\        Point(x: 0, y: y) { y; }
        \\        Point(x: x, y: _) { x; }
        \\    };
        \\}
        \\
        \\fn onAxis(p: Point) -> string {
        \\    return case p {
        \\        Point(x: 0, ..) { "on y"; }
        \\        Point(y: 0, ..) { "on x"; }
        \\        _ { "off"; }
        \\    };
        \\}
        \\
        \\pub fn main() {
        \\    @print(f(Point(x: 0, y: 5)));
        \\    @print(f(Point(x: 3, y: 0)));
        \\    @print(onAxis(Point(x: 0, y: 5)));
        \\    @print(onAxis(Point(x: 3, y: 0)));
        \\    @print(onAxis(Point(x: 3, y: 4)));
        \\}
    , "5\n3\non y\non x\noff\n", &.{"{test@main@@Point, 0, _} ->"});
}

test "erlang: a throw in a case arm of a Result fn is that fn's error" {
    // `return case n { 0 -> throw "zero", 1 { throw "one"; } _ -> n * 2 }`
    // wrapped the whole `case` in `{ok, …}`: the arrow arm's `{error, <<"zero">>}`
    // came back as `{ok, {error, …}}` and the block arm's throw escaped as an
    // uncaught erlang `throw`. The arms that do not leave carry the `{ok, …}`.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn parse(n: i32) -> @Result<i32, string> {
        \\    return case n {
        \\        0 -> throw "zero",
        \\        1 { throw "one"; }
        \\        _ -> n * 2,
        \\    };
        \\}
        \\
        \\pub fn main() {
        \\    @print(parse(0).unwrapOr(-1));
        \\    @print(parse(1).unwrapOr(-2));
        \\    @print(parse(2).unwrapOr(-3));
        \\}
    , "-1\n-2\n4\n", &.{ "{error, <<\"one\">>};", "{ok, (N * 2)}" });
}
