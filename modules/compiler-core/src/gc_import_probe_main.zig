//! `gc-import-probe` — decisions 1037, 1045: compile one component on the
//! engine configuration of `codegen/wat/engine.zig` (exceptions, function
//! references, GC, component model) and say whether wasmtime takes it. Its
//! own process, because the import the probe holds makes wasmtime panic, and a
//! panic aborts the process: `codegen/wat/runner.zig`'s test runs this tool
//! and reads how it ended, so nothing that can panic runs in the test binary.
//!
//! `gc-import-probe concrete` compiles the recorded reproduction (a core
//! module import whose type names a concrete GC struct); `abstract` the same
//! import through `anyref`, the control. Answers: `ok` and exit 0 when the
//! component compiled, `refused <message>` and exit 2 when wasmtime refused it
//! with an error, and a panic exits 134 with wasmtime's panic text on stderr
//! (the abort is caught, so no core is dumped).
const std = @import("std");

const c = @cImport({
    @cInclude("wasmtime.h");
});

pub const concrete_wat =
    \\(component (import "unit-0" (core module $u (type $s (struct)) (type $f (func (param (ref null $s)))) (export "a" (func (type $f))))))
;
pub const abstract_wat =
    \\(component (import "unit-0" (core module $u (type $f (func (param anyref))) (export "a" (func (type $f))))))
;

/// A panic's `abort()` ends here: exit 134, no core file.
fn onAbort(_: std.posix.SIG) callconv(.c) void {
    std.c._exit(134);
}

fn say(fd: c_int, text: []const u8) void {
    var off: usize = 0;
    while (off < text.len) {
        const n = std.c.write(fd, text.ptr + off, text.len - off);
        if (n <= 0) return;
        off += @intCast(n);
    }
}

pub fn main(init: std.process.Init) u8 {
    // No core dump, whatever ends the process (PR_SET_DUMPABLE = 4).
    _ = std.c.prctl(4, @as(c_ulong, 0), @as(c_ulong, 0), @as(c_ulong, 0), @as(c_ulong, 0));
    const act: std.posix.Sigaction = .{
        .handler = .{ .handler = onAbort },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    std.posix.sigaction(.ABRT, &act, null);

    var arena_inst = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_inst.deinit();
    const args = init.minimal.args.toSlice(arena_inst.allocator()) catch return 70;
    const which: []const u8 = if (args.len == 2) args[1] else "";
    const wat: []const u8 = if (std.mem.eql(u8, which, "concrete")) concrete_wat else if (std.mem.eql(u8, which, "abstract")) abstract_wat else {
        say(2, "usage: gc-import-probe concrete|abstract\n");
        return 64;
    };

    const config = c.wasm_config_new() orelse return 70;
    c.wasmtime_config_wasm_exceptions_set(config, true);
    c.wasmtime_config_wasm_function_references_set(config, true);
    c.wasmtime_config_wasm_gc_set(config, true);
    c.wasmtime_config_wasm_component_model_set(config, true);
    const engine = c.wasm_engine_new_with_config(config) orelse return 70;
    defer c.wasm_engine_delete(engine);

    var bin: c.wasm_byte_vec_t = undefined;
    if (c.wasmtime_wat2wasm(wat.ptr, wat.len, &bin)) |err| return refused(err);
    defer c.wasm_byte_vec_delete(&bin);
    var comp: ?*c.wasmtime_component_t = null;
    if (c.wasmtime_component_new(engine, @ptrCast(bin.data), bin.size, &comp)) |err| return refused(err);
    c.wasmtime_component_delete(comp);
    say(1, "ok\n");
    return 0;
}

fn refused(err: *c.wasmtime_error_t) u8 {
    var msg: c.wasm_name_t = undefined;
    c.wasmtime_error_message(err, &msg);
    say(1, "refused ");
    if (msg.size > 0) say(1, msg.data[0..msg.size]);
    say(1, "\n");
    return 2;
}
