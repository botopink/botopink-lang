----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    throw "something went wrong";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "something went wrong")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $fail
    i32.const 256
    unreachable
  )
)
```

----- RUN LOG -----
```logs
```
