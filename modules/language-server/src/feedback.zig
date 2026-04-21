/// Controle de quais arquivos têm diagnósticos ativos no editor.
///
/// O LSP exige que o servidor publique uma lista VAZIA de diagnósticos
/// para limpar erros anteriores de um arquivo. O FeedbackBookkeeper
/// rastreia quais URIs têm diagnósticos para que possamos limpá-los
/// corretamente quando o arquivo é corrigido ou fechado.
const std = @import("std");
const proto = @import("./protocol.zig");

pub const FeedbackBookkeeper = struct {
    gpa: std.mem.Allocator,
    /// Conjunto de URIs que têm diagnósticos ativos (erros ou warnings).
    active: std.StringHashMap(void),

    pub fn init(gpa: std.mem.Allocator) FeedbackBookkeeper {
        return .{
            .gpa = gpa,
            .active = std.StringHashMap(void).init(gpa),
        };
    }

    pub fn deinit(self: *FeedbackBookkeeper) void {
        var it = self.active.keyIterator();
        while (it.next()) |k| self.gpa.free(k.*);
        self.active.deinit();
    }

    /// Registra que `uri` tem diagnósticos ativos.
    pub fn mark(self: *FeedbackBookkeeper, uri: []const u8) !void {
        if (self.active.contains(uri)) return;
        const owned = try self.gpa.dupe(u8, uri);
        try self.active.put(owned, {});
    }

    /// Remove `uri` do conjunto de arquivos com diagnósticos.
    pub fn clear(self: *FeedbackBookkeeper, uri: []const u8) void {
        if (self.active.fetchRemove(uri)) |kv| {
            self.gpa.free(kv.key);
        }
    }

    /// Retorna true se o URI tem diagnósticos ativos registrados.
    pub fn has(self: *const FeedbackBookkeeper, uri: []const u8) bool {
        return self.active.contains(uri);
    }
};
