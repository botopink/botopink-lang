//! Decision 798 (4) — comptime never reads the build target: one analysed
//! tree feeds every backend, and what depends on the target is checked here,
//! over the analysed outputs, at the top of `codegen.emit`.
//!
//! - **STD-001** (decision 518 (4)): a call of a std function that reaches a
//!   host declaration with no binding for the target is refused at the call
//!   (`std-unsupported-on-target`). Inference recorded each such call and the
//!   host declarations it reaches, in order (`OkData.std_host_calls`); the
//!   first call whose first unbound host is found is the refusal.
//! - **`std/beam`** (front 17): the analysis holds it for every module-level
//!   `var`; a target that is not the BEAM emits it only when a module imports
//!   it (`withoutBeamStorage`).
//!
//! The texts, codes and places are the ones inference gave when it read the
//! target. A refusal turns the module's outcome into a `typeError` for the
//! emit alone: `restore` hands the analysis back as it was, so the same
//! outputs can be emitted for another target.
const std = @import("std");
const ast = @import("../ast.zig");
const comptimeMod = @import("../comptime.zig");
const diagnostics = @import("../comptime/diagnostics.zig");
const inlineTypes = @import("../comptime/inline_types.zig");
const configMod = @import("./config.zig");
const envMod = @import("../comptime/env.zig");

const ComptimeOutput = comptimeMod.ComptimeOutput;
const TypeError = @import("../comptime/error.zig").TypeError;

/// The lookup name a target's `#[compiler.external(…)]` implementations are
/// read by: BEAM reads the Erlang ones (decision 437), a wasm build names
/// its host (decision 334).
pub fn lookupName(config: configMod.Config) []const u8 {
    return switch (config.targetSource) {
        .commonJS => "node",
        .erlang, .beam => "erlang",
        .wasm => config.wasm_host.lookupName(),
    };
}

fn isBeam(lookup: []const u8) bool {
    return std.mem.eql(u8, lookup, "erlang") or std.mem.eql(u8, lookup, "beam");
}

/// The refusal of analysed module `ok` on the target `lookup` names, its
/// texts allocated with `arena`, or null when the target takes it.
pub fn refusalOf(arena: std.mem.Allocator, ok: ComptimeOutput.OkData, lookup: []const u8) !?TypeError {
    return refusalIn(arena, ok.std_host_calls, lookup);
}

/// The refusal of the std calls `calls` (in inference order) on the target
/// `lookup` names.
fn refusalIn(arena: std.mem.Allocator, calls: []const envMod.StdCall, lookup: []const u8) !?TypeError {
    for (calls) |call| {
        for (call.hosts) |h| if (ast.implementationFor(h.implementations, lookup) == null) {
            return located(try stdUnsupported(arena, call.module, call.name, h.name, lookup), call.site);
        };
    }
    return null;
}

/// The refusal of the target that comes before the refusal of a module's
/// analysis (`ComptimeOutput.target_trace`): a std call inference met before
/// the error — the one the module answered when inference read the target.
fn refusalBefore(arena: std.mem.Allocator, trace: *const envMod.TargetTrace, lookup: []const u8) !?TypeError {
    return refusalIn(arena, trace.calls.items, lookup);
}

/// `te` at `site`, as inference located its errors (a rewritten
/// constructor's call, decorator-added code at its annotation).
fn located(te: TypeError, site: envMod.TargetSite) TypeError {
    var out = te;
    out.loc = site.loc;
    out.origin = site.origin;
    out.frames = site.frames;
    return inlineTypes.locatedAtCall(out);
}

/// One module the target refused, and its analysis to hand back.
pub const Refusal = struct {
    index: usize,
    saved: ComptimeOutput.Outcome,
};

/// Turn each module of `outputs` the target refuses into a `typeError`
/// (texts in `arena`), answering what `restore` hands back.
pub fn apply(arena: std.mem.Allocator, outputs: []ComptimeOutput, lookup: []const u8) ![]const Refusal {
    var refused: std.ArrayListUnmanaged(Refusal) = .empty;
    for (outputs, 0..) |*o, i| switch (o.outcome) {
        .ok => |ok| if (try refusalOf(arena, ok, lookup)) |te| {
            try refused.append(arena, .{ .index = i, .saved = o.outcome });
            o.outcome = .{ .typeError = te };
        },
        .typeError, .validationError => if (o.target_trace) |trace| if (try refusalBefore(arena, trace, lookup)) |te| {
            try refused.append(arena, .{ .index = i, .saved = o.outcome });
            o.outcome = .{ .typeError = te };
        },
        .parseError => {},
    };
    return refused.items;
}

/// Hand the analysis `apply` replaced back to `outputs`.
pub fn restore(outputs: []ComptimeOutput, refused: []const Refusal) void {
    for (refused) |r| outputs[r.index].outcome = r.saved;
}

/// True when `name` is one of `refused`'s modules.
pub fn isRefused(outputs: []const ComptimeOutput, refused: []const Refusal, name: []const u8) bool {
    for (refused) |r| if (std.mem.eql(u8, outputs[r.index].name, name)) return true;
    return false;
}

/// `outputs` without `std/beam` when the target is not the BEAM and no
/// module imports it — the analysis holds it for every module-level `var`
/// (`comptime.zig` `expandStdImports`), which only the BEAM emitters lower
/// onto it. Null when nothing is left out. In `arena`.
pub fn withoutBeamStorage(arena: std.mem.Allocator, outputs: []const ComptimeOutput, lookup: []const u8) !?[]ComptimeOutput {
    if (isBeam(lookup)) return null;
    const at = for (outputs, 0..) |o, i| {
        if (std.mem.eql(u8, o.name, "std/beam")) break i;
    } else return null;
    for (outputs) |o| switch (o.outcome) {
        .ok => |ok| if (importsStdBeam(ok.transformed)) return null,
        else => {},
    };
    const out = try arena.alloc(ComptimeOutput, outputs.len - 1);
    @memcpy(out[0..at], outputs[0..at]);
    @memcpy(out[at..], outputs[at + 1 ..]);
    return out;
}

/// Copy back what the emit wrote into `kept` (an emitter may rewrite an
/// output in place) onto the outputs `withoutBeamStorage` took it from.
pub fn writeBack(outputs: []ComptimeOutput, kept: []const ComptimeOutput) void {
    var k: usize = 0;
    for (outputs) |*o| {
        if (k < kept.len and std.mem.eql(u8, o.name, kept[k].name)) {
            o.* = kept[k];
            k += 1;
        }
    }
}

/// An `import {beam…} from "std"` in `program`.
fn importsStdBeam(program: ast.Program) bool {
    for (program.decls) |d| switch (d) {
        .use => |u| {
            const from_std = switch (u.source) {
                .module => |m| std.mem.eql(u8, m, "std"),
                else => false,
            };
            if (!from_std) continue;
            for (u.imports) |imp| if (imp.segments.len > 0 and std.mem.eql(u8, imp.segments[0], "beam")) return true;
        },
        else => {},
    };
    return false;
}

/// `std-unsupported-on-target` speaks today's spellings: the binding is the
/// `.<Variant>(…)` implementation (`Node`, `Erlang`, `Wasm` — the beam target
/// reads `Erlang`'s, decision 437), and the target is the one `--target`
/// takes (`commonJS`, never the internal `node`). A wasm build names its host
/// too (decision 334): the lookup `wasm` is the `wasi` host's, `wasm.browser`
/// the `browser` host's, and the target reads `'wasm' on host 'wasi'`.
fn externalSpelling(arena: std.mem.Allocator, tgt: []const u8) !struct { member: []const u8, target: []const u8 } {
    const lookup = ast.ExternalLookup.of(tgt);
    const member: []const u8 = if (ast.Implementation.Target.ofMember(lookup.member)) |t| t.variant() else blk: {
        const m = try arena.dupe(u8, lookup.member);
        if (m.len > 0) m[0] = std.ascii.toUpper(m[0]);
        break :blk m;
    };
    const target = if (std.mem.eql(u8, lookup.member, "node"))
        "commonJS"
    else if (lookup.host) |h|
        try std.fmt.allocPrint(arena, "{s}' on host '{s}", .{ lookup.member, @tagName(h) })
    else
        lookup.member;
    return .{ .member = member, .target = target };
}

fn stdUnsupported(arena: std.mem.Allocator, mod_name: []const u8, name: []const u8, reached: []const u8, tgt: []const u8) !TypeError {
    const sp = try externalSpelling(arena, tgt);
    const msg = if (std.mem.eql(u8, name, reached))
        try std.fmt.allocPrint(arena, "{s}: std/{s}.{s} has no `.{s}(…)` implementation for target '{s}'", .{ diagnostics.std_unsupported_on_target, mod_name, name, sp.member, sp.target })
    else
        try std.fmt.allocPrint(arena, "{s}: std/{s}.{s} reaches `{s}`, which has no `.{s}(…)` implementation for target '{s}'", .{ diagnostics.std_unsupported_on_target, mod_name, name, reached, sp.member, sp.target });
    const hint = try std.fmt.allocPrint(arena, "The call is refused, not the import: the function reaches a host declaration with no binding for this target. Call it on a target the module supports (see libs/std/src/examples.md per-target coverage matrix), or give the declaration a `.{s}(…)` implementation (`#[external(…)]`).", .{sp.member});
    return TypeError.custom(msg, hint);
}
