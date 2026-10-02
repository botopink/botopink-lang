//! What decorators record about the program for reflection to read back
//! (decision 216): the comptime meta of each declaration (`decl.setMeta`, read
//! as `@typeinfo(X).meta.<decorator>.<key>`) and the associated types of each
//! owner (`decl.addType`, named `Owner.Name`).
//!
//! One `Reflection` lives for one compile session (`comptime.zig` `compile` /
//! `compileTypesOnly`) and every module's `Env` points at it
//! (`Env.reflection`). A decorator writes its declaration's entries while its
//! module is analysed — before any body of that module is inferred — and an
//! importer, analysed later, reads them, so meta travels with the declaration
//! the way its exports do.
const std = @import("std");
const envMod = @import("env.zig");

/// One `decl.setMeta(key, value)`.
pub const MetaEntry = struct {
    /// The decorator's own name (`entity`, never the `orm.entity` an
    /// annotation may spell): the namespace `@typeinfo(X).meta.<decorator>`
    /// reads.
    decorator: []const u8,
    key: []const u8,
    value: []const u8,
};

pub const Reflection = struct {
    arena: std.mem.Allocator,
    /// `envMod.declIdentity(module, name)` → the declaration's entries, in the
    /// order its decorators set them.
    meta: std.StringHashMapUnmanaged(std.ArrayListUnmanaged(MetaEntry)) = .empty,
    /// `envMod.declIdentity(module, owner)` → the names of the owner's
    /// associated types (`decl.addType`, decision 216 (3)), in declaration
    /// order. Read by `assoc_types.zig` to resolve `Owner.Name` in the owner's
    /// module and in every importer.
    assoc: std.StringHashMapUnmanaged(std.ArrayListUnmanaged([]const u8)) = .empty,

    pub fn init(arena: std.mem.Allocator) Reflection {
        return .{ .arena = arena };
    }

    /// Record one entry; false when this decorator already set `key` on the
    /// declaration (a key is set once — `decorator-meta-duplicate`).
    pub fn addMeta(self: *Reflection, module: []const u8, name: []const u8, entry: MetaEntry) !bool {
        const id = try envMod.declIdentity(self.arena, module, name);
        const slot = try self.meta.getOrPut(self.arena, id);
        if (!slot.found_existing) slot.value_ptr.* = .empty;
        for (slot.value_ptr.items) |e| {
            if (std.mem.eql(u8, e.decorator, entry.decorator) and std.mem.eql(u8, e.key, entry.key)) return false;
        }
        try slot.value_ptr.append(self.arena, entry);
        return true;
    }

    /// Record that `owner` has the associated type `name`; false when it
    /// already has one of that name (`decorator-type-duplicate`).
    pub fn addAssoc(self: *Reflection, module: []const u8, owner: []const u8, name: []const u8) !bool {
        const id = try envMod.declIdentity(self.arena, module, owner);
        const slot = try self.assoc.getOrPut(self.arena, id);
        if (!slot.found_existing) slot.value_ptr.* = .empty;
        for (slot.value_ptr.items) |n| if (std.mem.eql(u8, n, name)) return false;
        try slot.value_ptr.append(self.arena, name);
        return true;
    }

    /// The associated type names of `owner`; empty when none.
    pub fn assocOf(self: *const Reflection, arena: std.mem.Allocator, module: []const u8, owner: []const u8) ![]const []const u8 {
        const id = try envMod.declIdentity(arena, module, owner);
        return if (self.assoc.get(id)) |list| list.items else &.{};
    }

    /// Every entry of the declaration, in set order; empty when none.
    pub fn metaOf(self: *const Reflection, arena: std.mem.Allocator, module: []const u8, name: []const u8) ![]const MetaEntry {
        const id = try envMod.declIdentity(arena, module, name);
        return if (self.meta.get(id)) |list| list.items else &.{};
    }
};

test "reflection: a key is set once per decorator, and read back in order" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    var r = Reflection.init(arena_state.allocator());
    try std.testing.expect(try r.addMeta("app/models", "City", .{ .decorator = "entity", .key = "table", .value = "cities" }));
    try std.testing.expect(try r.addMeta("app/models", "City", .{ .decorator = "audited", .key = "table", .value = "a" }));
    try std.testing.expect(!try r.addMeta("app/models", "City", .{ .decorator = "entity", .key = "table", .value = "again" }));
    const got = try r.metaOf(arena_state.allocator(), "app/models", "City");
    try std.testing.expectEqual(@as(usize, 2), got.len);
    try std.testing.expectEqualStrings("cities", got[0].value);
    try std.testing.expectEqual(@as(usize, 0), (try r.metaOf(arena_state.allocator(), "app/models", "Town")).len);
}
