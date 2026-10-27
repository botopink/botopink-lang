----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val list: i32[] = [];
    val assert [] = list catch throw "not empty";
    return;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (data $__bp_seg0 "\09\00\00\00not empty")
  (func $f (result i32)
    (local $__mem0 i32)
    (local $list i32)
    (local $__assert_0 i32)
    (local $_res0 i32)
    (local $_res1 i32)
    i32.const 4
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    local.set $list
    local.get $list
    local.set $__assert_0
    local.get $__assert_0
    i32.load ;; element count
    i32.const 0
    i32.eq
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
    i32.const 11680
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
    i32.const 13
    memory.init $__bp_seg0
    data.drop $__bp_seg0
    global.get $__heap_ptr
    i32.const 11696
    i32.lt_u
    (if
      (then
      i32.const 11696
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
