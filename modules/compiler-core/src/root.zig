//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// ── Public API re-exports (consumed by compiler-cli and other consumers) ──────

pub const codegen = @import("./codegen.zig");
pub const format = @import("./format.zig");
pub const print_errors = @import("./print.zig");
pub const Module = @import("./module.zig").Module;
pub const comptime_pipeline = @import("./comptime.zig");
pub const Lexer = @import("./lexer.zig").Lexer;
pub const Token = @import("./lexer.zig").Token;
pub const TokenKind = @import("./lexer.zig").TokenKind;
pub const Parser = @import("./parser.zig").Parser;
pub const ast = @import("./ast.zig");

