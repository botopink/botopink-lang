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

pub const LspCompiler = struct {
    gpa: std.mem.Allocator,

    pub fn init(gpa: std.mem.Allocator) LspCompiler {
        return .{ .gpa = gpa };
    }

    /// Compila uma lista de módulos (source já em memória) usando apenas
    /// inferência de tipos — sem avaliar expressões comptime.
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

        const session = try comptime_pipeline.compileTypesOnly(self.gpa, mods);
        return .{ .session = session, .modules = modules };
    }
};

/// Par (uri, source) passado para compilação.
pub const ModuleEntry = struct {
    uri: []const u8,
    source: []const u8,
};

/// Resultado de uma sessão de compilação.
pub const CompileResult = struct {
    session: comptime_pipeline.ComptimeSession,
    modules: []const ModuleEntry,

    pub fn deinit(self: *CompileResult, gpa: std.mem.Allocator) void {
        self.session.deinit(gpa);
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
