----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var #(x, y) = #(10, 20);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $x i32)
    (local $y i32)
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 10
    i32.store
    local.get $__mem1
    i32.const 20
    i32.store offset=4
    local.get $__mem1
    local.set $__mem0
    local.get $__mem0
    i32.load
    local.set $x
    local.get $__mem0
    i32.load offset=4
    local.set $y
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
