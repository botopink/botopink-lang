----- SOURCE CODE -- main.bp
```botopink
*fn stream() -> @AsyncIterator<i32, string> {
    yield 1;
    yield 2;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; *fn (async/generator) — eager lowering
  (func $stream (result i32)
    i32.const 1
    i32.const 2
  )
)
```

----- RUN LOG -----
```logs
```
