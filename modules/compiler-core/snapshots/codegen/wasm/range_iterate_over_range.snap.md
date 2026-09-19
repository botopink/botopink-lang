----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32[] {
    return loop (0..n) { i ->
        yield i;
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $sumTo (param $n i32) (result i32)
    (local $i i32)
    (local $__yield0 i32)
    i32.const 0
    call $__arr_new
    local.set $__yield0
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
        local.get $i
    local.get $n
        i32.ge_s
        br_if $__break
    local.get $__yield0
    local.get $i
    call $__arr_push
    local.set $__yield0
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $__continue
      )
    )
    local.get $__yield0
    return
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
