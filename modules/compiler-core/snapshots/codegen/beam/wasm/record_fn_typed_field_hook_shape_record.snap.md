----- SOURCE CODE -- main.bp
```botopink
type State<T>(value: T, set: fn(next: T))
fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0))
  (data (i32.const 256) "\14\00\00\00R\05State\02\05valuei\03seti")
  (global $__heap_ptr (mut i32) (i32.const 280))
  (func $make (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $apply (param $s i32) (result i32)
    (local $__fnv0 i32)
    local.get $s
    i32.load offset=4 ;; .set
    local.set $__fnv0
    local.get $__fnv0
    local.get $s
    i32.load ;; .value
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    drop
    local.get $s
    i32.load ;; .value
    return
  )
  (func $__lambda0 (param $__env i32) (param $n i32) (result i32)
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
