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
  (global $__heap_ptr (mut i32) (i32.const 288))
  (func $f (result i32)
    (local $__mem0 i32)
    (local $items i32)
    (local $__assert_0 i32)
    (local $__mem1 i32)
    (local $first i32)
    (local $second i32)
    (local $rest i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
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
    i32.const 4
    call $__alloc
    local.set $__mem1
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
    call $__std_array_slice
    local.set $rest
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
  ;; std-wasm (decision 440): its functions, transpiled from std_wasm.wasm
  (global $__std_sp (mut i32) (i32.const 288))
  (func $__std_sp_check (param $sp i32) (result i32)
    local.get $sp
    i32.const 256
    i32.lt_s
    (if
      (then unreachable)
    )
    local.get $sp
  )
  ;; __std_f433 — from std_wasm.wasm (sha256 d13a98c08300)
  ;; __std_f434 — from std_wasm.wasm (sha256 4f0cbdd2d671)
  ;; __std_f435 — from std_wasm.wasm (sha256 0314fe5f477f)
  ;; __std_f436 — from std_wasm.wasm (sha256 4120145e86ab)
  ;; std:array.slice — from std_wasm.wasm (sha256 eebf2d3e1b4f)
)
```

----- RUN LOG -----
```logs
```
