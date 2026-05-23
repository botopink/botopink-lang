----- SOURCE CODE -- main.bp
```botopink
fn both(a: bool, b: bool) -> bool {
    return a && b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $both (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.and
    return
  )
)
```

----- RUN LOG -----
```logs
```
