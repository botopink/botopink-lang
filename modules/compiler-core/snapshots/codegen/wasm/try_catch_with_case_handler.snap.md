----- SOURCE CODE -- main.bp
```botopink
val ErrorKind = type { NotFound, Timeout }
fn fetch() -> Result<i32, ErrorKind> {
    throw ErrorKind.NotFound;
}
fn handle() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $box_i32 (struct (field $v i32)))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $fetch (result (ref null $result))
    i32.const 1
    i32.const 0 ;; ErrorKind.NotFound
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $handle (result i32)
    (local $_try0 i32)
    (local $r i32)
    (local $__gc0 (ref null $result))
    call $fetch
    local.set $__gc0
    local.get $__gc0
    struct.get $result $tag ;; Result tag (0 = Ok, non-zero = Error)
    (if (result i32)
      (then
    i32.const 0
      )
      (else
    local.get $__gc0
    struct.get $result $payload ;; Ok payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
      )
    )
    local.set $r
    local.get $r
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
