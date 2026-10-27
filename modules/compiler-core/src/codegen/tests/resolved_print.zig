//! Decision 798 (1), (5) — the resolved program's printer
//! (`comptime/resolved_print.zig`), held to its oracle over cells of the
//! conformance suite: each cell's printing lexes with no `comptime` /
//! `syntax` word, re-parses and type-checks with no comptime left to run (no
//! fold, no template expansion, no decorator, no build output), and the
//! printed program built on every target answers what the cell answers.
//!
//! The set is single-file cells whose answer does not name a place in their
//! own source (a printed file's lines are not the written one's): decorators
//! (an added member, an `@emit`, `compiler.init` executors), templates, top-
//! level `comptime` blocks, folded values and specialised copies.

const std = @import("std");
const test_scratch = @import("test_scratch");
const codegen = @import("../../codegen.zig");
const comptimeMod = @import("../../comptime.zig");
const resolvedPrint = @import("../../comptime/resolved_print.zig");
const reservedNames = @import("../../comptime/reserved_names.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const h = @import("helpers.zig");

const cells_dir = "../../conformance/modules";

/// The cells, by path under `conformance/modules`. A cell reading
/// `@TypeInfo.all` is out until B-137: its read is printed as written
/// (decision 835 (3)), which no program without comptime answers.
const cells = [_][]const u8{
    // Decorators: an added member, an `@emit`, a meta read, `compiler.init`.
    "decorator/cases/decorator_entity_table",
    "decorator/cases/decorator_arguments_meta",
    "decisions-taken/no_declaration_files_compiler_value-575/cases/init_executor_before_main",
    "decisions-taken/ast_fn_node_builds_mock_member-753/cases/ast_fn_node_builds_mock_member",
    "decisions-taken/typed_member_reads_own_meta-395/cases/member_reads_own_meta",
    "decisions-taken/decorator_registry_gathers_marked_declarations-665/cells/decl_member_owner",
    // Templates.
    "decisions-taken/template_called_with_raw_text-577/cases/template_annotation",
    "decisions-taken/template_called_with_raw_text-577/cells/template_known_at_build",
    "decisions-taken/template_call_type_is_built_code-426/cases/template_call_typed_by_expansion",
    "decisions-taken/ast_fn_node_builds_mock_member-753/cases/code_template_builds_ast",
    // Top-level `comptime` blocks and their executors.
    "decisions-taken/module_comptime_block-788/cases/module_comptime_block",
    // Folded values, specialised copies (`name_$N` between backticks), a
    // value-or-type parameter's twin, generics.
    "comptime/cases/comptime_section_value",
    "comptime/cases/comptime_fn_name_shadowed_by_local",
    "comptime/cases/comptime_value_or_type_param",
    "generic/cases/generic_method_map",
    "decisions-taken/commonjs_generic_body_receives_type_shape-673/cases/commonjs_generic_body_receives_type_shape",
    // A folded context, printed `createContext(v)` (decision 835 (1)).
    "decisions-taken/component_is_lambda_over_render_scope-388/cases/component_is_lambda",
};

fn moduleOf(source: []const u8) codegen.Module {
    return .{ .path = "main", .source = source, .srcPath = "src/main.bp", .root = true };
}

/// The resolved program of `source`'s one module.
fn printed(gpa: std.mem.Allocator, io: std.Io, source: []const u8, cfg: codegen.Config) ![]u8 {
    comptimeMod.keep_resolved = true;
    defer comptimeMod.keep_resolved = false;
    var session = try codegen.analyse(gpa, &.{moduleOf(source)}, io, cfg);
    defer session.deinit(gpa);
    return resolvedPrint.print(gpa, session.outputs.items, &.{"main"});
}

/// The printing holds no comptime form, and its analysis runs none.
fn expectNoComptime(gpa: std.mem.Allocator, io: std.Io, cell: []const u8, text: []const u8, cfg: codegen.Config) !void {
    try expectNoComptimeIn(gpa, io, cell, &.{moduleOf(text)}, cfg);
}

/// Every module of `modules` lexes with no `comptime` / `syntax` word, and
/// their analysis checks and runs no comptime.
fn expectNoComptimeIn(gpa: std.mem.Allocator, io: std.Io, cell: []const u8, modules: []const codegen.Module, cfg: codegen.Config) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    for (modules) |m| {
        var lx = Lexer.init(m.source);
        const tokens = try lx.scanAll(arena.allocator());
        for (tokens) |t| if (t.kind == .@"comptime" or std.mem.eql(u8, t.lexeme, "syntax")) {
            std.debug.print("{s}: the printing of {s} writes `{s}` at line {d}\n{s}\n", .{ cell, m.path, t.lexeme, t.line, m.source });
            return error.ComptimeLeft;
        };
    }
    var session = try codegen.analyse(gpa, modules, io, cfg);
    defer session.deinit(gpa);
    var seen: usize = 0;
    for (session.outputs.items) |o| {
        const printed_module = for (modules) |m| {
            if (std.mem.eql(u8, m.path, o.name)) break m;
        } else continue;
        seen += 1;
        const ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => {
                std.debug.print("{s}: the printing of {s} does not check\n{s}\n", .{ cell, o.name, printed_module.source });
                return error.PrintingRefused;
            },
        };
        if (ok.comptime_script != null or ok.comptime_traces.len > 0 or ok.template_expansions > 0 or ok.build_output.len > 0) {
            std.debug.print("{s}: the printing of {s} still runs comptime\n{s}\n", .{ cell, o.name, printed_module.source });
            return error.ComptimeLeft;
        }
    }
    if (seen != modules.len) return error.NoMainModule;
}

/// What `source` prints when run on `cfg`'s target.
fn answer(gpa: std.mem.Allocator, io: std.Io, source: []const u8, cfg: codegen.Config) ![]u8 {
    return answerOf(gpa, io, &.{moduleOf(source)}, cfg);
}

/// What the program of `modules` prints when run on `cfg`'s target.
fn answerOf(gpa: std.mem.Allocator, io: std.Io, modules: []const codegen.Module, cfg: codegen.Config) ![]u8 {
    var outputs = try codegen.generate(gpa, modules, io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(gpa);
        outputs.deinit(gpa);
    }
    for (outputs.items) |o| if (std.mem.eql(u8, o.name, "main"))
        return gpa.dupe(u8, o.result.run_output orelse "");
    return error.NoMainModule;
}

test "resolved program: a cell's printing checks with no comptime left and answers as the cell on every target (decision 798 (5))" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    var dir = try std.Io.Dir.cwd().openDir(io, cells_dir, .{});
    defer dir.close(io);
    // The printing's names are the compiler's own (805 (6)); read back here
    // alone, by this oracle.
    reservedNames.accept_compiler_names = true;
    defer reservedNames.accept_compiler_names = false;
    for (cells) |cell| {
        const path = try std.fs.path.join(gpa, &.{ cell, "src", "main.bp" });
        defer gpa.free(path);
        const source = try dir.readFileAlloc(io, path, gpa, .limited(1024 * 1024));
        defer gpa.free(source);
        var cfg0 = h.configs[0];
        cfg0.build_root = test_scratch.path(io, "codegen/resolved_print");
        const text = try printed(gpa, io, source, cfg0);
        defer gpa.free(text);
        try expectNoComptime(gpa, io, cell, text, cfg0);
        for (h.configs) |c| {
            var cfg = c;
            cfg.build_root = cfg0.build_root;
            const want = try answer(gpa, io, source, cfg);
            defer gpa.free(want);
            const got = try answer(gpa, io, text, cfg);
            defer gpa.free(got);
            if (!std.mem.eql(u8, want, got)) {
                std.debug.print("{s} on {s}: the printing answers\n{s}\nthe cell\n{s}\nprinted:\n{s}\n", .{ cell, @tagName(cfg.targetSource), got, want, text });
                return error.AnswerDiffers;
            }
        }
    }
}

// Decision 834 — a package of several modules and a dependency: one file per
// module, the dependency's under its own directory; a template of the
// dependency whose expansion calls the dependency's private `wrap` reaches it
// through its hygiene alias, printed as the alias import, `wrap` declared in
// the dependency's file; the decorators and templates that ran left out with
// their imports.
const lib_root = "pub mod tools;\n";
const lib_tools =
    \\import {compiler} from "std";
    \\
    \\fn quoted(text: string) -> string {
    \\    return "\"" + text + "\"";
    \\}
    \\
    \\fn wrap(text: string) -> string {
    \\    return "[" + text + "]";
    \\}
    \\
    \\pub fn entity(syntax decl: unknown, comptime table: string) -> void {
    \\    compiler.addMember("pub fn table() -> string { return " + quoted(table) + "; }");
    \\}
    \\
    \\pub fn shout(syntax q: string) -> string {
    \\    return compiler.build("(" + quoted(compiler.text(q)) + ").toUpper()");
    \\}
    \\
    \\pub fn boxed(syntax q: string) -> string {
    \\    return compiler.build("wrap(" + quoted(compiler.text(q)) + ")");
    \\}
    \\
    \\pub fn label(name: string, n: i32) -> string {
    \\    return name + "#" + n.toString();
    \\}
    \\
;
const app_util =
    \\import {tools.entity, tools.boxed, tools.label} from "lib";
    \\
    \\#[entity("towns")]
    \\pub type Town(name: string)
    \\
    \\pub fn greet() -> string {
    \\    return boxed @`hi` + Town.table() + label("n", comptime 6 * 7);
    \\}
    \\
;
const app_main =
    \\import {io.terminal.print} from "std";
    \\import {tools.shout} from "lib";
    \\
    \\pub mod util;
    \\
    \\import {util.greet};
    \\
    \\pub val loud = shout @`hello`;
    \\
    \\pub fn main() -> void {
    \\    print(loud);
    \\    print(greet());
    \\}
    \\
;

const project_packages: codegen.Config = blk: {
    var c = h.configs[0];
    c.packages = .{ .root = "test", .deps = &.{"lib"} };
    break :blk c;
};

fn projectModules(lib_r: []const u8, lib_t: []const u8, util: []const u8, main: []const u8) [4]codegen.Module {
    return .{
        .{ .path = "lib/root", .package = "lib", .source = lib_r, .srcPath = "src/root.bp" },
        .{ .path = "lib/tools", .package = "lib", .source = lib_t, .srcPath = "src/tools.bp" },
        .{ .path = "util", .source = util, .srcPath = "src/util.bp" },
        .{ .path = "main", .source = main, .srcPath = "src/main.bp", .root = true },
    };
}

/// The printed text of module `name` among `files`.
fn fileOf(files: []const resolvedPrint.File, name: []const u8) ![]const u8 {
    var buf: [128]u8 = undefined;
    const head = try std.fmt.bufPrint(&buf, "// module {s}\n", .{name});
    for (files) |f| if (std.mem.startsWith(u8, f.text, head)) return f.text;
    return error.ModuleNotPrinted;
}

test "resolved program: one file per module, a dependency's in its own directory, the printed tree answers as the project on every target (decision 834)" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    reservedNames.accept_compiler_names = true;
    defer reservedNames.accept_compiler_names = false;
    const written = projectModules(lib_root, lib_tools, app_util, app_main);
    var cfg0 = project_packages;
    cfg0.build_root = test_scratch.path(io, "codegen/resolved_print_project");

    const files = blk: {
        comptimeMod.keep_resolved = true;
        defer comptimeMod.keep_resolved = false;
        var session = try codegen.analyse(gpa, &written, io, cfg0);
        defer session.deinit(gpa);
        break :blk try resolvedPrint.files(gpa, session.outputs.items, "test", &.{"lib"});
    };
    defer resolvedPrint.freeFiles(gpa, files);

    // Each module at `<pkg>/<module path>.bp`, opened by its `// module` line.
    for ([_][2][]const u8{
        .{ "lib/root.bp", "lib/root" },
        .{ "lib/tools.bp", "lib/tools" },
        .{ "test/util.bp", "util" },
        .{ "test/main.bp", "main" },
    }) |want| {
        const f = for (files) |f| {
            if (std.mem.eql(u8, f.path, want[0])) break f;
        } else {
            std.debug.print("no file {s}\n", .{want[0]});
            return error.FileMissing;
        };
        var buf: [64]u8 = undefined;
        try std.testing.expect(std.mem.startsWith(u8, f.text, try std.fmt.bufPrint(&buf, "// module {s}\n", .{want[1]})));
    }
    const util = try fileOf(files, "util");
    const tools = try fileOf(files, "lib/tools");
    const main = try fileOf(files, "main");
    // The hygiene alias as its import, `wrap` declared in its own file.
    try std.testing.expect(std.mem.indexOf(u8, util, "import {tools.wrap as __bp_tpl_lib_tools__wrap} from \"lib\";") != null);
    try std.testing.expect(std.mem.indexOf(u8, tools, "fn wrap(text: string) -> string") != null);
    // What ran at build is gone with its import; the names are as written.
    try std.testing.expect(std.mem.indexOf(u8, tools, "fn entity") == null);
    try std.testing.expect(std.mem.indexOf(u8, util, "tools.entity") == null);
    try std.testing.expect(std.mem.indexOf(u8, main, "tools.shout") == null);
    try std.testing.expect(std.mem.indexOf(u8, main, "import {util.greet};") != null);
    // Decision 798 (2) — each piece's origin, the dependency's file named by
    // its module path: the member at the decorator's `addMember` call, each
    // expansion at its template, the folded value at its `comptime`.
    try expectHolds(util, "    // from #[entity] (lib/tools.bp:12)\n    pub fn table() -> string {");
    try expectHolds(util, "    // from boxed (lib/tools.bp:19)\n    // from comptime (src/util.bp:7)\n    return __bp_tpl_lib_tools__wrap(\"hi\")");
    try expectHolds(main, "\n\n// from shout (lib/tools.bp:15)\npub val loud = ");

    // The printed tree read back as the project: no comptime left, the same
    // answer on every target.
    const reread = projectModules(try fileOf(files, "lib/root"), tools, util, main);
    try expectNoComptimeIn(gpa, io, "project", &reread, cfg0);
    for (h.configs) |c| {
        var cfg = c;
        cfg.packages = cfg0.packages;
        cfg.build_root = cfg0.build_root;
        const want = try answerOf(gpa, io, &written, cfg);
        defer gpa.free(want);
        const got = try answerOf(gpa, io, &reread, cfg);
        defer gpa.free(got);
        if (!std.mem.eql(u8, want, got) or want.len == 0) {
            std.debug.print("project on {s}: the printing answers\n{s}\nthe project\n{s}\n", .{ @tagName(cfg.targetSource), got, want });
            for (files) |f| std.debug.print("{s}:\n{s}\n", .{ f.path, f.text });
            return error.AnswerDiffers;
        }
    }
}

fn expectHolds(text: []const u8, want: []const u8) !void {
    if (std.mem.indexOf(u8, text, want) != null) return;
    std.debug.print("the printing lacks\n{s}\nprinted:\n{s}\n", .{ want, text });
    return error.OriginMissing;
}

// Decision 798 (2) — every piece the build produced carries its origin as a
// `//` comment over it: a decorator's added member and `compiler.init`
// executor at the decorator's output call, a top-level `comptime` block's
// executor at its `compiler.init`, a template's expansion at the template, a
// folded `comptime` value at the `comptime`. The comments are never read
// back: the printing still checks with no comptime and answers as the
// program on every target.
const origins_main =
    \\import {compiler, io.terminal.print} from "std";
    \\
    \\var entries: string[] = [];
    \\
    \\pub fn register(entry: string) -> void {
    \\    entries.push(entry);
    \\}
    \\
    \\pub fn registered(syntax decl: unknown) -> void {
    \\    val name = compiler.name(decl)!;
    \\    compiler.init({ -> register(name) });
    \\}
    \\
    \\pub fn entity(syntax decl: unknown, comptime table: string) -> void {
    \\    compiler.addMember("pub fn table() -> string { return \"" + table + "\"; }");
    \\}
    \\
    \\pub fn shout(syntax q: string) -> string {
    \\    return compiler.build("(\"" + compiler.text(q) + "\").toUpper()");
    \\}
    \\
    \\comptime {
    \\    compiler.init({ -> register("block") });
    \\}
    \\
    \\#[entity("towns")]
    \\pub type Town(name: string)
    \\
    \\#[registered]
    \\pub fn own() -> string {
    \\    return "own";
    \\}
    \\
    \\pub val answer = comptime 6 * 7;
    \\
    \\pub fn main() -> void {
    \\    print(entries.join(","));
    \\    print(shout @`hello`);
    \\    print(Town.table() + " " + own() + " " + answer.toString());
    \\}
    \\
;

test "resolved program: each piece the build produced carries its origin as a comment, never read back (decision 798 (2))" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    reservedNames.accept_compiler_names = true;
    defer reservedNames.accept_compiler_names = false;
    var cfg0 = h.configs[0];
    cfg0.build_root = test_scratch.path(io, "codegen/resolved_print_origins");
    const text = try printed(gpa, io, origins_main, cfg0);
    defer gpa.free(text);
    try expectHolds(text, "\n\n// from comptime { … } (src/main.bp:23)\npub fn __bp_executor_");
    try expectHolds(text, "    // from #[entity] (src/main.bp:15)\n    pub fn table() -> string {");
    try expectHolds(text, "\n\n// from #[registered] (src/main.bp:11)\npub fn __bp_executor_");
    try expectHolds(text, "\n\n// from comptime (src/main.bp:34)\npub val answer = 42;");
    try expectHolds(text, "    // from shout (src/main.bp:18)\n    print((\"hello\").toUpper());");
    // One comment per piece: the `val` that runs an executor is the
    // executor's piece.
    try std.testing.expectEqual(@as(usize, 5), std.mem.count(u8, text, "// from "));
    try expectNoComptime(gpa, io, "origins", text, cfg0);
    for (h.configs) |c| {
        var cfg = c;
        cfg.build_root = cfg0.build_root;
        const want = try answer(gpa, io, origins_main, cfg);
        defer gpa.free(want);
        const got = try answer(gpa, io, text, cfg);
        defer gpa.free(got);
        if (!std.mem.eql(u8, want, got) or want.len == 0) {
            std.debug.print("origins on {s}: the printing answers\n{s}\nthe program\n{s}\nprinted:\n{s}\n", .{ @tagName(cfg.targetSource), got, want, text });
            return error.AnswerDiffers;
        }
    }
}
