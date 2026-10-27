----- SOURCE CODE -- main.bp
```botopink
type State<T>(value: T, set: fn(next: T))
fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (table funcref (elem $__lambda0))
  (data (i32.const 11696) "\14\00\00\00R\05State\02\05valueG\03seti")
  (data (i32.const 11720) "\01\00\00\00i")
  (func $make (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 11700
    i32.store
    local.get $__mem0
    i32.const 11724
    i32.store offset=12
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
  (start $__bp_reserve)
  (func $__bp_reserve
    global.get $__heap_ptr
    i32.const 11728
    i32.lt_u
    (if
      (then
      i32.const 11728
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
