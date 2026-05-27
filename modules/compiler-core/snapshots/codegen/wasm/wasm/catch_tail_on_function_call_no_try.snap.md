----- SOURCE CODE -- main.bp
```botopink
record RiskError { level: i32 }
fn risky() -> @Result(i32, RiskError) {
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
    i32.const 5
    call $RiskError
    unreachable
  )
  (func $safe (result i32)
    call $risky
    return
  )
)
```

----- RUN LOG -----
```logs
```
