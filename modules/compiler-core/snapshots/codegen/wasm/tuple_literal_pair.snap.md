----- SOURCE CODE -- main.bp
```botopink
val pair = #(1, "hello");
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $pair (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
