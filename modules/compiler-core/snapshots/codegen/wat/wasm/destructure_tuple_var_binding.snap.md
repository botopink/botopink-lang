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
    i32.const 8
    call $__alloc
    local.set $__mem1
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
