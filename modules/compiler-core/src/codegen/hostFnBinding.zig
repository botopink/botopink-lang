//! Decision 238's `fn:` form on every backend (decisions 259, 263): a
//! `declare fn` whose binding for the build's target is `fn:<name>` runs
//! `<name>`, a private bodied `fn` of the same module with the same signature
//! — `#[@External.Erlang("fn:tanBody")]`, `#[@External.Beam("fn:tanBody")]`,
//! `#[@External.Node("fn:powBody")]`, `#[@External.Wasm("fn:tanBody")]`. The
//! arguments are the declared parameters in order.
//!
//! `resolve` is the one check of a `fn:` binding — the named fn exists in the
//! declaring module, has a body, is not `pub` and takes and answers the same
//! types — and every refusal is a located error at the annotation, never a
//! guess (decision 67). wasm reads it from `wat.zig` `checkHostBindings`
//! beside its `op:` and `wasi:` forms. commonJS, erlang and beam read
//! `Lowering`: before a backend emits anything, each bound `declare fn` of the
//! program becomes an ordinary function whose body is `return <name>(<the
//! parameters>);`, its `#[@External.…]` annotations dropped — so a call, a
//! `pub` export and a consumer's cross-module call reach it like any other
//! function, and no backend learns a fourth binding shape. On those three
//! targets a single-string binding is otherwise a host expression or a `.S`
//! template; the `fn:` prefix is the binding there, and nothing else is.

const std = @import("std");
const ast = @import("../ast.zig");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");

const ComptimeOutput = comptimeMod.ComptimeOutput;

/// The backend whose `#[@External.<Target>(…)]` `Lowering` reads.
pub const Target = enum {
    node,
    erlang,
    /// `External.Beam`, or `External.Erlang` when the declaration has no
    /// `External.Beam` — the vocabulary beam falls back to everywhere else.
    beam,
};

/// The private fn a `fn:` binding names, or why it names none.
pub const Resolution = union(enum) {
    ok: ast.FnDecl,
    refused: []const u8,
};

/// The name a single-string binding `fn:<name>` names, or null for any other
/// binding.
pub fn fnName(ref: ast.ExternalRef) ?[]const u8 {
    if (ref.module.len > 0) return null;
    if (!std.mem.startsWith(u8, ref.symbol, "fn:")) return null;
    return ref.symbol["fn:".len..];
}

/// The location of `f`'s `#[@External.<label>(…)]`.
pub fn annotationLoc(f: ast.FnDecl, label: []const u8) ?ast.Loc {
    for (f.annotations) |a| {
        if (std.mem.startsWith(u8, a.name, "External.") and std.ascii.eqlIgnoreCase(a.name["External.".len..], label)) return a.loc;
    }
    return null;
}

/// Decision 238's check of `#[@External.<label>("fn:<name>")]` on `f`: `prog`
/// (the declaring module's program) declares a bodied, non-`pub` fn `<name>`
/// taking the parameter types `f` declares, in order, and answering the same
/// type. `module` is the declaring module's path when its declarations reach
/// the check through a link that qualified their types (wasm's static
/// linking, `typeText`), else empty.
pub fn resolve(ar: std.mem.Allocator, f: ast.FnDecl, name: []const u8, prog: ast.Program, module: []const u8, label: []const u8) !Resolution {
    const target: ?ast.FnDecl = for (prog.decls) |pd| switch (pd) {
        .@"fn" => |g| if (std.mem.eql(u8, g.name, name)) break g,
        else => {},
    } else null;
    const g = target orelse
        return .{ .refused = try std.fmt.allocPrint(ar, "`#[@External.{s}(\"fn:{s}\")]` on `{s}`: this module declares no fn `{s}`", .{ label, name, f.name, name }) };
    if (g.isDeclare or g.body.len == 0)
        return .{ .refused = try std.fmt.allocPrint(ar, "`#[@External.{s}(\"fn:{s}\")]` on `{s}`: `{s}` has no body of its own to run", .{ label, name, f.name, name }) };
    if (g.isPub)
        return .{ .refused = try std.fmt.allocPrint(ar, "`#[@External.{s}(\"fn:{s}\")]` on `{s}`: `{s}` is `pub` — a binding names a private fn, so no body becomes the module's surface twice", .{ label, name, f.name, name }) };
    if (!try sameSignature(ar, f, g, module))
        return .{ .refused = try std.fmt.allocPrint(ar, "`#[@External.{s}(\"fn:{s}\")]` on `{s}`: `{s}` must take the same parameter types in the same order and answer the same type", .{ label, name, f.name, name }) };
    return .{ .ok = g };
}

/// Whether `g` takes the parameter types `f` declares, in order, and answers
/// the same type — compared as written (`TypeRef.format`).
fn sameSignature(ar: std.mem.Allocator, f: ast.FnDecl, g: ast.FnDecl, module: []const u8) !bool {
    if (f.genericParams.len != g.genericParams.len) return false;
    var fp: std.ArrayListUnmanaged(ast.TypeRef) = .empty;
    var gp: std.ArrayListUnmanaged(ast.TypeRef) = .empty;
    for (f.params) |p| if (!std.mem.eql(u8, p.name, "self")) try fp.append(ar, p.typeRef);
    for (g.params) |p| if (!std.mem.eql(u8, p.name, "self")) try gp.append(ar, p.typeRef);
    if (fp.items.len != gp.items.len) return false;
    for (fp.items, gp.items) |a, b| {
        if (!std.mem.eql(u8, try typeText(ar, a, module), try typeText(ar, b, module))) return false;
    }
    if ((f.returnType == null) != (g.returnType == null)) return false;
    if (f.returnType) |fr| {
        if (!std.mem.eql(u8, try typeText(ar, fr, module), try typeText(ar, g.returnType.?, module))) return false;
    }
    return true;
}

/// A type as `TypeRef.format` spells it, its own module's qualification
/// dropped: linking a module qualifies a `pub` declaration's types for its
/// consumers (`std/io/random/Array<T>`) and leaves a private fn's as written
/// (`Array<T>`), and the two name one type.
fn typeText(ar: std.mem.Allocator, t: ast.TypeRef, module: []const u8) ![]const u8 {
    const text = try std.fmt.allocPrint(ar, "{f}", .{t});
    if (module.len == 0) return text;
    const prefix = try std.fmt.allocPrint(ar, "{s}/", .{module});
    return std.mem.replaceOwned(u8, ar, text, prefix, "");
}

/// A refused `fn:` binding: the message and the annotation it is written at.
pub const Refusal = struct {
    message: []const u8,
    loc: ?ast.Loc,

    /// The failed module a backend appends in place of emitting `ct`.
    pub fn failed(r: Refusal, alloc: std.mem.Allocator, ct: ComptimeOutput) !moduleOutput.ModuleOutput {
        return .{
            .name = ct.name,
            .src = ct.src,
            .result = .{
                .js = try alloc.dupe(u8, ""),
                .comptime_script = null,
                .diagnostic = .{ .type = .{ .message = try alloc.dupe(u8, r.message), .loc = r.loc } },
            },
        };
    }
};

/// The `fn:` bindings of every module lowered to ordinary functions for one
/// backend's emission. `apply` rewrites each `.ok` module's program in place;
/// `deinit` puts the original programs back, so nothing outside the backend's
/// `codegenEmit` sees the rewritten declarations or the arena they live in.
pub const Lowering = struct {
    arena: std.heap.ArenaAllocator,
    saved: std.ArrayListUnmanaged(Saved) = .empty,
    refusals: std.StringHashMapUnmanaged(Refusal) = .empty,

    const Saved = struct { program: *ast.Program, decls: []ast.DeclKind };

    pub fn apply(alloc: std.mem.Allocator, outputs: []ComptimeOutput, target: Target) !Lowering {
        var self: Lowering = .{ .arena = std.heap.ArenaAllocator.init(alloc) };
        errdefer self.deinit();
        const ar = self.arena.allocator();
        for (outputs) |*ct| {
            const ok = switch (ct.outcome) {
                .ok => |*o| o,
                else => continue,
            };
            const prog = &ok.transformed;
            var rewritten: ?[]ast.DeclKind = null;
            for (prog.decls, 0..) |d, i| {
                const f = switch (d) {
                    .@"fn" => |f| f,
                    else => continue,
                };
                if (!f.isDeclare or f.body.len > 0) continue;
                const label, const ref = bindingFor(f, target) orelse continue;
                const name = fnName(ref) orelse continue;
                switch (try resolve(ar, f, name, prog.*, "", label)) {
                    .refused => |message| {
                        try self.refusals.put(ar, ct.name, .{ .message = message, .loc = annotationLoc(f, label) });
                        break;
                    },
                    .ok => {},
                }
                const decls = rewritten orelse blk: {
                    const copy = try ar.dupe(ast.DeclKind, prog.decls);
                    rewritten = copy;
                    break :blk copy;
                };
                decls[i] = .{ .@"fn" = try forwarding(ar, f, name) };
            }
            if (self.refusals.contains(ct.name)) continue;
            if (rewritten) |decls| {
                try self.saved.append(ar, .{ .program = prog, .decls = prog.decls });
                prog.decls = decls;
            }
        }
        return self;
    }

    /// The refusal of a `fn:` binding in module `name`, if any — the backend
    /// fails that module with it instead of emitting it.
    pub fn refusal(self: *const Lowering, name: []const u8) ?Refusal {
        return self.refusals.get(name);
    }

    pub fn deinit(self: *Lowering) void {
        for (self.saved.items) |s| s.program.decls = s.decls;
        self.arena.deinit();
    }
};

/// The binding `f` carries for `target`, with the annotation's target label.
fn bindingFor(f: ast.FnDecl, target: Target) ?struct { []const u8, ast.ExternalRef } {
    return switch (target) {
        .node => if (f.externalFor("node")) |r| .{ "Node", r } else null,
        .erlang => if (f.externalFor("erlang")) |r| .{ "Erlang", r } else null,
        .beam => if (f.externalFor("beam")) |r|
            .{ "Beam", r }
        else if (f.externalFor("erlang")) |r|
            .{ "Erlang", r }
        else
            null,
    };
}

/// `f` as an ordinary function: its signature, the annotations that are not
/// `#[@External.…]`, and the body `return <name>(<parameters>);`.
fn forwarding(ar: std.mem.Allocator, f: ast.FnDecl, name: []const u8) !ast.FnDecl {
    const loc: ast.Loc = f.nameLoc;
    var annotations: std.ArrayListUnmanaged(ast.Annotation) = .empty;
    for (f.annotations) |a| {
        if (std.mem.startsWith(u8, a.name, "External.")) continue;
        try annotations.append(ar, a);
    }
    const args = try ar.alloc(ast.CallArg, f.params.len);
    for (f.params, args) |p, *arg| {
        const value = try ar.create(ast.Expr);
        value.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = p.name } } };
        arg.* = .{ .label = null, .value = value };
    }
    const call = try ar.create(ast.Expr);
    call.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = name,
        .is_builtin = false,
        .args = args,
        .trailing = &.{},
    } } } };
    const body = try ar.alloc(ast.Stmt, 1);
    body[0] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = call } } } };
    var out = f;
    out.isDeclare = false;
    out.annotations = try annotations.toOwnedSlice(ar);
    out.body = body;
    return out;
}
