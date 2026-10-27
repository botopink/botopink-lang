----- SOURCE CODE -- main.bp
```botopink
fn f() -> void {
    val items = [1, 2, 3, 4];
    val assert [first, second, ..rest] = items catch [];
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@array" "std:array.slice" (func $__std_array_slice (param i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $f (result i32)
    (local $__mem0 i32)
    (local $items i32)
    (local $__assert_0 i32)
    (local $__mem1 i32)
    (local $first i32)
    (local $second i32)
    (local $rest i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 4
    i32.store
    local.get $__mem0
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 2
    i32.store offset=8
    local.get $__mem0
    i32.const 3
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.store offset=16
    local.get $__mem0
    local.set $items
    local.get $items
    local.set $__assert_0
    local.get $__assert_0
    i32.load ;; element count
    i32.const 2
    i32.ge_u
    i32.eqz
    (if
      (then
    i32.const 4
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 0
    i32.store
    local.get $__mem1
    local.set $__assert_0
      )
    )
    local.get $__assert_0
    i32.load offset=4
    local.set $first
    local.get $__assert_0
    i32.load offset=8
    local.set $second
    local.get $__assert_0
    i32.const 2
    i32.const 2147483647
    call $__std_array_slice
    local.set $rest
    i32.const 0
  )
)
```

----- RUN LOG -----
```logs
```
