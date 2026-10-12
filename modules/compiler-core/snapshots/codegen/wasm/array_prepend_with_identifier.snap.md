----- SOURCE CODE -- main.bp
```botopink
val rest = [3, 4];
val list = [1, 2, ..rest];
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (start $__init_globals)
  (global $__heap_ptr (mut i32) (i32.const 288))
  (global $rest (mut i32) (i32.const 0))
  (global $list (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 2
    i32.store
    local.get $__mem0
    i32.const 3
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.store offset=8
    local.get $__mem0
    global.set $rest
    i32.const 12
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 2
    i32.store
    local.get $__mem1
    i32.const 1
    i32.store offset=4
    local.get $__mem1
    i32.const 2
    i32.store offset=8
    local.get $__mem1
    global.get $rest
    call $__std_array_concat
    global.set $list
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
  ;; __std_f372 — from std_wasm.wasm (sha256 d13a98c08300)
  ;; __std_f374 — from std_wasm.wasm (sha256 964928f3a255)
  ;; std:array.concat — from std_wasm.wasm (sha256 47da71077055)
)
```

----- RUN LOG -----
```logs
```
