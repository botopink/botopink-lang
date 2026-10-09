//! What decorators record about the program for reflection to read back
//! (decision 216): the comptime meta of each declaration (`decl.setMeta`, read
//! as `@typeInfo(X).meta.<decorator>.<key>`) and the associated types of each
//! owner (`decl.addType`, named `Owner.Name`), and every top-level declaration
//! a decorator ran over (`@TypeInfo.all(with: d)`).
//!
//! One `Reflection` lives for one compile session (`comptime.zig` `compile` /
//! `compileTypesOnly`) and every module's `Env` points at it
//! (`Env.reflection`). A decorator writes its declaration's entries while its
//! module is analysed — before any body of that module is inferred — and an
//! importer, analysed later, reads them, so meta travels with the declaration
//! the way its exports do.
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");

/// One `decl.setMeta(key, value)`.
pub const MetaEntry = struct {
    /// The decorator's own name (`entity`, never the `orm.entity` an
    /// annotation may spell): the namespace `@typeInfo(X).meta.<decorator>`
    /// reads.
    decorator: []const u8,
    key: []const u8,
    value: []const u8,
};

/// One top-level declaration carrying a body-carrying decorator — what
/// `@TypeInfo.all(with: d)` answers from (`typeinfo_all.zig`).
pub const DeclaredEntry = struct {
    module: []const u8,
    name: []const u8,
    kind: Kind,
    isPub: bool,
    /// Decision 256 — a function's declared return type as the source spells
    /// it (`Clock`), a `val`'s declared type (decision 356, `""` when none);
    /// `""` for a type or a behavior.
    returnTypeName: []const u8 = "",
    /// The decorator's identity: its declaring module and its own name.
    decorator_owner: []const u8,
    decorator_name: []const u8,
    /// Order of recording — source order inside a module.
    seq: usize,

    /// `val` — decision 356: a module-level `val` a decorator annotates.
    pub const Kind = enum { function, type_, behavior, val };
};

/// A decorator's identity: its declaring module and its own name.
pub const DecoratorId = struct { owner: []const u8, name: []const u8 };

/// Decision 353 — one `@TypeInfo.all(…)` written in a template function's
/// body, its arguments resolved in the template's own module (the decorators
/// `with:` names, `member:`). It is answered where the template is expanded,
/// for the program that expansion is compiled in (`typeinfo_all.zig`
/// `answerForTemplate`).
pub const TemplateQuery = struct {
    /// The call's location in the template's body.
    loc: ast.Loc,
    decorators: []const DecoratorId,
    member: ?[]const u8,
    /// How refusals name the decorators: `#[a]`, `#[a]/#[b]`.
    label: []const u8,
};

/// One answer given to a template body's query: where the expansion was
/// (`module`, `loc` — the template call), the template's query, and the
/// answer's text. Compared with the final catalogue after the session
/// (`comptime.zig` `compile`): an answer given before a later module's
/// decorators ran is stale.
pub const TemplateRead = struct {
    module: []const u8,
    loc: ast.Loc,
    query: TemplateQuery,
    text: []const u8,
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
    /// Every top-level declaration a body-carrying decorator ran over, in the
    /// order the decorators ran (decision 216 (4)).
    declared: std.ArrayListUnmanaged(DeclaredEntry) = .empty,
    /// The module paths that read `@TypeInfo.all` — analysed after every
    /// other module; none of them answers another's query.
    readers: std.StringHashMapUnmanaged(void) = .empty,
    /// Decision 353 — `templateKey(owner, name)` → the queries of that
    /// template function's body, recorded when its module is analysed.
    templateQueries: std.StringHashMapUnmanaged([]const TemplateQuery) = .empty,
    /// Every answer a template body's query was given in this session.
    templateReads: std.ArrayListUnmanaged(TemplateRead) = .empty,
    /// The complete catalogue of an earlier session over the same modules:
    /// when set, a template body's query is answered from it, so an expansion
    /// sees declarations of modules analysed after it (`comptime.zig`
    /// `compile`'s second session).
    oracle: ?*const Reflection = null,

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

    /// Record that `decorator` ran over a top-level declaration (once per
    /// declaration and decorator).
    pub fn addDeclared(self: *Reflection, entry: DeclaredEntry) !void {
        for (self.declared.items) |e| {
            if (std.mem.eql(u8, e.module, entry.module) and std.mem.eql(u8, e.name, entry.name) and
                std.mem.eql(u8, e.decorator_owner, entry.decorator_owner) and std.mem.eql(u8, e.decorator_name, entry.decorator_name)) return;
        }
        var e = entry;
        e.seq = self.declared.items.len;
        try self.declared.append(self.arena, e);
    }

    /// The key `templateQueries` holds a template function's queries under.
    pub fn templateKey(arena: std.mem.Allocator, owner: []const u8, name: []const u8) ![]const u8 {
        return std.fmt.allocPrint(arena, "{s}\x00{s}", .{ owner, name });
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
