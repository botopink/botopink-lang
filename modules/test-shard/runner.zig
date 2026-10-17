//! The compiler-core test runner: zig's default runner, restricted to one
//! SHARD of the test list, so `zig build test` can run the suite as several
//! processes side by side (`build.zig`, `test_shards`).
//!
//! `BOTOPINK_TEST_SHARD=<i>/<n>` selects the tests whose index in
//! `builtin.test_functions` is `i` modulo `n`; unset, the shard is `0/1` —
//! every test, which is exactly the default runner. Every index belongs to
//! exactly one shard of `0/n … (n-1)/n`, so the `n` run steps together run
//! each test once; none is skipped and none runs twice.
//!
//! Everything else is the default runner's contract (`lib/compiler/
//! test_runner.zig` of zig 0.16), minus fuzzing, which no test here uses:
//! under the build runner (`--listen=-`) it answers `query_test_metadata`
//! with the shard's names and `run_test` with the shard's k-th test, so every
//! failure, leak, logged error and timeout is reported per test by name,
//! exactly as before; without it, it runs the shard and prints the default
//! runner's terminal report. A test that logs at `err` level fails, a leak
//! fails, `--seed` seeds `std.testing.random_seed`.
const builtin = @import("builtin");
const std = @import("std");
const Io = std.Io;
const testing = std.testing;
const panic = std.debug.panic;

pub const std_options: std.Options = .{
    .logFn = log,
};

var log_err_count: usize = 0;
var fba: std.heap.FixedBufferAllocator = .init(&fba_buffer);
var fba_buffer: [8192]u8 = undefined;
var stdin_buffer: [4096]u8 = undefined;
var stdout_buffer: [4096]u8 = undefined;
var stdin_reader: Io.File.Reader = undefined;
var stdout_writer: Io.File.Writer = undefined;
const runner_threaded_io: Io = Io.Threaded.global_single_threaded.io();

/// The indices of this process's shard, in their `builtin.test_functions` order.
var shard: []const u32 = &.{};

/// `<i>/<n>` → the shard's indices. A malformed value is a panic, not the
/// whole suite: a typo in `build.zig` must not quietly run every test `n` times.
fn selectShard(env: ?[]const u8) void {
    var index: u32 = 0;
    var count: u32 = 1;
    if (env) |v| {
        const slash = std.mem.indexOfScalar(u8, v, '/') orelse panic("BOTOPINK_TEST_SHARD must be <i>/<n>, got '{s}'", .{v});
        index = std.fmt.parseUnsigned(u32, v[0..slash], 10) catch panic("BOTOPINK_TEST_SHARD: bad index in '{s}'", .{v});
        count = std.fmt.parseUnsigned(u32, v[slash + 1 ..], 10) catch panic("BOTOPINK_TEST_SHARD: bad count in '{s}'", .{v});
        if (count == 0 or index >= count) panic("BOTOPINK_TEST_SHARD: need 0 <= i < n, got '{s}'", .{v});
    }
    const n: usize = builtin.test_functions.len;
    const len: usize = if (index < n) (n - index + count - 1) / count else 0;
    const buf = std.heap.page_allocator.alloc(u32, len) catch panic("out of memory selecting the shard", .{});
    var i: u32 = index;
    for (buf) |*slot| {
        slot.* = i;
        i += count;
    }
    shard = buf;
}

pub fn main(init: std.process.Init.Minimal) void {
    @disableInstrumentation();

    const args = init.args.toSlice(fba.allocator()) catch |err| panic("unable to parse command line args: {t}", .{err});
    var listen = false;
    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "--listen=-")) {
            listen = true;
        } else if (std.mem.startsWith(u8, arg, "--seed=")) {
            testing.random_seed = std.fmt.parseUnsigned(u32, arg["--seed=".len..], 0) catch
                @panic("unable to parse --seed command line argument");
        } else if (std.mem.startsWith(u8, arg, "--cache-dir")) {
            // Only the fuzzer reads it.
        } else {
            panic("unrecognized command line argument: {s}", .{arg});
        }
    }

    // `getAlloc` rather than `getPosix`: the same call on every OS the suite
    // builds on (the windows CI row included).
    const shard_env: ?[]const u8 = init.environ.getAlloc(std.heap.page_allocator, "BOTOPINK_TEST_SHARD") catch |err| switch (err) {
        error.EnvironmentVariableMissing => null,
        else => panic("unable to read BOTOPINK_TEST_SHARD: {t}", .{err}),
    };
    selectShard(shard_env);

    if (listen) {
        return mainServer(init) catch |err| panic("internal test runner failure: {t}", .{err});
    } else {
        return mainTerminal(init);
    }
}

fn mainServer(init: std.process.Init.Minimal) !void {
    @disableInstrumentation();
    stdin_reader = .initStreaming(.stdin(), runner_threaded_io, &stdin_buffer);
    stdout_writer = .initStreaming(.stdout(), runner_threaded_io, &stdout_buffer);
    var server = try std.zig.Server.init(.{
        .in = &stdin_reader.interface,
        .out = &stdout_writer.interface,
        .zig_version = builtin.zig_version_string,
    });

    while (true) {
        const hdr = try server.receiveMessage();
        switch (hdr.tag) {
            .exit => {
                return std.process.exit(0);
            },
            .query_test_metadata => {
                testing.allocator_instance = .{};
                defer if (testing.allocator_instance.deinit() == .leak) {
                    @panic("internal test runner memory leak");
                };

                var string_bytes: std.ArrayList(u8) = .empty;
                defer string_bytes.deinit(testing.allocator);
                try string_bytes.append(testing.allocator, 0); // Reserve 0 for null.

                const names = try testing.allocator.alloc(u32, shard.len);
                defer testing.allocator.free(names);
                const expected_panic_msgs = try testing.allocator.alloc(u32, shard.len);
                defer testing.allocator.free(expected_panic_msgs);

                for (shard, names, expected_panic_msgs) |ti, *name, *expected_panic_msg| {
                    const test_fn = builtin.test_functions[ti];
                    name.* = @intCast(string_bytes.items.len);
                    try string_bytes.ensureUnusedCapacity(testing.allocator, test_fn.name.len + 1);
                    string_bytes.appendSliceAssumeCapacity(test_fn.name);
                    string_bytes.appendAssumeCapacity(0);
                    expected_panic_msg.* = 0;
                }

                try server.serveTestMetadata(.{
                    .names = names,
                    .expected_panic_msgs = expected_panic_msgs,
                    .string_bytes = string_bytes.items,
                });
            },

            .run_test => {
                testing.environ = init.environ;
                testing.allocator_instance = .{};
                testing.io_instance = .init(testing.allocator, .{
                    .argv0 = .init(init.args),
                    .environ = init.environ,
                });
                log_err_count = 0;
                // The build runner numbers the tests the metadata listed.
                const index = try server.receiveBody_u32();
                const test_fn = builtin.test_functions[shard[index]];

                try server.serveStringMessage(.test_started, &.{});

                const TestResults = std.zig.Server.Message.TestResults;
                const status: TestResults.Status = if (test_fn.func()) |v| s: {
                    v;
                    break :s .pass;
                } else |err| switch (err) {
                    error.SkipZigTest => .skip,
                    else => s: {
                        if (@errorReturnTrace()) |trace| {
                            std.debug.dumpErrorReturnTrace(trace);
                        }
                        break :s .fail;
                    },
                };
                testing.io_instance.deinit();
                const leak_count = testing.allocator_instance.detectLeaks();
                testing.allocator_instance.deinitWithoutLeakChecks();
                try server.serveTestResults(.{
                    .index = index,
                    .flags = .{
                        .status = status,
                        .fuzz = false,
                        .log_err_count = std.math.lossyCast(
                            @FieldType(TestResults.Flags, "log_err_count"),
                            log_err_count,
                        ),
                        .leak_count = std.math.lossyCast(
                            @FieldType(TestResults.Flags, "leak_count"),
                            leak_count,
                        ),
                    },
                });
            },
            else => {
                std.debug.print("unsupported message: {x}\n", .{@intFromEnum(hdr.tag)});
                std.process.exit(1);
            },
        }
    }
}

fn mainTerminal(init: std.process.Init.Minimal) void {
    @disableInstrumentation();

    var ok_count: usize = 0;
    var skip_count: usize = 0;
    var fail_count: usize = 0;
    const root_node = std.Progress.start(runner_threaded_io, .{
        .root_name = "Test",
        .estimated_total_items = shard.len,
    });
    const have_tty = Io.File.stderr().isTty(runner_threaded_io) catch unreachable;

    var leaks: usize = 0;
    for (shard, 0..) |ti, i| {
        const test_fn = builtin.test_functions[ti];
        testing.allocator_instance = .{};
        testing.io_instance = .init(testing.allocator, .{
            .argv0 = .init(init.args),
            .environ = init.environ,
        });
        defer {
            testing.io_instance.deinit();
            if (testing.allocator_instance.deinit() == .leak) leaks += 1;
        }
        testing.log_level = .warn;
        testing.environ = init.environ;

        const test_node = root_node.start(test_fn.name, 0);
        if (!have_tty) {
            std.debug.print("{d}/{d} {s}...", .{ i + 1, shard.len, test_fn.name });
        }
        if (test_fn.func()) |_| {
            ok_count += 1;
            test_node.end();
            if (!have_tty) std.debug.print("OK\n", .{});
        } else |err| switch (err) {
            error.SkipZigTest => {
                skip_count += 1;
                if (have_tty) {
                    std.debug.print("{d}/{d} {s}...SKIP\n", .{ i + 1, shard.len, test_fn.name });
                } else {
                    std.debug.print("SKIP\n", .{});
                }
                test_node.end();
            },
            else => {
                fail_count += 1;
                if (have_tty) {
                    std.debug.print("{d}/{d} {s}...FAIL ({t})\n", .{ i + 1, shard.len, test_fn.name, err });
                } else {
                    std.debug.print("FAIL ({t})\n", .{err});
                }
                if (@errorReturnTrace()) |trace| {
                    std.debug.dumpErrorReturnTrace(trace);
                }
                test_node.end();
            },
        }
    }
    root_node.end();
    if (ok_count == shard.len) {
        std.debug.print("All {d} tests passed.\n", .{ok_count});
    } else {
        std.debug.print("{d} passed; {d} skipped; {d} failed.\n", .{ ok_count, skip_count, fail_count });
    }
    if (log_err_count != 0) {
        std.debug.print("{d} errors were logged.\n", .{log_err_count});
    }
    if (leaks != 0) {
        std.debug.print("{d} tests leaked memory.\n", .{leaks});
    }
    if (leaks != 0 or log_err_count != 0 or fail_count != 0) {
        std.process.exit(1);
    }
}

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    @disableInstrumentation();
    if (@intFromEnum(message_level) <= @intFromEnum(std.log.Level.err)) {
        log_err_count +|= 1;
    }
    if (@intFromEnum(message_level) <= @intFromEnum(testing.log_level)) {
        std.debug.print(
            "[" ++ @tagName(scope) ++ "] (" ++ @tagName(message_level) ++ "): " ++ format ++ "\n",
            args,
        );
    }
}
