----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    _      -> {
        val value = "odd";
        break value;
    };
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (start $__init_globals)
  (data (i32.const 256) "\04\00\00\00even")
  (global $__heap_ptr (mut i32) (i32.const 264))
  (global $parity (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__case_0 i32)
    i32.const 5
    local.set $__case_0
    i32.const 0
    local.get $__case_0
    i32.const 0
    i32.eq
    i32.or
    local.get $__case_0
    i32.const 2
    i32.eq
    i32.or
    local.get $__case_0
    i32.const 4
    i32.eq
    i32.or
    (if (result i32)
      (then
    i32.const 256
      )
      (else
    i32.const 0 ;; lambda
      )
    )
    global.set $parity
  )
)
```

----- RUN LOG -----
```logs
```
