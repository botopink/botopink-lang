----- SOURCE CODE -- main.bp
```botopink
#[@generator]
fn range(a: i32, b: i32) -> @Generator<i32> {
    yield a;
    yield b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; *fn (async/generator) — eager lowering
  (func $range (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
  )
)
```

----- RUN LOG -----
```logs
```
