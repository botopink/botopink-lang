----- SOURCE CODE -- main.bp
```botopink
fn isZero(n: i32) -> bool {
    return n == 0;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $isZero (param $n i32) (result i32)
    local.get $n
    i32.const 0
    i32.eq
    return
  )
)
```

----- RUN LOG -----
```logs
```
