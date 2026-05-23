----- SOURCE CODE -- main.bp
```botopink
fn negate(x: i32) -> i32 {
    return -x;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $negate (param $x i32) (result i32)
    i32.const 0
    local.get $x
    i32.sub
    return
  )
)
```

----- RUN LOG -----
```logs
```
