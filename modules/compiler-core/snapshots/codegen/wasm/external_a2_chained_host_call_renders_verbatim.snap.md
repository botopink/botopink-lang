----- SOURCE CODE -- main.bp
```botopink
#[compiler.external(.Erlang("base64:encode($0)"), .JavaScript("""Buffer.from($0, 'utf8').toString('base64')"""))]
pub declare fn b64encode(s: string) -> string;

fn main() -> void {
    print(b64encode("hi"));
}

import {io.terminal.print, compiler} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `b64encode` has no implementation for the wasm backend
  ┌─ :5:11
  │
5 │     print(b64encode("hi"));
  │           ^
```

