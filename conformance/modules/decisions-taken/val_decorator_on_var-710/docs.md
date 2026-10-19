# Decision 710 — A user decorator on a module `var` is refused at the annotation (`` `#[mark]` annotates the module `var` `count`, and a decorator runs on a `val`, never on a `var` ``); `#[beamMemory(…)]` is untouched.

Three module-level declarations carry an annotation. `#[beamMemory(.PersistentTerm)]` on the `var` `mode` is untouched by the decision: it only picks how the BEAM holds that `var`, and has no effect elsewhere. `#[mark]` on the `val` `limit` runs, over a handle of kind `Val`, and records its meta. `#[mark]` on the `var` `count` is refused at the annotation — `` `#[mark]` annotates the module `var` `count`, and a decorator runs on a `val`, never on a `var` `` —, because a `var` has no build value for a decorator to read. The program stops there; without that annotation it would print `prod 10 1`.

Cells in this repository that also bear on it: `modules/val_decorator_on_var`, `modules/val_decorator_runs`.

[draft/main.bp](draft/main.bp) · [draft/comptime/marks.bp](draft/comptime/marks.bp)
