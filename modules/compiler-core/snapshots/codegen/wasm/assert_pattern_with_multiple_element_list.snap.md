----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val numbers = [1, 2, 3];
    val assert [1, 2, 3] = numbers catch throw "not matching";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $f (result i32)
    (local $__mem0 i32)
    (local $numbers i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 16
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 3
    i32.store
    local.get $__mem0
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 2
    i32.store offset=8
    local.get $__mem0
    i32.const 3
    i32.store offset=12
    local.get $__mem0
    local.set $numbers
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
