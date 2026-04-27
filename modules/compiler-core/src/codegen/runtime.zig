/// Runtime execution for generated code.
///
/// Provides functions to execute generated JavaScript (via Node.js) and
/// Erlang code, capturing stdout/stderr for inclusion in snapshots.
const std = @import("std");

/// Execute JavaScript code using Node.js and capture stdout/stderr.
pub fn executeJavaScript(allocator: std.mem.Allocator, js_code: []const u8, io: anytype) ![]u8 {
    // Write code to a temporary file
    const tmp_path = "tmp_run.js";
    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = tmp_path, .data = js_code });
    }
    defer std.Io.Dir.cwd().deleteFile(io, tmp_path) catch {};

    // Execute with Node.js
    const result = try std.process.run(allocator, io, .{ .argv = &.{ "node", tmp_path } });
    defer allocator.free(result.stderr);
    defer allocator.free(result.stdout);

    // Combine stdout and stderr
    var output: std.ArrayListUnmanaged(u8) = .empty;
    try output.appendSlice(allocator, result.stdout);
    if (result.stderr.len > 0) {
        if (output.items.len > 0) try output.append(allocator, '\n');
        try output.appendSlice(allocator, result.stderr);
    }

    return output.toOwnedSlice(allocator);
}

/// Execute Erlang code and capture stdout/stderr.
pub fn executeErlang(allocator: std.mem.Allocator, erl_code: []const u8, module_name: []const u8, io: anytype) ![]u8 {
    // Create temporary .erl file
    const erl_filename = try std.fmt.allocPrint(allocator, "{s}.erl", .{module_name});
    defer allocator.free(erl_filename);
    
    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_filename, .data = erl_code });
    }
    defer std.Io.Dir.cwd().deleteFile(io, erl_filename) catch {};

    // Compile the Erlang module
    const beam_filename = try std.fmt.allocPrint(allocator, "{s}.beam", .{module_name});
    defer allocator.free(beam_filename);
    
    _ = try std.process.run(allocator, io, .{ .argv = &.{ "erlc", erl_filename } });
    defer std.Io.Dir.cwd().deleteFile(io, beam_filename) catch {};

    // Find the main function to call (typically the first pub function or a function named 'main')
    // For now, we'll try to call 'main' if it exists, otherwise skip execution
    var output: std.ArrayListUnmanaged(u8) = .empty;
    
    // Try to execute the module's main function if it exists
    const exec_result = std.process.run(allocator, io, .{
        .argv = &.{ "erl", "-noshell", "-s", module_name, "main", "-s", "init", "stop" }
    }) catch |err| {
        // If main doesn't exist, that's okay - just return empty output
        if (err == error.ProcessTerminated) {
            return output.toOwnedSlice(allocator);
        }
        return err;
    };
    
    defer allocator.free(exec_result.stdout);
    defer allocator.free(exec_result.stderr);

    // Combine stdout and stderr
    try output.appendSlice(allocator, exec_result.stdout);
    if (exec_result.stderr.len > 0) {
        if (output.items.len > 0) try output.append(allocator, '\n');
        try output.appendSlice(allocator, exec_result.stderr);
    }

    return output.toOwnedSlice(allocator);
}
