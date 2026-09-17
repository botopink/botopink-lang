----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func: fn(string)-> string = {s ->
        return s;
    };
    return func("hello");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0))
  (data (i32.const 256) "\05\00\00\00hello")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $main (result i32)
    (local $func i32)
    (local $__mem0 i32)
    (local $__fnv0 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.set $func
    local.get $func
    local.set $__fnv0
    local.get $__fnv0
    i32.const 256
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    return
  )
  (func $__lambda0 (param $__env i32) (param $s i32) (result i32)
    local.get $s
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
    drop
  )
)
```

----- RUN LOG -----
```logs
```
