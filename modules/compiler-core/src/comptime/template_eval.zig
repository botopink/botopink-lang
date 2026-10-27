/// Template evaluation on the comptime runtime (`runtime/runtime.zig`; wasm for
/// every target, decision 434).
///
/// When the V1 classifier in `infer.zig` cannot reduce a template body by
/// inspection, the body runs here:
///
///   template `FnDecl` ─ codegen/erlang.zig `emitComptimeModule` ─ `main/1` → Erlang text
///   captures + plain args ─ `Term` ─ codegen/beam/etf ─ external term ─┐
///     → comptime/runtime/runtime `evalWithArg`: the text lowered to wasm   │
///       once per module, run with the call site's term ←───────────────────┘
///     → JSON reply → `Outcome`
///
/// The generated module carries the lowered body, the `'__bp_prim_…'` shims its
/// method calls reached and `main/1` — nothing else. The capture API, the result
/// constructors, the failure throws and the reply encoder are resident in
/// `bp_comptime_template`, parsed once per process
/// (`runtime/prelude.zig`), and reached by the `-import` `emitComptimeModule`
/// writes, so the body's own text is the same either way. **Nothing in the
/// module depends on the call site**, so its content hash is a hash of the
/// declaration: one module per template however many times it is called.
///
/// Reply format (`main/1`):
///   {"kind":"code","source":"…"}                  ← `q.build(src)` / `@code(src)`
///   {"kind":"ast","node":<tree>}                  ← `q.ast(node)` (decision 625 (2))
///   {"kind":"value","value":<json>}               ← `@expr(v)`
///   {"kind":"capture","param":"q"}                ← `return q`
///   {"kind":"custom","source":"…","ast":<tree>}   ← `q.custom(tree, code)`
///   {"kind":"fail","message","param","span"}      ← `q.fail` / `q.failAt` / `@compilerError`
///   {"kind":"error","message"}                    ← anything else raised
///
/// A capture reaches the body as a map — `main/1`'s argument, not a literal; its
/// methods (`q.text()`, `q.lookup(name)`, …) lower to the resident
/// host functions.
const std = @import("std");
const hostCells = @import("./host_cells.zig");
const ast = @import("../ast.zig");
const template = @import("./template.zig");
const erlang = @import("../codegen/erlang.zig");
const crossModule = @import("../codegen/crossModule.zig");
const Ast = @import("../codegen/beam/erl_ast.zig");
const Term = @import("../codegen/beam/term.zig").Term;
const erlEmitter = @import("../codegen/beam/erl_emitter.zig");
const formatMod = @import("../format.zig");
const hostRuntime = @import("./runtime/runtime.zig");
const preludeMod = @import("./runtime/prelude.zig");
const etf = @import("../codegen/beam/etf.zig");
const stages = @import("./runtime/stages.zig");
const trace = @import("./trace.zig");
const decoratorSame = @import("./decorator_same.zig");
const blockEval = @import("./block_eval.zig");

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
    /// Decision 625 (2) — `compiler.ast(node)`: the `compiler.Node` tree as
    /// the runtime encoded it (each record a JSON object of its fields; a
    /// `syntax` value the capture's object), read by `infer.zig`'s
    /// `astBuild`.
    ast: std.json.Value,
    value: TypedValue,
    capture: []const u8,
    custom: struct { code: []const u8, ast: CustomNodeTree },
    fail: struct {
        message: []const u8,
        param: ?[]const u8,
        span: ?template.Span,
    },
    err: []const u8,
    /// The body raised, and the raise crossed calls of the `located`
    /// functions (decisions 451 (3), 532, `erlang.ComptimeModule.located`):
    /// the text, and the calls it crossed, innermost first, each with the
    /// file it is written in.
    raised: struct { message: []const u8, frames: []const blockEval.Frame },
    /// Decision 302 — `q.annotate(decl, at)` has no answer yet: run the
    /// annotation written at `span` over the tag and evaluate again.
    need: struct {
        kind: []const u8,
        name: []const u8,
        attrs: []const [2][]const u8,
        answer: i64,
        span: template.Span,
    },
};

pub const EvalError = error{ OutOfMemory, EvalFailed } || std.Io.Writer.Error;

/// What a run answers beside its outcome (decision 426): the index of the
/// `q.build` whose code the body answered (`numberBuilds`), and the reasons
/// `q.note(message)` gave, in call order.
pub const Extras = struct {
    build: ?usize = null,
    notes: []const []const u8 = &.{},
};

/// Longest compiler/runtime diagnostic carried into `Outcome.err`.
const max_error_detail = 4096;

// ── evaluate ──────────────────────────────────────────────────────────────────

/// Decision 643 — the name an argument is written as, for
/// `compiler.name(x)` (a decorator's `'__bp_argName'/1`, a template's
/// capture `name`): a name or a dotted path answers
/// its last name; a lambda, a function, a literal, an array, a call or an
/// operator expression has none — `undefined`, the body's `null`.
pub fn argNameTerm(written: []const u8) Term {
    const src = std.mem.trim(u8, written, " \t\r\n");
    if (nameOfPath(src)) |n| return Term.str(n);
    return .{ .atom = "undefined" };
}

/// The last name of `a.b.c`, null when `src` is no dotted path of names.
fn nameOfPath(src: []const u8) ?[]const u8 {
    if (src.len == 0) return null;
    var start: usize = 0;
    var i: usize = 0;
    while (i <= src.len) : (i += 1) {
        if (i == src.len or src[i] == '.') {
            const seg = src[start..i];
            if (seg.len == 0 or !(std.ascii.isAlphabetic(seg[0]) or seg[0] == '_')) return null;
            for (seg) |ch| if (!(std.ascii.isAlphanumeric(ch) or ch == '_')) return null;
            if (i == src.len) return if (isLiteralWord(seg) and start == 0) null else seg;
            start = i + 1;
        }
    }
    return null;
}

fn isLiteralWord(w: []const u8) bool {
    return std.mem.eql(u8, w, "true") or std.mem.eql(u8, w, "false") or std.mem.eql(u8, w, "null");
}

pub fn evaluate(
    arena: std.mem.Allocator,
    io: std.Io,
    build_root: []const u8,
    /// The module path `tfn` was declared in (`Env.comptimeOwnerOf`); "" when
    /// no module owns it. Named in the module atom (`ownerId`).
    owner: []const u8,
    /// The display path of `owner`'s file (`src/deco.bp`, `@src().file`):
    /// a diagnostic located in the body names it.
    owner_file: []const u8,
    tfn: ast.FnDecl,
    /// The functions `tfn`'s body reaches (`infer.decoratorSupport`, decision
    /// 331's "calls included"), compiled into the module beside it.
    support: []const ast.FnDecl,
    /// Decision 451 (3) — the functions of another module's template whose
    /// calls are located (`tfn` and the `support` functions of its module),
    /// by name: a raise that leaves one of their calls is `Outcome.raised` at
    /// it, in `owner_file`. Empty for the module's own template.
    located: []const erlang.Located,
    /// The record and enum types `tfn` and `support` name, with the methods
    /// they call (`block_eval.typesReached`).
    types: []const ast.DeclKind,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    /// Receives what was sent to and returned by the runtime (snapshots); null skips it.
    traces: ?*std.ArrayListUnmanaged(trace.Entry),
    /// Receives the build index and the notes of the reply; null skips them.
    extras: ?*Extras,
) EvalError!Outcome {
    _ = build_root;
    var unsupported: erlang.UnsupportedMethod = .{};
    var refused: []const u8 = "";
    const t_module = stages.start();
    const source = buildModule(arena, owner, tfn, support, located, types, captures, plainArgs, &unsupported, &refused) catch |err| switch (err) {
        error.UnsupportedMethod => return .{ .err = try unsupportedText(arena, "template", tfn.name, owner_file, unsupported) },
        error.HostCell => return .{ .err = refused },
        else => |e| return e,
    };
    stages.stop(.module, t_module);

    // The comptime runtime is wasm for every target (decision 434,
    // `runtime/runtime.zig`).
    const t_encode = stages.start();
    const arg = try etf.encode(arena, source.argument);
    stages.stop(.encode, t_encode);
    const response = try hostRuntime.evalWithArg(arena, io, "template", source.module, source.code, arg);
    if (traces) |list| {
        const t_listing = stages.start();
        defer stages.stop(.listing, t_listing);
        const listing = try hostRuntime.listingOf(arena, "template", source.module, source.code, try argumentListing(arena, source.argument));
        try list.append(arena, .{
            .kind = .template,
            .name = tfn.name,
            .listing = listing,
            .reply = switch (response) {
                .ok => |stdout| stdout,
                .compile_error => |detail| try std.fmt.allocPrint(arena, "compile error: {s}", .{detail}),
                .runtime_error => |detail| try std.fmt.allocPrint(arena, "runtime error: {s}", .{detail}),
            },
        });
    }
    const t_outcome = stages.start();
    defer stages.stop(.outcome, t_outcome);
    return switch (response) {
        .ok => |stdout| parseOutcomeExtras(arena, stdout, extras),
        .compile_error => |detail| .{ .err = try errorText(arena, "the template module did not compile", detail) },
        .runtime_error => |detail| .{ .err = hostRuntime.interruptedText(detail) orelse try errorText(arena, "the template body raised", detail) },
    };
}

// ── the registry lock ────────────────────────────────────────────────────────
//
// The emit memo below (and the decorator evaluator's, which shares it) is
// process-wide. An atomic spin-lock: the critical sections are a hash lookup
// and an insert, and
// parallel test binaries are the only contenders. Storage outlives every
// caller arena and is never freed.

var rendered_lock: std.atomic.Value(u8) = .init(0);
const rendered_alloc = std.heap.page_allocator;

fn lockRendered() void {
    while (rendered_lock.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
}

fn unlockRendered() void {
    rendered_lock.store(0, .release);
}

// ── one emit per declaration ──────────────────────────────────────────────────
//
// Every call site used to run `emitComptimeModule`, and with it the re-lex and
// re-parse of the embedded `primitives.bp`'s compiler section and `primitives.bp`
// (`collectBuiltinErlangDispatch`) — 55 % of an N=200 build's samples (front 14
// step 2). The code is a function of the declarations lowered and of `main/1`'s
// plan (which slots it binds, and the literal it writes for a slot that has no
// term), never of a capture or a handle, so it is emitted once per
// `emitKey` and the atom and the renamed text are reused.
//
// The key is the declarations' FORMATTED source (the formatter round-trips to an
// equivalent AST, and the emitter is a function of the AST), the owner, and the
// plan — text, not an address, so a declaration edited in a long-lived process
// (the language server) is a different key, never a stale hit. A declaration the
// formatter cannot render is emitted every time, as before.

pub const Emitted = struct {
    /// The module atom (`erlDeclAtom`, content-addressed).
    module: []const u8,
    /// The compilable module text under that atom.
    code: []const u8,
};

var emitted_modules: std.StringHashMapUnmanaged(Emitted) = .empty;

/// The memo key of one comptime module, or null when a declaration does not
/// format (no memo then). `kind` separates a template from a decorator whose
/// declarations and plan would coincide.
pub fn emitKey(
    arena: std.mem.Allocator,
    kind: []const u8,
    owner: []const u8,
    decls: []ast.DeclKind,
    plans: []const ArgPlan,
) std.mem.Allocator.Error!?[]const u8 {
    var out: std.Io.Writer.Allocating = .init(arena);
    const w = &out.writer;
    const source = formatMod.format(arena, .{ .decls = decls }) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return null,
    };
    w.print("{s}\x00{s}\x00{s}\x00", .{ kind, owner, source }) catch return error.OutOfMemory;
    for (plans) |plan| {
        w.writeByte(if (plan.bound) 'b' else 'l') catch return error.OutOfMemory;
        erlEmitter.writeExpr(w, plan.expr, 0) catch return error.OutOfMemory;
        w.writeByte(0) catch return error.OutOfMemory;
    }
    return out.written();
}

/// Decisions 451 (3), 532 — a located function's calls are emitted as frames
/// (`erlang.zig` `framed`: their file, line and column), so its module text is a function of WHERE
/// its calls are written, which the formatted source the key holds drops. A
/// caller that locates functions appends every `ast.Loc` of those declarations
/// to its `kind` with this: one decorator compiled at another position (an
/// earlier build of the same text in this process — another test, the
/// language server after an edit above it, a conformance cell holding the same
/// decorator) is then another key, never the earlier build's module raising at
/// the earlier build's lines. Every call site of one declaration in one build
/// reads the same AST, so the memo still emits it once per build.
pub fn appendLocs(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), value: anytype) std.mem.Allocator.Error!void {
    const T = @TypeOf(value);
    if (T == ast.Loc) {
        var buf: [64]u8 = undefined;
        const text = std.fmt.bufPrint(&buf, "\x01{d}:{d}:{d}", .{ value.line, value.col, value.expansion }) catch unreachable;
        return out.appendSlice(arena, text);
    }
    switch (@typeInfo(T)) {
        .@"struct" => |s| inline for (s.fields) |f| {
            if (!f.is_comptime) try appendLocs(arena, out, @field(value, f.name));
        },
        .@"union" => |u| if (u.tag_type != null) switch (value) {
            inline else => |payload| try appendLocs(arena, out, payload),
        },
        .optional => if (value) |v| try appendLocs(arena, out, v),
        .array => for (value) |item| try appendLocs(arena, out, item),
        .pointer => |p| switch (p.size) {
            .one => if (@typeInfo(p.child) != .@"opaque" and @typeInfo(p.child) != .@"fn") try appendLocs(arena, out, value.*),
            .slice => if (p.child != u8) for (value) |item| try appendLocs(arena, out, item),
            else => {},
        },
        else => {},
    }
}

/// The module this process emitted under `key`, or null.
pub fn cachedEmit(key: []const u8) ?Emitted {
    lockRendered();
    defer unlockRendered();
    return emitted_modules.get(key);
}

/// Record the module emitted under `key` and return the stored copy.
pub fn rememberEmit(key: []const u8, emitted: Emitted) std.mem.Allocator.Error!Emitted {
    const owned_key = try rendered_alloc.dupe(u8, key);
    errdefer rendered_alloc.free(owned_key);
    const module = try rendered_alloc.dupe(u8, emitted.module);
    errdefer rendered_alloc.free(module);
    const code = try rendered_alloc.dupe(u8, emitted.code);
    errdefer rendered_alloc.free(code);

    lockRendered();
    defer unlockRendered();
    const slot = try emitted_modules.getOrPut(rendered_alloc, owned_key);
    if (slot.found_existing) {
        // Another thread emitted the same declarations first; its text is this text.
        rendered_alloc.free(owned_key);
        rendered_alloc.free(module);
        rendered_alloc.free(code);
        return slot.value_ptr.*;
    }
    slot.value_ptr.* = .{ .module = module, .code = code };
    return slot.value_ptr.*;
}

/// Distinct comptime modules emitted by this process (tests: a second call
/// site of one declaration must not emit again).
pub fn emittedCount() usize {
    lockRendered();
    defer unlockRendered();
    return emitted_modules.count();
}

fn errorText(arena: std.mem.Allocator, what: []const u8, detail: []const u8) ![]const u8 {
    const shown = detail[0..@min(detail.len, max_error_detail)];
    const ellipsis = if (detail.len > max_error_detail) " …" else "";
    return std.fmt.allocPrint(arena, "{s}: {s}{s}", .{ what, shown, ellipsis });
}

/// The diagnostic for a body method call nothing answers (`erlang.UnsupportedMethod`).
fn unsupportedText(arena: std.mem.Allocator, host: []const u8, name: []const u8, file: []const u8, m: erlang.UnsupportedMethod) ![]const u8 {
    return std.fmt.allocPrint(
        arena,
        "the {s} `{s}` calls `.{s}(…)` with {d} argument(s) at {s}:{d}:{d}, which no primitive type (string, array, int, float, bool) and no {s} host function provides",
        .{ host, name, m.callee, m.argc, file, m.loc.line, m.loc.col, host },
    );
}

// ── module ────────────────────────────────────────────────────────────────────

const Module = struct {
    /// Erlang module atom derived from the code's hash. The code carries no
    /// capture, so every call site of one declaration derives the same atom.
    module: []const u8,
    code: []const u8,
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
/// `writeStringFromLexeme` writes the code point as its UTF-8 bytes, one
/// `\x{HH}` each (Erlang's own `\x{263A}` inside a plain `<<"…">>` would keep
/// only the low byte). Decoding it here too would be a second definition of
/// what a botopink string literal means; leaving the literal in the module keeps
/// the single definition in the emitter (`tests/decorator_invocation.zig`'s
/// `a \u{…} literal in the body …` pins the argument's bytes on both runtimes).
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
pub fn lexemeBytes(arena: std.mem.Allocator, s: []const u8) std.mem.Allocator.Error!?[]const u8 {
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

/// `main/1`'s argument as `%%` comment lines, one `ArgN = …` per tuple
/// element, after the `%% main/1 argument` header — the per-call half of a
/// trace listing: `runtime.listingOf` puts it under the runtime's own listing
/// of the module (BEAM assembly, or wasm with the lines as `;;`). The capture is
/// no longer part of the module, and a snapshot that showed it has to keep
/// showing it — it is the input half of the evaluation the reply answers.
/// Rendered only when a trace is kept (`evaluate`'s `traces`).
///
/// Each element goes through `writeExpr`, not `writeTerm`: the expression writer
/// is the one that wraps a map or a list over several lines, so a capture reads
/// in a snapshot exactly as it read when it was a literal inside `main/0`.
/// `writeTermAt` does not wrap a tuple, which is why the tuple is unpacked here
/// rather than printed whole.
pub fn argumentListing(arena: std.mem.Allocator, argument: Term) EvalError![]const u8 {
    var out: std.Io.Writer.Allocating = .init(arena);
    const w = &out.writer;
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

/// The owning module of a comptime-evaluated body, for A2's atom (C-01; 13
/// half 1, step 5).
///
/// The evaluator's modules live in the compiler's own namespace (`bp`, which no
/// `botopink.json` may take), under `comptime/` followed by the path of the
/// `.bp` module the declaration was written in — `ui/panel` renders
/// `bp@comptime@ui@panel__tpl__panel__<hash>`, so a stack trace and a
/// `.botopinkbuild/tmp/template/` listing name the FILE as well as the
/// template, and `crossModule.decodeAtom` reads both back. The owner comes from
/// `Env.comptimeOwnerOf`, which the importing module fills from the registry
/// that exported the declaration. A declaration no module owns (the compiler's
/// own unit tests) keeps `bp@comptime__…`. The package namespace stays `bp`
/// rather than the owner's package: a comptime module is content-addressed
/// scratch loaded into one node for every package of the build, and a package
/// prefix would let it share a prefix with the modules a package emits.
pub fn ownerId(arena: std.mem.Allocator, owner: []const u8) std.mem.Allocator.Error!crossModule.ModuleId {
    if (owner.len == 0) return comptime_owner;
    return .inPackage(crossModule.COMPILER_PACKAGE, try std.fmt.allocPrint(arena, "comptime/{s}", .{owner}));
}

/// The atom's owner when no module owns the declaration.
pub const comptime_owner: crossModule.ModuleId = .inPackage(crossModule.COMPILER_PACKAGE, "comptime");

const placeholder_module = "template_module";

/// Records of the `std.syntax` template model a body may construct.
/// `f` with every tuple element read by its label (`x.kind`) read by its
/// position (`x._0`) — `Env.tupleLabelReads`, recorded by inference of the
/// module that declares `f`. A comptime module is lowered untyped from the
/// AST as written, where a label read is a map read: `{badmap, {…}}` on the
/// tuple. Positions are what the transform hands every backend; `f`'s own
/// declaration is left untouched (the copy is new nodes throughout).
pub fn relabelTupleReads(
    arena: std.mem.Allocator,
    reads: *const std.AutoHashMapUnmanaged(ast.Loc, usize),
    f: ast.FnDecl,
) std.mem.Allocator.Error!ast.FnDecl {
    if (reads.count() == 0) return f;
    var r: Relabel = .{ .arena = arena, .reads = reads };
    var out = f;
    out.body = try r.clone(@TypeOf(f.body), f.body);
    return out;
}

const Relabel = struct {
    arena: std.mem.Allocator,
    reads: *const std.AutoHashMapUnmanaged(ast.Loc, usize),

    fn clone(self: *Relabel, comptime U: type, v: U) std.mem.Allocator.Error!U {
        if (U == ast.TypeRef or U == ast.Pattern) return v;
        if (U == ast.Expr) if (try self.replace(v)) |r| return r;
        switch (@typeInfo(U)) {
            .@"struct" => |s| {
                var out: U = v;
                inline for (s.fields) |fld| {
                    if (fld.is_comptime) continue;
                    if (comptime mayHoldExprs(fld.type)) @field(out, fld.name) = try self.clone(fld.type, @field(v, fld.name));
                }
                return out;
            },
            .@"union" => |u| {
                if (u.tag_type == null) return v;
                switch (v) {
                    inline else => |payload, tag| {
                        const P = @TypeOf(payload);
                        if (comptime !mayHoldExprs(P)) return v;
                        return @unionInit(U, @tagName(tag), try self.clone(P, payload));
                    },
                }
            },
            .optional => |o| return if (v) |inner| try self.clone(o.child, inner) else null,
            .pointer => |p| switch (p.size) {
                .one => {
                    if (comptime !mayHoldExprs(p.child)) return v;
                    const n = try self.arena.create(p.child);
                    n.* = try self.clone(p.child, v.*);
                    return n;
                },
                .slice => {
                    if (comptime !mayHoldExprs(p.child)) return v;
                    const out = try self.arena.alloc(p.child, v.len);
                    for (v, 0..) |e, i| out[i] = try self.clone(p.child, e);
                    return out;
                },
                else => return v,
            },
            else => return v,
        }
    }

    fn replace(self: *Relabel, e: ast.Expr) std.mem.Allocator.Error!?ast.Expr {
        if (e != .identifier) return null;
        const id = e.identifier;
        if (id.kind != .identAccess) return null;
        const idx = self.reads.get(id.loc) orelse return null;
        var ia = id.kind.identAccess;
        ia.receiver = try self.clone(*ast.Expr, ia.receiver);
        ia.member = try std.fmt.allocPrint(self.arena, "_{d}", .{idx});
        var out = id;
        out.kind = .{ .identAccess = ia };
        return .{ .identifier = out };
    }
};

/// The name a template method's receiver parameter takes in the comptime
/// module: `self` is a method's receiver to the backends, which drop it from a
/// function's parameters, so the module names it otherwise.
pub const template_self_name = "__bp_self";

/// Decisions 311 (3), 415 (1) — `f`, a template method, with its
/// `comptime self: @Expr<R>` parameter and every bare `self` of its body named
/// `template_self_name` (the copy is new nodes throughout).
pub fn renameTemplateSelf(arena: std.mem.Allocator, f: ast.FnDecl) std.mem.Allocator.Error!ast.FnDecl {
    if (!ast.isTemplateMethodSignature(f.params, f.returnType)) return f;
    var r: Rewrite(RenameSelf) = .{ .arena = arena, .hook = .{} };
    var out = f;
    const params = try arena.dupe(ast.Param, f.params);
    params[0].name = template_self_name;
    out.params = params;
    out.body = try r.clone(@TypeOf(f.body), f.body);
    return out;
}

/// Decision 641 — `stmts` with every bare `from` written `to` (new nodes
/// throughout): a primitive type's member whose body is a private
/// function's (`.Wasm(body: f)`, `prelude_cache.dissolvedTypesAsMemberTables`)
/// reads the function's receiver parameter as the member's `self`.
pub fn renameIdentifier(arena: std.mem.Allocator, stmts: []ast.Stmt, from: []const u8, to: []const u8) std.mem.Allocator.Error![]ast.Stmt {
    var r: Rewrite(RenameIdent) = .{ .arena = arena, .hook = .{ .from = from, .to = to } };
    return r.clone([]ast.Stmt, stmts);
}

const RenameIdent = struct {
    from: []const u8,
    to: []const u8,

    fn replace(h: *RenameIdent, _: std.mem.Allocator, v: ast.Expr) std.mem.Allocator.Error!?ast.Expr {
        if (v != .identifier or v.identifier.kind != .ident or !std.mem.eql(u8, v.identifier.kind.ident, h.from)) return null;
        var out = v.identifier;
        out.kind = .{ .ident = h.to };
        return .{ .identifier = out };
    }
};

const RenameSelf = struct {
    fn replace(_: *RenameSelf, _: std.mem.Allocator, v: ast.Expr) std.mem.Allocator.Error!?ast.Expr {
        if (v != .identifier or v.identifier.kind != .ident or !std.mem.eql(u8, v.identifier.kind.ident, "self")) return null;
        var out = v.identifier;
        out.kind = .{ .ident = template_self_name };
        return .{ .identifier = out };
    }
};

/// Decision 426 (2) — `f` with each `q.build(src)` and `q.ast(node)` (decision
/// 625 (2)) of its body (`q` one of its
/// `@Expr` parameters) written `q.build(src, <i>)`, `i` the call's index in
/// `locs`: the prelude's `build/3` records the index of the build whose code
/// the body answers, so a built type outside the template's answer is refused
/// at that `build`. A body with one `build` is left as written: that build is
/// the one.
pub fn numberBuilds(arena: std.mem.Allocator, f: ast.FnDecl) std.mem.Allocator.Error!struct { f: ast.FnDecl, locs: []const ast.Loc } {
    var r: Rewrite(NumberBuilds) = .{ .arena = arena, .hook = .{ .params = f.params } };
    var out = f;
    out.body = try r.clone(@TypeOf(f.body), f.body);
    // One build names itself: the body is run as written.
    if (r.hook.locs.items.len <= 1) return .{ .f = f, .locs = r.hook.locs.items };
    return .{ .f = out, .locs = r.hook.locs.items };
}

const NumberBuilds = struct {
    params: []const ast.Param,
    locs: std.ArrayListUnmanaged(ast.Loc) = .empty,

    fn replace(self: *NumberBuilds, arena: std.mem.Allocator, v: ast.Expr) std.mem.Allocator.Error!?ast.Expr {
        if (v != .call or v.call.kind != .call) return null;
        const c = v.call.kind.call;
        if (c.is_builtin or c.args.len != 1 or !(std.mem.eql(u8, c.callee, "build") or std.mem.eql(u8, c.callee, "ast"))) return null;
        const r = c.receiver orelse return null;
        if (r.* != .identifier or r.identifier.kind != .ident) return null;
        const named = for (self.params) |p| {
            if (p.typeRef.isExprType() and std.mem.eql(u8, p.name, r.identifier.kind.ident)) break true;
        } else false;
        if (!named) return null;
        const index = self.locs.items.len;
        try self.locs.append(arena, v.call.loc);
        const lit = try arena.create(ast.Expr);
        lit.* = .{ .literal = .{ .loc = v.call.loc, .kind = .{ .numberLit = try std.fmt.allocPrint(arena, "{d}", .{index}) } } };
        const args = try arena.alloc(ast.CallArg, 2);
        args[0] = c.args[0];
        args[1] = .{ .label = null, .value = lit };
        var out = v;
        out.call.kind.call.args = args;
        return out;
    }
};

/// A copy of an AST value with the expressions `Hook.replace` answers for
/// replaced (null keeps walking into the node). New nodes throughout.
fn Rewrite(comptime Hook: type) type {
    return struct {
        arena: std.mem.Allocator,
        hook: Hook,

        fn clone(self: *@This(), comptime U: type, v: U) std.mem.Allocator.Error!U {
            if (U == ast.TypeRef or U == ast.Pattern) return v;
            if (U == ast.Expr) if (try self.hook.replace(self.arena, v)) |r| return r;
            switch (@typeInfo(U)) {
                .@"struct" => |s| {
                    var out: U = v;
                    inline for (s.fields) |fld| {
                        if (fld.is_comptime) continue;
                        if (comptime mayHoldExprs(fld.type)) @field(out, fld.name) = try self.clone(fld.type, @field(v, fld.name));
                    }
                    return out;
                },
                .@"union" => |u| {
                    if (u.tag_type == null) return v;
                    switch (v) {
                        inline else => |payload, tag| {
                            const P = @TypeOf(payload);
                            if (comptime !mayHoldExprs(P)) return v;
                            return @unionInit(U, @tagName(tag), try self.clone(P, payload));
                        },
                    }
                },
                .optional => |o| return if (v) |inner| try self.clone(o.child, inner) else null,
                .pointer => |p| switch (p.size) {
                    .one => {
                        if (comptime !mayHoldExprs(p.child)) return v;
                        const n = try self.arena.create(p.child);
                        n.* = try self.clone(p.child, v.*);
                        return n;
                    },
                    .slice => {
                        if (comptime !mayHoldExprs(p.child)) return v;
                        const out = try self.arena.alloc(p.child, v.len);
                        for (v, 0..) |e, i| out[i] = try self.clone(p.child, e);
                        return out;
                    },
                    else => return v,
                },
                else => return v,
            }
        }
    };
}

fn mayHoldExprs(comptime U: type) bool {
    return switch (@typeInfo(U)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque", .null, .undefined => false,
        .pointer => |p| if (p.child == u8) false else if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else true,
        else => true,
    };
}

/// The type names the template module defines itself (its host enums and
/// records): never carried from the program (`block_eval.typesReached`'s skip).
/// Each internal name is also reached through its `compiler.bp` alias
/// (`import {compiler.Span} from "std"`, decision 576 (13)).
pub const injected_names = [_][]const u8{ "__DeclKind", "__Span", "__CustomNode", "__Source", "__ExprContext", "DeclKind", "Span", "CustomNode", "Source", "ExprContext" };

const host_records = [_]erlang.HostRecord{
    .{ .name = "__Span", .fields = &.{ "start", "end", "line" } },
    .{ .name = "__CustomNode", .fields = &.{ "kind", "span", "label", "ref", "children" } },
    .{ .name = "__Source", .fields = &.{ "file", "line", "col", "root" } },
    .{ .name = "__ExprContext", .fields = &.{ "source", "text", "multiline" } },
    .{ .name = "Span", .fields = &.{ "start", "end", "line" } },
    .{ .name = "CustomNode", .fields = &.{ "kind", "span", "label", "ref", "children" } },
    .{ .name = "Source", .fields = &.{ "file", "line", "col", "root" } },
    .{ .name = "ExprContext", .fields = &.{ "source", "text", "multiline" } },
};

/// `main/1` — the evaluator entry: it destructures the argument tuple, calls the
/// body with it and answers the JSON reply. The capture API, the result
/// constructors, the failure throws and `'__bp_reply'/1` are resident
/// (`runtime/prelude.zig`), reached by the `-import` `emitComptimeModule`
/// writes. Nothing here depends on the call site any more — that is what makes
/// the module's hash a hash of the declaration.
fn mainForms(b: Ast.Builder, tfn: ast.FnDecl, plans: []const ArgPlan, annotates: bool, locating: bool) EvalError![]const Ast.Form {
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

    // Decision 302 — a body that calls `q.annotate(decl, at)` counts its
    // calls from zero, and a call past the answers the capture carries
    // replies with the annotation to run and where it is written. A body that
    // calls none keeps the module it had.
    const need: Ast.Clause = .{
        .patterns = try b.exprs(&.{try b.exception(A("throw"), try b.tuple(&.{ A(preludeMod.template_need_tag), V("Request"), V("Span") }))}),
        .body = try b.body(&.{try json(b, &.{
            Ast.field("kind", Ast.str("need")),
            Ast.field("decl", try b.call("__bp_json", &.{V("Request")})),
            Ast.field("span", try b.call("__bp_json", &.{V("Span")})),
        })}),
    };
    const others = [_]Ast.Clause{
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
    };
    // Decisions 451 (3), 532 — a module whose calls are located answers the
    // calls the raise crossed (`'__bp_frames'/1`); the module's own template keeps
    // the reply it had.
    const located_error: Ast.Clause = .{
        .patterns = others[1].patterns,
        .body = try b.body(&.{try json(b, &.{
            Ast.field("kind", Ast.str("error")),
            Ast.field("message", try b.call("__bp_text", &.{try b.tuple(&.{ V("Class"), V("Reason") })})),
            Ast.field("frames", try b.call("__bp_frames", &.{V("Reason")})),
        })}),
    };
    const catches = if (locating) &[_]Ast.Clause{ others[0], located_error } else &others;
    const tried: Ast.Expr = .{ .try_catch = .{
        .body = try b.body(&.{try b.remote("json", "encode", &.{try b.call(preludeMod.extras_fn, &.{try b.call("__bp_reply", &.{invoke})})})}),
        .catches = if (annotates) try std.mem.concat(b.arena, Ast.Clause, &.{ &.{need}, catches }) else try b.arena.dupe(Ast.Clause, catches),
    } };
    const reset = try b.call(preludeMod.extras_reset_fn, &.{});
    const main_body = if (annotates) try b.body(&.{ reset, try b.call("__bp_annotateReset", &.{}), tried }) else try b.body(&.{ reset, tried });
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
    owner: []const u8,
    tfn: ast.FnDecl,
    support: []const ast.FnDecl,
    located: []const erlang.Located,
    types: []const ast.DeclKind,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
    unsupported: *erlang.UnsupportedMethod,
    /// Why a host function cannot run on this runtime (`error.HostCell`).
    refused: *[]const u8,
) (EvalError || error{ UnsupportedMethod, HostCell })!Module {
    const b: Ast.Builder = .{ .arena = arena };
    const plans = try argPlans(arena, tfn, captures, plainArgs);
    const annotates = decoratorSame.mentionsMethod(tfn, "annotate") or for (support) |f| {
        if (decoratorSame.mentionsMethod(f, "annotate")) break true;
    } else false;
    const forms = try mainForms(b, tfn, plans, annotates, located.len > 0);
    const resident = try preludeMod.templateForms(b);

    const all = try arena.alloc(ast.DeclKind, 1 + support.len + types.len);
    all[0] = .{ .@"fn" = tfn };
    for (support, 1..) |f, i| all[i] = .{ .@"fn" = f };
    @memcpy(all[1 + support.len ..], types);
    // Decision 341 — each host function as this runtime runs it.
    const decls = switch (try hostCells.forRuntime(arena, all)) {
        .ok => |d| d,
        .refused => |msg| {
            refused.* = msg;
            return error.HostCell;
        },
    };
    const config: erlang.ComptimeModule = .{
        .host_enums = &.{ "__DeclKind", "DeclKind", "Stage" },
        .host_records = &host_records,
        .exports = &.{.{ .name = "main", .arity = 1 }},
        .forms = forms,
        .resident = .{
            .module = preludeMod.template_module,
            .forms = resident,
            .refs = try preludeMod.exportRefs(arena, resident),
        },
        .unsupported_method = unsupported,
        .located = located,
    };
    const argument = try argumentTerm(arena, plans);
    // The located functions change the code, so they are part of the key, as
    // a decorator's are (`decorator_eval.buildModule`).
    var kind: std.ArrayListUnmanaged(u8) = .empty;
    try kind.appendSlice(arena, "tpl");
    for (located) |n| {
        try kind.append(arena, 1);
        try kind.appendSlice(arena, n.name);
        try kind.append(arena, 3);
        try kind.appendSlice(arena, n.file);
    }
    for (decls) |d| switch (d) {
        .@"fn" => |f| for (located) |n| {
            if (std.mem.eql(u8, f.name, n.name)) {
                try kind.append(arena, 2);
                try kind.appendSlice(arena, n.name);
                try appendLocs(arena, &kind, f);
                break;
            }
        },
        else => {},
    };
    const key = try emitKey(arena, kind.items, owner, decls, plans);
    const emitted: Emitted = (if (key) |k| cachedEmit(k) else null) orelse blk: {
        const code = erlang.emitComptimeModule(arena, placeholder_module, .{ .decls = decls }, config) catch |err|
            return if (err == error.UnsupportedComptimeMethod) error.UnsupportedMethod else error.EvalFailed;
        // A2: `bp@comptime@<owner path>__tpl__<template>__<16 hex>`. The Wyhash is
        // unchanged, so an identical generated body is still the identical module
        // and the wat runtime's caches (`runtime/wat/program.zig`) hit.
        const module = crossModule.erlDeclAtom(arena, try ownerId(arena, owner), .tpl, tfn.name, std.hash.Wyhash.hash(0, code)) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => return error.EvalFailed,
        };
        const header = "-module(" ++ placeholder_module ++ ").";
        if (!std.mem.startsWith(u8, code, header)) return error.EvalFailed;
        const fresh: Emitted = .{ .module = module, .code = try std.fmt.allocPrint(arena, "-module({s}).{s}", .{ module, code[header.len..] }) };
        break :blk if (key) |k| try rememberEmit(k, fresh) else fresh;
    };
    const module = emitted.module;
    const renamed = emitted.code;

    return .{ .module = module, .code = renamed, .argument = argument };
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
/// `#{'__bp_capture' => Param, text, source, context, bindings, words}`.
/// Text is the template text's raw bytes (decision 577).
///
/// Decision 237: `words` are the words of the literal's own text
/// (`appendWords`) and `bindings` the scope entries whose name is one of them,
/// in the order the words first appear — `<Card title="x"><Badge/></Card>`
/// carries `Card` and `Badge` (when the scope has them), `"cfg-0"` nothing. The
/// argument is O(text), never O(scope). `lookup/2` answers `undefined` for a
/// word the scope lacks and fails the template for a name that is not a word.
pub fn captureToTerm(arena: std.mem.Allocator, cap: *const template.CapturedExpr) std.mem.Allocator.Error!Term {
    // Decision 577 — a template text is its raw bytes, with no hole.
    const text_bytes = cap.text orelse "";
    var words: Words = .empty;
    try appendWords(arena, &words, text_bytes);
    const text: struct { items: []const u8 } = .{ .items = text_bytes };

    const source_entries = try arena.alloc(Term.MapEntry, 4);
    source_entries[0] = Term.field("file", Term.str(if (cap.srcFile.len > 0) cap.srcFile else cap.modulePath));
    source_entries[1] = Term.field("line", Term.int(@intCast(cap.loc.line)));
    source_entries[2] = Term.field("col", Term.int(@intCast(cap.loc.col)));
    source_entries[3] = Term.field("root", Term.str(cap.srcRoot));
    const source = Term.mapOf(source_entries);

    const context_entries = try arena.alloc(Term.MapEntry, 3);
    context_entries[0] = Term.field("source", source);
    context_entries[1] = Term.field("text", Term.str(text.items));
    context_entries[2] = Term.field("multiline", .{ .boolean = cap.multiline });

    // Decision 237: one scope probe per word of the text — the scope's size
    // never enters the capture.
    var bindings: std.ArrayListUnmanaged(Term) = .empty;
    const word_terms = try arena.alloc(Term, words.count());
    for (words.keys(), word_terms) |word, *wt| {
        wt.* = Term.str(word);
        // Decision 415 (2) — the word's `@Decl` handle, when the call site
        // computed it.
        const handle: ?Term = for (cap.handles) |h| {
            if (std.mem.eql(u8, h.local, word)) break h.term;
        } else null;
        if (handle) |t| {
            try bindings.append(arena, t);
            continue;
        }
        const scope = cap.scope orelse continue;
        const e = scope.entries.getPtr(word) orelse continue;
        // Decision 112: `name` is the declaration's own name and
        // `identity` its `<package>@<path>@@<Decl>`; `local` is the name
        // the scope spells — what `lookup` matches.
        const be = try arena.alloc(Term.MapEntry, 4);
        be[0] = Term.field("name", Term.str(e.declName));
        be[1] = Term.field("kind", Term.atomOf(e.kind.declKindName()));
        be[2] = Term.field("identity", Term.str(e.identity));
        be[3] = Term.field("local", Term.str(e.name));
        try bindings.append(arena, Term.mapOf(be));
    }

    // Decision 364 (2) — `q.value`, when the template reads it: the literal's
    // value (it has no hole — the checker refuses the read of a holed one at
    // the argument).
    // Decision 302 — the answers `q.annotate` has had so far, in call order
    // (`expandTemplateCallViaRuntime`); the key only when there is one.
    const extra: usize = @as(usize, if (cap.valueRead) 1 else 0) + @as(usize, if (cap.tagAnswers.len > 0) 1 else 0) + @as(usize, if (cap.holes.len > 0) 1 else 0);
    const entries = try arena.alloc(Term.MapEntry, 7 + extra);
    var next: usize = 7;
    if (cap.valueRead) {
        entries[next] = Term.field("value", Term.str(text.items));
        next += 1;
    }
    // Decision 637 — `compiler.holes(t)`: each hole a capture of its own.
    if (cap.holes.len > 0) {
        const hs = try arena.alloc(Term, cap.holes.len);
        for (cap.holes, hs) |*h, *t| t.* = try captureToTerm(arena, h);
        entries[next] = Term.field("holes", Term.listOf(hs));
        next += 1;
    }
    if (cap.tagAnswers.len > 0) entries[next] = .{ .key = Term.atomOf(preludeMod.annotations_key), .value = Term.listOf(cap.tagAnswers) };
    entries[0] = .{ .key = Term.atomOf("__bp_capture"), .value = Term.str(cap.paramName) };
    entries[1] = Term.field("text", Term.str(text.items));
    entries[2] = Term.field("source", source);
    entries[3] = Term.field("context", Term.mapOf(context_entries));
    entries[4] = Term.field("bindings", Term.listOf(bindings.items));
    entries[5] = Term.field("words", Term.listOf(word_terms));
    // Decision 643 — `compiler.name(e)`: the name the call site wrote, or
    // `undefined` (`null`) when the expression has none.
    entries[6] = Term.field("name", argNameTerm(text.items));
    return Term.mapOf(entries);
}

/// Decision 415 (2) — the words of `cap`'s text, in order of first
/// appearance (decision 237): the names `q.lookup` may ask for.
pub fn captureWords(arena: std.mem.Allocator, cap: *const template.CapturedExpr) std.mem.Allocator.Error![]const []const u8 {
    var words: Words = .empty;
    switch (cap.node.*) {
        .literal => |lit| switch (lit.kind) {
            .stringTemplate => |st| for (st.parts) |part| switch (part) {
                .text => |t| try appendWords(arena, &words, t),
                .expr => {},
            },
            else => try appendWords(arena, &words, cap.text orelse ""),
        },
        else => try appendWords(arena, &words, cap.text orelse ""),
    }
    return words.keys();
}

/// Decision 302 — the text the body reads as `q.text()` (a hole as its
/// placeholder), which an annotation's span indexes.
pub fn captureText(arena: std.mem.Allocator, cap: *const template.CapturedExpr) std.mem.Allocator.Error![]const u8 {
    const t = try captureToTerm(arena, cap);
    for (t.map) |e| if (e.key == .atom and std.mem.eql(u8, e.key.atom, "text")) return e.value.binary;
    return "";
}

/// `infer.zig`'s memo key of a template call (hole-free captures only; the
/// caller decides when there is none): the callee, each capture's text with the
/// scope entries of its **words** (decision 237 — the bindings `captureToTerm`
/// carries, so the key is O(text) like the argument, never O(scope)), and each
/// plain argument's lexeme. Two call sites with the same key send the body the
/// same text, the same bindings and the same plain arguments. A word the scope
/// lacks is part of the key as a miss: adding that name to the scope later is a
/// different key, never a stale hit.
pub fn memoKey(
    arena: std.mem.Allocator,
    callee: []const u8,
    captures: []const template.CapturedExpr,
    plainArgs: []const template.PlainArg,
) std.mem.Allocator.Error![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    try buf.appendSlice(arena, callee);
    for (captures) |cap| {
        const text = cap.text orelse "";
        try buf.append(arena, 0);
        try buf.appendSlice(arena, text);
        const scope = cap.scope orelse continue;
        try buf.append(arena, 0);
        var words: Words = .empty;
        try appendWords(arena, &words, text);
        for (words.keys()) |word| {
            try buf.appendSlice(arena, word);
            if (scope.entries.getPtr(word)) |e| {
                try buf.append(arena, 1);
                try buf.appendSlice(arena, e.kind.variantName());
                try buf.append(arena, 1);
                try buf.appendSlice(arena, e.declName);
                try buf.append(arena, 1);
                try buf.appendSlice(arena, e.identity);
            }
            try buf.append(arena, 2);
        }
    }
    for (plainArgs) |pa| {
        try buf.append(arena, 0);
        try buf.appendSlice(arena, pa.paramName);
        try buf.append(arena, 1);
        try buf.appendSlice(arena, pa.source);
    }
    return buf.toOwnedSlice(arena);
}

/// The distinct words of a capture's text, in order of first appearance.
const Words = std.StringArrayHashMapUnmanaged(void);

/// Decision 237 — the words of `text`, appended to `words`: a word is a
/// maximal run of `[A-Za-z0-9_]` whose first byte is not a digit — the shape
/// of a botopink identifier (`lexer.zig` `isAlpha` / `isAlphaNumeric`), so
/// every name a scope can hold is a word wherever the text spells it. Every
/// other byte (punctuation, whitespace, non-ASCII) separates words. The text
/// is the literal's own: a `${…}` hole contributes no word (its source is
/// spliced back by `infer.zig`, never looked up) and neither does its
/// placeholder.
fn appendWords(arena: std.mem.Allocator, words: *Words, text: []const u8) std.mem.Allocator.Error!void {
    var i: usize = 0;
    while (i < text.len) {
        if (!isWordByte(text[i])) {
            i += 1;
            continue;
        }
        const start = i;
        while (i < text.len and isWordByte(text[i])) i += 1;
        if (!std.ascii.isDigit(text[start])) try words.put(arena, text[start..i], {});
    }
}

fn isWordByte(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '_';
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
    /// Decision 625 (2) — the `compiler.Node` tree `ast(node)` answered.
    node: std.json.Value = .null,
    decl: std.json.Value = .null,
    /// Decision 532 — `[[File, Line, Col], …]`, the located calls a raise
    /// crossed (`'__bp_frames'/1`), innermost first, `[]` when none.
    frames: ?std.json.Value = null,
    /// Decision 426 — `'__bp_extras'/1`: the build answered, the notes given
    /// (latest first).
    build: ?i64 = null,
    notes: []const []const u8 = &.{},
};

fn parseOutcome(arena: std.mem.Allocator, stdout: []const u8) EvalError!Outcome {
    return parseOutcomeExtras(arena, stdout, null);
}

fn parseOutcomeExtras(arena: std.mem.Allocator, stdout: []const u8, extras: ?*Extras) EvalError!Outcome {
    const reply = std.json.parseFromSliceLeaky(Reply, arena, stdout, .{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    }) catch return .{ .err = try errorText(arena, "the template evaluator returned an unreadable result", stdout) };
    if (extras) |x| {
        x.build = if (reply.build) |b| (if (b >= 0) @intCast(b) else null) else null;
        const notes = try arena.alloc([]const u8, reply.notes.len);
        for (reply.notes, 0..) |n, i| notes[notes.len - 1 - i] = n;
        x.notes = notes;
    }

    const kind = reply.kind;
    if (std.mem.eql(u8, kind, "code")) return .{ .code = reply.source };
    if (std.mem.eql(u8, kind, "ast")) return .{ .ast = reply.node };
    if (std.mem.eql(u8, kind, "value")) return .{ .value = try typedValue(arena, reply.value) };
    if (std.mem.eql(u8, kind, "capture")) return .{ .capture = reply.param orelse "" };
    if (std.mem.eql(u8, kind, "custom")) {
        const tree = (try customTree(arena, reply.ast)) orelse
            return .{ .err = "`q.custom` received a tree that is not a CustomNode" };
        return .{ .custom = .{ .code = reply.source, .ast = tree } };
    }
    if (std.mem.eql(u8, kind, "need")) return needOutcome(arena, reply);
    if (std.mem.eql(u8, kind, "fail")) return .{ .fail = .{
        .message = if (reply.message.len > 0) reply.message else "template rejected the input",
        .param = reply.param,
        .span = reply.span,
    } };
    const message = if (blockEval.divisionByZero(reply.message)) |plain| plain else if (reply.message.len > 0) reply.message else "template evaluation failed";
    const frames = try blockEval.framesOf(arena, reply.frames);
    if (frames.len > 0) return .{ .raised = .{ .message = message, .frames = frames } };
    return .{ .err = message };
}

/// Decision 302 — the request `q.annotate(decl, at)` replied with: the tag
/// (`kind`, `name`, `attrs` as `{"$tuple": [n, v]}` pairs, `answer` the index
/// of the answer it is, -1 for a fresh one) and the annotation's span.
fn needOutcome(arena: std.mem.Allocator, reply: Reply) EvalError!Outcome {
    const bad: Outcome = .{ .err = "`q.annotate` received a `Decl` the template did not build with `q.tagDecl`, or a span that is not a `Span`" };
    const obj = switch (reply.decl) {
        .object => |o| o,
        else => return bad,
    };
    const span = reply.span orelse return bad;
    const kind = jsonString(obj.get("kind")) orelse return bad;
    const name = jsonString(obj.get("name")) orelse return bad;
    const answer: i64 = if (obj.get("answer")) |a| switch (a) {
        .integer => |n| n,
        else => -1,
    } else -1;
    var attrs: std.ArrayListUnmanaged([2][]const u8) = .empty;
    if (obj.get("attrs")) |av| if (av == .array) for (av.array.items) |item| {
        const pair = switch (item) {
            .object => |o| o.get("$tuple") orelse return bad,
            else => return bad,
        };
        if (pair != .array or pair.array.items.len != 2) return bad;
        const n = jsonString(pair.array.items[0]) orelse return bad;
        const v = jsonString(pair.array.items[1]) orelse return bad;
        try attrs.append(arena, .{ n, v });
    };
    return .{ .need = .{ .kind = kind, .name = name, .attrs = attrs.items, .answer = answer, .span = span } };
}

pub fn typedValue(arena: std.mem.Allocator, v: std.json.Value) std.mem.Allocator.Error!TypedValue {
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
            // Key order is the reply's canonical one (`runtime/reply_order.zig`),
            // not the order the runtime's map happened to iterate in: it becomes
            // the lifted tuple's label order.
            std.mem.sort(TypedValue.KeyValuePair, out, {}, struct {
                fn lessThan(_: void, a: TypedValue.KeyValuePair, b: TypedValue.KeyValuePair) bool {
                    return std.mem.lessThan(u8, a.key, b.key);
                }
            }.lessThan);
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
            .identity = jsonString(ro.get("identity")) orelse "",
            .local = jsonString(ro.get("local")) orelse name,
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
        \\pub fn shout(syntax q: string) -> string {
        \\    return compiler.build(compiler.text(q));
        \\}
        \\import {compiler} from "std";
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
    var refused: []const u8 = "";
    const one = try capture(arena, "alpha");
    const two = try capture(arena, "a much longer literal");
    const first = try buildModule(arena, "", tfn, &.{}, &.{}, &.{}, &.{one}, &.{}, &unsupported, &refused);
    const second = try buildModule(arena, "", tfn, &.{}, &.{}, &.{}, &.{two}, &.{}, &unsupported, &refused);

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
    const shown = try argumentListing(arena, first.argument);
    try std.testing.expect(std.mem.indexOf(u8, shown, "%% main/1 argument") != null);
    try std.testing.expect(std.mem.indexOf(u8, shown, "alpha") != null);

    // C-01 — the owning module's path is in the atom and decodes back; the
    // same body declared in another module is another module, and one no
    // module owns keeps the compiler's own `bp@comptime`.
    try std.testing.expect(std.mem.startsWith(u8, first.module, "bp@comptime__tpl__shout__"));
    const owned = try buildModule(arena, "ui/panel", tfn, &.{}, &.{}, &.{}, &.{one}, &.{}, &unsupported, &refused);
    try std.testing.expect(std.mem.startsWith(u8, owned.module, "bp@comptime@ui@panel__tpl__shout__"));
    try std.testing.expect(std.mem.startsWith(u8, owned.code, "-module(bp@comptime@ui@panel__tpl__shout__"));
    const decoded = try crossModule.decodeAtom(arena, owned.module);
    try std.testing.expectEqualStrings("bp", decoded.package);
    try std.testing.expectEqualStrings("comptime/ui/panel", decoded.path);
    try std.testing.expectEqualStrings("tpl", decoded.kind);
    try std.testing.expectEqualStrings("shout", decoded.decl);
    const elsewhere = try buildModule(arena, "ui/card", tfn, &.{}, &.{}, &.{}, &.{one}, &.{}, &unsupported, &refused);
    try std.testing.expect(!std.mem.eql(u8, owned.module, elsewhere.module));
    // The hash segment is the body's, whoever owns it.
    try std.testing.expectEqualStrings(first.module[first.module.len - 16 ..], owned.module[owned.module.len - 16 ..]);
}

test "template module: the emit memo is keyed by the declaration's text and the plan, never a call site" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const lexerMod = @import("../lexer.zig");
    const parserMod = @import("../parser.zig");
    const parse = struct {
        fn decls(a: std.mem.Allocator, src: []const u8) ![]ast.DeclKind {
            var lx = lexerMod.Lexer.init(src);
            var p = parserMod.Parser.init(try lx.scanAll(a));
            return (try p.parse(a)).decls;
        }
    }.decls;
    const body =
        \\pub fn shout(syntax q: string) -> string {
        \\    return compiler.build(compiler.text(q));
        \\}
        \\import {compiler} from "std";
    ;
    const original = try parse(arena, body);
    // The same declaration parsed again at other positions (another session,
    // or the language server re-reading the file) is the same key.
    const moved = try parse(arena, "\n\n" ++ body);
    const edited = try parse(arena,
        \\pub fn shout(syntax q: string) -> string {
        \\    return compiler.build(compiler.text(q) + "!");
        \\}
        \\import {compiler} from "std";
    );

    const bound = [_]ArgPlan{.{ .term = Term.str("alpha"), .expr = Ast.Expr.v("Arg0"), .bound = true }};
    const other_capture = [_]ArgPlan{.{ .term = Term.str("a much longer literal"), .expr = Ast.Expr.v("Arg0"), .bound = true }};
    const literal = [_]ArgPlan{.{ .term = Term.undefined_atom, .expr = Ast.str("\\u{263A}"), .bound = false }};

    const key = (try emitKey(arena, "tpl", "main", original, &bound)).?;
    // The term is not part of the key: it is `main/1`'s argument, not the module.
    try std.testing.expectEqualStrings(key, (try emitKey(arena, "tpl", "main", original, &other_capture)).?);
    try std.testing.expectEqualStrings(key, (try emitKey(arena, "tpl", "main", moved, &bound)).?);
    // What the module text depends on is.
    try std.testing.expect(!std.mem.eql(u8, key, (try emitKey(arena, "tpl", "main", edited, &bound)).?));
    try std.testing.expect(!std.mem.eql(u8, key, (try emitKey(arena, "tpl", "main", original, &literal)).?));
    try std.testing.expect(!std.mem.eql(u8, key, (try emitKey(arena, "tpl", "ui/panel", original, &bound)).?));
    try std.testing.expect(!std.mem.eql(u8, key, (try emitKey(arena, "dec", "main", original, &bound)).?));
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
