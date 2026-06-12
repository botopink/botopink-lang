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
  (data (i32.const 256) "\08\00\00\00negative")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $validate (param $x i32)
    (local $__mem0 i32)
    local.get $x
    i32.const 0
    i32.lt_s
    (if (result i32)
      (then
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 400
    i32.store
    local.get $__mem0
    i32.const 256
    i32.store offset=4
    local.get $__mem0
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
