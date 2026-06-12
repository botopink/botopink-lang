/// Wrapper de compilação incremental para o LSP.
///
/// Usa `comptime_pipeline.compile()` com runtime `.none` para obter
/// diagnósticos de tipo sem executar código externo.
const std = @import("std");
const bp = @import("botopink");
const proto = @import("./protocol.zig");
const lsp_types = @import("./lsp_types.zig");

const Module = bp.Module;
const comptime_pipeline = bp.comptime_pipeline;

/// Re-export so the LSP can build the template-eval context without reaching
/// into compiler-core internals.
pub const TemplateEvalCtx = comptime_pipeline.TemplateEvalCtx;

pub const LspCompiler = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    /// Scratch root for the node-backed template evaluator. When non-null,
    /// `@ExprCustom` (and any runtime-evaluated) template bodies are expanded so
    /// their `CustomNode` trees reach `OkData.custom_ast` (sublanguage-lsp). Null
    /// keeps the pure types-only path — no `node`, no filesystem writes.
    eval_root: ?[]const u8,

    pub fn init(gpa: std.mem.Allocator, io: std.Io, eval_root: ?[]const u8) LspCompiler {
        return .{ .gpa = gpa, .io = io, .eval_root = eval_root };
    }

    /// Compila uma lista de módulos (source já em memória) usando apenas
    /// inferência de tipos. Quando `eval_root` foi fornecido, os corpos de
    /// template (incl. `@ExprCustom`) são expandidos via `node` para que suas
    /// árvores `CustomNode` cheguem em `custom_ast`.
    /// O chamador deve chamar `result.deinit(gpa)` quando terminar.
    pub fn compile(
        self: *LspCompiler,
        modules: []const ModuleEntry,
    ) !CompileResult {
        var mods = try self.gpa.alloc(Module, modules.len);
        defer self.gpa.free(mods);

        for (modules, 0..) |entry, i| {
            mods[i] = .{
                .path = lsp_types.uriToPath(entry.uri),
                .source = entry.source,
            };
        }

        const eval_ctx: ?TemplateEvalCtx = if (self.eval_root) |root|
            .{ .io = self.io, .build_root = root }
        else
            null;
        const session = try comptime_pipeline.compileTypesOnly(self.gpa, mods, eval_ctx);
        return .{ .session = session, .modules = modules };
    }
};

/// Par (uri, source) passado para compilação.
pub const ModuleEntry = struct {
    uri: []const u8,
    source: []const u8,
};

/// Re-export: one `@ExprCustom` reference-AST entry (`{ loc, callee, root, file,
/// line, col }`) surfaced by a sub-language template (sublanguage-lsp).
pub const CustomAstEntry = comptime_pipeline.CustomAstEntry;

/// Resultado de uma sessão de compilação.
pub const CompileResult = struct {
    session: comptime_pipeline.ComptimeSession,
    modules: []const ModuleEntry,

    pub fn deinit(self: *CompileResult, gpa: std.mem.Allocator) void {
        self.session.deinit(gpa);
    }

    /// The `@ExprCustom` reference trees a sub-language produced for `uri`'s
    /// document (one per `q.custom` call site). Empty when the module errored,
    /// has no custom templates, or the compiler ran without an eval context.
    pub fn customAstFor(self: *const CompileResult, uri: []const u8) []const CustomAstEntry {
        const path = lsp_types.uriToPath(uri);
        for (self.session.outputs.items) |output| {
            if (!std.mem.eql(u8, output.name, path)) continue;
            if (output.outcome == .ok) return output.outcome.ok.custom_ast;
        }
        return &.{};
    }

    /// The typed bindings of `uri`'s own module (NOT a dependency's). The server
    /// keys resolution on the active document, so picking the first `ok` output
    /// would wrongly return a dependency's bindings in a multi-module compile.
    pub fn bindingsFor(self: *const CompileResult, uri: []const u8) []const comptime_pipeline.TypedBinding {
        const path = lsp_types.uriToPath(uri);
        for (self.session.outputs.items) |output| {
            if (!std.mem.eql(u8, output.name, path)) continue;
            if (output.outcome == .ok) return output.outcome.ok.bindings;
        }
        return &.{};
    }

    /// Retorna diagnósticos LSP para o URI dado.
    /// O slice retornado é owned pelo chamador.
    pub fn diagnosticsFor(
        self: *const CompileResult,
        gpa: std.mem.Allocator,
        uri: []const u8,
    ) ![]proto.Diagnostic {
        const path = lsp_types.uriToPath(uri);
        var diags: std.ArrayList(proto.Diagnostic) = .empty;
        errdefer diags.deinit(gpa);

        for (self.session.outputs.items) |output| {
            if (!std.mem.eql(u8, output.name, path)) continue;
            switch (output.outcome) {
                .ok => {},
                .parseError => {},
                .typeError => |te| {
                    const line = if (te.loc) |l| l.line else 1;
                    const col = if (te.loc) |l| l.col else 1;
                    const start = lsp_types.locToPosition(line, col);
                    const end = lsp_types.locToPosition(line, col + 1);
                    const msg = try te.message(gpa);
                    try diags.append(gpa, .{
                        .range = .{ .start = start, .end = end },
                        .severity = proto.DiagnosticSeverity.Error,
                        .message = msg,
                        .source = "botopink",
                    });
                },
                .validationError => |err| {
                    // ComptimeError tem .loc: ast.Loc (1-based line/col)
                    const start = lsp_types.locToPosition(err.loc.line, err.loc.col);
                    const end = lsp_types.locToPosition(err.loc.line, err.loc.col + 1);
                    const msg = try std.fmt.allocPrint(
                        gpa,
                        "comptime error: '{s}' cannot be evaluated at compile time",
                        .{err.ident},
                    );
                    try diags.append(gpa, .{
                        .range = .{ .start = start, .end = end },
                        .severity = proto.DiagnosticSeverity.Error,
                        .message = msg,
                        .source = "botopink",
                    });
                },
            }
        }

        return diags.toOwnedSlice(gpa);
    }
};
