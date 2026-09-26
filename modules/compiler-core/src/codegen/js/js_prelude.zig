//! The commonJS runtime helpers, as built nodes.
//!
//! Most primitive methods lower to a native JS method or an inline host
//! template. A few native methods disagree with the botopink signature
//! (`"ab".at(5)` is `undefined` — and native `charAt` is `""` — where
//! `String.at` says `?string`), and those
//! need JavaScript of our own. It is never a shipped runtime file: only the
//! helper a module actually calls is written into that module, as a plain
//! function declaration built from `js_ast` nodes like any other.
//!
//! The shape is `codegen/wat/wat_prelude.zig`'s: a call site never spells a
//! helper's name — `Emitter.helper` in `commonJS.zig` hands out the symbol
//! **and** marks the helper for emission in one call, so a module cannot call a
//! helper it does not define.
//!
//! A helper answers a primitive *declaration* (`String.at`), which is the
//! identity every backend's lowering of that method shares.

const std = @import("std");
const ast = @import("js_ast.zig");

pub const Helper = enum {
    /// `assert cond, msg` outside test mode: always fatal, naming the message
    /// and the `file:line` (cross-backend semantics decision 4).
    assert_fatal,
    /// `String.at(i) -> ?string`: the character, or `null` out of range.
    /// Named `string_char_at` for the native JS method it wraps — the
    /// botopink declaration was renamed `charAt` -> `at` by decision 63's
    /// amendment, which gave every indexable type one reader name.
    string_char_at,
    /// `Array.at(i) -> ?T`: the element, or `null` out of range. Native
    /// `Array.prototype.at` answers `undefined` past the end (and counts a
    /// negative index from the back), where decision 47 gives absence one
    /// spelling — `null` — and `String.at` above already answers it.
    array_at,
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
    /// Structural `==` between two composite values (decision 8 §6 T6, and
    /// decision 35, which settles the same question for every other one): a JS
    /// `===` compares references, so a record, an array, a tuple and a variant
    /// all answered `false` where two equal ones were compared. Arrays and
    /// tuples compare element-wise; a class instance compares its constructor
    /// and then its own fields, which decision 5 made the one shape a record
    /// and a variant share.
    structural_eq,
    /// An expression-position `try x` (decisions 121, 122 — `total + try r`,
    /// `(try batch).length`): the Ok value, or — on an Error — a throw of
    /// `{ __bp_try: r }` that the enclosing function's guard
    /// (`commonJS.zig` `guardExprTry`) turns back into the propagated Result.
    try_unwrap,
    /// A host function declared `-> @Task<@Result<T, E>>` (decision 126): its
    /// Promise resolves with `{ ok: v }`, and a rejection resolves with
    /// `{ error: <message> }` instead of rejecting.
    host_task,
    /// A host answer adopted into the record class its declaration names
    /// (`docs.md` § Host bindings: "a plain object … is adopted into the record
    /// the declaration names"): `__bp_adopt(v, C, path)` gives a plain object
    /// `C`'s prototype — its methods and its `__bp` marker — keeping its fields,
    /// and leaves an instance of `C` (or `null`) as it is. `path` walks the
    /// containers the declaration looks through, one letter each: `a` an
    /// array, `r` an `@Result`'s ok side.
    adopt,
    /// `seq.next()` by hand (decision 122): a JS generator step `{ value, done }`
    /// as the prelude enum `YieldStep` — `Yield(value)`, or `Done` once the
    /// generator finished. The module declares `YieldStep` (the checker splices
    /// the declaration into every module that steps a sequence).
    yield_step,
};

/// Emission order of the helpers a module uses.
pub const order = [_]Helper{ .assert_fatal, .string_char_at, .array_at, .range_from, .structural_eq, .show, .print, .print_as, .try_unwrap, .host_task, .adopt, .yield_step };

/// The receiver family of a primitive method call, as inference recorded it.
pub const Receiver = enum { string, array, other };

/// The helper that replaces the native method `method` on a `receiver`
/// value, or null when the native method (or the annotation's template)
/// already matches the signature.
pub fn forMethod(receiver: Receiver, method: []const u8, argc: usize) ?Helper {
    // `at`, not `charAt`: the botopink declaration is `String.at` (decision
    // 63, amended). `Array.at` is wrapped too: native `Array.prototype.at`
    // answers `undefined` past the end, and decision 47's absent is `null`.
    if (argc == 1 and std.mem.eql(u8, method, "at")) return switch (receiver) {
        .string => .string_char_at,
        .array => .array_at,
        .other => null,
    };
    return null;
}

/// The function name a call site uses.
pub fn name(h: Helper) []const u8 {
    return switch (h) {
        .assert_fatal => "__bp_assert_fatal",
        .string_char_at => "__bp_string_char_at",
        .array_at => "__bp_array_at",
        .range_from => "__bp_range_from",
        .show => "__bp_show",
        .print => "__bp_print",
        .print_as => "__bp_print_as",
        .structural_eq => "__bp_eq",
        .try_unwrap => "__bp_try",
        .host_task => "__bp_host_task",
        .adopt => "__bp_adopt",
        .yield_step => "__bp_yield_step",
    };
}

/// The helper's declaration.
pub fn decl(h: Helper) ast.Stmt {
    return switch (h) {
        .assert_fatal => assert_fatal,
        .string_char_at => string_char_at,
        .array_at => array_at,
        .range_from => range_from,
        .show => show,
        .print => print,
        .print_as => print_as,
        .structural_eq => structural_eq,
        .try_unwrap => try_unwrap,
        .host_task => host_task,
        .adopt => adopt,
        .yield_step => yield_step,
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

const r_: ast.Expr = .{ .name = "r" };

/// `function __bp_try(r) { if ("error" in r) { throw { __bp_try: r }; } return r.ok; }`
const try_unwrap: ast.Stmt = .{ .function = .{
    .name = "__bp_try",
    .params = &.{.{ .pattern = .{ .name = "r" } }},
    .body = .{ .stmts = &.{
        .{ .if_ = .{
            .cond = .{ .binary = .{ .op = "in", .lhs = &.{ .quoted = "error" }, .rhs = &r_, .parens = false } },
            .then = &.{ .block = .{ .stmts = &.{.{ .throw_ = .{ .object = .{ .props = &.{.{ .kv = .{ .key = "__bp_try", .value = r_ } }} } } }}, .layout = .spaced } },
        } },
        .{ .return_ = .{ .member = .{ .object = &r_, .name = "ok" } } },
    }, .layout = .spaced },
} };

const p_: ast.Expr = .{ .name = "p" };
const hv: ast.Expr = .{ .name = "v" };
const he: ast.Expr = .{ .name = "e" };
const he_message: ast.Expr = .{ .member = .{ .object = &he, .name = "message" } };

/// `function __bp_host_task(p) { return Promise.resolve(p).then((v) => ({ ok: v }),
/// (e) => ({ error: (e && e.message) ? e.message : String(e) })); }`
const host_task: ast.Stmt = .{ .function = .{
    .name = "__bp_host_task",
    .params = &.{.{ .pattern = .{ .name = "p" } }},
    .body = .{ .stmts = &.{.{ .return_ = .{ .call = .{
        .callee = &.{ .member = .{
            .object = &.{ .call = .{ .callee = &.{ .member = .{ .object = &.{ .name = "Promise" }, .name = "resolve" } }, .args = &.{p_} } },
            .name = "then",
        } },
        .args = &.{
            .{ .arrow = .{ .params = &.{.{ .pattern = .{ .name = "v" } }}, .body = .{ .expr = &.{ .paren = &.{ .object = .{ .props = &.{.{ .kv = .{ .key = "ok", .value = hv } }} } } } } } },
            .{ .arrow = .{ .params = &.{.{ .pattern = .{ .name = "e" } }}, .body = .{ .expr = &.{ .paren = &.{ .object = .{ .props = &.{.{ .kv = .{ .key = "error", .value = .{ .ternary = .{
                .cond = &.{ .paren = &.{ .binary = .{ .op = "&&", .lhs = &he, .rhs = &he_message, .parens = false } } },
                .then = &he_message,
                .else_ = &.{ .call = .{ .callee = &.{ .name = "String" }, .args = &.{he} } },
            } } } }} } } } } } },
        },
    } } }}, .layout = .spaced },
} };

/// `function __bp_adopt(v, C, p) { return … }` — see `Helper.adopt`.
const adopt: ast.Stmt = .{ .function = .{
    .name = "__bp_adopt",
    .params = &.{ .{ .pattern = .{ .name = "v" } }, .{ .pattern = .{ .name = "C" } }, .{ .pattern = .{ .name = "p" } } },
    .body = .{ .stmts = &.{.{ .return_ = .{ .host = &.{.{ .text = "(v == null) ? v : (p === \"\") ? ((typeof v === \"object\" && !(v instanceof C)) ? Object.assign(Object.create(C.prototype), v) : v) : (p[0] === \"a\") ? (Array.isArray(v) ? v.map((e) => __bp_adopt(e, C, p.slice(1))) : v) : (p[0] === \"r\" && typeof v === \"object\" && \"ok\" in v) ? { ok: __bp_adopt(v.ok, C, p.slice(1)) } : v" }} } }}, .layout = .spaced },
} };

const yield_step_class: ast.Expr = .{ .name = "YieldStep" };

/// `function __bp_yield_step(r) { return r.done ? YieldStep.Done : YieldStep.Yield(r.value); }`
const yield_step: ast.Stmt = .{ .function = .{
    .name = "__bp_yield_step",
    .params = &.{.{ .pattern = .{ .name = "r" } }},
    .body = .{ .stmts = &.{.{ .return_ = .{ .ternary = .{
        .cond = &.{ .member = .{ .object = &r_, .name = "done" } },
        .then = &.{ .member = .{ .object = &yield_step_class, .name = "Done" } },
        .else_ = &.{ .call = .{
            .callee = &.{ .member = .{ .object = &yield_step_class, .name = "Yield" } },
            .args = &.{.{ .member = .{ .object = &r_, .name = "value" } }},
        } },
    } } }}, .layout = .spaced },
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

const xs: ast.Expr = .{ .name = "xs" };
const xs_length: ast.Expr = .{ .member = .{ .object = &xs, .name = "length" } };

/// `function __bp_array_at(xs, i) { return (i >= 0 && i < xs.length) ? xs[i] : null; }`
const array_at: ast.Stmt = .{ .function = .{
    .name = "__bp_array_at",
    .params = &.{ .{ .pattern = .{ .name = "xs" } }, .{ .pattern = .{ .name = "i" } } },
    .body = .{ .stmts = &.{.{ .return_ = .{ .ternary = .{
        .cond = &.{ .paren = &.{ .binary = .{
            .op = "&&",
            .lhs = &.{ .binary = .{ .op = ">=", .lhs = &i, .rhs = &zero, .parens = false } },
            .rhs = &.{ .binary = .{ .op = "<", .lhs = &i, .rhs = &xs_length, .parens = false } },
            .parens = false,
        } } },
        .then = &.{ .index = .{ .object = &xs, .index = &i } },
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

const eq_a: ast.Expr = .{ .name = "a" };
const eq_b: ast.Expr = .{ .name = "b" };
const is_array_a: ast.Expr = callOn(&.{ .name = "Array" }, "isArray", &.{eq_a});
/// `d + 1` — one level deeper in the structural walk.
const deeper: ast.Expr = .{ .binary = .{ .op = "+", .lhs = &.{ .name = "d" }, .rhs = &one } };

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
/// tuple as its brackets around its elements' formats, JavaScript's `undefined`
/// as `null` (decision 47 — absent has one spelling), anything else through
/// `%O` — `util.inspect`, the text `console.log` gives it — so the helper needs
/// no `require`.
const show: ast.Stmt = .{
    .function = .{
        .name = "__bp_show",
        .params = &.{ .{ .pattern = .{ .name = "v" } }, .{ .pattern = .{ .name = "s" } }, .{ .pattern = .{ .name = "top" } }, .{ .pattern = .{ .name = "a" } } },
        .body = .{
            .stmts = &.{
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
                // Decision 47: absent has ONE spelling, `null`. JavaScript has two
                // nones, and `?.` / an `if` with no `else` answer the other one —
                // printed through `%O` it read `undefined`.
                .{ .if_ = .{
                    .cond = .{ .binary = .{ .op = "===", .lhs = &v, .rhs = &.{ .name = "undefined" } } },
                    .then = &.{ .return_ = .{ .quoted = "null" } },
                } },
                .{ .expr = callOn(&args_a, "push", &.{v}) },
                .{ .return_ = .{ .quoted = "%O" } },
            },
        },
    },
};

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

/// ```js
/// function __bp_eq(a, b, d) {
///     if ((a === b)) {
///         return true;
///     }
///     if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
///         return false;
///     }
///     if (Array.isArray(a)) {
///         return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
///     }
///     const k = Object.keys(a);
///     return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
/// }
/// ```
///
/// Decision 8 §6 T6 for tuples, and decision 35 for every other composite
/// value: without mutation (decision 37) identity is unobservable — no program
/// can tell two structurally equal values apart except by `==` itself — so
/// structural is the only semantics that says anything.
///
/// `a.constructor !== b.constructor` is the type test: two arrays share
/// `Array`, and under decision 5 two values of the same variant share its
/// subclass while `Shape$Circle` and `Shape$Square` do not. Own fields only, so
/// the prototype's `__bp` and `tag` take no part — the constructor already
/// answered for them.
///
/// `d` is **not** needed against a botopink cycle: decision 37 makes a record
/// immutable, so no value can come to point at itself after it is built. It
/// stays because a value handed in by a `#[@External.Node(…)]` call carries no
/// such promise, and a cheap bound is better than a stack overflow in a host's
/// object graph.
const structural_eq: ast.Stmt = .{ .function = .{
    .name = "__bp_eq",
    .params = &.{ .{ .pattern = .{ .name = "a" } }, .{ .pattern = .{ .name = "b" } }, .{ .pattern = .{ .name = "d" } } },
    .body = .{ .stmts = &.{
        .{ .if_ = .{
            .cond = .{ .binary = .{ .op = "===", .lhs = &eq_a, .rhs = &eq_b } },
            .then = &.{ .block = .{ .stmts = &.{.{ .return_ = .{ .name = "true" } }}, .layout = .indented, .indent = 1 } },
        } },
        .{ .if_ = .{
            .cond = .{ .binary = .{
                .op = "||",
                .lhs = &.{ .binary = .{
                    .op = "||",
                    .lhs = &.{ .binary = .{
                        .op = "||",
                        .lhs = &.{ .binary = .{
                            .op = "||",
                            .lhs = &.{ .binary = .{ .op = ">", .lhs = &.{ .name = "d" }, .rhs = &.{ .number = "32" } } },
                            .rhs = &.{ .binary = .{ .op = "===", .lhs = &eq_a, .rhs = &null_ } },
                        } },
                        .rhs = &.{ .binary = .{ .op = "===", .lhs = &eq_b, .rhs = &null_ } },
                    } },
                    .rhs = &.{ .binary = .{
                        .op = "!==",
                        .lhs = &.{ .unary = .{ .op = "typeof ", .operand = &eq_a, .parens = false } },
                        .rhs = &.{ .quoted = "object" },
                    } },
                } },
                .rhs = &.{ .binary = .{
                    .op = "!==",
                    .lhs = &.{ .member = .{ .object = &eq_a, .name = "constructor" } },
                    .rhs = &.{ .member = .{ .object = &eq_b, .name = "constructor" } },
                } },
            } },
            .then = &.{ .block = .{ .stmts = &.{.{ .return_ = .{ .name = "false" } }}, .layout = .indented, .indent = 1 } },
        } },
        .{ .if_ = .{
            .cond = is_array_a,
            .then = &.{ .block = .{ .stmts = &.{.{ .return_ = .{ .binary = .{
                .op = "&&",
                .lhs = &.{ .binary = .{
                    .op = "===",
                    .lhs = &.{ .member = .{ .object = &eq_a, .name = "length" } },
                    .rhs = &.{ .member = .{ .object = &eq_b, .name = "length" } },
                } },
                .rhs = &callOn(&eq_a, "every", &.{.{ .arrow = .{
                    .params = &.{ .{ .pattern = .{ .name = "e" } }, .{ .pattern = .{ .name = "i" } } },
                    .body = .{ .expr = &.{ .call = .{ .callee = &.{ .name = "__bp_eq" }, .args = &.{
                        .{ .name = "e" },
                        .{ .index = .{ .object = &eq_b, .index = &.{ .name = "i" } } },
                        deeper,
                    } } } },
                } }}),
            } } }}, .layout = .indented, .indent = 1 } },
        } },
        .{ .decl = .{ .pattern = .{ .name = "k" }, .value = callOn(&.{ .name = "Object" }, "keys", &.{eq_a}) } },
        .{ .return_ = .{ .binary = .{
            .op = "&&",
            .lhs = &.{ .binary = .{
                .op = "===",
                .lhs = &.{ .member = .{ .object = &.{ .name = "k" }, .name = "length" } },
                .rhs = &.{ .member = .{ .object = &callOn(&.{ .name = "Object" }, "keys", &.{eq_b}), .name = "length" } },
            } },
            .rhs = &callOn(&.{ .name = "k" }, "every", &.{.{ .arrow = .{
                .params = &.{.{ .pattern = .{ .name = "n" } }},
                .body = .{ .expr = &.{ .call = .{ .callee = &.{ .name = "__bp_eq" }, .args = &.{
                    .{ .index = .{ .object = &eq_a, .index = &.{ .name = "n" } } },
                    .{ .index = .{ .object = &eq_b, .index = &.{ .name = "n" } } },
                    deeper,
                } } } },
            } }}),
        } } },
    } },
} };

test "js_prelude: structural equality walks arrays and class instances" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.structural_eq), 0);
    try std.testing.expectEqualStrings(
        \\function __bp_eq(a, b, d) {
        \\    if ((a === b)) {
        \\        return true;
        \\    }
        \\    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        \\        return false;
        \\    }
        \\    if (Array.isArray(a)) {
        \\        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
        \\    }
        \\    const k = Object.keys(a);
        \\    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
        \\}
    , aw.written());
}

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

test "js_prelude: string at answers null out of range" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.string_char_at), 0);
    try std.testing.expectEqualStrings(
        "function __bp_string_char_at(s, i) { return (i >= 0 && i < s.length) ? s.charAt(i) : null; }",
        aw.written(),
    );
    try std.testing.expectEqual(Helper.string_char_at, forMethod(.string, "at", 1).?);
    try std.testing.expectEqual(Helper.array_at, forMethod(.array, "at", 1).?);
    try std.testing.expect(forMethod(.other, "at", 1) == null);
    // The old spelling answers nothing: `charAt` is the HOST symbol the
    // template names, not a botopink declaration any more.
    try std.testing.expect(forMethod(.string, "charAt", 1) == null);
}

test "js_prelude: array at answers null out of range (decision 47)" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.array_at), 0);
    try std.testing.expectEqualStrings(
        "function __bp_array_at(xs, i) { return (i >= 0 && i < xs.length) ? xs[i] : null; }",
        aw.written(),
    );
}
