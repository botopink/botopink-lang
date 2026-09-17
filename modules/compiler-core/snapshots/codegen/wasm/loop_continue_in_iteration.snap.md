----- SOURCE CODE -- main.bp
```botopink
fn sumEvens(arr: i32[]) -> i32 {
    return loop (arr) { x ->
        if (x % 2 != 0) { continue; };
        yield x;
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $sumEvens (param $arr i32) (result i32)
    (local $x i32)
    (local $__yield0 i32)
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
    i32.const 0
    call $__arr_new
    local.set $__yield0
    local.get $arr
    local.set $__iter0
    local.get $__iter0
    i32.load ;; element count
    local.set $__len0
    i32.const 0
    local.set $__idx0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        i32.const 4
        i32.mul
        i32.add
        i32.load offset=4
        local.set $x
        (block $__next
    local.get $x
    i32.const 2
    i32.rem_s
    i32.const 0
    i32.ne
    (if (result i32)
      (then
    br $__next
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $__yield0
    local.get $x
    call $__arr_push
    local.set $__yield0
        )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
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
