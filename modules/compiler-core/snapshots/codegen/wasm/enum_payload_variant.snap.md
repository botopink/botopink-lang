----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Rgb(r: i32, g: i32, b: i32),
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
)
```

----- RUN LOG -----
```logs
```
