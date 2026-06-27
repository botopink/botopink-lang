/// In-memory cache of files open in the editor.
///
/// The editor sends the full content of a file via `textDocument/didOpen`
/// and `textDocument/didChange`. We store the latest version here so
/// the compiler always works with what's on screen, not on disk.
const std = @import("std");

pub const FileCache = struct {
    gpa: std.mem.Allocator,
    /// uri → current content (owned by this map)
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

    /// Registers a file newly opened by the editor.
    pub fn open(self: *FileCache, uri: []const u8, text: []const u8) !void {
        const owned_uri = try self.gpa.dupe(u8, uri);
        errdefer self.gpa.free(owned_uri);
        const owned_text = try self.gpa.dupe(u8, text);
        errdefer self.gpa.free(owned_text);

        // Frees previous URI→content mapping if it existed.
        if (self.map.fetchRemove(owned_uri)) |kv| {
            self.gpa.free(kv.key);
            self.gpa.free(kv.value);
        }
        try self.map.put(owned_uri, owned_text);
    }

    /// Applies full changes (LSP TextDocumentSyncKind.Full) to the cached file.
    pub fn change(self: *FileCache, uri: []const u8, new_text: []const u8) !void {
        if (self.map.getPtr(uri)) |ptr| {
            // Dup only in the found branch — the else branch's `open` dups its
            // own copy, so duping up-front here would leak it.
            const owned_text = try self.gpa.dupe(u8, new_text);
            self.gpa.free(ptr.*);
            ptr.* = owned_text;
        } else {
            // File was not open — treat as open.
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

    /// Returns the most recent content of the file.
    /// If not in cache, reads from disk.
    /// The returned slice is owned by the caller when read from disk;
    /// it is owned by the cache when it came from the map — do NOT free in that case.
    /// That's why we return a union indicating where it came from.
    pub fn get(self: *const FileCache, uri: []const u8) ?[]const u8 {
        return self.map.get(uri);
    }

    /// Reads file content, checking cache first then disk.
    /// The returned slice is always owned by the caller (allocated with `gpa`).
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
