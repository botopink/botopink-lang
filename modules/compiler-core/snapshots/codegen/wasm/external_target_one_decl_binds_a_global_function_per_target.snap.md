----- SOURCE CODE -- main.bp
```botopink
#[compiler.external(.Erlang("math:floor($0)"), .JavaScript("Math.floor($0)"))]
pub declare fn floor(n: f64) -> f64;

fn main() -> void {
    print(floor(1.7));
}

import {io.terminal.print, compiler} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `floor` has no implementation for the wasm backend
  ┌─ :5:11
  │
5 │     print(floor(1.7));
  │           ^
```

