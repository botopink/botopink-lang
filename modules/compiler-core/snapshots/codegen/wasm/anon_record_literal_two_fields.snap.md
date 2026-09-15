----- SOURCE CODE -- main.bp
```botopink
fn make() -> i32 {
    val r = record { a: 7, b: 11 };
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $make (result i32)
    (local $__mem0 i32)
    (local $r i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 7
    i32.store
    local.get $__mem0
    i32.const 11
    i32.store offset=4
    local.get $__mem0
    local.set $r
    local.get $r
    return
  )
)
```

----- RUN LOG -----
```logs
```
