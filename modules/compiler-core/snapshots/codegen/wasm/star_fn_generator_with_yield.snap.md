----- SOURCE CODE -- main.bp
```botopink
#[@iterator]
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
    yield 3;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; #[@future] / #[@asyncGenerator] — eager lowering
  (func $counter (result i32)
    i32.const 1
    i32.const 2
    i32.const 3
  )
)
```

----- RUN LOG -----
```logs
```
