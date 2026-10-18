----- SOURCE CODE -- hostlib.bp
```botopink
#[compiler.external(.JavaScript("String($0)"), .Erlang("""iolist_to_binary(io_lib:format("~0tp", [$0]))"""))]
pub declare fn hostKey(v: i32) -> string;

#[compiler.external(.JavaScript("$0.length"), .Erlang("erlang:length($0)"))]
pub declare fn hostLen(xs: Array<string>) -> i32;

#[compiler.external(.JavaScript("console.log($0)"))]
pub declare fn nodeOnly(s: string) -> void;

import {compiler} from "std";
```

----- WASM TEXT -- hostlib.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; declare fn hostKey — no wasm implementation (host-backed)
  ;; declare fn hostLen — no wasm implementation (host-backed)
  ;; declare fn nodeOnly — no wasm implementation (host-backed)
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import { hostlib.hostKey, hostlib.hostLen, hostlib.nodeOnly };

pub fn main() {
    print(hostKey(42));
    print(hostLen(["a", "b"]));
}

import {io.terminal.print} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `hostKey` has no implementation for the wasm backend
  ┌─ :4:11
  │
4 │     print(hostKey(42));
  │           ^
```

