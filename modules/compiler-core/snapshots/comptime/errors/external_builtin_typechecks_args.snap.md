----- SOURCE CODE
#[compiler.external(.Python("string", "length"))]
pub declare fn str_length(s: string) -> i32;

import {compiler} from "std";

----- ERROR
error: `.Python(…)` names a variant by its leading dot, and nothing here says which type declares it
  ┌─ main.bp:1:21
  │
1 │ #[compiler.external(.Python("string", "length"))]
  │                     ^

  hint: give the position a type that declares `Python` (`val v: T = .Python(…);`, a typed parameter or array), or write `T.Python(…)`
