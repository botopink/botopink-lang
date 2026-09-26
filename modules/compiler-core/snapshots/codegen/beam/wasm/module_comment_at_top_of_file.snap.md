----- SOURCE CODE -- main.bp
```botopink
//// This module provides utility functions
//// for string manipulation

fn capitalize(s: string) -> string {
    return s;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; This module provides utility functions
  ;; for string manipulation
  (func $capitalize (param $s i32) (result i32)
    local.get $s
    return
  )
)
```

----- RUN LOG -----
```logs
```
