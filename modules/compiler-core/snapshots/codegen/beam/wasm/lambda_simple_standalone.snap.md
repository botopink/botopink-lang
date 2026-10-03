----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func = {s ->
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
    i32.const 4
    call $__alloc
    local.set $__mem0
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
