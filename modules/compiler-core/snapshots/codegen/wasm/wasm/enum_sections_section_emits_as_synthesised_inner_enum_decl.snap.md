----- SOURCE CODE -- main.bp
```botopink
enum Token {
    Text {
        Bold, Italic, Underline,
    }
    Hover(inner: i32),
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
