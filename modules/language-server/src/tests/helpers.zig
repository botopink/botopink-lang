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

/// Compila `source` (módulo único) e devolve um handle que o chamador deve `.deinit(gpa)`.
/// Sem eval context — corpos de template não são expandidos (types-only puro).
pub fn compile(gpa: std.mem.Allocator, source: []const u8) !CompileHandle {
    var lsp_compiler = compiler_mod.LspCompiler.init(gpa, std.testing.io, null);
    const entries = [_]compiler_mod.ModuleEntry{.{ .uri = TEST_URI, .source = source }};
    const result = try lsp_compiler.compile(&entries);
    return .{ .result = result };
}

/// Counter for unique per-test template-eval scratch dirs — tests run in
/// parallel, so a shared `node` build root would race on deleteTree/writeFile.
var eval_counter: std.atomic.Value(usize) = .init(0);

/// Compila `source` expandindo corpos de template via `node` (necessário para
/// que sub-linguagens `@ExprCustom` produzam suas árvores `CustomNode`). Usa um
/// build root único por chamada para evitar corrida entre testes paralelos.
/// O `root` só é usado durante a compilação, então é liberado ao retornar.
pub fn compileEval(gpa: std.mem.Allocator, source: []const u8) !CompileHandle {
    const n = eval_counter.fetchAdd(1, .monotonic);
    const root = try std.fmt.allocPrint(gpa, ".botopinkbuild/lsp-test/{d}", .{n});
    defer gpa.free(root);
    var lsp_compiler = compiler_mod.LspCompiler.init(gpa, std.testing.io, root);
    const entries = [_]compiler_mod.ModuleEntry{.{ .uri = TEST_URI, .source = source }};
    const result = try lsp_compiler.compile(&entries);
    return .{ .result = result };
}

/// Compila múltiplos módulos juntos e devolve um handle que o chamador deve `.deinit(gpa)`.
///
/// Os módulos são compilados em ordem: os primeiros servem como dependências
/// para os posteriores, exatamente como `TestProject.add_module("dep", dep)` no Gleam.
/// O URI do módulo principal (último da lista) é `TEST_URI`; os demais recebem
/// `"file:///dep_{i}.bp"`.
///
/// Exemplo:
/// ```zig
/// const dep_src = "pub fn greet() -> string { return \"hi\"; }";
/// const main_src = "import { greet } from \"file:///dep_0.bp\"; val x = greet();";
/// var c = try h.compileMulti(gpa, &.{
///     .{ .uri = "file:///dep_0.bp", .source = dep_src },
///     .{ .uri = TEST_URI,           .source = main_src },
/// });
/// defer c.deinit(gpa);
/// ```
pub fn compileMulti(
    gpa: std.mem.Allocator,
    entries: []const compiler_mod.ModuleEntry,
) !CompileHandle {
    var lsp_compiler = compiler_mod.LspCompiler.init(gpa, std.testing.io, null);
    const result = try lsp_compiler.compile(entries);
    return .{ .result = result };
}

/// Como `compileMulti`, mas expande corpos de template via `node` — necessário
/// para que uma sub-linguagem `@ExprCustom` definida num módulo de dependência
/// (`from "<lib>"`) seja expandida ao ser usada no módulo principal (F4: a
/// expansão cross-module só acontece quando o grafo resolve o template fn).
pub fn compileMultiEval(
    gpa: std.mem.Allocator,
    entries: []const compiler_mod.ModuleEntry,
) !CompileHandle {
    const n = eval_counter.fetchAdd(1, .monotonic);
    const root = try std.fmt.allocPrint(gpa, ".botopinkbuild/lsp-test-multi/{d}", .{n});
    defer gpa.free(root);
    var lsp_compiler = compiler_mod.LspCompiler.init(gpa, std.testing.io, root);
    const result = try lsp_compiler.compile(entries);
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

    /// Entradas de Custom AST (`@ExprCustom`) do módulo principal.
    pub fn customAst(self: *const CompileHandle) []const compiler_mod.CustomAstEntry {
        return self.result.customAstFor(TEST_URI);
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
