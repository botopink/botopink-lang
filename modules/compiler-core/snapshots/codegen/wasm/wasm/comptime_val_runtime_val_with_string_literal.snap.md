----- SOURCE CODE -- main.bp
```botopink
val greeting = "Hello, World!";
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "Hello, World!")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (global $greeting (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```
