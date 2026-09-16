----- SOURCE CODE -- main.bp
```botopink
fn apply(f: syntax fn(x: i32) -> i32) -> i32 {
    return f(10);
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $apply (param $f i32) (result i32)
    unreachable ;; unresolved call: f/1
    return
  )
)
```

----- RUN LOG -----
```logs
```
