//! Decision 140: every `#[@External.Erlang(…)]` template the compiler ships —
//! `libs/std` (its modules and the `primitives.bp` prelude) and every bundled
//! library — compiles for the beam backend. The beam backend lowers a template
//! at build time into a helper function (BR5) through the comptime runtime's
//! reader and lowering; a template they refuse is a build error at its call
//! site, with no run-time evaluation of Erlang source to fall back on, so a
//! refused template here is a std function that stops compiling on beam.
const std = @import("std");
const ast = @import("../../ast.zig");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const comptimeMod = @import("../../comptime.zig");
const beamAsm = @import("../beam_asm.zig");
const primOpTemplate = @import("../../comptime/primOpTemplate.zig");

const Tally = struct {
    lowered: usize = 0,
    refused: std.ArrayListUnmanaged([]const u8) = .empty,
};

fn unquote(arg: []const u8) []const u8 {
    if (arg.len >= 6 and std.mem.startsWith(u8, arg, "\"\"\"") and std.mem.endsWith(u8, arg, "\"\"\"")) {
        var inner = arg[3 .. arg.len - 3];
        if (inner.len > 0 and inner[0] == '\n') inner = inner[1..];
        if (inner.len > 0 and inner[inner.len - 1] == '\n') inner = inner[0 .. inner.len - 1];
        return inner;
    }
    if (arg.len >= 2 and arg[0] == '"' and arg[arg.len - 1] == '"') return arg[1 .. arg.len - 1];
    return arg;
}

fn lowerOne(ar: std.mem.Allocator, tally: *Tally, where: []const u8, template: []const u8, has_recv: bool, argc: usize) !void {
    const body = try beamAsm.templateBody(ar, template, argc);
    const text = try beamAsm.templateModuleText(ar, body, has_recv, argc + @intFromBool(has_recv));
    switch (try beamAsm.lowerTemplateText(ar, text, "bp_tpl_audit")) {
        .ok => tally.lowered += 1,
        .refused => |why| try tally.refused.append(ar, try std.fmt.allocPrint(ar, "{s}: {s}", .{ where, why })),
    }
}

/// Every Erlang template one declaration's annotations carry: each arity
/// branch, a one-argument template, a `(module, template)` pair.
fn audit(ar: std.mem.Allocator, tally: *Tally, where: []const u8, annotations: []const ast.Annotation, params: []const ast.Param) !void {
    const has_recv = params.len > 0 and std.mem.eql(u8, params[0].name, "self");
    const argc = params.len - @intFromBool(has_recv);
    for (annotations) |a| {
        if (!std.mem.startsWith(u8, a.name, "External.")) continue;
        if (!std.ascii.eqlIgnoreCase(a.name["External.".len..], "erlang")) continue;
        var branched = false;
        for (a.args) |raw| {
            const branch = ast.parseArityBranchArg(raw) orelse continue;
            branched = true;
            try lowerOne(ar, tally, where, branch.template, has_recv, branch.argc);
        }
        if (branched) continue;
        var n = a.args.len;
        if (n >= 1 and (std.mem.eql(u8, a.args[n - 1], "true") or std.mem.eql(u8, a.args[n - 1], "false"))) n -= 1;
        if (n == 1) {
            try lowerOne(ar, tally, where, unquote(a.args[0]), has_recv, argc);
        } else if (n == 2) {
            const symbol = unquote(a.args[1]);
            if (primOpTemplate.looksLikeTemplate(symbol)) try lowerOne(ar, tally, where, symbol, has_recv, argc);
        }
    }
}

fn auditSource(ar: std.mem.Allocator, tally: *Tally, file: []const u8, src: []const u8) !void {
    var lx = lexerMod.Lexer.init(src);
    const tokens = try lx.scanAll(ar);
    var p = parserMod.Parser.init(tokens);
    const program = try p.parse(ar);
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| try audit(ar, tally, try std.fmt.allocPrint(ar, "{s} {s}", .{ file, f.name }), f.annotations, f.params),
        .behavior => |b| for (b.methods) |m| {
            try audit(ar, tally, try std.fmt.allocPrint(ar, "{s} {s}.{s}", .{ file, b.name, m.name }), m.annotations, m.params);
        },
        .type_ => |t| for (t.methods) |m| {
            try audit(ar, tally, try std.fmt.allocPrint(ar, "{s} {s}.{s}", .{ file, t.name, m.name }), m.annotations, m.params);
        },
        else => {},
    };
}

test "beam: every Erlang template std and the bundled libraries ship compiles at build time" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const ar = arena_state.allocator();
    var tally: Tally = .{};
    try auditSource(ar, &tally, "std/primitives.bp", @import("std_prelude").primitives);
    for (comptimeMod.std_pkg_modules) |m| try auditSource(ar, &tally, m.path, m.source);
    for (comptimeMod.bundled_packages) |pkg| for (pkg.modules) |m| {
        try auditSource(ar, &tally, try std.fmt.allocPrint(ar, "{s}/{s}", .{ pkg.name, m.file }), m.source);
    };
    if (tally.refused.items.len > 0) {
        std.debug.print("\n{d} template(s) lowered, {d} refused:\n", .{ tally.lowered, tally.refused.items.len });
        for (tally.refused.items) |r| std.debug.print("  {s}\n", .{r});
        return error.TemplateRefused;
    }
    // The audit is worthless if it stopped finding templates.
    try std.testing.expect(tally.lowered >= 150);
}
