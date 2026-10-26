# Decision 27 — Who declares `behavior Display`?

The program declares no `behavior Display` of its own. `Money` writes `implement Display` with no import, and the
behavior it implements is the one std declares, ambient like every other builtin behavior. `print` consults that
declaration before its per-type formatter, so `Money(cents: 1250)` prints `1250 cents`, and a list of them prints each
element through its own `display()`. `Plain` implements nothing and prints in the default record form. The two `Dict`
lines show std using its own declaration: `Dict` implements the same `Display`, printing its pairs in insertion order
with string keys quoted, and a `Money` value inside the dictionary still prints as `4210 cents`. All four backends read
this one declaration, so every target prints the same lines.

Cells in this repository that also bear on it: `modules/display/cases/display_print`.

[draft/main.bp](draft/main.bp)
