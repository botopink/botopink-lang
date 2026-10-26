//! Decision 989 (3) — a package `compiler.load` loaded and a `run()` brought
//! into the program, at `emit` for the target built: the target's refusal of
//! it is the `run()`'s answer, never the build's, and a manifest that leaves
//! the target out is audited.
//!
//! - **The refusal**: the first of `codegen/target_check.zig`'s refusals of
//!   the package's own modules (a std call reaching a host with no binding
//!   for the target), else a host function of the package with no binding
//!   for the target that its `main` reaches — the backends' own rule and text
//!   (`` `f` has no implementation for the <backend> backend ``, wasm's
//!   `dropUnlowerableDependencyFns` over the package's functions).
//! - **Refused**: the package's root is put in place by one whose only
//!   function, `__bp_loaded_main`, throws `load.off_marker`, the kind's
//!   letter and the refusal's text: `R` — `.Refused` — when the manifest
//!   holds the target, `X` — `.Excluded` — when it leaves it out; the
//!   package's other modules are not emitted. `run()`'s `__bp_run` reads it,
//!   and nothing of the package runs.
//! - **The audit** (the narrowing's, moved into the compiler; decision 67:
//!   the manifest is the only exemption): a package whose manifest leaves
//!   the target out and that the target does not refuse refuses each module
//!   that runs it, `load-excluded-target-compiles`, and the build with it.
//!
//! The analysis is handed back as it was (`writeBack`), so the same outputs
//! are emitted for another target.
const std = @import("std");
const ast = @import("../ast.zig");
const comptimeMod = @import("../comptime.zig");
const configMod = @import("./config.zig");
const loadMod = @import("../comptime/load.zig");
const targetCheck = @import("./target_check.zig");
const TypeError = @import("../comptime/error.zig").TypeError;

const ComptimeOutput = comptimeMod.ComptimeOutput;

pub const excluded_target_compiles = "load-excluded-target-compiles";

/// What `apply` changed: the outputs to emit in place of the analysis', and
/// the roots it put in place, which `writeBack` leaves out.
pub const Applied = struct {
    outputs: ?[]ComptimeOutput = null,
    replaced: []const []const u8 = &.{},
};

/// The package of output `name`: what comes before its first `/`.
fn packageOf(name: []const u8) []const u8 {
    const slash = std.mem.indexOfScalar(u8, name, '/') orelse return name;
    return name[0..slash];
}

fn targetName(t: configMod.TargetSource) []const u8 {
    return switch (t) {
        .commonJS => "commonJS",
        .erlang => "erlang",
        .beam => "beam",
        .wasm => "wasm",
    };
}

/// The backend a missing binding is named by, as each backend names it.
fn backendName(t: configMod.TargetSource) []const u8 {
    return switch (t) {
        .commonJS => "node",
        .erlang => "erlang",
        .beam => "beam",
        .wasm => "wasm",
    };
}

fn findFn(program: ast.Program, name: []const u8) ?ast.FnDecl {
    for (program.decls) |d| switch (d) {
        .@"fn" => |f| if (std.mem.eql(u8, f.name, name)) return f,
        else => {},
    };
    return null;
}

/// The string literal `f` returns (`return "…";`), as written.
fn returnedLiteral(f: ast.FnDecl) ?[]const u8 {
    for (f.body) |st| switch (st.expr) {
        .jump => |j| switch (j.kind) {
            .@"return" => |v| if (v) |e| switch (e.*) {
                .literal => |l| switch (l.kind) {
                    .stringLit => |s| return s,
                    else => {},
                },
                else => {},
            },
            else => {},
        },
        else => {},
    };
    return null;
}

/// `f` throwing the string literal `lexeme` instead of the one it throws
/// (a copy; `f` is kept): `throw "…"`, or, as the transform writes it in a
/// `Result` body, `return __bp_error("…")`.
fn throwing(arena: std.mem.Allocator, f: ast.FnDecl, lexeme: []const u8) !?ast.FnDecl {
    const body = try arena.dupe(ast.Stmt, f.body);
    for (body) |*st| switch (st.expr) {
        .jump => |j| {
            const v = switch (j.kind) {
                .throw_, .@"return" => |v| v orelse continue,
                else => continue,
            };
            const thrown = (try withLiteral(arena, v, lexeme)) orelse continue;
            var jump = j;
            jump.kind = switch (j.kind) {
                .throw_ => .{ .throw_ = thrown },
                else => .{ .@"return" = thrown },
            };
            st.expr = .{ .jump = jump };
            var out = f;
            out.body = body;
            return out;
        },
        else => {},
    };
    return null;
}

/// `e` — a string literal, or a call of one argument that is one — with
/// the literal `lexeme` in its place (a copy).
fn withLiteral(arena: std.mem.Allocator, e: *ast.Expr, lexeme: []const u8) !?*ast.Expr {
    if (e.* == .literal and e.literal.kind == .stringLit) {
        const lit = try arena.create(ast.Expr);
        lit.* = e.*;
        lit.literal.kind = .{ .stringLit = lexeme };
        return lit;
    }
    if (e.* == .call and e.call.kind == .call and e.call.kind.call.args.len == 1) {
        const arg = (try withLiteral(arena, e.call.kind.call.args[0].value, lexeme)) orelse return null;
        const args = try arena.dupe(@TypeOf(e.call.kind.call.args[0]), e.call.kind.call.args);
        args[0].value = arg;
        const call = try arena.create(ast.Expr);
        call.* = e.*;
        call.call.kind.call.args = args;
        return call;
    }
    return null;
}

/// Whether output `o` runs package `pkg`: a function of it names the alias
/// `run()` is rewritten to call (`load.runAlias`, `__bp_run__<package>`).
fn runs(arena: std.mem.Allocator, o: ComptimeOutput, pkg: []const u8) !bool {
    const ok = switch (o.outcome) {
        .ok => |ok| ok,
        else => return false,
    };
    const alias = try loadMod.runAlias(arena, pkg);
    for (ok.transformed.decls) |d| switch (d) {
        .@"fn" => |f| {
            var list: std.ArrayListUnmanaged([]const u8) = .empty;
            try ast.collectNames(arena, f.body, &list);
            for (list.items) |n| if (std.mem.eql(u8, n, alias)) return true;
        },
        else => {},
    };
    return false;
}

/// Whether the manifest's targets (`loaded_info_fn`'s, after the `|`) hold
/// `target`.
fn holds(targets: []const u8, target: []const u8) bool {
    if (std.mem.eql(u8, targets, "*")) return true;
    var it = std.mem.splitScalar(u8, targets, ',');
    while (it.next()) |t| if (std.mem.eql(u8, t, target)) return true;
    return false;
}

/// The text of the target's refusal of the package `pkg` (its own modules,
/// in `outputs`), or null when the target takes it.
fn refusalOf(arena: std.mem.Allocator, outputs: []const ComptimeOutput, pkg: []const u8, config: configMod.Config) !?[]const u8 {
    const lookup = targetCheck.lookupName(config);
    for (outputs) |o| {
        if (!std.mem.eql(u8, packageOf(o.name), pkg)) continue;
        switch (o.outcome) {
            .ok => |ok| if (try targetCheck.refusalOf(arena, ok, lookup)) |te| return try te.message(arena),
            else => {},
        }
    }
    // A host function of the package with no binding for the target, and the
    // functions reaching one — the backends' rule (wasm's
    // `dropUnlowerableDependencyFns`).
    var missing: std.StringHashMapUnmanaged([]const u8) = .empty;
    var bodies: std.ArrayListUnmanaged(struct { name: []const u8, names: []const []const u8 }) = .empty;
    for (outputs) |o| {
        if (!std.mem.eql(u8, packageOf(o.name), pkg)) continue;
        const ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => continue,
        };
        for (ok.transformed.decls) |d| switch (d) {
            .@"fn" => |f| if (f.body.len == 0) {
                if (f.isExternal() and f.externalFor(lookup) == null) try missing.put(arena, f.name, f.name);
            } else {
                var list: std.ArrayListUnmanaged([]const u8) = .empty;
                try ast.collectNames(arena, f.body, &list);
                try bodies.append(arena, .{ .name = f.name, .names = list.items });
            },
            else => {},
        };
    }
    if (missing.count() == 0) return null;
    var progressed = true;
    while (progressed) {
        progressed = false;
        for (bodies.items) |b| {
            if (missing.contains(b.name)) continue;
            for (b.names) |n| if (missing.get(n)) |host| {
                try missing.put(arena, b.name, host);
                progressed = true;
                break;
            };
        }
    }
    const host = missing.get(loadMod.loaded_main_fn) orelse return null;
    return try std.fmt.allocPrint(arena, "`{s}` has no implementation for the {s} backend", .{ host, backendName(config.targetSource) });
}

/// The outputs to emit for `config`'s target in place of `outputs` (texts
/// and copies in `arena`), or `.{}` when no loaded package changes.
pub fn apply(arena: std.mem.Allocator, outputs: []const ComptimeOutput, config: configMod.Config) !Applied {
    var changed: std.StringHashMapUnmanaged(ComptimeOutput) = .empty;
    var dropped: std.StringHashMapUnmanaged(void) = .empty;
    var replaced: std.ArrayListUnmanaged([]const u8) = .empty;
    const target = targetName(config.targetSource);
    for (outputs) |o| {
        const pkg = packageOf(o.name);
        if (!loadMod.isLoadedPackage(pkg)) continue;
        const ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => continue,
        };
        const info_fn = findFn(ok.transformed, loadMod.loaded_info_fn) orelse continue;
        const info = returnedLiteral(info_fn) orelse continue;
        const bar = std.mem.lastIndexOfScalar(u8, info, '|') orelse continue;
        const path = info[0..bar];
        const included = holds(info[bar + 1 ..], target);
        if (try refusalOf(arena, outputs, pkg, config)) |why| {
            const off_fn = findFn(ok.transformed, loadMod.loaded_main_off_fn) orelse continue;
            const lexeme = try std.mem.concat(arena, u8, &.{ loadMod.off_marker, if (included) "R" else "X", try @import("../comptime/block_eval.zig").stringLexeme(arena, why) });
            var main_fn = (try throwing(arena, off_fn, lexeme)) orelse continue;
            main_fn.name = loadMod.loaded_main_fn;
            const decls = try arena.alloc(ast.DeclKind, 1);
            decls[0] = .{ .@"fn" = main_fn };
            var root = o;
            var rok = ok;
            rok.transformed.decls = decls;
            rok.std_host_calls = &.{};
            root.outcome = .{ .ok = rok };
            try changed.put(arena, o.name, root);
            try replaced.append(arena, o.name);
            for (outputs) |other| if (!std.mem.eql(u8, other.name, o.name) and std.mem.eql(u8, packageOf(other.name), pkg)) try dropped.put(arena, other.name, {});
        } else if (!included) {
            // Refused where the package is run: each module importing its
            // `__bp_loaded_main` (`load.withRunImports`).
            const te = TypeError.custom(
                try std.fmt.allocPrint(arena, "{s}: the package `{s}` leaves the target '{s}' out of its manifest's `targets`, and the target compiles it — a target is left out only where a host binding refuses it (decisions 67, 989)", .{ excluded_target_compiles, path, target }),
                try std.fmt.allocPrint(arena, "Add '{s}' to `{s}/botopink.json`'s `targets`, or keep the package from running there.", .{ target, path }),
            );
            for (outputs) |caller| {
                if (changed.contains(caller.name) or !try runs(arena, caller, pkg)) continue;
                var refused = caller;
                refused.outcome = .{ .typeError = te };
                try changed.put(arena, caller.name, refused);
                try replaced.append(arena, caller.name);
            }
        }
    }
    if (changed.count() == 0) return .{};
    var out: std.ArrayListUnmanaged(ComptimeOutput) = .empty;
    for (outputs) |o| {
        if (dropped.contains(o.name)) continue;
        try out.append(arena, changed.get(o.name) orelse o);
    }
    return .{ .outputs = out.items, .replaced = replaced.items };
}

/// Copy back what the emit wrote into `applied`'s outputs (an emitter may
/// rewrite an output in place) onto `outputs`, but the roots `apply` put in
/// place: their analysis stays as it was.
pub fn writeBack(outputs: []ComptimeOutput, applied: Applied) void {
    const emitted = applied.outputs orelse return;
    for (emitted) |e| {
        const is_replaced = for (applied.replaced) |r| {
            if (std.mem.eql(u8, r, e.name)) break true;
        } else false;
        if (is_replaced) continue;
        for (outputs) |*o| if (std.mem.eql(u8, o.name, e.name)) {
            o.* = e;
            break;
        };
    }
}
