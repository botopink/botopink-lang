----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    @panic("something went wrong");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $fail
    unreachable
  )
)
```

----- RUN LOG -----
```logs
```
