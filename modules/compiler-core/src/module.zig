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
