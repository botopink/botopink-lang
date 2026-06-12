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
  (global $__heap_ptr (mut i32) (i32.const 268))
  (func $classify (param $n i32) (result i32)
    local.get $n
    (local $__case_0 i32)
    local.set $__case_0
    i32.const 256
    return
  )
)
```

----- RUN LOG -----
```logs
```
