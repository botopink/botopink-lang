----- SOURCE CODE -- main.bp
```botopink
fn negate(v: bool) -> bool {
    return !v;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $negate (param $v i32) (result i32)
    local.get $v
    i32.eqz
    return
  )
)
```

----- RUN LOG -----
```logs
```
