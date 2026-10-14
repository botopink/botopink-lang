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
const stdWasm = @import("std_wasm");

pub const Helper = enum {
    /// `assert cond, msg` outside test mode: always fatal (cross-backend
    /// semantics decision 4), a panic naming the condition, the message and
    /// the `file:line:col` (decision 527 (2)).
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
    /// A `result: true` binding's failure (decisions 431, 489): what the host
    /// threw as `{ error: HostError(message, "host", name, detail) }` —
    /// `__bp_host_fail(F, e)`, `F` std's `failure` module. An `Error` is
    /// `name: Error` with its `message` and `stack`; any other thrown value is
    /// `name: Throw` with `String(e)` and no detail.
    host_fail,
    /// A sync `result: true` binding (decisions 431, 490):
    /// `__bp_host_result(F, () => <call>)` answers `{ ok: v }`, or the throw
    /// through `host_fail`.
    host_result,
    /// A `result: true` binding declared `-> @Task<@Result<T, HostError>>`
    /// (decisions 431, 490, 432): `__bp_host_result_task(F, () => <call>)` —
    /// a failing task (`task`) that resolves with the host's `v`, and rejects
    /// with `host_fail`'s `HostError` for a rejection or a throw before the
    /// Promise exists.
    host_result_task,
    /// Decision 432 — a failing task: `__bp_task(p)` takes the Promise of a
    /// `@Task<@Result<T, E>>` body, which settles with the `{ ok }` /
    /// `{ error }` value the body built, and answers the task botopink's
    /// callers see — resolved with the bare `T`, rejected with the `E`
    /// (a JavaScript caller's `try { await f() } catch (e)`). The task is
    /// marked `__bp_fails`, which `await_task` reads, and `__bp_failure` once
    /// it rejected with an `E` — a body that crashed (a panic, an unannounced
    /// host raise) rejects without it, and stays a crash for botopink. It
    /// carries a handler of its own, so a failing task nobody has awaited yet
    /// is not an unhandled rejection (Node ends the process on one): a
    /// failure is a value until someone reads it.
    task,
    /// Decision 432 — `await` of a task that may fail (`InstanceLowering.task_await`):
    /// `__bp_await(t)` answers, for a task `task` marked, the Promise of the
    /// `@Result` it settles with — `{ ok: v }`, or `{ error: e }` for its
    /// failure (a crash rejects on) — and any other task as it is: a task a
    /// generic body made (`-> @Task<T>` with `T` a `@Result`) settles with
    /// the `@Result` value itself, and a rejection of an unmarked task is a
    /// crash. Host code that awaits botopink tasks generically (std's
    /// `async.runAll`, `raceOf`, `race`) spells the same reading inline.
    await_task,
    /// A host answer adopted into the record class its declaration names
    /// (`conformance/docs.md` § Host bindings: "a plain object … is adopted into the record
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
    /// Decision 264 — an integer `+` `-` `*` `/` `%`, unary `-` or `+=`
    /// answered inside its type's range, or an abort: `__bp_int(v, lo, hi,
    /// what)` answers `v + 0` (an integer is never `-0`, decision 214) when
    /// `lo <= v <= hi`, and otherwise throws `integer overflow: <what>` —
    /// `<op> on <type> at <file:line:col>`. A non-finite `v`
    /// is an integer `/` or `%` by zero (`Math.trunc(7 / 0)`, `7 % 0`), which
    /// throws `integer division by zero: <what>` — wasm traps on both. Only
    /// the types a JS number holds whole use it (`i8` … `u32`); the 64-bit
    /// four go through the `wide_*` helpers.
    int_check,
    /// Decision 319 — `i64`, `isize`, `u64` and `usize` hold their full range
    /// in a hybrid form: a value within ±(2^53 − 1) is a JS `number`, one
    /// beyond it a `BigInt`, never the other way round (`5` is never `5n`),
    /// so `===`, `<` and a `Map` key need no conversion. `__bp_wnorm(v, u,
    /// what)` takes a `BigInt` result, aborts with `integer overflow: <what>`
    /// past −2^63 … 2^63 − 1 (`u` false) or 0 … 2^64 − 1 (`u` true), and
    /// answers the canonical form.
    wide_norm,
    /// `__bp_wadd(a, b, u, what)` — `a + b` on a 64-bit type: two numbers whose
    /// sum is a safe integer (and not negative when `u`) answer it directly,
    /// the fast path; anything else is computed in `BigInt` and normalised.
    wide_add,
    /// `__bp_wsub(a, b, u, what)` — `a - b`, as `wide_add`.
    wide_sub,
    /// `__bp_wmul(a, b, u, what)` — `a * b`, as `wide_add` (`+ 0`: an integer
    /// is never `-0`).
    wide_mul,
    /// `__bp_wdiv(a, b, u, what)` — `a / b` truncated toward zero; a zero
    /// divisor throws `integer division by zero: <what>`. Two numbers divide
    /// as numbers (the quotient of two safe integers is exact after
    /// `Math.trunc`); a `BigInt` operand divides as `BigInt`, which truncates.
    wide_div,
    /// `__bp_wmod(a, b, u, what)` — `a % b`, as `wide_div`.
    wide_mod,
    /// `__bp_wneg(a, u, what)` — unary `-`: `-(-2^63)` and `-x` of a nonzero
    /// unsigned value abort.
    wide_neg,
    /// Decision 332 — `__bp_bdiv(a, b, what)`: `a / b` over two `bigint`s
    /// (`BigInt`s), which truncates toward zero; a zero divisor throws
    /// `integer division by zero: <what>` (264's text) where `BigInt` would
    /// throw its own `RangeError`.
    big_div,
    /// `__bp_bmod(a, b, what)` — `a % b`, as `big_div` (the dividend's sign).
    big_mod,
    /// Decision 320 — `__bp_has_surrogate(s)` (over `/[\uD800-\uDFFF]/`), the
    /// one test the string helpers make: a string holding no UTF-16 surrogate
    /// counts codepoints exactly as JavaScript counts units, so it keeps the
    /// native index; one holding a surrogate is walked by codepoint.
    str_surrogate,
    /// `__bp_str_count(s, u)` — the codepoints among `s`'s first `u` UTF-16
    /// units (a lone surrogate counts as one, as `for…of` reads it).
    str_count,
    /// `String.length` (the property and the call): codepoints.
    str_length,
    /// `String.indexOf(sub)`: the codepoint index of the first match, `-1`.
    str_index_of,
    /// `String.lastIndexOf(sub)`: the codepoint index of the last match, `-1`.
    str_last_index_of,
    /// The text of an `f64` (decision 8 § 7, the numbers' text; decision 521):
    /// std-wasm's `number.shortFloat` — OTP's `float_to_binary(F, [short])`,
    /// the shortest digits that read back, fixed or `D.DDDeE` whichever is
    /// shorter (`5.0`, `-0.5`, `1.0e3`, `1.0e21`, `1.0e-7`) — what erlang,
    /// beam and wasm answer. JavaScript has one number type, so a call site
    /// that types a value `f64` (`@print`'s shape `"f"`, a template hole,
    /// `toString`, a `+` with a string) asks for it.
    f64_text,
    /// `String.trim` / `trimStart` / `trimEnd` (decision 521): std-wasm's
    /// whitespace set — space, tab, LF, CR, VT, FF (`text.isWhite`) — where
    /// the engine's also strips a no-break space and the other Unicode
    /// spaces.
    str_trim,
    str_trim_start,
    str_trim_end,
    /// `String.toUpper` / `toLower` (decisions 443, 521): std-wasm's case
    /// mapping, its table (`text.mapCodepoint`) written into the helper —
    /// the simple mappings and the unconditional full ones, no final sigma
    /// (`"ΟΔΟΣ".toLower()` is `"οδοσ"`, where the engine answers `"οδος"`).
    str_upper,
    str_lower,
    /// `__bp_case_map(t)`: a case table's text as a `Map` from a code point
    /// to its mapping; `__bp_case(s, m)`: `s` mapped through it.
    case_map,
    case_apply,
    /// `__bp_text(v, s)`: the text `@print` writes for `v` at the top level, as a
    /// string — `show`'s format with its `%s` / `%O` verbs filled in, `s` the
    /// static print shape (a tuple, a float) or nothing. An enum's class answers
    /// it as its `toString`, and a template hole or a `string +` of any other
    /// composite value is written through it (decision 530), so each writes
    /// `Shape.Circle(radius: 2)` / `Point(x: 1, y: 2)` / `[1, 2, 3]`, not
    /// `[object Object]` / `1,2,3`.
    text,
};

/// Emission order of the helpers a module uses.
pub const order = [_]Helper{ .assert_fatal, .str_surrogate, .str_count, .string_char_at, .str_length, .str_index_of, .str_last_index_of, .array_at, .range_from, .structural_eq, .f64_text, .str_trim, .str_trim_start, .str_trim_end, .case_map, .case_apply, .str_upper, .str_lower, .show, .text, .print, .print_as, .try_unwrap, .host_fail, .task, .await_task, .host_result, .host_result_task, .adopt, .yield_step, .int_check, .wide_norm, .wide_add, .wide_sub, .wide_mul, .wide_div, .wide_mod, .wide_neg, .big_div, .big_mod };

/// The helpers `h`'s body calls, which a module calling `h` carries too.
pub fn requires(h: Helper) []const Helper {
    return switch (h) {
        .wide_add, .wide_sub, .wide_mul, .wide_div, .wide_mod, .wide_neg => &.{.wide_norm},
        .show => &.{.f64_text},
        .text => &.{ .show, .f64_text },
        .host_result => &.{.host_fail},
        .host_result_task => &.{ .host_fail, .task },
        .string_char_at, .str_length => &.{.str_surrogate},
        .str_upper, .str_lower => &.{ .case_map, .case_apply },
        .str_index_of, .str_last_index_of => &.{ .str_surrogate, .str_count },
        else => &.{},
    };
}

/// The receiver family of a primitive method call, as inference recorded it.
pub const Receiver = enum { string, array, float, other };

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
        .float, .other => null,
    };
    // The numbers' text: a float's `toString` keeps its decimal part.
    if (receiver == .float and argc == 0 and std.mem.eql(u8, method, "toString")) return .f64_text;
    // Decision 320 — a string index counts codepoints: the native `length`,
    // `indexOf` and `lastIndexOf` count UTF-16 units.
    if (receiver == .string) {
        if (argc == 0 and std.mem.eql(u8, method, "length")) return .str_length;
        if (argc == 1 and std.mem.eql(u8, method, "indexOf")) return .str_index_of;
        if (argc == 1 and std.mem.eql(u8, method, "lastIndexOf")) return .str_last_index_of;
        // Decision 521 — std-wasm's text, never the engine's.
        if (argc == 0 and std.mem.eql(u8, method, "trim")) return .str_trim;
        if (argc == 0 and std.mem.eql(u8, method, "trimStart")) return .str_trim_start;
        if (argc == 0 and std.mem.eql(u8, method, "trimEnd")) return .str_trim_end;
        if (argc == 0 and std.mem.eql(u8, method, "toUpper")) return .str_upper;
        if (argc == 0 and std.mem.eql(u8, method, "toLower")) return .str_lower;
    }
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
        .host_fail => "__bp_host_fail",
        .host_result => "__bp_host_result",
        .host_result_task => "__bp_host_result_task",
        .task => "__bp_task",
        .await_task => "__bp_await",
        .adopt => "__bp_adopt",
        .yield_step => "__bp_yield_step",
        .int_check => "__bp_int",
        .wide_norm => "__bp_wnorm",
        .wide_add => "__bp_wadd",
        .wide_sub => "__bp_wsub",
        .wide_mul => "__bp_wmul",
        .wide_div => "__bp_wdiv",
        .wide_mod => "__bp_wmod",
        .wide_neg => "__bp_wneg",
        .big_div => "__bp_bdiv",
        .big_mod => "__bp_bmod",
        .str_surrogate => "__bp_has_surrogate",
        .str_count => "__bp_str_count",
        .str_length => "__bp_str_length",
        .str_index_of => "__bp_str_index_of",
        .str_last_index_of => "__bp_str_last_index_of",
        .f64_text => "__bp_f64",
        .str_trim => "__bp_trim",
        .str_trim_start => "__bp_trim_start",
        .str_trim_end => "__bp_trim_end",
        .str_upper => "__bp_upper",
        .str_lower => "__bp_lower",
        .case_map => "__bp_case_map",
        .case_apply => "__bp_case",
        .text => "__bp_text",
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
        .host_fail => host_fail,
        .host_result => host_result,
        .host_result_task => host_result_task,
        .task => task,
        .await_task => await_task,
        .adopt => adopt,
        .yield_step => yield_step,
        .int_check => int_check,
        .wide_norm => wide_norm,
        .wide_add => wideArith("__bp_wadd", "+"),
        .wide_sub => wideArith("__bp_wsub", "-"),
        .wide_mul => wideArith("__bp_wmul", "*"),
        .wide_div => wideDivision("__bp_wdiv", "/", "Math.trunc(a / b) + 0"),
        .wide_mod => wideDivision("__bp_wmod", "%", "(a % b) + 0"),
        .wide_neg => wide_neg,
        .big_div => bigDivision("__bp_bdiv", "/"),
        .big_mod => bigDivision("__bp_bmod", "%"),
        .str_surrogate => str_surrogate,
        .str_count => str_count,
        .str_length => str_length,
        .str_index_of => strIndex("__bp_str_index_of", "indexOf"),
        .str_last_index_of => strIndex("__bp_str_last_index_of", "lastIndexOf"),
        .f64_text => f64_text,
        .str_trim => str_trim_fn,
        .str_trim_start => str_trim_start_fn,
        .str_trim_end => str_trim_end_fn,
        // The table is built by `declIn`; this form is only its shape.
        .str_upper => upper_static,
        .str_lower => lower_static,
        .case_map => case_map,
        .case_apply => case_apply,
        .text => show_text,
    };
}

/// The helper's declaration, with what is built at run time — a case
/// helper's table — allocated in `arena`.
pub fn declIn(arena: std.mem.Allocator, h: Helper) !ast.Stmt {
    return switch (h) {
        .str_upper => caseFn(arena, "__bp_upper", try caseTable(arena, .upper)),
        .str_lower => caseFn(arena, "__bp_lower", try caseTable(arena, .lower)),
        else => decl(h),
    };
}

/// `function <name>(s) { return __bp_case(s, <name>.m ??= __bp_case_map("<table>")); }`
/// — the table decoded once, on the first call. `decl`'s form has an empty
/// table; `declIn` writes the real one.
fn caseFnStatic(comptime fn_name: []const u8) ast.Stmt {
    return hFn(fn_name, &.{"s"}, &.{hRet("__bp_case(s, " ++ fn_name ++ ".m ??= __bp_case_map(\"\"))")});
}

fn caseFn(arena: std.mem.Allocator, comptime fn_name: []const u8, table: []const u8) !ast.Stmt {
    const parts = try arena.alloc(ast.HostPart, 1);
    parts[0] = .{ .text = try std.fmt.allocPrint(arena, "__bp_case(s, {s}.m ??= __bp_case_map(\"{s}\"))", .{ fn_name, table }) };
    const body = try arena.alloc(ast.Stmt, 1);
    body[0] = .{ .return_ = .{ .host = parts } };
    return .{ .function = .{
        .name = fn_name,
        .params = &.{.{ .pattern = .{ .name = "s" } }},
        .body = .{ .stmts = body },
    } };
}

/// The text of std-wasm's case table for `case` (`text.mapCodepoint`), as
/// `__bp_case_map` reads it: space-separated entries, numbers in base 36 —
/// `a,n,k,d` maps the `n` code points `a`, `a + k`, … each to itself plus
/// `d` (a simple mapping), `!a,x,y…` maps `a` to the code points `x`, `y`, …
/// (a full one). No code point at or past `case_limit` maps (pinned by a
/// test in `codegen/tests/js_prelude.zig`).
pub fn caseTable(arena: std.mem.Allocator, case: stdWasm.text.Case) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    const covered = try arena.alloc(bool, case_limit);
    @memset(covered, false);
    var cp: u21 = 0;
    while (cp < case_limit) : (cp += 1) {
        if (covered[cp]) continue;
        const d = simpleDelta(cp, case) orelse continue;
        const step: u21 = if (cp + 1 < case_limit and simpleDelta(cp + 1, case) == d) 1 else 2;
        var count: u21 = 1;
        covered[cp] = true;
        while (cp + count * step < case_limit) : (count += 1) {
            const at = cp + count * step;
            if (covered[at] or simpleDelta(at, case) != d) break;
            covered[at] = true;
        }
        if (out.items.len > 0) try out.append(arena, ' ');
        try writeBase36(&out, arena, cp);
        try out.append(arena, ',');
        try writeBase36(&out, arena, count);
        try out.append(arena, ',');
        try writeBase36(&out, arena, step);
        try out.append(arena, ',');
        try writeBase36(&out, arena, d);
    }
    cp = 0;
    while (cp < case_limit) : (cp += 1) {
        var m: [3]u21 = undefined;
        const mapped = stdWasm.text.mapCodepoint(&m, cp, case);
        if (mapped.len < 2) continue;
        if (out.items.len > 0) try out.append(arena, ' ');
        try out.append(arena, '!');
        try writeBase36(&out, arena, cp);
        for (mapped) |x| {
            try out.append(arena, ',');
            try writeBase36(&out, arena, x);
        }
    }
    return out.items;
}

/// The code points `caseTable` reads: every case mapping of Unicode is below.
pub const case_limit: u21 = 0x20000;

/// `cp`'s simple mapping under `case` as a distance, null when `cp` maps to
/// itself or has a full mapping.
fn simpleDelta(cp: u21, case: stdWasm.text.Case) ?i32 {
    var m: [3]u21 = undefined;
    const mapped = stdWasm.text.mapCodepoint(&m, cp, case);
    if (mapped.len != 1 or mapped[0] == cp) return null;
    return @as(i32, mapped[0]) - @as(i32, cp);
}

fn writeBase36(out: *std.ArrayListUnmanaged(u8), arena: std.mem.Allocator, value: i64) !void {
    if (value < 0) try out.append(arena, '-');
    var x: u64 = @abs(value);
    var tmp: [16]u8 = undefined;
    var k: usize = 0;
    while (true) {
        const digit: u8 = @intCast(x % 36);
        tmp[k] = if (digit < 10) '0' + digit else 'a' + digit - 10;
        k += 1;
        x /= 36;
        if (x == 0) break;
    }
    while (k > 0) {
        k -= 1;
        try out.append(arena, tmp[k]);
    }
}

/// `function __bp_trim(s) { … }` and its two one-ended forms — see
/// `Helper.str_trim`: std-wasm's `text.isWhite` set.
const str_trim_fn: ast.Stmt = hFn("__bp_trim", &.{"s"}, &.{hRet("s.replace(/^[ \\t\\n\\r\\v\\f]+|[ \\t\\n\\r\\v\\f]+$/g, \"\")")});
const str_trim_start_fn: ast.Stmt = hFn("__bp_trim_start", &.{"s"}, &.{hRet("s.replace(/^[ \\t\\n\\r\\v\\f]+/, \"\")")});
const str_trim_end_fn: ast.Stmt = hFn("__bp_trim_end", &.{"s"}, &.{hRet("s.replace(/[ \\t\\n\\r\\v\\f]+$/, \"\")")});
const upper_static: ast.Stmt = caseFnStatic("__bp_upper");
const lower_static: ast.Stmt = caseFnStatic("__bp_lower");

/// `function __bp_case_map(t) { … }` — see `Helper.case_map`.
const case_map: ast.Stmt = hFn("__bp_case_map", &.{"t"}, &.{
    hConst(.const_, "m", "new Map()"),
    .{ .for_of = .{
        .pattern = .{ .name = "e" },
        .iter = hx("t.split(\" \")"),
        .body = .{ .stmts = &.{
            hConst(.const_, "p", "e.replace(\"!\", \"\").split(\",\").map((x) => parseInt(x, 36))"),
            hIf("e[0] === \"!\"", &.{ .{ .expr = hx("m.set(p[0], String.fromCodePoint(...p.slice(1)))") }, .continue_ }),
            .{ .expr = hx("for (let i = 0; i < p[1]; i += 1) m.set(p[0] + i * p[2], String.fromCodePoint(p[0] + i * p[2] + p[3]))") },
        }, .layout = .indented, .indent = 1 },
    } },
    hRet("m"),
});

/// `function __bp_case(s, m) { … }` — see `Helper.case_apply`: each code
/// point of `s` through `m`, one with no entry kept as it is.
const case_apply: ast.Stmt = hFn("__bp_case", &.{ "s", "m" }, &.{
    hConst(.let_, "o", "\"\""),
    .{ .for_of = .{
        .pattern = .{ .name = "c" },
        .iter = hx("s"),
        .body = .{ .stmts = &.{
            hConst(.const_, "r", "m.get(c.codePointAt(0))"),
            .{ .expr = hx("o += (r === undefined) ? c : r") },
        }, .layout = .indented, .indent = 1 },
    } },
    hRet("o"),
});

// ── host-text builders ───────────────────────────────────────────────────────
// The 64-bit and codepoint helpers are a few statements each over JavaScript
// operators the model has no node for (`BigInt(a)`, `0n`, a regular
// expression); their expressions are fixed runtime text, never user code.

fn hx(comptime text: []const u8) ast.Expr {
    return .{ .host = &.{.{ .text = text }} };
}

fn hRet(comptime text: []const u8) ast.Stmt {
    return .{ .return_ = hx(text) };
}

fn hConst(comptime kw: ast.Decl.Kw, comptime binding: []const u8, comptime text: []const u8) ast.Stmt {
    return .{ .decl = .{ .kw = kw, .pattern = .{ .name = binding }, .value = hx(text) } };
}

fn hIf(comptime cond_text: []const u8, comptime then: []const ast.Stmt) ast.Stmt {
    return .{ .if_ = .{ .cond = hx(cond_text), .then = &.{ .block = .{ .stmts = then, .layout = .spaced } } } };
}

fn hFn(comptime fn_name: []const u8, comptime param_names: []const []const u8, comptime body: []const ast.Stmt) ast.Stmt {
    const ps = comptime blk: {
        var out: [param_names.len]ast.Param = undefined;
        for (param_names, 0..) |pn, k| out[k] = .{ .pattern = .{ .name = pn } };
        const final = out;
        break :blk final;
    };
    return .{ .function = .{ .name = fn_name, .params = &ps, .body = .{ .stmts = body } } };
}

/// `function __bp_f64(v) { … }` — see `Helper.f64_text`, a port of std-wasm's
/// `number.shortFloat`: the shortest digits (`toExponential()` with no
/// argument), written fixed or as `D.DDDeE`, whichever is shorter (fixed on a
/// tie) and `D.DDDeE` from 2^53 on, always a digit after the point; `-0.0`,
/// and `NaN`, `Infinity`, `-Infinity` as those words.
const f64_text: ast.Stmt = hFn("__bp_f64", &.{"v"}, &.{
    hIf("Number.isNaN(v)", &.{hRet("\"NaN\"")}),
    hIf("!Number.isFinite(v)", &.{hRet("(v < 0) ? \"-Infinity\" : \"Infinity\"")}),
    hIf("v === 0", &.{hRet("Object.is(v, -0) ? \"-0.0\" : \"0.0\"")}),
    hConst(.const_, "t", "Math.abs(v).toExponential()"),
    hConst(.const_, "i", "t.indexOf(\"e\")"),
    hConst(.const_, "d", "t.slice(0, i).replace(\".\", \"\")"),
    hConst(.const_, "e", "Number(t.slice(i + 1))"),
    hConst(.const_, "g", "(v < 0) ? \"-\" : \"\""),
    hConst(.const_, "x", "g + d[0] + \".\" + ((d.length > 1) ? d.slice(1) : \"0\") + \"e\" + e"),
    hConst(.const_, "p", "e + 1"),
    hConst(.const_, "f", "g + ((p <= 0) ? \"0.\" + \"0\".repeat(-p) + d : (p >= d.length) ? d + \"0\".repeat(p - d.length) + \".0\" : d.slice(0, p) + \".\" + d.slice(p))"),
    hRet("((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x"),
});

/// `function __bp_text(v) { … }` — see `Helper.text`: `__bp_show`'s top-level
/// format of `v`, each verb replaced by the value it consumes, in order. The
/// replacement is computed over the format alone, so a `%s` inside a pushed
/// string is never read as a verb.
const show_text: ast.Stmt = hFn("__bp_text", &.{ "v", "s" }, &.{
    hConst(.const_, "a", "[]"),
    hConst(.let_, "i", "0"),
    hRet("__bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]))"),
});

/// `function __bp_wnorm(v, u, what) { … }` — see `Helper.wide_norm`.
const wide_norm: ast.Stmt = hFn("__bp_wnorm", &.{ "v", "u", "what" }, &.{
    hIf("u ? (v < 0n || v > 18446744073709551615n) : (v < -9223372036854775808n || v > 9223372036854775807n)", &.{
        .{ .throw_ = hx("Object.defineProperty(new Error(\"integer overflow: \" + what), \"__bp_panic\", { value: true })") },
    }),
    hRet("(v >= -9007199254740991n && v <= 9007199254740991n) ? Number(v) : v"),
});

/// `function <name>(a, b, u, what) { … }` — `+`, `-` and `*` on a 64-bit type
/// (`Helper.wide_add`): the number fast path, else `BigInt` and normalise.
fn wideArith(comptime fn_name: []const u8, comptime op: []const u8) ast.Stmt {
    return hFn(fn_name, &.{ "a", "b", "u", "what" }, &.{
        hIf("typeof a === \"number\" && typeof b === \"number\"", &.{
            hConst(.const_, "r", "a " ++ op ++ " b + 0"),
            hIf("Number.isSafeInteger(r) && (r >= 0 || !u)", &.{hRet("r")}),
        }),
        hRet("__bp_wnorm(BigInt(a) " ++ op ++ " BigInt(b), u, what)"),
    });
}

/// `function <name>(a, b, u, what) { … }` — `/` and `%` on a 64-bit type
/// (`Helper.wide_div`). `b == 0` is loose so `0n` is zero too.
fn wideDivision(comptime fn_name: []const u8, comptime op: []const u8, comptime fast: []const u8) ast.Stmt {
    return hFn(fn_name, &.{ "a", "b", "u", "what" }, &.{
        hIf("b == 0", &.{.{ .throw_ = hx("Object.defineProperty(new Error(\"integer division by zero: \" + what), \"__bp_panic\", { value: true })") }}),
        hIf("typeof a === \"number\" && typeof b === \"number\"", &.{hRet(fast)}),
        hRet("__bp_wnorm(BigInt(a) " ++ op ++ " BigInt(b), u, what)"),
    });
}

/// `function <name>(a, b, what) { … }` — `/` and `%` over two `bigint`s
/// (`Helper.big_div`).
fn bigDivision(comptime fn_name: []const u8, comptime op: []const u8) ast.Stmt {
    return hFn(fn_name, &.{ "a", "b", "what" }, &.{
        hIf("b === 0n", &.{.{ .throw_ = hx("Object.defineProperty(new Error(\"integer division by zero: \" + what), \"__bp_panic\", { value: true })") }}),
        hRet("a " ++ op ++ " b"),
    });
}

/// `function __bp_wneg(a, u, what) { … }` — see `Helper.wide_neg`.
const wide_neg: ast.Stmt = hFn("__bp_wneg", &.{ "a", "u", "what" }, &.{
    hIf("typeof a === \"number\" && (a === 0 || !u)", &.{hRet("0 - a")}),
    hRet("__bp_wnorm(-BigInt(a), u, what)"),
});

/// `__bp_has_surrogate(s)` — see `Helper.str_surrogate`. The regular
/// expression costs a call into the regexp engine (≈15 ns) whatever the
/// string, so a cache answers a string seen again: two ways per length
/// (`s.length & 63`), each a pointer test when the string is the same object
/// (≈2 ns). Two ways keep two strings of one length — `"alpha"` and
/// `"delta"` read in turn — from evicting each other on every read; a miss
/// moves the first way to the second. The cache holds at most 128 strings
/// alive. A read whose binding carries a slot (`str_slots.zig`) asks this
/// once per binding.
const str_surrogate: ast.Stmt = .{ .group = &.{
    hConst(.const_, "__bp_surrogate", "/[\\uD800-\\uDFFF]/"),
    hConst(.const_, "__bp_surrogate_k", "new Array(64).fill(\"\")"),
    hConst(.const_, "__bp_surrogate_v", "new Array(64).fill(false)"),
    hConst(.const_, "__bp_surrogate_k2", "new Array(64).fill(\"\")"),
    hConst(.const_, "__bp_surrogate_v2", "new Array(64).fill(false)"),
    hFn("__bp_has_surrogate", &.{"s"}, &.{
        hConst(.const_, "h", "s.length & 63"),
        hIf("__bp_surrogate_k[h] === s", &.{hRet("__bp_surrogate_v[h]")}),
        hIf("__bp_surrogate_k2[h] === s", &.{hRet("__bp_surrogate_v2[h]")}),
        hConst(.const_, "p", "__bp_surrogate.test(s)"),
        .{ .expr = hx("__bp_surrogate_k2[h] = __bp_surrogate_k[h]") },
        .{ .expr = hx("__bp_surrogate_v2[h] = __bp_surrogate_v[h]") },
        .{ .expr = hx("__bp_surrogate_k[h] = s") },
        .{ .expr = hx("__bp_surrogate_v[h] = p") },
        hRet("p"),
    }),
} };

/// `function __bp_str_count(s, u) { let n = 0; for (const c of s.substring(0, u)) { n += 1; } return n; }`
const str_count: ast.Stmt = hFn("__bp_str_count", &.{ "s", "u" }, &.{
    hConst(.let_, "n", "0"),
    .{ .for_of = .{
        .pattern = .{ .name = "c" },
        .iter = hx("s.substring(0, u)"),
        .body = .{ .stmts = &.{.{ .expr = hx("n += 1") }}, .layout = .spaced },
    } },
    hRet("n"),
});

/// `function __bp_str_length(s) { … }` — see `Helper.str_length`.
const str_length: ast.Stmt = hFn("__bp_str_length", &.{"s"}, &.{
    hIf("!__bp_has_surrogate(s)", &.{hRet("s.length")}),
    hConst(.let_, "n", "0"),
    .{ .for_of = .{
        .pattern = .{ .name = "c" },
        .iter = hx("s"),
        .body = .{ .stmts = &.{.{ .expr = hx("n += 1") }}, .layout = .spaced },
    } },
    hRet("n"),
});

/// `function <name>(s, sub) { const u = s.<native>(sub); return … }` — the
/// native unit index, recounted in codepoints when `s` holds a surrogate.
fn strIndex(comptime fn_name: []const u8, comptime native: []const u8) ast.Stmt {
    return hFn(fn_name, &.{ "s", "sub" }, &.{
        hConst(.const_, "u", "s." ++ native ++ "(sub)"),
        hRet("(u <= 0 || !__bp_has_surrogate(s)) ? u : __bp_str_count(s, u)"),
    });
}

// ── the helpers ──────────────────────────────────────────────────────────────

/// `function __bp_assert_fatal(cond, msg, head, where) { if (!cond) { const m = head + (msg == null ? "" : ": " + msg) + " at " + where; throw Object.defineProperty(new Error(m), "__bp_panic", { value: m }); } }`
/// — decision 527 (2): the panic names the asserted condition (`head`,
/// `assertion failed: x > 0`), the program's message when it wrote one, and
/// where (`src/main.bp:12:5`); the mark carries that text, which std's
/// `failure.attempt` reads as the `Failure`'s message (kind `panic`).
const assert_fatal: ast.Stmt = hFn("__bp_assert_fatal", &.{ "cond", "msg", "head", "where" }, &.{
    hIf("!cond", &.{
        hConst(.const_, "m", "head + (msg == null ? \"\" : \": \" + msg) + \" at \" + where"),
        .{ .throw_ = hx("Object.defineProperty(new Error(m), \"__bp_panic\", { value: m })") },
    }),
});

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

/// `function __bp_host_fail(F, e) { … }` — see `Helper.host_fail`.
const host_fail: ast.Stmt = hFn("__bp_host_fail", &.{ "F", "e" }, &.{
    hConst(.const_, "n", "e instanceof Error"),
    hRet("{ error: new F.HostError(n ? e.message : String(e), \"host\", n ? F.HostErrorName.Error : F.HostErrorName.Throw, (n && typeof e.stack === \"string\") ? e.stack : null) }"),
});

/// `function __bp_host_result(F, f) { try { return { ok: f() }; } catch (e) { return __bp_host_fail(F, e); } }`
/// — see `Helper.host_result`.
const host_result: ast.Stmt = hFn("__bp_host_result", &.{ "F", "f" }, &.{.{ .try_catch = .{
    .body = .{ .stmts = &.{hRet("{ ok: f() }")}, .indent = 1 },
    .param = "e",
    .handler = .{ .stmts = &.{hRet("__bp_host_fail(F, e)")}, .indent = 1 },
} }});

/// `function __bp_host_result_task(F, f) { return __bp_task(new Promise((r) => r(f())).then((v) => ({ ok: v }), (e) => __bp_host_fail(F, e))); }`
/// — see `Helper.host_result_task`.
const host_result_task: ast.Stmt = hFn("__bp_host_result_task", &.{ "F", "f" }, &.{
    hRet("__bp_task(new Promise((r) => r(f())).then((v) => ({ ok: v }), (e) => __bp_host_fail(F, e)))"),
});

/// `function __bp_task(p) { … }` — see `Helper.task`.
const task: ast.Stmt = hFn("__bp_task", &.{"p"}, &.{
    hConst(.const_, "t", "p.then((r) => { if (r != null && \"error\" in r) { t.__bp_failure = true; throw r.error; } return (r == null) ? r : r.ok; })"),
    .{ .expr = hx("t.__bp_fails = true") },
    .{ .expr = hx("t.catch(() => {})") },
    hRet("t"),
});

/// `function __bp_await(t) { … }` — see `Helper.await_task`.
const await_task: ast.Stmt = hFn("__bp_await", &.{"t"}, &.{
    hRet("(t != null && t.__bp_fails === true) ? t.then((v) => ({ ok: v }), (e) => { if (t.__bp_failure === true) { return { error: e }; } throw e; }) : t"),
});

/// `function __bp_adopt(v, C, p) { return … }` — see `Helper.adopt`.
const adopt: ast.Stmt = .{ .function = .{
    .name = "__bp_adopt",
    .params = &.{ .{ .pattern = .{ .name = "v" } }, .{ .pattern = .{ .name = "C" } }, .{ .pattern = .{ .name = "p" } } },
    .body = .{ .stmts = &.{.{ .return_ = .{ .host = &.{.{ .text = "(v == null) ? v : (p === \"\") ? ((typeof v === \"object\" && !(v instanceof C)) ? Object.assign(Object.create(C.prototype), v) : v) : (p[0] === \"a\") ? (Array.isArray(v) ? v.map((e) => __bp_adopt(e, C, p.slice(1))) : v) : (p[0] === \"r\" && typeof v === \"object\" && \"ok\" in v) ? { ok: __bp_adopt(v.ok, C, p.slice(1)) } : v" }} } }}, .layout = .spaced },
} };

const iv: ast.Expr = .{ .name = "v" };

/// `function __bp_int(v, lo, hi, what) { … }` — see `Helper.int_check`.
const int_check: ast.Stmt = .{ .function = .{
    .name = "__bp_int",
    .params = &.{ .{ .pattern = .{ .name = "v" } }, .{ .pattern = .{ .name = "lo" } }, .{ .pattern = .{ .name = "hi" } }, .{ .pattern = .{ .name = "what" } } },
    .body = .{ .stmts = &.{
        .{ .if_ = .{
            .cond = .{ .binary = .{
                .op = "&&",
                .lhs = &.{ .binary = .{ .op = ">=", .lhs = &iv, .rhs = &.{ .name = "lo" }, .parens = false } },
                .rhs = &.{ .binary = .{ .op = "<=", .lhs = &iv, .rhs = &.{ .name = "hi" }, .parens = false } },
                .parens = false,
            } },
            .then = &.{ .block = .{ .stmts = &.{.{ .return_ = .{ .binary = .{ .op = "+", .lhs = &iv, .rhs = &.{ .number = "0" }, .parens = false } } }}, .layout = .spaced } },
        } },
        .{ .throw_ = .{ .call = .{
            .callee = &.{ .member = .{ .object = &.{ .name = "Object" }, .name = "defineProperty" } },
            .args = &.{
                .{ .new_ = .{
                    .callee = &.{ .name = "Error" },
                    .args = &.{.{ .binary = .{
                        .op = "+",
                        .lhs = &.{ .paren = &.{ .ternary = .{
                            .cond = &.{ .call = .{ .callee = &.{ .member = .{ .object = &.{ .name = "Number" }, .name = "isFinite" } }, .args = &.{iv} } },
                            .then = &.{ .quoted = "integer overflow: " },
                            .else_ = &.{ .quoted = "integer division by zero: " },
                        } } },
                        .rhs = &.{ .name = "what" },
                        .parens = false,
                    } }},
                } },
                .{ .quoted = "__bp_panic" },
                hx("{ value: true }"),
            },
        } } },
    }, .layout = .spaced },
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
const s_at: ast.Expr = .{ .member = .{ .object = &s, .name = "at" } };

/// `function __bp_string_char_at(s, i) { if (!__bp_has_surrogate(s)) { return s.at(i) ?? null; } return Array.from(s).at(i) ?? null; }`
/// — native `String.prototype.at` counts a negative index from the end
/// (decision 139) and answers `undefined` outside the string, which `?? null`
/// makes decision 47's absent. A string holding a surrogate is read by
/// codepoint (decision 320): `Array.from` splits it into codepoints.
const string_char_at: ast.Stmt = .{ .function = .{
    .name = "__bp_string_char_at",
    .params = &.{ .{ .pattern = .{ .name = "s" } }, .{ .pattern = .{ .name = "i" } } },
    .body = .{ .stmts = &.{
        hIf("!__bp_has_surrogate(s)", &.{.{ .return_ = .{ .binary = .{
            .op = "??",
            .lhs = &.{ .call = .{ .callee = &s_at, .args = &.{i} } },
            .rhs = &.null_,
            .parens = false,
        } } }}),
        hRet("Array.from(s).at(i) ?? null"),
    }, .layout = .spaced },
} };

const xs: ast.Expr = .{ .name = "xs" };
const xs_at: ast.Expr = .{ .member = .{ .object = &xs, .name = "at" } };

/// `function __bp_array_at(xs, i) { return xs.at(i) ?? null; }` — the same
/// reading for an array: `-1` is the last element, and past either end is
/// `null` (decision 139).
const array_at: ast.Stmt = .{ .function = .{
    .name = "__bp_array_at",
    .params = &.{ .{ .pattern = .{ .name = "xs" } }, .{ .pattern = .{ .name = "i" } } },
    .body = .{ .stmts = &.{.{ .return_ = .{ .binary = .{
        .op = "??",
        .lhs = &.{ .call = .{ .callee = &xs_at, .args = &.{i} } },
        .rhs = &.null_,
        .parens = false,
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
const keys_k: ast.Expr = .{ .name = "k" };

fn typeofIs(comptime operand: *const ast.Expr, comptime what: []const u8) ast.Expr {
    return .{ .binary = .{
        .op = "===",
        .lhs = &.{ .unary = .{ .op = "typeof ", .operand = operand, .parens = false } },
        .rhs = &.{ .quoted = what },
    } };
}

/// `if ((typeof v === "number") && (s === "f")) { a.push(__bp_f64(v)); return "%s"; }`
///
/// Decision 8 § 7 — an `f64` always carries its decimal part, on every backend.
/// JavaScript has one number type, so the call site says which values are
/// floats: `"f"` is the print shape `commonJS.zig` builds for an expression it
/// types as `f64`.
const float_branch: ast.Stmt = .{ .if_ = .{
    .cond = .{ .binary = .{ .op = "&&", .lhs = &typeofIs(&v, "number"), .rhs = &eq(&sh, "f") } },
    .then = &pushAndReturn(.{ .call = .{ .callee = &.{ .name = "__bp_f64" }, .args = &.{v} } }, "%s", 1),
} };

/// `if ((typeof v === "bigint")) { a.push(String(v)); return "%s"; }`
///
/// Decision 319 — a 64-bit integer past ±(2^53 − 1) is a `BigInt`, which
/// `%O` writes with an `n`; the language prints its digits.
const bigint_branch: ast.Stmt = .{ .if_ = .{
    .cond = typeofIs(&v, "bigint"),
    .then = &pushAndReturn(.{ .call = .{ .callee = &.{ .name = "String" }, .args = &.{v} } }, "%s", 1),
} };

/// `Object.getPrototypeOf(v).tag` — a variant's tag, which its subclass's
/// prototype carries. Read off the prototype, not the value: a record's own
/// field named `tag` (`Box(value: 1, tag: "t")`) is no variant, and read as
/// one it printed `Box.t(…)`.
const proto_tag: ast.Expr = .{ .member = .{
    .object = &callOn(&.{ .name = "Object" }, "getPrototypeOf", &.{v}),
    .name = "tag",
} };

/// `v.__bp + "." + <tag>` for a variant, `v.__bp` for a record — the source
/// name of the value's type. The base class of an enum carries `__bp` and each
/// variant subclass's prototype carries `tag`, so a variant inherits both.
const named_title: ast.Expr = .{ .ternary = .{
    .cond = &typeofIs(&proto_tag, "string"),
    .then = &.{ .binary = .{
        .op = "+",
        .lhs = &.{ .binary = .{ .op = "+", .lhs = &v_bp, .rhs = &.{ .quoted = "." } } },
        .rhs = &proto_tag,
    } },
    .else_ = &v_bp,
} };

/// `"(" + k.map((n) => n + ": " + __bp_show(v[n], v.__bp_s?.[n], false, a)).join(", ") + ")"`
/// — each field with the print shape its class declares (`__bp_s`, a float
/// field's `"f"`; 144 B-78).
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
                    hx("v.__bp_s?.[n]"),
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

/// ```js
/// if ((typeof v === "object") && (v != null) && (typeof v.__bp !== "string")) {
///     const k = Object.keys(v);
///     if ((k.length === 1) && ((k[0] === "ok") || (k[0] === "error"))) {
///         return ((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a) + ")";
///     }
/// }
/// ```
///
/// A `@Result` is the plain object `{ ok: v }` / `{ error: e }` (no `__bp`
/// marker), and prints the way the source writes it — `Ok(81)`,
/// `Error("bad")` — its payload shown as any nested value is (144 B-53).
const result_branch: ast.Stmt = .{ .if_ = .{
    .cond = .{ .binary = .{
        .op = "&&",
        .lhs = &.{ .binary = .{ .op = "&&", .lhs = &typeofIs(&v, "object"), .rhs = &.{ .binary = .{ .op = "!=", .lhs = &v, .rhs = &null_ } } } },
        .rhs = &.{ .binary = .{ .op = "!==", .lhs = &.{ .unary = .{ .op = "typeof ", .operand = &v_bp, .parens = false } }, .rhs = &.{ .quoted = "string" } } },
    } },
    .then = &.{ .block = .{ .stmts = &.{
        .{ .decl = .{ .pattern = .{ .name = "k" }, .value = callOn(&.{ .name = "Object" }, "keys", &.{v}) } },
        .{ .if_ = .{
            .cond = .{ .binary = .{
                .op = "&&",
                .lhs = &.{ .binary = .{ .op = "===", .lhs = &.{ .member = .{ .object = &keys_k, .name = "length" } }, .rhs = &one } },
                .rhs = &.{ .binary = .{
                    .op = "||",
                    .lhs = &eq(&k_first, "ok"),
                    .rhs = &eq(&k_first, "error"),
                } },
            } },
            .then = &.{ .block = .{ .stmts = &.{.{ .return_ = .{ .binary = .{
                .op = "+",
                .lhs = &.{ .binary = .{
                    .op = "+",
                    .lhs = &.{ .paren = &.{ .ternary = .{ .cond = &eq(&k_first, "ok"), .then = &.{ .quoted = "Ok(" }, .else_ = &.{ .quoted = "Error(" } } } },
                    .rhs = &.{ .call = .{ .callee = &.{ .name = "__bp_show" }, .args = &.{
                        .{ .index = .{ .object = &v, .index = &k_first } },
                        null_,
                        .{ .name = "false" },
                        args_a,
                    } } },
                } },
                .rhs = &.{ .quoted = ")" },
            } } }}, .layout = .indented, .indent = 2 } },
        } },
    }, .layout = .indented, .indent = 1 } },
} };

/// `k[0]` — the one key of a `@Result` object.
const k_first: ast.Expr = .{ .index = .{ .object = &keys_k, .index = &zero } };

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
                bigint_branch,
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
                result_branch,
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
///     if (Object.is(a, b)) {
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
///
/// Decision 214 — the first test is `Object.is`, the total order of `f64 ==`:
/// two NaNs are equal and `0.0` differs from `-0.0`. A number of unknown type
/// is safe to compare that way because an integer is never `-0` here — the
/// integer lowering canonicalises `*`, `%`, `/` and unary `-`
/// (`commonJS.zig` `intCanon`).
const structural_eq: ast.Stmt = .{ .function = .{
    .name = "__bp_eq",
    .params = &.{ .{ .pattern = .{ .name = "a" } }, .{ .pattern = .{ .name = "b" } }, .{ .pattern = .{ .name = "d" } } },
    .body = .{ .stmts = &.{
        .{ .if_ = .{
            .cond = .{ .call = .{ .callee = &.{ .name = "Object.is" }, .args = &.{ eq_a, eq_b } } },
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
        \\    if (Object.is(a, b)) {
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

test "js_prelude: an integer outside its type's range aborts (decision 264)" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.int_check), 0);
    try std.testing.expectEqualStrings(
        \\function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }
    , aw.written());
}

test "js_prelude: a 64-bit integer is a number or a BigInt, the full range (decision 319)" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const emitter = @import("js_emitter.zig");
    try emitter.writeStmt(&aw.writer, decl(.wide_norm), 0);
    try aw.writer.writeByte('\n');
    try emitter.writeStmt(&aw.writer, decl(.wide_add), 0);
    try aw.writer.writeByte('\n');
    try emitter.writeStmt(&aw.writer, decl(.wide_div), 0);
    try std.testing.expectEqualStrings(
        \\function __bp_wnorm(v, u, what) {
        \\    if (u ? (v < 0n || v > 18446744073709551615n) : (v < -9223372036854775808n || v > 9223372036854775807n)) { throw Object.defineProperty(new Error("integer overflow: " + what), "__bp_panic", { value: true }); }
        \\    return (v >= -9007199254740991n && v <= 9007199254740991n) ? Number(v) : v;
        \\}
        \\function __bp_wadd(a, b, u, what) {
        \\    if (typeof a === "number" && typeof b === "number") { const r = a + b + 0; if (Number.isSafeInteger(r) && (r >= 0 || !u)) { return r; } }
        \\    return __bp_wnorm(BigInt(a) + BigInt(b), u, what);
        \\}
        \\function __bp_wdiv(a, b, u, what) {
        \\    if (b == 0) { throw Object.defineProperty(new Error("integer division by zero: " + what), "__bp_panic", { value: true }); }
        \\    if (typeof a === "number" && typeof b === "number") { return Math.trunc(a / b) + 0; }
        \\    return __bp_wnorm(BigInt(a) / BigInt(b), u, what);
        \\}
    , aw.written());
    // A module calling an operation carries the normaliser it calls.
    try std.testing.expectEqualSlices(Helper, &.{.wide_norm}, requires(.wide_mul));
    const ArithKind = @import("../../comptime/env.zig").ArithKind;
    try std.testing.expectEqual(@as(i128, 18446744073709551615), ArithKind.u64.range().?.hi);
    try std.testing.expectEqual(@as(i128, -9223372036854775808), ArithKind.isize.range().?.lo);
}

test "js_prelude: a bigint divides as a BigInt, a zero divisor named (decision 332)" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const emitter = @import("js_emitter.zig");
    try emitter.writeStmt(&aw.writer, decl(.big_div), 0);
    try std.testing.expectEqualStrings(
        \\function __bp_bdiv(a, b, what) {
        \\    if (b === 0n) { throw Object.defineProperty(new Error("integer division by zero: " + what), "__bp_panic", { value: true }); }
        \\    return a / b;
        \\}
    , aw.written());
    try std.testing.expect(@import("../../comptime/env.zig").ArithKind.bigint.range() == null);
}

test "js_prelude: a string index counts codepoints (decision 320)" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const emitter = @import("js_emitter.zig");
    try emitter.writeStmt(&aw.writer, decl(.str_length), 0);
    try aw.writer.writeByte('\n');
    try emitter.writeStmt(&aw.writer, decl(.str_index_of), 0);
    try std.testing.expectEqualStrings(
        \\function __bp_str_length(s) {
        \\    if (!__bp_has_surrogate(s)) { return s.length; }
        \\    let n = 0;
        \\    for (const c of s) { n += 1; }
        \\    return n;
        \\}
        \\function __bp_str_index_of(s, sub) {
        \\    const u = s.indexOf(sub);
        \\    return (u <= 0 || !__bp_has_surrogate(s)) ? u : __bp_str_count(s, u);
        \\}
    , aw.written());
    try std.testing.expectEqual(Helper.str_length, forMethod(.string, "length", 0).?);
    try std.testing.expectEqual(Helper.str_last_index_of, forMethod(.string, "lastIndexOf", 1).?);
    try std.testing.expect(forMethod(.array, "indexOf", 1) == null);
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
        "function __bp_assert_fatal(cond, msg, head, where) {\n    if (!cond) { const m = head + (msg == null ? \"\" : \": \" + msg) + \" at \" + where; throw Object.defineProperty(new Error(m), \"__bp_panic\", { value: m }); }\n}",
        aw.written(),
    );
}

test "js_prelude: string at counts a negative index from the end, null out of range (decision 139)" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.string_char_at), 0);
    try std.testing.expectEqualStrings(
        "function __bp_string_char_at(s, i) { if (!__bp_has_surrogate(s)) { return s.at(i) ?? null; } return Array.from(s).at(i) ?? null; }",
        aw.written(),
    );
    try std.testing.expectEqual(Helper.string_char_at, forMethod(.string, "at", 1).?);
    try std.testing.expectEqual(Helper.array_at, forMethod(.array, "at", 1).?);
    try std.testing.expect(forMethod(.other, "at", 1) == null);
    // The old spelling answers nothing: `charAt` is the HOST symbol the
    // template names, not a botopink declaration any more.
    try std.testing.expect(forMethod(.string, "charAt", 1) == null);
}

test "js_prelude: array at counts a negative index from the end, null out of range (decisions 47, 139)" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.array_at), 0);
    try std.testing.expectEqualStrings(
        "function __bp_array_at(xs, i) { return xs.at(i) ?? null; }",
        aw.written(),
    );
}
