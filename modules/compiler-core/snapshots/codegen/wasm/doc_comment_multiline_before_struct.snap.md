----- SOURCE CODE -- main.bp
```botopink
/// User account structure
/// Holds name and email
val Account = type(name: string, email: string);
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  ;; User account structure
  ;; Holds name and email
)
```

----- RUN LOG -----
```logs
```
