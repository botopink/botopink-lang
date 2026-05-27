----- SOURCE CODE -- main.bp
```botopink
val ErrorKind = enum { NotFound, Timeout }
fn fetch() -> @Result(i32, ErrorKind) {
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
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $fetch (result i32)
    i32.const 0 ;; field access
    unreachable
  )
  (func $handle (result i32)
    (local $r i32)
    call $fetch
    local.set $r
    local.get $r
    return
  )
)
```

----- RUN LOG -----
```logs
```
