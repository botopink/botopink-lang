----- SOURCE CODE -- main.bp
```botopink
fn diff(x: i32, y: i32) -> i32 {
    return x + -y;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $diff (param $x i32) (param $y i32) (result i32)
    local.get $x
    i32.const 0
    local.get $y
    i32.sub
    i32.add
    return
  )
)
```

----- RUN LOG -----
```logs
```
