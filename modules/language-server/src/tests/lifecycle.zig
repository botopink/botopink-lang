/// Tests for the document-sync lifecycle cache — covers `files.FileCache`,
/// which backs `textDocument/didOpen` → `didChange` → `didClose` in the server.
/// The server publishes diagnostics off whatever this cache holds, so the cache
/// staying correct across the three events is the substance of the lifecycle.
const std = @import("std");
const files = @import("../files.zig");

test "lifecycle: FileCache open → change → close tracks the current source" {
    const gpa = std.testing.allocator;
    var cache = files.FileCache.init(gpa);
    defer cache.deinit();

    const uri = "file:///lifecycle.bp";

    // didOpen — the file's first version is cached.
    try cache.open(uri, "val x = 1;");
    try std.testing.expectEqualStrings("val x = 1;", cache.get(uri).?);

    // didChange — a full-text change replaces the cached version.
    try cache.change(uri, "val x = 2;");
    try std.testing.expectEqualStrings("val x = 2;", cache.get(uri).?);

    // didClose — the file drops out of the cache.
    cache.close(uri);
    try std.testing.expect(cache.get(uri) == null);
}

test "lifecycle: didChange on an unopened uri behaves like open" {
    const gpa = std.testing.allocator;
    var cache = files.FileCache.init(gpa);
    defer cache.deinit();

    const uri = "file:///never-opened.bp";
    try cache.change(uri, "val y = 3;");
    try std.testing.expectEqualStrings("val y = 3;", cache.get(uri).?);
}

test "lifecycle: closing one uri leaves the others cached" {
    const gpa = std.testing.allocator;
    var cache = files.FileCache.init(gpa);
    defer cache.deinit();

    try cache.open("file:///a.bp", "val a = 1;");
    try cache.open("file:///b.bp", "val b = 2;");

    cache.close("file:///a.bp");
    try std.testing.expect(cache.get("file:///a.bp") == null);
    try std.testing.expectEqualStrings("val b = 2;", cache.get("file:///b.bp").?);
}

test "lifecycle: reopening a uri replaces the previous contents (no leak)" {
    const gpa = std.testing.allocator;
    var cache = files.FileCache.init(gpa);
    defer cache.deinit();

    const uri = "file:///reopen.bp";
    try cache.open(uri, "val first = 1;");
    try cache.open(uri, "val second = 2;");
    try std.testing.expectEqualStrings("val second = 2;", cache.get(uri).?);
}
