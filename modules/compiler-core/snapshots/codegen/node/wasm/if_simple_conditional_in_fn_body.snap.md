----- SOURCE CODE -- main.bp
```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "positive")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $sign (param $n i32) (result i32)
    (local $r i32)
    local.get $n
    i32.const 0
    i32.gt_s
    (if (result i32)
      (then
    i32.const 256
      )
      (else
        i32.const 0
      )
    )
    local.set $r
    local.get $r
    return
  )
)
```

----- RUN LOG -----
```logs
```
