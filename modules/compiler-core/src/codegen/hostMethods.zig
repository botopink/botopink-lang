//! Host-backed methods — a `declare fn` carrying `#[@External.<Target>(…)]`
//! written inside a `type` body:
//!
//! ```botopink
//! pub type Socket(handle: any) {
//!     #[@External.Node("…"), @External.Erlang("…")]
//!     pub declare fn recv(self: Self, length: i32) -> @Result<string, string>;
//! }
//! ```
//!
//! Every backend lowers one as a real method of the type whose body is the
//! host binding applied to the method's own parameters — the method twin of
//! the wrapper a `pub` module-level `declare fn` gets (erlang
//! `externalWrapperForm`, commonJS `buildTemplateWrapper`, beam
//! `emitHostWrapper`). A call site (`sock.recv(n)`) is then an ordinary method
//! call on every backend, local or imported, so nothing at the call site knows
//! the method is host-backed — except when the backend has NO binding for it:
//! then the method is not emitted and the call is refused where it is written,
//! with the `MissingExternal` diagnostic a module-level host function gets
//! (`missingAt`). The template markers were already translated by
//! `parser/template_markers.zig` — on a method whose first parameter is `self`,
//! `$0` is the receiver and `$N` the Nth argument after it, on every target.

const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("../comptime/env.zig");
const moduleOutput = @import("./moduleOutput.zig");
const CrossModule = @import("./crossModule.zig").CrossModule;

/// A bodyless `declare fn` member carrying an `#[@External.<Target>(…)]`.
pub fn isHostMethod(m: ast.BehaviorMethod) bool {
    return m.body == null and m.isExternal();
}

/// True when the method's first parameter is its receiver.
pub fn takesSelf(m: ast.BehaviorMethod) bool {
    return m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self");
}

/// The backends a host binding can name. `beam` reads `External.Beam` and
/// falls back to `External.Erlang` (one vocabulary, `docs.md` § Host bindings).
/// `wasm` binds nothing: wasm has no host.
pub const Target = enum {
    node,
    erlang,
    beam,
    wasm,

    pub fn backendName(t: Target) []const u8 {
        return switch (t) {
            .node => "node",
            .erlang => "erlang",
            .beam => "beam",
            .wasm => "wasm",
        };
    }
};

fn bindsAnnotation(m: ast.BehaviorMethod, target: []const u8) bool {
    if (m.externalFor(target) != null) return true;
    return ast.externalHasArityBranches(m.annotations, target);
}

/// True when `m` carries a binding the `target` backend reads.
pub fn binds(m: ast.BehaviorMethod, target: Target) bool {
    return switch (target) {
        .node => bindsAnnotation(m, "node"),
        .erlang => bindsAnnotation(m, "erlang"),
        // `lowerExternalCall` reads an `External.Beam` body only on a
        // declaration without a receiver; a method taking `self` falls back to
        // its erlang binding.
        .beam => bindsAnnotation(m, "erlang") or (bindsAnnotation(m, "beam") and !takesSelf(m)),
        // wasm has no host (`docs.md` § Host bindings): nothing binds there.
        .wasm => false,
    };
}

/// `"<Type>.<method>"` — the index key and the name a refusal quotes. A
/// botopink identifier holds no `.`, so no module-level name collides with it.
pub fn keyOf(alloc: std.mem.Allocator, type_name: []const u8, method: []const u8) ![]u8 {
    return std.fmt.allocPrint(alloc, "{s}.{s}", .{ type_name, method });
}

/// The refusal of a call `recv.<callee>(…)` at `loc` whose receiver inference
/// typed as a `type` (`InstanceLowering.type_`) declaring `callee` as a host
/// method with no binding for `target`. Null when the call is anything else.
/// The name the diagnostic quotes is owned by `cross`, which outlives the
/// emitter that records it.
pub fn missingAt(
    cross: ?*const CrossModule,
    lowerings: ?*const std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    loc: ast.Loc,
    callee: []const u8,
    target: Target,
) ?moduleOutput.MissingExternal {
    const xc = cross orelse return null;
    if (xc.host_methods.count() == 0) return null;
    const lw = lowerings orelse return null;
    const type_name = switch (lw.get(loc) orelse return null) {
        .type_ => |t| t,
        else => return null,
    };
    var buf: [512]u8 = undefined;
    const key = std.fmt.bufPrint(&buf, "{s}.{s}", .{ type_name, callee }) catch return null;
    const entry = xc.host_methods.getEntry(key) orelse return null;
    if (binds(entry.value_ptr.*, target)) return null;
    return .{ .name = entry.key_ptr.*, .target = target.backendName(), .loc = loc };
}

test "binds: beam falls back to the erlang binding, wasm binds nothing" {
    var args = [_][]const u8{"\"x\""};
    var anns = [_]ast.Annotation{.{ .name = "External.Erlang", .args = &args }};
    const m: ast.BehaviorMethod = .{ .name = "m", .annotations = &anns, .params = &.{}, .body = null, .is_declare = true };
    try std.testing.expect(isHostMethod(m));
    try std.testing.expect(binds(m, .erlang));
    try std.testing.expect(binds(m, .beam));
    try std.testing.expect(!binds(m, .node));
    try std.testing.expect(!binds(m, .wasm));
}
