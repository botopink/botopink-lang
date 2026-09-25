----- SOURCE CODE -- main.bp
```botopink
fn sumTo(n: i32) -> i32 {
    var sum = 0;
    for (0..n) { i ->
        sum = sum + i;
    };
    return sum;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $sumTo (param $n i32) (result i32)
    (local $sum i32)
    (local $i i32)
    i32.const 0
    local.set $sum
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
        local.get $i
    local.get $n
        i32.ge_s
        br_if $__break
    local.get $sum
    local.get $i
    i32.add
    local.set $sum
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $sum
    return
  )
)
```

----- RUN LOG -----
```logs
```
