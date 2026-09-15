----- SOURCE CODE -- main.bp
```botopink
fn process(x: i32) -> string {
    return case (x) {
        0 -> {
            break case (x) {
                0 -> "zero";
                _ -> "other";
            };
        };
        _ -> "non-zero";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\08\00\00\00non-zero")
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $process (param $x i32) (result i32)
    local.get $x
    (local $__case_0 i32)
    local.set $__case_0
    local.get $__case_0
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 0 ;; lambda
      )
      (else
    i32.const 256
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
