----- SOURCE CODE -- main.bp
```botopink
pub val VERSION = 1;
pub val HOST = "localhost";
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "localhost")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (global $VERSION (export "VERSION") i32 (i32.const 1))
  (global $HOST (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```
