----- SOURCE CODE -- main.bp
```botopink
fn abs(n: i32) -> i32 {
    val result = if (n < 0) -n else n;
    return result;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $abs (param $n i32) (result i32)
    (local $result i32)
    local.get $n
    i32.const 0
    i32.lt_s
    (if (result i32)
      (then
    i32.const 0
    local.get $n
    i32.sub
      )
      (else
    local.get $n
      )
    )
    local.set $result
    local.get $result
    return
  )
)
```

----- RUN LOG -----
```logs
```
