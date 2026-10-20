----- SOURCE CODE -- main.bp
```botopink
pub type Probe(n: i32) {
    #[compiler.external(.Erlang("""element(2, $0)"""))]
    pub declare fn raw(self: Self) -> i32;
}

pub fn main() -> void {
    print(Probe(n: 1).raw());
}

import {io.terminal.print, compiler} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `Probe.raw` has no implementation for the wasm backend
  ┌─ :7:23
  │
7 │     print(Probe(n: 1).raw());
  │                       ^
```

