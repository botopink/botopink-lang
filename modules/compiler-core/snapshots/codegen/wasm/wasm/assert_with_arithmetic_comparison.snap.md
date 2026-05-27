----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert 1.0 + 2.0 == 3.0;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $f
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
