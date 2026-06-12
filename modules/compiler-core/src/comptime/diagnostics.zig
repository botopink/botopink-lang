//! Stable diagnostic codes for the effect-annotation + default-generic ruleset
//! authored in `tasks/v0.beta.19/specs/frente-b-rules-tooling.md` (§0–§4 + §1G).
//!
//! Each constant below is the **stable string** a snapshot or LSP consumer
//! pattern-matches against (the test runner asserts the byte-exact diagnostic
//! message — the code is the keyhole). The constant name mirrors the spec's
//! short identifier (R1 / RF1 / RI1 / RC1 / RG1 / …) so the diagnostic-code
//! table in the spec stays addressable from code.
//!
//! Diagnostic *messages* live next to the parser/comptime site that fires
//! them; this file only reserves the namespace. A net-new diagnostic must
//! land its constant here BEFORE the firing site references it, so the code
//! catalogue and the firing surface stay in sync (the F1 contract).
//!
//! Existing pre-v0.beta.19 diagnostics (`throw-without-result`, the typed
//! family in `error.zig`) keep their original text; the constants below
//! cover the **net-new** rules the spec authored. R6/R7/R8 also document
//! existing rules whose code names are now formalised here.

const std = @import("std");

// ── R1–R17: §2 rejection cases ───────────────────────────────────────────────

/// R1 — `#[@<effect>] declare fn …` (annotation on a bodyless declaration).
pub const effect_on_declare_forbidden: []const u8 = "effect-on-declare-forbidden";

/// R2 — `interface I { #[@<effect>] fn … }` (annotation on an interface method).
pub const effect_on_interface_method_forbidden: []const u8 = "effect-on-interface-method-forbidden";

/// R3 — annotation effect kind disagrees with the return wrapper kind.
pub const effect_wrapper_mismatch: []const u8 = "effect-wrapper-mismatch";

/// R4 — annotation present, return wrapper missing (`#[@result] fn f() -> i32`).
pub const effect_missing_wrapper: []const u8 = "effect-missing-wrapper";

/// R5 — more than one `#[@<effect>]` annotation on the same fn.
pub const effect_duplicate_annotation: []const u8 = "effect-duplicate-annotation";

/// R6 — `throw` outside a fallible-channel effect (result/future/iterator/asyncGenerator).
pub const effect_throw_without_fallible_channel: []const u8 = "effect-throw-without-fallible-channel";

/// R7 — `await` outside `#[@future]` / `#[@asyncGenerator]`.
pub const effect_await_without_future: []const u8 = "effect-await-without-future";

/// R8 — `yield` outside a yielding effect (generator/iterator/asyncGenerator).
pub const yield_without_generator: []const u8 = "yield-without-generator";

/// R9 — alias of R7 (`await` inside `#[@result]` body).
pub const effect_await_without_future_in_result: []const u8 = effect_await_without_future;

/// R10 — alias of R6 (`throw` inside `#[@context]` / `#[@generator]` body).
pub const effect_throw_without_fallible_channel_in_context: []const u8 = effect_throw_without_fallible_channel;

/// R11 — `return Result::Ok(<r>)` inside `#[@result]` body (must be bare R).
pub const return_must_be_bare_R: []const u8 = "return-must-be-bare-R";

/// R12 — manual `Result::Ok(...)`/`Result::Err(...)` construction inside `#[@result]`.
pub const result_manual_construction_forbidden: []const u8 = "result-manual-construction-forbidden";

/// `throw Result::Err(<e>)` inside `#[@result]` body (must be bare E).
pub const throw_must_be_bare_E: []const u8 = "throw-must-be-bare-E";

/// `return e;` where `e: E` inside `#[@result]` (auto-wrap targets R).
pub const result_return_type_mismatch: []const u8 = "result-return-type-mismatch";

/// `throw r;` where `r: R` inside `#[@result]` (auto-wrap targets E).
pub const result_throw_type_mismatch: []const u8 = "result-throw-type-mismatch";

/// `try { … }` block whose callee `E` differs from the enclosing `E`.
pub const result_error_type_incompatible: []const u8 = "result-error-type-incompatible";

/// R13 — `break <expr>` inside an iterator whose wrapper has `C = void`.
pub const iterator_break_without_completion_type: []const u8 = "iterator-break-without-completion-type";

/// R14 — `return <expr>` inside `#[@iterator]` / `#[@asyncGenerator]`.
pub const iterator_return_forbidden: []const u8 = "iterator-return-forbidden";

/// R15 — `yield :label <expr>` where the label is not bound.
pub const yield_label_unbound: []const u8 = "yield-label-unbound";

/// R16 — generic parameter list `<T = default, U>` (required after defaulted).
pub const generic_default_before_required: []const u8 = "generic-default-before-required";

/// R17 — manual `Future::resolved(...)` / `Future::rejected(...)` inside `#[@future]`.
pub const future_manual_construction_forbidden: []const u8 = "future-manual-construction-forbidden";

/// R18 (E2) — alias of RC2 (`use <hook>()` violates anchor).
/// R19 (E1) — alias of RC1 (`@getContex(T)` with no active provider).
/// R20      — alias of RC3 (`@getContex(T)` outside the anchor).
/// R21      — alias of RC6 (`use` of a non-`#[@context]` fn).
//
// The §1C addendum keeps the RC* names as the canonical surface; the R-table
// numbers point to them via alias here for the catalogue.

// ── RF1–RF5: §1F `#[@future]` auto-wrap diagnostics ─────────────────────────

/// RF1 — `return Future::resolved(<t>)` inside `#[@future]` (must be bare T).
pub const future_return_must_be_bare_T: []const u8 = "future-return-must-be-bare-T";

/// RF2 — `throw Future::rejected(<e>)` inside `#[@future]` (must be bare E).
pub const future_throw_must_be_bare_E: []const u8 = "future-throw-must-be-bare-E";

/// RF3 — `return e;` where `e: E` inside `#[@future]` (auto-wrap targets T).
pub const future_return_type_mismatch: []const u8 = "future-return-type-mismatch";

/// RF4 — `throw r;` where `r: T` inside `#[@future]` (auto-wrap targets E).
pub const future_throw_type_mismatch: []const u8 = "future-throw-type-mismatch";

/// RF5 — manual `Future::resolved(...)` / `Future::rejected(...)` inside `#[@future]`.
/// Identical to R17 (the §2 alias).
pub const future_manual_construction_forbidden_alias: []const u8 = future_manual_construction_forbidden;

// ── RI1–RI6: §1I `#[@iterator]` syntax diagnostics ──────────────────────────

/// RI1 — `return <expr>` inside `#[@iterator]` / `#[@asyncGenerator]`.
/// Identical to R14 (the §2 alias).
pub const iterator_return_forbidden_alias: []const u8 = iterator_return_forbidden;

/// RI2 — `break <expr>` whose type is not assignable to declared `C`.
pub const iterator_break_type_mismatch: []const u8 = "iterator-break-type-mismatch";

/// RI3 — `break <expr>` inside an iterator whose wrapper has `C = void`.
/// Identical to R13.
pub const iterator_break_without_completion_type_alias: []const u8 = iterator_break_without_completion_type;

/// RI4 — `yield :label <expr>` where `:label` is not bound.
/// Identical to R15.
pub const yield_label_unbound_alias: []const u8 = yield_label_unbound;

/// RI5 — `break :label <expr>` where `:label` is not bound.
pub const break_label_unbound: []const u8 = "break-label-unbound";

/// RI6 — `yield break <expr>` (the deprecated form, removed in v0.beta.19).
pub const yield_break_removed: []const u8 = "yield-break-removed";

// ── RC1–RC6: §1C `#[@context]` Anchor diagnostics ───────────────────────────

/// RC1 (E1) — `@getContex(T)` with no active provider of T on the scope stack.
pub const context_unbound: []const u8 = "context-unbound";

/// RC2 (E2) — `use <hook>()` whose `HookBase` is not assignable to enclosing Anchor.
pub const context_anchor_violation: []const u8 = "context-anchor-violation";

/// RC3 — `@getContex(T)` whose T is outside the enclosing fn's Anchor tree.
pub const context_getcontex_anchor_violation: []const u8 = "context-getcontex-anchor-violation";

/// RC4 — `@getContex(<value>)` (the argument must be a type).
pub const context_getcontex_expects_type: []const u8 = "context-getcontex-expects-type";

/// RC5 — `@getContex(…)` outside a `#[@context]` fn body.
pub const context_getcontex_outside_context_fn: []const u8 = "context-getcontex-outside-context-fn";

/// RC6 — `use <hook>()` where `<hook>` is not a `#[@context]` fn.
pub const use_of_non_context_fn: []const u8 = "use-of-non-context-fn";

// ── RG1–RG4: §1G default-generic diagnostics ────────────────────────────────

/// RG1 — `<T = default, U>` — required parameter follows a defaulted one.
/// Identical to R16.
pub const generic_default_before_required_alias: []const u8 = generic_default_before_required;

/// RG2 — `<>` with every parameter defaulted is legal — no diagnostic. Reserved
/// here for documentation symmetry.
pub const generic_all_defaults_legal_reserved: []const u8 = "";

/// RG3 — required generic argument missing (e.g. `@Future<>` where T is required).
pub const generic_required_arg_missing: []const u8 = "generic-required-arg-missing";

/// RG4 — skipped middle generic argument (`@Iterator<i32, , i64>`).
pub const generic_arg_skip_forbidden: []const u8 = "generic-arg-skip-forbidden";

/// §A3 — `#[@result] declare fn` whose `@external(<target>, "<template>")`
/// body is missing the `ok` or `error` branch on at least one target.
/// The template owns the wrapper shape — both branches must be present so
/// callers see a complete `{ok, _} | {error, _}` lowering.
pub const result_template_shape_mismatch: []const u8 = "result-template-shape-mismatch";

/// STD-001 — `import {fs} from "std"` (or any other std module) on a target
/// for which the module has no `#[@External.<target>( …)]` annotation set.
/// Fires when `Env.target != null` AND the imported module's stdModuleFns
/// entry holds at least one declare fn without an external matching the
/// active target. The diagnostic is intentionally registered ahead of the
/// runtime check so consumers/docs can reference the spelling; the check
/// itself lands with `Env.target` threading + `stdModuleFns` population.
pub const std_unsupported_on_target: []const u8 = "std-unsupported-on-target";

// ── D1–D6: fn-param-default-expansion diagnostics ────────────────────────────
// Authored in `tasks/v0.beta.20/specs/prim-op.md` §"fn-param-default-expansion"
// F2 — six diagnostics shared by every call surface (fn call / annotation /
// record/struct/enum-variant constructor) so the default-injection rule reads
// the same way wherever it fires.

/// D1 — `fn f(a: i32 = 1, b: i32)` at infer time (a defaulted param followed
/// by a required one). Fires from `inferFnDecl` / signature registration on
/// any user fn — companion to D5 which fires from the parser. Same wording.
pub const fn_param_default_trailing_only: []const u8 = "fn-param-default-trailing-only";

/// D2 — `f(host: "x", "y")` — a positional argument supplied after a named one.
/// Fires from `parser/decls.parseAnnotationCall` + `parser/expressions.parseCallExpr`.
pub const fn_param_positional_after_named: []const u8 = "fn-param-positional-after-named";

/// D3 — `connect()` when `host` has no default. Fires from `comptime/infer.zig`
/// at the call-site arity check, after `expandTrailingDefaults` could not
/// fill every missing arg.
pub const fn_param_default_arity_mismatch: []const u8 = "fn-param-default-arity-mismatch";

/// D4 — `Color.Rgb()` when the variant has 3 non-defaulted fields. Same wording
/// shape as D3 with the enum-variant tail; the firing site is the enum
/// variant constructor call in `comptime/infer.zig`.
pub const enum_variant_arity_mismatch: []const u8 = "enum-variant-arity-mismatch";

/// D5 — parse-time companion of D1: same wording, fires from
/// `parser/decls.parseParam` before infer ever sees the fn.
pub const fn_param_default_trailing_only_parse: []const u8 = "fn-param-default-trailing-only-parse";

/// D6 — `s.slice(2, 5, 99)` — more args than params (with the receiver shape
/// trimmed off the count). Fires from `comptime/infer.zig` at the call-site
/// arity check.
pub const fn_param_arity_exceeded: []const u8 = "fn-param-arity-exceeded";

// ── Lookup table — every code (skipping aliases & reserved-empties) ─────────

pub const all_codes = [_][]const u8{
    effect_on_declare_forbidden,
    effect_on_interface_method_forbidden,
    effect_wrapper_mismatch,
    effect_missing_wrapper,
    effect_duplicate_annotation,
    effect_throw_without_fallible_channel,
    effect_await_without_future,
    yield_without_generator,
    return_must_be_bare_R,
    result_manual_construction_forbidden,
    throw_must_be_bare_E,
    result_return_type_mismatch,
    result_throw_type_mismatch,
    result_error_type_incompatible,
    iterator_break_without_completion_type,
    iterator_return_forbidden,
    yield_label_unbound,
    generic_default_before_required,
    future_manual_construction_forbidden,
    future_return_must_be_bare_T,
    future_throw_must_be_bare_E,
    future_return_type_mismatch,
    future_throw_type_mismatch,
    iterator_break_type_mismatch,
    break_label_unbound,
    yield_break_removed,
    context_unbound,
    context_anchor_violation,
    context_getcontex_anchor_violation,
    context_getcontex_expects_type,
    context_getcontex_outside_context_fn,
    use_of_non_context_fn,
    generic_required_arg_missing,
    generic_arg_skip_forbidden,
    result_template_shape_mismatch,
    std_unsupported_on_target,
    fn_param_default_trailing_only,
    fn_param_positional_after_named,
    fn_param_default_arity_mismatch,
    enum_variant_arity_mismatch,
    fn_param_default_trailing_only_parse,
    fn_param_arity_exceeded,
};

test "every reserved code has a stable, non-empty spelling" {
    for (all_codes) |c| try std.testing.expect(c.len > 0);
}

test "codes are unique (the table is the contract)" {
    for (all_codes, 0..) |c, i| {
        for (all_codes[i + 1 ..]) |d| try std.testing.expect(!std.mem.eql(u8, c, d));
    }
}
