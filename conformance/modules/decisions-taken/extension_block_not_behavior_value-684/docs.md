# Decision 684 — A type that implements a behavior only through an extension block (`Sym implement B for T`) is not a value of that behavior: the block adds methods where it is visible, and `T` is refused for a `B` parameter, return or context.

An extension block adds methods to a type where the block is visible; it does not make the type a value of the
behavior it names. In [draft/shapes.bp](draft/shapes.bp), `SquareArea implement Shape for Square` gives `Square` an
`area`; `main` activates the block by name, `shapes.SquareArea*`, and `Square(side: 2.0).area()` calls it. `Circle`
writes `implement Shape` on its own declaration, so a `Circle` is a `Shape` and `total` takes one.
`total(Square(side: 2.0))` is refused at the argument: `Square` is no `Shape`, the block's `implement` clause being
written on the block, not on `Square` — no backend dispatches a behavior call to a block. The same refusal stands for a
return or a context of the behavior's type.

Cells that also bear on it: `modules/implement/cases/implement_clause_for`.

[draft/main.bp](draft/main.bp)
