const std = @import("std");

/// A source module for multi-module codegen.
/// `path` is the module identifier used in `import {X} from "path"` declarations.
/// `source` is the botopink source text.
/// `.d.bp` modules are declaration-only (no codegen output).
pub const Module = struct {
    path: []const u8,
    source: []const u8,
    declaration: bool = false,
    /// Display path of the source file relative to the root of the package it
    /// belongs to, forward slashes, extension included (`src/shapes/circle.bp`,
    /// `test/onze_test.bp`). It is what `@src().file` answers (1.0.10-beta
    /// decision 73). `""` means "not known" — the comptime front end then uses
    /// `<name>.bp`, the same spelling the test runners print (`main.bp:12`);
    /// the CLI's scanner/resolver/libs loaders fill it in for package modules.
    srcPath: []const u8 = "",
    /// The dependency package the module was loaded from — the first segment
    /// of `path` (`a` for `a/theme`) — or empty for a module of the root
    /// package. A module is its package plus its path (decisions 170, 337):
    /// the checker marks each import with it (`ImportDecl.ownPackage`), so
    /// `import {theme.make};` in `a/user` names `a/theme` and never another
    /// package's `theme`. The CLI's dependency loader fills it in.
    package: []const u8 = "",
    /// The `targets` the module's package declares in its `botopink.json`,
    /// null when it declares none (decision 341: a decorator's host
    /// function needs the cell of every comptime runtime those targets use —
    /// none declared is every target). The CLI's loaders fill it in
    /// (`Targets.of`).
    targets: ?Targets = null,
    /// One of std's own modules (decision 445: a `#[@External.Wasm(std: "…")]`
    /// cell is std's alone) — never read from `path`, which a package's own
    /// `src/std/` folder spells too. The compiler sets it on the embedded std
    /// modules it prepends (the prelude is std's by `registerStdlib`); the CLI
    /// on the modules of a root package named `std` — `libs/std` built,
    /// checked or tested as itself.
    std_member: bool = false,
    /// The package's root module: the file the CLI's resolver starts the
    /// `mod` tree from (`src/main.bp`, `src/root.bp` — the manifest's
    /// `entry`). A call that leaves out a `comptime` parameter whose default
    /// is a `@TypeInfo.all(…)` query is legal only in the root package's root
    /// (decision 551, `comptime.zig` `fillCatalogueDefaults`).
    root: bool = false,
    /// Decision 519 — the reader `@embed` reads the package's files through:
    /// the directory of the package's `botopink.json` and the function that
    /// reads a file under it. The CLI and the language server hand
    /// `PackageFiles.disk(io, <package dir>)`; a compiler with no file system
    /// (`compiler-web`) hands none, and every `@embed` is a located refusal
    /// (`embed-no-reader`).
    files: ?PackageFiles = null,
};

/// Decision 519 — the files of one package, as `@embed` reads them: `root` is
/// the directory of the package's `botopink.json`, and `read` answers the
/// bytes of `rel` (a relative path the checker already proved stays inside the
/// package: no absolute path, no `..`) under it, allocated with `arena`.
pub const PackageFiles = struct {
    root: []const u8,
    io: std.Io,
    read: *const fn (io: std.Io, arena: std.mem.Allocator, root: []const u8, rel: []const u8) ReadError![]const u8,

    pub const ReadError = error{ FileNotFound, Unreadable, OutOfMemory };

    /// The package at `root` on disk — the CLI's and the language server's.
    pub fn disk(io: std.Io, root: []const u8) PackageFiles {
        return .{ .root = root, .io = io, .read = readDisk };
    }

    /// The bytes of `rel` under the package's root.
    pub fn readFile(self: PackageFiles, arena: std.mem.Allocator, rel: []const u8) ReadError![]const u8 {
        return self.read(self.io, arena, self.root, rel);
    }

    fn readDisk(io: std.Io, arena: std.mem.Allocator, root: []const u8, rel: []const u8) ReadError![]const u8 {
        const path = std.fs.path.join(arena, &.{ root, rel }) catch return error.OutOfMemory;
        return std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited) catch |err| switch (err) {
            error.FileNotFound, error.IsDir, error.NotDir => error.FileNotFound,
            error.OutOfMemory => error.OutOfMemory,
            else => error.Unreadable,
        };
    }
};

/// A package's declared `targets`, by name — no allocation, so a `Module`
/// owns nothing more than it did.
pub const Targets = packed struct {
    commonJS: bool = false,
    typescript: bool = false,
    erlang: bool = false,
    beam: bool = false,
    wasm: bool = false,

    /// The set `names` spells (the manifest has validated each name); null
    /// for a manifest that declares no `targets`.
    pub fn of(names: ?[]const []const u8) ?Targets {
        const list = names orelse return null;
        var t: Targets = .{};
        for (list) |n| {
            if (eql(n, "commonJS")) t.commonJS = true;
            if (eql(n, "typescript")) t.typescript = true;
            if (eql(n, "erlang")) t.erlang = true;
            if (eql(n, "beam")) t.beam = true;
            if (eql(n, "wasm")) t.wasm = true;
        }
        return t;
    }

    fn eql(a: []const u8, b: []const u8) bool {
        return @import("std").mem.eql(u8, a, b);
    }
};
