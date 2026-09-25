----- SOURCE CODE -- main.bp
```botopink
#[@future]
pub fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
#[@resultGenerator]
pub fn count() -> @ResultGenerator<i32> {
    yield 1;
}
#[@futureGenerator]
pub fn pulses() -> @FutureGenerator<i32, string> {
    yield 1;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; #[@future] / #[@futureGenerator] — eager lowering
  (func $loadOne (export "loadOne") (param $x i32) (result i32)
    local.get $x
    return
  )
  ;; #[@future] / #[@futureGenerator] — eager lowering
  (func $count (export "count") (result i32)
    (local $__yield_fn i32)
    i32.const 0
    call $__arr_new
    local.set $__yield_fn
    local.get $__yield_fn
    i32.const 1
    call $__arr_push
    local.set $__yield_fn
    local.get $__yield_fn ;; everything the body yielded
  )
  ;; #[@future] / #[@futureGenerator] — eager lowering
  (func $pulses (export "pulses") (result i32)
    (local $__yield_fn i32)
    i32.const 0
    call $__arr_new
    local.set $__yield_fn
    local.get $__yield_fn
    i32.const 1
    call $__arr_push
    local.set $__yield_fn
    local.get $__yield_fn ;; everything the body yielded
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
  (func $__arr_push (param $xs i32) (param $x i32) (result i32)
    (local $n i32) (local $p i32)
    local.get $xs
    i32.load
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    call $__arr_new
    local.set $p
    local.get $p
    i32.const 4
    i32.add
    local.get $xs
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    memory.copy
    local.get $p
    i32.const 4
    i32.add
    local.get $n
    i32.const 4
    i32.mul
    i32.add
    local.get $x
    i32.store
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
