/// `botopink check` — type-check without generating code.
const std = @import("std");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");
const config = @import("./config.zig");
const scanner = @import("./scanner.zig");

pub fn run(gpa: std.mem.Allocator, io: std.Io) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    const proj = config.load(arena, io) catch |err| {
        switch (err) {
            error.ConfigNotFound => reporter.errMsg("botopink.json not found — are you in a botopink project?"),
            error.ConfigInvalid => reporter.errMsg("botopink.json is invalid JSON"),
            else => reporter.errMsg("failed to load botopink.json"),
        }
        return 1;
    };

    const modules = try scanner.scanSources(gpa, io, "src");
    defer scanner.freeModules(gpa, modules);

    if (modules.len == 0) {
        reporter.errMsg("no source files found in src/");
        return 1;
    }

    reporter.checking(modules.len);
    const t0 = std.Io.Timestamp.now(io, .awake);

    const runtime: bp.comptime_pipeline.ComptimeRuntime = switch (proj.parsedTarget()) {
        .commonJS => .node,
        .erlang => .erlang,
    };

    var session = bp.comptime_pipeline.compile(
        gpa,
        modules,
        io,
        runtime,
        ".botopinkbuild",
    ) catch |err| {
        reporter.errMsg("type-check failed");
        std.debug.print("  {s}\n", .{@errorName(err)});
        return 1;
    };
    defer session.deinit(gpa);

    const t1 = std.Io.Timestamp.now(io, .awake);

    var had_error = false;
    for (session.outputs.items) |o| {
        switch (o.outcome) {
            .ok => {},
            .parseError => {
                had_error = true;
                std.debug.print("error: parse error in {s}\n", .{o.name});
            },
            .validationError => |ce| {
                had_error = true;
                const rendered = ce.renderAlloc(gpa, o.src) catch continue;
                defer gpa.free(rendered);
                std.debug.print("{s}", .{rendered});
            },
        }
    }

    if (had_error) return 1;

    reporter.checked(reporter.nsToMs(t0.durationTo(t1).nanoseconds));
    return 0;
}
