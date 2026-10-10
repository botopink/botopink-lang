----- SOURCE CODE -- main.bp
```botopink
val list3 = [1, 2, ..[3, 4]];
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (start $__init_globals)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $list3 (mut i32) (i32.const 0))
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
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 2
    i32.store offset=8
    local.get $__mem0
    i32.const 12
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 2
    i32.store
    local.get $__mem1
    i32.const 3
    i32.store offset=4
    local.get $__mem1
    i32.const 4
    i32.store offset=8
    local.get $__mem1
    call $__arr_concat
    global.set $list3
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
  (func $__arr_concat (param $a i32) (param $b i32) (result i32)
    (local $na i32) (local $nb i32) (local $p i32)
    local.get $a
    i32.load
    local.set $na
    local.get $b
    i32.load
    local.set $nb
    local.get $na
    local.get $nb
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $na
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $na
    i32.const 4
    i32.mul
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $nb
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
