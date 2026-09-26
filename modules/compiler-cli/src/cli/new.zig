/// `botopink new <name>` — scaffold a new botopink project.
const std = @import("std");
const reporter = @import("./reporter.zig");
const manifest = @import("manifest");

// ── Options ───────────────────────────────────────────────────────────────────

pub const Options = struct {
    name: []const u8,
    target: []const u8 = "commonJS",
};

// ── Templates ─────────────────────────────────────────────────────────────────

/// The scaffolded program. It must **print**: a block's value is its `break`
/// (`specs/1.0.4-beta/08-review-backlog/semantics-decisions.md` decision 2), so
/// a body whose only statement is the literal `"Hello, world!"` evaluates to
/// nothing and `botopink run` shows an empty screen — the quick start of the
/// README then has no visible effect. `@print` is the builtin, on every target.
const MAIN_BP =
    \\fn greet(name: string) -> string {
    \\    return "Hello, " + name + "!";
    \\}
    \\
    \\pub fn main() {
    \\    @print(greet("world"));
    \\}
    \\
;

const GITIGNORE =
    \\out/
    \\.botopinkbuild/
    \\
;

// ── Entry point ───────────────────────────────────────────────────────────────

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options) !u8 {
    // Validate name.
    if (opts.name.len == 0) {
        reporter.errMsg("project name cannot be empty");
        return 1;
    }
    for (opts.name) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '-' and c != '_') {
            reporter.errMsg("project name may only contain letters, digits, '-' and '_'");
            return 1;
        }
    }
    // The name becomes the manifest's `name`, which `manifest` refuses unless
    // it starts with a lowercase letter (decision 109) — refuse before
    // scaffolding a project that could not build.
    if (manifest.nameRefusal(opts.name)) |why| {
        reporter.errMsg(why);
        return 1;
    }

    const cwd = std.Io.Dir.cwd();

    // Check if directory already exists.
    cwd.access(io, opts.name, .{}) catch {
        // Doesn't exist — good, we can create it.
        try cwd.createDirPath(io, opts.name);
        reporter.created(opts.name);
    };
    // If access succeeded, the dir already exists — we'll write into it anyway.

    // Create src/ subdirectory.
    const src_dir_path = try std.fmt.allocPrint(gpa, "{s}/src", .{opts.name});
    defer gpa.free(src_dir_path);
    cwd.createDirPath(io, src_dir_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    reporter.created(src_dir_path);

    // Write src/main.bp
    const main_bp_path = try std.fmt.allocPrint(gpa, "{s}/src/main.bp", .{opts.name});
    defer gpa.free(main_bp_path);
    try cwd.writeFile(io, .{ .sub_path = main_bp_path, .data = MAIN_BP });
    reporter.created(main_bp_path);

    // Write botopink.json
    const json_path = try std.fmt.allocPrint(gpa, "{s}/botopink.json", .{opts.name});
    defer gpa.free(json_path);
    const json_content = try std.fmt.allocPrint(gpa,
        \\{{
        \\  "name": "{s}",
        \\  "version": "0.1.0",
        \\  "target": "{s}"
        \\}}
        \\
    , .{ opts.name, opts.target });
    defer gpa.free(json_content);
    try cwd.writeFile(io, .{ .sub_path = json_path, .data = json_content });
    reporter.created(json_path);

    // Write .gitignore
    const gitignore_path = try std.fmt.allocPrint(gpa, "{s}/.gitignore", .{opts.name});
    defer gpa.free(gitignore_path);
    try cwd.writeFile(io, .{ .sub_path = gitignore_path, .data = GITIGNORE });
    reporter.created(gitignore_path);

    std.debug.print("\nYour botopink project \"{s}\" is ready.\n", .{opts.name});
    std.debug.print("Get started:\n\n  cd {s}\n  botopink run\n\n", .{opts.name});

    return 0;
}
