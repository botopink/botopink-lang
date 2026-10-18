----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement Renderable
fn render() -> Element {
    return Element();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_Element (struct))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $render (result (ref null $rec_Element))
    (local $__mem0 i32)
    struct.new $rec_Element
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
