----- SOURCE CODE -- main.bp
```botopink
fn getFirst(t: #(i32, string)) -> i32 {
    return t._0;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $getFirst (param $t i32) (result i32)
    local.get $t
    i32.load
    return
  )
)
```

----- RUN LOG -----
```logs
```
