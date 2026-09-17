----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0 -> {
      case 1 {
          0    -> 54;
          _ -> 1;
      };
   };
   _ -> 1;
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0))
  (start $__init_globals)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (global $result (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__case_0 i32)
    (local $__mem0 i32)
    i32.const 42
    local.set $__case_0
    local.get $__case_0
    i32.const 0
    i32.eq
    (if (result i32)
      (then
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
      (else
    i32.const 1
      )
    )
    global.set $result
  )
  (func $__lambda0 (param $__env i32) (result i32)
    (local $__case_0 i32)
    i32.const 1
    local.set $__case_0
    local.get $__case_0
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 54
      )
      (else
    i32.const 1
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
