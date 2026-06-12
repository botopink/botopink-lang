----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn Counter() -> Element {
    val #(count, setCount) = use state(0);
    Element();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $state (param $initial i32) (result i32)
    local.get $initial
  )
  (func $Counter (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $count i32)
    (local $setCount i32)
    i32.const 0
    call $state
    local.set $__mem0
    local.get $__mem0
    i32.load
    local.set $count
    local.get $__mem0
    i32.load offset=4
    local.set $setCount
    global.get $__heap_ptr
    local.set $__mem1
    local.get $__mem1
  )
)
```

----- RUN LOG -----
```logs
```
