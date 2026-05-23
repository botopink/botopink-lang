----- SOURCE CODE -- main.bp
```botopink
fn countUp(x: i32) {
    loop (x..) { i ->
        if (i > 100) {
          break;
        };
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $countUp (param $x i32)
    (local $i i32)
    local.get $x
    local.set $i
    (block $__break
      (loop $__continue
    local.get $i
    i32.const 100
    i32.gt_s
    (if (result i32)
      (then
      )
      (else
        i32.const 0
      )
    )
    drop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $__continue
      )
    )
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
