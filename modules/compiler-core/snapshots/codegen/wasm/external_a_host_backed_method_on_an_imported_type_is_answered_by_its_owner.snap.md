----- SOURCE CODE -- hostlib.bp
```botopink
pub type Meter(base: i32) {
    #[compiler.external(.JavaScript("""($0.base + $1)"""), .Erlang("""(element(2, $0) + $1)"""))]
    pub declare fn plus(self: Self, n: i32) -> i32;
}

import {compiler} from "std";
```

----- WASM TEXT -- hostlib.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import { hostlib.Meter };

pub fn main() -> void {
    print(Meter(base: 40).plus(2));
}

import {io.terminal.print} from "std";
```

----- COMPILE DIAGNOSTIC -- main
```text
error: `Meter.plus` has no implementation for the wasm backend
  ┌─ :4:27
  │
4 │     print(Meter(base: 40).plus(2));
  │                           ^
```

