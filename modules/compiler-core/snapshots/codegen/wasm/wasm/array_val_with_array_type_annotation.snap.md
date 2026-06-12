----- SOURCE CODE -- main.bp
```botopink
val array: string[] = ["65454"];
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $array (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
