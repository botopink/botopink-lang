----- SOURCE CODE
#[compiler.external(.Beam("math", "sqrt"))]
pub declare fn root(x: f64) -> f64;

import {compiler} from "std";

----- ERROR
error: `.Beam(…)` names a variant by its leading dot, and nothing here says which type declares it
  ┌─ main.bp:1:21
  │
1 │ #[compiler.external(.Beam("math", "sqrt"))]
  │                     ^

  hint: give the position a type that declares `Beam` (`val v: T = .Beam(…);`, a typed parameter or array), or write `T.Beam(…)`
