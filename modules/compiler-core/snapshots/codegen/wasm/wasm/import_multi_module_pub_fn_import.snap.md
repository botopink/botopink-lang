----- SOURCE CODE -- math.bp
```botopink
pub fn double(x: i32) -> i32 {
    return x * 2;
}
```

----- WASM TEXT -- math.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $double (export "double") (param $x i32) (result i32)
    local.get $x
    i32.const 2
    i32.mul
    return
  )
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {double} from "math";
val result = double(21);
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; cross-module import not linked (wasm single-module): double from math
  (global $result (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
