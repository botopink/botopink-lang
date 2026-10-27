----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val numbers = [1, 2, 3];
    val assert [1, 2, 3] = numbers catch throw "not matching";
    return;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (data (i32.const 11696) "\0c\00\00\00not matching")
  (func $f (result i32)
    (local $__mem0 i32)
    (local $numbers i32)
    (local $__assert_0 i32)
    (local $_res0 i32)
    (local $_res1 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 3
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
    local.set $numbers
    local.get $numbers
    local.set $__assert_0
    local.get $__assert_0
    i32.load ;; element count
    i32.const 3
    i32.eq
    (if (result i32)
      (then
    local.get $__assert_0
    i32.load offset=4
    i32.const 1
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $__assert_0
    i32.load offset=8
    i32.const 2
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $__assert_0
    i32.load offset=12
    i32.const 3
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    i32.eqz
    (if
      (then
    i32.const 8
    call $__alloc
    local.set $_res0
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    i32.const 11696
    i32.store offset=4 ;; payload
    local.get $_res0
    return
      )
    )
    i32.const 8
    call $__alloc
    local.set $_res1
    local.get $_res1
    i32.const 0
    i32.store ;; Result tag (Ok)
    local.get $_res1
    i32.const 0
    i32.store offset=4 ;; payload
    local.get $_res1
    return
  )
  (start $__bp_reserve)
  (func $__bp_reserve
    global.get $__heap_ptr
    i32.const 11712
    i32.lt_u
    (if
      (then
      i32.const 11712
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
