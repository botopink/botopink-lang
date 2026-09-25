----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
#[@use]
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
#[@use]
fn Counter() -> @Component<Element, Element> {
    val {count, setCount} = use state(0);
    Element();
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0a\00\00\00R\07Element\00")
  (global $__heap_ptr (mut i32) (i32.const 272))
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
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 260
    i32.store
    local.get $__mem1
    i32.const 4
    i32.add
  )
)
```

----- RUN LOG -----
```logs
```
