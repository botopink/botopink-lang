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

/// Decision 118 rule 1 — a capability (`throw`, `try`, `await`, `use`,
/// `yield`) used under an ALIASED return: the alias types the function, never
/// activates the effect. Fix-it: write the wrapper literally.
pub const effect_wrapper_behind_alias: []const u8 = "effect-wrapper-behind-alias";

/// Decision 119 — a `return` whose value fits two layers of a nested wrapper
/// (`-> @Result<@Result<i32, E>, E>`); asks for an explicit `Ok(…)`.
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
/// `iter` / `stream` whose `E` is inferred (`infer.zig` `unifyErrorChannel`).
pub const gen_infer_conflicting_errors: []const u8 = "gen-infer-conflicting-errors";

/// A member of a `@Result` value that is not one of its builtin methods
/// (`map`, `flatMap`, `unwrapOr`, `isOk`, `isError`): `parse(q).length` read a
/// field off the `{ok, V}` / `{ok: V}` carrier — `null` on commonJS, a crash on
/// erlang. The payload is reached through `try` or `unwrapOr` (`infer.zig`
/// `refuseResultMemberAccess`).
pub const result_member_not_a_method: []const u8 = "result-member-not-a-method";

// ── decision 105 — the three loops and the generator scope ───────────────────

/// `break <value>` outside a generator scope (an annotated fn or an annotated
/// `loop`), and not the value of a `comptime` block or a `case` arm's block.
pub const break_value_outside_generator: []const u8 = "break-value-outside-generator";
/// A bare `break` with no loop, generator scope or value block to leave.
pub const break_outside_loop: []const u8 = "break-outside-loop";
/// `continue` with no enclosing loop.
pub const continue_outside_loop: []const u8 = "continue-outside-loop";
/// Decision 539 — a `defer` body that would leave the path it runs on: `return`.
pub const defer_return: []const u8 = "defer-return";
/// … `break` out of the deferred body (a loop wholly inside it may break).
pub const defer_break: []const u8 = "defer-break";
/// … `continue` out of the deferred body.
pub const defer_continue: []const u8 = "defer-continue";
/// … `yield`.
pub const defer_yield: []const u8 = "defer-yield";
/// … `await`.
pub const defer_await: []const u8 = "defer-await";
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

// ── RC1, RC6, RC7: contexts and `use` (decision 354) ──────────────────────

/// Decision 354 — `@Context<C>` left the language (parser).
pub const context_marker_removed: []const u8 = "context-marker-removed";

/// Decision 354 (3) — `use` in a decorator body, a template body or a
/// `comptime { … }`: compile-time evaluation has no render tree.
pub const use_outside_render_tree: []const u8 = "use-outside-render-tree";

/// Decision 354 — `use provide(…)` outside a component's body (a hook's, or
/// a `@Component<R>` whose `R` is not `@Renderable`): a provider gives its
/// value to what a component renders below it, and a hook renders nothing.
pub const context_provide_outside_component: []const u8 = "context-provide-outside-component";

/// Decision 354 — `use provide(…)` after the body rendered a component: the
/// child rendered before it would not see the value.
pub const context_provide_after_render: []const u8 = "context-provide-after-render";

/// Decision 354 — std's `provide` / `context` referenced other than as the
/// operand of a `use` (called for a value, passed, bound).
pub const context_hook_without_use: []const u8 = "context-hook-without-use";

/// Decision 354 (2) — a `Context<T>()` that is not a module-level `val`'s
/// whole initializer: a context's identity is its declaration (281).
pub const context_not_declared: []const u8 = "context-not-declared";
pub const render_scope_construction: []const u8 = "render-scope-construction";

// ── `@src()` (1.0.10-beta front 01-std, decision 73) ─────────────────────────
/// `@src(…)` was given an argument or a trailing lambda — the builtin takes none.
pub const src_takes_no_arguments: []const u8 = "src-takes-no-arguments";
/// A `@name(…)` call no builtin arm recognises. Replaces the silent `void`
/// fallback that let a typo (`@pritn`) compile (decision 67: refuse).
pub const unknown_builtin: []const u8 = "unknown-builtin";
/// A builtin `builtins.d.bp` declares that no target lowers (`@module()`):
/// refused at the `@` instead of typed `void` and emitted verbatim.
pub const builtin_not_lowered: []const u8 = "builtin-not-lowered";
/// Decision 252 — a builtin call whose arguments its declaration in
/// `builtins.d.bp` refuses: too many, a parameter without a default missing, a
/// label naming no parameter (a type that disagrees is the ordinary mismatch).
pub const builtin_arguments: []const u8 = "builtin-arguments";
/// Decision 267 — a spread (`f(..xs)`) at a call of a variadic function.
pub const variadic_spread: []const u8 = "variadic-spread";
/// Decision 267 — a label on a variadic argument, or a trailing lambda.
pub const variadic_label: []const u8 = "variadic-label";
/// Decision 359 — a record spread (`..src`) at a call that is no record's
/// constructor: a plain function call takes no spread (267).
pub const call_spread: []const u8 = "call-spread";
/// Decision 359 (2) — a record spread whose source is neither the record's
/// own type nor a type derived from it by `Type.pick` / `omit` / `merge`.
pub const record_spread_type: []const u8 = "record-spread-type";
/// Decision 359 (2) — a record spread of a `Type.partial` value.
pub const record_spread_partial: []const u8 = "record-spread-partial";
/// Decision 359 (4) — a field without a default that no spread and no label
/// supplies.
pub const record_spread_missing_field: []const u8 = "record-spread-missing-field";
/// Decision 359 — a field labelled twice, or an unlabelled argument, beside a
/// record spread.
pub const record_spread_arguments: []const u8 = "record-spread-arguments";
/// Decision 529 (2) — a second `..props: R` record parameter in one function.
pub const record_param_twice: []const u8 = "record-param-twice";
/// Decision 529 (2) — a record parameter's type that is no record.
pub const record_param_not_record: []const u8 = "record-param-not-record";
/// Decision 529 (2) — a name that is both a parameter and a field of the
/// record parameter's type.
pub const record_param_clash: []const u8 = "record-param-clash";
/// Decision 529 (2) — a record parameter beside a variadic one.
pub const record_param_variadic: []const u8 = "record-param-variadic";
/// Decision 529 (2) — a call label that names neither a parameter nor a field
/// of the record parameter's type, or an argument without a parameter.
pub const record_param_label: []const u8 = "record-param-label";
/// Decision 525 — a block `{ … }` (no `->`) handed where a function is
/// expected: a trailing `f(x) { … }`, an argument of a function-typed
/// parameter. Refused at the block.
pub const block_not_function: []const u8 = "block-not-function";
/// Decision 525 — a block whose value is `void` handed where `unknown` is
/// expected (`@print({ f(); })`). Refused at the block.
pub const block_void_value: []const u8 = "block-void-value";
/// Decision 525 — a `break <value>` that gives a block (a bare `{ … }`,
/// `comptime { … }`) its value: the block's value is its tail.
pub const block_break_value: []const u8 = "block-break-value";
/// Decision 525 — an arm of a `case` used as a value that answers nothing (its
/// last expression written with `;`, or a statement) beside arms that answer
/// a value. Refused at the arm.
pub const case_arm_no_value: []const u8 = "case-arm-no-value";
/// A module-level `fn` / `val` / `var` named like a primitive type
/// (`pub fn string()`): it took the type's name in its module
/// (`language-gaps.md` row "A function named like a primitive type shadows
/// the type in its module").
pub const primitive_type_name_taken: []const u8 = "primitive-type-name-taken";
/// Decisions 280 (0), 297 — the argument of a `comptime` parameter reads a
/// run-time value (a local, a parameter that is not `comptime`).
pub const comptime_arg_not_known: []const u8 = "comptime-arg-not-known";
/// Decision 331 — the value of a `comptime` has no construction in the emitted
/// program: a lambda capturing the block's state, a resource (a process, a
/// port, a reference), a non-finite float, a record no reached type declares.
/// Fires from `comptime/block_eval.zig`'s lift, located at the `comptime`.
pub const comptime_value_not_liftable: []const u8 = "comptime-value-not-liftable";
/// Decision 332 — a `comptime` whose value is (or holds) a `bigint`: the
/// compile-time evaluator holds a 64-bit integer (front `01-compiler/139`).
pub const comptime_bigint: []const u8 = "comptime-bigint";
/// Decision 332 (question 139-a) — a `bigint` widened to `unknown` or into a
/// union: no target tells it from another integer at run time.
pub const bigint_widened: []const u8 = "bigint-widened";
/// Decision 332 (question 139-a) — `is` / a type pattern over a `bigint`, or
/// testing for one: its type is static.
pub const bigint_type_test: []const u8 = "bigint-type-test";
/// Decision 519 — `@embed`'s path is absolute: a package's files are named
/// relative to its `botopink.json`.
pub const embed_path_absolute: []const u8 = "embed-path-absolute";
/// Decision 519 — `@embed`'s path leaves the package (a `..` segment).
pub const embed_path_outside_package: []const u8 = "embed-path-outside-package";
/// Decision 519 — the file `@embed` names is not in the package.
pub const embed_file_missing: []const u8 = "embed-file-missing";
/// Decision 519 — `@embed` in a compiler handed no reader (`compiler-web`).
pub const embed_no_reader: []const u8 = "embed-no-reader";
/// Decision 519 — `a.text()` over bytes that are not UTF-8.
pub const embed_text_not_utf8: []const u8 = "embed-text-not-utf8";
/// Decision 519 — `a.text()` over an `Asset` whose bytes are not known where
/// the call is checked (a parameter, a function's answer).
pub const embed_text_not_at_build: []const u8 = "embed-text-not-at-build";
/// Decision 519 — `@embed` takes one argument, the path.
pub const embed_arguments: []const u8 = "embed-arguments";
/// Decision 538 — `a.open()` on an `Asset` hands it to std's file system: the
/// module that writes it imports `io.fs`.
pub const embed_open_needs_fs: []const u8 = "embed-open-needs-fs";
/// Decision 346 — `Bytes` widened to `unknown`: erlang and beam hold `Bytes`
/// and `string` alike (a binary), so no run-time test tells them apart.
pub const bytes_widened: []const u8 = "bytes-widened";
/// Decision 346 — `is` / a type pattern over `Bytes`, or testing for it: its
/// type is static.
pub const bytes_type_test: []const u8 = "bytes-type-test";
/// Decisions 434, 341, 452 — a host function reached at comptime has neither
/// cell the comptime runtime answers by: an `@External.Wasm(std: "…")` cell
/// (std-wasm) or an `@External.Wasm(fn: …)` cell (an `@External.Erlang` cell
/// never runs at build). Fires from `comptime/host_cells.zig`, naming the
/// function and both cells.
pub const comptime_host_cell_unavailable: []const u8 = "comptime-host-cell-unavailable";
/// Decision 472 — an arithmetic error while a `comptime` runs: Erlang's
/// `badarith`, in Erlang's words, located at the expression and naming it. Fires
/// from `comptime/block_eval.zig`'s `badarithRefusal`.
pub const comptime_badarith: []const u8 = "comptime-badarith";
/// Decision 343 — a decorator body writes a module-level `var`: each
/// invocation is independent. Fires from `comptime/decorator_eval.zig`
/// `moduleVarWrite`, located at the write.
pub const decorator_writes_module_var: []const u8 = "decorator-writes-module-var";
/// Decision 297 — `x is type` where `x` is no `comptime x: V | type T`
/// parameter.
pub const is_type_outside_value_or_type: []const u8 = "is-type-outside-value-or-type";
/// Decision 297 — a read of `x` in the branch where `x is type` holds.
pub const type_arg_read: []const u8 = "type-arg-read";
/// A labelled argument in a call of a function VALUE (a parameter, a local, a
/// field): its type is positional and names no parameter (01).
pub const label_on_function_value: []const u8 = "label-on-function-value";
/// A call whose callee is a VALUE of a record, enum or primitive type — not a
/// function, not a constructor (`val g = G(a: "x"); g()`). Row 32 of
/// `language-gaps.md`: it used to answer the value's own type, and the
/// backends failed at run time (`g is not a function`, `{badfun, …}`).
pub const callee_not_a_function: []const u8 = "callee-not-a-function";
/// A second `val` / `var` of one name in one block, a parameter counting as
/// the first (decision 152, 01c-d). A binding in an inner block is a new
/// scope and may shadow.
pub const binding_redeclared: []const u8 = "binding-redeclared";
/// Decision 148 (lg-b) — a lambda that is neither a `forEach` body nor a
/// local closure called at statement position writes a captured `var`.
pub const captured_var_write: []const u8 = "captured-var-write";
/// Decision 207 — an inline parameter type where only a top-level `fn`'s
/// parameter takes one, or two of them on one function, or a field named
/// like another parameter of its function.
pub const inline_type_position: []const u8 = "inline-type-position";
/// A program's own primitive behavior (`behavior String { … }`) extends std's
/// and may not declare a member std's already declares.
pub const behavior_member_redeclared: []const u8 = "behavior-member-redeclared";
/// A use of an imported name the import resolved to two different
/// declarations (`00 · 01-std`: the refusal of a duplicate `pub` name belongs
/// to the consumer's unqualified use).
pub const ambiguous_import_use: []const u8 = "ambiguous-import-use";
/// A use of an imported name whose module was refused earlier in the build:
/// the name is not unbound, its module did not check. Located at the import
/// item, naming the module — the module's own error is reported there.
pub const import_of_failed_module: []const u8 = "import-of-failed-module";
/// `import {testing.mocks.mock} from "std"` — a std decorator imported as a
/// leaf: the code it emits reaches its module through the annotation's handle,
/// so it is imported through the module (`#[mocks.mock]`).
pub const std_decorator_leaf_import: []const u8 = "std-decorator-leaf-import";
/// A method a primitive receiver's interface does not declare
/// (`"abc".toUpperCase()` — `String` declares `toUpper`). Used to type as a
/// fresh variable and reach the host under its own spelling (pending 0203-a,
/// answered (b)): refused, with the declared method whose host spelling or
/// name is nearest.
pub const unknown_primitive_method: []const u8 = "unknown-primitive-method";
/// A `#[@Family…]` annotation whose family the compiler does not read
/// (`#[@TotallyMadeUp.Nonsense(whatever: 42)]`). It used to parse, check and
/// be dropped (decision 15's failure mode; front 17 step 3's recorded row).
pub const unknown_annotation: []const u8 = "unknown-annotation";

/// RC6 — `use <hook>()` where `<hook>` is not a hook `@Component<R>` (a
/// component, or no `@Component` at all).
pub const use_of_non_context_fn: []const u8 = "use-of-non-context-fn";

/// RC7 (decisions 88, 104, 118) — `use` in a body whose fn does not return
/// `@Component<R>`, or in a nested closure of one: only that body
/// activates a hook.
pub const use_without_context_effect: []const u8 = "use-without-context-effect";

/// Decision 357 — a `use` that is not at the top level of its `@Component`
/// body: inside an `if` / `else`, a `case` arm, a loop, a lambda, a `catch`
/// handler, a short-circuit operand, or after a statement that may return
/// early. Named construct, located at the `use`.
pub const use_not_top_level: []const u8 = "use-not-top-level";

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

/// RG3 — required generic argument missing (e.g. `@Result<T>`).
pub const generic_required_arg_missing: []const u8 = "generic-required-arg-missing";

/// RG4 — skipped middle generic argument (`@Result<i32, , i64>`).
pub const generic_arg_skip_forbidden: []const u8 = "generic-arg-skip-forbidden";

/// RG5 — more generic arguments than a builtin wrapper declares
/// (`@Task<i32, string>`: a Task has no error parameter, decision 120, and an
/// argument nothing reads is refused, not dropped).
pub const generic_arg_count_exceeded: []const u8 = "generic-arg-count-exceeded";

/// §A3 — a host `declare fn -> @Result<…>` whose `#[@External.<Target>("<template>")]`
/// body is missing the `ok` or `error` branch on at least one target.
/// The template owns the wrapper shape — both branches must be present so
/// callers see a complete `{ok, _} | {error, _}` lowering.
pub const result_template_shape_mismatch: []const u8 = "result-template-shape-mismatch";

/// STD-001 — a call of a std function that reaches a host declaration with no
/// `#[@External.<target>( …)]` for the active target (the function itself, or
/// one of its module's functions its body reaches). Fires when `Env.target !=
/// null`, at the call; an import is never refused (decision 518 (4),
/// `infer.zig` `checkStdCall`).
pub const std_unsupported_on_target: []const u8 = "std-unsupported-on-target";

/// Decision 107 — two import items bind one local name (`import {url.parse,
/// json.parse}`), in either spelling. Located at the second item; an alias
/// on either side (`url.parse as parseUrl`) is the remedy. A repeated
/// identical item (an `@emit` contribution re-importing what its module
/// already imports) is not a collision.
pub const import_name_collision: []const u8 = "import-name-collision";

/// Decision 206 — `import {…} from "<name>"` where `<name>` is a module of the
/// importing package and no package: `from` names a package (std, a bundled
/// package, a declared dependency), and a module of this package is imported
/// by its path inside the braces. Located at the source string; the fix-it is
/// the brace form (`import {geometry.area};`). The CLI's module-tree resolver
/// raises it — it is the one stage that knows which modules are the package's.
pub const module_import_with_from: []const u8 = "module-import-with-from";

/// Decision 337 (1) — an import item with no `from` whose first segment names
/// no module of the package (`import {splitPath};`, the shorthand). Located at
/// the item; the fix is written: the path of the one module of the package
/// that declares the name `pub` (`write import {config.splitPath};`), the
/// candidates when several do, `unresolved import` when none does.
pub const shorthand_import: []const u8 = "shorthand-import";

/// Decision 337 (2) — `import {config};` in the module that declares `mod
/// config;`: `mod` already binds the namespace there. Located at the item;
/// the fix is to delete it.
pub const redundant_module_import: []const u8 = "redundant-module-import";

/// Decision 337 (2) — `mod1.mod2` through a namespace from outside `mod1`'s
/// subtree, where `mod1` declares `mod mod2;` (not `pub`). Located at `mod2`.
pub const private_module: []const u8 = "private-module";

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

// ── type aliases (decision 118 rule 1) ───────────────────────────────────────

/// `Parser<i32, string>` against `type Parser<T> = …;`, or a bare `Parser`:
/// an alias is written with exactly as many arguments as it declares.
pub const type_alias_arity: []const u8 = "type-alias-arity";

/// `type A = B; type B = A[];` — an alias whose expansion reaches itself.
/// An alias is a name for a type that already exists; a recursive type is a
/// `type` declaration.
pub const type_alias_recursive: []const u8 = "type-alias-recursive";

/// `type Point = …;` in a module that already has a `type Point(…)` (or a
/// primitive's name): one name, one type.
pub const type_alias_name_taken: []const u8 = "type-alias-name-taken";

// ── decision 280 — typed comptime decorator arguments ───────────────────────

/// A decorator parameter (after its `@Decl`) written without `comptime`: a
/// decorator's arguments exist only while the program compiles.
pub const decorator_param_not_comptime: []const u8 = "decorator-param-not-comptime";

// ── decision 364 — every `comptime` parameter is `comptime x: @Expr<T>` ─────

/// `comptime x: T` without `@Expr` (other than `@Decl`), at the parameter.
pub const comptime_param_not_expr: []const u8 = "comptime-param-not-expr";

/// `x.value` of an `@Expr` of a function: its body is not called while the
/// program compiles.
pub const expr_value_of_function: []const u8 = "expr-value-of-function";

/// `x.value` of an `@Expr` of a type: the type is not inspected while the
/// program compiles.
pub const expr_value_of_type: []const u8 = "expr-value-of-type";

/// A decorator argument not known while the program compiles whose parameter
/// the body reads (`key.value`), at the argument.
pub const decorator_value_not_comptime: []const u8 = "decorator-value-not-comptime";

/// A template reads `q.value` of an argument with a `${…}` hole: not known
/// while the program compiles, refused at the argument.
pub const template_value_not_known: []const u8 = "template-value-not-known";

/// A method of a `comptime` parameter's `@Expr` other than `.fail(…)` in a
/// decorator: the parameter answers `.value`.
pub const expr_param_method: []const u8 = "expr-param-method";

/// A `comptime` parameter with a default outside a decorator: no call site
/// fills it (decision 280 (0) gives the default to decorators).
pub const comptime_default_outside_decorator: []const u8 = "comptime-default-outside-decorator";

// ── decision 216 — what a decorator produces ───────────────────────────────

/// `decl.addMember(source)` from a decorator on a `fn`: a member belongs to a
/// type, and a function has no body to add it to.
pub const decorator_member_without_type: []const u8 = "decorator-member-without-type";

/// `decl.addMember` naming a member the type already has (written by hand or
/// added by another decorator): a decorator adds, it never replaces.
pub const decorator_member_duplicate: []const u8 = "decorator-member-duplicate";

/// `decl.addMember(source)` whose source is not exactly one `fn` member.
pub const decorator_member_not_one_fn: []const u8 = "decorator-member-not-one-fn";

// ── decision 316 — a decorator wraps the function it annotates ─────────────

/// `decl.wrapWith(f)` from a decorator on anything but a function or a method
/// (a `type`, a field, a `val`): only a function's call can be wrapped.
pub const decorator_wrap_without_function: []const u8 = "decorator-wrap-without-function";

/// `decl.wrapWith(f)` whose `f` is not a lambda written at the call: the
/// wrapper is the program's code, where the parameters' `@Expr`s are spliced.
pub const decorator_wrap_not_lambda: []const u8 = "decorator-wrap-not-lambda";

/// A wrapper answering another type than the wrapped function's return, as
/// the `@Decl<fn(…) -> R>` pattern names it.
pub const decorator_wrap_type: []const u8 = "decorator-wrap-type";

/// A wrapped function, or the type owning a wrapped method, with type
/// parameters: the call value is typed by the function's own signature.
pub const decorator_wrap_generic: []const u8 = "decorator-wrap-generic";

// ── decision 370 (2) — a typed member carrying the parameters' `@Expr`s ─────

/// `decl.addMember(name, f)` whose `f` is not a function expression written at
/// the call: the member's body is where the parameters' `@Expr`s are spliced.
pub const decorator_member_not_fn: []const u8 = "decorator-member-not-fn";

/// A member function with a parameter whose type is not written.
pub const decorator_member_fn_untyped: []const u8 = "decorator-member-fn-untyped";

/// A member function reading the decorator's `@Decl` handle or a local of the
/// decorator's body: those exist while the program compiles, the member runs
/// with the program.
pub const decorator_member_captures: []const u8 = "decorator-member-captures";

/// A member function's types at one annotation: a `self` that is not the type
/// the member joins, or a type parameter the annotation leaves unbound.
pub const decorator_member_type: []const u8 = "decorator-member-type";

/// `decl.addType` from a decorator on a `fn`: an associated type belongs to a type.
pub const decorator_type_without_owner: []const u8 = "decorator-type-without-owner";

/// `decl.addType` with a name that is not one upper-case identifier.
pub const decorator_type_name: []const u8 = "decorator-type-name";

/// A second associated type of one name on one owner, or a name the owner
/// already answers (a variant, a member) or the module already declares.
pub const decorator_type_duplicate: []const u8 = "decorator-type-duplicate";

/// `decl.addType(name, source)` whose source is not the shape of one type.
pub const decorator_type_not_one_type: []const u8 = "decorator-type-not-one-type";

/// `Type.f(…)` on a record-shaped `type` that declares no associated fn `f`
/// (by hand or through a decorator's `decl.addMember`): a type's members are
/// closed, so a call naming a member it does not have is refused where it is
/// written, not left to the backend.
pub const unknown_associated_fn: []const u8 = "unknown-associated-fn";

/// `@TypeInfo.all` written without its labels, with an unknown one, or with
/// `member:` where it does not apply.
pub const typeinfo_all_arguments: []const u8 = "typeinfo-all-arguments";

/// One query over a decorator carried by functions and by types.
pub const typeinfo_all_mixed: []const u8 = "typeinfo-all-mixed";

/// Decision 372 — `@TypeInfo.all(with: d)` in a module where `#[d]` reads
/// `.hooks` and annotates a declaration of that module: `d` runs after the
/// module's bodies, so the answer could not carry the meta it sets. Refused at
/// the decorator's name in `with:` (question s23-i).
pub const typeinfo_all_hooks_reader: []const u8 = "typeinfo-all-hooks-reader";

/// A query over types without `member:` — a type is no value.
pub const typeinfo_all_needs_member: []const u8 = "typeinfo-all-needs-member";

/// A declaration the query answers that is not `pub` (it is reached through
/// an import the answer adds).
pub const typeinfo_all_private: []const u8 = "typeinfo-all-private";

/// An import of a module that reads `@TypeInfo.all`.
pub const typeinfo_all_imported: []const u8 = "typeinfo-all-imported";

/// Decision 551 — a call that leaves out a `comptime` parameter whose default
/// is a `@TypeInfo.all(…)` query, written outside the root package's root
/// module (s23-i (d) (1)): the default answers for the whole program.
pub const typeinfo_all_default_outside_root: []const u8 = "typeinfo-all-default-outside-root";

/// Decision 353 — a template body reads `value` of a catalogue entry: a
/// declaration of the program is no value at build.
pub const typeinfo_all_template_value: []const u8 = "typeinfo-all-template-value";

/// Decision 353 — a template's answer changes the catalogue it read: the
/// declarations its expansion builds add or drop an entry of the answer.
pub const typeinfo_all_template_unstable: []const u8 = "typeinfo-all-template-unstable";

/// `decl.setMeta` from a field's or a method's decorator: meta describes a
/// top-level declaration, the one `@typeInfo` reflects.
pub const decorator_meta_on_member: []const u8 = "decorator-meta-on-member";

/// A decorator setting one of its keys twice on one declaration.
pub const decorator_meta_duplicate: []const u8 = "decorator-meta-duplicate";

/// Decision 372 — `@emit`, `addMember` or `addType` in a decorator that reads
/// `.hooks` (in its body or a function it reaches): such a decorator runs
/// after the module's bodies are inferred and may only record meta or refuse.
/// Refused at the call.
pub const decorator_hooks_output: []const u8 = "decorator-hooks-output";

/// Decision 253 — `@typeInfo.all(…)`: the catalogue is the static method
/// `@TypeInfo.all` of the builtin type `TypeInfo`, refused where it is written.
pub const typeinfo_all_on_function: []const u8 = "typeinfo-all-on-function";

/// Decision 248 — the lowercase `@typeinfo(X)` / `@typeinfo.all(…)`: the one
/// reflection builtin is `@typeInfo`, its catalogue `@TypeInfo.all` (253).
pub const typeinfo_lowercase: []const u8 = "typeinfo-lowercase";

/// `@typeInfo(X).<m>` naming no reflection member (or `.meta` / `.meta.<d>`
/// left without its key).
pub const typeinfo_unknown_member: []const u8 = "typeinfo-unknown-member";

/// `@typeInfo(X)` where `X` names no declaration of the module or its imports.
pub const typeinfo_unknown_declaration: []const u8 = "typeinfo-unknown-declaration";

/// `@typeInfo(X).meta.<decorator>.<key>` naming a key that decorator did not set.
pub const typeinfo_meta_missing: []const u8 = "typeinfo-meta-missing";

// ── decision 298 — typed meta, keyed by its type; 370 (1) its `@Expr` fields ──

/// Decision 298 — a second `decl.setMeta(v)` of one record type on one
/// declaration, or a type recorded by both `setMeta` and `addMeta` there:
/// refused at the annotation whose decorator recorded the second.
pub const decorator_meta_twice: []const u8 = "decorator-meta-twice";

/// Decision 302 — an annotation run over a tag (`q.annotate`) that calls
/// `decl.addMember`, `decl.addType`, `@emit` or the string `decl.setMeta`: on
/// a tag its one channel is typed meta; refused at the annotation.
pub const tag_annotation_output: []const u8 = "tag-annotation-output";

/// Decision 298 — `decl.setMeta(v)` / `decl.addMeta(v)` whose value is not a
/// record type's constructor written at the call (the type is the key, read
/// where the decorator is declared): refused at the argument.
pub const decorator_meta_not_record: []const u8 = "decorator-meta-not-record";

/// Decision 298 — a field of a meta record whose type is neither data the
/// compiler rebuilds where the meta is read (a string, an integer, a float, a
/// `bool`, a variant of an enum without payloads, an array or an optional of
/// those) nor `@Expr<T>` (370 (1)): refused at the call, naming the field.
pub const decorator_meta_field_type: []const u8 = "decorator-meta-field-type";

/// Decision 370 (1) — an `@Expr<T>` field of a meta record given anything but
/// one of the decorator's `comptime x: @Expr<T>` parameters, or such a
/// parameter given to a field that is no `@Expr<T>` (read `x.value` there):
/// refused at the argument.
pub const decorator_meta_expr_arg: []const u8 = "decorator-meta-expr-arg";

/// Decision 298 — `meta(T)` / `metaAll(T)` whose `T` names no record type of
/// the module or its imports.
pub const typeinfo_meta_type: []const u8 = "typeinfo-meta-type";

/// Decision 298 — `@typeInfo(X).meta(T)` where the declaration holds more than
/// one `T` (recorded with `decl.addMeta`): read them with `metaAll(T)`.
pub const typeinfo_meta_several: []const u8 = "typeinfo-meta-several";

/// Decision 298 — `d.meta(T)` / `d.metaAll(T)` on a `Declared` inside a
/// decorator's or a template's body: the catalogue's typed meta is run-time
/// data of the program, absent while it compiles.
pub const typeinfo_meta_at_build: []const u8 = "typeinfo-meta-at-build";

/// Decision 298 with 372 — a typed meta read of a declaration of this module
/// that a `.hooks`-reading decorator annotates, before that decorator ran.
pub const typeinfo_meta_hooks_pending: []const u8 = "typeinfo-meta-hooks-pending";

// ── decision 376 — every function's stage ──────────────────────────────────

/// Decision 376 (2) — a function that reaches a build-only resource and a
/// run-time one (directly or through its calls): refused at the second,
/// naming the first. A `comptime` separates them.
pub const build_and_run: []const u8 = "build-and-run";

/// Decision 376 (5), with 562 — a run-time value reached where the build
/// decides: a loop's bound or a condition of a function expanded at its call
/// site that needs one. Refused at it, naming the value.
pub const run_in_build: []const u8 = "run-in-build";

/// Decision 379 (1) — a second `createContext(…)` declaration of one type's
/// default in the program: refused at the second, naming the first.
pub const context_declared_twice: []const u8 = "context-declared-twice";

/// Decision 416 (1) — `use inject(T)` whose `T` is no record type (a
/// behavior is read with `use context`): refused at the argument.
pub const inject_not_record: []const u8 = "inject-not-record";

/// Decision 416 (2) — `createContext(value, B)` whose `value` does not
/// implement `B`, or whose `B` names no behavior: refused at the argument.
pub const context_behavior_not_implemented: []const u8 = "context-behavior-not-implemented";

// ── decision 553 — the body markers ──────────────────────────────────────────

/// Decision 553 (2) — a marker whose return type is not the wrapper it names:
/// a declaration's written return (the parser, `print.zig`), a marked lambda's
/// expected function type (147, the checker). Located at the marker.
pub const marker_type_mismatch: []const u8 = "marker-type-mismatch";
/// Decision 553 (1) — `iter { … }`, `async iter { … }`, `component { … }`
/// without `->`: refused by the parser (`print.zig`).
pub const marker_without_arrow: []const u8 = "marker-without-arrow";
/// Decision 553 (4), 147 — a marked lambda with no expected function type and
/// no written return type. Located at the marker.
pub const marker_lambda_without_expected_type: []const u8 = "marker-lambda-without-expected-type";
/// Decision 553 (1) — a marker on a bodyless declaration: refused by the
/// parser (`print.zig`, open point B-116-b).
pub const marker_on_declaration: []const u8 = "marker-on-declaration";
/// Decision 553 (1) — a `component { -> … }` lambda is parsed and checked;
/// its lowering is 144 B-116 (iii)'s (open point B-116-e), so it is refused
/// where it would reach a backend, located at the marker.
pub const component_lambda_not_lowered: []const u8 = "component-lambda-not-lowered";

// ── Lookup table — every code (skipping aliases & reserved-empties) ─────────

pub const all_codes = [_][]const u8{
    effect_annotation_removed,
    effect_type_removed,
    iterator_error_param_removed,
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
    context_marker_removed,
    use_outside_render_tree,
    context_provide_outside_component,
    context_not_declared,
    render_scope_construction,
    context_provide_after_render,
    context_hook_without_use,
    variadic_spread,
    call_spread,
    record_spread_type,
    record_spread_partial,
    record_spread_missing_field,
    record_spread_arguments,
    record_param_twice,
    record_param_not_record,
    record_param_clash,
    record_param_variadic,
    record_param_label,
    variadic_label,
    use_of_non_context_fn,
    use_without_context_effect,
    use_not_top_level,
    generic_required_arg_missing,
    generic_arg_skip_forbidden,
    generic_arg_count_exceeded,
    result_template_shape_mismatch,
    std_unsupported_on_target,
    import_name_collision,
    module_import_with_from,
    shorthand_import,
    redundant_module_import,
    private_module,
    import_alias_on_activation,
    std_root_imports_io,
    fn_param_default_trailing_only,
    fn_param_positional_after_named,
    fn_param_default_arity_mismatch,
    enum_variant_arity_mismatch,
    fn_param_default_trailing_only_parse,
    fn_param_arity_exceeded,
    optional_operator_never_null,
    optional_has_no_methods,
    nullish_beside_logical,
    namespace_type_construction,
    derived_type_field_string,
    derived_type_fields,
    derived_type_source_not_record,
    derived_type_merge_duplicate,
    derived_type_arguments,
    derived_type_outside_val,
    result_member_not_a_method,
    break_value_outside_generator,
    break_outside_loop,
    continue_outside_loop,
    defer_return,
    defer_break,
    defer_continue,
    defer_yield,
    defer_await,
    for_over_condition,
    for_over_stream,
    for_await_expects_stream,
    generator_loop_closed_scope,
    yield_label_not_generator,
    refutable_val_pattern,
    type_alias_arity,
    type_alias_recursive,
    type_alias_name_taken,
    callee_not_a_function,
    binding_redeclared,
    block_not_function,
    block_void_value,
    block_break_value,
    case_arm_no_value,
    primitive_type_name_taken,
    comptime_arg_not_known,
    comptime_value_not_liftable,
    comptime_bigint,
    bigint_widened,
    bigint_type_test,
    embed_path_absolute,
    embed_path_outside_package,
    embed_file_missing,
    embed_no_reader,
    embed_text_not_utf8,
    embed_text_not_at_build,
    embed_arguments,
    embed_open_needs_fs,
    bytes_widened,
    bytes_type_test,
    comptime_host_cell_unavailable,
    comptime_badarith,
    decorator_writes_module_var,
    is_type_outside_value_or_type,
    type_arg_read,
    captured_var_write,
    inline_type_position,
    behavior_member_redeclared,
    decorator_param_not_comptime,
    comptime_param_not_expr,
    expr_value_of_function,
    expr_value_of_type,
    decorator_value_not_comptime,
    expr_param_method,
    template_value_not_known,
    comptime_default_outside_decorator,
    decorator_member_without_type,
    decorator_member_duplicate,
    decorator_member_not_one_fn,
    decorator_wrap_without_function,
    decorator_wrap_not_lambda,
    decorator_wrap_type,
    decorator_wrap_generic,
    decorator_member_not_fn,
    decorator_member_fn_untyped,
    decorator_member_captures,
    decorator_member_type,
    decorator_type_without_owner,
    decorator_type_name,
    decorator_type_duplicate,
    decorator_type_not_one_type,
    unknown_associated_fn,
    typeinfo_all_arguments,
    typeinfo_all_mixed,
    typeinfo_all_hooks_reader,
    typeinfo_all_needs_member,
    typeinfo_all_private,
    typeinfo_all_imported,
    typeinfo_all_default_outside_root,
    typeinfo_all_template_value,
    typeinfo_all_template_unstable,
    decorator_meta_on_member,
    decorator_meta_duplicate,
    decorator_hooks_output,
    typeinfo_all_on_function,
    typeinfo_lowercase,
    typeinfo_unknown_member,
    typeinfo_unknown_declaration,
    typeinfo_meta_missing,
    decorator_meta_twice,
    tag_annotation_output,
    decorator_meta_not_record,
    decorator_meta_field_type,
    decorator_meta_expr_arg,
    typeinfo_meta_type,
    typeinfo_meta_several,
    typeinfo_meta_at_build,
    typeinfo_meta_hooks_pending,
    build_and_run,
    run_in_build,
    context_declared_twice,
    inject_not_record,
    context_behavior_not_implemented,
    template_annotation_not_template,
    template_annotation_call_form,
    template_annotation_without_decl,
    template_annotation_only,
    template_call_unexpanded,
    template_lookup_decl_write,
    template_lookup_meta_expr_field,
    template_build_outside_bound,
    marker_type_mismatch,
    marker_without_arrow,
    marker_lambda_without_expected_type,
    marker_on_declaration,
    component_lambda_not_lowered,
};

test "every reserved code has a stable, non-empty spelling" {
    for (all_codes) |c| try std.testing.expect(c.len > 0);
}

test "codes are unique (the table is the contract)" {
    for (all_codes, 0..) |c, i| {
        for (all_codes[i + 1 ..]) |d| try std.testing.expect(!std.mem.eql(u8, c, d));
    }
}

/// 1.0.5 decision 31 — `any` is deleted; a written `any` names `unknown`.
pub const any_type_removed: []const u8 = "any-type-removed";

/// Decision 329 — `Type()` on a namespace type (`type Type { fn … }`): it has
/// no field list and no value; its functions are called through it.
pub const namespace_type_construction: []const u8 = "namespace-type-construction";

/// Decision 307 — a field of `Type.pick` / `Type.omit` written as a string
/// (`"title"`): a field is `Type.Field<T>`, written `.title`
/// (`comptime/derived_types.zig`).
pub const derived_type_field_string: []const u8 = "derived-type-field-string";

/// Decision 307 — `Type.pick` / `Type.omit` with no field, a field named
/// twice, or an `omit` leaving no field.
pub const derived_type_fields: []const u8 = "derived-type-fields";

/// Decision 307 — a derived type's source is not a record type: an enum, a
/// namespace type, a primitive, a generic record, a value.
pub const derived_type_source_not_record: []const u8 = "derived-type-source-not-record";

/// Decision 307 — `Type.merge(A, B)` with a field on both sides: nothing
/// overrides silently.
pub const derived_type_merge_duplicate: []const u8 = "derived-type-merge-duplicate";

/// Decision 307 — a `Type` function called with the wrong number of
/// arguments, a labelled one or a trailing lambda.
pub const derived_type_arguments: []const u8 = "derived-type-arguments";

/// Decision 307 — a derivation anywhere but as the whole initializer of a
/// module-level `val` with no type annotation (a local, a default, a `var`).
pub const derived_type_outside_val: []const u8 = "derived-type-outside-val";

/// Decision 330 (2) — `??`, `?.`, `?.[]`, `?.()` or the postfix `!` over a
/// value whose type is not `?T`: it is never `null`.
pub const optional_operator_never_null: []const u8 = "optional-operator-never-null";

/// Decision 330 — `.map` / `.flatMap` / `.unwrapOr` (any method) on a `?T`:
/// the optional has no methods; its surface is `??`, `?.`, `?.[]`, `?.()`, `!`.
pub const optional_has_no_methods: []const u8 = "optional-has-no-methods";

/// Decision 330 (4) — `??` beside `&&` / `||` without parentheses.
pub const nullish_beside_logical: []const u8 = "nullish-beside-logical";

// ── decision 311 — the template annotation `#[f "…"]` ───────────────────────

/// Decision 311 — `#[f "…"]` naming a function that is not a template
/// function (a decorator, an ordinary function) or naming nothing: refused at
/// the annotation.
pub const template_annotation_not_template: []const u8 = "template-annotation-not-template";

/// Decision 311 — `#[f(…)]` / `#[f]` naming a template function: a template
/// is written as an annotation `#[f "…"]`; refused at the annotation.
pub const template_annotation_call_form: []const u8 = "template-annotation-call-form";

/// Decision 311, question s29-a — `#[f "…"]` naming a template function that
/// declares no `comptime decl: @Decl<…>` beside its literal: what it builds
/// has nowhere to go; refused at the annotation.
pub const template_annotation_without_decl: []const u8 = "template-annotation-without-decl";

/// Decision 311, question s29-a — `f "…"` calling a template function that
/// takes the annotated declaration's `@Decl`: it is written only as an
/// annotation; refused at the call.
pub const template_annotation_only: []const u8 = "template-annotation-only";

/// Decision 425 — a call of a template function that inference did not
/// expand: it would reach a backend as a run-time call of a function that
/// exists only at build. Refused at the call.
pub const template_call_unexpanded: []const u8 = "template-call-unexpanded";

/// Decision 425 — a template function named without a call (`val f = shout;`,
/// an argument): it exists only at build, so it is no value. Refused at the
/// reference.
pub const template_function_value: []const u8 = "template-function-value";

/// Decision 415 (2) — `setMeta` / `addMeta` / `addMember` / `addType` /
/// `wrapWith` on a declaration a template body looked up (`q.lookup`): the
/// handle is read-only. Refused at the call.
pub const template_lookup_decl_write: []const u8 = "template-lookup-decl-write";

/// Decision 415 (3) — `d.meta(T)` / `d.metaAll(T)` in a template body where
/// the record `T` has an `@Expr` field (370 (1)): that field is code the
/// program runs, not data the build has. Refused at the read, naming it.
pub const template_lookup_meta_expr_field: []const u8 = "template-lookup-meta-expr-field";

/// Decision 426 (2) — the code a template built is of a type outside the
/// template's answer (the signature's `-> @Expr<…>`, a bound). Refused at the
/// template's `build`.
pub const template_build_outside_bound: []const u8 = "template-build-outside-bound";
