----- SOURCE CODE -- main.bp
```botopink
val t = #(12, "5452");
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (start $__init_globals)
  (data (i32.const 256) "\04\00\00\005452")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (global $t (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__mem0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 12
    i32.store
    local.get $__mem0
    i32.const 256
    i32.store offset=4
    local.get $__mem0
    global.set $t
  )
)
```

----- RUN LOG -----
```logs
```
