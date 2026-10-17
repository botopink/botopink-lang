----- SOURCE CODE
#[@external(.Beam("math", "sqrt"))]
pub declare fn root(x: f64) -> f64;

----- ERROR
error: `.Beam(…)` names a variant by its leading dot, and nothing here says which type declares it
  ┌─ main.bp:1:13
  │
1 │ #[@external(.Beam("math", "sqrt"))]
  │             ^

  hint: give the position a type that declares `Beam` (`val v: T = .Beam(…);`, a typed parameter or array), or write `T.Beam(…)`
