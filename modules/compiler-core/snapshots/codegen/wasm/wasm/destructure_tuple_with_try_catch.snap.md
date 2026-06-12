----- SOURCE CODE -- main.bp
```botopink
record Error { msg: string }
*fn fetch() -> @Result<#(i32, i32), Error> {
    throw Error(msg: "boom");
}
fn f() {
    val #(a, b) = try fetch() catch throw Error(msg: "failed");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\04\00\00\00boom")
  (data (i32.const 264) "\06\00\00\00failed")
  (global $__heap_ptr (mut i32) (i32.const 276))
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
  (func $f
    (local $_try0 i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $a i32)
    (local $b i32)
    call $fetch
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    global.get $__heap_ptr
    local.set $__mem1
    global.get $__heap_ptr
    i32.const 4
    i32.add
    global.set $__heap_ptr
    local.get $__mem1
    i32.const 264
    i32.store
    local.get $__mem1
    unreachable
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
  )
)
```

----- RUN LOG -----
```logs
```
