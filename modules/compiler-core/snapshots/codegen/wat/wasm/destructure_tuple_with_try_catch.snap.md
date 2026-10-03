----- SOURCE CODE -- main.bp
```botopink
type Error(msg: string)
fn fetch() -> @Result<#(i32, i32), Error> {
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
  (data (i32.const 256) "\0d\00\00\00R\05Error\01\03msgs")
  (data (i32.const 276) "\04\00\00\00boom")
  (data (i32.const 284) "\06\00\00\00failed")
  (global $__heap_ptr (mut i32) (i32.const 296))
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
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 276
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
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
    i32.const 8
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 260
    i32.store
    local.get $__mem1
    i32.const 284
    i32.store offset=4
    local.get $__mem1
    i32.const 4
    i32.add
    drop
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
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
  )
)
```

----- RUN LOG -----
```logs
```
