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
    (local $__iter0 i32)
    (local $__idx0 i32)
    (local $__len0 i32)
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
    local.get $x
    i32.const 2
    i32.rem_s
    i32.const 0
    i32.ne
    (if (result i32)
      (then
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $x
    drop
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    return
  )
)
```

----- RUN LOG -----
```logs
```
