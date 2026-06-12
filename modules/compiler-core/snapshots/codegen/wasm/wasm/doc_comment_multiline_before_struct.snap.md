----- SOURCE CODE -- main.bp
```botopink
/// User account structure
/// Holds name and email
val Account = struct { name: string, email: string };
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; User account structure
  ;; Holds name and email
)
```

----- RUN LOG -----
```logs
```
