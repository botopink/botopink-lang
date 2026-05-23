----- SOURCE CODE -- main.bp
```botopink
fn describe(n: i32) -> string {
    return if (n > 0) "positive" else "non-positive";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "positive")
  (data (i32.const 264) "non-positive")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $describe (param $n i32) (result i32)
    local.get $n
    i32.const 0
    i32.gt_s
    (if (result i32)
      (then
    i32.const 256
      )
      (else
    i32.const 264
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
