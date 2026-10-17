----- SOURCE CODE -- main.bp
```botopink
fn process(a: i32, b: i32) {
    case a, b {
        0, 0 -> null;
        _, _ -> null;
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $process (param $a i32) (param $b i32) (result i32)
    (local $__case_0 i32)
    (local $__case_0_0 i32)
    (local $__case_0_1 i32)
    local.get $a
    local.set $__case_0_0
    local.get $__case_0_0
    local.set $__case_0
    local.get $b
    local.set $__case_0_1
    i32.const 1
    local.get $__case_0_0
    i32.const 0
    i32.eq
    i32.and
    local.get $__case_0_1
    i32.const 0
    i32.eq
    i32.and
    (if (result i32)
      (then
    i32.const 0
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
