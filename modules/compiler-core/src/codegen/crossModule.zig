//! Backend-agnostic cross-module link analysis.
//!
//! Built once over every module's transformed program, this index lets each
//! emitter resolve a name imported `from "<pkg>"` to the module that actually
//! emits it — so a consumer can `require`/remote-call into the owner, construct
//! an imported record with the owner's declared field order, and the owner can
//! `export` only the symbols another module actually consumes.
//!
//! commonJS, erlang, and beam_asm all share this one analysis. wasm stays
//! single-module today (see `wat.zig`), so it ignores the index.

const std = @import("std");
const ast = @import("../ast.zig");
const comptimeMod = @import("../comptime.zig");
const commonJS = @import("./commonJS.zig");

const ComptimeOutput = comptimeMod.ComptimeOutput;

/// Which kind of declaration a `pub` symbol comes from. Mirrors the relevant
/// `ast.Decl` tags; the consumer uses it to pick the right call/construction
/// lowering (a record name is constructed; a `fn`/`val` is referenced).
pub const ExportKind = enum { record, @"struct", @"enum", @"fn", val };

/// Where a `pub` symbol is emitted, for resolving cross-module imports.
/// `module` is the emitting module's path (e.g. `"web/http"`). `is_class`
/// marks record/struct exports whose construction needs `new` (commonJS) or
/// the owner's map shape (erlang/beam). `fields` is the declared field order
/// of a record/struct (empty otherwise) — a consumer needs it to build the map
/// for an imported record literal with positional args.
pub const ExportInfo = struct {
    module: []const u8,
    kind: ExportKind,
    is_class: bool,
    fields: []const []const u8 = &.{},
};

/// Cross-module link info, built once over every module's transformed program.
/// `exports` maps a `pub` symbol name → its emitting module + shape; `imported`
/// is the set of names some module imports (so an owner only emits an export
/// for symbols actually consumed elsewhere — single-module programs stay
/// unchanged).
pub const CrossModule = struct {
    exports: std.StringHashMap(ExportInfo),
    imported: std.StringHashMap(void),
    /// Owns the `fields` arrays allocated for record/struct exports.
    field_arrays: std.ArrayListUnmanaged([]const []const u8) = .empty,
    alloc: std.mem.Allocator,

    pub fn deinit(self: *CrossModule) void {
        for (self.field_arrays.items) |arr| self.alloc.free(arr);
        self.field_arrays.deinit(self.alloc);
        self.exports.deinit();
        self.imported.deinit();
    }

    /// Basename of an export's emitting module path — the Erlang/BEAM module
    /// atom (`"web/http"` → `"http"`). Null when `name` isn't a cross-module
    /// export.
    pub fn ownerModuleAtom(self: *const CrossModule, name: []const u8) ?[]const u8 {
        const info = self.exports.get(name) orelse return null;
        return moduleBasename(info.module);
    }
};

/// Last path segment of a module path — the Erlang/BEAM module atom.
pub fn moduleBasename(path: []const u8) []const u8 {
    if (std.mem.lastIndexOfScalar(u8, path, '/')) |i| return path[i + 1 ..];
    return path;
}

pub fn build(alloc: std.mem.Allocator, outputs: []ComptimeOutput) !CrossModule {
    var exports = std.StringHashMap(ExportInfo).init(alloc);
    errdefer exports.deinit();
    var imported = std.StringHashMap(void).init(alloc);
    errdefer imported.deinit();
    var field_arrays: std.ArrayListUnmanaged([]const []const u8) = .empty;
    errdefer {
        for (field_arrays.items) |arr| alloc.free(arr);
        field_arrays.deinit(alloc);
    }

    for (outputs) |*ct| {
        const ok = switch (ct.outcome) {
            .ok => |*o| o,
            else => continue,
        };
        for (ok.transformed.decls) |decl| switch (decl) {
            .record => |r| if (r.isPub) {
                const fields = try alloc.alloc([]const u8, r.fields.len);
                for (r.fields, 0..) |f, i| fields[i] = f.name;
                try field_arrays.append(alloc, fields);
                try exports.put(r.name, .{ .module = ct.name, .kind = .record, .is_class = true, .fields = fields });
            },
            .@"struct" => |s| if (s.isPub and !commonJS.isPhantomContextStruct(s)) {
                var count: usize = 0;
                for (s.members) |m| {
                    if (m == .field) count += 1;
                }
                const fields = try alloc.alloc([]const u8, count);
                var i: usize = 0;
                for (s.members) |m| switch (m) {
                    .field => |f| {
                        fields[i] = f.name;
                        i += 1;
                    },
                    else => {},
                };
                try field_arrays.append(alloc, fields);
                try exports.put(s.name, .{ .module = ct.name, .kind = .@"struct", .is_class = true, .fields = fields });
            },
            .@"enum" => |e| if (e.isPub) try exports.put(e.name, .{ .module = ct.name, .kind = .@"enum", .is_class = false }),
            // `pub fn` exports — including host-backed `#[@external]` declarations.
            // An external fn's owning module re-exports the host symbol under the
            // fn name (`exports.regItem = regItem`), so a consumer that imports it
            // `from "<lib>"` must `require` that owner just like any other export;
            // omitting externals here left such imports unresolved at the call site.
            .@"fn" => |f| if (f.isPub)
                try exports.put(f.name, .{ .module = ct.name, .kind = .@"fn", .is_class = false }),
            .val => |v| if (v.isPub) try exports.put(v.name, .{ .module = ct.name, .kind = .val, .is_class = false }),
            // A `pub implement` is emitted as a namespace object; a consumer that
            // stars it (`import { Name* }`) references it as a value (`Name.m(x)`).
            .implement => |im| if (im.isPub) try exports.put(im.name, .{ .module = ct.name, .kind = .val, .is_class = false }),
            .use => |u| for (u.imports) |imp| try imported.put(imp.name(), {}),
            else => {},
        };
    }
    return .{ .exports = exports, .imported = imported, .field_arrays = field_arrays, .alloc = alloc };
}
