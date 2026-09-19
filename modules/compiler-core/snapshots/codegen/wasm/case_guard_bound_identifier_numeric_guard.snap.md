----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    return case n {
        x if x > 0 -> "positive";
        0 -> "zero";
        _ -> "negative";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\08\00\00\00positive")
  (data (i32.const 268) "\04\00\00\00zero")
  (data (i32.const 276) "\08\00\00\00negative")
  (global $__heap_ptr (mut i32) (i32.const 288))
  (func $classify (param $n i32) (result i32)
    (local $x i32)
    (local $__case_0 i32)
    local.get $n
    local.set $__case_0
    local.get $__case_0
    local.set $x
    local.get $x
    i32.const 0
    i32.gt_s
    (if (result i32)
      (then
    i32.const 256
      )
      (else
    local.get $__case_0
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 268
      )
      (else
    i32.const 276
      )
    )
      )
    )
    return
  )
)
```

----- RUN LOG -----
```logs
```
