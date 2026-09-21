----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn make() -> Point {
    return Point(x: 3, y: 4);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0e\00\00\00R\05Point\02\01xi\01yi")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $make (result i32)
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 12
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 3
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
```
