# Decision 383 — `#[emilia(…)]` records `styled`'s `StyledMeta(layer: Layer, className: string, rules: string)`, one per tag.

`#[emilia(…)]` computes a class and its rules at build and records them as `styled`'s `StyledMeta(layer, className,
rules)`, the type a renderer reads beside `ClassName` without naming emilia. The example writes a small `emilia` of its
own, in [draft/comptime/emilia.bp](draft/comptime/emilia.bp), over the annotated declaration rather than a markup tag:
the tokens are one list whose order is the class, the class is the layer's prefix plus `contentHash` over the rules, and
the meta's `layer` is typed with `Layer`. It records with `setMeta`, not `addMeta`: one value of the type per
declaration. `Card` takes one `#[emilia]` and its meta reads back its class and rules. `Banner` writes two, and the
second is refused at its annotation, `decorator-meta-twice` — the tokens belong in one list —, so the program does not
run.

Cells that also bear on it: `modules/decorator/cases/decorator_same_refuses_mark`.

[draft/main.bp](draft/main.bp)
