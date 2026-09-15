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
  (data (i32.const 256) "\14\00\00\00something went wrong")
  (global $__heap_ptr (mut i32) (i32.const 280))
  (func $fail
    i32.const 256
    unreachable
  )
)
```

----- RUN LOG -----
```logs
```
