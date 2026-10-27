----- SOURCE CODE -- main.bp
```botopink
type ApiError(msg: string)
fn fetch() -> Result<i32, ApiError> {
    throw ApiError(msg: "not found");
}
fn strict() -> Result<i32, string> {
    val r = try fetch() catch throw "fetch failed";
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (data $__bp_seg0 "\10\00\00\00R\08ApiError\01\03msgs")
  (data $__bp_seg1 "\09\00\00\00not found")
  (data $__bp_seg2 "\0c\00\00\00fetch failed")
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
    i32.const 11684
    i32.store
    local.get $__mem0
    i32.const 11700
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    i32.store offset=4 ;; payload
    local.get $_res0
    return
  )
  (func $strict (result i32)
    (local $_try0 i32)
    (local $r i32)
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
    i32.const 11716
    i32.store offset=4 ;; payload
    local.get $_res0
    return
      )
      (else
    local.get $_try0
    i32.load offset=4 ;; Ok payload
      )
    )
    local.set $r
    i32.const 8
    call $__alloc
    local.set $_res1
    local.get $_res1
    i32.const 0
    i32.store ;; Result tag (Ok)
    local.get $_res1
    local.get $r
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
    i32.const 20
    memory.init $__bp_seg0
    data.drop $__bp_seg0
    i32.const 11700
    i32.const 0
    i32.const 13
    memory.init $__bp_seg1
    data.drop $__bp_seg1
    i32.const 11716
    i32.const 0
    i32.const 16
    memory.init $__bp_seg2
    data.drop $__bp_seg2
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
