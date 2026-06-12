----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn render() -> Element {
    Element();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $render (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    local.get $__mem0
  )
)
```

----- RUN LOG -----
```logs
```
