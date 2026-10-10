----- SOURCE CODE -- main.bp
```botopink
val greeting = "hello";
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\05\00\00\00hello")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (global $greeting (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```
