----- SOURCE CODE -- main.bp
```botopink
record State<T> { value: T, set: fn(next: T) }
fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $make (result i32)
    (local $__mem0 i32)
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
    i32.const 0 ;; lambda
    i32.store offset=4
    local.get $__mem0
    return
  )
  (func $apply (param $s i32) (result i32)
    i32.const 0 ;; field access .value
    call $set
    drop
    i32.const 0 ;; field access .value
    return
  )
)
```

----- RUN LOG -----
```logs
```
