/// The `.bpp` roles (decision 361, front 116 step 1): the package the
/// manifest's `"bpp"` names, and in it the declarations std's `bpp`
/// annotations mark — `#[bpp.html]` (the markup's unfold target, exactly
/// one), `#[bpp.style]` (the style section's, at most one),
/// `#[bpp.htmlPrelude]` and `#[bpp.stylePrelude]` (each the marker `val` of a
/// prelude module, at most one). The toolchain knows nothing else about the
/// package (285 as 361 amends it): the roles are found by the annotations,
/// read through the package's own `import {bpp} from "std"` (or an alias, or
/// a leaf `import {bpp.html} from "std"`), never by a declaration's name.
///
/// Every refusal is located: a count at the project's `"bpp"` key, naming
/// the declarations; a role declaration that is not `pub`, and a declaration
/// beside a prelude marker, at that declaration in the package's file; a
/// `.bpp` file in a project with no key at the file; a style section in a
/// project whose package marks no `#[bpp.style]` at its `--- style ---` line.
///
/// `libs.loadDependencies` runs both checks — every command that compiles a
/// project (`build`, `run`, `check`, `test`) loads its dependencies through
/// it. The unfold itself (116 step 2) is not here yet.
const std = @import("std");
const bp = @import("botopink");
const manifest = @import("manifest");

const Module = bp.Module;
const ast = bp.ast;

pub const Error = error{BppRefused} || std.mem.Allocator.Error;

pub const Role = enum {
    html,
    style,
    htmlPrelude,
    stylePrelude,

    /// What the role is, for a refusal.
    fn what(self: Role) []const u8 {
        return switch (self) {
            .html => "the template function a .bpp file's markup unfolds onto",
            .style => "the template function a .bpp file's style section unfolds onto",
            .htmlPrelude => "the marker `val` of the markup's prelude module",
            .stylePrelude => "the marker `val` of the style section's prelude module",
        };
    }
};

/// One declaration a role annotation marks.
pub const Marked = struct {
    /// The module, as the build names it (`<package>/root`).
    module: []const u8,
    name: []const u8,
    /// The file it is read from, relative to the working directory.
    file: []const u8,
    source: []const u8,
    loc: ast.Loc,
};

/// What `findRoles` found in the package: every declaration each role marks.
pub const Roles = struct {
    html: []const Marked = &.{},
    style: []const Marked = &.{},
    htmlPrelude: []const Marked = &.{},
    stylePrelude: []const Marked = &.{},

    fn of(self: Roles, r: Role) []const Marked {
        return switch (r) {
            .html => self.html,
            .style => self.style,
            .htmlPrelude => self.htmlPrelude,
            .stylePrelude => self.stylePrelude,
        };
    }
};

/// One module of the package and the file it was read from.
pub const PackageModule = struct {
    module: Module,
    file: []const u8,
};

/// The roles of the package `pkg` (its modules `mods`), checked against the
/// project manifest `project`: `#[bpp.html]` exactly once, the other three at
/// most once, each marked declaration `pub`, and a prelude module holding its
/// imports and its marker only. Prints the first refusal and answers
/// `error.BppRefused`.
pub fn checkPackage(arena: std.mem.Allocator, project: manifest.Manifest, pkg: []const u8, mods: []const PackageModule) Error!Roles {
    var lists: [4]std.ArrayListUnmanaged(Marked) = .{ .empty, .empty, .empty, .empty };
    for (mods) |pm| {
        if (pm.module.declaration) continue;
        const program = parse(arena, pm.module.source) orelse continue; // the build reports it
        const handles = try roleNames(arena, program);
        if (handles.count() == 0) continue;
        var marker: ?Role = null;
        for (program.decls) |decl| {
            const anns = annotationsOf(decl);
            for (anns) |a| {
                if (a.is_builtin) continue;
                const role = handles.get(a.name) orelse continue;
                const name = declName(decl) orelse "";
                const loc = declLoc(decl, pm.module.source) orelse a.loc orelse ast.Loc{ .line = 1, .col = 1 };
                const marked: Marked = .{ .module = pm.module.path, .name = name, .file = pm.file, .source = pm.module.source, .loc = loc };
                if (!isPub(decl)) return refuseAt(marked, try std.fmt.allocPrint(arena, "`{s}` carries #[bpp.{s}] and is not `pub` — {s} is imported by every .bpp file of the application", .{ name, @tagName(role), role.what() }));
                try lists[@intFromEnum(role)].append(arena, marked);
                if (role == .htmlPrelude or role == .stylePrelude) marker = role;
            }
        }
        // Decision 361 (2) — a prelude module's imports are the prelude, and
        // the marker is the one other declaration it holds (270).
        if (marker) |role| for (program.decls) |decl| {
            switch (decl) {
                .use, .comment => continue,
                else => {},
            }
            const marks_it = for (annotationsOf(decl)) |a| {
                if (!a.is_builtin and handles.get(a.name) == role) break true;
            } else false;
            if (marks_it) continue;
            const loc = declLoc(decl, pm.module.source) orelse ast.Loc{ .line = 1, .col = 1 };
            const at: Marked = .{ .module = pm.module.path, .name = declName(decl) orelse "", .file = pm.file, .source = pm.module.source, .loc = loc };
            return refuseAt(at, try std.fmt.allocPrint(arena, "`{s}` is a prelude module (#[bpp.{s}]) and holds this declaration — a prelude module holds imports and its marker `val` only", .{ pm.module.path, @tagName(role) }));
        };
    }
    const roles: Roles = .{
        .html = lists[0].items,
        .style = lists[1].items,
        .htmlPrelude = lists[2].items,
        .stylePrelude = lists[3].items,
    };
    inline for (.{ Role.html, Role.style, Role.htmlPrelude, Role.stylePrelude }) |r| {
        const found = roles.of(r);
        if (r == .html and found.len == 0) {
            project.locateAt("bpp", try std.fmt.allocPrint(arena, "\"bpp\" names \"{s}\", and no declaration of it carries #[bpp.html] — {s}; the package marks exactly one", .{ pkg, r.what() })).print();
            return error.BppRefused;
        }
        if (found.len > 1) {
            var names: std.ArrayListUnmanaged(u8) = .empty;
            for (found, 0..) |m, i| {
                if (i > 0) try names.appendSlice(arena, ", ");
                try names.print(arena, "`{s}` ({s}:{d})", .{ m.name, m.file, m.loc.line });
            }
            project.locateAt("bpp", try std.fmt.allocPrint(arena, "\"bpp\" names \"{s}\", and #[bpp.{s}] marks {d} of its declarations — {s}; {s} is {s}", .{ pkg, @tagName(r), found.len, names.items, r.what(), if (r == .html) "exactly one" else "at most one" })).print();
            return error.BppRefused;
        }
    }
    return roles;
}

/// The `.bpp` files under the project's `src` (`src_dir`, relative to the
/// working directory), each with its text. Sorted by path.
pub const BppFile = struct { file: []const u8, source: []const u8 };

pub fn scanBppFiles(arena: std.mem.Allocator, io: std.Io, src_dir: []const u8) ![]const BppFile {
    var out: std.ArrayListUnmanaged(BppFile) = .empty;
    var dir = std.Io.Dir.cwd().openDir(io, src_dir, .{ .iterate = true, .access_sub_paths = true }) catch |err| switch (err) {
        error.FileNotFound, error.NotDir => return &.{},
        else => return err,
    };
    defer dir.close(io);
    var walker = try dir.walk(arena);
    defer walker.deinit();
    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.basename, ".bpp")) continue;
        const source = try entry.dir.readFileAlloc(io, entry.basename, arena, .unlimited);
        try out.append(arena, .{ .file = try std.fs.path.join(arena, &.{ src_dir, entry.path }), .source = source });
    }
    std.mem.sort(BppFile, out.items, {}, struct {
        fn lt(_: void, a: BppFile, b: BppFile) bool {
            return std.mem.lessThan(u8, a.file, b.file);
        }
    }.lt);
    return out.items;
}

/// A project with `.bpp` files and no `"bpp"` key: refused at the first file.
pub fn refuseUnnamed(arena: std.mem.Allocator, files: []const BppFile) Error {
    const f = files[0];
    printAt(f.file, f.source, 1, 1, try std.fmt.allocPrint(arena, "{s} is a .bpp file, and botopink.json has no \"bpp\" — name the package whose #[bpp.html] function its markup unfolds onto (\"bpp\": \"<package>\")", .{f.file}));
    return error.BppRefused;
}

/// The line of `source`'s style separator (`--- style ---`), when the header
/// ends at one: the header runs from the first line to the first separator
/// line (`---` or `--- style ---`, decision 338 (7)).
pub fn styleSectionLine(source: []const u8) ?usize {
    var it = std.mem.splitScalar(u8, source, '\n');
    var n: usize = 1;
    while (it.next()) |raw| : (n += 1) {
        const line = std.mem.trimEnd(u8, raw, " \t\r");
        if (std.mem.eql(u8, line, "---")) return null;
        if (std.mem.eql(u8, line, "--- style ---")) return n;
    }
    return null;
}

/// A style section in a project whose package marks no `#[bpp.style]`:
/// refused at the first such file's `--- style ---` line.
pub fn checkStyleSections(arena: std.mem.Allocator, pkg: []const u8, roles: Roles, files: []const BppFile) Error!void {
    if (roles.style.len > 0) return;
    for (files) |f| {
        const line = styleSectionLine(f.source) orelse continue;
        printAt(f.file, f.source, line, 1, try std.fmt.allocPrint(arena, "a style section needs a #[bpp.style] function, and \"{s}\" (the package \"bpp\" names) marks none", .{pkg}));
        return error.BppRefused;
    }
}

// ── Reading the package ───────────────────────────────────────────────────────

fn parse(arena: std.mem.Allocator, source: []const u8) ?ast.Program {
    var lx = bp.Lexer.init(source);
    const tokens = lx.scanAll(arena) catch return null;
    var p = bp.Parser.init(tokens);
    return p.parse(arena) catch null;
}

/// The annotation names that mean a role in `program`: `<h>.<role>` for each
/// handle `h` the module binds to std's `bpp` (`import {bpp} from "std"`,
/// `{bpp as b}`), and the local name of each leaf it imports
/// (`import {bpp.html} from "std"`, `{bpp: {html as h}}`).
fn roleNames(arena: std.mem.Allocator, program: ast.Program) !std.StringHashMapUnmanaged(Role) {
    var names: std.StringHashMapUnmanaged(Role) = .empty;
    for (program.decls) |decl| {
        if (decl != .use) continue;
        const u = decl.use;
        if (u.source != .module or !std.mem.eql(u8, u.source.module, "std")) continue;
        for (u.imports) |imp| {
            if (imp.segments.len == 0 or !std.mem.eql(u8, imp.segments[0], "bpp")) continue;
            if (imp.segments.len == 1) {
                inline for (.{ Role.html, Role.style, Role.htmlPrelude, Role.stylePrelude }) |r| {
                    try names.put(arena, try std.fmt.allocPrint(arena, "{s}.{s}", .{ imp.name(), @tagName(r) }), r);
                }
            } else if (imp.segments.len == 2) {
                inline for (.{ Role.html, Role.style, Role.htmlPrelude, Role.stylePrelude }) |r| {
                    if (std.mem.eql(u8, imp.segments[1], @tagName(r))) try names.put(arena, imp.name(), r);
                }
            }
        }
    }
    return names;
}

fn annotationsOf(decl: ast.DeclKind) []const ast.Annotation {
    return switch (decl) {
        .@"fn" => |f| f.annotations,
        .val => |v| v.annotations,
        .type_ => |t| t.annotations,
        .behavior => |b| b.annotations,
        else => &.{},
    };
}

fn declName(decl: ast.DeclKind) ?[]const u8 {
    return switch (decl) {
        .@"fn" => |f| f.name,
        .val => |v| v.name,
        .type_ => |t| t.name,
        .behavior => |b| b.name,
        .typeAlias => |t| t.name,
        .delegate => |d| d.name,
        .mod => |m| m.name,
        .@"test" => |t| t.name orelse "test",
        else => null,
    };
}

fn isPub(decl: ast.DeclKind) bool {
    return switch (decl) {
        .@"fn" => |f| f.isPub,
        .val => |v| v.isPub,
        .type_ => |t| t.isPub,
        .behavior => |b| b.isPub,
        else => false,
    };
}

/// Where a declaration is written; a node with no location of its own is
/// found by its name in the source.
fn declLoc(decl: ast.DeclKind, source: []const u8) ?ast.Loc {
    const loc: ast.Loc = switch (decl) {
        .@"fn" => |f| f.nameLoc,
        .val => |v| v.nameLoc,
        .type_ => |t| t.loc,
        .typeAlias => |t| t.loc,
        .implement => |i| i.loc,
        .extend => |e| e.loc,
        .mod => |m| m.loc,
        .@"test" => |t| t.loc,
        else => .{ .line = 0, .col = 0 },
    };
    if (loc.line > 0) return loc;
    const name = declName(decl) orelse return null;
    const at = std.mem.indexOf(u8, source, name) orelse return null;
    var line: usize = 1;
    var start: usize = 0;
    for (source[0..at], 0..) |c, i| if (c == '\n') {
        line += 1;
        start = i + 1;
    };
    return .{ .line = line, .col = at - start + 1 };
}

fn refuseAt(m: Marked, message: []const u8) Error {
    printAt(m.file, m.source, m.loc.line, m.loc.col, message);
    return error.BppRefused;
}

fn printAt(file: []const u8, source: []const u8, line: usize, col: usize, message: []const u8) void {
    const located: manifest.Located = .{ .message = message, .file = file, .source = source, .line = line, .col = col, .span = 1 };
    located.print();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

fn testModule(path: []const u8, source: []const u8) PackageModule {
    return .{ .module = .{ .path = path, .source = source }, .file = path };
}

const PROJECT =
    \\{ "name": "app", "dependencies": { "ui": { "path": "../ui" } }, "bpp": "ui" }
;

fn testProject(arena: std.mem.Allocator) !manifest.Manifest {
    var err: ?manifest.Located = null;
    return manifest.parse(arena, PROJECT, "botopink.json", &err);
}

test "bpp roles: one #[bpp.html], the others at most once, through a handle, an alias and a leaf" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const roles = try checkPackage(a, try testProject(a), "ui", &.{
        testModule("ui/root",
            \\import {bpp} from "std";
            \\#[bpp.html]
            \\pub fn html(comptime t: @Expr<string>) -> @ExprCustom<i32> { return t.custom(t.node(), t.build("1")); }
        ),
        testModule("ui/style",
            \\import {bpp.style as role} from "std";
            \\#[role]
            \\pub fn css(comptime t: @Expr<string>) -> @ExprCustom<i32> { return t.custom(t.node(), t.build("1")); }
        ),
        testModule("ui/prelude",
            \\import {bpp as b} from "std";
            \\import {root.html};
            \\#[b.htmlPrelude]
            \\pub val prelude = b.Prelude();
        ),
    });
    try std.testing.expectEqual(@as(usize, 1), roles.html.len);
    try std.testing.expectEqualStrings("html", roles.html[0].name);
    try std.testing.expectEqualStrings("css", roles.style[0].name);
    try std.testing.expectEqualStrings("ui/prelude", roles.htmlPrelude[0].module);
    try std.testing.expectEqual(@as(usize, 0), roles.stylePrelude.len);
}

test "bpp roles: a missing #[bpp.html], a second one, a private role and a prelude holding a function are refused" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const p = try testProject(a);
    // An annotation spelled like a role but not read through std's `bpp` marks nothing.
    try std.testing.expectError(error.BppRefused, checkPackage(a, p, "ui", &.{testModule("ui/root",
        \\import {html} from "web";
        \\#[html]
        \\pub fn page() -> i32 { return 1; }
    )}));
    try std.testing.expectError(error.BppRefused, checkPackage(a, p, "ui", &.{
        testModule("ui/a", "import {bpp} from \"std\";\n#[bpp.html]\npub fn one() -> i32 { return 1; }"),
        testModule("ui/b", "import {bpp} from \"std\";\n#[bpp.html]\npub fn two() -> i32 { return 2; }"),
    }));
    try std.testing.expectError(error.BppRefused, checkPackage(a, p, "ui", &.{testModule("ui/a", "import {bpp} from \"std\";\n#[bpp.html]\nfn one() -> i32 { return 1; }")}));
    try std.testing.expectError(error.BppRefused, checkPackage(a, p, "ui", &.{
        testModule("ui/a", "import {bpp} from \"std\";\n#[bpp.html]\npub fn one() -> i32 { return 1; }"),
        testModule("ui/prelude", "import {bpp} from \"std\";\n#[bpp.htmlPrelude]\npub val prelude = bpp.Prelude();\npub fn extra() -> i32 { return 1; }"),
    }));
}

test "bpp files: the style separator ends the header; a markup separator first means no style section" {
    try std.testing.expectEqual(@as(?usize, 2), styleSectionLine("type Props(t: string)\n--- style ---\n.a {}\n---\n<h1/>"));
    try std.testing.expectEqual(@as(?usize, null), styleSectionLine("val x = 1;\n---\n<p>--- style ---</p>\n--- style ---"));
    try std.testing.expectEqual(@as(?usize, null), styleSectionLine("<article></article>"));
    try std.testing.expectEqual(@as(?usize, 1), styleSectionLine("--- style --- \r\n.a {}\n---\n<p/>"));
}
