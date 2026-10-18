//! Decision 141: every `#[@External.Erlang(…)]` template the compiler ships —
//! `libs/std` (its modules and the `primitives.bp` prelude) and every bundled
//! library — compiles for the beam backend. The beam backend lowers a template
//! at build time into a helper function (BR5) through the comptime runtime's
//! reader and lowering; a template they refuse is a build error at its call
//! site, with no run-time evaluation of Erlang source to fall back on, so a
//! refused template here is a std function that stops compiling on beam.
//! A single-string `fn:<name>` binding (decisions 238, 263) is no template:
//! it is checked the way the backends check it (`hostFnBinding.resolve`) and
//! a binding it refuses fails the audit like a refused template.
const std = @import("std");
const ast = @import("../../ast.zig");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const comptimeMod = @import("../../comptime.zig");
const beamAsm = @import("../beam_asm.zig");
const primOpTemplate = @import("../../comptime/primOpTemplate.zig");
const hostFnBinding = @import("../hostFnBinding.zig");
const erlTemplate = @import("../beam/erl_template.zig");

const Tally = struct {
    lowered: usize = 0,
    bound: usize = 0,
    refused: std.ArrayListUnmanaged([]const u8) = .empty,
};

fn lowerOne(ar: std.mem.Allocator, tally: *Tally, where: []const u8, template: []const u8, has_recv: bool, argc: usize) !void {
    const body = try beamAsm.templateBody(ar, template, argc);
    const text = try beamAsm.templateModuleText(ar, body, has_recv, argc + @intFromBool(has_recv));
    switch (try beamAsm.lowerTemplateText(ar, text, "bp_tpl_audit")) {
        .ok => tally.lowered += 1,
        .refused => |why| try tally.refused.append(ar, try std.fmt.allocPrint(ar, "{s}: {s}", .{ where, why })),
    }
}

/// A top-level `declare fn` and its module: the one place a `fn:` binding is
/// lowered (`hostFnBinding.Lowering` reads top-level fns only), so a method's
/// `fn:` string is audited as the template text it would be read as.
const Bindable = struct { program: ast.Program, f: ast.FnDecl };

/// Every Erlang template one declaration's implementations carry — a
/// template that is one remote call is a `call_ext`, no template — and each
/// `body:` binding of a top-level `declare fn`, checked by `hostFnBinding`.
fn audit(ar: std.mem.Allocator, tally: *Tally, where: []const u8, implementations: []const ast.Implementation, params: []const ast.Param, bindable: ?Bindable) !void {
    const has_recv = params.len > 0 and std.mem.eql(u8, params[0].name, "self");
    const argc = params.len - @intFromBool(has_recv);
    for (implementations) |impl| {
        if (impl.target != .erlang) continue;
        if (impl.cell) |c| {
            if (c.kind != .body) continue;
            const b = bindable orelse continue;
            switch (try hostFnBinding.resolve(ar, b.f, c.value, b.program, "", "Erlang")) {
                .ok => tally.bound += 1,
                .refused => |why| try tally.refused.append(ar, try std.fmt.allocPrint(ar, "{s}: {s}", .{ where, why })),
            }
            continue;
        }
        const template = impl.template orelse continue;
        if (ast.remoteCallOf(template, params.len) != null) continue;
        // `io/terminal.bp`'s `print` (decision 606 (2)) names the
        // `'__bp_print'/1` helper, which the beam backend writes as its own
        // bytecode beside the module that calls it: no template to lower.
        if (std.mem.indexOf(u8, template, "'__bp_print'") != null) continue;
        try lowerOne(ar, tally, where, template, has_recv, argc);
    }
}

fn auditSource(ar: std.mem.Allocator, tally: *Tally, file: []const u8, src: []const u8) !void {
    var lx = lexerMod.Lexer.init(src);
    const tokens = try lx.scanAll(ar);
    var p = parserMod.Parser.init(tokens);
    const program = try p.parse(ar);
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| try audit(ar, tally, try std.fmt.allocPrint(ar, "{s} {s}", .{ file, f.name }), f.implementations, f.params, .{ .program = program, .f = f }),
        .behavior => |b| for (b.methods) |m| {
            try audit(ar, tally, try std.fmt.allocPrint(ar, "{s} {s}.{s}", .{ file, b.name, m.name }), m.implementations, m.params, null);
        },
        .type_ => |t| for (t.methods) |m| {
            try audit(ar, tally, try std.fmt.allocPrint(ar, "{s} {s}.{s}", .{ file, t.name, m.name }), m.implementations, m.params, null);
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
        std.debug.print("\n{d} template(s) lowered, {d} fn: binding(s) resolved, {d} refused:\n", .{ tally.lowered, tally.bound, tally.refused.items.len });
        for (tally.refused.items) |r| std.debug.print("  {s}\n", .{r});
        return error.TemplateRefused;
    }
    // The audit is worthless if it stopped finding templates.
    try std.testing.expect(tally.lowered >= 150);
    // std/math binds fourteen functions on Erlang through `body:` (`pow` and
    // `fromCodepoint` are plain fns since decision 610's `external-all-bodies`).
    try std.testing.expect(tally.bound >= 14);
}

test "a result: true binding's wrap lowers for the beam backend (decisions 431, 489, 490)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ar = arena.allocator();
    const atoms: erlTemplate.HostErrorAtoms = .{
        .record = "std@failure@@HostError",
        .err = "std@failure@@HostErrorName__v__error",
        .throw = "std@failure@@HostErrorName__v__throw",
        .exit = "std@failure@@HostErrorName__v__exit",
    };
    const templates = [_][]const u8{
        "(case $0 > 0 of true -> $0; false -> erlang:error(negative) end)",
        "(case $0 > 0 of true -> {ok, $0}; false -> {error, refused} end)",
        try erlTemplate.remoteCallTemplate(ar, "erlang", "abs", 1),
    };
    for (templates) |t| {
        const wrapped = try erlTemplate.resultWrap(ar, t, atoms);
        const body = try beamAsm.templateBody(ar, wrapped, 1);
        const text = try beamAsm.templateModuleText(ar, body, false, 1);
        switch (try beamAsm.lowerTemplateText(ar, text, "bp_tpl_result")) {
            .ok => {},
            .refused => |why| {
                std.debug.print("refused: {s}\n{s}\n", .{ why, text });
                return error.TestUnexpectedResult;
            },
        }
    }
}
