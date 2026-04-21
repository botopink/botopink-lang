/// Shared helpers for LSP engine tests.
///
/// Pattern:
///   1. `compile(gpa, source)` → CompileHandle (owns session, call .deinit)
///   2. `tokenize(arena, source)` → []Token (freed with arena)
///   3. `pos(line, char)` / `range(...)` → proto types
const std = @import("std");
const bp = @import("botopink");
const proto = @import("../protocol.zig");
const lsp_types = @import("../lsp_types.zig");
const compiler_mod = @import("../compiler.zig");

pub const comptime_pipeline = bp.comptime_pipeline;
pub const Lexer = bp.Lexer;

/// URI usado em todos os testes.
pub const TEST_URI = "file:///test.bp";

/// Cria um LSP Position (0-based).
pub fn pos(line: u32, character: u32) proto.Position {
    return .{ .line = line, .character = character };
}

/// Cria um LSP Range (0-based).
pub fn range(sl: u32, sc: u32, el: u32, ec: u32) proto.Range {
    return .{ .start = pos(sl, sc), .end = pos(el, ec) };
}

/// Compila `source` e devolve um handle que o chamador deve `.deinit(gpa)`.
pub fn compile(gpa: std.mem.Allocator, source: []const u8) !CompileHandle {
    var lsp_compiler = compiler_mod.LspCompiler.init(gpa);
    const entries = [_]compiler_mod.ModuleEntry{.{ .uri = TEST_URI, .source = source }};
    const result = try lsp_compiler.compile(&entries);
    return .{ .result = result };
}

pub const CompileHandle = struct {
    result: compiler_mod.CompileResult,

    pub fn deinit(self: *CompileHandle, gpa: std.mem.Allocator) void {
        self.result.deinit(gpa);
    }

    /// Retorna bindings do primeiro output bem-sucedido, ou null se falhou.
    pub fn bindings(self: *const CompileHandle) ?[]const comptime_pipeline.TypedBinding {
        for (self.result.session.outputs.items) |output| {
            if (output.outcome == .ok) return output.outcome.ok.bindings;
        }
        return null;
    }

    /// true se o módulo compilou sem erros.
    pub fn isOk(self: *const CompileHandle) bool {
        for (self.result.session.outputs.items) |output| {
            if (output.outcome == .ok) return true;
        }
        return false;
    }
};

/// Tokeniza `source` usando o arena fornecido.
pub fn tokenize(arena: std.mem.Allocator, source: []const u8) ![]const bp.Token {
    var lexer = Lexer.init(source);
    return lexer.scanAll(arena);
}
