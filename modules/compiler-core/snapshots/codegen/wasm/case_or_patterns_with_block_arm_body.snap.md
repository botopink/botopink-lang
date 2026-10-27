----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    _      -> {
        val value = "odd";
        value
    };
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (start $__bp_reserve)
  (data $__bp_seg0 "\04\00\00\00even")
  (data $__bp_seg1 "\03\00\00\00odd")
  (global $parity (mut i32) (i32.const 0))
  (func $__init_globals
    (local $__case_0 i32)
    (local $value i32)
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
    i32.const 11696
      )
      (else
    i32.const 11704
    local.set $value
    local.get $value
      )
    )
    global.set $parity
  )
  (func $__bp_reserve
    memory.size
    i32.const 1
    i32.lt_u
    (if
      (then
      i32.const 1
      memory.size
      i32.sub
      memory.grow
      drop
      )
    )
    i32.const 11696
    i32.const 0
    i32.const 8
    memory.init $__bp_seg0
    data.drop $__bp_seg0
    i32.const 11704
    i32.const 0
    i32.const 7
    memory.init $__bp_seg1
    data.drop $__bp_seg1
    global.get $__heap_ptr
    i32.const 11712
    i32.lt_u
    (if
      (then
      i32.const 11712
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
