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
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (start $__bp_reserve)
  (data (i32.const 11696) "\04\00\00\00zero")
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
    i32.const 11696
      )
      (else
    i32.const 1
      )
    )
    global.set $result
  )
  (func $__bp_reserve
    global.get $__heap_ptr
    i32.const 11704
    i32.lt_u
    (if
      (then
      i32.const 11704
      global.set $__heap_ptr
      )
    )
    call $__init_globals
  )
)
```

----- RUN LOG -----
```logs
```
