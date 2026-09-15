----- SOURCE CODE -- main.bp
```botopink
fn make() -> i32 {
    val outer = record { span: record { start: 1, end: 2 }, kind: 3 };
    return outer;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $make (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $outer i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 1
    i32.store
    local.get $__mem1
    i32.const 2
    i32.store offset=4
    local.get $__mem1
    i32.store
    local.get $__mem0
    i32.const 3
    i32.store offset=4
    local.get $__mem0
    local.set $outer
    local.get $outer
    return
  )
)
```

----- RUN LOG -----
```logs
```
