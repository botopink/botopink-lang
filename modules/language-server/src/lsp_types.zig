/// Conversões entre posições do compiler-core e LSP.
///
/// O compiler-core usa:
///   - Loc { line: usize, col: usize }  (1-based, em nós do AST)
///   - byte offset usize                (em ParseErrorInfo e lexer)
///
/// O LSP usa:
///   - Position { line: u32, character: u32 }  (0-based)
const std = @import("std");
const proto = @import("./protocol.zig");

// ── Byte offset → LSP Position ────────────────────────────────────────────────

/// Converte um byte offset (0-based) no source para LSP Position (0-based line/char).
pub fn offsetToPosition(source: []const u8, offset: usize) proto.Position {
    const safe = @min(offset, source.len);
    var line: u32 = 0;
    var line_start: usize = 0;
    var i: usize = 0;
    while (i < safe) : (i += 1) {
        if (source[i] == '\n') {
            line += 1;
            line_start = i + 1;
        }
    }
    const character: u32 = @intCast(safe - line_start);
    return .{ .line = line, .character = character };
}

/// Converte LSP Position de volta para byte offset.
pub fn positionToOffset(source: []const u8, pos: proto.Position) usize {
    var line: u32 = 0;
    var i: usize = 0;
    while (i < source.len) : (i += 1) {
        if (line == pos.line) break;
        if (source[i] == '\n') line += 1;
    }
    return @min(i + pos.character, source.len);
}

/// Converte um span (start_offset, end_offset) para LSP Range.
pub fn spanToRange(source: []const u8, start: usize, end: usize) proto.Range {
    return .{
        .start = offsetToPosition(source, start),
        .end = offsetToPosition(source, end),
    };
}

// ── Loc (line/col, 1-based) → LSP Position ────────────────────────────────────

/// Converte o Loc do AST (1-based) para LSP Position (0-based).
pub fn locToPosition(line_1based: usize, col_1based: usize) proto.Position {
    return .{
        .line = @intCast(line_1based -| 1),
        .character = @intCast(col_1based -| 1),
    };
}

// ── Range cobrindo o documento inteiro ────────────────────────────────────────

/// Range que abrange todo o conteúdo do source.
pub fn fullRange(source: []const u8) proto.Range {
    return .{
        .start = .{ .line = 0, .character = 0 },
        .end = offsetToPosition(source, source.len),
    };
}

// ── URI → caminho de arquivo ───────────────────────────────────────────────────

/// Remove o prefixo "file://" de um URI retornando o caminho no sistema de arquivos.
/// O slice retornado aponta para dentro de `uri` (sem alocação).
pub fn uriToPath(uri: []const u8) []const u8 {
    if (std.mem.startsWith(u8, uri, "file://")) return uri["file://".len..];
    return uri;
}

/// Constrói um URI "file://<path>" alocado com `gpa`.
pub fn pathToUri(gpa: std.mem.Allocator, path: []const u8) ![]u8 {
    return std.fmt.allocPrint(gpa, "file://{s}", .{path});
}
