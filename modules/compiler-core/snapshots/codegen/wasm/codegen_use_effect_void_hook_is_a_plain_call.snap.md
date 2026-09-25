----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
fn cleanup() {
    0;
}
#[@use]
fn effect() -> @Use<Element, i32> {
    0;
}
#[@use]
fn Widget() -> @Component<Element> {
    use effect { -> cleanup(); };
    Element();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0a\00\00\00R\07Element\00")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (func $cleanup (result i32)
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
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 4
    i32.add
  )
)
```

----- RUN LOG -----
```logs
```
