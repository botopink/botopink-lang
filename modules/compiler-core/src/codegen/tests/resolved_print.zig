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

/// The cells, by path under `conformance/modules`.
const cells = [_][]const u8{
    // Decorators: an added member, an `@emit`, a meta read, `compiler.init`.
    "decorator/cells/decorator_entity_table",
    "decorator/cells/decorator_arguments_meta",
    "decisions-taken/no_declaration_files_compiler_value-575/cells/init_executor_before_main",
    "decisions-taken/ast_fn_node_builds_mock_member-753/cells/ast_fn_node_builds_mock_member",
    "decisions-taken/bodyless_declarations_two_only-604/cells/decorator_marker_empty_body",
    "decisions-taken/typed_member_reads_own_meta-395/cells/member_reads_own_meta",
    "decisions-taken/decorator_registry_gathers_marked_declarations-665/cells/decl_member_owner",
    // Templates.
    "decisions-taken/template_called_with_raw_text-577/cells/template_annotation",
    "decisions-taken/template_called_with_raw_text-577/cells/template_known_at_build",
    "decisions-taken/template_call_type_is_built_code-426/cells/template_call_typed_by_expansion",
    "decisions-taken/ast_fn_node_builds_mock_member-753/cells/code_template_builds_ast",
    // Top-level `comptime` blocks and their executors.
    "decisions-taken/module_comptime_block-788/cells/module_comptime_block",
    // Folded values, specialised copies (`name_$N` between backticks), a
    // value-or-type parameter's twin, generics.
    "comptime/cells/comptime_section_value",
    "comptime/cells/comptime_fn_name_shadowed_by_local",
    "comptime/cells/comptime_value_or_type_param",
    "generic/cells/generic_method_map",
    "decisions-taken/commonjs_generic_body_receives_type_shape-673/cells/commonjs_generic_body_receives_type_shape",
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
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    var lx = Lexer.init(text);
    const tokens = try lx.scanAll(arena.allocator());
    for (tokens) |t| if (t.kind == .@"comptime" or std.mem.eql(u8, t.lexeme, "syntax")) {
        std.debug.print("{s}: the printing writes `{s}` at line {d}\n{s}\n", .{ cell, t.lexeme, t.line, text });
        return error.ComptimeLeft;
    };
    var session = try codegen.analyse(gpa, &.{moduleOf(text)}, io, cfg);
    defer session.deinit(gpa);
    for (session.outputs.items) |o| {
        if (!std.mem.eql(u8, o.name, "main")) continue;
        const ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => {
                std.debug.print("{s}: the printing does not check\n{s}\n", .{ cell, text });
                return error.PrintingRefused;
            },
        };
        if (ok.comptime_script != null or ok.comptime_traces.len > 0 or ok.template_expansions > 0 or ok.build_output.len > 0) {
            std.debug.print("{s}: the printing still runs comptime\n{s}\n", .{ cell, text });
            return error.ComptimeLeft;
        }
        return;
    }
    return error.NoMainModule;
}

/// What `source` prints when run on `cfg`'s target.
fn answer(gpa: std.mem.Allocator, io: std.Io, source: []const u8, cfg: codegen.Config) ![]u8 {
    var outputs = try codegen.generate(gpa, &.{moduleOf(source)}, io, cfg);
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
