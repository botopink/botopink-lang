----- SOURCE CODE -- main.bp
```botopink
pub *fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
pub *fn count() -> @Iterator<i32> {
    yield 1;
}
pub *fn pulses() -> @AsyncIterator<i32, string> {
    yield 1;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; *fn (async/generator) — eager lowering
  (func $loadOne (export "loadOne") (param $x i32) (result i32)
    local.get $x
    return
  )
  ;; *fn (async/generator) — eager lowering
  (func $count (export "count") (result i32)
    i32.const 1
  )
  ;; *fn (async/generator) — eager lowering
  (func $pulses (export "pulses") (result i32)
    i32.const 1
  )
)
```

----- RUN LOG -----
```logs
```
