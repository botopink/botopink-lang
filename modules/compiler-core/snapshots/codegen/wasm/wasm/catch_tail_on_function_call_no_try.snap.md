----- SOURCE CODE -- main.bp
```botopink
record RiskError { level: i32 }
*fn risky() -> @Result<i32, RiskError> {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $risky (result i32)
    (local $__mem0 i32)
    (local $_res0 i32)
    global.get $__heap_ptr
    local.set $_res0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 5
    i32.store
    local.get $__mem0
    i32.store offset=4 ;; payload
    local.get $_res0
    return
  )
  (func $safe (result i32)
    (local $_try0 i32)
    call $risky
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 0
    i32.const 1
    i32.sub
      )
      (else
    local.get $_try0
    i32.load offset=4 ;; Ok payload
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
