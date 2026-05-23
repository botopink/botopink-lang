/// Runtime execution for generated code.
///
/// Provides functions to execute generated JavaScript (via Node.js) and
/// Erlang code, capturing stdout/stderr for inclusion in snapshots.
const std = @import("std");
fn isProcessSuccess(term: std.process.Child.Term) bool {
    return switch (term) {
        .exited => |code| code == 0,
        else => false,
    };
}

fn combineOutput(allocator: std.mem.Allocator, stdout: []const u8, stderr: []const u8) ![]u8 {
    var output: std.ArrayListUnmanaged(u8) = .empty;
    try output.appendSlice(allocator, stdout);
    if (stderr.len > 0) {
        if (output.items.len > 0) try output.append(allocator, '\n');
        try output.appendSlice(allocator, stderr);
    }
    return output.toOwnedSlice(allocator);
}

/// Execute JavaScript code using Node.js and capture stdout/stderr.
pub fn executeJavaScript(allocator: std.mem.Allocator, js_code: []const u8, io: anytype) ![]u8 {
    // Write code to a temporary file
    const tmp_path = "tmp_run.js";
    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = tmp_path, .data = js_code });
    }
    defer std.Io.Dir.cwd().deleteFile(io, tmp_path) catch {};

    // Execute with Node.js
    const result = std.process.run(allocator, io, .{ .argv = &.{ "node", tmp_path } }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(result.stderr);
    defer allocator.free(result.stdout);
    if (!isProcessSuccess(result.term)) {
        return allocator.dupe(u8, "");
    }

    return combineOutput(allocator, result.stdout, result.stderr);
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

    const compile_result = std.process.run(allocator, io, .{ .argv = &.{ "erlc", erl_filename } }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(compile_result.stdout);
    defer allocator.free(compile_result.stderr);
    defer std.Io.Dir.cwd().deleteFile(io, beam_filename) catch {};
    if (!isProcessSuccess(compile_result.term)) {
        return allocator.dupe(u8, "");
    }

    // Run only modules that export the generated Botopink entrypoint.
    if (std.mem.indexOf(u8, erl_code, "_botopink_main") == null) {
        return allocator.dupe(u8, "");
    }

    const exec_result = std.process.run(allocator, io, .{
        .argv = &.{ "erl", "-noshell", "-pa", ".", "-s", module_name, "_botopink_main", "-s", "init", "stop" },
    }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(exec_result.stdout);
    defer allocator.free(exec_result.stderr);
    if (exec_result.stderr.len > 0) {
        return allocator.dupe(u8, "");
    }
    if (!isProcessSuccess(exec_result.term)) {
        return allocator.dupe(u8, "");
    }

    return combineOutput(allocator, exec_result.stdout, exec_result.stderr);
}

/// Execute BEAM Assembly code: write the `.S`, assemble it with
/// `erlc +from_asm <file>.S` (produces `<module>.beam` in the cwd), then run
/// the generated `_botopink_main/0` via `erl -s ...`.
///
/// Returns the captured stdout. Failure (missing erlc, assembly rejection,
/// or runtime error) returns an empty string so the test still produces a
/// readable snapshot.
pub fn executeBeamAsm(allocator: std.mem.Allocator, asm_code: []const u8, module_name: []const u8, io: anytype) ![]u8 {
    const asm_filename = try std.fmt.allocPrint(allocator, "{s}.S", .{module_name});
    defer allocator.free(asm_filename);

    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = asm_filename, .data = asm_code });
    }
    defer std.Io.Dir.cwd().deleteFile(io, asm_filename) catch {};

    const beam_filename = try std.fmt.allocPrint(allocator, "{s}.beam", .{module_name});
    defer allocator.free(beam_filename);
    defer std.Io.Dir.cwd().deleteFile(io, beam_filename) catch {};

    const assemble_result = std.process.run(allocator, io, .{ .argv = &.{ "erlc", "+from_asm", asm_filename } }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(assemble_result.stdout);
    defer allocator.free(assemble_result.stderr);
    if (!isProcessSuccess(assemble_result.term)) {
        return allocator.dupe(u8, "");
    }

    // Run only modules that export the generated Botopink entrypoint.
    if (std.mem.indexOf(u8, asm_code, "'_botopink_main', 0") == null) {
        return allocator.dupe(u8, "");
    }

    const exec_result = std.process.run(allocator, io, .{
        .argv = &.{ "erl", "-noshell", "-pa", ".", "-s", module_name, "_botopink_main", "-s", "init", "stop" },
    }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(exec_result.stdout);
    defer allocator.free(exec_result.stderr);
    if (exec_result.stderr.len > 0) return allocator.dupe(u8, "");
    if (!isProcessSuccess(exec_result.term)) return allocator.dupe(u8, "");

    return combineOutput(allocator, exec_result.stdout, exec_result.stderr);
}

/// Execute WebAssembly Text: write the `.wat`, run via
/// `wasmtime run --invoke _botopink_main <file>.wat`, capture stdout.
/// Returns empty string if `wasmtime` is absent or the module has no
/// `_botopink_main` export.
pub fn executeWat(allocator: std.mem.Allocator, wat_code: []const u8, module_name: []const u8, io: anytype) ![]u8 {
    const wat_filename = try std.fmt.allocPrint(allocator, "{s}.wat", .{module_name});
    defer allocator.free(wat_filename);

    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = wat_filename, .data = wat_code });
    }
    defer std.Io.Dir.cwd().deleteFile(io, wat_filename) catch {};

    if (std.mem.indexOf(u8, wat_code, "_botopink_main") == null) {
        return allocator.dupe(u8, "");
    }

    const exec_result = std.process.run(allocator, io, .{
        .argv = &.{ "wasmtime", wat_filename },
    }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(exec_result.stdout);
    defer allocator.free(exec_result.stderr);
    if (!isProcessSuccess(exec_result.term)) return allocator.dupe(u8, "");

    return combineOutput(allocator, exec_result.stdout, exec_result.stderr);
}
