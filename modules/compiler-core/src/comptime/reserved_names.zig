//! Decision 805 (6), 144 B-163 — the names the compiler keeps for itself. A
//! hand-written declaration whose name holds `$` (the specialiser's
//! `name_$N`), starts with `__bp_` (a value, a function, a parameter, a field)
//! or with `Bp__` (a type) is refused at the name, `reserved-name`.
//!
//! The walk reads the module's parse, before any expansion adds what the
//! compiler writes (`__bp_tpl_`, `__bp_ns_`, `__bp_loaded*`, `Bp__Load*`, …), so
//! only the names a person wrote are checked.
const std = @import("std");
const ast = @import("../ast.zig");
const diagnostics = @import("diagnostics.zig");
const TypeError = @import("error.zig").TypeError;
const mayHoldExpr = @import("std_namespace.zig").mayHoldExpr;

const Error = std.mem.Allocator.Error;

const Kind = enum { value, type_ };

fn reserved(name: []const u8, kind: Kind) bool {
    if (std.mem.indexOfScalar(u8, name, '$') != null) return true;
    return switch (kind) {
        .value => std.mem.startsWith(u8, name, "__bp_"),
        .type_ => std.mem.startsWith(u8, name, "Bp__"),
    };
}

pub const Walker = struct {
    arena: std.mem.Allocator,
    /// The module's text: the parser itself writes a few names into the tree
    /// (`__bp_ct_decl`, `__bp_comptime_<k>`, `__bp_customTree`), and a name
    /// the text never spells is one of those, not a person's.
    source: []const u8,
    found: ?TypeError = null,
    loc: ast.Loc = .{ .line = 0, .col = 0 },

    fn note(self: *Walker, name: []const u8, kind: Kind, loc: ?ast.Loc) Error!void {
        if (self.found != null or !reserved(name, kind)) return;
        const bare = std.mem.trim(u8, name, "`");
        if (std.mem.indexOf(u8, self.source, bare) == null) return;
        const why = if (std.mem.indexOfScalar(u8, name, '$') != null)
            "a name holding `$`"
        else if (kind == .type_)
            "a name starting with `Bp__`"
        else
            "a name starting with `__bp_`";
        // A backtick name (561) keeps its backticks in the AST.
        const quote: []const u8 = if (std.mem.startsWith(u8, name, "`")) "" else "`";
        const msg = try std.fmt.allocPrint(self.arena, "{s}: {s}{s}{s} is reserved for the compiler ({s} is the compiler's)", .{ diagnostics.reserved_name, quote, name, quote, why });
        var te = TypeError.custom(msg, "Rename it. The compiler writes names with `$`, `__bp_` and `Bp__` itself (specialised copies, templates, loaded packages), so a hand-written one could meet its own.");
        const at = loc orelse self.loc;
        if (at.line != 0) te = te.withLoc(at);
        self.found = te;
    }

    pub fn walk(self: *Walker, comptime T: type, ptr: *const T) Error!void {
        if (self.found != null) return;
        if (T == ast.Param) try self.note(ptr.name, .value, if (ptr.loc.line != 0) ptr.loc else null);
        if (T == ast.Field) try self.note(ptr.name, .value, null);
        if (T == ast.FnDecl) try self.note(ptr.name, .value, ptr.nameLoc);
        if (T == ast.TypeDecl) try self.note(ptr.name, .type_, ptr.loc);
        if (T == ast.TypeAliasDecl) try self.note(ptr.name, .type_, ptr.loc);
        if (T == ast.ImportDecl) return;
        switch (@typeInfo(T)) {
            .@"struct" => |s| {
                if (comptime hasField(s.fields, "loc") and fieldIs(s.fields, "loc", ast.Loc)) {
                    if (ptr.loc.line != 0) self.loc = ptr.loc;
                }
                if (comptime hasField(s.fields, "params") and fieldIs(s.fields, "params", []const []const u8)) {
                    for (ptr.params) |n| try self.note(n, .value, null);
                }
                if (comptime T != ast.FnDecl and hasField(s.fields, "name") and hasField(s.fields, "value") and hasField(s.fields, "mutable") and fieldIs(s.fields, "name", []const u8)) {
                    const at: ?ast.Loc = if (comptime hasField(s.fields, "nameLoc")) ptr.nameLoc else null;
                    try self.note(ptr.name, .value, at);
                }
                inline for (s.fields) |f| {
                    if (f.is_comptime) continue;
                    if (comptime mayHoldExpr(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
                }
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                        try self.walk(@TypeOf(payload.*), payload);
                    },
                }
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) try self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, e);
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*e| try self.walk(arr.child, e);
            },
            else => {},
        }
    }

    fn hasField(comptime fields: anytype, comptime name: []const u8) bool {
        inline for (fields) |f| if (comptime std.mem.eql(u8, f.name, name)) return true;
        return false;
    }

    fn fieldIs(comptime fields: anytype, comptime name: []const u8, comptime T: type) bool {
        inline for (fields) |f| if (comptime std.mem.eql(u8, f.name, name)) return f.type == T;
        return false;
    }
};

/// The refusal for the first reserved name `program` (a module as written)
/// declares (`source` is its text), or null.
/// The resolved program's oracle (`comptime/resolved_print.zig`, decision
/// 798 (5)) reads back the compiler's own printing, whose names are the
/// compiler's: set only by that test, never by a driver — the compiler never
/// takes `--emit-resolved`'s text back (798 (2)).
pub var accept_compiler_names: bool = false;

pub fn check(arena: std.mem.Allocator, source: []const u8, program: ast.Program) Error!?TypeError {
    if (accept_compiler_names) return null;
    var w = Walker{ .arena = arena, .source = source };
    for (program.decls) |*d| {
        try w.walk(ast.DeclKind, d);
        if (w.found) |te| return te;
    }
    return null;
}

test "reserved spellings" {
    try std.testing.expect(reserved("pad_$1", .value));
    try std.testing.expect(reserved("__bp_x", .value));
    try std.testing.expect(!reserved("Bp__X", .value));
    try std.testing.expect(reserved("Bp__X", .type_));
    try std.testing.expect(!reserved("__bp_x", .type_));
    try std.testing.expect(!reserved("bp_x", .value));
}
