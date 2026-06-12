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

/// Tests may run concurrently (and several test binaries share this cwd), so
/// every execution gets its own scratch directory — fixed filenames like
/// `main.erl`/`main.beam` would otherwise race and lose runtime output.
fn makeScratchDir(io: anytype, buf: *[64]u8) ![]const u8 {
    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const id = std.mem.readInt(u64, &rand_bytes, .little);
    const tmp_dir = std.fmt.bufPrint(buf, ".tmp-exec-{x}", .{id}) catch unreachable;
    try std.Io.Dir.cwd().createDirPath(io, tmp_dir);
    return tmp_dir;
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

/// A sibling module written next to the entry file so `require`/remote calls
/// resolve at runtime (multi-module compilations, e.g. the "std" package).
pub const AuxFile = struct {
    name: []const u8,
    code: []const u8,
};

/// Execute JavaScript code using Node.js and capture stdout/stderr.
/// `aux` modules are written as `<scratch>/<name>.js` (subdirs created) so the
/// entry's `require("./<name>.js")` calls resolve.
pub fn executeJavaScript(allocator: std.mem.Allocator, js_code: []const u8, aux: []const AuxFile, io: anytype) ![]u8 {
    // Write code to a temporary file in a per-execution scratch dir
    var dir_buf: [64]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const tmp_path = try std.fmt.allocPrint(allocator, "{s}/tmp_run.js", .{tmp_dir});
    defer allocator.free(tmp_path);
    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = tmp_path, .data = js_code });
    }
    for (aux) |a| {
        const aux_path = try std.fmt.allocPrint(allocator, "{s}/{s}.js", .{ tmp_dir, a.name });
        defer allocator.free(aux_path);
        if (std.fs.path.dirname(aux_path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_path, .data = a.code });
    }

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

/// An Erlang module name is the path basename (`std/bool` → `bool`) —
/// matches the `-module(...)` atom the erlang backend emits.
fn erlModuleName(name: []const u8) []const u8 {
    return if (std.mem.lastIndexOfScalar(u8, name, '/')) |i| name[i + 1 ..] else name;
}

/// Execute Erlang code and capture stdout/stderr.
/// `aux` modules are compiled into the same scratch dir so remote calls
/// (`option:map(...)`) resolve at runtime.
pub fn executeErlang(allocator: std.mem.Allocator, erl_code: []const u8, module_name: []const u8, aux: []const AuxFile, io: anytype) ![]u8 {
    // Create temporary .erl file in a per-execution scratch dir
    var dir_buf: [64]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const entry_module = erlModuleName(module_name);
    const erl_filename = try std.fmt.allocPrint(allocator, "{s}/{s}.erl", .{ tmp_dir, entry_module });
    defer allocator.free(erl_filename);

    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_filename, .data = erl_code });
    }

    // Compile the Erlang module (and any sibling modules it calls into)
    const compile_result = std.process.run(allocator, io, .{ .argv = &.{ "erlc", "-o", tmp_dir, erl_filename } }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(compile_result.stdout);
    defer allocator.free(compile_result.stderr);
    if (!isProcessSuccess(compile_result.term)) {
        return allocator.dupe(u8, "");
    }
    for (aux) |a| {
        const aux_module = erlModuleName(a.name);
        if (std.mem.eql(u8, aux_module, entry_module)) continue;
        const aux_filename = try std.fmt.allocPrint(allocator, "{s}/{s}.erl", .{ tmp_dir, aux_module });
        defer allocator.free(aux_filename);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_filename, .data = a.code });
        const aux_compile = std.process.run(allocator, io, .{ .argv = &.{ "erlc", "-o", tmp_dir, aux_filename } }) catch |err| switch (err) {
            error.FileNotFound => return allocator.dupe(u8, ""),
            else => return err,
        };
        allocator.free(aux_compile.stdout);
        allocator.free(aux_compile.stderr);
        if (!isProcessSuccess(aux_compile.term)) {
            return allocator.dupe(u8, "");
        }
    }

    // Run only modules that export the generated Botopink entrypoint.
    if (std.mem.indexOf(u8, erl_code, "_botopink_main") == null) {
        return allocator.dupe(u8, "");
    }

    const exec_result = std.process.run(allocator, io, .{
        .argv = &.{ "erl", "-noinput", "-pa", tmp_dir, "-s", entry_module, "_botopink_main", "-s", "init", "stop" },
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
pub fn executeBeamAsm(allocator: std.mem.Allocator, asm_code: []const u8, module_name: []const u8, aux: []const AuxFile, io: anytype) ![]u8 {
    var dir_buf: [64]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const entry_module = erlModuleName(module_name);
    const asm_filename = try std.fmt.allocPrint(allocator, "{s}/{s}.S", .{ tmp_dir, entry_module });
    defer allocator.free(asm_filename);

    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = asm_filename, .data = asm_code });
    }

    const assemble_result = std.process.run(allocator, io, .{ .argv = &.{ "erlc", "+from_asm", "-o", tmp_dir, asm_filename } }) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, ""),
        else => return err,
    };
    defer allocator.free(assemble_result.stdout);
    defer allocator.free(assemble_result.stderr);
    if (!isProcessSuccess(assemble_result.term)) {
        return allocator.dupe(u8, "");
    }

    // Assemble sibling modules the entry calls into (cross-module `call_ext`).
    for (aux) |a| {
        const aux_module = erlModuleName(a.name);
        if (std.mem.eql(u8, aux_module, entry_module)) continue;
        const aux_filename = try std.fmt.allocPrint(allocator, "{s}/{s}.S", .{ tmp_dir, aux_module });
        defer allocator.free(aux_filename);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = aux_filename, .data = a.code });
        const aux_assemble = std.process.run(allocator, io, .{ .argv = &.{ "erlc", "+from_asm", "-o", tmp_dir, aux_filename } }) catch |err| switch (err) {
            error.FileNotFound => return allocator.dupe(u8, ""),
            else => return err,
        };
        allocator.free(aux_assemble.stdout);
        allocator.free(aux_assemble.stderr);
        if (!isProcessSuccess(aux_assemble.term)) {
            return allocator.dupe(u8, "");
        }
    }

    // Run only modules that export the generated Botopink entrypoint.
    if (std.mem.indexOf(u8, asm_code, "'_botopink_main', 0") == null) {
        return allocator.dupe(u8, "");
    }

    const exec_result = std.process.run(allocator, io, .{
        .argv = &.{ "erl", "-noinput", "-pa", tmp_dir, "-s", entry_module, "_botopink_main", "-s", "init", "stop" },
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
    var dir_buf: [64]u8 = undefined;
    const tmp_dir = try makeScratchDir(io, &dir_buf);
    defer std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};

    const wat_filename = try std.fmt.allocPrint(allocator, "{s}/{s}.wat", .{ tmp_dir, module_name });
    defer allocator.free(wat_filename);

    {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = wat_filename, .data = wat_code });
    }

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
