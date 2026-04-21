/// A source module for multi-module codegen.
/// `path` is the module identifier used in `use {X} from "path"` declarations.
/// `source` is the botopink source text.
pub const Module = struct {
    path: []const u8,
    source: []const u8,
};
