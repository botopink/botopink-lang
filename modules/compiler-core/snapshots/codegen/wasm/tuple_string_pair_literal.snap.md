----- SOURCE CODE -- main.bp
```botopink
val t = #("56454", "85484");
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $t (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
