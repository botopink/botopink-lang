----- SOURCE CODE -- main.bp
```botopink
record FetchError { url: string }
fn fetch() -> @Result(i32, FetchError) {
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
  (memory (export "memory") 1)
  (data (i32.const 256) "/api")
  (global $__heap_ptr (mut i32) (i32.const 260))
  (func $fetch (result i32)
    i32.const 256
    call $FetchError
    unreachable
  )
  (func $safe (result i32)
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
