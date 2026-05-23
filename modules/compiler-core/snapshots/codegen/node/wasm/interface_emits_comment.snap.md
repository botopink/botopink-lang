----- SOURCE CODE -- main.bp
```botopink
val Drawable = interface {
    val color: string,
    fn draw(self: Self);
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
