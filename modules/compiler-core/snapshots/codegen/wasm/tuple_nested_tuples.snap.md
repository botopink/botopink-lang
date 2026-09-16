----- SOURCE CODE -- main.bp
```botopink
val nested = #(#(1, 2), #(3, 4));
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (start $__init_globals)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $nested (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
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
    global.get $__heap_ptr
    local.set $__mem2
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem2
    i32.const 3
    i32.store
    local.get $__mem2
    i32.const 4
    i32.store offset=4
    local.get $__mem2
    i32.store offset=4
    local.get $__mem0
    global.set $nested
  )
)
```

----- RUN LOG -----
```logs
```
