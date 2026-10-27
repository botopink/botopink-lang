----- SOURCE CODE -- main.bp
```botopink
type Error(msg: string)
fn fetch() -> Result<#(i32, i32), Error> {
    throw Error(msg: "boom");
}
fn f() -> Result<void, Error> {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
    return;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (data $__bp_seg0 "\0d\00\00\00R\05Error\01\03msgs")
  (data $__bp_seg1 "\04\00\00\00boom")
  (data $__bp_seg2 "\06\00\00\00failed")
  (func $fetch (result i32)
    (local $__mem0 i32)
    (local $_res0 i32)
    i32.const 8
    call $__alloc
    local.set $_res0
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 11700
    i32.store
    local.get $__mem0
    i32.const 11716
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    i32.store offset=4 ;; payload
    local.get $_res0
    return
  )
  (func $f (result i32)
    (local $_try0 i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $a i32)
    (local $b i32)
    (local $_res0 i32)
    (local $_res1 i32)
    call $fetch
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 8
    call $__alloc
    local.set $_res0
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    i32.const 8
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 11700
    i32.store
    local.get $__mem1
    i32.const 11724
    i32.store offset=4
    local.get $__mem1
    i32.const 4
    i32.add
    i32.store offset=4 ;; payload
    local.get $_res0
    return
      )
      (else
    local.get $_try0
    i32.load offset=4 ;; Ok payload
      )
    )
    local.set $__mem0
    local.get $__mem0
    i32.load
    local.set $a
    local.get $__mem0
    i32.load offset=4
    local.set $b
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
    i32.const 11696
    i32.const 0
    i32.const 17
    memory.init $__bp_seg0
    data.drop $__bp_seg0
    i32.const 11716
    i32.const 0
    i32.const 8
    memory.init $__bp_seg1
    data.drop $__bp_seg1
    i32.const 11724
    i32.const 0
    i32.const 10
    memory.init $__bp_seg2
    data.drop $__bp_seg2
    global.get $__heap_ptr
    i32.const 11736
    i32.lt_u
    (if
      (then
      i32.const 11736
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
