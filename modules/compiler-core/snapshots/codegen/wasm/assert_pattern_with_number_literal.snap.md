----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $f (result i32)
    (local $answer i32)
    i32.const 42
    local.set $answer
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
