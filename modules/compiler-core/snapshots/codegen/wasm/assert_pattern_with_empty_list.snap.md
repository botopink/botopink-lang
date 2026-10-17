----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val list: i32[] = [];
    val assert [] = list catch throw "not empty";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\09\00\00\00not empty")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (func $f (result i32)
    (local $__mem0 i32)
    (local $list i32)
    (local $__assert_0 i32)
    i32.const 4
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.set $list
    local.get $list
    local.set $__assert_0
    local.get $__assert_0
    i32.load ;; element count
    i32.const 0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 256
    drop
    unreachable
      )
    )
    i32.const 0
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
