----- SOURCE CODE -- main.bp
```botopink
val Drawable = behavior {
    val color: string;
    fn draw(self: Self) -> void;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
)
```

----- RUN LOG -----
```logs
```
