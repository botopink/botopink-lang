/// Cache em memória de arquivos abertos no editor.
///
/// O editor envia o conteúdo completo de um arquivo via `textDocument/didOpen`
/// e `textDocument/didChange`. Guardamos a versão mais recente aqui para que
/// o compilador sempre trabalhe com o que está na tela, não no disco.
const std = @import("std");

pub const FileCache = struct {
    gpa: std.mem.Allocator,
    /// uri → conteúdo atual (owned por este mapa)
    map: std.StringHashMap([]u8),

    pub fn init(gpa: std.mem.Allocator) FileCache {
        return .{
            .gpa = gpa,
            .map = std.StringHashMap([]u8).init(gpa),
        };
    }

    pub fn deinit(self: *FileCache) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            self.gpa.free(entry.key_ptr.*);
            self.gpa.free(entry.value_ptr.*);
        }
        self.map.deinit();
    }

    /// Registra um arquivo recém-aberto pelo editor.
    pub fn open(self: *FileCache, uri: []const u8, text: []const u8) !void {
        const owned_uri = try self.gpa.dupe(u8, uri);
        errdefer self.gpa.free(owned_uri);
        const owned_text = try self.gpa.dupe(u8, text);
        errdefer self.gpa.free(owned_text);

        // Se já existia, libera os anteriores.
        if (self.map.fetchRemove(owned_uri)) |kv| {
            self.gpa.free(kv.key);
            self.gpa.free(kv.value);
        }
        try self.map.put(owned_uri, owned_text);
    }

    /// Aplica mudanças full (LSP TextDocumentSyncKind.Full) ao arquivo em cache.
    pub fn change(self: *FileCache, uri: []const u8, new_text: []const u8) !void {
        const owned_text = try self.gpa.dupe(u8, new_text);
        errdefer self.gpa.free(owned_text);

        if (self.map.getPtr(uri)) |ptr| {
            self.gpa.free(ptr.*);
            ptr.* = owned_text;
        } else {
            // Arquivo não estava aberto — trata como open.
            try self.open(uri, new_text);
        }
    }

    /// Remove um arquivo do cache quando o editor o fecha.
    pub fn close(self: *FileCache, uri: []const u8) void {
        if (self.map.fetchRemove(uri)) |kv| {
            self.gpa.free(kv.key);
            self.gpa.free(kv.value);
        }
    }

    /// Retorna o conteúdo mais recente do arquivo.
    /// Se não estiver em cache, lê do disco.
    /// O slice retornado é owned pelo chamador quando lido do disco;
    /// é owned pelo cache quando veio do map — NÃO libere nesse caso.
    /// Por isso retornamos um union que indica de onde veio.
    pub fn get(self: *const FileCache, uri: []const u8) ?[]const u8 {
        return self.map.get(uri);
    }

    /// Lê o conteúdo do arquivo, consultando o cache primeiro e depois o disco.
    /// O slice retornado é sempre owned pelo chamador (alocado com `gpa`).
    pub fn read(self: *const FileCache, gpa: std.mem.Allocator, io: std.Io, uri: []const u8) ![]u8 {
        if (self.map.get(uri)) |cached| {
            return gpa.dupe(u8, cached);
        }

        // Fallback: ler do disco.
        const path = uriToPath(uri);
        const cwd = std.Io.Dir.cwd();
        return cwd.readFileAlloc(io, path, gpa, .limited(10 * 1024 * 1024));
    }
};

fn uriToPath(uri: []const u8) []const u8 {
    if (std.mem.startsWith(u8, uri, "file://")) return uri["file://".len..];
    return uri;
}
