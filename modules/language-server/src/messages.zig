/// JSON-RPC 2.0 frame reader/writer sobre stdin/stdout.
///
/// Frame format:
///   Content-Length: <N>\r\n
///   \r\n
///   <N bytes de JSON>
const std = @import("std");

// ── Tipos de mensagem ─────────────────────────────────────────────────────────

pub const MessageKind = enum { request, notification, response };

/// Mensagem JSON-RPC decodificada. Ownership do JSON raw e do parsed value
/// são gerenciados pelo `Parsed` — chame `deinit()` quando terminar.
pub const Message = struct {
    kind: MessageKind,
    /// JSON bruto (alocado com `gpa`).
    raw: []u8,
    /// Valor parseado — arena owned pelo `parsed`.
    parsed: std.json.Parsed(std.json.Value),

    pub fn deinit(self: *Message, gpa: std.mem.Allocator) void {
        gpa.free(self.raw);
        self.parsed.deinit();
    }

    /// Retorna o valor `id` da mensagem (null se for notification).
    pub fn id(self: *const Message) std.json.Value {
        return self.parsed.value.object.get("id") orelse .null;
    }

    /// Retorna o `method` da mensagem (vazio se for response).
    pub fn method(self: *const Message) []const u8 {
        return if (self.parsed.value.object.get("method")) |m|
            switch (m) {
                .string => |s| s,
                else => "",
            }
        else
            "";
    }

    /// Retorna `params` como `std.json.Value` (.null se ausente).
    pub fn params(self: *const Message) std.json.Value {
        return self.parsed.value.object.get("params") orelse .null;
    }
};

// ── Reader ────────────────────────────────────────────────────────────────────

/// Lê uma mensagem JSON-RPC do `reader`. Retorna `null` em EOF.
pub fn readMessage(
    reader: *std.Io.Reader,
    gpa: std.mem.Allocator,
) !?Message {
    // ── headers ──────────────────────────────────────────────────────────────
    var content_length: usize = 0;

    while (true) {
        const line = reader.takeDelimiterExclusive('\n') catch |err| switch (err) {
            error.EndOfStream => return null,
            else => return err,
        };
        const trimmed = std.mem.trimEnd(u8, line, "\r");
        if (trimmed.len == 0) break; // linha em branco = fim dos headers
        if (std.mem.startsWith(u8, trimmed, "Content-Length: ")) {
            const num_str = trimmed["Content-Length: ".len..];
            content_length = std.fmt.parseInt(usize, num_str, 10) catch 0;
        }
    }

    if (content_length == 0) return null;

    // ── body ──────────────────────────────────────────────────────────────────
    const body = try reader.readAlloc(gpa, content_length);
    errdefer gpa.free(body);

    const parsed = try std.json.parseFromSlice(
        std.json.Value,
        gpa,
        body,
        .{ .ignore_unknown_fields = true },
    );
    errdefer parsed.deinit();

    const root = parsed.value;
    if (root != .object) {
        parsed.deinit();
        gpa.free(body);
        return null;
    }

    const kind: MessageKind = blk: {
        const has_id = root.object.contains("id");
        const has_method = root.object.contains("method");
        if (has_method and has_id) break :blk .request;
        if (has_method) break :blk .notification;
        break :blk .response;
    };

    return .{ .kind = kind, .raw = body, .parsed = parsed };
}

// ── Writer ────────────────────────────────────────────────────────────────────

const WRITE_MUTEX = std.debug.lockStderr; // reuse stderr mutex as a no-op placeholder
// Stdout é single-threaded no LSP — sem mutex necessário na fase 1.

/// Escreve um JSON-RPC response (result) para stdout.
pub fn writeResponse(
    io: std.Io,
    gpa: std.mem.Allocator,
    msg_id: std.json.Value,
    result: anytype,
) !void {
    const result_json = try std.json.Stringify.valueAlloc(gpa, result, .{
        .emit_null_optional_fields = false,
    });
    defer gpa.free(result_json);

    // Montar um Value para o campo result
    var result_parsed = try std.json.parseFromSlice(std.json.Value, gpa, result_json, .{});
    defer result_parsed.deinit();

    const envelope = .{
        .jsonrpc = "2.0",
        .id = msg_id,
        .result = result_parsed.value,
    };

    const body = try std.json.Stringify.valueAlloc(gpa, envelope, .{
        .emit_null_optional_fields = false,
    });
    defer gpa.free(body);

    try writeFrame(io, gpa, body);
}

/// Escreve uma notification JSON-RPC para stdout.
pub fn writeNotification(
    io: std.Io,
    gpa: std.mem.Allocator,
    method_name: []const u8,
    params_value: anytype,
) !void {
    const params_json = try std.json.Stringify.valueAlloc(gpa, params_value, .{
        .emit_null_optional_fields = false,
    });
    defer gpa.free(params_json);

    var params_parsed = try std.json.parseFromSlice(std.json.Value, gpa, params_json, .{});
    defer params_parsed.deinit();

    const envelope = .{
        .jsonrpc = "2.0",
        .method = method_name,
        .params = params_parsed.value,
    };

    const body = try std.json.Stringify.valueAlloc(gpa, envelope, .{
        .emit_null_optional_fields = false,
    });
    defer gpa.free(body);

    try writeFrame(io, gpa, body);
}

/// Escreve um JSON-RPC error response para stdout.
pub fn writeError(
    io: std.Io,
    gpa: std.mem.Allocator,
    msg_id: std.json.Value,
    code: i32,
    message: []const u8,
) !void {
    const envelope = .{
        .jsonrpc = "2.0",
        .id = msg_id,
        .@"error" = .{ .code = code, .message = message },
    };

    const body = try std.json.Stringify.valueAlloc(gpa, envelope, .{
        .emit_null_optional_fields = false,
    });
    defer gpa.free(body);

    try writeFrame(io, gpa, body);
}

// ── Frame interno ─────────────────────────────────────────────────────────────

fn writeFrame(io: std.Io, gpa: std.mem.Allocator, body: []const u8) !void {
    const header = try std.fmt.allocPrint(
        gpa,
        "Content-Length: {d}\r\n\r\n",
        .{body.len},
    );
    defer gpa.free(header);

    const frame = try std.mem.concat(gpa, u8, &.{ header, body });
    defer gpa.free(frame);

    try std.Io.File.stdout().writeStreamingAll(io, frame);
}
