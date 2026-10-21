----- SOURCE CODE -- main.bp
```botopink
#[compiler.external(.Erlang("filename:extension($0)"), .JavaScript("""require("node:path").extname($0)"""))]
pub declare fn extname(p: string) -> string;

fn main() -> void {
    print(extname("docs/readme.md"));
}

import {io.terminal.print, compiler} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `extname` has no implementation for the wasm backend
  ┌─ :5:11
  │
5 │     print(extname("docs/readme.md"));
  │           ^
```

