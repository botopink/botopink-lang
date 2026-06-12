//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// ── Public API re-exports (consumed by compiler-cli and other consumers) ──────

pub const codegen = @import("./codegen.zig");
pub const format = @import("./format.zig");
pub const print_errors = @import("./print.zig");
pub const Module = @import("./module.zig").Module;
pub const comptime_pipeline = @import("./comptime.zig");
// `@ExprCustom` tooling read API (expr-custom): the canonical reference node and
// the per-call-site entries a language server consumes. Generic — names no
// sub-language. See `comptime_pipeline.OkData.custom_ast`.
pub const CustomNode = comptime_pipeline.CustomNode;
pub const CustomAstEntry = comptime_pipeline.CustomAstEntry;
pub const Lexer = @import("./lexer.zig").Lexer;
pub const Token = @import("./lexer.zig").Token;
pub const TokenKind = @import("./lexer.zig").TokenKind;
pub const Parser = @import("./parser.zig").Parser;
pub const ast = @import("./ast.zig");
