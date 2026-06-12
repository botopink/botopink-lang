/// Testes de go-to-definition — cobre `engine.definition`.
/// Snapshots em: snapshots/lsp/definition_*.snap.md
///
/// Analogia Gleam: tests/definition.rs (43 testes / 77 snapshots).
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");

// ── DG1 — vai para declaração val ────────────────────────────────────────────

test "definition: cursor on val usage jumps to declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
        \\val y = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'x' na segunda linha: "val y = x;" — col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_val_usage", source, h.pos(1, 8), result);
}

// ── DG2 — vai para declaração fn ─────────────────────────────────────────────

test "definition: cursor on fn call jumps to fn declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\fn f(a: i32) { return a; }
        \\val r = f(1);
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'f' na segunda linha: "val r = f(1);" — col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_fn_usage", source, h.pos(1, 8), result);
}

// ── DG3 — cursor em literal retorna null ─────────────────────────────────────

test "definition: cursor on integer literal" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // '42' começa na col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(0, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_literal_null", source, h.pos(0, 8), result);
}

// ── DG4 — record ─────────────────────────────────────────────────────────────

test "definition: cursor on record type usage" {
    const gpa = std.testing.allocator;
    const source =
        \\val Point = record { x: i32, y: i32 };
        \\val p = Point(x: 1, y: 2);
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'Point' na linha 1: "val p = Point(x: 1, y: 2);" — col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_record_usage", source, h.pos(1, 8), result);
}

// ── DG5 — URI preservada ──────────────────────────────────────────────────────

test "definition: returned Location carries the correct URI" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    // Verificação inline: URI deve ser a que passamos
    if (result) |loc| {
        try std.testing.expectEqualStrings(h.TEST_URI, loc.uri);
    }

    try snap.assertDefinition(gpa, "definition_uri_preserved", source, h.pos(1, 8), result);
}

// ── DG6 — enum declaration ────────────────────────────────────────────────────

test "definition: cursor on enum usage jumps to enum declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\val Color = enum { Red, Green, Blue };
        \\val c = Color.Red;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'Color' na linha 1: "val c = Color.Red;" — col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_enum_usage", source, h.pos(1, 8), result);
}

// ── DG7 — símbolo importado salta para outro módulo ───────────────────────────
//
// TODO "lsp ---- go-to-definition on imported symbol".

test "definition: imported symbol jumps to defining module" {
    const gpa = std.testing.allocator;
    const main_src =
        \\use {double} = @root()
        \\val r = double(21);
    ;
    const math_uri = "file:///math.bp";
    const math_src =
        \\pub fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), main_src);

    // 'double' na segunda linha: "val r = double(21);" — col 8
    const others = [_]engine.ModuleSource{.{ .uri = math_uri, .source = math_src }};
    const result = try engine.definitionInModules(gpa, h.TEST_URI, main_src, h.pos(1, 8), tokens, &others);
    defer if (result) |loc| gpa.free(loc.uri);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.eql(u8, result.?.uri, math_uri));
    try snap.assertDefinition(gpa, "definition_imported_symbol", main_src, h.pos(1, 8), result);
}

// ── DG8 — símbolo de módulo std embutido ─────────────────────────────────────
//
// TODO "lsp ---- go-to-definition on std module fn".

test "definition: std module member jumps into embedded std source" {
    const gpa = std.testing.allocator;
    const source =
        \\import {order} from "std";
        \\val n = order.toInt(order.lt());
    ;

    // 'toInt' na linha 1: "val n = order.toInt(…" — col 14
    const result = try engine.definitionInStdModules(gpa, source, h.pos(1, 14));
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("order", result.?.module.name);

    // Snapshot com URI pseudo "std/<module>" — o server materializa o path real.
    const snap_loc = proto.Location{ .uri = "std/order", .range = result.?.range };
    try snap.assertDefinition(gpa, "definition_std_module_member", source, h.pos(1, 14), snap_loc);
}

test "definition: bare std module name jumps to top of module" {
    const gpa = std.testing.allocator;
    const source =
        \\import {order} from "std";
        \\val n = order.toInt(order.lt());
    ;

    // 'order' no import: "import {order} from …" — col 8
    const result = try engine.definitionInStdModules(gpa, source, h.pos(0, 8));
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("order", result.?.module.name);
    try std.testing.expectEqual(@as(u32, 0), result.?.range.start.line);

    const snap_loc = proto.Location{ .uri = "std/order", .range = result.?.range };
    try snap.assertDefinition(gpa, "definition_std_module_name", source, h.pos(0, 8), snap_loc);
}

test "definition: std lookup misses without a std import" {
    const gpa = std.testing.allocator;
    const source =
        \\val y = map;
    ;

    // 'map' sem qualificador nem `from "std"` — não deve resolver no std.
    const result = try engine.definitionInStdModules(gpa, source, h.pos(0, 8));
    try std.testing.expect(result == null);
}

test "definition: non-std qualifier does not resolve into std" {
    const gpa = std.testing.allocator;
    const source =
        \\import {order} from "std";
        \\val xs = foo.map(1);
    ;

    // 'map' qualificado por `foo` (não é módulo std) — null.
    const result = try engine.definitionInStdModules(gpa, source, h.pos(1, 13));
    try std.testing.expect(result == null);
}

test "definition: local declaration preferred over imported" {
    const gpa = std.testing.allocator;
    const main_src =
        \\fn double(x: i32) -> i32 { return x + x; }
        \\val r = double(21);
    ;
    const other_src =
        \\pub fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), main_src);

    const others = [_]engine.ModuleSource{.{ .uri = "file:///other.bp", .source = other_src }};
    const result = try engine.definitionInModules(gpa, h.TEST_URI, main_src, h.pos(1, 8), tokens, &others);
    defer if (result) |loc| gpa.free(loc.uri);

    // The local `double` (line 0) wins over the imported one.
    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.eql(u8, result.?.uri, h.TEST_URI));
    try std.testing.expectEqual(@as(u32, 0), result.?.range.start.line);
}

// ── R1 — go-to-def into the local scope (lsp-project-awareness) ───────────────
//
// A parameter, a `var` local, and a `{ f -> … }` closure binder carry no
// declaration keyword that the old keyword-scan could match — go-to-def returned
// nothing on them, and a same-named top-level decl would have shadowed the
// nearer local. The shared source below mirrors a decorator body.

const r1_source =
    \\val decl = 99;
    \\pub fn component(comptime decl: @Decl) {
    \\    var args = "";
    \\    items.forEach({ f ->
    \\        use(decl, args, f);
    \\    });
    \\}
;

test "definition: nearer param shadows same-named top-level decl (R1)" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), r1_source);

    // `decl` inside `use(decl, …)` on line 4 (0-based) — must resolve to the
    // function PARAMETER on line 1, not the top-level `val decl` on line 0.
    const cursor = h.pos(4, 13);
    const result = try engine.definition(gpa, h.TEST_URI, r1_source, cursor, tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try std.testing.expect(result != null);
    try std.testing.expectEqual(@as(u32, 1), result.?.range.start.line); // the param, not line 0
}

test "definition: var-declared local resolves on go-to-def (R1)" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), r1_source);

    // `args` inside `use(decl, args, f)` → the `var args` binding on line 2.
    const cursor = h.pos(4, 19);
    const result = try engine.definition(gpa, h.TEST_URI, r1_source, cursor, tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try std.testing.expect(result != null);
    try std.testing.expectEqual(@as(u32, 2), result.?.range.start.line);
}

test "definition: closure binder resolves to its binding site (R1)" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), r1_source);

    // `f` inside `use(decl, args, f)` → the `{ f -> … }` binder on line 3.
    const cursor = h.pos(4, 24);
    const result = try engine.definition(gpa, h.TEST_URI, r1_source, cursor, tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try std.testing.expect(result != null);
    try std.testing.expectEqual(@as(u32, 3), result.?.range.start.line);
    try snap.assertDefinition(gpa, "definition_closure_binder", r1_source, cursor, result);
}

// ── lsp-definition-completeness — members, builtin methods & `mod` refs ───────
//
// Go-to-def used to be a declaration-keyword scan with no notion of "member of a
// type": record fields had no keyword, methods resolved by the first same-named
// `fn` (receiver-blind), builtin methods had no `fn` in the file at all, and a
// `mod` name's declaration is a sibling file. These cover R2–R7 from the spec on
// the real erika shape: a record with an `Array` field + methods, a `self.field`
// access, a builtin call, a `Name(field:)` label, and a `pub mod <name>;`.

/// 0-based Position of the `occurrence`-th match of `needle`, shifted right by
/// `shift` characters (to land the cursor inside the needle).
fn posOf(source: []const u8, needle: []const u8, occurrence: usize, shift: usize) proto.Position {
    var from: usize = 0;
    var found: usize = 0;
    var idx: usize = 0;
    while (std.mem.indexOfPos(u8, source, from, needle)) |p| {
        found += 1;
        if (found == occurrence) {
            idx = p + shift;
            break;
        }
        from = p + 1;
    }
    var line: u32 = 0;
    var col: u32 = 0;
    var i: usize = 0;
    while (i < idx) : (i += 1) {
        if (source[i] == '\n') {
            line += 1;
            col = 0;
        } else col += 1;
    }
    return h.pos(line, col);
}

/// The source slice covered by `range` (single-line ranges only).
fn sliceAt(source: []const u8, range: proto.Range) []const u8 {
    var line: u32 = 0;
    var i: usize = 0;
    while (i < source.len and line < range.start.line) : (i += 1) {
        if (source[i] == '\n') line += 1;
    }
    const start = i + range.start.character;
    const end = i + range.end.character;
    return source[start..@min(end, source.len)];
}

/// erika-shaped fixture: a `Query` record over an `Array<i32>` with fields and
/// methods that reproduce R2–R6.
const member_source =
    \\pub record Query {
    \\    items: Array<i32>,
    \\    pub fn reverse(self: Self) -> Query {
    \\        return Query(items: self.items.reverse());
    \\    }
    \\    pub fn all(self: Self) -> Array<i32> {
    \\        return self.items;
    \\    }
    \\    pub fn each(self: Self) {
    \\        var sink = [];
    \\        self.items.forEach({ x -> sink = sink.append([x]); });
    \\    }
    \\}
    \\val q = Query(items: [1, 2, 3]);
    \\val r = q.reverse();
;

test "definition: method on a builtin field jumps to primitives, not the same-named record method (R2)" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, member_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), member_source);

    // `.reverse` in `self.items.reverse()` — receiver `self.items` is Array<i32>,
    // so it must resolve to the builtin `Array.reverse`, NOT Query's own method.
    const cursor = posOf(member_source, "self.items.reverse()", 1, "self.items.".len);
    const td = try engine.definitionMember(gpa, h.TEST_URI, member_source, cursor, tokens, bindings, &.{});
    defer if (td) |t| switch (t) {
        .location => |loc| gpa.free(loc.uri),
        .builtin => {},
    };
    try std.testing.expect(td != null);
    try std.testing.expect(td.? == .builtin);
    try std.testing.expectEqualStrings("reverse", sliceAt(td.?.builtin.source, td.?.builtin.range));
}

test "definition: field label in a constructor call jumps to the field decl (R3)" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, member_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), member_source);

    // `items` label in `Query(items: …)` → the `items:` field declaration (line 1).
    const cursor = posOf(member_source, "Query(items:", 1, "Query(".len);
    const td = try engine.definitionMember(gpa, h.TEST_URI, member_source, cursor, tokens, bindings, &.{});
    defer if (td) |t| switch (t) {
        .location => |loc| gpa.free(loc.uri),
        .builtin => {},
    };
    try std.testing.expect(td != null);
    try std.testing.expect(td.? == .location);
    try std.testing.expectEqual(@as(u32, 1), td.?.location.range.start.line);
    try std.testing.expectEqualStrings("items", sliceAt(member_source, td.?.location.range));
}

test "definition: self.field jumps to the field declaration (R4)" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, member_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), member_source);

    // `items` in `return self.items;` → the `items:` field declaration (line 1).
    const cursor = posOf(member_source, "self.items;", 1, "self.".len);
    const td = try engine.definitionMember(gpa, h.TEST_URI, member_source, cursor, tokens, bindings, &.{});
    defer if (td) |t| switch (t) {
        .location => |loc| gpa.free(loc.uri),
        .builtin => {},
    };
    try std.testing.expect(td != null);
    try std.testing.expect(td.? == .location);
    try std.testing.expectEqual(@as(u32, 1), td.?.location.range.start.line);
    try std.testing.expectEqualStrings("items", sliceAt(member_source, td.?.location.range));
}

/// The exact erika shape: a *generic* `Query<T>` over `Array<T>` (a generic field
/// whose arg is a type parameter, not a concrete type) — exercises R2/R4 the way
/// `libs/erika/src/erika.bp` actually declares them.
const generic_source =
    \\pub record Query<T> {
    \\    items: Array<T>,
    \\    pub fn reverse(self: Self) -> Query<T> {
    \\        return Query(items: self.items.reverse());
    \\    }
    \\    pub fn all(self: Self) -> Array<T> {
    \\        return self.items;
    \\    }
    \\}
    \\val q = Query(items: [1, 2, 3]);
;

test "definition: generic record — builtin method on Array<T> field jumps to primitives (R2 generic)" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, generic_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), generic_source);

    const cursor = posOf(generic_source, "self.items.reverse()", 1, "self.items.".len);
    const td = try engine.definitionMember(gpa, h.TEST_URI, generic_source, cursor, tokens, bindings, &.{});
    defer if (td) |t| switch (t) {
        .location => |loc| gpa.free(loc.uri),
        .builtin => {},
    };
    try std.testing.expect(td != null);
    try std.testing.expect(td.? == .builtin);
    try std.testing.expectEqualStrings("reverse", sliceAt(td.?.builtin.source, td.?.builtin.range));
}

test "definition: generic record — self.field on Array<T> field jumps to the field decl (R4 generic)" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, generic_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), generic_source);

    const cursor = posOf(generic_source, "self.items;", 1, "self.".len);
    const td = try engine.definitionMember(gpa, h.TEST_URI, generic_source, cursor, tokens, bindings, &.{});
    defer if (td) |t| switch (t) {
        .location => |loc| gpa.free(loc.uri),
        .builtin => {},
    };
    try std.testing.expect(td != null);
    try std.testing.expect(td.? == .location);
    try std.testing.expectEqual(@as(u32, 1), td.?.location.range.start.line);
    try std.testing.expectEqualStrings("items", sliceAt(generic_source, td.?.location.range));
}

/// Two records with a same-named method — `.tag` must land on the *receiver's*
/// record, not the first `fn tag` in the file.
const r5_source =
    \\pub record A {
    \\    n: i32,
    \\    pub fn tag(self: Self) -> i32 { return self.n; }
    \\}
    \\pub record B {
    \\    m: i32,
    \\    pub fn tag(self: Self) -> i32 { return self.m; }
    \\}
    \\val b = B(m: 5);
    \\val t = b.tag();
;

test "definition: same-named method resolves on the receiver's record (R5)" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, r5_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), r5_source);

    // `tag` in `b.tag()` where `b: B` → B.tag (line 6), not A.tag (line 2).
    const cursor = posOf(r5_source, "b.tag()", 1, "b.".len);
    const td = try engine.definitionMember(gpa, h.TEST_URI, r5_source, cursor, tokens, bindings, &.{});
    defer if (td) |t| switch (t) {
        .location => |loc| gpa.free(loc.uri),
        .builtin => {},
    };
    try std.testing.expect(td != null);
    try std.testing.expect(td.? == .location);
    try std.testing.expectEqual(@as(u32, 6), td.?.location.range.start.line);
}

test "definition: builtin method with no fn in the file jumps to primitives (R6)" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, member_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), member_source);

    // `forEach` in `self.items.forEach(…)` — no `fn forEach` anywhere in the file.
    const cursor = posOf(member_source, "self.items.forEach", 1, "self.items.".len);
    const td = try engine.definitionMember(gpa, h.TEST_URI, member_source, cursor, tokens, bindings, &.{});
    defer if (td) |t| switch (t) {
        .location => |loc| gpa.free(loc.uri),
        .builtin => {},
    };
    try std.testing.expect(td != null);
    try std.testing.expect(td.? == .builtin);
    try std.testing.expectEqualStrings("forEach", sliceAt(td.?.builtin.source, td.?.builtin.range));
}

test "definition: `pub mod <name>;` jumps to the backing module file (R7)" {
    const gpa = std.testing.allocator;
    const source =
        \\pub mod erika;
    ;
    const erika_uri = "file:///erika/src/erika.bp";
    const others = [_]engine.ModuleSource{.{
        .uri = erika_uri,
        .source = "pub fn ping() -> i32 { return 1; }",
    }};

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    // Cursor on `erika` in `pub mod erika;` → the `erika.bp` module file.
    const cursor = posOf(source, "erika", 1, 0);
    const empty: []const h.comptime_pipeline.TypedBinding = &.{};
    const td = try engine.definitionMember(gpa, h.TEST_URI, source, cursor, tokens, empty, &others);
    defer if (td) |t| switch (t) {
        .location => |loc| gpa.free(loc.uri),
        .builtin => {},
    };
    try std.testing.expect(td != null);
    try std.testing.expect(td.? == .location);
    try std.testing.expectEqualStrings(erika_uri, td.?.location.uri);
}

test "definition: cross-module field jumps into the declaring module (F5)" {
    const gpa = std.testing.allocator;
    const dep_uri = "file:///dep_0.bp";
    const dep_src =
        \\pub record Box {
        \\    value: i32,
        \\}
    ;
    const main_src =
        \\import { Box } from "dep";
        \\val b = Box(value: 1);
        \\val v = b.value;
    ;

    var c = try h.compileMulti(gpa, &.{
        .{ .uri = dep_uri, .source = dep_src },
        .{ .uri = h.TEST_URI, .source = main_src },
    });
    defer c.deinit(gpa);
    const bindings = c.result.bindingsFor(h.TEST_URI);

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), main_src);
    const others = [_]engine.ModuleSource{.{ .uri = dep_uri, .source = dep_src }};

    // `value` in `b.value` where `b: Box` (declared in dep_0) → dep_0's field.
    const cursor = posOf(main_src, "b.value", 1, "b.".len);
    const td = try engine.definitionMember(gpa, h.TEST_URI, main_src, cursor, tokens, bindings, &others);
    defer if (td) |t| switch (t) {
        .location => |loc| gpa.free(loc.uri),
        .builtin => {},
    };
    try std.testing.expect(td != null);
    try std.testing.expect(td.? == .location);
    try std.testing.expectEqualStrings(dep_uri, td.?.location.uri);
    try std.testing.expectEqualStrings("value", sliceAt(dep_src, td.?.location.range));
}
