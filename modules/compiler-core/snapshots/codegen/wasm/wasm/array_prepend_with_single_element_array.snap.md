----- SOURCE CODE -- main.bp
```botopink
val list2 = [1, 2, ..[3]];
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $list2 (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
