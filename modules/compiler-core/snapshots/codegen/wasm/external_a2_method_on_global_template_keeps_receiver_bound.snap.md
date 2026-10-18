----- SOURCE CODE -- main.bp
```botopink
#[compiler.external(.Erlang("iolist_to_binary(io_lib:format(\"~p\", [$0]))"), .JavaScript("JSON.stringify($0)"))]
declare fn stringify(value: i32) -> string;

fn main() {
    print(stringify(42));
}

import {io.terminal.print, compiler} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `stringify` has no implementation for the wasm backend
  ┌─ :5:11
  │
5 │     print(stringify(42));
  │           ^
```

