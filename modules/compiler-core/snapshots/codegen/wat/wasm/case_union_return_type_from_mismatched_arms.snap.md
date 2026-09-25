----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0    -> "zero";
    _ -> 1;
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (start $__init_globals)
  (data (i32.const 256) "\04\00\00\00zero")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (global $result (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__case_0 i32)
    i32.const 42
    local.set $__case_0
    local.get $__case_0
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 256
      )
      (else
    i32.const 1
      )
    )
    global.set $result
  )
)
```

----- RUN LOG -----
```logs
```
