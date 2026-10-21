//! Decision 519 — `@embed(comptime path: string) -> Asset`: the rules a path
//! is held to and the `Asset` a read answers. The checker (`infer.zig`
//! `inferEmbedBuiltin`) reads the path's value at build, asks `checkPath`,
//! reads the file through the module's reader (`Module.files`) and rewrites
//! the call into `asset`'s constructor; `a.text()` reads `text`.
const std = @import("std");
const ast = @import("../ast.zig");
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;

/// The private record a module that writes `@embed` declares (`comptime.zig`
/// `withAssetDecl`) and a `comptime`'s module carries (`block_eval`): the four
/// fields of the `decl_reflection_src` entry. `text()` is computed at build,
/// so no backend calls it.
pub const decl_src = "type Asset(path: string, bytes: bytes, size: i64, hash: string)";

/// `decl_src` parsed.
pub fn typeDecl(arena: std.mem.Allocator) !ast.TypeDecl {
    var lx = Lexer.init(decl_src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const prog = try p.parse(arena);
    return prog.decls[0].type_;
}

/// Why a path is refused before any file is read.
pub const PathRefusal = enum {
    /// `/etc/passwd`, `C:\x` — a package's files are named from its root.
    absolute,
    /// A `..` segment: the path would leave the package.
    outside_package,
};

/// The refusal `path` meets, or null when it names a file of the package.
pub fn checkPath(path: []const u8) ?PathRefusal {
    if (path.len > 0 and (path[0] == '/' or path[0] == '\\')) return .absolute;
    if (path.len >= 2 and std.ascii.isAlphabetic(path[0]) and path[1] == ':') return .absolute;
    var it = std.mem.tokenizeAny(u8, path, "/\\");
    while (it.next()) |seg| if (std.mem.eql(u8, seg, "..")) return .outside_package;
    return null;
}

/// The SHA-256 of `bytes`, 64 lowercase hex digits — `Asset.hash`.
pub fn hashHex(bytes: []const u8) [64]u8 {
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return std.fmt.bytesToHex(digest, .lower);
}

/// The untyped `Asset(path: …, bytes: …, size: …, hash: …)` constructor call
/// a read of `bytes` at `path` answers, every node at `loc`. `path_lexeme` is
/// the path as a string literal's lexeme (escapes written back).
pub fn asset(arena: std.mem.Allocator, loc: ast.Loc, path_lexeme: []const u8, bytes: []const u8) std.mem.Allocator.Error!*ast.Expr {
    const lit = struct {
        fn make(a: std.mem.Allocator, l: ast.Loc, kind: @FieldType(ast.LiteralExpr, "kind")) !*ast.Expr {
            const node = try a.create(ast.Expr);
            node.* = .{ .literal = .{ .loc = l, .kind = kind } };
            return node;
        }
    };
    const hash = hashHex(bytes);
    const args = try arena.alloc(ast.CallArg, 4);
    args[0] = .{ .label = "path", .value = try lit.make(arena, loc, .{ .stringLit = path_lexeme }) };
    args[1] = .{ .label = "bytes", .value = try lit.make(arena, loc, .{ .bytesLit = bytes }) };
    args[2] = .{ .label = "size", .value = try lit.make(arena, loc, .{ .numberLit = try std.fmt.allocPrint(arena, "{d}", .{bytes.len}) }) };
    args[3] = .{ .label = "hash", .value = try lit.make(arena, loc, .{ .stringLit = try arena.dupe(u8, &hash) }) };
    const call = try arena.create(ast.Expr);
    call.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = "Asset",
        .is_builtin = false,
        .args = args,
        .trailing = &.{},
    } } } };
    return call;
}

// ── a path through a `comptime` parameter ────────────────────────────────────
//
// `fn load(comptime p: @Expr<string>) -> Asset { return @embed(p.value); }`:
// the path is the caller's, so the file is the caller's package's (decision
// 519). The function is emitted with one more parameter per such `p`,
// `__embed_<p>: Asset` (`hiddenName`), last; its `@embed(p.value)` reads that
// parameter; and each call reads the file where it is written and passes the
// `Asset` as that argument (`Env.defaultInjections`).

/// The `comptime` parameter of `params` whose value `arg` is — `p.value`, or
/// `p` — or null.
pub fn paramOfArg(arg: ast.Expr, params: []const ast.Param) ?[]const u8 {
    const name = switch (arg) {
        .identifier => |id| switch (id.kind) {
            .ident => |n| n,
            .identAccess => |ia| if (std.mem.eql(u8, ia.member, "value") and ia.receiver.* == .identifier and ia.receiver.identifier.kind == .ident)
                ia.receiver.identifier.kind.ident
            else
                return null,
            else => return null,
        },
        else => return null,
    };
    for (params) |p| if (p.modifier == .@"comptime" and std.mem.eql(u8, p.name, name)) return name;
    return null;
}

/// The parameter a function reads `@embed(p.value)` through.
pub fn hiddenName(arena: std.mem.Allocator, param: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "__embed_{s}", .{param});
}

/// The `comptime` parameters of `f` an `@embed` in its body reads the path
/// of, in declaration order, each once — none for most functions.
pub fn embedParams(arena: std.mem.Allocator, f: ast.FnDecl) ![]const []const u8 {
    var w = ParamWalk{ .params = f.params };
    for (f.body) |*st| w.walk(ast.Stmt, st);
    if (w.found == 0) return &.{};
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (f.params, 0..) |p, i| if (i < 64 and w.found & (@as(u64, 1) << @intCast(i)) != 0) try out.append(arena, p.name);
    return out.items;
}

const ParamWalk = struct {
    params: []const ast.Param,
    /// One bit per parameter index.
    found: u64 = 0,

    fn walk(self: *ParamWalk, comptime U: type, ptr: *const U) void {
        if (U == ast.Expr) if (ptr.* == .call and ptr.call.kind == .call) {
            const c = ptr.call.kind.call;
            if (c.is_builtin and std.mem.eql(u8, c.callee, "embed") and c.args.len == 1) {
                if (paramOfArg(c.args[0].value.*, self.params)) |name| {
                    for (self.params, 0..) |p, i| if (i < 64 and std.mem.eql(u8, p.name, name)) {
                        self.found |= @as(u64, 1) << @intCast(i);
                    };
                }
            }
        };
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (fl.is_comptime) continue;
                if (comptime mayHold(fl.type)) self.walk(fl.type, &@field(ptr.*, fl.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime mayHold(@TypeOf(payload.*))) self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
            .pointer => |pt| switch (pt.size) {
                .one => if (comptime mayHold(pt.child)) self.walk(pt.child, ptr.*),
                .slice => if (comptime mayHold(pt.child)) {
                    for (ptr.*) |*e| self.walk(pt.child, e);
                },
                else => {},
            },
            else => {},
        }
    }

    fn mayHold(comptime U: type) bool {
        return @import("block_eval.zig").mayHoldNames(U);
    }
};

/// Every `@embed(p.value)` / `@embed(p)` of `body` whose `p` is one of
/// `names`, replaced in place by the read of its `__embed_<p>` parameter — the
/// specialised copies of a function too, which the transform clones from the
/// body as written (`comptime.zig` `withEmbedParams`).
pub fn readHiddenParams(arena: std.mem.Allocator, body: []const ast.Stmt, params: []const ast.Param, names: []const []const u8) !void {
    var w = HiddenRewrite{ .arena = arena, .params = params, .names = names };
    for (body) |*st| try w.walk(ast.Stmt, @constCast(st));
}

const HiddenRewrite = struct {
    arena: std.mem.Allocator,
    params: []const ast.Param,
    names: []const []const u8,

    fn walk(self: *HiddenRewrite, comptime U: type, ptr: *U) std.mem.Allocator.Error!void {
        if (U == ast.Expr) if (ptr.* == .call and ptr.call.kind == .call) {
            const c = ptr.call.kind.call;
            if (c.is_builtin and std.mem.eql(u8, c.callee, "embed") and c.args.len == 1) {
                // A specialised copy reads the parameter itself (`p`), the
                // function as written its value (`p.value`).
                const name = paramOfArg(c.args[0].value.*, self.params) orelse switch (c.args[0].value.*) {
                    .identifier => |id| if (id.kind == .ident) id.kind.ident else null,
                    else => null,
                };
                if (name) |n| for (self.names) |want| if (std.mem.eql(u8, want, n)) {
                    const loc = ptr.call.loc;
                    const hidden = try hiddenName(self.arena, n);
                    ptr.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = hidden } } };
                    return;
                };
            }
        };
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (fl.is_comptime) continue;
                if (comptime ParamWalk.mayHold(fl.type)) try self.walk(fl.type, &@field(ptr.*, fl.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime ParamWalk.mayHold(@TypeOf(payload.*))) try self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |pt| switch (pt.size) {
                .one => if (comptime ParamWalk.mayHold(pt.child)) try self.walk(pt.child, @constCast(ptr.*)),
                .slice => if (comptime ParamWalk.mayHold(pt.child)) {
                    for (ptr.*) |*e| try self.walk(pt.child, @constCast(e));
                },
                else => {},
            },
            else => {},
        }
    }
};

test "checkPath: absolute and leaving paths are refused, the package's own are not" {
    try std.testing.expectEqual(PathRefusal.absolute, checkPath("/etc/passwd").?);
    try std.testing.expectEqual(PathRefusal.absolute, checkPath("\\x").?);
    try std.testing.expectEqual(PathRefusal.absolute, checkPath("C:\\x").?);
    try std.testing.expectEqual(PathRefusal.outside_package, checkPath("../secret.txt").?);
    try std.testing.expectEqual(PathRefusal.outside_package, checkPath("assets/../../x").?);
    try std.testing.expect(checkPath("assets/hello.txt") == null);
    try std.testing.expect(checkPath("a..b/c.txt") == null);
    try std.testing.expect(checkPath("./assets/x") == null);
}

test "hashHex: the SHA-256 of the bytes" {
    try std.testing.expectEqualStrings("2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824", &hashHex("hello"));
}
