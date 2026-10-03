----- SOURCE CODE -- main.bp
```botopink
type NetError(code: i32)
fn fetch() -> @Result<i32, NetError> {
    throw NetError(code: 500);
}
fn safe() -> i32 {
    val r = try fetch() catch return -1;
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\11\00\00\00R\08NetError\01\04codei")
  (global $__heap_ptr (mut i32) (i32.const 280))
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
    i32.const 8
    i32.add
    global.set $__heap_ptr
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 500
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
    call $fetch
    local.set $_try0
    local.get $_try0
    i32.load ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 0
    i32.const 1
    call $__i32_sub_chk
    return
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
  (func $__i32_add_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $r
  )
)
```

----- RUN LOG -----
```logs
```
