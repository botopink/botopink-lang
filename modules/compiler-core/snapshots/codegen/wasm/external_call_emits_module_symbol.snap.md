----- SOURCE CODE -- main.bp
```botopink
#[compiler.external(.Erlang("filename:basename($0)"), .JavaScript("""require("node:path").basename($0)"""))]
pub declare fn basename(p: string) -> string;

fn main() -> void {
    print(basename("/tmp/notes.txt"));
}

import {io.terminal.print, compiler} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `basename` has no implementation for the wasm backend
  ┌─ :5:11
  │
5 │     print(basename("/tmp/notes.txt"));
  │           ^
```

