----- SOURCE CODE -- main.bp
```botopink
import { foo, bar };
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```
