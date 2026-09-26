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
};
