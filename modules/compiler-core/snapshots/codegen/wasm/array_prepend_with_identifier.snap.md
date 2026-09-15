----- SOURCE CODE -- main.bp
```botopink
val rest = [3, 4];
val list = [1, 2, ..rest];
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $rest (mut i32) (i32.const 0))
  (global $list (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
