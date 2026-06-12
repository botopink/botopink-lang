/// A source module for multi-module codegen.
/// `path` is the module identifier used in `import {X} from "path"` declarations.
/// `source` is the botopink source text.
/// `.d.bp` modules are declaration-only (no codegen output).
pub const Module = struct {
    path: []const u8,
    source: []const u8,
    declaration: bool = false,
};
