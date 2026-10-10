//! Decisions 384 and 385 — a name resolves where it was written, wherever the
//! code that holds it is read: 112's hygiene for a library decorator's member
//! (384) and for an annotation's `@Expr<T>` meta field read in another module
//! (385).
//!
//! Each module publishes its scope when its analysis ends (`publish`): every
//! top-level declaration, and every import followed to the module that
//! declares it (`Reflection.scopes`). A reader of a name another module wrote
//! asks that scope (`Reflection.written`) and binds the declaration under the
//! alias `envMod.templateAlias(module, name)` — a name no source writes —:
//! a value through the binding and `Env.templateImports`, which `comptime.zig`
//! `withTemplateHygiene` imports for the backends (`bindValue`), a type
//! through an aliased import the re-analysis adds (`typeImports`). A private
//! function or value travels as a template's does: a module that shares its
//! privates (`sharesPrivates`) exports them under `envMod.templatePrivateKey`
//! and marks them `pub` for the backends only.
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const Env = envMod.Env;
const reflectionMod = @import("reflection.zig");
const member_fn = @import("member_fn.zig");
const dslHygiene = @import("dsl_hygiene.zig");
const alias_erase = @import("alias_erase.zig");
const format = @import("../format.zig");
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;

pub const Error = error{OutOfMemory};

/// Publish what each top-level name of `program` and each import of `env`
/// resolves to in this module (`Reflection.scopes`).
pub fn publish(env: *Env, program: ast.Program) Error!void {
    const r = env.reflection orelse return;
    for (program.decls) |d| {
        const name: []const u8, const isType: bool = switch (d) {
            .@"fn" => |f| .{ f.name, false },
            .val => |v| .{ v.name, false },
            .type_ => |t| .{ t.name, true },
            .typeAlias => |a| .{ a.name, true },
            else => continue,
        };
        if (name.len == 0) continue;
        try r.scopes.put(r.arena, try reflectionMod.Reflection.scopeKey(r.arena, env.modulePath, name), .{ .module = env.modulePath, .name = name, .isType = isType });
    }
    var it = env.importOwners.iterator();
    while (it.next()) |e| {
        const o = e.value_ptr.*;
        try r.scopes.put(r.arena, try reflectionMod.Reflection.scopeKey(r.arena, env.modulePath, e.key_ptr.*), .{ .module = o.owner, .name = o.name, .isType = typeAt(env, o.owner, o.name) });
    }
}

fn typeAt(env: *const Env, module: []const u8, name: []const u8) bool {
    const registry = env.typeDeclRegistry orelse return false;
    const decls = registry.get(module) orelse return false;
    const d = decls.get(name) orelse return false;
    return d == .type_ or d == .typeAlias;
}

/// The alias a type of `module` is imported under: `templateAlias`'s, upper-
/// cased in front (`Bp__bp_tpl_<module>__<Name>`) — a constructor reached under
/// an alias takes its fields' labels when the alias is spelled as a type.
pub fn typeAliasOf(arena: std.mem.Allocator, module: []const u8, name: []const u8) Error![]const u8 {
    return std.fmt.allocPrint(arena, "Bp{s}", .{try envMod.templateAlias(arena, module, name)});
}

/// Whether `decls` (module `path`) shares its private functions and values
/// with the modules that read what it wrote: it declares a decorator whose
/// body hands a typed member on (384), or a declaration of it carries typed
/// meta with `@Expr` fields an annotation of it wrote (385).
pub fn sharesPrivates(arena: std.mem.Allocator, decls: []const ast.DeclKind, reflection: ?*const reflectionMod.Reflection, path: []const u8) Error!bool {
    for (decls) |d| if (d == .@"fn") {
        const f = d.@"fn";
        if (member_fn.declParamName(f)) |handle| if ((try member_fn.collect(arena, f, handle)).len > 0) return true;
    };
    const r = reflection orelse return false;
    var it = r.typedMeta.valueIterator();
    while (it.next()) |list| for (list.items) |e| {
        if (e.hasExpr and std.mem.eql(u8, e.annotationModule, path)) return true;
    };
    return false;
}

/// Bind the value `name` of `module` in `env` under its alias, module-wide
/// like an import, and record it for the backends; null when `module` does
/// not export it (nor share it as a private).
pub fn bindValue(env: *Env, module: []const u8, name: []const u8) Error!?[]const u8 {
    const registry = env.exportsRegistry orelse return null;
    const exports = registry.getPtr(module) orelse return null;
    const ty = exports.get(name) orelse
        exports.get(try envMod.templatePrivateKey(env.arena, name)) orelse return null;
    const alias = try envMod.templateAlias(env.arena, module, name);
    if (!env.templateImports.contains(alias)) {
        try env.templateImports.put(env.arena, alias, .{ .owner = module, .name = name });
        const scope = env.bodyScope;
        env.bodyScope = null;
        defer env.bodyScope = scope;
        env.bind(alias, ty) catch return error.OutOfMemory;
    }
    return alias;
}

/// The re-analysis' half: each value a first analysis recorded, bound again.
pub fn bindRecorded(env: *Env, recorded: []const envMod.HygieneImport) Error!void {
    for (recorded) |h| if (!h.isType) {
        _ = try bindValue(env, h.module, h.name);
    };
}

/// Every type alias `typeImports` bound (`Bp__bp_tpl_…`), erased in place in
/// `decls`' types for the modules that import them (`comptime.zig`
/// `registerExports`).
pub fn eraseTypeAliases(arena: std.mem.Allocator, decls: []const ast.DeclKind, aliases: *const alias_erase.Aliases) Error!void {
    var mine: alias_erase.Aliases = .empty;
    var it = aliases.iterator();
    while (it.next()) |e| if (std.mem.startsWith(u8, e.key_ptr.*, type_alias_prefix)) try mine.put(arena, e.key_ptr.*, e.value_ptr.*);
    if (mine.count() == 0) return;
    for (decls) |d| if (d == .type_) {
        _ = try alias_erase.erase(arena, .{ .decls = @constCast(&[_]ast.DeclKind{d}) }, &mine);
    };
}

const type_alias_prefix = "Bp__bp_tpl_";

/// The re-analysis' imports of each recorded type, under its alias:
/// `import {Violation as Bp__bp_tpl_rules__Violation} from "rules";`.
pub fn typeImports(arena: std.mem.Allocator, recorded: []const envMod.HygieneImport) Error![]const ast.DeclKind {
    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var seen: std.StringHashMapUnmanaged(void) = .empty;
    for (recorded) |h| {
        if (!h.isType or seen.contains(h.alias)) continue;
        try seen.put(arena, h.alias, {});
        const src = try std.fmt.allocPrint(arena, "import {{{s} as {s}}} from \"{s}\";", .{ h.name, h.alias, h.module });
        var lx = Lexer.init(src);
        const tokens = lx.scanAll(arena) catch return error.OutOfMemory;
        var p = Parser.init(tokens);
        const parsed = p.parse(arena) catch return error.OutOfMemory;
        try out.appendSlice(arena, parsed.decls);
    }
    return out.items;
}

/// A resolver (`dsl_hygiene.applyAll`) binding each value `module` wrote in
/// `env` (385's direct read).
pub const Binder = struct {
    env: *Env,
    module: []const u8,
    renamed: *usize,

    pub fn aliasFor(self: @This(), name: []const u8) Error!?[]const u8 {
        const r = self.env.reflection orelse return null;
        const w = (try r.written(self.env.arena, self.module, name)) orelse return null;
        if (w.isType) return null;
        const alias = (try bindValue(self.env, w.module, w.name)) orelse return null;
        self.renamed.* += 1;
        return alias;
    }
};

/// A resolver recording each value `module` wrote for a re-analysis to bind
/// (385 through a `@TypeInfo.all` entry, `typeinfo_all.zig`).
pub const Collector = struct {
    arena: std.mem.Allocator,
    reflection: *const reflectionMod.Reflection,
    module: []const u8,
    out: *std.ArrayListUnmanaged(envMod.HygieneImport),
    renamed: *usize,

    pub fn aliasFor(self: @This(), name: []const u8) Error!?[]const u8 {
        const w = (try self.reflection.written(self.arena, self.module, name)) orelse return null;
        if (w.isType) return null;
        const alias = try envMod.templateAlias(self.arena, w.module, w.name);
        try self.out.append(self.arena, .{ .alias = alias, .module = w.module, .name = w.name, .isType = false });
        self.renamed.* += 1;
        return alias;
    }
};

/// A typed meta value's constructor arguments as written, `(message: "…",
/// rule: passwordsMatch)` (`typed_meta.render`), with every name the
/// annotation wrote renamed by `resolver` — `renamed` counts the renames; the
/// text comes back unchanged when there is none.
pub fn renameArgs(arena: std.mem.Allocator, args: []const u8, resolver: anytype, renamed: *usize) Error![]const u8 {
    const head = "__bp_wn_ctor";
    const src = try std.fmt.allocPrint(arena, "val __bp_wn = {s}{s};", .{ head, args });
    var lx = Lexer.init(src);
    const tokens = lx.scanAll(arena) catch return args;
    var p = Parser.init(tokens);
    const parsed = p.parse(arena) catch return args;
    if (parsed.decls.len != 1 or parsed.decls[0] != .val) return args;
    const node = parsed.decls[0].val.value;
    const before = renamed.*;
    try dslHygiene.applyAll(arena, node, resolver);
    if (renamed.* == before) return args;
    var fm = format.Formatter.init(arena);
    const doc = fm.fmtExpr(node.*) catch return error.OutOfMemory;
    const text = format.render(arena, doc, std.math.maxInt(u16)) catch return error.OutOfMemory;
    if (!std.mem.startsWith(u8, text, head)) return args;
    return text[head.len..];
}

/// Whether this module holds a type named `name` other than `module`'s own —
/// declared here or imported from elsewhere: one module holds one type of a
/// name (`import-name-collision`, decision 310's gap).
pub fn typeNameTaken(env: *const Env, module: []const u8, name: []const u8) bool {
    if (!std.mem.eql(u8, module, env.modulePath)) for (env.moduleDecls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, name)) return true,
        .typeAlias => |a| if (std.mem.eql(u8, a.name, name)) return true,
        else => {},
    };
    var it = env.importedTypeDecls.iterator();
    while (it.next()) |e| {
        if (std.mem.eql(u8, e.value_ptr.name, name) and !std.mem.eql(u8, e.value_ptr.module, module)) return true;
    }
    return false;
}

test "renameArgs: each name the annotation wrote renamed, literals and labels kept" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const Fixed = struct {
        renamed: *usize,
        pub fn aliasFor(self: @This(), name: []const u8) Error!?[]const u8 {
            if (!std.mem.eql(u8, name, "passwordsMatch")) return null;
            self.renamed.* += 1;
            return "__bp_tpl_signup__passwordsMatch";
        }
    };
    var n: usize = 0;
    const out = try renameArgs(arena, "(message: \"the passwords differ\", rule: passwordsMatch)", Fixed{ .renamed = &n }, &n);
    try std.testing.expectEqualStrings("(message: \"the passwords differ\", rule: __bp_tpl_signup__passwordsMatch)", out);
    n = 0;
    const same = try renameArgs(arena, "(message: \"x\", rule: { v -> v.ok })", Fixed{ .renamed = &n }, &n);
    try std.testing.expectEqualStrings("(message: \"x\", rule: { v -> v.ok })", same);
}
