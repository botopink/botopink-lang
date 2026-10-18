----- SOURCE CODE -- main.bp
```botopink
#[compiler.external(.Erlang("filename:dirname($0)"), .JavaScript("""require("node:path").dirname($0)"""))]
pub declare fn dirname(p: string) -> string;

fn main() {
    print(dirname("/tmp/notes.txt"));
}

import {io.terminal.print, compiler} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `dirname` has no implementation for the wasm backend
  ┌─ :5:11
  │
5 │     print(dirname("/tmp/notes.txt"));
  │           ^
```

