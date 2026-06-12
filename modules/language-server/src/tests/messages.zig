/// Testes do frame reader JSON-RPC — cobre `messages.readMessage`.
///
/// Regressão F0a (tooling-update): com a API de Reader do Zig 0.16,
/// `takeDelimiterExclusive` parou ANTES do '\n', o que truncava o body e
/// derrubava o server na primeira mensagem. O reader deve consumir o '\n'.
const std = @import("std");
const messages = @import("../messages.zig");

test "readMessage: parses a single well-formed frame" {
    const gpa = std.testing.allocator;
    const body = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}";
    const frame = try std.fmt.allocPrint(gpa, "Content-Length: {d}\r\n\r\n{s}", .{ body.len, body });
    defer gpa.free(frame);

    var reader: std.Io.Reader = .fixed(frame);
    var msg = (try messages.readMessage(&reader, gpa)).?;
    defer msg.deinit(gpa);

    try std.testing.expectEqual(messages.MessageKind.request, msg.kind);
    try std.testing.expectEqualStrings("initialize", msg.method());
}

test "readMessage: parses two consecutive frames" {
    const gpa = std.testing.allocator;
    const body1 = "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{}}";
    const body2 = "{\"jsonrpc\":\"2.0\",\"method\":\"initialized\",\"params\":{}}";
    const stream = try std.fmt.allocPrint(
        gpa,
        "Content-Length: {d}\r\n\r\n{s}Content-Length: {d}\r\n\r\n{s}",
        .{ body1.len, body1, body2.len, body2 },
    );
    defer gpa.free(stream);

    var reader: std.Io.Reader = .fixed(stream);

    var msg1 = (try messages.readMessage(&reader, gpa)).?;
    defer msg1.deinit(gpa);
    try std.testing.expectEqualStrings("initialize", msg1.method());

    var msg2 = (try messages.readMessage(&reader, gpa)).?;
    defer msg2.deinit(gpa);
    try std.testing.expectEqual(messages.MessageKind.notification, msg2.kind);
    try std.testing.expectEqualStrings("initialized", msg2.method());
}

test "readMessage: extra headers before the body are skipped" {
    const gpa = std.testing.allocator;
    const body = "{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"shutdown\"}";
    const frame = try std.fmt.allocPrint(
        gpa,
        "Content-Length: {d}\r\nContent-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n{s}",
        .{ body.len, body },
    );
    defer gpa.free(frame);

    var reader: std.Io.Reader = .fixed(frame);
    var msg = (try messages.readMessage(&reader, gpa)).?;
    defer msg.deinit(gpa);

    try std.testing.expectEqualStrings("shutdown", msg.method());
}

test "readMessage: returns null at end of stream" {
    const gpa = std.testing.allocator;
    var reader: std.Io.Reader = .fixed("");
    try std.testing.expectEqual(@as(?messages.Message, null), try messages.readMessage(&reader, gpa));
}
