----- SOURCE CODE -- main.bp
```botopink
#[@external(.JavaScript("process.pid"), .Erlang("list_to_integer(os:getpid())"))]
declare fn pid() -> i32;

fn main() {
    print(pid() > 0);
}

import {io.terminal.print, compiler} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `pid` has no implementation for the wasm backend
  ┌─ :5:11
  │
5 │     print(pid() > 0);
  │           ^
```

