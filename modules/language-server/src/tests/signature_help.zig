/// Signature help tests — covers `engine.signatureHelp`.
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

// ── SH1 — cursor after ( shows first parameter ──

test "signature_help: cursor after opening paren shows first param" {
    const gpa = std.testing.allocator;

    // Bindings from the last successful compilation (definition only).
    const bindings_source =
        \\fn add(x: i32, y: i32) { return x; }
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Current source (incomplete) — real editing scenario.
    const source =
        \\fn add(x: i32, y: i32) { return x; }
        \\val r = add(
    ;
    // col 12 = depois do '(' em "val r = add("
    const cursor = h.pos(1, 12);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    try snap.assertSignatureHelp(gpa, "sig_first_param", source, cursor, result);
}

// ── SH2 — after comma shows second parameter ──

test "signature_help: cursor after comma shows second param" {
    const gpa = std.testing.allocator;

    // Bindings from the last successful compilation.
    const bindings_source =
        \\fn add(x: i32, y: i32) { return x; }
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Current source (incomplete): user typed first argument and comma.
    const source =
        \\fn add(x: i32, y: i32) { return x; }
        \\val r = add(1,
    ;
    // col 14 = after comma in "val r = add(1," → active_param=1
    const cursor = h.pos(1, 14);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    if (result) |sh| {
        const active_param = sh.activeParameter orelse 0;
        try std.testing.expectEqual(@as(u32, 1), active_param);
    }
    try snap.assertSignatureHelp(gpa, "sig_second_param", source, cursor, result);
}

// ── SH3 — fora de chamada retorna null ────────────────────────────────────────

test "signature_help: cursor outside a call returns null" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const cursor = h.pos(0, 4);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    try snap.assertSignatureHelp(gpa, "sig_outside_call_null", source, cursor, result);
}

// ── SH4 — function with no parameters ──

test "signature_help: zero-param function" {
    const gpa = std.testing.allocator;

    // Bindings from the last successful compilation.
    const bindings_source =
        \\fn greet() { return 42; }
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Current source (incomplete): user just typed `greet(`.
    const source =
        \\fn greet() { return 42; }
        \\val r = greet(
    ;
    // col 14 = depois do '(' em "val r = greet("
    const cursor = h.pos(1, 14);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    try snap.assertSignatureHelp(gpa, "sig_zero_params", source, cursor, result);
}

// ── SH5 — identifier is not a function ──

test "signature_help: non-function identifier returns null" {
    const gpa = std.testing.allocator;

    // Compile only `val x = 1;` so that bindings carry x : i32 (non-function).
    // We cannot include the incomplete call `val r = x(` in the compiled source
    // because the type-checker rejects calling an integer.
    const bindings_source =
        \\val x = 1;
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Separate source used only for position scanning (not compilation).
    // The engine scans text backwards from cursor, finds `x` before `(`,
    // looks up `x` in bindings, sees it is not a function, and returns null.
    const scan_source =
        \\val x = 1;
        \\val r = x(
    ;
    // col 10 = depois do '(' em "val r = x("
    const cursor = h.pos(1, 10);
    const result = try engine.signatureHelp(arena.allocator(), scan_source, cursor, bindings);

    try snap.assertSignatureHelp(gpa, "sig_non_function_null", scan_source, cursor, result);
}

// ── SH6 — every parameter label is separately highlightable ──
//
// No snapshot: the rendered output would repeat `sig_first_param`. What this
// test adds is the invariant behind it — `ParameterInformation.label` is a
// plain string that clients highlight by *substring*, so two same-typed
// parameters must not share a label, or the client underlines the first one for
// both. Bare type labels (`i32` / `i32`) used to violate exactly this.

test "signature_help: same-typed params get distinct, locatable labels" {
    const gpa = std.testing.allocator;

    // Bindings from the last successful compilation (definition only).
    const bindings_source =
        \\fn compute(n: i32, m: i32) { return n; }
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Current source (incomplete) — user just typed `compute(`.
    const source =
        \\fn compute(n: i32, m: i32) { return n; }
        \\val r = compute(
    ;
    // col 16 = depois do '(' em "val r = compute("
    const cursor = h.pos(1, 16);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    const sh = result orelse return error.NoSignatureHelp;
    try std.testing.expect(sh.signatures.len > 0);
    const label = sh.signatures[0].label;
    try std.testing.expect(std.mem.indexOf(u8, label, "compute") != null);

    const params = sh.signatures[0].parameters orelse return error.NoParams;
    try std.testing.expectEqual(@as(usize, 2), params.len);
    try std.testing.expect(!std.mem.eql(u8, params[0].label, params[1].label));
    // Each label must occur in the signature label, at its own offset.
    const at0 = std.mem.indexOf(u8, label, params[0].label) orelse return error.LabelNotInSignature;
    const at1 = std.mem.indexOf(u8, label, params[1].label) orelse return error.LabelNotInSignature;
    try std.testing.expect(at0 < at1);
}

// ── SH-F4 — interface method on a builtin receiver (self dropped) ──────────────

test "signature_help: interface method on integer receiver drops self" {
    const gpa = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // `42.clamp(lo, hi)` — `self` is the receiver, so the signature shows
    // only `lo` / `hi` (`clamp(self: Self, lo: Self, hi: Self)`).
    const source =
        \\val r = 42.clamp(
    ;
    // col 17 = right after `(` in "val r = 42.clamp("
    const cursor = h.pos(0, 17);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, &.{});

    try std.testing.expect(result != null);
    if (result) |sh| {
        try std.testing.expect(sh.signatures.len > 0);
        const params = sh.signatures[0].parameters orelse return error.NoParams;
        // self dropped → exactly lo, hi.
        try std.testing.expectEqual(@as(usize, 2), params.len);
        try std.testing.expect(std.mem.indexOf(u8, params[0].label, "lo") != null);
    }
    try snap.assertSignatureHelp(gpa, "sig_interface_method", source, cursor, result);
}

// ── front 11 carve-out: the surface spelling of an optional ────────────────────

test "signature_help: an optional parameter is labelled `?string`" {
    const gpa = std.testing.allocator;

    const bindings_source =
        \\fn find(k: ?string, n: i32) -> ?i32 { return null; }
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const source =
        \\fn find(k: ?string, n: i32) -> ?i32 { return null; }
        \\val r = find(
    ;
    // col 13 = right after `(` in "val r = find("
    const cursor = h.pos(1, 13);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    try std.testing.expect(result != null);
    // The label is read against the declaration one line above it: the two must
    // spell the same type.
    try std.testing.expect(std.mem.indexOf(u8, result.?.signatures[0].label, "optional<") == null);
    try snap.assertSignatureHelp(gpa, "sig_optional_params", source, cursor, result);
}
