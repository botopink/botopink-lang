/// Completion through the **server** path — `Server.completionItems`, which is
/// everything `textDocument/completion` answers minus the JSON frame.
///
/// The engine tests in `completion.zig` call `engine.completion` directly with
/// bindings a test compiled by hand; that path was always green while the editor
/// showed nothing, because the server answered `null` for every document whose
/// module did not type-check (front 14 step 1, found by the B6 investigation).
/// These tests drive the decision the server makes — compile, then complete with
/// the module's bindings or without any — so that defect cannot come back.
const std = @import("std");
const h = @import("./helpers.zig");
const proto = @import("../protocol.zig");
const server_mod = @import("../server.zig");

fn hasLabel(items: []const proto.CompletionItem, name: []const u8) bool {
    for (items) |it| if (std.mem.eql(u8, it.label, name)) return true;
    return false;
}

fn freeItems(gpa: std.mem.Allocator, items: []const proto.CompletionItem) void {
    for (items) |it| {
        gpa.free(it.label);
        if (it.detail) |d| gpa.free(d);
        if (it.insertText) |t| gpa.free(t);
    }
    gpa.free(items);
}

/// Completion items for `source` at `pos`, through the server. The document is
/// opened in the server's file cache first, the way `didOpen` does it.
fn completeThroughServer(
    gpa: std.mem.Allocator,
    source: []const u8,
    pos: proto.Position,
) ![]proto.CompletionItem {
    var server = server_mod.Server.init(gpa, std.testing.io, null);
    defer server.deinit();
    try server.files.open(h.TEST_URI, source);
    return server.completionItems(h.TEST_URI, source, pos);
}

// ── S1 — a module that type-checks answers from its typed bindings ────────────

test "completion (server): a healthy module completes from its bindings" {
    const gpa = std.testing.allocator;
    const source =
        \\val other = 1;
        \\fn f() -> i32 { return 1; }
        \\val x = other;
    ;

    // cursor on `other` in the last line (prefix `oth`)
    const items = try completeThroughServer(gpa, source, h.pos(2, 11));
    defer freeItems(gpa, items);

    try std.testing.expect(hasLabel(items, "other"));
    // `x` is the binding being defined on this very line.
    try std.testing.expect(!hasLabel(items, "x"));
}

// ── S2 — a type error elsewhere must not blank the list ───────────────────────

test "completion (server): a type error elsewhere still completes" {
    const gpa = std.testing.allocator;
    const source =
        \\val other = 1;
        \\val bad: i32 = "not an i32";
        \\val x = other;
    ;

    const items = try completeThroughServer(gpa, source, h.pos(2, 11));
    defer freeItems(gpa, items);

    // Before front 14 the server answered `null` here: one bad line, no
    // completion anywhere in the file.
    try std.testing.expect(items.len > 0);
    try std.testing.expect(hasLabel(items, "other"));
}

// ── S3 — a file being typed (no terminator yet) still completes ───────────────

test "completion (server): a half-typed line still completes" {
    const gpa = std.testing.allocator;
    const source =
        \\val other = 1;
        \\fn helper() -> i32 { return 2; }
        \\val x = oth
    ;

    // cursor at the end of the half-typed line, prefix `oth`
    const items = try completeThroughServer(gpa, source, h.pos(2, 11));
    defer freeItems(gpa, items);

    try std.testing.expect(hasLabel(items, "other"));
    try std.testing.expect(!hasLabel(items, "helper")); // prefix filters it out
}

// ── S4 — a failing `@emit` keeps the module's names ───────────────────────────

test "completion (server): a failing @emit keeps the module's declarations" {
    const gpa = std.testing.allocator;
    const source =
        \\fn service(comptime decl: @Decl) {
        \\    @emit("val __wired = unresolvedRuntimeSymbol();");
        \\}
        \\
        \\#[service]
        \\type PostService(name: string, count: i32)
        \\
        \\val other = 1;
        \\val usePost = PostService;
    ;

    const items = try completeThroughServer(gpa, source, h.pos(8, 14));
    defer freeItems(gpa, items);

    try std.testing.expect(hasLabel(items, "PostService"));
    try std.testing.expect(hasLabel(items, "other"));
    // The binding being defined is not in scope inside its own initialiser.
    try std.testing.expect(!hasLabel(items, "usePost"));
}

// ── S5 — a `val` declared after the cursor is not in scope ────────────────────

test "completion (server): a val declared below the cursor is not offered" {
    const gpa = std.testing.allocator;
    const source =
        \\val above = 1;
        \\val x = a;
        \\val alsoBelow = 3;
    ;

    // cursor on `a` in line 1 (prefix `a`): `above` is in scope, `alsoBelow` is not.
    const items = try completeThroughServer(gpa, source, h.pos(1, 9));
    defer freeItems(gpa, items);

    try std.testing.expect(hasLabel(items, "above"));
    try std.testing.expect(!hasLabel(items, "alsoBelow"));
}

// ── S6 — locals of a decorator body, through the server ───────────────────────
//
// `completion_decorator_body_locals` in `completion.zig` pins the engine's view
// of this shape; this is the same fixture through the server, where it used to
// answer nothing at all (the body does not type-check).

test "completion (server): decorator body lists its locals" {
    const gpa = std.testing.allocator;
    const source =
        \\pub fn component(comptime decl: @Decl) {
        \\    var args = "";
        \\    items.forEach({ f ->
        \\        log(args);
        \\    });
        \\}
    ;

    const items = try completeThroughServer(gpa, source, h.pos(3, 8));
    defer freeItems(gpa, items);

    try std.testing.expect(hasLabel(items, "decl")); // comptime parameter
    try std.testing.expect(hasLabel(items, "args")); // `var` local
    try std.testing.expect(hasLabel(items, "f")); //    closure binder
    try std.testing.expect(hasLabel(items, "component")); // module-level fallback
}
