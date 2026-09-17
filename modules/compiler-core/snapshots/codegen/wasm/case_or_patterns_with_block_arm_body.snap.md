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
  (table funcref (elem $__lambda0))
  (start $__init_globals)
  (data (i32.const 256) "\04\00\00\00even")
  (data (i32.const 264) "\03\00\00\00odd")
  (global $__heap_ptr (mut i32) (i32.const 272))
  (global $parity (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__case_0 i32)
    (local $__mem0 i32)
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
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
      )
    )
    global.set $parity
  )
  (func $__lambda0 (param $__env i32) (result i32)
    (local $value i32)
    i32.const 264
    local.set $value
    local.get $value
  )
)
```

----- RUN LOG -----
```logs
```
