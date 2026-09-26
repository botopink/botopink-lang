/// Hover tests — covers `engine.hover`. = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");
const std = @import("std");

// ── H1 — val inteiro ──────────────────────────────────────────────────────────

test "hover: val integer shows inferred type i32" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_val_integer", source, h.pos(0, 4), result);
}

// ── H2 — val string ───────────────────────────────────────────────────────────

test "hover: val string shows type string" {
    const gpa = std.testing.allocator;
    const source =
        \\val greeting = "hello";
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_val_string", source, h.pos(0, 4), result);
}

// ── H3 — keyword has no hover ──

test "hover: keyword val returns null" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // col 0 = 'v' em 'val'
    const result = try engine.hover(gpa, source, h.pos(0, 0), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_keyword_null", source, h.pos(0, 0), result);
}

// ── H4 — polymorphic fn ──

// Distinct from H5 (`hover_fn_annotated`) on purpose: that one covers a fn
// whose params carry concrete annotations, this one a *generic* fn, where the
// rendered signature has to keep the type parameter instead of a concrete type.
test "hover: generic fn keeps its type parameter" {
    const gpa = std.testing.allocator;
    const source =
        \\fn f<T>(a: T) -> T { return a; }
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // 'f' na col 3
    const result = try engine.hover(gpa, source, h.pos(0, 3), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    const hov = result orelse return error.NoHover;
    // The hover body must not collapse `T` into a concrete type.
    try std.testing.expect(std.mem.indexOf(u8, hov.contents.value, "a: T") != null);

    try snap.assertHover(gpa, "hover_fn_polymorphic", source, h.pos(0, 3), result);
}

// ── H5 — fn anotada ───────────────────────────────────────────────────────────

test "hover: annotated fn shows concrete parameter types" {
    const gpa = std.testing.allocator;
    const source =
        \\fn add(x: i32, y: i32) { return x; }
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 3), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_fn_annotated", source, h.pos(0, 3), result);
}

// ── H6 — segunda linha ────────────────────────────────────────────────────────

test "hover: val on second line" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = 2;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // 'y' na linha 1, col 4
    const result = try engine.hover(gpa, source, h.pos(1, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_second_line", source, h.pos(1, 4), result);
}

// ── H7 — sem bindings ─────────────────────────────────────────────────────────

test "hover: empty bindings returns null" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    const result = try engine.hover(gpa, source, h.pos(0, 4), &.{});
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_empty_bindings", source, h.pos(0, 4), result);
}

// ── effect returns (decision 118: the return is the effect) ──────────────────
//
// The footer names what a caller unwraps from the wrapper the fn writes as its
// return: `await`'s value for `@Task` / `@Component` (the `T` after the context
// base), the `for` / `for await` item for `@Iterator` / `@Stream`. A `@Result`
// return has no footer — it is consumed, not unwrapped.

/// Compiles `source`, hovers the fn name at (`line`, `col`) and snapshots it.
fn hoverSnap(slug: []const u8, source: []const u8, line: u32, col: u32) !void {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(line, col), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, slug, source, h.pos(line, col), result);
}

test "hover: @Iterator fn shows its for item type" {
    try hoverSnap("hover_effect_iterator",
        \\fn counter() -> @Iterator<i32> :gen { yield 1; }
    , 0, 3);
}

test "hover: @Task<@Result<T, E>> fn shows the whole Result as the await value" {
    try hoverSnap("hover_effect_task_result",
        \\pub type User(id: i32, name: string);
        \\fn fetchUser(id: i32) -> @Task<@Result<User, string>> {
        \\    if (id < 0) { throw "negative"; };
        \\    return User(id: id, name: "ana");
        \\}
    , 1, 3);
}

test "hover: @Component<C, T> fn shows T, not the context base" {
    try hoverSnap("hover_effect_component",
        \\val Element = type() implement @Context<Element>
        \\fn state(initial: i32) -> @Component<Element, i32> {
        \\    initial;
        \\}
    , 1, 3);
}

test "hover: @Stream fn shows its for await item type" {
    try hoverSnap("hover_effect_stream",
        \\fn pulses() -> @Stream<@Result<i32, string>> {
        \\    yield 1;
        \\    yield 2;
        \\}
    , 0, 3);
}

test "hover: @Iterator factory (no yield) still shows its item type" {
    try hoverSnap("hover_effect_iterator_factory",
        \\fn counter() -> @Iterator<i32> :gen { yield 1; }
        \\fn fresh() -> @Iterator<i32> { return counter(); }
    , 1, 3);
}

test "hover: @Result fn has no element footer" {
    try hoverSnap("hover_effect_result",
        \\fn parse(x: i32) -> @Result<i32, string> {
        \\    if (x < 0) { throw "negative"; };
        \\    return x;
        \\}
    , 0, 3);
}

// ── H-std — hover on a qualified std module member ────────────────────────────

test "hover: std module fn shows its signature" {
    const gpa = std.testing.allocator;
    const source =
        \\import {collections} from "std";
        \\val n = collections.toInt(collections.lt());
    ;
    // Cursor on `toInt` in `collections.toInt` (line 1, char 20).
    const result = try engine.hover(gpa, source, h.pos(1, 20), &.{});
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "fn toInt") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "std/collections") != null);
    try snap.assertHover(gpa, "hover_std_module_fn", source, h.pos(1, 20), result);
}

// ── decision 107 — the leaf an import path binds, in either spelling ─────────
//
// The server compiles with the same `resolveImports` the CLI runs, so a
// binding an aliased std leaf introduces (`flip`) hovers with the fn's
// type. One snapshot per spelling: the dotted path and the braced group are
// one tree, and the two hovers are byte-identical.

test "hover: a dotted std import path binds its aliased leaf" {
    const gpa = std.testing.allocator;
    const source =
        \\import {collections.gt, collections.reverse as flip} from "std";
        \\val d = flip(gt());
    ;
    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    // `from "std"` prepends the std module to the session, so the main
    // module's bindings are asked for by URI, not taken from the first output.
    const bindings = c.result.bindingsFor(h.TEST_URI);

    // Cursor on `flip` in `val d = flip(gt());` (line 1, char 8).
    const result = try engine.hover(gpa, source, h.pos(1, 8), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "Order") != null);
    try snap.assertHover(gpa, "hover_import_dotted_leaf_alias", source, h.pos(1, 8), result);
}

test "hover: a grouped std import binds its aliased leaf" {
    const gpa = std.testing.allocator;
    const source =
        \\import {collections: {gt, reverse as flip}} from "std";
        \\val d = flip(gt());
    ;
    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.result.bindingsFor(h.TEST_URI);

    const result = try engine.hover(gpa, source, h.pos(1, 8), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "Order") != null);
    try snap.assertHover(gpa, "hover_import_group_leaf_alias", source, h.pos(1, 8), result);
}

// NOTE: the "external declare fn in std module" hover test was retired with the
// stdlib-interface migration — `io` was dissolved and `@[external]` declarations
// now live in `primitives.d.bp` (flattened into the global env, not an importable
// std module). Re-add once an importable module carries an `@[external]` declare
// fn again (tasks/v0.beta.4 carryover).

// ── H-F4 — hover on an interface method invoked on a builtin receiver ──────────

test "hover: interface method on integer receiver shows signature" {
    const gpa = std.testing.allocator;
    const source =
        \\val s = 42.abs();
    ;
    // Cursor on `abs` in `42.abs` (line 0, char 12).
    const result = try engine.hover(gpa, source, h.pos(0, 12), &.{});
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "fn abs") != null);
    // `abs` is written in `Signed`; `I32 extends Signed` only inherits it. The
    // footer names the declaring behavior and the receiver's (front 14).
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "behavior Signed` (via I32)") != null);
    try snap.assertHover(gpa, "hover_interface_method", source, h.pos(0, 12), result);
}

test "hover: interface method on array receiver shows signature" {
    const gpa = std.testing.allocator;
    const valid_source =
        \\val xs = [1, 2, 3];
    ;
    const source =
        \\val xs = [1, 2, 3];
        \\val y = xs.filter({ x -> true });
    ;

    var c = try h.compile(gpa, valid_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // Cursor on `filter` in `xs.filter` (line 1, char 12).
    const result = try engine.hover(gpa, source, h.pos(1, 12), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    // Exact body: a substring check cannot catch the neighbouring member's doc
    // comment leaking into the signature (the bug this test now pins down).
    try std.testing.expectEqualStrings(
        \\```botopink
        \\fn filter(self: Self<T>, pred: fn(item: T) -> bool) -> Self<T>
        \\```
        \\
        \\*from `behavior Array`*
    ,
        result.?.contents.value,
    );
    try snap.assertHover(gpa, "hover_interface_method_array", source, h.pos(1, 12), result);
}

// ── H-14 — a declaration card is written in the 1.0.3 surface ─────────────────

// `record`, `enum` and `interface` are gone (MIGRATION.md): a hover that still
// printed them taught a form the parser rejects. The card is now the source
// line the user would write — fields in parentheses, variants in a body,
// `behavior` for the contract — with the type parameters a written generic type
// always carries (decision 8 §1.1).

test "hover: a record-shaped type is a `type Name(fields)` card" {
    const gpa = std.testing.allocator;
    const source =
        \\pub type Point(x: i32, y: i32)
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 9), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings(
        \\```botopink
        \\pub type Point(x: i32, y: i32)
        \\```
    ,
        result.?.contents.value,
    );
    try snap.assertHover(gpa, "hover_type_record", source, h.pos(0, 9), result);
}

test "hover: a generic record-shaped type keeps its type parameters" {
    const gpa = std.testing.allocator;
    const source =
        \\type Box<T>(value: T)
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 5), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings(
        \\```botopink
        \\type Box<T>(value: T)
        \\```
    ,
        result.?.contents.value,
    );
    try snap.assertHover(gpa, "hover_type_generic_record", source, h.pos(0, 5), result);
}

test "hover: an enum-shaped type is a `type Name { variants }` card" {
    const gpa = std.testing.allocator;
    const source =
        \\pub type Shape {
        \\    Circle(radius: f64),
        \\    Square,
        \\}
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 9), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings(
        \\```botopink
        \\pub type Shape { Circle(...), Square }
        \\```
    ,
        result.?.contents.value,
    );
    try snap.assertHover(gpa, "hover_type_enum", source, h.pos(0, 9), result);
}

test "hover: a behavior is a `behavior Name` card, not an interface" {
    const gpa = std.testing.allocator;
    const source =
        \\pub behavior Mappable<T> {
        \\    fn map(self: Self<T>) -> Self<T>;
        \\}
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 13), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings(
        \\```botopink
        \\pub behavior Mappable<T>
        \\```
    ,
        result.?.contents.value,
    );
    try snap.assertHover(gpa, "hover_behavior", source, h.pos(0, 13), result);
}

// ── H-14b — a rendered type is written the way the source writes it ───────────

// `array` and `tuple` are the checker's own names for two types that have no
// such spelling in source, and the structural record's `record { … }` is a
// parse error since the surface cutover. A card that prints one of them cannot
// be pasted back into the file.

test "hover: an array type is rendered `i32[]`, not `array<i32>`" {
    const gpa = std.testing.allocator;
    const source =
        \\val xs = [1, 2, 3];
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings(
        \\```botopink
        \\val xs : i32[]
        \\```
    ,
        result.?.contents.value,
    );
    try snap.assertHover(gpa, "hover_val_array", source, h.pos(0, 4), result);
}

test "hover: a tuple type is rendered `#(i32, string)`" {
    const gpa = std.testing.allocator;
    const source =
        \\val row = #(1, "a");
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try snap.assertHover(gpa, "hover_val_tuple", source, h.pos(0, 4), result);
}

test "hover: a labeled tuple type keeps its labels" {
    const gpa = std.testing.allocator;
    const source =
        \\fn load() -> #(name: string, pop: i32) { return #("SP", 12); }
        \\val row = load();
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(1, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try snap.assertHover(gpa, "hover_val_labeled_tuple", source, h.pos(1, 4), result);
}

// ── front 11 carve-out: the surface spelling of an optional ────────────────────

test "hover: an optional type is rendered `?i32`, not `optional<i32>`" {
    const gpa = std.testing.allocator;
    const source =
        \\fn find(k: string) -> ?i32 { return null; }
        \\val hit = find("a");
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(1, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    // The card must be source the user could write back: `optional<i32>` is the
    // checker's name for it, `?i32` is the only spelling the surface has.
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "optional<") == null);
    try snap.assertHover(gpa, "hover_val_optional", source, h.pos(1, 4), result);
}

test "hover: an optional of an array keeps both sugars" {
    const gpa = std.testing.allocator;
    const source =
        \\fn rows() -> ?i32[] { return null; }
        \\val all = rows();
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(1, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try snap.assertHover(gpa, "hover_val_optional_array", source, h.pos(1, 4), result);
}

// ── C-02 — an index is a method call, and the hover says what it answers ──────

test "hover: an index carries the method's answer, not void" {
    const gpa = std.testing.allocator;
    // Decision 63 as amended: `xs[0]` IS `xs.at(0)`, so the binding's type is
    // whatever `Index<i32, T>.at` answers — `?i32`. Before C-02 the checker had
    // no rule for the index node at all and fell through to `void`, which is
    // what this hover rendered and what sent two fronts to `.length()` rather
    // than indexing.
    const source =
        \\val xs = [10, 20, 30];
        \\val first = xs[0];
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(1, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "void") == null);
    try snap.assertHover(gpa, "hover_val_index", source, h.pos(1, 4), result);
}

test "hover: a tuple index carries the type of its position" {
    const gpa = std.testing.allocator;
    // The tuple is the checker's special case (decision 63's amendment says why:
    // a constant index, one type PER POSITION, which `at(key: K) -> ?V` cannot
    // say with one `V`). `t[1]` is `string` — and not an optional, because a
    // tuple position either exists in the type or the program is refused.
    const source =
        \\val t = #(1, "a");
        \\val second = t[1];
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(1, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "void") == null);
    try snap.assertHover(gpa, "hover_val_tuple_index", source, h.pos(1, 4), result);
}
