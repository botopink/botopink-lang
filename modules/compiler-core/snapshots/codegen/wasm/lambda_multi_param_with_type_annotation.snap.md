----- SOURCE CODE -- main.bp
```botopink
fn main() -> i32 {
    val add: fn(i32,i32)-> i32 = {a, b ->
        return a + b;
    };
    return add(10, 20);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0))
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main (result i32)
    (local $add i32)
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
    local.set $add
    local.get $add
    local.set $__fnv0
    local.get $__fnv0
    i32.const 10
    i32.const 20
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32 i32) (result i32)
    return
  )
  (func $__lambda0 (param $__env i32) (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.add
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
