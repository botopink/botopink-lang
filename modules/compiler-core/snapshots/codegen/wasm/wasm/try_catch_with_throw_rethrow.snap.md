----- SOURCE CODE -- main.bp
```botopink
record ApiError { msg: string }
*fn fetch() -> @Result<i32, ApiError> {
    throw ApiError(msg: "not found");
}
*fn strict() -> @Result<i32, string> {
    val r = try fetch() catch throw "fetch failed";
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\09\00\00\00not found")
  (data (i32.const 272) "\0c\00\00\00fetch failed")
  (global $__heap_ptr (mut i32) (i32.const 288))
  (func $fetch (result i32)
    (local $__mem0 i32)
    (local $_res0 i32)
    global.get $__heap_ptr
    local.set $_res0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    global.get $__heap_ptr
    local.set $__mem0
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 256
    i32.store
    local.get $__mem0
    i32.store offset=4 ;; payload
    local.get $_res0
    return
  )
  (func $strict (result i32)
    (local $_try0 i32)
    (local $r i32)
    call $fetch
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    (local $_res0 i32)
    global.get $__heap_ptr
    local.set $_res0
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res0
    i32.const 1
    i32.store ;; Result tag (Error)
    local.get $_res0
    i32.const 272
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
    (local $_res1 i32)
    global.get $__heap_ptr
    local.set $_res1
    global.get $__heap_ptr
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $_res1
    i32.const 0
    i32.store ;; Result tag (Ok)
    local.get $_res1
    local.get $r
    i32.store offset=4 ;; payload
    local.get $_res1
    return
  )
)
```

----- RUN LOG -----
```logs
```
