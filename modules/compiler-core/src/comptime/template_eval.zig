/// Template evaluation in the persistent erl runtime.
///
/// When the V1 classifier in `infer.zig` cannot reduce a template body by
/// inspection, the body runs here:
///
///   template `FnDecl` ─ codegen/erlang.zig `emitComptimeModule` ─ `main/1` → .erl
///   captures + plain args ─ `Term` ─ comptime/runtime/etf ─ external term ─┐
///     → comptime/runtime/persistent_erl `evalWithArg` (compile+load once,   │
///       then call `<module>:main(<term>)` per call site) ←─────────────────┘
///     → JSON reply → `Outcome`
///
/// The generated module carries the lowered body, the `'__bp_prim_…'` shims its
/// method calls reached and `main/1` — nothing else. The capture API, the result
/// constructors, the failure throws and the reply encoder are resident in
/// `bp_comptime_template`, built once at server warmup
/// (`runtime/prelude.zig`), and reached by the `-import` `emitComptimeModule`
/// writes, so the body's own text is the same either way. **Nothing in the
/// module depends on the call site**, so its content hash is a hash of the
/// declaration: one `.erl` per template however many times it is called.
///
/// Reply format (`main/1`):
///   {"kind":"code","source":"…"}                  ← `q.build(src)` / `@code(src)`
///   {"kind":"value","value":<json>}               ← `@expr(v)`
///   {"kind":"capture","param":"q"}                ← `return q`
///   {"kind":"custom","source":"…","ast":<tree>}   ← `q.custom(tree, code)`
///   {"kind":"fail","message","param","span"}      ← `q.fail` / `q.failAt` / `@compilerError`
///   {"kind":"error","message"}                    ← anything else raised
///
/// A capture reaches the body as a map — `main/1`'s argument, not a literal; its
/// methods (`q.text()`, `q.parts()`, `q.lookup(name)`, …) lower to the resident
/// host functions.
const std = @import("std");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const erlang = @import("../codegen/erlang.zig");
const crossModule = @import("../codegen/crossModule.zig");
const Ast = @import("../codegen/beam/erl_ast.zig");
const Term = @import("../codegen/beam/term.zig").Term;
const erlEmitter = @import("../codegen/beam/erl_emitter.zig");
const persistent_erl = @import("./runtime/persistent_erl.zig");
const preludeMod = @import("./runtime/prelude.zig");
const etf = @import("./runtime/etf.zig");
const trace = @import("./trace.zig");

/// Sole comptime runtime.
pub const Runtime = enum { erl };

// ── results ───────────────────────────────────────────────────────────────────

/// A value lifted by `@expr(…)`.
pub const TypedValue = union(enum) {
    integer: i64,
    float: f64,
    string: []const u8,
    bool: bool,
    null: void,
    array: []const TypedValue,
    /// An Erlang tuple, sent as `{"$tuple": [...]}` by `'__bp_json'/1`.
    tuple: []const TypedValue,
    object: []const KeyValuePair,

    pub const KeyValuePair = struct {
        key: []const u8,
        value: TypedValue,
    };
};

/// A `CustomNode` tree returned through `q.custom(tree, code)`.
pub const CustomNodeTree = struct {
    kind: []const u8,
    span: ?template.Span = null,
    label: ?[]const u8 = null,
    ref: ?template.NodeBinding = null,
    children: []const CustomNodeTree = &.{},
};

pub const Outcome = union(enum) {
    code: []const u8,
    value: TypedValue,
    capture: []const u8,
    custom: struct { code: []const u8, ast: CustomNodeTree },
    fail: struct {
        message: []const u8,
        param: ?[]const u8,
        span: ?template.Span,
    },
    err: []const u8,
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

/// Longest compiler/runtime diagnostic carried into `Outcome.err`.
const max_error_detail = 4096;

// ── evaluate ──────────────────────────────────────────────────────────────────

pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    /// Receives what was sent to and returned by the runtime (snapshots); null skips it.
    traces: ?*std.ArrayListUnmanaged(trace.Entry),
) EvalError!Outcome {
    _ = build_root;
    var unsupported: erlang.UnsupportedMethod = .{};
    const source = buildModule(arena, tfn, captures, plainArgs, &unsupported) catch |err| switch (err) {
        error.UnsupportedMethod => return .{ .err = try unsupportedText(arena, "template", tfn.name, unsupported) },
        else => |e| return e,
    };

    const path = try ensureModule(arena, io, ".botopinkbuild/tmp/template", source.module, source.code);

    const response = persistent_erl.evalWithArg(
        arena,
        io,
        path,
        source.module,
        try etf.encode(arena, source.argument),
    ) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return transportFailure(arena, "template", err),
    };
    if (traces) |list| try list.append(arena, .{
        .kind = .template,
        .name = tfn.name,
        .erl = source.listing,
        .reply = switch (response) {
            .ok => |stdout| stdout,
            .compile_error => |detail| try std.fmt.allocPrint(arena, "compile error: {s}", .{detail}),
            .runtime_error => |detail| try std.fmt.allocPrint(arena, "runtime error: {s}", .{detail}),
        },
    });
    return switch (response) {
        .ok => |stdout| parseOutcome(arena, stdout),
        .compile_error => |detail| .{ .err = try errorText(arena, "the template module did not compile", detail) },
        .runtime_error => |detail| .{ .err = try errorText(arena, "the template body raised", detail) },
    };
}

// ── one module, once per process ──────────────────────────────────────────────
//
// After step 2 a module's atom is the hash of code that carries nothing from the
// call site, so every call site of one declaration derives the same atom, the
// same bytes on disk and the same listing. `emitComptimeModule` re-parses the
// embedded `primitives.bp` and `erlang_bifs.d.bp` preludes on every emit
// (`codegen/erlang.zig`'s `collectPrimErlangDispatch` and
// `loadAutoImportedBifsFromPrelude`, both documented as throwaway per emit), so
// re-rendering a module the process has already rendered is the single most
// expensive thing left in an evaluation: **16.1 ms**, measured over 20
// `buildModule` calls.
//
// This registry removes the repeats. It is keyed by the module atom — the
// content hash of the compilable module — so a hit is the same text by
// construction, never a guess about declaration identity. Entries are
// process-lifetime and bounded by the declarations in the build, not by the call
// sites.

const Rendered = struct {
    /// The listing without the argument comment: the part that is the same for
    /// every call site (`listingWithArgument` adds the rest per evaluation).
    listing: []const u8,
};

/// Serialises the registry. An atomic spin-lock, as `runtime/persistent_erl.zig`
/// uses for the pipes: the critical sections are a hash lookup and an insert,
/// and parallel test binaries are the only contenders.
var rendered_lock: std.atomic.Value(u8) = .init(0);
var rendered_modules: std.StringHashMapUnmanaged(Rendered) = .empty;
/// Registry storage outlives every caller arena and is never freed.
const rendered_alloc = std.heap.page_allocator;

fn lockRendered() void {
    while (rendered_lock.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
}

fn unlockRendered() void {
    rendered_lock.store(0, .release);
}

/// The cached listing of `module`, or null when this process has not rendered it.
pub fn cachedListing(module: []const u8) ?[]const u8 {
    lockRendered();
    defer unlockRendered();
    const entry = rendered_modules.get(module) orelse return null;
    return entry.listing;
}

/// Record `listing` for `module` and return the stored copy.
pub fn rememberListing(module: []const u8, listing: []const u8) std.mem.Allocator.Error![]const u8 {
    const key = try rendered_alloc.dupe(u8, module);
    errdefer rendered_alloc.free(key);
    const owned = try rendered_alloc.dupe(u8, listing);
    errdefer rendered_alloc.free(owned);

    lockRendered();
    defer unlockRendered();
    const slot = try rendered_modules.getOrPut(rendered_alloc, key);
    if (slot.found_existing) {
        // Another thread rendered the same module first; its text is this text.
        rendered_alloc.free(key);
        rendered_alloc.free(owned);
        return slot.value_ptr.listing;
    }
    slot.value_ptr.* = .{ .listing = owned };
    return owned;
}

/// Stage `<dir>/<module>.erl` unless it is already there, and return its path
/// either way. The atom **is** the content's hash, and `writeModule` stages and
/// renames, so a file at that path is that content, complete — a second call
/// site of one declaration would rewrite the same bytes. The check is a single
/// `access`, and asking the filesystem rather than remembering means a cleared
/// `.botopinkbuild/` or a changed working directory mid-process writes the file
/// again instead of pointing the node at one that is gone.
pub fn ensureModule(arena: std.mem.Allocator, io: std.Io, dir: []const u8, module: []const u8, code: []const u8) EvalError![]const u8 {
    const path = try std.fmt.allocPrint(arena, "{s}/{s}.erl", .{ dir, module });
    if (std.Io.Dir.cwd().access(io, path, .{})) |_| return path else |_| {}
    return writeModule(arena, io, dir, module, code);
}

/// Write `<dir>/<module>.erl` and return its path. The module is written to a
/// uniquely named sibling first and renamed into place, so a reader never sees
/// a partial file: two evaluations of the same body — concurrent tests, or two
/// compiler processes sharing a working directory — derive the same
/// content-hashed name, and a plain truncate-and-write let one `compile:file`
/// read the file mid-rewrite and fail with no usable diagnostic.
pub fn writeModule(arena: std.mem.Allocator, io: std.Io, dir: []const u8, module: []const u8, code: []const u8) EvalError![]const u8 {
    const cwd = std.Io.Dir.cwd();
    cwd.createDirPath(io, dir) catch return error.EvalFailed;
    const path = try std.fmt.allocPrint(arena, "{s}/{s}.erl", .{ dir, module });
    var nonce: [8]u8 = undefined;
    io.random(&nonce);
    const staging = try std.fmt.allocPrint(arena, "{s}.{x}.tmp", .{ path, std.mem.readInt(u64, &nonce, .little) });
    cwd.writeFile(io, .{ .sub_path = staging, .data = code }) catch return error.EvalFailed;
    cwd.rename(staging, cwd, path, io) catch {
        cwd.deleteFile(io, staging) catch {};
        return error.EvalFailed;
    };
    return path;
}

/// What a failed round trip reports. Every transport failure used to collapse
/// into `error.EvalFailed`, which left `persistent_erl.lastTransportError()`
/// dead and the caller's diagnostic — "the template evaluator failed to run" —
/// with nothing behind it (1.0.4-beta's hygiene front recorded this residual
/// inside this file and could not sweep it).
///
/// Now the message is carried when there is one. When there is not, the failure
/// is `erl` or `erlc` missing rather than a broken stream, and `error.EvalFailed`
/// is still the right answer: the caller's hint for that case names PATH, which
/// is more useful than an error name.
fn transportFailure(arena: std.mem.Allocator, host: []const u8, err: anyerror) EvalError!Outcome {
    const detail = persistent_erl.lastTransportError() orelse return error.EvalFailed;
    return .{ .err = try std.fmt.allocPrint(
        arena,
        "the {s} evaluator's erl runtime failed ({s}): {s}",
        .{ host, @errorName(err), detail },
    ) };
}

fn errorText(arena: std.mem.Allocator, what: []const u8, detail: []const u8) ![]const u8 {
    const shown = detail[0..@min(detail.len, max_error_detail)];
    const ellipsis = if (detail.len > max_error_detail) " …" else "";
    return std.fmt.allocPrint(arena, "{s}: {s}{s}", .{ what, shown, ellipsis });
}

/// The diagnostic for a body method call nothing answers (`erlang.UnsupportedMethod`).
fn unsupportedText(arena: std.mem.Allocator, host: []const u8, name: []const u8, m: erlang.UnsupportedMethod) ![]const u8 {
    return std.fmt.allocPrint(
        arena,
        "the {s} `{s}` calls `.{s}(…)` with {d} argument(s) at {d}:{d}, which no primitive type (string, array, int, float, bool) and no {s} host function provides",
        .{ host, name, m.callee, m.argc, m.loc.line, m.loc.col, host },
    );
}

// ── module ────────────────────────────────────────────────────────────────────

const Module = struct {
    /// Erlang module atom derived from the code's hash. The code carries no
    /// capture, so every call site of one declaration derives the same atom.
    module: []const u8,
    code: []const u8,
    /// The lowered body and `main/1`, with the argument as a comment
    /// (`trace.Entry.erl`).
    listing: []const u8,
    /// `main/1`'s argument: one tuple element per parameter.
    argument: Term,
};

/// How one parameter of the body reaches it.
pub const ArgPlan = struct {
    /// The value in `main/1`'s argument tuple.
    term: Term,
    /// What the call in `main/1` writes for this parameter — the bound
    /// `ArgN`, or the literal itself when `term` is a placeholder.
    expr: Ast.Expr,
    /// Whether `main/1`'s head binds this slot.
    bound: bool,
};

/// `main/1`'s head pattern: `{Arg0, _, Arg2}`, or `_Args` for a body that takes
/// no parameter at all.
pub fn mainPattern(b: Ast.Builder, plans: []const ArgPlan) Ast.Builder.Error!Ast.Expr {
    if (plans.len == 0) return Ast.Expr.v("_Args");
    const patterns = try b.arena.alloc(Ast.Expr, plans.len);
    for (plans, 0..) |plan, i| {
        patterns[i] = if (plan.bound) Ast.Expr.v(try argVar(b.arena, i)) else Ast.Expr.v("_");
    }
    return b.tuple(patterns);
}

/// The term `main/1` is called with: one element per parameter, in order.
pub fn argumentTerm(arena: std.mem.Allocator, plans: []const ArgPlan) std.mem.Allocator.Error!Term {
    const items = try arena.alloc(Term, plans.len);
    for (plans, 0..) |plan, i| items[i] = plan.term;
    return Term.tupleOf(items);
}

fn argVar(arena: std.mem.Allocator, index: usize) std.mem.Allocator.Error![]const u8 {
    return std.fmt.allocPrint(arena, "Arg{d}", .{index});
}

/// A plain argument as a term, or null when its lexeme cannot be turned into
/// one exactly — then it stays a literal in the module, which is correct but
/// keys the module by that literal as well as by the code.
///
/// The only such lexeme today is one carrying `\u{…}`: `erl_emitter`'s
/// `writeStringFromLexeme` renders it as Erlang's `\x{…}`, which inside a plain
/// `<<"…">>` **truncates the code point to one byte** (`<<"a\x{263A}b">>` is
/// `<<97,58,98>>`). Reproducing that here would be a second definition of what a
/// botopink string literal means, and a wrong one; leaving the literal in the
/// module keeps the single definition in the emitter.
pub fn plainArgTerm(arena: std.mem.Allocator, pa: template.PlainArg) std.mem.Allocator.Error!?Term {
    const text = std.mem.trim(u8, pa.source, " \t\r\n");
    if (text.len >= 2 and text[0] == '"' and text[text.len - 1] == '"') {
        return if (try lexemeBytes(arena, text[1 .. text.len - 1])) |bytes| Term.str(bytes) else null;
    }
    if (std.mem.eql(u8, text, "true")) return .{ .boolean = true };
    if (std.mem.eql(u8, text, "false")) return .{ .boolean = false };
    if (std.fmt.parseInt(i64, text, 10)) |n| return Term.int(n) else |_| {}
    if (std.fmt.parseFloat(f64, text)) |f| {
        if (std.math.isFinite(f)) return .{ .float = f };
    } else |_| {}
    // `PlainArg.toExpr` reaches `Ast.str(text)` here — a binary of the raw
    // source bytes, which is the same value.
    return Term.str(text);
}

/// The bytes a string literal's lexer content stands for — the value side of
/// `erl_emitter.writeStringFromLexeme`, which writes the same thing as Erlang
/// source. Null when the lexeme carries `\u{…}` (see `plainArgTerm`).
fn lexemeBytes(arena: std.mem.Allocator, s: []const u8) std.mem.Allocator.Error!?[]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    while (i < s.len) {
        if (s[i] != '\\' or i + 1 >= s.len) {
            try out.append(arena, s[i]);
            i += 1;
            continue;
        }
        switch (s[i + 1]) {
            'n' => try out.append(arena, '\n'),
            'r' => try out.append(arena, '\r'),
            't' => try out.append(arena, '\t'),
            '0' => try out.append(arena, 0),
            '\\' => try out.append(arena, '\\'),
            '"' => try out.append(arena, '"'),
            '$' => try out.append(arena, '$'),
            'u' => return null,
            // An unknown escape keeps the backslash and re-reads the next byte
            // as itself, exactly as the emitter does.
            else => {
                try out.append(arena, '\\');
                i += 1;
                continue;
            },
        }
        i += 2;
    }
    return out.items;
}

/// The listing with `main/1`'s argument under it, one commented `ArgN = …` per
/// tuple element. The capture is no longer part of the module, and a snapshot
/// that showed it has to keep showing it — it is the input half of the
/// evaluation the reply answers.
///
/// Each element goes through `writeExpr`, not `writeTerm`: the expression writer
/// is the one that wraps a map or a list over several lines, so a capture reads
/// in a snapshot exactly as it read when it was a literal inside `main/0`.
/// `writeTermAt` does not wrap a tuple, which is why the tuple is unpacked here
/// rather than printed whole.
pub fn listingWithArgument(arena: std.mem.Allocator, listing: []const u8, argument: Term) EvalError![]const u8 {
    var out: std.Io.Writer.Allocating = .init(arena);
    const w = &out.writer;
    try w.writeAll(listing);
    try w.writeAll("\n%% main/1 argument — an external term, not part of the module");
    if (argument.tuple.len == 0) {
        try w.writeAll(": {}\n");
        return out.written();
    }
    try w.writeAll(":\n");

    for (argument.tuple, 0..) |element, i| {
        var text: std.Io.Writer.Allocating = .init(arena);
        erlEmitter.writeExpr(&text.writer, Ast.Expr.t(element), 0) catch return error.EvalFailed;
        var lines = std.mem.splitScalar(u8, text.written(), '\n');
        var first = true;
        while (lines.next()) |line| {
            if (first) {
                try w.print("%% Arg{d} = {s}\n", .{ i, line });
                first = false;
            } else {
                try w.print("%% {s}\n", .{line});
            }
        }
    }
    return out.written();
}

/// The owning module of a comptime-evaluated body, for A2's atom.
///
/// It SHOULD be the path of the `.bp` file the template was declared in
/// (`ui/panel` → `ui@panel__tpl__<decl>__<hash>`), which is what makes a stack
/// trace and a `.botopinkbuild/tmp/template/` listing traceable back to source.
/// That path does not reach here: the evaluator is handed the declaration
/// (`ast.FnDecl`, whose `Loc` carries a line and a column and no file) and the
/// template registry (`comptime.zig`, a `StringHashMap(ast.FnDecl)`) records no
/// owner either, so threading it needs the module name on
/// `env.TemplateEvalCtx` — `src/comptime/env.zig` and `src/comptime.zig`, which
/// this front does not own. Until that carve-out, every comptime body is owned
/// by one synthetic path, and the atom still names WHICH template it came from,
/// which `template_<hash>` did not.
pub const comptime_owner: crossModule.ModuleId = .of("bp/comptime");

const placeholder_module = "template_module";

/// Records of the `std.syntax` template model a body may construct.
const host_records = [_]erlang.HostRecord{
    .{ .name = "Span", .fields = &.{ "start", "end", "line" } },
    .{ .name = "CustomNode", .fields = &.{ "kind", "span", "label", "ref", "children" } },
    .{ .name = "Binding", .fields = &.{ "name", "kind" } },
    .{ .name = "Source", .fields = &.{ "file", "line", "col" } },
    .{ .name = "ExprContext", .fields = &.{ "source", "text", "multiline" } },
};

/// `main/1` — the evaluator entry: it destructures the argument tuple, calls the
/// body with it and answers the JSON reply. The capture API, the result
/// constructors, the failure throws and `'__bp_reply'/1` are resident
/// (`runtime/prelude.zig`), reached by the `-import` `emitComptimeModule`
/// writes. Nothing here depends on the call site any more — that is what makes
/// the module's hash a hash of the declaration.
fn mainForms(b: Ast.Builder, tfn: ast.FnDecl, plans: []const ArgPlan) EvalError![]const Ast.Form {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    const fail_tag = A(preludeMod.template_fail_tag);

    const args = try b.arena.alloc(Ast.Expr, plans.len);
    for (plans, 0..) |plan, i| args[i] = plan.expr;
    const invoke: Ast.Expr = .{ .call = .{ .name = tfn.name, .args = args } };

    const json = struct {
        fn encode(bb: Ast.Builder, fields: []const Ast.MapField) Ast.Builder.Error!Ast.Expr {
            return bb.remote("json", "encode", &.{try bb.map(fields)});
        }
    }.encode;

    var forms: std.ArrayListUnmanaged(Ast.Form) = .empty;

    const main_body = try b.body(&.{.{ .try_catch = .{
        .body = try b.body(&.{try b.remote("json", "encode", &.{try b.call("__bp_reply", &.{invoke})})}),
        .catches = try b.arena.dupe(Ast.Clause, &.{
            .{
                .patterns = try b.exprs(&.{try b.exception(A("throw"), try b.tuple(&.{ fail_tag, V("Message"), V("Param"), V("Span") }))}),
                .body = try b.body(&.{try json(b, &.{
                    Ast.field("kind", Ast.str("fail")),
                    Ast.field("message", try b.call("__bp_text", &.{V("Message")})),
                    Ast.field("param", V("Param")),
                    Ast.field("span", try b.call("__bp_json", &.{V("Span")})),
                })}),
            },
            .{
                .patterns = try b.exprs(&.{try b.exception(V("Class"), V("Reason"))}),
                .body = try b.body(&.{try json(b, &.{
                    Ast.field("kind", Ast.str("error")),
                    Ast.field("message", try b.call("__bp_text", &.{try b.tuple(&.{ V("Class"), V("Reason") })})),
                })}),
            },
        }),
    } }});
    try forms.append(b.arena, .{ .function = .{
        .name = "main",
        .clauses = try b.arena.dupe(Ast.Clause, &.{.{
            .patterns = try b.exprs(&.{try mainPattern(b, plans)}),
            .body = main_body,
        }}),
    } });
    return forms.items;
}

fn buildModule(
    arena: std.mem.Allocator,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    unsupported: *erlang.UnsupportedMethod,
) (EvalError || error{UnsupportedMethod})!Module {
    const b: Ast.Builder = .{ .arena = arena };
    const plans = try argPlans(arena, tfn, captures, plainArgs);
    const forms = try mainForms(b, tfn, plans);
    const resident = try preludeMod.templateForms(b);

    const decls = try arena.alloc(ast.DeclKind, 1);
    decls[0] = .{ .@"fn" = tfn };
    var config: erlang.ComptimeModule = .{
        .host_enums = &.{ "BindingKind", "DeclKind" },
        .host_records = &host_records,
        .exports = &.{.{ .name = "main", .arity = 1 }},
        .forms = forms,
        .resident = .{
            .module = preludeMod.template_module,
            .forms = resident,
            .refs = try preludeMod.exportRefs(arena, resident),
        },
        .unsupported_method = unsupported,
    };
    const code = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, config) catch |err|
        return if (err == error.UnsupportedComptimeMethod) error.UnsupportedMethod else error.EvalFailed;
    const argument = try argumentTerm(arena, plans);
    // A2: `bp@comptime__tpl__<template>__<16 hex>`. The Wyhash is unchanged, so
    // an identical generated body is still the identical module and re-loading
    // it is still a no-op (`runtime/persistent_erl.zig`).
    const module = crossModule.erlDeclAtom(arena, comptime_owner, .tpl, tfn.name, std.hash.Wyhash.hash(0, code)) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return error.EvalFailed,
    };
    const header = "-module(" ++ placeholder_module ++ ").";
    if (!std.mem.startsWith(u8, code, header)) return error.EvalFailed;
    const renamed = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] });

    // What snapshots show: the lowered body, `main/1` and the argument as a
    // comment. `resident` stays set: it decides where a method call lowers, so
    // dropping it would make the listing diverge from the module that ran.
    // Rendered once per module (`Rendered`), not once per call site.
    const listing = cachedListing(module) orelse blk: {
        config.listing = true;
        const fresh = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, config) catch return error.EvalFailed;
        break :blk try rememberListing(module, fresh);
    };
    return .{
        .module = module,
        .code = renamed,
        .listing = try listingWithArgument(arena, listing, argument),
        .argument = argument,
    };
}

/// How each parameter of `tfn` reaches the body. A captured `@Expr` is always a
/// term; a plain argument is one too unless its lexeme has no exact term
/// (`plainArgTerm`), in which case it stays a literal in the module; a parameter
/// the call site gave neither is `undefined`.
fn argPlans(
    arena: std.mem.Allocator,
    tfn: ast.FnDecl,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) EvalError![]const ArgPlan {
    const plans = try arena.alloc(ArgPlan, tfn.params.len);
    for (tfn.params, 0..) |p, i| {
        plans[i] = .{ .term = Term.undefined_atom, .expr = Ast.Expr.a("undefined"), .bound = false };
        var matched = false;
        for (captures) |*cap| {
            if (cap.paramIndex != i) continue;
            plans[i] = .{
                .term = try captureToTerm(arena, cap),
                .expr = Ast.Expr.v(try argVar(arena, i)),
                .bound = true,
            };
            matched = true;
            break;
        }
        if (matched) continue;
        for (plainArgs) |pa| {
            if (!std.mem.eql(u8, pa.paramName, p.name)) continue;
            plans[i] = if (try plainArgTerm(arena, pa)) |t|
                .{ .term = t, .expr = Ast.Expr.v(try argVar(arena, i)), .bound = true }
            else
                .{ .term = Term.undefined_atom, .expr = pa.toExpr(), .bound = false };
            break;
        }
    }
    return plans;
}

// ── capture ───────────────────────────────────────────────────────────────────

/// A capture as the map its host functions read:
/// `#{'__bp_capture' => Param, text, parts, source, context, bindings}`.
/// Text is the literal's raw text (escapes unprocessed); in a template with
/// `${…}` holes each hole appears as its `__bp_hole_<param>_<i>` placeholder,
/// which `infer.zig` substitutes back when the built code is spliced.
pub fn captureToTerm(arena: std.mem.Allocator, cap: *const template.CapturedExpr) std.mem.Allocator.Error!Term {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    var parts: std.ArrayListUnmanaged(Term) = .empty;

    switch (cap.node.*) {
        .literal => |lit| switch (lit.kind) {
            .stringTemplate => |st| {
                var hole: usize = 0;
                for (st.parts) |part| switch (part) {
                    .text => |t| {
                        const start = text.items.len;
                        try text.appendSlice(arena, t);
                        try parts.append(arena, try partTerm(arena, "Text", "text", t, text.items, start));
                    },
                    .expr => {
                        const placeholder = try std.fmt.allocPrint(arena, "__bp_hole_{s}_{d}", .{ cap.paramName, hole });
                        hole += 1;
                        const start = text.items.len;
                        try text.appendSlice(arena, placeholder);
                        try parts.append(arena, try partTerm(arena, "Interp", "code", placeholder, text.items, start));
                    },
                };
            },
            else => {
                const t = cap.text orelse "";
                try text.appendSlice(arena, t);
                if (t.len > 0) try parts.append(arena, try partTerm(arena, "Text", "text", t, text.items, 0));
            },
        },
        else => {
            const t = cap.text orelse "";
            try text.appendSlice(arena, t);
            if (t.len > 0) try parts.append(arena, try partTerm(arena, "Text", "text", t, text.items, 0));
        },
    }

    const source_entries = try arena.alloc(Term.MapEntry, 3);
    source_entries[0] = Term.field("file", Term.str(cap.modulePath));
    source_entries[1] = Term.field("line", Term.int(@intCast(cap.loc.line)));
    source_entries[2] = Term.field("col", Term.int(@intCast(cap.loc.col)));
    const source = Term.mapOf(source_entries);

    const context_entries = try arena.alloc(Term.MapEntry, 3);
    context_entries[0] = Term.field("source", source);
    context_entries[1] = Term.field("text", Term.str(text.items));
    context_entries[2] = Term.field("multiline", .{ .boolean = cap.multiline });

    var bindings: std.ArrayListUnmanaged(Term) = .empty;
    if (cap.scope) |scope| {
        var it = scope.entries.iterator();
        while (it.next()) |e| {
            const be = try arena.alloc(Term.MapEntry, 2);
            be[0] = Term.field("name", Term.str(e.value_ptr.name));
            be[1] = Term.field("kind", Term.atomOf(e.value_ptr.kind.variantName()));
            try bindings.append(arena, Term.mapOf(be));
        }
    }

    const entries = try arena.alloc(Term.MapEntry, 6);
    entries[0] = .{ .key = Term.atomOf("__bp_capture"), .value = Term.str(cap.paramName) };
    entries[1] = Term.field("text", Term.str(text.items));
    entries[2] = Term.field("parts", Term.listOf(parts.items));
    entries[3] = Term.field("source", source);
    entries[4] = Term.field("context", Term.mapOf(context_entries));
    entries[5] = Term.field("bindings", Term.listOf(bindings.items));
    return Term.mapOf(entries);
}

/// `#{kind => Kind, <field> => Value, span => #{start, end, line}}` for the part
/// occupying `text[start..]`.
fn partTerm(arena: std.mem.Allocator, kind: []const u8, field: []const u8, value: []const u8, text: []const u8, start: usize) !Term {
    const line = 1 + std.mem.count(u8, text[0..start], "\n");
    const span = try arena.alloc(Term.MapEntry, 3);
    span[0] = Term.field("start", Term.int(@intCast(start)));
    span[1] = Term.field("end", Term.int(@intCast(text.len)));
    span[2] = Term.field("line", Term.int(@intCast(line)));
    const entries = try arena.alloc(Term.MapEntry, 3);
    entries[0] = Term.field("kind", Term.str(kind));
    entries[1] = Term.field(field, Term.str(value));
    entries[2] = Term.field("span", Term.mapOf(span));
    return Term.mapOf(entries);
}

// ── outcome ───────────────────────────────────────────────────────────────────

/// The JSON object `main/0` returns.
const Reply = struct {
    kind: []const u8,
    source: []const u8 = "",
    param: ?[]const u8 = null,
    message: []const u8 = "",
    span: ?template.Span = null,
    value: std.json.Value = .null,
    ast: std.json.Value = .null,
};

fn parseOutcome(arena: std.mem.Allocator, stdout: []const u8) EvalError!Outcome {
    const reply = std.json.parseFromSliceLeaky(Reply, arena, stdout, .{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    }) catch return .{ .err = try errorText(arena, "the template evaluator returned an unreadable result", stdout) };

    const kind = reply.kind;
    if (std.mem.eql(u8, kind, "code")) return .{ .code = reply.source };
    if (std.mem.eql(u8, kind, "value")) return .{ .value = try typedValue(arena, reply.value) };
    if (std.mem.eql(u8, kind, "capture")) return .{ .capture = reply.param orelse "" };
    if (std.mem.eql(u8, kind, "custom")) {
        const tree = (try customTree(arena, reply.ast)) orelse
            return .{ .err = "`q.custom` received a tree that is not a CustomNode" };
        return .{ .custom = .{ .code = reply.source, .ast = tree } };
    }
    if (std.mem.eql(u8, kind, "fail")) return .{ .fail = .{
        .message = if (reply.message.len > 0) reply.message else "template rejected the input",
        .param = reply.param,
        .span = reply.span,
    } };
    return .{ .err = if (reply.message.len > 0) reply.message else "template evaluation failed" };
}

fn typedValue(arena: std.mem.Allocator, v: std.json.Value) std.mem.Allocator.Error!TypedValue {
    return switch (v) {
        .null => .null,
        .bool => |b| .{ .bool = b },
        .integer => |n| .{ .integer = n },
        .float => |f| .{ .float = f },
        .number_string, .string => |s| .{ .string = s },
        .array => |items| blk: {
            const out = try arena.alloc(TypedValue, items.items.len);
            for (items.items, 0..) |item, i| out[i] = try typedValue(arena, item);
            break :blk .{ .array = out };
        },
        .object => |obj| blk: {
            if (obj.count() == 1) {
                if (obj.get("$tuple")) |items| if (items == .array) {
                    const out = try arena.alloc(TypedValue, items.array.items.len);
                    for (items.array.items, 0..) |item, i| out[i] = try typedValue(arena, item);
                    break :blk .{ .tuple = out };
                };
            }
            const out = try arena.alloc(TypedValue.KeyValuePair, obj.count());
            var it = obj.iterator();
            var i: usize = 0;
            while (it.next()) |e| : (i += 1) {
                out[i] = .{ .key = e.key_ptr.*, .value = try typedValue(arena, e.value_ptr.*) };
            }
            break :blk .{ .object = out };
        },
    };
}

fn customTree(arena: std.mem.Allocator, v: std.json.Value) std.mem.Allocator.Error!?CustomNodeTree {
    const obj = switch (v) {
        .object => |o| o,
        else => return null,
    };
    const kind = jsonString(obj.get("kind")) orelse return null;

    const span: ?template.Span = if (obj.get("span")) |sv| switch (sv) {
        .object => |so| .{
            .start = jsonUsize(so.get("start")) orelse 0,
            .end = jsonUsize(so.get("end")) orelse 0,
            .line = jsonUsize(so.get("line")) orelse 1,
        },
        else => null,
    } else null;

    const ref: ?template.NodeBinding = if (obj.get("ref")) |rv| switch (rv) {
        .object => |ro| if (jsonString(ro.get("name"))) |name| .{
            .name = name,
            .kind = jsonString(ro.get("kind")) orelse "",
        } else null,
        else => null,
    } else null;

    var children: []const CustomNodeTree = &.{};
    if (obj.get("children")) |cv| switch (cv) {
        .array => |items| {
            const out = try arena.alloc(CustomNodeTree, items.items.len);
            var n: usize = 0;
            for (items.items) |item| {
                if (try customTree(arena, item)) |child| {
                    out[n] = child;
                    n += 1;
                }
            }
            children = out[0..n];
        },
        else => {},
    };

    return .{ .kind = kind, .span = span, .label = jsonString(obj.get("label")), .ref = ref, .children = children };
}

fn jsonString(v: ?std.json.Value) ?[]const u8 {
    return switch (v orelse return null) {
        .string => |s| s,
        else => null,
    };
}

fn jsonUsize(v: ?std.json.Value) ?usize {
    return switch (v orelse return null) {
        .integer => |n| if (n >= 0) @intCast(n) else null,
        else => null,
    };
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "template plain args: the lexeme's bytes, or the literal stays in the module" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const term = struct {
        fn of(a: std.mem.Allocator, source: []const u8) !?Term {
            return plainArgTerm(a, .{ .paramName = "p", .source = source });
        }
    }.of;

    try std.testing.expectEqualStrings("hi", (try term(arena, "\"hi\"")).?.binary);
    // The escapes `erl_emitter.writeStringFromLexeme` resolves, resolved to the
    // same bytes.
    try std.testing.expectEqualStrings("a\tb", (try term(arena, "\"a\\tb\"")).?.binary);
    try std.testing.expectEqualStrings("q\"r", (try term(arena, "\"q\\\"r\"")).?.binary);
    try std.testing.expectEqualStrings("c\\d", (try term(arena, "\"c\\\\d\"")).?.binary);
    try std.testing.expectEqualStrings("$x", (try term(arena, "\"\\$x\"")).?.binary);
    // An unknown escape keeps its backslash, as the emitter does.
    try std.testing.expectEqualStrings("\\qz", (try term(arena, "\"\\qz\"")).?.binary);
    // `\u{…}` has no exact term: the emitter renders it as Erlang's `\x{…}`,
    // which truncates to a byte inside a plain binary. The literal stays.
    try std.testing.expectEqual(@as(?Term, null), try term(arena, "\"a\\u{263A}b\""));

    try std.testing.expectEqual(true, (try term(arena, "true")).?.boolean);
    try std.testing.expectEqual(false, (try term(arena, " false ")).?.boolean);
    try std.testing.expectEqual(@as(i64, 42), (try term(arena, "42")).?.integer);
    try std.testing.expectEqual(@as(f64, 1.5), (try term(arena, "1.5")).?.float);
    // Anything else reaches the body as its source text, which is what
    // `PlainArg.toExpr` does with `Ast.str`.
    try std.testing.expectEqualStrings("someIdent", (try term(arena, "someIdent")).?.binary);
}

test "template module: one module per declaration, the capture as the argument" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const lexerMod = @import("../lexer.zig");
    const parserMod = @import("../parser.zig");
    var lx = lexerMod.Lexer.init(
        \\pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
        \\    return q.build(q.text());
        \\}
    );
    var p = parserMod.Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const tfn = program.decls[0].@"fn";

    const capture = struct {
        fn of(a: std.mem.Allocator, text: []const u8) !template.CapturedExpr {
            const node = try a.create(ast.Expr);
            node.* = .{ .literal = .{ .loc = .{ .line = 1, .col = 1 }, .kind = .{ .stringLit = text } } };
            return .{
                .callee = "shout",
                .paramIndex = 0,
                .paramName = "q",
                .node = node,
                .text = text,
                .multiline = false,
                .loc = .{ .line = 1, .col = 1 },
                .modulePath = "main",
                .scope = null,
            };
        }
    }.of;

    var unsupported: erlang.UnsupportedMethod = .{};
    const one = try capture(arena, "alpha");
    const two = try capture(arena, "a much longer literal");
    const first = try buildModule(arena, tfn, &.{one}, &.{}, &unsupported);
    const second = try buildModule(arena, tfn, &.{two}, &.{}, &unsupported);

    // Two call sites with different literals, one module — the difference is
    // entirely in `main/1`'s argument.
    try std.testing.expectEqualStrings(first.module, second.module);
    try std.testing.expectEqualStrings(first.code, second.code);
    try std.testing.expect(std.mem.indexOf(u8, first.code, "-export([main/1, shout/1]).") != null);
    try std.testing.expect(std.mem.indexOf(u8, first.code, "main({Arg0}) ->") != null);
    try std.testing.expect(std.mem.indexOf(u8, first.code, "shout(Arg0)") != null);
    try std.testing.expect(std.mem.indexOf(u8, first.code, "alpha") == null);

    try std.testing.expectEqualStrings("q", first.argument.tuple[0].map[0].value.binary);
    try std.testing.expectEqualStrings("alpha", first.argument.tuple[0].map[1].value.binary);
    try std.testing.expectEqualStrings("a much longer literal", second.argument.tuple[0].map[1].value.binary);
    // The listing keeps showing the capture, which is no longer in the module.
    try std.testing.expect(std.mem.indexOf(u8, first.listing, "%% main/1 argument") != null);
    try std.testing.expect(std.mem.indexOf(u8, first.listing, "alpha") != null);
}

test "template outcome: every reply kind" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const code = try parseOutcome(arena, "{\"kind\":\"code\",\"source\":\"\\\"hey!\\\"\"}");
    try std.testing.expectEqualStrings("\"hey!\"", code.code);

    const value = try parseOutcome(arena, "{\"kind\":\"value\",\"value\":[6,\"x\",null,{\"a\":true}]}");
    try std.testing.expectEqual(@as(i64, 6), value.value.array[0].integer);
    try std.testing.expect(value.value.array[2] == .null);
    try std.testing.expect(value.value.array[3].object[0].value.bool);

    const capture = try parseOutcome(arena, "{\"kind\":\"capture\",\"param\":\"q\"}");
    try std.testing.expectEqualStrings("q", capture.capture);

    const custom = try parseOutcome(arena,
        \\{"kind":"custom","source":"41","ast":{"kind":"root","span":{"start":0,"end":6,"line":1},"label":"keyword","ref":null,
        \\ "children":[{"kind":"leaf","span":{"start":5,"end":9,"line":1},"label":"property","ref":{"name":"Item","kind":"Record_"},"children":[]}]}}
    );
    try std.testing.expectEqualStrings("41", custom.custom.code);
    try std.testing.expect(custom.custom.ast.ref == null);
    try std.testing.expectEqualStrings("Record_", custom.custom.ast.children[0].ref.?.kind);

    const fail = try parseOutcome(arena, "{\"kind\":\"fail\",\"message\":\"no\",\"param\":\"q\",\"span\":null}");
    try std.testing.expectEqualStrings("no", fail.fail.message);
    try std.testing.expectEqualStrings("q", fail.fail.param.?);

    try std.testing.expect((try parseOutcome(arena, "{\"kind\":\"error\",\"message\":\"x\"}")) == .err);
    try std.testing.expect((try parseOutcome(arena, "garbage")) == .err);
}
