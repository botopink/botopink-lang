----- SOURCE CODE -- main.bp
```botopink
fn notImplemented() {
    @todo("implement this function");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $notImplemented
    unreachable
  )
)
```

----- RUN LOG -----
```logs
```
