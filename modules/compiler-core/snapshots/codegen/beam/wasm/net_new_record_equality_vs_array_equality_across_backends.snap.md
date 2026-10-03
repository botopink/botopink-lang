----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn recordEq() -> bool {
    val a = Point(x: 1, y: 2);
    val b = Point(x: 1, y: 2);
    return a == b;
}
fn arrayEq() -> bool {
    val xs = [1, 2];
    val ys = [1, 2];
    return xs == ys;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\0e\00\00\00R\05Point\02\01xi\01yi")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $recordEq (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $a i32)
    (local $b i32)
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 2
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $a
    i32.const 12
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 260
    i32.store
    local.get $__mem1
    i32.const 1
    i32.store offset=4
    local.get $__mem1
    i32.const 2
    i32.store offset=8
    local.get $__mem1
    i32.const 4
    i32.add
    local.set $b
    local.get $a
    local.get $b
    call $__eq_Point
    return
  )
  (func $arrayEq (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $xs i32)
    (local $ys i32)
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
    local.set $xs
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
    local.set $ys
    local.get $xs
    local.get $ys
    call $__eq_Array_i32
    return
  )
  (func $__eq_Point (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.eq
    (if
      (then i32.const 1 return)
    )
    local.get $a
    i32.load
    local.get $b
    i32.load
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    i32.load offset=4
    local.get $b
    i32.load offset=4
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
  )
  (func $__eq_Array_i32 (param $a i32) (param $b i32) (result i32)
    (local $n i32) (local $i i32)
    local.get $a
    local.get $b
    i32.eq
    (if
      (then i32.const 1 return)
    )
    local.get $a
    i32.load
    local.get $b
    i32.load
    i32.ne
    (if
      (then i32.const 0 return)
    )
    local.get $a
    i32.load
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $a
    i32.const 4
    i32.add
    local.get $i
    i32.const 4
    i32.mul
    i32.add
    i32.load
    local.get $b
    i32.const 4
    i32.add
    local.get $i
    i32.const 4
    i32.mul
    i32.add
    i32.load
    i32.eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    i32.const 1
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
