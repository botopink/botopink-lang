//! Decision 798 (2) — the origin comments of the resolved program: each piece
//! the build produced carries, as a `//` comment over it, where it came from,
//! `// from <what> (<file>:<line>)`. The comments are ordinary comment nodes of
//! `OkData.resolved` (a top-level comment, a statement comment, a member's
//! comment lines), so the printer writes them as it writes any comment; the
//! compiler never reads them back (798 (2)).
//!
//! What records an origin, without a field on any node:
//!
//! - a decorator's output (an added member, an associated type, a
//!   `compiler.init` executor) is placed past the module's last line
//!   (`comptime.zig` `parseAndMergeContributions`, `mergeMembers`), and
//!   `Env.memberContributions` / `typeContributions` / `executorAnchors` say
//!   which output owns which lines (`outputAt`, shared with the refusals'
//!   location, decision 567): `from #[<decorator>]` at the output's call in
//!   the decorator's file; a top-level `comptime` block's executor (its
//!   `__bp_comptime_<k>` marker) `from comptime { … }`;
//! - a template's expansion and a function expanded at its call (562):
//!   `Env.expansionOrigins`, by the call's loc, `from <template>` at its
//!   declaration;
//! - a folded `comptime` value: the `comptime` node whose loc the splices
//!   hold, `from comptime` at the node.
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const mayHoldExpr = @import("std_namespace.zig").mayHoldExpr;

const Env = envMod.Env;

/// A decorator output past the module's last line: the annotation that ran
/// it, the output call in the decorator's file, the decorator's name.
pub const OutputAt = struct {
    loc: ?ast.Loc,
    call: ?envMod.CallSite,
    decorator: []const u8,
};

/// The decorator output whose source holds line `at` of the merged module
/// (`source` the module's own text), or null for a line of the module's own.
pub fn outputAt(env: *const Env, source: []const u8, at: usize) ?OutputAt {
    const r = env.outputRecords();
    var line: usize = std.mem.count(u8, source, "\n") + 1;
    for (r.contributions, 0..) |c, ci| {
        const last = line + std.mem.count(u8, c, "\n") + 1;
        // Decision 580 — an executor is code a decorator added, located as
        // a member is.
        if (at > line and at <= last) for (r.anchors) |an| {
            if (an.contribution == ci) return .{ .loc = an.loc, .call = an.call, .decorator = an.decorator };
        };
        line = last;
    }
    for (r.members) |m| {
        const last = line + std.mem.count(u8, m.source, "\n") + 1;
        if (at > line and at <= last) return .{ .loc = m.loc, .call = m.call, .decorator = m.decorator };
        line = last;
    }
    for (r.types) |t| {
        const last = line + std.mem.count(u8, t.source, "\n") + 1;
        if (at > line and at <= last) return .{ .loc = t.loc, .call = t.call, .decorator = t.decorator };
        line = last;
    }
    return null;
}

/// `program` (the resolved tree, after the transform) with a comment over
/// each declaration and member a decorator wrote. `self_file` is the module's
/// file, named when an output has no call site.
pub fn annotateOutputs(arena: std.mem.Allocator, program: ast.Program, env: *const Env, source: []const u8, self_file: []const u8) !ast.Program {
    const own_lines = std.mem.count(u8, source, "\n") + 1;
    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var blank: std.ArrayListUnmanaged(bool) = .empty;
    var previous: ?[]const u8 = null;
    for (program.decls, 0..) |d_in, i| {
        var d = d_in;
        const was_blank = if (i < program.blankLineBefore.len) program.blankLineBefore[i] else false;
        switch (d) {
            .type_ => |*t| t.methods = try annotateMembers(arena, t.methods, env, source, own_lines, self_file),
            .behavior => |*b| b.methods = try annotateMembers(arena, b.methods, env, source, own_lines, self_file),
            else => {},
        }
        // A specialised copy (`name_$N`) keeps its template's lines, which
        // may be another module's: never a decorator's output.
        const line = if (declName(d)) |n| (if (std.mem.indexOfScalar(u8, n, '$') != null) 0 else declLine(d)) else declLine(d);
        const origin: ?[]const u8 = if (line > own_lines) if (outputAt(env, source, line)) |o| try outputText(arena, env, o, self_file) else null else null;
        // An executor's function and the `val` that runs it are one piece.
        if (origin) |text| if (previous == null or !std.mem.eql(u8, previous.?, text)) {
            try decls.append(arena, comment(text));
            try blank.append(arena, was_blank);
            try decls.append(arena, d);
            try blank.append(arena, false);
            previous = text;
            continue;
        };
        previous = origin;
        try decls.append(arena, d);
        try blank.append(arena, was_blank);
    }
    return .{ .decls = decls.items, .blankLineBefore = blank.items };
}

fn annotateMembers(arena: std.mem.Allocator, methods: []ast.BehaviorMethod, env: *const Env, source: []const u8, own_lines: usize, self_file: []const u8) ![]ast.BehaviorMethod {
    var out: ?[]ast.BehaviorMethod = null;
    for (methods, 0..) |m, i| {
        if (m.nameLoc.line <= own_lines) continue;
        const o = outputAt(env, source, m.nameLoc.line) orelse continue;
        const text = try outputText(arena, env, o, self_file);
        if (out == null) out = try arena.dupe(ast.BehaviorMethod, methods);
        const lines = try arena.alloc([]const u8, m.comments.len + 1);
        @memcpy(lines[0..m.comments.len], m.comments);
        lines[m.comments.len] = try std.fmt.allocPrint(arena, "// {s}", .{text});
        out.?[i].comments = lines;
    }
    return out orelse methods;
}

fn outputText(arena: std.mem.Allocator, env: *const Env, o: OutputAt, self_file: []const u8) ![]const u8 {
    const block = std.mem.startsWith(u8, o.decorator, "__bp_comptime_");
    const file, const line = if (o.call) |c| .{ labelOf(env, c.module, c.file), c.loc.line } else .{ self_file, if (o.loc) |l| l.line else 0 };
    if (block) return std.fmt.allocPrint(arena, "from comptime {{ … }} ({s}:{d})", .{ file, line });
    return std.fmt.allocPrint(arena, "from #[{s}] ({s}:{d})", .{ o.decorator, file, line });
}

/// The file a diagnostic names for `module` (decision 545): a program
/// module's package-relative file (`src/main.bp`), a dependency's module path
/// (`lib/tools.bp`); `file` when the session records none.
pub fn labelOf(env: *const Env, module: []const u8, file: []const u8) []const u8 {
    const r = env.reflection orelse return file;
    return r.diagLabels.get(module) orelse file;
}

fn declName(d: ast.DeclKind) ?[]const u8 {
    return switch (d) {
        .@"fn" => |f| f.name,
        .val => |v| v.name,
        else => null,
    };
}

/// The line a declaration's name is written on (0 when it has none).
fn declLine(d: ast.DeclKind) usize {
    return switch (d) {
        .@"fn" => |f| f.nameLoc.line,
        .val => |v| v.nameLoc.line,
        .type_ => |t| t.loc.line,
        .behavior => |b| b.nameLoc.line,
        else => 0,
    };
}

fn comment(text: []const u8) ast.DeclKind {
    return .{ .comment = .{ .text = text, .is_module = false, .is_doc = false } };
}

/// `program` (the module as written, before the transform) with a comment
/// over each statement or declaration holding an expansion or a folded
/// `comptime` value: in the innermost statement list that holds it, else over
/// the top-level declaration. `splices` is the folded values' channel the
/// transform reads.
pub fn annotateWritten(
    arena: std.mem.Allocator,
    program: ast.Program,
    env: *const Env,
    splices: *const std.AutoHashMap(ast.Loc, *const ast.Expr),
    self_file: []const u8,
) !ast.Program {
    var w: Walker = .{ .arena = arena, .env = env, .splices = splices, .self_file = self_file };
    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var blank: std.ArrayListUnmanaged(bool) = .empty;
    for (program.decls, 0..) |d_in, i| {
        var d = d_in;
        const was_blank = if (i < program.blankLineBefore.len) program.blankLineBefore[i] else false;
        w.found = .empty;
        try w.walk(ast.DeclKind, &d);
        if (w.found.items.len > 0) {
            for (w.found.items, 0..) |text, k| {
                try decls.append(arena, comment(text));
                try blank.append(arena, if (k == 0) was_blank else false);
            }
            try decls.append(arena, d);
            try blank.append(arena, false);
            continue;
        }
        try decls.append(arena, d);
        try blank.append(arena, was_blank);
    }
    return .{ .decls = decls.items, .blankLineBefore = blank.items };
}

const Walker = struct {
    arena: std.mem.Allocator,
    env: *const Env,
    splices: *const std.AutoHashMap(ast.Loc, *const ast.Expr),
    self_file: []const u8,
    /// The origins met since the enclosing statement list (or declaration)
    /// began, in source order, each once.
    found: std.ArrayListUnmanaged([]const u8) = .empty,

    fn note(self: *Walker, text: []const u8) !void {
        for (self.found.items) |t| if (std.mem.eql(u8, t, text)) return;
        try self.found.append(self.arena, text);
    }

    /// The origin of the expression `e`, when the build replaced it.
    fn originOf(self: *Walker, e: *const ast.Expr) !?[]const u8 {
        const loc = e.getLoc();
        if (self.env.templateExpansions.contains(loc)) {
            const o = self.env.expansionOrigins.get(loc) orelse return null;
            return try std.fmt.allocPrint(self.arena, "from {s} ({s}:{d})", .{ o.what, labelOf(self.env, o.module, o.file), o.line });
        }
        if (e.* == .comptime_ and self.splices.contains(loc)) {
            const what = switch (e.comptime_.kind) {
                .comptimeBlock => "comptime { … }",
                else => "comptime",
            };
            return try std.fmt.allocPrint(self.arena, "from {s} ({s}:{d})", .{ what, self.self_file, loc.line });
        }
        return null;
    }

    fn stmts(self: *Walker, list: []const ast.Stmt) ![]ast.Stmt {
        const outer = self.found;
        defer self.found = outer;
        var out: std.ArrayListUnmanaged(ast.Stmt) = .empty;
        for (list) |s_in| {
            var s = s_in;
            self.found = .empty;
            try self.walk(ast.Expr, &s.expr);
            for (self.found.items, 0..) |text, k| {
                try out.append(self.arena, .{
                    .expr = .{ .literal = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .comment = .{ .kind = .{ .normal = "" }, .text = text } } } },
                    .emptyLinesBefore = if (k == 0) s.emptyLinesBefore else 0,
                });
            }
            if (self.found.items.len > 0) s.emptyLinesBefore = 0;
            try out.append(self.arena, s);
        }
        return out.items;
    }

    fn walk(self: *Walker, comptime T: type, ptr: *T) std.mem.Allocator.Error!void {
        if (T == ast.ImportDecl or T == ast.TypeRef) return;
        if (T == ast.Expr) if (try self.originOf(ptr)) |text| return self.note(text);
        switch (@typeInfo(T)) {
            .@"struct" => |st| inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldExpr(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| {
                    if (comptime mayHoldExpr(@TypeOf(payload.*))) try self.walk(@TypeOf(payload.*), payload);
                },
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| if (comptime mayHoldExpr(p.child)) switch (p.size) {
                // The tree is the printer's own copy: a node behind a const
                // pointer is rewritten in place.
                .one => try self.walk(p.child, @constCast(ptr.*)),
                .slice => if (p.child == ast.Stmt) {
                    ptr.* = try self.stmts(ptr.*);
                } else for (@constCast(ptr.*)) |*e| try self.walk(p.child, e),
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*e| try self.walk(arr.child, e);
            },
            else => {},
        }
    }
};
