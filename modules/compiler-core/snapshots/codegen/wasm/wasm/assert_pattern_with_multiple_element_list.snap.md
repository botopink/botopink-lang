----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [1, 2, 3] = numbers catch throw Error("not matching");
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
