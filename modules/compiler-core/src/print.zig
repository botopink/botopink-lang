/// rustc-style parse error renderer.
///
/// Example output:
///
///   error: There must be a 'val' or 'var' to bind a variable to a value
///    --> <test>:1:8
///     |
///   1 | wibble = 4
///     |        ^ There must be a 'val' or 'var' to bind a variable to a value
///     |
///     = hint: Use `val <n> = <value>` for bindings.
///
const std = @import("std");

const parserMod = @import("./parser.zig");
pub const ParseErrorInfo = parserMod.ParseErrorInfo;
pub const ParseErrorType = parserMod.ParseErrorType;

// ── Canonical messages ────────────────────────────────────────────────────────

pub const ErrorMessages = struct {
    message: []const u8,
    hint: []const u8,
    /// Optional error code rendered in brackets after `error` in the header:
    /// `error[<code>]: <message>` instead of plain `error: <message>`.
    code: ?[]const u8 = null,
    /// Optional alternate caption rendered after the `^^^` carets. When null,
    /// the carets caption duplicates `message`.
    caretCaption: ?[]const u8 = null,
    /// Optional `= note: ...` line emitted before `= hint: ...`.
    note: ?[]const u8 = null,
};

/// Returns the (message, hint) pair for a given parse error.
pub fn errorMessages(info: ParseErrorInfo) ErrorMessages {
    return switch (info.kind) {
        .novalBinding => .{
            .message = "There must be a 'val' or 'var' to bind a variable to a value",
            .hint = "Use `val <n> = <value>` for bindings.",
        },
        .reservedWord => .{
            .message = "This is a reserved word and cannot be used as a name",
            .hint = "Choose a different identifier.",
        },
        .unexpectedToken => .{
            .message = "Unexpected token",
            .hint = "Check the syntax around this position.",
        },
        .opNakedRight => .{
            .message = "This operator has no value on its right-hand side",
            .hint = "Remove the operator or place a value after it.",
        },
        .listSpreadWithoutTail => .{
            .message = "A spread here requires a tail list",
            .hint = "Provide a tail, e.g. [1, 2, ..rest]",
        },
        .listSpreadNotLast => .{
            .message = "Elements cannot appear after a spread",
            .hint = "Lists are singly-linked. Prepend items and reverse when done.",
        },
        .uselessSpread => .{
            .message = "This spread does nothing",
            .hint = "Try prepending elements: [1, 2, ..list]",
        },
        .removedErrorUnion => .{
            .message = "Error union syntax `T!E` has been removed",
            .hint = "Use `@Result<D, E>` instead, e.g. `fn fetch() -> @Result<i32, MyError>`",
        },
        .removedBuiltinType => .{
            .message = "Builtin type syntax `@Result(D, E)` has been removed",
            .hint = "Use `@Result<D, E>` instead",
        },
        .useAfterBranch => .{
            .message = "`use` must be in static prefix",
            .hint = "Move all `use` statements to the top of the function body, before any `if`, `case`, `loop`, or `return`",
        },
        .metaKindRequiresComptime => .{
            .message = "A `type`/`expr` parameter must be marked `comptime`",
            .hint = "Meta-kinds only exist at compile time, e.g. `fn f(comptime T: type)` or `fn html(comptime template: expr string)`",
        },
        .badInterpolation => .{
            .message = "Malformed `${…}` interpolation in string",
            .hint = "Each `${…}` must contain one complete expression, e.g. \"hi ${name}\"; escape a literal dollar with `\\${`",
        },
        .anonymousImplExtend => .{
            .message = "An `implement`/`extend` block must be named",
            .hint = "Give it a name, e.g. `Name implement Trait for Type { … }` or `Name extend Type { … }`",
        },
        .deprecatedStarFn => .{
            .code = "deprecated-star-fn",
            .message = "the `*fn` prefix was removed in v0.beta.19",
            .caretCaption = "use a `#[@<effect>]` annotation instead",
            .note = "the `*fn` form was deprecated in v0.beta.12; a `*fn -> @Result<…>` was equivalent to `#[@result]`, `@Future<…>` to `#[@future]`, `@Iterator<…>` to `#[@iterator]`, `@AsyncIterator<…>` to `#[@asyncGenerator]`, `@Generator<…>` to `#[@generator]`, and `@Context<…>` to `#[@context]`",
            .hint = "rewrite as `#[@<effect>] fn <name>(...) -> @<Wrapper><...> { ... }`",
        },
        .effectOnDeclareForbidden => .{
            .message = "effect-on-declare-forbidden: a #[@<effect>] annotation marks an IMPLEMENTATION (a fn with a body); `declare fn` declarations express the effect through the return wrapper alone.",
            .hint = "Drop the #[@<effect>] annotation — the return-type wrapper (@Result/@Future/…) already carries the effect on a `declare fn`.",
        },
        .effectOnInterfaceMethodForbidden => .{
            .message = "effect-on-interface-method-forbidden: interface methods are declarative — they express the effect through the return wrapper alone, never via #[@<effect>].",
            .hint = "Drop the #[@<effect>] annotation; the implementing fn carries it.",
        },
        .effectDuplicateAnnotation => .{
            .message = "effect-duplicate-annotation: at most one #[@<effect>] annotation per fn.",
            .hint = "Keep the single annotation that matches the return-type wrapper (e.g. `#[@result]` for `-> @Result<…>`).",
        },
        .genericDefaultBeforeRequired => .{
            .message = "generic-default-before-required: default-typed generic parameters must be the trailing parameters of the list.",
            .hint = "Either give the following parameter a default too, or remove the default from the earlier one.",
        },
        .yieldBreakRemoved => .{
            .message = "yield-break-removed: use `break <C>` to end an iterator with a completion value. The `yield break` form was removed in v0.beta.19.",
            .hint = "Inside a #[@iterator] / #[@asyncGenerator] body, write `break <C>` to deliver a completion value, or bare `break` for a clean end.",
        },
        .genericArgSkipForbidden => .{
            .message = "generic-arg-skip-forbidden: cannot skip a defaulted argument while providing a later one.",
            .hint = "Either pass the middle argument explicitly, or rely on defaults for the contiguous trailing range.",
        },
        .fnParamDefaultTrailingOnly => .{
            .message = "fn-param-default-trailing-only: a defaulted parameter must be followed only by other defaulted parameters.",
            .hint = "Move the defaulted parameter to the end of the list, or give the following parameter a default too.",
        },
        .fnParamPositionalAfterNamed => .{
            .message = "fn-param-positional-after-named: positional argument supplied after a named one.",
            .hint = "Convert the trailing positional arg to a named one (`name: value`), or move the named argument to the end of the call.",
        },
    };
}

// ── Main renderer ─────────────────────────────────────────────────────────────

/// Renders a parse error to any `writer` (stderr, ArrayList(u8), etc).
///
/// `source`    ---- original source text (used to extract the context line).
/// `filePath` ---- path shown in the header (e.g. "src/main.botopink" or "<test>").
///
/// Output format (gutter = line-number width + 1 space):
///
///   error: <message>
///    --> <file>:<line>:<col>
///   <gutter> |
///   <line>   | <source line>
///   <gutter> | <spaces><carets> <detail>
///   <gutter> |
///   <gutter> = hint: <hint>
///
pub fn render(
    writer: anytype,
    info: ParseErrorInfo,
    source: []const u8,
    filePath: []const u8,
) !void {
    const msgs = errorMessages(info);
    const loc = findLocation(source, info.start);

    // width of the line number, e.g. line 1 -> 1, line 42 -> 2
    const lineW = digitWidth(loc.line);
    // gutter: spaces needed to align "|" with the line number column
    // e.g. "1 | ..." -> gutter=2, so blank gutter lines get 2 spaces before "|"
    const gutter = lineW + 1;

    // "error: <message>" or, when a code is set, "error[<code>]: <message>"
    if (msgs.code) |code| {
        try writer.print("error[{s}]: {s}\n", .{ code, msgs.message });
    } else {
        try writer.print("error: {s}\n", .{msgs.message});
    }

    // " --> <file>:<line>:<col>"  (gutter-1 spaces before "-->")
    try writePad(writer, gutter - 1);
    try writer.print("--> {s}:{d}:{d}\n", .{ filePath, loc.line, loc.col });

    // "<gutter>|"  ---- blank line above source
    try writePad(writer, gutter);
    try writer.print("|\n", .{});

    // "<line> | <text>"
    try writer.print("{d} | {s}\n", .{ loc.line, loc.lineText });

    // "<gutter>| <spaces><carets> <caption>"
    // The caret caption defaults to `message`; a kind may override it to give
    // the rejected span a tighter directive (e.g. "use a `#[@<effect>]`…").
    const caption = msgs.caretCaption orelse msgs.message;
    try writePad(writer, gutter);
    try writer.print("| ", .{});
    const spanLen = if (info.end > info.start) info.end - info.start else 1;
    try writePadN(writer, loc.col - 1, ' ');
    try writePadN(writer, spanLen, '^');
    try writer.print(" {s}\n", .{caption});

    // "<gutter>|"  ---- blank line below carets
    try writePad(writer, gutter);
    try writer.print("|\n", .{});

    // Optional "<gutter>= note: <note>" line — when set, it precedes the hint.
    if (msgs.note) |note| {
        try writePad(writer, gutter);
        try writer.print("= note: {s}\n", .{note});
    }

    // "<gutter>= hint: <hint>"
    try writePad(writer, gutter);
    try writer.print("= hint: {s}\n", .{msgs.hint});

    // trailing blank line
    try writer.print("\n", .{});
}

/// Allocating version ---- renders to a new string. Convenient for snapshot tests.
pub fn renderAlloc(
    allocator: std.mem.Allocator,
    info: ParseErrorInfo,
    source: []const u8,
    filePath: []const u8,
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    try render(&aw.writer, info, source, filePath);
    return aw.toOwnedSlice();
}

// ── Internal types and helpers ────────────────────────────────────────────────

const Location = struct {
    lineText: []const u8,
    line: usize, // 1-based
    col: usize, // 1-based
};

fn findLocation(source: []const u8, byteOffset: usize) Location {
    var line: usize = 1;
    var lineStart: usize = 0;
    const safeOffset = @min(byteOffset, source.len);

    var i: usize = 0;
    while (i < safeOffset) : (i += 1) {
        if (source[i] == '\n') {
            line += 1;
            lineStart = i + 1;
        }
    }

    var lineEnd = lineStart;
    while (lineEnd < source.len and source[lineEnd] != '\n') : (lineEnd += 1) {}

    const col = safeOffset - lineStart + 1;
    return .{
        .lineText = source[lineStart..lineEnd],
        .line = line,
        .col = col,
    };
}

fn digitWidth(n: usize) usize {
    if (n == 0) return 1;
    var w: usize = 0;
    var v = n;
    while (v > 0) : (v /= 10) w += 1;
    return w;
}

fn writePad(writer: anytype, n: usize) !void {
    for (0..n) |_| try writer.writeByte(' ');
}

fn writePadN(writer: anytype, n: usize, ch: u8) !void {
    for (0..n) |_| try writer.writeByte(ch);
}
