----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn cleanup() {
    0;
}
fn effect() -> @Context<Element, i32> {
    0;
}
fn Widget() -> Element {
    use effect { -> cleanup(); };
    Element();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $cleanup
    i32.const 0
  )
  (func $effect (result i32)
    i32.const 0
  )
  (func $Widget (result i32)
    (local $__mem0 i32)
    call $effect
    drop
    global.get $__heap_ptr
    local.set $__mem0
    local.get $__mem0
  )
)
```

----- RUN LOG -----
```logs
```
