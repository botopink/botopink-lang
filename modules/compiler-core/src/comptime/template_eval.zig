/// Runtime-backed template evaluation (expr-templates F6-full, slice 1).
///
/// When the V1 classifier in `infer.zig` cannot reduce a template body by
/// inspection, this module *runs* the body: the captures become JS objects
/// carrying the comptime surface (`text`/`parts`/`source`/`context`/`lookup`/
/// `bindings`/`build`/`fail`/`failAt`), the template fn is emitted as plain
/// JS (reusing the commonJS emitter), and the script reports one result:
///
///   {"kind":"code","source":"…"}                  ← build() / @code
///   {"kind":"value","value":<json>}               ← @expr(v)
///   {"kind":"capture","param":"template"}         ← `return template;`
///   {"kind":"custom","source":"…","ast":<json>}   ← custom(tree, code)
///   {"kind":"fail","message","param","span"}      ← fail()/failAt()
///   {"kind":"error","message"}                    ← anything else thrown
///
/// Template evaluation always uses the **node** runtime regardless of the
/// compile target — it is host-side comptime work, like the existing eval
/// backends (erlang parity is a recorded follow-up). Tooling paths
/// (compileTypesOnly / LSP) never reach this module.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const commonJS = @import("../codegen/commonJS.zig");

/// F8 — runtime dispatch for template body evaluation.
///
/// `node` (default): builds JS via `commonJS.emitFnJs` + the JS prelude in
/// `template_eval.zig`, runs through `persistent_node.eval`. Stable path,
/// covers every audit body today.
///
/// `wat`: builds WAT via `wat_runtime.prelude` + the wat backend's template
/// emitter, runs through `wasm3_host.runWat`. End-to-end path the spec
/// terminates at after F10 deletes `persistent_node.zig`. Currently gated
/// behind opt-in because F6's prelude has stub bodies for the descriptor
/// walker (`lookup`/`bindings`/`text` after expansion) and there is no
/// wat-side `emitFnJs` analogue yet — `evaluateWat` returns
/// `error.EvalFailed` so the caller transparently falls back to `node`.
pub const Runtime = enum { erl };

// ── outcome ───────────────────────────────────────────────────────────────────

pub const Outcome = union(enum) {
    /// Generated source text to parse and splice at the call site.
    code: []const u8,
    /// A comptime value to lift as a literal (JSON-encoded).
    value: std.json.Value,
    /// Pass-through of the named `@Expr` parameter's capture.
    capture: []const u8,
    /// `q.custom(tree, code)` — the executable `code` half (source text, spliced
    /// like `code` above) plus the reference `ast` tree (a JSON `CustomNode`,
    /// stored by call-location for tooling, never lowered). expr-custom.
    /// `root` is an optional pre-parsed tree from WAT memory (bypasses JSON).
    custom: struct {
        code: []const u8,
        ast: std.json.Value,
        root: ?template.CustomNode = null,
    },
    /// `fail`/`failAt` — abort expansion with a template diagnostic.
    fail: struct {
        message: []const u8,
        param: ?[]const u8,
        span: ?template.Span,
    },
    /// The script itself failed (JS exception, protocol violation, …).
    err: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

// ── JS prelude ────────────────────────────────────────────────────────────────
pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = build_root;
    return evaluateErl(arena, io, tfn, captures, plainArgs);
}

pub fn evaluateRuntime(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    runtime: Runtime,
) EvalError!Outcome {
    _ = runtime;
    _ = build_root;
    return evaluateErl(arena, io, tfn, captures, plainArgs);
}


fn evaluateErl(
    arena: std.mem.Allocator,
    io: std.Io,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError!Outcome {
    _ = arena;
    _ = io;
    _ = tfn;
    _ = captures;
    _ = plainArgs;
    return error.EvalFailed;
}
