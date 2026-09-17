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
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $make (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
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
    i32.store offset=4
    local.get $__mem0
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
)
```

----- RUN LOG -----
```logs
```
