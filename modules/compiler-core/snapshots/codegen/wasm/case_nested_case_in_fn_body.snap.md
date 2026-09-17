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
  (table funcref (elem $__lambda0))
  (data (i32.const 256) "\08\00\00\00non-zero")
  (data (i32.const 268) "\04\00\00\00zero")
  (data (i32.const 276) "\05\00\00\00other")
  (global $__heap_ptr (mut i32) (i32.const 288))
  (func $process (param $x i32) (result i32)
    (local $__case_0 i32)
    (local $__mem0 i32)
    local.get $x
    local.set $__case_0
    local.get $__case_0
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.get $x
    i32.store offset=4 ;; capture x
    local.get $__mem0
      )
      (else
    i32.const 256
      )
    )
    return
  )
  (func $__lambda0 (param $__env i32) (result i32)
    (local $x i32)
    (local $__case_0 i32)
    local.get $__env
    i32.load offset=4
    local.set $x
    local.get $x
    local.set $__case_0
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
```

----- RUN LOG -----
```logs
```
