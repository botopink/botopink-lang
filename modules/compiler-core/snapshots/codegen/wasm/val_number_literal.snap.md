----- SOURCE CODE -- main.bp
```botopink
val x = 42;
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (global $x i32 (i32.const 42))
)
```

----- RUN LOG -----
```logs
```
