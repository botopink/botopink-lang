----- SOURCE CODE -- main.bp
```botopink
pub fn loadOne(x: i32) -> @Task<i32> {
    return x;
}
pub fn count() -> @Iterator<i32> {
    yield 1;
}
pub fn pulses() -> @Stream<@Result<i32, string>> {
    yield 1;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; @Task — eager lowering
  (func $loadOne (export "loadOne") (param $x i32) (result i32)
    local.get $x
    return
  )
  ;; @Iterator — eager lowering
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
  ;; @Stream — eager lowering
  (func $pulses (export "pulses") (result i32)
    (local $__yield_fn i32)
    (local $_res0 i32)
    i32.const 0
    call $__arr_new
    local.set $__yield_fn
    local.get $__yield_fn
    global.get $__heap_ptr
    local.set $_res0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res0
    i32.const 0
    i32.store ;; Result tag (Ok)
    local.get $_res0
    i32.const 1
    i32.store offset=4 ;; payload
    local.get $_res0
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
