/// Entry point for the botopink language server.
///
/// The server is started by the editor via `botopink-lsp` in PATH and
/// communicates over JSON-RPC 2.0 on stdin/stdout.
const std = @import("std");
const Server = @import("./server.zig").Server;

pub fn main(init: std.process.Init) void {
    const gpa = init.gpa;
    const io = init.io;

    var server = Server.init(gpa, io);
    defer server.deinit();

    server.run() catch |err| {
        std.log.err("server error: {}", .{err});
    };
}
