----- SOURCE CODE -- main.bp
```botopink
type FetchError(url: string)
fn fetch() -> Result<i32, FetchError> {
    throw FetchError(url: "/api");
}
fn safe() -> i32 {
    val r = try fetch() catch fn(e) { return 0; };
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (table funcref (elem $__lambda0))
  (data (i32.const 11696) "\12\00\00\00R\nFetchError\01\03urls")
  (data (i32.const 11720) "\04\00\00\00/api")
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
    i32.const 11720
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    i32.store offset=4 ;; payload
    local.get $_res0
    return
  )
  (func $safe (result i32)
    (local $_try0 i32)
    (local $r i32)
    (local $__mem0 i32)
    call $fetch
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 4
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
      )
      (else
    local.get $_try0
    i32.load offset=4 ;; Ok payload
      )
    )
    local.set $r
    local.get $r
    return
  )
  (func $__lambda0 (param $__env i32) (param $e i32) (result i32)
    i32.const 0
    return
  )
  (start $__bp_reserve)
  (func $__bp_reserve
    global.get $__heap_ptr
    i32.const 11728
    i32.lt_u
    (if
      (then
      i32.const 11728
      global.set $__heap_ptr
      )
    )
  )
)
```

----- RUN LOG -----
```logs
```
