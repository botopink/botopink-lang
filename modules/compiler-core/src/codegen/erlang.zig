/// Erlang codegen backend.
///
/// Translates the botopink typed AST to Erlang source.
///
/// Conventions used:
///   - Variables → CamelCase (first letter uppercased)
///   - String literals → <<"...">> binaries
///   - Function bodies → comma-separated expressions; last is return value
///   - OR patterns  → expanded to multiple Erlang case clauses
///   - `return expr` → bare `expr` (Erlang last-expr return)
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const envMod = @import("../comptime/env.zig");
const crossModule = @import("./crossModule.zig");

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;
const CrossModule = crossModule.CrossModule;

fn fnArityNoSelf(f: ast.FnDecl) usize {
    var n: usize = 0;
    for (f.params) |p| {
        if (!std.mem.eql(u8, p.name, "self")) n += 1;
    }
    return n;
}

/// True when a record/struct/enum method is an associated fn — no `self`
/// receiver, so it's callable as `Type.method(...)` (and across modules as a
/// remote call). Its Erlang arity is just `params.len` (no `self` to drop).
fn isAssocMethod(m: ast.InterfaceMethod) bool {
    return m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self");
}

/// How the body of a `forEach` accumulator lambda computes the next value of
/// the captured `acc`, recognized by `classifyFoldStmt`. Each variant carries
/// the AST piece a `lists:foldl/3` fun body is built from (the accumulator is
/// the fun's second parameter, named after `acc`).
const FoldBodyKind = union(enum) {
    /// `acc = expr;` → fun body is `expr`.
    assign: *const ast.Expr,
    /// `acc += expr;` → fun body is `(Acc + expr)`.
    plus_assign: *const ast.Expr,
    /// `acc.push(x);` (mutate-in-place on JS) → fun body is `(Acc ++ [x])`.
    push: *const ast.Expr,
    /// `if (c) { acc = t; } [else { acc = e; }]` → `case c of true -> t; _ -> e|Acc end`.
    if_assign: struct { cond: *const ast.Expr, then_val: *const ast.Expr, else_val: ?*const ast.Expr },
};

/// A `var acc = init;` binding immediately followed by `recv.forEach({ p -> … })`
/// whose lambda body only mutates `acc`. Erlang closures can't rebind a captured
/// variable, so the pair is fused into a single
/// `Acc = lists:foldl(fun(P, Acc) -> <body> end, Init, Recv)` — see
/// `detectFoldFusion`/`emitFoldFusion`.
const FoldFusion = struct {
    acc_name: []const u8,
    init: *const ast.Expr,
    recv: *const ast.Expr,
    param: []const u8,
    body_kind: FoldBodyKind,
};

/// Recognize the single statement of a `forEach` accumulator lambda. Returns
/// `null` for any shape that doesn't reduce to "compute the next `acc`".
fn classifyFoldStmt(stmt: ast.Stmt, acc_name: []const u8) ?FoldBodyKind {
    switch (stmt.expr) {
        .binding => |b| switch (b.kind) {
            .assign => |a| {
                const tgt = switch (a.target) {
                    .name => |n| n,
                    else => return null,
                };
                if (!std.mem.eql(u8, tgt, acc_name)) return null;
                return switch (a.op) {
                    .assign => .{ .assign = a.value },
                    .plusAssign => .{ .plus_assign = a.value },
                };
            },
            else => return null,
        },
        .call => |c| switch (c.kind) {
            .call => |cc| {
                if (!std.mem.eql(u8, cc.callee, "push")) return null;
                if (cc.args.len != 1) return null;
                const recv = cc.receiver orelse return null;
                const rn = identName(recv.*) orelse return null;
                if (!std.mem.eql(u8, rn, acc_name)) return null;
                return .{ .push = cc.args[0].value };
            },
            else => return null,
        },
        .branch => |br| switch (br.kind) {
            .if_ => |if_node| {
                if (if_node.binding != null) return null;
                const then_val = singleAssignValue(if_node.then_, acc_name) orelse return null;
                var else_val: ?*const ast.Expr = null;
                if (if_node.else_) |else_body| {
                    else_val = singleAssignValue(else_body, acc_name) orelse return null;
                }
                return .{ .if_assign = .{ .cond = if_node.cond, .then_val = then_val, .else_val = else_val } };
            },
            else => return null,
        },
        else => return null,
    }
}

/// The RHS of a single `acc = expr;` statement body, or `null`.
fn singleAssignValue(body: []const ast.Stmt, acc_name: []const u8) ?*const ast.Expr {
    if (body.len != 1) return null;
    return switch (classifyFoldStmt(body[0], acc_name) orelse return null) {
        .assign => |e| e,
        else => null,
    };
}

/// The bare identifier name of `expr`, or `null` if it isn't a plain identifier.
fn identName(expr: ast.Expr) ?[]const u8 {
    return switch (expr) {
        .identifier => |id| switch (id.kind) {
            .ident => |n| n,
            else => null,
        },
        else => null,
    };
}

fn isZeroArgMainCallExpr(expr: ast.Expr) bool {
    return switch (expr) {
        .call => |c| switch (c.kind) {
            .call => |cc| !cc.is_builtin and
                cc.receiver == null and
                cc.args.len == 0 and
                cc.trailing.len == 0 and
                std.mem.eql(u8, cc.callee, "main"),
            else => false,
        },
        .jump => |j| switch (j.kind) {
            .@"return" => |r| if (r) |rp| isZeroArgMainCallExpr(rp.*) else false,
            .try_ => |t| if (t) |tp| isZeroArgMainCallExpr(tp.*) else false,
            else => false,
        },
        .collection => |col| switch (col.kind) {
            .grouped => |inner| isZeroArgMainCallExpr(inner.*),
            else => false,
        },
        else => false,
    };
}

fn isSyntheticMainEntrypointCall(v: ast.ValDecl) bool {
    if (std.mem.startsWith(u8, v.name, "_main")) return true;
    return std.mem.startsWith(u8, v.name, "_") and isZeroArgMainCallExpr(v.value.*);
}

// ── public entry ─────────────────────────────────────────────────────────────

pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    // Cross-module link index — lets a consumer resolve an imported record's
    // associated fn to a remote call into the owning module (`http:ok(...)`)
    // and an owner export only the assoc fns another module consumes.
    var cross = try crossModule.build(alloc, outputs);
    defer cross.deinit();

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError => continue,
            .typeError => continue,
            .validationError => |verr| {
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = try alloc.dupe(u8, ""),
                        .comptime_script = null,
                        .comptime_err = verr,
                    },
                });
            },
            .ok => |*ok| {
                // `"std"` package copies are dependencies — never emit their
                // test blocks (mirrors the commonJS rule).
                const module_test_mode = config.test_mode and !std.mem.startsWith(u8, ct.name, "std/");
                const code = try emitErlang(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, ok.instance_lowerings, module_test_mode, &cross);
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = code,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    return results;
}

// ── top-level emitter ─────────────────────────────────────────────────────────

fn emitErlang(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    test_mode: bool,
    cross: ?*const CrossModule,
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();

    var em = Emitter.init(alloc, &aw.writer, comptime_vals, rewrites);
    em.instance_lowerings = instance_lowerings;
    em.test_mode = test_mode;
    em.module_name = module_name;
    em.cross = cross;

    // Test registry entries collected while emitting decls (test mode only).
    const TestEntry = struct { name: ?[]const u8, line: usize, idx: usize };
    var test_entries: std.ArrayListUnmanaged(TestEntry) = .empty;
    defer test_entries.deinit(alloc);
    var test_count: usize = 0;
    if (test_mode) {
        for (program.decls) |decl| {
            if (decl == .@"test") test_count += 1;
        }
    }
    // Names of `implement`/`extend` blocks — a PascalCase call receiver that
    // matches one is a qualified extension call (`PatoNada.swim(d)`), lowered
    // to the bare local function `swim(d)` rather than a remote module call.
    try em.collectExtensionNames(program);
    defer em.ext_names.deinit();
    try em.collectExternals(program);
    defer em.externals.deinit();
    defer em.externals_missing.deinit();
    try em.collectStdImports(program);
    defer em.std_imports.deinit();
    defer em.locals.deinit();
    defer em.top_vals.deinit();
    try em.collectInterfaces(program);
    defer {
        var iface_it = em.interface_assoc.keyIterator();
        while (iface_it.next()) |k| em.alloc.free(k.*);
        em.interface_assoc.deinit();
    }
    try em.collectTypeShapes(program);
    try em.collectImportedTypes(program);
    defer {
        var rf_it = em.record_fields.valueIterator();
        while (rf_it.next()) |names| alloc.free(names.*);
        em.record_fields.deinit();
        em.enum_names.deinit();
        em.enum_variants.deinit();
        em.imported_types.deinit();
    }
    var top_runtime_vals: std.ArrayListUnmanaged(ast.ValDecl) = .empty;
    defer top_runtime_vals.deinit(alloc);
    var has_main_0 = false;
    for (program.decls) |decl| {
        switch (decl) {
            .val => |v| {
                if (!v.value.isComptimeExpr() and !isSyntheticMainEntrypointCall(v)) try top_runtime_vals.append(alloc, v);
            },
            .@"fn" => |f| {
                if (std.mem.eql(u8, f.name, "main") and fnArityNoSelf(f) == 0) has_main_0 = true;
            },
            else => {},
        }
    }
    // Test mode never auto-runs `main/0` — the escript entry is the test runner.
    const emit_entrypoint_wrapper = has_main_0 and !test_mode;

    // Without the wrapper, each runtime module-level `val` is emitted as a 0-arity
    // function (`emitTopVal`), so a bare reference to it lowers to a call `name()`,
    // not a variable. With the wrapper the vals are local `Name = …` bindings, so
    // the set stays empty and references stay variables.
    if (!emit_entrypoint_wrapper) {
        for (top_runtime_vals.items) |v| em.top_vals.put(v.name, {}) catch {};
    }

    // Module header. "std" package modules are named `std/<mod>` for output
    // layout; the Erlang module atom is the basename (`-module(option).`).
    const erl_module_name = if (std.mem.lastIndexOfScalar(u8, module_name, '/')) |i|
        module_name[i + 1 ..]
    else
        module_name;
    try aw.writer.print("-module({s}).\n", .{erl_module_name});

    // Collect public function names for export.
    var pub_fns: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    defer pub_fns.deinit(alloc);
    for (program.decls) |decl| {
        switch (decl) {
            // External fns emit no local definition — nothing to export.
            .@"fn" => |f| if (f.isPub and !f.isExternal()) try pub_fns.append(alloc, f),
            else => {},
        }
    }
    // Export generated entrypoint wrapper when main/0 exists.
    // `main/1` is the escript entry point — escript calls it with the argv list.
    if (emit_entrypoint_wrapper) {
        try aw.writer.writeAll("-export(['_botopink_main'/0, main/1]).\n");
    }
    // Test runner escript entry point.
    if (test_mode and test_count > 0) {
        try aw.writer.writeAll("-export([main/1]).\n");
    }

    // A record/struct/enum whose name another module imports must export its
    // associated fns: the consumer reaches them via a remote call
    // (`http:ok(...)`). Records emit assoc fns as bare local functions (see
    // `emitRecord`), so the owner exports `<fn>/<arity>` for every no-`self`
    // method. Scoped to consumed types → single-module programs are unchanged.
    var assoc_exports: std.ArrayListUnmanaged(struct { name: []const u8, arity: usize }) = .empty;
    defer assoc_exports.deinit(alloc);
    if (cross) |xc| {
        const Collect = struct {
            fn methods(list: *@TypeOf(assoc_exports), a: std.mem.Allocator, ms: []const ast.InterfaceMethod) !void {
                for (ms) |m| {
                    if (m.is_declare or !isAssocMethod(m)) continue;
                    try list.append(a, .{ .name = m.name, .arity = m.params.len });
                }
            }
        };
        for (program.decls) |decl| switch (decl) {
            .record => |r| if (xc.imported.contains(r.name)) try Collect.methods(&assoc_exports, alloc, r.methods),
            .@"enum" => |e| if (xc.imported.contains(e.name)) try Collect.methods(&assoc_exports, alloc, e.methods),
            .@"struct" => |s| if (xc.imported.contains(s.name)) {
                for (s.members) |m| if (m == .method) {
                    if (m.method.is_declare or !isAssocMethod(m.method)) continue;
                    try assoc_exports.append(alloc, .{ .name = m.method.name, .arity = m.method.params.len });
                };
            },
            else => {},
        };
    }

    // Export other public functions + cross-imported associated fns.
    if (pub_fns.items.len > 0 or assoc_exports.items.len > 0) {
        try aw.writer.writeAll("-export([");
        var first = true;
        var exp_buf: [256]u8 = undefined;
        for (pub_fns.items) |f| {
            if (!first) try aw.writer.writeAll(", ");
            first = false;
            try aw.writer.print("{s}/{d}", .{ try fnAtom(f.name, &exp_buf), fnArityNoSelf(f) });
        }
        for (assoc_exports.items) |e| {
            if (!first) try aw.writer.writeAll(", ");
            first = false;
            try aw.writer.print("{s}/{d}", .{ try fnAtom(e.name, &exp_buf), e.arity });
        }
        try aw.writer.writeAll("]).\n");
    }

    // Emit declarations
    for (program.decls) |decl| {
        try aw.writer.writeByte('\n');
        switch (decl) {
            .val => |v| {
                if (emit_entrypoint_wrapper) {
                    if (v.value.isComptimeExpr()) try em.emitTopVal(v, comptime_vals);
                } else {
                    try em.emitTopVal(v, comptime_vals);
                }
            },
            .@"fn" => |f| {
                if (f.isExternal()) {
                    // FFI declaration — calls lower to the remote target directly.
                    if (em.externals.get(f.name)) |ref| {
                        try aw.writer.print("%% external fn {s} -> {s}:{s}\n", .{ f.name, ref.module, ref.symbol });
                    } else {
                        try aw.writer.print("%% external fn {s} (no erlang target)\n", .{f.name});
                    }
                } else {
                    try em.emitFn(f);
                }
            },
            .@"struct" => |s| try em.emitStruct(s),
            .record => |r| try em.emitRecord(r),
            .@"enum" => |e| try em.emitEnum(e),
            .interface => |i| try em.emitInterface(i),
            .implement => |im| try em.emitImplement(im),
            .extend => |ex| try em.emitExtend(ex),
            .use => |u| try em.emitUse(u),
            // `mod` is module-tree metadata; the submodule emits as its own atom.
            .mod => {},
            .delegate => |d| try aw.writer.print("%% delegate {s}\n", .{d.name}),
            // Test blocks are only compiled under `botopink test`; in normal
            // builds they are skipped entirely.
            .@"test" => |t| {
                if (!test_mode) continue;
                const idx = test_entries.items.len;
                try test_entries.append(alloc, .{ .name = t.name, .line = t.loc.line, .idx = idx });
                try em.emitTestFn(t, idx);
            },
            .comment => |c| {
                const prefix = if (c.is_doc) "%%" else if (c.is_module) "%%%" else "%";
                try aw.writer.print("{s} {s}\n", .{ prefix, c.text });
            },
        }
    }

    if (emit_entrypoint_wrapper) {
        try aw.writer.writeByte('\n');
        try aw.writer.writeAll("'_botopink_main'() ->\n");
        const saved_indent = em.indent;
        em.indent = 1;

        for (top_runtime_vals.items) |v| {
            try em.writeIndent();
            try em.emitTopValEntryStmt(v);
            try aw.writer.writeAll(",\n");
        }
        try em.writeIndent();
        try aw.writer.writeAll("main().\n");
        em.indent = saved_indent;

        // escript entry point — `escript <file>` calls main/1 with the argv list.
        try aw.writer.writeByte('\n');
        try aw.writer.writeAll("main(_Args) ->\n");
        try aw.writer.writeAll("    '_botopink_main'().\n");
    }

    // Test mode: emit the registry + runner + escript entry.
    if (test_mode and test_entries.items.len > 0) {
        try aw.writer.writeByte('\n');
        try aw.writer.writeAll(
            \\'__bp_run_one'({Name, Fun, Loc}) ->
            \\    try
            \\        Fun(),
            \\        io:format("  ok   ~s~n", [Name]),
            \\        ok
            \\    catch
            \\        error:{bp_assert, Msg, ALoc} ->
            \\            io:format("  FAIL ~s  (~s)  at ~s~n", [Name, Msg, ALoc]),
            \\            fail;
            \\        Class:Reason ->
            \\            io:format("  FAIL ~s  (~p:~p)  at ~s~n", [Name, Class, Reason, Loc]),
            \\            fail
            \\    end.
            \\
            \\'__bp_run_tests'(Filter) ->
            \\    Tests = [
            \\
        );
        for (test_entries.items, 0..) |t, i| {
            if (i > 0) try aw.writer.writeAll(",\n");
            if (t.name) |n| {
                try aw.writer.print("        {{<<\"{s}\">>, fun '__bp_test_{d}'/0, <<\"{s}.bp:{d}\">>}}", .{ n, t.idx, module_name, t.line });
            } else {
                try aw.writer.print("        {{<<\"test_{d}\">>, fun '__bp_test_{d}'/0, <<\"{s}.bp:{d}\">>}}", .{ t.idx, t.idx, module_name, t.line });
            }
        }
        try aw.writer.writeAll(
            \\
            \\    ],
            \\    Selected = case Filter of
            \\        none -> Tests;
            \\        _ -> [T || {N, _, _} = T <- Tests, binary:match(N, Filter) =/= nomatch]
            \\    end,
            \\    io:format("running ~p tests~n", [length(Selected)]),
            \\    Results = ['__bp_run_one'(T) || T <- Selected],
            \\    Failed = length([R || R <- Results, R =:= fail]),
            \\    Passed = length(Results) - Failed,
            \\    io:format("~p passed, ~p failed~n", [Passed, Failed]),
            \\    case Failed > 0 of true -> halt(1); false -> ok end.
            \\
            \\main(Args) ->
            \\    Filter = case Args of
            \\        [F | _] -> list_to_binary(F);
            \\        _ -> none
            \\    end,
            \\    '__bp_run_tests'(Filter).
            \\
        );
    }

    return aw.toOwnedSlice();
}

// ── helpers ───────────────────────────────────────────────────────────────────

/// Return a heap-allocated copy of `name` with the first byte uppercased.
/// Caller owns the result.
fn erlangVar(alloc: std.mem.Allocator, name: []const u8) ![]u8 {
    if (name.len == 0) return alloc.dupe(u8, name);
    const buf = try alloc.dupe(u8, name);
    buf[0] = std.ascii.toUpper(buf[0]);
    return buf;
}

/// True when `name` looks like a module/type reference (PascalCase) rather than
/// a local variable. A qualified call whose receiver is such a name maps to an
/// Erlang remote call `module:fun(...)`; a lowercase receiver is a value the
/// method is invoked on and is left as-is.
fn isModuleRef(name: []const u8) bool {
    return name.len > 0 and std.ascii.isUpper(name[0]);
}

/// Return a heap-allocated copy of `name` with the first byte lowercased so it
/// is a valid unquoted Erlang module atom (`List` → `list`). Inverse of
/// `erlangVar`. Caller owns the result.
fn erlangModule(alloc: std.mem.Allocator, name: []const u8) ![]u8 {
    if (name.len == 0) return alloc.dupe(u8, name);
    const buf = try alloc.dupe(u8, name);
    buf[0] = std.ascii.toLower(buf[0]);
    return buf;
}

/// Erlang reserved words. A botopink identifier that collides with one of these
/// (e.g. a fn named `of` or `div`, an HTML builder `div`) is a syntactically
/// valid *unquoted* atom lexically, yet the parser rejects it as a bare atom —
/// it must be single-quoted (`'of'`). Used to decide quoting for atoms and
/// function names alike. Source: Erlang reference manual reserved words.
const erlang_reserved = std.StaticStringMap(void).initComptime(.{
    .{"after"}, .{"and"}, .{"andalso"}, .{"band"}, .{"begin"},  .{"bnot"},
    .{"bor"},   .{"bsl"}, .{"bsr"},     .{"bxor"}, .{"case"},   .{"catch"},
    .{"cond"},  .{"div"}, .{"end"},     .{"fun"},  .{"if"},     .{"let"},
    .{"maybe"}, .{"not"}, .{"of"},      .{"or"},   .{"orelse"}, .{"receive"},
    .{"rem"},   .{"try"}, .{"when"},    .{"xor"},
});

fn isErlangReserved(name: []const u8) bool {
    return erlang_reserved.has(name);
}

/// Render `name` as a valid Erlang atom into `buf` — quoted when it is not a
/// valid unquoted atom (must start lowercase; only alnum/`_`/`@` after) or when
/// it collides with a reserved word.
fn atomName(name: []const u8, buf: []u8) ![]const u8 {
    var ok = name.len > 0 and name[0] >= 'a' and name[0] <= 'z' and !isErlangReserved(name);
    if (ok) for (name) |ch| {
        if (!(std.ascii.isAlphanumeric(ch) or ch == '_' or ch == '@')) {
            ok = false;
            break;
        }
    };
    if (ok) return name;
    return std.fmt.bufPrint(buf, "'{s}'", .{name});
}

/// Render `name` as a callable Erlang function atom into `buf`. Function names
/// from botopink are already valid lowercase identifiers, so this only adds the
/// single-quoting a reserved word needs (`of` → `'of'`) and is otherwise a no-op
/// — keeping output byte-identical for every non-reserved name.
fn fnAtom(name: []const u8, buf: []u8) ![]const u8 {
    if (isErlangReserved(name)) return std.fmt.bufPrint(buf, "'{s}'", .{name});
    return name;
}

/// Mangled atom for an interface associated `default fn` (`Array`.`range` →
/// `array_range`). The interface's first char is lowercased so the result is a
/// valid UNQUOTED erlang atom (a PascalCase `Array_range` would need quoting),
/// and the `Interface_` prefix avoids colliding with a consumer's own top-level
/// fn of the same name (a consumer may define its own `range`/`repeat`).
fn interfaceAssocAtom(buf: []u8, iface: []const u8, method: []const u8) ![]const u8 {
    if (iface.len == 0) return std.fmt.bufPrint(buf, "{s}", .{method});
    return std.fmt.bufPrint(buf, "{c}{s}_{s}", .{ std.ascii.toLower(iface[0]), iface[1..], method });
}

/// Tuple positional member (`_0`, `_1`, …) → the digits, else null.
/// Distinguishes tuple index access from `_`-prefixed record fields.
fn tupleIndexMember(member: []const u8) ?[]const u8 {
    if (member.len < 2 or member[0] != '_') return null;
    for (member[1..]) |ch| {
        if (!std.ascii.isDigit(ch)) return null;
    }
    return member[1..];
}

// ── Emitter ───────────────────────────────────────────────────────────────────

const Emitter = struct {
    out: *std.Io.Writer,
    cv: std.StringHashMap([]const u8),
    indent: usize = 0,
    try_seq: usize = 0,
    alloc: std.mem.Allocator,
    /// Static extension dispatch (F6): call-site loc → activated extension symbol.
    /// At these sites `recv.m(args)` lowers to the bare local function `m(Recv, args)`.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Set of `implement`/`extend` block names (for qualified-call dispatch).
    ext_names: std.StringHashMap(void),
    /// `@[external(erlang, "module", "symbol")]` fns: name → remote target.
    /// Calls lower to `module:symbol(Args)`; the decl itself emits nothing.
    externals: std.StringHashMap(ast.ExternalRef),
    /// `@[external(…)]` fns with no `erlang` target — calling one is an error.
    externals_missing: std.StringHashMap(void),
    /// Module names imported via `import {…} from "std"` — a lowercase
    /// receiver naming one lowers to a remote call (`option:map(Args)`).
    std_imports: std.StringHashMap(void),
    /// When true, `emitFn` keeps the `self` parameter (extension methods take
    /// the receiver as an explicit first argument; ordinary fns drop `self`).
    keep_self: bool = false,
    /// `botopink test` compilation: `assert` lowers to a `bp_assert` error the
    /// test runner catches per test instead of a hard `true = (...)` badmatch.
    test_mode: bool = false,
    /// Module name, used for `<module>.bp:<line>` source locations in
    /// test-mode assert failures.
    module_name: []const u8 = "main",
    /// Record/struct constructors: name → ordered field names. A constructor
    /// call (`AppError(code: 1, msg: "x")`) lowers to a map literal
    /// `#{code => 1, msg => <<"x">>}` (mirrors the beam backend's
    /// `put_map_assoc` shape); field access lowers to `maps:get/2`.
    record_fields: std.StringHashMap([]const []const u8),
    /// Enum names → so `EnumName.Variant` access lowers to the variant atom.
    enum_names: std.StringHashMap(void),
    /// Enum variant names (across every enum) → so a bare `.ident` case pattern
    /// (`case o { Lt -> … }`) lowers to the atom `'Lt'`, not an erlang variable
    /// that would shadow-match anything.
    enum_variants: std.StringHashMap(void),
    /// Cross-module link index (null in the standalone path).
    cross: ?*const CrossModule = null,
    /// Imported record/struct name → owning module atom. A qualified call whose
    /// receiver names one (`Response.ok(...)` for an imported `Response`) lowers
    /// to a remote call into the owner (`http:ok(...)`), not a bare local fn.
    imported_types: std.StringHashMap([]const u8),
    /// Value-receiver instance call lowerings (call loc → record/primitive). A
    /// record method lowers to `method(Recv, args)` (or `owner:method(...)` for
    /// an imported type); a primitive method lowers to the erlang host op.
    instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering) = undefined,
    /// Function-scoped local bindings (params, `val`/`var`, lambda params) of the
    /// function currently being emitted. Erlang variables are function-scoped, so
    /// a flat per-function set is exact. A no-receiver call whose callee is a
    /// local lowers to a fun application (`F(args)`), not a bare function call.
    locals: std.StringHashMap(void),
    /// Module-level `val` names emitted as 0-arity functions (library / test
    /// mode, no entrypoint wrapper). A bare reference to one is NOT a variable —
    /// it lowers to the call `name()`. Empty when an entrypoint wrapper binds the
    /// vals as local variables instead.
    top_vals: std.StringHashMap(void),
    /// Interface associated `default fn` qualified names (`"Array.range"`,
    /// `"Pair.of"`). These pure-botopink fns are emitted as bare local functions
    /// (the interface decl is inlined into each consuming module), so an
    /// `Interface.method(...)` call resolves to the local fn, not a remote
    /// `array:range`. Populated by `collectInterfaces`.
    interface_assoc: std.StringHashMap(void),

    fn init(alloc: std.mem.Allocator, out: *std.Io.Writer, cv: std.StringHashMap([]const u8), rewrites: std.AutoHashMap(ast.Loc, []const u8)) Emitter {
        return .{
            .out = out,
            .cv = cv,
            .alloc = alloc,
            .rewrites = rewrites,
            .ext_names = std.StringHashMap(void).init(alloc),
            .externals = std.StringHashMap(ast.ExternalRef).init(alloc),
            .externals_missing = std.StringHashMap(void).init(alloc),
            .std_imports = std.StringHashMap(void).init(alloc),
            .record_fields = std.StringHashMap([]const []const u8).init(alloc),
            .enum_names = std.StringHashMap(void).init(alloc),
            .enum_variants = std.StringHashMap(void).init(alloc),
            .imported_types = std.StringHashMap([]const u8).init(alloc),
            .locals = std.StringHashMap(void).init(alloc),
            .top_vals = std.StringHashMap(void).init(alloc),
            .interface_assoc = std.StringHashMap(void).init(alloc),
        };
    }

    /// Index interface associated `default fn`s (no `self`, with a body) by their
    /// qualified name so `Interface.method(...)` resolves to the bare local fn
    /// `emitInterface` emits.
    fn collectInterfaces(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .interface => |i| {
                for (i.methods) |m| {
                    if (!m.is_default or m.body == null) continue;
                    const has_self = m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self");
                    if (has_self) continue;
                    const qn = try std.fmt.allocPrint(this.alloc, "{s}.{s}", .{ i.name, m.name });
                    try this.interface_assoc.put(qn, {});
                }
            },
            else => {},
        };
    }

    fn isInterfaceAssoc(this: *Emitter, iface: []const u8, method: []const u8) bool {
        var b: [256]u8 = undefined;
        const qn = std.fmt.bufPrint(&b, "{s}.{s}", .{ iface, method }) catch return false;
        return this.interface_assoc.contains(qn);
    }

    /// Mark `name` as a function-scoped local (param / `val` / lambda param).
    fn addLocal(this: *Emitter, name: []const u8) void {
        this.locals.put(name, {}) catch {};
    }

    /// Indexes record/struct field orders + enum names for constructor-call,
    /// field-access, and enum-member lowering.
    fn collectTypeShapes(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .record => |r| {
                var names = try self.alloc.alloc([]const u8, r.fields.len);
                for (r.fields, 0..) |f, i| names[i] = f.name;
                try self.record_fields.put(r.name, names);
            },
            .@"struct" => |s| {
                var count: usize = 0;
                for (s.members) |m| {
                    if (m == .field) count += 1;
                }
                var names = try self.alloc.alloc([]const u8, count);
                var i: usize = 0;
                for (s.members) |m| switch (m) {
                    .field => |f| {
                        names[i] = f.name;
                        i += 1;
                    },
                    else => {},
                };
                try self.record_fields.put(s.name, names);
            },
            .@"enum" => |e| {
                try self.enum_names.put(e.name, {});
                for (e.variants) |v| try self.enum_variants.put(v.name, {});
            },
            else => {},
        };
    }

    /// Registers types this module imports `from "<pkg>"` (resolved via the
    /// cross-module index). An imported record/struct joins `record_fields` so a
    /// construction (`App(8080, "/")`) inlines the same `#{…}` map the owner
    /// would build, and `imported_types` so an associated-fn call
    /// (`Response.ok(...)`) lowers to a remote call into the owner module.
    /// Imported enums join `enum_names` (their tagged-tuple / atom shape is
    /// module-independent). No-op without a cross index (standalone path).
    fn collectImportedTypes(self: *Emitter, program: ast.Program) !void {
        const xc = self.cross orelse return;
        for (program.decls) |decl| switch (decl) {
            .use => |u| for (u.imports) |imp| {
                const name = imp.name();
                const info = xc.exports.get(name) orelse continue;
                const owner = crossModule.moduleBasename(info.module);
                switch (info.kind) {
                    .record, .@"struct" => {
                        if (!self.record_fields.contains(name)) {
                            const fields = try self.alloc.dupe([]const u8, info.fields);
                            try self.record_fields.put(name, fields);
                        }
                        try self.imported_types.put(name, owner);
                    },
                    .@"enum" => try self.enum_names.put(name, {}),
                    .@"fn", .val => {},
                }
            },
            else => {},
        };
    }

    /// Records every module name imported from the "std" package.
    fn collectStdImports(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .use => |u| {
                const from_std = switch (u.source) {
                    .module => |m| std.mem.eql(u8, m, "std"),
                    .root => false,
                };
                if (!from_std) continue;
                for (u.imports) |imp| {
                    try this.std_imports.put(imp.segments[imp.segments.len - 1], {});
                }
            },
            else => {},
        };
    }

    fn collectExtensionNames(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .implement => |im| try this.ext_names.put(im.name, {}),
            .extend => |ex| try this.ext_names.put(ex.name, {}),
            else => {},
        };
    }

    /// Indexes every `@[external(…)]` fn by name: with an `erlang` target it
    /// goes to `externals`; without one it goes to `externals_missing` (so a
    /// call can fail with a clear error instead of an undefined function).
    fn collectExternals(this: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (!f.isExternal()) continue;
                if (f.externalFor("erlang")) |ref| {
                    try this.externals.put(f.name, ref);
                } else {
                    try this.externals_missing.put(f.name, {});
                }
            },
            else => {},
        };
    }

    fn w(this: *Emitter, s: []const u8) !void {
        try this.out.writeAll(s);
    }

    fn fmt(this: *Emitter, comptime f: []const u8, args: anytype) !void {
        try this.out.print(f, args);
    }

    fn writeIndent(this: *Emitter) !void {
        for (0..this.indent) |_| try this.w("    ");
    }

    // ── top-level val ─────────────────────────────────────────────────────────

    fn emitTopVal(this: *Emitter, v: ast.ValDecl, cv: std.StringHashMap([]const u8)) !void {
        if (v.value.isComptimeExpr()) {
            _ = cv;
            try this.fmt("%% comptime val {s}\n", .{v.name});
            return;
        }
        // Emit as a 0-arity function when there is no script wrapper entrypoint.
        try this.fmt("{s}() ->\n", .{v.name});
        const saved = this.indent;
        this.indent = 1;
        try this.writeIndent();
        try this.emitExpr(v.value.*);
        this.indent = saved;
        try this.w(".\n");
    }

    fn emitTopValEntryStmt(this: *Emitter, v: ast.ValDecl) !void {
        const synthetic_runtime_stmt = std.mem.startsWith(u8, v.name, "_");
        if (synthetic_runtime_stmt) {
            try this.emitExpr(v.value.*);
            return;
        }
        const vname = try erlangVar(this.alloc, v.name);
        defer this.alloc.free(vname);
        try this.fmt("{s} = ", .{vname});
        try this.emitExpr(v.value.*);
    }

    // ── fn ────────────────────────────────────────────────────────────────────

    /// True when the body is a flat sequence of `yield` statements (a simple
    /// finite generator that lowers to an eager Erlang list).
    fn isPlainYieldGenerator(f: ast.FnDecl) bool {
        if (f.effect == null or f.body.len == 0) return false;
        for (f.body) |stmt| {
            if (!(stmt.expr == .jump and stmt.expr.jump.kind == .yield)) return false;
        }
        return true;
    }

    fn emitFn(this: *Emitter, f: ast.FnDecl) !void {
        // An effect fn is async/generator — except `#[@result]` (checked-Result
        // effect), which is a plain function. Erlang is eager: a `@Future<T>`
        // resolves to `T` (so `await` is identity) and a finite `@Iterator<T>`
        // is a list.
        if (f.effect != null and f.effect.? != .result) {
            try this.fmt("%% *fn (async/generator) — eager lowering\n", .{});
        }
        // Fresh local scope for this function (erlang vars are function-scoped).
        this.locals.clearRetainingCapacity();
        var fn_buf: [256]u8 = undefined;
        try this.w(try fnAtom(f.name, &fn_buf));
        try this.w("(");
        var first = true;
        for (f.params) |p| {
            if (p.destruct) |d| {
                switch (d) {
                    .names => |*n| {
                        if (!first) try this.w(", ");
                        try this.w("{");
                        for (n.fields, 0..) |fld, i| {
                            if (i > 0) try this.w(", ");
                            const vname = try erlangVar(this.alloc, fld.bind_name);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                            this.addLocal(fld.bind_name);
                        }
                        if (n.hasSpread) try this.w(", _");
                        try this.w("}");
                        first = false;
                    },
                    .tuple_ => |t| {
                        if (!first) try this.w(", ");
                        try this.w("{");
                        for (t, 0..) |nm, i| {
                            if (i > 0) try this.w(", ");
                            const vname = try erlangVar(this.alloc, nm);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                            this.addLocal(nm);
                        }
                        try this.w("}");
                        first = false;
                    },
                    .list => {}, // List pattern — placeholder
                    .ctor => {}, // Constructor pattern — placeholder
                }
            } else if (this.keep_self or !std.mem.eql(u8, p.name, "self")) {
                if (!first) try this.w(", ");
                const vname = try erlangVar(this.alloc, p.name);
                defer this.alloc.free(vname);
                try this.w(vname);
                this.addLocal(p.name);
                first = false;
            }
        }
        try this.w(") ->\n");
        const saved = this.indent;
        this.indent = 1;
        this.try_seq = 0;
        if (isPlainYieldGenerator(f)) {
            // Finite generator → eager list of yielded items: `[V1, V2, ...]`.
            try this.writeIndent();
            try this.w("[");
            for (f.body, 0..) |stmt, i| {
                if (i > 0) try this.w(", ");
                if (stmt.expr.jump.kind.yield.value) |val| try this.emitExpr(val.*);
            }
            try this.w("]");
        } else {
            try this.emitBody(f.body);
        }
        this.indent = saved;
        try this.w(".\n");
    }

    /// Emit a `test { … }` body as `'__bp_test_<idx>'() -> Body.`
    /// Same body emission as `emitFn` — no params, exported via the runner.
    fn emitTestFn(this: *Emitter, t: ast.TestDecl, idx: usize) !void {
        try this.fmt("'__bp_test_{d}'() ->\n", .{idx});
        const saved = this.indent;
        this.indent = 1;
        this.try_seq = 0;
        try this.emitBody(t.body);
        this.indent = saved;
        try this.w(".\n");
    }

    /// `try expr` (no catch) at body position → propagate `{error, E}` by nesting
    /// the rest of the body inside the `{ok, V}` arm. Returns the inner expr.
    fn propagateTryInner(e: ast.Expr) ?ast.Expr {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                .try_ => |t| if (t) |i| i.* else null,
                else => null,
            },
            else => null,
        };
    }

    // ── body (comma-separated stmts; does NOT emit trailing newline) ──────────
    //
    // Callers are responsible for the terminator that follows on the same line:
    //   emitFn  → ".\n"
    //   fun end → "\nINDENT end"

    fn emitBody(this: *Emitter, body: []const ast.Stmt) !void {
        try this.emitBodyFrom(body, 0);
    }

    /// Emit statements `body[start..]`. A `try` without `catch` short-circuits:
    /// it lowers to `case Inner of {ok, V} -> <rest>; {error, E} -> {error, E} end`,
    /// nesting every following statement inside the Ok arm (Erlang has no early
    /// return), so the Error variant propagates up as the function's value.
    fn emitBodyFrom(this: *Emitter, body: []const ast.Stmt, start: usize) anyerror!void {
        // The body's tail (last value) and comma-joining key off the last *real*
        // statement, so trailing comments neither become the tail nor strand a
        // dangling `,` before the closing `end`/`.`.
        const last_real = lastRealStmt(body);
        var i = start;
        while (i < body.len) : (i += 1) {
            const stmt = body[i];
            const is_last = if (last_real) |lr| (i == lr) else (i == body.len - 1);

            // Detect `[val name =] try inner` (no catch) at this position.
            const prop: ?struct { inner: ast.Expr, head: TryHead } = switch (stmt.expr) {
                .binding => |b| switch (b.kind) {
                    .localBind => |lb| if (propagateTryInner(lb.value.*)) |inner|
                        .{ .inner = inner, .head = .{ .name = lb.name } }
                    else
                        null,
                    .localBindDestruct => |lb| if (propagateTryInner(lb.value.*)) |inner|
                        .{ .inner = inner, .head = .{ .destruct = lb.pattern } }
                    else
                        null,
                    else => null,
                },
                .jump => |j| switch (j.kind) {
                    .try_ => |t| if (t) |inner|
                        .{ .inner = inner.*, .head = .none }
                    else
                        null,
                    .@"return" => |r| if (r) |rv| if (propagateTryInner(rv.*)) |inner|
                        .{ .inner = inner, .head = .none }
                    else
                        null else null,
                    else => null,
                },
                else => null,
            };

            if (prop) |p| {
                try this.writeIndent();
                try this.emitPropagateTry(body, i, p.inner, p.head);
                return; // remaining statements are nested inside the Ok arm
            }

            // `if` whose then-branch ends in `return` and that has following
            // statements: Erlang has no early return, so nest the rest of the
            // body inside the false arm (mirrors the propagate-try nesting).
            if (!is_last and stmt.expr == .branch and stmt.expr.branch.kind == .if_) {
                const if_node = stmt.expr.branch.kind.if_;
                if (if_node.binding == null and if_node.else_ == null and bodyEndsWithReturn(if_node.then_)) {
                    try this.writeIndent();
                    try this.emitEarlyReturnIf(body, i, if_node);
                    return; // remaining statements are nested inside the false arm
                }
            }

            // `var acc = init;` + `recv.forEach({ p -> <mutate acc> })`: fuse
            // into a single `lists:foldl` (Erlang closures can't rebind a
            // captured var). Consumes both statements.
            if (!is_last) {
                if (this.detectFoldFusion(body, i)) |ff| {
                    try this.writeIndent();
                    try this.emitFoldFusion(ff);
                    if (i + 1 != body.len - 1) {
                        const real_follows = if (last_real) |lr| (i + 1 < lr) else false;
                        try this.w(if (real_follows) ",\n" else "\n");
                    }
                    i += 1; // also consume the forEach statement
                    continue;
                }
            }

            try this.writeIndent();
            try this.emitBodyStmt(stmt, is_last);
            // A real statement takes a trailing `,` only when another real
            // statement follows; comments (and the tail) get a bare newline.
            if (i != body.len - 1) {
                const real_follows = if (last_real) |lr| (!isCommentStmt(stmt) and i < lr) else false;
                try this.w(if (real_follows) ",\n" else "\n");
            }
        }

        // Erlang has no empty body: a `fun`, clause or function must end in an
        // expression (`fun(X) -> end` is a syntax error). When `body[start..]`
        // contributes no real statement — empty, or comments only — the tail
        // value is `undefined` (mirrors how an absent value lowers elsewhere).
        const has_real = blk: {
            var k = start;
            while (k < body.len) : (k += 1) {
                if (!isCommentStmt(body[k])) break :blk true;
            }
            break :blk false;
        };
        if (!has_real) {
            if (start < body.len) try this.w("\n"); // separate from emitted comments
            try this.writeIndent();
            try this.w("undefined");
        } else if (body.len > start and isCommentStmt(body[body.len - 1])) {
            // A trailing comment ends the body on a `%`-line; the caller's
            // terminator (`.` for a clause, `end` for a fun) would be swallowed
            // by it. Break to a fresh indented line so it lands cleanly.
            try this.w("\n");
            try this.writeIndent();
        }
    }

    /// Match `var acc = init;` at `body[i]` immediately followed by
    /// `recv.forEach({ p -> … })` at `body[i+1]` whose lambda body only mutates
    /// `acc`. Returns the fusion plan, or `null` if the shape doesn't match.
    fn detectFoldFusion(this: *Emitter, body: []const ast.Stmt, i: usize) ?FoldFusion {
        _ = this;
        if (i + 1 >= body.len) return null;

        const bind = switch (body[i].expr) {
            .binding => |b| switch (b.kind) {
                .localBind => |lb| lb,
                else => return null,
            },
            else => return null,
        };
        if (!bind.mutable) return null;

        const cc = switch (body[i + 1].expr) {
            .call => |c| switch (c.kind) {
                .call => |call| call,
                else => return null,
            },
            else => return null,
        };
        if (cc.receiver == null) return null;
        if (!std.mem.eql(u8, cc.callee, "forEach")) return null;

        // The action lambda may arrive as a parenthesized arg (`forEach({…})`)
        // or as a trailing block (`forEach { … }`).
        var lam_params: []const []const u8 = undefined;
        var lam_body: []const ast.Stmt = undefined;
        if (cc.args.len == 1 and cc.trailing.len == 0) {
            switch (cc.args[0].value.*) {
                .function => |fe| {
                    lam_params = fe.kind.params;
                    lam_body = fe.kind.body;
                },
                else => return null,
            }
        } else if (cc.args.len == 0 and cc.trailing.len == 1) {
            lam_params = cc.trailing[0].params;
            lam_body = cc.trailing[0].body;
        } else return null;
        if (lam_params.len != 1) return null;
        if (lam_body.len != 1) return null;

        const bk = classifyFoldStmt(lam_body[0], bind.name) orelse return null;
        return .{
            .acc_name = bind.name,
            .init = bind.value,
            .recv = cc.receiver.?,
            .param = lam_params[0],
            .body_kind = bk,
        };
    }

    /// Emit `Acc = lists:foldl(fun(P, Acc) -> <body> end, Init, Recv)`. The
    /// accumulator reuses its source name as the fun's second parameter so the
    /// body's reads of `acc` resolve to the per-iteration value.
    fn emitFoldFusion(this: *Emitter, ff: FoldFusion) anyerror!void {
        const acc_var = try erlangVar(this.alloc, ff.acc_name);
        defer this.alloc.free(acc_var);
        const p_var = try erlangVar(this.alloc, ff.param);
        defer this.alloc.free(p_var);
        this.addLocal(ff.acc_name);
        this.addLocal(ff.param);
        try this.fmt("{s} = lists:foldl(fun({s}, {s}) ->\n", .{ acc_var, p_var, acc_var });
        const saved = this.indent;
        this.indent = saved + 1;
        try this.writeIndent();
        try this.emitFoldBody(ff.body_kind, acc_var);
        this.indent = saved;
        try this.w("\n");
        try this.writeIndent();
        try this.w("end, ");
        try this.emitExpr(ff.init.*);
        try this.w(", ");
        try this.emitExpr(ff.recv.*);
        try this.w(")");
    }

    fn emitFoldBody(this: *Emitter, bk: FoldBodyKind, acc_var: []const u8) anyerror!void {
        switch (bk) {
            .assign => |e| try this.emitExpr(e.*),
            .plus_assign => |e| {
                try this.fmt("({s} + ", .{acc_var});
                try this.emitExpr(e.*);
                try this.w(")");
            },
            .push => |e| {
                try this.fmt("({s} ++ [", .{acc_var});
                try this.emitExpr(e.*);
                try this.w("])");
            },
            .if_assign => |ia| {
                try this.w("case ");
                try this.emitExpr(ia.cond.*);
                try this.w(" of\n");
                this.indent += 1;
                try this.writeIndent();
                try this.w("true -> ");
                try this.emitExpr(ia.then_val.*);
                try this.w(";\n");
                try this.writeIndent();
                try this.w("_ -> ");
                if (ia.else_val) |ev| try this.emitExpr(ev.*) else try this.w(acc_var);
                this.indent -= 1;
                try this.w("\n");
                try this.writeIndent();
                try this.w("end");
            },
        }
    }

    /// True when the last statement of a branch body is a valued `return`.
    /// A statement that is only a source comment (`.literal.comment`). Comments
    /// are not Erlang expressions: they never take a `,` separator and must not
    /// be treated as the body's tail value.
    fn isCommentStmt(stmt: ast.Stmt) bool {
        return switch (stmt.expr) {
            .literal => |lit| switch (lit.kind) {
                .comment => true,
                else => false,
            },
            else => false,
        };
    }

    /// Index of the last non-comment statement in `body`, or `null` when every
    /// statement is a comment. The comma-joining of a body keys off this: a real
    /// statement gets a trailing `,` only when another real statement follows, so
    /// trailing comments never strand a dangling comma before `end`/`.`.
    fn lastRealStmt(body: []const ast.Stmt) ?usize {
        var i = body.len;
        while (i > 0) {
            i -= 1;
            if (!isCommentStmt(body[i])) return i;
        }
        return null;
    }

    fn bodyEndsWithReturn(body: []const ast.Stmt) bool {
        if (body.len == 0) return false;
        return switch (body[body.len - 1].expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| r != null,
                else => false,
            },
            else => false,
        };
    }

    /// Emit `case Cond of true -> <then-body>; _ -> <body[i+1..]> end` for an
    /// `if` that early-returns, nesting the remaining statements in the false arm.
    fn emitEarlyReturnIf(this: *Emitter, body: []const ast.Stmt, i: usize, if_node: anytype) anyerror!void {
        try this.w("case ");
        try this.emitExpr(if_node.cond.*);
        try this.w(" of\n");
        this.indent += 1;
        try this.writeIndent();
        try this.w("true ->\n");
        this.indent += 1;
        try this.emitBranchBody(if_node.then_);
        this.indent -= 1;
        try this.w(";\n");
        try this.writeIndent();
        try this.w("_ ->\n");
        this.indent += 1;
        try this.emitBodyFrom(body, i + 1);
        this.indent -= 2;
        try this.w("\n");
        try this.writeIndent();
        try this.w("end");
    }

    const TryHead = union(enum) {
        name: []const u8,
        destruct: ast.ParamDestruct,
        none,
    };

    /// Emit the propagating `case` for a `try` at `body[i]`, nesting `body[i+1..]`
    /// inside the `{ok, _}` arm.
    fn emitPropagateTry(this: *Emitter, body: []const ast.Stmt, i: usize, inner: ast.Expr, head: TryHead) !void {
        const n = this.try_seq;
        this.try_seq += 1;

        try this.w("case ");
        try this.emitExpr(inner);
        try this.w(" of\n");
        this.indent += 1;
        try this.writeIndent();

        // {ok, <bind>} ->
        try this.w("{ok, ");
        switch (head) {
            .name => |nm| {
                const vname = try erlangVar(this.alloc, nm);
                defer this.alloc.free(vname);
                try this.w(vname);
            },
            .destruct => |pat| try this.emitDestructPattern(pat),
            .none => try this.fmt("_TryV{d}", .{n}),
        }
        try this.w("} ->\n");

        this.indent += 1;
        if (i + 1 < body.len) {
            try this.emitBodyFrom(body, i + 1);
        } else {
            // No continuation: the Ok value is the function's result.
            try this.writeIndent();
            switch (head) {
                .name => |nm| {
                    const vname = try erlangVar(this.alloc, nm);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                },
                else => try this.fmt("_TryV{d}", .{n}),
            }
        }
        this.indent -= 1;
        try this.w(";\n");
        try this.writeIndent();
        try this.fmt("{{error, _TryE{d}}} -> {{error, _TryE{d}}}\n", .{ n, n });
        this.indent -= 1;
        try this.writeIndent();
        try this.w("end");
    }

    /// Render a destructuring pattern (tuple/record names) as an Erlang pattern.
    fn emitDestructPattern(this: *Emitter, pattern: ast.ParamDestruct) !void {
        switch (pattern) {
            .names => |n| {
                try this.w("{");
                for (n.fields, 0..) |fld, k| {
                    if (k > 0) try this.w(", ");
                    const vname = try erlangVar(this.alloc, fld.bind_name);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                }
                if (n.hasSpread) try this.w(", _");
                try this.w("}");
            },
            .tuple_ => |t| {
                try this.w("{");
                for (t, 0..) |nm, k| {
                    if (k > 0) try this.w(", ");
                    const vname = try erlangVar(this.alloc, nm);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                }
                try this.w("}");
            },
            .list, .ctor => try this.w("_"),
        }
    }

    /// Emit a statement inside a function body.
    /// When `is_last` is true, `return expr` is emitted as bare `expr`.
    fn emitBodyStmt(this: *Emitter, stmt: ast.Stmt, is_last: bool) !void {
        const e = stmt.expr;
        switch (e) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    // In Erlang the last expression is the return value.
                    // Emit a bare expression; if not last, wrap in a noop binding.
                    _ = is_last;
                    if (r) |val| try this.emitExpr(val.*) else try this.w("undefined");
                },
                else => try this.emitExpr(e),
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    const vname = try erlangVar(this.alloc, lb.name);
                    defer this.alloc.free(vname);
                    this.addLocal(lb.name);
                    try this.fmt("{s} = ", .{vname});
                    try this.emitExpr(lb.value.*);
                },
                .assign => |a| {
                    switch (a.target) {
                        .name => |name| {
                            const vname = try erlangVar(this.alloc, name);
                            defer this.alloc.free(vname);
                            switch (a.op) {
                                .assign => try this.fmt("{s} = ", .{vname}),
                                .plusAssign => try this.fmt("{s} = {s} + ", .{ vname, vname }),
                            }
                            try this.emitExpr(a.value.*);
                        },
                        .fieldAccess => |*fa| {
                            _ = fa;
                            try this.w("%% field assignment is not directly supported in Erlang");
                        },
                    }
                },
                .localBindDestruct => |lb| {
                    switch (lb.pattern) {
                        .names => |*n| {
                            try this.w("{");
                            for (n.fields, 0..) |fld, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, fld.bind_name);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            if (n.hasSpread) try this.w(", _");
                            try this.w("} = ");
                        },
                        .tuple_ => |t| {
                            try this.w("{");
                            for (t, 0..) |nm, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, nm);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            try this.w("} = ");
                        },
                        .list => {}, // List pattern — placeholder
                        .ctor => {}, // Constructor pattern — placeholder
                    }
                    try this.emitExpr(lb.value.*);
                },
            },
            else => try this.emitExpr(e),
        }
    }

    // ── expressions ──────────────────────────────────────────────────────────

    fn emitBinaryOp(this: *Emitter, op: []const u8, lhs: *ast.Expr, rhs: *ast.Expr) !void {
        try this.w("(");
        try this.emitExpr(lhs.*);
        try this.w(" ");
        try this.w(op);
        try this.w(" ");
        try this.emitExpr(rhs.*);
        try this.w(")");
    }

    /// Emit the inline Erlang form for a lowered `@Result`/`@Option` method op.
    /// `args[0]` is the receiver; `args[1]` (when present) the fn/default value.
    /// A fun binds the receiver once (so chains don't re-evaluate it). Result
    /// values use the idiomatic OTP `{ok, V} | {error, E}` shape; absent options
    /// are `undefined`.
    fn emitResultOptionOp(this: *Emitter, callee: []const u8, args: []const ast.CallArg) anyerror!void {
        const recv = args[0].value;
        const arg1: ?*ast.Expr = if (args.len > 1) args[1].value else null;

        if (std.mem.eql(u8, callee, "__bp_ok")) {
            // Result constructor: `return v` in a `-> @Result<…>` fn.
            try this.w("{ok, ");
            try this.emitExpr(recv.*);
            try this.w("}");
            return;
        } else if (std.mem.eql(u8, callee, "__bp_error")) {
            // Result constructor: `throw e` in a `-> @Result<…>` fn.
            try this.w("{error, ");
            try this.emitExpr(recv.*);
            try this.w("}");
            return;
        } else if (std.mem.eql(u8, callee, "__bp_result_map")) {
            try this.w("(fun(R) -> case R of {ok, V} -> {ok, (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w(")(V)}; _ -> R end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_result_flatMap")) {
            try this.w("(fun(R) -> case R of {ok, V} -> (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w(")(V); _ -> R end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_result_unwrapOr")) {
            try this.w("(fun(R) -> case R of {ok, V} -> V; _ -> (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w(") end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_result_isOk")) {
            try this.w("(fun(R) -> case R of {ok, _} -> true; _ -> false end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_result_isError")) {
            try this.w("(fun(R) -> case R of {error, _} -> true; _ -> false end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_option_map") or std.mem.eql(u8, callee, "__bp_option_flatMap")) {
            try this.w("(fun(O) -> case O of undefined -> undefined; V -> (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w(")(V) end end)(");
        } else if (std.mem.eql(u8, callee, "__bp_option_unwrapOr")) {
            try this.w("(fun(O) -> case O of undefined -> (");
            if (arg1) |a| try this.emitExpr(a.*);
            try this.w("); V -> V end end)(");
        } else {
            return;
        }
        try this.emitExpr(recv.*);
        try this.w(")");
    }

    fn emitExpr(this: *Emitter, e: ast.Expr) anyerror!void {
        switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| try this.w(n),
                .comment => |c| {
                    const prefix = switch (c.kind) {
                        .normal => "%",
                        .doc => "%%",
                        .module => "%%%",
                    };
                    try this.fmt("{s} {s}", .{ prefix, c.text });
                },
                .stringLit => |s| try this.emitBinary(s),
                // Desugared to a `+` chain by the transform pass; never reaches codegen.
                .stringTemplate => unreachable,
                .null_ => try this.w("undefined"),
            },

            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    // Boolean literals are env-bound identifiers in botopink —
                    // they must stay lowercase atoms, never `True`/`False` vars.
                    if (std.mem.eql(u8, n, "true") or std.mem.eql(u8, n, "false")) {
                        try this.w(n);
                    } else if (!this.locals.contains(n) and this.top_vals.contains(n)) {
                        // A module-level `val` emitted as a 0-arity function: a bare
                        // reference is the call `name()`, not a variable. A local of
                        // the same name shadows it (handled by the `locals` check).
                        var fb: [256]u8 = undefined;
                        try this.fmt("{s}()", .{try fnAtom(n, &fb)});
                    } else {
                        const vname = try erlangVar(this.alloc, n);
                        defer this.alloc.free(vname);
                        try this.w(vname);
                    }
                },
                .identAccess => |ia| {
                    // Qualified enum member: `Order.Lt` → the variant atom.
                    if (ia.receiver.* == .identifier and ia.receiver.*.identifier.kind == .ident and
                        this.enum_names.contains(ia.receiver.*.identifier.kind.ident))
                    {
                        var tag_buf: [128]u8 = undefined;
                        try this.w(try atomName(ia.member, &tag_buf));
                        return;
                    }
                    // Tuple index access: `t._N` → `element(N+1, T)` (1-based).
                    if (tupleIndexMember(ia.member)) |digits| {
                        const idx = std.fmt.parseInt(usize, digits, 10) catch 0;
                        if (ia.optional) {
                            const n = this.try_seq;
                            this.try_seq += 1;
                            try this.fmt("(fun(undefined) -> undefined; (_Opt{d}) -> element({d}, _Opt{d}) end)(", .{ n, idx + 1, n });
                            try this.emitExpr(ia.receiver.*);
                            try this.w(")");
                        } else {
                            try this.fmt("element({d}, ", .{idx + 1});
                            try this.emitExpr(ia.receiver.*);
                            try this.w(")");
                        }
                        return;
                    }
                    // `arr.length` / `s.length` / `arr.len` recorded by inference
                    // as a primitive field access → the host length op, not a
                    // map read (`maps:get(length, …)` would crash on a list).
                    if (this.instance_lowerings.get(id.loc)) |il| switch (il) {
                        .prim => |k| {
                            switch (k) {
                                .string => try this.w("string:length("),
                                else => try this.w("length("),
                            }
                            try this.emitExpr(ia.receiver.*);
                            try this.w(")");
                            return;
                        },
                        .record => {},
                    };
                    // Record/struct field access — records are maps at runtime.
                    // Optional chaining (`a?.b`) guards on `undefined`.
                    if (ia.optional) {
                        const n = this.try_seq;
                        this.try_seq += 1;
                        var ab1: [128]u8 = undefined;
                        try this.fmt("(fun(undefined) -> undefined; (_Opt{d}) -> maps:get({s}, _Opt{d}) end)(", .{ n, try atomName(ia.member, &ab1), n });
                        try this.emitExpr(ia.receiver.*);
                        try this.w(")");
                    } else {
                        var ab2: [128]u8 = undefined;
                        try this.fmt("maps:get({s}, ", .{try atomName(ia.member, &ab2)});
                        try this.emitExpr(ia.receiver.*);
                        try this.w(")");
                    }
                },
                .dotIdent => |n| try this.fmt("{s}", .{n}),
            },

            .binaryOp => |bin| switch (bin.op) {
                .add => try this.emitBinaryOp("+", bin.lhs, bin.rhs),
                .sub => try this.emitBinaryOp("-", bin.lhs, bin.rhs),
                .mul => try this.emitBinaryOp("*", bin.lhs, bin.rhs),
                .div => try this.emitBinaryOp("div", bin.lhs, bin.rhs),
                .mod => try this.emitBinaryOp("rem", bin.lhs, bin.rhs),
                .lt => try this.emitBinaryOp("<", bin.lhs, bin.rhs),
                .gt => try this.emitBinaryOp(">", bin.lhs, bin.rhs),
                .lte => try this.emitBinaryOp("=<", bin.lhs, bin.rhs),
                .gte => try this.emitBinaryOp(">=", bin.lhs, bin.rhs),
                .eq => try this.emitBinaryOp("=:=", bin.lhs, bin.rhs),
                .ne => try this.emitBinaryOp("=/=", bin.lhs, bin.rhs),
                .@"and" => try this.emitBinaryOp("and", bin.lhs, bin.rhs),
                .@"or" => try this.emitBinaryOp("or", bin.lhs, bin.rhs),
            },

            .unaryOp => |un| switch (un.op) {
                .not => {
                    try this.w("(not ");
                    try this.emitExpr(un.expr.*);
                    try this.w(")");
                },
                .neg => {
                    try this.w("(-");
                    try this.emitExpr(un.expr.*);
                    try this.w(")");
                },
            },

            .call => |c| switch (c.kind) {
                .pipeline => |b| {
                    // Flatten the pipeline chain
                    var items: std.ArrayList(ast.Expr) = .empty;
                    defer items.deinit(this.alloc);
                    try items.append(this.alloc, b.lhs.*);
                    var current = b.rhs.*;
                    while (true) {
                        switch (current) {
                            .call => |cc| switch (cc.kind) {
                                .pipeline => |p| {
                                    try items.append(this.alloc, p.lhs.*);
                                    current = p.rhs.*;
                                    continue;
                                },
                                else => {},
                            },
                            else => {},
                        }
                        break;
                    }
                    try items.append(this.alloc, current);

                    // Emit as nested calls: last(...(first))
                    var i: usize = items.items.len - 1;
                    while (i > 0) : (i -= 1) {
                        try this.emitExpr(items.items[i]);
                        try this.w("(");
                    }
                    try this.emitExpr(items.items[0]);
                    i = items.items.len - 1;
                    while (i > 0) : (i -= 1) {
                        try this.w(")");
                    }
                },

                .call => |cc| {
                    if (cc.is_builtin) {
                        if (std.mem.eql(u8, cc.callee, "print")) {
                            // @print(arg1, arg2, ...) becomes io:format("~p~n", [arg1, arg2, ...])
                            try this.w("io:format(\"~p~n\", [");
                            var first = true;
                            for (cc.args) |arg| {
                                if (!first) try this.w(", ");
                                try this.emitExpr(arg.value.*);
                                first = false;
                            }
                            try this.w("])");
                            return;
                        }
                        if (std.mem.eql(u8, cc.callee, "todo")) {
                            try this.w("erlang:error({todo, ");
                            if (cc.args.len > 0) {
                                try this.emitExpr(cc.args[0].value.*);
                            } else {
                                try this.w("\"not implemented\"");
                            }
                            try this.w("})");
                            return;
                        }
                        if (std.mem.eql(u8, cc.callee, "panic")) {
                            try this.w("erlang:error({panic, ");
                            if (cc.args.len > 0) {
                                try this.emitExpr(cc.args[0].value.*);
                            } else {
                                try this.w("\"panic\"");
                            }
                            try this.w("})");
                            return;
                        }
                        if (std.mem.eql(u8, cc.callee, "block")) {
                            // @block { ... } emits an immediately-invoked fun
                            // so the body executes and its value is the call result.
                            if (cc.args.len == 1) {
                                const arg = cc.args[0].value;
                                const isFunction = switch (arg.*) {
                                    .function => true,
                                    else => false,
                                };
                                if (!isFunction) return error.InvalidArgs;
                                try this.w("(fun() ->\n");
                                this.indent += 1;
                                try this.emitExpr(arg.*);
                                this.indent -= 1;
                                try this.w("\n");
                                try this.writeIndent();
                                try this.w("end)()");
                                return;
                            } else if (cc.trailing.len == 1 and cc.trailing[0].params.len == 0) {
                                // @block { body } - trailing lambda with no params
                                try this.w("(fun() ->\n");
                                this.indent += 1;
                                try this.emitBody(cc.trailing[0].body);
                                this.indent -= 1;
                                try this.w("\n");
                                try this.writeIndent();
                                try this.w("end)()");
                                return;
                            } else {
                                return error.InvalidArgs;
                            }
                        }
                        if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
                            try this.emitResultOptionOp(cc.callee, cc.args);
                            return;
                        }
                        var callee_buf: [256]u8 = undefined;
                        try this.fmt("{s}(", .{try fnAtom(cc.callee, &callee_buf)});
                        var first = true;
                        for (cc.args) |arg| {
                            if (!first) try this.w(", ");
                            try this.emitExpr(arg.value.*);
                            first = false;
                        }
                        // Trailing lambdas: emit as fun args
                        for (cc.trailing) |tl| {
                            if (!first) try this.w(", ");
                            first = false;
                            try this.w("fun(");
                            for (tl.params, 0..) |p, pi| {
                                if (pi > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, p);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                                this.addLocal(p);
                            }
                            try this.w(") ->\n");
                            const tl_saved = this.indent;
                            this.indent = this.indent + 1;
                            try this.emitBody(tl.body);
                            this.indent = tl_saved;
                            try this.w("\n");
                            try this.writeIndent();
                            try this.w("end");
                        }
                        try this.w(")");
                    } else {
                        // `recv_arg_emitted` tracks whether the receiver was
                        // already written as the first positional argument
                        // (activated extension dispatch) so the argument loop
                        // knows to prefix a comma.
                        var recv_arg_emitted = false;
                        // Reserved-word function names (`of`, `div`) must be
                        // single-quoted wherever they are called; `fnAtom` is a
                        // no-op for every other callee. One buffer, reused per use.
                        var callee_buf: [256]u8 = undefined;
                        const callee = try fnAtom(cc.callee, &callee_buf);
                        if (cc.receiver) |recv| {
                            const mod_name: ?[]const u8 = switch (recv.*) {
                                .identifier => |id| switch (id.kind) {
                                    .ident => |n| if (isModuleRef(n)) n else null,
                                    else => null,
                                },
                                else => null,
                            };
                            // `"std"` package qualified call: a lowercase
                            // receiver naming an imported std module lowers to
                            // the remote `option:map(Args)`.
                            const std_mod: ?[]const u8 = switch (recv.*) {
                                .identifier => |id| switch (id.kind) {
                                    .ident => |n| if (this.std_imports.contains(n)) n else null,
                                    else => null,
                                },
                                else => null,
                            };
                            if (std_mod) |sm| {
                                try this.fmt("{s}:{s}(", .{ sm, callee });
                            } else if (this.rewrites.get(c.loc)) |_| {
                                // Activated extension dispatch: `recv.m(args)` →
                                // `m(Recv, args)`, a bare local call to the
                                // function emitted by `emitExtensionMethods`.
                                try this.fmt("{s}(", .{callee});
                                try this.emitExpr(recv.*);
                                recv_arg_emitted = true;
                            } else if (mod_name != null and this.ext_names.contains(mod_name.?)) {
                                // Qualified extension call `Sym.m(obj)`: the
                                // receiver names the extension block, so it is
                                // not a module — call the bare local `m(obj)`.
                                try this.fmt("{s}(", .{callee});
                            } else if (mod_name != null and this.enum_names.contains(mod_name.?)) {
                                // Qualified enum payload constructor:
                                // `Color.Rgb(r, g, b)` → tagged tuple
                                // `{'Rgb', R, G, B}` (matches the case-arm
                                // constructor pattern lowering).
                                var tag_buf: [128]u8 = undefined;
                                try this.fmt("{{{s}", .{try atomName(cc.callee, &tag_buf)});
                                for (cc.args) |arg| {
                                    try this.w(", ");
                                    try this.emitExpr(arg.value.*);
                                }
                                try this.w("}");
                                return;
                            } else if (mod_name != null and this.imported_types.get(mod_name.?) != null) {
                                // Associated fn of an IMPORTED record/struct
                                // (`Response.ok(...)` where `Response` comes
                                // `from "web"`): a remote call into the owning
                                // module (`http:ok(...)`) — the bare fn only
                                // exists in the owner, lowercasing the type name
                                // (`response:ok`) would hit the wrong module.
                                const owner = this.imported_types.get(mod_name.?).?;
                                try this.fmt("{s}:{s}(", .{ owner, callee });
                            } else if (mod_name != null and this.record_fields.contains(mod_name.?)) {
                                // Associated fn of a LOCAL record (`Response.ok(...)`):
                                // the fn is emitted as a bare local function in this
                                // module, not a remote `response:ok(...)`.
                                try this.fmt("{s}(", .{callee});
                            } else if (mod_name != null and this.isInterfaceAssoc(mod_name.?, cc.callee)) {
                                // Associated `default fn` of an interface (`Array.range`,
                                // `Pair.of`): `emitInterface` emits it as the mangled
                                // local `'<Interface>_<method>'` (so it never collides
                                // with a consumer's own top-level fn), so call that — not
                                // a remote `array:range`.
                                var mraw: [256]u8 = undefined;
                                const mname = interfaceAssocAtom(&mraw, mod_name.?, cc.callee) catch return;
                                try this.fmt("{s}(", .{mname});
                            } else if (mod_name) |name| {
                                // A PascalCase identifier receiver is a module-qualified
                                // call: `List.map(xs, f)` → a remote call `list:map(Xs, F)`.
                                // The module name is lowercased to a valid atom; arity is
                                // implicit from the arg count (args + trailing lambdas).
                                const mod = try erlangModule(this.alloc, name);
                                defer this.alloc.free(mod);
                                try this.fmt("{s}:{s}(", .{ mod, callee });
                            } else if (this.instance_lowerings.get(c.loc)) |il| switch (il) {
                                // Builtin-primitive method (`xs.map(f)`, `s.split(sep)`):
                                // erlang has no native method dispatch — emit the host op
                                // directly (the receiver's argument position varies).
                                .prim => |k| {
                                    try this.emitPrimMethod(k, cc.callee, recv, cc);
                                    return;
                                },
                                // Record/struct/enum instance method: a plain function
                                // taking the receiver first. Local types call the bare
                                // `m(Recv, args)`; an imported type calls into its owner
                                // module (`owner:m(Recv, args)`).
                                .record => |tn| {
                                    if (this.imported_types.get(tn)) |owner| {
                                        try this.fmt("{s}:{s}(", .{ owner, callee });
                                    } else {
                                        try this.fmt("{s}(", .{callee});
                                    }
                                    try this.emitExpr(recv.*);
                                    recv_arg_emitted = true;
                                },
                            } else {
                                // Method call on a value receiver with no recorded
                                // lowering — treat as a local record method taking the
                                // receiver first (`recv.m(args)` → `m(Recv, args)`).
                                try this.fmt("{s}(", .{callee});
                                try this.emitExpr(recv.*);
                                recv_arg_emitted = true;
                            }
                        } else if (this.externals.get(cc.callee)) |ref| {
                            // `@[external(erlang, "module", "symbol")]` fn:
                            // the call lowers to the remote `module:symbol(…)`.
                            try this.fmt("{s}:{s}(", .{ ref.module, ref.symbol });
                        } else if (this.externals_missing.contains(cc.callee)) {
                            // External fn with no `erlang` target — no symbol
                            // to call on this backend.
                            return error.MissingExternalTarget;
                        } else if (this.record_fields.get(cc.callee)) |fields| {
                            // Record/struct constructor → map literal
                            // `#{field => V, …}` (runtime shape mirrors the
                            // beam backend's `put_map_assoc` maps). Labeled
                            // args use their label; positional args map to
                            // the declared field order.
                            try this.w("#{");
                            for (cc.args, 0..) |arg, ai| {
                                if (ai > 0) try this.w(", ");
                                const fname: []const u8 = if (arg.label) |lbl|
                                    lbl
                                else if (ai < fields.len)
                                    fields[ai]
                                else
                                    "_arg";
                                var kb: [128]u8 = undefined;
                                try this.fmt("{s} => ", .{try atomName(fname, &kb)});
                                try this.emitExpr(arg.value.*);
                            }
                            try this.w("}");
                            return;
                        } else if (this.locals.contains(cc.callee)) {
                            // The callee is a fn-typed local (a parameter, `val`,
                            // or lambda binding) — apply it as a fun variable
                            // (`Pred(X)`), not a bare module function call.
                            const vname = try erlangVar(this.alloc, cc.callee);
                            defer this.alloc.free(vname);
                            try this.fmt("{s}(", .{vname});
                        } else {
                            try this.fmt("{s}(", .{callee});
                        }
                        var first = !recv_arg_emitted;
                        for (cc.args) |arg| {
                            if (!first) try this.w(", ");
                            try this.emitExpr(arg.value.*);
                            first = false;
                        }
                        // Trailing lambdas: emit as fun args
                        for (cc.trailing) |tl| {
                            if (!first) try this.w(", ");
                            first = false;
                            try this.w("fun(");
                            for (tl.params, 0..) |p, pi| {
                                if (pi > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, p);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                                this.addLocal(p);
                            }
                            try this.w(") ->\n");
                            const tl_saved = this.indent;
                            this.indent = this.indent + 1;
                            try this.emitBody(tl.body);
                            this.indent = tl_saved;
                            try this.w("\n");
                            try this.writeIndent();
                            try this.w("end");
                        }
                        try this.w(")");
                    }
                },
            },

            .function => |func| {
                try this.w("fun(");
                for (func.kind.params, 0..) |p, i| {
                    if (i > 0) try this.w(", ");
                    const vname = try erlangVar(this.alloc, p);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                    this.addLocal(p);
                }
                try this.w(") ->\n");
                const lam_saved = this.indent;
                this.indent = this.indent + 1;
                try this.emitBody(func.kind.body);
                this.indent = lam_saved;
                try this.w("\n");
                try this.writeIndent();
                try this.w("end");
            },

            .collection => |col| switch (col.kind) {
                .grouped => |inner| {
                    try this.w("(");
                    try this.emitExpr(inner.*);
                    try this.w(")");
                },
                .arrayLit => |al| {
                    // Special handling for spreadExpr: use ++ operator for list concatenation
                    if (al.spreadExpr) |se| {
                        // Emit the first part as a list
                        try this.w("[");
                        for (al.elems, 0..) |elem, i| {
                            if (i > 0) try this.w(", ");
                            try this.emitExpr(elem);
                        }
                        try this.w("]");

                        // Use ++ to concatenate with the spread expression
                        try this.w(" ++ ");
                        try this.emitExpr(se.*);
                    } else {
                        // Normal array literal or simple spread (identifier)
                        try this.w("[");
                        for (al.elems, 0..) |elem, i| {
                            if (i > 0) try this.w(", ");
                            try this.emitExpr(elem);
                        }
                        if (al.spread) |name| {
                            if (al.elems.len > 0) try this.w(", ");
                            if (name.len > 0) try this.w(name);
                        }
                        try this.w("]");
                    }
                },
                .tupleLit => |tl| {
                    try this.w("{");
                    for (tl.elems, 0..) |elem, i| {
                        if (i > 0) try this.w(", ");
                        try this.emitExpr(elem);
                    }
                    try this.w("}");
                },
                .case => |c| try this.emitCase(c.subjects, c.arms),
                .range => |r| {
                    // `a..b` is half-open `[a, b)` (parity with wasm + `Array.range`),
                    // but erlang's `lists:seq/2` is inclusive — so the upper bound is
                    // `b - 1` (`lists:seq(A, B - 1)`; `B = A` yields `[]`). An open
                    // range `a..` iterates to `infinity`.
                    try this.w("lists:seq(");
                    try this.emitExpr(r.start.*);
                    try this.w(", ");
                    if (r.end) |end| {
                        try this.w("(");
                        try this.emitExpr(end.*);
                        try this.w(") - 1");
                    } else try this.w("infinity");
                    try this.w(")");
                },
                // Anonymous record literal — an Erlang map (the same shape
                // named records lower to).
                .recordLit => |rl| {
                    try this.w("#{");
                    for (rl.fields, 0..) |f, i| {
                        if (i > 0) try this.w(", ");
                        try this.fmt("{s} => ", .{f.name});
                        try this.emitExpr(f.value.*);
                    }
                    try this.w("}");
                },
            },

            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |val| try this.emitExpr(val.*),
                .throw_ => |r| if (r) |val| {
                    try this.w("erlang:throw(");
                    try this.emitExpr(val.*);
                    try this.w(")");
                },
                .try_ => |t| if (t) |val| try this.emitExpr(val.*),
                .await_ => |av| try this.emitExpr(av.*),
                .@"break" => |b| if (b) |bp| try this.emitExpr(bp.*),
                .yield => |y| if (y.value) |val| try this.emitExpr(val.*),
                .@"continue" => try this.w("%% continue"),
            },

            .branch => |br| switch (br.kind) {
                .if_ => |i| {
                    try this.w("case ");
                    try this.emitExpr(i.cond.*);
                    try this.w(" of\n");
                    this.indent += 1;
                    try this.writeIndent();
                    if (i.binding) |_| {
                        try this.w("undefined -> undefined;\n");
                        try this.writeIndent();
                        try this.w("_ ->\n");
                    } else {
                        try this.w("true ->\n");
                    }
                    this.indent += 1;
                    try this.emitBranchBody(i.then_);
                    this.indent -= 1;
                    if (i.else_) |els| {
                        try this.w(";\n");
                        try this.writeIndent();
                        try this.w("false ->\n");
                        this.indent += 1;
                        try this.emitBranchBody(els);
                        this.indent -= 1;
                    } else {
                        // No else branch — emit a catch-all so the case
                        // doesn't crash when the condition is false.
                        try this.w(";\n");
                        try this.writeIndent();
                        try this.w("_ -> ok");
                    }
                    this.indent -= 1;
                    try this.w("\n");
                    try this.writeIndent();
                    try this.w("end");
                },
                .tryCatch => |tc| {
                    // `try expr catch handler` → pattern match on the Result tag.
                    //   case Expr of {ok, V} -> V; {error, E} -> Handler end
                    const handler = tc.handler.*;
                    const is_jump = switch (handler) {
                        .jump => |j| switch (j.kind) {
                            .throw_, .@"return", .@"break", .@"continue", .yield => true,
                            else => false,
                        },
                        else => false,
                    };
                    const is_fun = switch (handler) {
                        .function => true,
                        else => false,
                    };
                    const n = this.try_seq;
                    this.try_seq += 1;

                    try this.w("case ");
                    try this.emitExpr(tc.expr.*);
                    try this.w(" of\n");
                    this.indent += 1;
                    try this.writeIndent();
                    try this.fmt("{{ok, TryV{d}}} -> TryV{d};\n", .{ n, n });
                    try this.writeIndent();
                    try this.fmt("{{error, _TryE{d}}} ->\n", .{n});
                    this.indent += 1;
                    try this.writeIndent();
                    try this.emitExpr(handler);
                    if (is_fun) {
                        try this.fmt("(_TryE{d})", .{n});
                    } else if (is_jump) {
                        // handler already emitted its own control-flow expression
                    }
                    this.indent -= 2;
                    try this.w("\n");
                    try this.writeIndent();
                    try this.w("end");
                },
            },

            .loop => |lp| {
                const has_yield = blk: {
                    for (lp.body) |stmt| {
                        if (switch (stmt.expr) {
                            .jump => |j| j.kind == .yield,
                            else => false,
                        }) break :blk true;
                    }
                    break :blk false;
                };
                const fun_kw = if (has_yield) "lists:map" else "lists:foreach";
                try this.fmt("{s}(fun(", .{fun_kw});
                for (lp.params, 0..) |p, i| {
                    if (i > 0) try this.w(", ");
                    const vname = try erlangVar(this.alloc, p);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                }
                try this.w(") ->\n");
                const fun_body_indent = this.indent + 1;
                const saved2 = this.indent;
                this.indent = fun_body_indent;
                try this.emitBody(lp.body);
                this.indent = saved2;
                try this.w("\n");
                try this.writeIndent();
                try this.w("end, ");
                try this.emitExpr(lp.iter.*);
                try this.w(")");
            },

            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    const vname = try erlangVar(this.alloc, lb.name);
                    defer this.alloc.free(vname);
                    this.addLocal(lb.name);
                    try this.fmt("{s} = ", .{vname});
                    try this.emitExpr(lb.value.*);
                },
                .assign => |a| {
                    switch (a.target) {
                        .name => |name| {
                            const vname = try erlangVar(this.alloc, name);
                            defer this.alloc.free(vname);
                            switch (a.op) {
                                .assign => try this.fmt("{s} = ", .{vname}),
                                .plusAssign => try this.fmt("{s} = {s} + ", .{ vname, vname }),
                            }
                            try this.emitExpr(a.value.*);
                        },
                        .fieldAccess => |*fa| {
                            // Erlang records don't support mutation like this; emit a comment
                            try this.fmt("%% {s}.{s} = ...", .{ "self", fa.field });
                        },
                    }
                },
                .localBindDestruct => |lb| {
                    switch (lb.pattern) {
                        .names => |*n| {
                            try this.w("{");
                            for (n.fields, 0..) |fld, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, fld.bind_name);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            if (n.hasSpread) try this.w(", _");
                            try this.w("} = ");
                        },
                        .tuple_ => |t| {
                            try this.w("{");
                            for (t, 0..) |nm, i| {
                                if (i > 0) try this.w(", ");
                                const vname = try erlangVar(this.alloc, nm);
                                defer this.alloc.free(vname);
                                try this.w(vname);
                            }
                            try this.w("} = ");
                        },
                        .list => {}, // List pattern — placeholder
                        .ctor => {}, // Constructor pattern — placeholder
                    }
                    try this.emitExpr(lb.value.*);
                },
            },

            // `use` is a transparent prefix in Erlang: lower the wrapped call.
            // Any binding is handled by the enclosing `val` (localBind/Destruct),
            // so the hook result lands in a bound variable (a per-process slot).
            .useHook => |uh| try this.emitExpr(uh.kind.inner.*),

            .comptime_ => |ct| switch (ct.kind) {
                .comptimeExpr => |inner| try this.emitExpr(inner.*),
                .comptimeBlock => |cb| {
                    for (cb.body) |stmt| {
                        switch (stmt.expr) {
                            .jump => |j| switch (j.kind) {
                                .@"break" => |y| {
                                    if (y) |yp| try this.emitExpr(yp.*);
                                    return;
                                },
                                else => {},
                            },
                            else => {},
                        }
                    }
                },
                .assert => |a| {
                    if (this.test_mode) {
                        // Raise a tagged error the test runner catches per
                        // test (records the failure and continues).
                        try this.w("case (");
                        try this.emitExpr(a.condition.*);
                        try this.w(") of true -> ok; _ -> erlang:error({bp_assert, ");
                        if (a.message) |msg| {
                            try this.emitExpr(msg.*);
                        } else {
                            try this.w("<<\"assertion failed\">>");
                        }
                        try this.fmt(", <<\"{s}.bp:{d}\">>}}) end", .{ this.module_name, ct.loc.line });
                    } else {
                        // Erlang doesn't have built-in assert, so we use pattern matching
                        try this.w("true = (");
                        try this.emitExpr(a.condition.*);
                        try this.w(")");
                    }
                },
                .assertPattern => |ap| {
                    // Use Erlang's native pattern matching with case expressions
                    try this.w("case ");
                    try this.emitExpr(ap.expr.*);
                    try this.w(" of ");

                    // Emit the pattern
                    try this.emitPattern(ap.pattern);
                    try this.w(" -> ");

                    // On successful match, return the matched value
                    try this.emitExpr(ap.expr.*);

                    try this.w("; _ -> ");

                    // Handle the failure case
                    try this.emitExpr(ap.handler.*);

                    try this.w(" end");
                },
            },
        }
    }

    // ── if branch body (delegates to emitBody) ────────────────────────────────

    fn emitBranchBody(this: *Emitter, body: []const ast.Stmt) !void {
        try this.emitBody(body);
    }

    // ── case expression ───────────────────────────────────────────────────────

    fn emitCase(this: *Emitter, subjects: []ast.Expr, arms: []ast.CaseArm) !void {
        try this.w("case ");
        if (subjects.len == 1) {
            try this.emitExpr(subjects[0]);
        } else {
            try this.w("{");
            for (subjects, 0..) |s, i| {
                if (i > 0) try this.w(", ");
                try this.emitExpr(s);
            }
            try this.w("}");
        }
        try this.w(" of\n");
        this.indent += 1;

        var first_clause = true;
        for (arms) |arm| {
            // OR patterns expand to multiple Erlang clauses with the same body
            switch (arm.pattern) {
                .@"or" => |pats| {
                    for (pats) |p| {
                        if (!first_clause) try this.w(";\n");
                        try this.writeIndent();
                        try this.emitPattern(p);
                        try this.w(" ->\n");
                        this.indent += 1;
                        try this.emitCaseBody(arm.body);
                        this.indent -= 1;
                        first_clause = false;
                    }
                },
                .multi => {
                    if (!first_clause) try this.w(";\n");
                    try this.writeIndent();
                    try this.emitPattern(arm.pattern);
                    try this.w(" ->\n");
                    this.indent += 1;
                    try this.emitCaseBody(arm.body);
                    this.indent -= 1;
                    first_clause = false;
                },
                else => {
                    if (!first_clause) try this.w(";\n");
                    try this.writeIndent();
                    try this.emitPattern(arm.pattern);
                    try this.w(" ->\n");
                    this.indent += 1;
                    try this.emitCaseBody(arm.body);
                    this.indent -= 1;
                    first_clause = false;
                },
            }
        }

        this.indent -= 1;
        try this.w("\n");
        try this.writeIndent();
        try this.w("end");
    }

    fn emitPattern(this: *Emitter, pat: ast.Pattern) !void {
        switch (pat) {
            .wildcard => try this.w("_"),
            .ident => |n| {
                // A bare ident pattern is either a nullary enum variant (→ the
                // atom `'Lt'`) or a binding (→ an erlang variable `X`). Emitting
                // the raw name would make a variant match like an unbound var.
                if (this.enum_variants.contains(n)) {
                    var ab: [128]u8 = undefined;
                    try this.w(try atomName(n, &ab));
                } else {
                    const vname = try erlangVar(this.alloc, n);
                    defer this.alloc.free(vname);
                    try this.w(vname);
                }
            },
            .numberLit => |n| try this.w(n),
            .stringLit => |s| try this.emitBinary(s),
            .variant => |v| switch (v.payload) {
                .binding => |binding| {
                    const vname = try erlangVar(this.alloc, binding);
                    defer this.alloc.free(vname);
                    try this.fmt("{{tag, {s}, {s}}}", .{ v.name, vname });
                },
                .fields => |fields| {
                    try this.fmt("{{tag, {s}", .{v.name});
                    for (fields) |bb| {
                        try this.w(", ");
                        const vname = try erlangVar(this.alloc, bb);
                        defer this.alloc.free(vname);
                        try this.w(vname);
                    }
                    try this.w("}");
                },
                .literals => |args| {
                    try this.fmt("{{tag, {s}", .{v.name});
                    for (args) |arg| {
                        try this.w(", ");
                        try this.emitPattern(arg);
                    }
                    try this.w("}");
                },
            },
            .list => |lp| {
                if (lp.spread) |sp| {
                    if (lp.elems.len == 0 and sp.len == 0) {
                        try this.w("_");
                    } else {
                        try this.w("[");
                        for (lp.elems, 0..) |elem, i| {
                            if (i > 0) try this.w(", ");
                            try this.emitListPatElem(elem);
                        }
                        if (sp.len > 0) {
                            if (lp.elems.len > 0) try this.w(" | ");
                            const vname = try erlangVar(this.alloc, sp);
                            defer this.alloc.free(vname);
                            try this.w(vname);
                        } else {
                            try this.w(" | _");
                        }
                        try this.w("]");
                    }
                } else if (lp.elems.len == 0) {
                    try this.w("[]");
                } else {
                    try this.w("[");
                    for (lp.elems, 0..) |elem, i| {
                        if (i > 0) try this.w(", ");
                        try this.emitListPatElem(elem);
                    }
                    try this.w("]");
                }
            },
            .@"or" => |pats| {
                // Should be expanded by emitCase; fallback: emit first
                if (pats.len > 0) try this.emitPattern(pats[0]);
            },
            .multi => |pats| {
                try this.w("{");
                for (pats, 0..) |p, i| {
                    if (i > 0) try this.w(", ");
                    try this.emitPattern(p);
                }
                try this.w("}");
            },
        }
    }

    fn emitListPatElem(this: *Emitter, elem: ast.ListPatternElem) !void {
        switch (elem) {
            .wildcard => try this.w("_"),
            .bind => |name| {
                const vname = try erlangVar(this.alloc, name);
                defer this.alloc.free(vname);
                try this.w(vname);
            },
            .numberLit => |n| try this.w(n),
        }
    }

    fn emitCaseBody(this: *Emitter, body: ast.Expr) !void {
        switch (body) {
            .function => |func| switch (func.kind.syntax) {
                .lambda => {
                    // Multi-statement block: emitBody handles indentation via this.indent
                    try this.emitBody(func.kind.body);
                },
                .fnExpr => {
                    // Single expression: emit with current indentation
                    try this.writeIndent();
                    try this.emitExpr(body);
                },
            },
            else => {
                // Single expression: emit with current indentation
                try this.writeIndent();
                try this.emitExpr(body);
            },
        }
    }

    // ── builtin-primitive method lowering ─────────────────────────────────────

    /// Emit the `i`-th argument of a call (positional args first, then trailing
    /// lambdas as `fun(...) -> ... end`). Used by `emitPrimMethod`, where the
    /// receiver and arguments are reordered to fit the erlang host signature.
    fn emitArg(this: *Emitter, cc: anytype, i: usize) anyerror!void {
        if (i < cc.args.len) {
            try this.emitExpr(cc.args[i].value.*);
            return;
        }
        if (i - cc.args.len >= cc.trailing.len) {
            // Caller asked for an argument that wasn't supplied (e.g. an
            // optional-arg method form) — emit nothing rather than crash.
            try this.w("undefined");
            return;
        }
        const tl = cc.trailing[i - cc.args.len];
        try this.w("fun(");
        for (tl.params, 0..) |p, pi| {
            if (pi > 0) try this.w(", ");
            const vname = try erlangVar(this.alloc, p);
            defer this.alloc.free(vname);
            try this.w(vname);
            this.addLocal(p);
        }
        try this.w(") ->\n");
        const saved = this.indent;
        this.indent = this.indent + 1;
        try this.emitBody(tl.body);
        this.indent = saved;
        try this.w("\n");
        try this.writeIndent();
        try this.w("end");
    }

    /// Lower a builtin-primitive instance method to its erlang host operation.
    /// botopink arrays are erlang lists, strings are binaries, numbers/bools are
    /// native. The receiver's argument position differs per op (e.g. the fun is
    /// first in `lists:map/2`), so this emits the whole call. Unmapped methods
    /// fall back to a bare local `m(Recv, args)` call (a clear runtime error if
    /// truly unsupported) rather than invalid `Recv:m(args)` syntax.
    fn emitPrimMethod(this: *Emitter, k: envMod.PrimKind, callee: []const u8, recv: *const ast.Expr, cc: anytype) anyerror!void {
        const eq = std.mem.eql;
        switch (k) {
            .array => {
                if (eq(u8, callee, "map") or eq(u8, callee, "filter")) {
                    try this.fmt("lists:{s}(", .{callee});
                    try this.emitArg(cc, 0);
                    try this.w(", ");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "forEach")) {
                    try this.w("lists:foreach(");
                    try this.emitArg(cc, 0);
                    try this.w(", ");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "reverse")) {
                    try this.w("lists:reverse(");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "append")) {
                    try this.w("(");
                    try this.emitExpr(recv.*);
                    try this.w(" ++ ");
                    try this.emitArg(cc, 0);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "prepend")) {
                    try this.w("[");
                    try this.emitArg(cc, 0);
                    try this.w(" | ");
                    try this.emitExpr(recv.*);
                    try this.w("]");
                    return;
                }
                if (eq(u8, callee, "push")) {
                    // Append a single element to the end of the list.
                    try this.w("(");
                    try this.emitExpr(recv.*);
                    try this.w(" ++ [");
                    try this.emitArg(cc, 0);
                    try this.w("])");
                    return;
                }
                if (eq(u8, callee, "contains")) {
                    try this.w("lists:member(");
                    try this.emitArg(cc, 0);
                    try this.w(", ");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "indexOf")) {
                    // 0-based position of the first matching element, or -1.
                    try this.w("(fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(");
                    try this.emitExpr(recv.*);
                    try this.w(", ");
                    try this.emitArg(cc, 0);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "len") or eq(u8, callee, "length") or eq(u8, callee, "size")) {
                    try this.w("length(");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "isEmpty")) {
                    try this.w("(");
                    try this.emitExpr(recv.*);
                    try this.w(" =:= [])");
                    return;
                }
                if (eq(u8, callee, "slice")) {
                    const argc = cc.args.len + cc.trailing.len;
                    if (argc >= 2) {
                        // `xs.slice(start, end)` (0-based, end-exclusive) → erlang's
                        // 1-based `lists:sublist(L, Start+1, End-Start)`.
                        try this.w("lists:sublist(");
                        try this.emitExpr(recv.*);
                        try this.w(", (");
                        try this.emitArg(cc, 0);
                        try this.w(") + 1, ((");
                        try this.emitArg(cc, 1);
                        try this.w(") - (");
                        try this.emitArg(cc, 0);
                        try this.w(")))");
                    } else {
                        // `xs.slice(start)` → drop the first `start` elements.
                        try this.w("lists:nthtail(");
                        try this.emitArg(cc, 0);
                        try this.w(", ");
                        try this.emitExpr(recv.*);
                        try this.w(")");
                    }
                    return;
                }
                if (eq(u8, callee, "join")) {
                    // Concatenate the elements, interspersing the separator, into
                    // a single binary. Each element is first rendered to text to
                    // match JS (`[10,20].join(",") == "10,20"`) — a bare integer
                    // in an iolist is a byte, not its decimal form, so numbers
                    // must go through `integer_to_binary`/`io_lib:format`.
                    try this.w("iolist_to_binary(lists:join(");
                    try this.emitArg(cc, 0);
                    try this.w(", lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format(\"~p\", [__E])) end end, ");
                    try this.emitExpr(recv.*);
                    try this.w(")))");
                    return;
                }
                if (eq(u8, callee, "at")) {
                    // Bounds-safe 0-based index → erlang's 1-based `lists:nth`,
                    // returning `undefined` (the `?T` absence) out of range.
                    try this.w("(fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(");
                    try this.emitExpr(recv.*);
                    try this.w(", ");
                    try this.emitArg(cc, 0);
                    try this.w(")");
                    return;
                }
            },
            .string => {
                if (eq(u8, callee, "length")) {
                    try this.w("string:length(");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "toUpper")) {
                    try this.w("string:uppercase(");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "toLower")) {
                    try this.w("string:lowercase(");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "trim")) {
                    try this.w("string:trim(");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
                if (eq(u8, callee, "slice")) {
                    const argc = cc.args.len + cc.trailing.len;
                    if (argc >= 2) {
                        // `s.slice(start, end)` (0-based, end-exclusive) → erlang's
                        // `string:slice(S, Start, End - Start)` (start + length).
                        try this.w("string:slice(");
                        try this.emitExpr(recv.*);
                        try this.w(", ");
                        try this.emitArg(cc, 0);
                        try this.w(", ((");
                        try this.emitArg(cc, 1);
                        try this.w(") - (");
                        try this.emitArg(cc, 0);
                        try this.w(")))");
                    } else {
                        // `s.slice(start)` → from `start` to the end.
                        try this.w("string:slice(");
                        try this.emitExpr(recv.*);
                        try this.w(", ");
                        try this.emitArg(cc, 0);
                        try this.w(")");
                    }
                    return;
                }
                if (eq(u8, callee, "contains")) {
                    try this.w("(string:find(");
                    try this.emitExpr(recv.*);
                    try this.w(", ");
                    try this.emitArg(cc, 0);
                    try this.w(") =/= nomatch)");
                    return;
                }
                if (eq(u8, callee, "startsWith")) {
                    try this.w("(string:prefix(");
                    try this.emitExpr(recv.*);
                    try this.w(", ");
                    try this.emitArg(cc, 0);
                    try this.w(") =/= nomatch)");
                    return;
                }
                if (eq(u8, callee, "split")) {
                    try this.w("string:split(");
                    try this.emitExpr(recv.*);
                    try this.w(", ");
                    try this.emitArg(cc, 0);
                    try this.w(", all)");
                    return;
                }
            },
            .bool => {
                if (eq(u8, callee, "negate")) {
                    try this.w("(not ");
                    try this.emitExpr(recv.*);
                    try this.w(")");
                    return;
                }
            },
            .int, .float => {},
        }
        // Unmapped primitive method: bare local call (`m(Recv, args)`).
        try this.fmt("{s}(", .{callee});
        try this.emitExpr(recv.*);
        for (cc.args) |arg| {
            try this.w(", ");
            try this.emitExpr(arg.value.*);
        }
        try this.w(")");
    }

    // ── struct / record / enum ────────────────────────────────────────────────

    fn emitStruct(this: *Emitter, s: ast.StructDecl) !void {
        // Structs are maps at runtime (`#{field => V}`) — no decl needed.
        // (`-record(PascalCase, …)` is invalid Erlang: a capitalised bare atom.)
        try this.fmt("%% struct {s}: ", .{s.name});
        var first = true;
        for (s.members) |m| switch (m) {
            .field => |f| {
                if (!first) try this.w(", ");
                try this.w(f.name);
                first = false;
            },
            else => {},
        };
        try this.w("\n");
        // Emit methods as standalone functions
        for (s.members) |m| switch (m) {
            .method => |md| {
                if (md.is_declare) continue;
                try this.w("\n");
                const saved_keep_self = this.keep_self;
                this.keep_self = !isAssocMethod(md);
                defer this.keep_self = saved_keep_self;
                try this.emitFn(.{
                    .isPub = false,
                    .name = md.name,
                    .annotations = &.{},
                    .genericParams = &.{},
                    .params = md.params,
                    .returnType = md.returnType,
                    .body = md.body orelse &.{},
                });
            },
            else => {},
        };
    }

    fn emitRecord(this: *Emitter, r: ast.RecordDecl) !void {
        // Records are maps at runtime (`#{field => V}`) — no decl needed.
        // (`-record(PascalCase, …)` is invalid Erlang: a capitalised bare atom.)
        try this.fmt("%% record {s}: ", .{r.name});
        for (r.fields, 0..) |f, i| {
            if (i > 0) try this.w(", ");
            try this.w(f.name);
        }
        try this.w("\n");
        // Instance methods keep their `self` receiver as an explicit first
        // parameter (`Self`); the call site passes the receiver positionally
        // (`recv.m(args)` → `m(Recv, args)`). Associated fns (no `self`) are
        // emitted as ordinary bare functions.
        for (r.methods) |m| {
            if (m.is_declare) continue;
            try this.w("\n");
            const saved_keep_self = this.keep_self;
            this.keep_self = !isAssocMethod(m);
            defer this.keep_self = saved_keep_self;
            try this.emitFn(.{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = m.returnType,
                .body = m.body orelse &.{},
            });
        }
    }

    fn emitEnum(this: *Emitter, e: ast.EnumDecl) !void {
        try this.fmt("%% enum {s}\n", .{e.name});
        for (e.variants) |v| {
            if (v.fields.len == 0) {
                try this.fmt("%%   {s}\n", .{v.name});
            } else {
                try this.fmt("%%   {s}(", .{v.name});
                for (v.fields, 0..) |f, i| {
                    if (i > 0) try this.w(", ");
                    try this.w(f.name);
                }
                try this.w(")\n");
            }
        }
        for (e.methods) |m| {
            if (m.is_declare) continue;
            try this.w("\n");
            const saved_keep_self = this.keep_self;
            this.keep_self = !isAssocMethod(m);
            defer this.keep_self = saved_keep_self;
            try this.emitFn(.{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = m.returnType,
                .body = m.body orelse &.{},
            });
        }
    }

    fn emitInterface(this: *Emitter, i: ast.InterfaceDecl) !void {
        try this.fmt("%% interface {s}\n", .{i.name});
        // Associated `default fn`s (no `self`) are pure botopink — emit them as
        // local functions so `Interface.method(...)` resolves locally (the
        // interface decl is inlined into each consuming module). The name is
        // mangled `Interface_method` (→ quoted `'Array_range'`, since it starts
        // uppercase) so it never collides with a consumer's own top-level fn of
        // the same name (a consumer may define its own `range`/`repeat`). Instance
        // default fns (with `self`) are a separate gap, not emitted here.
        for (i.methods) |m| {
            if (!m.is_default or m.body == null) continue;
            const has_self = m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self");
            if (has_self) continue;
            var mbuf: [256]u8 = undefined;
            const mangled = interfaceAssocAtom(&mbuf, i.name, m.name) catch continue;
            try this.w("\n");
            try this.emitFn(.{
                .isPub = false,
                .name = mangled,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = null,
                .body = m.body.?,
            });
        }
    }

    fn emitImplement(this: *Emitter, im: ast.ImplementDecl) !void {
        try this.w("%% implement ");
        for (im.interfaces, 0..) |iface, i| {
            if (i > 0) try this.w(", ");
            try this.w(switch (iface) {
                .named => |n| n,
                .generic => |g| g.name,
                else => "?",
            });
        }
        try this.fmt(" for {s}\n", .{im.target});
        try this.emitExtensionMethods(im.methods);
    }

    fn emitExtend(this: *Emitter, ex: ast.ExtendDecl) !void {
        try this.fmt("%% extend {s}\n", .{ex.target});
        try this.emitExtensionMethods(ex.methods);
    }

    /// Extension methods (from `implement`/`extend`) are emitted as bare
    /// top-level functions that take the receiver as their first param, so an
    /// activated `recv.m(args)` dispatch can call `m(Recv, args)` directly.
    fn emitExtensionMethods(this: *Emitter, methods: []const ast.ImplementMethod) !void {
        const saved_keep_self = this.keep_self;
        this.keep_self = true;
        defer this.keep_self = saved_keep_self;
        for (methods) |m| {
            try this.w("\n");
            try this.emitFn(.{
                .isPub = false,
                .name = m.name,
                .annotations = &.{},
                .genericParams = &.{},
                .params = m.params,
                .returnType = null,
                .body = m.body,
            });
        }
    }

    fn emitUse(this: *Emitter, u: ast.ImportDecl) !void {
        try this.w(if (u.activationOnly) "%% activate " else "%% import ");
        for (u.imports, 0..) |imp, i| {
            if (i > 0) try this.w(", ");
            try this.w(imp.name());
        }
        try this.w("\n");
    }

    // ── binary string helper ─────────────────────────────────────────────────

    fn emitBinary(this: *Emitter, s: []const u8) !void {
        try this.w("<<\"");
        for (s) |c| switch (c) {
            '"' => try this.w("\\\""),
            '\\' => try this.w("\\\\"),
            '\n' => try this.w("\\n"),
            '\r' => try this.w("\\r"),
            '\t' => try this.w("\\t"),
            else => try this.out.writeByte(c),
        };
        try this.w("\">>");
    }
};
