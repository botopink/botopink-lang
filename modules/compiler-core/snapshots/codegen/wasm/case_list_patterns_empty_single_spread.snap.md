----- SOURCE CODE -- main.bp
```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@array" "std:array.slice" (func $__std_array_slice (param i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (data $__bp_seg0 "\01\00\00\00a")
  (data $__bp_seg1 "\01\00\00\00b")
  (data $__bp_seg2 "\01\00\00\00c")
  (data $__bp_seg3 "\05\00\00\00empty")
  (data $__bp_seg4 "\03\00\00\00one")
  (data $__bp_seg5 "\04\00\00\00many")
  (func $describe (result i32)
    (local $__mem0 i32)
    (local $items i32)
    (local $x i32)
    (local $first i32)
    (local $rest i32)
    (local $__case_0 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 3
    i32.store
    local.get $__mem0
    i32.const 11680
    i32.store offset=4
    local.get $__mem0
    i32.const 11688
    i32.store offset=8
    local.get $__mem0
    i32.const 11696
    i32.store offset=12
    local.get $__mem0
    local.set $items
    local.get $items
    local.set $__case_0
    local.get $__case_0
    i32.load ;; element count
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 11704
      )
      (else
    local.get $__case_0
    i32.load ;; element count
    i32.const 1
    i32.eq
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $x
    i32.const 11716
      )
      (else
    local.get $__case_0
    i32.load ;; element count
    i32.const 1
    i32.ge_u
    (if (result i32)
      (then
    local.get $__case_0
    i32.load offset=4
    local.set $first
    local.get $__case_0
    i32.const 1
    i32.const 2147483647
    call $__std_array_slice
    local.set $rest
    i32.const 11724
      )
      (else
    i32.const 0
      )
    )
      )
    )
      )
    )
    return
  )
  (start $__bp_reserve)
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
    i32.const 11680
    i32.const 0
    i32.const 5
    memory.init $__bp_seg0
    data.drop $__bp_seg0
    i32.const 11688
    i32.const 0
    i32.const 5
    memory.init $__bp_seg1
    data.drop $__bp_seg1
    i32.const 11696
    i32.const 0
    i32.const 5
    memory.init $__bp_seg2
    data.drop $__bp_seg2
    i32.const 11704
    i32.const 0
    i32.const 9
    memory.init $__bp_seg3
    data.drop $__bp_seg3
    i32.const 11716
    i32.const 0
    i32.const 7
    memory.init $__bp_seg4
    data.drop $__bp_seg4
    i32.const 11724
    i32.const 0
    i32.const 8
    memory.init $__bp_seg5
    data.drop $__bp_seg5
    global.get $__heap_ptr
    i32.const 11732
    i32.lt_u
    (if
      (then
      i32.const 11732
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
