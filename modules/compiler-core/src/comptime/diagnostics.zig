//! Stable diagnostic codes for the effect ruleset (1.0.10-beta decisions
//! 118–128 — the return type is the effect) and the default-generic ruleset
//! authored in `tasks/v0.beta.19/specs/frente-b-rules-tooling.md` (§1G).
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

// ── decisions 118–128 — the return is the effect ────────────────────────────
//
// Decision 118 removed the effect annotations, so every rule that paired an
// annotation with its wrapper left with them: `effect-on-declare-forbidden`,
// `effect-on-behavior-method-forbidden`, `effect-missing-wrapper`,
// `effect-missing-annotation` and `effect-duplicate-annotation` (a function
// has one return, so it has one effect). Decision 121 merged
// `effect-throw-without-fallible-channel` into
// `effect-try-without-fallible-channel` — the guide spells both refusals with
// the one code. Decision 122 deleted `for-over-fallible-generator` (a `for`
// does no implicit `try`). `specs/1.0.10-beta/decisions-pending.md` records
// these choices (front 24, open point 2).

/// Decisions 118 / 127 — `#[@result]`, `#[@future]`, `#[@use]`,
/// `#[@generator]`, `#[@resultGenerator]`, `#[@futureGenerator]`: refused by
/// the parser (`print.zig`), fix-it: remove it (on a loop: `iter` / `stream`).
pub const effect_annotation_removed: []const u8 = "effect-annotation-removed";

/// Decisions 120 / 122 / 127 / 128 — `@Future`, `@Generator`,
/// `@ResultGenerator`, `@FutureGenerator`, `@Use` in a type: refused by the
/// parser, fix-it: the new name.
pub const effect_type_removed: []const u8 = "effect-type-removed";

/// Decision 122 — `@Iterator<T, E>`: refused by the parser, fix-it
/// `@Iterator<@Result<T, E>>`.
pub const iterator_error_param_removed: []const u8 = "iterator-error-param-removed";

/// Decision 128 — a component `-> @Component<C, T>` whose `T` implements
/// `@Context<B>` with a `B` other than `C`.
pub const effect_wrapper_mismatch: []const u8 = "effect-wrapper-mismatch";

/// Decision 118 rule 1 — a capability (`throw`, `try`, `await`, `use`,
/// `yield`) used under an ALIASED return: the alias types the function, never
/// activates the effect. Fix-it: write the wrapper literally.
pub const effect_wrapper_behind_alias: []const u8 = "effect-wrapper-behind-alias";

/// Decision 119 — a `return` whose value fits two layers of a nested wrapper
/// (`-> @Result<@Result<i32, E>, E>`); asks for an explicit `Ok(…)`.
/// Reserved: the refinement is deferred (front 24's priority order).
pub const effect_return_ambiguous_nesting: []const u8 = "effect-return-ambiguous-nesting";

/// Decision 121 — `throw` or bare `try` (the propagating form) in a body whose
/// return carries no `@Result` in any layer. The `try … catch` form supplies
/// its own fallback and needs no channel, so it is not gated.
pub const effect_try_without_fallible_channel: []const u8 = "effect-try-without-fallible-channel";

/// Decision 120 — `await` (or `for await`) without an await channel: a
/// `@Task`, `@Component` or `@Stream` return, or a `stream` loop.
pub const effect_await_without_task: []const u8 = "effect-await-without-task";

/// Decision 122 — `await` in an `@Iterator` body or an `iter` loop.
pub const iter_await: []const u8 = "iter-await";

/// Decision 123 — `yield` and `return <iterator>` in one body.
pub const iter_mixed_yield_return: []const u8 = "iter-mixed-yield-return";

/// Decisions 124 / 125 — two different `E`s in the body of `async { }` /
/// `iter` / `stream`. Reserved: deferred with `async { }`.
pub const gen_infer_conflicting_errors: []const u8 = "gen-infer-conflicting-errors";

/// Front 20 F11 — `.expect(default)` on a `?T`. It was an alias of `unwrapOr`
/// under a name that says the absent branch is unreachable, which is the
/// loosest reading of the stricter word (decision 67). There is one spelling
/// now, and reaching for the old one is refused rather than typed permissively
/// and broken at run time.
pub const option_expect_removed: []const u8 = "option-expect-removed";

// ── decision 105 — the three loops and the generator scope ───────────────────

/// `break <value>` outside a generator scope (an annotated fn or an annotated
/// `loop`), and not the value of a `comptime` block or a `case` arm's block.
pub const break_value_outside_generator: []const u8 = "break-value-outside-generator";
/// A bare `break` with no loop, generator scope or value block to leave.
pub const break_outside_loop: []const u8 = "break-outside-loop";
/// `continue` with no enclosing loop.
pub const continue_outside_loop: []const u8 = "continue-outside-loop";
/// `for (cond) { x -> … }` over a `bool` — a condition is a `while`.
pub const for_over_condition: []const u8 = "for-over-condition";
/// `for` (not `for await`) over a `@Stream`.
pub const for_over_stream: []const u8 = "for-over-stream";
/// `for await` over something that is not a `@Stream`.
pub const for_await_expects_stream: []const u8 = "for-await-expects-stream";
/// A `use`, or a `break :outer` / `continue :outer`, crossing the border of an
/// `iter` / `stream` loop — its body is closed like a closure.
pub const generator_loop_closed_scope: []const u8 = "generator-loop-closed-scope";
/// `yield :label` naming a plain loop's label rather than a generator scope's.
pub const yield_label_not_generator: []const u8 = "yield-label-not-generator";

/// R8 — `yield` outside a generator scope (an `@Iterator` / `@Stream` return
/// that yields, or an `iter` / `stream` loop).
pub const yield_without_generator: []const u8 = "yield-without-generator";

/// R11 — `return Result::Ok(<r>)` in a body whose return carries a `@Result` (must be bare R).
pub const return_must_be_bare_R: []const u8 = "return-must-be-bare-R";

/// R12 — manual `Result::Ok(...)`/`Result::Err(...)` construction in such a body.
pub const result_manual_construction_forbidden: []const u8 = "result-manual-construction-forbidden";

/// `throw Result::Err(<e>)` in such a body (must be bare E).
pub const throw_must_be_bare_E: []const u8 = "throw-must-be-bare-E";

/// `return Result.Error(e);` in such a body (auto-wrap targets R).
pub const result_return_type_mismatch: []const u8 = "result-return-type-mismatch";

/// `throw Result.Ok(r);` in such a body (auto-wrap targets E).
pub const result_throw_type_mismatch: []const u8 = "result-throw-type-mismatch";

/// `try { … }` block whose callee `E` differs from the enclosing `E`.
pub const result_error_type_incompatible: []const u8 = "result-error-type-incompatible";

/// R14 — `return <expr>` inside an `iter` / `stream` loop: a sequence has no
/// return channel (decision 122) — `break <v>` emits the last item and ends.
/// (In a function body the same shape is `iter-mixed-yield-return`.)
pub const iterator_return_forbidden: []const u8 = "iterator-return-forbidden";

/// R15 — `yield :label <expr>` where the label is not bound.
pub const yield_label_unbound: []const u8 = "yield-label-unbound";

/// R16 — generic parameter list `<T = default, U>` (required after defaulted).
pub const generic_default_before_required: []const u8 = "generic-default-before-required";

/// R18 (E2) — alias of RC2 (`use <hook>()` violates anchor).
/// R19 (E1) — alias of RC1 (`@getContext(T)` with no active provider).
/// R20      — alias of RC3 (`@getContext(T)` outside the anchor).
/// R21      — alias of RC6 (`use` of a non-hook (a callee that is not a hook `@Component<C, _>`)).
//
// The §1C addendum keeps the RC* names as the canonical surface; the R-table
// numbers point to them via alias here for the catalogue.

// ── RI1–RI6: §1I generator-body syntax diagnostics ───────────────────────────

/// RI1 — `return <expr>` inside a generator body. Identical to R14 (the §2 alias).
pub const iterator_return_forbidden_alias: []const u8 = iterator_return_forbidden;

/// RI2 — `break <expr>` whose type is not the generator's item type `T`
/// (decision 103: `break v` ≡ `yield v; break;`, so `v` is an item). RI3 —
/// `break <expr>` against a `C = void` wrapper — left with the `C` channel.
pub const iterator_break_type_mismatch: []const u8 = "iterator-break-type-mismatch";

/// RI4 — `yield :label <expr>` where `:label` is not bound.
/// Identical to R15.
pub const yield_label_unbound_alias: []const u8 = yield_label_unbound;

/// RI5 — `break :label <expr>` where `:label` is not bound.
pub const break_label_unbound: []const u8 = "break-label-unbound";

/// RI6 — `yield break <expr>` (the deprecated form, removed in v0.beta.19).
pub const yield_break_removed: []const u8 = "yield-break-removed";

// ── RC1–RC6: §1C `@Component` base diagnostics ───────────────────────────

/// RC1 (E1) — `@getContext(T)` with no active provider of T on the scope stack.
pub const context_unbound: []const u8 = "context-unbound";

/// RC2 (E2) — `use <hook>()` whose `HookBase` is not assignable to enclosing Anchor.
pub const context_anchor_violation: []const u8 = "context-anchor-violation";

/// RC3 — `@getContext(T)` whose T is outside the enclosing fn's Anchor tree.
pub const context_getcontext_anchor_violation: []const u8 = "context-getcontext-anchor-violation";

// ── `@src()` (1.0.10-beta front 01-std, decision 73) ─────────────────────────
/// `@src(…)` was given an argument or a trailing lambda — the builtin takes none.
pub const src_takes_no_arguments: []const u8 = "src-takes-no-arguments";
/// A `@name(…)` call no builtin arm recognises. Replaces the silent `void`
/// fallback that let a typo (`@pritn`) compile (decision 67: refuse).
pub const unknown_builtin: []const u8 = "unknown-builtin";

/// RC4 — `@getContext(<value>)` (the argument must be a type).
pub const context_getcontext_expects_type: []const u8 = "context-getcontext-expects-type";

/// RC5 — `@getContext(…)` outside a `-> @Component<…>` fn body.
pub const context_getcontext_outside_context_fn: []const u8 = "context-getcontext-outside-context-fn";

/// RC6 — `use <hook>()` where `<hook>` is not a hook `@Component<C, _>` hook.
pub const use_of_non_context_fn: []const u8 = "use-of-non-context-fn";

/// RC7 (decisions 88, 104, 118) — `use` in a body whose fn does not return
/// `@Component<C, T>`, or in a nested closure of one: only that body
/// activates a hook.
pub const use_without_context_effect: []const u8 = "use-without-context-effect";

/// Front 19 step 3 — `val #(a, b) = use …` whose hook yields a tuple of another
/// arity, or no tuple at all. Located at the binding; no flag (decision 67).
pub const use_tuple_arity: []const u8 = "use-tuple-arity";

/// 01 R5 — `val <Pattern> = e;` whose pattern can fail to match the subject.
/// The bare form has no failure path; `val assert` and `case` are the forms
/// that say what a mismatch does.
pub const refutable_val_pattern: []const u8 = "refutable-val-pattern";

// ── RG1–RG4: §1G default-generic diagnostics ────────────────────────────────

/// RG1 — `<T = default, U>` — required parameter follows a defaulted one.
/// Identical to R16.
pub const generic_default_before_required_alias: []const u8 = generic_default_before_required;

/// RG2 — `<>` with every parameter defaulted is legal — no diagnostic. Reserved
/// here for documentation symmetry.
pub const generic_all_defaults_legal_reserved: []const u8 = "";

/// RG3 — required generic argument missing (e.g. `@Component<T>`: decision 128 requires the base).
pub const generic_required_arg_missing: []const u8 = "generic-required-arg-missing";

/// RG4 — skipped middle generic argument (`@Result<i32, , i64>`).
pub const generic_arg_skip_forbidden: []const u8 = "generic-arg-skip-forbidden";

/// RG5 — more generic arguments than a builtin wrapper declares
/// (`@Task<i32, string>`: a Task has no error parameter, decision 120, and an
/// argument nothing reads is refused, not dropped).
pub const generic_arg_count_exceeded: []const u8 = "generic-arg-count-exceeded";

/// §A3 — a host `declare fn -> @Result<…>` whose `@external(<target>, "<template>")`
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

/// Decision 107 — two import items bind one local name (`import {url.parse,
/// json.parse}`), in either spelling. Located at the second item; an alias
/// on either side (`url.parse as parseUrl`) is the remedy. A repeated
/// identical item (an `@emit` contribution re-importing what its module
/// already imports) is not a collision.
pub const import_name_collision: []const u8 = "import-name-collision";

/// Decision 107 — `as` on an item whose leaf is a nominal type
/// (`import {dict.Dict as D} from "std"`). A type's identity is its declared
/// name on every backend (the record shape, the class, the module a type
/// module gets — policy 3), so an alias would bind a name the emitted code
/// never defines. Refused rather than accepted half-way (decision 67).
pub const import_alias_on_type: []const u8 = "import-alias-on-type";

/// Decision 107 — `as` on an activated item (`import {PatoNada* as Voa}`).
/// An activation opts an extension in BY NAME (the dispatch rewrite emits
/// `PatoNada.swim(donald)`), so a renamed binding would never be the one the
/// rewrite reaches for.
pub const import_alias_on_activation: []const u8 = "import-alias-on-activation";

/// Decision 106 — a module at the root of std (`std/<name>`) is pure and
/// imports nothing from `io/` (`import {io.fs.readText};`, `import {io: {clock}}
/// from "std"`). Located at the item; `io/` and `testing/` are free; no flag.
pub const std_root_imports_io: []const u8 = "std-root-imports-io";

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
    effect_annotation_removed,
    effect_type_removed,
    iterator_error_param_removed,
    effect_wrapper_mismatch,
    effect_wrapper_behind_alias,
    effect_return_ambiguous_nesting,
    effect_try_without_fallible_channel,
    effect_await_without_task,
    iter_await,
    iter_mixed_yield_return,
    gen_infer_conflicting_errors,
    yield_without_generator,
    return_must_be_bare_R,
    result_manual_construction_forbidden,
    throw_must_be_bare_E,
    result_return_type_mismatch,
    result_throw_type_mismatch,
    result_error_type_incompatible,
    iterator_return_forbidden,
    yield_label_unbound,
    generic_default_before_required,
    iterator_break_type_mismatch,
    break_label_unbound,
    yield_break_removed,
    context_unbound,
    context_anchor_violation,
    context_getcontext_anchor_violation,
    context_getcontext_expects_type,
    context_getcontext_outside_context_fn,
    use_of_non_context_fn,
    use_without_context_effect,
    generic_required_arg_missing,
    generic_arg_skip_forbidden,
    generic_arg_count_exceeded,
    result_template_shape_mismatch,
    std_unsupported_on_target,
    import_name_collision,
    import_alias_on_type,
    import_alias_on_activation,
    std_root_imports_io,
    fn_param_default_trailing_only,
    fn_param_positional_after_named,
    fn_param_default_arity_mismatch,
    enum_variant_arity_mismatch,
    fn_param_default_trailing_only_parse,
    fn_param_arity_exceeded,
    option_expect_removed,
    break_value_outside_generator,
    break_outside_loop,
    continue_outside_loop,
    for_over_condition,
    for_over_stream,
    for_await_expects_stream,
    generator_loop_closed_scope,
    yield_label_not_generator,
    refutable_val_pattern,
};

test "every reserved code has a stable, non-empty spelling" {
    for (all_codes) |c| try std.testing.expect(c.len > 0);
}

test "codes are unique (the table is the contract)" {
    for (all_codes, 0..) |c, i| {
        for (all_codes[i + 1 ..]) |d| try std.testing.expect(!std.mem.eql(u8, c, d));
    }
}
