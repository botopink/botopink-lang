//! The commonJS runtime helpers, as built nodes.
//!
//! Most primitive methods lower to a native JS method or an inline host
//! template. A few native methods disagree with the botopink signature
//! (`"ab".charAt(5)` is `""` where `String.charAt` says `?string`), and those
//! need JavaScript of our own. It is never a shipped runtime file: only the
//! helper a module actually calls is written into that module, as a plain
//! function declaration built from `js_ast` nodes like any other.
//!
//! The shape is `codegen/wat/wat_prelude.zig`'s: a call site never spells a
//! helper's name — `Emitter.helper` in `commonJS.zig` hands out the symbol
//! **and** marks the helper for emission in one call, so a module cannot call a
//! helper it does not define.
//!
//! A helper answers a primitive *declaration* (`String.charAt`), which is the
//! identity every backend's lowering of that method shares.

const std = @import("std");
const ast = @import("js_ast.zig");

pub const Helper = enum {
    /// `assert cond, msg` outside test mode: always fatal, naming the message
    /// and the `file:line` (cross-backend semantics decision 4).
    assert_fatal,
    /// `String.charAt(i) -> ?string`: the character, or `null` out of range.
    string_char_at,
    /// An open-ended range `a..` used as a value: the lazy, unbounded
    /// sequence `a, a + 1, …` as a generator (a finite array cannot hold it).
    range_from,
    /// The text of one printed value (semantics decisions 1 and 1a), as a
    /// `console.log` format plus the values it consumes: a string at top level
    /// is itself, nested it is quoted with the source escapes; an array is
    /// `[a,b]`, a tuple `#(a,b)`; anything else is `%O` — what `console.log`
    /// prints for it. A tuple is a JS array, so it is told apart only by the
    /// static shape the call site passes.
    show,
    /// `@print`/`@println`/`@debug` with no tuple shape known: every argument
    /// through `show`, space-separated, one `console.log` line.
    print,
    /// The same with a static shape per argument (`["#", …]` a tuple,
    /// `["[", elem]` an array, `null` unknown).
    print_as,
};

/// Emission order of the helpers a module uses.
pub const order = [_]Helper{ .assert_fatal, .string_char_at, .range_from, .show, .print, .print_as };

/// The receiver family of a primitive method call, as inference recorded it.
pub const Receiver = enum { string, array, other };

/// The helper that replaces the native method `method` on a `receiver`
/// value, or null when the native method (or the annotation's template)
/// already matches the signature.
pub fn forMethod(receiver: Receiver, method: []const u8, argc: usize) ?Helper {
    if (receiver == .string and argc == 1 and std.mem.eql(u8, method, "charAt")) return .string_char_at;
    return null;
}

/// The function name a call site uses.
pub fn name(h: Helper) []const u8 {
    return switch (h) {
        .assert_fatal => "__bp_assert_fatal",
        .string_char_at => "__bp_string_char_at",
        .range_from => "__bp_range_from",
        .show => "__bp_show",
        .print => "__bp_print",
        .print_as => "__bp_print_as",
    };
}

/// The helper's declaration.
pub fn decl(h: Helper) ast.Stmt {
    return switch (h) {
        .assert_fatal => assert_fatal,
        .string_char_at => string_char_at,
        .range_from => range_from,
        .show => show,
        .print => print,
        .print_as => print_as,
    };
}

// ── the helpers ──────────────────────────────────────────────────────────────

const cond: ast.Expr = .{ .name = "cond" };
const msg: ast.Expr = .{ .name = "msg" };
const loc: ast.Expr = .{ .name = "loc" };

/// `function __bp_assert_fatal(cond, msg, loc) { if (!cond) { throw new Error((msg ?? "assertion failed") + " at " + loc); } }`
const assert_fatal: ast.Stmt = .{ .function = .{
    .name = "__bp_assert_fatal",
    .params = &.{ .{ .pattern = .{ .name = "cond" } }, .{ .pattern = .{ .name = "msg" } }, .{ .pattern = .{ .name = "loc" } } },
    .body = .{ .stmts = &.{.{ .if_ = .{
        .cond = .{ .unary = .{ .op = "!", .operand = &cond, .parens = false } },
        .then = &.{ .block = .{ .stmts = &.{.{ .throw_ = .{ .new_ = .{
            .callee = &.{ .name = "Error" },
            .args = &.{.{ .binary = .{
                .op = "+",
                .lhs = &.{ .binary = .{
                    .op = "+",
                    .lhs = &.{ .binary = .{ .op = "??", .lhs = &msg, .rhs = &.{ .quoted = "assertion failed" } } },
                    .rhs = &.{ .quoted = " at " },
                    .parens = false,
                } },
                .rhs = &loc,
                .parens = false,
            } }},
        } } }}, .layout = .spaced } },
    } }}, .layout = .spaced },
} };

const s: ast.Expr = .{ .name = "s" };
const i: ast.Expr = .{ .name = "i" };
const zero: ast.Expr = .{ .number = "0" };
const s_length: ast.Expr = .{ .member = .{ .object = &s, .name = "length" } };
const s_char_at: ast.Expr = .{ .member = .{ .object = &s, .name = "charAt" } };

/// `function __bp_string_char_at(s, i) { return (i >= 0 && i < s.length) ? s.charAt(i) : null; }`
const string_char_at: ast.Stmt = .{ .function = .{
    .name = "__bp_string_char_at",
    .params = &.{ .{ .pattern = .{ .name = "s" } }, .{ .pattern = .{ .name = "i" } } },
    .body = .{ .stmts = &.{.{ .return_ = .{ .ternary = .{
        .cond = &.{ .paren = &.{ .binary = .{
            .op = "&&",
            .lhs = &.{ .binary = .{ .op = ">=", .lhs = &i, .rhs = &zero, .parens = false } },
            .rhs = &.{ .binary = .{ .op = "<", .lhs = &i, .rhs = &s_length, .parens = false } },
            .parens = false,
        } } },
        .then = &.{ .call = .{ .callee = &s_char_at, .args = &.{i} } },
        .else_ = &.null_,
    } } }}, .layout = .spaced },
} };

const n: ast.Expr = .{ .name = "n" };
const one: ast.Expr = .{ .number = "1" };

/// `function* __bp_range_from(n) { while (true) { yield n; n += 1; } }`
const range_from: ast.Stmt = .{ .function = .{
    .keyword = "function*",
    .name = "__bp_range_from",
    .params = &.{.{ .pattern = .{ .name = "n" } }},
    .body = .{ .stmts = &.{.{ .while_ = .{
        .cond = .{ .name = "true" },
        .body = .{ .stmts = &.{
            .{ .expr = .{ .yield_ = &n } },
            .{ .expr = .{ .assign = .{ .target = &n, .op = "+=", .value = &one } } },
        }, .layout = .spaced },
    } }}, .layout = .spaced },
} };

const v: ast.Expr = .{ .name = "v" };
const c: ast.Expr = .{ .name = "c" };
const sh: ast.Expr = .{ .name = "s" };
const t: ast.Expr = .{ .name = "t" };
const null_: ast.Expr = .null_;

fn eq(comptime lhs: *const ast.Expr, comptime rhs: []const u8) ast.Expr {
    return .{ .binary = .{ .op = "===", .lhs = lhs, .rhs = &.{ .quoted = rhs } } };
}

fn callOn(comptime object: *const ast.Expr, comptime method: []const u8, comptime args: []const ast.Expr) ast.Expr {
    return .{ .call = .{ .callee = &.{ .member = .{ .object = object, .name = method } }, .args = args } };
}

/// `"\"" + Array.from(v, (c) => … escape c …).join("") + "\""`
const quoted_v: ast.Expr = .{ .binary = .{
    .op = "+",
    .lhs = &.{ .binary = .{
        .op = "+",
        .lhs = &.{ .quoted = "\\\"" },
        .rhs = &callOn(&.{ .call = .{ .callee = &.{ .member = .{ .object = &.{ .name = "Array" }, .name = "from" } }, .args = &.{
            v,
            .{ .arrow = .{ .params = &.{.{ .pattern = .{ .name = "c" } }}, .body = .{ .expr = &.{ .ternary = .{
                .cond = &.{ .binary = .{ .op = "||", .lhs = &eq(&c, "\\\""), .rhs = &eq(&c, "\\\\") } },
                .then = &.{ .binary = .{ .op = "+", .lhs = &.{ .quoted = "\\\\" }, .rhs = &c } },
                .else_ = &.{ .ternary = .{
                    .cond = &eq(&c, "\\n"),
                    .then = &.{ .quoted = "\\\\n" },
                    .else_ = &.{ .ternary = .{
                        .cond = &eq(&c, "\\r"),
                        .then = &.{ .quoted = "\\\\r" },
                        .else_ = &.{ .ternary = .{ .cond = &eq(&c, "\\t"), .then = &.{ .quoted = "\\\\t" }, .else_ = &c } },
                    } },
                } },
            } } } } },
        } } }, "join", &.{.{ .quoted = "" }}),
    } },
    .rhs = &.{ .quoted = "\\\"" },
} };

/// `(t ? "#(" : "[") + v.map((e, i) => __bp_show(e, s == null ? null : t ? s[i + 1] : s[1], false, a)).join(", ") + (t ? ")" : "]")`
const bracketed_v: ast.Expr = .{ .binary = .{
    .op = "+",
    .lhs = &.{ .binary = .{
        .op = "+",
        .lhs = &.{ .paren = &.{ .ternary = .{ .cond = &t, .then = &.{ .quoted = "#(" }, .else_ = &.{ .quoted = "[" } } } },
        .rhs = &callOn(&callOn(&v, "map", &.{.{ .arrow = .{
            .params = &.{ .{ .pattern = .{ .name = "e" } }, .{ .pattern = .{ .name = "i" } } },
            .body = .{ .expr = &.{ .call = .{ .callee = &.{ .name = "__bp_show" }, .args = &.{
                .{ .name = "e" },
                .{ .ternary = .{
                    .cond = &.{ .binary = .{ .op = "==", .lhs = &sh, .rhs = &null_ } },
                    .then = &null_,
                    .else_ = &.{ .ternary = .{
                        .cond = &t,
                        .then = &.{ .index = .{ .object = &sh, .index = &.{ .binary = .{ .op = "+", .lhs = &.{ .name = "i" }, .rhs = &one, .parens = false } } } },
                        .else_ = &.{ .index = .{ .object = &sh, .index = &one } },
                    } },
                } },
                .{ .name = "false" },
                args_a,
            } } } },
        } }}), "join", &.{.{ .quoted = ", " }}),
    } },
    .rhs = &.{ .paren = &.{ .ternary = .{ .cond = &t, .then = &.{ .quoted = ")" }, .else_ = &.{ .quoted = "]" } } } },
} };

const args_a: ast.Expr = .{ .name = "a" };

/// `a.push(<value>); return "<verb>";`, as a block at `indent`.
fn pushAndReturn(comptime value: ast.Expr, comptime verb: []const u8, comptime indent: usize) ast.Stmt {
    return .{ .block = .{ .stmts = &.{
        .{ .expr = callOn(&args_a, "push", &.{value}) },
        .{ .return_ = .{ .quoted = verb } },
    }, .layout = .indented, .indent = indent } };
}

const v_bp: ast.Expr = .{ .member = .{ .object = &v, .name = "__bp" } };
const v_tag: ast.Expr = .{ .member = .{ .object = &v, .name = "tag" } };
const keys_k: ast.Expr = .{ .name = "k" };

fn typeofIs(comptime operand: *const ast.Expr, comptime what: []const u8) ast.Expr {
    return .{ .binary = .{
        .op = "===",
        .lhs = &.{ .unary = .{ .op = "typeof ", .operand = operand, .parens = false } },
        .rhs = &.{ .quoted = what },
    } };
}

/// `if ((typeof v === "number") && (s === "f")) { a.push(Number.isInteger(v) ? v.toFixed(1) : String(v)); return "%s"; }`
///
/// Decision 8 § 7 — an `f64` always carries its decimal part, on every backend.
/// JavaScript has one number type, so the call site says which values are
/// floats: `"f"` is the print shape `commonJS.zig` builds for an expression it
/// types as `f64`.
const float_branch: ast.Stmt = .{ .if_ = .{
    .cond = .{ .binary = .{ .op = "&&", .lhs = &typeofIs(&v, "number"), .rhs = &eq(&sh, "f") } },
    .then = &pushAndReturn(.{ .ternary = .{
        .cond = &callOn(&.{ .name = "Number" }, "isInteger", &.{v}),
        .then = &callOn(&v, "toFixed", &.{.{ .number = "1" }}),
        .else_ = &.{ .call = .{ .callee = &.{ .name = "String" }, .args = &.{v} } },
    } }, "%s", 1),
} };

/// `v.__bp + "." + v.tag` for a variant, `v.__bp` for a record — the source
/// name of the value's type. The base class of an enum carries `__bp` and each
/// variant subclass carries `tag`, so a variant inherits both.
const named_title: ast.Expr = .{ .ternary = .{
    .cond = &typeofIs(&v_tag, "string"),
    .then = &.{ .binary = .{
        .op = "+",
        .lhs = &.{ .binary = .{ .op = "+", .lhs = &v_bp, .rhs = &.{ .quoted = "." } } },
        .rhs = &v_tag,
    } },
    .else_ = &v_bp,
} };

/// `"(" + k.map((n) => n + ": " + __bp_show(v[n], null, false, a)).join(", ") + ")"`
const named_fields: ast.Expr = .{ .binary = .{
    .op = "+",
    .lhs = &.{ .binary = .{
        .op = "+",
        .lhs = &.{ .quoted = "(" },
        .rhs = &callOn(&callOn(&keys_k, "map", &.{.{ .arrow = .{
            .params = &.{.{ .pattern = .{ .name = "n" } }},
            .body = .{ .expr = &.{ .binary = .{
                .op = "+",
                .lhs = &.{ .binary = .{ .op = "+", .lhs = &.{ .name = "n" }, .rhs = &.{ .quoted = ": " } } },
                .rhs = &.{ .call = .{ .callee = &.{ .name = "__bp_show" }, .args = &.{
                    .{ .index = .{ .object = &v, .index = &.{ .name = "n" } } },
                    null_,
                    .{ .name = "false" },
                    args_a,
                } } },
            } } },
        } }}), "join", &.{.{ .quoted = ", " }}),
    } },
    .rhs = &.{ .quoted = ")" },
} };

/// ```js
/// if ((v != null) && (typeof v.__bp === "string")) {
///     if ((typeof v.display === "function")) { a.push(v.display()); return "%s"; }
///     const k = Object.keys(v);
///     return <title> + ((k.length === 0) ? "" : <fields>);
/// }
/// ```
///
/// Decision 8 § 7 — a record prints `Point(x: 1, y: 2)` and a variant
/// `Shape.Square(side: 4)` / `Shape.Nothing`, in the language's shape rather
/// than `util.inspect`'s. The marker `__bp` is a prototype property every
/// record class and every enum base class carries (decision 5), so only a
/// botopink value takes this branch — a host object keeps `%O`. `Object.keys`
/// answers the payload fields in declaration order, because the constructor
/// assigns them in that order and `__bp` and `tag` live on the prototype.
/// A type implementing `Display` answers its own `display()`, nested too.
const named_branch: ast.Stmt = .{ .if_ = .{
    .cond = .{ .binary = .{
        .op = "&&",
        .lhs = &.{ .binary = .{ .op = "!=", .lhs = &v, .rhs = &null_ } },
        .rhs = &typeofIs(&v_bp, "string"),
    } },
    .then = &.{ .block = .{ .stmts = &.{
        .{ .if_ = .{
            .cond = typeofIs(&.{ .member = .{ .object = &v, .name = "display" } }, "function"),
            .then = &pushAndReturn(callOn(&v, "display", &.{}), "%s", 2),
        } },
        .{ .decl = .{ .pattern = .{ .name = "k" }, .value = callOn(&.{ .name = "Object" }, "keys", &.{v}) } },
        .{ .return_ = .{ .binary = .{
            .op = "+",
            .lhs = &.{ .paren = &named_title },
            .rhs = &.{ .paren = &.{ .ternary = .{
                .cond = &.{ .binary = .{ .op = "===", .lhs = &.{ .member = .{ .object = &keys_k, .name = "length" } }, .rhs = &zero } },
                .then = &.{ .quoted = "" },
                .else_ = &named_fields,
            } } },
        } } },
    }, .layout = .indented, .indent = 1 } },
} };

/// `function __bp_show(v, s, top, a) { … }` — see `Helper.show`. It answers the
/// `console.log` format of `v` and pushes the values its `%s` / `%O` verbs
/// consume onto `a`: a string through `%s` (quoted when nested), an array or a
/// tuple as its brackets around its elements' formats, anything else through
/// `%O` — `util.inspect`, the text `console.log` gives it — so the helper needs
/// no `require`.
const show: ast.Stmt = .{ .function = .{
    .name = "__bp_show",
    .params = &.{ .{ .pattern = .{ .name = "v" } }, .{ .pattern = .{ .name = "s" } }, .{ .pattern = .{ .name = "top" } }, .{ .pattern = .{ .name = "a" } } },
    .body = .{ .stmts = &.{
        .{ .if_ = .{
            .cond = .{ .binary = .{ .op = "===", .lhs = &.{ .unary = .{ .op = "typeof ", .operand = &v, .parens = false } }, .rhs = &.{ .quoted = "string" } } },
            .then = &pushAndReturn(.{ .ternary = .{ .cond = &.{ .name = "top" }, .then = &v, .else_ = &quoted_v } }, "%s", 1),
        } },
        float_branch,
        .{ .if_ = .{
            .cond = callOn(&.{ .name = "Array" }, "isArray", &.{v}),
            .then = &.{ .block = .{ .stmts = &.{
                .{ .decl = .{ .pattern = .{ .name = "t" }, .value = .{ .binary = .{
                    .op = "&&",
                    .lhs = &.{ .binary = .{ .op = "!=", .lhs = &sh, .rhs = &null_ } },
                    .rhs = &eq(&.{ .index = .{ .object = &sh, .index = &zero } }, "#"),
                } } } },
                .{ .return_ = bracketed_v },
            }, .layout = .indented, .indent = 1 } },
        } },
        named_branch,
        .{ .expr = callOn(&args_a, "push", &.{v}) },
        .{ .return_ = .{ .quoted = "%O" } },
    } },
} };

/// `const a = []; const f = Array.from(<values>, (v, i) => __bp_show(v, <shape>, true, a)).join(" "); console.log.apply(console, [f, ...a]);`
fn printBody(comptime values: ast.Expr, comptime shape: ast.Expr) ast.Block {
    return .{ .stmts = &.{
        .{ .decl = .{ .pattern = .{ .name = "a" }, .value = .{ .array = .{} } } },
        .{ .decl = .{ .pattern = .{ .name = "f" }, .value = callOn(&callOn(&.{ .name = "Array" }, "from", &.{
            values,
            .{ .arrow = .{
                .params = &.{ .{ .pattern = .{ .name = "v" } }, .{ .pattern = .{ .name = "i" } } },
                .body = .{ .expr = &.{ .call = .{ .callee = &.{ .name = "__bp_show" }, .args = &.{ v, shape, .{ .name = "true" }, args_a } } } },
            } },
        }), "join", &.{.{ .quoted = " " }}) } },
        .{ .expr = callOn(&.{ .member = .{ .object = &.{ .name = "console" }, .name = "log" } }, "apply", &.{
            .{ .name = "console" },
            .{ .array = .{ .elems = &.{.{ .name = "f" }}, .spread = .{ .name = "a" } } },
        }) },
    } };
}

/// `function __bp_print() { … __bp_show(v, null, true, a) … }`
const print: ast.Stmt = .{ .function = .{
    .name = "__bp_print",
    .body = printBody(.{ .name = "arguments" }, .null_),
} };

/// `function __bp_print_as(shapes) { … over Array.from(arguments).slice(1), __bp_show(v, shapes[i], true, a) … }`
const print_as: ast.Stmt = .{ .function = .{
    .name = "__bp_print_as",
    .params = &.{.{ .pattern = .{ .name = "shapes" } }},
    .body = printBody(
        callOn(&callOn(&.{ .name = "Array" }, "from", &.{.{ .name = "arguments" }}), "slice", &.{one}),
        .{ .index = .{ .object = &.{ .name = "shapes" }, .index = &.{ .name = "i" } } },
    ),
} };

test "js_prelude: an open-ended range counts up lazily" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.range_from), 0);
    try std.testing.expectEqualStrings(
        "function* __bp_range_from(n) { while (true) { yield n; n += 1; } }",
        aw.written(),
    );
}

test "js_prelude: a failed assert throws with its message and location" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.assert_fatal), 0);
    try std.testing.expectEqualStrings(
        "function __bp_assert_fatal(cond, msg, loc) { if (!cond) { throw new Error((msg ?? \"assertion failed\") + \" at \" + loc); } }",
        aw.written(),
    );
}

test "js_prelude: charAt answers null out of range" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.string_char_at), 0);
    try std.testing.expectEqualStrings(
        "function __bp_string_char_at(s, i) { return (i >= 0 && i < s.length) ? s.charAt(i) : null; }",
        aw.written(),
    );
    try std.testing.expectEqual(Helper.string_char_at, forMethod(.string, "charAt", 1).?);
    try std.testing.expect(forMethod(.array, "charAt", 1) == null);
}
