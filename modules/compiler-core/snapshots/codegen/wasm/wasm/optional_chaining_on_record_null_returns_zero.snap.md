----- SOURCE CODE -- main.bp
```botopink
record R { a: i32, b: i32 }
fn pick(maybe: ?R) -> i32 {
    return maybe?.b;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $pick (param $maybe i32) (result i32)
    (local $__mem0 i32)
    local.get $maybe
    local.tee $__mem0
    i32.eqz
    (if (result i32)
      (then
        i32.const 0 ;; ?.b on null
      )
      (else
        local.get $__mem0
        i32.load offset=4 ;; ?.b
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
