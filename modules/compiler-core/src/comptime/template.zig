/// Comptime template infrastructure for the `expr` meta-kind (expr-templates F4).
///
/// `CapturedExpr`  — an argument bound to a `comptime p: expr T` parameter,
///                   captured **unevaluated** at the call site with provenance
///                   (module path, location, origin-scope snapshot).
/// `ScopeSnapshot` — V1 origin-scope model: the capturing module's top-level
///                   declarations + imports, name → BindingKind. Function
///                   locals are not visible (V1 limit recorded in the spec).
/// `Span` / `mapSpanToLoc` / `failDiagnostic` — map a template-relative span
///                   back into the caller's file so `fail`/`failAt` point
///                   inside the `"""…"""` literal, not at the library.
///
/// The stdlib data model (`std.syntax`: `Span`, `Part`, `Binding`,
/// `BindingKind`) mirrors these shapes as ordinary `.bp` types; the call-site
/// expansion pass (F6) bridges the two.
const std = @import("std");
const ast = @import("../ast.zig");
const TypeError = @import("./error.zig").TypeError;

// ── scope snapshot ────────────────────────────────────────────────────────────

/// What kind of top-level declaration a name resolves to.
/// Mirrors `std.syntax.BindingKind` (records and structs both map to `struct_`).
pub const BindingKind = enum {
    fn_,
    val,
    struct_,
    enum_,
    interface,

    /// The `std.syntax.BindingKind` variant name for serialization.
    pub fn variantName(self: BindingKind) []const u8 {
        return switch (self) {
            .fn_ => "Fn",
            .val => "Val",
            .struct_ => "Struct",
            .enum_ => "Enum",
            .interface => "Interface",
        };
    }
};

/// One name visible in an expression's origin scope.
pub const ScopeEntry = struct {
    name: []const u8,
    kind: BindingKind,
    /// true when the name arrives via an import (`use { … }`).
    isImport: bool = false,
};

/// V1 origin-scope snapshot: top-level decls + imports of one module, in
/// declaration order. Built once per module by inference and attached to every
/// capture; `lookup` on a template resolves against this map.
pub const ScopeSnapshot = struct {
    /// Arena every entry lives in (same lifetime as the type-check session).
    arena: std.mem.Allocator,
    /// Module path of the scope's file ("" for main).
    modulePath: []const u8,
    /// name → entry, preserving declaration order (deterministic serialization).
    entries: std.StringArrayHashMapUnmanaged(ScopeEntry),

    pub fn init(arena: std.mem.Allocator, modulePath: []const u8) !*ScopeSnapshot {
        const snap = try arena.create(ScopeSnapshot);
        snap.* = .{
            .arena = arena,
            .modulePath = modulePath,
            .entries = .empty,
        };
        return snap;
    }

    /// Record a visible name. A redeclaration keeps the latest kind.
    pub fn put(self: *ScopeSnapshot, name: []const u8, kind: BindingKind, isImport: bool) !void {
        try self.entries.put(self.arena, name, .{ .name = name, .kind = kind, .isImport = isImport });
    }

    /// Resolve `name` in this scope; null on a miss (the `lookup` extension
    /// surfaces the miss as `@Option` none).
    pub fn lookup(self: *const ScopeSnapshot, name: []const u8) ?ScopeEntry {
        return self.entries.get(name);
    }

    /// Serialize as a JSON object `{"name": "Kind", …}` in declaration order —
    /// the opaque handle handed to the expansion runtime (F6). Caller owns the
    /// returned slice.
    pub fn toJsonAlloc(self: *const ScopeSnapshot, allocator: std.mem.Allocator) ![]u8 {
        var buf: std.ArrayList(u8) = .empty;
        errdefer buf.deinit(allocator);
        try buf.append(allocator, '{');
        var it = self.entries.iterator();
        var first = true;
        while (it.next()) |e| {
            if (!first) try buf.append(allocator, ',');
            first = false;
            try buf.append(allocator, '"');
            try buf.appendSlice(allocator, e.value_ptr.name);
            try buf.appendSlice(allocator, "\":\"");
            try buf.appendSlice(allocator, e.value_ptr.kind.variantName());
            try buf.append(allocator, '"');
        }
        try buf.append(allocator, '}');
        return buf.toOwnedSlice(allocator);
    }
};

// ── captured expressions ──────────────────────────────────────────────────────

/// An argument bound to a `comptime p: expr T` parameter: type-checked in the
/// caller (its type unified against the inner `T`), then captured unevaluated.
/// V1 requires a literal string at the call site (single or multiline,
/// interpolation allowed) — a variable carries no span/scope to attach.
pub const CapturedExpr = struct {
    /// The called template function's name.
    callee: []const u8,
    /// Index + name of the `expr` parameter this capture binds to.
    paramIndex: usize,
    paramName: []const u8,
    /// The argument exactly as parsed (unevaluated; `.literal` with
    /// `stringLit` or `stringTemplate` kind). Points into the parse arena.
    node: *const ast.Expr,
    /// Raw template text for a plain string literal (escapes unprocessed);
    /// null when the template has `${…}` holes — the parts live on `node`.
    text: ?[]const u8,
    /// true when the literal was written as `"""…"""`.
    multiline: bool,
    /// Location of the literal in the caller's file.
    loc: ast.Loc,
    /// Module path of the caller's file ("" for main).
    modulePath: []const u8,
    /// Origin scope for `lookup`/`fail` resolution (V1: top-level decls +
    /// imports). Null only in direct unit-test paths that bypass
    /// `inferProgram*`.
    scope: ?*ScopeSnapshot,
};

// ── second-layer context ──────────────────────────────────────────────────────

/// Append `s` to `buf` as a JSON string literal (quoted + escaped).
/// Also used by `template_eval.zig` to serialize template parts.
pub fn appendJsonString(buf: *std.ArrayList(u8), allocator: std.mem.Allocator, s: []const u8) !void {
    try buf.append(allocator, '"');
    for (s) |c| switch (c) {
        '"' => try buf.appendSlice(allocator, "\\\""),
        '\\' => try buf.appendSlice(allocator, "\\\\"),
        '\n' => try buf.appendSlice(allocator, "\\n"),
        '\r' => try buf.appendSlice(allocator, "\\r"),
        '\t' => try buf.appendSlice(allocator, "\\t"),
        else => if (c < 0x20) {
            var hex: [6]u8 = undefined;
            const written = std.fmt.bufPrint(&hex, "\\u{x:0>4}", .{c}) catch unreachable;
            try buf.appendSlice(allocator, written);
        } else try buf.append(allocator, c),
    };
    try buf.append(allocator, '"');
}

/// Serialize a capture's second-layer context as one JSON object —
/// everything a DSL compiler running inside a template function needs:
/// declaration position (`file`/`line`/`col`), shape (`multiline`), raw
/// `text` (null when `${…}` holes split it — the parts live on the node),
/// and the origin `scope`. This is the handle the runtime-backed evaluator
/// (F6-full) hands to `source()`/`context()`/`bindings()`. Caller owns the
/// returned slice.
pub fn contextJsonAlloc(capture: *const CapturedExpr, allocator: std.mem.Allocator) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(allocator);

    var numBuf: [24]u8 = undefined;
    try buf.appendSlice(allocator, "{\"file\":");
    try appendJsonString(&buf, allocator, capture.modulePath);
    try buf.appendSlice(allocator, ",\"line\":");
    try buf.appendSlice(allocator, std.fmt.bufPrint(&numBuf, "{d}", .{capture.loc.line}) catch unreachable);
    try buf.appendSlice(allocator, ",\"col\":");
    try buf.appendSlice(allocator, std.fmt.bufPrint(&numBuf, "{d}", .{capture.loc.col}) catch unreachable);
    try buf.appendSlice(allocator, ",\"multiline\":");
    try buf.appendSlice(allocator, if (capture.multiline) "true" else "false");
    try buf.appendSlice(allocator, ",\"text\":");
    if (capture.text) |txt| {
        try appendJsonString(&buf, allocator, txt);
    } else {
        try buf.appendSlice(allocator, "null");
    }
    try buf.appendSlice(allocator, ",\"scope\":");
    if (capture.scope) |scope| {
        const scopeJson = try scope.toJsonAlloc(allocator);
        defer allocator.free(scopeJson);
        try buf.appendSlice(allocator, scopeJson);
    } else {
        try buf.appendSlice(allocator, "{}");
    }
    try buf.append(allocator, '}');
    return buf.toOwnedSlice(allocator);
}

// ── plain comptime arguments ──────────────────────────────────────────────────

/// A non-`@Expr` parameter in a template function that received a literal value
/// at the call site. Serialized as a plain JS binding in the eval script so the
/// template body can use it alongside the `@Expr` capture objects.
pub const PlainArg = struct {
    /// Name of the parameter as declared in the template function.
    paramName: []const u8,
    /// The argument's value as a JS literal expression (e.g. `"42"`, `"\"hi\""`, `"true"`).
    jsValue: []const u8,
};

// ── span mapping + diagnostics ────────────────────────────────────────────────

/// A template-relative span (the Zig-side shape of `std.syntax.Span`):
/// byte offsets into the template text plus a 1-based line within it.
pub const Span = struct {
    start: usize,
    end: usize,
    line: usize,
};

// ── custom AST (expr-custom) ──────────────────────────────────────────────────

/// A node's optional tie to an origin-scope symbol — the Zig-side shape of a
/// `std.syntax.Binding` carried on a `CustomNode.ref` (a `q.lookup` result).
/// `kind` is the resolved binding's variant name ("Val"/"Fn"/…), kept as an
/// opaque string: the core never interprets it.
pub const NodeBinding = struct {
    name: []const u8,
    kind: []const u8,
};

/// The Zig-side shape of a `std.syntax.CustomNode`: one node of ANY embedded
/// sub-language, in the single canonical form the core/tooling understand
/// without knowing the language. `kind`/`label` are opaque tags the producing
/// lib chose (the core never branches on them); `span` indexes the template's
/// source text; `ref` optionally associates the node with a caller-scope
/// symbol. This tree is reference-only — it never reaches codegen.
pub const CustomNode = struct {
    kind: []const u8,
    span: Span,
    label: []const u8,
    ref: ?NodeBinding,
    children: []const CustomNode,
};

fn jsonStr(v: ?std.json.Value) ?[]const u8 {
    return switch (v orelse return null) {
        .string => |s| s,
        else => null,
    };
}

fn jsonUsizeField(v: ?std.json.Value) usize {
    return switch (v orelse return 0) {
        .integer => |n| if (n >= 0) @intCast(n) else 0,
        .float => |f| if (f >= 0) @intFromFloat(f) else 0,
        else => 0,
    };
}

fn parseSpanJson(v: ?std.json.Value) Span {
    const obj = switch (v orelse return .{ .start = 0, .end = 0, .line = 1 }) {
        .object => |o| o,
        else => return .{ .start = 0, .end = 0, .line = 1 },
    };
    return .{
        .start = jsonUsizeField(obj.get("start")),
        .end = jsonUsizeField(obj.get("end")),
        .line = blk: {
            const l = jsonUsizeField(obj.get("line"));
            break :blk if (l == 0) 1 else l;
        },
    };
}

/// Deserialize the JSON `CustomNode` tree a template returned via `q.custom`
/// into the Zig-side `CustomNode`. Strings are duped into `arena` (the
/// type-check session). Generic throughout — no sub-language is named.
pub fn parseCustomNode(arena: std.mem.Allocator, v: std.json.Value) error{OutOfMemory}!CustomNode {
    const obj = switch (v) {
        .object => |o| o,
        else => return CustomNode{ .kind = "", .span = .{ .start = 0, .end = 0, .line = 1 }, .label = "", .ref = null, .children = &.{} },
    };

    const ref: ?NodeBinding = blk: {
        const ro = switch (obj.get("ref") orelse break :blk null) {
            .object => |o| o,
            else => break :blk null,
        };
        const name = jsonStr(ro.get("name")) orelse break :blk null;
        break :blk NodeBinding{
            .name = try arena.dupe(u8, name),
            .kind = try arena.dupe(u8, jsonStr(ro.get("kind")) orelse ""),
        };
    };

    var children: []const CustomNode = &.{};
    if (obj.get("children")) |c| switch (c) {
        .array => |arr| {
            const buf = try arena.alloc(CustomNode, arr.items.len);
            for (arr.items, 0..) |child, i| buf[i] = try parseCustomNode(arena, child);
            children = buf;
        },
        else => {},
    };

    return CustomNode{
        .kind = try arena.dupe(u8, jsonStr(obj.get("kind")) orelse ""),
        .span = parseSpanJson(obj.get("span")),
        .label = try arena.dupe(u8, jsonStr(obj.get("label")) orelse ""),
        .ref = ref,
        .children = children,
    };
}

/// Map a template-relative `span` to a location in the caller's file.
///
/// When the contiguous template text is available, line/column are derived
/// from `span.start` by counting newlines — a multiline literal's content
/// starts with the `\n` right after the opening `"""`, so the offset lands on
/// the correct file line with no special casing. With `${…}` holes the
/// mapping falls back to `span.line` (1-based line within the template).
pub fn mapSpanToLoc(capture: *const CapturedExpr, span: Span) ast.Loc {
    if (capture.text) |txt| {
        var line: usize = 0; // newlines crossed before `span.start`
        var lineStart: usize = 0;
        const upto = @min(span.start, txt.len);
        for (txt[0..upto], 0..) |c, i| {
            if (c == '\n') {
                line += 1;
                lineStart = i + 1;
            }
        }
        if (line == 0) {
            // Still on the literal's own line: content sits after the opening quote.
            return .{ .line = capture.loc.line, .col = capture.loc.col + 1 + upto };
        }
        return .{ .line = capture.loc.line + line, .col = upto - lineStart + 1 };
    }
    // Holes present — line-based fallback.
    // `span.line` is 1-based (line 1 = the opening `"""` line); subtract 1 so
    // line 1 maps to capture.loc.line and line N maps to capture.loc.line + N-1.
    if (capture.multiline) return .{ .line = capture.loc.line + span.line -| 1, .col = 1 };
    return .{ .line = capture.loc.line, .col = capture.loc.col };
}

/// Build the rustc-style diagnostic for `fail`/`failAt`: `msg` points at the
/// template (or a `span` inside it) in the **caller's** file — never at the
/// template library. Consumed by the expansion pass (F6) when a template
/// function aborts.
pub fn failDiagnostic(capture: *const CapturedExpr, span: ?Span, msg: []const u8) TypeError {
    const loc = if (span) |s| mapSpanToLoc(capture, s) else capture.loc;
    return TypeError.custom(
        msg,
        "raised by the template function via `fail`/`failAt` against this template",
    ).withLoc(loc);
}
