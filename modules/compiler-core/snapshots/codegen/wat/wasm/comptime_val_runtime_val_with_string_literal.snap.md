----- SOURCE CODE -- main.bp
```botopink
val greeting = "Hello, World!";
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0d\00\00\00Hello, World!")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (global $greeting (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```
