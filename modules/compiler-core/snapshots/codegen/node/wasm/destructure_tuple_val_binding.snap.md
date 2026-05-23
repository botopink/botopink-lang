----- SOURCE CODE -- main.bp
```botopink
fn extract() {
    val #(a, b) = #(12, "hello");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $extract
    (local $a i32)
    (local $b i32)
    i32.const 0 ;; tuple
    local.set $b
    local.set $a
  )
)
```

----- RUN LOG -----
```logs
```
