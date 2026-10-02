----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val items = [1, 2, 3, 4];
    val assert [first, second, ..rest] = items catch [];
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $f (result i32)
    (local $__mem0 i32)
    (local $items i32)
    (local $__assert_0 i32)
    (local $__mem1 i32)
    (local $first i32)
    (local $second i32)
    (local $rest i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 20
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 4
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
    i32.const 4
    i32.store offset=16
    local.get $__mem0
    local.set $items
    local.get $items
    local.set $__assert_0
    local.get $__assert_0
    i32.load ;; element count
    i32.const 2
    i32.ge_u
    i32.eqz
    (if
      (then
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    local.set $__assert_0
      )
    )
    local.get $__assert_0
    i32.load offset=4
    local.set $first
    local.get $__assert_0
    i32.load offset=8
    local.set $second
    local.get $__assert_0
    i32.const 2
    i32.const 2147483647
    call $__arr_slice
    local.set $rest
    i32.const 0
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32)
    global.get $__heap_ptr
    local.set $p
    global.get $__heap_ptr
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    global.set $__heap_ptr
    local.get $p
  )
  (func $__arr_new (param $n i32) (result i32)
    (local $p i32)
    local.get $n
    i32.const 1
    i32.add
    i32.const 4
    i32.mul
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
    local.get $p
  )
  (func $__arr_slice (param $xs i32) (param $a i32) (param $b i32) (result i32)
    (local $n i32) (local $cnt i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $a
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $a
        i32.add
        local.set $a
        local.get $a
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $a
          )
        )
      )
      (else
        local.get $a
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $a
          )
        )
      )
    )
    local.get $b
    i32.const 0
    i32.lt_s
    (if
      (then
        local.get $n
        local.get $b
        i32.add
        local.set $b
        local.get $b
        i32.const 0
        i32.lt_s
        (if
          (then
            i32.const 0
            local.set $b
          )
        )
      )
      (else
        local.get $b
        local.get $n
        i32.gt_s
        (if
          (then
            local.get $n
            local.set $b
          )
        )
      )
    )
    local.get $b
    local.get $a
    i32.sub
    local.set $cnt
    local.get $cnt
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $cnt
      )
    )
    local.get $cnt
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.mul
    i32.add
    local.get $cnt
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
