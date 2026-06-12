//! Shared test harness for the comptime stage (moved from tests.zig).
//! Pure harness module: imports + `pub fn`/data helpers, no test blocks.

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const snapMod = @import("../../utils/snap.zig");
const prettyMod = @import("../../utils/pretty.zig");
const T = @import(".././types.zig");
const envMod = @import("../env.zig");
const inferMod = @import("../infer.zig");
const comptimeMod = @import("../../comptime.zig");
const errorMod = @import("../error.zig");
const snapshot = @import("../snapshot.zig");
const Module = @import("../../module.zig").Module;
const format = @import("../../format.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;

pub fn slugify(comptime s: []const u8) []const u8 {
    const n: usize = comptime blk: {
        var count: usize = 0;
        var sep = true;
        for (s) |c| {
            if (std.ascii.isAlphanumeric(c)) {
                count += 1;
                sep = false;
            } else if (!sep) {
                count += 1;
                sep = true;
            }
        }
        if (sep and count > 0) count -= 1;
        break :blk count;
    };
    const S = struct {
        const data: [n]u8 = blk: {
            var buf: [n]u8 = undefined;
            var i: usize = 0;
            var sep = true;
            for (s) |c| {
                if (std.ascii.isAlphanumeric(c)) {
                    if (i < n) {
                        buf[i] = std.ascii.toLower(c);
                        i += 1;
                    }
                    sep = false;
                } else if (!sep) {
                    if (i < n) {
                        buf[i] = '_';
                        i += 1;
                    }
                    sep = true;
                }
            }
            break :blk buf;
        };
    };
    return &S.data;
}

pub fn slugFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const desc = comptime blk: {
        const fnName = loc.fn_name;
        const afterTest = if (std.mem.startsWith(u8, fnName, "test."))
            fnName["test.".len..]
        else
            fnName;
        break :blk if (std.mem.indexOf(u8, afterTest, ": ")) |i|
            afterTest[i + 2 ..]
        else
            afterTest;
    };
    return slugify(desc);
}

pub fn buildRootPathFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const slug = comptime slugFromSrc(loc);
    return comptime std.fmt.comptimePrint(".botopinkbuild/comptime/{s}", .{slug});
}

pub fn assertComptimeAst(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
) !void {
    const io = std.testing.io;
    const runtimes = [_]comptimeMod.ComptimeRuntime{ .node, .erlang, .wasm, .beam };
    const base_slug = comptime slugFromSrc(loc);

    for (runtimes) |runtime| {
        var build_root_buf: [512]u8 = undefined;
        const build_root_path = try std.fmt.bufPrint(&build_root_buf, ".botopinkbuild/comptime/{s}", .{base_slug});

        var session = try comptimeMod.compile(allocator, modules, io, runtime, build_root_path);
        defer session.deinit(allocator);

        // Collect outputs
        var outputs = std.ArrayList(comptimeMod.ComptimeOutput).empty;
        defer outputs.deinit(allocator);

        for (session.outputs.items) |output| {
            try outputs.append(allocator, output);
        }

        // Save snapshots in separate directories per runtime
        const runtime_path = switch (runtime) {
            .node => "comptime/node",
            .erlang => "comptime/erlang",
            .wasm => "comptime/wasm",
            .beam => "comptime/beam",
        };
        var snap_buf: [512]u8 = undefined;
        const snap_slug = try std.fmt.bufPrint(&snap_buf, "{s}/{s}", .{ runtime_path, base_slug });
        try snapshot.assertComptimeAstWithPath(allocator, snap_slug, outputs.items);
    }
}

pub fn assertComptimeAstSingle(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    return assertComptimeAst(allocator, loc, &.{.{ .path = "", .source = src }});
}

pub fn getSourceLine(src: []const u8, line: usize) []const u8 {
    var currentLine: usize = 1;
    var start: usize = 0;
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        if (currentLine == line) {
            var end = i;
            while (end < src.len and src[end] != '\n') end += 1;
            return src[start..end];
        }
        if (src[i] == '\n') {
            currentLine += 1;
            start = i + 1;
        }
    }
    return src[start..];
}

pub fn renderTypeError(
    allocator: std.mem.Allocator,
    src: []const u8,
    err: errorMod.TypeError,
) ![]u8 {
    // Use an arena so intermediate allocPrint strings are freed together.
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const tmp = arena.allocator();

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    // ----- SOURCE CODE section
    try out.appendSlice(allocator, "----- SOURCE CODE\n");
    try out.appendSlice(allocator, src);
    if (src.len > 0 and src[src.len - 1] != '\n') try out.append(allocator, '\n');
    try out.appendSlice(allocator, "\n----- ERROR\n");

    // Error title
    const title = switch (err.kind) {
        .typeMismatch => "type mismatch",
        .unboundVariable => "unbound variable",
        .arityMismatch => "arity mismatch",
        .unknownField => "unknown field",
        .notARecord => "not a record type",
        .recursiveType => "recursive type",
        .unknownTypeName => "unknown type",
        .missingField => "missing field",
        .methodNotActive => "method not active",
        .ambiguousExtension => "ambiguous extension method",
        .notAnExtension => "not an extension symbol",
        .extendRequiresInterface => "extend requires an interface",
        .redundantActivation => "redundant activation",
        .useNotAllowed => "`use` not allowed",
        .useNotContext => "`use` requires @Context",
        .contextMismatch => "ContextBase mismatch",
        .throwWithoutResult => "throw outside @Result",
        .missingMethod => "missing interface method",
        .unknownMethod => "unknown method",
        .unknownInterface => "unknown interface",
        .ambiguousMethod => "ambiguous method",
        .typeparamConstraint => "type constraint not satisfied",
        .tryOnNonResult => "try on non-Result",
        .nonExhaustive => "non-exhaustive case",
        .redundantPattern => "unreachable case arm",
        .custom => |c| c.message,
    };
    try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "error: {s}\n", .{title}));

    // Location box if available
    if (err.loc) |errLoc| {
        const lineText = getSourceLine(src, errLoc.line);
        const col0 = if (errLoc.col > 0) errLoc.col - 1 else 0;
        // ┌─ :line:col
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            tmp,
            "  \u{250c}\u{2500} :{d}:{d}\n",
            .{ errLoc.line, errLoc.col },
        ));
        // │
        try out.appendSlice(allocator, "  \u{2502}\n");
        // N │ source line
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            tmp,
            "{d} \u{2502} {s}\n",
            .{ errLoc.line, lineText },
        ));
        // │ spaces^
        try out.appendSlice(allocator, "  \u{2502} ");
        for (0..col0) |_| try out.append(allocator, ' ');
        try out.appendSlice(allocator, "^\n");
    }

    // Error details
    switch (err.kind) {
        .typeMismatch => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  expected: {s}\n  found:    {s}\n",
                .{ try snapshot.typeNameOf(tmp, m.expected), try snapshot.typeNameOf(tmp, m.got) },
            ));
        },
        .unboundVariable => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not in scope\n",
                .{name},
            ));
        },
        .arityMismatch => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' expected {d} argument(s), got {d}\n",
                .{ a.name, a.expected, a.got },
            ));
        },
        .unknownField => |f| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has no field '{s}'\n",
                .{ f.typeName, f.field },
            ));
        },
        .notARecord => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not a record or struct type\n",
                .{name},
            ));
        },
        .recursiveType => {
            try out.appendSlice(allocator, "\n  type variable would reference itself (infinite type)\n");
        },
        .unknownTypeName => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  the type '{s}' is not defined in this scope\n",
                .{name},
            ));
        },
        .missingField => |f| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' requires field '{s}'\n",
                .{ f.typeName, f.field },
            ));
        },
        .methodNotActive => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has no active method '{s}'\n  hint: activate the extension with `{s}*`\n",
                .{ m.typeName, m.method, m.hintSym },
            ));
        },
        .ambiguousExtension => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}.{s}' is provided by both '{s}' and '{s}'\n  hint: qualify the call, e.g. `{s}.{s}(obj)`\n",
                .{ a.typeName, a.method, a.symA, a.symB, a.symA, a.method },
            ));
        },
        .notAnExtension => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' does not name an implement/extend symbol\n",
                .{name},
            ));
        },
        .extendRequiresInterface => |t| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `extend {s}` adds methods without a contract\n  hint: use `implement <Interface> for {s}` so the methods satisfy an interface\n",
                .{ t, t },
            ));
        },
        .redundantActivation => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `{s}*` is redundant: a local extension is auto-applied\n  hint: drop it — `*` is only for imports\n",
                .{name},
            ));
        },
        .useNotAllowed => |returnType| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  function returns `{s}` which does not implement @Context\n",
                .{returnType},
            ));
        },
        .useNotContext => |exprType| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `{s}` does not implement @Context — `use` requires @Context<_, _>\n",
                .{exprType},
            ));
        },
        .contextMismatch => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  function returns @Context<{s}, _>\n  but the `use` expression returns @Context<{s}, _>\n",
                .{ m.fnBase, m.useBase },
            ));
        },
        .throwWithoutResult => {
            try out.appendSlice(allocator, "\n  'throw' requires the enclosing fn to return '@Result<D, E>'\n");
        },
        .missingMethod => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' does not implement '{s}' required by interface '{s}'\n",
                .{ m.typeName, m.method, m.interfaceName },
            ));
        },
        .unknownMethod => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not declared in any interface implemented for '{s}'\n",
                .{ m.method, m.typeName },
            ));
        },
        .unknownInterface => |u| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not an interface implemented here (method '{s}')\n",
                .{ u.qualifier, u.method },
            ));
        },
        .ambiguousMethod => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is declared by both '{s}' and '{s}' — qualify it\n",
                .{ a.method, a.interfaceA, a.interfaceB },
            ));
        },
        .typeparamConstraint => |c| {
            const gotName = try snapshot.typeNameOf(tmp, c.got);
            var list: std.ArrayList(u8) = .empty;
            for (c.constraints, 0..) |name, i| {
                if (i > 0) try list.appendSlice(tmp, ", ");
                try list.appendSlice(tmp, name);
            }
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has type '{s}', which does not satisfy 'type {s}'\n",
                .{ c.paramName, gotName, list.items },
            ));
        },
        .tryOnNonResult => |ty| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `try` requires a @Result<D, E> value, found '{s}'\n",
                .{try snapshot.typeNameOf(tmp, ty)},
            ));
        },
        .nonExhaustive => |n| {
            if (n.missing.len == 0) {
                try out.appendSlice(allocator, try std.fmt.allocPrint(
                    tmp,
                    "\n  `{s}` has no wildcard `_` arm; it cannot be matched exhaustively\n",
                    .{n.typeName},
                ));
            } else {
                var list: std.ArrayList(u8) = .empty;
                for (n.missing, 0..) |name, i| {
                    if (i > 0) try list.appendSlice(tmp, ", ");
                    try list.appendSlice(tmp, name);
                }
                try out.appendSlice(allocator, try std.fmt.allocPrint(
                    tmp,
                    "\n  '{s}' is missing variant(s): {s}\n",
                    .{ n.typeName, list.items },
                ));
            }
        },
        .redundantPattern => |r| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  {s} is already covered by an earlier arm ('{s}')\n",
                .{ r.description, r.typeName },
            ));
        },
        .custom => |c| {
            if (c.hint) |h| {
                try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "\n  hint: {s}\n", .{h}));
            }
        },
    }

    return try out.toOwnedSlice(allocator);
}

pub fn assertTypeErrorSnap(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try p.parse(alloc);
    defer program.deinit(alloc);

    var env = Env.init(alloc);
    defer env.deinit();
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, allocator);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));

    const result = inferMod.inferProgram(&env, program);
    try std.testing.expectError(error.TypeError, result);
    const err = env.lastError orelse return error.TestExpectedEqual;

    const desc = try renderTypeError(allocator, src, err);
    defer allocator.free(desc);

    const base_slug = comptime slugFromSrc(loc);

    // Save the same error snapshot in both node/errors/ and erlang/errors/
    // Error messages are runtime-agnostic (type inference happens before codegen)
    const runtimes = [_][]const u8{ "node", "erlang" };
    for (runtimes) |runtime| {
        var snap_buf: [512]u8 = undefined;
        const snap_slug = try std.fmt.bufPrint(&snap_buf, "comptime/{s}/errors/{s}", .{ runtime, base_slug });
        try snapMod.checkText(allocator, snap_slug, desc);
    }
}

pub fn assertInfersOk(
    allocator: std.mem.Allocator,
    src: []const u8,
) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try p.parse(alloc);
    defer program.deinit(alloc);

    var env = Env.init(alloc);
    defer env.deinit();
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, allocator);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));

    _ = inferMod.inferProgram(&env, program) catch |err| {
        if (env.lastError) |te| {
            const desc = try renderTypeError(allocator, src, te);
            defer allocator.free(desc);
            std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
        }
        return err;
    };
}
