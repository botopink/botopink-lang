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
  (rec
    (type $str (array (mut i8)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; This module provides utility functions
  ;; for string manipulation
  (func $capitalize (param $s (ref null $str)) (result (ref null $str))
    local.get $s
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
