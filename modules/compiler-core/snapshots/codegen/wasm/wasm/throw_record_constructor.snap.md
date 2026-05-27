----- SOURCE CODE -- main.bp
```botopink
record AppError { code: i32, msg: string }
fn validate(x: i32) {
    if (x < 0) {
        throw AppError(code: 400, msg: "negative");
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "negative")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (func $validate (param $x i32)
    local.get $x
    i32.const 0
    i32.lt_s
    (if (result i32)
      (then
    i32.const 400
    i32.const 256
    call $AppError
    unreachable
      )
      (else
        i32.const 0
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
