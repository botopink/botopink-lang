# Decision 774 — `stage` and `beamMemory` are members of `compiler`, as `external` is — `#[compiler.stage(.Any)]`, `#[compiler.beamMemory(.Ets)]` — one home for every annotation the compiler itself reads (606 (4)); `memo` is a function of std's `hooks` module, imported as any std function (582's forms) and written in a `use`.

`compiler` is the one home of every annotation the compiler itself reads. `stage` and `beamMemory` are members of
it, as `external` is, so they are written `#[compiler.stage(…)]` and `#[compiler.beamMemory(…)]`, never bare. `memo`
is not an annotation. It is a function of std's `hooks` module, imported like any std function and written in a `use`.

In the example, `double` is `#[compiler.stage(.Any)]`, so the `comptime` call folds at build and prints `42`. The
same function runs again at run time. `hits` is `#[compiler.beamMemory(.Ets)]`: an ETS entry on erlang and beam, an
ordinary module `var` elsewhere, and it prints `2`. The component `Badge` imports `memo` from `hooks` and writes
`use memo({ -> … })`; its rendered text prints `badge a`.

Cells that also bear on it:
`modules/annotation/cases/annotation_family_misspelled` (a misspelled
`compiler.` member refused), `modules/beam/cases/beam_memory_annotations`,
`modules/memo_computed_once_per_instance`.

[draft/main.bp](draft/main.bp)
