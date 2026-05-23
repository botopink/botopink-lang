----- SOURCE CODE -- main.bp
```botopink
val add = { x, y ->
    x + y;
};
val result = add(10, 20);
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $add (mut i32) (i32.const 0))
  (global $result (mut i32) (i32.const 0))
)
```

----- RUN LOG -----
```logs
```
