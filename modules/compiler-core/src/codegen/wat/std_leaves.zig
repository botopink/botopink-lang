//! Front 164 s3 — std-wasm's leaves: the hand-written `.wat` functions of
//! `modules/std-wasm/wat/`, read by `wat_reader.zig` into the program that
//! calls them.
//!
//! A leaf is `(func $<module>.<function> …)` in one of the files `build.zig`
//! lists (`std_wasm_leaf_files`, embedded as `std_wasm_wat/<file>`). A `std:`
//! cell whose name is a leaf (`host_binding.parse`) is answered by it in a
//! WasmGC module: the program calls `$__std_<module>_<function>` (the symbol
//! `std_wasm_link.entryName` spells), and the leaf is read and emitted as an
//! ordinary function of the module only when something calls it — an
//! unreached leaf is never in the module. A leaf names the codegen's GC types
//! and never declares one (decision 549). A name still in `std_wasm.exports`
//! keeps std-wasm's function in a module lowered in linear memory.

const std = @import("std");
const ast = @import("wat_ast.zig");
const reader = @import("wat_reader.zig");
const opts = @import("std_wasm_leaves");

/// One file of leaves: the path a refusal names, and its text.
pub const File = struct { path: []const u8, text: []const u8 };

/// Every leaf file, as `build.zig` lists them.
pub const files: [opts.files.len]File = blk: {
    var out: [opts.files.len]File = undefined;
    for (opts.files, 0..) |f, i| out[i] = .{
        .path = "modules/std-wasm/wat/" ++ f,
        .text = @embedFile("std_wasm_wat/" ++ f),
    };
    break :blk out;
};

/// A leaf: its `<module>.<function>` name and the file that holds it.
pub const Leaf = struct {
    name: []const u8,
    file: usize,
};

/// The leaf named `name` (`text.length`), or null.
pub fn find(name: []const u8) ?Leaf {
    for (files, 0..) |f, i| {
        var it = reader.FuncNames.init(f.text);
        while (it.next()) |n| if (std.mem.eql(u8, n, name)) return .{ .name = name, .file = i };
    }
    return null;
}

/// Every leaf's name, `, `-separated, owned by the caller — what a refusal lists.
pub fn names(ar: std.mem.Allocator) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (files) |f| {
        var it = reader.FuncNames.init(f.text);
        while (it.next()) |n| {
            if (out.items.len > 0) try out.appendSlice(ar, ", ");
            try out.appendSlice(ar, n);
        }
    }
    return out.toOwnedSlice(ar);
}

/// The symbol a program calls the leaf `name` by: `text.length` →
/// `__std_text_length` (`std_wasm_link.entryName`'s spelling).
pub fn symbol(ar: std.mem.Allocator, name: []const u8) ![]const u8 {
    const out = try std.fmt.allocPrint(ar, "__std_{s}", .{name});
    std.mem.replaceScalar(u8, out, '.', '_');
    return out;
}

/// Whether `sym` is the symbol of a leaf (`__std_text_length`).
pub fn isSymbol(sym: []const u8) bool {
    if (!std.mem.startsWith(u8, sym, "__std_")) return false;
    const rest = sym["__std_".len..];
    for (files) |f| {
        var it = reader.FuncNames.init(f.text);
        while (it.next()) |n| {
            if (n.len != rest.len) continue;
            const same = for (n, rest) |a, b| {
                if (a != b and !(a == '.' and b == '_')) break false;
            } else true;
            if (same) return true;
        }
    }
    return false;
}

/// What a leaf's types resolve against: the module's type table (decision
/// 549), as the codegen answers it.
pub const Types = struct {
    ctx: *anyopaque,
    index: *const fn (ctx: *anyopaque, name: []const u8) ?u16,
};

/// The leaf `name` read against `types`, renamed to its symbol, and the
/// leaves it calls (`calls`, by name, appended). A leaf that does not read is
/// `error.Unreadable`, `diag` locating it in its file.
pub fn read(ar: std.mem.Allocator, leaf: Leaf, types: Types, calls: *std.ArrayListUnmanaged([]const u8), diag: *reader.Diag) reader.Error!ast.Func {
    const Ctx = struct {
        ar: std.mem.Allocator,
        types: Types,
        calls: *std.ArrayListUnmanaged([]const u8),
        oom: bool = false,

        fn typeIndex(p: *anyopaque, n: []const u8) ?u16 {
            const c: *@This() = @ptrCast(@alignCast(p));
            return c.types.index(c.types.ctx, n);
        }

        fn callee(p: *anyopaque, n: []const u8) ?[]const u8 {
            const c: *@This() = @ptrCast(@alignCast(p));
            if (find(n) == null) return null;
            c.calls.append(c.ar, n) catch {
                c.oom = true;
                return null;
            };
            return symbol(c.ar, n) catch {
                c.oom = true;
                return null;
            };
        }
    };
    var ctx: Ctx = .{ .ar = ar, .types = types, .calls = calls };
    const f = files[leaf.file];
    const funcs = reader.read(ar, f.text, f.path, .{ .ctx = &ctx, .typeIndex = Ctx.typeIndex, .callee = Ctx.callee }, diag) catch |err| {
        if (ctx.oom) return error.OutOfMemory;
        return err;
    };
    for (funcs) |func| if (std.mem.eql(u8, func.name, leaf.name)) {
        var out = func;
        out.name = try symbol(ar, leaf.name);
        return out;
    };
    unreachable; // `find` answered the leaf from this file's function names
}

test "std_leaves: every leaf reads against the codegen's GC types" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ar = arena.allocator();
    const T = struct {
        const known = [_][]const u8{ "str", "arr_i32", "arr_f64", "arr_any", "box_i32", "box_i64", "box_f64", "result" };
        fn index(_: *anyopaque, n: []const u8) ?u16 {
            for (known, 0..) |k, i| if (std.mem.eql(u8, k, n)) return @intCast(i);
            return null;
        }
        var dummy: u8 = 0;
    };
    var count: usize = 0;
    for (files, 0..) |f, i| {
        var it = reader.FuncNames.init(f.text);
        while (it.next()) |n| {
            var calls: std.ArrayListUnmanaged([]const u8) = .empty;
            var diag: reader.Diag = .{};
            const func = read(ar, .{ .name = n, .file = i }, .{ .ctx = &T.dummy, .index = T.index }, &calls, &diag) catch |err| {
                std.debug.print("\n{s}\n", .{try diag.text(ar)});
                return err;
            };
            try std.testing.expect(isSymbol(func.name));
            count += 1;
        }
    }
    try std.testing.expect(count > 0);
    try std.testing.expect(find("text.length") != null);
    for ([_][]const u8{ "text.length", "text.charCodeAt", "text.byteLength", "text.byteAt", "text.byteSlice", "text.fromCodepoint", "number.i32ToString", "number.i64ToString", "number.u64ToString" }) |n|
        try std.testing.expect(find(n) != null);
    try std.testing.expect(find("text.sha256") == null);
    try std.testing.expectEqualStrings("__std_text_charCodeAt", try symbol(ar, "text.charCodeAt"));
    try std.testing.expect(!isSymbol("__std_text_split"));
}
